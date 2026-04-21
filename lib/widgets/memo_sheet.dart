import 'package:flutter/material.dart';
import 'package:clib/blocs/article_list/article_list_cubit.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/theme/design_tokens.dart';

/// 메모 입력 바텀시트.
///
/// [TextEditingController]를 StatefulWidget 라이프사이클로 관리해
/// 시트가 닫힐 때 반드시 dispose된다.
class MemoSheet extends StatefulWidget {
  const MemoSheet({super.key, required this.article, required this.cubit});

  final Article article;
  final ArticleListCubit cubit;

  /// [showModalBottomSheet] 편의 헬퍼.
  static Future<void> show(
    BuildContext context, {
    required Article article,
    required ArticleListCubit cubit,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => MemoSheet(article: article, cubit: cubit),
    );
  }

  @override
  State<MemoSheet> createState() => _MemoSheetState();
}

class _MemoSheetState extends State<MemoSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.article.memo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.md),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(l.memo, style: theme.textTheme.titleSmall),
            const SizedBox(height: Spacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: TextField(
                controller: _controller,
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
                  if (widget.article.memo != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: Radii.borderMd,
                          ),
                        ),
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await widget.cubit.updateMemo(widget.article, null);
                          if (mounted) nav.pop();
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
                        final nav = Navigator.of(context);
                        await widget.cubit.updateMemo(
                          widget.article,
                          _controller.text.isEmpty ? null : _controller.text,
                        );
                        if (mounted) nav.pop();
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
    );
  }
}
