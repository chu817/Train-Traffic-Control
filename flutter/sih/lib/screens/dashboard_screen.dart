// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';

// We're using Map<String, dynamic> for train data now instead of a class

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;
  


  // We'll use direct Maps for train data instead of a class
  
  @override
  void initState() {
    super.initState();
    
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
    _sidebarController.dispose();
    super.dispose();
  }
  
  // Simplified initialization without time updating or data refreshing
  
  void _logout() {
    Navigator.of(context).pushReplacement(
      PageRoutes.fadeThrough(const LoginScreen()),
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
  
  // Removed unused time formatting method

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
            // Use ClipRect to ensure contents don't overflow during animation
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
                          _buildCriticalAlerts(),
                          const SizedBox(height: 24),
                          _buildRealTimeTrainStatus(),
                          const SizedBox(height: 24),
                          _buildSummarySection(),
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
                      isSelected: true,
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
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const OverrideControlsScreen()),
                        );
                      },
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
                  onTap: _logout,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Railway Traffic Control System',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '1 Critical',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}, ${_formatTime(DateTime.now())}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  // WIDGET: The red critical alert box
  Widget _buildCriticalAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Critical Alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'Signal failure at Junction A - Track 3',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert acknowledged'),
                      backgroundColor: Color(0xFF0D47A1),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                child: const Text('Acknowledge'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET: The main section with all the train status cards
  Widget _buildRealTimeTrainStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Real-time Train Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 6),
                Text('Live - Last updated: ${_formatTime(DateTime.now())}', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            _buildTrainCard(
              trainNumber: '12002',
              trainName: 'Shatabdi Express',
              currentLocation: 'New Delhi',
              nextLocation: 'Kanpur Central',
              eta: '14:30',
              passengers: '1,200',
              status: 'On Time',
              statusColor: Colors.green,
            ),
            _buildTrainCard(
              trainNumber: '12951',
              trainName: 'Mumbai Rajdhani',
              currentLocation: 'Vadodara',
              nextLocation: 'Surat',
              eta: '16:45 (+22 min)',
              passengers: '1,800',
              status: 'Delayed',
              statusColor: Colors.red,
            ),
            _buildTrainCard(
              trainNumber: '22691',
              trainName: 'Rajdhani Express',
              currentLocation: 'Gwalior',
              nextLocation: 'Jhansi',
              eta: '18:20',
              passengers: '1,500',
              status: 'On Time',
              statusColor: Colors.green,
            ),
            _buildTrainCard(
              trainNumber: '12425',
              trainName: 'Jammu Express',
              currentLocation: 'Ambala',
              nextLocation: 'Jammu Tawi',
              eta: '21:15 (+39 min)',
              passengers: '1,100',
              status: 'Delayed',
              statusColor: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  // WIDGET: A single card for one train's status with hover effect
  Widget _buildTrainCard({
    required String trainNumber,
    required String trainName,
    required String currentLocation,
    required String nextLocation,
    required String eta,
    required String passengers,
    required String status,
    required Color statusColor,
  }) {
    return HoverCard(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trainNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(trainName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            _buildInfoRow(icon: Icons.location_on, label: 'Current:', value: currentLocation),
            _buildInfoRow(icon: Icons.location_on, label: 'Next:', value: nextLocation),
            _buildInfoRow(icon: Icons.access_time, label: 'ETA:', value: eta),
            _buildInfoRow(icon: Icons.person, label: 'Passengers:', value: passengers),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Details for Train $trainNumber'),
                        backgroundColor: const Color(0xFF0D47A1),
                      ),
                    );
                  }, 
                  child: const Text('Details')
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tracking Train $trainNumber'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Track'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: label,
              style: const TextStyle(color: Colors.grey),
              children: [
                TextSpan(
                  text: ' $value',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummarySection() {
    return Wrap(
      spacing: 24.0,
      runSpacing: 24.0,
      children: [
        _buildSummaryCard(
          icon: Icons.access_time,
          iconColor: Colors.green,
          title: 'On Time',
          value: '2',
        ),
        _buildSummaryCard(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          title: 'Delayed',
          value: '2',
        ),
        _buildSummaryCard(
          icon: Icons.person,
          iconColor: Colors.blue,
          title: 'Total Passengers',
          value: '5,600',
        ),
        _buildSummaryCard(
          icon: Icons.insights,
          iconColor: Colors.purple,
          title: 'Avg Delay',
          value: '15 min',
        ),
      ],
    );
  }
  
  // WIDGET: A single card for the summary section with hover effect
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return HoverCard(
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ],
        ),
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

// Hover Card class for card hover effects
class HoverCard extends StatefulWidget {
  final Widget child;
  
  const HoverCard({
    required this.child,
    super.key,
  });
  
  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _isHovering 
            ? (Matrix4.identity()..translate(0.0, -5.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(_isHovering ? 0.3 : 0.1),
              spreadRadius: _isHovering ? 3 : 1,
              blurRadius: _isHovering ? 10 : 5,
              offset: Offset(0, _isHovering ? 5 : 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}