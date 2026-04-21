import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clib/main.dart'
    show articlesChangedNotifier, labelsChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'home_event.dart';
import 'home_state.dart';

/// 홈 스와이프 덱 Bloc.
///
/// - 스와이프/필터 이벤트를 이벤트 소싱으로 명시.
/// - `CardSwiperController` / `_pendingDispose` / `_thresholdNotifier`는
///   위젯 로컬 SSOT(bloc 금지).
/// - 필터는 **AND**(`every`)로 기존 UX 보존.
/// - `articlesChangedNotifier` 발사원: `ShareService.processAndSave`,
///   `SyncService` 원격 스냅샷 — 로컬 CRUD(`markAsRead`/`toggleBookmark` 등)는
///   발사하지 않으므로 Bloc이 각 액션 핸들러에서 직접 [HomeLoadDeck]을 emit한다.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeLoadDeck>(_onLoad);
    on<HomeFilterLabelsChanged>(_onFilter);
    on<HomeSwipeRead>(_onSwipeRead);
    on<HomeSwipeLater>(_onSwipeLater);
    on<HomeToggleBookmark>(_onToggleBookmark);
    on<HomeUpdateMemo>(_onUpdateMemo);
    on<HomeToggleExpand>((event, emit) {
      emit(state.copyWith(isExpanded: !state.isExpanded));
    });
    on<HomeArticlesChangedExternally>((event, emit) {
      add(const HomeLoadDeck(resetPosition: false));
    });
    on<HomeLabelsChangedExternally>((event, emit) {
      add(const HomeLoadDeck(resetPosition: false));
    });

    articlesChangedNotifier.addListener(_onExtArticles);
    labelsChangedNotifier.addListener(_onExtLabels);

    add(const HomeLoadDeck(resetPosition: true));
  }

  void _onExtArticles() => add(const HomeArticlesChangedExternally());
  void _onExtLabels() => add(const HomeLabelsChangedExternally());

  List<Article> _computeFiltered(Set<String> selected) {
    final unread = DatabaseService.getUnreadArticles();
    if (selected.isEmpty) return unread;
    // 기존 UX: AND — 모든 선택 라벨을 포함하는 아티클만 표시.
    return unread
        .where((a) => selected.every((l) => a.topicLabels.contains(l)))
        .toList();
  }

  Future<void> _onLoad(HomeLoadDeck event, Emitter<HomeState> emit) async {
    final List<Label> labels = DatabaseService.getAllLabelObjects();
    final filtered = _computeFiltered(state.selectedLabelNames);
    emit(state.copyWith(
      articles: filtered,
      allLabels: labels,
      isLoading: false,
      deckVersion:
          event.resetPosition ? state.deckVersion + 1 : state.deckVersion,
      // Article/Label in-place 변경 시에도 stream emit 보장.
      refreshToken: state.refreshToken + 1,
    ));
  }

  Future<void> _onFilter(
    HomeFilterLabelsChanged event,
    Emitter<HomeState> emit,
  ) async {
    final filtered = _computeFiltered(event.names);
    emit(state.copyWith(
      selectedLabelNames: event.names,
      articles: filtered,
      deckVersion: state.deckVersion + 1,
    ));
  }

  Future<void> _onSwipeRead(
    HomeSwipeRead event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.markAsRead(event.article);
    // 덱에서 즉시 제거 + 덱 재생성으로 CardSwiper 내부 인덱스 정합성 보장.
    final next = state.articles
        .where((a) => a.key != event.article.key)
        .toList();
    emit(state.copyWith(
      articles: next,
      deckVersion: state.deckVersion + 1,
    ));
  }

  Future<void> _onSwipeLater(
    HomeSwipeLater event,
    Emitter<HomeState> emit,
  ) async {
    // "나중에"는 DB 상태 변경 없음. 루프 경계(reachedEnd)에서만 덱 재생성으로
    // CardSwiper 내부 인덱스 꼬임 방지 — 기존 HomeScreen 동작 보존.
    if (event.reachedEnd) {
      emit(state.copyWith(deckVersion: state.deckVersion + 1));
    }
  }

  Future<void> _onToggleBookmark(
    HomeToggleBookmark event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.toggleBookmark(event.article);
    add(const HomeLoadDeck(resetPosition: false));
  }

  Future<void> _onUpdateMemo(
    HomeUpdateMemo event,
    Emitter<HomeState> emit,
  ) async {
    await DatabaseService.updateMemo(event.article, event.memo);
    add(const HomeLoadDeck(resetPosition: false));
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onExtArticles);
    labelsChangedNotifier.removeListener(_onExtLabels);
    return super.close();
  }
}
