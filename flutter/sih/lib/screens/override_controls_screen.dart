// lib/screens/override_controls_screen.dart
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'login_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';

class OverrideControlsScreen extends StatefulWidget {
  const OverrideControlsScreen({super.key});

  @override
  State<OverrideControlsScreen> createState() => _OverrideControlsScreenState();
}

class _OverrideControlsScreenState extends State<OverrideControlsScreen> with SingleTickerProviderStateMixin {
  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;

  // A list of sample train numbers for the dropdown.
  final List<String> _trains = ['Choose a train...', 'Train 12951', 'Train 22691', 'Train 2002'];
  String? _selectedTrain;
  final TextEditingController _reasonController = TextEditingController();
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _selectedTrain = _trains.first;
    _updateTime();
    
    // Initialize sidebar animation controller
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _sidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    ));
    
    // Start expanded
    _sidebarController.value = 1.0;
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    _sidebarController.dispose();
    super.dispose();
  }
  
  void _updateTime() {
    if (!mounted) return;
    
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.day}/${now.month}/${now.year}, ${_formatTime(now)}';
    });
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
            // Section 1: Navigation Sidebar (Left)
            ClipRect(
              child: AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (context, child) {
                  return _buildSidebar();
                },
              ),
            ),
            // Section 2: Main Content (Right)
            Expanded(
              child: Column(
                children: [
                  // Top bar with hamburger menu
                  _buildTopAppBar(),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          // Main content row with two panels.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Manual Override Controls panel.
                              Expanded(
                                flex: 2,
                                child: _buildManualOverridePanel(),
                              ),
                              const SizedBox(width: 24),
                              // Recent Override Actions panel.
                              Expanded(
                                flex: 1,
                                child: _buildRecentActionsPanel(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Safety Notice panel.
                          _buildSafetyNoticePanel(),
                        ],
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
  
  // WIDGET: Top app bar with hamburger menu
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
        ],
      ),
    );
  }

  // WIDGET: The left navigation sidebar
  Widget _buildSidebar() {
    // Calculate width based on animation value
    final double sidebarWidth = _sidebarAnimation.value * 250;
    
    // Don't render anything when fully collapsed
    if (sidebarWidth < 1) {
      return const SizedBox(width: 0);
    }
    
    // Only show labels when sidebar width is sufficient
    final bool showLabels = sidebarWidth > 80;
    
    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(
        children: [
          // Header with logo
          if (showLabels)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: const Icon(Icons.train_rounded, size: 28, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Hero(
                          tag: 'app_title',
                          child: const Material(
                            color: Colors.transparent,
                            child: Text(
                              'Indian Railways', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Control Center', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                ],
              ),
            ),
            
          // Navigation items in scrollable area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildNavigationItem(
                      icon: Icons.dashboard, 
                      title: showLabels ? 'Dashboard' : '',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const DashboardScreen()),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      icon: Icons.map, 
                      title: showLabels ? 'Track Map' : '',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const TrackMapScreen()),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      icon: Icons.lightbulb_outline, 
                      title: showLabels ? 'AI Recommendations' : '',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const AiRecommendationsScreen()),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      icon: Icons.rule, 
                      title: showLabels ? 'Override Controls' : '',
                      isSelected: true,
                    ),
                    _buildNavigationItem(
                      icon: Icons.analytics_outlined, 
                      title: showLabels ? 'What-if Analysis' : '',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const WhatIfAnalysisScreen()),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      icon: Icons.bar_chart, 
                      title: showLabels ? 'Performance' : '',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const PerformanceScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer with logout button
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 16.0),
            child: Column(
              children: [
                if (showLabels) const Divider(height: 1),
                _buildNavigationItem(
                  icon: Icons.logout, 
                  title: showLabels ? 'Logout' : '',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      PageRoutes.fadeThrough(const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Helper for a single item in the navigation sidebar
  Widget _buildNavigationItem({
    required IconData icon, 
    required String title, 
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final bool isCollapsed = title.isEmpty;
    
    if (isCollapsed) {
      return _HoverButton(
        isSelected: isSelected,
        icon: icon,
        onTap: onTap,
        tooltipText: icon == Icons.dashboard ? 'Dashboard' :
                     icon == Icons.map ? 'Track Map' :
                     icon == Icons.lightbulb_outline ? 'AI Recommendations' :
                     icon == Icons.rule ? 'Override Controls' :
                     icon == Icons.analytics_outlined ? 'What-if Analysis' :
                     icon == Icons.bar_chart ? 'Performance' :
                     icon == Icons.logout ? 'Logout' : '',
      );
    } else {
      return _HoverListTile(
        isSelected: isSelected,
        icon: icon,
        title: title,
        onTap: onTap,
      );
    }
  }

  // WIDGET: Header for the main content area
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.rule, size: 28, color: Color(0xFF0D47A1)),
        const SizedBox(width: 12),
        const Text(
          'Override Controls',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Chip(
          label: const Text(
            '1 Critical', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red[600],
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            _currentTime, 
            style: TextStyle(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Build the "Manual Override Controls" panel.
  Widget _buildManualOverridePanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Override Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select Train'),
            const SizedBox(height: 8),
            // Train selection dropdown.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTrain,
                  isExpanded: true,
                  items: _trains.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTrain = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Reason for Override'),
            const SizedBox(height: 8),
            // Reason for override text field.
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason for manual intervention...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Override action buttons.
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionButton(Icons.arrow_forward, 'Change Priority'),
                _buildActionButton(Icons.pause, 'Hold Train'),
                _buildActionButton(Icons.refresh, 'Change Route'),
                _buildActionButton(Icons.trending_up, 'Adjust Speed'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build an action button.
  Widget _buildActionButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action requested'),
            backgroundColor: const Color(0xFF0D47A1),
          ),
        );
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF0D47A1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Build the "Recent Override Actions" panel.
  Widget _buildRecentActionsPanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Override Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No recent override actions',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recent override actions will appear here',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the "Safety Notice" panel.
  Widget _buildSafetyNoticePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.amber[700], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Notice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manual overrides should only be used in emergency situations. All actions are logged and will be reviewed. Ensure proper authorization before executing any override.',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Hover widgets for navigation items
class _HoverButton extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltipText;
  
  const _HoverButton({
    required this.isSelected,
    required this.icon,
    this.onTap,
    required this.tooltipText,
  });
  
  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: widget.isSelected 
              ? const Color(0xFFE3F2FD) 
              : isHovering 
                  ? const Color(0xFFF5F5F5)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            widget.icon,
            size: 22,
            color: widget.isSelected 
                ? const Color(0xFF0D47A1) 
                : isHovering
                    ? const Color(0xFF42A5F5)
                    : Colors.grey[600],
          ),
          onPressed: widget.onTap,
          tooltip: widget.tooltipText,
        ),
      ),
    );
  }
}

class _HoverListTile extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  
  const _HoverListTile({
    required this.isSelected,
    required this.icon,
    required this.title,
    this.onTap,
  });
  
  @override
  _HoverListTileState createState() => _HoverListTileState();
}

class _HoverListTileState extends State<_HoverListTile> {
  bool isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isSelected 
              ? const Color(0xFFE3F2FD) 
              : isHovering
                  ? const Color(0xFFF5F5F5)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            widget.icon, 
            color: widget.isSelected 
                ? const Color(0xFF0D47A1) 
                : isHovering
                    ? const Color(0xFF42A5F5)
                    : Colors.grey[700],
          ),
          title: Text(
            widget.title, 
            style: TextStyle(
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal, 
              color: widget.isSelected 
                  ? const Color(0xFF0D47A1) 
                  : isHovering
                      ? const Color(0xFF42A5F5)
                      : Colors.black87,
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}