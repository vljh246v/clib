import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/blocs/library/library_cubit.dart';
import 'package:clib/blocs/library/library_state.dart';
import 'package:clib/main.dart'
    show articlesChangedNotifier, labelsChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';

/// LibraryCubit은 `DatabaseService`(Hive) + 두 전역 notifier에 의존한다.
/// - path_provider 우회를 위해 `Hive.init(path)`로 직접 초기화.
/// - 필요 박스(`articles`, `labels`)를 미리 연다.
/// - `load()`가 내부에 `await`가 없어 동기 실행되므로, 생성자 직후
///   `state`는 이미 로드 완료 상태. 초기 `isLoading=true`는 관측 불가.
void main() {
  const testHivePath = '.dart_tool/test_hive_library_cubit';

  setUpAll(() async {
    Hive.init(testHivePath);
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(PlatformAdapter());
    Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
  });

  setUp(() async {
    await Hive.box<Article>('articles').clear();
    await Hive.box<Label>('labels').clear();
    articlesChangedNotifier.value = 0;
    labelsChangedNotifier.value = 0;
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

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

  Future<Label> seedLabel(String name) async {
    final l = Label()
      ..name = name
      ..colorValue = 0xFF000000
      ..createdAt = DateTime.now();
    await Hive.box<Label>('labels').add(l);
    return l;
  }

  test('생성자 직후 load()가 동기 실행되어 DB 상태를 반영한다', () async {
    await seedLabel('tech');
    await seedLabel('news');
    await seedArticle(url: 'u1', title: 't1', labels: ['tech'], isRead: true);
    await seedArticle(url: 'u2', title: 't2', labels: ['tech']);
    await seedArticle(
        url: 'u3', title: 't3', labels: ['news'], isBookmarked: true);

    final cubit = LibraryCubit();
    // load()는 내부 await가 없어 동기 완료.
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.labels.map((l) => l.name), ['news', 'tech']);
    expect(cubit.state.overall, (total: 3, read: 1));
    expect(cubit.state.bookmark, (total: 1, read: 0));
    expect(cubit.state.labelStats['tech'], (total: 2, read: 1));
    expect(cubit.state.labelStats['news'], (total: 1, read: 0));

    await cubit.close();
  });

  test('빈 DB에서 생성 시 통계는 모두 0', () async {
    final cubit = LibraryCubit();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.labels, isEmpty);
    expect(cubit.state.overall, (total: 0, read: 0));
    expect(cubit.state.bookmark, (total: 0, read: 0));
    expect(cubit.state.labelStats, isEmpty);

    await cubit.close();
  });

  test('articlesChangedNotifier 변경 시 load가 재실행된다', () async {
    await seedLabel('tech');
    await seedArticle(url: 'u1', title: 't1', labels: ['tech']);

    final cubit = LibraryCubit();
    expect(cubit.state.overall.total, 1);

    final emitted = <LibraryState>[];
    final sub = cubit.stream.listen(emitted.add);

    await seedArticle(url: 'u2', title: 't2', labels: ['tech'], isRead: true);
    articlesChangedNotifier.value++;
    await Future<void>.delayed(Duration.zero);

    expect(emitted, hasLength(1));
    expect(emitted.first.overall, (total: 2, read: 1));
    expect(emitted.first.labelStats['tech'], (total: 2, read: 1));

    await sub.cancel();
    await cubit.close();
  });

  test('labelsChangedNotifier 변경 시 load가 재실행된다', () async {
    final cubit = LibraryCubit();
    expect(cubit.state.labels, isEmpty);

    final emitted = <LibraryState>[];
    final sub = cubit.stream.listen(emitted.add);

    await seedLabel('added');
    labelsChangedNotifier.value++;
    await Future<void>.delayed(Duration.zero);

    expect(emitted, hasLength(1));
    expect(emitted.first.labels.map((l) => l.name), ['added']);

    await sub.cancel();
    await cubit.close();
  });

  test('close() 이후 notifier 변경은 무시된다', () async {
    await seedLabel('tech');
    final cubit = LibraryCubit();
    expect(cubit.state.labels.map((l) => l.name), ['tech']);

    await cubit.close();

    // removeListener 되었으므로 추가 DB 변경 + trigger는 cubit에 전달되지 않는다.
    await seedLabel('ignored');
    articlesChangedNotifier.value++;
    labelsChangedNotifier.value++;
    await Future<void>.delayed(Duration.zero);

    // 닫힌 cubit의 state는 close 직전 값 그대로.
    expect(cubit.state.labels.map((l) => l.name), ['tech']);
  });

  test('copyWith는 지정 필드만 갱신한다', () {
    const base = LibraryState();
    final updated = base.copyWith(
      overall: (total: 5, read: 2),
      isLoading: false,
    );

    expect(updated.overall, (total: 5, read: 2));
    expect(updated.isLoading, isFalse);
    expect(updated.labels, same(base.labels));
    expect(updated.bookmark, base.bookmark);
    expect(updated.labelStats, same(base.labelStats));
  });

  test('동일한 상태는 Equatable로 동등하다 (Map 비교 포함)', () {
    final s1 = LibraryState(
      labels: const [],
      overall: (total: 1, read: 1),
      bookmark: (total: 0, read: 0),
      labelStats: {'a': (total: 2, read: 1)},
      isLoading: false,
    );
    final s2 = LibraryState(
      labels: const [],
      overall: (total: 1, read: 1),
      bookmark: (total: 0, read: 0),
      labelStats: {'a': (total: 2, read: 1)},
      isLoading: false,
    );
    expect(s1, s2);
  });
}
