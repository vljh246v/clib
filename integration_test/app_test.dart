import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_harness.dart';
import 'scenarios/bookmark_toggle.dart';
import 'scenarios/home_smoke.dart';
import 'scenarios/swipe_read.dart';

/// integration_test 엔트리.
///
/// 시나리오는 `scenarios/*.dart`에 `registerXxxTests()` 형태로 정의하고
/// 여기서 한 번에 등록한다. 실행:
///
/// ```
/// flutter test integration_test/app_test.dart -d <device-id>
/// ```
///
/// 자세한 실행 가이드: `doc/bloc-migration/integration-test-guide.md`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `bootstrap()` 은 `setUpAll` 에서 호출한다.
  // `main()` 최상위에서 `await` 하면 test binding 이 활성화되기 전에 hang 될 수
  // 있어 실기기에서 스플래시 단계에 멈춘다.
  setUpAll(() async {
    await TestHarness.bootstrap();
  });

  registerHomeSmokeTests();
  registerSwipeReadTests();
  registerBookmarkToggleTests();
}
