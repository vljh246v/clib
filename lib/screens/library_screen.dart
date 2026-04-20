import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/library/library_cubit.dart';
import 'package:clib/blocs/library/library_state.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/label.dart';
import 'package:clib/screens/all_articles_screen.dart';
import 'package:clib/screens/bookmarked_articles_screen.dart';
import 'package:clib/screens/label_detail_screen.dart';
import 'package:clib/theme/design_tokens.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryCubit(),
      child: const _LibraryBody(),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Text(l.library, style: theme.textTheme.displaySmall),
            const SizedBox(height: Spacing.sm),
            _OverallStatsCard(state: state, theme: theme, l: l),
            const SizedBox(height: Spacing.xl),
            Text(l.labelStatus, style: theme.textTheme.titleMedium),
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
              itemCount: state.labels.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AllCard(
                    stats: state.overall,
                    theme: theme,
                    isDark: isDark,
                    l: l,
                  );
                }
                if (index == 1) {
                  return _BookmarkCard(
                    stats: state.bookmark,
                    theme: theme,
                    isDark: isDark,
                    l: l,
                  );
                }
                final label = state.labels[index - 2];
                final stats = state.labelStats[label.name] ??
                    const (total: 0, read: 0);
                return _LabelCard(
                  label: label,
                  stats: stats,
                  theme: theme,
                  isDark: isDark,
                  l: l,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// 전체 통계 요약 카드 (라벨 기반 합산).
class _OverallStatsCard extends StatelessWidget {
  const _OverallStatsCard({
    required this.state,
    required this.theme,
    required this.l,
  });

  final LibraryState state;
  final ThemeData theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    var totalArticles = 0;
    var totalRead = 0;
    for (final label in state.labels) {
      final stats = state.labelStats[label.name] ?? const (total: 0, read: 0);
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
                          Text(l.overallReadingStatus,
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            l.articlesRead(totalRead, totalArticles),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.labelCount(state.labels.length),
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

/// 전체 아티클 카드.
class _AllCard extends StatelessWidget {
  const _AllCard({
    required this.stats,
    required this.theme,
    required this.isDark,
    required this.l,
  });

  final ({int total, int read}) stats;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
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
        if (!context.mounted) return;
        await context.read<LibraryCubit>().load();
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
              l.all,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge(
                  l.totalAll(stats.total),
                  theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                _statBadge(
                  l.totalUnread(unread),
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

/// 북마크 카드.
class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.stats,
    required this.theme,
    required this.isDark,
    required this.l,
  });

  final ({int total, int read}) stats;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final color = theme.colorScheme.secondary;
    final unread = stats.total - stats.read;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookmarkedArticlesScreen()),
        );
        if (!context.mounted) return;
        await context.read<LibraryCubit>().load();
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
              l.bookmarks,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBadge(
                  l.totalAll(stats.total),
                  theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                _statBadge(
                  l.totalUnread(unread),
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

/// 라벨 카드.
class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.label,
    required this.stats,
    required this.theme,
    required this.isDark,
    required this.l,
  });

  final Label label;
  final ({int total, int read}) stats;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
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
        if (!context.mounted) return;
        await context.read<LibraryCubit>().load();
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
                  l.totalAll(stats.total),
                  theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                _statBadge(
                  l.totalUnread(unread),
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

/// 원형 프로그레스 바 Painter.
class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

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
