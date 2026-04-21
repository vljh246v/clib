import 'package:equatable/equatable.dart';

import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';

/// 홈 화면 스와이프 덱 상태.
///
/// - [articles]: 현재 필터가 적용된 미읽음 덱 (광고 슬롯 제외 순수 아티클).
/// - [allLabels]: 필터 칩 렌더링용 전체 라벨.
/// - [selectedLabelNames]: 필터 선택값. 빈 Set이면 전체.
///   **필터 로직은 AND**(모든 선택 라벨을 포함하는 아티클만 표시) — 기존 UX 보존.
/// - [isExpanded]: 라벨 칩 확장/접기.
/// - [deckVersion]: CardSwiper `ValueKey` prop. 증가 시 위젯 재생성.
/// - [refreshToken]: 매 로드 시 증가. `Article`은 in-place 변경되므로
///   `articles` 리스트의 identity 비교만으론 Equatable dedup에 걸려
///   `emit`이 스킵될 수 있음 — 재로드를 stream에 강제로 흘리기 위한 토큰.
/// - [isLoading]: 초기 로드 게이트.
class HomeState extends Equatable {
  final List<Article> articles;
  final List<Label> allLabels;
  final Set<String> selectedLabelNames;
  final bool isExpanded;
  final int deckVersion;
  final int refreshToken;
  final bool isLoading;

  const HomeState({
    this.articles = const [],
    this.allLabels = const [],
    this.selectedLabelNames = const {},
    this.isExpanded = false,
    this.deckVersion = 0,
    this.refreshToken = 0,
    this.isLoading = true,
  });

  HomeState copyWith({
    List<Article>? articles,
    List<Label>? allLabels,
    Set<String>? selectedLabelNames,
    bool? isExpanded,
    int? deckVersion,
    int? refreshToken,
    bool? isLoading,
  }) {
    return HomeState(
      articles: articles ?? this.articles,
      allLabels: allLabels ?? this.allLabels,
      selectedLabelNames: selectedLabelNames ?? this.selectedLabelNames,
      isExpanded: isExpanded ?? this.isExpanded,
      deckVersion: deckVersion ?? this.deckVersion,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        articles,
        allLabels,
        selectedLabelNames,
        isExpanded,
        deckVersion,
        refreshToken,
        isLoading,
      ];
}
