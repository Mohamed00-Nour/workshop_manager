import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission for push notifications
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted notification permission: ${settings.authorizationStatus}');

    // Subscribe to a topic (e.g. "workshop_updates" so everyone gets notifications)
    await _fcm.subscribeToTopic('workshop_updates');
  }

  Future<String?> getDeviceToken() async {
    return await _fcm.getToken();
  }

  // Best Practice: Instead of using service account directly inside the app,
  // we trigger the notification by writing a document to a Firestore 'notifications' collection.
  // The secure backend script will listen to this collection and send the notification.
  Future<void> triggerNotification({
    required String title,
    required String body,
    String? topic,
    String? token,
  }) async {
    try {
      await _firestore.collection('notifications').add({
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
