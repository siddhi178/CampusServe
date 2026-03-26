// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final String _razorpayKey = "rzp_test_S6uouPpSOvhOo6";
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  String _selectedFilter = 'All Time';
  DateTime? _customSelectedDate;

  // The specific elegant light green color requested
  final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);

  final List<String> _filterOptions = [
    'All Time',
    'Today',
    'This Month',
    'This Year',
    'Custom Date'
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _startAddMoney() {
    FocusScope.of(context).unfocus();
    double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount < 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter amount > ₹1")));
      return;
    }

    var options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'CampusServe',
      'description': 'Add Money to Wallet',
      'prefill': {
        'contact': '',
        'email': FirebaseAuth.instance.currentUser?.email ?? ''
      },
      'theme': {'color': '#A5D6A7'} // Matching your theme color
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _updateBackend(double.parse(_amountController.text.trim()),
        response.paymentId ?? "TXN_ID");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed: ${response.message}"),
        backgroundColor: Colors.red));
  }

  Future<void> _updateBackend(double amount, String txnId) async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(userRef);
        double currentBal = 0.0;

        if (snap.exists) {
          var data = snap.data() as Map<String, dynamic>;
          currentBal = data.containsKey('wallet_balance')
              ? (data['wallet_balance'] as num).toDouble()
              : 0.0;
        }

        transaction.set(userRef, {'wallet_balance': currentBal + amount},
            SetOptions(merge: true));

        transaction
            .set(FirebaseFirestore.instance.collection('transactions').doc(), {
          'userId': user.uid,
          'userName': user.displayName ?? 'Student',
          'amount': amount,
          'type': 'Credit',
          'method': 'Razorpay',
          'status': 'Success',
          'description': 'Added to Wallet',
          'timestamp': FieldValue.serverTimestamp()
        });
      });

      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Money Added Successfully!"),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFilterChange(String? newValue) async {
    if (newValue == 'Custom Date') {
      DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime.now());
      if (picked != null) {
        setState(() {
          _customSelectedDate = picked;
          _selectedFilter = newValue!;
        });
      }
    } else if (newValue != null) {
      setState(() => _selectedFilter = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Clean white background
      appBar: AppBar(
          title: const Text("My Wallet",
              style: TextStyle(
                  color: Colors.black87, 
                  fontSize: 18,
                  fontWeight: FontWeight.w600)), // Reduced bold
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          double balance = 0.0;
          if (snapshot.hasData && snapshot.data!.exists) {
            var d = snapshot.data!.data() as Map<String, dynamic>?;
            if (d != null && d.containsKey('wallet_balance')) {
              balance = (d['wallet_balance'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PREMIUM LIGHT BALANCE CARD ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryLightGreen.withOpacity(0.2), // Soft pastel background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryLightGreen.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Available Balance",
                          style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text("₹ ${balance.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.black87, // Dark elegant text
                              fontSize: 40,
                              fontWeight: FontWeight.w500)), // NOT BOLD
                    ],
                  ),
                ),
                
                const SizedBox(height: 35),
                
                // --- ADD MONEY SECTION ---
                const Text("Add Money",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 12),
                _buildAddMoneyField(),
                
                const SizedBox(height: 35),
                
                // --- TRANSACTIONS HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Transactions",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                    _buildFilterDropdown(),
                  ],
                ),
                
                const SizedBox(height: 15),
                _buildTransactionList(user?.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddMoneyField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5)),
      child: Row(
        children: [
          Expanded(
              child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      hintText: "0.00",
                      hintStyle: TextStyle(color: Colors.grey.shade400)))),
          SizedBox(
            height: 48,
            width: 80, // Giving the button a nice proportion
            child: ElevatedButton(
                onPressed: _isLoading ? null : _startAddMoney,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryLightGreen, // Beautiful pastel green
                    foregroundColor: Colors.black87, // Dark text for contrast
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                    : const Text("Add", style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
          items: _filterOptions
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e == 'Custom Date' && _customSelectedDate != null
                      ? DateFormat('dd MMM').format(_customSelectedDate!)
                      : e)))
              .toList(),
          onChanged: _handleFilterChange,
        ),
      ),
    );
  }

  // --- ELEGANT TRANSACTION LIST ---
  Widget _buildTransactionList(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryLightGreen));
        }
        var docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Text("No transactions yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            bool isCredit = d['type'] == 'Credit';
            
            // Format Timestamp
            String formattedDate = '';
            if (d['timestamp'] != null) {
               formattedDate = DateFormat('dd MMM, hh:mm a').format((d['timestamp'] as Timestamp).toDate());
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3)
                  )
                ]
              ),
              child: Row(
                children: [
                  // Icon Circle
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: isCredit ? primaryLightGreen.withOpacity(0.2) : Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? Colors.green.shade700 : Colors.red.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['description'] ?? 'Transaction',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500, // Reduced bold
                            color: Colors.black87
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.normal
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Text(
                    "${isCredit ? '+' : '-'} ₹${d['amount']}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600, // Semi-bold for clarity
                      color: isCredit ? Colors.green.shade700 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}