// lib/screens/track_map_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dashboard_screen.dart';
import 'ai_recommendations_screen.dart';
import 'login_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';
import '../widgets/user_menu.dart';
import '../services/auth_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/train_map_widget.dart';
import 'package:latlong2/latlong.dart';

class TrackMapScreen extends StatefulWidget {
  const TrackMapScreen({super.key});

  @override
  _TrackMapScreenState createState() => _TrackMapScreenState();
}

class _TrackMapScreenState extends State<TrackMapScreen> with SingleTickerProviderStateMixin {
  // A map to store the position of each train.
  final Map<int, double> _trainPositions = {
    12951: 0.5,
    2265: 0.9,
    2002: 0.2,
  };
  
  // A map to store the status of each track.
  final Map<String, bool> _trackStatus = {
    'Track 1': true,
    'Track 2': true,
    'Track 3': false,
    'Junction A': true,
  };
  
  // A map to store the status of each signal.
  final Map<String, String> _signalStatus = {
    'Signal A1': 'green',
    'Signal A2': 'yellow',
    'Signal B1': 'green',
    'Signal B2': 'red',
  };

  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;

  late Timer _timer;
  Timer? _timeUpdateTimer;
  final Random _random = Random();
  String _currentTime = '';

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
    
    // Start a timer that updates the train and signal positions every 3 seconds.
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateTrainPositions();
      _updateSignalStatus();
    });
  }

  @override
  void dispose() {
    // Cancel all timers to prevent memory leaks.
    _timer.cancel();
    _timeUpdateTimer?.cancel();
    _sidebarController.dispose();
    super.dispose();
  }
  
  // Update train positions randomly.
  void _updateTrainPositions() {
    setState(() {
      _trainPositions.forEach((key, value) {
        // Move each train randomly by a small amount.
        _trainPositions[key] = (value + (_random.nextDouble() - 0.5) * 0.1).clamp(0.0, 1.0);
      });
    });
  }

  // Update signal status randomly.
  void _updateSignalStatus() {
    setState(() {
      _signalStatus.forEach((key, value) {
        // Randomly change the signal status with a small probability
        if (_random.nextInt(10) < 2) { // 20% chance of change
          final statuses = ['green', 'yellow', 'red'];
          _signalStatus[key] = statuses[_random.nextInt(statuses.length)];
        }
      });
    });
  }
  
  void _updateTime() {
    if (!mounted) return;
    
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.day}/${now.month}/${now.year}, ${_formatTime(now)}';
    });
    
    // Update time every minute using a proper timer that we can cancel
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer(const Duration(minutes: 1), _updateTime);
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
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
  
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRoutes.fadeThrough(const DashboardScreen()),
    );
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
                    currentPage: 'track_map',
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTrackLayoutSection(),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildTrackStatusPanel(),
                                    const SizedBox(height: 16),
                                    _buildSignalStatusPanel(),
                                    const SizedBox(height: 16),
                                    _buildActiveTrainsPanel(),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                  backgroundColor: Color(0xFF0D47A1),
                ),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0D47A1)),
            onPressed: () {
              _updateTrainPositions();
              _updateSignalStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Map data refreshed'),
                  backgroundColor: Color(0xFF0D47A1),
                ),
              );
            },
            tooltip: 'Refresh data',
          ),
          const SizedBox(width: 8),
          const UserMenu(),
        ],
      ),
    );
  }

  // WIDGET: Header for the main content area
  Widget _buildHeader() {
    return Row(
      children: [
        const Text('Track Map', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const Spacer(),
        FutureBuilder<Map<String, dynamic>?>(
          future: _loadUserStation(),
          builder: (context, snapshot) {
            final station = snapshot.data != null ? (snapshot.data!['station'] as String?) : null;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place, size: 16, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 6),
                  Text(
                    station == null || station.isEmpty ? 'Station: Not set' : 'Station: $station',
                    style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Chip(
          label: Text(
            _trackStatus.containsValue(false) ? 'Track Issue' : 'All Tracks Clear',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _trackStatus.containsValue(false) ? Colors.red[600] : Colors.green[600],
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

  Future<Map<String, dynamic>?> _loadUserStation() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    return await AuthService().fetchUserProfile(user.uid);
  }

  // Build the track layout section with dynamic trains.
  Widget _buildTrackLayoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Track Layout - Section A',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green[600], size: 10),
                  const SizedBox(width: 8),
                  Text(
                    'Live',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTrackNetwork(),
          const SizedBox(height: 16),
          const Text(
            'Legend:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(color: Colors.blue, label: 'Route Line'),
              _buildLegendItem(color: Colors.green, label: 'Train Running'),
              _buildLegendItem(color: Colors.orange, label: 'Train Delayed'),
              _buildLegendItem(color: Colors.red, label: 'Train Stopped'),
              _buildLegendItem(color: Colors.grey, label: 'Train Maintenance'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildTrackNetwork() {
    // Sample train data for demonstration
    final List<TrainMarker> trainMarkers = [
      TrainMarker(
        id: '12951',
        name: 'Rajdhani Express',
        position: const LatLng(28.6139, 77.2090), // Delhi
        status: TrainStatus.running,
        route: 'Delhi-Mumbai',
        lastUpdate: DateTime.now(),
      ),
      TrainMarker(
        id: '2265',
        name: 'Shatabdi Express',
        position: const LatLng(19.0760, 72.8777), // Mumbai
        status: TrainStatus.delayed,
        route: 'Mumbai-Pune',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      TrainMarker(
        id: '2002',
        name: 'Duronto Express',
        position: const LatLng(12.9716, 77.5946), // Bangalore
        status: TrainStatus.running,
        route: 'Bangalore-Chennai',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    // Sample route points (Delhi to Mumbai)
    final List<LatLng> routePoints = [
      const LatLng(28.6139, 77.2090), // Delhi
      const LatLng(26.2389, 73.0243), // Ajmer
      const LatLng(23.0225, 72.5714), // Ahmedabad
      const LatLng(19.0760, 72.8777), // Mumbai
    ];

    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TrainMapWidget(
          initialCenter: const LatLng(23.0225, 72.5714), // Center on India
          initialZoom: 5.0,
          trainMarkers: trainMarkers,
          routePoints: routePoints,
          onTap: (point) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tapped at: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'),
                backgroundColor: const Color(0xFF0D47A1),
              ),
            );
          },
          onLongPress: (point) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Long pressed at: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'),
                backgroundColor: const Color(0xFF0D47A1),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build the track status panel.
  Widget _buildTrackStatusPanel() {
    return _buildStatusPanel(
      title: 'Track Status',
      children: _trackStatus.entries.map((entry) {
        final trackName = entry.key;
        final isGood = entry.value;
        return _buildStatusItem(
          trackName,
          isGood ? Icons.check_circle : Icons.warning,
          isGood ? Colors.green : Colors.red,
        );
      }).toList(),
    );
  }

  // Build the signal status panel.
  Widget _buildSignalStatusPanel() {
    return _buildStatusPanel(
      title: 'Signal Status',
      children: _signalStatus.entries.map((entry) {
        final signalName = entry.key;
        final status = entry.value;
        Color color;
        switch (status) {
          case 'green':
            color = Colors.green;
            break;
          case 'yellow':
            color = Colors.yellow[700]!;
            break;
          case 'red':
            color = Colors.red;
            break;
          default:
            color = Colors.grey;
        }
        return _buildStatusItem(
          signalName,
          Icons.circle,
          color,
        );
      }).toList(),
    );
  }

  // Build active trains panel
  Widget _buildActiveTrainsPanel() {
    return _buildStatusPanel(
      title: 'Active Trains',
      children: _trainPositions.entries.map((entry) {
        final trainNumber = entry.key;
        final position = entry.value;
        final progress = (position * 100).toStringAsFixed(0);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.train, color: Colors.red[300], size: 20),
                  const SizedBox(width: 8),
                  Text("Train #$trainNumber"),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: position,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "$progress% complete",
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Build a generic status panel.
  Widget _buildStatusPanel({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  // Helper widget to build a status list item.
  Widget _buildStatusItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
