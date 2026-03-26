// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_manager.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic> newItem;

  const CartScreen({super.key, required this.newItem});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  final CartManager _cartManager = CartManager();
  bool _isVerifying = false;

  // Animation Controller for smooth entry
  late AnimationController _animController;
  
  // Cache for storing combo images so they load instantly without flickering
  Map<String, List<dynamic>> _comboImagesCache = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animController.forward();
    
    // Fetch combo images for any deals currently in the cart
    _fetchComboImages();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  // Smart fetcher to get combo images for Deals in the background
  Future<void> _fetchComboImages() async {
    for (var item in _cartManager.cartItems) {
      if (item['category'] == 'Deals') {
        String title = item['title'] ?? '';
        if (title.isNotEmpty && !_comboImagesCache.containsKey(title)) {
          try {
            var query = await FirebaseFirestore.instance
                .collection('menu')
                .where('name', isEqualTo: title)
                .limit(1)
                .get();
                
            if (query.docs.isNotEmpty && mounted) {
              var data = query.docs.first.data();
              if (data['combo_images'] is List) {
                setState(() {
                  _comboImagesCache[title] = data['combo_images'];
                });
              }
            }
          } catch (e) {
            debugPrint("Error fetching combo images: $e");
          }
        }
      }
    }
  }

  Future<void> _verifyItemsAndProceed() async {
    setState(() => _isVerifying = true);

    try {
      for (var i = 0; i < _cartManager.cartItems.length; i++) {
        var item = _cartManager.cartItems[i];
        String name = item['title'] ?? item['name'];

        try {
          var query = await FirebaseFirestore.instance
              .collection('menu')
              .where('name', isEqualTo: name)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            var data = query.docs.first.data();
            var maxTimeStr =
                data['time_max'] ?? '10'; // Defaulting to 10 for safety
            int realTime = int.tryParse(maxTimeStr.toString()) ?? 10;
            _cartManager.cartItems[i]['prep_time'] = realTime;
          }
        } catch (e) {
          debugPrint("Error fetching time for $name: $e");
        }
      }

      double itemTotal = _cartManager.totalPrice;
      double platformFee = itemTotal > 0 ? 5.00 : 0.00; // Platform Fee Added
      double gst = itemTotal * 0.05;
      double grandTotal = itemTotal + platformFee + gst;

      if (grandTotal > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(grandTotal: grandTotal),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error checking menu: $e"),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _isVerifying = false);
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
    double itemTotal = _cartManager.totalPrice;
    double platformFee = itemTotal > 0 ? 5.00 : 0.00; 
    double gst = itemTotal * 0.05;
    double grandTotal = itemTotal > 0 ? itemTotal + platformFee + gst : 0.00;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text("My Cart",
            style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500)), // Removed bold weight (now w500)
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cartManager.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.green.shade100),
                  const SizedBox(height: 20),
                  Text("Your cart is empty",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    itemCount: _cartManager.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.cartItems[index];

                      final Animation<double> slideAnim = Tween<double>(
                              begin: 50.0, end: 0.0)
                          .animate(CurvedAnimation(
                              parent: _animController,
                              curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0,
                                  curve: Curves.easeOutCubic)));

                      final Animation<double> fadeAnim = Tween<double>(
                              begin: 0.0, end: 1.0)
                          .animate(CurvedAnimation(
                              parent: _animController,
                              curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0,
                                  curve: Curves.easeIn)));

                      return AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, slideAnim.value),
                            child: Opacity(
                              opacity: fadeAnim.value,
                              child: _buildCartItemCard(item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildBillSection(itemTotal, platformFee, gst, grandTotal),
              ],
            ),
    );
  }

  // --- UPDATED CART CARD ---
  Widget _buildCartItemCard(Map<String, dynamic> item) {
    bool isDeal = item['category'] == 'Deals';
    List<dynamic> combo = _comboImagesCache[item['title']] ?? [];

    Widget imageSection;

    if (isDeal && combo.length > 1) {
      imageSection = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(combo[0].toString()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text("+",
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ),
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(combo[1].toString()),
            ),
          ),
        ],
      );
    } else {
      imageSection = Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImage(item['imagePath'] ?? item['image'] ?? ''),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14), 
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100, width: 1.2), // Beautiful light green border
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05), // Soft floating shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          imageSection, 
          
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? 'Unknown',
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                    ),
                    if (isDeal)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          "DEAL",
                          style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 2), 
                Text(
                  item['subtitle'] ?? 'Item details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11, 
                      fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['price'].toString().startsWith('₹')
                          ? "${item['price']}"
                          : "₹${item['price']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.shade300, width: 1)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _cartManager.removeItem(item['title']);
                              _updateState();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.remove,
                                  size: 14, color: Colors.green),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${_cartManager.getQuantity(item['title'])}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.green),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _cartManager.addItem(
                                item['title'],
                                item['subtitle'],
                                item['price'],
                                item['imagePath'],
                                item['category'] ?? 'General',
                                item['sub_category'] ?? 'General',
                                prepTime: item['prep_time'] ?? 10,
                              );
                              _updateState();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.add,
                                  size: 14, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSection(double itemTotal, double platformFee, double gst, double grandTotal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bill Summary",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, 
                    color: Colors.black87)),
            const SizedBox(height: 16),

            _buildRow("Item Total", "₹${itemTotal.toStringAsFixed(2)}"),
            const SizedBox(height: 10),
            _buildRow("Platform Fee", "₹${platformFee.toStringAsFixed(2)}"),
            const SizedBox(height: 10),
            _buildRow("GST (5%)", "₹${gst.toStringAsFixed(2)}"),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),
            
            _buildRow("Grand Total", "₹${grandTotal.toStringAsFixed(2)}",
                isBold: true),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      _cartManager.clearCart();
                      _updateState();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text("Clear Cart",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyItemsAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("Checkout",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400, 
                color: isBold ? Colors.black87 : Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}