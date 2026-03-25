// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'make_payment_screen.dart';
import 'cart_manager.dart';
import 'package:intl/intl.dart'; // Add this for date formatting

class PayOnCounterScreen extends StatefulWidget {
  final double amount;
  final List<Map<String, dynamic>> orderItems;

  const PayOnCounterScreen({
    super.key,
    required this.amount,
    required this.orderItems,
  });

  @override
  State<PayOnCounterScreen> createState() => _PayOnCounterScreenState();
}

class _PayOnCounterScreenState extends State<PayOnCounterScreen> {
  String? tokenNumber;
  String? orderId;
  bool isTokenGenerated = false;
  bool _isGenerating = false;

  // --- 1. FIXED TIME CALCULATION (Fetch from DB) ---
  Future<int> _calculateRealPrepTime(List<Map<String, dynamic>> items) async {
    int totalMinutes = 0;

    for (var i = 0; i < items.length; i++) {
      String itemName = items[i]['title'] ?? items[i]['name'];
      int qty = items[i]['quantity'] ?? 1;

      try {
        var query = await FirebaseFirestore.instance
            .collection('menu')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          var data = query.docs.first.data();
          // Get time_max (e.g., "2"), default to 5
          var maxTimeStr = data['time_max'] ?? '5';
          int itemTime = int.tryParse(maxTimeStr.toString()) ?? 5;

          // IMPORTANT: Update item list with specific time for display later
          items[i]['prep_time'] = itemTime;

          totalMinutes += (itemTime * qty);
        } else {
          totalMinutes += (5 * qty);
        }
      } catch (e) {
        totalMinutes += (5 * qty);
      }
    }

    // REMOVED the < 15 check. Returns actual time (e.g. 2).
    return totalMinutes == 0 ? 2 : totalMinutes;
  }

  Future<void> _updateItemPopularity() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var item in widget.orderItems) {
        String itemName = item['title'] ?? item['name'];
        int quantity = item['quantity'] ?? 1;
        var query = await FirebaseFirestore.instance
            .collection('menu')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          var docRef = query.docs.first.reference;
          batch.update(docRef, {'order_count': FieldValue.increment(quantity)});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error updating popularity: $e");
    }
  }

  Future<String> getNextTokenNumber() async {
    DocumentReference counterRef =
        FirebaseFirestore.instance.collection('settings').doc('token_counter');

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);

      int nextNumber = 1;
      if (snapshot.exists) {
        int lastNumber = snapshot.get('lastTokenNumber') ?? 0;
        nextNumber = lastNumber + 1;
      }

      transaction.set(
          counterRef,
          {
            'lastTokenNumber': nextNumber,
          },
          SetOptions(merge: true)); // merge: true preserves other fields

      return "T-${nextNumber.toString().padLeft(2, '0')}";
    });
  }

// 3. Update the _generateTokenAndCreateOrder function
  Future<void> _generateTokenAndCreateOrder() async {
    setState(() => _isGenerating = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String newOrderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";
      // CALL THE FUNCTION HERE
      String newToken = await getNextTokenNumber();
      int prepTime = await _calculateRealPrepTime(widget.orderItems);
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(newOrderId)
          .set({
        'orderId': newOrderId,
        'tokenNumber': newToken, // Will now be T-01, T-02...
        'userId': user?.uid ?? 'guest',
        'userName': user?.displayName ?? 'Student',
        'items': widget.orderItems,
        'totalAmount': widget.amount,
        'paymentMethod': 'Pay on Counter',
        'status': 'Pending Payment',
        'totalPrepTime': prepTime,
        'timestamp': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'feedbackGiven': false,
        'overdue': false,
      });

      // ADMIN NOTIFICATION
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'New Cash Order',
        'message':
            'Token $newToken: New cash order waiting for payment confirmation.',
        'type': 'new_order',
        'orderId': newOrderId,
        'isRead': false,
        'timestamp':
            FieldValue.serverTimestamp(), // Field must be named 'timestamp'
      });

      // ... rest of your existing transaction logic ...
      setState(() {
        tokenNumber = newToken;
        orderId = newOrderId;
        isTokenGenerated = true;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 3. CANCEL ORDER LOGIC ---
  Future<void> _cancelAndGoBack() async {
    if (orderId != null) {
      // Delete the pending order so it doesn't stay in the system
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pay on Counter",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Step 1 of 2",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 20),

              // --- STATE A: TOKEN GENERATED ---
              if (isTokenGenerated) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "TOKEN NUMBER",
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        tokenNumber!,
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      const Divider(
                          color: Colors.orange,
                          thickness: 1,
                          indent: 40,
                          endIndent: 40),
                      const SizedBox(height: 10),
                      Text(
                        "Pay ₹${widget.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Token generated! Show this to the cashier.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // --- PROCEED & CANCEL BUTTONS ---
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton(
                          onPressed: _cancelAndGoBack,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancel",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Proceed Button
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MakePaymentScreen(
                                  orderId: orderId!,
                                  tokenNumber: tokenNumber!,
                                  amount: widget.amount,
                                  orderItems: widget.orderItems,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text("Proceed",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                )
              ]
              // --- STATE B: INITIAL STATE ---
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 60, color: Colors.green),
                      const SizedBox(height: 15),
                      const Text(
                        "Generate Token",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Click below to generate your token.\nShow it to the cashier to pay ₹${widget.amount.toStringAsFixed(2)}.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Spacer

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _isGenerating ? null : _generateTokenAndCreateOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA5D6A7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("Generate Token",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
