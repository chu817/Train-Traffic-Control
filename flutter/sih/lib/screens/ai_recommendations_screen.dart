// lib/screens/ai_recommendations_screen.dart
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'track_map_screen.dart';
import 'login_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';
import '../widgets/user_menu.dart';
import '../widgets/app_sidebar.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() => _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> with SingleTickerProviderStateMixin {
  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;
  
  // A list of recommendation data. You can replace this with data fetched from an API.
  final List<Map<String, dynamic>> _recommendations = [
    {
      'title': 'Prioritize Express Service',
      'tag': 'Priority',
      'description': 'Hold 12951 at current station and give priority to oncoming express trains',
      'confidence': 87,
      'timeToImplement': '5 min to implement',
      'expectedImpact': 'Reduces overall delay by 12 minutes',
      'details': 'This recommendation is based on real-time traffic data and future predictions. Implementing this will reduce congestion and ensure on-time performance for express trains, minimizing cascading delays.'
    },
    {
      'title': 'Optimize Junction Routing',
      'tag': 'Routing',
      'description': 'Redirect Train 22691 through alternate route at Kanpur Junction to avoid congestion',
      'confidence': 72,
      'timeToImplement': '3 min to implement',
      'expectedImpact': 'Prevents potential 8-minute delay',
      'details': 'This is a short-term routing solution to mitigate a temporary traffic bottleneck. The alternate route is clear and will not affect other scheduled services.'
    },
    {
      'title': 'Schedule Signal Maintenance',
      'tag': 'Maintenance',
      'description': 'Signal B2 showing intermittent failures - schedule maintenance during low traffic window',
      'confidence': 94,
      'timeToImplement': '30 min to implement',
      'expectedImpact': 'Prevents potential safety hazard',
      'details': 'Signal B2 has reported multiple intermittent failures in the past 24 hours. A maintenance crew should be dispatched during the next low traffic period to address the issue before it causes a critical failure.'
    },
  ];

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
  
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRoutes.fadeThrough(const DashboardScreen()),
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
                  return AppSidebar(
                    sidebarAnimation: _sidebarAnimation,
                    currentPage: 'ai_recommendations',
                  );
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
                          // Loop through the list of recommendations to build each card.
                          ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
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
          const UserMenu(),
        ],
      ),
    );
  }


  // WIDGET: Header for the main content area
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.lightbulb_outline, size: 28, color: Color(0xFF0D47A1)),
        const SizedBox(width: 12),
        const Text(
          'AI Recommendations',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'AI Active - ${_recommendations.length} recommendations',
            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Build a single recommendation card.
  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and tag section.
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Color(0xFF0D47A1), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTag(rec['tag']),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    // Action to dismiss the card
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recommendation dismissed'),
                        backgroundColor: Color(0xFF0D47A1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Description.
            Text(
              rec['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Confidence and time to implement.
            Row(
              children: [
                Text(
                  'Confidence: ${rec['confidence']}%', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 24),
                Text(
                  rec['timeToImplement'], 
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar for confidence.
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rec['confidence'] / 100,
                backgroundColor: Colors.grey[200],
                color: _getConfidenceColor(rec['confidence']),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            // Expected impact.
            Row(
              children: [
                Icon(
                  Icons.trending_up, 
                  color: Colors.green[700],
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expected Impact: ${rec['expectedImpact']}',
                  style: TextStyle(color: Colors.green[700], fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            // Collapsible "View Details" section.
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                title: Text(
                  'View Details',
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rec['details'],
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            // Action buttons.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recommendation dismissed'),
                        backgroundColor: Color(0xFF0D47A1),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recommendation implemented'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 2,
                  ),
                  child: const Text('Implement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the colored tag.
  Widget _buildTag(String text) {
    Color tagColor;
    Color textColor;
    
    switch (text) {
      case 'Priority':
        tagColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      case 'Routing':
        tagColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case 'Maintenance':
        tagColor = Colors.amber[100]!;
        textColor = Colors.amber[900]!;
        break;
      default:
        tagColor = Colors.grey[100]!;
        textColor = Colors.grey[900]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: textColor, 
          fontSize: 12, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
  
  // Helper to get color based on confidence level
  Color _getConfidenceColor(int confidence) {
    if (confidence >= 90) {
      return Colors.green[600]!;
    } else if (confidence >= 70) {
      return Colors.blue[600]!;
    } else if (confidence >= 50) {
      return Colors.amber[600]!;
    } else {
      return Colors.red[600]!;
    }
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