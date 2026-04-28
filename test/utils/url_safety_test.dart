// M-4: URL 스킴 화이트리스트 — url_safety.dart 유닛 테스트
// M-5: isPrivateOrLoopback — 사설/루프백 IP 판별 유닛 테스트
//
// isAllowedUrl: http/https 스킴만 허용. 그 외 모두 false.
// parseAllowedUrl: isAllowedUrl 통과 시 Uri 반환, 아니면 null.
// isPrivateOrLoopback: 사설망·루프백·링크로컬 주소 → true, 공인 IP → false.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:clib/utils/url_safety.dart';

void main() {
  group('isAllowedUrl', () {
    test('(1) https URL은 허용된다', () {
      expect(isAllowedUrl('https://example.com/path'), isTrue);
    });

    test('(2) http URL은 허용된다', () {
      expect(isAllowedUrl('http://example.com'), isTrue);
    });

    test('(3) HTTPS 대문자 스킴도 허용된다 (case insensitive)', () {
      expect(isAllowedUrl('HTTPS://EXAMPLE.com'), isTrue);
    });

    test('(4) javascript: 스킴은 거부된다', () {
      expect(isAllowedUrl('javascript:alert(1)'), isFalse);
    });

    test('(5) intent:// 스킴은 거부된다', () {
      expect(isAllowedUrl('intent://example.com'), isFalse);
    });

    test('(6) file:// 스킴은 거부된다', () {
      expect(isAllowedUrl('file:///etc/passwd'), isFalse);
    });

    test('(7) ftp:// 스킴은 거부된다', () {
      expect(isAllowedUrl('ftp://example.com'), isFalse);
    });

    test('(8) ssh:// 스킴은 거부된다', () {
      expect(isAllowedUrl('ssh://user@host'), isFalse);
    });

    test('(9) mailto: 스킴은 거부된다', () {
      expect(isAllowedUrl('mailto:foo@bar.com'), isFalse);
    });

    test('(10) //example.com (스킴 없음)은 거부된다', () {
      expect(isAllowedUrl('//example.com'), isFalse);
    });

    test('(11) example.com (스킴 없음)은 거부된다', () {
      expect(isAllowedUrl('example.com'), isFalse);
    });

    test('(12) https: (호스트 없음)은 거부된다', () {
      expect(isAllowedUrl('https:'), isFalse);
    });

    test('(13) 빈 문자열은 거부된다', () {
      expect(isAllowedUrl(''), isFalse);
    });

    test('(14) 공백 문자열은 거부된다', () {
      expect(isAllowedUrl('   '), isFalse);
    });
  });

  group('parseAllowedUrl', () {
    test('(15) https URL이면 non-null Uri를 반환하고 scheme/host가 올바르다', () {
      final uri = parseAllowedUrl('https://x.com/y');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'x.com');
    });

    test('(16) javascript: URL이면 null을 반환한다', () {
      expect(parseAllowedUrl('javascript:alert(1)'), isNull);
    });
  });

  // -----------------------------------------------------------------------
  // M-5: isPrivateOrLoopback 테스트
  // -----------------------------------------------------------------------
  InternetAddress ip(String addr) => InternetAddress(addr);

  group('isPrivateOrLoopback — IPv4 차단 대상', () {
    test('(17) 127.0.0.1 (루프백)은 true', () {
      expect(isPrivateOrLoopback(ip('127.0.0.1')), isTrue);
    });

    test('(18) 10.0.0.5 (RFC1918 10/8)은 true', () {
      expect(isPrivateOrLoopback(ip('10.0.0.5')), isTrue);
    });

    test('(19) 172.16.5.10 (RFC1918 172.16/12 경계 안)은 true', () {
      expect(isPrivateOrLoopback(ip('172.16.5.10')), isTrue);
    });

    test('(20) 172.31.255.255 (RFC1918 172.16/12 끝)은 true', () {
      expect(isPrivateOrLoopback(ip('172.31.255.255')), isTrue);
    });

    test('(21) 192.168.1.1 (RFC1918 192.168/16)은 true', () {
      expect(isPrivateOrLoopback(ip('192.168.1.1')), isTrue);
    });

    test('(22) 169.254.169.254 (링크로컬 / AWS 메타데이터)은 true', () {
      expect(isPrivateOrLoopback(ip('169.254.169.254')), isTrue);
    });

    test('(23) 0.0.0.0 (이 네트워크)은 true', () {
      expect(isPrivateOrLoopback(ip('0.0.0.0')), isTrue);
    });
  });

  group('isPrivateOrLoopback — IPv4 허용 대상', () {
    test('(24) 8.8.8.8 (Google DNS)은 false', () {
      expect(isPrivateOrLoopback(ip('8.8.8.8')), isFalse);
    });

    test('(25) 1.1.1.1 (Cloudflare DNS)은 false', () {
      expect(isPrivateOrLoopback(ip('1.1.1.1')), isFalse);
    });

    test('(26) 172.15.0.1 (RFC1918 범위 바로 바깥)은 false', () {
      expect(isPrivateOrLoopback(ip('172.15.0.1')), isFalse);
    });

    test('(27) 172.32.0.1 (RFC1918 범위 바로 바깥)은 false', () {
      expect(isPrivateOrLoopback(ip('172.32.0.1')), isFalse);
    });
  });

  group('isPrivateOrLoopback — IPv6 차단 대상', () {
    test('(28) ::1 (IPv6 루프백)은 true', () {
      expect(isPrivateOrLoopback(ip('::1')), isTrue);
    });

    test('(29) fe80::1 (IPv6 링크로컬)은 true', () {
      expect(isPrivateOrLoopback(ip('fe80::1')), isTrue);
    });

    test('(30) fd00::1 (IPv6 ULA)은 true', () {
      expect(isPrivateOrLoopback(ip('fd00::1')), isTrue);
    });

    test('(31) fc00::1 (IPv6 ULA fc00::/7)은 true', () {
      expect(isPrivateOrLoopback(ip('fc00::1')), isTrue);
    });
  });

  group('isPrivateOrLoopback — IPv6 허용 대상', () {
    test('(32) 2001:4860:4860::8888 (Google DNS)은 false', () {
      expect(isPrivateOrLoopback(ip('2001:4860:4860::8888')), isFalse);
    });
  });
}
