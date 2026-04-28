// ScrapingService (M-5 보안 강화)
//
// SSRF 방어:
//   - URL 호스트가 IP literal이면 isPrivateOrLoopback으로 사전 차단한다.
//   - 3xx 리다이렉트를 자동 추적하지 않고 수동 루프로 매 hop마다 재검증한다.
//     (Location 헤더가 사설 IP 또는 비-http/https 스킴이면 fallback 반환)
//   - DNS 해석 결과의 사설 IP 차단은 미구현(DNS rebinding은 향후 follow-up).
//
// OOM 방어:
//   - http.Client.send()를 통해 스트리밍 응답을 받는다.
//   - 누적 버퍼가 _maxResponseBytes(2MB)를 초과하면 스트림을 중단하고 fallback을 반환.
//
// Content-Type 가드:
//   - text/html, application/xhtml+xml, text/plain 이외의 응답은 파싱하지 않는다.
//
// 리다이렉트 처리:
//   - followRedirects = false 로 자동 추적 비활성화.
//   - 3xx 응답의 Location 헤더를 parseAllowedUrl + isPrivateOrLoopback으로 재검증.
//   - 최대 _maxRedirects(5)회. 초과 시 fallback 반환.
//   - 누적 timeout _totalTimeoutSeconds(10s) 기준 deadline 방식.
//
// 테스트 주입 시임(seam):
//   - clientFactory가 null이 아니면 해당 팩토리로 http.Client를 생성한다.
//   - 프로덕션에서는 항상 null이며 http.Client()가 사용된다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:clib/utils/url_safety.dart';

/// 응답 body 최대 허용 크기 (2MB)
const int _maxResponseBytes = 2 * 1024 * 1024;

/// 최대 리다이렉트 횟수
const int _maxRedirects = 5;

/// 총 허용 시간 (초)
const int _totalTimeoutSeconds = 10;

/// 허용되는 Content-Type 접두사 목록
const List<String> _allowedContentTypes = [
  'text/html',
  'application/xhtml+xml',
  'text/plain',
];

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
  /// 테스트 주입용 팩토리 (null이면 프로덕션 기본값 http.Client() 사용)
  @visibleForTesting
  static http.Client Function()? clientFactory;

  static Future<OpenGraphData> scrape(String url) async {
    try {
      final initialUri = parseAllowedUrl(url);
      if (initialUri == null) return OpenGraphData(title: url);

      // 누적 deadline: 전체 리다이렉트 체인에 걸쳐 10초
      final deadline = DateTime.now().add(
        const Duration(seconds: _totalTimeoutSeconds),
      );

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
      };

      var currentUri = initialUri;
      http.StreamedResponse? finalResponse;

      // --- 초기 URL IP literal 사전 차단 (clientFactory 호출 전) ---
      // 첫 hop을 루프 전에 검증하여 사설 IP literal이면 client 생성 없이 즉시 반환.
      {
        final ipAddr = InternetAddress.tryParse(currentUri.host);
        if (ipAddr != null && isPrivateOrLoopback(ipAddr)) {
          return OpenGraphData(title: url);
        }
      }

      // --- 리다이렉트 루프 (SSRF 방어: 매 hop마다 IP literal 재검증) ---
      final client = clientFactory != null ? clientFactory!() : http.Client();
      try {
        for (var hop = 0; hop <= _maxRedirects; hop++) {
          // 매 hop마다 IP literal 차단 (리다이렉트 대상 포함)
          // 참고: 최초 URL은 루프 진입 전에 이미 검증하였으나 hop == 0일 때도
          //       동일 검증을 실행하여 코드 경로를 단순화한다.
          final ipAddr = InternetAddress.tryParse(currentUri.host);
          if (ipAddr != null && isPrivateOrLoopback(ipAddr)) {
            // 사설/루프백 IP literal → HTTP 요청 없이 fallback 반환
            return OpenGraphData(title: url);
          }

          final remaining = deadline.difference(DateTime.now());
          if (remaining.isNegative || remaining == Duration.zero) {
            // 전체 deadline 소진 → fallback
            return OpenGraphData(title: url);
          }

          final request = http.Request('GET', currentUri)
            ..followRedirects = false
            ..headers.addAll(headers);

          final streamedResponse = await client
              .send(request)
              .timeout(remaining);

          final statusCode = streamedResponse.statusCode;

          if (statusCode >= 300 && statusCode < 400) {
            // 3xx 리다이렉트 처리
            final location = streamedResponse.headers['location'];
            if (location == null || hop == _maxRedirects) {
              // Location 없거나 최대 횟수 초과 → fallback
              return OpenGraphData(title: url);
            }
            // Location을 현재 URI 기준으로 해석 (상대 경로 지원)
            final resolvedUri = currentUri.resolve(location);
            // http/https 스킴 + 호스트 검증
            final allowedNext = parseAllowedUrl(resolvedUri.toString());
            if (allowedNext == null) {
              return OpenGraphData(title: url);
            }
            currentUri = allowedNext;
            // 리다이렉트 응답 body 소비하여 연결 자원 해제
            await streamedResponse.stream.drain<void>();
            continue;
          }

          // 2xx 또는 기타 터미널 상태 → 루프 탈출
          finalResponse = streamedResponse;
          break;
        }

        if (finalResponse == null) {
          return OpenGraphData(title: url);
        }

        if (finalResponse.statusCode != 200) {
          return OpenGraphData(title: url);
        }

        // --- Content-Type 가드 ---
        final contentType =
            (finalResponse.headers['content-type'] ?? '').toLowerCase();
        final isAllowedType = _allowedContentTypes.any(
          (allowed) => contentType.startsWith(allowed),
        );
        if (!isAllowedType) {
          // HTML이 아닌 응답(이미지, PDF 등) → 파싱 중단
          return OpenGraphData(title: url);
        }

        // --- 응답 크기 상한: 스트림을 2MB까지만 누적 ---
        final buffer = <int>[];
        var truncated = false;

        final remainingForBody = deadline.difference(DateTime.now());
        if (remainingForBody.isNegative) return OpenGraphData(title: url);

        await for (final chunk in finalResponse.stream.timeout(
          remainingForBody,
        )) {
          if (buffer.length + chunk.length > _maxResponseBytes) {
            // 상한 초과 → 더 이상 수집하지 않고 중단
            truncated = true;
            break;
          }
          buffer.addAll(chunk);
        }

        if (truncated) {
          // 잘린 응답은 파싱하지 않고 fallback 반환
          return OpenGraphData(title: url);
        }

        // --- charset 감지 후 디코딩 ---
        final charsetMatch = RegExp(
          r'charset=([^\s;]+)',
          caseSensitive: false,
        ).firstMatch(contentType);
        final charset = charsetMatch?.group(1)?.toLowerCase() ?? 'utf-8';

        final bodyBytes = Uint8List.fromList(buffer);
        String body;
        if (charset == 'utf-8' || charset == 'utf8') {
          body = utf8.decode(bodyBytes, allowMalformed: true);
        } else if (charset == 'euc-kr' || charset == 'euckr') {
          // EUC-KR은 dart 기본 미지원이므로 UTF-8 fallback
          try {
            body = utf8.decode(bodyBytes, allowMalformed: true);
          } catch (_) {
            body = latin1.decode(bodyBytes);
          }
        } else {
          body = utf8.decode(bodyBytes, allowMalformed: true);
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
      } finally {
        client.close();
      }
    } catch (_) {
      // 동적 렌더링 사이트 등 스크래핑 실패 시 URL로 대체
      return OpenGraphData(title: url);
    }
  }
}
