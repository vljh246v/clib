import 'package:equatable/equatable.dart';
import 'package:clib/models/article.dart';
import 'article_list_source.dart';

class ArticleListState extends Equatable {
  final ArticleListSource source;
  final List<Article> articles;
  final bool isSelecting;

  /// Hive key 목록. Set 대신 List로 저장해 Equatable 비교가 정상 동작하도록 한다.
  final List<dynamic> selectedKeys;

  /// `load()` 호출마다 1씩 증가해 Equatable 깊은 비교를 우회한다.
  ///
  /// Hive Article 객체는 in-place 변경되므로 동일 인스턴스끼리 비교하면
  /// 항상 equal로 판정돼 emit이 스킵된다. generation이 달라지면
  /// Equatable이 두 상태를 항상 다르다고 판단해 BlocBuilder가 올바르게 재빌드된다.
  final int generation;

  const ArticleListState({
    required this.source,
    this.articles = const [],
    this.isSelecting = false,
    this.selectedKeys = const [],
    this.generation = 0,
  });

  int get total => articles.length;
  int get readCount => articles.where((a) => a.isRead).length;
  int get unreadCount => total - readCount;

  List<Article> get unreadArticles => articles.where((a) => !a.isRead).toList();
  List<Article> get readArticles => articles.where((a) => a.isRead).toList();

  bool allSelectedFor(List<Article> visible) =>
      visible.isNotEmpty && visible.every((a) => selectedKeys.contains(a.key));

  ArticleListState copyWith({
    List<Article>? articles,
    bool? isSelecting,
    List<dynamic>? selectedKeys,
    int? generation,
  }) {
    return ArticleListState(
      source: source,
      articles: articles ?? this.articles,
      isSelecting: isSelecting ?? this.isSelecting,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      generation: generation ?? this.generation,
    );
  }

  @override
  List<Object?> get props => [source, articles, isSelecting, selectedKeys, generation];
}
