import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/share_service.dart';
import 'package:clib/theme/design_tokens.dart';

/// Android 공유 인텐트 수신 시 라벨 선택 후 저장하는 바텀시트
class ShareLabelSheet extends StatefulWidget {
  final String url;

  const ShareLabelSheet({super.key, required this.url});

  static Future<void> show(BuildContext context, {required String url}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => ShareLabelSheet(url: url),
    );
  }

  @override
  State<ShareLabelSheet> createState() => _ShareLabelSheetState();
}

class _ShareLabelSheetState extends State<ShareLabelSheet> {
  final Set<String> _selected = {};
  bool _saving = false;

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
                  final isSelected = selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
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
                            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
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
      child: SafeArea(
        top: false,
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
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            l.saveToClib,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            widget.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.lg),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: Spacing.lg),
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
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
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
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
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
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ShareService.processAndSave(
        widget.url,
        labels: _selected.toList(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed)),
        );
      }
    }
  }
}
