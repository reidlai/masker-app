import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0D131A);
  static const Color surface = Color(0xFF131B24);
  static const Color cardBg = Color(0xFF1A2430);
  static const Color cardBorder = Color(0xFF253342);
  
  static const Color primaryTeal = Color(0xFF00B4D8);
  static const Color primaryTealDark = Color(0xFF0077B6);
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPink = Color(0xFFF43F5E);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryTeal,
      cardColor: AppColors.cardBg,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryTeal,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
