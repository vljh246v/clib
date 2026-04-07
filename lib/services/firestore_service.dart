import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';

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

  static Article articleFromMap(Map<String, dynamic> map, String docId) {
    return Article()
      ..firestoreId = docId
      ..url = map['url'] as String
      ..title = map['title'] as String
      ..thumbnailUrl = map['thumbnailUrl'] as String?
      ..platform = Platform.values.byName(map['platform'] as String)
      ..topicLabels = List<String>.from(map['topicLabels'] as List)
      ..isRead = map['isRead'] as bool
      ..isBookmarked = map['isBookmarked'] as bool? ?? false
      ..memo = map['memo'] as String?
      ..createdAt = (map['createdAt'] as Timestamp).toDate()
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

  static Label labelFromMap(Map<String, dynamic> map, String docId) {
    return Label()
      ..firestoreId = docId
      ..name = map['name'] as String
      ..colorValue = map['colorValue'] as int
      ..createdAt = (map['createdAt'] as Timestamp).toDate()
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

  // ── Snapshot Listeners ──

  static Stream<List<Article>> listenArticles(String uid) {
    return _articlesRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => articleFromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Stream<List<Label>> listenLabels(String uid) {
    return _labelsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => labelFromMap(doc.data(), doc.id))
          .toList();
    });
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

      for (final item in chunk) {
        if (item.article != null) {
          final docRef = _articlesRef(uid).doc();
          batch.set(docRef, articleToMap(item.article!));
          item.article!.firestoreId = docRef.id;
        } else if (item.label != null) {
          final docRef = _labelsRef(uid).doc();
          batch.set(docRef, labelToMap(item.label!));
          item.label!.firestoreId = docRef.id;
        }
      }

      await batch.commit();
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
