// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SEND NOTIFICATION (Used by User Actions like Order/Wallet) ---
  static Future<void> sendNotification({
    required String title,
    required String message,
    required String type, // 'order', 'wallet', 'alert', 'general'
    required String targetId, // orderId, transactionId, etc.
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('user_notifications').add({
        'userId': user.uid,
        'title': title,
        'message': message,
        'type': type,
        'targetId': targetId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  // --- GET NOTIFICATIONS STREAM (Combined Personal + General) ---
  // This logic is usually handled in the UI (StreamBuilder), but this helper prepares the query.
  // Since Firestore doesn't support "OR" queries across fields easily, we usually fetch
  // user-specific ones. For "General" (All Users), we need a separate query or duplicate them.
  //
  // STRATEGY: The Admin Panel writes to 'notifications' (General).
  // User Actions write to 'user_notifications' (Personal).
  // We will display BOTH in the Notification Screen.
}
