// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'cart_manager.dart';
import 'pay_on_counter_screen.dart';
import 'order_placed_screen.dart';
import 'wallet_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final double amountToPay;

  const PaymentMethodScreen({super.key, required this.amountToPay});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  // YOUR RAZORPAY KEY
  final String _razorpayKey = "rzp_test_S6uouPpSOvhOo6";

  late Razorpay _razorpay;
  bool _isProcessing = false;
  final CartManager _cartManager = CartManager();

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
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _updateItemsWithRealTime(
      List<Map<String, dynamic>> cartItems) async {
    List<Map<String, dynamic>> updatedItems = [];

    for (var item in cartItems) {
      Map<String, dynamic> newItem = Map.from(item);
      String itemName = newItem['title'] ?? newItem['name'];

      try {
        var query = await FirebaseFirestore.instance
            .collection('menu')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          var data = query.docs.first.data();
          var maxTimeStr = data['time_max'] ?? '5';
          int realTime = int.tryParse(maxTimeStr.toString()) ?? 5;
          newItem['prep_time'] = realTime;

          var docRef = query.docs.first.reference;
          int qty = newItem['quantity'] ?? 1;
          docRef.update({'order_count': FieldValue.increment(qty)});
        } else {
          newItem['prep_time'] = 5;
        }
      } catch (e) {
        debugPrint("Error fetching time: $e");
        newItem['prep_time'] = 5;
      }
      updatedItems.add(newItem);
    }
    return updatedItems;
  }

  void _initiateRazorpay() {
    var options = {
      'key': _razorpayKey,
      'amount': (widget.amountToPay * 100).toInt(),
      'name': 'CampusServe',
      'description': 'Food Order',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'email': FirebaseAuth.instance.currentUser?.email ?? ''
      },
      'theme': {'color': '#1B5E20'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _processOrder(context, "Online (Razorpay)", txnId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.red));
  }

  void _handleWalletTap(double currentBal) {
    if (currentBal < widget.amountToPay) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Insufficient Balance! Redirecting..."),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ));

      Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WalletScreen()))
          .then((_) {
        setState(() {});
      });
      return;
    }

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Confirm Payment",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                  "Pay ₹${widget.amountToPay.toStringAsFixed(0)} from your Campus Wallet?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deductMoneyAndOrder(currentBal);
                    },
                    child: const Text("Pay Now",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  Future<String> getNextTokenNumber() async {
    DocumentReference counterRef =
        FirebaseFirestore.instance.collection('settings').doc('token_counter');

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);
      int nextNumber = 1;
      if (snapshot.exists) {
        int lastNumber = snapshot.get('lastTokenNumber') ?? 0;
        nextNumber = lastNumber + 1;
      }
      transaction.set(
          counterRef,
          {
            'lastTokenNumber': nextNumber,
          },
          SetOptions(merge: true));
      return "T-${nextNumber.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _deductMoneyAndOrder(double currentBal) async {
    setState(() => _isProcessing = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(userRef);
        if (!snap.exists) throw Exception("User record not found!");

        var data = snap.data() as Map<String, dynamic>;
        double bal = (data['wallet_balance'] ?? 0).toDouble();
        String realName = data['name'] ?? user.displayName ?? 'Student';

        if (bal < widget.amountToPay) throw Exception("Balance too low");

        transaction
            .update(userRef, {'wallet_balance': bal - widget.amountToPay});

        transaction
            .set(FirebaseFirestore.instance.collection('transactions').doc(), {
          'userId': user.uid,
          'userName': realName,
          'amount': widget.amountToPay,
          'type': 'Debit',
          'method': 'Wallet',
          'status': 'Success',
          'description': 'Order Payment',
          'timestamp': FieldValue.serverTimestamp()
        });
      });

      await _processOrder(context, "Wallet");
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _processOrder(BuildContext context, String method,
      {String? txnId}) async {
    setState(() => _isProcessing = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String finalName = 'Student';
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        var d = userDoc.data() as Map<String, dynamic>;
        finalName = d['name'] ?? d['userName'] ?? finalName;
      }

      List<Map<String, dynamic>> rawItems = List.from(_cartManager.cartItems);
      List<Map<String, dynamic>> finalItems =
          await _updateItemsWithRealTime(rawItems);

      int totalTime = 0;
      for (var i in finalItems) {
        totalTime +=
            ((i['prep_time'] ?? 5) as int) * ((i['quantity'] ?? 1) as int);
      }
      if (totalTime == 0) totalTime = 10;

      String token = await getNextTokenNumber();
      String orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'tokenNumber': token,
        'userId': user.uid,
        'userName': finalName,
        'items': finalItems,
        'totalAmount': widget.amountToPay,
        'paymentMethod': method,
        'status': 'Preparing',
        'totalPrepTime': totalTime,
        'timestamp': FieldValue.serverTimestamp(),
        // IMPORTANT: Since Wallet/Online is instantly paid, we start the kitchen timer NOW.
        'prepStartTime': FieldValue.serverTimestamp(),
        'txnId': txnId ?? "WALLET_TXN"
      });

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'New Online Order',
        'message': 'Token $token: $finalName placed a new order via $method.',
        'type': 'new_order',
        'orderId': orderId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _cartManager.clearCart();

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => OrderPlacedScreen(
                  tokenNumber: token,
                  orderId: orderId,
                  paymentType: method,
                  itemCount: finalItems.length,
                  totalPaid: widget.amountToPay,
                  orderItems: finalItems)),
          (route) => false);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Order Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9), // Very light premium green bg
      appBar: AppBar(
          title: const Text("Select Payment",
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87)),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('settings')
                  .doc('config')
                  .snapshots(),
              builder: (context, settingsSnapshot) {
                // Default settings fallback
                bool isCashEnabled = true;
                bool isUpiEnabled = true;

                // Read Admin Settings from Firebase
                if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
                  var configData =
                      settingsSnapshot.data!.data() as Map<String, dynamic>?;
                  if (configData != null && configData.containsKey('payment')) {
                    isCashEnabled = configData['payment']['cash'] ?? true;
                    isUpiEnabled = configData['payment']['upi'] ?? true;
                  }
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    double walletBal = 0.0;
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      var d =
                          userSnapshot.data!.data() as Map<String, dynamic>?;
                      if (d != null) {
                        walletBal = (d['wallet_balance'] ?? 0).toDouble();
                      }
                    }

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- REDESIGNED TOTAL TO PAY BANNER ---
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 25, horizontal: 20),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9), // Pastel Green
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.green.shade200, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Column(children: [
                                Text("Total Amount",
                                    style: TextStyle(
                                        color:
                                            Colors.green.shade800, // Dark text
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 5),
                                Text(
                                    "₹${widget.amountToPay.toStringAsFixed(0)}",
                                    style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            Colors.green.shade900)) // Dark text
                              ]),
                            ),

                            const SizedBox(height: 35),
                            const Text("Payment Methods",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 15),

                            // --- CAMPUS WALLET (Always Enabled) ---
                            _buildTile(
                              "Campus Wallet",
                              "Balance: ₹${walletBal.toStringAsFixed(0)}",
                              Icons.account_balance_wallet,
                              Colors.white,
                              () => _handleWalletTap(walletBal),
                              isWallet: true,
                              isEnabled: true,
                            ),
                            const SizedBox(height: 15),

                            // --- ONLINE / UPI (Admin Controlled) ---
                            _buildTile(
                              "Google Pay / UPI",
                              "Pay via GPay, PhonePe, Paytm",
                              Icons.security_update_good,
                              Colors.white,
                              () => _initiateRazorpay(),
                              isEnabled: isUpiEnabled,
                            ),
                            const SizedBox(height: 15),

                            // --- PAY ON COUNTER (Admin Controlled) ---
                            _buildTile(
                              "Pay on Counter",
                              "Cash Payment",
                              Icons.storefront,
                              Colors.white,
                              () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PayOnCounterScreen(
                                            amount: widget.amountToPay,
                                            orderItems: List.from(
                                                _cartManager.cartItems))));
                              },
                              isEnabled: isCashEnabled,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // --- PREMIUM LIST TILE ---
  Widget _buildTile(
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback tap, {
    bool isWallet = false,
    bool isEnabled = true,
  }) {
    // If disabled by admin, change subtitle and fade it out
    if (!isEnabled) {
      sub = "Currently disabled by Admin";
      color = Colors.grey.shade100;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
              color: isEnabled ? Colors.grey.shade300 : Colors.transparent,
              width: 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: ListTile(
          onTap: isEnabled ? tap : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.green.shade50 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isEnabled ? Colors.green.shade800 : Colors.grey,
                size: 24),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isEnabled ? Colors.black87 : Colors.grey.shade700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(sub,
                style: TextStyle(
                    fontSize: 13,
                    color: isEnabled ? Colors.black54 : Colors.red.shade400,
                    fontWeight:
                        isEnabled ? FontWeight.normal : FontWeight.w600)),
          ),
          trailing: isWallet
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text("FAST",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)))
              : Icon(Icons.chevron_right,
                  size: 22,
                  color: isEnabled ? Colors.grey.shade400 : Colors.transparent),
        ),
      ),
    );
  }
}
