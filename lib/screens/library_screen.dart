import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/screens/all_articles_screen.dart';
import 'package:clib/screens/label_detail_screen.dart';

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
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '보관함',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // 전체 통계 요약
        _buildOverallStats(labels, theme, isDark),
        const SizedBox(height: 20),
        Text(
          '라벨별 현황',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // 2열 그리드 (전체 카드 + 라벨 카드)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: labels.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAllCard(theme, isDark);
            return _buildLabelCard(labels[index - 1], theme, isDark);
          },
        ),
      ],
    );
  }

  /// 전체 통계 요약 카드
  Widget _buildOverallStats(
      List<Label> labels, ThemeData theme, bool isDark) {
    var totalArticles = 0;
    var totalRead = 0;
    for (final label in labels) {
      final stats = DatabaseService.getLabelStats(label.name);
      totalArticles += stats.total;
      totalRead += stats.read;
    }
    final progress = totalArticles > 0 ? totalRead / totalArticles : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 큰 원형 프로그레스
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progress,
                color: theme.colorScheme.secondary,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                strokeWidth: 6,
              ),
              child: Center(
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전체 읽기 현황',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalRead / $totalArticles 아티클 읽음',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${labels.length}개 라벨',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  strokeWidth: 5,
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
            const SizedBox(height: 10),
            Text(
              '전체',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge('전체 ${stats.total}', Colors.grey.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                _statBadge(
                  '안읽음 $unread',
                  unread > 0
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.5),
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
          MaterialPageRoute(
            builder: (_) => LabelDetailScreen(label: label),
          ),
        );
        // 돌아오면 상태 갱신 (읽음 처리 등 반영)
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 원형 프로그레스 + 퍼센트
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  strokeWidth: 5,
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
            const SizedBox(height: 10),
            // 라벨명
            Text(
              label.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            // 통계 수치
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge('전체 ${stats.total}', Colors.grey.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                _statBadge(
                  '안읽음 $unread',
                  unread > 0
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.5),
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

    // 배경 원
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 프로그레스 호
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
