import 'package:child_life/app/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('config error screen is localized (vi)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      const ConfigErrorApp(message: 'Firebase is not configured for prod'),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Cấu hình môi trường không hợp lệ'),
      findsOneWidget,
    );
    expect(find.textContaining('not configured for prod'), findsOneWidget);
  });

  testWidgets('config error screen is localized (en)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ConfigErrorApp(message: 'x'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Invalid environment configuration'),
      findsOneWidget,
    );
  });
}
