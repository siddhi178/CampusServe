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

class _CartScreenState extends State<CartScreen> {
  final CartManager _cartManager = CartManager();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
  }

  void _updateState() {
    setState(() {});
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
      double gst = itemTotal * 0.05;
      double grandTotal = itemTotal + gst;

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
      return const Icon(Icons.fastfood, size: 40, color: Colors.grey);
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
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
      }
      return Image.asset(path,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.error));
    } catch (e) {
      return const Icon(Icons.broken_image, size: 40, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    double itemTotal = _cartManager.totalPrice;
    double gst = itemTotal * 0.05;
    double grandTotal = itemTotal + gst;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Cart",
            style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cartManager.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("Your cart is empty",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: _cartManager.cartItems.length,
                    itemBuilder: (context, index) {
                      // Fetch item fresh from the manager to ensure UI updates
                      final item = _cartManager.cartItems[index];
                      return _buildCartItemCard(item, index);
                    },
                  ),
                ),
                _buildBillSection(itemTotal, gst, grandTotal),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 55,
              width: 55,
              child: _buildImage(item['imagePath'] ?? item['image'] ?? ''),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  item['subtitle'] ?? 'Item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  item['price'].toString().startsWith('₹')
                      ? "${item['price']}"
                      : "₹${item['price']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _cartManager.removeItem(item['title']);
                    _updateState(); // FORCE UI REFRESH
                  },
                  child:
                      const Icon(Icons.remove, size: 18, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_cartManager.getQuantity(item['title'])}', // Read directly from manager
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
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
                    _updateState(); // FORCE UI REFRESH
                  },
                  child: const Icon(Icons.add, size: 18, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              while (_cartManager.getQuantity(item['title']) > 0) {
                _cartManager.removeItem(item['title']);
              }
              _updateState();
            },
            child: const Icon(Icons.close, size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSection(double itemTotal, double gst, double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Bill Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const Divider(),
          _buildRow("Item Total", "₹${itemTotal.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _buildRow("GST (5%)", "₹${gst.toStringAsFixed(2)}"),
          const SizedBox(height: 15),
          const Divider(),
          _buildRow("Grand Total", "₹${grandTotal.toStringAsFixed(2)}",
              isBold: true),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _cartManager.clearCart();
                    _updateState();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD5E8D4),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Clear Cart"),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyItemsAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA5D6A7),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text("Checkout"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.black : Colors.black87)),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isBold ? Colors.black : Colors.black87)),
      ],
    );
  }
}
