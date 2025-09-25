import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/track_map_screen.dart';
import 'screens/ai_recommendations_screen.dart';
import 'screens/override_controls_screen.dart';
import 'screens/what_if_analysis_screen.dart';
import 'screens/performance_screen.dart';

Future<void> main() async {
  print('🚀 Starting app...');
  WidgetsFlutterBinding.ensureInitialized();
  // Load dotenv so plain `flutter run` works without --dart-define
  try {
    await dotenv.load(fileName: '.env');
    print('📦 .env loaded');
  } catch (_) {
    print('⚠️ .env not found or failed to load; relying on --dart-define');
  }
  
  try {
    if (kIsWeb) {
      print('🌐 Initializing Firebase for web...');
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
      print('✅ Firebase initialized successfully!');
    } else {
      print('📱 Initializing Firebase for mobile...');
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully!');
    }
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Continue anyway to see if the app loads
  }
  
  print('🎯 Running MyApp...');
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
            backgroundColor: WidgetStateProperty.all(const Color(0xFF0D47A1)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          print('🔍 Auth state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ Showing loading...');
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            print('👤 User logged in, showing Dashboard');
            return const DashboardScreen();
          }
          print('🔐 No user, showing Login');
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/track_map': (context) => const TrackMapScreen(),
        '/ai_recommendations': (context) => const AiRecommendationsScreen(),
        '/override_controls': (context) => const OverrideControlsScreen(),
        '/what_if_analysis': (context) => const WhatIfAnalysisScreen(),
        '/performance': (context) => const PerformanceScreen(),
      }
    );
  }
}
