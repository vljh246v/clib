import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  /// true이면 설정 > 사용 방법에서 진입 (완료 시 pop)
  final bool isGuideMode;

  const OnboardingScreen({super.key, this.isGuideMode = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    } else {
      _onComplete();
    }
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    _onComplete();
  }

  Future<void> _onComplete() async {
    if (!widget.isGuideMode) {
      await DatabaseService.setOnboardingComplete();
    }
    if (mounted) {
      if (widget.isGuideMode) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    final pages = [
      _PageData(
        icon: Icons.link_rounded,
        title: l.onboardingSaveTitle,
        subtitle: l.onboardingSaveSubtitle,
        hint: l.onboardingSaveHint,
      ),
      _PageData(
        icon: Icons.swipe_rounded,
        title: l.onboardingSwipeTitle,
        subtitle: l.onboardingSwipeSubtitle,
        hint: l.onboardingSwipeHint,
      ),
      _PageData(
        icon: Icons.auto_awesome_rounded,
        title: l.onboardingLibraryTitle,
        subtitle: l.onboardingLibrarySubtitle,
        hint: l.onboardingLibraryHint,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 스킵 버튼
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Spacing.md,
                  right: Spacing.lg,
                ),
                child: _currentPage < pages.length - 1
                    ? GestureDetector(
                        onTap: _onSkip,
                        child: Text(
                          l.skip,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : const SizedBox(height: 20),
              ),
            ),

            // 페이지 콘텐츠
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _OnboardingPage(page: page, isDark: isDark);
                },
              ),
            ),

            // 인디케이터 + 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xxl,
                Spacing.lg,
                Spacing.xxl,
                Spacing.xxxl,
              ),
              child: Column(
                children: [
                  // 도트 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.symmetric(
                          horizontal: Spacing.xs,
                        ),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.25),
                          borderRadius: Radii.borderFull,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: Spacing.xxl),

                  // 다음/시작 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: Radii.borderMd,
                        ),
                      ),
                      child: Text(
                        _currentPage < pages.length - 1
                            ? l.next
                            : widget.isGuideMode
                                ? l.confirm
                                : l.start,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 페이지 데이터 ───

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;

  const _PageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
  });
}

// ─── 개별 페이지 위젯 ───

class _OnboardingPage extends StatelessWidget {
  final _PageData page;
  final bool isDark;

  const _OnboardingPage({required this.page, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 원형 배경
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            ),
            child: Icon(
              page.icon,
              size: 52,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: Spacing.xxxl),

          // 타이틀
          Text(
            page.title,
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.md),

          // 서브타이틀
          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xxl),

          // 힌트 칩
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: Radii.borderFull,
            ),
            child: Text(
              page.hint,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
