// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  
  CartManager._internal() {
    loadCart(); 
  }

  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> get cartItems => _cartItems;

  // --- SAVE TO DISK ---
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_cart', jsonEncode(_cartItems));
  }

  // --- LOAD FROM DISK ---
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('user_cart');
    if (data != null) {
      try {
        _cartItems = List<Map<String, dynamic>>.from(jsonDecode(data));
      } catch (e) {
        debugPrint("Error decoding cart data: $e");
      }
    }
  }

  // --- 1. ADD ITEM (FIXED ARGUMENTS) ---
  // Changed from named {category, subCategory} to standard positional arguments
  // to match the call in home_screen.dart
  void addItem(
    String title, 
    String subtitle, 
    dynamic price, 
    String imagePath, 
    String category, 
    String subCategory, 
    {int prepTime = 10}
  ) {
    int index = _cartItems.indexWhere((item) => item['title'] == title);

    if (index != -1) {
      _cartItems[index]['quantity'] += 1;
    } else {
      _cartItems.add({
        'title': title,
        'subtitle': subtitle,
        'price': price,
        'imagePath': imagePath,
        'quantity': 1,
        'prep_time': prepTime,
        'category': category,
        'sub_category': subCategory,
      });
    }
    saveCart(); 
  }

  // --- 2. REMOVE ITEM ---
  void removeItem(String title) {
    int index = _cartItems.indexWhere((item) => item['title'] == title);
    if (index != -1) {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity'] -= 1;
      } else {
        _cartItems.removeAt(index);
      }
      saveCart();
    }
  }

  // --- 3. REMOVE ITEM BY INDEX ---
  void removeItemByIndex(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      saveCart();
    }
  }

  // --- 4. UPDATE QUANTITY ---
  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _cartItems.length) {
      if (newQuantity > 0) {
        _cartItems[index]['quantity'] = newQuantity;
      } else {
        _cartItems.removeAt(index);
      }
      saveCart();
    }
  }

  // --- 5. CLEAR CART ---
  void clearCart() {
    _cartItems.clear();
    saveCart();
  }

  // --- GETTERS ---
  int getQuantity(String title) {
    var item = _cartItems.firstWhere(
      (item) => item['title'] == title,
      orElse: () => {},
    );
    return item.isNotEmpty ? (item['quantity'] as int) : 0;
  }

  int get itemCount =>
      _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) {
      double priceValue = 0.0;
      if (item['price'] is String) {
        String priceStr = item['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
        priceValue = double.tryParse(priceStr) ?? 0.0;
      } else if (item['price'] is num) {
        priceValue = (item['price'] as num).toDouble();
      }
      return sum + (priceValue * (item['quantity'] as int));
    });
  }
}