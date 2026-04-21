import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/main.dart' show articlesChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'article_list_source.dart';
import 'article_list_state.dart';

/// 아티클 목록 Cubit.
///
/// [ArticleListSource]에 따라 DB에서 아티클을 로드하고
/// 선택 모드(다중 선택) + 개별/일괄 CRUD 액션을 처리한다.
///
/// `articlesChangedNotifier`를 구독해 ShareService 저장 등 외부 변경 시
/// 자동으로 재로드한다. 직접 실행한 DB 작업 후에는 명시적으로 [load]를 호출한다.
class ArticleListCubit extends Cubit<ArticleListState> {
  ArticleListCubit(ArticleListSource source)
      : super(ArticleListState(source: source)) {
    articlesChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => unawaited(load());

  Future<void> load() async {
    final articles = switch (state.source) {
      ArticleListSourceAll() => DatabaseService.getAllArticles(),
      ArticleListSourceBookmarked() => DatabaseService.getBookmarkedArticles(),
      ArticleListSourceByLabel(:final labelName) =>
        DatabaseService.getArticlesByLabel(labelName),
    };
    emit(state.copyWith(articles: articles, generation: state.generation + 1));
  }

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
        selectedKeys: visibleArticles.map((a) => a.key).toList(),
      ));
    }
  }

  void toggleSelection(dynamic key) {
    final keys = List<dynamic>.from(state.selectedKeys);
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
    for (final a in targets) {
      await DatabaseService.deleteArticle(a);
    }
    await _reloadAndClearSelection();
  }

  Future<void> _reloadAndClearSelection() async {
    final articles = switch (state.source) {
      ArticleListSourceAll() => DatabaseService.getAllArticles(),
      ArticleListSourceBookmarked() => DatabaseService.getBookmarkedArticles(),
      ArticleListSourceByLabel(:final labelName) =>
        DatabaseService.getArticlesByLabel(labelName),
    };
    emit(state.copyWith(
      articles: articles,
      isSelecting: false,
      selectedKeys: [],
      generation: state.generation + 1,
    ));
  }

  // ── 개별 액션 ──────────────────────────────────────────────

  Future<void> toggleBookmark(Article article) async {
    await DatabaseService.toggleBookmark(article);
    await load();
  }

  Future<void> markRead(Article article) async {
    await DatabaseService.markAsRead(article);
    await load();
  }

  Future<void> markUnread(Article article) async {
    await DatabaseService.markAsUnread(article);
    await load();
  }

  Future<void> updateMemo(Article article, String? memo) async {
    await DatabaseService.updateMemo(article, memo);
    await load();
  }

  Future<void> deleteArticle(Article article) async {
    await DatabaseService.deleteArticle(article);
    await load();
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
