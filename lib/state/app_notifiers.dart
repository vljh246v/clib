import 'package:flutter/foundation.dart';

/// 아티클 추가/삭제/수정 시 구독자(Cubit/Bloc)에 알리는 전역 notifier.
///
/// 발사 위치는 `DatabaseService`의 mutation 메서드 + `SyncService` 원격 스냅샷
/// 적용 분기. 그 외 경로에서 직접 발사하지 않는다.
final articlesChangedNotifier = ValueNotifier<int>(0);

/// 라벨 변경 시 구독자(Cubit/Bloc)에 알리는 전역 notifier.
///
/// 발사 위치는 `DatabaseService`의 라벨 mutation 메서드 + `SyncService` 원격
/// 스냅샷 적용 분기.
final labelsChangedNotifier = ValueNotifier<int>(0);

class NotificationLabelTapRequest {
  final int labelKey;
  final int requestId;

  const NotificationLabelTapRequest({
    required this.labelKey,
    required this.requestId,
  });
}

/// 라벨 알림 클릭 요청.
///
/// 같은 라벨 알림을 반복 클릭해도 처리되도록 [NotificationLabelTapRequest.requestId]
/// 를 매번 증가시킨다.
final notificationLabelTapNotifier =
    ValueNotifier<NotificationLabelTapRequest?>(null);
