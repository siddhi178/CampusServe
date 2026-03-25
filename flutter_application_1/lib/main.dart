import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Ensure this file exists
import 'screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async calls in main

  // 1. Initialize Firebase
  // We use DefaultFirebaseOptions.currentPlatform to ensure it works on both Android & iOS
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusServe Canteen',
      home: SplashScreen(), // Starts with your Splash Screen
    );
  }
}
