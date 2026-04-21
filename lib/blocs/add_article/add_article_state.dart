import 'package:equatable/equatable.dart';
import 'package:clib/models/label.dart';

/// AddArticleSheet 상태.
///
/// - `urlError`: TextField inline errorText 용. 'invalid_url' 같은 로케일 키
///   센티넬. 위젯에서 `AppLocalizations`로 해석.
/// - `saveFailure`: 저장(`processAndSave`) 실패 토큰. listener가 `saveFailed`
///   i18n 문구로 SnackBar 노출 후 `clearSaveFailure()`.
/// - `labelErrorMessage`: 라벨 생성 실패 **원문** 메시지. 로컬 DB 예외는 이미
///   한국어/영문이 아닐 수 있으므로 그대로 SnackBar에 표시.
/// - `isDone`: 저장 성공 시 true. 위젯의 BlocListener가 Navigator.pop.
class AddArticleState extends Equatable {
  final Set<String> selectedLabels;
  final List<Label> allLabels;
  final bool isSaving;
  final String? urlError;
  final bool saveFailure;
  final String? labelErrorMessage;
  final bool isDone;

  const AddArticleState({
    this.selectedLabels = const {},
    this.allLabels = const [],
    this.isSaving = false,
    this.urlError,
    this.saveFailure = false,
    this.labelErrorMessage,
    this.isDone = false,
  });

  AddArticleState copyWith({
    Set<String>? selectedLabels,
    List<Label>? allLabels,
    bool? isSaving,
    String? urlError,
    bool clearUrlError = false,
    bool? saveFailure,
    String? labelErrorMessage,
    bool clearLabelError = false,
    bool? isDone,
  }) {
    return AddArticleState(
      selectedLabels: selectedLabels ?? this.selectedLabels,
      allLabels: allLabels ?? this.allLabels,
      isSaving: isSaving ?? this.isSaving,
      urlError: clearUrlError ? null : (urlError ?? this.urlError),
      saveFailure: saveFailure ?? this.saveFailure,
      labelErrorMessage: clearLabelError
          ? null
          : (labelErrorMessage ?? this.labelErrorMessage),
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [
        selectedLabels,
        allLabels,
        isSaving,
        urlError,
        saveFailure,
        labelErrorMessage,
        isDone,
      ];
}
