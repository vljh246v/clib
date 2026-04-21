import 'dart:ui' show Color;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/state/app_notifiers.dart' show labelsChangedNotifier;
import 'package:clib/services/database_service.dart';
import 'package:clib/services/share_service.dart';
import 'add_article_state.dart';

/// 수동 아티클 추가 바텀시트 Cubit.
///
/// - 라벨 목록은 `labelsChangedNotifier` 구독으로 자동 갱신.
/// - URL 유효성 검증은 Cubit 내부에서 수행(기존 `Uri.tryParse + hasScheme +
///   host` 동치). 실패 시 `urlError='invalid_url'` 센티넬.
/// - 저장 성공 시 `isDone=true` → 위젯이 Navigator.pop. Cubit이 직접 pop 불가.
/// - 저장 예외 시 `failureMessage` 셋 → listener가 SnackBar 후 `clearFailure()`.
/// - `articlesChangedNotifier`는 `DatabaseService.saveArticle`이 발사하므로
///   Cubit에서 중복 발사 금지.
class AddArticleCubit extends Cubit<AddArticleState> {
  AddArticleCubit() : super(const AddArticleState()) {
    labelsChangedNotifier.addListener(_refreshLabels);
    _refreshLabels();
  }

  void _refreshLabels() {
    emit(state.copyWith(allLabels: DatabaseService.getAllLabelObjects()));
  }

  void toggleLabel(String name) {
    final next = Set<String>.from(state.selectedLabels);
    if (!next.add(name)) next.remove(name);
    emit(state.copyWith(selectedLabels: next));
  }

  /// 새 라벨 생성 + 자동 선택. 성공 시 라벨 이름 반환, 실패 시 null.
  /// 실패 시 `labelErrorMessage`에 원문 메시지 emit.
  Future<String?> createLabel(String name, Color color) async {
    try {
      final created = await DatabaseService.createLabel(name, color);
      final labels = DatabaseService.getAllLabelObjects();
      emit(state.copyWith(
        allLabels: labels,
        selectedLabels: {...state.selectedLabels, created.name},
      ));
      return created.name;
    } catch (e) {
      emit(state.copyWith(labelErrorMessage: e.toString()));
      return null;
    }
  }

  /// URL 입력이 변경됐을 때 inline error만 해제.
  /// TextEditingController는 위젯 로컬 SSOT 유지.
  void urlInputChanged() {
    if (state.urlError != null) {
      emit(state.copyWith(clearUrlError: true));
    }
  }

  void clearSaveFailure() => emit(state.copyWith(saveFailure: false));

  void clearLabelError() => emit(state.copyWith(clearLabelError: true));

  Future<void> save(String rawUrl) async {
    final url = rawUrl.trim();
    if (!_isValidUrl(url)) {
      emit(state.copyWith(urlError: 'invalid_url'));
      return;
    }
    emit(state.copyWith(isSaving: true, clearUrlError: true));
    try {
      await ShareService.processAndSave(
        url,
        labels: state.selectedLabels.toList(),
      );
      emit(state.copyWith(isSaving: false, isDone: true));
    } catch (_) {
      emit(state.copyWith(isSaving: false, saveFailure: true));
    }
  }

  static bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  @override
  Future<void> close() {
    labelsChangedNotifier.removeListener(_refreshLabels);
    return super.close();
  }
}
