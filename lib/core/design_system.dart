import 'package:flutter/material.dart';

/// GABAY – Flutter design system
/// One primary color (Blue). No gradients. No pure black. Same padding/button height everywhere.
class DesignSystem {
  DesignSystem._();

  // ─── COLOR PALETTE (BLUE PRIMARY) ─────────────────────────────────────────

  static const Color primary = Color(0xFF3B82F6);           // PrimaryBlue
  static const Color primaryDark = Color(0xFF2563EB);       // PrimaryBlueDark (pressed)
  static const Color primarySoft = Color(0xFFEAF2FF);        // PrimaryBlueSoft (secondary button bg)
  static const Color primaryDisabled = Color(0xFFBFDBFE);   // Disabled primary

  static const Color textTitle = Color(0xFF1F2937);         // TextTitle
  static const Color textBody = Color(0xFF4B5563);          // TextBody
  static const Color textMuted = Color(0xFF9CA3AF);         // TextMuted / caption

  static const Color bgMain = Color(0xFFFFFFFF);            // BgMain
  static const Color bgSection = Color(0xFFF9FAFB);         // BgSection
  static const Color border = Color(0xFFE5E7EB);           // Border

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Aliases for backward compatibility
  static const Color primaryDarkLegacy = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color accentYellow = Color(0xFFF4C430);

  // ─── LAYOUT & SPACING ────────────────────────────────────────────────────

  static const double screenPaddingH = 16;
  static const double maxContentWidth = 640;

  static const double spacingMicro = 4;
  static const double spacingParagraph = 12;
  static const double spacingSeparation = 24;

  // Scaled (responsive) – use when needed for different screen sizes
  static const double baselineWidth = 375;
  static const double maxScale = 1.3;

  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final raw = width / baselineWidth;
    return raw.clamp(0.8, maxScale);
  }

  static double s(BuildContext context, double value) => value * scale(context);
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double wRatio(BuildContext context, double ratio) => width(context) * ratio;

  // ─── TYPOGRAPHY (Inter) ───────────────────────────────────────────────────

  /// App Bar Title: 18, SemiBold, line 24, TextTitle
  static const double appBarTitleSize = 18;
  static const double appBarTitleHeight = 24;
  static const FontWeight appBarTitleWeight = FontWeight.w600;

  /// Module Title: 20, SemiBold, line 28, TextTitle
  static const double moduleTitleSize = 20;
  static const double moduleTitleHeight = 28;
  static const FontWeight moduleTitleWeight = FontWeight.w600;

  /// Body: 14–15, Regular, line 22–24, TextBody
  static const double bodyTextSizeValue = 14;
  static const double bodyTextSizeLarge = 15;
  static const double bodyLineHeight = 22;
  static const FontWeight bodyWeight = FontWeight.w400;

  /// Muted / Caption: 12, Regular, line 16, TextMuted
  static const double captionSizeValue = 12;
  static const double captionLineHeight = 16;
  static const FontWeight captionWeight = FontWeight.w400;

  /// Button: 14–16, Medium
  static const double buttonTextSizeValue = 14;
  static const double buttonTextSizeLarge = 16;
  static const FontWeight buttonTextWeight = FontWeight.w500;

  // Context-aware (scaled) typography – used by screens that pass (context)
  static double appTitleSize(BuildContext context) => appBarTitleSize * scale(context);
  static double sectionTitleSize(BuildContext context) => moduleTitleSize * scale(context);
  static double bodyTextSize(BuildContext context) => bodyTextSizeValue * scale(context);
  static double helperLinkSize(BuildContext context) => 13 * scale(context);
  static double captionSize(BuildContext context) => captionSizeValue * scale(context);
  static double inputTextSize(BuildContext context) => 16 * scale(context);
  static double buttonTextSize(BuildContext context) => buttonTextSizeValue * scale(context);

  // Legacy aliases
  static double bodyTextSizeScaled(BuildContext context) => bodyTextSize(context);
  static double captionSizeScaled(BuildContext context) => captionSize(context);

  // ─── SPACING (scaled when used in layout) ──────────────────────────────────

  static const double spacingSmallValue = 8;
  static const double spacingSectionValue = 16;

  static double spacingSmall(BuildContext context) => spacingSmallValue * scale(context);
  static double spacingMedium(BuildContext context) => spacingSectionValue * scale(context);
  static double spacingLarge(BuildContext context) => spacingSeparation * scale(context);
  static double spacingSection(BuildContext context) => spacingSectionValue * scale(context);
  static double spacingSmallScaled(BuildContext context) => spacingSmall(context);
  static double spacingSectionScaled(BuildContext context) => 32 * scale(context);

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  static const double appBarHeight = 56;
  static const Color appBarBackground = bgMain;
  static const Color appBarTitleColor = textTitle;
  static const Color appBarIconColor = textBody;
  static const Color appBarDivider = border;

  // ─── BUTTONS ──────────────────────────────────────────────────────────────

  static const double buttonHeight = 46;           // 44–48
  static const double buttonBorderRadius = 10;     // 10–12
  static const double buttonGap = 12;
  static const EdgeInsets buttonContainerPadding = EdgeInsets.symmetric(horizontal: 16);

  static double buttonHeightScaled(BuildContext context) => buttonHeight * scale(context);
  static double buttonBorderRadiusScaled(BuildContext context) => buttonBorderRadius * scale(context);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 20);
  static EdgeInsets buttonPaddingScaled(BuildContext context) =>
      EdgeInsets.symmetric(vertical: 12 * scale(context), horizontal: 20 * scale(context));

  // ─── BOTTOM NAVIGATION ───────────────────────────────────────────────────

  static const double bottomNavHeight = 56;
  static const double bottomNavIconSize = 24;
  static const double bottomNavLabelSize = 10;
  static const Color bottomNavBackground = bgMain;
  static const Color bottomNavDivider = border;
  static const Color bottomNavActive = primary;
  static const Color bottomNavInactive = textMuted;

  // ─── INPUT & CARD (legacy / admin) ────────────────────────────────────────

  static const double inputHeight = 48;
  static double inputHeightScaled(BuildContext context) => 48 * scale(context);
  static double inputBorderRadiusScaled(BuildContext context) => 10 * scale(context);
  static const double inputBorderRadius = 10;
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 14);
  static EdgeInsets inputPaddingScaled(BuildContext context) =>
      EdgeInsets.symmetric(vertical: 14 * scale(context), horizontal: 14 * scale(context));

  // Admin layout (unchanged for admin screens)
  static const double _base = 375.0;
  static double adminContentPadding(BuildContext context) => wRatio(context, 20 / _base);
  static double adminGridGap(BuildContext context) => wRatio(context, 12 / _base);
  static double adminSectionGap(BuildContext context) => wRatio(context, 20 / _base);
  static double adminCardRadius(BuildContext context) => s(context, 12);
  static const double adminKpiAspectRatio = 1.4;
  static const double adminActionAspectRatio = 1.2;
  static double adminPieChartSize(BuildContext context) => wRatio(context, 128 / _base);
  static double adminChartHeight(BuildContext context) => wRatio(context, 180 / _base);
  static double adminAvatarLarge(BuildContext context) => wRatio(context, 80 / _base);
  static double adminListTileHeight(BuildContext context) => wRatio(context, 88 / _base);
}
