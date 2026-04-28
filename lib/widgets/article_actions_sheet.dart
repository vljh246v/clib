import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/blocs/article_list/article_list_cubit.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/utils/url_safety.dart';
import 'package:clib/widgets/memo_sheet.dart';

/// 아티클 롱프레스 액션 시트 (북마크/메모/읽음토글/브라우저/삭제).
///
/// 호출 측에서 [ArticleListCubit]을 미리 capture해 전달한다
/// (showModalBottomSheet route가 BlocProvider 범위를 이탈할 수 있음).
class ArticleActionsSheet {
  const ArticleActionsSheet._();

  static Future<void> show(
    BuildContext context, {
    required Article article,
    required ArticleListCubit cubit,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => _SheetBody(
        article: article,
        cubit: cubit,
        rootContext: context,
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.article,
    required this.cubit,
    required this.rootContext,
  });

  final Article article;
  final ArticleListCubit cubit;

  /// 시트 pop 이후에도 유효한 바깥 BuildContext (메모 시트 / 삭제 다이얼로그 진입용).
  final BuildContext rootContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Spacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ListTile(
            leading: Icon(
              article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            title: Text(article.isBookmarked ? l.removeBookmark : l.bookmark),
            onTap: () async {
              Navigator.pop(context);
              await cubit.toggleBookmark(article);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(article.memo != null ? l.editMemo : l.addMemo),
            subtitle: article.memo != null
                ? Text(
                    article.memo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              MemoSheet.show(rootContext, article: article, cubit: cubit);
            },
          ),
          ListTile(
            leading: Icon(
              article.isRead ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(article.isRead ? l.markAsUnread : l.markAsRead),
            onTap: () async {
              Navigator.pop(context);
              if (article.isRead) {
                await cubit.markUnread(article);
              } else {
                await cubit.markRead(article);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l.openInBrowser),
            onTap: () async {
              Navigator.pop(context);
              // M-4: http/https 스킴만 허용 (legacy 또는 변조된 DB 방어)
              final uri = parseAllowedUrl(article.url);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l.delete,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: rootContext,
                builder: (ctx2) => AlertDialog(
                  title: Text(l.deleteArticle),
                  content: Text(l.deleteArticleConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(ctx2, true),
                      child: Text(l.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await cubit.deleteArticle(article);
              }
            },
          ),
        ],
      ),
    );
  }
}
