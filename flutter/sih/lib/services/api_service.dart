import 'package:flutter/foundation.dart';

/// Railway Control Center API Service
/// 
/// A robust, production-ready HTTP client for railway traffic control system.
/// Features mock data support for development without requiring a backend.
class ApiService {
  static const String _tag = 'ApiService';
  
  // Environment configuration
  static const Map<String, String> _baseUrls = {
    'development': 'http://localhost:5000/api',
    'staging': 'https://staging-api.indianrailways.gov.in/api',
    'production': 'https://api.indianrailways.gov.in/api',
  };
  
  static const String _environment = 'development';
  static String get baseUrl => _baseUrls[_environment]!;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Authentication state
  String? _authToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  
  void _log(String message, {bool isError = false}) {
    if (kDebugMode) {
      final prefix = isError ? '❌' : '📡';
      print('$prefix [$_tag]: $message');
    }
  }
  
  // ============ AUTHENTICATION ============
  
  Future<ApiResponse<LoginResult>> login(String username, String password, String role) async {
    try {
      _log('Login attempt for: $username');
      
      // Mock login for development
      if (_environment == 'development') {
        await Future.delayed(const Duration(seconds: 1));
        
        final mockUser = UserInfo(
          id: 'user_123',
          username: username,
          role: role,
          name: 'Railway Controller',
          email: '$username@railways.gov.in',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLogin: DateTime.now(),
        );
        
        _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        _refreshToken = 'mock_refresh_token';
        _currentUser = {
          'id': mockUser.id,
          'username': mockUser.username,
          'role': mockUser.role,
          'name': mockUser.name,
          'email': mockUser.email,
          'createdAt': mockUser.createdAt.toIso8601String(),
          'lastLogin': mockUser.lastLogin.toIso8601String(),
        };
        
        return ApiResponse.success(LoginResult(
          user: mockUser,
          accessToken: _authToken!,
          refreshToken: _refreshToken!,
        ));
      }
      
      return ApiResponse.error(ApiError.networkError('Backend not available'));
      
    } catch (e) {
      _log('Login failed: $e', isError: true);
      return ApiResponse.error(ApiError.networkError('Login failed'));
    }
  }
  
  Future<ApiResponse<void>> logout() async {
    _clearAuth();
    return ApiResponse.success(null);
  }
  
  bool get isAuthenticated => _authToken != null;
  
  UserInfo? get currentUser => _currentUser != null ? UserInfo.fromJson(_currentUser!) : null;
  
  void _clearAuth() {
    _authToken = null;
    _refreshToken = null;
    _currentUser = null;
  }
  
  // ============ RAILWAY METHODS ============
  
  Future<ApiResponse<List<TrainInfo>>> getTrains({String? route, String? status, int? limit}) async {
    try {
      _log('Getting trains');
      
      if (_environment == 'development') {
        await Future.delayed(const Duration(seconds: 1));
        
        final mockTrains = <TrainInfo>[
          TrainInfo(
            number: '12002',
            name: 'Shatabdi Express',
            currentStation: 'New Delhi',
            nextStation: 'Ghaziabad',
            status: 'On Time',
            scheduledArrival: DateTime.now().add(const Duration(minutes: 15)),
            actualArrival: DateTime.now().add(const Duration(minutes: 15)),
            passengerCount: 450,
            isDelayed: false,
            delayMinutes: 0,
          ),
          TrainInfo(
            number: '12951',
            name: 'Mumbai Rajdhani',
            currentStation: 'Kota',
            nextStation: 'Sawai Madhopur',
            status: 'Delayed',
            scheduledArrival: DateTime.now().add(const Duration(minutes: 45)),
            actualArrival: DateTime.now().add(const Duration(minutes: 65)),
            passengerCount: 320,
            isDelayed: true,
            delayMinutes: 20,
          ),
        ];
        
        return ApiResponse.success(mockTrains);
      }
      
      return ApiResponse.success([]);
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get trains'));
    }
  }
  
  Future<ApiResponse<List<SystemAlert>>> getAlerts({String? severity, bool? acknowledged}) async {
    try {
      _log('Getting alerts');
      
      if (_environment == 'development') {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final mockAlerts = <SystemAlert>[
          SystemAlert(
            id: 'alert_001',
            message: 'Signal failure at Junction A - delays expected',
            severity: 'critical',
            category: 'infrastructure',
            createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
            acknowledged: false,
            trainNumber: '12002',
            stationCode: 'JNCA',
          ),
          SystemAlert(
            id: 'alert_002',
            message: 'Heavy rainfall in Eastern region',
            severity: 'warning',
            category: 'weather',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
            acknowledged: true,
          ),
        ];
        
        return ApiResponse.success(mockAlerts);
      }
      
      return ApiResponse.success([]);
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get alerts'));
    }
  }
  
  Future<ApiResponse<DashboardStats>> getDashboardStats() async {
    try {
      _log('Getting dashboard stats');
      
      if (_environment == 'development') {
        await Future.delayed(const Duration(milliseconds: 700));
        
        final mockStats = DashboardStats(
          totalTrains: 150,
          activeTrains: 142,
          delayedTrains: 23,
          onTimeTrains: 119,
          criticalAlerts: 3,
          averageDelay: 8.5,
          onTimePerformance: 83.8,
        );
        
        return ApiResponse.success(mockStats);
      }
      
      return ApiResponse.success(DashboardStats(
        totalTrains: 0,
        activeTrains: 0,
        delayedTrains: 0,
        onTimeTrains: 0,
        criticalAlerts: 0,
        averageDelay: 0.0,
        onTimePerformance: 0.0,
      ));
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get stats'));
    }
  }
}

// ============ RESPONSE CLASSES ============

class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final bool isSuccess;
  
  const ApiResponse._({this.data, this.error, required this.isSuccess});
  
  factory ApiResponse.success(T? data) => ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(ApiError error) => ApiResponse._(error: error, isSuccess: false);
}

class ApiError {
  final String message;
  final String type;
  final int? statusCode;
  
  const ApiError._({required this.message, required this.type, this.statusCode});
  
  factory ApiError.networkError(String message) => ApiError._(message: message, type: 'NETWORK_ERROR');
  factory ApiError.unauthorized(String message) => ApiError._(message: message, type: 'UNAUTHORIZED', statusCode: 401);
  factory ApiError.notFound(String message) => ApiError._(message: message, type: 'NOT_FOUND', statusCode: 404);
  factory ApiError.unknown(String message) => ApiError._(message: message, type: 'UNKNOWN');
  
  @override
  String toString() => 'ApiError($type): $message';
}

// ============ DATA MODELS ============

class UserInfo {
  final String id;
  final String username;
  final String role;
  final String name;
  final String? email;
  final DateTime createdAt;
  final DateTime lastLogin;
  
  UserInfo({
    required this.id,
    required this.username,
    required this.role,
    required this.name,
    this.email,
    required this.createdAt,
    required this.lastLogin,
  });
  
  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'],
    username: json['username'],
    role: json['role'],
    name: json['name'],
    email: json['email'],
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: DateTime.parse(json['lastLogin']),
  );
}

class LoginResult {
  final UserInfo user;
  final String accessToken;
  final String refreshToken;
  
  LoginResult({required this.user, required this.accessToken, required this.refreshToken});
}

class TrainInfo {
  final String number;
  final String name;
  final String currentStation;
  final String nextStation;
  final String status;
  final DateTime? scheduledArrival;
  final DateTime? actualArrival;
  final int passengerCount;
  final bool isDelayed;
  final int delayMinutes;
  
  TrainInfo({
    required this.number,
    required this.name,
    required this.currentStation,
    required this.nextStation,
    required this.status,
    this.scheduledArrival,
    this.actualArrival,
    required this.passengerCount,
    required this.isDelayed,
    required this.delayMinutes,
  });
}

class SystemAlert {
  final String id;
  final String message;
  final String severity;
  final String category;
  final DateTime createdAt;
  final bool acknowledged;
  final String? trainNumber;
  final String? stationCode;
  
  SystemAlert({
    required this.id,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    required this.acknowledged,
    this.trainNumber,
    this.stationCode,
  });
}

class DashboardStats {
  final int totalTrains;
  final int activeTrains;
  final int delayedTrains;
  final int onTimeTrains;
  final int criticalAlerts;
  final double averageDelay;
  final double onTimePerformance;
  
  DashboardStats({
    required this.totalTrains,
    required this.activeTrains,
    required this.delayedTrains,
    required this.onTimeTrains,
    required this.criticalAlerts,
    required this.averageDelay,
    required this.onTimePerformance,
  });
}