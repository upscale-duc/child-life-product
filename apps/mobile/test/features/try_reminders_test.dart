import 'dart:convert';

import 'package:child_life/features/rhythm/try_reminders.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final l = AppLocalizationsVi();
  final plan = TryReminder(
    contentId: 'act_sing',
    babyId: 'b1',
    title: 'Hát nhẹ khi con thức và tỉnh táo',
    at: DateTime(2026, 10, 24, 19),
  );

  test('a plan rings at its time and asks the next morning at 08:30', () {
    final n = tryReminderNotifications(l, [plan], DateTime(2026, 10, 24, 18));
    expect(n.map((x) => x.fireAt), [
      DateTime(2026, 10, 24, 19),
      DateTime(2026, 10, 25, 8, 30),
    ]);
    expect(n.first.title, l.pv2TryNowTitle);
    expect(n.first.body, plan.title);
    expect(n.last.title, l.pv2TryAskTitle);
    expect(n.last.body, l.pv2TryAskBody(plan.title));
    expect(n.first.id, isNot(n.last.id));
    // A tap opens that activity for that baby.
    expect(tryReminderFromPayload(n.last.payload), (
      babyId: 'b1',
      contentId: 'act_sing',
    ));
    expect(jsonDecode(n.first.payload)['k'], 'try');
  });

  test(
    'past the try time only the morning question is left; after it, nothing',
    () {
      expect(
        tryReminderNotifications(l, [
          plan,
        ], DateTime(2026, 10, 24, 22)).single.fireAt,
        DateTime(2026, 10, 25, 8, 30),
      );
      expect(
        tryReminderNotifications(l, [plan], DateTime(2026, 10, 25, 9)),
        isEmpty,
      );
    },
  );

  test(
    'the store keeps one plan per idea per person, an answer clears it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mine = TryReminderStore(prefs, 'u1');
      await mine.set(plan);
      await mine.set(
        TryReminder(
          contentId: 'act_sing',
          babyId: 'b1',
          title: plan.title,
          at: DateTime(2026, 10, 24, 20, 30),
        ),
      );
      expect(mine.read().values.single.at, DateTime(2026, 10, 24, 20, 30));
      expect(TryReminderStore(prefs, 'u2').read(), isEmpty);
      expect(await mine.clear('act_sing'), isTrue);
      expect(mine.read(), isEmpty);
      expect(await mine.clear('act_sing'), isFalse);
      expect(
        tryReminderClearingValues,
        containsAll(['tried', 'helpful', 'hide']),
      );
      expect(tryReminderClearingValues, isNot(contains('save')));
    },
  );

  test('pruning drops plans whose morning question has passed', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TryReminderStore(await SharedPreferences.getInstance(), 'u1');
    await store.set(plan);
    await store.prune(DateTime(2026, 10, 25, 8));
    expect(store.read(), hasLength(1));
    await store.prune(DateTime(2026, 10, 25, 9));
    expect(store.read(), isEmpty);
  });
}
