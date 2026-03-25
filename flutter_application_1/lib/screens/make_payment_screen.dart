// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_placed_screen.dart';

class MakePaymentScreen extends StatefulWidget {
  final String orderId;
  final String tokenNumber;
  final double amount;
  final List<Map<String, dynamic>> orderItems;

  const MakePaymentScreen({
    super.key,
    required this.orderId,
    required this.tokenNumber,
    required this.amount,
    required this.orderItems,
  });

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Awaiting Confirmation",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("Order Error."));
          }

          String status = data['status'] ?? 'Pending Payment';

          // --- AUTO NAVIGATION TRIGGER ---
          // Once the admin clicks "Confirm" in the HTML panel, it sets status to Preparing.
          // This jumps the user to the OrderPlacedScreen automatically.
          if (status != 'Pending Payment') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderPlacedScreen(
                    tokenNumber: widget.tokenNumber,
                    orderId: widget.orderId,
                    paymentType: "Pay on Counter",
                    itemCount: widget.orderItems.length,
                    totalPaid: widget.amount,
                    orderItems: widget.orderItems,
                  ),
                ),
                (route) => false,
              );
            });
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: Colors.orange, strokeWidth: 6),
                  const SizedBox(height: 40),
                  const Text("Waiting for Admin...",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                      "Please pay ₹${widget.amount.toStringAsFixed(0)} to the cashier to confirm your order.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Order Status:",
                            style: TextStyle(fontSize: 16)),
                        Text(status,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
