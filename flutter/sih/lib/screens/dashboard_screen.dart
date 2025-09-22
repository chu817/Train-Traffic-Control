// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'track_map_screen.dart';

// A simple data model for our train information
class TrainInfo {
  final String number;
  final String name;
  final String current;
  final String next;
  final String eta;
  final int passengers;
  final bool isDelayed;
  final String delayTime;

  TrainInfo({
    required this.number,
    required this.name,
    required this.current,
    required this.next,
    required this.eta,
    required this.passengers,
    this.isDelayed = false,
    this.delayTime = '',
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;

  // Dummy data for the train status
  final List<TrainInfo> _trains = [
    TrainInfo(number: '12002', name: 'Shatabdi Express', current: 'New Delhi', next: 'Kanpur Central', eta: '14:30', passengers: 1200),
    TrainInfo(number: '12951', name: 'Mumbai Rajdhani', current: 'Vadodara', next: 'Surat', eta: '16:45', passengers: 1800, isDelayed: true, delayTime: '+25 min'),
    TrainInfo(number: '22691', name: 'Rajdhani Express', current: 'Gwalior', next: 'Jhansi', eta: '18:20', passengers: 1500),
    TrainInfo(number: '12425', name: 'Jammu Express', current: 'Ambala', next: 'Jammu Tawi', eta: '21:15', passengers: 1100, isDelayed: true, delayTime: '+39 min'),
  ];
  
  String _currentTime = '';
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
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
    _sidebarController.dispose();
    super.dispose();
  }
  
  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.day}/${now.month}/${now.year}, ${_formatTime(now)}';
    });
    // Update time every minute
    Future.delayed(const Duration(minutes: 1), _updateTime);
  }
  
  void _refreshData() {
    setState(() {
      _isRefreshing = true;
    });
    
    // Simulate data refresh
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Train data refreshed'),
          backgroundColor: Color(0xFF0D47A1),
        ),
      );
    });
  }
  
  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
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
                          MaterialPageRoute(builder: (context) => const TrackMapScreen()),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      icon: Icons.lightbulb_outline, 
                      title: showLabels ? 'AI Recommendations' : '',
                    ),
                    _buildNavigationItem(
                      icon: Icons.rule, 
                      title: showLabels ? 'Override Controls' : '',
                    ),
                    _buildNavigationItem(
                      icon: Icons.analytics_outlined, 
                      title: showLabels ? 'What-if Analysis' : '',
                    ),
                    _buildNavigationItem(
                      icon: Icons.bar_chart, 
                      title: showLabels ? 'Performance' : '',
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
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 22,
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[600],
          ),
          onPressed: onTap,
          // Use appropriate tooltip when collapsed - based on the icon
          tooltip: icon == Icons.dashboard ? 'Dashboard' :
                 icon == Icons.map ? 'Track Map' :
                 icon == Icons.lightbulb_outline ? 'AI Recommendations' :
                 icon == Icons.rule ? 'Override Controls' :
                 icon == Icons.analytics_outlined ? 'What-if Analysis' :
                 icon == Icons.bar_chart ? 'Performance' :
                 icon == Icons.logout ? 'Logout' : '',
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon, 
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[700],
          ),
          title: Text(
            title, 
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
              color: isSelected ? const Color(0xFF0D47A1) : Colors.black87,
            ),
          ),
          onTap: onTap,
        ),
      );
    }
  }

  // WIDGET: Header for the main content area
  Widget _buildHeader() {
    return Row(
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: _isRefreshing ? const Color(0xFF0D47A1) : Colors.grey[600],
          ),
          onPressed: _isRefreshing ? null : _refreshData,
          tooltip: 'Refresh data',
        ),
        const SizedBox(width: 8),
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

  // WIDGET: The red critical alert box
  Widget _buildCriticalAlerts() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.red[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 12),
            // Added Expanded to prevent overflow
            Expanded(
              child: const Text(
                'Signal failure at Junction A - Track 3',
                style: TextStyle(fontWeight: FontWeight.bold),
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
              child: const Text('Acknowledge'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: The main section with all the train status cards
  Widget _buildRealTimeTrainStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Real-time Train Status', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)
              ),
            ),
            Icon(Icons.circle, color: Colors.green[600], size: 10),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Live - Last updated: $_currentTime', 
                style: TextStyle(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap( // Wrap is responsive and will move cards to the next line if space is tight
          spacing: 16.0,
          runSpacing: 16.0,
          children: _trains.map((train) => _buildTrainCard(train)).toList(),
        )
      ],
    );
  }

  // WIDGET: A single card for one train's status
  Widget _buildTrainCard(TrainInfo train) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(train.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(
                  label: Text(
                    train.isDelayed ? 'Delayed' : 'On Time',
                    style: TextStyle(
                      color: train.isDelayed ? Colors.red[800] : Colors.green[800], 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: train.isDelayed ? Colors.red[100] : Colors.green[100],
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
            Text(train.name, style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            _buildInfoRow(icon: Icons.location_on, title: 'Current', value: train.current),
            _buildInfoRow(icon: Icons.arrow_forward, title: 'Next', value: train.next),
            _buildInfoRow(
              icon: Icons.access_time,
              title: 'ETA',
              value: train.eta,
              trailingText: train.delayTime,
              trailingColor: Colors.red
            ),
            _buildInfoRow(icon: Icons.group, title: 'Passengers', value: train.passengers.toString()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Showing details for ${train.name}'),
                        backgroundColor: const Color(0xFF0D47A1),
                      ),
                    );
                  }, 
                  child: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tracking ${train.name} in real-time'),
                        backgroundColor: const Color(0xFF0D47A1),
                      ),
                    );
                  }, 
                  child: const Text('Track'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Helper for a row of info inside the train card (e.g., "Current: New Delhi")
  Widget _buildInfoRow({required IconData icon, required String title, required String value, String? trailingText, Color? trailingColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$title:', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,)),
          if (trailingText != null)
            Text(trailingText, style: TextStyle(color: trailingColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // WIDGET: The bottom section with summary statistics
  Widget _buildSummarySection() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: [
        _buildSummaryCard(title: 'On Time', value: '2', icon: Icons.check_circle_outline, color: Colors.green),
        _buildSummaryCard(title: 'Delayed', value: '2', icon: Icons.warning_amber_rounded, color: Colors.red),
        _buildSummaryCard(title: 'Total Passengers', value: '5,600', icon: Icons.group, color: const Color(0xFF0D47A1)),
        _buildSummaryCard(title: 'Avg Delay', value: '16 min', icon: Icons.timer_outlined, color: Colors.orange),
      ],
    );
  }
  
  // WIDGET: A single card for the summary section
  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Icon(icon, size: 32, color: color),
          ],
        ),
      ),
    );
  }
}
