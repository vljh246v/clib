import 'dart:io' as io;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static bool get _isKorean => io.Platform.localeName.startsWith('ko');

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  /// 알림 권한 요청
  static Future<bool> requestPermission() async {
    if (io.Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } else if (io.Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  /// 라벨의 알림 스케줄 등록
  static Future<void> scheduleForLabel(Label label) async {
    // 기존 알림 먼저 취소
    await cancelForLabel(label);

    if (!label.notificationEnabled || label.notificationDays.isEmpty) return;

    final timeParts = label.notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 각 요일별로 weekly 알림 등록
    for (final day in label.notificationDays) {
      final id = _notificationId(label, day);
      // 0=월 → DateTime.monday(1), 6=일 → DateTime.sunday(7)
      final dartDay = day + 1;

      final channelName = _isKorean ? 'Clib 라벨 알림' : 'Clib Label Notifications';
      final channelDesc = _isKorean ? '라벨별 미읽음 아티클 알림' : 'Unread article notifications by label';

      await _plugin.zonedSchedule(
        id,
        '📚 ${label.name}',
        _buildBody(label.name),
        _nextWeekday(dartDay, hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'clib_label_${label.key}',
            channelName,
            channelDescription: channelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// 라벨의 모든 알림 취소
  static Future<void> cancelForLabel(Label label) async {
    for (var day = 0; day < 7; day++) {
      await _plugin.cancel(_notificationId(label, day));
    }
  }

  /// 앱 시작 시 모든 활성 알림 재등록
  static Future<void> rescheduleAll() async {
    await _plugin.cancelAll();
    final labels = DatabaseService.getLabelsWithNotification();
    for (final label in labels) {
      await scheduleForLabel(label);
    }
  }

  /// 알림 메시지 생성
  static String _buildBody(String labelName) {
    final stats = DatabaseService.getLabelStats(labelName);
    final unread = stats.total - stats.read;
    if (unread > 0) {
      return _isKorean
          ? '읽지 않은 아티클 $unread개가 있어요!'
          : 'You have $unread unread articles!';
    }
    return _isKorean ? '모두 읽었어요! 🎉' : 'All caught up! 🎉';
  }

  /// 알림 고유 ID (라벨 key * 10 + 요일)
  static int _notificationId(Label label, int day) {
    return (label.key as int) * 10 + day;
  }

  /// 다음 특정 요일+시간의 TZDateTime
  static tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 해당 요일로 이동
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // 이미 지난 시간이면 다음 주로
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
