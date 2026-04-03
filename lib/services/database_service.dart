import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';

class DatabaseService {
  static const _boxName = 'articles';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(PlatformAdapter());
    await Hive.openBox<Article>(_boxName);
  }

  static Box<Article> get _box => Hive.box<Article>(_boxName);

  // 아티클 저장
  static Future<int> saveArticle(Article article) async {
    return _box.add(article);
  }

  // 미읽은 아티클 목록 (홈 스와이프용)
  static List<Article> getUnreadArticles() {
    return _box.values
        .where((a) => !a.isRead)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // 라벨별 아티클 목록
  static List<Article> getArticlesByLabel(String label) {
    return _box.values
        .where((a) => a.topicLabels.contains(label))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // 읽음 처리
  static Future<void> markAsRead(Article article) async {
    article.isRead = true;
    await article.save();
  }

  // 모든 라벨 목록
  static List<String> getAllLabels() {
    final labels = <String>{};
    for (final article in _box.values) {
      labels.addAll(article.topicLabels);
    }
    return labels.toList()..sort();
  }

  // 라벨별 통계
  static ({int total, int read}) getLabelStats(String label) {
    final articles = _box.values
        .where((a) => a.topicLabels.contains(label))
        .toList();
    final read = articles.where((a) => a.isRead).length;
    return (total: articles.length, read: read);
  }
}
