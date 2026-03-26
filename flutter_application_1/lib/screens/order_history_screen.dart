// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/invoice_service.dart';
import 'cart_manager.dart';
import 'cart_screen.dart';
import 'track_order_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final CartManager _cartManager = CartManager();
  String? _expandedOrderId;

  void _handleReOrder(List<dynamic> items) {
    _cartManager.clearCart();
    for (var item in items) {
      String title = item['title'] ?? item['name'] ?? 'Unknown Item';
      String subtitle = item['subtitle'] ?? item['description'] ?? '';

      // FIX FOR DOUBLE RUPEE SYMBOL
      String priceStr = item['price'].toString().replaceAll('₹', '').trim();

      String imagePath =
          item['imagePath'] ?? item['image'] ?? item['image_url'] ?? '';
      int pTime = item['prepTime'] ?? item['prep_time'] ?? 10;

      String cat = item['category'] ?? 'General';
      String subCat = item['sub_category'] ?? item['subCategory'] ?? 'General';

      _cartManager.addItem(
        title,
        subtitle,
        "₹$priceStr", // Add it cleanly once
        imagePath,
        cat,
        subCat,
        prepTime: pTime,
      );
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CartScreen(newItem: {})));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Order History",
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 16)), // Smaller title
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black87, size: 18),
            onPressed: () => Navigator.pop(context)),
      ),
      body: user == null
          ? const Center(child: Text("Please login to view history"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState("No orders found");
                }

                var allOrders = snapshot.data!.docs;

                allOrders.sort((a, b) {
                  Timestamp t1 =
                      (a.data() as Map<String, dynamic>)['timestamp'] ??
                          Timestamp.now();
                  Timestamp t2 =
                      (b.data() as Map<String, dynamic>)['timestamp'] ??
                          Timestamp.now();
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: allOrders.length,
                  itemBuilder: (context, index) {
                    var data = allOrders[index].data() as Map<String, dynamic>;
                    return _buildOrderCard(data, allOrders[index].id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildTimelineRow(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700))), // Smaller text
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data, String docId) {
    String status = data['status'] ?? 'Unknown';
    String token = data['tokenNumber'] ?? '#';
    String orderId = data['orderId'] ?? '---';
    if (orderId.length > 8) orderId = "#${orderId.substring(6, 12)}";

    double total = (data['totalAmount'] ?? 0).toDouble();
    Timestamp? ts = data['timestamp'];
    String dateStr =
        ts != null ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) : '';
    List items = data['items'] ?? [];

    bool isOngoing = status == 'Preparing' ||
        status == 'Ready' ||
        status == 'Rescheduled' ||
        status == 'Pending Payment';

    bool isExpanded = _expandedOrderId == docId;

    Color chipBgColor = Colors.grey.shade100;
    Color chipTextColor = Colors.grey.shade700;

    if (status == 'Completed') {
      chipBgColor = Colors.green.shade50;
      chipTextColor = Colors.green.shade700;
    } else if (status.contains('Refund') || status.contains('Disputed')) {
      chipBgColor = Colors.orange.shade50;
      chipTextColor = Colors.orange.shade900;
    } else if (status == 'Cancelled') {
      chipBgColor = Colors.red.shade50;
      chipTextColor = Colors.red.shade700;
    } else if (status == 'Rescheduled') {
      chipBgColor = Colors.blue.shade50;
      chipTextColor = Colors.blue.shade700;
    } else if (status == 'Preparing') {
      chipBgColor = Colors.orange.shade50;
      chipTextColor = Colors.orange.shade800;
    }

    List<dynamic> reschHistory = data['rescheduleHistory'] ?? [];
    List<dynamic> extHistory = data['extensionHistory'] ?? [];
    List<dynamic> activityLogs = data['activityLogs'] ?? [];

    // FIX: Explicitly ensure the timeline is visible if it's cancelled/refunded so the user sees the logs
    bool hasTimeline = reschHistory.isNotEmpty ||
        extHistory.isNotEmpty ||
        activityLogs.isNotEmpty ||
        status.contains('Refund') ||
        status.contains('Cancelled');

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedOrderId == docId) {
            _expandedOrderId = null;
          } else {
            _expandedOrderId = docId;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1B5E20).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text("Token $token",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1B5E20),
                                    fontSize: 11)), // Smaller
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Order $orderId",
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 10)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status.toUpperCase(),
                            style: TextStyle(
                                color: chipTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9, // Smaller status
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 6),
                      Text(dateStr,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Colors.black12),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((item) {
                    // Clean up the price display here too
                    String cleanPrice =
                        item['price'].toString().replaceAll('₹', '').trim();

                    return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text("${item['quantity']}x",
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text("${item['title'] ?? item['name']}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                        fontWeight: FontWeight
                                            .w500)), // Smaller item name
                              ),
                              Text("₹$cleanPrice",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w800))
                            ]));
                  }),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Bill",
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600)),
                      Text("₹${total.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Colors.black87)), // Smaller Total
                    ],
                  ),

                  // TIMELINE
                  if (hasTimeline) ...[
                    const SizedBox(height: 8),
                    AnimatedCrossFade(
                      firstChild: Center(
                          child: Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey.shade300, size: 20)),
                      secondChild: Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Activity Log",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.black45)),
                            const SizedBox(height: 10),
                            ...reschHistory.map((r) => _buildTimelineRow(
                                "Rescheduled: $r",
                                Icons.calendar_month,
                                Colors.blue)),
                            ...extHistory.map((e) => _buildTimelineRow(
                                "Extended: $e",
                                Icons.more_time,
                                Colors.purple)),
                            ...activityLogs.map((log) => _buildTimelineRow(
                                log.toString(),
                                Icons.info_outline,
                                Colors.orange.shade700)),
                            if (status.contains('Refund') ||
                                status.contains('Cancelled'))
                              _buildTimelineRow(
                                  "Status: $status",
                                  Icons.account_balance_wallet,
                                  Colors.red.shade700),
                            const SizedBox(height: 5),
                            Center(
                                child: Icon(Icons.keyboard_arrow_up,
                                    color: Colors.grey.shade300, size: 20)),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],

                  const SizedBox(height: 15),

                  if (isOngoing)
                    SizedBox(
                      width: double.infinity,
                      height: 40, // Smaller button
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TrackOrderScreen(
                                      orderId: docId,
                                      tokenNumber: token,
                                      totalAmount: total.toInt(),
                                      paymentType: data['paymentMethod'] ?? '',
                                      orderItems:
                                          List<Map<String, dynamic>>.from(
                                              items),
                                    )),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text("Track Order",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () =>
                                  InvoiceService.generateAndOpenInvoice(data),
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: const Text("Invoice",
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => _handleReOrder(items),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE7F3EB),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: const Text("Re-Order",
                                  style: TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.shade300),
      const SizedBox(height: 15),
      Text(message,
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w600))
    ]));
  }
}
