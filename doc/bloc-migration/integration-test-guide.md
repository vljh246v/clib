# Integration Test 실행 가이드

> `integration_test/` 자동화 스모크. PR 11 §3 실기기 회귀 17 항목 중
> 앱 내 인터랙션 시나리오를 자동화하기 위한 부트스트랩.

---

## 디렉토리 구조

```
integration_test/
├── app_test.dart                   # 엔트리 — binding ensure + bootstrap + scenario 등록
├── helpers/
│   └── test_harness.dart           # bootstrap 래퍼 + resetAll + seedArticle/Label + pumpUntil
└── scenarios/
    └── home_smoke.dart             # PoC #1 — 시드 1건 + 홈 카드 렌더 확인
```

---

## 사전 조건

1. **실기기/에뮬레이터 연결 필수**. integration_test는 순수 Dart 테스트가 아니라
   실제 Flutter 엔진 위에서 돈다.
   ```bash
   flutter devices
   ```
   Android: `adb devices`, iOS: `xcrun simctl list devices booted`.

2. **Firebase 설정 파일**이 프로젝트에 있어야 한다 (`google-services.json` /
   `GoogleService-Info.plist`). `bootstrap(forTest: true)`도
   `Firebase.initializeApp()`은 호출한다(AuthCubit의 `FirebaseAuth` 구독 때문).
   로그인은 하지 않으므로 네트워크만 가능하면 된다.

3. **Hive 박스 격리**. 테스트는 실기기의 실제 Hive path를 사용하므로 실행 후
   앱 상태가 초기화된다. 실 사용자 데이터가 있으면 **같은 기기에서 실행 금지** —
   테스트 전용 기기 사용 권장.

---

## 실행 명령

```bash
# 기본 실행
flutter test integration_test/app_test.dart

# 특정 기기 지정
flutter test integration_test/app_test.dart -d <device-id>

# 예시: iPhone 15 Pro 시뮬레이터
flutter test integration_test/app_test.dart -d "iPhone 15 Pro"

# 예시: 실기기 Android
flutter test integration_test/app_test.dart -d <adb-serial>
```

실행 후 `All tests passed!` 메시지를 확인한다. 실패 시 `expect` 메시지와
위젯 트리 덤프가 터미널에 표시된다.

---

## 동작 원리

1. `app_test.dart::main()` 이 `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
   호출.
2. `TestHarness.bootstrap()` → `app.bootstrap(forTest: true)` 호출 →
   `Firebase.initializeApp()` + `DatabaseService.init()` + `skipSync=true`.
   NotificationService / AdService / DemoDataService / ShareService 는 건너뜀.
3. 각 `testWidgets` 는 `setUp` 에서 `TestHarness.resetAll()`(3박스 clear)을
   호출 — 직접 `setUp` 선언하거나 필요 시 testWidgets 내부 첫 줄.
4. 시드는 `TestHarness.seedArticle/seedLabel` 로 Hive 에 직접 쓴다
   (`DatabaseService.saveArticle` 우회 → Firestore 경로 + notifier 트리거 회피).
5. `onboardingComplete` / `homeGuideComplete` 플래그는 `DatabaseService`의
   setter 로 설정 — 온보딩 화면 건너뛰고 바로 MainScreen 진입.
6. `tester.pumpWidget(const ClibApp())` 후 `TestHarness.pumpUntil(tester)`
   로 폴링. `pumpAndSettle` 이 `CustomPaint` + `BlocBuilder` 조합에서
   수렴하지 않는 이슈(PR 11 §2.6에서 관측)를 회피한다.
7. `expect` 로 화면 상태 검증.

---

## 신규 시나리오 추가

1. `integration_test/scenarios/<name>.dart` 신설.
2. `void registerXxxTests()` 함수 내부에 `group()` + `testWidgets()` 작성.
3. `integration_test/app_test.dart::main()` 에서 `registerXxxTests()` 호출.

예시:
```dart
// integration_test/scenarios/bulk_action.dart
void registerBulkActionTests() {
  group('Bulk action', () {
    testWidgets('5건 선택 후 일괄 삭제', (tester) async {
      await TestHarness.resetAll();
      for (var i = 0; i < 5; i++) {
        await TestHarness.seedArticle(url: 'u$i', title: 't$i');
      }
      await DatabaseService.setOnboardingComplete();
      await DatabaseService.setHomeGuideComplete();

      await tester.pumpWidget(const ClibApp());
      await TestHarness.pumpUntil(tester);

      // 라이브러리 탭 → 전체 → 길게 눌러 선택 모드 → 전체 선택 → 삭제
      // ...
    });
  });
}
```

---

## 현재 커버 / 미커버

**커버(1 시나리오)**:
- Home smoke: 시드 1건 + onboarding 완료 → 홈 카드 제목 렌더

**우선 확장 후보** (`pr-11-cleanup.md` §3.2 번호):
- 3.1 홈 스와이프 (오른쪽 = 읽음) — CardSwiperController 직접 호출
- 4.5 홈 롱프레스 → 북마크 토글
- 6.9 일괄 삭제 (PR 11 핵심 회귀)
- 7.1 라벨 CRUD

**미커버(수동 유지)**:
- 시스템 공유 시트 (2.4 / 2.5) — `patrol` 필요
- Google/Apple 로그인 (9.1 / 9.2) — OAuth 리다이렉트
- 알림 수신 (7.3) — 기기 시간 조작 또는 test hook 필요
- 메모리 부족 재개 (10.2) — OS 수준
- Firestore 양방향 동기화 (9.3~9.5) — emulator 또는 멀티 기기

---

## 알려진 리스크

1. **`pumpAndSettle` hang**: widget_test 에서 `LibraryScreen` + 시드 라벨 1개+
   조합이 5분+ 수렴 실패. integration_test 는 실제 프레임 루프라 다를 수 있지만
   재현 시 `pumpUntil` 의 `step`/`timeout` 를 조정.
2. **AdMob 위젯**: `bootstrap(forTest: true)` 에서 `AdService.initialize()`
   스킵 → `SwipeAdCard`/`InlineBannerAd` 는 빈 공간만 점유(크래시 없음 기대).
   검증 실패 시 find 로직이 광고 위치를 건너뛰도록 조정 필요.
3. **Firebase Auth 구독**: `AuthCubit` 가 `FirebaseAuth.idTokenChanges`를
   listen 하므로 Firebase init 필수. 완전 오프라인 테스트 불가.

---

## CI 확장 (별도 PR 권장)

- GitHub Actions `macos-latest` runner + `reactivecircus/android-emulator-runner`.
- iOS runner 는 Xcode + 시뮬레이터 부팅 비용 큼 → Android 먼저.
- 워크플로 YAML 은 이번 PR 범위에서 제외.
