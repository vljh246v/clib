import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/design_tokens.dart';

/// 홈 화면 위에 표시되는 단계별 오버레이 가이드.
///
/// [targetKeys]로 하이라이트할 위젯의 GlobalKey를 전달받고,
/// 각 단계에서 해당 영역을 스포트라이트로 강조한다.
class HomeOverlayGuide extends StatefulWidget {
  /// 순서: 카드 영역, + 버튼, 보관함 탭, 설정 탭
  final List<GlobalKey> targetKeys;
  final VoidCallback onComplete;

  const HomeOverlayGuide({
    super.key,
    required this.targetKeys,
    required this.onComplete,
  });

  @override
  State<HomeOverlayGuide> createState() => _HomeOverlayGuideState();
}

class _HomeOverlayGuideState extends State<HomeOverlayGuide>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isAnimating = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // step 0 spotlight bottom을 GuideCard top에 맞추기 위한 key
  final GlobalKey _guideCardKey = GlobalKey();

  static const _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    // 레이아웃 완료 후 fade-in (설정에서 진입 시 타겟 위젯이 아직 빌드 안 됐을 수 있음)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {}); // targetRect 재계산
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isAnimating) return;
    _isAnimating = true;
    HapticFeedback.lightImpact();

    if (_currentStep < _totalSteps - 1) {
      _animController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _currentStep++);
        _animController.forward().then((_) {
          _isAnimating = false;
        });
      });
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await DatabaseService.setHomeGuideComplete();
    await _animController.reverse();
    if (mounted) widget.onComplete();
  }

  Rect? _getTargetRect() {
    if (_currentStep >= widget.targetKeys.length) return null;

    // step 0: 카드 트래킹 포기. "+" row 아래 ~ 메뉴바 위까지 화면 전체 너비 고정 사각형.
    // Column 상단 간격: md(12) + filter row(36) + SizedBox(10) + count row(≈28) + sm(8) ≈ 94
    // 하단 nav 영역: SafeArea bottom + margin(16) + padding(8) + icon(≈24) + padding(8) ≈ bottomSafe + 56
    if (_currentStep == 0) {
      final mq = MediaQuery.of(context);
      final size = mq.size;
      final topInset = mq.padding.top + 94;
      final bottomInset = mq.padding.bottom + 56;
      return Rect.fromLTWH(
        0,
        topInset,
        size.width,
        size.height - topInset - bottomInset,
      );
    }

    final key = widget.targetKeys[_currentStep];
    final renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final steps = [
      _StepData(
        icon: Icons.swipe_rounded,
        title: l.guideSwipeTitle,
        desc: l.guideSwipeDesc,
      ),
      _StepData(
        icon: Icons.add_rounded,
        title: l.guideAddTitle,
        desc: l.guideAddDesc,
      ),
      _StepData(
        icon: Icons.grid_view_rounded,
        title: l.guideLibraryTitle,
        desc: l.guideLibraryDesc,
      ),
      _StepData(
        icon: Icons.settings_rounded,
        title: l.guideSettingsTitle,
        desc: l.guideSettingsDesc,
      ),
    ];

    final step = steps[_currentStep];
    final targetRect = _getTargetRect();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 반투명 배경 + 스포트라이트 컷아웃
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  overlayColor: Colors.black.withValues(alpha: 0.6),
                  // 카드 step은 카드 경계와 정확히 일치시키기 위해 inflate 제거
                  inflate: _currentStep == 0 ? 0 : 8,
                ),
              ),
            ),

            // 설명 카드 — step 0은 하단 고정(spotlight 아래), 나머지는 화면 중앙
            if (_currentStep == 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.xxl, 0, Spacing.xxl, Spacing.xl,
                    ),
                    child: _GuideCard(
                      key: _guideCardKey,
                      step: step,
                      currentStep: _currentStep,
                      totalSteps: _totalSteps,
                      tapHint: l.guideTapToContinue,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
                  child: _GuideCard(
                    step: step,
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    tapHint: l.guideTapToContinue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 데이터 ───

class _StepData {
  final IconData icon;
  final String title;
  final String desc;

  const _StepData({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

// ─── 스포트라이트 페인터 ───

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;
  final double inflate;

  _SpotlightPainter({
    this.targetRect,
    required this.overlayColor,
    this.inflate = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // 전체 어두운 오버레이
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);

    if (targetRect != null) {
      final padded =
          inflate > 0 ? targetRect!.inflate(inflate) : targetRect!;
      final clearPaint = Paint()..blendMode = BlendMode.clear;
      if (inflate > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(padded, const Radius.circular(Radii.xl)),
          clearPaint,
        );
      } else {
        canvas.drawRect(padded, clearPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      inflate != oldDelegate.inflate;
}

// ─── 설명 카드 ───

class _GuideCard extends StatelessWidget {
  final _StepData step;
  final int currentStep;
  final int totalSteps;
  final String tapHint;

  const _GuideCard({
    super.key,
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.tapHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(Spacing.xxl),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: Radii.borderXl,
        border: isDark
            ? Border.all(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            ),
            child: Icon(
              step.icon,
              size: 32,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // 타이틀
          Text(
            step.title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),

          // 설명
          Text(
            step.desc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xxl),

          // 도트 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (i) {
              final isActive = i == currentStep;
              return AnimatedContainer(
                duration: AppDurations.fast,
                margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
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
          const SizedBox(height: Spacing.lg),

          // 탭 힌트
          Text(
            tapHint,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
