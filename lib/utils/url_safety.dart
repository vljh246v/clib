// URL 스킴 화이트리스트 유틸리티 (M-4)
//
// http/https 스킴만 허용하며, 그 외 임의 스킴(javascript:, intent://, file:// 등)은
// 모두 거부한다. AddArticleCubit / ShareService / launchUrl 호출 지점에서 공통으로 사용.

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
