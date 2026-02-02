import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GABAY - Calm, parent-friendly theme
/// Large readable text, minimal navigation, accessible design
class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFFD32F2F); // Red (from design)
  static const Color _primaryLight = Color(0xFFE57373);
  static const Color _accent = Color(0xFFEF5350);
  static const Color _surface = Color(0xFFF5F5F5);
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF212121);
  static const Color _onSurfaceVariant = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _primary,
        primaryContainer: _primaryLight,
        secondary: _accent,
        surface: _surface,
        onPrimary: _onPrimary,
        onSurface: _onSurface,
        onSurfaceVariant: _onSurfaceVariant,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: _onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _background,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.nunito(color: _onSurfaceVariant, fontSize: 16),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.nunito(fontSize: 18),
      bodyMedium: GoogleFonts.nunito(fontSize: 16),
      bodySmall: GoogleFonts.nunito(fontSize: 14),
      labelLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
