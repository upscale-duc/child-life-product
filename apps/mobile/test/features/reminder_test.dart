import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/reminder_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rule_fixtures.dart';
import '../helpers/router_pump.dart';

/// Nhắc nhở opens on "Một lần" (the dated reminders); a tap on it changes nothing.
Future<void> _oneTime(WidgetTester tester) async {
  await tester.tap(find.text('Một lần'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(ensureTimeZones);

  group('model (R-093, D-032)', () {
    test('groups: overdue oldest first, upcoming soonest first, done', () {
      final g = groupReminders(mockReminders(), careNow);
      expect(g.overdue.map((r) => r.title), ['Mua sữa công thức']);
      expect(g.upcoming.map((r) => r.title), [
        'Tiêm 6 trong 1',
        'Tái khám rốn',
      ]);
      expect(g.done.map((r) => r.title), ['Khám 1 tháng']);
    });

    test('fires once at due time minus "Báo trước"', () {
      final r = mockReminders()[1];
      expect(r.fireAt, r.dueAt.subtract(const Duration(hours: 1)));
    });

    test('an edit sends the due time only when it changed', () {
      final r = mockReminders().first;
      expect(
        r.copyWith(title: 'x').toEditJson(r, 'u_mai'),
        isNot(contains('dueAt')),
      );
      final moved = r.copyWith(dueAt: r.dueAt.add(const Duration(days: 3)));
      expect(moved.toEditJson(r, 'u_mai'), contains('dueAt'));
    });

    test('notification ids and payloads are stable and round-trip', () {
      final r = mockReminders()[1];
      expect(notificationIdOf(r.id), notificationIdOf(r.id));
      expect(notificationIdOf(r.id), lessThan(1 << 28));
      expect(reminderOfPayload(reminderPayload(r, 't', 'b')), (r.babyId, r.id));
      expect(reminderOfPayload('{"k":"other"}'), isNull);
      expect(reminderOfPayload('not json'), isNull);
    });
  });

  group('8a / 12f list', () {
    testWidgets('groups with Figma metas; "+ Nhắc việc mới" for parents', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: careOverrides(),
      );
      await _oneTime(tester);
      expect(find.text('Quá hạn'), findsOneWidget);
      expect(find.text('Quá hạn · hôm qua 18:00 · Ba tạo'), findsOneWidget);
      expect(find.text('Thứ Bảy, 10 thg 10 · 08:30 · Bạn tạo'), findsOneWidget);
      expect(find.text('Ba đánh dấu xong · 6 thg 10'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Nhắc việc mới'), 200);
      expect(find.text('Nhắc việc mới'), findsOneWidget);
    });

    testWidgets('the ring marks done, with undo', (tester) async {
      final repo = FakeReminderRepository();
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: mockReminders(),
          reminderRepo: repo,
          now: careNow,
        ),
      );
      await _oneTime(tester);
      await tester.tap(find.bySemanticsLabel('Đánh dấu xong: Tiêm 6 trong 1'));
      await tester.pump();
      expect(repo.done.single.$1.title, 'Tiêm 6 trong 1');
      expect(repo.done.single.$2, isTrue);
      expect(find.text('Đã đánh dấu xong'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      expect(repo.done.last.$2, isFalse);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('caregivers: role note, no create, mark done only (12f)', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          me: lan,
          reminders: mockReminders(),
          reminderRepo: repo,
          now: careNow,
        ),
      );
      await _oneTime(tester);
      expect(
        find.text('Ba mẹ tạo nhắc việc. Bạn xem và đánh dấu Xong.'),
        findsOneWidget,
      );
      expect(find.text('Nhắc việc mới'), findsNothing);
      // Someone else's done cannot be undone by a caregiver (D-030).
      await tester.tap(find.bySemanticsLabel('Bỏ đánh dấu xong: Khám 1 tháng'));
      await tester.pump();
      expect(repo.done, isEmpty);
      await tester.tap(find.bySemanticsLabel('Đánh dấu xong: Tái khám rốn'));
      await tester.pump();
      expect(repo.done.single.$2, isTrue);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('8d: notifications off on the device that holds them', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: mockReminders(),
          notifications: FakeReminderNotifications(on: false),
          now: careNow,
        ),
        prefs: const {'reminders.notificationsAsked': true},
      );
      await _oneTime(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Đã lưu nhắc việc. Chưa bật thông báo trên máy này.'),
        findsOneWidget,
      );
      expect(find.text('Cài đặt'), findsOneWidget);
    });
  });

  group('8b / 8c create', () {
    testWidgets('needs a title; saves on this device, then asks once (R-092)', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      final notifications = FakeReminderNotifications(on: false);
      final (_, container) = await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: const [],
          reminderRepo: repo,
          notifications: notifications,
          now: careNow,
        ),
      );
      await _oneTime(tester);
      await tester.tap(find.text('Nhắc việc mới'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Theo giờ của Teddy (GMT+7). '
          'Gia đình thấy nhắc việc trong app. '
          'Thông báo chỉ được đặt trên máy tạo nhắc việc.',
        ),
        findsOneWidget,
      );
      expect(find.text('1 giờ'), findsOneWidget);
      await tester.tap(find.text('Lưu nhắc việc'));
      await tester.pump();
      expect(find.text('Nhập việc cần nhớ.'), findsOneWidget);
      expect(repo.created, isEmpty);

      await tester.enterText(find.byType(EditableText), 'Tiêm 6 trong 1');
      await tester.tap(find.text('Lưu nhắc việc'));
      await tester.pumpAndSettle();
      final saved = repo.created.single;
      expect(saved.title, 'Tiêm 6 trong 1');
      expect(saved.leadMinutes, 60);
      expect(saved.notifyDevice, maiPhone());
      // 15:05 → the next whole hour at least an hour away: 17:00 in Teddy's zone.
      expect(saved.dueAt, DateTime.utc(2026, 10, 8, 10));

      expect(find.text('Bật thông báo trên máy này?'), findsOneWidget);
      await tester.tap(find.text('Bật thông báo'));
      await tester.pumpAndSettle();
      expect(notifications.requests, 1);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getBool('reminders.notificationsAsked'),
        isTrue,
      );
    });

    testWidgets('"Báo trước" offers the D-031 options', (tester) async {
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: careOverrides(reminders: const []),
      );
      await _oneTime(tester);
      await tester.tap(find.text('Nhắc việc mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo trước'));
      await tester.pumpAndSettle();
      for (final label in [
        'Đúng giờ',
        '10 phút',
        '30 phút',
        '2 giờ',
        '1 ngày',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('1 ngày'));
      await tester.pumpAndSettle();
      expect(find.text('1 ngày'), findsOneWidget);
    });
  });

  group('8e detail', () {
    testWidgets('rows, mark done, edit and delete (D-030)', (tester) async {
      final repo = FakeReminderRepository();
      final list = mockReminders();
      final (visits, _) = await pumpRouted(
        tester,
        ReminderDetailScreen(reminderId: list[1].id),
        overrides: familyOverrides(
          reminders: list,
          reminderRepo: repo,
          now: careNow,
        ),
      );
      expect(find.text('Nhắc việc · Teddy'), findsOneWidget);
      expect(find.text('T7, 10 thg 10 · 08:30'), findsOneWidget);
      expect(find.text('GMT+7'), findsOneWidget);
      expect(find.text('iPhone của Mai'), findsOneWidget);
      expect(find.text('Bạn · 8 thg 10'), findsOneWidget);

      await tester.tap(find.text('Sửa nhắc việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá nhắc việc'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá nhắc việc này?'), findsOneWidget);
      await tester.tap(find.text('Xoá nhắc việc').last);
      await tester.pumpAndSettle();
      expect(repo.deleted.single.id, list[1].id);
      expect(visits, isEmpty);
    });

    testWidgets('a reminder held elsewhere can move here (D-029)', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      final list = mockReminders();
      await pumpRouted(
        tester,
        ReminderDetailScreen(reminderId: list[1].id),
        overrides: familyOverrides(
          me: minh,
          reminders: list,
          reminderRepo: repo,
          now: careNow,
          deviceId: 'd_eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        ),
      );
      expect(find.text('iPhone của Mai'), findsOneWidget);
      await tester.tap(find.text('iPhone của Mai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển sang máy này'));
      await tester.pumpAndSettle();
      final (_, device) = repo.moved.single;
      expect(device.uid, minh.uid);
      expect(device.id, 'd_eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee');
      expect(device.owner, minh.displayName);
    });

    testWidgets('caregivers mark done but do not edit', (tester) async {
      final list = mockReminders();
      await pumpRouted(
        tester,
        ReminderDetailScreen(reminderId: list[1].id),
        overrides: familyOverrides(me: lan, reminders: list, now: careNow),
      );
      expect(find.text('Đánh dấu đã xong'), findsOneWidget);
      expect(find.text('Sửa nhắc việc'), findsNothing);
    });
  });

  group('ReminderPeek (128:665) and notifications', () {
    testWidgets('Today shows the next upcoming and the open count', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      expect(find.text('Nhắc việc · 3'), findsOneWidget);
      expect(find.text('Thứ Bảy 08:30 · còn 2 ngày'), findsOneWidget);
      await tester.tap(find.text('Tiêm 6 trong 1'));
      await tester.pumpAndSettle();
      expect(visits.single.location, Routes.reminders);
    });

    testWidgets(
      'Today lists the next 3, rules\' next times included, then "Xem thêm"',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const Scaffold(body: TodayScreen()),
          overrides: careOverrides(rules: [feed, sleep, diaper]),
        );
        // 3 dated (1 overdue, 1 done not counted) + 2 running rules; the paused one is not.
        expect(find.text('Nhắc việc · 5'), findsOneWidget);
        double y(String t) => tester.getTopLeft(find.text(t)).dy;
        expect(y('Mua sữa công thức'), lessThan(y('Nhắc bú')));
        expect(y('Nhắc bú'), lessThan(y('Nhắc chuẩn bị ngủ')));
        expect(find.text('Hôm nay 17:20 · còn 2 giờ 15 phút'), findsOneWidget);
        expect(find.text('Tiêm 6 trong 1'), findsNothing);
        await tester.tap(find.text('Xem thêm'));
        await tester.pumpAndSettle();
        expect(visits.single.location, Routes.reminders);
      },
    );

    testWidgets('relatives never see reminders (D-018)', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(me: hoa),
      );
      expect(find.byType(ReminderPeek), findsNothing);
    });

    testWidgets('only open reminders held by this device are scheduled', (
      tester,
    ) async {
      final notifications = FakeReminderNotifications();
      await pumpRouted(
        tester,
        const ReminderNotificationSync(child: SizedBox()),
        overrides: familyOverrides(
          reminders: mockReminders(),
          notifications: notifications,
          now: careNow,
        ),
      );
      await tester.pumpAndSettle();
      final scheduled = notifications.scheduled;
      expect(scheduled.map((s) => s.title), ['Tiêm 6 trong 1', 'Tái khám rốn']);
      expect(scheduled.first.body, 'Teddy · Thứ Bảy 08:30');
      expect(
        scheduled.first.fireAt.isAtSameMomentAs(
          DateTime.utc(2026, 10, 10, 0, 30),
        ),
        isTrue,
        reason: '08:30 GMT+7 minus 1 giờ',
      );
    });
  });
}
