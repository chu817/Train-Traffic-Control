import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import your new screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indian Railways Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // A clean, modern font
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: const LoginScreen(), // Set the login screen as the home page
    );
  }
}
