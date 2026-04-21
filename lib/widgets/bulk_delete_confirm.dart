import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/article_list/article_list_cubit.dart';
import 'package:clib/l10n/app_localizations.dart';

/// 다중 선택 일괄 삭제 확인 다이얼로그.
///
/// `AllArticles` / `Bookmarked` / `LabelDetail` 3화면 공통 헬퍼.
/// `ctx.read<ArticleListCubit>()`로 현재 선택을 가져와 확인 후 `bulkDelete()`.
Future<void> showBulkDeleteConfirm(BuildContext context) async {
  final cubit = context.read<ArticleListCubit>();
  final l = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final count = cubit.state.selectedKeys.length;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteArticle),
      content: Text(l.deleteSelectedConfirm(count)),
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
  if (confirmed == true) {
    await cubit.bulkDelete();
  }
}
