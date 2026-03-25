import 'package:flutter/material.dart';
import 'login_screen.dart'; // We will link Login button here
import 'signup_screen.dart'; // We will link Sign Up button here

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 550,
              width: double.infinity,
              child: Image.asset(
                'assets/auth.jpg', // Replace with your specific image file name
                fit: BoxFit.contain, // Ensures the image fits nicely
              ),
            ),

            const SizedBox(height: 40),

            const Spacer(),

            // --- LOGIN BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Login Screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: _buttonStyle(),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- SIGN UP BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Sign Up (Using Placeholder for now)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  style: _buttonStyle(),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Helper for Button Style (Shared style for both buttons)
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFB9E4C9), // Light Green
      foregroundColor: Colors.black, // Text Color
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
    );
  }
}

// --- PLACEHOLDER FOR SIGNUP PAGE ---
class SignupScreenPlaceholder extends StatelessWidget {
  const SignupScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: const Center(child: Text("Sign Up Page Coming Soon!")),
    );
  }
}

// ===============================================
// CUSTOM ILLUSTRATION WIDGET (Hands & Phone)
// ===============================================
class CustomAuthIllustration extends StatelessWidget {
  const CustomAuthIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. BACKGROUND SHELVES (Abstract)
        Positioned(
          top: 100,
          child: Container(
            height: 200,
            width: 320,
            decoration: BoxDecoration(
              color: Colors.blueGrey[50], // Very light background
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShelfRow(),
                const SizedBox(height: 40),
                _buildShelfRow(),
              ],
            ),
          ),
        ),

        // 2. THE PHONE
        Container(
          height: 280,
          width: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF43A047), // Green Phone Screen
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              // Search Bar on Phone
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 15,
                // ignore: deprecated_member_use
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              // Food Icons Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(10),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildFoodItem(Icons.bakery_dining, Colors.orange),
                    _buildFoodItem(Icons.local_pizza, Colors.redAccent),
                    _buildFoodItem(Icons.icecream, Colors.pinkAccent),
                    _buildFoodItem(Icons.coffee, Colors.brown),
                  ],
                ),
              ),
              // "Place Order" Button
              Container(
                margin: const EdgeInsets.all(15),
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    "PLACE ORDER",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. HANDS (Simplified geometric shapes)
        // Left Hand
        Positioned(
          left: 40,
          bottom: 20,
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              height: 120,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE6A07E), // Skin Tone
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ),
        // Right Hand
        Positioned(
          right: 40,
          bottom: 20,
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              height: 120,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE6A07E), // Skin Tone
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ),

        // Sleeves (Green suit)
        Positioned(left: 0, bottom: 0, child: _buildSleeve(true)),
        Positioned(right: 0, bottom: 0, child: _buildSleeve(false)),

        // 4. SPEECH BUBBLE
        Positioned(
          top: 30,
          left: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFA5D6A7), // Light Green
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[800]!),
            ),
            child: const Text(
              "Skip the Line!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(width: 30, height: 40, color: Colors.orange[200]),
        Container(width: 30, height: 40, color: Colors.red[200]),
        Container(width: 30, height: 40, color: Colors.yellow[200]),
        Container(width: 30, height: 40, color: Colors.purple[200]),
      ],
    );
  }

  Widget _buildFoodItem(IconData icon, Color color) {
    return Container(
      // ignore: deprecated_member_use
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildSleeve(bool isLeft) {
    return Transform.rotate(
      angle: isLeft ? -0.5 : 0.5,
      child: Container(
        height: 80,
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF66BB6A), // Suit Green
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
