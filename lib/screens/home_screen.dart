import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/main.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/widgets/article_card.dart';
import 'package:clib/widgets/label_edit_sheet.dart';
import 'package:clib/widgets/add_article_sheet.dart';
import 'package:clib/widgets/swipe_ad_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CardSwiperController _swiperController = CardSwiperController();
  final List<CardSwiperController> _pendingDispose = [];
  List<Article> _articles = [];
  List<String> _allLabels = [];
  final Set<String> _selectedLabels = {};
  int _cardSwiperKey = 0;
  bool _isExpanded = false;

  static const _adInterval = 8;

  /// 광고 슬롯을 포함한 전체 카드 수
  int get _totalCards {
    if (_articles.isEmpty) return 0;
    final adCount = _articles.length >= _adInterval
        ? (_articles.length / _adInterval).floor()
        : 0;
    return _articles.length + adCount;
  }

  /// 해당 인덱스가 광고 슬롯인지 판단
  bool _isAdSlot(int index) {
    if (_articles.length < _adInterval) return false;
    return index > 0 && (index + 1) % (_adInterval + 1) == 0;
  }

  /// 광고 슬롯을 제외한 실제 아티클 인덱스
  int _articleIndex(int index) {
    if (_articles.length < _adInterval) return index;
    return index - ((index + 1) ~/ (_adInterval + 1));
  }

  @override
  void initState() {
    super.initState();
    _loadArticles();
    articlesChangedNotifier.addListener(_loadArticles);
  }

  void _loadArticles() {
    if (!mounted) return;
    final oldController = _swiperController;
    _pendingDispose.add(oldController);
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
      _disposePendingControllers();
    });
  }

  void _disposePendingControllers() {
    for (final controller in _pendingDispose) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    _pendingDispose.clear();
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
    _disposePendingControllers();
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // 광고 카드는 스와이프만 허용, 아티클 처리 안함
    if (_isAdSlot(previousIndex)) return true;

    final artIdx = _articleIndex(previousIndex);
    if (artIdx >= _articles.length) return false;
    final article = _articles[artIdx];

    if (direction == CardSwiperDirection.right) {
      HapticFeedback.mediumImpact();
      DatabaseService.markAsRead(article);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadArticles());
    } else if (direction == CardSwiperDirection.left) {
      HapticFeedback.lightImpact();
      if (currentIndex == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadArticles());
      }
    }

    return true;
  }

  void _showCardActions(Article article) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ListTile(
              leading: Icon(
                article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              title: Text(article.isBookmarked ? l.removeBookmark : l.bookmark),
              onTap: () async {
                Navigator.pop(ctx);
                await DatabaseService.toggleBookmark(article);
                _loadArticles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(article.memo != null ? l.editMemo : l.addMemo),
              subtitle: article.memo != null
                  ? Text(article.memo!, maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _showMemoDialog(article);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(l.editLabelAction),
              onTap: () async {
                Navigator.pop(ctx);
                await LabelEditSheet.show(context, article: article);
                _loadArticles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l.openInBrowser),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.tryParse(article.url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMemoDialog(Article article) {
    final controller = TextEditingController(text: article.memo);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Spacing.md),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(l.memo, style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
                child: TextField(
                  controller: controller,
                  maxLength: 100,
                  maxLines: 1,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l.memoHint,
                    counterText: '',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: Radii.borderMd,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.xxl, 0, Spacing.xxl, Spacing.lg),
                child: Row(
                  children: [
                    if (article.memo != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
                          ),
                          onPressed: () async {
                            await DatabaseService.updateMemo(article, null);
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadArticles();
                          },
                          child: Text(l.delete),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
                        ),
                        onPressed: () async {
                          await DatabaseService.updateMemo(article, controller.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadArticles();
                        },
                        child: Text(l.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.06),
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 56,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                l.noArticlesToSwipe,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                _selectedLabels.isEmpty
                    ? l.addLinksHint
                    : l.noUnreadInLabel,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final labelCountText = _selectedLabels.isEmpty
        ? l.articleCountText(_articles.length)
        : l.labelArticleCountText(_selectedLabels.join(', '), _articles.length);

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
                            label: l.all,
                            selected: _selectedLabels.isEmpty,
                            onTap: _clearLabels,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 20,
                            color: Theme.of(context).dividerColor,
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
                      behavior: HitTestBehavior.opaque,
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
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: SingleChildScrollView(
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
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        const SizedBox(height: 10),
        // 아티클 카운트 + 추가 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                labelCountText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => AddArticleSheet.show(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_articles.isEmpty) _buildEmptyState(),
        // 카드 스택
        if (_articles.isNotEmpty) Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CardSwiper(
                  key: ValueKey(_cardSwiperKey),
                  controller: _swiperController,
                  cardsCount: _totalCards,
                  numberOfCardsDisplayed: _totalCards < 3 ? _totalCards : 3,
                  backCardOffset: const Offset(0, 36),
                  scale: 0.95,
                  padding: const EdgeInsets.only(bottom: 56),
                  isLoop: _totalCards > 1,
                  allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                    horizontal: true,
                  ),
                  onSwipe: _onSwipe,
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    if (index >= _totalCards) return const SizedBox.shrink();

                    // 광고 슬롯
                    if (_isAdSlot(index)) {
                      return const SwipeAdCard();
                    }

                    final artIdx = _articleIndex(index);
                    if (artIdx >= _articles.length) return const SizedBox.shrink();

                    // 스와이프 방향에 따른 테두리 색상
                    Color? borderColor;
                    if (percentThresholdX > 20) {
                      borderColor = AppColors.swipeRead
                          .withValues(alpha: (percentThresholdX / 100).clamp(0, 1));
                    } else if (percentThresholdX < -20) {
                      borderColor = AppColors.swipeSkip
                          .withValues(alpha: (percentThresholdX.abs() / 100).clamp(0, 1));
                    }

                    // 스와이프 힌트 opacity (20% 이상 드래그 시 페이드인)
                    final readOpacity = percentThresholdX > 20
                        ? ((percentThresholdX - 20) / 40).clamp(0.0, 1.0)
                        : 0.0;
                    final laterOpacity = percentThresholdX < -20
                        ? ((percentThresholdX.abs() - 20) / 40).clamp(0.0, 1.0)
                        : 0.0;

                    return GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(_articles[artIdx].url);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        _showCardActions(_articles[artIdx]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: borderColor != null
                              ? Border.all(color: borderColor, width: 2.5)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            ArticleCard(article: _articles[artIdx]),
                            // 오른쪽 스와이프: "읽음" 스탬프
                            if (readOpacity > 0)
                              Positioned(
                                top: 24,
                                left: 20,
                                child: Opacity(
                                  opacity: readOpacity,
                                  child: _SwipeStamp(
                                    text: l.swipeRead,
                                    icon: Icons.check_rounded,
                                    color: AppColors.swipeRead,
                                  ),
                                ),
                              ),
                            // 왼쪽 스와이프: "나중에" 스탬프
                            if (laterOpacity > 0)
                              Positioned(
                                top: 24,
                                right: 20,
                                child: Opacity(
                                  opacity: laterOpacity,
                                  child: _SwipeStamp(
                                    text: l.swipeLater,
                                    icon: Icons.schedule_rounded,
                                    color: AppColors.swipeSkip,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: Radii.borderFull,
          border: Border.all(
            color: selected
                ? accent
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? accent
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SwipeStamp({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: Radii.borderMd,
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
