import 'dart:convert';

import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/rhythm/wake_check.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final start = DateTime.utc(2026, 10, 25, 2);
  final plan = (
    babyId: 'b_teddy',
    sessionId: 'a' * 32,
    start: start,
    fireAt: start.add(const Duration(minutes: 105)),
    second: false,
    againMinutes: 45,
    until: start.add(const Duration(hours: 5)),
  );
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('L6 words: the time asleep, no baby name, never a verdict', () {
    final vi = wakeCheckNotification(
      lookupAppLocalizations(const Locale('vi')),
      plan,
    );
    expect(vi.title, 'Bé dậy chưa?');
    expect(
      vi.body,
      'Bé đã ngủ 1 giờ 45 phút. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé.',
    );
    expect(vi.body, isNot(contains('Teddy')));
    final en = wakeCheckNotification(
      lookupAppLocalizations(const Locale('en')),
      plan,
    );
    expect(en.title, 'Is your baby awake?');
    expect(en.fireAt, plan.fireAt);
  });

  test('a tap finds its baby; other payloads are not ours', () {
    final n = wakeCheckNotification(
      lookupAppLocalizations(const Locale('vi')),
      plan,
    );
    expect(wakeCheckOfPayload(n.payload), 'b_teddy');
    expect(wakeCheckOfPayload('{"k":"reminder","b":"b_teddy"}'), isNull);
    expect(wakeCheckOfPayload('not json'), isNull);
  });

  test('ids stay apart from reminders, the digest and Nhịp lớn lên', () {
    for (final id in ['b_teddy', 'b_na', 'b_${'f' * 28}']) {
      final n = wakeCheckNotificationId(id);
      expect(n, greaterThanOrEqualTo((1 << 28) + 0x100));
      expect(n, lessThan(1 << 29));
    }
  });

  group('"Vẫn ngủ" (lumi-plan §7.1)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'the first ask offers three buttons and carries what asking again needs',
      () {
        final n = wakeCheckNotification(vi, plan);
        expect(n.buttons, NotificationButtons.wakeCheck);
        expect(wakeCheckSessionOfPayload(n.payload), 'a' * 32);
        final json = jsonDecode(n.payload) as Map;
        expect(json['g'], 45);
        expect(json.containsKey('n'), isFalse);
      },
    );

    test(
      'asks once more, the same notification the app would schedule',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final first = wakeCheckNotification(vi, plan);
        final tapped = plan.fireAt.add(const Duration(minutes: 5));
        final at = await wakeCheckSnooze(prefs, first.payload, tapped);
        expect(at, tapped.add(const Duration(minutes: 45)));
        expect(
          prefs.getInt('wakeCheck.again.${'a' * 32}'),
          at!.millisecondsSinceEpoch,
        );
        final background = wakeCheckNotification(
          vi,
          wakeCheckSecondPlan(first.payload, at)!,
        );
        // The app's own plan after a reload: the same payload, so its sync keeps it.
        final app = wakeCheckNotification(vi, (
          babyId: plan.babyId,
          sessionId: plan.sessionId,
          start: plan.start,
          fireAt: at,
          second: true,
          againMinutes: 0,
          until: null,
        ));
        expect(background.payload, app.payload);
        expect(background.id, first.id);
        expect(background.buttons, NotificationButtons.wakeCheckLast);
        expect(
          background.body,
          'Bé đã ngủ 2 giờ 35 phút. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé.',
        );
        // Never a third ask.
        expect(await wakeCheckSnooze(prefs, background.payload, at), isNull);
      },
    );

    test('no second ask past quiet hours or the night', () async {
      final prefs = await SharedPreferences.getInstance();
      final first = wakeCheckNotification(vi, plan);
      expect(
        await wakeCheckSnooze(
          prefs,
          first.payload,
          plan.until.subtract(const Duration(minutes: 30)),
        ),
        isNull,
      );
      expect(prefs.getKeys(), isEmpty);
    });

    test('a newer snooze replaces the old session', () async {
      SharedPreferences.setMockInitialValues({'wakeCheck.again.old': 1});
      final prefs = await SharedPreferences.getInstance();
      await wakeCheckSnooze(
        prefs,
        wakeCheckNotification(vi, plan).payload,
        plan.fireAt,
      );
      expect(prefs.getKeys(), {'wakeCheck.again.${'a' * 32}'});
    });
  });
}
