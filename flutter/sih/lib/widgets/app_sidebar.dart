import 'package:flutter/material.dart';
import '../utils/page_transitions_fixed.dart';
import '../screens/dashboard_screen.dart';
import '../screens/track_map_screen.dart';
import '../screens/ai_recommendations_screen.dart';
import '../screens/override_controls_screen.dart';
import '../screens/what_if_analysis_screen.dart';
import '../screens/performance_screen.dart';
import '../screens/login_screen.dart';

class AppSidebar extends StatelessWidget {
  final Animation<double> sidebarAnimation;
  final String currentPage;

  const AppSidebar({
    super.key,
    required this.sidebarAnimation,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = sidebarAnimation.value * 250;
    if (sidebarWidth < 1) return const SizedBox(width: 0);
    final bool showLabels = sidebarWidth > 80;

    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(
        children: [
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
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildNavigationItem(
                      context: context,
                      icon: Icons.dashboard,
                      title: showLabels ? 'Dashboard' : '',
                      isSelected: currentPage == 'dashboard',
                      onTap: () {
                        Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const DashboardScreen()));
                      },
                    ),
                    _buildNavigationItem(
                      context: context,
                      icon: Icons.map,
                      title: showLabels ? 'Track Map' : '',
                      isSelected: currentPage == 'track_map',
                      onTap: () {
                        Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const TrackMapScreen()));
                      },
                    ),
                    _buildNavigationItem(
                      context: context,
                      icon: Icons.lightbulb_outline,
                      title: showLabels ? 'AI Recommendations' : '',
                      isSelected: currentPage == 'ai_recommendations',
                      onTap: () {
                        Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const AiRecommendationsScreen()));
                      },
                    ),
                    _buildNavigationItem(
                      context: context,
                      icon: Icons.rule,
                      title: showLabels ? 'Override Controls' : '',
                      isSelected: currentPage == 'override_controls',
                      onTap: () {
                        Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const OverrideControlsScreen()));
                      },
                    ),
                    _buildNavigationItem(
                      context: context,
                      icon: Icons.analytics_outlined,
                      title: showLabels ? 'What-if Analysis' : '',
                      isSelected: currentPage == 'what_if_analysis',
                      onTap: () {
                        Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const WhatIfAnalysisScreen()));
                      },
                    ),
                    _buildNavigationItem(
                      context: context,
                      icon: Icons.bar_chart,
                      title: showLabels ? 'Performance' : '',
                      isSelected: currentPage == 'performance',
                      onTap: () {
                        Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const PerformanceScreen()));
                      },
                    ),
                  ],
+                ),
+              ),
+            ),
+          ),
+          Padding(
+            padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 16.0),
+            child: Column(
+              children: [
+                if (showLabels) const Divider(height: 1),
+                _buildNavigationItem(
+                  context: context,
+                  icon: Icons.logout,
+                  title: showLabels ? 'Logout' : '',
+                  onTap: () {
+                    Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const LoginScreen()));
+                  },
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _buildNavigationItem({
+    required BuildContext context,
+    required IconData icon,
+    required String title,
+    bool isSelected = false,
+    VoidCallback? onTap,
+  }) {
+    final bool isCollapsed = title.isEmpty;
+
+    if (isCollapsed) {
+      return _HoverButton(
+        isSelected: isSelected,
+        icon: icon,
+        onTap: onTap,
+        tooltipText: icon == Icons.dashboard ? 'Dashboard' :
+                     icon == Icons.map ? 'Track Map' :
+                     icon == Icons.lightbulb_outline ? 'AI Recommendations' :
+                     icon == Icons.rule ? 'Override Controls' :
+                     icon == Icons.analytics_outlined ? 'What-if Analysis' :
+                     icon == Icons.bar_chart ? 'Performance' :
+                     icon == Icons.logout ? 'Logout' : '',
+      );
+    } else {
+      return _HoverListTile(
+        isSelected: isSelected,
+        icon: icon,
+        title: title,
+        onTap: onTap,
+      );
+    }
+  }
+}
+
+class _HoverButton extends StatefulWidget {
+  final bool isSelected;
+  final IconData icon;
+  final VoidCallback? onTap;
+  final String tooltipText;
+
+  const _HoverButton({
+    required this.isSelected,
+    required this.icon,
+    this.onTap,
+    required this.tooltipText,
+  });
+
+  @override
+  _HoverButtonState createState() => _HoverButtonState();
+}
+
+class _HoverButtonState extends State<_HoverButton> {
+  bool isHovering = false;
+
+  @override
+  Widget build(BuildContext context) {
+    return MouseRegion(
+      onEnter: (_) => setState(() => isHovering = true),
+      onExit: (_) => setState(() => isHovering = false),
+      child: Container(
+        margin: const EdgeInsets.symmetric(vertical: 4),
+        decoration: BoxDecoration(
+          color: widget.isSelected
+              ? const Color(0xFFE3F2FD)
+              : isHovering
+                  ? const Color(0xFFF5F5F5)
+                  : Colors.transparent,
+          borderRadius: BorderRadius.circular(8),
+        ),
+        child: IconButton(
+          icon: Icon(
+            widget.icon,
+            size: 22,
+            color: widget.isSelected
+                ? const Color(0xFF0D47A1)
+                : isHovering
+                    ? const Color(0xFF42A5F5)
+                    : Colors.grey[600],
+          ),
+          onPressed: widget.onTap,
+          tooltip: widget.tooltipText,
+        ),
+      ),
+    );
+  }
+}
+
+class _HoverListTile extends StatefulWidget {
+  final bool isSelected;
+  final IconData icon;
+  final String title;
+  final VoidCallback? onTap;
+
+  const _HoverListTile({
+    required this.isSelected,
+    required this.icon,
+    required this.title,
+    this.onTap,
+  });
+
+  @override
+  _HoverListTileState createState() => _HoverListTileState();
+}
+
+class _HoverListTileState extends State<_HoverListTile> {
+  bool isHovering = false;
+
+  @override
+  Widget build(BuildContext context) {
+    return MouseRegion(
+      onEnter: (_) => setState(() => isHovering = true),
+      onExit: (_) => setState(() => isHovering = false),
+      child: Container(
+        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
+        decoration: BoxDecoration(
+          color: widget.isSelected
+              ? const Color(0xFFE3F2FD)
+              : isHovering
+                  ? const Color(0xFFF5F5F5)
+                  : Colors.transparent,
+          borderRadius: BorderRadius.circular(8),
+        ),
+        child: ListTile(
+          dense: true,
+          leading: Icon(
+            widget.icon,
+            color: widget.isSelected
+                ? const Color(0xFF0D47A1)
+                : isHovering
+                    ? const Color(0xFF42A5F5)
+                    : Colors.grey[700],
+          ),
+          title: Text(
+            widget.title,
+            style: TextStyle(
+              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
+              color: widget.isSelected
+                  ? const Color(0xFF0D47A1)
+                  : isHovering
+                      ? const Color(0xFF42A5F5)
+                      : Colors.black87,
+            ),
+          ),
+          onTap: widget.onTap,
+        ),
+      ),
+    );
+  }
+}


