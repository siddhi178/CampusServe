import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletManager extends ChangeNotifier {
  static final WalletManager _instance = WalletManager._internal();
  factory WalletManager() => _instance;
  WalletManager._internal();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Stream for balance updates
  Stream<DocumentSnapshot> get walletStream {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .snapshots();
  }

  // --- ADD MONEY (Corrected Name Fetching) ---
  Future<void> addMoney(double amount, String paymentId, String method) async {
    if (currentUser == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    final txnRef = FirebaseFirestore.instance.collection('transactions').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);

      double currentBal = 0.0;
      String userName = 'Student'; // Default

      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        currentBal = (data['wallet_balance'] ?? 0).toDouble();

        // --- FETCH REAL NAME ---
        if (data.containsKey('name')) {
          userName = data['name'];
        }
      } else {
        // If user doc doesn't exist, create it (safe fallback)
        transaction.set(userRef, {'wallet_balance': 0.0, 'name': 'Student'});
      }

      transaction.update(userRef, {'wallet_balance': currentBal + amount});

      transaction.set(txnRef, {
        'transactionId': paymentId,
        'userId': currentUser!.uid,
        'userName': userName, // SAVES REAL NAME
        'amount': amount,
        'type': 'Credit',
        'method': method,
        'status': 'Success',
        'description': 'Wallet Top-up',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
    notifyListeners();
  }

  // --- PROCESS PAYMENT (Corrected Name Fetching) ---
  Future<bool> processPayment(double totalBill) async {
    if (currentUser == null) return false;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    final txnRef = FirebaseFirestore.instance.collection('transactions').doc();

    try {
      final result = await FirebaseFirestore.instance
          .runTransaction<bool>((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return false;

        var data = snapshot.data() as Map<String, dynamic>;
        double currentBal = (data['wallet_balance'] ?? 0.0).toDouble();

        // --- FETCH REAL NAME ---
        String userName = data['name'] ?? 'Student';

        if (currentBal >= totalBill) {
          transaction
              .update(userRef, {'wallet_balance': currentBal - totalBill});

          transaction.set(txnRef, {
            'transactionId': "TXN_${DateTime.now().millisecondsSinceEpoch}",
            'userId': currentUser!.uid,
            'userName': userName, // SAVES REAL NAME
            'amount': totalBill,
            'type': 'Debit',
            'method': 'Wallet',
            'status': 'Success',
            'description': 'Order Payment',
            'timestamp': FieldValue.serverTimestamp(),
          });
          return true;
        }
        return false;
      });
      return result;
    } catch (e) {
      debugPrint("Payment Logic Error: $e");
      return false;
    }
  }
}
