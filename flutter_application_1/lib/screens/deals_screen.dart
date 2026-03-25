import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_manager.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final CartManager _cartManager = CartManager();

  void _addToCartDirectly(Map<String, dynamic> data) {
    String title = data['name'] ?? 'Unknown Deal';
    String subtitle = data['short_desc'] ?? '';
    num price = data['price'] is String
        ? (num.tryParse(data['price']) ?? 0)
        : (data['price'] ?? 0);

    String firstImage = "";
    if (data['combo_images'] != null &&
        (data['combo_images'] as List).isNotEmpty) {
      firstImage = data['combo_images'][0];
    } else {
      firstImage = data['image_url'] ?? data['image'] ?? '';
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
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
            child: Icon(Icons.fastfood, color: Colors.grey, size: 20)),
      );
    }
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data),
            fit: BoxFit.cover, gaplessPlayback: true);
      }
      if (path.startsWith('http'))
        return Image.network(path, fit: BoxFit.cover, gaplessPlayback: true);
      return Image.asset(path, fit: BoxFit.cover, gaplessPlayback: true);
    } catch (e) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
            child: Icon(Icons.broken_image, color: Colors.red, size: 20)),
      );
    }
  }

  Widget _buildComboImages(List<dynamic> images) {
    List<Widget> imageWidgets = [];

    double imageSize = images.length > 2 ? 60.0 : 80.0;

    for (int i = 0; i < images.length; i++) {
      imageWidgets.add(Container(
        width: imageSize,
        height: imageSize,
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(images[i].toString())),
      ));

      if (i < images.length - 1) {
        imageWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
              child: Text("+",
                  style: TextStyle(
                      fontSize: images.length > 2 ? 20 : 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light, clean background color
      appBar: AppBar(
        title: const Text("Deals & Combos",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                      size: 80, color: Colors.green.shade200),
                  const SizedBox(height: 20),
                  const Text("No Active Combos Right Now",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(
                      "Check back later for exciting\nbundles of your favorite meals!",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final deals = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: deals.length,
            itemBuilder: (context, index) {
              var data = deals[index].data() as Map<String, dynamic>;

              String title = data['name'] ?? 'Unknown Deal';
              num price = data['price'] is String
                  ? (num.tryParse(data['price']) ?? 0)
                  : (data['price'] ?? 0);
              num originalPrice = data['original_price'] ?? price;
              num offerPercent = data['offer_percentage'] ?? 0;

              List<dynamic> comboImages = data['combo_images'] ?? [];

              // --- WRAPPED IN A CARD CONTAINER ---
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5), // Subtle border
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Images
                        Expanded(
                          flex: 3,
                          child: comboImages.isNotEmpty
                              ? _buildComboImages(comboImages)
                              : Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.fastfood,
                                          color: Colors.green, size: 30)),
                                ),
                        ),

                        const SizedBox(width: 10),

                        // Right side: Price and Button
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Pricing Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (originalPrice > price)
                                    Text("₹$originalPrice",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500,
                                            decoration:
                                                TextDecoration.lineThrough)),
                                  if (originalPrice > price)
                                    const SizedBox(width: 6),
                                  Text("₹$price",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Light Green % Off Tag
                              if (offerPercent > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text("${offerPercent.toInt()}% Off",
                                      style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10)),
                                ),
                              const SizedBox(height: 15),

                              // Light Green Add Button
                              GestureDetector(
                                onTap: () => _addToCartDirectly(data),
                                child: Container(
                                  width: 80,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA5D6A7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text("Add",
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
