// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
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

  @override
  void initState() {
    super.initState();
    // Load favorites from Firebase
    _favoriteManager.fetchFavorites();
  }

  // --- IMAGE BUILDER ---
  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return const Icon(Icons.fastfood, color: Colors.grey, size: 40);
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
          backgroundColor: Colors.white, // White background matches your design
          appBar: AppBar(
            title: const Text(
              "Favorite",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (favorites.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Clear Favorites?"),
                        content: const Text(
                            "Are you sure you want to remove all items?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              _favoriteManager.clearFavorites();
                              Navigator.pop(ctx);
                            },
                            child: const Text("Clear All",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: favorites.isEmpty
              ? _buildEmptyState() // <--- NEW UI WHEN EMPTY
              : _buildFavoriteList(favorites), // EXISTING LIST
        );
      },
    );
  }

  // --- 1. NEW EMPTY STATE UI (Matches your Image) ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large Heart Icon
          Icon(
            Icons.favorite_border_rounded,
            size: 120,
            color: const Color(0xFFA5D6A7).withOpacity(0.8), // Light Green
          ),
          const SizedBox(height: 30),

          // Title
          const Text(
            "No liked Items yet",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Tab the heart icon on any food to save it here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 50),

          // Browse Menu Button
          SizedBox(
            width: 220,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8E6C9), // Pastel Green
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Browse Menu",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. FAVORITE LIST UI (When items exist) ---
  Widget _buildFavoriteList(List<Map<String, dynamic>> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
              offset: Offset(0, 50 * (1 - value)),
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
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9), // Very light grey card
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(imagePath),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          price,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                  // Heart/Remove Button
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      _favoriteManager.removeFavorite(title);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$title removed"),
                          duration: const Duration(milliseconds: 1000),
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
