// app_logger 유틸리티 단위 테스트 (M-8)
//
// maskUid: 길이 기준 마스킹 정확성 검증
// log / logError: 기본 입력에서 예외 미발생 검증

import 'package:flutter_test/flutter_test.dart';
import 'package:clib/utils/app_logger.dart';

void main() {
  group('maskUid', () {
    test('길이 > 6 이면 앞 6자리 + … 반환', () {
      expect(maskUid('abc123def456'), equals('abc123…'));
    });

    test('길이 < 6 이면 *** 반환', () {
      expect(maskUid('short'), equals('***'));
    });

    test('길이 == 6 이면 *** 반환 (경계값 포함)', () {
      expect(maskUid('123456'), equals('***'));
    });

    test('길이 == 7 이면 앞 6자리 + … 반환 (경계값 +1)', () {
      expect(maskUid('1234567'), equals('123456…'));
    });
  });

  group('log', () {
    test('기본 메시지 입력 시 예외 없이 실행', () {
      expect(() => log('테스트 로그 메시지'), returnsNormally);
    });
  });

  group('logError', () {
    test('메시지만 전달 시 예외 없이 실행', () {
      expect(() => logError('테스트 에러 메시지'), returnsNormally);
    });

    test('error 객체 전달 시 예외 없이 실행', () {
      expect(
        () => logError('에러 발생', Exception('테스트 예외')),
        returnsNormally,
      );
    });

    test('error + stack 전달 시 예외 없이 실행', () {
      final trace = StackTrace.current;
      expect(
        () => logError('에러 발생', Exception('테스트 예외'), trace),
        returnsNormally,
      );
    });
  });
}
