# PR 11 — Cleanup + 문서화

> PR 1~9 전환 완료 후 누적된 후속 정리 + CLAUDE.md 갱신 + 최종 회귀 테스트.

**의존성**: PR 1~9 완료
**브랜치**: `feature/bloc-11-cleanup`
**예상 작업 시간**: 3~5시간 (스모크 포함)
**난이도**: ⭐⭐⭐

---

## 1. 목표

1. PR 1~9에서 이관된 후속 정리 항목 일괄 처리
2. `CLAUDE.md` 갱신 — 새 구조 반영
3. `doc/bloc-migration/` 최종 상태 기록
4. 실기기/시뮬레이터 일괄 스모크 (누적 미수행분)
5. `test/widget_test.dart` 재작성 (Firebase/Hive 초기화 헬퍼)

---

## 2. 누적 후속 정리 체크리스트

### 2.1 Notifier 발사 경로 통합

- [ ] `DatabaseService.createLabel/updateLabel/deleteLabel` → 각 성공 분기에서 `labelsChangedNotifier.value++` 발사 (PR 8 발견)
- [ ] `DatabaseService.markAsRead/markAsUnread/bulkMarkRead/toggleBookmark/bulkSetBookmark/updateMemo/updateArticleLabels/deleteArticle` → `articlesChangedNotifier.value++` 발사 승격 검토 (PR 9 확인)
- [ ] 발사 후 Cubit/Bloc 측의 **수동 reload 제거** — `HomeBloc._onToggleBookmark/_onUpdateMemo`의 `add(HomeLoadDeck)` 중복 여부 재확인
- [ ] 중복 발사(같은 tick 내 2회) 방지 — 기존 `ShareService.processAndSave` 경로 재검증

**주의**: notifier 발사가 Cubit/Bloc 전 구독자에게 전파되므로 불필요한 재로드 폭발 방지 위해 단순 스냅샷 테스트로 재확인.

### 2.2 컨트롤러 라이프사이클 정리

- [ ] `HomeScreen._showMemoDialog`의 `TextEditingController` dispose 호출 추가
- [ ] `LabelEditSheet`, `ShareLabelSheet` 등 다른 시트도 동일 패턴 점검
- [ ] PR 6~7에서 분리된 `MemoSheet` 공통 헬퍼 사용으로 통합 가능

### 2.3 디자인 토큰 적용

- [ ] `lib/screens/home_screen.dart`의 하드코딩 숫자 치환:
  - `BorderRadius.circular(20)` → `Radii.borderXl` 또는 신규 토큰
  - 120/56/36/28/26/16/12 → `Spacing.*` 또는 전용 상수
- [ ] `_SwipeHint` 왼쪽 색: `onSurfaceVariant` → `AppColors.swipeSkip`(공용 Muted Rose) 일치 검토 (디자인 의도 확인 필요)
- [ ] `adInterval = 8` 매직 넘버 → `AdService` 또는 디자인 토큰 인접 상수로 이동 (PR 6 TODO)

### 2.4 코드 품질 nit 이관 (PR 6~7)

- [ ] `ArticleListItem`에 `Color? accentColor` 옵션 추가 — LabelDetail 아이템 뱃지 labelColor 복원
- [ ] `_confirmBulkDelete` 3화면 중복 → `showBulkDeleteConfirm(context, cubit)` 헬퍼 추출 또는 `BulkActionBar.onDelete` 시그니처 승격
- [ ] `selectedKeys: List<dynamic>` → `List<int>`로 좁히기 (Hive key는 int)
- [ ] `bulkDelete` for-await 순차 → `DatabaseService.bulkDelete(articles)` batch + 단일 sync trigger (PR 6 TODO)

### 2.5 미사용 코드 / import 정리

- [ ] `lib/main.dart`: `themeModeNotifier`, `authStateNotifier` 잔존 여부 재점검 (PR 1/2에서 제거됨, 확정 확인)
- [ ] 각 화면 미사용 import — `dart fix --apply` 후 수동 검토
- [ ] 각 Cubit/Bloc의 디버그 print 제거
- [ ] 미사용 ARB 키 — `arb-sync-checker` 서브에이전트 호출

### 2.6 테스트 복구

- [ ] 기존 `test/widget_test.dart` 재작성:
  - `setUpAll`에서 Hive 격리 path + 어댑터 등록 + box open
  - Firebase 초기화는 mock 또는 skip
  - `DatabaseService.skipSync = true` 기본
  - `MainScreen` / `HomeScreen` 스모크 수준
- [ ] 공통 테스트 헬퍼 추출: `test/helpers/hive_bootstrap.dart`

### 2.7 pubspec / 환경

- [ ] `pubspec.yaml`의 `environment.flutter` floor 명시 — `RadioGroup<T>` (Flutter 3.32+ API) 명세화

### 2.8 CLAUDE.md 갱신

- [ ] **전역 상태** 섹션: `ValueNotifier` 4개 설명 → `ThemeCubit`, `AuthCubit` + 남은 notifier 2개(`articlesChangedNotifier`, `labelsChangedNotifier`)
- [ ] **화면별 주요 로직** 섹션: Cubit/Bloc 사용 명시 (기본 Cubit, `HomeScreen`만 Bloc)
- [ ] **프로젝트 구조** 섹션: `lib/blocs/` 디렉터리 추가
- [ ] **기술 스택** 표: `flutter_bloc ^8.1.6`, `equatable ^2.0.5` 추가
- [ ] **개발 컨벤션** 섹션에 새 규칙 추가:
  - 상태 관리 = `flutter_bloc`
  - 기본 Cubit, 복잡 화면만 Bloc
  - 전역 = `ThemeCubit` + `AuthCubit`, 나머지 화면 로컬 `BlocProvider`
  - 상태 클래스 = `equatable` + `copyWith` 필수
  - Hive in-place 변경 대응 `refreshToken` 패턴
  - CardSwiper 재생성 `deckVersion` 패턴

### 2.9 doc/bloc-migration 마무리

- [ ] `README.md` 트래커 전부 🟢
- [ ] `SESSION_LOG.md` PR 11 완료 엔트리 추가
- [ ] `SESSION_STARTER.md`는 **본 PR 이후 archive** 안내 한 줄 추가 가능(선택)

---

## 3. 최종 회귀 스모크 (실기기 `flutter run --release`)

누적 미수행분 일괄 진행. 각 체크박스는 실기기 기준.

- [ ] 첫 실행(Hive 초기화) → 온보딩 3페이지 → 메인
- [ ] 아티클 저장(시스템 공유 시트 → 앱)
- [ ] 수동 URL 추가(+ 버튼 → AddArticleSheet)
- [ ] 홈 스와이프: 오른쪽(읽음), 왼쪽(나중에), loop 경계
- [ ] 홈 라벨 필터: 단일/다중(AND), 해제, 확장/접기
- [ ] 홈 롱프레스 액션: 북마크, 메모 추가/수정/삭제, 라벨 편집, 외부 열기
- [ ] 8번째 슬롯 광고 카드 스와이프 (상태 영향 없음)
- [ ] 라이브러리 탭: 전체/북마크/라벨별 진입
- [ ] 전체 / 북마크 / LabelDetail 화면: 행 탭, 롱프레스 액션, 다중선택 + 일괄 액션(읽음/북마크/삭제)
- [ ] 라벨 CRUD + 라벨별 알림(요일 칩 + TimePicker)
- [ ] 테마 전환(Light/Dark/System) + 앱 재시작 유지
- [ ] Google/Apple 로그인 → Firestore 동기화(articles + labels)
- [ ] 로그아웃 → 재로그인 → 동기화 정상
- [ ] 계정 삭제
- [ ] 백그라운드 → 포그라운드 → 상태 꼬임/크래시 없음
- [ ] `flutter run --release` 크래시 없이 전 플로우 통과

---

## 4. 성과 측정

| 항목 | 기준(PR 0) | 현재(PR 9 머지 직후) | PR 11 완료 후 |
|------|-----------|---------------------|---------------|
| 총 LOC (`lib/`) | ~8,705 | ? | ? |
| 화면 LOC 합 | ~3,749 | ? | ? |
| widget_test 개수 | 1 (broken) | 1 (broken) | ? |
| Bloc/Cubit 유닛 테스트 | 0 | 74 | ? |
| 전역 ValueNotifier | 4 | 2 | 2 (유지) |

측정 명령:
```bash
grep -rn "setState" lib/ | wc -l
grep -rn "ValueNotifier" lib/ | wc -l
cloc lib/
```

---

## 5. 커밋 메시지

```
BLoC PR11: 전환 마무리 — 클린업 + 문서 갱신

- notifier 발사 경로 일원화 (DatabaseService 내부 승격)
- 컨트롤러 라이프사이클 정리 (MemoDialog 등)
- 디자인 토큰 치환 (home_screen 잔존 하드코딩)
- CLAUDE.md 갱신: flutter_bloc 기반 상태 관리 문서화
- widget_test.dart 재작성 + Hive/Firebase 헬퍼
- 회귀 스모크 통과
```

성격이 다르면 커밋 분리 권장:
- `refactor(db): notifier 발사 경로 DatabaseService 승격`
- `refactor(theme): home_screen 하드코딩 → 디자인 토큰`
- `test: widget_test 재작성 + hive_bootstrap 헬퍼`
- `docs: CLAUDE.md flutter_bloc 기반 구조 반영`

---

## 6. 핸드오프 노트 (PR 11 완료 시 작성)

### 전환 완료 상태
- (작성)

### 남은 부채 / 후속 PR 후보
- (예: Repository 계층 도입 / Hive Stream 전환 / 테스트 커버리지 보강)

### 배운 점
- (작성)

### 검증 결과
- `flutter analyze`, `flutter test`, release 빌드 스모크
