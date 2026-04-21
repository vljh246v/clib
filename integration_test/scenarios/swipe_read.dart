import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clib/blocs/home/home_bloc.dart';
import 'package:clib/blocs/home/home_event.dart';
import 'package:clib/main.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'package:hive/hive.dart';

import '../helpers/test_harness.dart';

/// 시나리오 #2 — 스와이프 읽음 처리 (Home 3.1).
///
/// 실 제스처는 `CardSwiper` 특성상 integration_test 에서 불안정하므로
/// `HomeBloc` 에 `HomeSwipeRead` 이벤트를 직접 dispatch 해 Bloc 경로를 검증한다.
///
/// 검증:
/// 1. 시드 2건 중 첫 카드(t1) 제목이 보인다.
/// 2. `HomeSwipeRead(t1)` dispatch 후 t2 제목이 보인다(덱 교체).
/// 3. Hive 의 t1.isRead == true (markAsRead 반영).
void registerSwipeReadTests() {
  group('Home swipe read', () {
    setUp(() => TestHarness.resetAll());

    testWidgets('오른쪽 스와이프 = 읽음 → 덱에서 제거 + Hive isRead=true',
        (tester) async {
      const title1 = 'Swipe Read Article 1';
      const title2 = 'Swipe Read Article 2';
      // createdAt 오름차순 정렬이므로 t1 이 먼저(=덱 상단).
      final a1 = await TestHarness.seedArticle(
        url: 'https://example.com/swipe/1',
        title: title1,
      );
      a1.createdAt = DateTime.now().subtract(const Duration(minutes: 10));
      await a1.save();
      await TestHarness.seedArticle(
        url: 'https://example.com/swipe/2',
        title: title2,
      );
      await DatabaseService.setOnboardingComplete();
      await DatabaseService.setHomeGuideComplete();

      await tester.pumpWidget(const ClibApp());
      await TestHarness.pumpUntil(
        tester,
        until: find.text(title1),
        timeout: const Duration(seconds: 8),
      );

      expect(find.text(title1), findsOneWidget);

      // HomeBloc 획득 → HomeSwipeRead dispatch.
      final homeBlocContext = tester.element(find.byType(CardSwiper));
      final homeBloc = homeBlocContext.read<HomeBloc>();
      homeBloc.add(HomeSwipeRead(a1));

      await TestHarness.pumpUntil(
        tester,
        until: find.text(title2),
        timeout: const Duration(seconds: 5),
      );

      expect(find.text(title2), findsOneWidget,
          reason: '덱에서 t1 제거 후 t2 가 렌더되어야 함');

      // Hive 직접 확인 — markAsRead 가 반영되었는지.
      final box = Hive.box<Article>('articles');
      final reread = box.get(a1.key) as Article;
      expect(reread.isRead, isTrue,
          reason: 'markAsRead 가 Hive 에 반영되지 않았음');
    });
  });
}
