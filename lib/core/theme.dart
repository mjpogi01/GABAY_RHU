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
        secondary: DesignSystem.primary,
        surface: DesignSystem.bgMain,
        surfaceContainerHighest: DesignSystem.bgSection,
        onPrimary: Colors.white,
        onSurface: DesignSystem.textTitle,
        onSurfaceVariant: DesignSystem.textBody,
      ),
      scaffoldBackgroundColor: DesignSystem.bgSection,
      textTheme: TextTheme(
        displayLarge: _inter(24, FontWeight.w600, DesignSystem.textTitle),
        displayMedium: _inter(DesignSystem.moduleTitleSize, FontWeight.w600, DesignSystem.textTitle),
        headlineMedium: _inter(DesignSystem.moduleTitleSize, FontWeight.w600, DesignSystem.textTitle),
        titleLarge: _inter(DesignSystem.moduleTitleSize, FontWeight.w600, DesignSystem.textTitle),
        titleMedium: _inter(16, FontWeight.w500, DesignSystem.textTitle),
        bodyLarge: _inter(16, FontWeight.w400, DesignSystem.textBody),
        bodyMedium: _inter(DesignSystem.bodyTextSizeValue, FontWeight.w400, DesignSystem.textBody),
        bodySmall: _inter(DesignSystem.bodyTextSizeValue, FontWeight.w400, DesignSystem.textBody),
        labelLarge: _inter(16, FontWeight.w600, DesignSystem.textTitle),
        labelMedium: _inter(13, FontWeight.w400, DesignSystem.textBody),
        labelSmall: _inter(DesignSystem.captionSizeValue, FontWeight.w400, DesignSystem.textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignSystem.appBarBackground,
        foregroundColor: DesignSystem.appBarIconColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: DesignSystem.appBarTitleSize,
          fontWeight: DesignSystem.appBarTitleWeight,
          color: DesignSystem.appBarTitleColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(DesignSystem.buttonHeight),
          padding: DesignSystem.buttonPadding,
          textStyle: _inter(DesignSystem.buttonTextSizeLarge, DesignSystem.buttonTextWeight),
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
        color: DesignSystem.bgMain,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignSystem.bgSection,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
          borderSide: const BorderSide(color: DesignSystem.border),
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
