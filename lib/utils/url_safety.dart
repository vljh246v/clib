// URL 스킴 화이트리스트 유틸리티 (M-4)
//
// http/https 스킴만 허용하며, 그 외 임의 스킴(javascript:, intent://, file:// 등)은
// 모두 거부한다. AddArticleCubit / ShareService / launchUrl 호출 지점에서 공통으로 사용.

// IP 안전성 유틸리티 (M-5)
//
// SSRF 방어를 위해 사설망/루프백/링크로컬 IP를 판별한다.
// ScrapingService에서 아웃바운드 요청 전 IP literal 호스트를 사전 차단한다.
// 주의: DNS 해석 결과의 사설 IP 차단은 미구현(DNS rebinding은 향후 follow-up).

import 'dart:io';

/// [input]이 허용된 URL(http 또는 https, 호스트 있음)이면 [Uri]를 반환하고,
/// 그렇지 않으면 null을 반환한다.
///
/// 스킴 비교는 대소문자 구별 없이 수행된다.
Uri? parseAllowedUrl(String input) {
  final uri = Uri.tryParse(input);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return uri;
}

/// [input]이 허용된 URL(http 또는 https, 호스트 있음)이면 true를 반환한다.
///
/// 내부적으로 [parseAllowedUrl]에 위임한다.
bool isAllowedUrl(String input) => parseAllowedUrl(input) != null;

/// [addr]가 사설망·루프백·링크로컬 주소이면 true를 반환한다.
///
/// 차단 범위 (IPv4):
///   - 127.0.0.0/8  (루프백)
///   - 10.0.0.0/8   (RFC1918 사설)
///   - 172.16.0.0/12 (RFC1918 사설)
///   - 192.168.0.0/16 (RFC1918 사설)
///   - 169.254.0.0/16 (링크로컬, AWS 메타데이터 포함)
///   - 0.0.0.0/8    (이 네트워크)
///
/// 차단 범위 (IPv6):
///   - ::1/128      (루프백)
///   - fc00::/7     (ULA)
///   - fe80::/10    (링크로컬)
///   - ::/128       (미지정)
bool isPrivateOrLoopback(InternetAddress addr) {
  if (addr.type == InternetAddressType.IPv4) {
    final bytes = addr.rawAddress;
    final b0 = bytes[0];
    final b1 = bytes[1];

    // 127.0.0.0/8 — 루프백
    if (b0 == 127) return true;
    // 10.0.0.0/8 — RFC1918 사설
    if (b0 == 10) return true;
    // 172.16.0.0/12 — RFC1918 사설 (172.16 ~ 172.31)
    if (b0 == 172 && b1 >= 16 && b1 <= 31) return true;
    // 192.168.0.0/16 — RFC1918 사설
    if (b0 == 192 && b1 == 168) return true;
    // 169.254.0.0/16 — 링크로컬
    if (b0 == 169 && b1 == 254) return true;
    // 0.0.0.0/8 — 이 네트워크
    if (b0 == 0) return true;

    return false;
  }

  if (addr.type == InternetAddressType.IPv6) {
    final bytes = addr.rawAddress;
    final b0 = bytes[0];
    final b1 = bytes[1];

    // ::1/128 — 루프백: 모든 바이트가 0이고 마지막만 1
    if (addr.address == '::1') return true;
    // ::/128 — 미지정: 모든 바이트가 0
    if (bytes.every((b) => b == 0)) return true;
    // fc00::/7 — ULA: 상위 7비트가 1111110
    if ((b0 & 0xFE) == 0xFC) return true;
    // fe80::/10 — 링크로컬: 상위 10비트가 1111111010
    if (b0 == 0xFE && (b1 & 0xC0) == 0x80) return true;

    return false;
  }

  // 알 수 없는 주소 유형은 안전상 차단
  return true;
}
