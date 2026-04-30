// Hive AES 암호화 키 관리 서비스 (M-7)
//
// 32바이트 마스터 키를 OS 보안 저장소에 영속 보관한다:
//   - Android: Android KeyStore (하드웨어 보안 모듈 지원)
//   - iOS: Keychain (first_unlock_this_device_only — 재설치 시 키 승계 없음)
//
// preferences 박스는 마이그레이션 플래그(hive_encrypted_v1) 보관을 위해
// 평문으로 유지한다. 암호화하면 닭-달걀 문제가 발생한다.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive AES 암호화 키를 OS 보안 저장소에 관리한다.
class HiveCipherService {
  /// 보안 저장소에서 마스터 키를 식별하는 키 이름.
  static const _keyName = 'hive_master_key';

  /// 테스트 전용 의존성 주입 심(Seam).
  ///
  /// null 이면 프로덕션 FlutterSecureStorage 인스턴스를 사용한다.
  /// 테스트에서는 원하는 구현체를 주입해 OS 보안 저장소 없이 동작한다.
  @visibleForTesting
  static FlutterSecureStorage? storageOverride;

  /// 프로덕션 FlutterSecureStorage 인스턴스.
  ///
  /// iOS: first_unlock_this_device_only — 재부팅 후 첫 잠금 해제 시부터 접근 가능.
  ///      `this_device`이므로 iCloud 백업/마이그레이션으로 다른 기기로 전파되지 않는다.
  ///      앱 재설치 후 Hive 박스는 초기화되므로 Keychain 잔존 키는 빈 박스를
  ///      암호화하는 데 재활용 — 데이터 손실·손상 없음.
  /// Android: Keystore 기반으로 adb backup 범위에 포함되지 않는다.
  static FlutterSecureStorage get _storage =>
      storageOverride ??
      const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
        aOptions: AndroidOptions.defaultOptions,
      );

  /// 보안 저장소에서 마스터 키를 읽는다.
  ///
  /// 키가 없으면 `Hive.generateSecureKey()`로 32바이트 키를 생성한 뒤
  /// base64 인코딩하여 저장하고 반환한다.
  static Future<List<int>> getOrCreateKey() async {
    final stored = await _storage.read(key: _keyName);
    if (stored != null) {
      return base64.decode(stored);
    }

    // 최초 실행: 새 키 생성 후 저장
    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyName, value: base64.encode(key));
    return key;
  }

  /// `HiveAesCipher`를 반환한다.
  static Future<HiveAesCipher> getCipher() async {
    return HiveAesCipher(await getOrCreateKey());
  }
}
