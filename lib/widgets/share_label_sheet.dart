import 'package:flutter/material.dart';
import 'package:clib/models/label.dart';
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
  static const _colorOptions = [
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFF5C6BC0),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFFFFCA28),
    Color(0xFF26C6DA),
    Color(0xFF8D6E63),
  ];

  final Set<String> _selected = {};
  bool _saving = false;

  Future<void> _showAddLabelDialog() async {
    final nameController = TextEditingController();
    var selectedColor = _colorOptions.first;

    final created = await showDialog<Label>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('새 라벨 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '라벨 이름',
                  hintText: '예: Flutter, 디자인',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('색상', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((color) {
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
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
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
              child: const Text('취소'),
            ),
            FilledButton(
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
              child: const Text('추가'),
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
          if (labels.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...labels.map((label) {
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
                }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('새 라벨'),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  onPressed: _showAddLabelDialog,
                ),
              ],
            ),
          if (labels.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('새 라벨'),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                onPressed: _showAddLabelDialog,
              ),
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
