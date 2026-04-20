# PR 4 — LibraryCubit

> 라이브러리 메인 화면(전체/북마크/라벨 그리드). `articlesChangedNotifier` + `labelsChangedNotifier` 두 전역 notifier를 Cubit으로 브릿지한다.

**의존성**: PR 1
**브랜치**: `feature/bloc-04-library`
**예상 작업 시간**: 2시간
**난이도**: ⭐⭐

---

## 1. 목표

- `lib/blocs/library/library_cubit.dart` + `library_state.dart` 신규
- 로드 대상: 라벨 목록, 전체 통계, 북마크 통계, 라벨별 통계 Map
- 두 notifier 구독 → 변경 시 자동 재로드
- `LibraryScreen`을 `BlocBuilder`로 교체
- 유닛 테스트

---

## 2. 사전 요건

| 파일 | 범위 |
|------|------|
| `lib/screens/library_screen.dart` | 전체 (445 LOC) |
| `lib/services/database_service.dart` | `getAllLabelObjects`, `getOverallStats`, `getLabelStats`, `getBookmarkStats` 시그니처 |
| `lib/main.dart:23-32` | notifier 정의 확인 |

**핵심 사실**:
- LibraryScreen은 로컬 상태 없음. 두 notifier의 addListener로 `setState((){})`만 함.
- Navigator.push 후 복귀 시에도 `setState((){})` 호출 (L184, L263, L329).
- 2열 GridView (index 0 = 전체, 1 = 북마크, 2+ = 라벨).

---

## 3. LibraryState

`lib/blocs/library/library_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../models/label.dart';

class LibraryState extends Equatable {
  final List<Label> labels;
  final OverallStats overall;
  final BookmarkStats bookmark;
  final Map<String, LabelStats> labelStats; // key = label.name
  final bool isLoading;

  const LibraryState({
    this.labels = const [],
    this.overall = OverallStats.zero,
    this.bookmark = BookmarkStats.zero,
    this.labelStats = const {},
    this.isLoading = true,
  });

  LibraryState copyWith({
    List<Label>? labels,
    OverallStats? overall,
    BookmarkStats? bookmark,
    Map<String, LabelStats>? labelStats,
    bool? isLoading,
  }) {
    return LibraryState(
      labels: labels ?? this.labels,
      overall: overall ?? this.overall,
      bookmark: bookmark ?? this.bookmark,
      labelStats: labelStats ?? this.labelStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [labels, overall, bookmark, labelStats, isLoading];
}
```

**주의**: `OverallStats` / `BookmarkStats` / `LabelStats` 는 `DatabaseService`가 반환하는 타입이다. 실제 이름은 코드에서 확인하고 맞춰야 한다. 만약 이들이 class/record가 아니라 `Map`이면 Map으로 가져와 그대로 사용해도 된다. **우선 코드를 읽고 타입을 맞춘다.**

만약 통계가 Map 형태라면 props 비교에 문제가 있을 수 있으니 `DeepCollectionEquality`를 사용하거나 별도 value class를 도입한다.

---

## 4. LibraryCubit

`lib/blocs/library/library_cubit.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main.dart' show articlesChangedNotifier, labelsChangedNotifier;
import '../../services/database_service.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState()) {
    articlesChangedNotifier.addListener(_onChanged);
    labelsChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => load();

  Future<void> load() async {
    // DatabaseService는 동기 API지만, 향후 async로 바뀔 수 있으니 Future.
    final labels = DatabaseService.getAllLabelObjects();
    final overall = DatabaseService.getOverallStats();
    final bookmark = DatabaseService.getBookmarkStats();
    final stats = <String, LabelStats>{
      for (final l in labels) l.name: DatabaseService.getLabelStats(l.name),
    };
    emit(LibraryState(
      labels: labels,
      overall: overall,
      bookmark: bookmark,
      labelStats: stats,
      isLoading: false,
    ));
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    labelsChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
```

---

## 5. LibraryScreen 교체

### 5.1 BlocProvider 삽입

`MainScreen`에서 LibraryScreen을 빌드하는 지점 또는 LibraryScreen 자체 상단:

```dart
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryCubit(),
      child: const _LibraryBody(),
    );
  }
}
```

### 5.2 notifier addListener 제거

기존 `initState`의 `articlesChangedNotifier.addListener(_refresh)` / `labelsChangedNotifier.addListener(_refresh)` 및 `dispose()` 제거. StatelessWidget으로 다운그레이드.

### 5.3 Navigator.push 후 복귀 처리

복귀 시 `setState((){})` 대신:

```dart
await Navigator.push(...);
if (!context.mounted) return;
context.read<LibraryCubit>().load();
```

이 부분이 가장 실수하기 쉬움. Navigator.push를 호출하는 **모든 카드 onTap**에서 적용.

### 5.4 그리드 빌드

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<LibraryCubit, LibraryState>(
    builder: (context, state) {
      if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          // ...
        ),
        itemCount: 2 + state.labels.length,
        itemBuilder: (context, index) {
          if (index == 0) return _AllCard(state.overall);
          if (index == 1) return _BookmarkCard(state.bookmark);
          final label = state.labels[index - 2];
          final stats = state.labelStats[label.name]!;
          return _LabelCard(label: label, stats: stats);
        },
      );
    },
  );
}
```

---

## 6. 주의사항

- **`articlesChangedNotifier`가 초기에 `value = 0`으로 시작하므로** 생성자에서 `load()`를 바로 호출해야 첫 빌드가 비어 보이지 않는다.
- Cubit을 공유하지 말 것. `MainScreen`의 탭 전환 시 라이브러리 탭이 사라졌다 돌아와도 BlocProvider 스코프가 유지되면 Cubit도 유지된다. 이 경우 notifier 구독 중복을 피할 수 있음.
- **Navigator.push → pop 후 `context.read<LibraryCubit>().load()`** 를 빠뜨리면 다른 화면에서의 변경이 notifier를 통해 전파됐더라도 stale하게 느껴질 수 있다. 다만 notifier 구독이 이미 있으므로 대부분 자동 갱신됨. 명시적 load는 **notifier를 쏘지 않는 단발성 액션**(예: 설정 변경)에만 필요.

---

## 7. 테스트

`test/blocs/library_cubit_test.dart`:

```dart
// DatabaseService의 Hive 의존성 때문에 순수 유닛 테스트 어려움.
// PR 1의 테스트 패턴을 재사용:
// 1) 테스트 setUp에서 Hive.initFlutter + DatabaseService.init
// 2) seed 데이터 넣기
// 3) Cubit load 후 state 검증
```

완전한 테스트가 시간 소모가 크면 **상태 클래스 copyWith 테스트만** 작성하고 Cubit 통합 테스트는 실기기 QA로 대체(핸드오프 노트에 기록).

---

## 8. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크

- [ ] 라이브러리 탭 → 전체 / 북마크 / 라벨 카드 숫자 정상
- [ ] 홈에서 카드 스와이프(읽음) → 라이브러리 복귀 시 "안 읽은" 수 감소
- [ ] 공유 시트로 새 URL 추가 → 라이브러리 "전체" 수 증가
- [ ] 라벨 추가/이름 변경/삭제 → 라벨 그리드 즉시 반영
- [ ] 북마크 토글 → 북마크 카드 수 변경

---

## 9. 커밋 메시지

```
BLoC PR4: LibraryCubit 도입 — notifier 브릿지 기반 재로드

- lib/blocs/library/ 신규 (cubit, state)
- 두 전역 notifier를 Cubit에서 구독
- LibraryScreen → StatelessWidget + BlocBuilder
- Navigator 복귀 시 명시적 load 호출
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
