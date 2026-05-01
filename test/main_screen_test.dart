import 'package:clib/main.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late String testHivePath;

  setUpAll(() async {
    testHivePath =
        '/private/tmp/test_hive_main_screen_${DateTime.now().microsecondsSinceEpoch}';
    Hive.init(testHivePath);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlatformAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LabelAdapter());
    await Hive.openBox('preferences');
    await Hive.openBox<Article>('articles');
    await Hive.openBox<Label>('labels');
  });

  setUp(() async {
    notificationLabelTapNotifier.value = null;
    await Hive.box('preferences').clear();
    await Hive.box<Article>('articles').clear();
    await Hive.box<Label>('labels').clear();
    await Hive.box('preferences').put('hasSeenHomeGuide', true);
  });

  tearDown(() {
    notificationLabelTapNotifier.value = null;
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('label notification tap returns to the main home route', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainScreen(),
      ),
    );
    await tester.pump();

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('details route')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('details route'), findsOneWidget);

    notificationLabelTapNotifier.value = const NotificationLabelTapRequest(
      labelKey: 1,
      requestId: 1,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('details route'), findsNothing);
    expect(find.byType(MainScreen), findsOneWidget);
  });

  testWidgets(
    'label notification tap scrolls the selected label chip into view',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final targetKey = (await tester.runAsync<int>(() async {
        final labelBox = Hive.box<Label>('labels');
        for (var i = 0; i < 18; i++) {
          await labelBox.add(
            Label()
              ..name = 'label-$i'
              ..colorValue = 0xFF888888
              ..createdAt = DateTime.now(),
          );
        }
        final target = Label()
          ..name = 'zz-target'
          ..colorValue = 0xFF888888
          ..createdAt = DateTime.now();
        return await labelBox.add(target);
      }))!;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pump();

      notificationLabelTapNotifier.value = NotificationLabelTapRequest(
        labelKey: targetKey,
        requestId: 1,
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final targetChip = find.text('zz-target');
      expect(targetChip, findsOneWidget);
      final chipLeft = tester.getTopLeft(targetChip).dx;
      final chipRight = tester.getTopRight(targetChip).dx;

      expect(chipLeft, greaterThanOrEqualTo(0));
      expect(chipRight, lessThanOrEqualTo(360));
    },
  );
}
