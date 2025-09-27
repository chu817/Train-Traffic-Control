import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import '../utils/page_transitions_fixed.dart';
import '../widgets/user_menu.dart';
import '../widgets/app_sidebar.dart';
import '../services/train_api_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with TickerProviderStateMixin {
  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;
  
  // Data for charts
  final List<FlSpot> punctualityData = [];
  final List<FlSpot> delayData = [];
  Map<String, dynamic>? _metrics;
  bool _loading = false;
  String? _error;
  
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
    
    _loadPerformance();
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  // Toggle sidebar expanded/collapsed state
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
  
  Future<void> _loadPerformance() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      // Align with dashboard: request metrics for AGC (Agra Cantt)
      final data = await TrainApiService.getPerformanceMetrics(stations: const ['AGC']);
      _metrics = data;
      // Build time series from backend trends
      punctualityData.clear();
      delayData.clear();
      final List<dynamic> p = (data['trends']?['punctuality'] as List? ?? []);
      final List<dynamic> d = (data['trends']?['average_delay'] as List? ?? []);
      for (final e in p) {
        final hour = (e['hour'] ?? 0).toDouble();
        final value = (e['value'] ?? 0).toDouble();
        punctualityData.add(FlSpot(hour, value));
      }
      for (final e in d) {
        final hour = (e['hour'] ?? 0).toDouble();
        final value = (e['value'] ?? 0).toDouble();
        delayData.add(FlSpot(hour, value));
      }
      if (!mounted) return;
      setState(() { _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
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
                    currentPage: 'performance',
                  );
                },
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top app bar with hamburger menu
                  _buildTopAppBar(),
                  
                  // Header
                  _buildHeader(),
                  
                  // Main scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPerformanceDashboard(),
                          const SizedBox(height: 24),
                          _buildChartSection(),
                          const SizedBox(height: 24),
                          _buildAuditTrail(),
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
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance',
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
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  Widget _buildPerformanceDashboard() {
    final kpis = _metrics?['kpis'] as Map<String, dynamic>?;
    final statusCounts = _metrics?['status_counts'] as Map<String, dynamic>?;
    final onTime = kpis?['punctuality_rate']?.toString() ?? '—';
    final avgDelay = kpis?['average_delay_minutes']?.toString() ?? '—';
    final active = kpis?['active_trains']?.toString() ?? '—';
    final delayed = (statusCounts?['delayed'] ?? kpis?['delayed_trains'])?.toString() ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildKpiCard(
              title: 'On-time Performance', 
              value: '$onTime%',
              subtitle: 'Based on current trains',
              iconData: Icons.schedule,
              iconColor: Colors.green,
              subtitleColor: Colors.green,
            ),
            _buildKpiCard(
              title: 'Average Delay', 
              value: '$avgDelay min',
              subtitle: 'Across reporting window',
              iconData: Icons.timelapse,
              iconColor: Colors.orange,
              subtitleColor: Colors.green,
            ),
            _buildKpiCard(
              title: 'Trains Running', 
              value: active,
              subtitle: 'Actively moving',
              iconData: Icons.train,
              iconColor: Colors.blue,
              subtitleColor: Colors.grey[600]!,
            ),
            _buildKpiCard(
              title: 'Delayed Trains', 
              value: delayed,
              subtitle: 'Currently delayed',
              iconData: Icons.warning_amber,
              iconColor: Colors.red,
              subtitleColor: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildKeyStatistic(
              title: 'Most Delayed Train',
              value: 'Rajdhani Express (#12302)',
              subtitle: '42 minutes',
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildKeyStatistic(
              title: 'Busiest Station',
              value: 'New Delhi Railway Station',
              subtitle: '86 trains/day',
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildKeyStatistic(
              title: 'Network Health',
              value: 'Good',
              subtitle: 'All systems operational',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData iconData,
    required Color iconColor,
    required Color subtitleColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKeyStatistic({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Performance Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
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
                        const Text('Punctuality Rate (%)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D47A1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Today', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: punctualityData.isEmpty
                          ? const Center(child: Text('No punctuality data available'))
                          : LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 5,
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 4,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 4 != 0) return const Text('');
                                        return Text(
                                          '${value.toInt()}h',
                                          style: const TextStyle(
                                            color: Color(0xff72719b),
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 23,
                                minY: 75,
                                maxY: 100,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: punctualityData,
                                    isCurved: true,
                                    color: const Color(0xFF0D47A1),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
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
                        const Text('Average Delay (minutes)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Today', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: delayData.isEmpty
                          ? const Center(child: Text('No delay data available'))
                          : LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 5,
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 4,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 4 != 0) return const Text('');
                                        return Text(
                                          '${value.toInt()}h',
                                          style: const TextStyle(
                                            color: Color(0xff72719b),
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 23,
                                minY: 0,
                                maxY: 30,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: delayData,
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.red.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuditTrail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audit Trail - Recent Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          // You would use a DataTable or a ListView.builder for the data
          _buildAuditTrailRow(
            timestamp: '23/9/2025, 7:55:39 PM',
            action: 'Priority Override',
            train: '12002',
            operator: 'Controller-001',
            result: 'Successful',
            impact: 'Reduced delay by 8 minutes',
            resultColor: Colors.green,
          ),
          _buildAuditTrailRow(
            timestamp: '23/9/2025, 7:40:39 PM',
            action: 'Route Change',
            train: '12951',
            operator: 'Controller-002',
            result: 'Successful',
            impact: 'Avoided congestion',
            resultColor: Colors.green,
          ),
          _buildAuditTrailRow(
            timestamp: '23/9/2025, 7:25:39 PM',
            action: 'Hold Train',
            train: '22691',
            operator: 'Controller-001',
            result: 'Successful',
            impact: 'Prevented conflict',
            resultColor: Colors.green,
          ),
          _buildAuditTrailRow(
            timestamp: '23/9/2025, 6:55:39 PM',
            action: 'Signal Maintenance',
            train: '-',
            operator: 'Maintenance-Team',
            result: 'Completed',
            impact: 'Improved safety',
            resultColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailRow({
    required String timestamp,
    required String action,
    required String train,
    required String operator,
    required String result,
    required String impact,
    required Color resultColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(timestamp)),
          Expanded(child: Text(action)),
          Expanded(child: Text(train)),
          Expanded(child: Text(operator)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: resultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                result,
                style: TextStyle(color: resultColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(child: Text(impact)),
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