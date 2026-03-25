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

  // ... Razorpay logic remains same ...

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
      'theme': {'color': '#1B5E20'}
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
          // SAFE CHECK: Use containsKey to avoid Bad State error
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
      if (picked != null)
        setState(() {
          _customSelectedDate = picked;
          _selectedFilter = newValue!;
        });
    } else if (newValue != null) {
      setState(() => _selectedFilter = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9),
      appBar: AppBar(
          title: const Text("My Wallet",
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          elevation: 0,
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
            // SAFE CHECK: Ensuring wallet_balance is read safely
            if (d != null && d.containsKey('wallet_balance')) {
              balance = (d['wallet_balance'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.green.shade200, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Available Balance",
                          style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text("₹ ${balance.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: Colors.green.shade900,
                              fontSize: 42,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                // Add Money Input
                const Text("Add Money",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                _buildAddMoneyField(),
                const SizedBox(height: 35),
                // Transactions Header with Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Transactions",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(
              child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      prefixText: "₹ ",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      hintText: "0.00"))),
          ElevatedButton(
              onPressed: _isLoading ? null : _startAddMoney,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text("Add")),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
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

  Widget _buildTransactionList(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No transactions yet"));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            bool isCredit = d['type'] == 'Credit';
            return ListTile(
              leading: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red),
              title: Text(d['description'] ?? 'Transaction'),
              subtitle: Text(d['timestamp'] != null
                  ? DateFormat('dd MMM, hh:mm a')
                      .format((d['timestamp'] as Timestamp).toDate())
                  : ''),
              trailing: Text("${isCredit ? '+' : '-'} ₹${d['amount']}",
                  style: TextStyle(
                      color: isCredit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}
