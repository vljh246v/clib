# PR 10 — MainScreen ShareFlowCubit (⚪ Skip 확정)

> PR 9 완료 시점(2026-04-21) 기준 **공식적으로 SKIP**. 본 문서는 스킵 사유와 재개 조건만 남긴다.

**상태**: ⚪ Skip
**결정일**: 2026-04-21 (PR 9 머지 후)

---

## 스킵 사유

1. **전환 가치 낮음**: `MainScreen`의 로컬 state는 `_currentIndex`(탭 인덱스), `_showOverlayGuide` 두 개뿐. 다른 Bloc과 교차 참조 없음.
2. **생명주기 결합**: `WidgetsBindingObserver`는 StatefulWidget 생명주기에 강하게 결합. Cubit 이전 시 오히려 코드 복잡도 상승.
3. **MethodChannel 의존**: `_checkPendingShares()`는 플랫폼 채널 결과를 시트 표시로 바로 전달 — 상태 관리 이점이 없음.
4. **PR 1~9 누적 원칙 부합**: "라이트 스코프" — Cubit/Bloc 이익이 명확한 화면만 전환.

---

## 재개 조건 (향후)

아래 중 하나라도 해당되면 재평가:

- `MainScreen`에 신규 로직이 추가되어 로컬 state가 3개 이상 → Cubit 분리 이점 발생
- 공유 플로우가 복잡해져 여러 화면에서 pending share 상태를 구독해야 할 때
- iOS ↔ Android 공유 플로우 분기가 플랫폼별 Cubit으로 명확히 나뉘는 것이 유리할 때

재개 시 본 문서 §과거 플랜 — 아래 "참고: 원래 플랜(아카이브)" 섹션을 기반으로 작업.

---

## 핸드오프 노트

### 스킵 사유
위 §스킵 사유 4개 항목 그대로. PR 9 리뷰 시점에도 추가 조건 미충족.

### 관련 정리 항목
본 PR에서 다루지 않더라도 `MainScreen` 공유 플로우에서 파생된 정리 항목은 **PR 11에 이관**:
- 공유 수신 후 `articlesChangedNotifier` 발사원 일원화 검토
- iOS App Group / Android Intent filter 처리 순서 확인

---

## 참고: 원래 플랜 (아카이브)

재개 시 아래 설계 스케치 참고.

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
    } catch (_) {
      emit(state.copyWith(isProcessing: false));
    }
  }

  void clear() => emit(state.copyWith(pendingURL: null));
}
```

`BlocListener<ShareFlowCubit>`에서 `pendingURL != null` 감지 시 `ShareLabelSheet.show()`.
