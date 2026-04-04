import 'package:flutter/material.dart';

class AppColors {
  // ─── Main ───
  static const warmCharcoal = Color(0xFF2C2C3A);
  static const softLavender = Color(0xFFA8B5D6);

  // ─── Accent ───
  static const sageGreen = Color(0xFF5BA67D);
  static const softSage = Color(0xFF7DC4A0);

  // ─── Semantic ───
  static const mutedRose = Color(0xFFE8726E);
  static const softRose = Color(0xFFE8857F);

  // ─── Swipe 방향 (개념 유지, 톤만 변경) ───
  static const swipeRead = Color(0xFF5BA67D); // 오른쪽: sage green
  static const swipeSkip = Color(0xFFE8726E); // 왼쪽: muted rose

  // ─── Neutral - Light ───
  static const lightBg = Color(0xFFF8F7F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF2F1EE);

  // ─── Neutral - Dark ───
  static const darkBg = Color(0xFF141416);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkSurfaceContainer = Color(0xFF242426);

  // ─── Text ───
  static const lightOnSurface = Color(0xFF1C1C1E);
  static const lightOnSurfaceVariant = Color(0xFF8E8E93);
  static const darkOnSurface = Color(0xFFE5E5EA);
  static const darkOnSurfaceVariant = Color(0xFF8E8E93);
}

class AppTheme {
  static const _fontFamily = 'Pretendard';

  // ─── Dark Theme ───
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.softLavender,
        onPrimary: Color(0xFF1C1C1E),
        secondary: AppColors.softSage,
        onSecondary: Color(0xFF1C1C1E),
        error: AppColors.softRose,
        onError: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        surfaceContainerHighest: AppColors.darkSurfaceContainer,
      ),
      textTheme: _textTheme(Brightness.dark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.softSage,
        unselectedItemColor: AppColors.darkOnSurfaceVariant,
      ),
      dividerColor: const Color(0xFF2C2C2E),
      useMaterial3: true,
    );
  }

  // ─── Light Theme ───
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.warmCharcoal,
        onPrimary: Colors.white,
        secondary: AppColors.sageGreen,
        onSecondary: Colors.white,
        error: AppColors.mutedRose,
        onError: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        surfaceContainerHighest: AppColors.lightSurfaceContainer,
      ),
      textTheme: _textTheme(Brightness.light),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.warmCharcoal,
        unselectedItemColor: AppColors.lightOnSurfaceVariant,
      ),
      dividerColor: const Color(0xFFEAEAE8),
      useMaterial3: true,
    );
  }

  // ─── Typography ───
  static TextTheme _textTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final Color secondary = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final Color title = isDark ? Colors.white : const Color(0xFF0D0D0D);

    return TextTheme(
      // 화면 타이틀
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: title,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: title,
      ),

      // 섹션 헤더
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: title,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: title,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primary,
      ),

      // 본문
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondary,
      ),

      // 칩, 뱃지, 메타
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.1,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.2,
        color: secondary,
      ),
    );
  }
}
