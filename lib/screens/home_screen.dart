import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clib/blocs/home/home_bloc.dart';
import 'package:clib/blocs/home/home_event.dart';
import 'package:clib/blocs/home/home_state.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/ad_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';
import 'package:clib/utils/url_safety.dart';
import 'package:clib/widgets/add_article_sheet.dart';
import 'package:clib/widgets/article_card.dart';
import 'package:clib/widgets/label_edit_sheet.dart';
import 'package:clib/widgets/swipe_ad_card.dart';

class HomeScreen extends StatelessWidget {
  /// MainScreen에서 오버레이 가이드에 사용할 GlobalKey
  final GlobalKey? cardAreaKey;
  final GlobalKey? addButtonKey;

  const HomeScreen({super.key, this.cardAreaKey, this.addButtonKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(),
      child: _HomeBody(
        cardAreaKey: cardAreaKey,
        addButtonKey: addButtonKey,
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  final GlobalKey? cardAreaKey;
  final GlobalKey? addButtonKey;

  const _HomeBody({this.cardAreaKey, this.addButtonKey});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  CardSwiperController _swiperController = CardSwiperController();
  final List<CardSwiperController> _pendingDispose = [];
  final ValueNotifier<double> _thresholdNotifier = ValueNotifier<double>(0.0);
  int _currentDeckVersion = 0;

  static const _adInterval = AdService.adInterval;

  @override
  void dispose() {
    _disposePendingControllers();
    try {
      _swiperController.dispose();
    } catch (_) {}
    _thresholdNotifier.dispose();
    super.dispose();
  }

  void _disposePendingControllers() {
    for (final c in _pendingDispose) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _pendingDispose.clear();
  }

  /// Bloc의 [HomeState.deckVersion] 변경에 맞춰 CardSwiperController를 교체.
  /// 이전 컨트롤러는 프레임 이후 일괄 dispose(이중 dispose 방지 try-catch).
  void _syncControllerWithDeckVersion(int newVersion) {
    if (_currentDeckVersion == newVersion) return;
    _currentDeckVersion = newVersion;
    _pendingDispose.add(_swiperController);
    _swiperController = CardSwiperController();
    _thresholdNotifier.value = 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposePendingControllers();
    });
  }

  int _totalCards(int articleCount) {
    if (articleCount == 0) return 0;
    final adCount =
        articleCount >= _adInterval ? (articleCount / _adInterval).floor() : 0;
    return articleCount + adCount;
  }

  bool _isAdSlot(int index, int articleCount) {
    if (articleCount < _adInterval) return false;
    return index > 0 && (index + 1) % (_adInterval + 1) == 0;
  }

  int _articleIndex(int index, int articleCount) {
    if (articleCount < _adInterval) return index;
    return index - ((index + 1) ~/ (_adInterval + 1));
  }

  void _toggleLabel(String label) {
    final current = context.read<HomeBloc>().state.selectedLabelNames;
    final next = Set<String>.from(current);
    if (!next.add(label)) next.remove(label);
    context.read<HomeBloc>().add(HomeFilterLabelsChanged(next));
  }

  void _clearLabels() {
    context.read<HomeBloc>().add(const HomeFilterLabelsChanged({}));
  }

  void _showCardActions(Article article) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<HomeBloc>();
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
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ListTile(
              leading: Icon(
                article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              title:
                  Text(article.isBookmarked ? l.removeBookmark : l.bookmark),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(HomeToggleBookmark(article));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(article.memo != null ? l.editMemo : l.addMemo),
              subtitle: article.memo != null
                  ? Text(article.memo!,
                      maxLines: 1, overflow: TextOverflow.ellipsis)
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
                // 시트가 내부적으로 persist → 덱 재로드만 요청.
                if (!bloc.isClosed) {
                  bloc.add(const HomeLoadDeck(resetPosition: false));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l.openInBrowser),
              onTap: () async {
                Navigator.pop(ctx);
                // M-4: http/https 스킴만 허용 (legacy 또는 변조된 DB 방어)
                final uri = parseAllowedUrl(article.url);
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final bloc = context.read<HomeBloc>();
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
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(l.memo, style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.xxl),
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
                padding: const EdgeInsets.fromLTRB(
                    Spacing.xxl, 0, Spacing.xxl, Spacing.lg),
                child: Row(
                  children: [
                    if (article.memo != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: Radii.borderMd),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            bloc.add(HomeUpdateMemo(article, null));
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
                          shape: RoundedRectangleBorder(
                              borderRadius: Radii.borderMd),
                        ),
                        onPressed: () {
                          final text = controller.text;
                          Navigator.pop(ctx);
                          bloc.add(HomeUpdateMemo(article, text));
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
    ).whenComplete(controller.dispose);
  }

  Widget _buildEmptyContent(Set<String> selectedLabels) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Center(
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
                color:
                    theme.colorScheme.secondary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              l.noArticlesToSwipe,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              selectedLabels.isEmpty ? l.addLinksHint : l.noUnreadInLabel,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (p, c) => p.deckVersion != c.deckVersion,
      listener: (context, state) {
        _syncControllerWithDeckVersion(state.deckVersion);
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLabelNames =
            state.allLabels.map((label) => label.name).toList();
        final selectedLabels = state.selectedLabelNames;
        final labelCountText = selectedLabels.isEmpty
            ? l.articleCountText(state.articles.length)
            : l.labelArticleCountText(
                selectedLabels.join(', '),
                state.articles.length,
              );
        final totalCards = _totalCards(state.articles.length);

        return Column(
          children: [
            const SizedBox(height: Spacing.md),
            if (allLabelNames.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: Spacing.lg),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FilterChip(
                                label: l.all,
                                selected: selectedLabels.isEmpty,
                                onTap: _clearLabels,
                              ),
                              const SizedBox(width: Spacing.sm),
                              Container(
                                width: 1,
                                height: Spacing.xl,
                                color: Theme.of(context).dividerColor,
                              ),
                              const SizedBox(width: Spacing.sm),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allLabelNames.length,
                            itemBuilder: (context, index) => Padding(
                              padding: EdgeInsets.only(
                                right: index < allLabelNames.length - 1
                                    ? Spacing.sm
                                    : 0,
                              ),
                              child: _FilterChip(
                                label: allLabelNames[index],
                                selected: selectedLabels
                                    .contains(allLabelNames[index]),
                                onTap: () =>
                                    _toggleLabel(allLabelNames[index]),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context
                              .read<HomeBloc>()
                              .add(const HomeToggleExpand()),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: Spacing.md, right: Spacing.lg),
                            child: AnimatedRotation(
                              turns: state.isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: state.isExpanded
                        ? ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxHeight: 160),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                  Spacing.lg,
                                  Spacing.sm,
                                  Spacing.lg,
                                  Spacing.xs),
                              child: Wrap(
                                spacing: Spacing.sm,
                                runSpacing: Spacing.sm,
                                children: [
                                  for (final name in allLabelNames)
                                    _FilterChip(
                                      label: name,
                                      selected:
                                          selectedLabels.contains(name),
                                      onTap: () => _toggleLabel(name),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: Row(
                children: [
                  Text(
                    labelCountText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  GestureDetector(
                    key: widget.addButtonKey,
                    onTap: () => AddArticleSheet.show(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            if (state.articles.isEmpty)
              Expanded(
                child: Container(
                  key: widget.cardAreaKey,
                  child: _buildEmptyContent(selectedLabels),
                ),
              ),
            if (state.articles.isNotEmpty)
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: CardSwiper(
                        key: ValueKey(state.deckVersion),
                        controller: _swiperController,
                        cardsCount: totalCards,
                        numberOfCardsDisplayed:
                            totalCards < 3 ? totalCards : 3,
                        backCardOffset: const Offset(0, 36),
                        scale: 0.95,
                        padding: const EdgeInsets.only(bottom: 56),
                        isLoop: totalCards > 1,
                        allowedSwipeDirection:
                            const AllowedSwipeDirection.symmetric(
                          horizontal: true,
                        ),
                        onSwipe: (previousIndex, currentIndex, direction) {
                          return _onSwipe(
                            previousIndex: previousIndex,
                            currentIndex: currentIndex,
                            direction: direction,
                            articles: state.articles,
                          );
                        },
                        cardBuilder: (context, index, pctX, pctY) {
                          if (index >= totalCards) {
                            return const SizedBox.shrink();
                          }
                          if (_isAdSlot(index, state.articles.length)) {
                            return const SwipeAdCard();
                          }
                          final artIdx =
                              _articleIndex(index, state.articles.length);
                          if (artIdx >= state.articles.length) {
                            return const SizedBox.shrink();
                          }

                          final onVariant = Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant;
                          Color? borderColor;
                          if (pctX > 20) {
                            borderColor = AppColors.swipeRead.withValues(
                                alpha: (pctX / 100).clamp(0, 1));
                          } else if (pctX < -20) {
                            borderColor = onVariant.withValues(
                                alpha: (pctX.abs() / 100).clamp(0, 1));
                          }

                          WidgetsBinding.instance
                              .addPostFrameCallback((_) {
                            if (mounted) {
                              _thresholdNotifier.value = pctX.toDouble();
                            }
                          });

                          final article = state.articles[artIdx];
                          return GestureDetector(
                            onTap: () async {
                              // M-4: http/https 스킴만 허용 (legacy 또는 변조된 DB 방어)
                              final uri = parseAllowedUrl(article.url);
                              if (uri == null) return;
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            },
                            onLongPress: () {
                              HapticFeedback.heavyImpact();
                              _showCardActions(article);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: Radii.borderXl,
                                border: borderColor != null
                                    ? Border.all(
                                        color: borderColor, width: 2.5)
                                    : null,
                              ),
                              child: ArticleCard(article: article),
                            ),
                          );
                        },
                      ),
                    ),
                    if (widget.cardAreaKey != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            key: widget.cardAreaKey,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 12,
                      child: IgnorePointer(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _thresholdNotifier,
                          builder: (context, threshold, _) {
                            const base = 0.3;
                            final laterOpacity = threshold < -20
                                ? (base +
                                        (1 - base) *
                                            ((threshold.abs() - 20) / 40))
                                    .clamp(base, 1.0)
                                : base;
                            final readOpacity = threshold > 20
                                ? (base +
                                        (1 - base) *
                                            ((threshold - 20) / 40))
                                    .clamp(base, 1.0)
                                : base;
                            final theme = Theme.of(context);

                            return Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Opacity(
                                  opacity: laterOpacity,
                                  child: _SwipeHint(
                                    text: l.swipeLater,
                                    icon: Icons.schedule_rounded,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Opacity(
                                  opacity: readOpacity,
                                  child: _SwipeHint(
                                    text: l.swipeRead,
                                    icon: Icons.check_rounded,
                                    color: AppColors.swipeRead,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  bool _onSwipe({
    required int previousIndex,
    required int? currentIndex,
    required CardSwiperDirection direction,
    required List<Article> articles,
  }) {
    if (_isAdSlot(previousIndex, articles.length)) return true;

    final artIdx = _articleIndex(previousIndex, articles.length);
    if (artIdx >= articles.length) return false;
    final article = articles[artIdx];

    if (direction == CardSwiperDirection.right) {
      HapticFeedback.mediumImpact();
      context.read<HomeBloc>().add(HomeSwipeRead(article));
    } else if (direction == CardSwiperDirection.left) {
      HapticFeedback.lightImpact();
      context.read<HomeBloc>().add(
            HomeSwipeLater(article, reachedEnd: currentIndex == null),
          );
    }
    return true;
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
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
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
            color: selected ? accent : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SwipeHint({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
