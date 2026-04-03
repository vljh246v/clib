import 'package:flutter/material.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/notification_service.dart';

class LabelManagementScreen extends StatefulWidget {
  const LabelManagementScreen({super.key});

  @override
  State<LabelManagementScreen> createState() => _LabelManagementScreenState();
}

class _LabelManagementScreenState extends State<LabelManagementScreen> {
  static const _colorOptions = [
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFF5C6BC0),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFFFFCA28),
    Color(0xFF26C6DA),
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final labels = DatabaseService.getAllLabelObjects();

    return Scaffold(
      appBar: AppBar(
        title: const Text('라벨 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showLabelDialog(),
          ),
        ],
      ),
      body: labels.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_off_outlined,
                      size: 48, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    '라벨이 없습니다.\n+ 버튼으로 추가해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: labels.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final label = labels[index];
                final stats = DatabaseService.getLabelStats(label.name);
                final color = Color(label.colorValue);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    radius: 18,
                    child: Text(
                      label.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(label.name),
                  subtitle: Text('${stats.total}개 아티클 · ${stats.read}개 읽음'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          label.notificationEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: label.notificationEnabled
                              ? color
                              : Colors.grey.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        onPressed: () => _showNotificationDialog(label),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  onTap: () => _showLabelDialog(label: label),
                  onLongPress: () => _confirmDelete(label),
                );
              },
            ),
    );
  }

  Future<void> _showNotificationDialog(Label label) async {
    var enabled = label.notificationEnabled;
    var selectedDays = Set<int>.from(label.notificationDays);
    final timeParts = label.notificationTime.split(':');
    var selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${label.name} 알림'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('알림 받기'),
                value: enabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setDialogState(() => enabled = v),
              ),
              if (enabled) ...[
                const SizedBox(height: 8),
                const Text('요일', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (i) {
                    final isSelected = selectedDays.contains(i);
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        if (isSelected) {
                          selectedDays.remove(i);
                        } else {
                          selectedDays.add(i);
                        }
                      }),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(label.colorValue)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Color(label.colorValue)
                                : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('시간'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                if (enabled) {
                  await NotificationService.requestPermission();
                }
                final timeStr =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                await DatabaseService.updateLabelNotification(
                  label,
                  enabled: enabled,
                  days: selectedDays.toList()..sort(),
                  time: timeStr,
                );
                if (enabled) {
                  await NotificationService.scheduleForLabel(label);
                } else {
                  await NotificationService.cancelForLabel(label);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLabelDialog({Label? label}) async {
    final isEdit = label != null;
    final nameController = TextEditingController(text: label?.name ?? '');
    var selectedColor =
        label != null ? Color(label.colorValue) : _colorOptions.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? '라벨 수정' : '라벨 추가'),
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
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.5),
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
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                try {
                  if (isEdit) {
                    await DatabaseService.updateLabel(
                      label,
                      newName: name,
                      newColor: selectedColor,
                    );
                  } else {
                    await DatabaseService.createLabel(name, selectedColor);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Label label) async {
    final stats = DatabaseService.getLabelStats(label.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('라벨 삭제'),
        content: Text(
          '\'${label.name}\' 라벨을 삭제할까요?\n'
          '${stats.total}개 아티클에서 이 라벨이 제거됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.cancelForLabel(label);
      await DatabaseService.deleteLabel(label);
      setState(() {});
    }
  }
}
