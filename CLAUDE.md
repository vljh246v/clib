# Clib (클립)

> 저장만 하던 습관에서 읽는 습관으로, 스와이프 지식 도서관

링크를 저장만 하고 읽지 않는 습관을 개선하는 모바일 앱. 스와이프 카드 UI + 주간 로컬 푸시로 재방문을 유도한다.

- **Local-first**: 회원가입 없이 Hive 로컬 DB 동작. Firebase 로그인 시 선택적 클라우드 동기화.
- **핵심 가치**: 무마찰 수집 / 게임화된 소비 / 능동적 재방문

## 관련 프로젝트

| 프로젝트 | 경로 | 설명 |
|----------|------|------|
| **크롬 확장 프로그램** | `~/Documents/workspace/clib-extension` | Vite + TypeScript 기반 Chrome Extension. 브라우저에서 링크를 바로 Clib으로 저장 |
| **설명 & 개인정보처리 페이지** | `~/Documents/workspace/clib-support` | 정적 HTML(`docs/index.html`). 앱스토어 지원 URL 및 개인정보처리방침 호스팅 |

## Quick Start

```bash
flutter pub get
cd ios && pod install && cd ..
dart run build_runner build --delete-conflicting-outputs   # 모델 변경 시
flutter gen-l10n                                            # ARB 변경 시 (l10n.yaml 기반)
flutter analyze                                             # warning/error 0 유지
flutter test                                                # widget_test
flutter run                                                 # 디버그
flutter run --release                                       # 릴리즈 빌드 실기기 확인 필수
```

## 기술 스택

| 영역 | 패키지 |
|------|-------|
| 로컬 DB | `hive` ^2.2.3, `hive_flutter` ^1.1.0 (+ `hive_generator` 코드 생성) |
| 클라우드 동기화 | `firebase_core` ^3.13, `firebase_auth` ^5.5, `cloud_firestore` ^5.6, `google_sign_in` ^6.2 |
| 알림 | `flutter_local_notifications` ^18, `timezone` ^0.10, `flutter_timezone` ^5 |
| UI | `flutter_card_swiper` ^7, `url_launcher` ^6.2, `google_mobile_ads` ^7 |
| 상태 관리 | `flutter_bloc` ^8.1.6, `equatable` ^2.0.5 (+ `bloc_test` ^9.1.7 dev) |
| 스크래핑 | `http` ^1.2, `html` ^0.15 |
| i18n | `flutter_localizations` (SDK) + `intl`, Flutter 공식 gen-l10n |

## 프로젝트 구조

```
lib/
├── main.dart                  # 앱 진입점, MultiBlocProvider(ThemeCubit, AuthCubit)
├── l10n/                      # app_{ko,en,de,es,fr,ja,pt,zh,zh_CN,zh_TW}.arb + 자동 생성
├── blocs/                     # theme/ auth/ onboarding/ library/ label_management/
│                              # article_list/ add_article/ home/ — 화면별 Cubit(+HomeBloc)
├── models/                    # Article, Label (Hive), platform_meta
├── services/                  # 아래 "서비스 계층" 참조
├── state/                     # app_notifiers (전역 articlesChangedNotifier 등)
├── screens/                   # home, library, all_articles, bookmarked_articles,
│                              # label_detail, label_management, onboarding, settings, theme_settings
├── widgets/                   # article_card, swipe_ad_card, inline_banner_ad,
│                              # article_list_view, article_list_item, bulk_action_bar,
│                              # bulk_delete_confirm, article_actions_sheet, memo_sheet,
│                              # label_edit_sheet, share_label_sheet,
│                              # add_article_sheet, home_overlay_guide
└── theme/                     # app_theme(Light/Dark), design_tokens
```

## 데이터 모델

모델 변경 시 **반드시** `dart run build_runner build --delete-conflicting-outputs` 실행. `HiveField` 번호는 **재사용 금지**(추가만 가능).

### Article (`typeId: 0`)

| HiveField | 필드 | 타입 |
|---|---|---|
| 0 | url | String |
| 1 | title | String |
| 2 | thumbnailUrl | String? |
| 3 | platform | Platform (enum) |
| 4 | topicLabels | List\<String\> |
| 5 | isRead | bool |
| 6 | createdAt | DateTime |
| 7 | isBookmarked | bool (default false) |
| 8 | memo | String? (한 줄, 최대 100자) |
| 9 | firestoreId | String? (동기화 식별자) |
| 10 | updatedAt | DateTime? |
| 11 | deletedAt | DateTime? (tombstone) |

`Platform` enum: `youtube, instagram, blog, x, tiktok, facebook, linkedin, github, reddit, threads, naverBlog, etc`. `classifyPlatform(url)`로 URL 호스트 기반 자동 분류.

### Label (`typeId: 2`)

| HiveField | 필드 | 비고 |
|---|---|---|
| 0 | name | |
| 1 | colorValue | int (Color.value) |
| 2 | createdAt | |
| 3 | notificationEnabled | bool (default false) |
| 4 | notificationDays | List\<int\> (0=월 ~ 6=일) |
| 5 | notificationTime | "HH:mm" (default "09:00") |

## 서비스 계층

Hive Boxes: `articles`, `labels`, `preferences` (동적 key-value).

| 서비스 | 역할 |
|--------|------|
| **DatabaseService** | Hive CRUD, 통계, 테마/온보딩 preferences, 북마크/메모, 라벨 정규화. **모든 mutation 직후 `articlesChangedNotifier` / `labelsChangedNotifier` 발사**(Cubit/Bloc이 자동 재로드). `skipSync` 플래그로 동기화 억제 가능 |
| **NotificationService** | 주간 weekly 반복 알림. ID = `label.key * 10 + dayOfWeek`. 메시지는 `Platform.localeName` 기반 다국어 |
| **ShareService** | Android: MethodChannel `com.jaehyun.clib/share`. iOS: App Group `group.com.jaehyun.clib.share` UserDefaults. `processAndSave()`가 스크래핑 후 `DatabaseService.saveArticle()` 위임(notifier 발사는 DB 서비스 내부) |
| **ScrapingService** | HTTP(User-Agent: iPhone Safari) + charset 감지 디코딩(`utf8.decode(allowMalformed: true)`). `og:title/image/description` → `<title>` → URL fallback |
| **AdService** | AdMob 초기화. debug는 Google 테스트 ID, release는 프로덕션. 네이티브는 `NativeTemplateStyle(TemplateType.medium)` Flutter 렌더링 |
| **AuthService** | Firebase Auth + Google Sign-In. 로그인/로그아웃/탈퇴 |
| **FirestoreService** | `users/{uid}/articles`, `users/{uid}/labels` 컬렉션 맵핑. 서버 타임스탬프 사용 |
| **SyncService** | 로그인 시 snapshot listener → 로컬↔리모트 머지. 동시 스냅샷은 pending 버퍼에 큐잉. tombstone(`deletedAt`)으로 삭제 전파 |
| **DemoDataService** | 앱스토어 스크린샷용 시드 데이터. 기존 데이터가 있으면 미실행 |

## 전역 상태

상태 관리는 `flutter_bloc`(기본 Cubit, 이벤트 소싱이 필요한 화면만 Bloc) 기반.

### 전역 BlocProvider (`lib/main.dart` MultiBlocProvider)

| Bloc/Cubit | 역할 | lazy |
|---|---|---|
| `ThemeCubit` | `ThemeMode` 상태 + `DatabaseService.saveThemeMode` 영속화 | true |
| `AuthCubit` | `FirebaseAuth.idTokenChanges` 구독 + `SyncService.init/dispose` 소유 | **false**(즉시 인스턴스화) |

그 외 화면 단위 Cubit/Bloc(`OnboardingCubit`, `LibraryCubit`, `LabelManagementCubit`, `ArticleListCubit`, `AddArticleCubit`, `HomeBloc`)은 **화면 진입 시 `BlocProvider`로 주입**한다.

### 전역 ValueNotifier (`lib/state/app_notifiers.dart`)

```dart
final articlesChangedNotifier = ValueNotifier<int>(0); // DB 변경 시 increment
final labelsChangedNotifier   = ValueNotifier<int>(0);
```

- 발사 위치는 **`DatabaseService` mutation 메서드 + `SyncService` 원격 스냅샷 적용 분기**. 그 외 경로(Cubit/Bloc/`ShareService`)에서 직접 발사 금지(중복 reload 방지).
- 각 Cubit/Bloc은 생성자에서 `addListener(_onChanged)` → `close()`에서 `removeListener` 짝.
- `lib/main.dart`는 호환을 위해 `state/app_notifiers.dart`를 re-export — `package:clib/main.dart` show ... 경로도 계속 동작.

### 부팅 흐름

- `main()`: Firebase init → `DatabaseService.init()` → `NotificationService.init/rescheduleAll` → AdMob은 `addPostFrameCallback`에서 lazy init → `runApp(ClibApp)`.
- `ClibApp`: `MultiBlocProvider(ThemeCubit, AuthCubit)` → `BlocBuilder<ThemeCubit, ThemeMode>` → `MaterialApp(themeMode)`. `hasSeenOnboarding`로 초기 화면 분기(Onboarding ↔ MainScreen).
- `MainScreen`: `WidgetsBindingObserver`로 `AppLifecycleState.resumed` 시 `_checkPendingShares()` 호출(Android `ShareLabelSheet` / iOS `ShareService.checkPendingShares()`).
- **아티클/라벨 CRUD는 반드시 `DatabaseService`를 경유**해야 notifier 트리거 + Firestore 동기화 + Cubit/Bloc 자동 재로드가 일관 동작한다.

## 화면별 주요 로직

- **HomeScreen** (`HomeBloc` — 시리즈 유일 Bloc): 이벤트 소싱 — `HomeLoadDeck/SwipeRead/SwipeLater/FilterLabelsChanged/ToggleBookmark/UpdateMemo/ToggleExpand`. `CardSwiper(isLoop: true)` 덱. 오른쪽 = 읽음, 왼쪽 = 나중에. 스와이프 중 테두리는 `AppColors.swipeRead/swipeSkip`. **컨트롤러(`CardSwiperController`/`_pendingDispose`/`_thresholdNotifier`)는 `_HomeBody(StatefulWidget)` 로컬 SSOT**(Bloc state 진입 금지). `state.deckVersion`을 `CardSwiper(key: ValueKey(...))`로 사용해 인덱스 out-of-range 방지. `AdService.adInterval` 카드마다 `SwipeAdCard` 삽입. 첫 실행 시 `home_overlay_guide` 오버레이.
- **LibraryScreen** (`LibraryCubit`): 2열 GridView. 인덱스 0="전체", 1="북마크", 이후 라벨 카드(원형 프로그레스). `articlesChangedNotifier` + `labelsChangedNotifier` 양쪽 구독.
- **AllArticlesScreen / BookmarkedArticlesScreen / LabelDetailScreen** (`ArticleListCubit` 재사용): `ArticleListSource`로 분기(`All`/`Bookmarked`/`ByLabel`). 공통 위젯 `ArticleListView` + `ArticleListItem`(+`accentColor` 옵션) + `BulkActionBar` + `showBulkDeleteConfirm` 헬퍼. `selectedKeys: List<int>`(Hive key는 int). `AdService.adInterval` 마다 `InlineBannerAd` 삽입.
- **LabelManagementScreen** (`LabelManagementCubit`): 라벨 CRUD + 라벨별 알림(요일 칩 + TimePicker).
- **OnboardingScreen** (`OnboardingCubit`): 3페이지. `isGuideMode: false`(첫 실행, 완료 시 `setOnboardingComplete()` + `/main`), `true`(설정에서 진입, `Navigator.pop()`).
- **AddArticleSheet** (`AddArticleCubit`): URL 검증 + 라벨 토글 + 신규 라벨 생성 + 저장. `urlError` 센티넬 / `saveFailure` flag로 에러 채널 분리.

## 디자인 시스템

디자인 방향: **Calm & Refined** (Notion, Things 3 영감). Pretendard 5 weight(Regular~ExtraBold).

### 컬러 (`AppColors`)

| 토큰 | Light | Dark |
|------|-------|------|
| Primary | Warm Charcoal `#2C2C3A` | Soft Lavender `#A8B5D6` |
| Secondary(accent) | Sage Green `#5BA67D` | Soft Sage `#7DC4A0` |
| Error | Muted Rose `#E8726E` | Soft Rose `#E8857F` |
| Background | `#F8F7F4` | `#141416` |
| Surface / Container | `#FFFFFF` / `#F2F1EE` | `#1C1C1E` / `#242426` |
| OnSurface / Variant | `#1C1C1E` / `#8E8E93` | `#E5E5EA` / `#8E8E93` |
| swipeRead / swipeSkip | Sage Green / Muted Rose (공용) | |

### 디자인 토큰 (`design_tokens.dart`)

- **Spacing**: `xs(4) / sm(8) / md(12) / lg(16) / xl(20) / xxl(24) / xxxl(32)`
- **Radii**: `sm(8) / md(12) / lg(16) / xl(20) / full(100)` + `BorderRadius` 상수
- **AppShadows**: `card(isDark)`, `swipeCard(isDark)`, `navigation(isDark)` — 이중 레이어
- **AppDurations**: `fast(150) / medium(250) / slow(350)`
- **LabelColors.presets**: 10색 (채도 낮은 톤)

**UI 규칙**: 색은 `Theme.of(context).colorScheme` 또는 `AppColors`, 간격은 `Spacing.*`, 코너는 `Radii.*`, 그림자는 `AppShadows.*`. 하드코딩 금지.

## 다국어 (i18n)

- 방식: Flutter 공식 `gen-l10n` (ARB, `l10n.yaml` 템플릿=`app_ko.arb`).
- **지원 로케일(10)**: `ko`(기본), `en`(fallback), `de, es, fr, ja, pt, zh, zh_CN, zh_TW`.
- 로케일 결정: 시스템 언어 자동 감지. 앱별 언어 설정: iOS Settings > Clib, Android 13+ Settings > Clib.
- UI 문자열: `AppLocalizations.of(context)!.keyName`. **하드코딩 금지.**
- `NotificationService`는 BuildContext 없이 `dart:io` `Platform.localeName`으로 로케일 판단 → 한국어면 한국어, 그 외는 영어 메시지.
- ICU 플레이스홀더: `"selectedCount": "{count}개 선택됨"` 형태. **ko/en을 포함한 모든 로케일 파일에 동일 키·동일 플레이스홀더**가 있어야 한다.

## 네이티브 설정

### Android
- Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`.
- `MainActivity.launchMode = singleTop` + Intent filter `ACTION_SEND` `text/plain`(URL 공유 수신).
- `android:localeConfig="@xml/locales_config"`(Android 13+ 앱별 언어).
- AdMob App ID: `AndroidManifest.xml` meta-data `com.google.android.gms.ads.APPLICATION_ID`.
- 스플래시: `drawable/launch_image.png` + `android:gravity="center"`, 배경 `#ECE5D5`. `values-night/styles.xml` LaunchTheme 부모는 `Theme.NoTitleBar`(검정 배경 방지).

### iOS (`AppDelegate.swift`)
- App Group: `group.com.jaehyun.clib.share`. MethodChannel `com.jaehyun.clib/share`: `getSharedURLs`, `clearSharedURLs`, `syncLabels`.
- `UNUserNotificationCenter` delegate 설정.
- `Info.plist`: `CFBundleLocalizations`(전 로케일), `GADApplicationIdentifier`(AdMob iOS App ID).
- 스플래시: `LaunchImage.imageset` 400×1200, `scaleAspectFit` + 4방향 edge 제약, 배경 `#ECE5D5`.

## 개발 컨벤션

- 한국어 주석/커밋 메시지.
- UI 문자열 하드코딩 금지 → 모든 ARB 파일에 키 추가 후 `AppLocalizations` 사용.
- 디자인 토큰 우회 금지 (색/간격/코너/그림자).
- 모델 변경 → `dart run build_runner build`.
- `flutter analyze` = No issues 유지.
- 릴리즈 검증은 실기기 `flutter run --release`.

### 상태 관리 규칙 (`flutter_bloc`)

- 기본은 **Cubit**. 이벤트 소싱이 명시적으로 필요한 화면만 **Bloc**(현재 `HomeBloc` 1개).
- 전역 = `ThemeCubit` + `AuthCubit`. 나머지는 화면 진입 시 `BlocProvider`로 주입.
- 모든 `state` 클래스는 `Equatable` + `copyWith` 필수.
- **컨트롤러는 위젯 로컬 SSOT**: `TextEditingController` / `CardSwiperController` / `PageController` 등은 StatefulWidget의 `initState`/`dispose`에서 관리. Cubit/Bloc state에 보관 금지.
- **Hive in-place 변경 대응 `refreshToken` 패턴**: Hive 모델(`Article`/`Label`)은 `==` 미구현이라 in-place 변경 후 동일 인스턴스 리스트는 Equatable dedup으로 emit이 스킵된다. 상태 클래스에 `final int refreshToken;`(또는 `generation`) 필드 추가 + 로드 핸들러에서 매번 증가시켜 stream emit 강제.
- **CardSwiper 재생성 `deckVersion` 패턴**: `CardSwiper(key: ValueKey(state.deckVersion))`. 필터 변경 / swipe-read / loop 경계에서 증가 → 컨트롤러는 `BlocListener.listenWhen: p.deckVersion != c.deckVersion` 가드 후 `_pendingDispose` 큐 + `addPostFrameCallback` 일괄 dispose(이중 dispose 방지 try-catch).
- **다이얼로그/시트 호출 전 `final cubit = context.read<X>()` 캡처**: `showDialog`/`showModalBottomSheet`는 provider scope 이탈.
- **에러 채널 분리**: inline 필드 오류(센티넬 코드), SnackBar 트리거(bool flag 또는 transient nonce + `clearXxx()`), 원문 메시지(String?) 혼용 금지. `BlocListener.listenWhen` 가드 필수.
- **bloc_test 미도입**: `hive_generator 2.0.1` ↔ `bloc_test`(test 1.16+) 충돌. 일반 `flutter_test` + `Cubit.stream.listen` + `expectLater` + `await Future<void>.delayed(Duration.zero)` 패턴 사용.

## 코드 품질 & 재검증 (필수)

**모든 코드 변경 후 아래를 반드시 수행한다.**

1. **영향 범위 파악**: 대상 파일을 먼저 읽고 참조 지점 전부 grep. 파급이 크면 작업 전에 사용자와 공유.
2. **정적 분석**: `flutter analyze` warning/error 0건.
3. **크로스 체크**: import 유효성, 네이밍 일관성, 신규 `AppLocalizations` 키는 **10개 ARB 전부**에 존재, 모델 변경 시 `build_runner` 실행.
4. **자기 리뷰**: 조건 분기/null/`await` 누락/`setState` 남용/`dispose` 누락/하드코딩/매직 넘버 재확인.
5. **최종 보고**: 한 줄 요약 (예: "analyze 통과, ARB 10개 동기화, 영향 범위 HomeScreen만").
6. **커밋 메시지 제안**: 코드 변경이 있었을 때만. 한국어 한 줄 요약. 성격이 다르면 분리 커밋 권장.

**보조 에이전트**: `.claude/agents/arb-sync-checker.md`(ARB 동기화), `.claude/agents/flutter-code-reviewer.md`(변경분 리뷰). 커밋/PR 전 호출 권장.
