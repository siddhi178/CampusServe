import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  // Collection Reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  // --- 1. CREATE/UPDATE USER DATA ---
  // Call this function immediately after the user registers successfully.
  Future<void> updateUserData({
    required String name,
    required String email,
    required String phone,
  }) async {
    return await userCollection.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'wallet_balance': 0.0, // Initialize wallet with 0
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user', // 'user' or 'admin'
      'profileImage': '', // Empty string for now
    }, SetOptions(merge: true));
    // merge: true ensures we don't overwrite existing data like wallet balance if we update name later
  }

  // --- 2. GET USER DATA STREAM ---
  // Useful for displaying profile info in the app
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  // --- 3. GET USER DATA FUTURE ---
  // Useful for one-time fetches (e.g., getting name for a transaction)
  Future<DocumentSnapshot> getUserDataOnce() async {
    return await userCollection.doc(uid).get();
  }
}
