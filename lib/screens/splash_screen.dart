import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_routes.dart';
import '../core/constants.dart';
import '../core/design_system.dart';
import '../providers/app_provider.dart';

const String _keyLastRoute = 'last_route';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleNavigate();
  }

  Future<void> _scheduleNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRoute = prefs.getString(_keyLastRoute);
    final isRestore = lastRoute == AppRoutes.dashboard ||
        lastRoute == AppRoutes.adminDashboard;
    if (!mounted) return;
    final delay = isRestore
        ? const Duration(milliseconds: 400)
        : const Duration(seconds: 2);
    Future.delayed(delay, _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (provider.loading) {
      Future.delayed(const Duration(milliseconds: 500), _navigate);
      return;
    }
    String route;
    if (provider.user == null) {
      route = AppRoutes.landing;
    } else if (provider.user!.isAdmin) {
      route = AppRoutes.adminDashboard;
    } else {
      route = AppRoutes.dashboard;
    }

    final prefs = await SharedPreferences.getInstance();
    if (route == AppRoutes.landing) {
      await prefs.remove(_keyLastRoute);
    } else {
      await prefs.setString(_keyLastRoute, route);
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesignSystem.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignSystem.s(context, 24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // These Hero widgets will smoothly transition to auth screen
                      _buildLogo(context),
                      SizedBox(height: DesignSystem.s(context, 16)),
                      _buildAppName(context),
                      SizedBox(height: DesignSystem.s(context, 8)),
                      _buildTagline(context),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
            const Center(
              child: CircularProgressIndicator(color: DesignSystem.primary),
            ),
            SizedBox(height: DesignSystem.s(context, 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final scale = DesignSystem.scale(context);
    return Hero(
      tag: 'app_logo',
      transitionOnUserGestures: true,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 80 * scale,
          width: 80 * scale, // Fixed width for smoother transition
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'G',
                style: TextStyle(
                  fontSize: 64 * scale,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.primary,
                ),
              ),
              Positioned(
                top: 0,
                right: 4,
                child: Icon(
                  Icons.light_mode,
                  color: DesignSystem.accentYellow,
                  size: 32 * scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppName(BuildContext context) {
    return Hero(
      tag: 'app_name',
      transitionOnUserGestures: true,
      child: Material(
        color: Colors.transparent,
        child: Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: DesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: DesignSystem.appTitleSize(context) * 1.5,
              ),
        ),
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Hero(
      tag: 'app_tagline',
      transitionOnUserGestures: true,
      child: Material(
        color: Colors.transparent,
        child: Text(
          AppConstants.appTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DesignSystem.textSecondary,
                fontSize: DesignSystem.bodyTextSize(context),
              ),
        ),
      ),
    );
  }
}
