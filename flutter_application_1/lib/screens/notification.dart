// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'track_order_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Elegant Theme Colors
  final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);
  final Color darkGreenText = const Color(0xFF1B5E20);
  String _selectedFilter = 'All';

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  // --- DELETE NOTIFICATION ON SWIPE ---
  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  // --- RESOLVE REFUND SELECTION FROM NOTIFICATION ---
  Future<void> _handleUserRefundChoice(
      String notifId, String orderId, String complainId, String choice) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderSnap.exists) return;
      double amount = (orderSnap.data() as Map<String, dynamic>)['totalAmount']
              ?.toDouble() ??
          0.0;

      String timeNow = DateFormat('dd MMM, hh:mm a').format(DateTime.now());

      if (choice == 'Wallet') {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          DocumentSnapshot userDoc = await transaction.get(userRef);

          double currentBal = 0.0;
          String userName = "Student";
          if (userDoc.exists) {
            currentBal =
                (userDoc.data() as Map<String, dynamic>)['wallet_balance']
                        ?.toDouble() ??
                    0.0;
            userName =
                (userDoc.data() as Map<String, dynamic>)['name'] ?? "Student";
          }

          transaction.set(userRef, {'wallet_balance': currentBal + amount},
              SetOptions(merge: true));

          DocumentReference txnRef =
              FirebaseFirestore.instance.collection('transactions').doc();
          transaction.set(txnRef, {
            'userId': user.uid,
            'userName': userName,
            'amount': amount,
            'type': 'Credit',
            'method': 'Refund',
            'status': 'Success',
            'description': 'Dispute Resolved (Wallet)',
            'timestamp': FieldValue.serverTimestamp()
          });

          transaction.update(
              FirebaseFirestore.instance.collection('orders').doc(orderId), {
            'status': 'Cancelled',
            'refundMethod': 'Wallet (Dispute Resolved)',
            'refundVerified': true,
            'resolvedAt': FieldValue.serverTimestamp(),
            'activityLogs':
                FieldValue.arrayUnion(['Resolved to Wallet Refund on $timeNow'])
          });

          if (complainId.isNotEmpty) {
            transaction.update(
                FirebaseFirestore.instance
                    .collection('complaints')
                    .doc(complainId),
                {
                  'status': 'Resolved',
                  'adminReply':
                      'User opted for Wallet Refund. Amount ₹$amount added to wallet.',
                  'replyTimestamp': FieldValue.serverTimestamp()
                });
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("₹$amount instantly added to Campus Wallet!"),
            backgroundColor: Colors.green));
      } else if (choice == 'Cash') {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': 'Cash Refund Requested',
          'refundMethod': 'Cash (Dispute)',
          'cashRequestTime':
              FieldValue.serverTimestamp(), // Used for 24h tracking
          'activityLogs':
              FieldValue.arrayUnion(['User selected Cash Refund on $timeNow'])
        });

        if (complainId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('complaints')
              .doc(complainId)
              .update({
            'adminReply':
                'User selected CASH. Waiting for admin to hand over cash.',
            'replyTimestamp': FieldValue.serverTimestamp()
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "You selected collect cash from the counter. Please go today and collect the cash from the counter."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ));
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notifId)
          .update({'actionTaken': true, 'isRead': true});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleNotificationTap(
      Map<String, dynamic> data, String docId, bool isRead) async {
    // Mark as read immediately to remove the unread dot
    if (!isRead) {
      await _markAsRead(docId);
    }
    
    // Navigate to order if applicable
    if (data['targetId'] != null &&
        data['targetId'].toString().isNotEmpty &&
        data['type'] != 'resolution_request') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackOrderScreen(orderId: data['targetId']),
        ),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
      case 'cancelled':
        return Icons.warning_amber_rounded;
      case 'refund':
      case 'resolution_request':
        return Icons.account_balance_wallet_outlined;
      case 'offer':
      case 'new':
        return Icons.local_offer_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
      case 'cancelled':
        return Colors.red.shade500;
      case 'refund':
      case 'resolution_request':
        return Colors.orange.shade500;
      case 'offer':
      case 'new':
        return Colors.blue.shade500;
      case 'announcement':
        return Colors.purple.shade500;
      default:
        return Colors.green.shade600;
    }
  }

  String _formatTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
      case 'cancelled':
        return 'Alerts';
      case 'refund':
      case 'resolution_request':
        return 'Refunds';
      case 'offer':
      case 'new':
        return 'Offers';
      case 'announcement':
        return 'Announcements';
      default:
        return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text("Please login to see notifications.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Clean white background
      appBar: AppBar(
        title: const Text("Notifications",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18)), // Medium bold
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryLightGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: primaryLightGreen.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text("No notifications right now.",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          var allDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['userId'] == user.uid ||
                data['type'] == 'general' ||
                data['type'] == 'alert' ||
                data['type'] == 'announcement' ||
                data['type'] == 'offer';
          }).toList();

          if (allDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: primaryLightGreen.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text("No notifications right now.",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          Set<String> availableFilters = {'All'};
          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String typeLabel = _formatTypeLabel(data['type'] ?? 'general');
            availableFilters.add(typeLabel);
          }

          List<String> filterList = availableFilters.toList();

          var filteredDocs = allDocs.where((doc) {
            if (_selectedFilter == 'All') return true;
            var data = doc.data() as Map<String, dynamic>;
            return _formatTypeLabel(data['type'] ?? 'general') ==
                _selectedFilter;
          }).toList();

          return Column(
            children: [
              // --- ELEGANT FILTER CHIPS ---
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filterList.length,
                  itemBuilder: (context, index) {
                    String filter = filterList[index];
                    bool isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryLightGreen.withOpacity(0.25) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? primaryLightGreen
                                  : Colors.grey.shade200, width: 1.2),
                        ),
                        child: Center(
                          child: Text(filter,
                              style: TextStyle(
                                  color: isSelected
                                      ? darkGreenText
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    String docId = filteredDocs[index].id;
                    
                    bool isRead = data['isRead'] ?? false;
                    bool actionTaken = data['actionTaken'] ?? false;
                    String type = data['type'] ?? 'general';
                    Timestamp? ts = data['timestamp'];

                    String tokenMatch = "";
                    RegExp regExp = RegExp(r'Token (T-\d+)');
                    Match? match = regExp.firstMatch(data['message'] ?? '');
                    if (match != null) {
                      tokenMatch = match.group(1) ?? '';
                    }

                    Color iconColor = _getColorForType(type);
                    IconData iconData = _getIconForType(type);

                    // --- ELEGANT NOTIFICATION CARD (NEVER GREYS OUT) ---
                    return Dismissible(
                      key: Key(docId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteNotification(docId);
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            _handleNotificationTap(data, docId, isRead),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, // Always white
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isRead ? Colors.grey.shade100 : primaryLightGreen.withOpacity(0.5), 
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Colored Icon (Always retains color)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.1),
                                        shape: BoxShape.circle),
                                    child: Icon(iconData,
                                        color: iconColor,
                                        size: 20), 
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      data['title'] ??
                                                          'Notification',
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: TextStyle(
                                                          fontWeight: isRead
                                                              ? FontWeight.w500  // Normal if read
                                                              : FontWeight.bold, // Bold if unread
                                                          fontSize: 15,
                                                          color: Colors.black87),
                                                    ),
                                                  ),
                                                  if (tokenMatch.isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                          color: primaryLightGreen
                                                              .withOpacity(0.3), 
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6)),
                                                      child: Text(tokenMatch,
                                                          style: TextStyle(
                                                              color: darkGreenText,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                    )
                                                  ]
                                                ],
                                              ),
                                            ),
                                            // UNREAD INDICATOR DOT
                                            if (!isRead)
                                              Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                      color: Colors.blue.shade500, // Unread dot
                                                      shape: BoxShape.circle))
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(data['message'] ?? '',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700, // Always clear and readable
                                                height: 1.4)),
                                        const SizedBox(height: 10),
                                        Text(
                                            ts != null
                                                ? DateFormat('dd MMM, hh:mm a')
                                                    .format(ts.toDate())
                                                : 'Just now',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade400)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              if (type == 'resolution_request' &&
                                  !actionTaken) ...[
                                const SizedBox(height: 15),
                                const Divider(color: Colors.black12),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _handleUserRefundChoice(
                                                docId,
                                                data['targetId'],
                                                data['complainId'],
                                                'Wallet'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryLightGreen, 
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10))),
                                        child: const Text("Add to Wallet",
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _handleUserRefundChoice(
                                                docId,
                                                data['targetId'],
                                                data['complainId'],
                                                'Cash'),
                                        style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.orange.shade300),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10))),
                                        child: Text("Collect Cash",
                                            style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}