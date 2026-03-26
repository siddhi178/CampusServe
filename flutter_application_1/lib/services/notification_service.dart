// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- INITIALIZE LOCAL NOTIFICATIONS (Call this in main.dart) ---
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Make sure you have an app icon

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  // --- PLAY SOUND & SHOW BANNER ON PHONE ---
  static Future<void> _showLocalNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'campus_serve_channel', // channel Id
      'Campus Serve Notifications', // channel Name
      channelDescription: 'Notifications for order updates and alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // THIS PLAYS THE SOUND
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecond, // Random ID
      title,
      message,
      platformDetails,
    );
  }

  // --- SEND NOTIFICATION TO DB & TRIGGER SOUND ---
  static Future<void> sendNotification({
    required String title,
    required String message,
    required String type, // 'order', 'wallet', 'alert', 'general'
    required String targetId, // orderId, transactionId, etc.
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Save to Database
      await _db.collection('user_notifications').add({
        'userId': user.uid,
        'title': title,
        'message': message,
        'type': type,
        'targetId': targetId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Trigger the phone to ring/buzz and show banner
      await _showLocalNotification(title, message);
      
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}