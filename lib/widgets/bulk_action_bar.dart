import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/theme/design_tokens.dart';

/// 다중 선택 모드에서 하단에 표시되는 일괄 작업 버튼 바.
///
/// 2행 5버튼 구성:
/// - 행 1: 북마크 추가 | 북마크 해제
/// - 행 2: 안읽음 | 읽음 | 삭제(error 색상)
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    super.key,
    required this.onBookmark,
    required this.onRemoveBookmark,
    required this.onMarkUnread,
    required this.onMarkRead,
    required this.onDelete,
  });

  final VoidCallback onBookmark;
  final VoidCallback onRemoveBookmark;
  final VoidCallback onMarkUnread;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return SafeArea(
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
                    onPressed: onBookmark,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_remove, size: 18),
                    label: Text(l.removeBookmark),
                    onPressed: onRemoveBookmark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(l.unread),
                    onPressed: onMarkUnread,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(l.read),
                    onPressed: onMarkRead,
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
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
