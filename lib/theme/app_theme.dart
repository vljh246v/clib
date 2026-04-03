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
        primary: Color(0xFF7986CB),       // 다크 배경에서 읽기 좋은 인디고
        onPrimary: Colors.white,
        secondary: AppColors.neonGreen,
        onSecondary: Colors.black,
        error: AppColors.softCoral,
        onError: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: Color(0xFFE8E8E8),     // 밝은 텍스트
        onSurfaceVariant: Color(0xFFB0B0B0),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE8E8E8)),
        bodyMedium: TextStyle(color: Color(0xFFE8E8E8)),
        bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Color(0xFFE8E8E8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: Color(0xFF888888),
      ),
      dividerColor: Color(0xFF2E2E2E),
      useMaterial3: true,
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepIndigo,
        onPrimary: Colors.white,
        secondary: Color(0xFF2DBF0F),     // 라이트 모드에서 더 진한 녹색
        onSecondary: Colors.white,
        error: AppColors.softCoral,
        onError: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: Color(0xFF1A1A1A),
        onSurfaceVariant: Color(0xFF555555),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
        bodySmall: TextStyle(color: Color(0xFF555555)),
        titleLarge: TextStyle(color: Color(0xFF0D0D0D)),
        titleMedium: TextStyle(color: Color(0xFF0D0D0D)),
        titleSmall: TextStyle(color: Color(0xFF1A1A1A)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.deepIndigo,
        unselectedItemColor: Color(0xFF888888),
      ),
      dividerColor: Color(0xFFE0E0E0),
      useMaterial3: true,
    );
  }
}
