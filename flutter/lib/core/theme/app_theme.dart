import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);      // Slate 900
  static const Color surface = Color(0xFF1E293B);         // Slate 800
  static const Color cardBorder = Color(0xFF334155);      // Slate 700
  static const Color accentGreen = Color(0xFF10B981);     // Emerald 500
  static const Color warningAmber = Color(0xFFF59E0B);    // Amber 500
  static const Color dangerRed = Color(0xFFEF4444);       // Red 500 / Siren Alert
  static const Color purpleAnalytics = Color(0xFF6D28D9);  // Royal Purple 700
  static const Color nightMode = Color(0xFF000000);       // 0-FPS Black
  static const Color textPrimary = Color(0xFFF8FAFC);     // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accentGreen,
      cardColor: AppColors.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.surface,
        surface: AppColors.surface,
        error: AppColors.dangerRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
