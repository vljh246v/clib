import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:clib/blocs/home/home_bloc.dart';
import 'package:clib/blocs/home/home_event.dart';
import 'package:clib/blocs/home/home_state.dart';
import 'package:clib/main.dart'
    show articlesChangedNotifier, labelsChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

/// HomeBloc 단위 테스트.
///
/// - `Hive.init(path)`로 path_provider 우회.
/// - `bloc_test` 미사용 — flutter_test + stream.listen + `Future<void>.delayed`.
/// - 필터는 AND 로직(기존 HomeScreen UX) 확인.
void main() {
  const testHivePath = '.dart_tool/test_hive_home_bloc';

  setUpAll(() async {
    Hive.init(testHivePath);
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(PlatformAdapter());
    Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
  });

  setUp(() async {
    DatabaseService.skipSync = true;
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
    String? memo,
  }) async {
    final a = Article()
      ..url = url
      ..title = title
      ..platform = Platform.etc
      ..topicLabels = List.of(labels)
      ..isRead = isRead
      ..isBookmarked = isBookmarked
      ..createdAt = DateTime.now()
      ..memo = memo;
    await Hive.box<Article>('articles').add(a);
    return a;
  }

  Future<Label> seedLabel(String name) async {
    final l = Label()
      ..name = name
      ..colorValue = 0xFF888888
      ..createdAt = DateTime.now();
    await Hive.box<Label>('labels').add(l);
    return l;
  }

  /// 초기 HomeLoadDeck emit이 반영될 때까지 대기.
  Future<void> settle(HomeBloc bloc) async {
    while (bloc.state.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  // ── HomeState 기본 동작 ────────────────────────────────────────

  group('HomeState', () {
    test('copyWith 는 지정 필드만 갱신한다', () {
      const base = HomeState();
      final updated = base.copyWith(
        selectedLabelNames: {'tech'},
        isExpanded: true,
        deckVersion: 5,
      );
      expect(updated.selectedLabelNames, {'tech'});
      expect(updated.isExpanded, isTrue);
      expect(updated.deckVersion, 5);
      expect(updated.articles, same(base.articles));
      expect(updated.allLabels, same(base.allLabels));
    });

    test('동일 내용은 Equatable 로 동등하다', () {
      const s1 = HomeState(isExpanded: true, deckVersion: 2);
      const s2 = HomeState(isExpanded: true, deckVersion: 2);
      expect(s1, s2);
    });
  });

  // ── 초기 로드 ──────────────────────────────────────────────────

  group('초기 로드', () {
    test('생성자 직후 미읽음 아티클 + 라벨이 로드되고 deckVersion=1', () async {
      await seedArticle(url: 'u1', title: 't1');
      await seedArticle(url: 'u2', title: 't2', isRead: true);
      await seedLabel('tech');

      final bloc = HomeBloc();
      await settle(bloc);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.articles.length, 1);
      expect(bloc.state.articles.first.url, 'u1');
      expect(bloc.state.allLabels.length, 1);
      expect(bloc.state.deckVersion, 1);

      await bloc.close();
    });
  });

  // ── 필터 (AND) ─────────────────────────────────────────────────

  group('HomeFilterLabelsChanged (AND)', () {
    test('선택한 라벨 전부를 포함한 아티클만 남는다', () async {
      await seedArticle(url: 'u1', title: 't1', labels: ['tech', 'news']);
      await seedArticle(url: 'u2', title: 't2', labels: ['tech']);
      await seedArticle(url: 'u3', title: 't3', labels: ['news']);

      final bloc = HomeBloc();
      await settle(bloc);
      expect(bloc.state.articles.length, 3);
      final initialVersion = bloc.state.deckVersion;

      bloc.add(const HomeFilterLabelsChanged({'tech', 'news'}));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.articles.length, 1);
      expect(bloc.state.articles.first.url, 'u1');
      expect(bloc.state.selectedLabelNames, {'tech', 'news'});
      expect(bloc.state.deckVersion, greaterThan(initialVersion));

      await bloc.close();
    });

    test('빈 Set 으로 변경하면 전체 덱 복귀', () async {
      await seedArticle(url: 'u1', title: 't1', labels: ['tech']);
      await seedArticle(url: 'u2', title: 't2', labels: ['news']);

      final bloc = HomeBloc();
      await settle(bloc);

      bloc.add(const HomeFilterLabelsChanged({'tech'}));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.articles.length, 1);

      bloc.add(const HomeFilterLabelsChanged({}));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.articles.length, 2);
      expect(bloc.state.selectedLabelNames, isEmpty);

      await bloc.close();
    });
  });

  // ── 스와이프 ───────────────────────────────────────────────────

  group('HomeSwipeRead', () {
    test('읽음 처리 + 덱에서 제거 + deckVersion 증가', () async {
      final a = await seedArticle(url: 'u1', title: 't1');
      await seedArticle(url: 'u2', title: 't2');

      final bloc = HomeBloc();
      await settle(bloc);
      expect(bloc.state.articles.length, 2);
      final initialVersion = bloc.state.deckVersion;

      bloc.add(HomeSwipeRead(a));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.articles.length, 1);
      expect(bloc.state.articles.first.url, 'u2');
      expect(bloc.state.deckVersion, greaterThan(initialVersion));
      expect(a.isRead, isTrue);

      await bloc.close();
    });
  });

  group('HomeSwipeLater', () {
    test('reachedEnd=false 면 상태 변경 없음', () async {
      final a = await seedArticle(url: 'u1', title: 't1');

      final bloc = HomeBloc();
      await settle(bloc);
      final before = bloc.state;

      bloc.add(HomeSwipeLater(a));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, before);
      expect(a.isRead, isFalse);

      await bloc.close();
    });

    test('reachedEnd=true 면 deckVersion 만 증가', () async {
      final a = await seedArticle(url: 'u1', title: 't1');

      final bloc = HomeBloc();
      await settle(bloc);
      final initialVersion = bloc.state.deckVersion;

      bloc.add(HomeSwipeLater(a, reachedEnd: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.deckVersion, greaterThan(initialVersion));
      expect(bloc.state.articles.length, 1);
      expect(a.isRead, isFalse);

      await bloc.close();
    });
  });

  // ── 개별 액션 ──────────────────────────────────────────────────

  group('HomeToggleBookmark / HomeUpdateMemo', () {
    test('토글 후 재로드되어 articles 반영 + stream emit 확인', () async {
      final a = await seedArticle(url: 'u1', title: 't1');
      final bloc = HomeBloc();
      await settle(bloc);
      expect(bloc.state.articles.first.isBookmarked, isFalse);

      // Article in-place 변경 시 Equatable dedup으로 emit이 스킵되지 않도록
      // HomeState.refreshToken을 항상 증가시킴 — stream 이벤트로 검증.
      final emitted = <HomeState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(HomeToggleBookmark(a));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.articles.first.isBookmarked, isTrue);
      expect(emitted, isNotEmpty);
      expect(emitted.last.refreshToken, greaterThan(0));

      await sub.cancel();
      await bloc.close();
    });

    test('메모 업데이트 후 articles 에 반영', () async {
      final a = await seedArticle(url: 'u1', title: 't1');
      final bloc = HomeBloc();
      await settle(bloc);

      bloc.add(HomeUpdateMemo(a, 'note'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.articles.first.memo, 'note');
      await bloc.close();
    });
  });

  // ── 확장 토글 ──────────────────────────────────────────────────

  group('HomeToggleExpand', () {
    test('isExpanded 를 토글한다', () async {
      final bloc = HomeBloc();
      await settle(bloc);
      expect(bloc.state.isExpanded, isFalse);

      bloc.add(const HomeToggleExpand());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.isExpanded, isTrue);

      bloc.add(const HomeToggleExpand());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.isExpanded, isFalse);

      await bloc.close();
    });
  });

  // ── notifier 브릿지 ────────────────────────────────────────────

  group('외부 notifier', () {
    test('articlesChangedNotifier 가 발사되면 덱 재로드', () async {
      await seedArticle(url: 'u1', title: 't1');
      final bloc = HomeBloc();
      await settle(bloc);
      expect(bloc.state.articles.length, 1);

      await seedArticle(url: 'u2', title: 't2');
      articlesChangedNotifier.value++;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.articles.length, 2);
      await bloc.close();
    });

    test('labelsChangedNotifier 가 발사되면 allLabels 갱신', () async {
      final bloc = HomeBloc();
      await settle(bloc);
      expect(bloc.state.allLabels, isEmpty);

      await seedLabel('tech');
      labelsChangedNotifier.value++;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.allLabels.length, 1);
      await bloc.close();
    });

    test('close() 이후 notifier 트리거는 무시된다', () async {
      await seedArticle(url: 'u1', title: 't1');
      final bloc = HomeBloc();
      await settle(bloc);

      await bloc.close();

      await seedArticle(url: 'u2', title: 't2');
      articlesChangedNotifier.value++;
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.articles.length, 1);
    });
  });
}
