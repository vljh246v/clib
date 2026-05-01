# PR 8 — AddArticleCubit

> 아티클 수동 추가 바텀시트의 상태를 Cubit으로 이동. 클립보드 붙여넣기, URL 검증, 라벨 선택, 새 라벨 생성, 저장 플로우를 캡슐화.

**의존성**: PR 1
**브랜치**: `feature/bloc-08-add-article`
**예상 작업 시간**: 2시간
**난이도**: ⭐⭐

---

## 1. 목표

- `lib/blocs/add_article/add_article_cubit.dart` + state
- 상태: `url: String`, `selectedLabels: Set<String>`, `allLabels: List<Label>`, `isSaving: bool`, `urlError: String?`
- 메서드: `urlChanged(String)`, `pasteFromClipboard()`, `toggleLabel(String)`, `createLabel(name, color)`, `save()`
- `AddArticleSheet` StatefulWidget → StatelessWidget 또는 **TextEditingController만 남긴 minimal StatefulWidget**
- 유닛 테스트

---

## 2. 사전 요건

| 파일 | 범위 |
|------|------|
| `lib/widgets/add_article_sheet.dart` | 전체 (347 LOC) |
| `lib/services/share_service.dart:52-70` | `processAndSave(url, {labels})` 시그니처 |
| `lib/services/database_service.dart` | `createLabel`, `getAllLabelObjects` |

**핵심 사실**:
- 시트 표시 방식: `showModalBottomSheet`
- URL 검증: `ShareService.extractURL(raw)`로 실제 URL 추출
- 저장: `ShareService.processAndSave(url, labels: labelNames)` → `articlesChangedNotifier.value++` 자동 트리거됨

---

## 3. AddArticleState

`lib/blocs/add_article/add_article_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../models/label.dart';

class AddArticleState extends Equatable {
  final String url;
  final Set<String> selectedLabels;
  final List<Label> allLabels;
  final bool isSaving;
  final String? urlError;
  final bool isDone; // 저장 성공 → UI가 pop 트리거

  const AddArticleState({
    this.url = '',
    this.selectedLabels = const {},
    this.allLabels = const [],
    this.isSaving = false,
    this.urlError,
    this.isDone = false,
  });

  AddArticleState copyWith({
    String? url,
    Set<String>? selectedLabels,
    List<Label>? allLabels,
    bool? isSaving,
    String? urlError,
    bool clearUrlError = false,
    bool? isDone,
  }) {
    return AddArticleState(
      url: url ?? this.url,
      selectedLabels: selectedLabels ?? this.selectedLabels,
      allLabels: allLabels ?? this.allLabels,
      isSaving: isSaving ?? this.isSaving,
      urlError: clearUrlError ? null : (urlError ?? this.urlError),
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props =>
      [url, selectedLabels, allLabels, isSaving, urlError, isDone];
}
```

---

## 4. AddArticleCubit

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/label.dart';
import '../../services/database_service.dart';
import '../../services/share_service.dart';
import 'add_article_state.dart';

class AddArticleCubit extends Cubit<AddArticleState> {
  AddArticleCubit() : super(const AddArticleState()) {
    _loadLabels();
  }

  void _loadLabels() {
    emit(state.copyWith(allLabels: DatabaseService.getAllLabelObjects()));
  }

  void urlChanged(String value) {
    emit(state.copyWith(url: value, clearUrlError: true));
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    emit(state.copyWith(url: text, clearUrlError: true));
  }

  void toggleLabel(String name) {
    final next = Set<String>.from(state.selectedLabels);
    if (!next.add(name)) next.remove(name);
    emit(state.copyWith(selectedLabels: next));
  }

  Future<void> createLabel(String name, Color color) async {
    final created = await DatabaseService.createLabel(name, color);
    final labels = DatabaseService.getAllLabelObjects();
    emit(state.copyWith(
      allLabels: labels,
      selectedLabels: {...state.selectedLabels, created.name},
    ));
  }

  Future<void> save() async {
    final url = ShareService.extractURL(state.url);
    if (url == null || url.isEmpty) {
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
    } catch (e) {
      emit(state.copyWith(isSaving: false, urlError: e.toString()));
    }
  }
}
```

**주의**: `urlError`에 로컬라이즈되지 않은 키("invalid_url")를 넣는 건 UI가 해석해서 번역하도록 하는 패턴. UI에서 `state.urlError == 'invalid_url' ? l10n.invalidUrl : state.urlError` 같은 분기.

---

## 5. AddArticleSheet 교체

### 5.1 BlocProvider 삽입

`add_article_sheet.dart`:

```dart
class AddArticleSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => AddArticleCubit(),
        child: const _AddArticleForm(),
      ),
    );
  }
}
```

### 5.2 _AddArticleForm

```dart
class _AddArticleForm extends StatefulWidget {
  const _AddArticleForm();
  @override
  State<_AddArticleForm> createState() => _AddArticleFormState();
}

class _AddArticleFormState extends State<_AddArticleForm> {
  final _controller = TextEditingController();
  bool _syncFromState = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<AddArticleCubit, AddArticleState>(
      listenWhen: (p, c) => p.isDone != c.isDone && c.isDone,
      listener: (context, state) {
        Navigator.pop(context);
      },
      builder: (context, state) {
        // Cubit이 clipboard paste로 url을 바꾼 경우에만 TextField 갱신
        if (_controller.text != state.url) {
          _controller.value = _controller.value.copyWith(
            text: state.url,
            selection: TextSelection.collapsed(offset: state.url.length),
          );
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  onChanged: (v) =>
                      context.read<AddArticleCubit>().urlChanged(v),
                  decoration: InputDecoration(
                    hintText: l10n.urlHint,
                    errorText: _resolveError(state.urlError, l10n),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: () =>
                          context.read<AddArticleCubit>().pasteFromClipboard(),
                    ),
                  ),
                ),
                _LabelChips(state: state),
                FilledButton(
                  onPressed: state.isSaving
                      ? null
                      : () => context.read<AddArticleCubit>().save(),
                  child: state.isSaving
                      ? const SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _resolveError(String? code, AppLocalizations l10n) {
    if (code == null) return null;
    if (code == 'invalid_url') return l10n.invalidUrl;
    return code;
  }
}
```

**주의**: `TextEditingController`는 위젯 로컬에 유지. Cubit의 `url` 상태가 외부 페이스트/초기화로 변경될 때만 컨트롤러 값을 수동 동기화. onChanged는 양방향이 꼬이지 않도록 컨트롤러 내부에서 호출.

### 5.3 _LabelChips

```dart
class _LabelChips extends StatelessWidget {
  const _LabelChips({required this.state});
  final AddArticleState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      children: [
        for (final label in state.allLabels)
          FilterChip(
            label: Text(label.name),
            selected: state.selectedLabels.contains(label.name),
            onSelected: (_) =>
                context.read<AddArticleCubit>().toggleLabel(label.name),
          ),
        ActionChip(
          label: Text(AppLocalizations.of(context)!.newLabel),
          avatar: const Icon(Icons.add),
          onPressed: () => _showCreateLabelDialog(context),
        ),
      ],
    );
  }

  Future<void> _showCreateLabelDialog(BuildContext context) async {
    final cubit = context.read<AddArticleCubit>();
    // 기존 다이얼로그 로직 재사용. 결과로 (name, color) 얻으면:
    final result = await showDialog<({String name, Color color})>(/* ... */);
    if (result != null) {
      await cubit.createLabel(result.name, result.color);
    }
  }
}
```

---

## 6. 주의사항

- **Done 처리**는 `BlocListener`의 `isDone` 전이에서 `Navigator.pop`. Cubit이 직접 pop 불가.
- **TextEditingController와 Cubit 상태 동기화**는 단방향(Cubit → Controller)이 안전. 사용자 입력은 onChanged → Cubit.
- `ShareService.processAndSave`가 실패해도 Hive에 저장 시도 후 Firestore는 뒤에서 syncing되므로 에러 UI는 선택적.
- 새 라벨 생성 후 Cubit이 `allLabels`를 즉시 갱신 → FilterChip이 자동 반영.

---

## 7. 테스트

```dart
test('AddArticleState copyWith clearUrlError', () {
  final s = AddArticleState(urlError: 'x').copyWith(clearUrlError: true);
  expect(s.urlError, isNull);
});

blocTest<AddArticleCubit, AddArticleState>(
  'urlChanged clears error',
  build: () => AddArticleCubit(),
  seed: () => const AddArticleState(urlError: 'invalid_url'),
  act: (c) => c.urlChanged('https://example.com'),
  expect: () => [
    predicate<AddArticleState>((s) => s.url == 'https://example.com' && s.urlError == null),
  ],
);
```

---

## 8. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크

- [ ] 수동 추가 버튼 → 시트 열림
- [ ] 클립보드에 URL 복사 후 "붙여넣기" 버튼 → TextField 채워짐
- [ ] 잘못된 URL 입력 → "invalid url" 에러 표시
- [ ] 라벨 선택/해제 → 즉시 반영
- [ ] 새 라벨 생성 → 칩 목록에 추가 + 자동 선택
- [ ] 저장 → 로딩 → 시트 닫힘 → 홈/라이브러리에 아티클 반영

---

## 9. 커밋 메시지

```
BLoC PR8: AddArticleCubit 도입 — 수동 추가 시트 상태 이동

- lib/blocs/add_article/ 신규
- 클립보드 페이스트/URL 검증/라벨 선택/새 라벨 생성/저장 Cubit 경유
- BlocListener로 저장 완료 시 시트 닫기
- TextEditingController는 위젯 로컬, 단방향 동기화
```

---

## 10. 핸드오프 노트

### 계획대로 된 점
- `lib/blocs/add_article/{cubit,state}.dart` 신규. `AddArticleState`는 Equatable + copyWith, `AddArticleCubit`은 `labelsChangedNotifier` 구독으로 `allLabels` 자동 갱신.
- `AddArticleSheet` 리팩터: 347 LOC StatefulWidget(_selected/_saving/_urlError 로컬) → Cubit 이동. TextEditingController만 `_AddArticleBody(StatefulWidget)` 로컬 유지(SSOT).
- `BlocProvider(create: AddArticleCubit())`를 `show()`의 builder에 삽입(화면 로컬 provider 규칙 준수).
- `BlocConsumer.listenWhen`: `isDone` / `saveFailure` / `labelErrorMessage` 3채널 전이 가드. 중복 SnackBar 방지.
- URL 검증 로직 유지: `Uri.tryParse + hasScheme + host.isNotEmpty` (기존 UX 동치). 실패 시 `urlError='invalid_url'` 센티넬 → UI에서 `AppLocalizations.invalidUrl` 해석.
- `articlesChangedNotifier` 중복 발사 방지: `ShareService.processAndSave` 내부 발사 경로 존중, Cubit에서 추가 발사 없음.
- `test/blocs/add_article_cubit_test.dart` 11 PASS. 기존 49 + 신규 11 = 60 PASS.

### 계획과 다르게 된 점
- **PR 8 문서의 `ShareService.extractURL` 검증 제안 미채택**: 기존 코드는 `Uri.tryParse` 기반 엄격 검증 사용 중. `extractURL`은 정규식으로 URL 추출(너무 관대). 회귀 방지 위해 기존 로직 유지.
- **`url` state 필드 드롭**: PR 8 문서 스니펫은 `url: String`을 Cubit state에 포함했으나, TextEditingController와 이중 SSOT가 되어 페이스트/onChanged 동기화가 복잡해짐. Cubit은 `urlError` 센티넬만 소유하고, `save(rawUrl)`은 파라미터로 URL 수신. 단방향 데이터 흐름.
- **에러 채널 3분리 (리뷰 must-fix 반영)**: 초기 구현은 `failureMessage: String?` 단일 필드였으나, 저장 실패(i18n 'saveFailed' SnackBar) ↔ 라벨 생성 실패(원문 메시지) 의미가 달라 SnackBar 문구가 잘못 매핑되는 회귀 발견. `saveFailure: bool` + `labelErrorMessage: String?`로 분리.
- **`AddArticleSheet` private ctor (리뷰 should-fix 반영)**: 초기 구현은 StatelessWidget + 중복 `BlocProvider`였으나, `show()`가 유일 진입점이므로 위젯 트리 직접 삽입 방지를 위해 일반 클래스 + `_()` private 생성자로 변경. `build()` 메서드 dead code 제거.
- **`_showAddLabelDialog` 단순화**: 기존 다이얼로그가 내부에서 `DatabaseService.createLabel` 직접 호출 + try/catch로 SnackBar까지 띄우던 구조를, 다이얼로그는 `(name, color)` 선택만 담당하고 Cubit.`createLabel(name, color)`로 위임. 실패 시 Cubit → listener → SnackBar(원문).
- **`DatabaseService.createLabel`이 생성 `Label`을 직접 반환**하므로 `getAllLabelObjects().firstWhere(...)` 재조회 제거(nit 반영).

### 새로 발견한 이슈 / TODO
- **`labelsChangedNotifier`가 로컬 라벨 CRUD에서 발사되지 않음**: `DatabaseService.createLabel/updateLabel/deleteLabel`은 현재 `labelsChangedNotifier.value++`를 발사하지 않고, `SyncService`의 원격 스냅샷 머지에서만 발사된다(`sync_service.dart:392`). AddArticleSheet가 열린 동안 다른 화면에서 라벨이 바뀌어도 `_refreshLabels`가 트리거되지 않음. 본 PR 범위 밖(LibraryCubit/LabelManagementCubit도 동일 가정). PR 11 또는 별도 PR에서 로컬 CRUD 발사 통합 필요.
- **하드코딩 매직 넘버** (기존 유지분): 핸들바 `36×4`, 컬러 칩 `36×36`, `circular(2.5)`, 알파 `0.15/0.25/0.3/0.4` 등. 디자인 토큰 미적용. 본 PR 범위 밖.
- **`_showAddLabelDialog`의 `nameController` lifecycle**: `showDialog` 완료 후 dispose. 호스트 시트 dismiss 시 Future가 null로 완료되어 도달 보장. 기존 코드부터 동일(회귀 아님).

### 참고한 링크
- 리뷰어 지적: must-fix 1(에러 채널 충돌) + should-fix 2(중복 BlocProvider)
- flutter_bloc BlocConsumer listenWhen: https://bloclibrary.dev/flutter-bloc-concepts/#blocconsumer
- `DatabaseService.createLabel` 시그니처: `Future<Label> createLabel(String name, Color color)` — 생성 인스턴스 반환(`database_service.dart:234`)

### 다음 세션 유의사항 (PR 9 — HomeBloc)
- **PR 9는 유일한 `Bloc`** (Cubit 아님). HomeScreen의 swipe 제스처 이벤트(`markAsRead`, `skip`, `undo`) + deck 상태 + `CardSwiperController` 재생성이 이벤트 기반이라 Bloc 적합.
- **의존성**: PR 1 + PR 6(`ArticleListCubit`). 재사용 여부 판단 필요 — HomeScreen의 deck은 읽지 않은 아티클만 스트리밍, `ArticleListCubit`과 소스 다름. 별도 HomeBloc 권장.
- **복잡성 경고**: `CardSwiperController` dispose 이중 방지(`try-catch`), 8카드마다 `SwipeAdCard` 삽입, 오버레이 가이드, 컨트롤러 교체 시 `addPostFrameCallback` 패턴. 상태 전환을 이벤트로 캡슐화해야 setState 남용이 제거됨.
- **컨벤션 불변** (PR 1~8): bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 서브에이전트 병렬 dispatch / 시뮬레이터 스모크 사용자 요청 시만.

### 검증 결과
- `flutter analyze`: ✅ No issues (2.0s)
- `flutter test test/blocs/`: ✅ 60 PASS (기존 49 + 신규 11)
- 실기기 스모크: ⚪ 미수행 (사용자 방침: 전 PR 정리 후 일괄 진행)
- opus `flutter-code-reviewer`: ✅ must-fix 1 + should-fix 1 모두 반영, nit 4건은 범위 외 이관
