// lib/firebase_options.dart
// This file contains the Firebase configuration options for your Flutter app.
// Values are sourced from --dart-define at runtime.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String get _apiKey => const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_API_KEY') ?? '');
  static String get _authDomain => const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_AUTH_DOMAIN') ?? '');
  static String get _projectId => const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_PROJECT_ID') ?? '');
  static String get _storageBucket => const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_STORAGE_BUCKET') ?? '');
  static String get _messagingSenderId => const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_MESSAGING_SENDER_ID') ?? '');
  static String get _appId => const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_APP_ID') ?? '');
  static String get _measurementId => const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: '')
      .ifEmpty(() => dotenv.maybeGet('FIREBASE_MEASUREMENT_ID') ?? '');

  static FirebaseOptions get web {
    print('Firebase Config Debug:');
    print('API Key: ${_apiKey.isEmpty ? "EMPTY" : "SET"}');
    print('Project ID: ${_projectId.isEmpty ? "EMPTY" : "SET"}');
    print('Auth Domain: ${_authDomain.isEmpty ? "EMPTY" : "SET"}');

    if (_apiKey.isEmpty || _projectId.isEmpty) {
      throw Exception('Firebase configuration is missing! Provide via --dart-define or .env');
    }
    
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain,
      storageBucket: _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
    );
  }
}

extension _IfEmpty on String {
  String ifEmpty(String Function() fallback) => isEmpty ? fallback() : this;
}