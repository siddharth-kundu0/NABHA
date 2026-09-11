import 'package:flutter/material.dart';

class RuralCareColors {
  // Brand operational backbone
  static const Color primary = Color(0xFF0A6B56); // Forest Teal
  static const Color primaryDark = Color(0xFF085443);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryContainer = Color(0xFF97E8CE);

  // Administrative structural accents
  static const Color secondary = Color(0xFF3B6B82); // Slate Navy
  static const Color secondaryContainer = Color(0xFFB3E4FE);

  // Human-touch / Community / Maternal accent
  static const Color tertiary = Color(0xFFC05621); // Warm Terracotta
  static const Color tertiaryContainer = Color(0xFFFFCEBA);

  // Anti-glare tinted canvas for bright outdoor sunlight
  static const Color surfaceCanvas = Color(0xFFF4F6F6);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderInput = Color(0xFFD1D5DB);

  // Clinical Triage and Operational Statuses
  static const Color success = Color(0xFF145A32);
  static const Color successBg = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFF8C3C00);
  static const Color warningBg = Color(0xFFFEF3C7);

  static const Color critical = Color(0xFF991B1B); // Emergency / High-Risk
  static const Color criticalBg = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF1E40AF);
  static const Color infoBg = Color(0xFFDBEAFE);

  // Typography Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
}

/// Backward compatible and ergonomic alias for Stitch tokens
class AppColors {
  static const Color forestTeal = Color(0xFF0A6B56);
  static const Color forestTealDark = Color(0xFF085443);
  static const Color forestTealLight = Color(0xFF97E8CE);

  static const Color slateNavy = Color(0xFF3B6B82);
  static const Color terracotta = Color(0xFFC05621);
  static const Color surfaceAntiGlare = Color(0xFFF4F6F6);
  static const Color criticalRed = Color(0xFF991B1B);

  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
}

class RuralCareTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: RuralCareColors.surfaceCanvas,
      colorScheme: const ColorScheme.light(
        primary: RuralCareColors.primary,
        onPrimary: Colors.white,
        secondary: RuralCareColors.secondary,
        onSecondary: Colors.white,
        tertiary: RuralCareColors.tertiary,
        surface: RuralCareColors.surfaceWhite,
        onSurface: RuralCareColors.textPrimary,
        error: RuralCareColors.critical,
        onError: Colors.white,
      ),
      fontFamily: 'Noto Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: RuralCareColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: RuralCareColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: RuralCareColors.borderSubtle, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RuralCareColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48), // Stitch 48px hit standard
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RuralCareColors.secondary,
          side: const BorderSide(color: RuralCareColors.secondary, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: RuralCareColors.borderInput, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: RuralCareColors.borderInput, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: RuralCareColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: RuralCareColors.critical, width: 1.5),
        ),
      ),
    );
  }
}

class AppTheme {
  static ThemeData get themeData => RuralCareTheme.lightTheme;
}
