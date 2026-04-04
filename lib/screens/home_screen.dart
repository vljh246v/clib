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
  List<String> _allLabels = [];
  final Set<String> _selectedLabels = {};
  int _cardSwiperKey = 0;
  bool _isExpanded = false;

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
    final allUnread = DatabaseService.getUnreadArticles();
    final filtered = _selectedLabels.isEmpty
        ? allUnread
        : allUnread
            .where((a) => _selectedLabels.every((l) => a.topicLabels.contains(l)))
            .toList();
    setState(() {
      _allLabels = DatabaseService.getAllLabelObjects().map((l) => l.name).toList();
      _articles = filtered;
      _cardSwiperKey++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), oldController.dispose);
    });
  }

  void _toggleLabel(String label) {
    if (_selectedLabels.contains(label)) {
      _selectedLabels.remove(label);
    } else {
      _selectedLabels.add(label);
    }
    _loadArticles();
  }

  void _clearLabels() {
    _selectedLabels.clear();
    _loadArticles();
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
    if (previousIndex >= _articles.length) return false;
    final article = _articles[previousIndex];

    if (direction == CardSwiperDirection.right) {
      // 오른쪽 스와이프: 읽음 처리 후 목록 갱신
      HapticFeedback.mediumImpact();
      DatabaseService.markAsRead(article);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadArticles());
    } else if (direction == CardSwiperDirection.left) {
      // 왼쪽 스와이프: 나중에 (스택 아래로)
      HapticFeedback.lightImpact();
      // 마지막 카드를 스와이프한 경우(currentIndex == null) 스와이퍼 리셋
      if (currentIndex == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadArticles());
      }
    }

    return true;
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
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
                _selectedLabels.isEmpty
                    ? '공유 시트에서 링크를 추가해보세요!'
                    : '선택한 라벨에 읽지 않은 아티클이 없어요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final labelCountText = _selectedLabels.isEmpty
        ? '${_articles.length}개의 아티클'
        : '${_selectedLabels.join(', ')} · ${_articles.length}개의 아티클';

    return Column(
      children: [
        const SizedBox(height: 12),
        // 라벨 필터 바
        if (_allLabels.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    // 고정: 전체 칩 + 구분선
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FilterChip(
                            label: '전체',
                            selected: _selectedLabels.isEmpty,
                            onTap: _clearLabels,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    // 스크롤 가능한 라벨 목록
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allLabels.length,
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(
                            right: index < _allLabels.length - 1 ? 8 : 0,
                          ),
                          child: _FilterChip(
                            label: _allLabels[index],
                            selected: _selectedLabels.contains(_allLabels[index]),
                            onTap: () => _toggleLabel(_allLabels[index]),
                          ),
                        ),
                      ),
                    ),
                    // 확장 버튼
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 16),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: Colors.grey.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 확장된 라벨 그리드
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in _allLabels)
                              _FilterChip(
                                label: label,
                                selected: _selectedLabels.contains(label),
                                onTap: () => _toggleLabel(label),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        const SizedBox(height: 10),
        // 아티클 카운트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                labelCountText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_articles.isEmpty) _buildEmptyState(),
        // 카드 스택 (화면의 70%)
        if (_articles.isNotEmpty) Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CardSwiper(
              key: ValueKey(_cardSwiperKey),
              controller: _swiperController,
              cardsCount: _articles.length,
              numberOfCardsDisplayed: _articles.length < 3 ? _articles.length : 3,
              backCardOffset: const Offset(0, -30),
              padding: const EdgeInsets.only(bottom: 24),
              isLoop: _articles.length > 1,
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
              ),
              onSwipe: _onSwipe,
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                if (index >= _articles.length) return const SizedBox.shrink();
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
        if (_articles.isNotEmpty) Padding(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : Colors.grey.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? colorScheme.onPrimary : Colors.grey.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
