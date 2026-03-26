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
    this.subtitle = "", // Made optional for announcements
    this.price = "", // Made optional for announcements
    this.imagePath = "", // Made optional for announcements
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

  // Dynamic Display Data (Auto-fetches if opened from an announcement)
  String displayPrice = "";
  String displayImage = "";
  String displaySubtitle = "";

  String prepTimeDisplay = "Loading...";
  int avgPrepTime = 10;

  List<Map<String, dynamic>> similarItems = [];
  List<Map<String, dynamic>> userReviews = [];

  final FavoriteManager _favoriteManager = FavoriteManager();
  final CartManager _cartManager = CartManager();

  // Elegant Theme Colors
  final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);
  final Color darkGreenText = const Color(0xFF1B5E20);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _timeController;
  late Animation<double> _timeScaleAnimation;

  @override
  void initState() {
    super.initState();
    category = widget.category;
    subCategory = widget.subCategory;
    
    displayPrice = widget.price;
    displayImage = widget.imagePath;
    displaySubtitle = widget.subtitle;

    _refreshQuantity();
    _fetchItemDetails();
    _fetchReviews();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _timeScaleAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(_timeController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.contain}) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: Icon(Icons.fastfood, size: 60, color: Colors.grey))
      );
    }
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
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey))
      );
    }
  }

  void _refreshQuantity() {
    setState(() {
      quantity = _cartManager.getQuantity(widget.title);
    });
  }

  // --- SMART FETCHER (Handles empty data from Announcements) ---
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

          // Auto-fill missing data if opened from Announcement
          if (displayImage.isEmpty) {
            displayImage = data['image'] ?? data['image_url'] ?? '';
          }
          if (displayPrice.isEmpty || displayPrice == "₹0") {
            num p = data['price'] is String ? (num.tryParse(data['price']) ?? 0) : (data['price'] ?? 0);
            displayPrice = "₹$p";
          }
          if (displaySubtitle.isEmpty) {
            displaySubtitle = data['short_desc'] ?? '';
          }

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
        if (data['price'] is String) {
          price = num.tryParse(data['price'].replaceAll('₹', '')) ?? 0;
        } else {
          price = data['price'] ?? 0;
        }

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
            // Check for specific item comment first, then fallback to general message
            String msg = "";
            if (data['itemComments'] != null && data['itemComments'][widget.title] != null) {
              msg = data['itemComments'][widget.title].toString();
            } else {
              msg = (data['message'] ?? data['comment'] ?? '').toString();
            }
            
            String dbName = data['userName'] ?? 'Student';
            
            // Get specific item rating, fallback to general rating
            double rtg = 5.0;
            if (data['itemRatings'] != null && data['itemRatings'][widget.title] != null) {
               rtg = (data['itemRatings'][widget.title]).toDouble();
            } else {
               rtg = (data['rating'] ?? 5.0).toDouble();
            }

            if (msg.trim().isNotEmpty && msg.length > 2) {
              loadedReviews.add({
                'user': dbName,
                'rating': rtg,
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
    String cleanPrice = displayPrice.replaceAll('₹', '').trim();
    _cartManager.addItem(
      widget.title,
      displaySubtitle,
      "₹$cleanPrice",
      displayImage,
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
    String cleanPrice = displayPrice.replaceAll('₹', '').trim();
    final item = {
      'title': widget.title,
      'subtitle': displaySubtitle,
      'price': "₹$cleanPrice",
      'imagePath': displayImage,
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
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(isNowFav ? "Added to Favorites!" : "Removed from Favorites",
                style: const TextStyle(fontWeight: FontWeight.w500)), // Lighter
          ],
        ),
        backgroundColor: isNowFav ? Colors.green.shade600 : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Widget _buildSimilarItemImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: Icon(Icons.fastfood, size: 30, color: Colors.grey))
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
        return Image.network(path, fit: BoxFit.cover);
      }
      return Image.asset(path, fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 30, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = _favoriteManager.isFavorite(widget.title);
    final displayQty = quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Clean white
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
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black87, size: 20),
                          ),
                        ),
                      ),
                    ),

                    // --- ELEGANT HERO IMAGE ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Hero(
                        tag: widget.title,
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8))
                              ]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                      sigmaX: 15.0, sigmaY: 15.0),
                                  child: Transform.scale(
                                    scale: 1.1,
                                    child: _buildImageWidget(displayImage,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                Container(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                Center(
                                  child: Container(
                                    height: 170,
                                    width: 220,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.08),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4))
                                        ]),
                                    child: _buildImageWidget(displayImage, fit: BoxFit.contain),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- ELEGANT FLOATING QUANTITY PILL ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: primaryLightGreen.withOpacity(0.2), // Soft pastel bg
                          border: Border.all(color: primaryLightGreen.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(25)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _decreaseQuantity,
                            child: Container(
                                height: 32,
                                width: 32,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.remove,
                                    size: 16, color: darkGreenText)),
                          ),
                          const SizedBox(width: 20),
                          Text('$displayQty',
                              style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.w600, // Medium Bold
                                  color: darkGreenText)),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: _increaseQuantity,
                            child: Container(
                                height: 32,
                                width: 32,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.add,
                                    size: 16, color: darkGreenText)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

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
                                      fontWeight: FontWeight.w600, // Lightened
                                      color: Colors.black87))),
                          Text(displayPrice,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600, // Lightened
                                  color: darkGreenText)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

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
                                return Text("New",
                                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500));
                              }
                              var data = snapshot.data!.docs.first.data()
                                  as Map<String, dynamic>;
                              double rating =
                                  (data['rating'] ?? 0.0).toDouble();
                              int count = (data['ratingCount'] ?? 0).toInt();

                              if (count == 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Text("No ratings yet",
                                      style: TextStyle(
                                          color: Colors.amber.shade800, fontSize: 11, fontWeight: FontWeight.w500)),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: Row(children: [
                                  Icon(Icons.star_rounded,
                                      color: Colors.amber.shade600, size: 16),
                                  const SizedBox(width: 4),
                                  Text(rating.toStringAsFixed(1),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.amber.shade800)),
                                ]),
                              );
                            },
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryLightGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: primaryLightGreen.withOpacity(0.5), width: 1),
                              ),
                              child: Row(children: [
                                ScaleTransition(
                                  scale: _timeScaleAnimation,
                                  child: Icon(Icons.timer_outlined,
                                      size: 14, color: darkGreenText),
                                ),
                                const SizedBox(width: 6),
                                Text(prepTimeDisplay,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: darkGreenText))
                              ])),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- CENTERED DESCRIPTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(displaySubtitle.isNotEmpty ? displaySubtitle : "${widget.title} prepared fresh.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87)),
                          const SizedBox(height: 6),
                          Text(longDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.5)), // Elegant line height
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    // --- CUSTOMER REVIEWS ---
                    if (userReviews.isNotEmpty) ...[
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Customer Reviews",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)))), // Lightened
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 75, // Slightly taller to breathe
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
                                      color: Colors.grey.shade200, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2)
                                    )
                                  ]
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: primaryLightGreen.withOpacity(0.3),
                                          child: Text(initial,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkGreenText)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          firstName,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        width: 14), 
                                    Expanded(
                                      child: Text('"${rev['comment']}"',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                              height: 1.3,
                                              color: Colors.grey.shade700)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star_rounded,
                                                  size: 14,
                                                  color: Colors.amber.shade600),
                                              const SizedBox(width: 2),
                                              Text("${rev['rating']}",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.amber.shade800)),
                                            ]))
                                  ],
                                ));
                          },
                        ),
                      ),
                      const SizedBox(height: 35),
                    ],

                    // --- ELEGANT SUGGESTIONS ---
                    if (similarItems.isNotEmpty) ...[
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("You May Also Like",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)))), // Lightened
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100, // Reduced height for elegant horizontal card
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
                                width: 220, // Wider for horizontal layout
                                margin: const EdgeInsets.only(right: 12, bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: primaryLightGreen.withOpacity(0.5), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3)
                                    )
                                  ]
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade100)
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: _buildSimilarItemImage(
                                            item['imagePath']),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(item['title'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600, // Medium
                                                  color: Colors.black87)),
                                          const SizedBox(height: 4),
                                          Text("₹$simPrice",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkGreenText)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // --- ELEGANT BOTTOM ACTION BAR ---
      bottomSheet: Container(
        height: 85, // Proper height
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), // Very soft shadow
                blurRadius: 15,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red.shade400 : Colors.black87, size: 24), // Softer red
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
                        color: primaryLightGreen, // Elegant pastel green
                        borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                        child: Text('Add Item To Cart',
                            style: TextStyle(
                                color: Colors.black87, // Dark elegant text
                                fontSize: 16,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600))), // Semi-bold
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