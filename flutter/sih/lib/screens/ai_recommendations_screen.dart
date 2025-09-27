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
import '../services/train_api_service.dart';
import '../services/auth_service.dart';

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
  
  bool _loading = false;
  String? _error;
  String _aiText = '';
  String _stationName = '';
  String _stationCode = '';
  List<LiveTrainData> _liveTrains = [];
  Map<String, dynamic>? _schedule;
  List<Map<String, dynamic>> _recommendationCards = [];
  final TextEditingController _promptCtrl = TextEditingController();

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
    _fetchContextAndRecommend();
  }
  
  @override
  void dispose() {
    _sidebarController.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchContextAndRecommend() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = AuthService().currentUser;
      final profile = user != null ? await AuthService().fetchUserProfile(user.uid) : null;
      final userStationName = (profile?['station'] as String?) ?? 'NEW DELHI';
      _stationName = userStationName;

      String code = 'NDLS';
      final allStations = await TrainApiService.getStations();
      final match = allStations.firstWhere(
        (s) => s.name.toUpperCase() == userStationName.toUpperCase(),
        orElse: () => allStations.firstWhere((s) => s.id == 'NDLS', orElse: () => allStations.first),
      );
      code = match.id;
      _stationCode = code;

      _liveTrains = await TrainApiService.getLiveTrains(stations: [code]);

      final basePrompt = 'Provide concise, safety-first operational recommendations for Indian Railway control. Consider congestion, delays, halts, and priority routing.';
      final text = await TrainApiService.getAiRecommendations(
        station: _stationName,
        liveTrains: _liveTrains,
        constraints: { 'max_items': 5 },
        prompt: basePrompt,
      );
      // Also request conflict-free schedule
      final schedule = await TrainApiService.getConflictFreeSchedule(
        station: _stationName,
        liveTrains: _liveTrains,
        constraints: { 'buffer_minutes': 5 },
      );
      // Build cards once from the AI text
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final List<Map<String, dynamic>> cards = [];
      for (int i = 0; i < lines.length; i++) {
        final t = lines[i].trim();
        cards.add({
          'id': '${DateTime.now().millisecondsSinceEpoch}-$i',
          'title': 'Recommendation ${i + 1}',
          'description': t,
          'confidence': 70 + (i * 5),
          'timeToImplement': 'Est. ${(i + 1) * 5} min',
          'expectedImpact': i == 0 ? 'Reduced dwell time' : i == 1 ? 'Improved punctuality' : 'Lower congestion',
          'tag': i == 0 ? 'Priority' : i == 1 ? 'Routing' : 'Maintenance',
          'details': 'Generated based on live trains and constraints for $_stationName ($_stationCode).',
        });
      }
      if (!mounted) return;
      setState(() { _aiText = text; _schedule = schedule; _recommendationCards = cards; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
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
                          // Removed interactive controls; generate once per session
                          _buildAiResultCards(),
                          const SizedBox(height: 24),
                          _buildScheduleSection(),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _stationName.isEmpty ? 'Station: —' : 'Station: $_stationName ($_stationCode)',
            style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Controls removed per requirements

  Widget _buildAiResultCards() {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (_recommendationCards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No recommendations yet.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _recommendationCards.length; i++)
          _buildRecommendationCard(_recommendationCards[i], i)
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: Colors.black87)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final schedule = _schedule;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: Color(0xFF0D47A1)),
              SizedBox(width: 8),
              Text('Conflict-free Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (schedule == null) const Text('No schedule generated yet.'),
          if (schedule != null) ...[
            _buildScheduleTable(schedule['slots'] as List? ?? const []),
            const SizedBox(height: 12),
            if ((schedule['notes'] as List? ?? const []).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  for (final n in (schedule['notes'] as List))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${n.toString()}'),
                    ),
                ],
              ),
          ]
        ],
      ),
    );
  }

  Widget _buildScheduleTable(List slots) {
    if (slots.isEmpty) {
      return const Text('No conflicts detected or schedule unavailable.');
    }
    return Column(
      children: [
        for (final s in slots)
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.train, color: Color(0xFF0D47A1)),
              title: Text('${s['train_number'] ?? ''} • ${s['train_name'] ?? ''}'),
              subtitle: Text('Arr: ${s['arrival'] ?? '-'}  |  Dep: ${s['departure'] ?? '-'}  |  Platform: ${s['platform'] ?? '-'}'),
              trailing: (s['conflicts'] is List && (s['conflicts'] as List).isNotEmpty)
                  ? const Icon(Icons.error_outline, color: Colors.red)
                  : const Icon(Icons.check_circle_outline, color: Colors.green)
            ),
          ),
      ],
    );
  }

  // Build a single recommendation card.
  Widget _buildRecommendationCard(Map<String, dynamic> rec, int index) {
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
                    setState(() {
                      if (index >= 0 && index < _recommendationCards.length) {
                        _recommendationCards.removeAt(index);
                      }
                    });
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
                  setState(() {
                    if (index >= 0 && index < _recommendationCards.length) {
                      _recommendationCards.removeAt(index);
                    }
                  });
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