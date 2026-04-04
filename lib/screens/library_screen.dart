import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/screens/all_articles_screen.dart';
import 'package:clib/screens/bookmarked_articles_screen.dart';
import 'package:clib/screens/label_detail_screen.dart';
import 'package:clib/theme/design_tokens.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final labels = DatabaseService.getAllLabelObjects();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text('보관함', style: theme.textTheme.displaySmall),
        const SizedBox(height: Spacing.sm),
        _buildOverallStats(labels, theme, isDark),
        const SizedBox(height: Spacing.xl),
        Text('라벨별 현황', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 0.95,
          ),
          itemCount: labels.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAllCard(theme, isDark);
            if (index == 1) return _buildBookmarkCard(theme, isDark);
            return _buildLabelCard(labels[index - 2], theme, isDark);
          },
        ),
      ],
    );
  }

  /// 전체 통계 요약 카드
  Widget _buildOverallStats(List<Label> labels, ThemeData theme, bool isDark) {
    var totalArticles = 0;
    var totalRead = 0;
    for (final label in labels) {
      final stats = DatabaseService.getLabelStats(label.name);
      totalArticles += stats.total;
      totalRead += stats.read;
    }
    final progress = totalArticles > 0 ? totalRead / totalArticles : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: Radii.borderLg,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: theme.colorScheme.secondary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CustomPaint(
                        painter: _CircularProgressPainter(
                          progress: progress,
                          color: theme.colorScheme.secondary,
                          backgroundColor: theme.colorScheme.secondary
                              .withValues(alpha: 0.12),
                          strokeWidth: 5,
                        ),
                        child: Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('전체 읽기 현황', style: theme.textTheme.titleSmall),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            '$totalRead / $totalArticles 아티클 읽음',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${labels.length}개 라벨',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: Radii.borderSm,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 전체 아티클 카드
  Widget _buildAllCard(ThemeData theme, bool isDark) {
    final stats = DatabaseService.getOverallStats();
    final color = theme.colorScheme.primary;
    final progress = stats.total > 0 ? stats.read / stats.total : 0.0;
    final unread = stats.total - stats.read;
    final percent = stats.total > 0 ? (progress * 100).round() : 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllArticlesScreen()),
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: Radii.borderLg,
          boxShadow: AppShadows.card(isDark),
        ),
        child: Column(
          children: [
            // 상단 컬러 바
            Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: Spacing.md),
              decoration: BoxDecoration(
                color: color,
                borderRadius: Radii.borderFull,
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                  strokeWidth: 4,
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '전체',
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge(
                  '전체 ${stats.total}',
                  theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                _statBadge(
                  '안읽음 $unread',
                  unread > 0 ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 북마크 카드 (그리드 아이템)
  Widget _buildBookmarkCard(ThemeData theme, bool isDark) {
    final stats = DatabaseService.getBookmarkStats();
    final color = theme.colorScheme.secondary;
    final unread = stats.total - stats.read;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookmarkedArticlesScreen()),
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: Radii.borderLg,
          boxShadow: AppShadows.card(isDark),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: Spacing.md),
              decoration: BoxDecoration(
                color: color,
                borderRadius: Radii.borderFull,
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.bookmark_rounded, size: 32, color: color),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '북마크',
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge(
                  '전체 ${stats.total}',
                  theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                _statBadge(
                  '안읽음 $unread',
                  unread > 0 ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 라벨 카드 (그리드 아이템)
  Widget _buildLabelCard(Label label, ThemeData theme, bool isDark) {
    final stats = DatabaseService.getLabelStats(label.name);
    final color = Color(label.colorValue);
    final progress = stats.total > 0 ? stats.read / stats.total : 0.0;
    final unread = stats.total - stats.read;
    final percent = stats.total > 0 ? (progress * 100).round() : 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LabelDetailScreen(label: label)),
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: Radii.borderLg,
          boxShadow: AppShadows.card(isDark),
        ),
        child: Column(
          children: [
            // 상단 라벨 컬러 바
            Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: Spacing.md),
              decoration: BoxDecoration(
                color: color,
                borderRadius: Radii.borderFull,
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                  strokeWidth: 4,
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              label.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge(
                  '전체 ${stats.total}',
                  theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                _statBadge(
                  '안읽음 $unread',
                  unread > 0 ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 원형 프로그레스 바 Painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) {
    return old.progress != progress || old.color != color;
  }
}
