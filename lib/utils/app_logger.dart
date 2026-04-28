// 릴리즈 빌드 로그 유출 방어 유틸리티 (M-8)
//
// Flutter debugPrint 는 기본 구현이 print()를 호출하여 release 빌드에서도
// Android logcat / iOS Console에 출력된다. 본 파일은 kDebugMode 가드를 통해
// 릴리즈 빌드에서 출력을 억제하고, UID 등 식별자를 마스킹하는 헬퍼를 제공한다.

import 'package:flutter/foundation.dart';

/// 일반 디버그 로그를 출력한다.
///
/// kDebugMode 에서만 [debugPrint]를 호출하며, 릴리즈/프로파일 빌드에서는
/// 출력하지 않는다.
void log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// 에러 로그를 출력한다.
///
/// [message]에 이어 [error], [stack]이 있을 경우 각각 한 줄씩 추가 출력한다.
/// kDebugMode 에서만 동작한다.
void logError(String message, [Object? error, StackTrace? stack]) {
  if (kDebugMode) {
    debugPrint(message);
    if (error != null) debugPrint('  error: $error');
    if (stack != null) debugPrint('  stack: $stack');
  }
}

/// Firebase UID 등 식별자를 앞 6자리만 남기고 마스킹한다.
///
/// - [uid] 길이가 6 이하이면 `'***'`를 반환한다.
/// - [uid] 길이가 7 이상이면 `앞 6자리 + '…'` 형식으로 반환한다.
String maskUid(String uid) {
  if (uid.length <= 6) return '***';
  return '${uid.substring(0, 6)}…';
}
