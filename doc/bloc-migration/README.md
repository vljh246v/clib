# BLoC 점진적 전환 — 세션 관리 마스터 문서

> Clib의 상태 관리를 `setState` + `ValueNotifier`에서 `flutter_bloc`(Cubit 중심)으로 **화면 단위로 점진적 전환**하는 장기 작업. 한 번의 세션에서 모두 끝낼 수 없으므로, **각 PR이 독립 세션에서 실행 가능**하도록 설계되었다.

## 최종 목표

- 모든 화면의 상태를 Cubit(복잡한 HomeScreen만 Bloc)으로 캡슐화
- 화면/서비스/상태 테스트 가능하게
- 중복 화면(`AllArticles`/`Bookmarked`/`LabelDetail`) 공통 Cubit으로 통합
- 기존 `*Service` static API는 **유지**(라이트 스코프)

전체 아키텍처 결정은 `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md` 참조.

---

## 진행 현황 트래커

체크박스 업데이트는 **각 PR 완료 시 해당 세션 말미에 반드시 수행**한다.

| PR | 제목 | 의존성 | 상태 | 브랜치 | 세션 완료일 |
|----|------|--------|------|--------|------------|
| 1 | Foundation + ThemeCubit | - | 🟢 Done | `feature/bloc-01-theme` | 2026-04-20 |
| 2 | AuthCubit + SyncService 연동 이동 | PR 1 | 🟢 Done | `feature/bloc-02-auth` | 2026-04-20 |
| 3 | OnboardingCubit | PR 1 | 🟢 Done | `feature/bloc-03-onboarding` | 2026-04-20 |
| 4 | LibraryCubit | PR 1 | 🟢 Done | `feature/bloc-04-library` | 2026-04-20 |
| 5 | LabelManagementCubit | PR 1 | ⬜ Not Started | `feature/bloc-05-label-mgmt` | - |
| 6 | ArticleListCubit 도입 + AllArticles | PR 1 | ⬜ Not Started | `feature/bloc-06-article-list` | - |
| 7 | Bookmarked + LabelDetail (Cubit 재사용) | PR 6 | ⬜ Not Started | `feature/bloc-07-bookmarked-label` | - |
| 8 | AddArticleCubit | PR 1 | ⬜ Not Started | `feature/bloc-08-add-article` | - |
| 9 | HomeBloc (유일한 Bloc) | PR 1, 6 | ⬜ Not Started | `feature/bloc-09-home` | - |
| 10 | MainScreen (선택) | PR 9 | ⬜ Skip (기본) | - | - |
| 11 | Cleanup + 문서화 | PR 2~9 | ⬜ Not Started | `feature/bloc-11-cleanup` | - |

**상태 기호**: ⬜ Not Started / 🟡 In Progress / 🟢 Done / 🔴 Blocked / ⚪ Skip

---

## 각 PR 문서

- [PR 1 — Foundation + ThemeCubit](./pr-01-foundation-theme.md)
- [PR 2 — AuthCubit](./pr-02-auth.md)
- [PR 3 — OnboardingCubit](./pr-03-onboarding.md)
- [PR 4 — LibraryCubit](./pr-04-library.md)
- [PR 5 — LabelManagementCubit](./pr-05-label-management.md)
- [PR 6 — ArticleListCubit + AllArticlesScreen](./pr-06-article-list-all.md)
- [PR 7 — Bookmarked + LabelDetail](./pr-07-bookmarked-label-detail.md)
- [PR 8 — AddArticleCubit](./pr-08-add-article.md)
- [PR 9 — HomeBloc](./pr-09-home.md)
- [PR 10 — MainScreen ShareFlowCubit (선택)](./pr-10-main-optional.md)
- [PR 11 — Cleanup](./pr-11-cleanup.md)

---

## 세션 운영

- 새 세션을 시작할 때 반드시 먼저 읽을 파일: [`SESSION_STARTER.md`](./SESSION_STARTER.md)
- 이전 세션에서 어떤 일이 있었는지: [`SESSION_LOG.md`](./SESSION_LOG.md)
- **세션 종료 시 의무**: 해당 PR 문서 말미의 "핸드오프 노트" 섹션 + `SESSION_LOG.md`에 한 줄 엔트리 추가

---

## 공통 규칙 (모든 PR 공통, 각 PR 문서에서 반복하지 않음)

### 브랜치 & 커밋

```bash
git checkout main
git pull
git checkout -b feature/bloc-<NN>-<slug>
# ... 작업 ...
git add <files>
git commit -m "BLoC PR<NN>: <요약>"
# PR 생성은 사용자에게 확인 후
```

- 커밋 메시지는 한국어 요약 + 필요시 영어 bullet.
- 한 PR 내에 여러 논리 단위가 있으면 커밋 분리 권장.

### 검증 3단계 (매 PR 공통)

1. `flutter analyze` — No issues (필수, CLAUDE.md 원칙)
2. `flutter test` — 기존 widget_test + 신규 bloc_test 통과
3. 실기기 스모크 — 각 PR 문서의 "스모크 시나리오" 체크리스트

### 코드 품질 필수

- CLAUDE.md 6단계 준수
- `flutter-code-reviewer` 서브에이전트 호출 권장(커밋 전)
- ARB 수정 시 `arb-sync-checker` 서브에이전트 호출

### 파일 구조 약속

```
lib/blocs/<domain>/
├── <domain>_cubit.dart       # 또는 <domain>_bloc.dart
├── <domain>_state.dart
└── <domain>_event.dart        # Bloc인 경우만
```

모든 상태 클래스는 `equatable` 사용 + `copyWith` 필수.

### BlocProvider 스코프 약속

- **전역**(main.dart MultiBlocProvider): `ThemeCubit`, `AuthCubit`
- **화면 로컬**(Screen 빌드 시 BlocProvider): 나머지 모두

### articlesChangedNotifier / labelsChangedNotifier 브릿지

PR 11 전까지는 기존 전역 `ValueNotifier`를 **유지**한다. 각 Cubit은 생성자에서 `addListener`로 구독하고, `close()`에서 해제한다. 표준 패턴:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(LibraryState.initial()) {
    articlesChangedNotifier.addListener(_onChanged);
    labelsChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => load();

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    labelsChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
```

### 패키지 버전 (PR 1에서 추가, 이후 고정)

- `flutter_bloc: ^8.1.6`
- `equatable: ^2.0.5`
- `bloc_test: ^9.1.7` (dev)

---

## 참고 링크 (전 PR 공통)

- flutter_bloc 공식: https://bloclibrary.dev/
- Cubit vs Bloc: https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc
- bloc_test: https://pub.dev/packages/bloc_test
- Equatable: https://pub.dev/packages/equatable
- 프로젝트 아키텍처: `/CLAUDE.md`
- 전체 플랜: `/Users/jaehyun/.claude/plans/bloc-dynamic-diffie.md`
