import 'package:equatable/equatable.dart';

import 'package:clib/models/article.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const [];
}

/// 덱 재로딩. [resetPosition]=true면 `deckVersion`을 증가시켜
/// CardSwiper 위젯을 재생성한다(인덱스 out-of-range 방지).
class HomeLoadDeck extends HomeEvent {
  final bool resetPosition;
  const HomeLoadDeck({this.resetPosition = false});

  @override
  List<Object?> get props => [resetPosition];
}

/// 필터 선택 변경(치환). 항상 덱 리셋.
class HomeFilterLabelsChanged extends HomeEvent {
  final Set<String> names;
  const HomeFilterLabelsChanged(this.names);

  @override
  List<Object?> get props => [names];
}

/// 오른쪽 스와이프 = 읽음 처리. 덱에서 해당 아티클 즉시 제거 +
/// CardSwiper 내부 인덱스 정합성을 위해 `deckVersion`을 올려 재생성.
class HomeSwipeRead extends HomeEvent {
  final Article article;
  const HomeSwipeRead(this.article);

  @override
  List<Object?> get props => [article.key];
}

/// 왼쪽 스와이프 = 나중에. DB 상태 변경 없음.
/// [reachedEnd]=true(loop 경계에서 currentIndex null)인 경우만 덱 리셋으로
/// 꼬임 방지 — 기존 HomeScreen 동작 보존.
class HomeSwipeLater extends HomeEvent {
  final Article article;
  final bool reachedEnd;
  const HomeSwipeLater(this.article, {this.reachedEnd = false});

  @override
  List<Object?> get props => [article.key, reachedEnd];
}

class HomeToggleBookmark extends HomeEvent {
  final Article article;
  const HomeToggleBookmark(this.article);

  @override
  List<Object?> get props => [article.key];
}

class HomeUpdateMemo extends HomeEvent {
  final Article article;
  final String? memo;
  const HomeUpdateMemo(this.article, this.memo);

  @override
  List<Object?> get props => [article.key, memo];
}

class HomeToggleExpand extends HomeEvent {
  const HomeToggleExpand();
}

/// 외부(ShareService 저장, Sync 원격 스냅샷) 변경 감지. 덱 위치 유지 재로드.
class HomeArticlesChangedExternally extends HomeEvent {
  const HomeArticlesChangedExternally();
}

/// 외부 라벨 변경 감지. 덱 위치 유지 재로드(라벨 리스트/필터 칩 갱신).
class HomeLabelsChangedExternally extends HomeEvent {
  const HomeLabelsChangedExternally();
}
