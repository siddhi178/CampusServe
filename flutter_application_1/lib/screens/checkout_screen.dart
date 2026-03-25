// ignore_for_file: deprecated_member_use, unnecessary_cast, duplicate_ignore, unnecessary_to_list_in_spreads
import 'dart:convert';
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
    _generateSmartRecommendations();
  }

  Future<void> _generateSmartRecommendations() async {
    if (!mounted) return;
    Map<String, double> itemScores = {};

    try {
      var allItemsSnap = await FirebaseFirestore.instance
          .collection('menu')
          .where('is_available', isEqualTo: true)
          .get();
      var allItems = allItemsSnap.docs;

      List<Map<String, dynamic>> cart = _cartManager.cartItems;
      final Set<String> cartItemNames =
          cart.map((i) => i['title'].toString().toLowerCase().trim()).toSet();

      const westernCats = ['Fast Food', 'Baked', 'Milkshakes'];
      const indianCats = [
        'Paneer Dishes',
        'Indian Items',
        'Roti/Bread',
        'Rice Items',
        'Fried Snacks'
      ];

      const Map<String, List<String>> pairingMatrix = {
        'Paneer Dishes': ['Roti/Bread', 'Rice Items', 'Cold Drinks'],
        'Indian Items': ['Roti/Bread', 'Rice Items'],
        'Fried Snacks': ['Hot Drinks'],
        'Fast Food': ['Cold Drinks', 'Milkshakes', 'Desserts'],
        'Roti/Bread': ['Paneer Dishes', 'Indian Items'],
      };

      Set<String> subCatsInCart = {};
      Set<String> mainCatsInCart = {};

      for (var item in cart) {
        String sCat = (item['sub_category'] ?? '').toString().trim();
        String mCat = (item['category'] ?? '').toString().trim();
        if (sCat.isNotEmpty) subCatsInCart.add(sCat);
        if (mCat.isNotEmpty) mainCatsInCart.add(mCat);
      }

      bool cartHasIndian = subCatsInCart.any((s) => indianCats.contains(s));
      bool cartHasWestern = subCatsInCart.any((s) => westernCats.contains(s));

      for (var doc in allItems) {
        var itemData = doc.data() as Map<String, dynamic>;
        String name = itemData['name'] ?? 'Unknown';
        String itemSubCat = (itemData['sub_category'] ?? '').toString().trim();
        String itemMainCat = (itemData['category'] ?? '').toString().trim();

        // Prevent recommending deals/combos in the pairing section
        if (itemMainCat == 'Deals') continue;

        double score = 0;

        if (cartItemNames.contains(name.toLowerCase().trim())) continue;

        // RULE A: Direct Pairing
        for (String cartSubCat in subCatsInCart) {
          if (pairingMatrix.containsKey(cartSubCat) &&
              pairingMatrix[cartSubCat]!.contains(itemSubCat)) {
            score += 250;
          }
        }

        // RULE B: Cultural Harmony
        if (cartHasIndian && westernCats.contains(itemSubCat)) {
          score -= 300;
        }
        if (cartHasWestern &&
            indianCats.contains(itemSubCat) &&
            itemSubCat != 'Fried Snacks') {
          score -= 300;
        }

        // RULE C: Same-Subcategory (Discovery)
        if (subCatsInCart.contains(itemSubCat)) {
          score += 40;
        }

        // RULE D: Beverage Logic
        if (itemMainCat == 'Beverages') {
          if (cartHasIndian && itemSubCat == 'Hot Drinks') score += 100;
          if (cartHasWestern &&
              (itemSubCat == 'Cold Drinks' || itemSubCat == 'Milkshakes')) {
            score += 100;
          }
        }

        if (score > 0) {
          itemScores[name] = score;
        }
      }

      List<Map<String, dynamic>> resultList = allItems
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
                'score': itemScores[doc['name']] ?? 0
              })
          .where((item) => (item['score'] as double) > 0)
          .toList();

      resultList.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double));

      if (mounted) {
        setState(() {
          _recommendedItems = resultList.take(4).toList();
          _isLoadingRecs = false;
        });
      }
    } catch (e) {
      debugPrint("Recommendation Error: $e");
      if (mounted) setState(() => _isLoadingRecs = false);
    }
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) return const Icon(Icons.fastfood, color: Colors.grey);
    try {
      if (path.startsWith('data:image')) {
        String base64Data = path
            .substring(path.indexOf(',') + 1)
            .replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data), fit: fit);
      }
      return Image.network(path,
          fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemTotal = _cartManager.totalPrice;
    final double gst = itemTotal * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Checkout",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ORDER SUMMARY ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE8F5E9), // Matching Recommendation Color
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color.fromARGB(160, 61, 170, 6),
                      width: 1), // Matching Recommendation Border
                ),
                child: Column(
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Order Summary",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                                  "${item['title']} x ${item['quantity']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87)),
                            ),
                            Text(
                                "₹${(price * item['quantity']).toStringAsFixed(1)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 25, color: Colors.black12),
                    _row("Item Total", "₹${itemTotal.toInt()}"),
                    _row("GST (5%):", "₹${gst.toInt()}"),
                    const Divider(height: 25, color: Colors.black12),
                    _row("Grand Total:", "₹${(itemTotal + gst).toInt()}",
                        isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text("Pair it with...",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // --- SMART RECOMMENDATION LIST ---
              SizedBox(
                height: 200,
                child: _isLoadingRecs
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green))
                    : _recommendedItems.isEmpty
                        ? const Text("No pairings available right now",
                            style: TextStyle(color: Colors.grey))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recommendedItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildMenuCard(_recommendedItems[index]),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PaymentMethodScreen(
                              amountToPay: itemTotal + gst))),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA5D6A7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text("Add payment Method",
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- DESIGN: EXACT MATCH TO HOME SCREEN ---
  Widget _buildMenuCard(Map<String, dynamic> data) {
    String title = data['name'] ?? '';
    num price = data['price'] ?? 0;
    String imagePath = data['image_url'] ?? data['image'] ?? '';

    // Safely parse times since some items (like deals) might not have them natively
    String minT = data['time_min']?.toString() ?? '5';
    String maxT = data['time_max']?.toString() ?? '10';
    String prepTime = "$minT-$maxT min";

    return Container(
      width: 135,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color.fromARGB(82, 232, 255, 239),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color.fromARGB(160, 61, 170, 6))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: _buildImage(imagePath, fit: BoxFit.cover))),
            Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    const Icon(Icons.access_time,
                        size: 10, color: Colors.green),
                    const SizedBox(width: 2),
                    Text(prepTime,
                        style: const TextStyle(
                            fontSize: 8, fontWeight: FontWeight.bold)),
                  ]),
                )),
          ]),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(data['category'] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹$price",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
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
                  _generateSmartRecommendations();
                  setState(() {});
                },
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green)),
                    child:
                        const Icon(Icons.add, size: 16, color: Colors.green)),
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
                color: Colors.black87,
                fontSize: isBold ? 17 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: Colors.black87,
                fontSize: isBold ? 17 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
