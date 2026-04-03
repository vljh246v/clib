import 'package:flutter_test/flutter_test.dart';
import 'package:clib/main.dart';

void main() {
  testWidgets('앱이 정상적으로 로드되는지 확인', (WidgetTester tester) async {
    await tester.pumpWidget(const ClibApp());

    // 하단 네비게이션 바 확인
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('보관함'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
