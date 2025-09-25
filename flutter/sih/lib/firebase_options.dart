// lib/firebase_options.dart
// This file contains the Firebase configuration options for your Flutter app.
// Values are sourced from --dart-define at runtime.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: '');

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
    measurementId: measurementId.isEmpty ? null : measurementId,
  );
}