import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late String testHivePath;

  setUpAll(() async {
    testHivePath =
        '/private/tmp/test_hive_widget_${DateTime.now().microsecondsSinceEpoch}';
    Hive.init(testHivePath);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());
    await Hive.openBox('preferences');
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
  });

  setUp(() async {
    await Hive.box('preferences').clear();
    await Hive.box<Article>('articles').clear();
    await Hive.box<Label>('labels').clear();
    await Hive.box('preferences').put('hasSeenHomeGuide', true);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('앱이 정상적으로 로드되는지 확인', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });
}
