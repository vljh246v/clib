import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/add_article/add_article_cubit.dart';
import 'package:clib/blocs/add_article/add_article_state.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/theme/design_tokens.dart';

/// 수동 URL 입력으로 아티클을 추가하는 바텀시트.
///
/// 상태는 [AddArticleCubit]이 소유. 위젯은 TextEditingController와 시트 UX만
/// 담당한다. 진입점은 [show] 정적 메서드 하나뿐이므로 일반 위젯으로 트리에
/// 직접 삽입하지 않는다.
class AddArticleSheet {
  const AddArticleSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => AddArticleCubit(),
        child: const _AddArticleBody(),
      ),
    );
  }
}

class _AddArticleBody extends StatefulWidget {
  const _AddArticleBody();

  @override
  State<_AddArticleBody> createState() => _AddArticleBodyState();
}

class _AddArticleBodyState extends State<_AddArticleBody> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final trimmed = text.trim();
    _urlController.text = trimmed;
    _urlController.selection = TextSelection.fromPosition(
      TextPosition(offset: trimmed.length),
    );
    if (!mounted) return;
    context.read<AddArticleCubit>().urlInputChanged();
  }

  Future<void> _showAddLabelDialog() async {
    final cubit = context.read<AddArticleCubit>();
    final nameController = TextEditingController();
    var selectedColor = LabelColors.presets.first;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.addNewLabelTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l.labelName,
                  hintText: l.labelNameHint,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: Spacing.lg),
              Text(l.color, style: theme.textTheme.labelLarge),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: LabelColors.presets.map((color) {
                  final isSelected =
                      selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
              onPressed: () {
                final trimmed = nameController.text.trim();
                if (trimmed.isEmpty) return;
                Navigator.pop(ctx, trimmed);
              },
              child: Text(l.add),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    if (name == null) return;
    await cubit.createLabel(name, selectedColor);
  }

  String? _resolveUrlError(String? code, AppLocalizations l) {
    if (code == null) return null;
    if (code == 'invalid_url') return l.invalidUrl;
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return BlocConsumer<AddArticleCubit, AddArticleState>(
      listenWhen: (prev, curr) =>
          (prev.isDone != curr.isDone && curr.isDone) ||
          (prev.saveFailure != curr.saveFailure && curr.saveFailure) ||
          (prev.labelErrorMessage != curr.labelErrorMessage &&
              curr.labelErrorMessage != null),
      listener: (ctx, state) {
        if (state.isDone) {
          Navigator.pop(ctx);
          return;
        }
        final cubit = ctx.read<AddArticleCubit>();
        if (state.saveFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(l.saveFailed)),
          );
          cubit.clearSaveFailure();
          return;
        }
        if (state.labelErrorMessage != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.labelErrorMessage!)),
          );
          cubit.clearLabelError();
        }
      },
      builder: (ctx, state) {
        return Padding(
          padding: EdgeInsets.only(
            left: Spacing.xxl,
            right: Spacing.xxl,
            top: Spacing.xxl,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + Spacing.xxl,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(l.addArticle, style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.lg),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: l.urlHint,
                    errorText: _resolveUrlError(state.urlError, l),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      tooltip: l.pasteFromClipboard,
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) =>
                      ctx.read<AddArticleCubit>().urlInputChanged(),
                ),
                const SizedBox(height: Spacing.lg),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: Spacing.lg),
                Text(l.label, style: theme.textTheme.labelLarge),
                const SizedBox(height: Spacing.md),
                if (state.allLabels.isNotEmpty)
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      ...state.allLabels.map((label) {
                        final isSelected =
                            state.selectedLabels.contains(label.name);
                        final color = Color(label.colorValue);
                        return FilterChip(
                          label: Text(label.name),
                          selected: isSelected,
                          selectedColor: color.withValues(alpha: 0.15),
                          checkmarkColor: color,
                          side: BorderSide(
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.25),
                          ),
                          onSelected: (_) => ctx
                              .read<AddArticleCubit>()
                              .toggleLabel(label.name),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(l.newLabel),
                        side: BorderSide(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.25),
                        ),
                        onPressed: _showAddLabelDialog,
                      ),
                    ],
                  ),
                if (state.allLabels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(l.newLabel),
                      side: BorderSide(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.25),
                      ),
                      onPressed: _showAddLabelDialog,
                    ),
                  ),
                const SizedBox(height: Spacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: Radii.borderMd,
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l.cancel),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: Radii.borderMd,
                          ),
                        ),
                        onPressed: state.isSaving
                            ? null
                            : () => ctx
                                .read<AddArticleCubit>()
                                .save(_urlController.text),
                        child: state.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
