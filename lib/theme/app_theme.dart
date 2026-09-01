import 'package:flutter/material.dart';

class AppColors {
  // Pastel Quadrant Colors
  static const Color q1 = Color(0xFFFF7B73); // Soft Pastel Coral Red
  static const Color q2 = Color(0xFF4AA598); // Soft Pastel Sage Teal
  static const Color q3 = Color(0xFFEAA134); // Soft Pastel Warm Amber
  static const Color q4 = Color(0xFF94A3B8); // Soft Pastel Slate Grey
  static const Color q0 = Color(0xFF9D84D9); // Soft Pastel Lavender

  // Light Theme Pastel Colors (Apple Clean Aesthetic)
  static const Color lightBg = Color(0xFFF4F6F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInputBg = Color(0xFFEDF1F6);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightDivider = Colors.transparent; // No visible harsh borders

  // Dark Theme Pastel Colors (Apple Dark Aesthetic)
  static const Color darkBg = Color(0xFF161618);
  static const Color darkCard = Color(0xFF242426);
  static const Color darkInputBg = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF86868B);
  static const Color darkDivider = Colors.transparent; // No visible harsh borders
}

class AppTheme {
  static const String appleFont = 'Apple SD Gothic Neo';

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: appleFont,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      dividerColor: Colors.transparent,
      primaryColor: AppColors.q2,
      colorScheme: const ColorScheme.light(
        primary: AppColors.q2,
        secondary: AppColors.q3,
        surface: AppColors.lightCard,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontFamily: appleFont,
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontFamily: appleFont,
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontFamily: appleFont,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: appleFont,
          color: AppColors.lightTextSecondary,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.q2, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: appleFont,
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: appleFont,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      dividerColor: Colors.transparent,
      primaryColor: AppColors.q2,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.q2,
        secondary: AppColors.q3,
        surface: AppColors.darkCard,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontFamily: appleFont,
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontFamily: appleFont,
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontFamily: appleFont,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: appleFont,
          color: AppColors.darkTextSecondary,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.q2, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: appleFont,
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
      ),
      useMaterial3: true,
    );
  }
}
