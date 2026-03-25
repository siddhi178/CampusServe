// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final List<dynamic> orderItems;
  final String orderId;

  const FeedbackScreen(
      {super.key, required this.orderItems, required this.orderId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final Map<String, double> _ratings = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.orderItems) {
      _ratings[item['title'] ?? item['name']] = 5.0;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // --- 1. CALCULATE OVERALL RATING ---
      double totalStars = 0;
      _ratings.forEach((key, value) => totalStars += value);
      double avgRating = totalStars / _ratings.length;
      if (avgRating.isNaN) avgRating = 5.0;

      // --- 2. SAVE TO 'feedbacks' COLLECTION (Synced with Admin) ---
      DocumentReference feedbackRef =
          FirebaseFirestore.instance.collection('feedbacks').doc();

      // Grab the exact text typed by the user, remove trailing spaces
      String userComment = _commentController.text.trim();

      batch.set(feedbackRef, {
        'orderId': widget.orderId,
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Student',
        'items': widget.orderItems.map((e) => e['title'] ?? e['name']).toList(),
        'itemRatings': _ratings, // Detailed ratings
        'rating': avgRating, // Overall rating for Admin Panel
        'message': userComment, // PERFECTLY SAVED COMMENT
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- 3. UPDATE MENU ITEM RATINGS ---
      for (var item in widget.orderItems) {
        String itemName = item['title'] ?? item['name'];
        double userRating = _ratings[itemName] ?? 5.0;

        QuerySnapshot menuQuery = await FirebaseFirestore.instance
            .collection('menu')
            .where('name', isEqualTo: itemName)
            .get();

        if (menuQuery.docs.isNotEmpty) {
          DocumentReference itemRef = menuQuery.docs.first.reference;
          Map<String, dynamic> data =
              menuQuery.docs.first.data() as Map<String, dynamic>;

          double currentAvg = (data['rating'] ?? 0.0).toDouble();
          int totalCount = (data['ratingCount'] ?? 0).toInt();

          double newAvg =
              ((currentAvg * totalCount) + userRating) / (totalCount + 1);

          batch.update(itemRef, {
            'rating': newAvg,
            'ratingCount': totalCount + 1,
          });
        }
      }

      // --- 4. MARK ORDER AS REVIEWED ---
      batch.update(
          FirebaseFirestore.instance.collection('orders').doc(widget.orderId),
          {'feedbackGiven': true});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Feedback Sent!")));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (r) => false,
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Rate Your Meal"),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("How was the food?",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  ...widget.orderItems.map((item) {
                    String name = item['title'] ?? item['name'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)),
                      child: Column(children: [
                        Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return IconButton(
                                onPressed: () => setState(
                                    () => _ratings[name] = index + 1.0),
                                icon: Icon(
                                    index < (_ratings[name] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 32),
                              );
                            }))
                      ]),
                    );
                  }),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        hintText: "Comments (Optional)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50]),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text("Submit Feedback",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ))
                ],
              ),
            ),
    );
  }
}
