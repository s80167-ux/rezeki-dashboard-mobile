import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF4F7FB);
  static const Color backgroundMid = Color(0xFFF6F8FC);
  static const Color backgroundEnd = Color(0xFFEFF4FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0E1726);
  static const Color textSecondary = Color(0xFF5F7088);
  static const Color textTertiary = Color(0xFF7E8FA8);
  static const Color border = Color(0xFFDBE4EF);
  static const Color input = Color(0xFFE9EFF6);

  static const Color primary = Color(0xFF2860B8);
  static const Color primaryDark = Color(0xFF071F52);
  static const Color primaryBright = Color(0xFF0751D8);
  static const Color ring = Color(0xFF4D82D6);
  static const Color secondary = Color(0xFFE5ECF5);

  static const Color success = Color(0xFF268158);
  static const Color successLight = Color(0xFFE7F4ED);
  static const Color warning = Color(0xFFB57C22);
  static const Color warningLight = Color(0xFFF7EEDB);
  static const Color error = Color(0xFFBE4E54);
  static const Color errorLight = Color(0xFFF8E8E9);
  static const Color muted = Color(0xFFEDF2F8);

  static const Color newLead = textSecondary;
  static const Color newLeadLight = muted;
  static const Color interestedLight = Color(0xFFE9F0FB);
  static const Color processingLight = Color(0xFFE5EEF9);

  // Backward-compatible names used by the current widgets.
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
}

class RezekiTheme {
  RezekiTheme._();

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, AppColors.backgroundMid, AppColors.backgroundEnd],
    stops: [0, 0.46, 1],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0A1525).withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
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
      color: AppColors.border.withValues(alpha: 0.6),
    ),
    boxShadow: softShadow,
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
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.45,
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
            color: AppColors.border.withValues(alpha: 0.6),
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
