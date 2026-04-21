import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/label_management/label_management_cubit.dart';
import 'package:clib/blocs/label_management/label_management_state.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/auth_service.dart';
import 'package:clib/theme/design_tokens.dart';

class LabelManagementScreen extends StatelessWidget {
  const LabelManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LabelManagementCubit(),
      child: const _LabelManagementBody(),
    );
  }
}

class _LabelManagementBody extends StatelessWidget {
  const _LabelManagementBody();

  List<String> _dayLabels(AppLocalizations l) =>
      [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LabelManagementCubit, LabelManagementState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
        context.read<LabelManagementCubit>().clearError();
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final l = AppLocalizations.of(context)!;

        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(l.labelManagement)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l.labelManagement),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showLabelDialog(context),
              ),
            ],
          ),
          body: state.labels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.06),
                        ),
                        child: Icon(Icons.label_outline,
                            size: 40,
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        l.createLabelPrompt,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: Spacing.xl),
                      GestureDetector(
                        onTap: () => _showLabelDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.xl, vertical: Spacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            borderRadius: Radii.borderFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 18,
                                  color: theme.colorScheme.secondary),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                l.addNewLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: Radii.borderLg,
                      boxShadow: AppShadows.card(isDark),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: state.labels.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 56,
                        color: theme.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final label = state.labels[index];
                        final stats = state.labelStats[label.name]!;
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
                          title: Text(label.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              )),
                          subtitle: Text(
                            l.articleStats(stats.total, stats.read),
                            style: theme.textTheme.labelSmall,
                          ),
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
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _showNotificationDialog(context, label),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, label, stats),
                              ),
                            ],
                          ),
                          onTap: () => _showLabelDialog(context, label: label),
                        );
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _showNotificationDialog(
      BuildContext context, Label label) async {
    var enabled = label.notificationEnabled;
    var selectedDays = Set<int>.from(label.notificationDays);
    final timeParts = label.notificationTime.split(':');
    var selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final days = _dayLabels(l);
    final cubit = context.read<LabelManagementCubit>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.labelNotification(label.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: Text(l.receiveNotification),
                value: enabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setDialogState(() => enabled = v),
              ),
              if (AuthService.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Text(
                    l.notificationDeviceOnly,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (enabled) ...[
                const SizedBox(height: Spacing.sm),
                Text(l.daysOfWeek, style: theme.textTheme.labelLarge),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (i) {
                    final isSelected = selectedDays.contains(i);
                    final labelColor = Color(label.colorValue);
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
                          color:
                              isSelected ? labelColor : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? labelColor
                                : theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          days[i],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: Spacing.lg),
                GestureDetector(
                  onTap: () async {
                    var tempTime = DateTime(
                        2000, 1, 1, selectedTime.hour, selectedTime.minute);
                    await showModalBottomSheet(
                      context: ctx,
                      backgroundColor: theme.colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(Radii.xl)),
                      ),
                      builder: (sheetCtx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: Spacing.md),
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Text(l.selectTime,
                                style: theme.textTheme.titleSmall),
                            SizedBox(
                              height: 200,
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.time,
                                initialDateTime: tempTime,
                                use24hFormat: true,
                                onDateTimeChanged: (dt) => tempTime = dt,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  Spacing.xxl, 0, Spacing.xxl, Spacing.lg),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                    foregroundColor:
                                        theme.colorScheme.onSecondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: Radii.borderMd,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(sheetCtx);
                                  },
                                  child: Text(l.confirm),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    setDialogState(() {
                      selectedTime = TimeOfDay(
                          hour: tempTime.hour, minute: tempTime.minute);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg, vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: Radii.borderMd,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: Spacing.md),
                        Text(l.time, style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ],
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
                final timeStr =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                await cubit.updateNotification(
                  label,
                  enabled: enabled,
                  days: selectedDays.toList()..sort(),
                  time: timeStr,
                );
                if (cubit.state.errorMessage == null && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLabelDialog(BuildContext context, {Label? label}) async {
    final isEdit = label != null;
    final nameController = TextEditingController(text: label?.name ?? '');
    var selectedColor =
        label != null ? Color(label.colorValue) : LabelColors.presets.first;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<LabelManagementCubit>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? l.editLabelTitle : l.addLabelTitle),
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
                if (isEdit) {
                  await cubit.updateLabel(label,
                      newName: name, newColor: selectedColor);
                } else {
                  await cubit.createLabel(name, selectedColor);
                }
                if (cubit.state.errorMessage == null && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEdit ? l.edit : l.add),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Label label,
    ({int total, int read}) stats,
  ) async {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<LabelManagementCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteLabel),
        content: Text(l.deleteLabelConfirm(label.name, stats.total)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.deleteLabel(label);
    }
  }
}
