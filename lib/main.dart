import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:clib/screens/home_screen.dart';
import 'package:clib/screens/library_screen.dart';
import 'package:clib/screens/settings_screen.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/notification_service.dart';
import 'package:clib/services/share_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/screens/onboarding_screen.dart';
import 'package:clib/widgets/share_label_sheet.dart';

/// 앱 전역 테마 모드
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

/// 아티클 추가/삭제 시 HomeScreen에 알리는 notifier
final articlesChangedNotifier = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await DatabaseService.syncLabelsToAppGroup();
  await NotificationService.init();
  await NotificationService.rescheduleAll();
  themeModeNotifier.value = DatabaseService.savedThemeMode;
  runApp(const ClibApp());
}

class ClibApp extends StatelessWidget {
  const ClibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        final showOnboarding = !DatabaseService.hasSeenOnboarding;
        return MaterialApp(
          title: 'Clib',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: showOnboarding
              ? const OnboardingScreen()
              : const MainScreen(),
          routes: {
            '/main': (_) => const MainScreen(),
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingShares());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingShares();
    }
  }

  Future<void> _checkPendingShares() async {
    if (io.Platform.isAndroid) {
      // Android: URL 감지 후 라벨 선택 시트 표시
      final url = await ShareService.getPendingShareURL();
      if (url != null && mounted) {
        await ShareLabelSheet.show(context, url: url);
      }
    } else if (io.Platform.isIOS) {
      // iOS: Share Extension에서 이미 라벨 포함 저장됨
      await ShareService.checkPendingShares();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: Radii.borderFull,
            boxShadow: AppShadows.navigation(isDark),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.layers_rounded,
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                selected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                selected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.secondary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: AppDurations.fast,
              child: Icon(
                icon,
                size: 24,
                color: selected ? selectedColor : unselectedColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: AppDurations.fast,
              width: selected ? 5 : 0,
              height: selected ? 5 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? selectedColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
