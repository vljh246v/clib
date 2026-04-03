import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:clib/main.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/scraping_service.dart';

class ShareService {
  static const _channel = MethodChannel('com.clib.clib/share');

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
    articlesChangedNotifier.value++;
    return article;
  }

  /// 안드로이드: 공유된 URL만 반환 (저장하지 않음)
  static Future<String?> getPendingShareURL() async {
    if (!io.Platform.isAndroid) return null;
    final text = await getSharedTextFromIntent();
    if (text == null) return null;
    return extractURL(text);
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
        // JSON 형식: {"url":"...","labels":["..."]} 또는 plain URL
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final url = map['url'] as String;
          final labels = (map['labels'] as List?)?.cast<String>() ?? [];
          // Share Extension에서 생성한 신규 라벨을 Hive에 저장
          final newLabels = (map['newLabels'] as List?)?.cast<Map>() ?? [];
          for (final nl in newLabels) {
            final name = nl['name'] as String;
            final colorValue = nl['colorValue'] as int;
            final exists = DatabaseService.getAllLabelObjects()
                .any((l) => l.name == name);
            if (!exists) {
              await DatabaseService.createLabel(name, Color(colorValue));
            }
          }
          await processAndSave(url, labels: labels);
        } catch (_) {
          // 구버전 plain URL 호환
          await processAndSave(item);
        }
      }
      if (items.isNotEmpty) {
        await clearSharedURLs();
      }
    }
  }
}
