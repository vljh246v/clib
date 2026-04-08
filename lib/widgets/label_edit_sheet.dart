import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/platform_meta.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/design_tokens.dart';

/// 아티클의 플랫폼 + 라벨을 편집하는 바텀시트
class LabelEditSheet extends StatefulWidget {
  final Article article;
  final VoidCallback? onChanged;

  const LabelEditSheet({
    super.key,
    required this.article,
    this.onChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Article article,
    VoidCallback? onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => LabelEditSheet(article: article, onChanged: onChanged),
    );
  }

  @override
  State<LabelEditSheet> createState() => _LabelEditSheetState();
}

class _LabelEditSheetState extends State<LabelEditSheet> {
  late Set<String> _selected;
  late Platform _platform;

  static final _platformOptions = Platform.values.map((p) {
    final meta = platformMeta(p);
    return (p, meta.label, meta.icon);
  }).toList();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.article.topicLabels);
    _platform = widget.article.platform;
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
            l.editArticle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            widget.article.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),

          // ── 플랫폼 선택 ──
          const SizedBox(height: Spacing.xl),
          Text(l.platform, style: theme.textTheme.labelLarge),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: _platformOptions.map((opt) {
              final (value, label, icon) = opt;
              final isSelected = _platform == value;
              return ChoiceChip(
                avatar: Icon(icon, size: 16),
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => setState(() => _platform = value),
              );
            }).toList(),
          ),

          // ── 라벨 선택 ──
          const SizedBox(height: Spacing.xl),
          Text(l.label, style: theme.textTheme.labelLarge),
          const SizedBox(height: Spacing.sm),
          if (labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Center(
                child: Text(
                  l.addLabelsFirst,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: labels.map((label) {
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
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selected.add(label.name);
                      } else {
                        _selected.remove(label.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: Spacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: Radii.borderMd,
                ),
              ),
              onPressed: _save,
              child: Text(l.save),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _save() async {
    widget.article.platform = _platform;
    await DatabaseService.updateArticleLabels(
      widget.article,
      _selected.toList(),
    );
    widget.onChanged?.call();
    if (mounted) Navigator.pop(context);
  }
}
