import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/main.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/widgets/article_card.dart';
import 'package:clib/widgets/label_edit_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CardSwiperController _swiperController = CardSwiperController();
  List<Article> _articles = [];
  int _cardSwiperKey = 0;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    articlesChangedNotifier.addListener(_loadArticles);
  }

  void _loadArticles() {
    if (!mounted) return;
    final oldController = _swiperController;
    _swiperController = CardSwiperController();
    setState(() {
      _articles = DatabaseService.getUnreadArticles();
      _cardSwiperKey++;
    });
    // 리빌드 완료 후 이전 컨트롤러 해제
    WidgetsBinding.instance.addPostFrameCallback((_) => oldController.dispose());
  }

  @override
  void dispose() {
    articlesChangedNotifier.removeListener(_loadArticles);
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final article = _articles[previousIndex];

    if (direction == CardSwiperDirection.right) {
      // 오른쪽 스와이프: 읽음 처리 후 목록 갱신
      HapticFeedback.mediumImpact();
      DatabaseService.markAsRead(article);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadArticles());
    } else if (direction == CardSwiperDirection.left) {
      // 왼쪽 스와이프: 나중에 (스택 아래로)
      HapticFeedback.lightImpact();
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_clear,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '스와이프할 아티클이 없습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '공유 시트에서 링크를 추가해보세요!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // 남은 아티클 수
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '${_articles.length}개의 아티클',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 카드 스택 (화면의 70%)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CardSwiper(
              key: ValueKey(_cardSwiperKey),
              controller: _swiperController,
              cardsCount: _articles.length,
              numberOfCardsDisplayed: _articles.length < 3 ? _articles.length : 3,
              backCardOffset: const Offset(0, -30),
              padding: const EdgeInsets.only(bottom: 24),
              isLoop: true,
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
              ),
              onSwipe: _onSwipe,
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                // 스와이프 방향에 따른 테두리 색상
                Color? borderColor;
                if (percentThresholdX > 20) {
                  borderColor = AppColors.neonGreen
                      .withValues(alpha: (percentThresholdX / 100).clamp(0, 1));
                } else if (percentThresholdX < -20) {
                  borderColor = AppColors.softCoral
                      .withValues(alpha: (percentThresholdX.abs() / 100).clamp(0, 1));
                }

                return GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(_articles[index].url);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  onLongPress: () async {
                    HapticFeedback.heavyImpact();
                    await LabelEditSheet.show(
                      context,
                      article: _articles[index],
                    );
                    _loadArticles();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: borderColor != null
                          ? Border.all(color: borderColor, width: 3)
                          : null,
                    ),
                    child: ArticleCard(article: _articles[index]),
                  ),
                );
              },
            ),
          ),
        ),
        // 스와이프 힌트
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 16, color: AppColors.softCoral.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                '나중에',
                style: TextStyle(fontSize: 12, color: AppColors.softCoral.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 32),
              Text(
                '읽음',
                style: TextStyle(fontSize: 12, color: AppColors.neonGreen.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16, color: AppColors.neonGreen.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ],
    );
  }
}
