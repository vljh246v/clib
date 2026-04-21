import 'package:equatable/equatable.dart';

sealed class ArticleListSource extends Equatable {
  const ArticleListSource();
}

final class ArticleListSourceAll extends ArticleListSource {
  const ArticleListSourceAll();

  @override
  List<Object?> get props => [];
}

final class ArticleListSourceBookmarked extends ArticleListSource {
  const ArticleListSourceBookmarked();

  @override
  List<Object?> get props => [];
}

final class ArticleListSourceByLabel extends ArticleListSource {
  const ArticleListSourceByLabel(this.labelName);

  final String labelName;

  @override
  List<Object?> get props => [labelName];
}
