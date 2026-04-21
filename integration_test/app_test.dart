import 'package:integration_test/integration_test.dart';

import 'helpers/test_harness.dart';
import 'scenarios/home_smoke.dart';

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
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await TestHarness.bootstrap();

  registerHomeSmokeTests();
}
