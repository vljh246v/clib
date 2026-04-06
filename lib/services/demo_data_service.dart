import 'package:flutter/material.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/design_tokens.dart';

/// 앱스토어 스크린샷용 데모 데이터 시드
class DemoDataService {
  static Future<void> seed() async {
    // 기존 데이터 모두 삭제
    final existing = DatabaseService.getAllArticles();
    for (final a in existing) {
      await DatabaseService.deleteArticle(a);
    }
    final existingLabels = DatabaseService.getAllLabelObjects();
    for (final l in existingLabels) {
      await DatabaseService.deleteLabel(l);
    }

    // ── 라벨 생성 ──
    await DatabaseService.createLabel('생산성', LabelColors.presets[0]);       // Calm Blue
    await DatabaseService.createLabel('개발', LabelColors.presets[6]);         // Teal
    await DatabaseService.createLabel('디자인', LabelColors.presets[3]);       // Soft Purple
    await DatabaseService.createLabel('자기계발', LabelColors.presets[1]);     // Forest Green
    await DatabaseService.createLabel('트렌드', LabelColors.presets[5]);      // Warm Amber

    // ── 아티클 생성 (최신이 위로) ──
    final articles = <_DemoArticle>[
      // 안 읽은 아티클 (스와이프 카드에 표��)
      _DemoArticle(
        title: '2026 프론트엔드 트렌드 총정리: React 19, Svelte 5, 그리고 그 너머',
        url: 'https://medium.com/frontend-trends-2026',
        thumbnailUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
        platform: Platform.blog,
        labels: ['개발', '트렌드'],
        isRead: false,
        isBookmarked: true,
        memo: '팀 세미나 발표 자료로 활용하기',
      ),
      _DemoArticle(
        title: 'The Art of Deep Work: 몰입을 위한 환경 설계 가이드',
        url: 'https://youtube.com/watch?v=deep-work-guide',
        thumbnailUrl: 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=800&q=80',
        platform: Platform.youtube,
        labels: ['생산성', '자기계발'],
        isRead: false,
        isBookmarked: false,
      ),
      _DemoArticle(
        title: '미니멀 UI 디자인 원칙 — 적을수록 강해지는 인터페이스',
        url: 'https://brunch.co.kr/minimal-ui-design',
        thumbnailUrl: 'https://images.unsplash.com/photo-1545235617-9465d2a55698?w=800&q=80',
        platform: Platform.blog,
        labels: ['���자인'],
        isRead: false,
        isBookmarked: true,
        memo: '앱 리디자인 참고',
      ),
      _DemoArticle(
        title: 'GitHub Copilot을 200% 활용하는 프롬프트 작성법',
        url: 'https://github.com/copilot-prompt-engineering',
        thumbnailUrl: 'https://images.unsplash.com/photo-1618401471353-b98afee0b2eb?w=800&q=80',
        platform: Platform.github,
        labels: ['개발', '생산성'],
        isRead: false,
        isBookmarked: false,
      ),
      _DemoArticle(
        title: '매일 30분 독서 습관이 만든 변화 — 1년간의 기록',
        url: 'https://velog.io/reading-habit-one-year',
        thumbnailUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800&q=80',
        platform: Platform.blog,
        labels: ['자기계발'],
        isRead: false,
        isBookmarked: false,
      ),
      _DemoArticle(
        title: '디자인 시스템 구축기: 작은 팀이 일관된 UI를 만드는 법',
        url: 'https://medium.com/design-system-small-team',
        thumbnailUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800&q=80',
        platform: Platform.blog,
        labels: ['디자인', '개발'],
        isRead: false,
        isBookmarked: false,
      ),
      _DemoArticle(
        title: 'AI 시대의 개발자 생존 전략 — 코딩 너머의 역량',
        url: 'https://youtube.com/watch?v=ai-developer-survival',
        thumbnailUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
        platform: Platform.youtube,
        labels: ['개발', '트렌드'],
        isRead: false,
        isBookmarked: true,
      ),
      _DemoArticle(
        title: '집중력을 높이는 5가지 과학적 방법',
        url: 'https://reddit.com/r/productivity/focus-methods',
        thumbnailUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80',
        platform: Platform.reddit,
        labels: ['생산성'],
        isRead: false,
        isBookmarked: false,
      ),
      // 읽은 아티클 (라이브러리에 표시)
      _DemoArticle(
        title: 'Flutter 성능 최적화 팁 10가지',
        url: 'https://medium.com/flutter-performance-tips',
        thumbnailUrl: 'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=800&q=80',
        platform: Platform.blog,
        labels: ['개발'],
        isRead: true,
        isBookmarked: true,
        memo: '빌드 최적화 부분 다시 읽기',
      ),
      _DemoArticle(
        title: '사이드 프로젝트를 끝까지 완주하는 마인드셋',
        url: 'https://youtube.com/watch?v=side-project-mindset',
        thumbnailUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80',
        platform: Platform.youtube,
        labels: ['자기계발', '생산성'],
        isRead: true,
        isBookmarked: false,
      ),
      _DemoArticle(
        title: 'Notion으로 제텔카스텐 구축하기',
        url: 'https://blog.naver.com/zettelkasten-notion',
        thumbnailUrl: 'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=800&q=80',
        platform: Platform.naverBlog,
        labels: ['생산성'],
        isRead: true,
        isBookmarked: true,
      ),
      _DemoArticle(
        title: '2026년 주목할 디자인 컬러 팔레트',
        url: 'https://www.threads.net/design-colors-2026',
        thumbnailUrl: 'https://images.unsplash.com/photo-1525909002-1b05e0c869d8?w=800&q=80',
        platform: Platform.threads,
        labels: ['디자인', '트렌드'],
        isRead: true,
        isBookmarked: false,
      ),
    ];

    // 시간 간격을 두고 생성 (정렬 순서 보장)
    final now = DateTime.now();
    for (var i = 0; i < articles.length; i++) {
      final demo = articles[i];
      final article = Article()
        ..url = demo.url
        ..title = demo.title
        ..thumbnailUrl = demo.thumbnailUrl
        ..platform = demo.platform
        ..topicLabels = demo.labels
        ..isRead = demo.isRead
        ..isBookmarked = demo.isBookmarked
        ..memo = demo.memo
        ..createdAt = now.subtract(Duration(hours: i * 3));
      await DatabaseService.saveArticle(article);
    }

    debugPrint('✅ Demo data seeded: ${articles.length} articles, 5 labels');
  }
}

class _DemoArticle {
  final String title;
  final String url;
  final String? thumbnailUrl;
  final Platform platform;
  final List<String> labels;
  final bool isRead;
  final bool isBookmarked;
  final String? memo;

  const _DemoArticle({
    required this.title,
    required this.url,
    this.thumbnailUrl,
    required this.platform,
    required this.labels,
    required this.isRead,
    required this.isBookmarked,
    this.memo,
  });
}
