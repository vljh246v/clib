import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/share_service.dart';
import 'package:clib/theme/design_tokens.dart';

/// 수동 URL 입력으로 아티클을 추가하는 바텀시트
class AddArticleSheet extends StatefulWidget {
  const AddArticleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => const AddArticleSheet(),
    );
  }

  @override
  State<AddArticleSheet> createState() => _AddArticleSheetState();
}

class _AddArticleSheetState extends State<AddArticleSheet> {
  final _urlController = TextEditingController();
  final Set<String> _selected = {};
  bool _saving = false;
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!.trim();
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: _urlController.text.length),
      );
      setState(() => _urlError = null);
    }
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final l = AppLocalizations.of(context)!;

    if (!_isValidUrl(url)) {
      setState(() => _urlError = l.invalidUrl);
      return;
    }

    setState(() {
      _saving = true;
      _urlError = null;
    });

    await ShareService.processAndSave(
      url,
      labels: _selected.toList(),
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _showAddLabelDialog() async {
    final nameController = TextEditingController();
    var selectedColor = LabelColors.presets.first;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final created = await showDialog<Label>(
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
                                    blurRadius: 8)
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
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                try {
                  await DatabaseService.createLabel(name, selectedColor);
                  final label = DatabaseService.getAllLabelObjects()
                      .firstWhere((l) => l.name == name);
                  if (ctx.mounted) Navigator.pop(ctx, label);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(l.add),
            ),
          ],
        ),
      ),
    );

    if (created != null) {
      setState(() => _selected.add(created.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = DatabaseService.getAllLabelObjects();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.xxl,
        right: Spacing.xxl,
        top: Spacing.xxl,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들 바
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
          // URL 입력
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: l.urlHint,
              errorText: _urlError,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 20),
                tooltip: l.pasteFromClipboard,
                onPressed: _pasteFromClipboard,
              ),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_urlError != null) setState(() => _urlError = null);
            },
          ),
          const SizedBox(height: Spacing.lg),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: Spacing.lg),
          // 라벨 선택
          Text(l.label, style: theme.textTheme.labelLarge),
          const SizedBox(height: Spacing.md),
          if (labels.isNotEmpty)
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                ...labels.map((label) {
                  final isSelected = _selected.contains(label.name);
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
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(label.name);
                        } else {
                          _selected.remove(label.name);
                        }
                      });
                    },
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
          if (labels.isEmpty)
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
          // 버튼
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
                  onPressed: () => Navigator.pop(context),
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
