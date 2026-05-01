# Architecture

> Clib 데이터 모델·서비스·전역 상태·부팅 흐름·네이티브 설정 정리.
> 함정·운영 규칙은 `/CLAUDE.md`. 코드 컨벤션·디자인 토큰·i18n 워크플로는 `conventions.md`.

## 1. 폴더 구조

```
lib/
├── main.dart                  앱 진입점, MultiBlocProvider(ThemeCubit, AuthCubit)
├── l10n/                      ARB(10 로케일) + gen-l10n 산출물(app_localizations*.dart)
├── blocs/                     화면 단위 Cubit + 1개 Bloc (HomeBloc)
│   └── theme/ auth/ onboarding/ library/ label_management/
│       article_list/ add_article/ home/
├── models/                    Article, Label (Hive), platform_meta
├── services/                  아래 §3 참조
├── state/                     app_notifiers (전역 articlesChangedNotifier 등)
├── screens/                   home, library, all_articles, bookmarked_articles,
│                              label_detail, label_management, onboarding,
│                              settings, theme_settings
├── widgets/                   article_card, swipe_ad_card, inline_banner_ad,
│                              article_list_view/item, bulk_action_bar,
│                              bulk_delete_confirm, article_actions_sheet,
│                              memo_sheet, label_edit_sheet, share_label_sheet,
│                              add_article_sheet, home_overlay_guide
└── theme/                     app_theme(Light/Dark), design_tokens

test/                          unit + bloc tests (flutter_test 기반, bloc_test 미도입)
integration_test/              실기기 시나리오 (Home swipe, bookmark 등)
docs/                          본 문서·conventions·security 등 reference
```

## 2. 데이터 모델 (Hive)

`HiveField` 번호 재사용 금지. 추가만 가능. 모델 변경 시 `dart run build_runner build --delete-conflicting-outputs`.

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

### Hive Boxes

`articles`, `labels`, `preferences`(동적 key-value: themeMode, hasSeenOnboarding 등). 모두 **AES 암호화** 적용 — `HiveCipherService`가 `flutter_secure_storage` 키스토어에서 키를 읽어와 `Hive.openBox(..., encryptionCipher: ...)`로 연다 (M-7).

## 3. 서비스 계층

| 서비스 | 역할 |
|--------|------|
| **DatabaseService** | Hive CRUD, 통계, 테마/온보딩 preferences, 북마크/메모, 라벨 정규화. **모든 mutation 직후 `articlesChangedNotifier`/`labelsChangedNotifier` 발사**(Cubit/Bloc 자동 재로드). `skipSync` 플래그로 동기화 억제 가능 |
| **HiveCipherService** | `flutter_secure_storage` 기반 32B AES 키 발급/조회. 첫 실행 시 생성, 이후 재사용 |
| **NotificationService** | 주간 weekly 반복 알림. ID = `label.key * 10 + dayOfWeek`. 메시지는 `Platform.localeName` 기반 다국어(BuildContext 없이) |
| **ShareService** | Android: MethodChannel `com.jaehyun.clib/share`. iOS: App Group `group.com.jaehyun.clib.share` UserDefaults. `processAndSave()`가 스크래핑 후 `DatabaseService.saveArticle()` 위임(notifier 발사는 DB 서비스 내부) |
| **ScrapingService** | HTTP(User-Agent: iPhone Safari) + charset 감지 디코딩(`utf8.decode(allowMalformed: true)`). `og:title/image/description` → `<title>` → URL fallback. **SSRF/OOM 가드**: IP literal·redirect 차단 + 응답 크기 상한 (M-5) |
| **AdService** | AdMob 초기화. debug=Google 테스트 ID, release=프로덕션. 네이티브는 `NativeTemplateStyle(TemplateType.medium)` Flutter 렌더링. `adInterval` 단일 출처 |
| **AuthService** | Firebase Auth + Google Sign-In. 로그인/로그아웃/탈퇴. Firebase App Check(Play Integrity / App Attest) 활성 (M-10) |
| **FirestoreService** | `users/{uid}/articles`, `users/{uid}/labels` 컬렉션 맵핑. 서버 타임스탬프. 방어 캐스트 + null-skip(M-3) |
| **SyncService** | 로그인 시 snapshot listener → 로컬↔리모트 머지. 동시 스냅샷은 pending 버퍼에 큐잉. tombstone(`deletedAt`)으로 삭제 전파. 계정 전환 시 Hive 박스 wipe(H-3) |
| **DemoDataService** | 앱스토어 스크린샷용 시드 데이터. 기존 데이터가 있으면 미실행 |

**중요**: 화면/위젯/Cubit/Bloc은 `Hive.box(...)`나 `FirestoreService` 직접 접근 금지. `DatabaseService`만 단일 경로.

## 4. 전역 상태

상태 관리는 `flutter_bloc`(기본 Cubit, 이벤트 소싱이 필요한 화면만 Bloc).

### 4.1 전역 BlocProvider (`lib/main.dart` MultiBlocProvider)

| Bloc/Cubit | 역할 | lazy |
|---|---|---|
| `ThemeCubit` | `ThemeMode` + `DatabaseService.saveThemeMode` 영속화 | true |
| `AuthCubit` | `FirebaseAuth.idTokenChanges` 구독 + `SyncService.init/dispose` 소유 | **false** |

그 외(`OnboardingCubit`, `LibraryCubit`, `LabelManagementCubit`, `ArticleListCubit`, `AddArticleCubit`, `HomeBloc`)는 화면 진입 시 `BlocProvider`로 주입.

### 4.2 전역 ValueNotifier (`lib/state/app_notifiers.dart`)

```dart
final articlesChangedNotifier = ValueNotifier<int>(0); // DB 변경 시 increment
final labelsChangedNotifier   = ValueNotifier<int>(0);
```

발사 위치는 **`DatabaseService` mutation + `SyncService` 원격 스냅샷 적용 분기 단독**. 그 외(Cubit/Bloc/`ShareService`) 직접 발사 금지(중복 reload). 각 Cubit/Bloc은 `addListener(_onChanged)` ↔ `close()`에서 `removeListener` 짝.

`lib/main.dart`는 호환을 위해 `state/app_notifiers.dart`를 re-export — `package:clib/main.dart show ...` 경로도 계속 동작.

## 5. 부팅 흐름

`main()`:
1. Firebase init
2. `DatabaseService.init()` (Hive 박스 open + 암호화 키 부트스트랩)
3. `NotificationService.init()` + `rescheduleAll()`
4. AdMob lazy init (`addPostFrameCallback`에서)
5. `runApp(ClibApp)`

`ClibApp`:
- `MultiBlocProvider(ThemeCubit, AuthCubit)` → `BlocBuilder<ThemeCubit, ThemeMode>` → `MaterialApp(themeMode)`
- `hasSeenOnboarding`로 초기 화면 분기 (Onboarding ↔ MainScreen)

`MainScreen`:
- `WidgetsBindingObserver`로 `AppLifecycleState.resumed` 시 `_checkPendingShares()` 호출 (Android `ShareLabelSheet` / iOS `ShareService.checkPendingShares()`)

## 6. 화면별 주요 로직

- **HomeScreen** (`HomeBloc` — 시리즈 유일 Bloc): 이벤트 소싱 — `HomeLoadDeck/SwipeRead/SwipeLater/FilterLabelsChanged/ToggleBookmark/UpdateMemo/ToggleExpand`. `CardSwiper(isLoop: true)` 덱. 우=읽음, 좌=나중에. 스와이프 중 테두리 = `AppColors.swipeRead/swipeSkip`. 컨트롤러는 `_HomeBody` 로컬 SSOT(Bloc state 진입 금지). `state.deckVersion`을 `CardSwiper(key: ValueKey(...))`로 사용해 인덱스 out-of-range 방지. `AdService.adInterval` 카드마다 `SwipeAdCard`. 첫 실행 시 `home_overlay_guide`.
- **LibraryScreen** (`LibraryCubit`): 2열 GridView. 인덱스 0="전체", 1="북마크", 이후 라벨 카드(원형 프로그레스). `articlesChangedNotifier` + `labelsChangedNotifier` 양쪽 구독.
- **AllArticles / Bookmarked / LabelDetail** (`ArticleListCubit` 재사용): `ArticleListSource`로 분기 (`All`/`Bookmarked`/`ByLabel`). 공통 위젯 `ArticleListView` + `ArticleListItem(accentColor)` + `BulkActionBar` + `showBulkDeleteConfirm`. `selectedKeys: List<int>`(Hive key는 int). `AdService.adInterval`마다 `InlineBannerAd`.
- **LabelManagementScreen** (`LabelManagementCubit`): 라벨 CRUD + 알림(요일 칩 + TimePicker).
- **OnboardingScreen** (`OnboardingCubit`): 3페이지. `isGuideMode: false`(첫 실행 → `setOnboardingComplete()` + `/main`), `true`(설정에서 진입 → `Navigator.pop()`).
- **AddArticleSheet** (`AddArticleCubit`): URL 검증 + 라벨 토글 + 신규 라벨 + 저장. `urlError` 센티넬 / `saveFailure` flag로 에러 채널 분리.

## 7. 네이티브 설정

### Android (`android/app/`)

- Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`.
- `MainActivity.launchMode = singleTop` + Intent filter `ACTION_SEND` `text/plain`.
- `android:localeConfig="@xml/locales_config"` (Android 13+ 앱별 언어).
- AdMob App ID: `AndroidManifest.xml` meta-data `com.google.android.gms.ads.APPLICATION_ID`.
- `android:allowBackup="false"` (M-7 — 외부 백업으로 암호화 우회 차단).
- 스플래시: `drawable/launch_image.png` + `android:gravity="center"`, 배경 `#ECE5D5`. `values-night/styles.xml` LaunchTheme 부모는 `Theme.NoTitleBar`.
- Signing: `key.properties` 추적 제외. 로테이션 절차는 `android-signing-rotation.md`.

### iOS (`ios/Runner/`)

- App Group: `group.com.jaehyun.clib.share`.
- MethodChannel `com.jaehyun.clib/share`: `getSharedURLs`, `clearSharedURLs`, `syncLabels`.
- `UNUserNotificationCenter` delegate 설정.
- `Info.plist`: `CFBundleLocalizations`(전 로케일), `GADApplicationIdentifier`(AdMob iOS App ID).
- 스플래시: `LaunchImage.imageset` 400×1200, `scaleAspectFit` + 4방향 edge, 배경 `#ECE5D5`.

## 8. 패키지 (`pubspec.yaml`)

핵심: `hive`/`hive_flutter` (+`hive_generator` dev), `flutter_bloc` + `equatable`, `firebase_core`/`firebase_auth`/`cloud_firestore`/`firebase_app_check`/`google_sign_in`, `flutter_local_notifications` + `timezone` + `flutter_timezone`, `flutter_card_swiper`, `google_mobile_ads`, `url_launcher`, `http` + `html`, `flutter_secure_storage`. 정확한 버전·dev 의존성은 `pubspec.yaml` 직접 참조.

`flutter: ">=3.32.0"` floor (`RadioGroup<T>` 등 사용).
