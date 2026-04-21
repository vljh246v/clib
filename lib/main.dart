import 'dart:io' as io;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/auth/auth_cubit.dart';
import 'package:clib/blocs/theme/theme_cubit.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/screens/home_screen.dart';
import 'package:clib/screens/library_screen.dart';
import 'package:clib/screens/settings_screen.dart';
import 'package:clib/services/auth_service.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/notification_service.dart';
import 'package:clib/services/ad_service.dart';
import 'package:clib/services/demo_data_service.dart';
import 'package:clib/services/share_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/screens/onboarding_screen.dart';
import 'package:clib/widgets/share_label_sheet.dart';
import 'package:clib/widgets/home_overlay_guide.dart';

// 기존 `package:clib/main.dart` show ... 경로 호환을 위한 re-export.
export 'package:clib/state/app_notifiers.dart'
    show articlesChangedNotifier, labelsChangedNotifier;

void main() async {
  await bootstrap(forTest: false);
  runApp(const ClibApp());
}

/// 앱 초기화 파이프라인.
///
/// 실행/테스트 공통 경로.
///
/// `forTest: true` 이면 `integration_test`용 경로로 동작한다:
/// - `Firebase.initializeApp()` + `DatabaseService.init()` 은 수행
///   (AuthCubit 이 `FirebaseAuth.idTokenChanges` 를 구독하므로 Firebase 자체는 필요)
/// - `DatabaseService.skipSync = true` 로 Firestore 동기화 경로 차단
/// - `NotificationService` / `AdService` / `DemoDataService` / `ShareService`
///   관련 초기화는 건너뜀 (네이티브 의존 + 테스트 간섭 방지)
///
/// 테스트에서는 `bootstrap(forTest: true)` 후 `runApp(const ClibApp())`.
/// 기본 사용자 흐름은 그대로지만 미로그인 + seed 데이터 없는 빈 상태로 시작.
Future<void> bootstrap({required bool forTest}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await DatabaseService.init();

  if (forTest) {
    DatabaseService.skipSync = true;
    return;
  }

  await DatabaseService.syncLabelsToAppGroup();
  await NotificationService.init();
  await NotificationService.rescheduleAll();
  // AdMob 초기화는 iOS Scene 엔진 준비 완료 후 실행
  // (main에서 직접 호출 시 EXC_BAD_ACCESS 크래시 발생)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService.initialize().catchError(
      (e, st) => debugPrint('AdMob init failed: $e'),
    );
  });
  // debug 모드 + 미로그인 상태에서만 데모 데이터 생성
  // (로그인 상태에서 seed하면 Firestore 동기화와 충돌)
  if (kDebugMode && !AuthService.isLoggedIn) {
    await DemoDataService.seed();
  }
  // 인증 상태 감지 + SyncService.init/dispose 는 AuthCubit이 소유한다
  // (ClibApp의 MultiBlocProvider에서 lazy: false로 즉시 인스턴스화)
}

class ClibApp extends StatelessWidget {
  const ClibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit(), lazy: false),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
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
      ),
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
