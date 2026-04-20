# PR 5 — LabelManagementCubit

> 라벨 CRUD + 라벨별 알림 설정 화면. 다이얼로그 내부 `StatefulBuilder`는 유지하고, 저장 경계만 Cubit으로 뺀다.

**의존성**: PR 1
**브랜치**: `feature/bloc-05-label-mgmt`
**예상 작업 시간**: 2~3시간
**난이도**: ⭐⭐

---

## 1. 목표

- `lib/blocs/label_management/label_management_cubit.dart` + state
- 상태: `labels: List<Label>`, `labelStats: Map<String, LabelStats>`, `isSaving: bool`
- 메서드: `load()`, `createLabel(name, color)`, `updateLabel(label, newName, newColor)`, `deleteLabel(label)`, `updateNotification(label, enabled, days, time)`
- 기존 다이얼로그 로컬 상태(`StatefulBuilder` 내부)는 **그대로 유지**
- `LabelManagementScreen` StatelessWidget 전환 + BlocBuilder
- 유닛 테스트

---

## 2. 사전 요건

| 파일 | 범위 |
|------|------|
| `lib/screens/label_management_screen.dart` | 전체 (514 LOC) |
| `lib/services/database_service.dart` | `getAllLabelObjects`, `getLabelStats`, `createLabel`, `updateLabel`, `deleteLabel`, `updateLabelNotification` |
| `lib/services/notification_service.dart` | `requestPermission`, `scheduleForLabel`, `cancelForLabel` |

**핵심 사실**:
- 다이얼로그 내부 요일 선택 / 시간 선택 / 스위치 상태는 **다이얼로그 수명 동안만 유효** → StatefulBuilder로 처리
- Cubit은 다이얼로그의 **최종 저장 시점**에만 관여
- `updateLabel` 호출 시 아티클의 라벨명 일괄 갱신이 자동으로 이루어짐 (DatabaseService 내부)

---

## 3. LabelManagementState

`lib/blocs/label_management/label_management_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../models/label.dart';

class LabelManagementState extends Equatable {
  final List<Label> labels;
  final Map<String, LabelStats> labelStats;
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
    Map<String, LabelStats>? labelStats,
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
```

---

## 4. LabelManagementCubit

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main.dart' show labelsChangedNotifier;
import '../../models/label.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import 'label_management_state.dart';

class LabelManagementCubit extends Cubit<LabelManagementState> {
  LabelManagementCubit() : super(const LabelManagementState()) {
    labelsChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => load();

  Future<void> load() async {
    final labels = DatabaseService.getAllLabelObjects();
    final stats = <String, LabelStats>{
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
        notificationEnabled: enabled,
        notificationDays: days,
        notificationTime: time,
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

  @override
  Future<void> close() {
    labelsChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
```

**주의**: `DatabaseService.updateLabelNotification`의 정확한 시그니처를 읽어서 맞춘다. named 파라미터 순서/이름 확인 필수.

---

## 5. LabelManagementScreen 교체

### 5.1 Stateless 전환

```dart
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
```

### 5.2 다이얼로그 내부

다이얼로그 자체는 `StatefulBuilder`로 유지. 저장 버튼에서:

**Before**:
```dart
onPressed: () async {
  await DatabaseService.createLabel(name, color);
  Navigator.pop(context);
  setState(() {});
},
```

**After**:
```dart
onPressed: () async {
  await context.read<LabelManagementCubit>().createLabel(name, color);
  if (!context.mounted) return;
  Navigator.pop(context);
},
```

**주의**: `context`가 다이얼로그 내부라 `BlocProvider` 상위에서 얻어야 한다. 다이얼로그 `showDialog` 호출 시 `context`를 부모의 것으로 사용(빌더 내에서는 `context.read` 가 상위 BlocProvider까지 탐색 가능).

### 5.3 리스트 빌드

```dart
BlocBuilder<LabelManagementCubit, LabelManagementState>(
  builder: (context, state) {
    if (state.isLoading) return const CircularProgressIndicator();
    return ListView.builder(
      itemCount: state.labels.length,
      itemBuilder: (context, i) {
        final label = state.labels[i];
        final stats = state.labelStats[label.name]!;
        return _LabelTile(label: label, stats: stats);
      },
    );
  },
)
```

### 5.4 에러 처리

`BlocListener`로 errorMessage 변경 시 SnackBar:

```dart
BlocListener<LabelManagementCubit, LabelManagementState>(
  listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
  listener: (context, state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.errorMessage!)),
    );
    context.read<LabelManagementCubit>().emit(state.copyWith(clearError: true));
    // 주의: emit은 외부에서 호출 불가(protected). clearError 메서드를 Cubit에 추가하거나 SnackBar 후 상태 그대로 둠.
  },
  child: ...
)
```

**개선**: 위 코드처럼 외부에서 `emit` 불가. Cubit에 `void clearError() => emit(state.copyWith(clearError: true));` 추가.

---

## 6. 주의사항

- `AuthService.isLoggedIn` 체크가 다이얼로그 빌드에 들어있다면(로그인 사용자에게만 동기화 경고) 그대로 유지.
- 알림 권한 요청(`requestPermission`)은 OS 다이얼로그를 띄우므로 await 필수.
- **라벨 삭제 시** 아티클의 `topicLabels`에서 자동 제거되는지 `DatabaseService.deleteLabel` 내부 구현 확인.

---

## 7. 테스트

DatabaseService 의존성으로 유닛 테스트 복잡. 최소:

```dart
test('LabelManagementState copyWith clearError', () {
  final s1 = LabelManagementState(errorMessage: 'x');
  final s2 = s1.copyWith(clearError: true);
  expect(s2.errorMessage, isNull);
});
```

Cubit 통합 테스트는 실기기 QA로 커버.

---

## 8. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크

- [ ] 라벨 추가 → 리스트에 즉시 등장
- [ ] 라벨 이름 변경 → 아티클들의 라벨 자동 갱신
- [ ] 라벨 색상 변경 → 라이브러리 그리드 반영
- [ ] 라벨 삭제 → 해당 라벨이 달린 아티클에서 라벨 제거
- [ ] 알림 토글 ON + 요일 + 시간 저장 → 실제 알림 예약 확인
- [ ] 알림 토글 OFF → 예약된 알림 취소
- [ ] 권한 거부 후 토글 ON → 적절한 안내 (에러 SnackBar 또는 무반응)

---

## 9. 커밋 메시지

```
BLoC PR5: LabelManagementCubit 도입 — 라벨 CRUD + 알림 설정 이동

- lib/blocs/label_management/ 신규
- 다이얼로그 내부 StatefulBuilder는 유지, 저장 경계만 Cubit으로
- NotificationService 호출 일원화
- 에러 메시지를 상태로 승격 + BlocListener SnackBar
```

---

## 10. 핸드오프 노트

### 계획대로 된 점
- (작성)

### 계획과 다르게 된 점
- (작성)

### 새로 발견한 이슈 / TODO
- (작성)

### 참고한 링크
- (작성)

### 다음 세션 유의사항
- (작성)

### 검증 결과
- (작성)
