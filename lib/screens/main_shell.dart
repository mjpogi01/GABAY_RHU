import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_routes.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'baby_guide_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

/// Main shell with Drawer and Bottom Nav
/// Design: Profile in drawer, menu items, bottom nav bar
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedDrawerItem = 'HOME';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      endDrawer: _buildDrawer(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedDrawerItem == 'HOME' || _selectedDrawerItem == 'MODULES' ||
        _selectedDrawerItem == 'ASSESSMENTS' || _selectedDrawerItem == 'PROGRESS') {
      return null; // Dashboard has no app bar (content starts at top)
    }
    final titles = {
      'BABY_GUIDE': 'Baby Guide',
      'HELP': 'Help',
      'SETTINGS': 'Settings',
    };
    return AppBar(
      title: Text(titles[_selectedDrawerItem] ?? 'GABAY'),
      automaticallyImplyLeading: false,
      actions: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.amber.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final child = provider.child;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.amber.shade200,
                    child: Icon(Icons.person, size: 48, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 4),
                    Text('Children: ${provider.completedModuleIds.isNotEmpty ? 1 : 0}'),
                  ],
                  if (user?.status != null) ...[
                    const SizedBox(height: 4),
                    Text('Status: ${user!.status}'),
                  ],
                  if (user?.address != null) ...[
                    const SizedBox(height: 4),
                    Text('Address: ${user!.address}'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSupabaseConnected() ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: _isSupabaseConnected() ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSupabaseConnected() ? '🟢 Connected' : '🔴 Not Connected',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSupabaseConnected() ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Menu items
            _drawerItem('HOME', Icons.home, () => _navigateDrawer('HOME')),
            _drawerItem('BABY GUIDE', Icons.child_care, () => _navigateDrawer('BABY_GUIDE')),
            _drawerItem('MODULES', Icons.menu_book, () => _navigateDrawer('MODULES')),
            _drawerItem('ASSESSMENTS', Icons.quiz, () => _navigateDrawer('ASSESSMENTS')),
            _drawerItem('PROGRESS', Icons.trending_up, () => _navigateDrawer('PROGRESS')),
            _drawerItem('HELP', Icons.help_outline, () => _navigateDrawer('HELP')),
            _drawerItem('SETTINGS', Icons.settings, () => _navigateDrawer('SETTINGS')),
            const Spacer(),
            const Divider(),
            _drawerItem('LOGOUT', Icons.logout, () => _logout(context)),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(String label, IconData icon, VoidCallback onTap) {
    final isSelected = _selectedDrawerItem == label;
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : null,
        ),
      ),
      tileColor: isSelected ? const Color(0xFFD32F2F) : null,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateDrawer(String item) {
    setState(() => _selectedDrawerItem = item);
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AppProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  bool _isSupabaseConnected() {
    try {
      // Check if Supabase is initialized and has a valid session
      final supabase = Supabase.instance.client;
      return supabase.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  Widget _buildBody() {
    if (_selectedDrawerItem == 'BABY_GUIDE') return const BabyGuideScreen();
    if (_selectedDrawerItem == 'HELP') return const HelpScreen();
    if (_selectedDrawerItem == 'SETTINGS') return const SettingsScreen();
    return DashboardScreen(onAvatarTap: _openDrawer);
  }
}
