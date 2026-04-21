import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:clib/main.dart' as app;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/state/app_notifiers.dart';

/// integration_test 공용 부트스트랩.
///
/// - `app.bootstrap(forTest: true)` 호출 → Firebase + Hive 초기화 + skipSync=true.
/// - 각 테스트 `setUp`에서 `resetAll()` 호출해 3박스 클리어 + 온보딩 상태 리셋.
/// - 시드는 `seedArticle()` / `seedLabel()` 헬퍼 사용 (Hive 직접 쓰기 +
///   `articlesChangedNotifier` 수동 발사).
///
/// `DatabaseService.saveArticle` 등을 거치지 않고 직접 Hive box에 쓰는 이유:
/// 테스트에서는 시드 단계가 Firestore 동기화나 notifier 트리거를 타지 않도록
/// 격리하고, 앱 실행 후 Cubit/Bloc이 초기 load() 시점에 박스를 자연스럽게
/// 읽도록 하기 위함.
class TestHarness {
  TestHarness._();

  static Future<void> bootstrap() async {
    await app.bootstrap(forTest: true);
  }

  /// 3박스 클리어 + `skipSync` 재설정 + 두 notifier 수동 발사.
  ///
  /// 앱이 실행 중인 상태에서 호출해도 안전(박스는 이미 open 되어 있음).
  /// `Hive.box.clear()` 는 `DatabaseService` 를 우회하므로 notifier 를 직접
  /// 발사해야 이미 생성된 Cubit/Bloc 이 빈 상태를 반영한다.
  /// 이후 테스트 코드는 `tester.pump()` 또는 `pumpUntil()` 로 재빌드를 기다린다.
  static Future<void> resetAll() async {
    await Hive.box<Article>('articles').clear();
    await Hive.box<Label>('labels').clear();
    await Hive.box('preferences').clear();
    DatabaseService.skipSync = true;
    articlesChangedNotifier.value++;
    labelsChangedNotifier.value++;
  }

  static Future<Article> seedArticle({
    required String url,
    required String title,
    List<String> labels = const [],
    bool isRead = false,
    bool isBookmarked = false,
    Platform? platform,
  }) async {
    final a = Article()
      ..url = url
      ..title = title
      ..platform = platform ?? classifyPlatform(url)
      ..topicLabels = List.of(labels)
      ..isRead = isRead
      ..isBookmarked = isBookmarked
      ..createdAt = DateTime.now();
    await Hive.box<Article>('articles').add(a);
    return a;
  }

  static Future<Label> seedLabel(String name, {int color = 0xFF888888}) async {
    final l = Label()
      ..name = name
      ..colorValue = color
      ..createdAt = DateTime.now();
    await Hive.box<Label>('labels').add(l);
    return l;
  }

  /// `pumpAndSettle` 대체. 최대 [timeout] 동안 `pump(Duration)` 반복 호출.
  ///
  /// `pumpAndSettle` 이 `CustomPaint` + `BlocBuilder` 조합에서 수렴하지 않는
  /// 이슈(PR 11 §2.6 widget_test에서 관측)를 회피한다.
  ///
  /// [until] 이 지정되면 해당 Finder 가 일치하는 즉시 반환(조기 종료).
  /// 타임아웃 도달 시 실패하지 않고 그대로 반환 — 검증은 이후 `expect`가 담당.
  static Future<void> pumpUntil(
    WidgetTester tester, {
    Finder? until,
    Duration step = const Duration(milliseconds: 100),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (until != null && tester.any(until)) return;
    }
  }
}
