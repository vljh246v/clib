// test/services/firestore_service_from_map_test.dart
//
// M-3: articleFromMap / labelFromMap 방어 캐스트 단위 테스트
//
// Platform 전략: unknown enum → Platform.etc 폴백 (article 보존)
// 필수 필드(url, title, createdAt) 누락 → null 반환 (skip)
//
// Timestamp은 cloud_firestore 순수 값 클래스로 Firebase init 불필요.
// Article/Label는 HiveObject이지만 late 필드를 cascade로 세팅하므로
// Hive box 없이도 정상 인스턴스화 가능.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── 공통 픽스처 ──

  /// 유효한 아티클 맵 (모든 필수 필드 포함)
  Map<String, dynamic> validArticleMap() => {
        'url': 'https://example.com/article',
        'title': '테스트 아티클',
        'platform': 'youtube',
        'topicLabels': ['flutter', 'dart'],
        'isRead': false,
        'isBookmarked': true,
        'memo': '메모',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        'deletedAt': null,
      };

  /// 유효한 라벨 맵 (모든 필수 필드 포함)
  Map<String, dynamic> validLabelMap() => {
        'name': '개발',
        'colorValue': 0xFF5BA67D,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        'deletedAt': null,
      };

  // ── articleFromMap ──

  group('articleFromMap', () {
    test('1. 정상 맵 → non-null Article 반환, 필드 매핑 정확', () {
      final map = validArticleMap();
      final article = FirestoreService.articleFromMap(map, 'doc123');

      expect(article, isNotNull);
      expect(article!.firestoreId, 'doc123');
      expect(article.url, 'https://example.com/article');
      expect(article.title, '테스트 아티클');
      expect(article.platform, Platform.youtube);
      expect(article.topicLabels, ['flutter', 'dart']);
      expect(article.isRead, false);
      expect(article.isBookmarked, true);
      expect(article.memo, '메모');
      expect(article.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(article.createdAt, DateTime(2024, 1, 1));
      expect(article.updatedAt, DateTime(2024, 1, 2));
    });

    test('2. url 누락 → null 반환', () {
      final map = validArticleMap()..remove('url');
      final article = FirestoreService.articleFromMap(map, 'doc_no_url');
      expect(article, isNull);
    });

    test('3. title 누락 → null 반환', () {
      final map = validArticleMap()..remove('title');
      final article = FirestoreService.articleFromMap(map, 'doc_no_title');
      expect(article, isNull);
    });

    test('4. 알 수 없는 platform → Platform.etc 폴백, article 반환', () {
      // 전략: unknown platform은 데이터를 보존하고 Platform.etc로 폴백
      final map = validArticleMap();
      map['platform'] = 'unknown_future_platform';
      final article = FirestoreService.articleFromMap(map, 'doc_unknown_platform');

      expect(article, isNotNull);
      expect(article!.platform, Platform.etc);
    });

    test('5. topicLabels 누락 → 빈 리스트로 기본값 처리', () {
      final map = validArticleMap()..remove('topicLabels');
      final article = FirestoreService.articleFromMap(map, 'doc_no_labels');

      expect(article, isNotNull);
      expect(article!.topicLabels, <String>[]);
    });

    test('6. isRead 누락 → false 기본값', () {
      final map = validArticleMap()..remove('isRead');
      final article = FirestoreService.articleFromMap(map, 'doc_no_is_read');

      expect(article, isNotNull);
      expect(article!.isRead, false);
    });

    test('7. createdAt 누락 → null 반환', () {
      final map = validArticleMap()..remove('createdAt');
      final article = FirestoreService.articleFromMap(map, 'doc_no_created_at');
      expect(article, isNull);
    });

    test('8. url이 null → null 반환', () {
      final map = validArticleMap();
      map['url'] = null;
      final article = FirestoreService.articleFromMap(map, 'doc_null_url');
      expect(article, isNull);
    });

    test('9. createdAt이 잘못된 타입(String) → null 반환', () {
      final map = validArticleMap();
      map['createdAt'] = 'not-a-timestamp';
      final article = FirestoreService.articleFromMap(map, 'doc_bad_created_at');
      expect(article, isNull);
    });

    test('10. topicLabels가 null → 빈 리스트로 기본값', () {
      final map = validArticleMap();
      map['topicLabels'] = null;
      final article = FirestoreService.articleFromMap(map, 'doc_null_labels');

      expect(article, isNotNull);
      expect(article!.topicLabels, <String>[]);
    });

    test('11. isBookmarked 누락 → false 기본값', () {
      final map = validArticleMap()..remove('isBookmarked');
      final article = FirestoreService.articleFromMap(map, 'doc_no_bookmark');

      expect(article, isNotNull);
      expect(article!.isBookmarked, false);
    });
  });

  // ── labelFromMap ──

  group('labelFromMap', () {
    test('1. 정상 맵 → non-null Label 반환, 필드 매핑 정확', () {
      final map = validLabelMap();
      final label = FirestoreService.labelFromMap(map, 'label123');

      expect(label, isNotNull);
      expect(label!.firestoreId, 'label123');
      expect(label.name, '개발');
      expect(label.colorValue, 0xFF5BA67D);
      expect(label.createdAt, DateTime(2024, 1, 1));
      expect(label.updatedAt, DateTime(2024, 1, 2));
    });

    test('2. name 누락 → null 반환', () {
      final map = validLabelMap()..remove('name');
      final label = FirestoreService.labelFromMap(map, 'label_no_name');
      expect(label, isNull);
    });

    test('3. colorValue 누락 → null 반환', () {
      final map = validLabelMap()..remove('colorValue');
      final label = FirestoreService.labelFromMap(map, 'label_no_color');
      expect(label, isNull);
    });

    test('4. createdAt 누락 → null 반환', () {
      final map = validLabelMap()..remove('createdAt');
      final label = FirestoreService.labelFromMap(map, 'label_no_created_at');
      expect(label, isNull);
    });

    test('5. colorValue가 잘못된 타입(String) → null 반환', () {
      final map = validLabelMap();
      map['colorValue'] = 'not-an-int';
      final label = FirestoreService.labelFromMap(map, 'label_bad_color');
      expect(label, isNull);
    });
  });

  // ── 호출자 패턴: 유효/무효 혼합 목록 → whereType 필터 ──

  group('호출자 패턴 (listenArticles 방식)', () {
    test('유효 doc 1개 + 무효 doc(url 누락) 1개 → 결과 리스트 1개', () {
      final maps = [
        MapEntry('doc_valid', validArticleMap()),
        MapEntry('doc_invalid', validArticleMap()..remove('url')),
      ];

      // listenArticles가 fix 후 사용하는 패턴과 동일
      final articles = maps
          .map((e) => FirestoreService.articleFromMap(e.value, e.key))
          .whereType<Article>()
          .toList();

      expect(articles.length, 1);
      expect(articles.first.firestoreId, 'doc_valid');
    });

    test('유효 라벨 1개 + 무효 라벨(name 누락) 1개 → 결과 리스트 1개', () {
      final maps = [
        MapEntry('label_valid', validLabelMap()),
        MapEntry('label_invalid', validLabelMap()..remove('name')),
      ];

      final labels = maps
          .map((e) => FirestoreService.labelFromMap(e.value, e.key))
          .whereType<Label>()
          .toList();

      expect(labels.length, 1);
      expect(labels.first.firestoreId, 'label_valid');
    });
  });
}
