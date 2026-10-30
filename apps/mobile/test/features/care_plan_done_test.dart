import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/care_plan/care_plan_done.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

// Cùng Chăm Con 10 Vừa xong (Figma 1353:22683): a heart and a thanks for what Ba did (N2 → N3).
final _l = lookupAppLocalizations(const Locale('vi'));

/// Ba (Minh) gave the bath at 18:42; Cô Lan already sent a heart.
CarePlanItem doneBath() => planItem(
  CarePlanTask.bath,
  '18:30',
  who: [minh.uid],
  status: CarePlanStatus.done,
  doneBy: minh.uid,
  doneAt: DateTime.utc(2026, 10, 28, 11, 42),
  reactions: {lan.uid: const CarePlanReaction(heart: true)},
);

Future<FakeCarePlanRepository> _pump(
  WidgetTester tester,
  CarePlanItem item, {
  dynamic me,
}) async {
  final repo = FakeCarePlanRepository();
  await pumpRouted(
    tester,
    CarePlanDoneScreen(date: carePlanToday, itemId: item.id),
    viewport: const Size(375, 812),
    overrides: [
      ...familyOverrides(me: me ?? mai, now: carePlanNow, carePlan: false),
      ...carePlanOverrides(
        days: {
          carePlanToday: [...planFresh(), item],
        },
        repo: repo,
      ),
    ],
  );
  await tester.pumpAndSettle();
  return repo;
}

ClButton _send(WidgetTester tester) =>
    tester.widget<ClButton>(find.byKey(const Key('cp_react_send')));

void main() {
  testWidgets('Mẹ sends Ba a heart and "Ba giỏi quá"', (tester) async {
    final item = doneBath();
    final repo = await _pump(tester, item);
    expect(find.text(_l.cpDidLine('Ba', 'bath', 'Teddy')), findsOneWidget);
    expect(find.text('18:42'), findsOneWidget);
    // Nothing chosen yet: nothing to send.
    expect(_send(tester).onPressed, isNull);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cp_react_heart')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cp_thanks_proud')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cp_react_send')));
    await tester.pumpAndSettle();
    final (name, args) = repo.calls.single;
    expect(name, 'react');
    expect(args, {'itemId': item.id, 'heart': true, 'thanks': 'proud'});
    expect(find.text(_l.cpSentTo('Ba')), findsOneWidget);
  });

  testWidgets('Ba sees the hearts on his own task, nothing to send', (
    tester,
  ) async {
    await _pump(tester, doneBath(), me: minh);
    expect(find.text(_l.cpHeartsFrom(1)), findsOneWidget);
    expect(find.byKey(const Key('cp_react_send')), findsNothing);
  });

  testWidgets('a task no longer done says so', (tester) async {
    await _pump(tester, planItem(CarePlanTask.bath, '18:30', who: [minh.uid]));
    expect(find.text(_l.cpDoneMissing), findsOneWidget);
  });
}
