import 'package:equatable/equatable.dart';
import 'package:clib/models/label.dart';

class LabelManagementState extends Equatable {
  final List<Label> labels;
  final Map<String, ({int total, int read})> labelStats;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const LabelManagementState({
    this.labels = const [],
    this.labelStats = const {},
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  LabelManagementState copyWith({
    List<Label>? labels,
    Map<String, ({int total, int read})>? labelStats,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LabelManagementState(
      labels: labels ?? this.labels,
      labelStats: labelStats ?? this.labelStats,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [labels, labelStats, isLoading, isSaving, errorMessage];
}
