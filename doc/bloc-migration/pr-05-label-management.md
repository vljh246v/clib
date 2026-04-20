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

**세션 결과**: 🟢 완료 (2026-04-20)
**브랜치**: `feature/bloc-05-label-mgmt` (feature 커밋: `65ab02f`, 머지 커밋: `1ece09e`)

### 계획대로 된 점
- `lib/blocs/label_management/label_management_state.dart` + `label_management_cubit.dart` 신규 (플랜 3~4절과 대체로 동일).
- `LabelManagementScreen` StatefulWidget → StatelessWidget + `BlocProvider(LabelManagementCubit)` + `_LabelManagementBody` 교체.
- 다이얼로그 내부 `StatefulBuilder` 그대로 유지 — 요일/시간/스위치/색상 로컬 상태 보존.
- 저장 경계(`createLabel` / `updateLabel` / `deleteLabel` / `updateNotification`)만 Cubit으로 이동.
- `clearError()` public 메서드 + `BlocConsumer` listener에서 SnackBar 노출 후 즉시 `clearError` 호출.
- 유닛 테스트 3 PASS (`copyWith clearError` / `copyWith` 보존 / 초기 기본값).
- 서브에이전트 병렬 dispatch (Haiku: state + test, Sonnet: cubit, Sonnet: screen) → Opus 최종 리뷰 LGTM.

### 계획과 다르게 된 점
- **`Map<String, LabelStats>` → `Map<String, ({int total, int read})>`**: 플랜 3절 오기재. DatabaseService는 Dart record를 반환하므로 PR 4 교훈대로 record로 교체.
- **`updateLabelNotification` 파라미터명**: 플랜 4절의 `notificationEnabled` / `notificationDays` / `notificationTime`은 오기재 → 실제 시그니처 `enabled:` / `days:` / `time:`에 맞춤.
- **`articlesChangedNotifier`도 구독**: 플랜 4절은 `labelsChangedNotifier`만 언급. 그러나 라벨 통계(`getLabelStats`)가 아티클 `isRead`에 의존하므로 양쪽 notifier 모두 구독해야 stats가 최신화된다. `articlesChangedNotifier.addListener(_onChanged)` + `close()`에서 `removeListener` 짝 유지.
- **`_LabelManagementBody`는 StatelessWidget**: PR 3의 "StatefulWidget + BlocProvider 분리" 패턴은 PR 4에서 조건부 선택지로 재해석됨. 본 화면은 로컬 상태 0 → StatelessWidget 단일로 충분.
- **다이얼로그 cubit capture**: 플랜 5.2의 `ctx.read<LabelManagementCubit>()`는 `showDialog` 내부 route에서 provider 범위 이탈로 동작 불가. `final cubit = context.read<LabelManagementCubit>();`를 **`showDialog` 호출 전에 캡처**한 뒤 `StatefulBuilder` 내부 클로저가 참조.
- **`_showLabelDialog` try/catch 제거**: 기존 inline `ScaffoldMessenger.showSnackBar`는 Cubit `errorMessage` + `BlocListener` 경로로 일원화. 저장 버튼은 `cubit.state.errorMessage == null`로 성공 여부 판정 후에만 `Navigator.pop` — 실패 시 다이얼로그 열린 채 SnackBar만 표시되어 재시도 가능.
- **`_confirmDelete` stats를 파라미터로 수신**: screen에서 `DatabaseService` 의존을 완전히 제거하기 위해 `itemBuilder`에서 `state.labelStats[label.name]!`을 캡처해 `_confirmDelete(context, label, stats)`로 전달. `NotificationService.cancelForLabel` 호출도 `cubit.deleteLabel` 내부로 흡수 → screen 파일에서 `database_service.dart` / `notification_service.dart` import 완전 제거.
- **`listenWhen` 가드**: `prev.errorMessage != curr.errorMessage && curr.errorMessage != null`로 동일 메시지 재진입 시 SnackBar 중복 방지. PR 4보다 한 단계 엄격.
- **병렬 서브에이전트**: 사용자 지시로 3개 에이전트 병렬 실행(단순 파일은 Haiku, 로직은 Sonnet, 검토만 Opus). 글로벌 서브에이전트 모델 정책 그대로 적용.

### 새로 발견한 이슈 / TODO
- **`state.labels`와 `state.labelStats` 동기성**: `load()`에서 두 필드를 한 번에 emit하므로 현재는 안전. 추후 부분 emit(`copyWith(labels: ...)`만)이 추가되면 `itemBuilder`의 `state.labelStats[label.name]!` 강제 언랩에서 crash 가능. 메서드 추가 시 동시 emit 유지 규약.
- **`_showNotificationDialog` 타임피커 취소 거동**: `showModalBottomSheet`를 스와이프로 닫아도 `onDateTimeChanged`의 최종 `tempTime`이 `selectedTime`에 반영됨. 기존 Stateful 구현과 동일(회귀 아님). 명확한 취소 UX가 필요하면 confirmed flag 도입.
- **`updateNotification` 권한 거부 시 상태 불일치 가능성**: 알림 ON + `requestPermission()` 거부 → DB는 `enabled: true`로 저장되지만 실제 예약은 skip. 후속에서 권한 거부 시 `enabled` 롤백 또는 사용자 안내 추가 검토.
- **Cubit 통합 테스트 미작성**: state `copyWith` 3종만. `createLabel` / `updateLabel` / `deleteLabel` / `updateNotification` Hive 격리 통합은 PR 4 패턴으로 확장 가능. 현재는 실기기 QA로 커버(CLAUDE.md 컨벤션 허용 범위).
- **리뷰 nit(현재 미반영)**: (1) `createLabel` catch 직후 `emit(errorMessage)` + finally `emit(isSaving:false)`가 동일 프레임 2회 emit — `listenWhen` 가드 덕에 UX 영향 없으나 마이크로 중복. (2) `load()`의 `for (final l in labels)` 변수명이 다른 파일의 `AppLocalizations l`와 시각적 충돌(서로 다른 스코프라 컴파일 영향 없음). 모두 의도적 보류.
- **루트 untracked 파일**(`DECISION_LOG.md` / `PROJECT_STATE.md` / `doc/img/`): PR 4와 동일, 다른 스킬 산출물. PR 5 범위 밖.

### 참고한 링크
- flutter_bloc BlocConsumer: https://bloclibrary.dev/flutter-bloc-concepts/#blocconsumer
- Dart records: https://dart.dev/language/records#record-types
- PR 4 선례: `lib/blocs/library/`, `test/blocs/library_cubit_test.dart`

### 다음 세션 유의사항
- **PR 6(ArticleListCubit + AllArticles)**: Bookmarked/LabelDetail까지 공통화할 단일 Cubit 도입. `source` enum(`all` / `bookmarked` / `byLabel(name)`)으로 분기.
- **다중 선택(`_isSelecting` + `Set<dynamic> _selectedKeys`)**: Cubit 상태로 승격. Hive key는 `dynamic` 유지 — 타입 동일성 주의.
- **`articlesChangedNotifier`만 구독으로 충분**: PR 6은 라벨 목록 자체를 보여주지 않으므로 `labelsChangedNotifier` 불필요. (단 PR 7의 LabelDetail은 헤더에 라벨 정보 쓰면 별도 검토.)
- **screen 진입점 3개(AllArticles / Bookmarked / LabelDetail)** → 각 화면에서 `BlocProvider(create: (_) => ArticleListCubit(source: ...))`.
- **`InlineBannerAd` 8개마다 삽입**: UI 패턴. Cubit 상태엔 영향 없고 `itemBuilder` 책임.
- **라벨 통계 자동 갱신은 이미 보장**: PR 4/5의 양쪽 notifier 브릿지로 아티클 읽음/삭제 시 Library/LabelManagement가 자동 재로드됨. PR 6이 아티클을 변경하면 자동 파급.

### 검증 결과
- `flutter analyze`: ✅ No issues found (ran in 2.2s)
- `flutter test test/blocs/label_management_cubit_test.dart`: ✅ 3/3 passed
- 실기기 스모크: ⚪ 사용자 요청 시에만 (미수행)
- Opus 최종 리뷰: ✅ LGTM (nit 2건은 의도적 보류 — 위 TODO 참조)
