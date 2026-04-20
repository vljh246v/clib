# PR 10 — MainScreen ShareFlowCubit (선택, 기본 스킵 권장)

> `MainScreen`의 `AppLifecycleState.resumed` 시 공유 URL 체크 로직을 ShareFlowCubit으로 분리하는 **선택적 PR**. 라이트 스코프 원칙상 기본적으로 **스킵**한다.

**상태**: ⚪ Skip (기본값)
**의존성**: PR 9 완료 후 재평가
**브랜치**: `feature/bloc-10-main` (수행 시만)
**난이도**: ⭐⭐

---

## 1. 스킵 권장 이유

1. `MainScreen`은 전환 가치가 낮다 — `_currentIndex`(탭 인덱스)와 `_showOverlayGuide`만 로컬 state.
2. `WidgetsBindingObserver`는 위젯 생명주기와 결합되어 있어 Cubit으로 옮기면 오히려 꼬인다.
3. `_checkPendingShares()`는 외부 플러그인(MethodChannel) 기반이라 Cubit 이점 적음.

**결론**: PR 9 완료 후 남은 `setState`가 많지 않으면 이 PR은 **SKIP**. `SESSION_LOG.md`에 "PR 10 skipped — MainScreen 로컬 상태 유지가 더 간결"로 기록.

---

## 2. 그래도 수행하고 싶다면

### 2.1 목표

- `lib/blocs/share_flow/share_flow_cubit.dart`
- 상태: `pendingURL: String?`, `isProcessing: bool`
- 메서드: `checkPendingShares()`, `processAndClear()`
- `MainScreen`에서 pending share 체크 결과를 Cubit으로 위임

### 2.2 사전 요건

| 파일 | 범위 |
|------|------|
| `lib/main.dart` | MainScreen 클래스 |
| `lib/services/share_service.dart` | `getPendingShareURL`, `checkPendingShares` |
| `lib/widgets/share_label_sheet.dart` | 시트 표시 로직 |

### 2.3 Cubit

```dart
class ShareFlowCubit extends Cubit<ShareFlowState> {
  ShareFlowCubit() : super(const ShareFlowState());

  Future<void> check() async {
    if (state.isProcessing) return;
    emit(state.copyWith(isProcessing: true));
    try {
      if (Platform.isAndroid) {
        final url = await ShareService.getPendingShareURL();
        emit(state.copyWith(pendingURL: url, isProcessing: false));
      } else {
        await ShareService.checkPendingShares();
        emit(state.copyWith(isProcessing: false));
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false));
    }
  }

  void clear() {
    emit(state.copyWith(pendingURL: null));
  }
}
```

### 2.4 MainScreen 교체

```dart
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    context.read<ShareFlowCubit>().check();
  }
}
```

`BlocListener<ShareFlowCubit>`에서 `pendingURL != null` 감지 시 `ShareLabelSheet.show()`.

---

## 3. 스킵 결정 기록

이 PR을 스킵할 경우 README.md 진행 현황 트래커의 PR 10 상태를 `⚪ Skip`로 표시하고 `SESSION_LOG.md`에 사유 기록.

---

## 4. 핸드오프 노트

### 수행 결정 사유
- (작성 또는 "Skipped")

### 스킵 사유 (스킵 시)
- (작성)
