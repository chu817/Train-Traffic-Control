import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/station_dropdown.dart';
import '../widgets/user_menu.dart';
import '../widgets/app_sidebar.dart';
import '../utils/page_transitions_fixed.dart';
import 'dashboard_screen.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  String? _station;
  bool _loading = true;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInQuart),
    );
    _sidebarController.value = 1.0;
    _load();
  }

  Future<void> _load() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final data = await AuthService().fetchUserProfile(user.uid) ?? {};
    _nameController.text = (data['displayName'] ?? '') as String;
    _station = data['station'] as String?;
    if (mounted) setState(() => _loading = false);
  }

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
        child: Row(
          children: [
            // Sidebar
            ClipRect(
              child: AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (context, child) {
                  return AppSidebar(
                    sidebarAnimation: _sidebarAnimation,
                    currentPage: 'profile',
                  );
                },
              ),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  _buildTopAppBar(),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            const Text('User Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: _nameController,
                                              decoration: InputDecoration(
                                                labelText: 'Full Name',
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
                                            StationDropdown(
                                              initialStation: _station,
                                              onChanged: (v) => _station = v,
                                            ),
                                            const SizedBox(height: 24),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final name = _nameController.text.trim();
                                                if (name.isEmpty || _station == null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name and select station')));
                                                  return;
                                                }
                                                final uid = AuthService().currentUser!.uid;
                                                await AuthService().updateUserProfile(uid: uid, displayName: name, station: _station);
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0D47A1),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.menu_open : Icons.menu,
              color: const Color(0xFF0D47A1),
            ),
            onPressed: _toggleSidebar,
            tooltip: _isSidebarExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          ),
          const Spacer(),
          const UserMenu(),
        ],
      ),
    );
  }


  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }
}


