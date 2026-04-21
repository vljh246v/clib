import 'package:flutter/material.dart';
import 'package:clib/models/article.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/widgets/article_list_item.dart';
import 'package:clib/widgets/inline_banner_ad.dart';

/// 아티클 목록 ListView.
///
/// 8개마다 [InlineBannerAd]를 삽입한다. 빈 목록이면 [emptyWidget]을 표시한다.
/// 순수 위젯이므로 Cubit에 의존하지 않고 콜백으로 이벤트를 전달한다.
class ArticleListView extends StatelessWidget {
  const ArticleListView({
    super.key,
    required this.articles,
    required this.isSelecting,
    required this.selectedKeys,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionToggle,
    required this.emptyWidget,
  });

  final List<Article> articles;
  final bool isSelecting;
  final List<dynamic> selectedKeys;
  final void Function(Article article) onTap;
  final void Function(Article article) onLongPress;
  final void Function(dynamic key) onSelectionToggle;
  final Widget emptyWidget;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return emptyWidget;

    const adInterval = 8;
    final adCount = articles.length >= adInterval
        ? (articles.length / adInterval).floor()
        : 0;
    final totalCount = articles.length + adCount;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.sm,
        horizontal: Spacing.lg,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final adsBefore = adCount == 0 ? 0 : (index + 1) ~/ (adInterval + 1);
        final isAd =
            adCount > 0 && index > 0 && (index + 1) % (adInterval + 1) == 0;

        if (isAd) return const InlineBannerAd();

        final article = articles[index - adsBefore];
        return ArticleListItem(
          article: article,
          isSelecting: isSelecting,
          isSelected: selectedKeys.contains(article.key),
          onTap: () => onTap(article),
          onSelectionToggle: () => onSelectionToggle(article.key),
          onLongPress: () => onLongPress(article),
        );
      },
    );
  }
}
