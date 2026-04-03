import 'package:flutter/material.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/share_service.dart';

/// Android 공유 인텐트 수신 시 라벨 선택 후 저장하는 바텀시트
class ShareLabelSheet extends StatefulWidget {
  final String url;

  const ShareLabelSheet({super.key, required this.url});

  static Future<void> show(BuildContext context, {required String url}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            'Clib에 저장',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            '라벨',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '설정에서 라벨을 추가하면 여기서 선택할 수 있어요',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.7),
                  fontSize: 13,
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
                    color: isSelected
                        ? color
                        : Colors.grey.withValues(alpha: 0.3),
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
              }).toList(),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ShareService.processAndSave(
      widget.url,
      labels: _selected.toList(),
    );
    if (mounted) Navigator.pop(context);
  }
}
