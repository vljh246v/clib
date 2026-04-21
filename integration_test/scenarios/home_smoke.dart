import 'package:flutter_test/flutter_test.dart';

import 'package:clib/main.dart';
import 'package:clib/services/database_service.dart';

import '../helpers/test_harness.dart';

/// PoC 시나리오 #1 — 앱 부팅 + 홈 카드 렌더링 스모크.
///
/// 검증:
/// 1. `bootstrap(forTest: true)` 경로로 앱이 크래시 없이 뜬다.
/// 2. 시드 1건 + `hasSeenOnboarding=true` 상태에서 `MainScreen` 진입.
/// 3. 시드 아티클 제목이 홈 카드에 보인다.
///
/// 실제 스와이프 제스처는 `CardSwiper`의 제스처 인식이 integration_test
/// 환경에서 까다로우므로 이 PoC에서는 렌더 확인까지만 한다. 스와이프는
/// 다음 단계(`HomeBloc` add 이벤트 또는 CardSwiperController swipe 직접 호출)
/// 로 확장한다.
void registerHomeSmokeTests() {
  group('Home smoke', () {
    setUp(() => TestHarness.resetAll());

    testWidgets('시드 1건 + onboarding 완료 상태에서 홈에 아티클 제목이 보인다',
        (tester) async {
      const title = 'Integration Test PoC Article';
      await TestHarness.seedArticle(
        url: 'https://example.com/poc',
        title: title,
      );
      await DatabaseService.setOnboardingComplete();
      await DatabaseService.setHomeGuideComplete();

      await tester.pumpWidget(const ClibApp());
      await TestHarness.pumpUntil(
        tester,
        until: find.text(title),
        timeout: const Duration(seconds: 8),
      );

      expect(
        find.text(title),
        findsOneWidget,
        reason: 'Home 덱에 시드 아티클이 렌더되지 않았습니다',
      );
    });
  });
}
