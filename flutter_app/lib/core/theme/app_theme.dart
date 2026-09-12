import 'package:flutter/material.dart';

/// Design tokens strictly conforming to DESIGN.md specification
class RuralCareColors {
  // Screen background & surfaces
  static const Color canvas = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFEEF3F8);

  // Typography
  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF52637A);

  // Borders
  static const Color border = Color(0xFFDCE4ED);
  static const Color inputBorder = Color(0xFF7B8BA0);

  // Primary Brand & Interactive
  static const Color primary = Color(0xFF2457C5);
  static const Color primaryPressed = Color(0xFF1B4399);
  static const Color primarySoft = Color(0xFFEDF3FF);

  // Supportive details
  static const Color teal = Color(0xFF147D78);
  static const Color tealSoft = Color(0xFFEAF7F4);

  // Clinical & System Statuses
  static const Color success = Color(0xFF216E4A);
  static const Color successSoft = Color(0xFFECF7EF);

  static const Color warning = Color(0xFF8A5300);
  static const Color warningSoft = Color(0xFFFFF5DF);

  static const Color critical = Color(0xFFB42318);
  static const Color criticalSoft = Color(0xFFFFF0ED);

  static const Color focus = Color(0xFF2457C5);

  // Backward compatibility aliases
  static const Color surfaceCanvas = canvas;
  static const Color surfaceWhite = surface;
  static const Color borderSubtle = border;
  static const Color borderInput = inputBorder;
  static const Color primaryDark = primaryPressed;
  static const Color primaryLight = primarySoft;
  static const Color primaryContainer = primarySoft;
  static const Color secondary = teal;
  static const Color secondaryContainer = tealSoft;
  static const Color tertiary = teal;
  static const Color tertiaryContainer = tealSoft;
  static const Color successBg = successSoft;
  static const Color warningBg = warningSoft;
  static const Color criticalBg = criticalSoft;
  static const Color info = primary;
  static const Color infoBg = primarySoft;
  static const Color textMuted = textSecondary;
}

/// Backward compatible and ergonomic alias for DESIGN.md tokens
class AppColors {
  // Canonical DESIGN.md tokens
  static const Color canvas = RuralCareColors.canvas;
  static const Color surface = RuralCareColors.surface;
  static const Color surfaceSubtle = RuralCareColors.surfaceSubtle;
  static const Color textPrimary = RuralCareColors.textPrimary;
  static const Color textSecondary = RuralCareColors.textSecondary;
  static const Color border = RuralCareColors.border;
  static const Color inputBorder = RuralCareColors.inputBorder;
  static const Color primary = RuralCareColors.primary;
  static const Color primaryPressed = RuralCareColors.primaryPressed;
  static const Color primarySoft = RuralCareColors.primarySoft;
  static const Color teal = RuralCareColors.teal;
  static const Color tealSoft = RuralCareColors.tealSoft;
  static const Color success = RuralCareColors.success;
  static const Color successSoft = RuralCareColors.successSoft;
  static const Color warning = RuralCareColors.warning;
  static const Color warningSoft = RuralCareColors.warningSoft;
  static const Color critical = RuralCareColors.critical;
  static const Color criticalSoft = RuralCareColors.criticalSoft;
  static const Color focus = RuralCareColors.focus;

  // Stitch & Legacy token redirects (all aligned with calm DESIGN.md specification)
  static const Color stitchPrimary = primary;
  static const Color stitchPrimaryContainer = primarySoft;
  static const Color stitchOnPrimaryContainer = primary;
  static const Color stitchSurface = canvas;
  static const Color stitchSurfaceContainerLowest = surface;
  static const Color stitchSurfaceContainerLow = surfaceSubtle;
  static const Color stitchSurfaceContainer = surfaceSubtle;
  static const Color stitchSurfaceContainerHigh = border;
  static const Color stitchOnSurface = textPrimary;
  static const Color stitchWarning = warning;
  static const Color stitchWarningBg = warningSoft;
  static const Color stitchCritical = critical;
  static const Color stitchCriticalBg = criticalSoft;

  static const Color forestTeal = teal;
  static const Color forestTealDark = teal;
  static const Color forestTealLight = tealSoft;
  static const Color slateNavy = textSecondary;
  static const Color terracotta = critical;
  static const Color surfaceAntiGlare = canvas;
  static const Color criticalRed = critical;

  static const Color neutral100 = Color(0xFFF7F9FC);
  static const Color neutral200 = Color(0xFFEEF3F8);
  static const Color neutral300 = Color(0xFFDCE4ED);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral600 = Color(0xFF52637A);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF172B4D);

  // Stitch Design System Tokens
  static const Color darkSlate = Color(0xFF1E293B);
  static const Color slateGray = Color(0xFF64748B);
  static const Color navyBlue = Color(0xFF104A7B);
  static const Color skyBlue = Color(0xFF0284C7);
  static const Color skyBlueSoft = Color(0xFFE0F2FE);
  static const Color earthOchre = Color(0xFFD97706);
  static const Color earthOchreDark = Color(0xFF92400E);
  static const Color cardBackground = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF8FAFC);

  // Calm solid tint for priority areas per DESIGN.md (no loud gradients)
  static const LinearGradient priorityGradient = LinearGradient(
    colors: [Color(0xFF1B4399), Color(0xFF2457C5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Standardized typography scale from DESIGN.md Section 3
class AppTypography {
  static const String fontFamily = 'Noto Sans';

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    color: RuralCareColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: RuralCareColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    color: RuralCareColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: RuralCareColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle supporting = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: RuralCareColors.textSecondary,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle measurement = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    color: RuralCareColors.textPrimary,
  );
}

/// Reusable layout shapes & decorations conforming to DESIGN.md Section 3
class AppDecorations {
  /// Standard card decoration: white surface, 1px border (#DCE4ED), radius 16, no shadow
  static BoxDecoration card({Color? color, Color? borderColor, double? radius}) {
    return BoxDecoration(
      color: color ?? RuralCareColors.surface,
      borderRadius: BorderRadius.circular(radius ?? 16.0),
      border: Border.all(
        color: borderColor ?? RuralCareColors.border,
        width: 1.0,
      ),
    );
  }

  /// Subtle floating sheet/navigation shadow (black 6%, blur 20, vertical offset 4)
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x0F000000), // 6% black
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  /// Status label chip decoration: radius 6 (not oversized pill)
  static BoxDecoration statusBadge({required Color background, Color? border}) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6.0),
      border: border != null ? Border.all(color: border, width: 1.0) : null,
    );
  }

  /// 52px primary action button style (radius 12, bold text, primary background)
  static ButtonStyle primaryButton({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? RuralCareColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTypography.button,
      elevation: 0,
    );
  }

  /// 52px form input decoration (1px input-border, radius 10, clean background)
  static InputDecoration input({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.supporting,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: RuralCareColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: RuralCareColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: RuralCareColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: RuralCareColors.primary, width: 1.5),
      ),
    );
  }
}

class RuralCareTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: RuralCareColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: RuralCareColors.primary,
        onPrimary: Colors.white,
        primaryContainer: RuralCareColors.primarySoft,
        onPrimaryContainer: RuralCareColors.primary,
        secondary: RuralCareColors.teal,
        onSecondary: Colors.white,
        secondaryContainer: RuralCareColors.tealSoft,
        onSecondaryContainer: RuralCareColors.teal,
        surface: RuralCareColors.surface,
        onSurface: RuralCareColors.textPrimary,
        error: RuralCareColors.critical,
        onError: Colors.white,
        errorContainer: RuralCareColors.criticalSoft,
        onErrorContainer: RuralCareColors.critical,
      ),
      fontFamily: AppTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: RuralCareColors.surface,
        foregroundColor: RuralCareColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle,
        iconTheme: IconThemeData(color: RuralCareColors.textPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: RuralCareColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: RuralCareColors.border, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RuralCareColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52), // DESIGN.md: min height 52
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // DESIGN.md: inputs/buttons 12
          ),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RuralCareColors.primary,
          side: const BorderSide(color: RuralCareColors.inputBorder, width: 1.0),
          minimumSize: const Size.fromHeight(52), // DESIGN.md: min height 52
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RuralCareColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: RuralCareColors.inputBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: RuralCareColors.inputBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: RuralCareColors.focus, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: RuralCareColors.critical, width: 1.0),
        ),
        labelStyle: AppTypography.supporting,
        hintStyle: AppTypography.supporting,
      ),
    );
  }
}

class AppTheme {
  static ThemeData get themeData => RuralCareTheme.lightTheme;
}
