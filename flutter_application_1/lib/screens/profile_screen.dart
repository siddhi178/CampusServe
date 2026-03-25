import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';
import 'order_history_screen.dart';
import 'profile_info_screen.dart';
import 'wallet_screen.dart';
import 'report_problem_screen.dart';
import 'help_support_screen.dart';
import 'terms_conditions_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- PROFILE CARD WITH SAFE DATA CHECKS ---
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String userName = "Student";
                String userEmail = currentUser?.email ?? "No Email";

                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  // Safe extraction of name
                  userName = data.containsKey('name') ? data['name'] : "Student";
                }

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileInformationScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFA5D6A7),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(userEmail, style: TextStyle(fontSize: 13, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.receipt_long, title: 'Order History', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()))),
            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.account_balance_wallet, title: 'My Wallet', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()))),
            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.settings, title: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.report_problem, title: 'Report Problem', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportProblemScreen()))),
            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.help_outline, title: 'Help and Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()))),
            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.description, title: 'Terms and Conditions', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsScreen()))),
            const SizedBox(height: 16),
            _buildMenuCard(context, icon: Icons.logout, title: 'Log out', onTap: () => _showLogoutDialog(context)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); _handleLogout(context); }, child: const Text("Log Out", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.green[700], size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87))),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
          ],
        ),
      ),
    );
  }
}