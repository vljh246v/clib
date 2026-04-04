import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:clib/services/ad_service.dart';
import 'package:clib/theme/design_tokens.dart';

/// 리스트 사이에 삽입되는 인피드 네이티브 광고 위젯.
/// TemplateType.small로 앱 디자인에 자연스럽게 녹아든다.
class InlineNativeAd extends StatefulWidget {
  const InlineNativeAd({super.key});

  @override
  State<InlineNativeAd> createState() => _InlineNativeAdState();
}

class _InlineNativeAdState extends State<InlineNativeAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
        },
      ),
      nativeTemplateStyle: _buildTemplateStyle(),
    )..load();
  }

  NativeTemplateStyle _buildTemplateStyle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: theme.colorScheme.surface,
      cornerRadius: Radii.lg,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: theme.colorScheme.onSecondary,
        backgroundColor: theme.colorScheme.secondary,
        style: NativeTemplateFontStyle.bold,
        size: 12.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: theme.colorScheme.onSurface,
        style: NativeTemplateFontStyle.bold,
        size: 13.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: isDark
            ? const Color(0xFF8E8E93)
            : const Color(0xFF8E8E93),
        style: NativeTemplateFontStyle.normal,
        size: 11.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: isDark
            ? const Color(0xFF8E8E93)
            : const Color(0xFF8E8E93),
        style: NativeTemplateFontStyle.normal,
        size: 11.0,
      ),
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Radii.borderLg,
        boxShadow: AppShadows.card(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          minHeight: 90,
          maxHeight: 200,
        ),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
