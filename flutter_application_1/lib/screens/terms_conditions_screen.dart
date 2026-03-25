import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSection(
              '1. Introduction',
              'By using CampusServe, you agree to follow all rules and policies mentioned below. These Terms apply to all users of the application.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '2. User Responsibilities',
              'You must: provide correct information, use the app safely, and avoid sharing harmful or illegal content.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '3. Account Security',
              'You are responsible for keeping your login details safe. Any activity on your account will be considered your action.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '4. Payments (If any)',
              'All payments made for services or products are final unless stated otherwise by the service provider.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '5. Prohibited Actions',
              'You must not: impersonate others, send harmful files, scam, threaten, or misuse any feature of the platform.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '6. Content Rights',
              'All app content is protected. You may not copy, resell, or distribute any part of the platform.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '7. Privacy Protection',
              'We collect only necessary information and keep it secure. Your data is not shared or sold to third parties.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '8. Account Termination',
              'We may stop your access if you break any rules. You may request account deletion at any time.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '9. Limitation of Liability',
              'We are not responsible for any loss, misuse, or damage caused by inappropriate use of the app.',
            ),
            const SizedBox(height: 20),
            _buildTermSection(
              '10. Updates to Terms',
              'We may revise these Terms when needed. Continued use of the app means you accept changes.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }
}
