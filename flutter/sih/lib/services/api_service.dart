// lib/services/api_service.dart
// Flutter HTTP Service for Indian Railways Control Center Backend Integration

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL for your Flask backend
  static const String baseUrl = 'http://localhost:5000/api';  // Change this to your server IP

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client with persistent session
  final http.Client _client = http.Client();

  // Common headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // =============================================
  // AUTHENTICATION METHODS
  // =============================================

  /// Login user with credentials
  Future<Map<String, dynamic>> login(String username, String password, String role) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/logout'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Check session status
  Future<Map<String, dynamic>> checkSession() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/session'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // =============================================
  // TRAIN DATA METHODS
  // =============================================

  /// Get all trains information
  Future<Map<String, dynamic>> getTrains() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/trains'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get specific train details
  Future<Map<String, dynamic>> getTrainDetails(String trainNumber) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/trains/$trainNumber'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Refresh train data
  Future<Map<String, dynamic>> refreshTrainData() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/refresh'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // =============================================
  // ALERTS METHODS
  // =============================================

  /// Get critical alerts
  Future<Map<String, dynamic>> getAlerts() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/alerts'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Acknowledge an alert
  Future<Map<String, dynamic>> acknowledgeAlert(String alertId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/alerts/$alertId/acknowledge'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // =============================================
  // DASHBOARD METHODS  
  // =============================================

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // =============================================
  // UTILITY METHODS
  // =============================================

  /// Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/health'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: $e',
        'code': response.statusCode,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

// =============================================
// USAGE EXAMPLES FOR YOUR EXISTING CODE
// =============================================

/*
// In your login_screen.dart, replace the hardcoded login logic:

// OLD CODE:
if (username == "demo" && password == "demo" && role != null) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const DashboardScreen()),
  );
}

// NEW CODE WITH BACKEND INTEGRATION:
ElevatedButton(
  onPressed: () async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final role = _selectedRole;

    if (username.isEmpty || password.isEmpty || role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call backend
    final result = await ApiService().login(username, password, role);
    Navigator.pop(context); // Close loading dialog

    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: const Text('Login to Control Center'),
),

// In your dashboard_screen.dart, replace the hardcoded data:

// OLD CODE:
final List<TrainInfo> _trains = [
  TrainInfo(number: "12002", name: "Shatabdi Express", ...),
  // ... hardcoded data
];

// NEW CODE WITH BACKEND INTEGRATION:
List<TrainInfo> _trains = [];
bool _isLoading = true;

@override
void initState() {
  super.initState();
  _loadTrains();
}

Future<void> _loadTrains() async {
  setState(() => _isLoading = true);

  final result = await ApiService().getTrains();

  if (result['success']) {
    final trainsData = result['data'] as List;
    setState(() {
      _trains = trainsData.map((train) => TrainInfo(
        number: train['number'],
        name: train['name'],
        current: train['current'],
        next: train['next'],
        eta: train['eta'],
        passengers: train['passengers'],
        isDelayed: train['isDelayed'],
        delayTime: train['delayTime'],
      )).toList();
      _isLoading = false;
    });
  } else {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Failed to load trains')),
    );
  }
}

// For refresh functionality:
void refreshData() async {
  setState(() => isRefreshing = true);

  final result = await ApiService().refreshTrainData();

  if (result['success']) {
    await _loadTrains(); // Reload the trains
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Train data refreshed'),
        backgroundColor: Color(0xFF0D47A1),
      ),
    );
  }

  setState(() => isRefreshing = false);
}

// Don't forget to add http dependency to pubspec.yaml:
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # Add this line
*/
