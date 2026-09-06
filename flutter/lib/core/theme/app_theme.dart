import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);      // Slate 900 (Deep Night Background)
  static const Color surface = Color(0xFF1E293B);         // Slate 800 (Dark Glassmorphic Card Surface)
  static const Color cardBorder = Color(0xFF334155);      // Slate 700 (Subtle Card Border)
  static const Color accentGreen = Color(0xFF10B981);     // Emerald 500 (Healthy Respiration / Normal Apnea Index)
  static const Color warningAmber = Color(0xFFF59E0B);    // Amber 500 (Moderate Apnea Index / Active Calibration)
  static const Color dangerRed = Color(0xFFEF4444);       // Red 500 (Tier-1 Apnea Siren Alert / Emergency)
  static const Color purpleAnalytics = Color(0xFF6D28D9);  // Royal Purple 700 (Morning Analytics & Trends)
  static const Color textPrimary = Color(0xFFF8FAFC);     // Slate 50 (High Contrast Text)
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400 (Subtle Subtitles & Labels)
  static const Color nightMode = Color(0xFF000000);       // Pure Black (0-FPS Sleep Display Lock)
  static const Color pressedSurface = Color(0xFF273449);  // Slate 800 pressed (list-row / menu-row active background)

  // Legacy / Semantic Aliases
  static const Color primaryTeal = Color(0xFF14B8A6);     // Teal 500
  static const Color accentPink = Color(0xFFEC4899);      // Pink 500
  static const Color cardBg = surface;
  static const Color textMuted = textSecondary;
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseFont = GoogleFonts.interTextTheme();
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accentGreen,
      cardColor: AppColors.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: baseFont.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.surface,
        surface: AppColors.surface,
        error: AppColors.dangerRed,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }

  /// TextStyle helper for bio-signals and live countdowns requiring tabular figures
  static TextStyle tabularTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
