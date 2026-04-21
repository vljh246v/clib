import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';

import 'helpers/hive_bootstrap.dart';

/// 위젯 스모크 테스트.
///
/// 목적: 앱 셸이 Hive + 로컬라이제이션 경로를 크래시 없이 구성할 수 있는지
/// 확인한다. 전체 [ClibApp]은 `Firebase.initializeApp()` / `AuthCubit` /
/// `ShareService`(네이티브 채널)에 의존해 테스트 환경에서 띄울 수 없고,
/// [LibraryScreen] 등 실제 화면은 `CustomPaint`가 포함된 `GridView` +
/// BlocBuilder 조합에서 `pumpAndSettle`/`pump` 모두 수렴하지 않는 이슈가 있어
/// 실화면 렌더는 실기기 회귀 스모크(`pr-11-cleanup.md` §3)로 위임한다.
///
/// Cubit/Bloc 동작은 `test/blocs/*_test.dart`에서 이미 74 케이스로 커버되므로,
/// 여기서는 **Hive 부트스트랩 + `AppLocalizations` delegate 해석**의 최소
/// 경로만 검증한다.
void main() {
  final harness = HiveTestHarness('widget_test');

  setUpAll(() => harness.setUpAll());
  setUp(() => harness.setUp());
  tearDownAll(() => harness.tearDownAll());

  Widget wrap(Widget child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  test('HiveTestHarness 가 3개 박스를 오픈하고 setUp 이 클리어한다', () async {
    expect(Hive.box<Article>('articles').isOpen, isTrue);
    expect(Hive.box<Label>('labels').isOpen, isTrue);
    expect(Hive.box('preferences').isOpen, isTrue);

    await harness.seedArticle(url: 'u1', title: 't1');
    await harness.seedLabel('tech');
    expect(Hive.box<Article>('articles').length, 1);
    expect(Hive.box<Label>('labels').length, 1);

    // 다음 테스트 setUp 이 clear 하는지 아래 테스트에서 검증.
  });

  test('다음 테스트 진입 시 이전 시드는 제거되어 있다', () {
    expect(Hive.box<Article>('articles').isEmpty, isTrue);
    expect(Hive.box<Label>('labels').isEmpty, isTrue);
  });

  testWidgets('AppLocalizations delegate 가 로드되어 한국어 문자열이 해석된다',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return Text(l.library);
            },
          ),
        ),
      ),
    );
    // AppLocalizations delegate 는 `SynchronousFuture` 기반이라 단일 pump 로 해석.
    await tester.pump();

    expect(find.text('보관함'), findsOneWidget);
  });
}
