import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/state/app_notifiers.dart' show articlesChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'article_list_source.dart';
import 'article_list_state.dart';

/// 아티클 목록 Cubit.
///
/// [ArticleListSource]에 따라 DB에서 아티클을 로드하고
/// 선택 모드(다중 선택) + 개별/일괄 CRUD 액션을 처리한다.
///
/// `articlesChangedNotifier`를 구독해 외부/내부 mutation 시 자동 재로드한다.
/// `DatabaseService`가 모든 mutation 직후 발사하므로 개별 액션 후 추가 [load]를
/// 호출하지 않는다. 일괄 액션만 selection 초기화를 위해 [_reloadAndClearSelection]
/// 으로 emit 1회 합친다.
class ArticleListCubit extends Cubit<ArticleListState> {
  ArticleListCubit(ArticleListSource source)
      : super(ArticleListState(source: source)) {
    articlesChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => unawaited(load());

  Future<void> load() async {
    emit(state.copyWith(articles: _fetch(), generation: state.generation + 1));
  }

  List<Article> _fetch() => switch (state.source) {
        ArticleListSourceAll() => DatabaseService.getAllArticles(),
        ArticleListSourceBookmarked() => DatabaseService.getBookmarkedArticles(),
        ArticleListSourceByLabel(:final labelName) =>
          DatabaseService.getArticlesByLabel(labelName),
      };

  // ── 선택 모드 ──────────────────────────────────────────────

  void toggleSelectMode() {
    emit(state.copyWith(isSelecting: !state.isSelecting, selectedKeys: []));
  }

  void clearSelection() {
    emit(state.copyWith(selectedKeys: []));
  }

  void selectAll(List<Article> visibleArticles) {
    if (state.allSelectedFor(visibleArticles)) {
      emit(state.copyWith(selectedKeys: []));
    } else {
      emit(state.copyWith(
        selectedKeys: visibleArticles.map((a) => a.key as int).toList(),
      ));
    }
  }

  void toggleSelection(int key) {
    final keys = List<int>.from(state.selectedKeys);
    if (keys.contains(key)) {
      keys.remove(key);
    } else {
      keys.add(key);
    }
    emit(state.copyWith(selectedKeys: keys));
  }

  // ── 일괄 액션 ──────────────────────────────────────────────

  Future<void> bulkMarkRead(bool isRead) async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key))
        .toList();
    await DatabaseService.bulkMarkRead(targets, isRead);
    await _reloadAndClearSelection();
  }

  Future<void> bulkToggleBookmark(bool bookmark) async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key))
        .toList();
    await DatabaseService.bulkSetBookmark(targets, bookmark);
    await _reloadAndClearSelection();
  }

  Future<void> bulkDelete() async {
    final targets = state.articles
        .where((a) => state.selectedKeys.contains(a.key))
        .toList();
    await DatabaseService.bulkDelete(targets);
    await _reloadAndClearSelection();
  }

  Future<void> _reloadAndClearSelection() async {
    emit(state.copyWith(
      articles: _fetch(),
      isSelecting: false,
      selectedKeys: [],
      generation: state.generation + 1,
    ));
  }

  // ── 개별 액션 ──────────────────────────────────────────────
  // 모든 호출은 DatabaseService가 articlesChangedNotifier를 발사 → _onChanged
  // listener 경로로 자동 reload. 추가 load() 호출 불필요.

  Future<void> toggleBookmark(Article article) =>
      DatabaseService.toggleBookmark(article);

  Future<void> markRead(Article article) =>
      DatabaseService.markAsRead(article);

  Future<void> markUnread(Article article) =>
      DatabaseService.markAsUnread(article);

  Future<void> updateMemo(Article article, String? memo) =>
      DatabaseService.updateMemo(article, memo);

  Future<void> deleteArticle(Article article) =>
      DatabaseService.deleteArticle(article);

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
