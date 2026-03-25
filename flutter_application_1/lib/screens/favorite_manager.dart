import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteManager extends ChangeNotifier {
  // --- SINGLETON PATTERN ---
  static final FavoriteManager _instance = FavoriteManager._internal();

  factory FavoriteManager() {
    return _instance;
  }

  FavoriteManager._internal() {
    fetchFavorites();
  }

  // --- STATE ---
  final List<Map<String, dynamic>> _favoriteItems = [];

  List<Map<String, dynamic>> get favoriteItems =>
      List.unmodifiable(_favoriteItems);

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // --- 1. FETCH FAVORITES ---
  Future<void> fetchFavorites() async {
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('favorites')
          .get();

      _favoriteItems.clear();

      for (var doc in snapshot.docs) {
        _favoriteItems.add(doc.data());
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
    }
  }

  // --- 2. CHECK IF FAVORITE ---
  bool isFavorite(String title) {
    return _favoriteItems.any((item) => item['title'] == title);
  }

  // --- 3. TOGGLE FAVORITE ---
  Future<void> toggleFavorite(Map<String, dynamic> item) async {
    final title = item['title'];
    final isExisting = isFavorite(title);

    // Optimistic Update
    if (isExisting) {
      _favoriteItems.removeWhere((fav) => fav['title'] == title);
    } else {
      _favoriteItems.add(item);
    }
    notifyListeners();

    // Backend Update
    if (currentUser != null) {
      try {
        final collectionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('favorites');

        if (isExisting) {
          await collectionRef.doc(title).delete();
        } else {
          await collectionRef.doc(title).set(item);
        }
      } catch (e) {
        debugPrint("Error updating backend: $e");
      }
    }
  }

  // --- 4. REMOVE SPECIFIC FAVORITE ---
  Future<void> removeFavorite(String title) async {
    _favoriteItems.removeWhere((item) => item['title'] == title);
    notifyListeners();

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('favorites')
            .doc(title)
            .delete();
      } catch (e) {
        debugPrint("Error removing from backend: $e");
      }
    }
  }

  // --- 5. CLEAR ALL ---
  Future<void> clearFavorites() async {
    _favoriteItems.clear();
    notifyListeners();

    if (currentUser != null) {
      try {
        final collectionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('favorites');

        var snapshots = await collectionRef.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error clearing backend: $e");
      }
    }
  }
}
