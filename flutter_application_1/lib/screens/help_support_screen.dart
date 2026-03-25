// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF9FAFB), // Slightly grey background for contrast

      // TOP BAR ---------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),

      // MAIN BODY ------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. CONTACT & SUPPORT --------------------------------
            _sectionCard(
              title: "1. Contact and Support",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone,
                            size: 20, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Call Us",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "For urgent issues",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.only(left: 44),
                    child: Text(
                      "+91 12345 67890",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. EMAIL SUPPORT -------------------------------------
            _sectionCard(
              title: "2. Email Support",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.email,
                            size: 20, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Email Us",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "For feedback & queries",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.only(left: 44),
                    child: Text(
                      "support@campusserve.com",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. FAQ SECTION ---------------------------------------
            _sectionCard(
              title: "3. Frequently Asked Questions",
              child: Column(
                children: [
                  _faqItem("1. When will my order be ready?",
                      "Most orders take 5-10 minutes, depending on the crowd."),
                  _faqItem("2. Where do I pick up my order?",
                      'Collect your order from the canteen counter when the app shows "Ready for Pickup".'),
                  _faqItem("3. Can I cancel my order?",
                      "Orders cannot be cancelled once they are prepared."),
                  _faqItem("4. What if my payment fails?",
                      "If UPI fails, no money is deducted. Try again after a few minutes."),
                  _faqItem("5. Do you accept cash?",
                      "Yes, you can choose 'Pay at Counter' during checkout."),
                  _faqItem("6. How do I report a wrong item?",
                      "Please contact the canteen staff immediately at the counter."),
                  _faqItem("7. Is non-veg available?",
                      "No, the canteen serves veg-only items."),
                  _faqItem("8. Why is an item unavailable?",
                      "Sometimes items go out of stock due to high demand."),
                  _faqItem("9. Can I change my number?",
                      "Currently, profile updates are restricted for security."),
                  _faqItem("10. Do I need a token?",
                      "Yes, show your digital token number at the counter.",
                      isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
          child,
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
                fontSize: 13, height: 1.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
