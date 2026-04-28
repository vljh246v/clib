// M-1 회귀 테스트: iOS 공유 JSON 파싱 실패 시 쓰레기 URL 저장 방지
//
// 테스트 심(Seam) — processAndSaveOverride:
//   null이면 프로덕션 경로(실제 processAndSave)를 사용한다.
//   테스트에서는 Hive/네트워크 없이 호출 여부·인자를 검증하기 위해
//   processAndSaveOverride에 추적 함수를 주입한다.
//
// newLabels 처리(DatabaseService.createLabel)는 Hive를 필요로 하므로
// 이 테스트에서는 newLabels 키가 없는 JSON만 사용한다.
// 그 대신 URL 검증 로직 전체(JSON happy path + catch path 양쪽)를 커버한다.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:clib/models/article.dart';
import 'package:clib/services/share_service.dart';

/// 테스트용 더미 Article 팩토리
Article _dummyArticle(String url) {
  return Article()
    ..url = url
    ..title = 'Test'
    ..thumbnailUrl = null
    ..platform = Platform.etc
    ..topicLabels = []
    ..isRead = false
    ..createdAt = DateTime(2024, 1, 1);
}

void main() {
  // 마지막으로 override가 호출된 인자를 추적
  String? capturedUrl;
  List<String>? capturedLabels;
  int overrideCallCount = 0;

  setUp(() {
    capturedUrl = null;
    capturedLabels = null;
    overrideCallCount = 0;

    // processAndSave 를 스텁으로 대체 — Hive/네트워크 없이 동작
    ShareService.processAndSaveOverride = (String url, {List<String> labels = const []}) async {
      capturedUrl = url;
      capturedLabels = List<String>.from(labels);
      overrideCallCount++;
      return _dummyArticle(url);
    };
  });

  tearDown(() {
    ShareService.processAndSaveOverride = null;
  });

  group('processSharedItem — URL 검증 및 저장 분기 검증 (M-1)', () {
    // 1. 유효한 JSON + 유효한 URL → override 호출
    test(
      '(M-1-1) 유효한 JSON이고 url 필드가 유효한 URL이면 override가 호출된다',
      () async {
        final item = jsonEncode({
          'url': 'https://example.com/article',
          'labels': ['tech', 'news'],
        });

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 1, reason: 'processAndSave가 정확히 1회 호출되어야 한다');
        expect(capturedUrl, 'https://example.com/article');
        expect(capturedLabels, ['tech', 'news']);
        expect(result, isNotNull);
      },
    );

    // 2. 유효한 JSON이지만 url 필드가 비-URL → override 미호출
    test(
      '(M-1-2) 유효한 JSON이지만 url 필드가 유효하지 않은 URL이면 override가 호출되지 않는다',
      () async {
        final item = jsonEncode({'url': 'not-a-url'});

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 0,
            reason: '비-URL url 필드는 저장이 건너뛰어져야 한다');
        expect(result, isNull);
      },
    );

    // 3. plain URL 문자열 → catch 경로, override 호출
    test(
      '(M-1-3) plain URL 문자열이면 catch 경로에서 override가 URL과 함께 호출된다',
      () async {
        const item = 'https://example.com/path';

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 1, reason: 'plain URL은 processAndSave가 호출되어야 한다');
        expect(capturedUrl, 'https://example.com/path');
        expect(result, isNotNull);
      },
    );

    // 4. 쓰레기 텍스트 → catch 경로, extractURL null → override 미호출
    test(
      '(M-1-4) 쓰레기 텍스트이면 extractURL이 null을 반환해 override가 호출되지 않는다',
      () async {
        const item = 'hello world';

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 0,
            reason: '비-URL 텍스트는 저장이 건너뛰어져야 한다');
        expect(result, isNull);
      },
    );

    // 5. 파손된 JSON → catch 경로, extractURL null → override 미호출
    test(
      '(M-1-5) 파손된 JSON이면 catch 경로로 떨어지고 override가 호출되지 않는다',
      () async {
        const item = '{"url":'; // 파손된 JSON

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 0,
            reason: '파손된 JSON은 저장이 건너뛰어져야 한다');
        expect(result, isNull);
      },
    );

    // 6. JSON url 필드가 "텍스트 + URL" 형태 → extractURL로 URL만 추출해 호출
    test(
      '(M-1-6) JSON url 필드에 텍스트가 섞인 경우 extractURL로 추출한 URL만 override에 전달된다',
      () async {
        final item = jsonEncode({
          'url': 'check this https://x.com/post/123',
        });

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 1, reason: 'URL이 추출되었으므로 저장이 호출되어야 한다');
        // 원문('check this https://x.com/post/123')이 아닌 추출된 URL만 전달
        expect(capturedUrl, 'https://x.com/post/123',
            reason: 'extractURL이 추출한 URL만 저장되어야 한다 (원문 전달 금지)');
        expect(result, isNotNull);
      },
    );

    // 7. labels가 없는 JSON → 빈 리스트로 처리
    test(
      '(M-1-7) JSON에 labels 키가 없으면 빈 라벨 리스트로 override가 호출된다',
      () async {
        final item = jsonEncode({'url': 'https://github.com/flutter/flutter'});

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 1);
        expect(capturedLabels, isEmpty,
            reason: 'labels 키 누락 시 빈 리스트로 처리되어야 한다');
        expect(result, isNotNull);
      },
    );
  });

  // M-4: URL 스킴 화이트리스트 — 허용되지 않는 스킴은 override 미호출
  group('processSharedItem — M-4 스킴 화이트리스트 검증', () {
    test(
      '(M-4-1) JSON url 필드가 javascript: 스킴이면 override가 호출되지 않는다',
      () async {
        // extractURL regex는 https?:// 만 매칭하므로 이미 null 반환.
        // isAllowedUrl 이중 검증(방어-심층) 보장을 위한 테스트.
        final item = jsonEncode({'url': 'javascript:alert(1)'});

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 0,
            reason: 'javascript: URL은 저장이 건너뛰어져야 한다');
        expect(result, isNull);
      },
    );

    test(
      '(M-4-2) JSON url 필드가 intent:// 스킴이면 override가 호출되지 않는다',
      () async {
        final item = jsonEncode({'url': 'intent://attacker.app/x'});

        final result = await ShareService.processSharedItem(item);

        expect(overrideCallCount, 0,
            reason: 'intent:// URL은 저장이 건너뛰어져야 한다');
        expect(result, isNull);
      },
    );
  });
}
