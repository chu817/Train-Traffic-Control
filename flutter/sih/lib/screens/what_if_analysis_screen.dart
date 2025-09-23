import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'override_controls_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';

class WhatIfAnalysisScreen extends StatefulWidget {
  const WhatIfAnalysisScreen({super.key});

  @override
  State<WhatIfAnalysisScreen> createState() => _WhatIfAnalysisScreenState();
}

class _WhatIfAnalysisScreenState extends State<WhatIfAnalysisScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  // Animation controller for sidebar
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
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
    _tabController.dispose();
    _sidebarController.dispose();
    super.dispose();
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
            
            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with hamburger menu
                  _buildTopAppBar(),
                  
                  // Content area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildWhatIfSimulationToolSection(),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  indicatorColor: const Color(0xFF0D47A1),
                                  labelColor: const Color(0xFF0D47A1),
                                  unselectedLabelColor: Colors.grey[600],
                                  tabs: const [
                                    Tab(text: 'Create Scenario'),
                                    Tab(text: 'Scenarios (0)'),
                                    Tab(text: 'Results'),
                                  ],
                                ),
                                Container(
                                  height: 500,
                                  padding: const EdgeInsets.all(16),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildCreateScenarioForm(),
                                      const Center(child: Text('Scenarios will be shown here.')),
                                      const Center(child: Text('Results will be shown here.')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          PageRoutes.fadeThrough(const OverrideControlsScreen()),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      icon: Icons.analytics_outlined, 
                      title: showLabels ? 'What-if Analysis' : '',
                      isSelected: true,
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
  
  // --- Widget Builders ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 28, color: Color(0xFF0D47A1)),
                const SizedBox(width: 12),
                const Text(
                  'What-If Analysis',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Analyze operational scenarios before implementation',
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

  Widget _buildWhatIfSimulationToolSection() {
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
            const Row(
              children: [
                Icon(Icons.play_circle_fill, color: Color(0xFF0D47A1)),
                SizedBox(width: 8),
                Text(
                  'What-If Simulation Tool',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Analyze the impact of operational decisions before implementation',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'This tool helps simulate operational changes and predict their impact on train schedules, passenger experience, and network efficiency. Create different scenarios to compare outcomes before making critical decisions.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateScenarioForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormRow('Scenario Name', 'Enter scenario name...', isDropdown: false),
        const SizedBox(height: 16),
        _buildFormRow('Select Train', 'Choose a train...', isDropdown: true, items: [
          'Train A123', 'Train B456', 'Train C789'
        ]),
        const SizedBox(height: 16),
        _buildActionAndValueRow(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Show a snackbar confirmation when adding to scenario
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action added to scenario'),
                  backgroundColor: Color(0xFF0D47A1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Add to Scenario',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow(String labelText, String hintText, {required bool isDropdown, List<String>? items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (isDropdown)
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: items?.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList() ?? [],
            onChanged: (String? newValue) {},
          )
        else
          TextField(
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionAndValueRow() {
    final actionTypes = ['Delay Train', 'Speed Up Train', 'Change Route', 'Signal Failure'];
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Action Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Select action...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: actionTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {},
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Value (minutes)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
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