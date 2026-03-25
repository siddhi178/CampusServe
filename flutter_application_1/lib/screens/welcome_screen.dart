import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    // --- FIXED LOGIC ---
    // Wait for 3 seconds, then go to Home Screen
    Timer(const Duration(seconds: 3), () {
      // Check if the widget is still on screen before navigating
      if (mounted) {
        // Using pushAndRemoveUntil to clear the back stack
        // This prevents going back to Login/Welcome screen on back press
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) =>
              false, // This predicate removes all previous routes
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // --- 1. HEADER TEXT ---
              const Text(
                "Welcome to Our Smart\nCanteen!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),

              const Spacer(),

              // --- 2. CENTRAL ILLUSTRATION ---
              SizedBox(
                height: 350,
                width: double.infinity,
                child: Image.asset(
                  'assets/welcome.jpg', // Replace with your specific image file name
                  fit: BoxFit.contain, // Ensures the image fits nicely
                ),
              ),

              const Spacer(),

              // --- 3. FOOTER TEXT ---
              const Text(
                "We’re happy to serve you a smooth\nand hassle-free ordering experience.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM ILLUSTRATION WIDGET
// ==========================================
class CustomWelcomeIllustration extends StatelessWidget {
  const CustomWelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Big Circular Background
        Container(
          height: 320,
          width: 320,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Light Grey
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // 2. Text Bubble
        Positioned(
          top: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5)
              ],
            ),
            child: const Column(
              children: [
                Text(
                  "Welcome!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Delicious food, no waiting",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  "Just Scan, Get Notified, and Enjoy!",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // 3. Left Box (Skip the Queue)
        Positioned(
          left: 20,
          top: 130,
          child: Container(
            height: 140,
            width: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2), // Light Orange
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Skip the Queue",
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Queue Icons
                Wrap(
                  spacing: 2,
                  runSpacing: 5,
                  children: List.generate(
                    6,
                    (index) => const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Red Arrow
        const Positioned(
          top: 180,
          child: Icon(Icons.arrow_forward, size: 40, color: Colors.redAccent),
        ),

        // 5. Right Box (Pickup Counter)
        Positioned(
          right: 20,
          top: 130,
          child: Container(
            height: 140,
            width: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9), // Light Green
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    "Pickup Counter",
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Chef & Customer
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face_3, size: 30, color: Colors.black87), // Chef
                    SizedBox(width: 5),
                    Icon(
                      Icons.fastfood,
                      size: 20,
                      color: Colors.orange,
                    ), // Food
                    SizedBox(width: 5),
                    Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blueGrey,
                    ), // Customer
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  height: 30,
                  width: 80,
                  color: Colors.orange[800],
                ), // Counter Table
              ],
            ),
          ),
        ),

        // 6. Get Started Button (Manual)
        Positioned(
          bottom: 40,
          child: ElevatedButton(
            onPressed: () {
              // Manual Navigation with mounting check
              if (context.mounted) {
                // Use pushAndRemoveUntil here as well for manual click
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5), // Blue
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "Get Started",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
