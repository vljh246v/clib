import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/main.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/platform_meta.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/widgets/inline_banner_ad.dart';

/// 전체 아티클 화면 — 읽음/안읽음 필터 탭
class AllArticlesScreen extends StatefulWidget {
  const AllArticlesScreen({super.key});

  @override
  State<AllArticlesScreen> createState() => _AllArticlesScreenState();
}

class _AllArticlesScreenState extends State<AllArticlesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSelecting = false;
  final Set<dynamic> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() => _selectedKeys.clear()));
    articlesChangedNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    articlesChangedNotifier.removeListener(_refresh);
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<Article> _getFilteredArticles(bool? isReadFilter) {
    var articles = DatabaseService.getAllArticles();
    if (isReadFilter != null) {
      articles = articles.where((a) => a.isRead == isReadFilter).toList();
    }
    return articles;
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _selectedKeys.clear();
    });
  }

  void _selectAll(List<Article> articles) {
    setState(() {
      if (_selectedKeys.length == articles.length) {
        _selectedKeys.clear();
      } else {
        _selectedKeys
          ..clear()
          ..addAll(articles.map((a) => a.key));
      }
    });
  }

  Future<void> _bulkMarkRead(bool isRead) async {
    final articles = DatabaseService.getAllArticles()
        .where((a) => _selectedKeys.contains(a.key))
        .toList();
    await DatabaseService.bulkMarkRead(articles, isRead);
    setState(() {
      _isSelecting = false;
      _selectedKeys.clear();
    });
  }

  Future<void> _bulkDelete() async {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteArticle),
        content: Text(l.deleteSelectedConfirm(_selectedKeys.length)),
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
    if (confirmed != true) return;

    final articles = DatabaseService.getAllArticles()
        .where((a) => _selectedKeys.contains(a.key))
        .toList();
    for (final a in articles) {
      await DatabaseService.deleteArticle(a);
    }
    setState(() {
      _isSelecting = false;
      _selectedKeys.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = DatabaseService.getOverallStats();
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final l = AppLocalizations.of(context)!;

    final bool? filterMap = [null, false, true][_tabController.index];
    final currentArticles = _getFilteredArticles(filterMap);
    final allSelected =
        _selectedKeys.length == currentArticles.length &&
        currentArticles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSelecting
            ? Text(l.selectedCount(_selectedKeys.length))
            : Text(l.allArticles),
        actions: _isSelecting
            ? [
                Checkbox(
                  value: allSelected,
                  tristate: false,
                  onChanged: (_) => _selectAll(currentArticles),
                ),
                TextButton(
                  onPressed: _toggleSelectMode,
                  child: Text(l.cancel),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: l.select,
                  onPressed: _toggleSelectMode,
                ),
              ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: color,
          labelColor: color,
          tabs: [
            Tab(text: l.tabAll(stats.total)),
            Tab(text: l.tabUnread(stats.total - stats.read)),
            Tab(text: l.tabRead(stats.read)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArticleList(null),
          _buildArticleList(false),
          _buildArticleList(true),
        ],
      ),
      bottomNavigationBar: _isSelecting && _selectedKeys.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.bookmark_add, size: 18),
                            label: Text(l.bookmark),
                            onPressed: () => _bulkToggleBookmark(true),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.bookmark_remove, size: 18),
                            label: Text(l.removeBookmark),
                            onPressed: () => _bulkToggleBookmark(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(l.unread),
                            onPressed: () => _bulkMarkRead(false),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: Text(l.read),
                            onPressed: () => _bulkMarkRead(true),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(l.delete),
                            onPressed: _bulkDelete,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildArticleList(bool? isReadFilter) {
    final articles = _getFilteredArticles(isReadFilter);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    if (articles.isEmpty) {
      return Center(
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
    }

    // 8개 아티클마다 인피드 배너 1개 삽입
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
        // adInterval개마다 광고 슬롯: index (adInterval), (adInterval*2+1), ...
        final adsBefore = adCount == 0
            ? 0
            : (index + 1) ~/ (adInterval + 1);
        final isAd = adCount > 0 &&
            index > 0 &&
            (index + 1) % (adInterval + 1) == 0;

        if (isAd) return const InlineBannerAd();

        final articleIndex = index - adsBefore;
        return _buildArticleItem(articles[articleIndex]);
      },
    );
  }

  Widget _buildArticleItem(Article article) {
    final meta = platformMeta(article.platform);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    final createdDaysAgo = DateTime.now().difference(article.createdAt).inDays;
    final dateText = createdDaysAgo == 0
        ? l.today
        : createdDaysAgo == 1
        ? l.yesterday
        : l.daysAgo(createdDaysAgo);
    final isSelected = _selectedKeys.contains(article.key);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Radii.borderLg,
        boxShadow: AppShadows.card(isDark),
      ),
      child: InkWell(
        borderRadius: Radii.borderLg,
        onTap: _isSelecting
            ? () => setState(() {
                if (isSelected) {
                  _selectedKeys.remove(article.key);
                } else {
                  _selectedKeys.add(article.key);
                }
              })
            : () async {
                final uri = Uri.tryParse(article.url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
        onLongPress: _isSelecting ? null : () => _showArticleActions(article),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.lg,
          ),
          child: Row(
            children: [
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => setState(() {
                        if (isSelected) {
                          _selectedKeys.remove(article.key);
                        } else {
                          _selectedKeys.add(article.key);
                        }
                      }),
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: Radii.borderMd,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: article.thumbnailUrl != null
                      ? Image.network(
                          article.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _thumbnailPlaceholder(meta, theme),
                        )
                      : _thumbnailPlaceholder(meta, theme),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: article.isRead
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Icon(
                          meta.icon,
                          size: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(meta.label, style: theme.textTheme.labelSmall),
                        const SizedBox(width: Spacing.sm),
                        Text(dateText, style: theme.textTheme.labelSmall),
                        if (article.isRead) ...[
                          const SizedBox(width: Spacing.sm),
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ],
                        if (article.isBookmarked) ...[
                          const SizedBox(width: Spacing.sm),
                          Icon(
                            Icons.bookmark,
                            size: 12,
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (article.memo != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        article.memo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArticleActions(Article article) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
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
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.25,
                ),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ListTile(
              leading: Icon(
                article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              title: Text(article.isBookmarked ? l.removeBookmark : l.bookmark),
              onTap: () async {
                Navigator.pop(ctx);
                await DatabaseService.toggleBookmark(article);
                setState(() {});
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
                _showMemoDialog(article);
              },
            ),
            ListTile(
              leading: Icon(
                article.isRead ? Icons.visibility_off : Icons.visibility,
              ),
              title: Text(article.isRead ? l.markAsUnread : l.markAsRead),
              onTap: () async {
                Navigator.pop(ctx);
                if (article.isRead) {
                  await DatabaseService.markAsUnread(article);
                } else {
                  await DatabaseService.markAsRead(article);
                }
                setState(() {});
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
                  await DatabaseService.deleteArticle(article);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMemoDialog(Article article) {
    final controller = TextEditingController(text: article.memo);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.25,
                  ),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(l.memo, style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
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
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: Radii.borderMd,
                            ),
                          ),
                          onPressed: () async {
                            await DatabaseService.updateMemo(article, null);
                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() {});
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
                          await DatabaseService.updateMemo(
                            article,
                            controller.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          setState(() {});
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

  Future<void> _bulkToggleBookmark(bool bookmark) async {
    final articles = DatabaseService.getAllArticles()
        .where((a) => _selectedKeys.contains(a.key))
        .toList();
    for (final a in articles) {
      a.isBookmarked = bookmark;
      await a.save();
    }
    setState(() {
      _isSelecting = false;
      _selectedKeys.clear();
    });
  }

  Widget _thumbnailPlaceholder(
    ({String label, IconData icon}) meta,
    ThemeData theme,
  ) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          meta.icon,
          size: 24,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
