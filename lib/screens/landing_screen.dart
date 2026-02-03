import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/constants.dart';
import '../core/design_system.dart';

/// Landing screen - white card, Login / Register buttons
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = DesignSystem.scale(context);
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: DesignSystem.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignSystem.s(context, 32)),
                  child: Card(
                elevation: 2,
                color: DesignSystem.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(DesignSystem.spacingSection(context)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(context),
                      SizedBox(height: DesignSystem.spacingMedium(context)),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w600,
                          color: DesignSystem.textPrimary,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingSmall(context)),
                      Text(
                        AppConstants.appTaglineLanding,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: DesignSystem.bodyTextSize(context),
                          color: DesignSystem.textSecondary,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingSection(context)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _navigateToAuth(context, isSignUp: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
                            padding: DesignSystem.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingMedium(context)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _navigateToAuth(context, isSignUp: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.secondary,
                            foregroundColor: DesignSystem.textPrimary,
                            minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
                            padding: DesignSystem.buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                            ),
                          ),
                          child: const Text('Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final scale = DesignSystem.scale(context);
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 48 * scale,
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
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAuth(BuildContext context, {required bool isSignUp}) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: {'isSignUp': isSignUp},
    );
  }
}
