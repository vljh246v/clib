import 'package:flutter/material.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';

/// 아티클의 라벨을 편집하는 바텀시트
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LabelEditSheet(article: article, onChanged: onChanged),
    );
  }

  @override
  State<LabelEditSheet> createState() => _LabelEditSheetState();
}

class _LabelEditSheetState extends State<LabelEditSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.article.topicLabels);
  }

  @override
  Widget build(BuildContext context) {
    final labels = DatabaseService.getAllLabelObjects();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들 바
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '라벨 편집',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.article.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '설정에서 라벨을 먼저 추가해주세요',
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.map((label) {
                final isSelected = _selected.contains(label.name);
                final color = Color(label.colorValue);
                return FilterChip(
                  label: Text(label.name),
                  selected: isSelected,
                  selectedColor: color.withValues(alpha: 0.3),
                  checkmarkColor: color,
                  side: BorderSide(
                    color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await DatabaseService.updateArticleLabels(
      widget.article,
      _selected.toList(),
    );
    widget.onChanged?.call();
    if (mounted) Navigator.pop(context);
  }
}
