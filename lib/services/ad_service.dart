import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:clib/utils/app_logger.dart';

class AdService {
  /// 아티클 리스트 / 홈 덱에서 N개마다 광고를 1개 삽입한다.
  /// 변경 시 [HomeBloc] 덱 카운트와 [ArticleListView] 모두 영향.
  static const int adInterval = 8;

  static BannerAd? _bannerAd;
  static bool _isLoaded = false;

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // 디버그 빌드: Google 테스트 광고 ID 사용 (계정 보호)
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-9364520099576698/3623099162'
        : 'ca-app-pub-9364520099576698/8220819728';
  }

  /// 인피드 네이티브 광고 단위 ID
  static String get nativeAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-9364520099576698/8758004217'
        : 'ca-app-pub-9364520099576698/9855463463';
  }

  static Future<void> initialize() async {
    final status = await MobileAds.instance.initialize();
    log('✅ AdMob SDK initialized');
    status.adapterStatuses.forEach((adapter, status) {
      log('  Adapter: $adapter → ${status.state}');
    });
  }

  static BannerAd? get bannerAd => _isLoaded ? _bannerAd : null;

  static void loadBannerAd({required Function onLoaded}) {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          _isLoaded = false;
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd!.load();
  }

  static void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }
}
