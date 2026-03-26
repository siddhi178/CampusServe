// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/favorite_manager.dart'
    show FavoriteManager;
import 'food_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  // Singleton Instance
  final FavoriteManager _favoriteManager = FavoriteManager();
  
  // Elegant pastel theme color
  final Color primaryLightGreen = const Color.fromRGBO(165, 214, 167, 1);

  @override
  void initState() {
    super.initState();
    // Load favorites from Firebase
    _favoriteManager.fetchFavorites();
  }

  // --- IMAGE BUILDER ---
  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: Icon(Icons.fastfood, color: Colors.grey, size: 30))
      );
    }
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
      if (path.startsWith('http')) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
      return Image.asset(
        path,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _favoriteManager,
      builder: (context, child) {
        final favorites = _favoriteManager.favoriteItems;

        return Scaffold(
          backgroundColor: const Color(0xFFFDFDFD), // Clean white background
          appBar: AppBar(
            title: const Text(
              "Favorite",
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black87), // Reduced bold
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (favorites.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep_outlined,
                      color: Colors.red.shade400),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text("Clear Favorites?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        content: const Text(
                            "Are you sure you want to remove all items?", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                          TextButton(
                            onPressed: () {
                              _favoriteManager.clearFavorites();
                              Navigator.pop(ctx);
                            },
                            child: const Text("Clear All",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: favorites.isEmpty
              ? _buildEmptyState() 
              : _buildFavoriteList(favorites), 
        );
      },
    );
  }

  // --- 1. ELEGANT EMPTY STATE UI ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large Heart Icon
          Icon(
            Icons.favorite_border_rounded,
            size: 120,
            color: primaryLightGreen.withOpacity(0.8), // Matching theme color
          ),
          const SizedBox(height: 30),

          // Title
          const Text(
            "No liked Items yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600, // Reduced bold
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Tab the heart icon on any food to save it here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 50),

          // Browse Menu Button
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryLightGreen, // Pastel Green
                foregroundColor: Colors.black87, // Dark text
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Browse Menu",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. ELEGANT FAVORITE LIST UI ---
  Widget _buildFavoriteList(List<Map<String, dynamic>> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        final String title = item['title'] ?? 'Unknown';
        final String subtitle = item['subtitle'] ?? '';
        final String price = item['price'] ?? '';
        final String imagePath = item['imagePath'] ?? '';

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodDetailScreen(
                    title: title,
                    subtitle: subtitle,
                    price: price,
                    imagePath: imagePath,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryLightGreen.withOpacity(0.6), width: 1.2), // Elegant light green border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3)
                  )
                ]
              ),
              child: Row(
                children: [
                  // Image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(imagePath),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87), // Semi-bold
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          price.startsWith('₹') ? price : "₹$price",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600, // Semi-bold
                              color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),

                  // Heart/Remove Button
                  IconButton(
                    icon: Icon(Icons.favorite, color: Colors.red.shade400, size: 24),
                    onPressed: () {
                      _favoriteManager.removeFavorite(title);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$title removed", style: const TextStyle(fontWeight: FontWeight.w500)),
                          duration: const Duration(milliseconds: 1500),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}