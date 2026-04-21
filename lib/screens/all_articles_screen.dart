import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/blocs/article_list/article_list_cubit.dart';
import 'package:clib/blocs/article_list/article_list_source.dart';
import 'package:clib/blocs/article_list/article_list_state.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/widgets/article_list_view.dart';
import 'package:clib/widgets/bulk_action_bar.dart';

/// 전체 아티클 화면 — 읽음/안읽음 필터 탭.
class AllArticlesScreen extends StatelessWidget {
  const AllArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(const ArticleListSourceAll()),
      child: const _AllArticlesBody(),
    );
  }
}

class _AllArticlesBody extends StatefulWidget {
  const _AllArticlesBody();

  @override
  State<_AllArticlesBody> createState() => _AllArticlesBodyState();
}

class _AllArticlesBodyState extends State<_AllArticlesBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<ArticleListCubit>().clearSelection();
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
        final color = theme.colorScheme.primary;

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
                : Text(l.allArticles),
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
                      onDelete: () => _confirmBulkDelete(context),
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
              Icons.article_outlined,
              size: 40,
              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            isReadFilter == null
                ? l.noArticles
                : isReadFilter
                ? l.noReadArticles
                : l.noUnreadArticles,
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
        final uri = Uri.tryParse(article.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      onLongPress: (article) => _showArticleActions(context, article),
      onSelectionToggle: (key) =>
          context.read<ArticleListCubit>().toggleSelection(key),
    );
  }

  void _showArticleActions(BuildContext context, Article article) {
    final cubit = context.read<ArticleListCubit>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ListTile(
              leading: Icon(
                article.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
              title: Text(
                article.isBookmarked ? l.removeBookmark : l.bookmark,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await cubit.toggleBookmark(article);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(article.memo != null ? l.editMemo : l.addMemo),
              subtitle: article.memo != null
                  ? Text(
                      article.memo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _showMemoDialog(context, article, cubit);
              },
            ),
            ListTile(
              leading: Icon(
                article.isRead ? Icons.visibility_off : Icons.visibility,
              ),
              title: Text(
                article.isRead ? l.markAsUnread : l.markAsRead,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                if (article.isRead) {
                  await cubit.markUnread(article);
                } else {
                  await cubit.markRead(article);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l.openInBrowser),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.tryParse(article.url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l.delete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: Text(l.deleteArticle),
                    content: Text(l.deleteArticleConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, false),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx2, true),
                        child: Text(l.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await cubit.deleteArticle(article);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMemoDialog(
    BuildContext context,
    Article article,
    ArticleListCubit cubit,
  ) {
    final controller = TextEditingController(text: article.memo);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Spacing.md),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(l.memo, style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.xxl),
                child: TextField(
                  controller: controller,
                  maxLength: 100,
                  maxLines: 1,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l.memoHint,
                    counterText: '',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: Radii.borderMd,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xxl,
                  0,
                  Spacing.xxl,
                  Spacing.lg,
                ),
                child: Row(
                  children: [
                    if (article.memo != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: Radii.borderMd,
                            ),
                          ),
                          onPressed: () async {
                            await cubit.updateMemo(article, null);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(l.delete),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: Radii.borderMd,
                          ),
                        ),
                        onPressed: () async {
                          await cubit.updateMemo(
                            article,
                            controller.text.isEmpty ? null : controller.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(l.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBulkDelete(BuildContext context) async {
    final cubit = context.read<ArticleListCubit>();
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final count = cubit.state.selectedKeys.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteArticle),
        content: Text(l.deleteSelectedConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.bulkDelete();
    }
  }
}
