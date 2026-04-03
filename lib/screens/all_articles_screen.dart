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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = DatabaseService.getOverallStats();
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 아티클'),
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
    );
  }

  Widget _buildArticleList(bool? isReadFilter) {
    var articles = DatabaseService.getAllArticles();
    if (isReadFilter != null) {
      articles = articles.where((a) => a.isRead == isReadFilter).toList();
    }

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
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: articles.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildArticleItem(articles[index]),
    );
  }

  Widget _buildArticleItem(Article article) {
    final meta = platformMeta(article.platform);
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final createdDaysAgo = DateTime.now().difference(article.createdAt).inDays;
    final dateText = createdDaysAgo == 0
        ? '오늘'
        : createdDaysAgo == 1
            ? '어제'
            : '$createdDaysAgo일 전';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: article.thumbnailUrl != null
              ? Image.network(
                  article.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _thumbnailPlaceholder(meta),
                )
              : _thumbnailPlaceholder(meta),
        ),
      ),
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: article.isRead ? Colors.grey.withValues(alpha: 0.6) : null,
          decoration: article.isRead ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(meta.icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              meta.label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      trailing: article.isRead
          ? Icon(Icons.check_circle, color: color, size: 20)
          : IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 20),
              color: Colors.grey.withValues(alpha: 0.4),
              onPressed: () async {
                await DatabaseService.markAsRead(article);
                setState(() {});
              },
            ),
      onTap: () async {
        final uri = Uri.tryParse(article.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  Widget _thumbnailPlaceholder(({String label, IconData icon}) meta) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      child: Center(
        child:
            Icon(meta.icon, size: 24, color: Colors.grey.withValues(alpha: 0.5)),
      ),
    );
  }
}
