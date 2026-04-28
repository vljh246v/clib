import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/scraping_service.dart';

class ShareService {
  static const _channel = MethodChannel('com.jaehyun.clibapp/share');

  /// 테스트 전용 심(Seam): null이면 프로덕션 경로(processAndSave)를 사용한다.
  /// 테스트에서 Hive/네트워크 없이 호출 여부·인자를 검증하기 위해 사용한다.
  @visibleForTesting
  static Future<Article?> Function(String url, {List<String> labels})?
      processAndSaveOverride;

  /// Android: intent에서 공유된 텍스트 수신
  static Future<String?> getSharedTextFromIntent() async {
    try {
      final result = await _channel.invokeMethod<String>('getSharedText');
      return result;
    } on PlatformException {
      return null;
    }
  }

  /// iOS: App Group UserDefaults에서 공유된 URL 가져오기
  static Future<List<String>> getSharedURLsFromAppGroup() async {
    try {
      final result = await _channel.invokeMethod<List>('getSharedURLs');
      return result?.cast<String>() ?? [];
    } on PlatformException {
      return [];
    }
  }

  /// iOS: 처리 완료 후 UserDefaults 비우기
  static Future<void> clearSharedURLs() async {
    try {
      await _channel.invokeMethod('clearSharedURLs');
    } on PlatformException {
      // 무시
    }
  }

  /// 공유된 텍스트에서 URL 추출
  static String? extractURL(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  /// URL을 스크래핑하여 Article로 저장
  static Future<Article?> processAndSave(
    String url, {
    List<String> labels = const [],
  }) async {
    final ogData = await ScrapingService.scrape(url);

    final article = Article()
      ..url = url
      ..title = ogData.title
      ..thumbnailUrl = ogData.imageUrl
      ..platform = classifyPlatform(url)
      ..topicLabels = List<String>.from(labels)
      ..isRead = false
      ..createdAt = DateTime.now();

    await DatabaseService.saveArticle(article);
    return article;
  }

  /// 안드로이드: 공유된 URL만 반환 (저장하지 않음)
  static Future<String?> getPendingShareURL() async {
    if (!io.Platform.isAndroid) return null;
    final text = await getSharedTextFromIntent();
    if (text == null) return null;
    return extractURL(text);
  }

  /// iOS 공유 아이템 1건을 처리한다.
  ///
  /// JSON 형식(`{"url":"...","labels":[...],"newLabels":[...]}`)과
  /// 구버전 plain URL 문자열 양쪽을 처리한다.
  ///
  /// 모든 분기에서 [extractURL] 로 URL 유효성을 검증한 뒤에만 저장하며,
  /// 유효하지 않으면 null을 반환하고 저장을 건너뛴다.
  ///
  /// @visibleForTesting — 루프 로직과 MethodChannel 의존을 분리해 단위 테스트 가능.
  @visibleForTesting
  static Future<Article?> processSharedItem(String item) async {
    try {
      // JSON 형식 파싱 시도
      final map = jsonDecode(item) as Map<String, dynamic>;
      final rawUrl = map['url'] as String;

      // URL 필드 유효성 검증 — 비-URL이면 저장하지 않고 반환
      final extracted = extractURL(rawUrl);
      if (extracted == null) return null;

      // Share Extension에서 생성한 신규 라벨을 Hive에 저장
      // (URL 검증 통과 후에 라벨을 생성해 고아 라벨 생성 방지)
      final newLabels = (map['newLabels'] as List?)?.cast<Map>() ?? [];
      for (final nl in newLabels) {
        final name = nl['name'] as String;
        final colorValue = nl['colorValue'] as int;
        final exists =
            DatabaseService.getAllLabelObjects().any((l) => l.name == name);
        if (!exists) {
          await DatabaseService.createLabel(name, Color(colorValue));
        }
      }

      final labels = (map['labels'] as List?)?.cast<String>() ?? [];
      return await (processAndSaveOverride ?? processAndSave)(
        extracted,
        labels: labels,
      );
    } catch (_) {
      // 구버전 plain URL 또는 파손된 JSON 호환 처리
      // extractURL 을 통과한 경우에만 저장 (쓰레기 텍스트 저장 방지)
      final extracted = extractURL(item);
      if (extracted == null) return null;
      return await (processAndSaveOverride ?? processAndSave)(extracted);
    }
  }

  /// 앱 시작 시 또는 포그라운드 복귀 시 호출
  static Future<void> checkPendingShares() async {
    if (io.Platform.isAndroid) {
      final text = await getSharedTextFromIntent();
      if (text != null) {
        final url = extractURL(text);
        if (url != null) {
          await processAndSave(url);
        }
      }
    } else if (io.Platform.isIOS) {
      final items = await getSharedURLsFromAppGroup();
      for (final item in items) {
        await processSharedItem(item);
      }
      if (items.isNotEmpty) {
        await clearSharedURLs();
      }
    }
  }
}
