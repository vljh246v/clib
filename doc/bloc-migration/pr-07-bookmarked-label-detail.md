# PR 7 — BookmarkedArticlesScreen + LabelDetailScreen (Cubit 재사용)

> PR 6에서 만든 `ArticleListCubit` + `ArticleListView` + `BulkActionBar`를 두 화면에 적용하여 중복 코드를 제거한다.
> 예상 감소: 화면당 ~650 LOC → ~200 LOC.

**의존성**: PR 6 (필수)
**브랜치**: `feature/bloc-07-bookmarked-label`
**예상 작업 시간**: 2~3시간
**난이도**: ⭐⭐⭐

---

## 0. 사전 필독: PR 6 실제 구현 정리

PR 6 계획 문서의 예제 코드 일부가 실제 구현과 다르다. **이 섹션을 먼저 숙지하고 시작할 것.**

### 실제 Source 클래스 이름

```dart
// lib/blocs/article_list/article_list_source.dart
ArticleListSourceAll()                // (NOT ArticleListSource.all())
ArticleListSourceBookmarked()         // (NOT ArticleListSource.bookmarked())
ArticleListSourceByLabel(labelName)   // (NOT ArticleListSource.byLabel(name))
```

### 실제 State 구조

```dart
class ArticleListState extends Equatable {
  final ArticleListSource source;
  final List<Article> articles;      // source 기준 전체 목록
  final bool isSelecting;
  final List<dynamic> selectedKeys;  // Set 아님
  final int generation;              // load()마다 +1, emit 스킵 방지용

  // getters: total, readCount, unreadCount, readArticles, unreadArticles
  // bool allSelectedFor(List<Article> visible)
}
```

`tabIndex` 없음. 탭 필터링은 위젯의 `TabController.index`로 처리.

### 실제 Cubit 메서드

| 계획 | 실제 |
|------|------|
| `changeTab(int)` | **없음** |
| `toggleItem(dynamic key)` | `toggleSelection(dynamic key)` |
| `selectAll()` | `selectAll(List<Article> visibleArticles)` |
| bulk 후 `clearSelection()` + `load()` | `_reloadAndClearSelection()` 단일 emit |

### 실제 `ArticleListView` 서명

```dart
ArticleListView(
  articles: visibleArticles,          // 이미 필터링된 목록
  isSelecting: state.isSelecting,
  selectedKeys: state.selectedKeys,   // List<dynamic>
  onTap: (article) { ... },
  onSelectionToggle: (key) => cubit.toggleSelection(key),
  emptyWidget: ...,                   // Widget (builder 아님)
  onLongPress: (article) { ... },     // nullable
)
```

### 실제 `BulkActionBar` 서명 (lib/widgets/bulk_action_bar.dart)

```dart
BulkActionBar(
  onBookmark: () => cubit.bulkToggleBookmark(true),
  onRemoveBookmark: () => cubit.bulkToggleBookmark(false),
  onMarkUnread: () => cubit.bulkMarkRead(false),
  onMarkRead: () => cubit.bulkMarkRead(true),
  onDelete: () => _confirmBulkDelete(context),
)
```

---

## 1. 목표

- `BookmarkedArticlesScreen` → `ArticleListCubit(ArticleListSourceBookmarked())` 기반으로 전환
- `LabelDetailScreen` → `ArticleListCubit(ArticleListSourceByLabel(label.name))` 기반으로 전환
- 각 화면의 고유 요소만 유지 (AppBar 제목, LabelDetailScreen의 통계 헤더/라벨색)
- 두 화면의 `ArticleListScreenBody` 공통 추출은 **불필요** — 각 AppBar 로직이 달라 오버엔지니어링

---

## 2. 사전 요건

먼저 두 파일 전체를 읽어 고유 요소를 파악한다.

| 파일 | 현재 LOC | 핵심 고유 요소 |
|------|---------|--------------|
| `lib/screens/bookmarked_articles_screen.dart` | 664 | AppBar 제목(`bookmarkedArticles`), 탭 구조는 AllArticles와 동일 |
| `lib/screens/label_detail_screen.dart` | 685 | `labelColor`, 통계 헤더, 라벨 아이콘(첫 글자), `_showArticleActions(article, labelColor)` |

---

## 3. BookmarkedArticlesScreen 교체

구조는 `AllArticlesScreen`과 거의 동일. **차이점만** 반영:

```dart
class BookmarkedArticlesScreen extends StatelessWidget {
  const BookmarkedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(const ArticleListSourceBookmarked()),
      child: const _BookmarkedBody(),
    );
  }
}
```

### 3.1 `_BookmarkedBody`

`AllArticlesScreen`의 `_AllArticlesBody`를 템플릿으로 사용하되 다음만 변경:

1. **AppBar.title**: `l.bookmarkedArticles` (선택 모드 아닐 때)
2. **Tab listener** (AllArticles와 동일 패턴):
   ```dart
   _tabController.addListener(() {
     if (_tabController.indexIsChanging) {
       context.read<ArticleListCubit>().clearSelection();
       setState(() {}); // 탭 헤더 stale 방지
     }
   });
   ```
3. **빈 상태 메시지**: `l.noBookmarks` (탭별로 북마크 전용 메시지 사용)
4. **탭별 필터링** (위젯에서 처리):
   ```dart
   final visibleArticles = switch (_tabController.index) {
     0 => state.articles,
     1 => state.unreadArticles,
     2 => state.readArticles,
     _ => state.articles,
   };
   ```

### 3.2 핵심 주의사항

- Tab listener에 반드시 `setState(() {})` 포함. 없으면 BlocBuilder가 rebild 스킵 → 탭 헤더 카운트 stale.
- `selectAll(visibleArticles)` 호출 시 현재 탭의 `visibleArticles` 전달.

---

## 4. LabelDetailScreen 교체

기존 `LabelDetailScreen`에는 AllArticlesScreen에 없는 고유 요소가 있다.

### 4.1 고유 요소 확인

기존 코드에서 확인된 주요 고유 요소:

- `labelColor = Color(widget.label.colorValue)` — 아티클 아이템 좌측 라벨 색 표시
- 통계 헤더 (total / read 카운트) — `DatabaseService.getLabelStats()` 직접 호출 중
- 앱바 좌측에 라벨 아이콘 (첫 글자 + 라벨색 원형 배경)
- `_showArticleActions(article, labelColor)` — labelColor를 파라미터로 받음

### 4.2 구조

```dart
class LabelDetailScreen extends StatelessWidget {
  const LabelDetailScreen({super.key, required this.label});
  final Label label;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(ArticleListSourceByLabel(label.name)),
      child: _LabelDetailBody(label: label),
    );
  }
}
```

### 4.3 통계 헤더

`DatabaseService.getLabelStats()` 직접 호출 대신 **Cubit state에서 파생 계산**:

```dart
BlocBuilder<ArticleListCubit, ArticleListState>(
  builder: (context, state) {
    final total = state.total;
    final unread = state.unreadCount;
    final read = state.readCount;
    // 통계 헤더 위젯 렌더링
  },
)
```

이 방식이 아티클 변경 시 통계도 자동 갱신 (별도 `getLabelStats()` 재호출 불필요).

### 4.4 `labelColor` 처리

라벨 색은 `_LabelDetailBody.widget.label`에서 한 번만 파생:

```dart
class _LabelDetailBodyState extends State<_LabelDetailBody>
    with SingleTickerProviderStateMixin {
  late final Color _labelColor;

  @override
  void initState() {
    super.initState();
    _labelColor = Color(widget.label.colorValue);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<ArticleListCubit>().clearSelection();
        setState(() {});
      }
    });
  }
}
```

`_labelColor`를 `_buildTab()`, `_showArticleActions()` 등에 전달.

### 4.5 `_showArticleActions`에서 `labelColor` 전달

기존 코드가 `_showArticleActions(article, labelColor)`로 색상 파라미터를 받는다면 그대로 유지.
없다면 아티클 아이템 좌측 컬러 표시는 `ArticleListItem`에 `labelColor` 파라미터 추가 고려 (별도 결정).

### 4.6 라벨명 stale 문제

`ArticleListSourceByLabel(label.name)`은 화면 진입 시 이름을 캡처한다.
라벨 이름 편집 후에는 `Navigator.pop()`으로 화면을 빠져나가게 해야 한다 (기존 동작 유지).
편집 없이 그냥 화면이 열려 있는 상태에서 라벨명이 변경되면 다음 `load()`가 빈 리스트를 반환하지만 별도 안내 UI는 없어도 됨 (기존과 동일 동작).

### 4.7 라벨 편집 / 알림 버튼

기존 로직을 그대로 유지한다. `LabelManagementCubit` 재사용은 별도 개선.

---

## 5. `_MemoSheet` 패턴

두 화면 모두 메모 다이얼로그가 있다. `AllArticlesScreen`에서 사용한 `_MemoSheet` 패턴을 동일하게 적용:

```dart
class _MemoSheet extends StatefulWidget {
  const _MemoSheet({required this.article, required this.cubit});
  final Article article;
  final ArticleListCubit cubit;

  @override
  State<_MemoSheet> createState() => _MemoSheetState();
}

class _MemoSheetState extends State<_MemoSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.article.memo);
  }

  @override
  void dispose() {
    _controller.dispose(); // 반드시 dispose
    super.dispose();
  }
  // ...
}
```

**절대 인라인 builder에서 TextEditingController 생성하지 말 것** — dispose 누락으로 메모리 누수.

---

## 6. `use_build_context_synchronously` 방지

async 콜백 내 `Navigator.pop(context)` 전에 context를 캡처:

```dart
onPressed: () async {
  final nav = Navigator.of(context); // await 전에 캡처
  await widget.cubit.updateMemo(widget.article, memo);
  if (mounted) nav.pop();
},
```

---

## 7. 테스트

Cubit 자체는 PR 6에서 22개 테스트 통과. PR 7에서 추가할 것:

```dart
// test/blocs/article_list_cubit_test.dart에 추가

group('ArticleListSourceBookmarked', () {
  test('load returns only bookmarked articles', () async {
    DatabaseService.skipSync = true;
    // Hive setUp ...
    final a = Article(url: 'u', title: 't', isBookmarked: true, ...);
    await DatabaseService.saveArticle(a);
    final cubit = ArticleListCubit(const ArticleListSourceBookmarked());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.articles.every((a) => a.isBookmarked), true);
    await cubit.close();
  });
});

group('ArticleListSourceByLabel', () {
  test('load returns articles with matching label', () async {
    // ...
    final cubit = ArticleListCubit(const ArticleListSourceByLabel('flutter'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.articles.every((a) => a.topicLabels.contains('flutter')), true);
    await cubit.close();
  });
});
```

테스트 패턴 핵심:
- `DatabaseService.skipSync = true` (Firebase 미초기화 환경)
- Cubit 생성 후 `await Future<void>.delayed(Duration.zero)` (broadcast stream async 특성)

---

## 8. 검증

```bash
flutter analyze    # No issues 필수
flutter test       # 신규 테스트 포함 전체 통과
```

### 실기기 스모크

**BookmarkedArticlesScreen:**
- [ ] 라이브러리 > 북마크 카드 → 화면 진입
- [ ] 전체/안읽음/읽음 탭 전환 + 카운트 정상
- [ ] 다중선택 → 전체선택 → 일괄 북마크해제 → 목록 갱신
- [ ] 롱프레스 → 액션시트 (북마크 토글, 메모, 읽음, 삭제)
- [ ] 메모 입력 → 저장/삭제 정상

**LabelDetailScreen:**
- [ ] 라이브러리 > 라벨 카드 → 화면 진입
- [ ] 라벨명 / 통계 헤더 정상 표시
- [ ] 라벨색 반영 (아티클 아이템 좌측 컬러)
- [ ] 탭 전환 + 다중선택 + 일괄 작업
- [ ] 라벨 이름 편집 → 화면 pop (stale 방지)
- [ ] 라벨 삭제 → 화면 자동 닫힘

---

## 9. 리팩터링 성과 측정

PR 6 기준:
- `bookmarked_articles_screen.dart`: 664 LOC (미변경)
- `label_detail_screen.dart`: 685 LOC (미변경)
- 합계: **1,349 LOC**

PR 7 목표:
- `bookmarked_articles_screen.dart`: ~200 LOC
- `label_detail_screen.dart`: ~250 LOC (통계 헤더 + 라벨색 고유 로직 포함)
- 합계: **~450 LOC (67% 감소)**

실제 수치를 핸드오프 노트에 기록.

---

## 10. 커밋 메시지

```
BLoC PR7: Bookmarked/LabelDetail 화면 ArticleListCubit 재사용

- BookmarkedArticlesScreen → ArticleListSourceBookmarked()
- LabelDetailScreen → ArticleListSourceByLabel(label.name)
- 통계 헤더 state.articles 파생 계산으로 전환
- _MemoSheet 패턴 재사용
- 기존 LOC 약 N% 감소
```

---

## 11. 핸드오프 노트

### 계획대로 된 점
- `BookmarkedArticlesScreen` → `ArticleListCubit(const ArticleListSourceBookmarked())` 전환.
- `LabelDetailScreen` → `ArticleListCubit(ArticleListSourceByLabel(label.name))` 전환.
- AllArticlesScreen과 동일한 StatelessWidget + BlocProvider + `_XxxBody(StatefulWidget, TabController)` 구조.
- 공통 위젯 2종 신규 분리:
  - `lib/widgets/memo_sheet.dart` (162 LOC): `MemoSheet.show()` 정적 헬퍼 제공. TextEditingController StatefulWidget 라이프사이클로 관리.
  - `lib/widgets/article_actions_sheet.dart` (160 LOC): `ArticleActionsSheet.show()` 정적 헬퍼. 롱프레스 액션시트 5종(북마크/메모/읽음/브라우저/삭제) + 삭제 confirm dialog + MemoSheet 연계.
- 3개 화면(All/Bookmarked/LabelDetail) 모두 공통 위젯 재사용. 중복 제거 완료.
- Tab listener `setState(() {})` 포함해 Equatable 스킵 시에도 탭 헤더 카운트 stale 방지 (PR 6 교훈 적용).
- LabelDetail `_labelColor`는 `initState` 1회 파생, `_buildTab`/TabBar/AppBar CircleAvatar 3곳 재사용.
- 통계 헤더는 `state.total / readCount / unreadCount` 파생 계산으로 전환 — `DatabaseService.getLabelStats()` 직접 호출 제거.
- `flutter analyze`: No issues. `flutter test test/blocs/`: 49 PASS (PR 6 대비 증가분 0 — Bookmarked/ByLabel 테스트는 PR 6에서 이미 추가됨).

### 계획과 다르게 된 점
- **PR 7 문서의 "테스트 추가" 항목 불필요**: `test/blocs/article_list_cubit_test.dart`에 Bookmarked/ByLabel 그룹이 PR 6 때 이미 포함(라인 125-153). 문서는 추가 안내였으나 실제로는 기존 커버리지 그대로 둠.
- **`_showArticleActions(article, labelColor)`의 labelColor 파라미터 드롭**: 기존 LabelDetail 코드가 labelColor를 전달받았지만 body에서 사용하지 않음(데드 코드). 공통 `ArticleActionsSheet`는 파라미터 불요.
- **`ArticleListItem`에 labelColor 추가 안 함**: PR 7 문서 §4.5의 "별도 결정" 항목. 기존 LabelDetail 아이템은 `check_circle` / `bookmark` 뱃지에 labelColor 사용했지만, 디자인 일관성 위해 secondary 유지. 라벨색은 AppBar CircleAvatar + TabBar + empty 아이콘만 적용.
- **`ArticleActionsSheet`에 `rootContext` 명시 전달**: 삭제 confirm dialog / MemoSheet 진입은 시트 pop 이후 BuildContext가 필요한데, `_SheetBody` 내부 context는 pop 뒤 deactivated 되므로 호출 측(`show(context, ...)`) context를 `rootContext`로 주입.

### 새로 발견한 이슈 / TODO
- **`selectedKeys: List<dynamic>` → `List<int>` 축소 검토**: Hive key는 int이므로 타입 좁힐 수 있음(PR 6에서도 언급됨). 후속 cleanup에서.
- **`ArticleActionsSheet` 진입점 일관성**: 호출 측에서 `cubit: context.read<ArticleListCubit>()`를 매번 받는 대신 시트가 `BlocProvider.of`로 self-lookup 하는 방식도 가능. 다만 시트 route가 provider 범위 이탈 가능성 때문에 현재 capture 패턴 유지.
- **`_confirmBulkDelete` 3화면 중복**: 같은 dialog 로직이 3곳에 있음. `bulk_delete_dialog.dart`로 추출 가능하나 LOC가 작고 `l.deleteSelectedConfirm(count)` 단일 호출이라 우선순위 낮음.
- **`adInterval = 8` 매직 넘버**: `ArticleListView`에 상수화 상태. PR 11 cleanup에서 AdService 인접 상수로 이동 검토.

### 다음 세션 유의사항 (PR 8)
- **AddArticleCubit**은 공유 시트(`add_article_sheet.dart`) + 수동 저장 화면. 기존 인라인 form 상태(`TextEditingController`, 로딩 flag)를 Cubit state로 승격.
- **URL 검증 / 스크래핑 중 상태** — `isLoading` / `errorMessage` 2상태로 충분. `ClearError()` 공개 메서드 추가.
- **`ScrapingService` 호출** — Cubit 내부에서 직접. Error 발생 시 errorMessage state로 승격, SnackBar는 BlocListener.
- **공통 위젯 재사용 현황**: `ArticleListCubit` / `ArticleListView` / `BulkActionBar` / `ArticleActionsSheet` / `MemoSheet` 모두 PR 6~7에서 분리 완료. PR 8은 추가 위젯 분리 없음.
- **컨벤션 불변**: bloc_test 미도입 / Hive 격리 path / 화면 로컬 BlocProvider / 서브에이전트 병렬 dispatch (단순 haiku, 로직 sonnet, 최종 opus) / 시뮬레이터 스모크는 사용자 요청 시만.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/`: ✅ 49 PASS
- 실기기 스모크: ⚪ 미수행 (사용자 요청 시 진행)

### LOC 감소 결과
- `bookmarked_articles_screen.dart`: **664 → 228 LOC** (-65.7%)
- `label_detail_screen.dart`: **685 → 251 LOC** (-63.4%)
- `all_articles_screen.dart`: 506 → 230 LOC (PR 7 리팩터 부수 효과, -54.5%)
- 신규 공통 위젯: `memo_sheet.dart` 162 LOC + `article_actions_sheet.dart` 160 LOC = 322 LOC 추가.
- **순 감소**: (664+685+506) - (228+251+230+322) = 1855 - 1031 = **-824 LOC (-44.4%)**
