// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'make_payment_screen.dart';
import 'cart_manager.dart';
import 'package:intl/intl.dart';

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
  int _prepTime = 5; // Added to store calculated time locally
  
  bool isTokenGenerated = false;
  bool _isGenerating = false;
  bool _isProceeding = false; // Added to show loading on Proceed button

  // Elegant pastel theme colors
  final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);
  final Color darkGreenText = const Color(0xFF1B5E20);

  // --- 1. CALCULATE TIME LOCALLY ---
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
          var maxTimeStr = data['time_max'] ?? '5';
          int itemTime = int.tryParse(maxTimeStr.toString()) ?? 5;

          items[i]['prep_time'] = itemTime;
          totalMinutes += (itemTime * qty);
        } else {
          totalMinutes += (5 * qty);
        }
      } catch (e) {
        totalMinutes += (5 * qty);
      }
    }

    return totalMinutes == 0 ? 2 : totalMinutes;
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
          SetOptions(merge: true));

      return "T-${nextNumber.toString().padLeft(2, '0')}";
    });
  }

  // --- 2. GENERATE TOKEN ONLY (DOES NOT PLACE ORDER YET) ---
  Future<void> _generateTokenOnly() async {
    setState(() => _isGenerating = true);
    try {
      String newOrderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";
      String newToken = await getNextTokenNumber();
      int pTime = await _calculateRealPrepTime(widget.orderItems);

      setState(() {
        tokenNumber = newToken;
        orderId = newOrderId;
        _prepTime = pTime; // Store time locally
        isTokenGenerated = true;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 3. PROCEED & PLACE ORDER IN DATABASE ---
  Future<void> _placeOrderAndProceed() async {
    setState(() => _isProceeding = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      // NOW we place the order in Firebase because the user clicked Proceed
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set({
        'orderId': orderId,
        'tokenNumber': tokenNumber,
        'userId': user?.uid ?? 'guest',
        'userName': user?.displayName ?? 'Student',
        'items': widget.orderItems,
        'totalAmount': widget.amount,
        'paymentMethod': 'Pay on Counter',
        'status': 'Pending Payment', // Waiting for admin to confirm cash
        'totalPrepTime': _prepTime,
        'timestamp': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'feedbackGiven': false,
        'overdue': false,
      });

      // Notify Admin
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'New Cash Order',
        'message': 'Token $tokenNumber: New cash order waiting for payment confirmation.',
        'type': 'new_order',
        'orderId': orderId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => _isProceeding = false);

      if (mounted) {
        // Go to MakePaymentScreen (Waiting screen)
        Navigator.pushReplacement(
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
      }
    } catch (e) {
      setState(() => _isProceeding = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 4. CANCEL ORDER LOGIC (No DB deletion needed anymore!) ---
  void _cancelAndGoBack() {
    // Because the order wasn't placed in DB yet, we just pop!
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Clean white background
      appBar: AppBar(
        title: const Text("Pay on Counter",
            style: TextStyle(
                color: Colors.black87, 
                fontSize: 18,
                fontWeight: FontWeight.w600)), // Reduced bold
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Step 1 of 2",
                  style: TextStyle(
                      color: Colors.grey, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w500)), // Lightened
              const SizedBox(height: 24),

              // --- STATE A: TOKEN GENERATED ---
              if (isTokenGenerated) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
                  decoration: BoxDecoration(
                    color: primaryLightGreen.withOpacity(0.15), // Soft pastel background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryLightGreen.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "TOKEN NUMBER",
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600, // Semi-bold instead of heavy bold
                            fontSize: 12,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tokenNumber!,
                        style: TextStyle(
                            fontSize: 36, // Reduced from 48
                            fontWeight: FontWeight.w500, // Reduced from w900
                            color: darkGreenText),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Colors.black12, height: 1),
                      ),
                      Text(
                        "Pay ₹${widget.amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 20, // Reduced from 24
                            fontWeight: FontWeight.w600, // Reduced bold
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "Token generated! Show this to the cashier.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 35),

                // --- PROCEED & CANCEL BUTTONS ---
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _cancelAndGoBack,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade300, width: 1.2), // Softer red
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Cancel",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w500)), // Reduced bold
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // Proceed Button (PLACES ORDER)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isProceeding ? null : _placeOrderAndProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryLightGreen, // Pastel green theme
                            foregroundColor: Colors.black87, // Dark text
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0, // Flat design
                          ),
                          child: _isProceeding
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                              : const Text("Proceed",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ],
                )
              ]
              // --- STATE B: INITIAL STATE ---
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryLightGreen.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4)
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryLightGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.confirmation_number_outlined,
                            size: 40, color: Colors.green.shade700), // Elegant icon
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Generate Token",
                        style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600, // Reduced bold
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Click below to generate your token.\nShow it to the cashier to pay ₹${widget.amount.toStringAsFixed(0)}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50), 

                // Generate Token Button (DOES NOT PLACE ORDER)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isGenerating ? null : _generateTokenOnly,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryLightGreen, // Pastel green theme
                      foregroundColor: Colors.black87, // Dark text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                        : const Text("Generate Token",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
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