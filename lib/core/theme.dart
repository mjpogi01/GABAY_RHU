import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system.dart';

/// GABAY – Design system theme
/// Font: Inter, SF Pro Text, system-ui, sans-serif
class AppTheme {
  AppTheme._();

  static TextStyle _inter(double size, FontWeight weight, [Color? color]) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? DesignSystem.textPrimary,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: DesignSystem.primary,
        primaryContainer: DesignSystem.primaryDark,
        secondary: DesignSystem.secondary,
        surface: DesignSystem.cardSurface,
        surfaceContainerHighest: DesignSystem.background,
        onPrimary: Colors.white,
        onSurface: DesignSystem.textPrimary,
        onSurfaceVariant: DesignSystem.textSecondary,
      ),
      scaffoldBackgroundColor: DesignSystem.background,
      textTheme: TextTheme(
        displayLarge: _inter(24, FontWeight.w600),
        displayMedium: _inter(20, FontWeight.w600),
        headlineMedium: _inter(20, FontWeight.w600),
        titleLarge: _inter(20, FontWeight.w600),
        titleMedium: _inter(16, FontWeight.w500),
        bodyLarge: _inter(16, FontWeight.w400),
        bodyMedium: _inter(14, FontWeight.w400),
        bodySmall: _inter(14, FontWeight.w400),
        labelLarge: _inter(16, FontWeight.w600),
        labelMedium: _inter(13, FontWeight.w400),
        labelSmall: _inter(12, FontWeight.w400),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DesignSystem.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _inter(20, FontWeight.w600, Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
          padding: DesignSystem.buttonPadding,
          textStyle: _inter(16, FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignSystem.primary,
          minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: DesignSystem.cardSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignSystem.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
          borderSide: const BorderSide(color: DesignSystem.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
          borderSide: const BorderSide(color: DesignSystem.primary, width: 1.5),
        ),
        contentPadding: DesignSystem.inputPadding,
        hintStyle: _inter(16, FontWeight.w400, DesignSystem.textMuted),
      ),
    );
  }
}
