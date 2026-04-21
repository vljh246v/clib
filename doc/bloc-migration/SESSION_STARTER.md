# 새 세션 시작 가이드

> 새 세션에서 BLoC 작업 이어갈 때 가장 먼저 읽을 문서.
>
> **현 진행 상태(2026-04-21)**: PR 1~9 머지 + PR 11 코드/문서 정리 merge(develop) +
> §2.6 widget_test 재작성(`feature/bloc-11-widget-test`). PR 10 Skip 확정.
>
> **다음 = §3 실기기 회귀 스모크 17 항목(사용자 수행).**

---

## 1. 다음 세션 즉시 시작 가이드

### A) 다음 작업(PR 11 마무리)을 이어가는 경우

```
doc/bloc-migration/SESSION_LOG.md PR 11 엔트리와
doc/bloc-migration/pr-11-cleanup.md §2.6 + §3을 읽고
test/widget_test.dart 재작성부터 시작해줘.
브랜치는 feature/bloc-11-cleanup 그대로 사용.
```

### B) PR 11 머지부터 진행하는 경우

```
feature/bloc-11-cleanup 브랜치 7 커밋이 이미 적용됐어.
스모크 결과 보고할 테니 머지 + push 진행해줘.
```

### C) 후속 PR(NotificationService ARB 통합 등) 시작

```
README.md "후속 PR 후보" 표를 보고
[항목명] 작업을 시작하자. 현 브랜치는 develop.
```

---

## 2. Claude가 세션 시작 시 해야 할 일 (순서대로)

1. **진행 현황 파악**
   - `README.md` § 진행 현황 트래커
   - `SESSION_LOG.md` 최상단 (PR 11 엔트리 + "다음 세션 유의사항" 필독)

2. **브랜치 상태 확인**
   ```bash
   git status
   git branch --show-current
   git log --oneline -10
   ```

3. **대상 작업 문서 정독**
   - PR 11 마무리: `pr-11-cleanup.md` §2.6 + §3 전체
   - 후속 PR: 해당 후보 항목 + 관련 코드 grep

4. **검증 기준선 확인**
   ```bash
   flutter analyze
   flutter test test/blocs/
   ```
   - 기준선 = analyze 0건, bloc test 74 PASS.

5. **작업 시작 전 사용자에게 보고**
   - "진행할 작업 / 예상 수정 파일 / 알려진 위험"
   - 사용자 확인 후 진행.

---

## 3. 세션 종료 시 의무

### 작업 완료 시

1. `SESSION_LOG.md` 최상단에 새 엔트리 추가 (템플릿은 같은 파일).
2. `README.md` 트래커 상태 업데이트.
3. 코드/문서 분할 커밋 (성격이 다르면 분리).
4. 사용자에게 한 줄 요약 보고 + push 여부 확인.

### 중단 시

1. `SESSION_LOG.md`에 "어디까지 됐는지 / 무엇이 남았는지 / 다음 세션 액션" 기록.
2. WIP 커밋(사용자 확인 후)으로 브랜치 보존.
3. 해당 작업 상태 🟡 In Progress.

---

## 4. 비용 최적화 팁

- **코드베이스 전체 탐색 금지**: 핵심 결정은 `CLAUDE.md` + `README.md`에 있음.
- **Explore 서브에이전트는 예상 못한 문제만**.
- 질문은 AskUserQuestion으로 배치.
- archive/ 문서는 회고 참조용 — 활성 작업 시작 시 정독 불필요.

---

## 5. 자주 찾는 파일 경로 캐시

### 프로젝트 핵심
| 용도 | 경로 |
|------|------|
| 프로젝트 규칙 | `/Users/jaehyun/Documents/workspace/clib/CLAUDE.md` |
| 전체 플랜 | `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md` |
| 디자인 토큰 | `lib/theme/design_tokens.dart` |
| ARB 템플릿 | `lib/l10n/app_ko.arb` |

### Bloc/Cubit + 신규 위젯 (PR 1~11)
| 용도 | 경로 |
|------|------|
| 전역 notifier (PR 11에서 분리) | `lib/state/app_notifiers.dart` |
| ThemeCubit | `lib/blocs/theme/theme_cubit.dart` |
| AuthCubit + State | `lib/blocs/auth/auth_{cubit,state}.dart` |
| OnboardingCubit | `lib/blocs/onboarding/onboarding_cubit.dart` |
| LibraryCubit + State | `lib/blocs/library/library_{cubit,state}.dart` |
| LabelManagementCubit + State | `lib/blocs/label_management/label_management_{cubit,state}.dart` |
| ArticleListCubit/Source/State | `lib/blocs/article_list/article_list_{cubit,source,state}.dart` |
| AddArticleCubit + State | `lib/blocs/add_article/add_article_{cubit,state}.dart` |
| HomeBloc + Event + State | `lib/blocs/home/home_{bloc,event,state}.dart` |
| ArticleListView (광고 8마다 삽입) | `lib/widgets/article_list_view.dart` |
| ArticleListItem (+ accentColor PR 11) | `lib/widgets/article_list_item.dart` |
| BulkActionBar | `lib/widgets/bulk_action_bar.dart` |
| ArticleActionsSheet | `lib/widgets/article_actions_sheet.dart` |
| MemoSheet | `lib/widgets/memo_sheet.dart` |
| AddArticleSheet | `lib/widgets/add_article_sheet.dart` |
| 일괄 삭제 헬퍼 (PR 11) | `lib/widgets/bulk_delete_confirm.dart` |
| 공통 테스트 패턴 | `test/blocs/*_test.dart` |

### 서비스
| 용도 | 경로 |
|------|------|
| DatabaseService (PR 11 notifier 발사 단독 책임) | `lib/services/database_service.dart` |
| AuthService | `lib/services/auth_service.dart` |
| NotificationService | `lib/services/notification_service.dart` |
| SyncService (원격 스냅샷) | `lib/services/sync_service.dart` |
| ShareService | `lib/services/share_service.dart` |
| AdService (`adInterval=8`) | `lib/services/ad_service.dart` |

---

## 6. 누적 핵심 주의사항 (PR 1~11 도출, 잊지 말 것)

- **글로벌 Provider 규칙**: 전역 = `ThemeCubit` + `AuthCubit`만. 나머지는 화면 로컬.
- **bloc_test 미도입**: `hive_generator 2.0.1` ↔ `bloc_test`(test 1.16+) 충돌.
  일반 `flutter_test` + `Cubit.stream.listen` + `expectLater` +
  `await Future<void>.delayed(Duration.zero)` 패턴.
- **Hive 테스트 격리**: setUpAll에서 `.dart_tool/test_hive_<name>` + 어댑터 등록 +
  box open. setUp에서 clear + `DatabaseService.skipSync = true`. tearDownAll에서
  `deleteFromDisk`. **PR 11 §2.6에서 이 패턴을 헬퍼로 추출 예정**.
- **컨트롤러는 위젯 로컬 SSOT**: Cubit/Bloc state에 두지 않음.
- **Hive in-place 변경 + Equatable dedup 함정**: state 클래스에 `refreshToken`
  또는 `generation` 필드 + 매 emit 시 증가 → stream emit 강제.
- **CardSwiper 재생성 `deckVersion` 패턴**: `key: ValueKey(deckVersion)` +
  `_pendingDispose` 큐 + `addPostFrameCallback` 일괄 dispose.
- **에러 채널 분리**: inline 센티넬 / SnackBar bool flag / 원문 String? 혼용 금지.
- **다이얼로그/시트 호출 전 `final cubit = context.read<X>()` 캡처**.
- **notifier 발사 단일 출처 (PR 11 확립)**:
  `articlesChangedNotifier` / `labelsChangedNotifier`는 **`DatabaseService`
  mutation 메서드 + `SyncService` 원격 스냅샷**만 발사. 그 외 경로(Cubit/Bloc/
  ShareService) 발사 금지.
- **ARB 10개 동기화**: 신규 UI 문자열은 ko/en/de/es/fr/ja/pt/zh/zh_CN/zh_TW
  전부에 동일 키 + ICU 플레이스홀더. `arb-sync-checker` 서브에이전트 활용.
- **기존 `test/widget_test.dart`는 broken**: PR 11 §2.6에서 재작성 예정.
  그 전에는 만지지 말 것.
