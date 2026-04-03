import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/models/platform_meta.dart';
import 'package:clib/services/database_service.dart';

/// 라벨 상세 화면 — 해당 라벨의 아티클 리스트 + 읽음/안읽음 필터
class LabelDetailScreen extends StatefulWidget {
  final Label label;

  const LabelDetailScreen({super.key, required this.label});

  @override
  State<LabelDetailScreen> createState() => _LabelDetailScreenState();
}

class _LabelDetailScreenState extends State<LabelDetailScreen>
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

  List<Article> _getArticles() {
    return DatabaseService.getArticlesByLabel(widget.label.name);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.label.colorValue);
    final stats = DatabaseService.getLabelStats(widget.label.name);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text(
                widget.label.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.label.name),
          ],
        ),
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
          _buildArticleList(null, isDark, color),
          _buildArticleList(false, isDark, color),
          _buildArticleList(true, isDark, color),
        ],
      ),
    );
  }

  /// 아티클 리스트 (isReadFilter: null=전체, true=읽음, false=안읽음)
  Widget _buildArticleList(bool? isReadFilter, bool isDark, Color labelColor) {
    var articles = _getArticles();
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
      itemBuilder: (context, index) {
        final article = articles[index];
        return _buildArticleItem(article, isDark, labelColor);
      },
    );
  }

  /// 아티클 리스트 아이템
  Widget _buildArticleItem(Article article, bool isDark, Color labelColor) {
    final meta = platformMeta(article.platform);
    final createdDaysAgo =
        DateTime.now().difference(article.createdAt).inDays;
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
          color: article.isRead
              ? Colors.grey.withValues(alpha: 0.6)
              : null,
          decoration:
              article.isRead ? TextDecoration.lineThrough : null,
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
          ? Icon(Icons.check_circle, color: labelColor, size: 20)
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
        child: Icon(meta.icon, size: 24, color: Colors.grey.withValues(alpha: 0.5)),
      ),
    );
  }
}
