// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, unused_element, prefer_final_fields

import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_screen.dart';
import 'notification.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'food_detail_screen.dart';
import 'cart_manager.dart';
import 'favorite_manager.dart';
import 'track_order_screen.dart';
import 'order_history_screen.dart';
import 'announcement_detail_screen.dart';
import 'dart:ui';
import '../services/notification_service.dart';
import 'deals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = "All";
  final CartManager _cartManager = CartManager();
  final FavoriteManager _favoriteManager = FavoriteManager();
  String userName = "Student";

  final Color themeColor = const Color(0xFFBEDFC8);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color mcdLightGreen = const Color.fromARGB(184, 14, 78, 0);

  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 5000;
  bool _isUserInteracting = false;
  int _shuffleSeed = 0;

  bool _isFilterVisible = false;
  String _selectedFilterOption = "";
  final List<String> _filterOptions = [
    'Rating 4.0+',
    'Top Seller',
    'Most Ordered',
    'Quick (<10m)'
  ];

  late AnimationController _blinkController;
  bool _isConverting5PM = false;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(viewportFraction: 0.9, initialPage: _currentPage);
    _fetchUserData();
    _startAutoScroll();
    _blinkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_isUserInteracting) return;
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(_currentPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.fastOutSlowIn);
      }
    });
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            userName = doc['name'] ?? "Student";
          });
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _shuffleSeed = DateTime.now().millisecondsSinceEpoch % 1000;
      _selectedFilterOption = "";
    });
    await Future.delayed(const Duration(seconds: 1));
  }

  List<DocumentSnapshot> _applyFilterAndSort(List<DocumentSnapshot> items) {
    var filtered = items.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      if (_selectedFilterOption == 'Rating 4.0+') {
        num r = data['rating'] is String
            ? (num.tryParse(data['rating']) ?? 0)
            : (data['rating'] ?? 0);
        return r >= 4.0;
      }
      if (_selectedFilterOption == 'Quick (<10m)') {
        int tMax = int.tryParse(data['time_max']?.toString() ?? '15') ?? 15;
        return tMax <= 10;
      }
      return true;
    }).toList();

    if (_selectedFilterOption == 'Top Seller' ||
        _selectedFilterOption == 'Most Ordered') {
      filtered.sort((a, b) {
        int countA =
            ((a.data() as Map<String, dynamic>)['order_count'] ?? 0) as int;
        int countB =
            ((b.data() as Map<String, dynamic>)['order_count'] ?? 0) as int;
        return countB.compareTo(countA);
      });
    }
    return filtered;
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    Widget errorWidget = Container(
        color: Colors.grey.shade100,
        child: const Center(
            child: Icon(Icons.fastfood, color: Colors.grey, size: 24)));
    if (path.isEmpty) return errorWidget;
    try {
      if (path.startsWith('data:image')) {
        String base64Data = path
            .substring(path.indexOf(',') + 1)
            .replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data),
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (c, e, s) => errorWidget);
      }
      if (path.startsWith('http'))
        return Image.network(path,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (c, e, s) => errorWidget);
      return Image.asset(path,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => errorWidget);
    } catch (e) {
      return errorWidget;
    }
  }

  Future<void> _forceAutoRefund(
      String orderId, String token, double amount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference orderRef =
            FirebaseFirestore.instance.collection('orders').doc(orderId);
        DocumentSnapshot orderSnap = await transaction.get(orderRef);
        if (orderSnap.exists && orderSnap['status'] == 'Preparing') {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          DocumentSnapshot userSnap = await transaction.get(userRef);
          double bal = userSnap.exists
              ? (userSnap.data() as Map<String, dynamic>)['wallet_balance']
                      ?.toDouble() ??
                  0.0
              : 0.0;
          String userNameStr = userSnap.exists
              ? (userSnap.data() as Map<String, dynamic>)['name'] ?? "Student"
              : "Student";

          transaction.set(userRef, {'wallet_balance': bal + amount},
              SetOptions(merge: true));

          DocumentReference txnRef =
              FirebaseFirestore.instance.collection('transactions').doc();
          transaction.set(txnRef, {
            'userId': user.uid,
            'userName': userNameStr,
            'amount': amount,
            'type': 'Credit',
            'method': 'Refund',
            'status': 'Success',
            'description': 'Auto 1Hr Refund',
            'timestamp': FieldValue.serverTimestamp()
          });

          transaction.update(orderRef, {
            'status': 'Cancelled',
            'refundMethod': 'Wallet (Auto 1hr Cancel)',
            'overdue': false,
            'refundVerified': true,
            'resolvedAt': FieldValue.serverTimestamp()
          });
        }
      });

      FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'Order Auto-Refunded',
        'message':
            'Token $token: ₹$amount was refunded to the user\'s wallet due to extreme delay.',
        'type': 'cancelled',
        'orderId': orderId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      NotificationService.sendNotification(
          title: "Order Auto-Refunded! 🚨",
          message:
              "Your order was delayed for 1 Hour. ₹$amount has been securely refunded to your Campus Wallet.",
          type: "alert",
          targetId: orderId);
    } catch (e) {
      debugPrint("Home Screen Auto Refund Error: $e");
    }
  }

  Future<void> _force5PMCashToWalletRefund(
      String orderId, String token, double amount) async {
    if (_isConverting5PM) return;
    _isConverting5PM = true;
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isConverting5PM = false;
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference orderRef =
            FirebaseFirestore.instance.collection('orders').doc(orderId);
        DocumentSnapshot orderSnap = await transaction.get(orderRef);

        if (orderSnap.exists &&
            orderSnap['status'] == 'Cash Refund Requested') {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          DocumentSnapshot userSnap = await transaction.get(userRef);
          double bal = userSnap.exists
              ? (userSnap.data() as Map<String, dynamic>)['wallet_balance']
                      ?.toDouble() ??
                  0.0
              : 0.0;
          String userNameStr = userSnap.exists
              ? (userSnap.data() as Map<String, dynamic>)['name'] ?? "Student"
              : "Student";

          transaction.set(userRef, {'wallet_balance': bal + amount},
              SetOptions(merge: true));

          DocumentReference txnRef =
              FirebaseFirestore.instance.collection('transactions').doc();
          transaction.set(txnRef, {
            'userId': user.uid,
            'userName': userNameStr,
            'amount': amount,
            'type': 'Credit',
            'method': 'Refund',
            'status': 'Success',
            'description': 'Auto 5 PM Uncollected Cash Rescue',
            'timestamp': FieldValue.serverTimestamp()
          });

          transaction.update(orderRef, {
            'status': 'Cancelled',
            'refundMethod': 'Wallet (Auto 5PM Rescue)',
            'overdue': false,
            'refundVerified': true,
            'unseenWalletTransfer': true,
            'resolvedAt': FieldValue.serverTimestamp()
          });
        }
      });

      FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'Cash Refund Auto-Converted',
        'message':
            'Token $token: Student did not collect cash before 5 PM. Amount auto-credited to their wallet.',
        'type': 'refund',
        'orderId': orderId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Cash Refund Rescued 💳',
        'message':
            'You forgot to collect ₹$amount in cash before 5 PM. We have safely deposited it into your Campus Wallet.',
        'type': 'refund',
        'userId': user.uid,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      NotificationService.sendNotification(
          title: "Cash Refund Saved! 💳",
          message:
              "You missed collecting cash by 5 PM. ₹$amount safely deposited to your Wallet.",
          type: "refund",
          targetId: orderId);
    } catch (e) {
      debugPrint("5PM Auto-Refund Error: $e");
    } finally {
      _isConverting5PM = false;
    }
  }

  void _incrementQuantity(String title, String subtitle, num price,
      String imagePath, String category, String subCategory) {
    _cartManager.addItem(
        title, subtitle, "₹$price", imagePath, category, subCategory);
    setState(() {});
  }

  void _decrementQuantity(String title) {
    _cartManager.removeItem(title);
    setState(() {});
  }

  Widget _buildTag(int orderCount, num rating, bool isNew) {
    String text = '';
    Color bgColor = Colors.transparent;
    Color textColor = Colors.transparent;
    IconData? icon;

    if (orderCount >= 50) {
      text = "BESTSELLER";
      bgColor = const Color(0xFFFFF0E6);
      textColor = Colors.deepOrange.shade700;
      icon = Icons.whatshot;
    } else if (orderCount >= 20) {
      text = "MOST ORDERED";
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
      icon = Icons.trending_up;
    } else if (isNew) {
      text = "NEW";
      bgColor = Colors.purple.shade50;
      textColor = Colors.purple.shade800;
      icon = Icons.new_releases;
    } else if (rating >= 4.5 && orderCount > 5) {
      text = "TOP RATED";
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
      icon = Icons.star;
    }

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: textColor.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 9, color: textColor),
          const SizedBox(width: 3)
        ],
        Text(text,
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.3)),
      ]),
    );
  }

  Color _getRatingColor(num rating) {
    if (rating >= 4.0) return Colors.green.shade700;
    if (rating >= 3.0) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Widget _buildAnnouncementCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox(height: 140);
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();

        var docs = snapshot.data!.docs;
        return Column(
          children: [
            SizedBox(
              height: 140,
              child: Listener(
                onPointerDown: (_) => _isUserInteracting = true,
                onPointerUp: (_) => _isUserInteracting = false,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: docs.length == 1 ? 1 : 100000,
                  onPageChanged: (page) => _currentPage = page,
                  itemBuilder: (context, index) {
                    var data = docs[index % docs.length].data()
                        as Map<String, dynamic>;
                    String imageSource = data['image'] ?? '';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AnnouncementDetailScreen(data: data))),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black87,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Transform.scale(
                                  scale: 1.25,
                                  child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                          sigmaX: 18, sigmaY: 18),
                                      child: Opacity(
                                          opacity: 0.8,
                                          child: _buildImage(imageSource,
                                              fit: BoxFit.cover)))),
                              Container(color: Colors.black.withOpacity(0.15)),
                              _buildImage(imageSource, fit: BoxFit.contain),
                              Positioned.fill(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: const [
                                    0.5,
                                    1.0
                                  ],
                                              colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.85)
                                  ])))),
                              Positioned(
                                  bottom: 12,
                                  left: 15,
                                  right: 15,
                                  child: Text(data['title'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                                offset: const Offset(0, 1),
                                                blurRadius: 8.0,
                                                color: Colors.black
                                                    .withOpacity(0.8))
                                          ]))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildUnseenRefundBanners(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('unseenWalletTransfer', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            double amount = (data['totalAmount'] ?? 0).toDouble();
            String token = data['tokenNumber'] ?? '#';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: Row(
                children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 24)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Money Secured!",
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                            "You didn't collect your Token $token cash before 5 PM. We safely deposited ₹$amount into your Wallet.",
                            style: TextStyle(
                                fontSize: 12, color: Colors.green.shade900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('orders')
                          .doc(doc.id)
                          .update({'unseenWalletTransfer': false});
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: const Text("Okay",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActiveOrderStatus(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('status', whereIn: [
            'Preparing',
            'Ready',
            'Rescheduled',
            'Pending Payment',
            'Refund Requested',
            'Wallet Refund Requested',
            'Cash Refund Requested',
            'Cash Refunded - Verify',
            'Refund Disputed'
          ])
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();

        var activeOrders = snapshot.data!.docs;

        return Column(
          children: activeOrders.map((doc) {
            var orderData = doc.data() as Map<String, dynamic>;
            String status = orderData['status'] ?? 'Preparing';
            String orderId = doc.id;
            String token = orderData['tokenNumber'] ?? '--';
            int totalPrepTime =
                (orderData['totalPrepTime'] as num? ?? 15).toInt();
            Timestamp? startTs =
                orderData['prepStartTime'] ?? orderData['timestamp'];
            String timeString = "Calculating...";
            bool isActuallyOverdue = false;
            DateTime now = DateTime.now();

            if (startTs != null && status == 'Preparing') {
              DateTime start = startTs.toDate();
              DateTime end = start.add(Duration(minutes: totalPrepTime));
              int diff = end.difference(now).inSeconds;

              if (diff <= 0) {
                isActuallyOverdue = true;
                int delMins = diff.abs() ~/ 60;
                timeString = delMins > 0 ? "Delayed by ${delMins}m" : "Delayed";
                if (delMins >= 60) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _forceAutoRefund(orderId, token,
                        orderData['totalAmount']?.toDouble() ?? 0.0);
                  });
                }
              } else {
                int min = diff ~/ 60;
                int sec = diff % 60;
                timeString =
                    "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
              }
            }

            if (status == 'Cash Refund Requested') {
              DateTime orderDate = startTs?.toDate() ?? now;
              if ((now.hour >= 17 && now.day >= orderDate.day) ||
                  now.difference(orderDate).inDays >= 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _force5PMCashToWalletRefund(orderId, token,
                      orderData['totalAmount']?.toDouble() ?? 0.0);
                });
              }
            }

            IconData icon;
            String text;
            String subText;
            Color iconColor = Colors.green;
            Color textColor = Colors.black;
            Color borderColor = Colors.green;

            if (status == 'Ready') {
              icon = Icons.check_circle;
              text = "Order Ready!";
              subText = "Pick up at counter (Token: $token)";
              timeString = "Ready";
              isActuallyOverdue = false;
            } else if (status == 'Pending Payment') {
              icon = Icons.hourglass_empty;
              text = "Waiting for Payment";
              subText = "Pay at counter to start order";
              iconColor = Colors.orange;
              textColor = Colors.orange.shade900;
              borderColor = Colors.orange;
              timeString = "Wait";
            } else if (status.contains('Verify')) {
              icon = Icons.verified_user;
              text = "Cash Ready for Collection";
              subText = "Admin has the cash. Click to verify.";
              iconColor = Colors.purple;
              textColor = Colors.purple.shade900;
              borderColor = Colors.purple;
              timeString = "Collect";
            } else if (status.contains('Refund')) {
              icon = Icons.account_balance_wallet;
              text = "Refund Processing";
              subText = status == 'Refund Disputed'
                  ? "Dispute under review by admin"
                  : "Amount is being refunded";
              iconColor = Colors.orange;
              textColor = Colors.orange.shade900;
              borderColor = Colors.orange;
              timeString = "Refunding";
            } else if (status == 'Rescheduled') {
              icon = Icons.calendar_month;
              text = "Order Rescheduled";
              subText =
                  "Scheduled for ${orderData['scheduledSlot'] ?? 'later'}";
              iconColor = Colors.blue;
              textColor = Colors.blue.shade900;
              borderColor = Colors.blue;
              timeString = "Paused";
            } else if (isActuallyOverdue) {
              icon = Icons.warning_amber_rounded;
              text = "Order Running Late!";
              subText = "Token: $token - Kitchen is busy";
              iconColor = Colors.red;
              textColor = Colors.red.shade900;
              borderColor = Colors.red;
            } else {
              icon = Icons.soup_kitchen;
              text = "Preparing Order...";
              subText = "Kitchen working on Token: $token";
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TrackOrderScreen(orderId: orderId))),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: isActuallyOverdue
                          ? const Color(0xFFFFEBEE)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: borderColor,
                          width: isActuallyOverdue ? 1.2 : 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]),
                  child: Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: Icon(icon, color: iconColor, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(text,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(subText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: isActuallyOverdue
                                  ? Colors.red
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(timeString,
                              style: TextStyle(
                                  color: isActuallyOverdue
                                      ? Colors.white
                                      : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)))
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _categoryBox(String name, String path) {
    final bool selected = _selectedCategory == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name),
      child: Container(
        width: 75,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: selected ? const Color(0xFFDFF5E1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? Colors.green : Colors.grey.shade300,
                width: selected ? 1.5 : 1)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
              height: 35,
              width: 35,
              child: _buildImage(path, fit: BoxFit.contain)),
          const SizedBox(height: 6),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? Colors.green.shade800 : Colors.black87)),
        ]),
      ),
    );
  }

  Widget _buildAllCategoriesLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Popular Menu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        _buildDynamicHorizontalList(),
        const SizedBox(height: 15),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text("All Menu Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        _buildAllMenuItemsVertical(),
      ],
    );
  }

  Widget _buildSubCategoryLayout(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('menu')
          .where('category', isEqualTo: category)
          .where('is_available', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        List<DocumentSnapshot> filteredDocs =
            _applyFilterAndSort(snapshot.data!.docs);
        if (filteredDocs.isEmpty)
          return const Center(
              child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No items match your criteria",
                      style: TextStyle(color: Colors.grey))));

        Map<String, List<DocumentSnapshot>> groupedItems = {};
        for (var doc in filteredDocs) {
          var data = doc.data() as Map<String, dynamic>;
          String subCat = data['sub_category'] ?? 'General';
          if (!groupedItems.containsKey(subCat)) groupedItems[subCat] = [];
          groupedItems[subCat]!.add(doc);
        }

        return Column(
          children: groupedItems.entries.map((entry) {
            String subCategoryName = entry.key;
            List<DocumentSnapshot> items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8),
                    child: Text(subCategoryName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87))),
                SizedBox(
                  height: 255,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    clipBehavior: Clip.none,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var data = items[index].data() as Map<String, dynamic>;
                      String cat = data['category'] ?? '';
                      String subCat = data['sub_category'] ?? '';
                      String title = data['name'] ?? 'Unknown';
                      num price = data['price'] is String
                          ? (num.tryParse(data['price']) ?? 0)
                          : (data['price'] ?? 0);
                      String prepTime =
                          "${data['time_min'] ?? '5'}-${data['time_max'] ?? '10'} min";
                      int orderCount = (data['order_count'] ?? 0) as int;
                      num rating = data['rating'] is String
                          ? (num.tryParse(data['rating']) ?? 0)
                          : (data['rating'] ?? 0);
                      Timestamp? createdAt =
                          data['timestamp'] ?? data['created_at'];

                      // --- FETCH OFFER DATA ---
                      bool hasOffer = data['has_offer'] ?? false;
                      num offerPercent = data['offer_percentage'] ?? 0;
                      num originalPrice = data['original_price'] ?? price;

                      bool isNew = false;
                      if (createdAt != null) {
                        isNew = DateTime.now()
                                .difference(createdAt.toDate())
                                .inDays <=
                            30;
                      } else if (orderCount == 0) {
                        isNew = true;
                      }

                      return Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: _buildMenuCard(
                              title,
                              data['short_desc'] ?? '',
                              price,
                              originalPrice,
                              hasOffer,
                              offerPercent,
                              data['image'] ?? data['image_url'] ?? '',
                              prepTime,
                              cat,
                              subCat,
                              rating,
                              orderCount,
                              isNew));
                    },
                  ),
                ),
                const SizedBox(height: 15),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDynamicHorizontalList({String? filterCategory}) {
    Query query = FirebaseFirestore.instance
        .collection('menu')
        .where('is_available', isEqualTo: true);
    if (filterCategory != null)
      query = query.where('category', isEqualTo: filterCategory);

    return SizedBox(
      height: 255,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          var items = snapshot.data?.docs ?? [];
          var sortedList = _applyFilterAndSort(items);

          if (_selectedFilterOption.isEmpty) {
            sortedList.sort((a, b) {
              var dataA = a.data() as Map<String, dynamic>;
              var dataB = b.data() as Map<String, dynamic>;
              int countA = (dataA['order_count'] ?? 0) as int;
              int countB = (dataB['order_count'] ?? 0) as int;
              return countB.compareTo(countA);
            });
          }

          if (sortedList.isEmpty)
            return const Center(
                child: Text("No items match your filter",
                    style: TextStyle(color: Colors.grey)));
          if (sortedList.length > 10) sortedList = sortedList.sublist(0, 10);

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.none,
            itemCount: sortedList.length,
            itemBuilder: (context, index) {
              var data = sortedList[index].data() as Map<String, dynamic>;
              String title = data['name'] ?? 'Unknown';
              num price = data['price'] is String
                  ? (num.tryParse(data['price']) ?? 0)
                  : (data['price'] ?? 0);
              String prepTime =
                  "${data['time_min'] ?? '5'}-${data['time_max'] ?? '10'} min";
              String cat = data['category'] ?? '';
              String subCat = data['sub_category'] ?? '';
              int orderCount = (data['order_count'] ?? 0) as int;
              num rating = data['rating'] is String
                  ? (num.tryParse(data['rating']) ?? 0)
                  : (data['rating'] ?? 0);
              Timestamp? createdAt = data['timestamp'] ?? data['created_at'];

              // --- FETCH OFFER DATA ---
              bool hasOffer = data['has_offer'] ?? false;
              num offerPercent = data['offer_percentage'] ?? 0;
              num originalPrice = data['original_price'] ?? price;

              bool isNew = false;
              if (createdAt != null) {
                isNew =
                    DateTime.now().difference(createdAt.toDate()).inDays <= 30;
              } else if (orderCount == 0) {
                isNew = true;
              }

              return Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: _buildMenuCard(
                      title,
                      data['short_desc'] ?? '',
                      price,
                      originalPrice,
                      hasOffer,
                      offerPercent,
                      data['image'] ?? data['image_url'] ?? '',
                      prepTime,
                      cat,
                      subCat,
                      rating,
                      orderCount,
                      isNew));
            },
          );
        },
      ),
    );
  }

  Widget _buildAllMenuItemsVertical({String? filterCategory}) {
    Query query = FirebaseFirestore.instance
        .collection('menu')
        .where('is_available', isEqualTo: true);
    if (filterCategory != null)
      query = query.where('category', isEqualTo: filterCategory);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        var items = snapshot.data?.docs ?? [];
        var displayList = _applyFilterAndSort(items);

        if (_selectedFilterOption.isEmpty) {
          displayList.shuffle(Random(_shuffleSeed + 1));
        }
        if (displayList.isEmpty)
          return const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                  child: Text("No items match your filter",
                      style: TextStyle(color: Colors.grey))));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: displayList.length,
          itemBuilder: (_, i) {
            var data = displayList[i].data() as Map<String, dynamic>;
            String title = data['name'] ?? 'Unknown';
            num price = data['price'] is String
                ? (num.tryParse(data['price']) ?? 0)
                : (data['price'] ?? 0);
            String prepTime =
                "${data['time_min'] ?? '5'}-${data['time_max'] ?? '10'}m";
            String category = data['category'] ?? '';
            String subCategory = data['sub_category'] ?? '';
            int orderCount = (data['order_count'] ?? 0) as int;
            num rating = data['rating'] is String
                ? (num.tryParse(data['rating']) ?? 0)
                : (data['rating'] ?? 0);
            Timestamp? createdAt = data['timestamp'] ?? data['created_at'];

            // --- FETCH OFFER DATA ---
            bool hasOffer = data['has_offer'] ?? false;
            num offerPercent = data['offer_percentage'] ?? 0;
            num originalPrice = data['original_price'] ?? price;

            bool isNew = false;
            if (createdAt != null) {
              isNew =
                  DateTime.now().difference(createdAt.toDate()).inDays <= 30;
            } else if (orderCount == 0) {
              isNew = true;
            }

            return _buildMenuRowItem(
                title,
                data['short_desc'] ?? '',
                price,
                originalPrice,
                hasOffer,
                offerPercent,
                data['image'] ?? data['image_url'] ?? '',
                prepTime,
                category,
                subCategory,
                rating,
                orderCount,
                isNew);
          },
        );
      },
    );
  }

  // --- UPDATED MENU ROW TO SHOW OFFER ---
  Widget _buildMenuRowItem(
      String title,
      String subtitle,
      num price,
      num originalPrice,
      bool hasOffer,
      num offerPercent,
      String imagePath,
      String prepTime,
      String category,
      String subCategory,
      num rating,
      int orderCount,
      bool isNew) {
    final int quantity = _cartManager.getQuantity(title);
    String ratingStr = rating.toStringAsFixed(1);
    Color ratingColor = _getRatingColor(rating);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FoodDetailScreen(
                  title: title,
                  subtitle: subtitle,
                  price: "₹$price",
                  imagePath: imagePath))).then((_) => setState(() {})),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFCFEFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTag(orderCount, rating, isNew),
                  if (_buildTag(orderCount, rating, isNew) is! SizedBox)
                    const SizedBox(height: 6),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // --- SHOW CROSSED OUT PRICE IF OFFER EXISTS ---
                      if (hasOffer)
                        Text("₹$originalPrice",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough)),
                      if (hasOffer) const SizedBox(width: 6),
                      Text("₹$price",
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),

                      const SizedBox(width: 12),
                      if (rating > 0) // Hide if 0.0
                        Row(children: [
                          Icon(Icons.star, size: 14, color: ratingColor),
                          const SizedBox(width: 4),
                          Text(ratingStr,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: ratingColor))
                        ])
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(fit: StackFit.expand, children: [
                          ImageFiltered(
                              imageFilter:
                                  ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: _buildImage(imagePath, fit: BoxFit.cover)),
                          Container(color: Colors.white.withOpacity(0.15)),
                          _buildImage(imagePath, fit: BoxFit.contain)
                        ]))),

                // --- SHOW ORANGE OFFER BADGE IN CORNER ---
                if (hasOffer)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange
                              .withOpacity(0.8), // TRANSLUCENT ORANGE
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(8))),
                      child: Text("${offerPercent.toInt()}% OFF",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                // --- SHOW TIME BADGE IN OPPOSITE CORNER ---
                Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(8)),
                            border: Border(
                                bottom:
                                    BorderSide(color: Colors.green.shade200),
                                left:
                                    BorderSide(color: Colors.green.shade200))),
                        child: Row(children: [
                          const Icon(Icons.access_time,
                              size: 8, color: Colors.green),
                          const SizedBox(width: 2),
                          Text(prepTime,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87))
                        ]))),

                Positioned(
                    bottom: -10,
                    child: _buildSmallAddButton(title, subtitle, price,
                        imagePath, quantity, category, subCategory)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED MENU CARD TO SHOW OFFER ---
  Widget _buildMenuCard(
      String title,
      String subtitle,
      num price,
      num originalPrice,
      bool hasOffer,
      num offerPercent,
      String imagePath,
      String prepTime,
      String category,
      String subCategory,
      num rating,
      int orderCount,
      bool isNew) {
    final int quantity = _cartManager.getQuantity(title);
    String ratingStr = rating.toStringAsFixed(1);
    Color ratingColor = _getRatingColor(rating);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FoodDetailScreen(
                  title: title,
                  subtitle: subtitle,
                  price: "₹$price",
                  imagePath: imagePath))).then((_) => setState(() {})),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10), // Keep padding tight
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION WITH BLUR BACKGROUND
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(fit: StackFit.expand, children: [
                      ImageFiltered(
                        imageFilter:
                            ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Transform.scale(
                          scale: 1.2,
                          child: _buildImage(imagePath, fit: BoxFit.cover),
                        ),
                      ),
                      Container(color: Colors.white.withOpacity(0.6)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImage(imagePath, fit: BoxFit.contain),
                        ),
                      ),
                    ]),
                  ),
                ),

                // --- SHOW ORANGE OFFER BADGE IN CORNER ---
                if (hasOffer)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange
                            .withOpacity(0.8), // TRANSLUCENT ORANGE
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(8)),
                      ),
                      child: Text("${offerPercent.toInt()}% OFF",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),

                // --- SHOW TIME BADGE IN OPPOSITE CORNER ---
                Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(8)),
                            border: Border(
                                bottom:
                                    BorderSide(color: Colors.green.shade200),
                                left:
                                    BorderSide(color: Colors.green.shade200))),
                        child: Row(children: [
                          const Icon(Icons.access_time,
                              size: 8, color: Colors.green),
                          const SizedBox(width: 3),
                          Text(prepTime,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87))
                        ]))),
              ],
            ),

            const SizedBox(height: 8),

            // TEXT & ACTION SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTag(orderCount, rating, isNew),
                  if (_buildTag(orderCount, rating, isNew) is! SizedBox)
                    const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (rating > 0)
                    Row(children: [
                      Icon(Icons.star, size: 12, color: ratingColor),
                      const SizedBox(width: 3),
                      Text(ratingStr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ratingColor))
                    ]),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // --- UPDATED PRICING DISPLAY ---
                      Flexible(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasOffer)
                            Text("₹$originalPrice",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1)),
                          Text("₹$price",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  height: 1),
                              overflow: TextOverflow.ellipsis),
                        ],
                      )),
                      _buildSmallAddButton(title, subtitle, price, imagePath,
                          quantity, category, subCategory),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAddButton(String title, String subtitle, num price,
      String imagePath, int quantity, String category, String subCategory) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () => _incrementQuantity(
            title, subtitle, price, imagePath, category, subCategory),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]),
            child: const Text("ADD",
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
                onTap: () => _decrementQuantity(title),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(Icons.remove, size: 14, color: Colors.green))),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('$quantity',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green))),
            GestureDetector(
                onTap: () => _incrementQuantity(
                    title, subtitle, price, imagePath, category, subCategory),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(Icons.add, size: 14, color: Colors.green))),
          ],
        ),
      );
    }
  }

  Widget _buildFloatingCartBanner(double cartTotal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CartScreen(newItem: {})))
            .then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            color: mcdLightGreen,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "${_cartManager.itemCount} Item${_cartManager.itemCount > 1 ? 's' : ''}  |  ₹${cartTotal.toStringAsFixed(0)}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Row(children: const [
              Text("View Cart",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.arrow_right, color: Colors.white, size: 20)
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildModernNavItem(IconData icon, String label, int index,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DealsScreen()))
              .then((_) => setState(() {}));
        } else if (index == 2) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: MediaQuery.of(context).size.width / 3.2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.shade100.withOpacity(0.6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(icon,
                  size: isActive ? 24 : 22,
                  color:
                      isActive ? Colors.green.shade800 : Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color:
                      isActive ? Colors.green.shade800 : Colors.grey.shade500,
                  fontFamily: 'Poppins'),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String firstName = userName.trim().split(RegExp(r'\s+')).first;
    if (firstName.isNotEmpty) {
      firstName =
          firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
    }

    double cartTotal = 0;
    for (var item in _cartManager.cartItems) {
      double price =
          double.tryParse(item['price'].toString().replaceAll('₹', '')) ?? 0;
      int qty = item['quantity'] ?? 1;
      cartTotal += (price * qty);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ]),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModernNavItem(Icons.home_rounded, "Home", 0,
                  isActive: true),
              _buildModernNavItem(Icons.local_offer, "Deals", 1,
                  isActive: false),
              _buildModernNavItem(Icons.receipt_long_outlined, "Orders", 2,
                  isActive: false),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: _cartManager.itemCount > 0 ? 80 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // --- NEW ROW 1: PROFILE & NOTIFICATIONS (AT THE VERY TOP) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen())),
                            child: Row(
                              children: [
                                Container(
                                  height: 45,
                                  width: 45,
                                  decoration: BoxDecoration(
                                      color: themeColor,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.person,
                                      color: Colors.black54, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Welcome back,",
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    Text(firstName,
                                        style: TextStyle(
                                            color: darkGreen,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .orderBy('timestamp', descending: true)
                                  .limit(10)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  var docs = snapshot.data!.docs.where((doc) {
                                    var d = doc.data() as Map<String, dynamic>;
                                    return d['userId'] == user?.uid ||
                                        d['type'] == 'general' ||
                                        d['type'] == 'alert' ||
                                        d['type'] == 'refund';
                                  }).toList();
                                  var unreadDocs = docs
                                      .where((d) =>
                                          (d.data() as Map<String, dynamic>)[
                                              'isRead'] ==
                                          false)
                                      .toList();
                                  unreadCount = unreadDocs.length;
                                }
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const NotificationScreen())),
                                      child: Container(
                                        height: 45,
                                        width: 45,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFC1E1CA),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                            Icons.notifications_outlined,
                                            color: darkGreen,
                                            size: 24),
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2)),
                                          child: Text('$unreadCount',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                  ],
                                );
                              }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- NEW ROW 2: SEARCH, FILTER & FAVORITE (HEIGHT DECREASED TO 42) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SearchPage())),
                              child: Container(
                                height: 42,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.grey.shade200)),
                                child: Row(
                                  children: [
                                    Icon(Icons.search,
                                        color: Colors.grey.shade500, size: 20),
                                    const SizedBox(width: 10),
                                    Text("Search for food...",
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFilterVisible = !_isFilterVisible;
                              });
                            },
                            child: Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                    color: _isFilterVisible
                                        ? themeColor
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: _isFilterVisible
                                            ? darkGreen
                                            : Colors.grey.shade200)),
                                child: Icon(Icons.tune,
                                    color: _isFilterVisible
                                        ? darkGreen
                                        : Colors.black54,
                                    size: 20)),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const FavoriteScreen()))
                                .then((_) => setState(() {})),
                            child: Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.favorite_border,
                                      color: Colors.black54, size: 20),
                                  if (_favoriteManager.favoriteItems.isNotEmpty)
                                    Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle),
                                            child: Text(
                                                '${_favoriteManager.favoriteItems.length}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isFilterVisible)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 15, left: 20, right: 20),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filterOptions.map((filter) {
                            bool isSelected = _selectedFilterOption == filter;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedFilterOption =
                                    isSelected ? "" : filter;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                    color:
                                        isSelected ? themeColor : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade300)),
                                child: Text(filter,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.green.shade800
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),
                    if (user != null) _buildUnseenRefundBanners(user.uid),
                    _buildAnnouncementCarousel(),
                    if (user != null) _buildActiveOrderStatus(user.uid),

                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text("Categories",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 80,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('categories')
                            .orderBy('order')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.green));
                          var docs = snapshot.data!.docs;
                          List<Map<String, dynamic>> allCats = docs
                              .map((d) => d.data() as Map<String, dynamic>)
                              .toList();
                          int dbAllIndex = allCats.indexWhere((c) =>
                              (c['name'] ?? '').toString().toLowerCase() ==
                              'all');
                          if (dbAllIndex != -1) {
                            var temp = allCats.removeAt(dbAllIndex);
                            allCats.insert(0, temp);
                          } else {
                            allCats.insert(0,
                                {'name': 'All', 'image': 'assets/snacks.png'});
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: allCats.length,
                            itemBuilder: (context, index) {
                              var catData = allCats[index];
                              return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _categoryBox(
                                      catData['name'] ?? 'Unknown',
                                      catData['image'] ?? ''));
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _selectedCategory == "All"
                        ? _buildAllCategoriesLayout()
                        : _buildSubCategoryLayout(_selectedCategory),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _cartManager.itemCount > 0 ? 10 : -100,
              left: 16,
              right: 16,
              child: _buildFloatingCartBanner(cartTotal),
            )
          ],
        ),
      ),
    );
  }
}
