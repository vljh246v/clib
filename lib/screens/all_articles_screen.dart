import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/platform_meta.dart';
import 'package:clib/services/database_service.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    for (final a in articles) {
      if (isRead) {
        await DatabaseService.markAsRead(a);
      } else {
        await DatabaseService.markAsUnread(a);
      }
    }
    setState(() {
      _isSelecting = false;
      _selectedKeys.clear();
    });
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('아티클 삭제'),
        content: Text('선택한 ${_selectedKeys.length}개 아티클을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
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

    // 현재 탭의 articles (전체선택 체크박스용)
    final bool? filterMap = [null, false, true][_tabController.index];
    final currentArticles = _getFilteredArticles(filterMap);
    final allSelected = _selectedKeys.length == currentArticles.length &&
        currentArticles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedKeys.length}개 선택됨')
            : const Text('전체 아티클'),
        actions: _isSelecting
            ? [
                Checkbox(
                  value: allSelected,
                  tristate: false,
                  onChanged: (_) => _selectAll(currentArticles),
                ),
                TextButton(
                  onPressed: _toggleSelectMode,
                  child: const Text('취소'),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '선택',
                  onPressed: _toggleSelectMode,
                ),
              ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: color,
          labelColor: color,
          tabs: [
            Tab(text: '전체 (${stats.total})'),
            Tab(text: '안 읽음 (${stats.total - stats.read})'),
            Tab(text: '읽음 (${stats.read})'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('안 읽음'),
                        onPressed: () => _bulkMarkRead(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('읽음'),
                        onPressed: () => _bulkMarkRead(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('삭제'),
                        onPressed: _bulkDelete,
                      ),
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

    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 48, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              isReadFilter == null
                  ? '아티클이 없습니다.'
                  : isReadFilter
                      ? '읽은 아티클이 없습니다.'
                      : '안 읽은 아티클이 없습니다.',
              style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: articles.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) => _buildArticleItem(articles[index]),
    );
  }

  Widget _buildArticleItem(Article article) {
    final meta = platformMeta(article.platform);
    final theme = Theme.of(context);
    final createdDaysAgo = DateTime.now().difference(article.createdAt).inDays;
    final dateText = createdDaysAgo == 0
        ? '오늘'
        : createdDaysAgo == 1
            ? '어제'
            : '$createdDaysAgo일 전';
    final isSelected = _selectedKeys.contains(article.key);

    return InkWell(
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
      onLongPress: _isSelecting
          ? null
          : () => _showArticleActions(article),
      child: Opacity(
        opacity: article.isRead ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            children: [
              // 선택 모드: 체크박스
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
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
              // 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: article.thumbnailUrl != null
                      ? Image.network(
                          article.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _thumbnailPlaceholder(meta),
                        )
                      : _thumbnailPlaceholder(meta),
                ),
              ),
              const SizedBox(width: 12),
              // 제목 + 부제
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(meta.icon, size: 11, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(meta.label,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text(dateText,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.withValues(alpha: 0.6))),
                        if (article.isRead) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 12,
                              color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                        ],
                      ],
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

  void _showArticleActions(Article article) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                article.isRead ? Icons.visibility_off : Icons.visibility,
              ),
              title: Text(article.isRead ? '안 읽음으로 변경' : '읽음으로 변경'),
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
              title: const Text('브라우저에서 열기'),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.tryParse(article.url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('삭제', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('아티클 삭제'),
                    content: const Text('이 아티클을 삭제할까요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx2, true),
                        child: const Text('삭제'),
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

  Widget _thumbnailPlaceholder(({String label, IconData icon}) meta) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      child: Center(
        child: Icon(meta.icon,
            size: 24, color: Colors.grey.withValues(alpha: 0.5)),
      ),
    );
  }
}
