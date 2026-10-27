import 'dart:async';

import 'package:child_life/app/session.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/me/me_repository.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/reminders/device_identity.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/reminder_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rule_fixtures.dart';
import '../helpers/router_pump.dart';

const _zone = 'Asia/Ho_Chi_Minh';

/// Nhắc nhở opens on "Một lần" (the dated reminders); a tap on it changes nothing.
Future<void> _oneTime(WidgetTester tester) async {
  await tester.tap(find.text('Một lần'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(ensureTimeZones);

  group('model (R-093, D-032)', () {
    test('groups: overdue oldest first, upcoming soonest first, done', () {
      final g = groupReminders(mockReminders(), careNow, _zone);
      expect(g.overdue.map((r) => r.title), ['Mua sữa công thức']);
      expect(g.upcoming.map((r) => r.title), [
        'Tiêm 6 trong 1',
        'Tái khám rốn',
      ]);
      expect(g.done.map((r) => r.title), ['Khám 1 tháng']);
    });

    test('fires once at due time minus "Báo trước"', () {
      final r = mockReminders()[1];
      expect(r.fireAt(_zone), r.dueAt.subtract(const Duration(hours: 1)));
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
      expect(reminderOfPayload(reminderPayload(r, r.dueAt, 't', 'b')), (
        r.babyId,
        r.id,
      ));
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

  group('NT-3: one "asked" flag for the launch prompt, EN03 and 8c', () {
    testWidgets('asked at launch: 8c does not ask again after a save', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      final notifications = FakeReminderNotifications(on: false);
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: const [],
          reminderRepo: repo,
          notifications: notifications,
          now: careNow,
        ),
        // What the launch prompt (D-098) wrote before NT-3.
        prefs: const {'notifications.askedOnLaunch': true},
      );
      await _oneTime(tester);
      await tester.tap(find.text('Nhắc việc mới'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Tiêm 6 trong 1');
      await tester.tap(find.text('Lưu nhắc việc'));
      await tester.pumpAndSettle();
      expect(repo.created, hasLength(1));
      expect(find.text('Bật thông báo trên máy này?'), findsNothing);
      expect(notifications.requests, 0);
    });

    testWidgets('8c refused at the system prompt: the toast offers Cài đặt', (
      tester,
    ) async {
      final notifications = FakeReminderNotifications(on: false, grant: false);
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: const [],
          reminderRepo: FakeReminderRepository(),
          notifications: notifications,
          now: careNow,
        ),
      );
      await _oneTime(tester);
      await tester.tap(find.text('Nhắc việc mới'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Tiêm 6 trong 1');
      await tester.tap(find.text('Lưu nhắc việc'));
      await tester.pumpAndSettle();
      expect(
        find.text('Để nhắc việc kêu đúng giờ, kể cả khi đang đóng app.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Bật thông báo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(notifications.requests, 1);
      expect(
        find.text('Đã lưu nhắc việc. Chưa bật thông báo trên máy này.'),
        findsWidgets,
      );
      expect(find.text('Cài đặt'), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
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
      // A row opens that reminder.
      await tester.tap(find.text('Tiêm 6 trong 1'));
      await tester.pumpAndSettle();
      expect(visits.single.location, startsWith('${Routes.reminders}/rm_'));
    });

    testWidgets(
      'Today lists the next 3, rules\' next times included, under "Xem tất cả"',
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
        await tester.tap(find.text('Xem tất cả'));
        await tester.pumpAndSettle();
        expect(visits.single.location, Routes.reminders);
      },
    );

    testWidgets('a rule\'s row on Today opens that rule', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(rules: [feed]),
      );
      await tester.tap(find.text('Nhắc bú'));
      await tester.pumpAndSettle();
      expect(visits.single.location, '${Routes.ruleDetail}/rr_feed');
    });

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

  // ---------- A start before the sources answer (D-068 #9) ----------

  group('notification sync waits for its sources', () {
    test('reminders count as known only once Firestore answers', () async {
      final pending = StreamController<List<Reminder>>();
      addTearDown(pending.close);
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWithValue(
            SessionSignedIn(
              user: FakeUser(uid: mai.uid),
              memberships: [mai],
            ),
          ),
          deviceIdentityProvider.overrideWith(
            (ref) async => DeviceIdentity(id: testDeviceId, label: 'iPhone'),
          ),
          notificationPrefsProvider.overrideWith(
            (ref, uid) => Stream.value(const NotificationPrefs()),
          ),
          babyProvider.overrideWith((ref, id) => Stream.value(teddy)),
          remindersProvider.overrideWith((ref, id) => pending.stream),
        ],
      );
      addTearDown(container.dispose);
      container.listen(deviceRemindersReadyProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(deviceRemindersReadyProvider), isFalse);
      pending.add(const []);
      await pumpEventQueue();
      expect(container.read(deviceRemindersReadyProvider), isTrue);
    });

    test('signed out is known: everything is cancelled', () {
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWithValue(const SessionSignedOut()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(deviceRemindersReadyProvider), isTrue);
    });

    testWidgets(
      'a cold start cancels nothing until the sources answer, then syncs',
      (tester) async {
        final notifications = FakeReminderNotifications();
        // What an earlier run scheduled, e.g. 09:00 "Hôm nay Teddy tròn 1 tháng".
        final earlier = [
          LocalReminder(
            id: 1,
            fireAt: DateTime(2026, 10, 17, 9),
            title: 'Hôm nay Teddy tròn 1 tháng 🎂',
            body: '',
            payload: '{}',
          ),
        ];
        notifications.scheduled = earlier;
        final (_, container) = await pumpRouted(
          tester,
          const ReminderNotificationSync(child: SizedBox()),
          overrides: [
            ...familyOverrides(
              reminders: mockReminders(),
              notifications: notifications,
              now: careNow,
            ),
            notificationSourcesReadyProvider.overrideWith(
              (ref) => ref.watch(_sourcesReady),
            ),
          ],
        );
        await tester.pumpAndSettle();
        expect(notifications.scheduled, same(earlier));
        container.read(_sourcesReady.notifier).set(true);
        await tester.pumpAndSettle();
        expect(notifications.scheduled.map((s) => s.title), [
          'Tiêm 6 trong 1',
          'Tái khám rốn',
        ]);
      },
    );
  });

  // ---------- D-075 #5: date-only (all day) and an assignee ----------

  group('all day and assignee: model (D-075 #5)', () {
    test(
      'an all-day reminder is due all its day (baby zone), overdue from the next',
      () {
        final r = allDayReminder('Mua bỉm', '2026-10-08', mai);
        expect(r.dueDay, DateTime(2026, 10, 8));
        // 23:50 on the 8th in Vietnam.
        expect(
          r.statusAt(DateTime.utc(2026, 10, 8, 16, 50), _zone),
          ReminderStatus.upcoming,
        );
        // 00:10 on the 9th.
        expect(
          r.statusAt(DateTime.utc(2026, 10, 8, 17, 10), _zone),
          ReminderStatus.overdue,
        );
        final g = groupReminders([r], careNow, _zone);
        expect(g.upcoming, [r]);
      },
    );

    test(
      'rings at the person’s time on its day, or the day before for "1 ngày"',
      () {
        final r = allDayReminder('Mua bỉm', '2026-10-10', mai);
        expect(
          r.fireAt(_zone).isAtSameMomentAs(DateTime.utc(2026, 10, 10, 1)),
          isTrue,
          reason: '08:00 GMT+7 by default',
        );
        expect(
          r
              .fireAt(_zone, allDayMinutes: 6 * 60 + 30)
              .isAtSameMomentAs(DateTime.utc(2026, 10, 9, 23, 30)),
          isTrue,
        );
        final dayBefore = allDayReminder(
          'Mua bỉm',
          '2026-11-01',
          mai,
          lead: 1440,
        );
        expect(
          dayBefore
              .fireAt(_zone)
              .isAtSameMomentAs(DateTime.utc(2026, 10, 31, 1)),
          isTrue,
        );
      },
    );

    test(
      'rings on the device it was put on and on every device of its assignee',
      () {
        final r = allDayReminder('Mua bỉm', '2026-10-10', mai, assignee: lan);
        expect(r.ringsOn(deviceId: testDeviceId, uid: 'u_lan'), isTrue);
        expect(r.ringsOn(deviceId: testDeviceId, uid: 'u_mai'), isFalse);
        final held = r.copyWith(notifyDevice: maiPhone());
        expect(held.ringsOn(deviceId: testDeviceId, uid: 'u_mai'), isTrue);
      },
    );

    test(
      'writes the new keys on create; an edit sends them only when they changed',
      () {
        final r = allDayReminder('Mua bỉm', '2026-10-10', mai, assignee: lan);
        expect(r.toCreateJson(), containsPair('allDay', true));
        expect(r.toCreateJson(), containsPair('dueDate', '2026-10-10'));
        expect(r.toCreateJson(), containsPair('assigneeUid', 'u_lan'));
        final timed = mockReminders()[1].toCreateJson();
        expect(timed, containsPair('allDay', false));
        expect(timed, containsPair('dueDate', null));
        expect(timed, containsPair('assigneeUid', null));

        final renamed = r.copyWith(title: 'Mua tã').toEditJson(r, 'u_mai');
        expect(renamed.keys, isNot(contains('assigneeUid')));
        expect(renamed.keys, isNot(contains('allDay')));
        final unassigned = r.copyWith(assigneeUid: null).toEditJson(r, 'u_mai');
        expect(unassigned, containsPair('assigneeUid', null));
        final moved = r.copyWith(dueDate: '2026-10-11').toEditJson(r, 'u_mai');
        expect(moved, containsPair('dueDate', '2026-10-11'));
        expect(moved, containsPair('allDay', true));
      },
    );
  });

  group('all day and assignee: screens (D-075 #5)', () {
    testWidgets('8b "Cả ngày": a date, the person’s 08:00 shown, "Đúng ngày"', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: const [],
          reminderRepo: repo,
          now: careNow,
        ),
      );
      await _oneTime(tester);
      await tester.tap(find.text('Nhắc việc mới'));
      await tester.pumpAndSettle();
      expect(find.text('Giờ báo'), findsNothing);
      await tester.tap(find.byType(ClToggle));
      await tester.pumpAndSettle();
      expect(find.text('Ngày'), findsOneWidget);
      expect(find.text('T5, 8 thg 10'), findsOneWidget);
      expect(find.text('Giờ báo'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Đúng ngày'), findsOneWidget);
      await tester.tap(find.text('Báo trước'));
      await tester.pumpAndSettle();
      expect(find.text('10 phút'), findsNothing);
      expect(find.text('1 ngày'), findsOneWidget);
      await tester.tap(find.text('Đúng ngày').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'Mua bỉm');
      await tester.tap(find.text('Lưu nhắc việc'));
      await tester.pumpAndSettle();
      final saved = repo.created.single;
      expect(saved.allDay, isTrue);
      expect(saved.dueDate, '2026-10-08');
      expect(saved.leadMinutes, 0);
      // 23:59 on the 8th in Teddy's zone.
      expect(saved.dueAt, DateTime.utc(2026, 10, 8, 16, 59));
      expect(saved.notifyDevice, maiPhone());
      expect(saved.assigneeUid, isNull);
    });

    testWidgets(
      '8b "Giao cho": Cùng nuôi and caregivers only; someone else’s job '
      'rings on their devices, not here',
      (tester) async {
        final repo = FakeReminderRepository();
        await pumpRouted(
          tester,
          const RemindersScreen(),
          overrides: familyOverrides(
            reminders: const [],
            reminderRepo: repo,
            now: careNow,
          ),
        );
        await _oneTime(tester);
        await tester.tap(find.text('Nhắc việc mới'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa giao'), findsOneWidget);
        await tester.tap(find.text('Giao cho'));
        await tester.pumpAndSettle();
        expect(find.text('Không giao ai'), findsOneWidget);
        expect(find.text('Bạn'), findsOneWidget);
        expect(find.text('Ba'), findsOneWidget);
        expect(find.text('Cô Lan'), findsOneWidget);
        // A relative is never offered.
        expect(find.text('Bà nội'), findsNothing);
        expect(find.text('Bà nội Hoa'), findsNothing);
        await tester.tap(find.text('Cô Lan'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Theo giờ của Teddy (GMT+7). Gia đình thấy nhắc việc trong app. '
            'Cô Lan nhận thông báo trên máy của mình khi mở app.',
          ),
          findsOneWidget,
        );
        await tester.enterText(find.byType(EditableText), 'Mua bỉm');
        await tester.tap(find.text('Lưu nhắc việc'));
        await tester.pumpAndSettle();
        final saved = repo.created.single;
        expect(saved.assigneeUid, 'u_lan');
        expect(saved.notifyDevice, isNull);
        expect(saved.allDay, isFalse);
      },
    );

    testWidgets('8a: "Giao cho Cô Lan" for others, all-day meta', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RemindersScreen(),
        overrides: familyOverrides(
          reminders: mockAssignedReminders(),
          now: careNow,
        ),
      );
      await _oneTime(tester);
      expect(
        find.text('Thứ Bảy, 10 thg 10 · Cả ngày · Bạn tạo'),
        findsOneWidget,
      );
      expect(find.text('Giao cho Cô Lan'), findsOneWidget);
      // Mai's own job is highlighted for her.
      expect(find.text('Giao cho bạn'), findsOneWidget);
    });

    testWidgets(
      '12f: the caregiver sees her job highlighted and marks it done',
      (tester) async {
        final repo = FakeReminderRepository();
        await pumpRouted(
          tester,
          const RemindersScreen(),
          overrides: familyOverrides(
            me: lan,
            reminders: mockAssignedReminders(),
            reminderRepo: repo,
            now: careNow,
          ),
        );
        await _oneTime(tester);
        expect(find.text('Giao cho bạn'), findsOneWidget);
        expect(find.text('Giao cho Mẹ'), findsOneWidget);
        await tester.tap(
          find.bySemanticsLabel('Đánh dấu xong: Mua bỉm size S'),
        );
        await tester.pump();
        expect(repo.done.single.$2, isTrue);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '8e: all-day rows, the person’s time, the assignee and her devices',
      (tester) async {
        final list = mockAssignedReminders();
        final (_, container) = await pumpRouted(
          tester,
          ReminderDetailScreen(reminderId: list[4].id),
          overrides: familyOverrides(reminders: list, now: careNow),
          prefs: const {'reminders.allDayMinutes': 7 * 60 + 30},
        );
        expect(find.text('T7, 10 thg 10 · Cả ngày'), findsOneWidget);
        expect(find.text('Đúng ngày'), findsOneWidget);
        expect(find.text('Giờ báo'), findsOneWidget);
        expect(find.text('07:30'), findsOneWidget);
        expect(find.text('Cô Lan'), findsOneWidget);
        expect(find.text('Các máy của Cô Lan'), findsOneWidget);
        expect(
          find.text(
            'Người được giao nhận thông báo trên máy của mình khi mở app. '
            'Đánh dấu xong khi đã làm.',
          ),
          findsOneWidget,
        );
        // The person changes their all-day time from the row.
        await tester.tap(find.text('07:30'));
        await tester.pumpAndSettle();
        expect(find.text('Giờ nhắc việc cả ngày'), findsOneWidget);
        await tester.tap(find.text('Xong'));
        await tester.pumpAndSettle();
        expect(container.read(reminderAllDayTimeProvider), 7 * 60 + 30);
      },
    );

    testWidgets(
      'notifications: an all-day job assigned to me rings at my time on my '
      'device; someone else’s job does not',
      (tester) async {
        final notifications = FakeReminderNotifications();
        await pumpRouted(
          tester,
          const ReminderNotificationSync(child: SizedBox()),
          overrides: familyOverrides(
            me: lan,
            reminders: [
              ...mockAssignedReminders(),
              allDayReminder(
                'Mua sữa',
                '2026-10-11',
                mai,
                lead: 1440,
                assignee: lan,
              ),
            ],
            notifications: notifications,
            now: careNow,
            deviceId: 'd_${'1' * 32}',
          ),
          prefs: const {'reminders.allDayMinutes': 6 * 60 + 30},
        );
        await tester.pumpAndSettle();
        final scheduled = notifications.scheduled;
        expect(scheduled.map((s) => s.title), ['Mua bỉm size S', 'Mua sữa']);
        expect(scheduled.first.body, 'Teddy · Thứ Bảy · Cả ngày');
        expect(
          scheduled.first.fireAt.isAtSameMomentAs(
            DateTime.utc(2026, 10, 9, 23, 30),
          ),
          isTrue,
          reason: '06:30 GMT+7 on Saturday, the time Lan chose',
        );
        expect(
          scheduled.last.fireAt.isAtSameMomentAs(
            DateTime.utc(2026, 10, 9, 23, 30),
          ),
          isTrue,
          reason: '"1 ngày": 06:30 the day before Sunday',
        );
      },
    );

    testWidgets(
      'notifications: the creator’s device keeps the timed ones it holds and '
      'its own assignments',
      (tester) async {
        final notifications = FakeReminderNotifications();
        await pumpRouted(
          tester,
          const ReminderNotificationSync(child: SizedBox()),
          overrides: familyOverrides(
            reminders: mockAssignedReminders(),
            notifications: notifications,
            now: careNow,
          ),
        );
        await tester.pumpAndSettle();
        expect(notifications.scheduled.map((s) => s.title), [
          'Tiêm 6 trong 1',
          'Tái khám rốn',
          'Đặt lịch khám 2 tháng',
        ]);
      },
    );
  });
}

/// Stands in for [notificationSourcesReadyProvider] so a test decides when the sources answer.
final _sourcesReady = NotifierProvider<_SourcesReady, bool>(_SourcesReady.new);

class _SourcesReady extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}
