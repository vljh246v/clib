import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/main.dart' show labelsChangedNotifier, articlesChangedNotifier;
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/notification_service.dart';
import 'label_management_state.dart';

class LabelManagementCubit extends Cubit<LabelManagementState> {
  LabelManagementCubit() : super(const LabelManagementState()) {
    labelsChangedNotifier.addListener(_onChanged);
    articlesChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => unawaited(load());

  Future<void> load() async {
    final labels = DatabaseService.getAllLabelObjects();
    final stats = <String, ({int total, int read})>{
      for (final l in labels) l.name: DatabaseService.getLabelStats(l.name),
    };
    emit(state.copyWith(labels: labels, labelStats: stats, isLoading: false));
  }

  Future<void> createLabel(String name, Color color) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await DatabaseService.createLabel(name, color);
      await load();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> updateLabel(Label label, {String? newName, Color? newColor}) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await DatabaseService.updateLabel(label, newName: newName, newColor: newColor);
      await load();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> deleteLabel(Label label) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await NotificationService.cancelForLabel(label);
      await DatabaseService.deleteLabel(label);
      await load();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> updateNotification(
    Label label, {
    required bool enabled,
    required List<int> days,
    required String time,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await DatabaseService.updateLabelNotification(
        label,
        enabled: enabled,
        days: days,
        time: time,
      );
      if (enabled) {
        final granted = await NotificationService.requestPermission();
        if (granted) {
          await NotificationService.scheduleForLabel(label);
        }
      } else {
        await NotificationService.cancelForLabel(label);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    labelsChangedNotifier.removeListener(_onChanged);
    articlesChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
