// M-5: ScrapingService SSRF + OOM 방어 — 유닛 테스트
//
// 테스트 목표:
//   a. 공개 URL 성공 경로: og:title 파싱
//   b. 사설 IP literal 차단: HTTP 요청 없이 fallback 반환
//   c. 루프백 URL 차단: HTTP 요청 없이 fallback 반환
//   d. AWS 메타데이터 URL 차단: HTTP 요청 없이 fallback 반환
//   e. 응답 크기 초과: 2MB 이상 응답 시 fallback 반환
//   f. 비HTML Content-Type 차단: 파싱 없이 fallback 반환
//   g. IPv6 루프백 literal 차단
//   h. IPv6 링크로컬 literal 차단
//   i. 404 응답 → fallback 반환
//   j. og:title 없고 <title> 있음 → <title> 값 반환
//   k. 리다이렉트(공개→사설 IP) 차단: 두 번째 hop 요청 없이 fallback 반환
//   l. 리다이렉트 체인(3회) 성공: og:title 파싱
//   m. 최대 리다이렉트 초과(6회+) → fallback 반환
//   n. 리다이렉트 Location이 javascript: 스킴 → fallback 반환
//   o. 상대 리다이렉트(/other) → 현재 URI 기준 해석 후 정상 스크래핑
//
// 주의: ScrapingService.clientFactory는 각 테스트 후 반드시 null로 초기화한다.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:clib/services/scraping_service.dart';

void main() {
  tearDown(() {
    // 테스트 간 상태 누출 방지
    ScrapingService.clientFactory = null;
  });

  // -----------------------------------------------------------------------
  // a. 공개 URL 성공 경로
  // -----------------------------------------------------------------------
  test('(a) og:title이 있는 HTML 응답 → OpenGraphData(title: og:title)', () async {
    const html = '''
<html>
  <head>
    <meta property="og:title" content="Hello World" />
    <meta property="og:image" content="https://example.com/img.png" />
  </head>
</html>''';

    ScrapingService.clientFactory = () => MockClient((request) async {
          return http.Response(html, 200, headers: {
            'content-type': 'text/html; charset=utf-8',
          });
        });

    final result = await ScrapingService.scrape('https://example.com');
    expect(result.title, 'Hello World');
    expect(result.imageUrl, 'https://example.com/img.png');
  });

  // -----------------------------------------------------------------------
  // b. 사설 IP literal 차단
  // -----------------------------------------------------------------------
  test('(b) 192.168.1.1 (사설 IP) → HTTP 요청 없이 fallback 반환', () async {
    var clientCalled = false;
    ScrapingService.clientFactory = () {
      clientCalled = true;
      return MockClient((_) async => http.Response('', 200));
    };

    const url = 'http://192.168.1.1/admin';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    // clientFactory 자체가 호출되지 않아야 한다 (HTTP 요청 전에 차단)
    expect(clientCalled, isFalse);
  });

  // -----------------------------------------------------------------------
  // c. 루프백 URL 차단
  // -----------------------------------------------------------------------
  test('(c) 127.0.0.1 (루프백) → HTTP 요청 없이 fallback 반환', () async {
    var clientCalled = false;
    ScrapingService.clientFactory = () {
      clientCalled = true;
      return MockClient((_) async => http.Response('', 200));
    };

    const url = 'http://127.0.0.1:8080/page';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    expect(clientCalled, isFalse);
  });

  // -----------------------------------------------------------------------
  // d. AWS 메타데이터 URL 차단
  // -----------------------------------------------------------------------
  test('(d) 169.254.169.254 (AWS 메타데이터) → HTTP 요청 없이 fallback 반환', () async {
    var clientCalled = false;
    ScrapingService.clientFactory = () {
      clientCalled = true;
      return MockClient((_) async => http.Response('', 200));
    };

    const url = 'http://169.254.169.254/latest/meta-data/';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    expect(clientCalled, isFalse);
  });

  // -----------------------------------------------------------------------
  // e. 응답 크기 초과 → fallback 반환
  // -----------------------------------------------------------------------
  test('(e) 3MB 응답 → 2MB 캡 초과로 fallback 반환', () async {
    // 1MB 청크 3개 → 총 3MB, 2MB 캡 초과
    final chunk1MB = Uint8List(1024 * 1024); // 1MB 빈 바이트
    final chunks = [chunk1MB, chunk1MB, chunk1MB];

    ScrapingService.clientFactory = () => MockClient.streaming(
          (request, bodyStream) async {
            final controller = StreamController<List<int>>();
            Future.microtask(() async {
              for (final chunk in chunks) {
                controller.add(chunk);
              }
              await controller.close();
            });
            return http.StreamedResponse(
              controller.stream,
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          },
        );

    const url = 'https://example.com/huge-page';
    final result = await ScrapingService.scrape(url);

    // 잘린 응답 → og:title 없음 → fallback
    expect(result.title, url);
  });

  // -----------------------------------------------------------------------
  // f. 비HTML Content-Type 차단
  // -----------------------------------------------------------------------
  test('(f) Content-Type: image/png → 파싱 없이 fallback 반환', () async {
    ScrapingService.clientFactory = () => MockClient((_) async {
          return http.Response(
            '\x89PNG\r\n\x1a\n', // PNG 시그니처
            200,
            headers: {'content-type': 'image/png'},
          );
        });

    const url = 'https://example.com/image.png';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
  });

  // -----------------------------------------------------------------------
  // g. IPv6 literal 루프백 차단
  // -----------------------------------------------------------------------
  test('(g) [::1] (IPv6 루프백 literal) → HTTP 요청 없이 fallback 반환', () async {
    var clientCalled = false;
    ScrapingService.clientFactory = () {
      clientCalled = true;
      return MockClient((_) async => http.Response('', 200));
    };

    const url = 'http://[::1]/page';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    expect(clientCalled, isFalse);
  });

  // -----------------------------------------------------------------------
  // h. IPv6 링크로컬 literal 차단
  // -----------------------------------------------------------------------
  test('(h) [fe80::1] (IPv6 링크로컬 literal) → HTTP 요청 없이 fallback 반환', () async {
    var clientCalled = false;
    ScrapingService.clientFactory = () {
      clientCalled = true;
      return MockClient((_) async => http.Response('', 200));
    };

    const url = 'http://[fe80::1]/';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    expect(clientCalled, isFalse);
  });

  // -----------------------------------------------------------------------
  // i. 404 응답 → fallback 반환
  // -----------------------------------------------------------------------
  test('(i) 404 응답 → fallback 반환', () async {
    ScrapingService.clientFactory = () => MockClient((_) async {
          return http.Response('Not Found', 404, headers: {
            'content-type': 'text/html',
          });
        });

    const url = 'https://example.com/not-found';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
  });

  // -----------------------------------------------------------------------
  // j. <title> 태그 fallback (og:title 없음)
  // -----------------------------------------------------------------------
  test('(j) og:title 없고 <title> 있음 → <title> 값 반환', () async {
    const html = '''
<html>
  <head><title>Page Title</title></head>
  <body></body>
</html>''';

    ScrapingService.clientFactory = () => MockClient((_) async {
          return http.Response(html, 200, headers: {
            'content-type': 'text/html; charset=utf-8',
          });
        });

    final result = await ScrapingService.scrape('https://example.com/page');
    expect(result.title, 'Page Title');
  });

  // -----------------------------------------------------------------------
  // k. 리다이렉트: 공개 URL → 사설 IP → fallback (두 번째 hop 요청 없음)
  // -----------------------------------------------------------------------
  test('(k) 302 → 192.168.1.1 (사설 IP) → fallback, send 호출 1회만', () async {
    var sendCount = 0;
    ScrapingService.clientFactory = () => MockClient((request) async {
          sendCount++;
          if (request.url.host == 'attacker.example.com') {
            // 첫 번째 요청: 사설 IP로 리다이렉트
            return http.Response('', 302, headers: {
              'location': 'http://192.168.1.1/admin',
            });
          }
          // 두 번째 요청은 호출되어서는 안 됨
          return http.Response('should not reach', 200, headers: {
            'content-type': 'text/html',
          });
        });

    const url = 'https://attacker.example.com/page';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    // 첫 번째 hop에서 302를 받고 Location을 검증하여 차단 → send 1회만
    expect(sendCount, 1);
  });

  // -----------------------------------------------------------------------
  // l. 리다이렉트 체인 3회 성공 (공개 → 공개 → 공개 → 200)
  // -----------------------------------------------------------------------
  test('(l) 302 → 302 → 200 (공개 호스트) → og:title 파싱 성공, send 3회', () async {
    var sendCount = 0;
    const ogHtml = '''
<html>
  <head><meta property="og:title" content="Final Page" /></head>
</html>''';

    ScrapingService.clientFactory = () => MockClient((request) async {
          sendCount++;
          if (request.url.host == 'hop1.example.com') {
            return http.Response('', 302, headers: {
              'location': 'https://hop2.example.com/page',
            });
          } else if (request.url.host == 'hop2.example.com') {
            return http.Response('', 302, headers: {
              'location': 'https://hop3.example.com/final',
            });
          } else {
            // hop3.example.com → 최종 응답
            return http.Response(ogHtml, 200, headers: {
              'content-type': 'text/html; charset=utf-8',
            });
          }
        });

    final result = await ScrapingService.scrape('https://hop1.example.com/start');

    expect(result.title, 'Final Page');
    expect(sendCount, 3);
  });

  // -----------------------------------------------------------------------
  // m. 최대 리다이렉트 초과(6회+) → fallback, send 최대 maxRedirects+1 = 6회
  // -----------------------------------------------------------------------
  test('(m) 6회 이상 리다이렉트 → fallback, send 6회 이하', () async {
    var sendCount = 0;
    ScrapingService.clientFactory = () => MockClient((request) async {
          sendCount++;
          // 항상 자기 자신으로 리다이렉트 (무한 루프)
          return http.Response('', 302, headers: {
            'location': 'https://loop.example.com/page',
          });
        });

    const url = 'https://loop.example.com/page';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    // _maxRedirects = 5 → hop 0~5 = 6회 이하
    expect(sendCount, lessThanOrEqualTo(6));
  });

  // -----------------------------------------------------------------------
  // n. 리다이렉트 Location이 javascript: 스킴 → fallback
  // -----------------------------------------------------------------------
  test('(n) 302 Location: javascript:alert(1) → fallback (parseAllowedUrl null)', () async {
    var sendCount = 0;
    ScrapingService.clientFactory = () => MockClient((request) async {
          sendCount++;
          return http.Response('', 302, headers: {
            'location': 'javascript:alert(1)',
          });
        });

    const url = 'https://example.com/page';
    final result = await ScrapingService.scrape(url);

    expect(result.title, url);
    // javascript: 스킴은 parseAllowedUrl에서 거부 → 두 번째 hop 없음
    expect(sendCount, 1);
  });

  // -----------------------------------------------------------------------
  // o. 상대 리다이렉트(/other) → 현재 URI 기준 해석 후 정상 스크래핑
  // -----------------------------------------------------------------------
  test('(o) 302 Location: /other (상대 경로) → 정상 해석 후 og:title 파싱', () async {
    const ogHtml = '''
<html>
  <head><meta property="og:title" content="Other Page" /></head>
</html>''';

    var sendCount = 0;
    ScrapingService.clientFactory = () => MockClient((request) async {
          sendCount++;
          if (request.url.path == '/start') {
            return http.Response('', 302, headers: {
              'location': '/other',
            });
          } else {
            // /other → 최종 응답
            return http.Response(ogHtml, 200, headers: {
              'content-type': 'text/html; charset=utf-8',
            });
          }
        });

    final result = await ScrapingService.scrape('https://example.com/start');

    expect(result.title, 'Other Page');
    // /start → 302 → /other(해석: https://example.com/other) → 200
    expect(sendCount, 2);
  });
}
