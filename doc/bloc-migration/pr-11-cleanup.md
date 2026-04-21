# PR 11 — Cleanup + 문서화

> PR 1~9 전환 완료 후 누적된 후속 정리 + CLAUDE.md 갱신 + 최종 회귀 테스트.

**의존성**: PR 1~9 완료
**브랜치**: `feature/bloc-11-cleanup` (코드/문서 7 커밋 적용 완료)
**현재 상태**: 🟡 In Progress — 코드/문서 정리 종료, **§2.6 widget_test + §3 실기기 스모크만 남음**

---

## 1. 완료 요약 (2026-04-21)

§2.1~2.5 / §2.7~2.9 모두 처리. 분할 커밋 7개:

| 커밋 | 제목 |
|------|------|
| `51ecd9f` | (1/7) notifier 발사 경로 DatabaseService 일원화 + bulkDelete batch |
| `913e7e6` | (2/7) home_screen 디자인 토큰 + AdService.adInterval 상수화 + dispose 보강 |
| `149da17` | (3/7) showBulkDeleteConfirm 헬퍼 + ArticleListItem.accentColor + 타입 좁힘 |
| `01f0ed9` | (4/7) 미사용 ARB 키 syncing/syncComplete 제거 (10 로케일) |
| `a229204` | (5/7) pubspec.yaml environment.flutter floor 명시 |
| `deb6b2e` | (6/7) CLAUDE.md flutter_bloc 기반 구조 갱신 |
| `01c4a78` | (7/7) doc/bloc-migration PR 11 핸드오프 |

**검증**: `flutter analyze` 0건, `flutter test test/blocs/` 74 PASS.

자세한 변경 내역 + 계획 차이 + 후속 PR 후보는 `SESSION_LOG.md` PR 11 엔트리.

---

## 2. 완료 체크리스트

### 2.1 Notifier 발사 경로 통합 ✅

- [x] `DatabaseService.createLabel/updateLabel/deleteLabel` → `labelsChangedNotifier` 발사
- [x] `DatabaseService.markAsRead/markAsUnread/bulkMarkRead/toggleBookmark/bulkSetBookmark/updateMemo/updateArticleLabels/deleteArticle/saveArticle` → `articlesChangedNotifier` 발사
- [x] `HomeBloc._onToggleBookmark/_onUpdateMemo` 수동 `add(HomeLoadDeck)` 제거
- [x] `ArticleListCubit` 개별 액션 수동 `await load()` 제거
- [x] `ShareService.processAndSave` 중복 발사 제거
- [x] `lib/state/app_notifiers.dart`로 정의 분리(순환 import 회피) + main.dart re-export

### 2.2 컨트롤러 라이프사이클 정리 ✅

- [x] `HomeScreen._showMemoDialog` `whenComplete(controller.dispose)`
- [x] `share_label_sheet._showAddLabelDialog` nameController dispose
- [x] `label_management_screen._showLabelDialog` nameController dispose

### 2.3 디자인 토큰 적용 ✅

- [x] `home_screen` SizedBox/EdgeInsets 12/16/8/4/20 → `Spacing.*`
- [x] `BorderRadius.circular(20)` → `Radii.borderXl`
- [x] `adInterval = 8` → `AdService.adInterval` 상수, `home_screen` + `article_list_view` 모두 참조
- [ ] **(보류)** `_SwipeHint` 왼쪽 색 — 디자인 의도 확인 필요. 별도 PR/이슈로 분리.
- [ ] **(인라인 유지)** 26/28/36/120 등 의도 사이즈는 토큰화하지 않음.

### 2.4 코드 품질 nit 이관 ✅

- [x] `ArticleListItem.accentColor` 옵션 + `ArticleListView.accentColor` 패스스루
- [x] `LabelDetailScreen`이 `_labelColor` 전달
- [x] `_confirmBulkDelete` 3화면 중복 → `lib/widgets/bulk_delete_confirm.dart` `showBulkDeleteConfirm()`
- [x] `selectedKeys: List<dynamic>` → `List<int>` (state + cubit + view)
- [x] `bulkDelete` for-await → `DatabaseService.bulkDelete(articles)` batch

### 2.5 미사용 코드 / import 정리 ✅

- [x] `themeModeNotifier` / `authStateNotifier` 잔존 없음 확인 (PR 1/2에서 제거됨)
- [x] `dart fix --dry-run` Nothing to fix
- [x] `debugPrint` 모두 의미 있는 logging — 유지
- [x] 미사용 ARB 키 `syncing` / `syncComplete` 10 로케일 제거 + `flutter gen-l10n` 재생성
- [ ] **(보존)** NotificationService 4개 키(`notificationChannelName/Desc`,
  `allReadNotification`, `unreadNotification`)는 BuildContext 없이 동작하는
  구조라 보존. 별도 PR(`lookupAppLocalizations` 도입)로 통합 검토.

### 2.7 pubspec / 환경 ✅

- [x] `pubspec.yaml` `environment.flutter: ">=3.32.0"` floor 명시 (RadioGroup<T>)

### 2.8 CLAUDE.md 갱신 ✅

- [x] 기술 스택에 `flutter_bloc` / `equatable` / `bloc_test` 추가
- [x] 프로젝트 구조에 `lib/blocs/` + `lib/state/` + 신규 위젯 반영
- [x] 서비스 계층 표 — DatabaseService notifier 단독 책임 + ShareService 위임 명시
- [x] **전역 상태** 섹션 전면 재작성 — MultiBlocProvider 표 + app_notifiers + 부팅 흐름
- [x] **화면별 주요 로직** Cubit/Bloc 표기 + selectedKeys: List<int>
- [x] **개발 컨벤션 §상태 관리 규칙** 신설 (refreshToken/deckVersion/controller SSOT/에러 채널/bloc_test 미도입 사유)

### 2.9 doc/bloc-migration 마무리 ✅

- [x] `archive/` 디렉토리 신설
- [x] PR 1~10 문서를 `archive/`로 이동
- [x] PR 1~9 SESSION_LOG 엔트리 → `archive/SESSION_LOG_PR1-9.md`로 분리
- [x] 활성 `README.md` / `SESSION_LOG.md` / `SESSION_STARTER.md` 압축 + 갱신
- [x] PR 11 트래커 🟡 (§2.6 + §3 완료 후 🟢)

---

## 3. 남은 작업 (다음 세션) 🚧

### 3.1 §2.6 widget_test 재작성

- [ ] `test/helpers/hive_bootstrap.dart` 추출
  - `setUpAll`: `.dart_tool/test_hive_<name>` 격리 path + Adapter 등록 + box open
  - `setUp`: `box.clear()` + `DatabaseService.skipSync = true`
  - `tearDownAll`: `Hive.deleteFromDisk()`
- [ ] Firebase 초기화 처리 결정 (mock 패키지 도입 vs 분기 vs skip)
- [ ] `test/widget_test.dart` 재작성 — `MainScreen` / `HomeScreen` 스모크 수준

### 3.2 §3 실기기 회귀 스모크 (`flutter run --release`)

- [ ] 첫 실행(Hive 초기화) → 온보딩 3페이지 → 메인
- [ ] 아티클 저장 (시스템 공유 시트 → 앱)
- [ ] 수동 URL 추가 (+ 버튼 → AddArticleSheet)
- [ ] 홈 스와이프: 오른쪽(읽음), 왼쪽(나중에), loop 경계
- [ ] 홈 라벨 필터: 단일/다중(AND), 해제, 확장/접기
- [ ] 홈 롱프레스 액션: 북마크, 메모 추가/수정/삭제, 라벨 편집, 외부 열기
- [ ] 8번째 슬롯 광고 카드 스와이프 (상태 영향 없음)
- [ ] 라이브러리 탭: 전체/북마크/라벨별 진입
- [ ] 전체 / 북마크 / LabelDetail: 행 탭, 롱프레스 액션, 다중선택 + 일괄 액션 (읽음/북마크/삭제)
- [ ] 라벨 CRUD + 라벨별 알림(요일 칩 + TimePicker)
- [ ] 테마 전환(Light/Dark/System) + 앱 재시작 유지
- [ ] Google/Apple 로그인 → Firestore 동기화(articles + labels)
- [ ] 로그아웃 → 재로그인 → 동기화 정상
- [ ] 계정 삭제
- [ ] 백그라운드 → 포그라운드 → 상태 꼬임/크래시 없음
- [ ] `flutter run --release` 크래시 없이 전 플로우 통과

**핵심 회귀 포인트** (notifier 일원화 + bulkDelete batch):
- 다중 선택 일괄 삭제/북마크/읽음
- 라벨 변경 후 모든 화면 동기 갱신
- 공유 시트 → 라벨 선택 → 저장 후 홈 즉시 반영
- 라벨 이름/색 변경 시 LabelDetail 뱃지 색 + accentColor 반영

### 3.3 마무리

- [ ] §3.1 + §3.2 완료 후 추가 commit (`refactor(test): widget_test 재작성 + hive_bootstrap 헬퍼`)
- [ ] PR 11 push + PR 생성
- [ ] 머지 후 `README.md` 트래커 🟢
- [ ] `SESSION_LOG.md`에 PR 11 완료 엔트리 추가

---

## 4. 후속 PR 후보 (PR 11 외, 별도 작업)

`README.md` § "후속 PR 후보" 표 참조. PR 11 머지 후 우선순위 결정.

- NotificationService ARB 통합
- `_SwipeHint` 색 일관성 결정
- `bulk_action_bar.onDelete` 시그니처 승격
- Repository 계층 도입 검토
- Hive Stream 전환 검토
