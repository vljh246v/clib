import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';

class DatabaseService {
  static const _boxName = 'articles';
  static const _labelBoxName = 'labels';
  static const _channel = MethodChannel('com.clib.clib/share');

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(PlatformAdapter());
    Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>(_boxName);
    await Hive.openBox<Label>(_labelBoxName);
  }

  static Box<Article> get _box => Hive.box<Article>(_boxName);
  static Box<Label> get _labelBox => Hive.box<Label>(_labelBoxName);

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

  // ── 라벨 CRUD ──

  // 라벨 전체 목록
  static List<Label> getAllLabelObjects() {
    return _labelBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // 라벨 생성
  static Future<Label> createLabel(String name, Color color) async {
    final exists = _labelBox.values.any(
      (l) => l.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) throw Exception('이미 존재하는 라벨입니다: $name');

    final label = Label()
      ..name = name
      ..colorValue = color.toARGB32()
      ..createdAt = DateTime.now();
    await _labelBox.add(label);
    await syncLabelsToAppGroup();
    return label;
  }

  // 라벨 수정
  static Future<void> updateLabel(
    Label label, {
    String? newName,
    Color? newColor,
  }) async {
    final oldName = label.name;

    if (newName != null && newName != oldName) {
      // 중복 체크
      final exists = _labelBox.values.any(
        (l) => l.key != label.key && l.name.toLowerCase() == newName.toLowerCase(),
      );
      if (exists) throw Exception('이미 존재하는 라벨입니다: $newName');

      // 모든 아티클의 라벨명 일괄 업데이트
      for (final article in _box.values) {
        final idx = article.topicLabels.indexOf(oldName);
        if (idx != -1) {
          article.topicLabels[idx] = newName;
          await article.save();
        }
      }
      label.name = newName;
    }

    if (newColor != null) {
      label.colorValue = newColor.toARGB32();
    }

    await label.save();
    await syncLabelsToAppGroup();
  }

  // 라벨 삭제
  static Future<void> deleteLabel(Label label) async {
    // 모든 아티클에서 해당 라벨 제거
    for (final article in _box.values) {
      if (article.topicLabels.remove(label.name)) {
        await article.save();
      }
    }
    await label.delete();
    await syncLabelsToAppGroup();
  }

  // iOS Share Extension용 라벨 동기화
  static Future<void> syncLabelsToAppGroup() async {
    if (!io.Platform.isIOS) return;
    try {
      final payload = _labelBox.values
          .map((l) => {'name': l.name, 'colorValue': l.colorValue})
          .toList();
      await _channel.invokeMethod('syncLabels', payload);
    } on PlatformException {
      // 무시
    }
  }

  // 라벨 이름으로 Label 객체 찾기
  static Label? getLabelByName(String name) {
    try {
      return _labelBox.values.firstWhere(
        (l) => l.name == name,
      );
    } catch (_) {
      return null;
    }
  }

  // ── 라벨 알림 설정 ──

  // 라벨 알림 설정 저장
  static Future<void> updateLabelNotification(
    Label label, {
    required bool enabled,
    required List<int> days,
    required String time,
  }) async {
    label.notificationEnabled = enabled;
    label.notificationDays = days;
    label.notificationTime = time;
    await label.save();
  }

  // 알림 활성 라벨 목록
  static List<Label> getLabelsWithNotification() {
    return _labelBox.values
        .where((l) => l.notificationEnabled && l.notificationDays.isNotEmpty)
        .toList();
  }

  // 아티클의 라벨 업데이트
  static Future<void> updateArticleLabels(
    Article article,
    List<String> newLabels,
  ) async {
    article.topicLabels = newLabels;
    await article.save();
  }

  // 기초 데이터 삽입 (테스트용, 항상 초기화)
  static Future<void> seedData() async {
    await _box.clear();
    await _labelBox.clear();

    // 라벨 시드
    {
      final defaultLabels = {
        'Flutter': const Color(0xFF42A5F5),
        '개발': const Color(0xFF66BB6A),
        'Dart': const Color(0xFF5C6BC0),
        '아키텍처': const Color(0xFFAB47BC),
        'Git': const Color(0xFFEF5350),
        '디자인': const Color(0xFFFFCA28),
      };
      for (final entry in defaultLabels.entries) {
        final label = Label()
          ..name = entry.key
          ..colorValue = entry.value.toARGB32()
          ..createdAt = DateTime.now();
        await _labelBox.add(label);
      }
    }

    final seeds = [
      Article()
        ..url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
        ..title = 'Flutter 상태관리 완벽 가이드 2026'
        ..thumbnailUrl = 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'
        ..platform = Platform.youtube
        ..topicLabels = ['Flutter', '개발']
        ..isRead = false
        ..createdAt = DateTime.now().subtract(const Duration(days: 5)),
      Article()
        ..url = 'https://medium.com/flutter-community/dart-3-patterns'
        ..title = 'Dart 3 패턴 매칭으로 코드 가독성 높이기'
        ..thumbnailUrl = null
        ..platform = Platform.blog
        ..topicLabels = ['Dart', '개발']
        ..isRead = false
        ..createdAt = DateTime.now().subtract(const Duration(days: 3)),
      Article()
        ..url = 'https://velog.io/@dev/clean-architecture-flutter'
        ..title = 'Clean Architecture를 Flutter에 적용하는 실전 방법'
        ..thumbnailUrl = null
        ..platform = Platform.blog
        ..topicLabels = ['Flutter', '아키텍처']
        ..isRead = false
        ..createdAt = DateTime.now().subtract(const Duration(days: 2)),
      Article()
        ..url = 'https://www.youtube.com/watch?v=abc123xyz'
        ..title = '주니어 개발자가 알아야 할 Git 브랜치 전략'
        ..thumbnailUrl = 'https://img.youtube.com/vi/abc123xyz/hqdefault.jpg'
        ..platform = Platform.youtube
        ..topicLabels = ['Git', '개발']
        ..isRead = false
        ..createdAt = DateTime.now().subtract(const Duration(days: 1)),
      Article()
        ..url = 'https://www.instagram.com/p/design_tips_2026'
        ..title = '모바일 UI 디자인 트렌드 2026'
        ..thumbnailUrl = null
        ..platform = Platform.instagram
        ..topicLabels = ['디자인']
        ..isRead = false
        ..createdAt = DateTime.now(),
      Article()
        ..url = 'https://tistory.com/entry/hive-vs-sqflite'
        ..title = 'Flutter 로컬 DB 비교: Hive vs sqflite vs Isar'
        ..thumbnailUrl = null
        ..platform = Platform.blog
        ..topicLabels = ['Flutter', '개발']
        ..isRead = true
        ..createdAt = DateTime.now().subtract(const Duration(days: 7)),
    ];

    for (final article in seeds) {
      await _box.add(article);
    }
  }
}
