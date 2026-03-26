// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
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
  final Map<String, TextEditingController> _commentControllers = {};
  bool _isLoading = false;

  // Elegant pastel theme colors
  final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);

  @override
  void initState() {
    super.initState();
    // Initialize a rating and a text controller for EACH item
    for (var item in widget.orderItems) {
      String name = item['title'] ?? item['name'] ?? 'Unknown Item';
      _ratings[name] = 5.0;
      _commentControllers[name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Clean up all controllers
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // --- 1. CALCULATE OVERALL RATING & COMPILE COMMENTS ---
      double totalStars = 0;
      Map<String, String> itemComments = {};
      List<String> combinedMessageParts = [];

      _ratings.forEach((key, value) {
        totalStars += value;
        String comment = _commentControllers[key]?.text.trim() ?? "";
        itemComments[key] = comment;
        if (comment.isNotEmpty) {
          combinedMessageParts.add("$key: $comment");
        }
      });

      double avgRating = totalStars / _ratings.length;
      if (avgRating.isNaN) avgRating = 5.0;
      
      // A fallback string for the admin panel's general view
      String combinedMessage = combinedMessageParts.join(" | ");

      // --- 2. SAVE TO 'feedbacks' COLLECTION ---
      DocumentReference feedbackRef =
          FirebaseFirestore.instance.collection('feedbacks').doc();

      batch.set(feedbackRef, {
        'orderId': widget.orderId,
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Student',
        'items': widget.orderItems.map((e) => e['title'] ?? e['name']).toList(),
        'itemRatings': _ratings, // Detailed star ratings per item
        'itemComments': itemComments, // Detailed text feedback per item
        'rating': avgRating, // Overall rating
        'message': combinedMessage, // Combined fallback message
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- 3. UPDATE MENU ITEM RATINGS ---
      for (var item in widget.orderItems) {
        String itemName = item['title'] ?? item['name'] ?? 'Unknown Item';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Feedback Sent Successfully!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green));
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
            .showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
            child: Icon(Icons.fastfood, color: Colors.grey, size: 20)),
      );
    }
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data), fit: BoxFit.cover);
      }
      if (path.startsWith('http')) {
        return Image.network(path,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image, color: Colors.grey));
      }
      return Image.asset(path,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.error, color: Colors.grey));
    } catch (e) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
            child: Icon(Icons.broken_image, size: 20, color: Colors.red)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Clean white background
      appBar: AppBar(
          title: const Text("Rate Your Meal", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black87)),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.black87),
          elevation: 0),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryLightGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("How was the food?",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)), // Reduced bold
                  const SizedBox(height: 8),
                  Text("Rate each item and share your thoughts to help us improve.",
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 25),
                  
                  // --- DYNAMIC ITEM REVIEWS ---
                  ...widget.orderItems.map((item) {
                    String name = item['title'] ?? item['name'] ?? 'Unknown Item';
                    String imagePath = item['imagePath'] ?? item['image'] ?? item['image_url'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryLightGreen.withOpacity(0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4)
                            )
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Image & Name
                          Row(
                            children: [
                              Container(
                                height: 45,
                                width: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildImage(imagePath),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600)), // Semi-bold
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1, color: Colors.black12),
                          ),
                          
                          // Stars Row
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(
                                      () => _ratings[name] = index + 1.0),
                                  icon: Icon(
                                      index < (_ratings[name] ?? 0)
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber.shade400,
                                      size: 36),
                                );
                              })),
                          
                          const SizedBox(height: 16),
                          
                          // Individual Comment Field
                          TextField(
                            controller: _commentControllers[name],
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                                hintText: "Tell us about the $name...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 10),
                  
                  // --- SUBMIT BUTTON ---
                  SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryLightGreen, // Pastel green
                            foregroundColor: Colors.black87, // Dark text for contrast
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text("Submit Feedback",
                            style: TextStyle(
                                fontSize: 15,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600)), // Semi-bold
                      )),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}