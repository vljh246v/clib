import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:clib/blocs/home/home_bloc.dart';
import 'package:clib/blocs/home/home_event.dart';
import 'package:clib/main.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';

import '../helpers/test_harness.dart';

/// 시나리오 #3 — 북마크 토글 (Home 4.5).
///
/// 액션시트 UI 경로 대신 `HomeBloc.HomeToggleBookmark` 를 직접 dispatch.
/// UI 경로(롱프레스 → ListTile 탭)는 시트 애니메이션 + pumpAndSettle 수렴
/// 이슈로 별도 시나리오에서 다룬다.
///
/// 검증:
/// 1. 시드 1건이 홈에 렌더.
/// 2. `HomeToggleBookmark` dispatch → Hive isBookmarked == true.
/// 3. 한 번 더 dispatch → isBookmarked == false (토글).
void registerBookmarkToggleTests() {
  group('Home bookmark toggle', () {
    setUp(() => TestHarness.resetAll());

    testWidgets('HomeToggleBookmark 2회 dispatch → Hive on/off 토글',
        (tester) async {
      const title = 'Bookmark Toggle Article';
      final a = await TestHarness.seedArticle(
        url: 'https://example.com/bookmark',
        title: title,
      );
      await DatabaseService.setOnboardingComplete();
      await DatabaseService.setHomeGuideComplete();

      await tester.pumpWidget(const ClibApp());
      await TestHarness.pumpUntil(
        tester,
        until: find.text(title),
        timeout: const Duration(seconds: 8),
      );

      expect(find.text(title), findsOneWidget);
      expect(a.isBookmarked, isFalse);

      final homeBloc =
          tester.element(find.byType(CardSwiper)).read<HomeBloc>();

      // 1차 토글 → true.
      homeBloc.add(HomeToggleBookmark(a));
      await TestHarness.pumpUntil(
        tester,
        timeout: const Duration(milliseconds: 500),
      );

      final box = Hive.box<Article>('articles');
      var reread = box.get(a.key) as Article;
      expect(reread.isBookmarked, isTrue,
          reason: '1차 토글 후 isBookmarked=true');

      // 2차 토글 → false.
      homeBloc.add(HomeToggleBookmark(reread));
      await TestHarness.pumpUntil(
        tester,
        timeout: const Duration(milliseconds: 500),
      );

      reread = box.get(a.key) as Article;
      expect(reread.isBookmarked, isFalse,
          reason: '2차 토글 후 isBookmarked=false');
    });
  });
}
