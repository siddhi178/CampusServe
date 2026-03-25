import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
          'About Us',
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
            // INTRODUCTION
            Text(
              'CampusServe is a digital platform created to simplify everyday campus activities for students. We bring together essential academic and campus services into one easy-to-use application.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // WHAT WE OFFER
            const Text(
              'What We Offer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Notes and study materials'),
            _buildBulletPoint('Book rentals and exchange'),
            _buildBulletPoint('Lost & found support'),
            _buildBulletPoint('Complaints and issue reporting'),
            _buildBulletPoint('Student marketplace'),
            _buildBulletPoint('Campus information & updates'),

            const SizedBox(height: 24),

            // OUR MISSION
            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To make student life easier by providing fast, accessible, and reliable digital services that save time and reduce stress.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // OUR VISION
            const Text(
              'Our Vision',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To become the most trusted platform for students by creating a connected and supportive campus environment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // WHY CHOOSE US
            const Text(
              'Why Choose Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Simple and user-friendly'),
            _buildBulletPoint('Secure and privacy-protected'),
            _buildBulletPoint('Quick issue resolution'),
            _buildBulletPoint('Built specially for students and their needs'),

            const SizedBox(height: 24),

            // CONTACT US
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Phone:  123456',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Email:  campusserve@gmail.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
