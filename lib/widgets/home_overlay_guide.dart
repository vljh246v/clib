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
                ),
              ),
            ),

            // 설명 카드 — 화면 중앙에 고정
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

  _SpotlightPainter({this.targetRect, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // 전체 어두운 오버레이
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);

    if (targetRect != null) {
      // 패딩 추가
      final padded = targetRect!.inflate(8);
      final clearPaint = Paint()..blendMode = BlendMode.clear;
      canvas.drawRRect(
        RRect.fromRectAndRadius(padded, const Radius.circular(Radii.lg)),
        clearPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect;
}

// ─── 설명 카드 ───

class _GuideCard extends StatelessWidget {
  final _StepData step;
  final int currentStep;
  final int totalSteps;
  final String tapHint;

  const _GuideCard({
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
