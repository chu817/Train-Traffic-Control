// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../widgets/user_menu.dart';
import '../widgets/app_sidebar.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';
import '../services/train_api_service.dart';

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
  
  // Train data
  List<LiveTrainData> _liveTrains = [];
  bool _isLoadingTrains = false;
  String? _trainError;
  Timer? _trainRefreshTimer;
  bool _criticalAlertVisible = true;

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
    
    // Load train data
    _loadTrainData();
    
    // Start auto-refresh for trains
    _startTrainRefresh();
  }
  
  @override
  void dispose() {
    _trainRefreshTimer?.cancel();
    _sidebarController.dispose();
    super.dispose();
  }
  
  void _startTrainRefresh() {
    _trainRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadTrainData();
    });
  }
  
  Future<void> _loadTrainData() async {
    // Only show loading state on initial load, not on refreshes
    if (_liveTrains.isEmpty) {
      setState(() {
        _isLoadingTrains = true;
        _trainError = null;
      });
    }
    
    try {
      // Determine user's selected station code (same logic as Track Map)
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final userProfile = await AuthService().fetchUserProfile(currentUser.uid);
      final userStationName = userProfile?['station'] ?? 'NEW DELHI';
      String userStationCode = 'NDLS';
      if (userStationName != null) {
        final allStations = await TrainApiService.getStations();
        final matchingStation = allStations.firstWhere(
          (station) => station.name.toUpperCase() == userStationName.toUpperCase(),
          orElse: () => allStations.firstWhere(
            (station) => station.id == 'NDLS',
            orElse: () => allStations.first,
          ),
        );
        userStationCode = matchingStation.id;
      }
      
      // Load live trains for the user's station only, to match map count
      final trains = await TrainApiService.getLiveTrains(stations: [userStationCode]);
      setState(() {
        _liveTrains = trains;
        _isLoadingTrains = false;
      });
    } catch (e) {
      setState(() {
        _trainError = e.toString();
        _isLoadingTrains = false;
      });
    }
  }
  
  // Simplified initialization without time updating or data refreshing
  
  void _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const LoginScreen()));
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
                  return AppSidebar(
                    sidebarAnimation: _sidebarAnimation,
                    currentPage: 'dashboard',
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
          const UserMenu(),
        ],
      ),
    );
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
            if (_criticalAlertVisible)
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
    if (!_criticalAlertVisible) {
      return const SizedBox.shrink();
    }
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
                  setState(() {
                    _criticalAlertVisible = false;
                  });
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
              'Live Train Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 6),
                Text('Live - Last updated: ${_formatTime(DateTime.now())}', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _loadTrainData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh trains',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingTrains)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_trainError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading trains: $_trainError',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ),
              ],
            ),
          )
        else if (_liveTrains.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.grey),
                SizedBox(width: 8),
                Text('No trains available'),
              ],
            ),
          )
        else
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: _liveTrains.take(6).map((train) => _buildLiveTrainCard(train)).toList(),
          ),
      ],
    );
  }

  Widget _buildLiveTrainCard(LiveTrainData train) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (train.demoStatus != null) {
      switch (train.demoStatus) {
        case 'RUNNING_FAST':
          statusColor = Colors.green;
          statusText = 'RUNNING FAST';
          statusIcon = Icons.speed;
          break;
        case 'BRIEF_HALT':
          statusColor = Colors.orange;
          statusText = 'BRIEF HALT';
          statusIcon = Icons.pause;
          break;
        case 'ON_TIME':
          statusColor = Colors.blue;
          statusText = 'ON TIME';
          statusIcon = Icons.train;
          break;
        default:
          statusColor = Colors.grey;
          statusText = 'UNKNOWN';
          statusIcon = Icons.train;
      }
    } else {
      if (train.haltMins > 0) {
        statusColor = Colors.red;
        statusText = 'HALT';
        statusIcon = Icons.stop;
      } else if (train.minsSinceDep > 30) {
        statusColor = Colors.orange;
        statusText = 'DELAYED';
        statusIcon = Icons.schedule;
      } else {
        statusColor = Colors.green;
        statusText = 'RUNNING';
        statusIcon = Icons.train;
      }
    }

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  train.trainName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Train No: ${train.trainNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${train.currentStationName}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: ${train.type}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
    // Dynamic summary based on live trains
    final running = _liveTrains.where((t) => t.demoStatus == 'RUNNING_FAST' || (t.haltMins == 0 && t.minsSinceDep <= 30)).length;
    final halted = _liveTrains.where((t) => t.demoStatus == 'BRIEF_HALT' || t.haltMins > 0).length;
    final delayed = _liveTrains.where((t) => t.demoStatus == 'ON_TIME' ? false : (t.haltMins == 0 && t.minsSinceDep > 30)).length;
    return Wrap(
      spacing: 24.0,
      runSpacing: 24.0,
      children: [
        _buildSummaryCard(
          icon: Icons.access_time,
          iconColor: Colors.green,
          title: 'Running',
          value: '$running',
        ),
        _buildSummaryCard(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          title: 'Halt/Delay',
          value: '${halted + delayed}',
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