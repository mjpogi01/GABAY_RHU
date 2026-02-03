import 'package:flutter/material.dart';

/// GABAY – Flutter Responsive Design System
class DesignSystem {
  DesignSystem._();

  // ─── COLORS ───────────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF1F4FD8);
  static const Color primaryDark = Color(0xFF193EB0);
  static const Color secondary = Color(0xFF6FA8FF);
  static const Color background = Color(0xFFF6F8FC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFE9F1F7);
  static const Color inputBorder = Color(0xFFC7D6EA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF9AA3AF);
  static const Color accentYellow = Color(0xFFF4C430);

  // ─── RESPONSIVE SCALE ─────────────────────────────────────────────────────

  static const double baselineWidth = 375;
  /// Cap scale so elements don't grow too large on tablets/landscape.
  static const double maxScale = 1.3;
  /// Max width for main content on large screens; content is centered when narrower.
  static const double maxContentWidth = 440;

  static double scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final raw = width / baselineWidth;
    return raw.clamp(0.8, maxScale);
  }

  static double s(BuildContext context, double value) =>
      value * scale(context);

  // ─── FONT SIZES (multiply by scale) ───────────────────────────────────────

  static double appTitleSize(BuildContext context) => 24 * scale(context);
  static double sectionTitleSize(BuildContext context) => 20 * scale(context);
  static double buttonTextSize(BuildContext context) => 16 * scale(context);
  static double inputTextSize(BuildContext context) => 16 * scale(context);
  static double bodyTextSize(BuildContext context) => 14 * scale(context);
  static double helperLinkSize(BuildContext context) => 13 * scale(context);
  static double captionSize(BuildContext context) => 12 * scale(context);

  // ─── SPACING ──────────────────────────────────────────────────────────────

  static double spacingSmall(BuildContext context) => 8 * scale(context);
  static double spacingMedium(BuildContext context) => 16 * scale(context);
  static double spacingLarge(BuildContext context) => 24 * scale(context);
  static double spacingSection(BuildContext context) => 32 * scale(context);

  // ─── INPUT SPECS ──────────────────────────────────────────────────────────

  static const double inputHeight = 48;
  static const double inputBorderRadius = 10;
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(vertical: 14, horizontal: 14);

  // ─── BUTTON SPECS ─────────────────────────────────────────────────────────

  static const double buttonHeight = 52;
  static const double buttonBorderRadius = 12;
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(vertical: 14, horizontal: 24);
}
