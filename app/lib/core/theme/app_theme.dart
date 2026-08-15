import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bg = Color(0xFFFDF6EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFF0DE);
  static const Color border = Color(0xFFE8D5B7);
  static const Color divider = Color(0xFFF0E4CC);

  // Primary — burnt orange
  static const Color primary = Color(0xFFE8640C);
  static const Color primaryLight = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFC2440A);

  // Accent — forest green
  static const Color accent = Color(0xFF2D6A4F);
  static const Color accentLight = Color(0xFF40916C);

  // Text
  static const Color textPrimary = Color(0xFF1C1007);
  static const Color textSecondary = Color(0xFF5C4033);
  static const Color textMuted = Color(0xFF9C7B6A);

  // Score colors
  static const Color scoreLow = Color(0xFFDC2626);
  static const Color scoreMid = Color(0xFFEA580C);
  static const Color scoreHigh = Color(0xFFCA8A04);
  static const Color scoreTop = Color(0xFF16A34A);

  static Color forScore(double score) {
    if (score < 10) return scoreLow;
    if (score < 25) return scoreMid;
    if (score < 50) return scoreHigh;
    return scoreTop;
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8640C), Color(0xFFF97316)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          surface: AppColors.bg,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.scoreLow,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Color(0x22000000),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: AppColors.textSecondary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textMuted,
              size: 22)),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              color: s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textMuted,
              fontSize: 11,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500)),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.scoreLow),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: AppColors.primary,
          thumbColor: AppColors.primary,
          inactiveTrackColor: AppColors.border,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
