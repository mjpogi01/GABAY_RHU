import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/pre_test_screen.dart';
import '../screens/module_screen.dart';
import '../screens/post_test_screen.dart';
import '../screens/certificate_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/main_shell.dart';
import '../screens/baby_guide_screen.dart';
import '../screens/help_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String preTest = '/pre-test';
  static const String module = '/module';
  static const String postTest = '/post-test';
  static const String certificate = '/certificate';
  static const String feedback = '/feedback';
  static const String babyGuide = '/baby-guide';
  static const String help = '/help';
  static const String settings = '/settings';

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
      case login:
      case register:
        final args = settings.arguments as Map<String, dynamic>?;
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AuthScreen(initialIsSignUp: args?['isSignUp'] as bool? ?? false),
          transitionDuration: const Duration(milliseconds: 1500),
          reverseTransitionDuration: const Duration(milliseconds: 1500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use FadeTransition for the page itself, Hero widgets handle their own transitions
            // The Hero animation duration matches this route's transition duration
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );
      case dashboard:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case preTest:
        return MaterialPageRoute(builder: (_) => const PreTestScreen());
      case module:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ModuleScreen(
            moduleId: args?['moduleId'] as String? ?? '',
          ),
        );
      case postTest:
        return MaterialPageRoute(builder: (_) => const PostTestScreen());
      case certificate:
        return MaterialPageRoute(builder: (_) => const CertificateScreen());
      case feedback:
        return MaterialPageRoute(builder: (_) => const FeedbackScreen());
      case babyGuide:
        return MaterialPageRoute(builder: (_) => const BabyGuideScreen());
      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
    }
  }
}
