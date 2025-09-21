// lib/screens/login_screen.dart
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedRole;
  final _roles = ['Station Master', 'Train Operator', 'Admin', 'Any role'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The main container for the whole screen
      body: Container(
        // Set up the background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Allows scrolling on smaller screens
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Section 1: Header (Icon, Title, Subtitle)
                const Icon(Icons.train_rounded, size: 60, color: Color(0xFF0D47A1)),
                const SizedBox(height: 16),
                const Text(
                  'Indian Railways',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time Train Operations Management',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                // Section 2: Login Form Card
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
                        // Username Field
                        _buildTextField(
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        _buildTextField(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),
                        // Role Dropdown
                        _buildRoleDropdown(),
                        const SizedBox(height: 24),
                        // Login Button
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Add login logic here
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Demo Credentials Card
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

                // Section 4: Footer Text
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
    );
  }

  // Helper method to build text fields to avoid code repetition
  Widget _buildTextField({required String label, required IconData icon, bool isPassword = false}) {
    return TextFormField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0D47A1)),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
  
  // Helper method to build the role dropdown
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      hint: const Text('Select your role'),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.work_outline, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      items: _roles.map((String role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(role),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedRole = newValue;
        });
      },
    );
  }
}