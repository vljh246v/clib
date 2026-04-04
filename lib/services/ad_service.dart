import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static BannerAd? _bannerAd;
  static bool _isLoaded = false;

  static String get _bannerAdUnitId {
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

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd? get bannerAd => _isLoaded ? _bannerAd : null;

  static void loadBannerAd({required Function onLoaded}) {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
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
