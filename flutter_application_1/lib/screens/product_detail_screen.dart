// import 'package:flutter/material.dart';
// import 'home_screen.dart'; // Import Home Screen for navigation
// // ignore: unused_import
// import 'cart_screen.dart'; // Import Cart Screen for navigation

// class ProductDetailsScreen extends StatefulWidget {
//   const ProductDetailsScreen({super.key});

//   @override
//   State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
// }

// class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
//   int _quantity = 1;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // --- MAIN SCROLLABLE CONTENT ---
//             Padding(
//               padding: const EdgeInsets.only(
//                 bottom: 90,
//               ), // Space for Bottom Nav
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 10),

//                     // --- 1. HEADER (Back Button) ---
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: IconButton(
//                           icon: const Icon(
//                             Icons.arrow_back,
//                             color: Colors.black,
//                           ),
//                           onPressed: () {
//                             // Navigate back to Home Screen
//                             // Checks if it can pop (go back), otherwise pushes Home
//                             if (Navigator.canPop(context)) {
//                               Navigator.pop(context);
//                             } else {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => const HomeScreen(),
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                       ),
//                     ),

//                     // --- 2. PRODUCT IMAGE ---
//                     Container(
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 10,
//                       ),
//                       height: 250,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: const Color(
//                           0xFFE8F5E9,
//                         ), // Light Green Background
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Center(
//                         // Added Center to ensure it sits in the middle
//                         child: Padding(
//                           padding: const EdgeInsets.all(
//                             20.0,
//                           ), // Added padding so it doesn't touch edges
//                           child: Image.asset(
//                             'assets/burger.png', // CHANGED: Ensure this matches your Home Screen image
//                             fit: BoxFit.contain,
//                             width:
//                                 200, // Explicit width to ensure it's large enough
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     // --- 3. QUANTITY SELECTOR ---
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _buildQuantityButton(Icons.remove, () {
//                           if (_quantity > 1) setState(() => _quantity--);
//                         }),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: Text(
//                             "$_quantity",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         _buildQuantityButton(Icons.add, () {
//                           setState(() => _quantity++);
//                         }),
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     // --- 4. TITLE & PRICE ---
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: const [
//                           Text(
//                             "Veg Burger",
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             "₹180",
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     // --- 5. RATING & TIME ---
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           // Stars
//                           Row(
//                             children: List.generate(
//                               4,
//                               (index) => const Icon(
//                                 Icons.star,
//                                 color: Colors.amber,
//                                 size: 20,
//                               ),
//                             ),
//                           ),
//                           // Time
//                           Row(
//                             children: const [
//                               Icon(
//                                 Icons.access_time,
//                                 size: 16,
//                                 color: Colors.grey,
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 "10-15min",
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // --- 6. DESCRIPTION ---
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Text(
//                         "Crispy veg patty with fresh onions, tomatoes, and chutney inside a soft bun. Perfect for a quick bite!",
//                         style: TextStyle(color: Colors.black87, height: 1.5),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // --- 7. REVIEWS TITLE ---
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Text(
//                         "Reviews",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     // --- 8. REVIEW CARDS ---
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Column(
//                         children: [
//                           _buildReviewCard(
//                             "Good burger for the price.",
//                             "The patty is crispy.",
//                             4.3,
//                           ),
//                           const SizedBox(height: 10),
//                           _buildReviewCard(
//                             "Very tasty and fresh.",
//                             "Perfect for a quick lunch!",
//                             4.0,
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // --- 9. ADD TO CART BUTTON ---
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                       child: SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             // Add to Cart Logic
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   "Added $_quantity Veg Burger(s) to Cart!",
//                                 ),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.shopping_cart_outlined),
//                           label: const Text(
//                             "Add To Cart",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(
//                               0xFFC8E6C9,
//                             ), // Light Green
//                             foregroundColor: Colors.black,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- HELPER WIDGETS ---

//   Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
//     return Container(
//       height: 40,
//       width: 40,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: IconButton(
//         icon: Icon(icon, size: 20, color: Colors.black),
//         onPressed: onPressed,
//         padding: EdgeInsets.zero,
//       ),
//     );
//   }

//   Widget _buildReviewCard(String title, String subtitle, double rating) {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F8E9), // Very light green
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Row(
//         children: [
//           // Profile Placeholder
//           Container(
//             height: 40,
//             width: 40,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//           ),
//           const SizedBox(width: 15),
//           // Text
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: const TextStyle(fontSize: 10, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ),
//           // Rating
//           Column(
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.star, size: 12, color: Colors.amber),
//                   Text(
//                     " $rating",
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 5),
//               Row(
//                 children: List.generate(
//                   3,
//                   (index) =>
//                       const Icon(Icons.star, size: 10, color: Colors.amber),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
