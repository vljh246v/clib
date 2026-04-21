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
- (작성)

### 계획과 다르게 된 점
- (작성)

### 새로 발견한 이슈 / TODO
- (작성)

### 다음 세션 유의사항 (PR 8)
- (작성)

### 검증 결과
- (작성)

### LOC 감소 결과
- `bookmarked_articles_screen.dart`: 664 → (작성) LOC
- `label_detail_screen.dart`: 685 → (작성) LOC
