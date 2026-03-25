import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reset_pass_screen1.dart'; // Ensure this import matches your file structure

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  bool _isGmailValid = false;
  bool _isLoading = false; // Added to show spinner
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- 1. Validation Logic ---
  void _validateEmail(String value) {
    if (value.isEmpty) {
      _errorText = 'Email is required';
      _isGmailValid = false;
    } else if (!value.trim().endsWith('@gmail.com')) {
      // Added trim() for safety
      _errorText = 'Please enter a valid Gmail address';
      _isGmailValid = false;
    } else {
      _errorText = null;
      _isGmailValid = true;
    }
    setState(() {});
  }

  // --- 2. Backend Connection Logic ---
  Future<void> _handleSendResetPassword() async {
    if (!_isGmailValid) return;

    setState(() => _isLoading = true); // Start loading

    try {
      // Send Firebase Reset Email
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        // Success: Navigate to the Success Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResetPassScreen1()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Errors
      String message = "An error occurred";
      if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Stop loading
    }
  }

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Image Asset (Make sure this exists in your pubspec.yaml)
                Image.asset(
                  'assets/forgot_pass.jpg',
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lock_reset,
                      size: 100,
                      color: Color(0xFFB8E6D5)),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Enter your user account\'s verified\nemail address and we will send you\na password reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, height: 1.6, color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 32),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),

                const SizedBox(height: 8),

                // EMAIL FIELD
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  enabled: !_isLoading, // Disable input while loading
                  decoration: InputDecoration(
                    hintText: 'Your Gmail address',
                    errorText: _errorText,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Only Gmail accounts are supported.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isGmailValid && !_isLoading)
                        ? _handleSendResetPassword
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8E6D5),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      disabledBackgroundColor:
                          // ignore: deprecated_member_use
                          const Color(0xFFB8E6D5).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
