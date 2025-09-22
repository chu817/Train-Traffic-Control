import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/track_map_screen.dart';
import 'screens/ai_recommendations_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indian Railways Control Center',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
        fontFamily: 'Roboto', // A clean, modern font
        useMaterial3: false,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(const Color(0xFF0D47A1)),
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: const LoginScreen(), // Set the login screen as the home page
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/track_map': (context) => const TrackMapScreen(),
        '/ai_recommendations': (context) => const AiRecommendationsScreen(),
      }
    );
  }
}
