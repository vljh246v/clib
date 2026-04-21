import 'package:hive/hive.dart';

import 'package:clib/main.dart'
    show articlesChangedNotifier, labelsChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

/// 테스트용 Hive 부트스트랩 헬퍼.
///
/// `setUpAll`/`setUp`/`tearDownAll`에서 호출해 path_provider 우회 + 어댑터 등록 +
/// 박스 오픈/클리어/삭제를 한 곳에서 처리한다. `DatabaseService.skipSync`를 켜서
/// 테스트 중 Firestore 동기화가 시도되지 않도록 한다.
///
/// 기존 블록 테스트(`test/blocs/*_test.dart`)는 각자 `test_hive_<name>`로 격리
/// 경로를 쓰므로, [pathName]도 테스트 파일마다 고유하게 지정한다.
class HiveTestHarness {
  HiveTestHarness(this.pathName);

  final String pathName;

  String get path => '.dart_tool/test_hive_$pathName';

  Future<void> setUpAll() async {
    Hive.init(path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ArticleAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PlatformAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LabelAdapter());
    }
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
    await Hive.openBox('preferences');
  }

  Future<void> setUp() async {
    DatabaseService.skipSync = true;
    await Hive.box<Article>('articles').clear();
    await Hive.box<Label>('labels').clear();
    await Hive.box('preferences').clear();
    articlesChangedNotifier.value = 0;
    labelsChangedNotifier.value = 0;
  }

  Future<void> tearDownAll() async {
    await Hive.deleteFromDisk();
  }

  Future<Article> seedArticle({
    required String url,
    required String title,
    List<String> labels = const [],
    bool isRead = false,
    bool isBookmarked = false,
  }) async {
    final a = Article()
      ..url = url
      ..title = title
      ..platform = Platform.etc
      ..topicLabels = List.of(labels)
      ..isRead = isRead
      ..isBookmarked = isBookmarked
      ..createdAt = DateTime.now();
    await Hive.box<Article>('articles').add(a);
    return a;
  }

  Future<Label> seedLabel(String name, {int color = 0xFF888888}) async {
    final l = Label()
      ..name = name
      ..colorValue = color
      ..createdAt = DateTime.now();
    await Hive.box<Label>('labels').add(l);
    return l;
  }
}
