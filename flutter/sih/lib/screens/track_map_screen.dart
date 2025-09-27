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
import '../services/train_api_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class TrackMapScreen extends StatefulWidget {
  const TrackMapScreen({super.key});

  @override
  _TrackMapScreenState createState() => _TrackMapScreenState();
}

class _TrackMapScreenState extends State<TrackMapScreen> with SingleTickerProviderStateMixin {
  // API data
  List<TrainData> _trains = [];
  List<RouteData> _routes = [];
  List<StationData> _stations = [];
  List<LiveTrainData> _liveTrains = [];
  bool _isLoading = true;
  bool _showLiveTrains = false;
  String? _error;
  Timer? _refreshTimer;

  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;

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
    
    // Load data from API
    _loadData();
    
    // Start auto-refresh for live trains
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // Cancel all timers to prevent memory leaks.
    _timeUpdateTimer?.cancel();
    _refreshTimer?.cancel();
    _sidebarController.dispose();
    super.dispose();
  }
  
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_showLiveTrains) {
        _loadData();
      }
    });
  }
  
  // Load data from API
  Future<void> _loadData() async {
    try {
      // Only show loading state on initial load, not on refreshes
      if (_stations.isEmpty) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Get user's selected station
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final userProfile = await AuthService().fetchUserProfile(currentUser.uid);
      final userStationName = userProfile?['station'] ?? 'NEW DELHI'; // Default to New Delhi if no station
      
      // Convert station name to station code
      String userStationCode = 'NDLS'; // Default fallback
      if (userStationName != null) {
        // Try to find the station code by name
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
      
      print('🎯 User selected station name: $userStationName');
      print('🎯 User selected station code: $userStationCode');

      // Fetch only connected stations (no trains or routes)
      final stations = await TrainApiService.getConnectedStations(userStationCode);

      // Load live trains if enabled
      List<LiveTrainData> liveTrains = [];
      if (_showLiveTrains) {
        try {
          liveTrains = await TrainApiService.getLiveTrains(stations: [userStationCode]);
        } catch (e) {
          print('❌ Error loading live trains: $e');
        }
      }

      setState(() {
        _trains = []; // No trains
        _routes = []; // No routes
        _stations = stations;
        _liveTrains = liveTrains;
        _isLoading = false;
      });
      
      print('✅ Loaded ${_stations.length} connected stations for $userStationCode');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading data: $e');
    }
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
          // Live trains toggle
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.train,
                  color: _showLiveTrains ? Colors.green : const Color(0xFF0D47A1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showLiveTrains,
                  onChanged: (value) {
                    setState(() {
                      _showLiveTrains = value;
                    });
                    _loadData(); // Reload data with new setting
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Live Trains',
                    style: TextStyle(
                      color: _showLiveTrains ? Colors.green : const Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0D47A1)),
            onPressed: () {
              _loadData();
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
        const SizedBox(width: 16),
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
            _error != null ? 'Connection Issue' : 'All Systems Operational',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _error != null ? Colors.red[600] : Colors.green[600],
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
    if (_isLoading) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0D47A1)),
              SizedBox(height: 16),
              Text('Loading train data...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load train data'),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Convert API data to map format - only stations
    final List<StationMarker> stationMarkers = _buildStationMarkers();
    
    // No train markers or route points
    final List<LatLng> routePoints = [];

    return Container(
      height: 500, // Increased height for better visibility
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            TrainMapWidget(
          initialCenter: const LatLng(23.0225, 72.5714), // Center on India
          initialZoom: 5.0,
          trainMarkers: _showLiveTrains ? _liveTrains.map((train) => train.toTrainMarker()).toList() : [],
          routePoints: routePoints,
          stationMarkers: stationMarkers,
          bounds: _calculateStationBounds(),
          autoFitBounds: true,
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
            // Live tracking indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Station count indicator
            if (stationMarkers.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stationMarkers.length} Stations',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build the track status panel.
  Widget _buildTrackStatusPanel() {
    return _buildStatusPanel(
      title: 'Station Count',
      children: [
        _buildStatusItem(
          'Total Connected: ${_stations.length}',
          Icons.numbers,
          Colors.blue,
        ),
        _buildStatusItem(
          'Major Stations: ${_stations.where((s) => s.type == 'major').length}',
          Icons.location_city,
          Colors.blue,
        ),
        _buildStatusItem(
          'Minor Stations: ${_stations.where((s) => s.type == 'minor').length}',
          Icons.place,
          Colors.green,
        ),
      ],
    );
  }

  // Build the signal status panel.
  Widget _buildSignalStatusPanel() {
    return _buildStatusPanel(
      title: 'Station Details',
      children: _stations.map((station) {
        return _buildStatusItem(
          '${station.name} (${station.id})',
          Icons.info,
          station.type == 'major' ? Colors.blue : Colors.green,
        );
      }).toList(),
    );
  }

  // Build active trains panel
  Widget _buildActiveTrainsPanel() {
    if (_showLiveTrains && _liveTrains.isNotEmpty) {
      return _buildStatusPanel(
        title: 'Live Trains',
        children: _liveTrains.map((train) {
          Color statusColor;
          IconData statusIcon;
          String statusText;
          
          // Use demo status for better demo experience
          if (train.demoStatus != null) {
            switch (train.demoStatus) {
              case 'RUNNING_FAST':
                statusColor = Colors.green;
                statusIcon = Icons.speed;
                statusText = 'FAST';
                break;
              case 'BRIEF_HALT':
                statusColor = Colors.orange;
                statusIcon = Icons.pause;
                statusText = 'BRIEF HALT';
                break;
              case 'ON_TIME':
                statusColor = Colors.blue;
                statusIcon = Icons.train;
                statusText = 'ON TIME';
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.train;
                statusText = 'UNKNOWN';
            }
          } else {
            // Fallback to original logic
            if (train.haltMins > 0) {
              statusColor = Colors.red;
              statusIcon = Icons.stop;
              statusText = 'HALT';
            } else if (train.minsSinceDep > 30) {
              statusColor = Colors.orange;
              statusIcon = Icons.schedule;
              statusText = 'DELAYED';
            } else {
              statusColor = Colors.green;
              statusIcon = Icons.train;
              statusText = 'RUNNING';
            }
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        train.trainName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'At: ${train.currentStationName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return _buildStatusPanel(
        title: 'Connected Stations',
        children: _stations.map((station) {
          Color statusColor;
          IconData statusIcon;
          
          if (station.type == 'major') {
            statusColor = Colors.blue;
            statusIcon = Icons.location_city;
          } else {
            statusColor = Colors.green;
            statusIcon = Icons.place;
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  station.type.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
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

  // Build station markers for the map - only connected stations
  List<StationMarker> _buildStationMarkers() {
    if (_stations.isEmpty) return [];
    
    // The first station in the list should be the user's station
    // (as returned by the connected stations API)
    final userStationCode = _stations.isNotEmpty ? _stations.first.id : '';
    
    return _stations.map((station) {
      return StationMarker(
        id: station.id,
        name: station.name,
        position: station.position,
        type: station.type,
        isUserStation: station.id == userStationCode,
      );
    }).toList();
  }

  // Calculate bounds for auto-zoom to connected stations
  LatLngBounds? _calculateStationBounds() {
    if (_stations.isEmpty) return null;
    
    double minLat = _stations.first.position.latitude;
    double maxLat = _stations.first.position.latitude;
    double minLng = _stations.first.position.longitude;
    double maxLng = _stations.first.position.longitude;
    
    for (final station in _stations) {
      minLat = minLat < station.position.latitude ? minLat : station.position.latitude;
      maxLat = maxLat > station.position.latitude ? maxLat : station.position.latitude;
      minLng = minLng < station.position.longitude ? minLng : station.position.longitude;
      maxLng = maxLng > station.position.longitude ? maxLng : station.position.longitude;
    }
    
    // Add some padding around the bounds
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    
    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }
}
