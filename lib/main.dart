import 'dart:io' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/screens/home_screen.dart';
import 'package:clib/screens/library_screen.dart';
import 'package:clib/screens/settings_screen.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/notification_service.dart';
import 'package:clib/services/ad_service.dart';
import 'package:clib/services/demo_data_service.dart';
import 'package:clib/services/share_service.dart';
import 'package:clib/services/sync_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/screens/onboarding_screen.dart';
import 'package:clib/widgets/share_label_sheet.dart';
import 'package:clib/widgets/home_overlay_guide.dart';

/// 앱 전역 테마 모드
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

/// 아티클 추가/삭제 시 HomeScreen에 알리는 notifier
final articlesChangedNotifier = ValueNotifier<int>(0);

/// 라벨 변경 시 LibraryScreen 등에 알리는 notifier
final labelsChangedNotifier = ValueNotifier<int>(0);

/// 인증 상태 notifier
final authStateNotifier = ValueNotifier<User?>(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await DatabaseService.init();
  await DatabaseService.syncLabelsToAppGroup();
  await NotificationService.init();
  await NotificationService.rescheduleAll();
  await AdService.initialize();
  // debug 모드 + 미로그인 상태에서만 데모 데이터 생성
  // (로그인 상태에서 seed하면 Firestore 동기화와 충돌)
  if (kDebugMode && FirebaseAuth.instance.currentUser == null) {
    await DemoDataService.seed();
  }
  // 모든 초기화 완료 후 인증 상태 감지 + 동기화 시작
  // (seed()보다 뒤에 와야 레이스 컨디션 방지)
  final currentUser = FirebaseAuth.instance.currentUser;
  authStateNotifier.value = currentUser;
  if (currentUser != null) {
    await SyncService.init(currentUser);
  }
  // 첫 이벤트(현재 상태)는 위에서 처리했으므로 건너뜀
  bool isFirstAuthEvent = true;
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (isFirstAuthEvent) {
      isFirstAuthEvent = false;
      return;
    }
    authStateNotifier.value = user;
    if (user != null) {
      SyncService.init(user);
    } else {
      SyncService.dispose();
    }
  });
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
  bool _showOverlayGuide = false;

  // 오버레이 가이드용 GlobalKey
  final _cardAreaKey = GlobalKey();
  final _addButtonKey = GlobalKey();
  final _libraryNavKey = GlobalKey();
  final _settingsNavKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(cardAreaKey: _cardAreaKey, addButtonKey: _addButtonKey),
      const LibraryScreen(),
      SettingsScreen(onShowGuide: _showGuideFromSettings),
    ];
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingShares();
      if (!DatabaseService.hasSeenHomeGuide) {
        setState(() => _showOverlayGuide = true);
      }
    });
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

  void _showGuideFromSettings() {
    setState(() => _currentIndex = 0);
    // 홈 탭 레이아웃 완료 후 오버레이 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showOverlayGuide = true);
    });
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

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: _screens[_currentIndex],
          ),
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
                    key: _libraryNavKey,
                    icon: Icons.grid_view_rounded,
                    selected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _NavItem(
                    key: _settingsNavKey,
                    icon: Icons.settings_rounded,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showOverlayGuide)
          HomeOverlayGuide(
            targetKeys: [
              _cardAreaKey,
              _addButtonKey,
              _libraryNavKey,
              _settingsNavKey,
            ],
            onComplete: () => setState(() => _showOverlayGuide = false),
          ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
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
