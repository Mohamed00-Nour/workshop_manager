import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  /// Cached service account credentials loaded from the asset bundle.
  Map<String, dynamic>? _cachedCredentials;

  /// The FCM V1 project ID extracted from the service account JSON.
  String? _projectId;

  /// Local notifications plugin for showing foreground notifications on Android.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel details (matches the one created in MainActivity).
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  bool get _isFirebaseInitialized => Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _firestore {
    if (!_isFirebaseInitialized) return null;
    return FirebaseFirestore.instance;
  }

  FirebaseMessaging? get _fcm {
    if (!_isFirebaseInitialized) return null;
    if (kIsWeb) return FirebaseMessaging.instance;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return FirebaseMessaging.instance;
    }
    return null;
  }

  /// Loads the service account JSON from the Flutter asset bundle.
  /// The file is read once and cached for subsequent calls.
  Future<Map<String, dynamic>> _loadServiceAccountCredentials() async {
    if (_cachedCredentials != null) return _cachedCredentials!;

    final jsonString = await rootBundle.loadString(
      'assets/workshop-manager-5f2f7-1c915a4d22cd.json',
    );
    _cachedCredentials = json.decode(jsonString) as Map<String, dynamic>;
    _projectId = _cachedCredentials!['project_id'] as String?;
    return _cachedCredentials!;
  }

  Future<void> init() async {
    final fcm = _fcm;
    if (fcm == null) {
      debugPrint(
        'Push notifications are not supported or Firebase is not initialized on this platform.',
      );
      return;
    }

    try {
      // Pre-load the service account credentials so they are cached early.
      await _loadServiceAccountCredentials();

      // Request permission for push notifications
      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'User granted notification permission: ${settings.authorizationStatus}',
      );

      // Initialize flutter_local_notifications for Android foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      // Ensure the channel exists via the plugin as well
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Enable foreground presentation options (for iOS)
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground notifications and display them as system notifications
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      // Subscribe to a topic
      await fcm.subscribeToTopic('workshop_updates');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<String?> getDeviceToken() async {
    final fcm = _fcm;
    if (fcm == null) return null;
    try {
      return await fcm.getToken();
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return null;
    }
  }

  /// Displays a foreground FCM message as a visible system notification on Android.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('FCM: Showing foreground notification: ${notification.title} - ${notification.body}');

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Saves the current device's FCM token to the user's Firestore document.
  /// Call this after login so admin tokens can be looked up later.
  Future<void> saveUserToken(String userId) async {
    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('FCM saveUserToken: Firestore not available.');
      return;
    }

    final token = await getDeviceToken();
    if (token == null) {
      debugPrint('FCM saveUserToken: Device token is null.');
      return;
    }

    try {
      await firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      debugPrint('FCM saveUserToken: FCM token successfully saved for user $userId (Token: $token)');
    } catch (e) {
      // If document exists but update fails, try set with merge
      try {
        await firestore.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        debugPrint('FCM saveUserToken: FCM token successfully merged/saved for user $userId (Token: $token)');
      } catch (err) {
        debugPrint('FCM saveUserToken: Error saving FCM token: $err');
      }
    }
  }

  /// Sends a push notification to every user with role == 'admin'.
  /// Looks up admin FCM tokens from Firestore and sends individually.
  Future<void> notifyAdmins({
    required String title,
    required String body,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('Cannot notify admins: Firestore is not available.');
      return;
    }

    try {
      debugPrint('FCM notifyAdmins: Fetching admin users from Firestore...');
      final snapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      debugPrint('FCM notifyAdmins: Found ${snapshot.docs.length} admin document(s).');
      int sentCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown Admin';
        final adminToken = data['fcmToken'] as String?;
        debugPrint('FCM notifyAdmins: Admin "${name}" (UID: ${doc.id}) token: $adminToken');
        if (adminToken != null && adminToken.isNotEmpty) {
          sentCount++;
          await sendFcmNotification(
            title: title,
            body: body,
            token: adminToken,
          );
        } else {
          debugPrint('FCM notifyAdmins: Admin "${name}" has no FCM token saved.');
        }
      }

      // Save to notification history
      await firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'target': 'admins',
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM notifyAdmins: Finished notifying admins. Sent to $sentCount admins.');
    } catch (e) {
      debugPrint('FCM notifyAdmins: Error: $e');
    }
  }

  /// Sends a push notification to all users subscribed to the 'workshop_updates' topic.
  Future<void> notifyAllUsers({
    required String title,
    required String body,
  }) async {
    final firestore = _firestore;
    try {
      debugPrint('FCM notifyAllUsers: Sending topic-based notification to all users...');
      await sendFcmNotification(
        title: title,
        body: body,
        topic: 'workshop_updates',
      );

      // Save to notification history if firestore is available
      if (firestore != null) {
        await firestore.collection('notifications').add({
          'title': title,
          'body': body,
          'target': 'all_users',
          'status': 'sent',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('FCM notifyAllUsers: Finished sending notification to all users.');
    } catch (e) {
      debugPrint('FCM notifyAllUsers: Error: $e');
    }
  }

  /// Obtains a short-lived OAuth2 access token using the service account.
  Future<String> _getAccessToken() async {
    final credentials = await _loadServiceAccountCredentials();
    final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    try {
      return client.credentials.accessToken.data;
    } finally {
      client.close();
    }
  }

  /// Sends a push notification via the FCM HTTP V1 API.
  ///
  /// Either [token] (for a single device) or [topic] (for a topic broadcast)
  /// should be provided. If neither is given, defaults to the
  /// `workshop_updates` topic.
  Future<void> sendFcmNotification({
    required String title,
    required String body,
    String? topic,
    String? token,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final projectId = _projectId ?? 'workshop-manager-5f2f7';
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final Map<String, dynamic> message = <String, dynamic>{
        'notification': {'title': title, 'body': body},
        'android': {
          'notification': {
            'channel_id': 'high_importance_channel',
            'notification_priority': 'PRIORITY_HIGH',
            'sound': 'default'
          }
        }
      };

      if (token != null && token.isNotEmpty) {
        message['token'] = token;
      } else {
        message['topic'] = topic ?? 'workshop_updates';
      }

      final Map<String, dynamic> payload = {'message': message};

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM notification sent successfully via V1 API.');
      } else {
        debugPrint(
          'Failed to send FCM notification: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
    }
  }

}
