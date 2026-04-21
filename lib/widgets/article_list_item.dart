import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/platform_meta.dart';
import 'package:clib/theme/design_tokens.dart';

/// 아티클 목록의 단일 행 위젯.
///
/// 선택 모드(`isSelecting`)에서는 좌측에 체크박스가 표시되고
/// 탭 시 선택 상태를 토글한다. 일반 모드에서는 탭 → 브라우저, 롱프레스 → 액션 시트.
class ArticleListItem extends StatelessWidget {
  const ArticleListItem({
    super.key,
    required this.article,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onSelectionToggle,
    this.onLongPress,
    this.accentColor,
  });

  final Article article;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelectionToggle;
  final VoidCallback? onLongPress;

  /// 라벨 상세 화면 등 컨텍스트 색을 행 뱃지(읽음/북마크)에 강조하기 위한 옵션.
  /// 미지정 시 `theme.colorScheme.secondary` 사용.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final meta = platformMeta(article.platform);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    final accent = accentColor ?? theme.colorScheme.secondary;

    final createdDaysAgo =
        DateTime.now().difference(article.createdAt).inDays;
    final dateText = createdDaysAgo == 0
        ? l.today
        : createdDaysAgo == 1
        ? l.yesterday
        : l.daysAgo(createdDaysAgo);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Radii.borderLg,
        boxShadow: AppShadows.card(isDark),
      ),
      child: InkWell(
        borderRadius: Radii.borderLg,
        onTap: isSelecting ? onSelectionToggle : onTap,
        onLongPress: isSelecting ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.lg,
          ),
          child: Row(
            children: [
              if (isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onSelectionToggle(),
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
                            color: accent.withValues(alpha: 0.6),
                          ),
                        ],
                        if (article.isBookmarked) ...[
                          const SizedBox(width: Spacing.sm),
                          Icon(
                            Icons.bookmark,
                            size: 12,
                            color: accent.withValues(alpha: 0.6),
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
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
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
