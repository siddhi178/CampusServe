// ignore_for_file: unused_import, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favorite_manager.dart';
import 'cart_manager.dart';
import 'cart_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imagePath;
  final String category;
  final String subCategory;

  const FoodDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imagePath,
    this.category = "",
    this.subCategory = "",
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen>
    with TickerProviderStateMixin {
  int quantity = 0;
  String longDescription = "Loading description...";
  String category = "";
  String subCategory = "";

  String prepTimeDisplay = "Loading...";
  int avgPrepTime = 10;

  List<Map<String, dynamic>> similarItems = [];
  List<Map<String, dynamic>> userReviews = [];

  final FavoriteManager _favoriteManager = FavoriteManager();
  final CartManager _cartManager = CartManager();

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _timeController;
  late Animation<double> _timeScaleAnimation;

  Widget? _cachedImage;

  @override
  void initState() {
    super.initState();
    category = widget.category;
    subCategory = widget.subCategory;

    _refreshQuantity();
    _fetchItemDetails();
    _fetchReviews();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _timeScaleAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(_timeController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.contain}) {
    if (path.isEmpty)
      return const Icon(Icons.fastfood, size: 100, color: Colors.grey);
    Widget image;
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        image = Image.memory(base64Decode(base64Data),
            fit: fit, gaplessPlayback: true);
      } else if (path.startsWith('http')) {
        image = Image.network(path, fit: fit, gaplessPlayback: true);
      } else {
        image = Image.asset(path, fit: fit, gaplessPlayback: true);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: image,
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 100, color: Colors.red);
    }
  }

  void _refreshQuantity() {
    setState(() {
      quantity = _cartManager.getQuantity(widget.title);
    });
  }

  Future<void> _fetchItemDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('menu')
          .where('name', isEqualTo: widget.title)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          longDescription = data['long_desc'] ??
              data['description'] ??
              "No detailed description available.";
          category = data['category'] ?? widget.category;
          subCategory = data['sub_category'] ?? widget.subCategory;

          var min = data['time_min'] ?? '5';
          var max = data['time_max'] ?? '10';

          int minInt = int.tryParse(min.toString()) ?? 5;
          int maxInt = int.tryParse(max.toString()) ?? 10;

          prepTimeDisplay = "$minInt-$maxInt min";
          avgPrepTime = maxInt;
        });

        _fetchCrossSellItems();
      } else {
        setState(() {
          longDescription = "Delicious food made fresh for you.";
          prepTimeDisplay = "5-10 min";
          avgPrepTime = 10;
        });
      }
    } catch (e) {
      debugPrint("Error details: $e");
    }
  }

  Future<void> _fetchCrossSellItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('menu')
          .where('is_available', isEqualTo: true)
          .limit(20)
          .get();

      List<Map<String, dynamic>> fetchedList = snapshot.docs.map((doc) {
        final data = doc.data();
        num price = 0;
        if (data['price'] is String)
          price = num.tryParse(data['price'].replaceAll('₹', '')) ?? 0;
        else
          price = data['price'] ?? 0;

        return {
          'title': data['name'] ?? 'Unknown',
          'subtitle': data['short_desc'] ?? data['description'] ?? 'Tasty',
          'price': "₹$price",
          'imagePath': data['image'] ?? data['image_url'] ?? '',
          'category': data['category'] ?? '',
          'subCategory': data['sub_category'] ?? '',
        };
      }).toList();

      fetchedList.removeWhere((item) => item['title'] == widget.title);

      List<Map<String, dynamic>> differentCategoryItems =
          fetchedList.where((item) => item['category'] != category).toList();
      differentCategoryItems.shuffle();

      List<Map<String, dynamic>> finalSuggestions = [];
      finalSuggestions.addAll(differentCategoryItems.take(4));

      if (finalSuggestions.length < 4) {
        List<Map<String, dynamic>> sameCategoryItems =
            fetchedList.where((item) => item['category'] == category).toList();
        sameCategoryItems.shuffle();
        finalSuggestions
            .addAll(sameCategoryItems.take(4 - finalSuggestions.length));
      }

      setState(() {
        similarItems = finalSuggestions;
      });
    } catch (e) {
      debugPrint("Error fetching cross-sell items: $e");
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> loadedReviews = [];

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final data = doc.data();

          bool containsItem = false;
          if (data['items'] != null && data['items'] is List) {
            containsItem = (data['items'] as List).contains(widget.title);
          } else if (data['message'] != null &&
              data['message'].toString().contains(widget.title)) {
            containsItem = true;
          }

          if (containsItem) {
            String msg = (data['message'] ?? data['comment'] ?? '').toString();
            String dbName = data['userName'] ?? 'Student';

            if (msg.trim().isNotEmpty && msg.length > 2) {
              loadedReviews.add({
                'user': dbName,
                'rating': (data['rating'] ?? 5.0).toDouble(),
                'comment': msg.trim(),
              });
            }
          }
        }
      }

      setState(() {
        userReviews = loadedReviews;
      });
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    }
  }

  void _increaseQuantity() {
    String cleanPrice = widget.price.replaceAll('₹', '').trim();
    _cartManager.addItem(
      widget.title,
      widget.subtitle,
      "₹$cleanPrice",
      widget.imagePath,
      category,
      subCategory,
      prepTime: avgPrepTime,
    );
    _refreshQuantity();
  }

  void _decreaseQuantity() {
    _cartManager.removeItem(widget.title);
    _refreshQuantity();
  }

  void _mainActionButtonClick() async {
    await _controller.forward();
    await _controller.reverse();

    _increaseQuantity();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${widget.title} added to cart!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1)),
    );
  }

  void _toggleFavorite() {
    String cleanPrice = widget.price.replaceAll('₹', '').trim();
    final item = {
      'title': widget.title,
      'subtitle': widget.subtitle,
      'price': "₹$cleanPrice",
      'imagePath': widget.imagePath,
    };
    setState(() {
      _favoriteManager.toggleFavorite(item);
    });

    bool isNowFav = _favoriteManager.isFavorite(widget.title);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isNowFav ? Icons.favorite : Icons.heart_broken,
                color: Colors.white),
            const SizedBox(width: 12),
            Text(isNowFav ? "Added to Favorites!" : "Removed from Favorites",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: isNowFav ? Colors.pink.shade400 : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Widget _buildSimilarItemImage(String path) {
    if (path.isEmpty)
      return const Icon(Icons.fastfood, size: 40, color: Colors.grey);
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data),
            fit: BoxFit.cover, gaplessPlayback: true);
      }
      if (path.startsWith('http'))
        return Image.network(path, fit: BoxFit.cover);
      return Image.asset(path, fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 40, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    _cachedImage ??= _buildImageWidget(widget.imagePath, fit: BoxFit.contain);
    final isFavorite = _favoriteManager.isFavorite(widget.title);
    final displayQty = quantity;
    String cleanPrice = widget.price.replaceAll('₹', '').trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- HEADER BACK BUTTON ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2))
                                ]),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black, size: 18),
                          ),
                        ),
                      ),
                    ),

                    // --- SHORTER HERO IMAGE WITH BLUR EFFECT ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Hero(
                        tag: widget.title,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                      sigmaX: 20.0, sigmaY: 20.0),
                                  child: Transform.scale(
                                    scale: 1.2,
                                    child: _buildImageWidget(widget.imagePath,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                Container(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                Center(
                                  child: Container(
                                    height: 160,
                                    width: 200,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]),
                                    child: _cachedImage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- SMALLER FLOATING QUANTITY PILL ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(25)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _decreaseQuantity,
                            child: Container(
                                height: 30,
                                width: 30,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.remove,
                                    size: 16, color: Colors.black87)),
                          ),
                          const SizedBox(width: 20),
                          Text('$displayQty',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: _increaseQuantity,
                            child: Container(
                                height: 30,
                                width: 30,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.add,
                                    size: 16, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- TITLE AND PRICE ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(widget.title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87))),
                          Text("₹$cleanPrice",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // --- RATING AND TIME ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('menu')
                                .where('name', isEqualTo: widget.title)
                                .limit(1)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text("New",
                                    style: TextStyle(color: Colors.grey));
                              }
                              var data = snapshot.data!.docs.first.data()
                                  as Map<String, dynamic>;
                              double rating =
                                  (data['rating'] ?? 0.0).toDouble();
                              int count = (data['ratingCount'] ?? 0).toInt();

                              if (count == 0)
                                return const Text("No ratings",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12));

                              return Row(children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.black87)),
                              ]);
                            },
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.green.shade300, width: 1),
                              ),
                              child: Row(children: [
                                ScaleTransition(
                                  scale: _timeScaleAnimation,
                                  child: const Icon(Icons.timer_outlined,
                                      size: 12, color: Colors.green),
                                ),
                                const SizedBox(width: 4),
                                Text(prepTimeDisplay,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green))
                              ])),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- CENTERED DESCRIPTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("${widget.title} prepared fresh daily.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(longDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.4)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- CUSTOMER REVIEWS (PERFECTED ALIGNMENT) ---
                    if (userReviews.isNotEmpty) ...[
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Customer Reviews",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: userReviews.length,
                          itemBuilder: (context, index) {
                            var rev = userReviews[index];
                            String userNameStr =
                                rev['user']?.toString() ?? "User";
                            String firstName =
                                userNameStr.trim().split(RegExp(r'\s+')).first;
                            String initial = firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : "U";

                            return Container(
                                width: 260,
                                margin: const EdgeInsets.only(right: 12),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.green.shade200, width: 1.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Profile Column (Avatar + Name)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.green.shade200
                                              .withOpacity(0.5),
                                          child: Text(initial,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color:
                                                      Colors.green.shade900)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          firstName,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        width: 16), // Adjusted spacing

                                    // Quote Text (Left Aligned for better readability next to profile)
                                    Expanded(
                                      child: Text('"${rev['comment']}"',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700)),
                                    ),

                                    const SizedBox(width: 10),

                                    // Yellow Rating Pill
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFFFF9C4),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star,
                                                  size: 12,
                                                  color: Colors.amber),
                                              const SizedBox(width: 3),
                                              Text("${rev['rating']}",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.black87)),
                                            ]))
                                  ],
                                ));
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    // --- REDESIGNED SLEEK SUGGESTIONS WITH PADDED BORDERS ---
                    if (similarItems.isNotEmpty) ...[
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("You May Also Like",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 155,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: similarItems.length,
                          itemBuilder: (context, index) {
                            final item = similarItems[index];
                            String simPrice = item['price']
                                .toString()
                                .replaceAll('₹', '')
                                .trim();
                            return GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => FoodDetailScreen(
                                          title: item['title'],
                                          subtitle: item['subtitle'],
                                          price: "₹$simPrice",
                                          imagePath: item['imagePath'],
                                          category: item['category'],
                                          subCategory: item['subCategory']))),
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: _buildSimilarItemImage(
                                                item['imagePath']),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item['title'],
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87)),
                                      const SizedBox(height: 2),
                                      Text("₹$simPrice",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.green.shade800)),
                                    ]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM ACTION BAR (SIMPLE "ADD TO CART" BUTTON) ---
      bottomSheet: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.black87, size: 24),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: _mainActionButtonClick,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: const Color(0xFFA5D6A7),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                        child: Text('Add Item To Cart',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
