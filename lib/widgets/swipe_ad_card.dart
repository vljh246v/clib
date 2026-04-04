import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:clib/services/ad_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';

/// 스와이프 덱에 삽입되는 네이티브 광고 카드.
/// ArticleCard와 동일한 외형(둥근 모서리, 그림자, 풀사이즈)을 가진다.
class SwipeAdCard extends StatefulWidget {
  const SwipeAdCard({super.key});

  @override
  State<SwipeAdCard> createState() => _SwipeAdCardState();
}

class _SwipeAdCardState extends State<SwipeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _adRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adRequested) {
      _adRequested = true;
      _loadAd();
    }
  }

  void _loadAd() {
    final theme = Theme.of(context);

    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Swipe native ad loaded');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Swipe native ad failed: ${error.message}');
          ad.dispose();
          _nativeAd = null;
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: theme.colorScheme.surface,
        cornerRadius: Radii.xl,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: theme.colorScheme.onSecondary,
          backgroundColor: theme.colorScheme.secondary,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.colorScheme.onSurface,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF8E8E93),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF8E8E93),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: Radii.borderXl,
        boxShadow: AppShadows.swipeCard(isDark),
        color: theme.colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoaded && _nativeAd != null
          ? AdWidget(ad: _nativeAd!)
          : _placeholder(theme),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warmCharcoal, Color(0xFF3D3D4A)],
        ),
      ),
    );
  }
}
