import 'package:flutter/material.dart';

class AppColors {
  // Quadrant colors
  static const Color q1 = Color(0xFFFF4D4D); // crimson
  static const Color q2 = Color(0xff2563eb); // cobalt blue (originally 3B82F6, 2563eb is cleaner)
  static const Color q3 = Color(0xFFF59E0B); // amber
  static const Color q4 = Color(0xFF64748B); // slate grey

  // Light theme colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // Dark theme colors
  static const Color darkBg = Color(0xFF0F172A); // slate-900
  static const Color darkCard = Color(0xFF1E293B); // slate-800
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightDivider,
      primaryColor: AppColors.q2,
      colorScheme: const ColorScheme.light(
        primary: AppColors.q2,
        secondary: AppColors.q3,
        surface: AppColors.lightCard,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkDivider,
      primaryColor: AppColors.q2,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.q2,
        secondary: AppColors.q3,
        surface: AppColors.darkCard,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }
}
