// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'track_order_screen.dart';
import 'home_screen.dart';

class OrderPlacedScreen extends StatelessWidget {
  final String tokenNumber;
  final String orderId;
  final String paymentType;
  final int itemCount;
  final num totalPaid;
  final List<Map<String, dynamic>> orderItems;

  const OrderPlacedScreen({
    super.key,
    required this.tokenNumber,
    required this.orderId,
    required this.paymentType,
    required this.itemCount,
    required this.totalPaid,
    required this.orderItems,
  });

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The specific elegant light green color
    final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goToHome(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD), // Clean white background
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Success Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryLightGreen.withOpacity(0.2), // Soft pastel green
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryLightGreen.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600, // Elegant green icon
                          size: 60,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Order Placed Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600, // Removed heavy bold
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your food is being prepared.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 35),

                  // TOKEN NUMBER BOX
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: primaryLightGreen.withOpacity(0.15), // Very light background
                      borderRadius: BorderRadius.circular(16),
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
                        Text(
                          'TOKEN NUMBER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tokenNumber,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w600, // Removed heavy w900
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ORDER DETAILS BOX
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3)
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600, // Semi-bold
                            color: Colors.black87,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Colors.black12),
                        ),

                        // Formats string correctly if order ID starts with ORDER_
                        _buildDetailRow(
                            'Order ID',
                            orderId.startsWith("ORDER_")
                                ? '#${orderId.substring(6, 12)}'
                                : orderId),
                        const SizedBox(height: 12),
                        _buildDetailRow('Total Items', '$itemCount'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Payment Mode', paymentType),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        _buildDetailRow(
                          'Amount Paid',
                          '₹${totalPaid.toStringAsFixed(0)}', 
                          isBold: true,
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // INFO SECTIONS
                  _buildInfoSection(
                    icon: Icons.notifications_active_outlined,
                    title: 'Stay Tuned!',
                    description:
                        'You will receive a notification when your order is Ready.',
                  ),

                  const SizedBox(height: 35),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrackOrderScreen(
                                  orderId: orderId,
                                  tokenNumber: tokenNumber,
                                  totalAmount: totalPaid,
                                  paymentType: paymentType,
                                  orderItems: orderItems,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.green.shade600, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Track Order',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _goToHome(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryLightGreen, // Pastel green
                            foregroundColor: Colors.black87, // Dark text for contrast
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Go Home',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14, 
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500, // Lighter weights
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.orange.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, // Semi-bold
                  color: Colors.black87
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}