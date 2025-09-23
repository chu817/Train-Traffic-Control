import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../utils/page_transitions_fixed.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedRole;
  final List<String> _roles = [
    'Station Master',
    'Train Operator',
    'Admin',
    'Any role',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Header
                Hero(
                  tag: 'app_logo',
                  child: const Icon(Icons.train_rounded, size: 60, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 16),
                Hero(
                  tag: 'app_title',
                  child: const Material(
                    color: Colors.transparent,
                    child: Text(
                      'Indian Railways',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time Train Operations Management',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                // Login Card
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Secure Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        // Username
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          hint: const Text('Select your role'),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.work_outline, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          items: _roles.map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        // Login Button
                        ElevatedButton(
                          onPressed: () {
                            final username = _usernameController.text.trim();
                            final password = _passwordController.text.trim();
                            final role = _selectedRole;
                            if (username == 'demo' && password == 'demo' && role != null) {
                              Navigator.of(context).pushReplacement(
                                PageRoutes.scaleFade(const DashboardScreen()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid credentials. Please use the demo credentials.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Login to Control Center',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        // No Google Sign-In button
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Demo Credentials Card
                Card(
                  elevation: 2.0,
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Demo Credentials', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Username: demo'),
                        Text('Password: demo'),
                        Text('Role: Any role'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Footer
                Text(
                  'This system is for authorized personnel only. All activities are monitored and logged.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2025 Indian Railways. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}