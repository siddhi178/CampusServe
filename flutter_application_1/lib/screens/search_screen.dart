// ignore_for_file: unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_to_list_in_spreads, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- THIS IS CRITICAL
import 'cart_manager.dart';
import 'food_detail_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final CartManager _cartManager = CartManager();

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _searchHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _fetchMenuItems();
    _searchController.addListener(_onSearchChanged);
  }

  // --- 1. SEARCH HISTORY (SharedPrefs) ---
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query); // Add to top
        if (_searchHistory.length > 5)
          _searchHistory.removeLast(); // Keep max 5
      });
      await prefs.setStringList('search_history', _searchHistory);
    }
  }

  Future<void> _removeFromHistory(String item) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.remove(item);
    });
    await prefs.setStringList('search_history', _searchHistory);
  }

  // --- 2. FETCH MENU ITEMS ---
  Future<void> _fetchMenuItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('menu')
          .where('is_available', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> items = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        num price = 0;
        if (data['price'] is String) {
          price = num.tryParse(data['price']) ?? 0;
        } else {
          price = data['price'] ?? 0;
        }

        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'short_desc': data['short_desc'] ?? data['description'] ?? '',
          'description': data['long_desc'] ?? data['description'] ?? '',
          'price': price,
          'image': data['image'] ?? data['image_url'] ?? '',
        };
      }).toList();

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching menu: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 3. SEARCH LOGIC ---
  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = [];
      } else {
        _filteredItems = _allItems.where((item) {
          return item['name'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // --- HELPER: Image Builder ---
  Widget _buildImage(String path) {
    if (path.isEmpty) return const Icon(Icons.fastfood, color: Colors.grey);
    try {
      if (path.startsWith('data:image')) {
        String base64Data =
            path.split(',').last.replaceAll(RegExp(r'[\n\r]'), '');
        return Image.memory(base64Decode(base64Data), fit: BoxFit.cover);
      }
      if (path.startsWith('http')) {
        return Image.network(path, fit: BoxFit.cover);
      }
      return Image.asset(path, fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.red);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Search',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // --- SEARCH INPUT ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: (val) => _addToHistory(val),
                decoration: InputDecoration(
                  hintText: 'Search for food...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFE8F5E9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // --- MAIN CONTENT AREA ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. SEARCH HISTORY (Only when NOT searching)
                          if (!isSearching && _searchHistory.isNotEmpty) ...[
                            const Text(
                              'Search History',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _searchHistory.map((historyItem) {
                                return GestureDetector(
                                  onTap: () {
                                    _searchController.text = historyItem;
                                    _onSearchChanged();
                                  },
                                  child: Chip(
                                    label: Text(historyItem),
                                    backgroundColor: Colors.white,
                                    deleteIcon:
                                        const Icon(Icons.close, size: 16),
                                    onDeleted: () =>
                                        _removeFromHistory(historyItem),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 25),
                          ],

                          // 2. RESULTS TITLE
                          Text(
                            isSearching
                                ? "Search Results"
                                : "People Also Search for",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 12),

                          // 3. EMPTY STATE
                          if (isSearching && _filteredItems.isEmpty)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.only(top: 50.0),
                              child: Text("No items found",
                                  style: TextStyle(color: Colors.grey)),
                            )),

                          // 4. LIST ITEMS (Filtered OR Suggestions)
                          ...(isSearching ? _filteredItems : _allItems.take(5))
                              .map((item) {
                            return _buildSearchItemRow(item);
                          }).toList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ITEM ROW WIDGET ---
  Widget _buildSearchItemRow(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // Save to history
        if (_searchController.text.isNotEmpty) {
          _addToHistory(_searchController.text);
        } else {
          _addToHistory(item['name']);
        }

        // Navigate to Detail Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(
              title: item['name'],
              subtitle: item['description'],
              price: "₹${item['price']}",
              imagePath: item['image'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImage(item['image']),
              ),
            ),
            const SizedBox(width: 15),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  // Short Description
                  Text(
                    item['short_desc'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${item['price']}",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
