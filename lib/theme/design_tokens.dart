import 'package:flutter/material.dart';

// ─── 간격 ───
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

// ─── 라운딩 ───
class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 100;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));
}

// ─── 그림자 ───
class AppShadows {
  /// 일반 카드용 (보관함, 설정 등)
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// 스와이프 카드용
  static List<BoxShadow> swipeCard(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// 플로팅 네비게이션용
  static List<BoxShadow> navigation(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─── 애니메이션 ───
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

// ─── 라벨 프리셋 컬러 (채도 낮춘 버전) ───
class LabelColors {
  static const List<Color> presets = [
    Color(0xFF5B9BD5), // Calm Blue
    Color(0xFF6DAE72), // Forest Green
    Color(0xFF7B84B8), // Lavender
    Color(0xFFA672B0), // Soft Purple
    Color(0xFFD9706E), // Dusty Rose
    Color(0xFFE8BD4E), // Warm Amber
    Color(0xFF4DB8C7), // Teal
    Color(0xFFE08A6A), // Terracotta
    Color(0xFF8D7B6E), // Warm Taupe
    Color(0xFF8D9AA3), // Cool Slate
  ];
}
