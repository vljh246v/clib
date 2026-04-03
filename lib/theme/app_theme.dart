import 'package:flutter/material.dart';

class AppColors {
  // Main
  static const deepIndigo = Color(0xFF1A1A40);

  // Point
  static const neonGreen = Color(0xFF39FF14);
  static const softCoral = Color(0xFFFF6B6B);

  // Neutral
  static const darkBg = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const lightBg = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.deepIndigo,
        secondary: AppColors.neonGreen,
        error: AppColors.softCoral,
        surface: AppColors.darkSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: Colors.grey,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepIndigo,
        secondary: AppColors.neonGreen,
        error: AppColors.softCoral,
        surface: AppColors.lightSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.deepIndigo,
        unselectedItemColor: Colors.grey,
      ),
      useMaterial3: true,
    );
  }
}
