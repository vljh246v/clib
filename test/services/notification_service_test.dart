import 'package:flutter_test/flutter_test.dart';

import 'package:clib/services/notification_service.dart';
import 'package:clib/state/app_notifiers.dart';

void main() {
  setUp(() {
    notificationLabelTapNotifier.value = null;
  });

  tearDown(() {
    notificationLabelTapNotifier.value = null;
  });

  group('NotificationService label tap payload', () {
    test('builds and parses a label tap payload with label key', () {
      final payload = NotificationService.buildLabelTapPayload(42);

      final request = NotificationService.parseLabelTapPayload(payload);

      expect(request?.labelKey, 42);
    });

    test('ignores empty, malformed, or non-label payloads', () {
      expect(NotificationService.parseLabelTapPayload(null), isNull);
      expect(NotificationService.parseLabelTapPayload(''), isNull);
      expect(NotificationService.parseLabelTapPayload('not-json'), isNull);
      expect(
        NotificationService.parseLabelTapPayload('{"type":"article"}'),
        isNull,
      );
    });

    test('publishes a new request for every valid label tap payload', () {
      final payload = NotificationService.buildLabelTapPayload(7);

      NotificationService.handleLabelTapPayload(payload);
      final first = notificationLabelTapNotifier.value;

      NotificationService.handleLabelTapPayload(payload);
      final second = notificationLabelTapNotifier.value;

      expect(first?.labelKey, 7);
      expect(second?.labelKey, 7);
      expect(second?.requestId, greaterThan(first!.requestId));
    });
  });
}
