import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/blocs/article_list/article_list_cubit.dart';
import 'package:clib/blocs/article_list/article_list_source.dart';
import 'package:clib/blocs/article_list/article_list_state.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/utils/url_safety.dart';
import 'package:clib/widgets/article_actions_sheet.dart';
import 'package:clib/widgets/article_list_view.dart';
import 'package:clib/widgets/bulk_action_bar.dart';
import 'package:clib/widgets/bulk_delete_confirm.dart';

/// 북마크된 아티클 화면.
class BookmarkedArticlesScreen extends StatelessWidget {
  const BookmarkedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(const ArticleListSourceBookmarked()),
      child: const _BookmarkedBody(),
    );
  }
}

class _BookmarkedBody extends StatefulWidget {
  const _BookmarkedBody();

  @override
  State<_BookmarkedBody> createState() => _BookmarkedBodyState();
}

class _BookmarkedBodyState extends State<_BookmarkedBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<ArticleListCubit>().clearSelection();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleListCubit, ArticleListState>(
      builder: (context, state) {
        final l = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final color = theme.colorScheme.secondary;

        final visibleArticles = switch (_tabController.index) {
          0 => state.articles,
          1 => state.unreadArticles,
          2 => state.readArticles,
          _ => state.articles,
        };
        final allSelected = state.allSelectedFor(visibleArticles);

        return Scaffold(
          appBar: AppBar(
            title: state.isSelecting
                ? Text(l.selectedCount(state.selectedKeys.length))
                : Text(l.bookmarks),
            actions: state.isSelecting
                ? [
                    Checkbox(
                      value: allSelected,
                      tristate: false,
                      onChanged: (_) => context
                          .read<ArticleListCubit>()
                          .selectAll(visibleArticles),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<ArticleListCubit>().toggleSelectMode(),
                      child: Text(l.cancel),
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: l.select,
                      onPressed: () =>
                          context.read<ArticleListCubit>().toggleSelectMode(),
                    ),
                  ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: color,
              labelColor: color,
              tabs: [
                Tab(text: l.tabAll(state.total)),
                Tab(text: l.tabUnread(state.unreadCount)),
                Tab(text: l.tabRead(state.readCount)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTab(context, state, state.articles, null),
              _buildTab(context, state, state.unreadArticles, false),
              _buildTab(context, state, state.readArticles, true),
            ],
          ),
          bottomNavigationBar:
              state.isSelecting && state.selectedKeys.isNotEmpty
                  ? BulkActionBar(
                      onBookmark: () =>
                          context.read<ArticleListCubit>().bulkToggleBookmark(true),
                      onRemoveBookmark: () =>
                          context.read<ArticleListCubit>().bulkToggleBookmark(false),
                      onMarkUnread: () =>
                          context.read<ArticleListCubit>().bulkMarkRead(false),
                      onMarkRead: () =>
                          context.read<ArticleListCubit>().bulkMarkRead(true),
                      onDelete: () => showBulkDeleteConfirm(context),
                    )
                  : null,
        );
      },
    );
  }

  Widget _buildTab(
    BuildContext context,
    ArticleListState state,
    List<Article> articles,
    bool? isReadFilter,
  ) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final emptyWidget = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withValues(alpha: 0.06),
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 40,
              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            isReadFilter == null
                ? l.noBookmarks
                : isReadFilter
                ? l.noReadBookmarks
                : l.noUnreadBookmarks,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );

    return ArticleListView(
      articles: articles,
      isSelecting: state.isSelecting,
      selectedKeys: state.selectedKeys,
      emptyWidget: emptyWidget,
      onTap: (article) async {
        // M-4: http/https 스킴만 허용 (legacy 또는 변조된 DB 방어)
        final uri = parseAllowedUrl(article.url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      onLongPress: (article) => ArticleActionsSheet.show(
        context,
        article: article,
        cubit: context.read<ArticleListCubit>(),
      ),
      onSelectionToggle: (key) =>
          context.read<ArticleListCubit>().toggleSelection(key),
    );
  }
}
