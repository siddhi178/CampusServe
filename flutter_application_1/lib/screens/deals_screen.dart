// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, unused_element, prefer_final_fields

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_manager.dart';
import 'cart_screen.dart'; // Added so the floating cart button works

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final CartManager _cartManager = CartManager();
  final Color mcdLightGreen = const Color.fromARGB(184, 14, 78, 0);

  void _addToCartDirectly(Map<String, dynamic> data) {
    String title = data['name'] ?? 'Unknown Deal';
    String subtitle = data['short_desc'] ?? '';
    num price = data['price'] is String
        ? (num.tryParse(data['price']) ?? 0)
        : (data['price'] ?? 0);

    String firstImage = "";
    // SAFE CHECK: Prevents the red screen crash
    List<dynamic> comboImages = data['combo_images'] is List ? data['combo_images'] : [];
    
    if (comboImages.isNotEmpty) {
      firstImage = comboImages[0].toString();
    } else {
      firstImage = data['image_url']?.toString() ?? data['image']?.toString() ?? '';
    }

    _cartManager.addItem(
      title,
      subtitle,
      "₹$price",
      firstImage,
      data['category'] ?? 'Deals',
      data['sub_category'] ?? '',
      prepTime: int.tryParse(data['time_max']?.toString() ?? '10') ?? 10,
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title added to cart!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {}); // Update the screen to show the floating cart
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

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
            child: Icon(Icons.fastfood, color: Colors.grey, size: 18)),
      );
    }
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data),
            fit: BoxFit.cover, gaplessPlayback: true);
      }
      if (path.startsWith('http')) {
        return Image.network(path, fit: BoxFit.cover, gaplessPlayback: true);
      }
      return Image.asset(path, fit: BoxFit.cover, gaplessPlayback: true);
    } catch (e) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(
            child: Icon(Icons.broken_image, color: Colors.red, size: 18)),
      );
    }
  }

  Widget _buildComboImages(List<dynamic> images) {
    List<Widget> imageWidgets = [];
    double imageSize = images.length > 2 ? 55.0 : 70.0; 

    for (int i = 0; i < images.length; i++) {
      imageWidgets.add(Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildImage(images[i].toString())),
      ));

      if (i < images.length - 1) {
        imageWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
              child: Text("+",
                  style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400))), 
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: imageWidgets),
    );
  }

  Widget _buildSmallAddButton(String title, String subtitle, num price,
      String imagePath, int quantity, String category, String subCategory, Map<String, dynamic> rawData) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () => _addToCartDirectly(rawData),
        child: Container(
          width: 85,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade400, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2)
              )
            ]
          ),
          child: const Center(
            child: Text("ADD",
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600, 
                    letterSpacing: 0.8, 
                    fontSize: 12)),
          ),
        ),
      );
    } else {
      return Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade400, width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
                onTap: () => _decrementQuantity(title),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.remove, size: 14, color: Colors.green))),
            Text('$quantity',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.green)),
            GestureDetector(
                onTap: () => _addToCartDirectly(rawData),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
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
                    fontWeight: FontWeight.w600)),
            Row(children: const [
              Text("View Cart",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.arrow_right, color: Colors.white, size: 20)
            ])
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double cartTotal = 0;
    for (var item in _cartManager.cartItems) {
      double price =
          double.tryParse(item['price'].toString().replaceAll('₹', '')) ?? 0;
      int qty = item['quantity'] ?? 1;
      cartTotal += (price * qty);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), 
      appBar: AppBar(
        title: const Text("Deals & Combos",
            style: TextStyle(
                color: Colors.black87, 
                fontSize: 20, 
                fontWeight: FontWeight.w600)), 
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu')
                  .where('is_available', isEqualTo: true)
                  .where('category', isEqualTo: 'Deals')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 60, color: Colors.green.shade200), 
                        const SizedBox(height: 16),
                        const Text("No Active Combos Right Now",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500, 
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(
                            "Check back later for exciting\nbundles of your favorite meals!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, 
                                height: 1.3,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                final deals = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 15,
                      bottom: _cartManager.itemCount > 0 ? 80 : 20),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    var data = deals[index].data() as Map<String, dynamic>;

                    String title = data['name'] ?? 'Unknown Deal';
                    String subtitle = data['short_desc'] ?? '';
                    num price = data['price'] is String
                        ? (num.tryParse(data['price']) ?? 0)
                        : (data['price'] ?? 0);
                    num originalPrice = data['original_price'] ?? price;
                    num offerPercent = data['offer_percentage'] ?? 0;

                    List<dynamic> comboImages = data['combo_images'] is List ? data['combo_images'] : [];
                    String firstImage = comboImages.isNotEmpty ? comboImages[0].toString() : (data['image_url']?.toString() ?? data['image']?.toString() ?? '');

                    int quantity = _cartManager.getQuantity(title);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.green.shade100, width: 1.5), 
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.green.withOpacity(0.06), 
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: offerPercent > 0 ? 55.0 : 0),
                                  child: Text(title,
                                      style: const TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.w600, 
                                          color: Colors.black87)),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center, 
                                  children: [
                                    Expanded(
                                      child: comboImages.isNotEmpty
                                          ? _buildComboImages(comboImages)
                                          : Container(
                                              height: 70,
                                              width: 70,
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F8F2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                  child: Icon(Icons.fastfood,
                                                      color: Colors.green.shade300, size: 24)),
                                            ),
                                    ),

                                    const SizedBox(width: 16), 

                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            if (originalPrice > price)
                                              Text("₹$originalPrice",
                                                  style: TextStyle(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.normal, 
                                                      color: Colors.grey.shade400,
                                                      decoration: TextDecoration.lineThrough,
                                                      height: 1)),
                                            if (originalPrice > price)
                                              const SizedBox(width: 6),
                                            Text("₹$price",
                                                style: const TextStyle(
                                                    fontSize: 18, 
                                                    fontWeight: FontWeight.w600, 
                                                    color: Colors.black87,
                                                    height: 1)),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 14), 

                                        _buildSmallAddButton(
                                            title, subtitle, price, firstImage, quantity, 
                                            data['category'] ?? 'Deals', data['sub_category'] ?? '', data)
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (offerPercent > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.9), 
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16), 
                                    bottomLeft: Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "${offerPercent.toInt()}% OFF",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      fontSize: 10),
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                );
              },
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