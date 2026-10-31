import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Lumi L5 (album): the photo sheet offers Kỷ niệm's own pick and compose to a Cùng nuôi; the
/// photo is never sent to Lumi, so nothing is quoted.
void main() {
  Future<FakeAssistantRepository> open(
    WidgetTester tester, {
    bool parent = true,
  }) async {
    final repo = FakeAssistantRepository();
    await pumpRouted(
      tester,
      AssistantChatScreen(scopeKey: teddyScope.key),
      overrides: assistantOverrides(
        repo: repo,
        me: parent ? null : lan,
        images: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ảnh').last);
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('a Cùng nuôi sees "Lưu ảnh của bé vào Kỷ niệm"', (tester) async {
    final repo = await open(tester);
    expect(find.text('Gửi ảnh để trợ lý đọc'), findsOneWidget);
    expect(find.text('Lưu ảnh của bé vào Kỷ niệm'), findsOneWidget);
    expect(find.text('Không gửi cho Lumi đọc, không tốn lượt'), findsOneWidget);
    await tester.tap(find.text('Lưu ảnh của bé vào Kỷ niệm'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi ảnh để trợ lý đọc'), findsNothing);
    expect(repo.named('quoteTask'), isEmpty);
  });

  testWidgets('a caregiver does not', (tester) async {
    await open(tester, parent: false);
    expect(find.text('Gửi ảnh để trợ lý đọc'), findsOneWidget);
    expect(find.text('Lưu ảnh của bé vào Kỷ niệm'), findsNothing);
  });
}
