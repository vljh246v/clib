import 'package:equatable/equatable.dart';
import 'package:clib/models/label.dart';

/// 라이브러리 화면 상태.
///
/// - [labels]: 라벨 이름 오름차순 정렬된 전체 라벨 목록.
/// - [overall]: 전체 아티클 total/read.
/// - [bookmark]: 북마크된 아티클 total/read.
/// - [labelStats]: label.name → total/read. 키는 labels의 name과 일치.
/// - [isLoading]: 초기 로드 전 true. 첫 `load()` 완료 시 false.
///
/// 통계는 `DatabaseService`가 반환하는 Dart 레코드 `({int total, int read})`
/// 타입을 그대로 사용한다. 레코드는 구조적 `==`를 가지며 Equatable의
/// Map 비교에서 정상 동작한다.
class LibraryState extends Equatable {
  final List<Label> labels;
  final ({int total, int read}) overall;
  final ({int total, int read}) bookmark;
  final Map<String, ({int total, int read})> labelStats;
  final bool isLoading;

  const LibraryState({
    this.labels = const [],
    this.overall = (total: 0, read: 0),
    this.bookmark = (total: 0, read: 0),
    this.labelStats = const {},
    this.isLoading = true,
  });

  LibraryState copyWith({
    List<Label>? labels,
    ({int total, int read})? overall,
    ({int total, int read})? bookmark,
    Map<String, ({int total, int read})>? labelStats,
    bool? isLoading,
  }) {
    return LibraryState(
      labels: labels ?? this.labels,
      overall: overall ?? this.overall,
      bookmark: bookmark ?? this.bookmark,
      labelStats: labelStats ?? this.labelStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [labels, overall, bookmark, labelStats, isLoading];
}
