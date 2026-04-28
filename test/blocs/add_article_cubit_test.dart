import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:clib/blocs/add_article/add_article_cubit.dart';
import 'package:clib/blocs/add_article/add_article_state.dart';
import 'package:clib/main.dart'
    show articlesChangedNotifier, labelsChangedNotifier;
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';

/// AddArticleCubit 테스트.
///
/// - Hive 격리 path + 어댑터 등록.
/// - `DatabaseService.skipSync = true`로 Firestore 호출 억제.
/// - 실제 `save()`는 `ShareService.processAndSave` → `ScrapingService.scrape`
///   (http 호출)로 이어지므로, 본 테스트에서는 **URL 검증 실패 케이스만** 검증.
///   happy path는 스모크 테스트에서 커버.
void main() {
  const testHivePath = '.dart_tool/test_hive_add_article_cubit';

  setUpAll(() async {
    Hive.init(testHivePath);
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(PlatformAdapter());
    Hive.registerAdapter(LabelAdapter());
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
    DatabaseService.skipSync = true;
  });

  setUp(() async {
    await Hive.box<Article>('articles').clear();
    await Hive.box<Label>('labels').clear();
    articlesChangedNotifier.value = 0;
    labelsChangedNotifier.value = 0;
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  Future<Label> seedLabel(String name) async {
    final l = Label()
      ..name = name
      ..colorValue = 0xFF000000
      ..createdAt = DateTime.now();
    await Hive.box<Label>('labels').add(l);
    return l;
  }

  group('AddArticleState.copyWith', () {
    test('clearUrlError=true는 urlError를 null로 만든다', () {
      const s = AddArticleState(urlError: 'invalid_url');
      expect(s.copyWith(clearUrlError: true).urlError, isNull);
    });

    test('clearLabelError=true는 labelErrorMessage를 null로 만든다', () {
      const s = AddArticleState(labelErrorMessage: 'boom');
      expect(s.copyWith(clearLabelError: true).labelErrorMessage, isNull);
    });

    test('saveFailure=false로 리셋 가능', () {
      const s = AddArticleState(saveFailure: true);
      expect(s.copyWith(saveFailure: false).saveFailure, isFalse);
    });

    test('copyWith는 명시하지 않은 필드를 보존한다', () {
      const s = AddArticleState(
        selectedLabels: {'tech'},
        isSaving: true,
        urlError: 'invalid_url',
      );
      final next = s.copyWith(isSaving: false);
      expect(next.selectedLabels, {'tech'});
      expect(next.urlError, 'invalid_url');
      expect(next.isSaving, isFalse);
    });
  });

  group('AddArticleCubit', () {
    test('생성자에서 labels를 로드한다', () async {
      await seedLabel('tech');
      await seedLabel('news');
      final cubit = AddArticleCubit();
      expect(cubit.state.allLabels.map((l) => l.name), ['news', 'tech']);
      await cubit.close();
    });

    test('toggleLabel은 선택을 추가/제거한다', () async {
      final cubit = AddArticleCubit();
      cubit.toggleLabel('tech');
      expect(cubit.state.selectedLabels, {'tech'});
      cubit.toggleLabel('news');
      expect(cubit.state.selectedLabels, {'tech', 'news'});
      cubit.toggleLabel('tech');
      expect(cubit.state.selectedLabels, {'news'});
      await cubit.close();
    });

    test('save(빈 문자열)은 urlError="invalid_url"을 emit한다', () async {
      final cubit = AddArticleCubit();
      await cubit.save('');
      expect(cubit.state.urlError, 'invalid_url');
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.isDone, isFalse);
      await cubit.close();
    });

    test('save(비정상 URL)은 urlError="invalid_url"을 emit한다', () async {
      final cubit = AddArticleCubit();
      await cubit.save('not a url');
      expect(cubit.state.urlError, 'invalid_url');
      await cubit.close();
    });

    // M-4: URL 스킴 화이트리스트 — 허용되지 않는 스킴 거부
    test('save(javascript: URL)은 urlError="invalid_url"을 emit한다 (M-4)', () async {
      final cubit = AddArticleCubit();
      await cubit.save('javascript:alert(1)');
      expect(cubit.state.urlError, 'invalid_url');
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.isDone, isFalse);
      await cubit.close();
    });

    test('save(intent:// URL)은 urlError="invalid_url"을 emit한다 (M-4)', () async {
      final cubit = AddArticleCubit();
      await cubit.save('intent://attacker.app/x#Intent;end');
      expect(cubit.state.urlError, 'invalid_url');
      await cubit.close();
    });

    test('save(file:// URL)은 urlError="invalid_url"을 emit한다 (M-4)', () async {
      final cubit = AddArticleCubit();
      await cubit.save('file:///etc/passwd');
      expect(cubit.state.urlError, 'invalid_url');
      await cubit.close();
    });

    test('urlInputChanged는 urlError를 해제한다', () async {
      final cubit = AddArticleCubit();
      await cubit.save('');
      expect(cubit.state.urlError, 'invalid_url');
      cubit.urlInputChanged();
      expect(cubit.state.urlError, isNull);
      await cubit.close();
    });

    test('createLabel 중복 실패는 labelErrorMessage 원문을 emit한다', () async {
      await seedLabel('dup');
      final cubit = AddArticleCubit();
      final result = await cubit.createLabel('dup', const Color(0xFF000000));
      expect(result, isNull);
      expect(cubit.state.labelErrorMessage, contains('dup'));
      cubit.clearLabelError();
      expect(cubit.state.labelErrorMessage, isNull);
      await cubit.close();
    });

    test('labelsChangedNotifier 트리거 시 allLabels를 재로드한다', () async {
      final cubit = AddArticleCubit();
      expect(cubit.state.allLabels, isEmpty);
      await seedLabel('tech');
      labelsChangedNotifier.value++;
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.allLabels.map((l) => l.name), ['tech']);
      await cubit.close();
    });
  });
}
