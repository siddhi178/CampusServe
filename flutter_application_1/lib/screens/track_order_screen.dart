// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_local_variable, unnecessary_to_list_in_spreads

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'home_screen.dart';
import 'feedback_screen.dart';
import '../services/notification_service.dart';
import 'cart_manager.dart';
import '../services/invoice_service.dart';

class TrackOrderScreen extends StatefulWidget {
  final String? orderId;
  final String? tokenNumber;
  final num? totalAmount;
  final String? paymentType;
  final List<Map<String, dynamic>>? orderItems;

  const TrackOrderScreen({
    super.key,
    this.orderId,
    this.tokenNumber,
    this.totalAmount,
    this.paymentType,
    this.orderItems,
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final Color themeColor = const Color(0xFFBEDFC8);
  final Color darkGreen = const Color(0xFF1B5E20);

  Timer? _timer;
  String _timeString = "Calculating...";
  bool _isLocalOverdue = false;
  double _progressValue = 0.0;
  String _readyByTime = "--:--";

  bool _showAutoRefundSelection = false;
  bool _isAutoRefunding = false;

  Stream<DocumentSnapshot>? _orderStream;
  String _currentStatus = "Preparing";
  List _currentItems = [];

  bool _hasPlayedSound = false;

  @override
  void initState() {
    super.initState();
    CartManager().clearCart();
    if (widget.orderId != null) {
      _orderStream = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots();
      _checkAutoStartKitchen();
    }
    _startUiTimer();
  }

  void _startUiTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
        _checkAutoStartKitchen();
      }
    });
  }

  void _checkAutoStartKitchen() {
    if (widget.orderId == null) return;
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get()
        .then((doc) {
      if (doc.exists && doc.data() != null) {
        var data = doc.data()!;
        if (data['status'] == 'Rescheduled') {
          Timestamp? scheduledTs = data['scheduledTimestamp'];
          if (scheduledTs != null &&
              DateTime.now().isAfter(scheduledTs.toDate())) {
            FirebaseFirestore.instance
                .collection('orders')
                .doc(widget.orderId)
                .update({
              'status': 'Preparing',
              'prepStartTime': FieldValue.serverTimestamp(),
              'overdue': false,
              'wasRescheduled': true,
            });
          }
        }
      }
    });
  }

  void _checkAndPlaySound(String status) {
    if (status == 'Ready' && !_hasPlayedSound) {
      _hasPlayedSound = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("🔔 Your Order is Ready! Please pickup at counter."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5)),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _handleBackNavigation();
    return false;
  }

  void _handleBackNavigation() {
    if (_currentStatus == 'Completed' || _currentStatus == 'Cancelled') {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => FeedbackScreen(
                  orderItems: List<Map<String, dynamic>>.from(_currentItems),
                  orderId: widget.orderId ?? "")));
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false);
    }
  }

  void _calculateTimer(Timestamp startTimestamp, int totalMinutes) {
    DateTime start = startTimestamp.toDate();
    DateTime end = start.add(Duration(minutes: totalMinutes));
    DateTime now = DateTime.now();
    _readyByTime = DateFormat('hh:mm a').format(end);

    int totalSeconds = end.difference(start).inSeconds;
    int elapsedSeconds = now.difference(start).inSeconds;
    int remainingSeconds = end.difference(now).inSeconds;

    if (remainingSeconds <= 0) {
      _isLocalOverdue = true;
      _progressValue = 1.0;

      int overdueMins = remainingSeconds.abs() ~/ 60;
      _timeString = overdueMins > 0 ? "Delayed by ${overdueMins}m" : "Delayed";

      if (overdueMins >= 60 &&
          _currentStatus == 'Preparing' &&
          !_isAutoRefunding) {
        _executeAppRefund("Wallet", isAuto: true);
      } else if (overdueMins >= 30 && _currentStatus == 'Preparing') {
        _showAutoRefundSelection = true;
      } else {
        _showAutoRefundSelection = false;
      }
    } else {
      _isLocalOverdue = false;
      _showAutoRefundSelection = false;
      int min = remainingSeconds ~/ 60;
      int sec = remainingSeconds % 60;
      _timeString =
          "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
      if (totalSeconds > 0) {
        _progressValue = (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
      }
    }
  }

  Future<List<DateTime>> _calculateKitchenLoadAndGetSlots() async {
    DateTime baseTime = DateTime.now().add(const Duration(minutes: 5));
    return [
      baseTime,
      baseTime.add(const Duration(minutes: 15)),
      baseTime.add(const Duration(minutes: 30))
    ];
  }

  Future<void> _addWaitTime(int minutes) async {
    Navigator.pop(context);
    String timeNow = DateFormat('hh:mm a').format(DateTime.now());
    String extMsg = "+$minutes min at $timeNow (By You)";

    var doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();
    if (!doc.exists) return;

    var data = doc.data()!;
    Timestamp startField =
        data['prepStartTime'] ?? data['timestamp'] ?? Timestamp.now();
    int currentPrepTime = data['totalPrepTime'] ?? 15;
    int elapsedMins = DateTime.now().difference(startField.toDate()).inMinutes;
    int newTotalPrepTime = max(elapsedMins, currentPrepTime) + minutes;

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
      'totalPrepTime': newTotalPrepTime,
      'overdue': false,
      'status': 'Preparing',
      'isExtended': true,
      'extensionHistory': FieldValue.arrayUnion([extMsg]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Time Extended Successfully! Timer updated."),
        backgroundColor: Colors.purple));
  }

  Future<void> _rescheduleOrder(DateTime slotTime) async {
    Navigator.pop(context);
    String displayTime = DateFormat('hh:mm a').format(slotTime);
    String timeNow = DateFormat('hh:mm a').format(DateTime.now());
    String reschMsg = "Shifted to $displayTime (at $timeNow)";

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
      'status': 'Rescheduled',
      'scheduledTimestamp': Timestamp.fromDate(slotTime),
      'scheduledSlot': displayTime,
      'overdue': false,
      'wasRescheduled': true,
      'rescheduleHistory': FieldValue.arrayUnion([reschMsg])
    });
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processCancelOrder();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processCancelOrder() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Refund Method"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How would you like to receive your refund?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet, color: Colors.green),
              title: const Text("Add to Wallet",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Instant Refund"),
              tileColor: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.green.shade200)),
              onTap: () {
                Navigator.pop(ctx);
                _executeAppRefund("Wallet");
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.orange),
              title: const Text("Refund by Cash",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Collect at Counter"),
              tileColor: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.orange.shade200)),
              onTap: () {
                Navigator.pop(ctx);
                _executeAppRefund("Cash");
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))
        ],
      ),
    );
  }

  void _showRescheduleSlots(List<DateTime> slots) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Time Slot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: slots
              .map((time) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: () => _rescheduleOrder(time),
                            child: Text(DateFormat('hh:mm a').format(time)))),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"))
        ],
      ),
    );
  }

  Future<void> _executeAppRefund(String method, {bool isAuto = false}) async {
    if (_isAutoRefunding) return;
    setState(() {
      _isAutoRefunding = true;
    });

    try {
      double refundAmount = widget.totalAmount?.toDouble() ?? 0.0;
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not found");
      String timeNow = DateFormat('dd MMM, hh:mm a').format(DateTime.now());

      if (method == "Wallet") {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          DocumentSnapshot userSnap = await transaction.get(userRef);

          double currentBal = 0.0;
          String userName = "Student";
          if (userSnap.exists) {
            var data = userSnap.data() as Map<String, dynamic>;
            currentBal = data['wallet_balance']?.toDouble() ?? 0.0;
            userName = data['name'] ?? "Student";
          }

          transaction.set(
              userRef,
              {'wallet_balance': currentBal + refundAmount},
              SetOptions(merge: true));

          DocumentReference txnRef =
              FirebaseFirestore.instance.collection('transactions').doc();
          transaction.set(txnRef, {
            'userId': user.uid,
            'userName': userName,
            'amount': refundAmount,
            'type': 'Credit',
            'method': 'Refund',
            'status': 'Success',
            'description':
                isAuto ? 'Auto 1Hr Cancel Refund' : 'Order Cancelled Refund',
            'timestamp': FieldValue.serverTimestamp()
          });

          transaction.update(
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderId),
              {
                'status': 'Cancelled',
                'refundMethod': isAuto ? 'Wallet (Auto 1hr Cancel)' : 'Wallet',
                'overdue': false,
                'refundVerified': true,
                'resolvedAt': FieldValue.serverTimestamp(),
                'activityLogs': FieldValue.arrayUnion(
                    ['Resolved to Wallet Refund on $timeNow'])
              });
        });

        await FirebaseFirestore.instance.collection('admin_notifications').add({
          'title':
              isAuto ? 'Order Auto-Refunded' : 'Order Cancelled & Refunded',
          'message':
              'Token ${widget.tokenNumber}: ₹$refundAmount was refunded to the user\'s wallet.',
          'type': 'cancelled',
          'orderId': widget.orderId!,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        NotificationService.sendNotification(
            title: isAuto ? "Order Auto-Refunded! 🚨" : "Refund Successful 💳",
            message:
                "₹$refundAmount has been securely refunded to your Campus Wallet.",
            type: "alert",
            targetId: widget.orderId!);

        if (!isAuto && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Refund instantly added to your Campus Wallet."),
              backgroundColor: Colors.green));
        }
      } else if (method == "Cash") {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'status': 'Cash Refund Requested',
          'refundMethod': 'Cash',
          'overdue': false,
          'cashRequestTime': FieldValue.serverTimestamp(),
          'activityLogs':
              FieldValue.arrayUnion(['User selected Cash Refund on $timeNow'])
        });

        await FirebaseFirestore.instance.collection('admin_notifications').add({
          'title': 'Cash Refund Requested!',
          'message':
              'Token ${widget.tokenNumber}: User requested a cash refund of ₹$refundAmount at the counter.',
          'type': 'alert',
          'orderId': widget.orderId!,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        NotificationService.sendNotification(
            title: "Cash Refund Requested",
            message:
                "Please visit the counter to collect your ₹$refundAmount cash refund.",
            type: "alert",
            targetId: widget.orderId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "You selected collect cash from the counter. Please go today and collect the cash from the counter."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error processing refund: $e"),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoRefunding = false;
        });
      }
    }
  }

  void _showManageOrderDialog(String paymentMethod, double amount) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Manage Order",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Extend Wait Time:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () => _addWaitTime(5),
                          icon: const Icon(Icons.av_timer, size: 18),
                          label: const Text("+ 5 Min"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade50,
                              foregroundColor: Colors.purple,
                              elevation: 0))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () => _addWaitTime(10),
                          icon: const Icon(Icons.more_time, size: 18),
                          label: const Text("+ 10 Min"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade50,
                              foregroundColor: Colors.purple,
                              elevation: 0))),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              _buildManageOption(
                  icon: Icons.access_time,
                  color: Colors.blue,
                  title: "Reschedule Order",
                  subtitle: "Move to later time",
                  onTap: () async {
                    Navigator.pop(context);
                    List<DateTime> slots =
                        await _calculateKitchenLoadAndGetSlots();
                    _showRescheduleSlots(slots);
                  }),
              const SizedBox(height: 12),
              _buildManageOption(
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  title: "Cancel Order",
                  subtitle: "Cancel completely",
                  onTap: () {
                    Navigator.pop(context);
                    _showCancelConfirmation();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  // --- USER VERIFIES THEY RECEIVED CASH ---
  Future<void> _finalizeRefundVerification(bool received) async {
    String timeNow = DateFormat('dd MMM, hh:mm a').format(DateTime.now());

    if (received) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'Cancelled',
        'refundVerified': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'activityLogs':
            FieldValue.arrayUnion(['User confirmed Cash Receipt on $timeNow'])
      });

      // EXACT MESSAGE REQUESTED
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cash successfully refunded.",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green));
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false);
    } else {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'Refund Disputed',
        'activityLogs':
            FieldValue.arrayUnion(['User DISPUTED receiving cash on $timeNow'])
      });
      await FirebaseFirestore.instance.collection('complaints').add({
        'orderId': widget.tokenNumber ?? widget.orderId,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userName': FirebaseAuth.instance.currentUser?.displayName ?? "Student",
        'issueType': 'Refund Dispute',
        'description': 'User denied receiving refund cash marked by Admin.',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'New',
      });
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'REFUND DISPUTED!',
        'message':
            'Token ${widget.tokenNumber}: Student denied receiving their cash refund! Please check Complaints.',
        'type': 'alert',
        'orderId': widget.orderId!,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Dispute Raised. Manager will check.",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red));
    }
  }

  Widget _buildVerificationUI(double amount) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Confirm Refund Receipt",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 15),
            Text(
                "The Admin has confirmed handing you ₹$amount in cash. Please click below to confirm you received it.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () => _finalizeRefundVerification(true),
                child: const Text("YES, I RECEIVED IT",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => _finalizeRefundVerification(false),
              child: const Text("NO, I DID NOT RECEIVE IT",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildManageOption(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey))
              ])),
          Icon(Icons.chevron_right, color: color)
        ]),
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String subtitle, bool isActive, bool isLast,
      {bool isWarning = false, IconData? icon, Color? activeColor}) {
    Color color = isActive ? (activeColor ?? darkGreen) : Colors.grey.shade300;
    if (title.contains("Delayed") ||
        title.contains("Awaiting") ||
        title.contains("Refund") ||
        title.contains("Cancelled")) {
      color = isWarning ? Colors.orange : Colors.red;
    }
    if (title.contains("Extended")) color = Colors.purple;
    if (title.contains("Rescheduled")) color = Colors.blue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color:
                      isActive ? color.withOpacity(0.15) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2)),
              child: Icon(icon ?? (isActive ? Icons.check : Icons.circle),
                  size: 14, color: color),
            ),
            if (!isLast)
              AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 2,
                  height: 45,
                  color:
                      isActive ? color.withOpacity(0.4) : Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(title,
                  style: TextStyle(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? Colors.black87 : Colors.grey.shade400,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.black54 : Colors.grey.shade400,
                      height: 1.3)),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: Text("No Order ID")));
    }
    if (_orderStream == null) {
      return Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: darkGreen)));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: _handleBackNavigation),
          title: const Text("Track Order",
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          centerTitle: true,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _orderStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: darkGreen));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Order not found"));
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Preparing';
            _currentStatus = status;
            _currentItems = data['items'] ?? [];

            if (status == 'Ready') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkAndPlaySound(status);
              });
            }

            String token = data['tokenNumber'] ?? '---';
            String orderIdDisplay = data['orderId'] ?? widget.orderId!;
            if (orderIdDisplay.length > 10 &&
                orderIdDisplay.startsWith("ORDER_")) {
              orderIdDisplay = "#${orderIdDisplay.substring(6, 12)}";
            }

            double grandTotal = (data['totalAmount'] ?? 0).toDouble();
            String payType = data['paymentMethod'] ?? 'Online';

            Timestamp orderTime = data['timestamp'] ?? Timestamp.now();
            Timestamp placedTime = data['originalOrderTime'] ??
                data['timestamp'] ??
                Timestamp.now();
            Timestamp startTs = data['prepStartTime'] ?? orderTime;

            int totalPrepTime = (data['totalPrepTime'] ?? 5).toInt();
            List items = data['items'] ?? [];
            List<dynamic> extHistory = data['extensionHistory'] ?? [];
            List<dynamic> reschHistory = data['rescheduleHistory'] ?? [];
            List<dynamic> activityLogs = data['activityLogs'] ?? [];

            bool isOverdue = data['overdue'] ?? false;
            bool isExtended = data['isExtended'] ?? false;
            bool isRescheduledStatus = status == 'Rescheduled';
            bool wasRescheduled = data['wasRescheduled'] ?? false;
            String scheduledSlot = data['scheduledSlot'] ?? '';

            // Handle Verification State
            if (status.contains("Verify")) {
              return _buildVerificationUI(grandTotal);
            }

            // --- 24-HOUR AUTO REVERT FOR UNCOLLECTED CASH ---
            bool isCashExpired = false;
            if (status == 'Cash Refund Requested' &&
                data['cashRequestTime'] != null) {
              DateTime crt = (data['cashRequestTime'] as Timestamp).toDate();
              if (DateTime.now().difference(crt).inHours >= 24) {
                isCashExpired = true;
              }
            }

            // If user gets tired of waiting or the 24 hours expired, show options again!
            if (status == 'Refund Disputed' ||
                (status == 'Cash Refund Requested' && isCashExpired)) {
              return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_problem, size: 70, color: Colors.red),
                      const SizedBox(height: 20),
                      Text(
                          isCashExpired
                              ? "Cash Collection Expired"
                              : "Refund Disputed",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                            isCashExpired
                                ? "You did not collect your cash within 24 hours. Please select your refund method again."
                                : "A complaint has been registered. The Admin will reply to you shortly.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54)),
                      ),
                      const SizedBox(height: 20),
                      const Text("Don't want to wait?",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.account_balance_wallet),
                            label:
                                const Text("Switch to Wallet Refund (Instant)"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            onPressed: () =>
                                _executeAppRefund("Wallet", isAuto: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                          onPressed: _handleBackNavigation,
                          child: const Text("Back to Home",
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold)))
                    ]),
              );
            }

            // Just normal requested state
            if (status == 'Cash Refund Requested') {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.hourglass_empty,
                        size: 60, color: Colors.orange),
                    const SizedBox(height: 10),
                    const Text("Refund Processing",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                          "Please visit the counter to collect your cash refund. Waiting for Admin to hand it over.",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.black54)),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text("Switch to Wallet Refund"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white),
                          onPressed: () =>
                              _executeAppRefund("Wallet", isAuto: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _handleBackNavigation,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen),
                        child: const Text("Go Back",
                            style: TextStyle(color: Colors.white)))
                  ]));
            }

            if (status == 'Pending Payment') {
              _timeString = "Waiting...";
              _progressValue = 0.0;
              _readyByTime = "Pending Confirmation";
            } else if (!isRescheduledStatus) {
              _calculateTimer(startTs, totalPrepTime);
            }

            bool showOverdueUI = (isOverdue || _isLocalOverdue) &&
                !isRescheduledStatus &&
                status != 'Ready' &&
                status != 'Completed' &&
                status != 'Pending Payment' &&
                !status.contains('Refund') &&
                status != 'Cancelled';
            int currentStep = 1;
            if (status == 'Ready') currentStep = 2;
            if (status == 'Completed') currentStep = 3;

            if (status == 'Cancelled') {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.cancel, size: 60, color: Colors.red),
                    const SizedBox(height: 10),
                    const Text("Order Cancelled",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                          "Your order has been cancelled and completely refunded.",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.black54)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _handleBackNavigation,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen),
                        child: const Text("Go Back",
                            style: TextStyle(color: Colors.white)))
                  ]));
            }

            String topStatusText = "";
            Color topTextColor = darkGreen;
            Color cardBgColor = Colors.white;
            Color borderColor = themeColor;

            if (status == 'Pending Payment') {
              topStatusText = "Awaiting Confirmation";
              topTextColor = Colors.orange[800]!;
            } else if (status == 'Ready') {
              topStatusText =
                  wasRescheduled ? "Rescheduled Order Ready" : "Order Ready";
            } else if (isRescheduledStatus) {
              topStatusText = scheduledSlot;
              topTextColor = Colors.blue;
            } else if (showOverdueUI && !_showAutoRefundSelection) {
              topStatusText = _timeString;
              topTextColor = Colors.red;
              borderColor = Colors.red.shade200;
            } else if (_showAutoRefundSelection) {
              topStatusText = "Extremely Delayed";
              topTextColor = Colors.red;
              borderColor = Colors.red.shade400;
            } else {
              topStatusText = _timeString;
              if (isExtended) {
                topTextColor = Colors.purple;
                borderColor = Colors.purple.shade300;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ]),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Token Number",
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(token,
                                      style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900)),
                                ]),
                            Flexible(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                  Text(
                                      status == 'Pending Payment'
                                          ? "Status"
                                          : (isRescheduledStatus
                                              ? "Scheduled For"
                                              : (status == 'Ready' ||
                                                      showOverdueUI
                                                  ? "Status"
                                                  : "Remaining Time")),
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(topStatusText,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: (isRescheduledStatus ||
                                                  status == 'Ready' ||
                                                  status == 'Pending Payment')
                                              ? 18
                                              : 26,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                          color: topTextColor)),
                                ])),
                          ],
                        ),
                        if (!isRescheduledStatus &&
                            !showOverdueUI &&
                            status == 'Preparing') ...[
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                              value: _progressValue,
                              backgroundColor: Colors.grey.shade100,
                              color: isExtended ? Colors.purple : themeColor,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(10)),
                          const SizedBox(height: 10),
                          Align(
                              alignment: Alignment.centerRight,
                              child: Text("Est. Ready: $_readyByTime",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isExtended
                                          ? Colors.purple
                                          : darkGreen,
                                      fontWeight: FontWeight.w800)))
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // DYNAMIC TIMELINE SYSTEM
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      children: [
                        _buildTimelineItem(
                            "Order Placed",
                            DateFormat('hh:mm a').format(placedTime.toDate()),
                            true,
                            false,
                            icon: Icons.receipt_long),
                        if (status == 'Pending Payment')
                          _buildTimelineItem("Awaiting Confirmation",
                              "Pay at counter to start prep", false, false,
                              isWarning: true, icon: Icons.hourglass_empty)
                        else
                          _buildTimelineItem("Order Confirmed",
                              "Admin accepted your order", true, false,
                              icon: Icons.thumb_up),
                        ...reschHistory
                            .map((resch) => _buildTimelineItem(
                                "Rescheduled", resch.toString(), true, false,
                                isWarning: true, icon: Icons.calendar_month))
                            .toList(),
                        ...extHistory
                            .map((ext) => _buildTimelineItem(
                                "Time Extended", ext.toString(), true, false,
                                isWarning: true, icon: Icons.more_time))
                            .toList(),
                        ...activityLogs
                            .map((log) => _buildTimelineItem(
                                "Activity Update", log.toString(), true, false,
                                isWarning: true, icon: Icons.info_outline))
                            .toList(),
                        if (showOverdueUI)
                          _buildTimelineItem(
                              "Delayed",
                              "Kitchen is taking longer than expected",
                              true,
                              false,
                              isWarning: true,
                              icon: Icons.warning_amber_rounded),
                        if (status != 'Pending Payment')
                          _buildTimelineItem(
                              "Preparing",
                              "Total Est. Time: $totalPrepTime mins",
                              !isRescheduledStatus && currentStep >= 1,
                              false,
                              icon: Icons.soup_kitchen),
                        _buildTimelineItem(
                            "Ready",
                            (status == 'Ready' && wasRescheduled)
                                ? "Rescheduled Order Ready"
                                : "Pickup at Counter",
                            currentStep >= 2,
                            false,
                            icon: Icons.check_circle_outline),
                        _buildTimelineItem("Completed", "Enjoy your food!",
                            currentStep >= 3, true,
                            icon: Icons.done_all),
                      ],
                    ),
                  ),

                  if (_showAutoRefundSelection && status == 'Preparing')
                    Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 25),
                        child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Colors.red.shade200, width: 2)),
                            child: Column(
                              children: [
                                const Row(children: [
                                  Icon(Icons.warning,
                                      color: Colors.red, size: 28),
                                  SizedBox(width: 10),
                                  Expanded(
                                      child: Text("Order Excessively Delayed!",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.red))),
                                ]),
                                const SizedBox(height: 10),
                                const Text(
                                    "It has been over 30 mins since your order was supposed to be ready. Would you like a refund?",
                                    style: TextStyle(color: Colors.redAccent)),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () =>
                                                _executeAppRefund("Wallet"),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green),
                                            child: const Text("Wallet Refund",
                                                style: TextStyle(
                                                    color: Colors.white)))),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: () =>
                                                _executeAppRefund("Cash"),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange),
                                            child: const Text("Cash Refund",
                                                style: TextStyle(
                                                    color: Colors.white)))),
                                  ],
                                )
                              ],
                            ))),

                  if (showOverdueUI &&
                      !_showAutoRefundSelection &&
                      status == 'Preparing')
                    Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 25),
                        child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.orange.shade200)),
                            child: Row(children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 10),
                              const Expanded(
                                  child: Text("Order Delayed.",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange))),
                              OutlinedButton(
                                  onPressed: () => _showManageOrderDialog(
                                      payType, grandTotal),
                                  style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.red)),
                                  child: const Text("Manage Order",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12)))
                            ]))),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.shade200, width: 1.5)),
                    child: Column(
                      children: [
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14))),
                            child: const Center(
                                child: Text("Receipt Details",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black54)))),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Order ID : $orderIdDisplay",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold)),
                                    Text("Payment : $payType",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold))
                                  ]),
                              const SizedBox(height: 20),
                              ...items.map((item) {
                                int q = item['quantity'] ?? 1;
                                int pTime = item['prep_time'] ?? 5;
                                String priceStr = item['price']
                                    .toString()
                                    .replaceAll('₹', '')
                                    .trim();
                                return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              "${item['title']} x $q (${pTime}m)",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600)),
                                          Text("₹$priceStr",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800))
                                        ]));
                              }),
                              const Divider(height: 30, color: Colors.black12),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Grand Total",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16)),
                                    Text("₹${grandTotal.toStringAsFixed(0)}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: darkGreen))
                                  ]),
                              if (status == 'Completed') ...[
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf,
                                        color: Colors.green, size: 18),
                                    label: const Text("Download Invoice",
                                        style: TextStyle(color: Colors.green)),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.green)),
                                    onPressed: () {
                                      InvoiceService.generateAndOpenInvoice(
                                          data);
                                    },
                                  ),
                                )
                              ]
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
