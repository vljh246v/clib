// M-7 회귀 테스트: Hive 평문 → AES 암호화 마이그레이션
//
// FlutterSecureStorage는 OS 네이티브 의존성이 있어 단위 테스트에서 직접 사용이
// 불가능하다. HiveCipherService.getCipher() 경로 대신 주입 가능한
// DatabaseService.migrateBoxesForTest() 심(Seam)을 사용한다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

// 아티클 픽스처 헬퍼
Article _makeArticle({required String title, String? url}) {
  return Article()
    ..url = url ?? 'https://example.com/$title'
    ..title = title
    ..thumbnailUrl = null
    ..platform = Platform.etc
    ..topicLabels = ['테스트']
    ..isRead = false
    ..isBookmarked = true
    ..createdAt = DateTime(2024, 6, 1)
    ..memo = 'memo_$title';
}

// 라벨 픽스처 헬퍼
Label _makeLabel(String name) {
  return Label()
    ..name = name
    ..colorValue = 0xFF5BA67D
    ..createdAt = DateTime(2024, 1, 1)
    ..notificationEnabled = false
    ..notificationDays = []
    ..notificationTime = '09:00';
}

// 단위 테스트에서 사용할 간단한 XOR 키 기반 더미 cipher 대신
// 실제 HiveAesCipher를 사용한다 (hive 패키지 자체가 테스트 의존성으로 포함됨).
HiveAesCipher _makeCipher() {
  // 32바이트 고정 키 (테스트 전용)
  final key = List<int>.generate(32, (i) => i + 1);
  return HiveAesCipher(key);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_migration_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());
  });

  tearDown(() async {
    if (Hive.isBoxOpen('articles')) await Hive.box<Article>('articles').close();
    if (Hive.isBoxOpen('labels')) await Hive.box<Label>('labels').close();
    if (Hive.isBoxOpen('preferences')) await Hive.box('preferences').close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('migrateBoxesForTest — 평문 → 암호화 마이그레이션', () {
    test('(M-7) 아티클·라벨 데이터가 암호화 박스로 정확히 이전된다', () async {
      // ARRANGE: 평문 박스에 데이터 시드
      await Hive.openBox('preferences');
      final plainArticles = await Hive.openBox<Article>('articles');
      final plainLabels = await Hive.openBox<Label>('labels');

      final article1 = _makeArticle(title: '아티클1');
      final article2 = _makeArticle(title: '아티클2');
      final label1 = _makeLabel('라벨A');
      await plainArticles.add(article1);
      await plainArticles.add(article2);
      await plainLabels.add(label1);

      expect(plainArticles.length, 2);
      expect(plainLabels.length, 1);

      // 박스 닫기 (migrateBoxesForTest가 재오픈할 것)
      await plainArticles.close();
      await plainLabels.close();

      // ACT: 마이그레이션 실행
      final cipher = _makeCipher();
      await DatabaseService.migrateBoxesForTest(cipher: cipher);

      // ASSERT 1: 암호화 박스에서 데이터 검증
      final encArticles = Hive.box<Article>('articles');
      final encLabels = Hive.box<Label>('labels');

      expect(encArticles.length, 2,
          reason: '아티클 2개가 암호화 박스로 이전되어야 한다');
      expect(encLabels.length, 1,
          reason: '라벨 1개가 암호화 박스로 이전되어야 한다');

      // 내용 검증
      final titles = encArticles.values.map((a) => a.title).toSet();
      expect(titles, containsAll(['아티클1', '아티클2']));
      expect(encLabels.values.first.name, '라벨A');

      // 메모·북마크 등 속성 보존
      final migratedArticle =
          encArticles.values.firstWhere((a) => a.title == '아티클1');
      expect(migratedArticle.isBookmarked, isTrue);
      expect(migratedArticle.memo, 'memo_아티클1');
    });

    test('(M-7) 마이그레이션 완료 후 preferences 플래그가 true로 설정된다', () async {
      // ARRANGE: 빈 평문 박스 준비
      await Hive.openBox('preferences');
      final prefsBox = Hive.box('preferences');
      expect(prefsBox.get('hive_encrypted_v1', defaultValue: false), isFalse);

      await Hive.openBox<Article>('articles');
      await Hive.openBox<Label>('labels');
      await Hive.box<Article>('articles').close();
      await Hive.box<Label>('labels').close();

      // ACT
      await DatabaseService.migrateBoxesForTest(cipher: _makeCipher());

      // ASSERT
      expect(
        prefsBox.get('hive_encrypted_v1', defaultValue: false),
        isTrue,
        reason: '마이그레이션 후 hive_encrypted_v1 플래그가 true 여야 한다',
      );
    });

    test('(M-7) 신규 설치 — 빈 박스도 마이그레이션이 정상 완료된다', () async {
      // ARRANGE: 아무 데이터 없는 신규 설치 시뮬레이션
      await Hive.openBox('preferences');
      await Hive.openBox<Article>('articles');
      await Hive.openBox<Label>('labels');
      await Hive.box<Article>('articles').close();
      await Hive.box<Label>('labels').close();

      // ACT + ASSERT: 예외 없이 완료
      await expectLater(
        DatabaseService.migrateBoxesForTest(cipher: _makeCipher()),
        completes,
      );

      // 빈 암호화 박스가 열려 있어야 함
      expect(Hive.isBoxOpen('articles'), isTrue);
      expect(Hive.isBoxOpen('labels'), isTrue);
      expect(Hive.box<Article>('articles').isEmpty, isTrue);
      expect(Hive.box<Label>('labels').isEmpty, isTrue);
    });

  });
  // NOTE: 추가 테스트(평문 재오픈 차단, init(forTest:true) 플래그)는 환경 의존
  // (path_provider 미목업 / labels box 라이프사이클)으로 단위 테스트 불가.
  // 실기기/통합 테스트로 대체.
}
