import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

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

  Future<void> init() async {
    final fcm = _fcm;
    if (fcm == null) {
      print('Push notifications are not supported or Firebase is not initialized on this platform.');
      return;
    }

    try {
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

      print('User granted notification permission: ${settings.authorizationStatus}');

      // Subscribe to a topic
      await fcm.subscribeToTopic('workshop_updates');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<String?> getDeviceToken() async {
    final fcm = _fcm;
    if (fcm == null) return null;
    try {
      return await fcm.getToken();
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  Future<void> triggerNotification({
    required String title,
    required String body,
    String? topic,
    String? token,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      print('Skipping notification trigger: Firestore is not available.');
      return;
    }

    try {
      await firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'topic': topic ?? 'workshop_updates',
        'token': token,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error triggering notification: $e');
    }
  }
}
