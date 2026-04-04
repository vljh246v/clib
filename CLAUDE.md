# Clib (클립)

> 저장만 하던 습관에서 읽는 습관으로, 스와이프 지식 도서관

## 프로젝트 개요

Clib은 링크를 저장만 하고 읽지 않는 습관을 개선하기 위한 모바일 앱이다. 스와이프 기반의 카드 UI로 콘텐츠 소비를 게임화하고, 로컬 푸시 알림으로 재방문을 유도한다.

- 핵심 가치: 무마찰 수집(Zero-friction Scraping), 게임화된 소비(Swiping), 능동적 재방문(Scheduled Push)
- Local-first: 회원가입 없음, 모든 데이터는 기기 내부 Hive DB에 저장, 서버 의존성 없음

## 기술 스택

| 패키지 | 버전 | 목적 |
|--------|------|------|
| hive / hive_flutter | ^2.2.3 / ^1.1.0 | 로컬 DB |
| flutter_local_notifications | ^18.0.0 | 로컬 푸시 알림 |
| flutter_card_swiper | ^7.0.0 | 카드 스와이프 UI |
| http / html | ^1.2.0 / ^0.15.0 | OG 메타데이터 스크래핑 |
| url_launcher | ^6.2.0 | 외부 링크 열기 |
| timezone | ^0.10.0 | 주간 알림 스케줄 |
| flutter_localizations (SDK) | — | 다국어 지원 (i18n) |
| intl | any | ICU 메시지 포맷 |
| google_mobile_ads | ^7.0.0 | AdMob 광고 (네이티브) |

코드 생성: `hive_generator` + `build_runner` → `*.g.dart` 자동 생성

## 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점, 전역 notifier
├── l10n/
│   ├── app_ko.arb                   # 한국어 문자열 (템플릿)
│   ├── app_en.arb                   # 영어 문자열
│   ├── app_localizations.dart       # gen-l10n 자동 생성
│   ├── app_localizations_ko.dart    # gen-l10n 자동 생성
│   └── app_localizations_en.dart    # gen-l10n 자동 생성
├── models/
│   ├── article.dart / .g.dart       # Article HiveObject (typeId: 0)
│   ├── label.dart / .g.dart         # Label HiveObject (typeId: 2)
│   └── platform_meta.dart           # 플랫폼별 아이콘/라벨
├── services/
│   ├── database_service.dart        # Hive CRUD, 통계 조회, preferences
│   ├── notification_service.dart    # 주간 로컬 알림 스케줄
│   ├── share_service.dart           # OS 공유 수신 (Android/iOS)
│   ├── scraping_service.dart        # OG 메타 스크래핑
│   └── ad_service.dart              # AdMob 초기화, 광고 단위 ID 관리
├── screens/
│   ├── home_screen.dart             # 스와이프 카드 UI
│   ├── library_screen.dart          # 보관함 2열 그리드
│   ├── all_articles_screen.dart     # 전체 아티클 목록 + 다중선택
│   ├── bookmarked_articles_screen.dart # 북마크된 아티클 목록 + 다중선택
│   ├── label_detail_screen.dart     # 라벨별 아티클 목록 + 다중선택
│   ├── label_management_screen.dart # 라벨 CRUD + 알림 설정
│   ├── onboarding_screen.dart       # 온보딩 + 사용 방법 가이드
│   ├── settings_screen.dart         # 설정 (라벨 관리, 테마, 사용 방법)
│   └── theme_settings_screen.dart   # 다크/라이트/시스템 선택
├── widgets/
│   ├── article_card.dart            # 스와이프용 아티클 카드
│   ├── swipe_ad_card.dart           # 스와이프 덱용 네이티브 광고 카드
│   ├── inline_banner_ad.dart        # 리스트 인피드 네이티브 광고
│   ├── label_edit_sheet.dart        # 라벨 수정 바텀시트
│   └── share_label_sheet.dart       # Android 공유 시 라벨 선택
└── theme/
    ├── app_theme.dart               # AppTheme.light() / AppTheme.dark()
    └── design_tokens.dart           # Spacing, Radii, AppShadows, AppDurations, LabelColors
```

## 데이터 모델

### Article (`typeId: 0`)

| 필드 | 타입 | HiveField |
|------|------|-----------|
| url | String | 0 |
| title | String | 1 |
| thumbnailUrl | String? | 2 |
| platform | Platform (enum) | 3 |
| topicLabels | List\<String\> | 4 |
| isRead | bool | 5 |
| createdAt | DateTime | 6 |
| isBookmarked | bool | 7 (기본 false) |
| memo | String? | 8 (최대 100자 한줄 메모) |

`Platform` enum: `youtube, instagram, blog, x, tiktok, facebook, linkedin, github, reddit, threads, naverBlog, etc`  
`classifyPlatform(String url)` — URL 호스트 기반 자동 분류

### Label (`typeId: 2`)

| 필드 | 타입 | HiveField |
|------|------|-----------|
| name | String | 0 |
| colorValue | int | 1 (Color.value) |
| createdAt | DateTime | 2 |
| notificationEnabled | bool | 3 (기본 false) |
| notificationDays | List\<int\> | 4 (0=월 ~ 6=일) |
| notificationTime | String | 5 ("HH:mm", 기본 "09:00") |

모델 변경 시 반드시 `dart run build_runner build` 실행

## 서비스 계층

### DatabaseService

Hive Boxes: `articles` (Article), `labels` (Label), `preferences` (동적 key-value)

- `getAllArticles()` — 최신순 정렬
- `getUnreadArticles()` — 홈 스와이프용
- `getArticlesByLabel(String label)`
- `saveArticle()`, `deleteArticle()`, `markAsRead()`, `markAsUnread()`
- `toggleBookmark()` — 북마크 토글
- `updateMemo(article, memo)` — 메모 업데이트 (빈 문자열은 null로 변환)
- `getBookmarkedArticles()` — 북마크된 아티클 최신순
- `getBookmarkStats()` — 북마크 통계 `(total, read)`
- `getAllLabels()`, `getAllLabelObjects()`, `getLabelStats(String label)`, `getOverallStats()`
- `createLabel()`, `updateLabel()` — 이름 변경 시 아티클 일괄 업데이트
- `deleteLabel()`
- `updateLabelNotification()`, `getLabelsWithNotification()`
- `syncLabelsToAppGroup()` — iOS App Group UserDefaults에 라벨 JSON 동기화
- `hasSeenOnboarding` (getter) — 온보딩 완료 여부 (preferences box)
- `setOnboardingComplete()` — 온보딩 완료 플래그 저장
- `savedThemeMode` (getter) — 저장된 테마 모드 (0=system, 1=light, 2=dark)
- `saveThemeMode(ThemeMode)` — 테마 선택 Hive 영구 저장

### NotificationService

- `init()` — Android/iOS 알림 채널 초기화
- `requestPermission()` — 알림 권한 요청
- `scheduleForLabel(Label label)` — 요일별 weekly 반복 알림 등록
- `cancelForLabel(Label label)` — 특정 라벨 알림 취소
- `rescheduleAll()` — 앱 시작 시 모든 활성 라벨 알림 재등록
- 알림 ID 계산: `label.key * 10 + dayOfWeek`
- 알림 메시지: 로케일에 따라 한국어/영어 자동 전환 (`Platform.localeName` 기반)
- 한국어: `"읽지 않은 아티클 N개가 있어요!"` / `"모두 읽었어요! 🎉"`
- 영어: `"You have N unread articles!"` / `"All caught up! 🎉"`

### ShareService

- **Android**: MethodChannel `com.clib.clib/share` → Intent 텍스트 수신 → URL 정규식 추출
- **iOS**: App Group UserDefaults에서 JSON `{"url":"...", "labels":[...], "newLabels":[...]}` 파싱
- `processAndSave(url, labels)` — 스크래핑 후 저장, `articlesChangedNotifier.value++`로 홈화면 갱신

### AdService

- `initialize()` — `MobileAds.instance.initialize()`, 앱 시작 시 `main()`에서 호출
- `bannerAdUnitId` — 배너 광고 단위 ID (debug: Google 테스트 ID, release: 프로덕션 ID)
- `nativeAdUnitId` — 네이티브 광고 단위 ID (debug/release 분리)
- 테스트 광고 ID (debug):
  - iOS 네이티브: `ca-app-pub-3940256099942544/3986624511`
  - Android 네이티브: `ca-app-pub-3940256099942544/2247696110`
- 네이티브 광고는 `NativeTemplateStyle(TemplateType.medium)` 사용 (Flutter 측 렌더링, iOS 네이티브 코드 불필요)

### ScrapingService

- HTTP GET (User-Agent: iPhone Safari)
- `response.bodyBytes` + charset 감지 디코딩 (UTF-8 기본, `Content-Type` 헤더 charset 참조)
- `utf8.decode(allowMalformed: true)`로 멀티바이트 문자 깨짐 방지
- `og:title`, `og:image`, `og:description` 추출
- Fallback: `<title>` → URL 자체

## 전역 상태 (`lib/main.dart`)

```dart
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final articlesChangedNotifier = ValueNotifier<int>(0); // 아티클 추가/삭제 시 increment
```

- `main()`에서 `DatabaseService.savedThemeMode`로 저장된 테마를 `themeModeNotifier`에 적용 (앱 재시작 후에도 유지)
- `ThemeSettingsScreen`에서 선택 변경 시 `DatabaseService.saveThemeMode()` 즉시 호출
- `ClibApp`은 `localizationsDelegates` + `supportedLocales` 설정으로 다국어 지원
- `ClibApp`은 `DatabaseService.hasSeenOnboarding`으로 초기 화면 분기 (온보딩 or 메인)
- Named route: `/main` → `MainScreen`
- `MainScreen`은 `WidgetsBindingObserver`를 구현해 `AppLifecycleState.resumed` 시 `_checkPendingShares()` 호출
- Android: `ShareLabelSheet.show()` 표시 → 사용자가 라벨 선택 후 저장
- iOS: `ShareService.checkPendingShares()` 자동 처리

## 화면별 주요 사항

### HomeScreen

- `CardSwiper(isLoop: true)` — 덱 형태 카드 스택 (`backCardOffset: Offset(0, 36)`, `scale: 0.95`)
- 오른쪽 스와이프 → `DatabaseService.markAsRead()` + `addPostFrameCallback(_loadArticles)`
- 왼쪽 스와이프 → 나중에 (스택 아래로 이동)
- 스와이프 중 카드 테두리: 오른쪽 `AppColors.swipeRead` (Sage Green), 왼쪽 `AppColors.swipeSkip` (Muted Rose)
- `_loadArticles()`: 컨트롤러 교체 시 `_pendingDispose` 리스트에 모아둔 뒤 `addPostFrameCallback`에서 일괄 dispose (try-catch로 이중 dispose 방지)
- 아티클 탭 → 외부 브라우저 오픈, 롱프레스 → 통합 액션 시트 (북마크/메모/라벨편집/브라우저)
- 라벨 필터: 가로 스크롤 칩 + 확장 버튼 → `ConstrainedBox(maxHeight: 160)` + `SingleChildScrollView`로 스크롤 가능한 그리드

### LibraryScreen

- 2열 GridView, index 0 = "전체" 카드, index 1 = "북마크" 카드, 이후 라벨 카드
- 북마크 카드: `Icons.bookmark_rounded` 아이콘 + 전체/안읽음 뱃지 → `BookmarkedArticlesScreen`
- 라벨 카드: 원형 프로그레스바에 퍼센트 표시 + `_statBadge`로 전체/안읽음 수치 뱃지

### AllArticlesScreen / LabelDetailScreen

세 화면 모두 동일한 인터랙션 패턴 (`BookmarkedArticlesScreen` 포함):
- 행 탭 → 아티클을 외부 브라우저에서 열기 (1차 액션)
- 행 롱프레스 → 바텀시트 (북마크 토글, 메모 추가/편집, 읽음/안읽음 변경, 브라우저 열기, 삭제)
- 메타 줄 표시: 읽음 시 `secondary` 색 체크 아이콘 + 북마크 시 `secondary` 색 북마크 아이콘
- 메모 표시: 메타 줄 아래 이탤릭 한 줄 텍스트 (`onSurfaceVariant` 70% alpha)
- 다중선택: `_isSelecting` + `Set<dynamic> _selectedKeys` (Hive `article.key`)
- 탭 전환 시 `_selectedKeys.clear()`
- AppBar: 일반 모드(checklist 아이콘) / 선택 모드(개수 + 전체선택 체크박스 + 취소)
- 하단 바 (선택 시): 1행 북마크 추가/해제, 2행 안읽음/읽음/삭제 일괄 처리
- 메모 입력: 바텀시트 (핸들바 + 제목 + filled TextField + 저장/삭제 버튼)

### LabelManagementScreen

- 라벨 목록, 추가/수정/삭제
- 빈 상태: chip 스타일 "신규 라벨 추가" 버튼 표시
- 알림 설정: 각 라벨에서 활성화 토글 + 요일 다중선택 칩 + TimePicker

### OnboardingScreen

- 3페이지 PageView (링크 저장 → 스와이프 → 라이브러리)
- `isGuideMode: false` (기본) — 첫 실행 온보딩, 완료 시 `pushReplacementNamed('/main')` + `setOnboardingComplete()`
- `isGuideMode: true` — 설정 > 사용 방법에서 진입, 완료 시 `Navigator.pop()`
- 디자인: 원형 아이콘 배경 (secondary 8% alpha) + 힌트 칩 (surfaceContainer) + 도트 인디케이터
- 건너뛰기 버튼 (마지막 페이지 제외), 다음/시작하기 FilledButton (secondary 컬러)

## 폰트

- Pretendard (v1.3.9) — `ThemeData.fontFamily`로 전역 적용
- 5개 weight: Regular(400), Medium(500), SemiBold(600), Bold(700), ExtraBold(800)
- 에셋 경로: `assets/fonts/Pretendard-{Weight}.otf`

## 디자인 시스템

디자인 방향: **Calm & Refined** (Notion, Things 3 영감)

### 컬러 시스템 (`AppColors`)

| 토큰 | Light | Dark |
|------|-------|------|
| Primary | `#2C2C3A` Warm Charcoal | `#A8B5D6` Soft Lavender |
| Secondary (accent) | `#5BA67D` Sage Green | `#7DC4A0` Soft Sage |
| Error | `#E8726E` Muted Rose | `#E8857F` Soft Rose |
| Background | `#F8F7F4` Warm Off-White | `#141416` Warm Black |
| Surface | `#FFFFFF` | `#1C1C1E` |
| SurfaceContainer | `#F2F1EE` | `#242426` |
| OnSurface | `#1C1C1E` | `#E5E5EA` |
| OnSurfaceVariant | `#8E8E93` | `#8E8E93` |
| `swipeRead` | `#5BA67D` Sage Green (오른쪽 스와이프 읽음) | |
| `swipeSkip` | `#E8726E` Muted Rose (왼쪽 스와이프 나중에) | |

### 디자인 토큰 (`design_tokens.dart`)

- **Spacing**: `xs(4)`, `sm(8)`, `md(12)`, `lg(16)`, `xl(20)`, `xxl(24)`, `xxxl(32)`
- **Radii**: `sm(8)`, `md(12)`, `lg(16)`, `xl(20)`, `full(100)` + 대응 `BorderRadius` 상수
- **AppShadows**: `card(isDark)`, `swipeCard(isDark)`, `navigation(isDark)` — 이중 레이어 그림자
- **AppDurations**: `fast(150ms)`, `medium(250ms)`, `slow(350ms)`
- **LabelColors.presets**: 10색 프리셋 (채도 낮춘 버전, 라벨 생성 시 사용)

### UI 패턴

- **하단 네비게이션**: 플로팅 필 스타일 (양쪽 24px 마진, `Radii.borderFull`, 아이콘 + 점 인디케이터)
- **카드 리스트**: Divider 대신 개별 카드 (`surface` + `AppShadows.card` + `Radii.borderLg`)
- **설정 화면**: iOS 스타일 그룹 컨테이너 (아이콘 배경 32x32)
- **바텀시트**: 36px 핸들바, 둥근 상단 모서리, `isScrollControlled: true` + `viewInsets.bottom` 패딩 (키보드 대응)
- **빈 상태**: 원형 배경 + 아이콘, accent 컬러 사용
- **스와이프 카드 북마크**: 우상단 frosted-glass 스타일 아이콘 (`Colors.black` 30% alpha 배경)

## 앱 아이콘 & 스플래시

### 아이콘 원본
- 소스: `~/Downloads/AppIcons/` (appicon.co에서 생성)
- 디자인: 카드 스택 아이소메트릭 + 우상단 Sage Green 북마크 탭

### iOS 아이콘
- 경로: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- 52개 사이즈 (20px ~ 1024px) 모두 교체 완료

### iOS 스플래시 (`LaunchScreen.storyboard`)
- `LaunchImage.imageset`에 400×1200 이미지 (`@1x/@2x/@3x` 동일 파일)
- `contentMode="scaleAspectFit"` + 4방향 edge 제약 (전체 화면)
- 배경색: `#ECE5D5` (이미지 배경색과 동일하게 맞춰 사이드 바 자연스럽게 처리)

### Android 아이콘
- 경로: `android/app/src/main/res/mipmap-{density}/ic_launcher.png`
- mdpi(48) / hdpi(72) / xhdpi(96) / xxhdpi(144) / xxxhdpi(192) 5개 교체 완료

### Android 스플래시 (`launch_background.xml`)
- `drawable/launch_image.png` (400×1200) + `android:gravity="center"`
- 배경색: `#ECE5D5`
- `values-night/styles.xml` LaunchTheme 부모를 `Theme.NoTitleBar`로 변경 (기존 `Theme.Black`이 다크모드에서 검정 배경 유발)

## 네이티브 설정

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

- `MainActivity.launchMode = singleTop`
- Intent filter: `ACTION_SEND`, `mimeType="text/plain"` (URL 공유 수신)
- `android:localeConfig="@xml/locales_config"` — Android 13+ 앱별 언어 설정 지원
- `res/xml/locales_config.xml` — 지원 로케일: `ko`, `en`

### iOS (`AppDelegate.swift`)

- App Group: `group.com.clib.clib`
- MethodChannel: `com.clib.clib/share`
- 지원 메서드: `getSharedURLs`, `clearSharedURLs`, `syncLabels`
- `UNUserNotificationCenter` delegate 설정
- `Info.plist`에 `CFBundleLocalizations`: `ko`, `en` — iOS 앱별 언어 설정 지원

## 다국어 (i18n)

- 방식: Flutter 공식 `gen-l10n` (ARB 기반)
- 설정 파일: `l10n.yaml` (템플릿: `app_ko.arb`)
- 지원 로케일: `ko` (한국어, 기본), `en` (영어, fallback)
- 로케일 결정: 시스템 언어 설정 자동 감지 — 한국어면 ko, 그 외 en
- 앱별 언어 설정: iOS (설정 > Clib > 언어), Android 13+ (설정 > 앱 > Clib > 언어)
- UI 문자열: `AppLocalizations.of(context)!.keyName` 패턴으로 접근
- NotificationService: BuildContext 없이 `dart:io`의 `Platform.localeName`으로 로케일 판단
- 문자열 추가 시: `app_ko.arb` + `app_en.arb` 모두에 키 추가 → `dart run build_runner build` 실행
- 파라미터 문자열: ARB의 ICU 메시지 포맷 사용 (예: `"selectedCount": "{count}개 선택됨"`)

## 개발 컨벤션

- 언어: 한국어 (주석, 커밋 메시지)
- UI 텍스트: 하드코딩 금지, 반드시 ARB 파일(`lib/l10n/app_ko.arb`, `app_en.arb`)에 정의 후 `AppLocalizations` 사용
- Flutter 표준 구조 준수
- 모델 변경 시 `dart run build_runner build` 필수
- 분석: `flutter analyze` — No issues found 유지
- 릴리즈 빌드 테스트 (실기기): `flutter run --release`
