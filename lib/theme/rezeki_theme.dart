import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryBright = Color(0xFF3B82F6);
  static const Color ring = Color(0xFF60A5FA);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFF);
  static const Color backgroundMid = Color(0xFFF0F5FF);
  static const Color backgroundEnd = Color(0xFFEEF2FF);
  static const Color surface = Colors.white;
  static const Color surfaceGlass = Color(0xE6FFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Borders & inputs
  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Color(0xFFF1F5F9);

  // Secondary / accent
  static const Color secondary = Color(0xFFE0E7FF);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);

  // Status — vibrant
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color muted = Color(0xFFF1F5F9);

  // Status lead
  static const Color newLead = Color(0xFF64748B);
  static const Color newLeadLight = Color(0xFFE2E8F0);
  static const Color interestedLight = Color(0xFFE0E7FF);
  static const Color processingLight = Color(0xFFDBEAFE);

  // Backward-compatible names
  static const Color navy = primary;
  static const Color navyLight = primaryBright;
  static const Color orange = warning;
  static const Color orangeLight = warningLight;
}

class RezekiSpacings {
  RezekiSpacings._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class RezekiRadii {
  RezekiRadii._();

  static const double none = 0;
  static const double sm = 8;
  static const double input = 12;
  static const double button = 12;
  static const double card = 16;
  static const double avatar = 12;
  static const double badge = 999;
  static const double glass = 20;
}

class RezekiTheme {
  RezekiTheme._();

  // Background gradients by screen context
  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, AppColors.backgroundMid, AppColors.backgroundEnd],
    stops: [0, 0.46, 1],
  );

  static const LinearGradient loginBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
    stops: [0, 0.5, 1],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  static const LinearGradient tealPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF8B5CF6)],
  );

  static const LinearGradient amberRoseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
  );

  static const LinearGradient surfaceGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FF)],
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0A1525).withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: const Color(0xFF0A1525).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0A1525).withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: const Color(0xFF0A1525).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0A1525).withValues(alpha: 0.02),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.1),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get panelShadow => [
    BoxShadow(
      color: const Color(0xFF0B1626).withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(RezekiRadii.card),
    border: Border.all(
      color: AppColors.border.withValues(alpha: 0.5),
    ),
    boxShadow: softShadow,
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: AppColors.surfaceGlass,
    borderRadius: BorderRadius.circular(RezekiRadii.glass),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.6),
    ),
    boxShadow: elevatedShadow,
  );

  static ({Color bg, Color fg}) statusColors(String status) {
    switch (status) {
      case 'Closed Won':
        return (bg: AppColors.successLight, fg: AppColors.success);
      case 'Closed Lost':
        return (bg: AppColors.errorLight, fg: AppColors.error);
      case 'Interested':
      case 'Contacted':
        return (bg: AppColors.interestedLight, fg: AppColors.primary);
      case 'Processing':
        return (bg: AppColors.warningLight, fg: AppColors.warning);
      case 'New Lead':
      default:
        return (bg: AppColors.newLeadLight, fg: AppColors.newLead);
    }
  }

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Avenir Next',
      fontFamilyFallback: const ['Segoe UI', 'Helvetica Neue', 'Arial'],
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        surfaceContainerHighest: AppColors.muted,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        prefixIconColor: AppColors.textTertiary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RezekiRadii.button),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RezekiRadii.button),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.card),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.muted,
        selectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          side: BorderSide.none,
        ),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textTertiary, size: 24);
        }),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(RezekiRadii.card)),
        ),
      ),
    );
  }
}
