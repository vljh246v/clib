import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/blocs/article_list/article_list_cubit.dart';
import 'package:clib/blocs/article_list/article_list_source.dart';
import 'package:clib/blocs/article_list/article_list_state.dart';
import 'package:clib/main.dart' show articlesChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

/// ArticleListCubit 단위 테스트.
///
/// - `Hive.init(path)`로 path_provider 우회.
/// - `bloc_test` 미사용 — flutter_test + stream.listen 패턴.
/// - 각 소스 타입(`All`, `Bookmarked`, `ByLabel`)을 개별 테스트.
void main() {
  const testHivePath = '.dart_tool/test_hive_article_list_cubit';

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

  // ── ArticleListSourceAll ────────────────────────────────────

  group('ArticleListSourceAll', () {
    test('생성자 직후 DB 전체 아티클이 로드된다', () async {
      await seedArticle(url: 'u1', title: 't1', isRead: true);
      await seedArticle(url: 'u2', title: 't2');

      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.articles.length, 2);
      expect(cubit.state.total, 2);
      expect(cubit.state.readCount, 1);
      expect(cubit.state.unreadCount, 1);
      expect(cubit.state.isSelecting, isFalse);
      expect(cubit.state.selectedKeys, isEmpty);
      await cubit.close();
    });

    test('readArticles / unreadArticles 게터가 올바르게 필터한다', () async {
      await seedArticle(url: 'u1', title: 't1', isRead: true);
      await seedArticle(url: 'u2', title: 't2');
      await seedArticle(url: 'u3', title: 't3', isRead: true);

      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.readArticles.length, 2);
      expect(cubit.state.unreadArticles.length, 1);
      await cubit.close();
    });

    test('articlesChangedNotifier 변경 시 자동으로 재로드된다', () async {
      await seedArticle(url: 'u1', title: 't1');

      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.total, 1);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await seedArticle(url: 'u2', title: 't2');
      articlesChangedNotifier.value++;
      await Future<void>.delayed(Duration.zero);

      expect(emitted.isNotEmpty, isTrue);
      expect(emitted.last.total, 2);

      await sub.cancel();
      await cubit.close();
    });

    test('close() 이후 notifier 트리거는 무시된다', () async {
      await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.total, 1);

      await cubit.close();

      await seedArticle(url: 'u2', title: 't2');
      articlesChangedNotifier.value++;
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.total, 1);
    });
  });

  // ── ArticleListSourceBookmarked ─────────────────────────────

  group('ArticleListSourceBookmarked', () {
    test('북마크된 아티클만 로드한다', () async {
      await seedArticle(url: 'u1', title: 't1', isBookmarked: true);
      await seedArticle(url: 'u2', title: 't2');
      await seedArticle(url: 'u3', title: 't3', isBookmarked: true, isRead: true);

      final cubit =
          ArticleListCubit(const ArticleListSourceBookmarked());
      expect(cubit.state.total, 2);
      expect(cubit.state.readCount, 1);
      await cubit.close();
    });
  });

  // ── ArticleListSourceByLabel ────────────────────────────────

  group('ArticleListSourceByLabel', () {
    test('해당 라벨을 가진 아티클만 로드한다', () async {
      await seedArticle(url: 'u1', title: 't1', labels: ['tech']);
      await seedArticle(url: 'u2', title: 't2', labels: ['news']);
      await seedArticle(url: 'u3', title: 't3', labels: ['tech'], isRead: true);

      final cubit =
          ArticleListCubit(const ArticleListSourceByLabel('tech'));
      expect(cubit.state.total, 2);
      expect(cubit.state.readCount, 1);
      await cubit.close();
    });
  });

  // ── 선택 모드 ───────────────────────────────────────────────

  group('선택 모드', () {
    test('toggleSelectMode() 가 isSelecting 을 토글하고 선택을 초기화한다', () async {
      await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.isSelecting, isFalse);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.toggleSelectMode();
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.isSelecting, isTrue);

      cubit.toggleSelectMode();
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.isSelecting, isFalse);

      await sub.cancel();
      await cubit.close();
    });

    test('toggleSelection() 이 키를 추가/제거한다', () async {
      final a = await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.toggleSelection(a.key);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.selectedKeys, contains(a.key));

      cubit.toggleSelection(a.key);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.selectedKeys, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('selectAll() 이 전체 선택과 전체 해제를 토글한다', () async {
      final a1 = await seedArticle(url: 'u1', title: 't1');
      final a2 = await seedArticle(url: 'u2', title: 't2');
      final cubit = ArticleListCubit(const ArticleListSourceAll());

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.selectAll(cubit.state.articles);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.selectedKeys, containsAll([a1.key, a2.key]));

      // 전부 선택된 상태에서 다시 호출 → 전체 해제
      cubit.selectAll(cubit.state.articles);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.selectedKeys, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('clearSelection() 이 키를 초기화한다', () async {
      final a = await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      cubit.toggleSelection(a.key);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.clearSelection();
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.selectedKeys, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('allSelectedFor() 가 부분 선택과 전체 선택을 구분한다', () async {
      final a1 = await seedArticle(url: 'u1', title: 't1');
      final a2 = await seedArticle(url: 'u2', title: 't2');
      final cubit = ArticleListCubit(const ArticleListSourceAll());

      cubit.toggleSelection(a1.key);
      expect(cubit.state.allSelectedFor(cubit.state.articles), isFalse);

      cubit.toggleSelection(a2.key);
      expect(cubit.state.allSelectedFor(cubit.state.articles), isTrue);

      await cubit.close();
    });
  });

  // ── 개별 액션 ───────────────────────────────────────────────

  group('개별 액션', () {
    test('toggleBookmark() 가 북마크를 토글하고 재로드한다', () async {
      await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.articles.first.isBookmarked, isFalse);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.toggleBookmark(cubit.state.articles.first);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.articles.first.isBookmarked, isTrue);

      await cubit.toggleBookmark(emitted.last.articles.first);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.articles.first.isBookmarked, isFalse);

      await sub.cancel();
      await cubit.close();
    });

    test('markRead() / markUnread() 가 읽음 상태를 변경한다', () async {
      await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.markRead(cubit.state.articles.first);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.articles.first.isRead, isTrue);

      await cubit.markUnread(emitted.last.articles.first);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.articles.first.isRead, isFalse);

      await sub.cancel();
      await cubit.close();
    });

    test('updateMemo() 가 메모를 저장하고 null 로 삭제한다', () async {
      await seedArticle(url: 'u1', title: 't1');
      final cubit = ArticleListCubit(const ArticleListSourceAll());

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.updateMemo(cubit.state.articles.first, 'test memo');
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.articles.first.memo, 'test memo');

      await cubit.updateMemo(emitted.last.articles.first, null);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.articles.first.memo, isNull);

      await sub.cancel();
      await cubit.close();
    });

    test('deleteArticle() 가 아티클을 삭제하고 목록에서 제거한다', () async {
      await seedArticle(url: 'u1', title: 't1');
      await seedArticle(url: 'u2', title: 't2');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      expect(cubit.state.total, 2);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.deleteArticle(cubit.state.articles.first);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.total, 1);

      await sub.cancel();
      await cubit.close();
    });
  });

  // ── 일괄 액션 ───────────────────────────────────────────────

  group('일괄 액션', () {
    test('bulkMarkRead(true) 가 선택된 아티클을 읽음으로 표시하고 선택 해제한다', () async {
      final a1 = await seedArticle(url: 'u1', title: 't1');
      final a2 = await seedArticle(url: 'u2', title: 't2');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      cubit.toggleSelection(a1.key);
      cubit.toggleSelection(a2.key);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.bulkMarkRead(true);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.last.articles.every((a) => a.isRead), isTrue);
      expect(emitted.last.isSelecting, isFalse);
      expect(emitted.last.selectedKeys, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('bulkToggleBookmark(true) 가 선택 아티클에 북마크를 추가한다', () async {
      final a1 = await seedArticle(url: 'u1', title: 't1');
      await seedArticle(url: 'u2', title: 't2');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      cubit.toggleSelection(a1.key);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.bulkToggleBookmark(true);
      await Future<void>.delayed(Duration.zero);

      final bookmarked =
          emitted.last.articles.where((a) => a.isBookmarked).toList();
      expect(bookmarked.length, 1);
      expect(emitted.last.selectedKeys, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('bulkDelete() 가 선택된 아티클을 삭제하고 선택 해제한다', () async {
      final a1 = await seedArticle(url: 'u1', title: 't1');
      await seedArticle(url: 'u2', title: 't2');
      final cubit = ArticleListCubit(const ArticleListSourceAll());
      cubit.toggleSelection(a1.key);

      final emitted = <ArticleListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.bulkDelete();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.last.total, 1);
      expect(emitted.last.selectedKeys, isEmpty);
      expect(emitted.last.isSelecting, isFalse);

      await sub.cancel();
      await cubit.close();
    });
  });

  // ── ArticleListState Equatable ──────────────────────────────

  group('ArticleListState', () {
    test('동일한 상태는 Equatable 로 동등하다', () {
      final s1 = ArticleListState(
        source: const ArticleListSourceAll(),
        articles: const [],
        isSelecting: false,
        selectedKeys: const [],
      );
      final s2 = ArticleListState(
        source: const ArticleListSourceAll(),
        articles: const [],
        isSelecting: false,
        selectedKeys: const [],
      );
      expect(s1, s2);
    });

    test('소스가 다르면 동등하지 않다', () {
      final s1 = ArticleListState(source: const ArticleListSourceAll());
      final s2 =
          ArticleListState(source: const ArticleListSourceBookmarked());
      expect(s1, isNot(s2));
    });

    test('ArticleListSourceByLabel 는 labelName 으로 비교한다', () {
      expect(
        const ArticleListSourceByLabel('tech'),
        const ArticleListSourceByLabel('tech'),
      );
      expect(
        const ArticleListSourceByLabel('tech'),
        isNot(const ArticleListSourceByLabel('news')),
      );
    });

    test('copyWith 는 지정 필드만 갱신한다', () {
      const base = ArticleListState(source: ArticleListSourceAll());
      final updated = base.copyWith(isSelecting: true, selectedKeys: [1, 2]);
      expect(updated.isSelecting, isTrue);
      expect(updated.selectedKeys, [1, 2]);
      expect(updated.source, const ArticleListSourceAll());
      expect(updated.articles, same(base.articles));
    });
  });
}
