# PR 7 — BookmarkedArticlesScreen + LabelDetailScreen (Cubit 재사용)

> PR 6에서 만든 `ArticleListCubit` + `ArticleListView`를 두 화면에 적용하여 중복 코드를 제거한다. 예상 감소: 화면당 ~500 LOC → ~150 LOC.

**의존성**: PR 6 (필수)
**브랜치**: `feature/bloc-07-bookmarked-label`
**예상 작업 시간**: 2~3시간
**난이도**: ⭐⭐⭐

---

## 1. 목표

- `BookmarkedArticlesScreen` → `ArticleListCubit(ArticleListSource.bookmarked())` 기반
- `LabelDetailScreen` → `ArticleListCubit(ArticleListSource.byLabel(name))` 기반
- 각 화면의 고유 요소(앱바 제목, 라벨 헤더, 필터 로직 등)만 유지
- 유닛 테스트(상태 클래스 재사용이므로 생략 가능)

---

## 2. 사전 요건

| 파일 | 범위 |
|------|------|
| `lib/screens/bookmarked_articles_screen.dart` | 전체 (664 LOC) |
| `lib/screens/label_detail_screen.dart` | 전체 (685 LOC) |
| PR 6에서 만든 `lib/blocs/article_list/*` | 구조 재확인 |
| PR 6에서 만든 `lib/widgets/article_list_view.dart` | 재사용 |

**핵심 사실**:
- `BookmarkedArticlesScreen`은 AllArticlesScreen과 탭 구조 동일(전체/안읽음/읽음) — Source만 다름
- `LabelDetailScreen`은 라벨 정보 헤더 + 알림 토글 같은 고유 UI를 가질 수 있음 → 기존 코드 확인 필수

---

## 3. BookmarkedArticlesScreen 교체

```dart
class BookmarkedArticlesScreen extends StatelessWidget {
  const BookmarkedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(const ArticleListSource.bookmarked()),
      child: const _BookmarkedBody(),
    );
  }
}
```

`_BookmarkedBody`는 AllArticlesScreen의 `_AllArticlesBody`와 거의 동일한 구조를 따른다. **차이점만** 반영:

- `AppBar.title`: `l10n.bookmarkedArticles`
- 필요시 empty 상태 메시지 변경 (`l10n.bookmarkEmpty`)

### 3.1 중복 줄이기

AllArticlesScreen과 BookmarkedArticlesScreen의 본체가 거의 같다면 **더 공통화 가능**:

```dart
// lib/widgets/article_list_screen_body.dart 도입 고려
class ArticleListScreenBody extends StatefulWidget {
  const ArticleListScreenBody({
    super.key,
    required this.title,
    this.headerBuilder,
    this.emptyBuilder,
  });

  final Widget title;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? emptyBuilder;
  // ...
}
```

위 위젯을 만들면 AllArticles/Bookmarked는 거의 한 줄:

```dart
ArticleListScreenBody(title: Text(l10n.bookmarkedArticles))
```

**결정**: 이번 PR에서 **ArticleListScreenBody 추출을 병행 권장**. 안 하면 여전히 3화면이 각자 TabController/AppBar 코드를 들고 있게 됨.

단, PR 6에서 `_AllArticlesBody`가 이미 특수한 로직을 많이 갖고 있으면, 추출 범위를 조절. 핸드오프 노트에 근거 기록.

---

## 4. LabelDetailScreen 교체

### 4.1 라벨별 고유 요소 확인

먼저 기존 코드에서 다음을 확인:
- 앱바 타이틀: 라벨 이름
- 라벨 알림 설정 버튼 (대부분 있음)
- 라벨 이름/색상 편집 진입
- 라벨별 통계 카드

이 요소들은 **화면 고유**이므로 Cubit에 넣지 않고 위젯 로컬에 유지. 또는 LibraryCubit/LabelManagementCubit을 별도로 주입해 통계를 읽는다.

### 4.2 구조

```dart
class LabelDetailScreen extends StatelessWidget {
  const LabelDetailScreen({super.key, required this.label});
  final Label label;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticleListCubit(ArticleListSource.byLabel(label.name)),
      child: _LabelDetailBody(label: label),
    );
  }
}
```

### 4.3 본체

```dart
class _LabelDetailBody extends StatefulWidget {
  const _LabelDetailBody({required this.label});
  final Label label;

  @override
  State<_LabelDetailBody> createState() => _LabelDetailBodyState();
}

class _LabelDetailBodyState extends State<_LabelDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      context.read<ArticleListCubit>().changeTab(_tab.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... AllArticlesScreen과 유사. 차이는 앱바 타이틀과 통계 헤더.
  }
}
```

### 4.4 통계 헤더

라벨 통계가 Cubit 상태로 올라오지 않는다면 `DatabaseService.getLabelStats(label.name)` 직접 호출. 다만 아티클 변경 시 통계도 갱신되어야 하므로 **`ArticleListState.articles` 변화에 따라 파생 통계를 계산**하는 게 깔끔:

```dart
// _LabelDetailBody.build 내부
BlocBuilder<ArticleListCubit, ArticleListState>(
  builder: (context, state) {
    final total = state.articles.length;
    final unread = state.articles.where((a) => !a.isRead).length;
    return _StatsHeader(total: total, unread: unread);
  },
),
```

**주의**: 이 방식은 Cubit의 articles가 **모든 해당 라벨 아티클**(삭제/tombstone 제외)을 담고 있음을 전제로 한다. DatabaseService가 필터링 후 반환하므로 맞을 것.

### 4.5 라벨 편집 / 알림 / 삭제 버튼

기존 LabelManagementScreen의 편집 다이얼로그를 재사용 가능하면 그대로. 없으면 LabelManagementCubit을 BlocProvider로 별도 주입하거나 DatabaseService를 직접 호출.

**권장**: 간단한 경우 이번 PR에서는 기존 로직 유지. LabelManagementCubit 재사용은 별도 개선.

---

## 5. 주의사항

- **BlocProvider scope**가 화면 전체를 감싸야 BottomAppBar의 버튼 액션이 `context.read`로 Cubit을 찾을 수 있다.
- `LabelDetailScreen`은 라벨 이름을 삭제/변경하면 `ArticleListSource.byLabel(name)`이 stale해질 수 있다. 편집 후에는 `Navigator.pop`으로 화면 빠져나가게 하거나, 새 이름으로 화면 재진입 유도.
- Firestore 동기화에서 라벨명 변경이 일어나면 현재 화면의 소스와 안 맞게 됨. 이 경우 `articlesChangedNotifier` 펄스 → `load()` → 빈 리스트가 정상. 사용자 안내 UI 없음(기존과 동일).

---

## 6. 테스트

- Cubit 자체는 PR 6에서 테스트됨. 이번 PR에서는 Source 분기 경로만 추가:

```dart
test('_fetch dispatches to correct DatabaseService method by source', () {
  // DatabaseService 호출을 mock하기 어렵다면 실 Hive로 seed 후 소스별 호출 결과 비교
});
```

- 또는 스킵하고 실기기 QA로 대체.

---

## 7. 검증

```bash
flutter analyze
flutter test
```

### 실기기 스모크

- [ ] 라이브러리 > 북마크 카드 → BookmarkedArticlesScreen
  - 모든 동작이 AllArticlesScreen과 동일하게 작동
- [ ] 라이브러리 > 임의 라벨 카드 → LabelDetailScreen
  - 라벨명/통계 헤더 정상
  - 탭 전환/다중선택/롱프레스 모두 동작
- [ ] LabelDetail에서 라벨 이름 편집 → 화면 제목 갱신 또는 자연스러운 복귀
- [ ] LabelDetail에서 라벨 삭제 → 화면 자동 닫힘 (기존 동작과 동일해야 함)

---

## 8. 리팩터링 성과 측정

PR 6 전:
- AllArticles: 728 LOC
- Bookmarked: 664 LOC
- LabelDetail: 685 LOC
- 합계: **2,077 LOC**

PR 7 후 목표:
- AllArticles: ~150 LOC
- Bookmarked: ~100 LOC
- LabelDetail: ~200 LOC
- ArticleListCubit: ~200 LOC
- ArticleListView: ~120 LOC
- ArticleListScreenBody (선택): ~150 LOC
- 합계: **~920 LOC (55% 감소)**

실제 수치를 핸드오프 노트에 기록.

---

## 9. 커밋 메시지

```
BLoC PR7: Bookmarked/LabelDetail 화면 ArticleListCubit 재사용

- BookmarkedArticlesScreen → source.bookmarked()
- LabelDetailScreen → source.byLabel(name)
- (선택) ArticleListScreenBody 공통 위젯 추출
- 중복 코드 약 N% 감소
```

---

## 10. 핸드오프 노트

### 계획대로 된 점
- (작성)

### 계획과 다르게 된 점
- (작성)

### 새로 발견한 이슈 / TODO
- (작성)

### 참고한 링크
- (작성)

### 다음 세션 유의사항
- (작성)

### 검증 결과
- (작성)

### LOC 감소 결과
- (작성)
