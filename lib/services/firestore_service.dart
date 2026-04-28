import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/utils/app_logger.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── 컬렉션 참조 ──

  static CollectionReference<Map<String, dynamic>> _articlesRef(String uid) =>
      _db.collection('users').doc(uid).collection('articles');

  static CollectionReference<Map<String, dynamic>> _labelsRef(String uid) =>
      _db.collection('users').doc(uid).collection('labels');

  // ── Article 변환 ──

  static Map<String, dynamic> articleToMap(Article article) {
    return {
      'url': article.url,
      'title': article.title,
      'thumbnailUrl': article.thumbnailUrl,
      'platform': article.platform.name,
      'topicLabels': article.topicLabels,
      'isRead': article.isRead,
      'isBookmarked': article.isBookmarked,
      'memo': article.memo,
      'createdAt': Timestamp.fromDate(article.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'deletedAt': article.deletedAt != null
          ? Timestamp.fromDate(article.deletedAt!)
          : null,
    };
  }

  /// Firestore 문서 맵을 [Article]로 변환한다.
  ///
  /// 필수 필드(url, title, createdAt)가 누락·타입 불일치인 경우 null을 반환하고
  /// [docId]와 함께 로그를 남긴다. 한 doc의 스키마 위반이 전체 동기화 stream을
  /// 중단시키지 않도록 null-skip 전략을 사용한다.
  ///
  /// Platform: byName 실패 시 [Platform.etc]로 폴백 (article 보존).
  static Article? articleFromMap(Map<String, dynamic> map, String docId) {
    // 필수 필드 검증 — 누락·타입 불일치 시 null 반환
    final url = map['url'] as String?;
    if (url == null) {
      log('articleFromMap: url 필드 누락 (docId=$docId)');
      return null;
    }

    final title = map['title'] as String?;
    if (title == null) {
      log('articleFromMap: title 필드 누락 (docId=$docId)');
      return null;
    }

    final createdAtTs = map['createdAt'];
    if (createdAtTs is! Timestamp) {
      log('articleFromMap: createdAt 필드 누락 또는 타입 불일치 (docId=$docId)');
      return null;
    }

    // Platform: unknown enum 값은 Platform.etc로 폴백
    Platform platform;
    try {
      final platformName = map['platform'] as String?;
      if (platformName == null) throw ArgumentError('platform null');
      platform = Platform.values.byName(platformName);
    } catch (_) {
      log('articleFromMap: 알 수 없는 platform 값, Platform.etc로 폴백 (docId=$docId)');
      platform = Platform.etc;
    }

    // 선택 필드 — 안전한 캐스트 + 기본값
    final topicLabels =
        (map['topicLabels'] as List?)?.cast<String>() ?? <String>[];
    final isRead = map['isRead'] as bool? ?? false;
    final isBookmarked = map['isBookmarked'] as bool? ?? false;

    return Article()
      ..firestoreId = docId
      ..url = url
      ..title = title
      ..thumbnailUrl = map['thumbnailUrl'] as String?
      ..platform = platform
      ..topicLabels = topicLabels
      ..isRead = isRead
      ..isBookmarked = isBookmarked
      ..memo = map['memo'] as String?
      ..createdAt = createdAtTs.toDate()
      ..updatedAt = (map['updatedAt'] as Timestamp?)?.toDate()
      ..deletedAt = (map['deletedAt'] as Timestamp?)?.toDate();
  }

  // ── Label 변환 ──

  static Map<String, dynamic> labelToMap(Label label) {
    return {
      'name': label.name,
      'colorValue': label.colorValue,
      'createdAt': Timestamp.fromDate(label.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'deletedAt': label.deletedAt != null
          ? Timestamp.fromDate(label.deletedAt!)
          : null,
    };
  }

  /// Firestore 문서 맵을 [Label]로 변환한다.
  ///
  /// 필수 필드(name, colorValue, createdAt)가 누락·타입 불일치인 경우 null을 반환하고
  /// [docId]와 함께 로그를 남긴다.
  static Label? labelFromMap(Map<String, dynamic> map, String docId) {
    // 필수 필드 검증
    final name = map['name'] as String?;
    if (name == null) {
      log('labelFromMap: name 필드 누락 (docId=$docId)');
      return null;
    }

    // int? 캐스트는 null만 허용하므로 잘못된 타입(예: String)은 is int로 사전 검증
    final colorRaw = map['colorValue'];
    if (colorRaw is! int) {
      log('labelFromMap: colorValue 필드 누락 또는 타입 불일치 (docId=$docId)');
      return null;
    }
    final colorValue = colorRaw;

    final createdAtTs = map['createdAt'];
    if (createdAtTs is! Timestamp) {
      log('labelFromMap: createdAt 필드 누락 또는 타입 불일치 (docId=$docId)');
      return null;
    }

    return Label()
      ..firestoreId = docId
      ..name = name
      ..colorValue = colorValue
      ..createdAt = createdAtTs.toDate()
      ..updatedAt = (map['updatedAt'] as Timestamp?)?.toDate()
      ..deletedAt = (map['deletedAt'] as Timestamp?)?.toDate();
  }

  // ── Article CRUD ──

  static Future<String> uploadArticle(String uid, Article article) async {
    if (article.firestoreId != null) {
      await _articlesRef(uid)
          .doc(article.firestoreId)
          .set(articleToMap(article), SetOptions(merge: true));
      return article.firestoreId!;
    } else {
      final docRef = await _articlesRef(uid).add(articleToMap(article));
      return docRef.id;
    }
  }

  static Future<void> updateArticleFields(
    String uid,
    String firestoreId,
    Map<String, dynamic> fields,
  ) async {
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _articlesRef(uid).doc(firestoreId).update(fields);
  }

  static Future<void> softDeleteArticle(String uid, String firestoreId) async {
    await _articlesRef(uid).doc(firestoreId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Label CRUD ──

  static Future<String> uploadLabel(String uid, Label label) async {
    if (label.firestoreId != null) {
      await _labelsRef(uid)
          .doc(label.firestoreId)
          .set(labelToMap(label), SetOptions(merge: true));
      return label.firestoreId!;
    } else {
      final docRef = await _labelsRef(uid).add(labelToMap(label));
      return docRef.id;
    }
  }

  static Future<void> updateLabelFields(
    String uid,
    String firestoreId,
    Map<String, dynamic> fields,
  ) async {
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _labelsRef(uid).doc(firestoreId).update(fields);
  }

  static Future<void> softDeleteLabel(String uid, String firestoreId) async {
    await _labelsRef(uid).doc(firestoreId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Batch Update ──

  /// 여러 아티클의 필드를 한 번의 batch로 업데이트
  static Future<void> batchUpdateArticleFields(
    String uid,
    List<Article> articles,
    Map<String, dynamic> fields,
  ) async {
    final updates = <String, dynamic>{
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    const maxBatchSize = 450;
    for (var i = 0; i < articles.length; i += maxBatchSize) {
      final chunk = articles.sublist(
        i,
        i + maxBatchSize > articles.length ? articles.length : i + maxBatchSize,
      );
      final batch = _db.batch();
      for (final article in chunk) {
        if (article.firestoreId == null) continue;
        batch.update(_articlesRef(uid).doc(article.firestoreId), updates);
      }
      await batch.commit();
    }
  }

  // ── Snapshot Listeners ──

  static Stream<List<Article>> listenArticles(String uid) {
    return _articlesRef(uid).snapshots().map((snapshot) {
      // null 반환된 doc(필수 필드 이상)은 whereType으로 필터링해 stream 무결성 유지
      return snapshot.docs
          .map((doc) => articleFromMap(doc.data(), doc.id))
          .whereType<Article>()
          .toList();
    });
  }

  static Stream<List<Label>> listenLabels(String uid) {
    return _labelsRef(uid).snapshots().map((snapshot) {
      // null 반환된 doc(필수 필드 이상)은 whereType으로 필터링해 stream 무결성 유지
      return snapshot.docs
          .map((doc) => labelFromMap(doc.data(), doc.id))
          .whereType<Label>()
          .toList();
    });
  }

  // ── 사용자 데이터 전체 삭제 (계정 삭제 시) ──

  /// 사용자의 articles, labels 서브컬렉션 문서를 모두 영구 삭제한다.
  /// Firestore batch 최대 500 제한을 고려해 청크 처리한다.
  static Future<void> deleteAllUserData(String uid) async {
    await _deleteCollection(_articlesRef(uid));
    await _deleteCollection(_labelsRef(uid));
    // users/{uid} 문서 자체도 삭제
    await _db.collection('users').doc(uid).delete();
  }

  static Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    const batchSize = 450;
    while (true) {
      final snapshot = await ref.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ── 일괄 업로드 (첫 로그인 시) ──

  /// Firestore batch 최대 500 operations 제한을 고려한 청크 업로드
  static Future<void> batchUpload(
    String uid,
    List<Article> articles,
    List<Label> labels,
  ) async {
    const maxBatchSize = 450;

    // 아티클 + 라벨을 합쳐서 450개씩 청크 처리
    final allItems = <_BatchItem>[
      ...articles.map((a) => _BatchItem.article(a)),
      ...labels.map((l) => _BatchItem.label(l)),
    ];

    for (var i = 0; i < allItems.length; i += maxBatchSize) {
      final chunk = allItems.sublist(
        i,
        i + maxBatchSize > allItems.length ? allItems.length : i + maxBatchSize,
      );
      final batch = _db.batch();

      // docRef를 먼저 생성하고 batch에 추가 (commit 전에 firestoreId 설정하지 않음)
      final docRefs = <int, DocumentReference>{}; // chunk index → docRef
      for (var j = 0; j < chunk.length; j++) {
        final item = chunk[j];
        if (item.article != null) {
          final docRef = _articlesRef(uid).doc();
          batch.set(docRef, articleToMap(item.article!));
          docRefs[j] = docRef;
        } else if (item.label != null) {
          final docRef = _labelsRef(uid).doc();
          batch.set(docRef, labelToMap(item.label!));
          docRefs[j] = docRef;
        }
      }

      await batch.commit();

      // commit 성공 후에만 firestoreId 설정
      for (var j = 0; j < chunk.length; j++) {
        final item = chunk[j];
        final docRef = docRefs[j];
        if (docRef == null) continue;
        if (item.article != null) {
          item.article!.firestoreId = docRef.id;
        } else if (item.label != null) {
          item.label!.firestoreId = docRef.id;
        }
      }
    }

    // Hive에 firestoreId 반영
    for (final article in articles) {
      if (article.isInBox) await article.save();
    }
    for (final label in labels) {
      if (label.isInBox) await label.save();
    }
  }
}

class _BatchItem {
  final Article? article;
  final Label? label;

  _BatchItem.article(this.article) : label = null;
  _BatchItem.label(this.label) : article = null;
}
