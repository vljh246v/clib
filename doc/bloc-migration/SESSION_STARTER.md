# 새 세션 시작 가이드

이 문서는 **BLoC 전환 작업을 새 세션에서 이어 할 때** 가장 먼저 해야 할 것들을 정리한다. Claude가 매번 전체 코드베이스를 다시 탐색하지 않고 문서만 읽어서 바로 작업에 착수할 수 있도록 설계되었다.

---

## 권장 초기 프롬프트

사용자가 새 세션을 시작할 때 다음 프롬프트 중 하나를 쓴다.

### A) 다음 PR을 이어서 하고 싶을 때

```
doc/bloc-migration/ 문서를 읽고 BLoC 전환 작업을 이어가자.
현재 진행 상황 확인하고, 다음 PR의 문서를 읽어서 작업을 시작해줘.
```

### B) 특정 PR을 지정하고 싶을 때

```
doc/bloc-migration/pr-04-library.md 를 읽고 PR 4 작업을 수행해줘.
이전 세션 결과는 SESSION_LOG.md 에 있어.
```

### C) 중단된 PR을 재개할 때

```
doc/bloc-migration/SESSION_LOG.md 에 따르면 PR 6이 In Progress 상태야.
해당 PR 문서와 현재 브랜치 상태 확인 후 이어서 진행해줘.
```

---

## Claude가 세션 시작 시 해야 할 일 (순서대로)

1. **진행 현황 파악**
   - `doc/bloc-migration/README.md` → 진행 현황 트래커 테이블 확인
   - `doc/bloc-migration/SESSION_LOG.md` → 마지막 세션 로그 확인 (특히 **"다음 세션 유의사항"** 섹션)

2. **브랜치 상태 확인**
   ```bash
   git status
   git branch --show-current
   git log --oneline -10
   ```
   - 현재 main 브랜치인가? 아니면 작업 중인 feature 브랜치가 있는가?
   - 커밋되지 않은 변경이 있는가?

3. **대상 PR 문서 정독**
   - `doc/bloc-migration/pr-<NN>-*.md` 전체 읽기
   - "사전 요건" 섹션의 파일들을 Read 툴로 로드

4. **정적 분석 기준점 확인**
   ```bash
   flutter analyze
   flutter test
   ```
   - 기준선이 No issues인지 확인 (이미 오염되어 있으면 원인 파악 먼저)

5. **작업 시작 전 사용자에게 보고**
   - "PR <NN> — <제목>을 시작하려고 한다"
   - "예상 수정 파일: [...]"
   - "이전 세션에서 알려진 이슈: [...]"
   - 사용자 확인 후 진행

---

## 세션 종료 시 해야 할 일 (의무)

### 작업 완료 시

1. **해당 PR 문서 업데이트**
   - 문서 하단 "핸드오프 노트" 섹션 작성
     - 계획대로 된 점 / 계획과 다르게 된 점 / 주의할 점
     - 참고한 링크/문서
     - 발견한 새 이슈 또는 TODO

2. **SESSION_LOG.md 에 엔트리 추가** (템플릿은 SESSION_LOG.md 참조)

3. **README.md 진행 현황 트래커 업데이트**
   - 상태 ⬜ → 🟢
   - 완료일, 브랜치 입력

4. **커밋**
   - 코드 변경 커밋
   - 문서 업데이트는 별도 커밋 권장 (예: `docs(bloc): PR 4 완료 로그 추가`)

5. **사용자에게 최종 보고**
   - 한 줄 요약: "analyze 통과, PR 4 커밋 완료, 다음은 PR 5"
   - PR 생성 여부 확인 (push는 사용자 확인 후)

### 중단 시 (세션 한도 도달 등)

1. **현재 상태를 SESSION_LOG.md 에 기록**
   - 어디까지 됐는지
   - 무엇이 남았는지
   - **다음 세션이 바로 이어갈 수 있는 구체적 액션**
2. **WIP 커밋**으로 브랜치에 저장(사용자 확인 후)
3. 해당 PR 문서 상태를 "🟡 In Progress"로 변경

---

## 비용 최적화 팁

- **코드베이스 전체 탐색 금지**: 이미 `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md`에 모든 아키텍처 결정이 있다. 필요한 것만 골라 읽기.
- **각 PR 문서의 "사전 요건"에 나열된 파일만** Read로 로드한다.
- Explore 서브에이전트는 **예상 못한 문제**가 생겼을 때만 사용.
- 질문이 필요하면 AskUserQuestion으로 배치 처리.

---

## 자주 찾는 파일 경로 캐시

| 용도 | 경로 |
|------|------|
| 전체 플랜 | `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md` |
| 프로젝트 규칙 | `/Users/jaehyun/Documents/workspace/clib/CLAUDE.md` |
| 전역 notifier 정의 | `lib/main.dart:23-32` |
| DatabaseService | `lib/services/database_service.dart` |
| AuthService | `lib/services/auth_service.dart` |
| 테마 저장 로직 | `lib/services/database_service.dart:62-75` |
| 알림 서비스 | `lib/services/notification_service.dart` |
| 동기화 서비스 | `lib/services/sync_service.dart` |
| 디자인 토큰 | `lib/theme/design_tokens.dart` |
| ARB 템플릿 | `lib/l10n/app_ko.arb` |

### Cubit / 공통 위젯 (PR 1~7 누적)

| 용도 | 경로 |
|------|------|
| ThemeCubit | `lib/blocs/theme/theme_cubit.dart` |
| AuthCubit + State | `lib/blocs/auth/auth_{cubit,state}.dart` |
| OnboardingCubit | `lib/blocs/onboarding/onboarding_cubit.dart` |
| LibraryCubit + State | `lib/blocs/library/library_{cubit,state}.dart` |
| LabelManagementCubit + State | `lib/blocs/label_management/label_management_{cubit,state}.dart` |
| ArticleListCubit/Source/State | `lib/blocs/article_list/article_list_{cubit,source,state}.dart` |
| ArticleListView (리스트 + 광고 8개마다 삽입) | `lib/widgets/article_list_view.dart` |
| ArticleListItem (개별 행) | `lib/widgets/article_list_item.dart` |
| BulkActionBar (다중 선택 하단 액션바) | `lib/widgets/bulk_action_bar.dart` |
| ArticleActionsSheet (롱프레스 액션시트) | `lib/widgets/article_actions_sheet.dart` |
| MemoSheet (메모 입력 바텀시트) | `lib/widgets/memo_sheet.dart` |
| 공통 테스트 패턴 | `test/blocs/*_test.dart` |
