import 'dart:convert';

import 'package:child_life/core/appearance/appearance.dart';
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
    silent: false,
    hint: false,
  );
  final vi = lookupAppLocalizations(const Locale('vi'));
  // Light all day, so the time of day never makes an ask silent here.
  const day = AppearanceSettings(
    theme: ThemePreference.light,
    nightCareScheduleEnabled: false,
  );

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
          wakeCheckSecondPlan(first.payload, at, day)!,
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
          silent: false,
          hint: false,
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

  group('the first ask says where to turn it off (§7.1)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'once: the hinted ask is remembered, then later asks go without',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final now = plan.start;
        expect(wakeCheckHint(prefs, now), isTrue);
        final first = wakeCheckNotification(vi, (
          babyId: plan.babyId,
          sessionId: plan.sessionId,
          start: plan.start,
          fireAt: plan.fireAt,
          second: false,
          againMinutes: 45,
          until: plan.until,
          silent: false,
          hint: true,
        ));
        expect(
          first.body,
          'Bé đã ngủ 1 giờ 45 phút. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé. '
          'Tắt lời hỏi này trong Hồ sơ › Thông báo.',
        );
        await wakeCheckRememberHint(prefs, [first], now);
        // Before it rings it is still the one with the hint; after, none.
        expect(wakeCheckHint(prefs, now), isTrue);
        expect(
          wakeCheckHint(prefs, plan.fireAt.add(const Duration(minutes: 1))),
          isFalse,
        );
        // A plain ask does not forget a hint that already rang.
        await wakeCheckRememberHint(prefs, [
          wakeCheckNotification(vi, plan),
        ], plan.fireAt.add(const Duration(hours: 1)));
        expect(
          wakeCheckHint(prefs, plan.fireAt.add(const Duration(hours: 1))),
          isFalse,
        );
      },
    );

    test(
      'a hinted ask cancelled before it rang hints again next time',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final first = wakeCheckNotification(vi, (
          babyId: plan.babyId,
          sessionId: plan.sessionId,
          start: plan.start,
          fireAt: plan.fireAt,
          second: false,
          againMinutes: 45,
          until: plan.until,
          silent: false,
          hint: true,
        ));
        await wakeCheckRememberHint(prefs, [first], plan.start);
        // The timer was stopped: nothing is scheduled any more.
        await wakeCheckRememberHint(
          prefs,
          const [],
          plan.start.add(const Duration(minutes: 30)),
        );
        expect(
          wakeCheckHint(prefs, plan.fireAt.add(const Duration(hours: 2))),
          isTrue,
        );
      },
    );
  });

  group('Night care: no sound or vibration (§7.1)', () {
    final evening = DateTime(2026, 10, 25, 22);
    final noon = DateTime(2026, 10, 25, 12);

    test(
      'the Night care schedule at the time it rings, or the "Tối" theme',
      () {
        const schedule = AppearanceSettings(theme: ThemePreference.light);
        expect(wakeCheckSilent(schedule, evening), isTrue);
        expect(wakeCheckSilent(schedule, noon), isFalse);
        expect(wakeCheckSilent(day, evening), isFalse);
        expect(
          wakeCheckSilent(
            const AppearanceSettings(
              theme: ThemePreference.dark,
              nightCareScheduleEnabled: false,
            ),
            noon,
          ),
          isTrue,
        );
        // "Tự động" follows the system look, unknown at that hour.
        expect(
          wakeCheckSilent(
            const AppearanceSettings(nightCareScheduleEnabled: false),
            noon,
          ),
          isFalse,
        );
      },
    );

    test('a silent ask is told apart, and the second ask keeps the rule', () {
      final n = wakeCheckNotification(vi, (
        babyId: plan.babyId,
        sessionId: plan.sessionId,
        start: plan.start,
        fireAt: plan.fireAt,
        second: false,
        againMinutes: 45,
        until: plan.until,
        silent: true,
        hint: false,
      ));
      expect(n.silent, isTrue);
      expect((jsonDecode(n.payload) as Map)['q'], 1);
      expect(wakeCheckNotification(vi, plan).silent, isFalse);
      const schedule = AppearanceSettings(theme: ThemePreference.light);
      expect(wakeCheckSecondPlan(n.payload, evening, schedule)!.silent, isTrue);
      expect(wakeCheckSecondPlan(n.payload, noon, schedule)!.silent, isFalse);
    });
  });
}
