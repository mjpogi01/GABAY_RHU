import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_routes.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
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
  bool _welcomePreTestShown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedDrawerItem == 'HOME' ? null : _buildAppBar(),
      endDrawer: _buildDrawer(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    final titles = {
      'HELP': 'Help',
      'SETTINGS': 'Settings',
    };

    return AppBar(
      toolbarHeight: 48,
      title: Text(
        titles[_selectedDrawerItem] ?? 'GABAY',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      automaticallyImplyLeading: false,
      leading: Container(
        padding: const EdgeInsets.all(10),
        child: CircleAvatar(
          radius: 6,
          backgroundColor: _isSupabaseConnected() ? Colors.green : Colors.red,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.amber.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade700, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;

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
                  if (user?.status != null) ...[
                    const SizedBox(height: 4),
                    Text('Status: ${user!.status}'),
                  ],
                  if (user?.address != null) ...[
                    const SizedBox(height: 4),
                    Text('Address: ${user!.address}'),
                  ],
                ],
              ),
            ),
            const Divider(),
            // Menu items
            _drawerItem('HOME', Icons.home, () => _navigateDrawer('HOME')),
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
    if (_selectedDrawerItem == 'HELP') return const HelpScreen();
    if (_selectedDrawerItem == 'SETTINGS') return const SettingsScreen();
    return _WelcomePreTestWrapper(
      alreadyShown: _welcomePreTestShown,
      onShown: () => setState(() => _welcomePreTestShown = true),
      child: DashboardScreen(onAvatarTap: _openDrawer),
    );
  }
}

/// Shows a one-time welcome dialog when the user hasn't completed the pre-test.
class _WelcomePreTestWrapper extends StatefulWidget {
  final Widget child;
  final bool alreadyShown;
  final VoidCallback onShown;

  const _WelcomePreTestWrapper({
    required this.child,
    required this.alreadyShown,
    required this.onShown,
  });

  @override
  State<_WelcomePreTestWrapper> createState() => _WelcomePreTestWrapperState();
}

class _WelcomePreTestWrapperState extends State<_WelcomePreTestWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcomeDialog());
  }

  void _maybeShowWelcomeDialog() {
    if (!mounted || widget.alreadyShown) return;
    final provider = context.read<AppProvider>();
    if (provider.hasCompletedPreTest) return;
    widget.onShown();
    _showWelcomeDialog();
  }

  void _showWelcomeDialog() {
    final userName = context.read<AppProvider>().user?.displayName ?? 'there';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.s(ctx, 16))),
        title: Row(
          children: [
            const Icon(Icons.waving_hand, color: DesignSystem.primary, size: 28),
            SizedBox(width: DesignSystem.s(ctx, 8)),
            Expanded(
              child: Text(
                'Welcome, $userName!',
                style: TextStyle(
                  fontSize: DesignSystem.sectionTitleSize(ctx),
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'To give you the best experience, we’d love to know where you’re at. '
          'Answer a short pre-test so we can tailor your learning content just for you.',
          style: TextStyle(
            fontSize: DesignSystem.bodyTextSize(ctx),
            height: 1.4,
            color: DesignSystem.textSecondary,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.preTest);
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignSystem.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Take the test'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
