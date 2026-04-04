import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class OpenGraphData {
  final String title;
  final String? imageUrl;
  final String? description;

  const OpenGraphData({
    required this.title,
    this.imageUrl,
    this.description,
  });
}

class ScrapingService {
  static Future<OpenGraphData> scrape(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return OpenGraphData(title: url);
      }

      // Content-Type 헤더에서 charset 확인, 없으면 UTF-8로 디코딩
      final contentType = response.headers['content-type'] ?? '';
      final charsetMatch =
          RegExp(r'charset=([^\s;]+)', caseSensitive: false).firstMatch(contentType);
      final charset = charsetMatch?.group(1)?.toLowerCase() ?? 'utf-8';

      String body;
      if (charset == 'utf-8' || charset == 'utf8') {
        body = utf8.decode(response.bodyBytes, allowMalformed: true);
      } else if (charset == 'euc-kr' || charset == 'euckr') {
        // EUC-KR은 dart 기본 미지원이므로 Latin-1 fallback 후 UTF-8 재시도
        try {
          body = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          body = latin1.decode(response.bodyBytes);
        }
      } else {
        body = utf8.decode(response.bodyBytes, allowMalformed: true);
      }

      final document = html_parser.parse(body);
      final metaTags = document.getElementsByTagName('meta');

      String? ogTitle;
      String? ogImage;
      String? ogDescription;

      for (final tag in metaTags) {
        final property = tag.attributes['property'] ?? tag.attributes['name'];
        final content = tag.attributes['content'];

        if (content == null || content.isEmpty) continue;

        switch (property) {
          case 'og:title':
            ogTitle = content;
          case 'og:image':
            ogImage = content;
          case 'og:description':
            ogDescription = content;
        }
      }

      // og:title 없으면 <title> 태그에서 추출
      ogTitle ??= document.querySelector('title')?.text;

      return OpenGraphData(
        title: ogTitle ?? url,
        imageUrl: ogImage,
        description: ogDescription,
      );
    } catch (_) {
      // 동적 렌더링 사이트 등 스크래핑 실패 시 URL로 대체
      return OpenGraphData(title: url);
    }
  }
}
