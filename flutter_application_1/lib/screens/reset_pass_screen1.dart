// reset_pass_screen1.dart
import 'package:flutter/material.dart';
import 'login_screen.dart'; // make sure this file exists

class ResetPassScreen1 extends StatelessWidget {
  const ResetPassScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.07, // responsive padding
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---------------- IMAGE ----------------
                SizedBox(
                  height: screenHeight * 0.50,
                  child: Image.asset(
                    'assets/reset_pass1.jpg', // <-- your asset
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // ---------------- TITLE ----------------
                const Text(
                  "Reset Your Password",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.02),

                // ---------------- SUB TEXT ----------------
                const Text(
                  "Check your email for a link to reset your password. "
                  "If it doesn’t appear within a few minutes, check your spam folder.",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.05),

                // ---------------- BUTTON ----------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6F5D6), // Light green
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Return to sign in",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
