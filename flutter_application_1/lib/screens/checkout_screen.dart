// ignore_for_file: deprecated_member_use, unnecessary_cast, duplicate_ignore, unnecessary_to_list_in_spreads

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_manager.dart';
import 'payment_method_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double grandTotal;
  const CheckoutScreen({super.key, required this.grandTotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartManager _cartManager = CartManager();
  List<Map<String, dynamic>> _recommendedItems = [];
  bool _isLoadingRecs = true;

  @override
  void initState() {
    super.initState();
    _generateRandomRecommendations();
  }

  // --- REPLACED WITH RANDOM RECOMMENDATIONS ---
  Future<void> _generateRandomRecommendations() async {
    if (!mounted) return;

    try {
      // Fetch all available items
      var allItemsSnap = await FirebaseFirestore.instance
          .collection('menu')
          .where('is_available', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> cart = _cartManager.cartItems;
      final Set<String> cartItemNames =
          cart.map((i) => i['title'].toString().toLowerCase().trim()).toSet();

      List<Map<String, dynamic>> availableRecs = [];

      for (var doc in allItemsSnap.docs) {
        var itemData = doc.data();
        String name = itemData['name'] ?? 'Unknown';
        String itemMainCat = (itemData['category'] ?? '').toString().trim();

        // Prevent recommending deals in the pairing section
        if (itemMainCat == 'Deals') continue;
        // Prevent recommending items already in the cart
        if (cartItemNames.contains(name.toLowerCase().trim())) continue;

        itemData['id'] = doc.id;
        availableRecs.add(itemData);
      }

      // Shuffle the list to get random items every time
      availableRecs.shuffle(Random());

      if (mounted) {
        setState(() {
          // Take the first 4 random items
          _recommendedItems = availableRecs.take(4).toList();
          _isLoadingRecs = false;
        });
      }
    } catch (e) {
      debugPrint("Recommendation Error: $e");
      if (mounted) setState(() => _isLoadingRecs = false);
    }
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) return const Icon(Icons.fastfood, color: Colors.grey, size: 24);
    try {
      if (path.startsWith('data:image')) {
        String base64Data = path
            .substring(path.indexOf(',') + 1)
            .replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data), fit: fit);
      }
      return Image.network(path,
          fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey));
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemTotal = _cartManager.totalPrice;
    final double platformFee = itemTotal > 0 ? 5.00 : 0.00;
    final double gst = itemTotal * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Clean white background
      appBar: AppBar(
        title: const Text("Checkout",
            style: TextStyle(
                color: Colors.black87, 
                fontSize: 18, 
                fontWeight: FontWeight.w600)), // Reduced bold
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ELEGANT ORDER SUMMARY ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.green.shade100, 
                      width: 1.5), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4)
                    )
                  ]
                ),
                child: Column(
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Order Summary",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600, // Reduced bold
                                color: Colors.black87))),
                    const Divider(height: 25, color: Colors.black12),
                    ..._cartManager.cartItems.map((item) {
                      double price = double.tryParse(
                              item['price'].toString().replaceAll('₹', '')) ??
                          0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  "${item['title']}  x ${item['quantity']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.w500, // Medium weight
                                      color: Colors.black87)),
                            ),
                            Text(
                                "₹${(price * item['quantity']).toStringAsFixed(1)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, // Semi-bold
                                    fontSize: 14,
                                    color: Colors.black87)),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 25, color: Colors.black12),
                    _row("Item Total", "₹${itemTotal.toStringAsFixed(2)}"),
                    const SizedBox(height: 8),
                    _row("Platform Fee", "₹${platformFee.toStringAsFixed(2)}"),
                    const SizedBox(height: 8),
                    _row("GST (5%)", "₹${gst.toStringAsFixed(2)}"),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    _row("Grand Total", "₹${widget.grandTotal.toStringAsFixed(2)}",
                        isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text("Pair it with...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)), // Reduced bold
              const SizedBox(height: 12),

              // --- SMART RECOMMENDATION LIST ---
              SizedBox(
                height: 200,
                child: _isLoadingRecs
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green))
                    : _recommendedItems.isEmpty
                        ? Center(
                            child: Text("No pairings available right now",
                                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: _recommendedItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12, bottom: 8),
                                child: _buildMenuCard(_recommendedItems[index]),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 30),
              
              // --- ELEGANT ADD PAYMENT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PaymentMethodScreen(
                              amountToPay: widget.grandTotal))),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 173, 227, 176), // Premium Dark Green
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Add Payment Method",
                          style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w500)), // Reduced bold
                      SizedBox(width: 8),
                      Icon(Icons.payment, size: 20)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- ELEGANT RECOMMENDATION CARD ---
  Widget _buildMenuCard(Map<String, dynamic> data) {
    String title = data['name'] ?? '';
    num price = data['price'] ?? 0;
    String imagePath = data['image_url'] ?? data['image'] ?? '';

    String minT = data['time_min']?.toString() ?? '5';
    String maxT = data['time_max']?.toString() ?? '10';
    String prepTime = "$minT-$maxT min";

    return Container(
      width: 140, // Slightly wider for elegance
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3)
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                    height: 85,
                    width: double.infinity,
                    child: _buildImage(imagePath, fit: BoxFit.cover))),
            Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(8)
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.green.shade100),
                        left: BorderSide(color: Colors.green.shade100)
                      )),
                  child: Row(children: [
                    const Icon(Icons.access_time,
                        size: 10, color: Color.fromRGBO(76, 175, 80, 1)),
                    const SizedBox(width: 3),
                    Text(prepTime,
                        style: const TextStyle(
                            fontSize: 8, 
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)), // Reduced bold
                  ]),
                )),
          ]),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)), // Reduced bold
          Text(data['category'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.normal)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹$price",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)), // Reduced bold
              GestureDetector(
                onTap: () {
                  _cartManager.addItem(
                    title,
                    data['short_desc'] ?? '',
                    "₹$price",
                    imagePath,
                    data['category'] ?? 'General',
                    data['sub_category'] ?? 'General',
                    prepTime: int.tryParse(maxT) ?? 10,
                  );
                  // Refresh recommendations to avoid suggesting what was just added
                  _generateRandomRecommendations();
                  setState(() {});
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color.fromRGBO(129, 199, 132, 1), width: 1.2)),
                    child:
                        const Text("ADD", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isBold ? Colors.black87 : Colors.grey.shade600,
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)), // Lightened weights
        Text(value,
            style: TextStyle(
                color: Colors.black87,
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500)), // Lightened weights
      ],
    );
  }
}