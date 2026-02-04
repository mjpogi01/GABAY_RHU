import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_users_screen.dart';
import 'admin_modules_screen.dart';
import 'admin_tests_screen.dart';
import '../../core/design_system.dart';

/// Admin shell: bottom nav with Home, Data, Users, LMs, Tests.
/// Shown only when user.role == 'admin'.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home', icon: Icons.dashboard_outlined),
    _NavItem(label: 'Data', icon: Icons.bar_chart_outlined),
    _NavItem(label: 'Users', icon: Icons.people_outline),
    _NavItem(label: 'LMs', icon: Icons.library_books_outlined),
    _NavItem(label: 'Tests', icon: Icons.assignment_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdminDashboardScreen(),
          AdminAnalyticsScreen(),
          AdminUsersScreen(),
          AdminModulesScreen(),
          AdminTestsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DesignSystem.cardSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: DesignSystem.adminGridGap(context) * 0.7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _currentIndex == i;
                return InkWell(
                  onTap: () => setState(() => _currentIndex = i),
                  borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context) * 0.67),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context) * 0.6, vertical: DesignSystem.adminGridGap(context) * 0.7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: DesignSystem.s(context, 24),
                          color: selected ? DesignSystem.primary : DesignSystem.textMuted,
                        ),
                        SizedBox(height: DesignSystem.s(context, 4)),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: DesignSystem.captionSize(context),
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? DesignSystem.primary : DesignSystem.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}
