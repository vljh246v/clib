import 'package:flutter_test/flutter_test.dart';
import 'package:clib/blocs/label_management/label_management_state.dart';

void main() {
  group('LabelManagementState', () {
    test('copyWith clearError removes errorMessage', () {
      const s1 = LabelManagementState(errorMessage: 'error');
      final s2 = s1.copyWith(clearError: true);
      expect(s2.errorMessage, isNull);
    });

    test('copyWith preserves errorMessage when clearError is false', () {
      const s1 = LabelManagementState(errorMessage: 'error');
      final s2 = s1.copyWith(isSaving: true);
      expect(s2.errorMessage, equals('error'));
    });

    test('initial state has correct defaults', () {
      const state = LabelManagementState();
      expect(state.labels, isEmpty);
      expect(state.labelStats, isEmpty);
      expect(state.isLoading, isTrue);
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, isNull);
    });
  });
}
