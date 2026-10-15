import 'package:child_life/app/router.dart';
import 'package:child_life/core/widgets/cl_choices.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/notifications/inbox_screen.dart';
import 'package:child_life/features/notifications/notification_bell.dart';
import 'package:child_life/features/notifications/notification_models.dart';
import 'package:child_life/features/notifications/notification_settings_screen.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/notification_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/router_pump.dart';

// Notification centre (D-076 #2): the Hôm nay bell, EN06 Hộp thông báo, EN07 Cài đặt thông báo.
final _now = DateTime(2026, 10, 8, 21);

List<Override> _overrides(
  FakeNotificationRepository repo, {
  ReminderNotifications? os,
  bool relative = false,
}) => [
  ...familyOverrides(
    me: relative ? hoa : mai,
    now: _now,
    notificationRepo: repo,
    notifications: os ?? FakeReminderNotifications(),
  ),
  userPreferencesProvider.overrideWith(
    (ref, uid) => Stream.value(UserPreferences.defaults),
  ),
];

/// [screen] at '/', stub pages elsewhere, and the app's own router replaced by this one so
/// deep links (routerProvider) land in [visits].
Future<List<String>> _pump(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides, {
  Locale locale = const Locale('vi'),
}) async {
  final visits = <String>[];
  late final GoRouter router;
  Widget stub(GoRouterState s) {
    visits.add(s.uri.toString());
    return const Scaffold(body: Text('stub'));
  }

  router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(path: '/:a/:b/:c', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a/:b', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a', builder: (_, s) => stub(s)),
    ],
  );
  addTearDown(router.dispose);
  await pumpRouted(
    tester,
    screen,
    router: router,
    locale: locale,
    overrides: [routerProvider.overrideWithValue(router), ...overrides],
  );
  return visits;
}

void main() {
  group('bell (559:57622)', () {
    testWidgets('no dot when everything is read; opens EN06', (tester) async {
      final repo = FakeNotificationRepository(
        inbox: [
          for (final i in mockInbox())
            if (!i.unread) i,
        ],
      );
      final visits = await _pump(
        tester,
        const Scaffold(body: Center(child: NotificationBell())),
        _overrides(repo),
      );
      expect(find.byKey(const Key('notificationBellDot')), findsNothing);
      expect(find.bySemanticsLabel('Thông báo'), findsOneWidget);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(visits, ['/notifications']);
    });

    testWidgets('red dot and count while rows are unread', (tester) async {
      final repo = FakeNotificationRepository(inbox: mockInbox());
      await _pump(
        tester,
        const Scaffold(body: Center(child: NotificationBell())),
        _overrides(repo),
      );
      expect(find.byKey(const Key('notificationBellDot')), findsOneWidget);
      expect(find.bySemanticsLabel('Thông báo, 2 chưa đọc'), findsOneWidget);
    });
  });

  group('EN06 Hộp thông báo', () {
    testWidgets('groups by day, filters by chip, marks all read', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(inbox: mockInbox());
      await _pump(tester, const InboxScreen(), _overrides(repo));
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('TUẦN NÀY'), findsOneWidget);
      expect(find.text('TRƯỚC ĐÓ'), findsOneWidget);
      expect(find.text('Ngày mai có lịch tiêm của bé'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      expect(find.byKey(const Key('ntUnreadDot')), findsNWidgets(2));

      final family = find.widgetWithText(ClFilterChip, 'Gia đình');
      await tester.ensureVisible(family);
      await tester.pumpAndSettle();
      await tester.tap(family);
      await tester.pumpAndSettle();
      expect(find.text('Ngày mai có lịch tiêm của bé'), findsNothing);
      expect(find.text('Có 3 khoảnh khắc mới'), findsOneWidget);
      expect(find.text('Có lời nhắn mới'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ntMarkAllRead')));
      await tester.pumpAndSettle();
      expect(repo.calls.single.$1, 'markRead');
      expect(repo.calls.single.$2, {'n_vx-1', 'n_bn-1'});
      expect(find.byKey(const Key('ntUnreadDot')), findsNothing);
      expect(find.byKey(const Key('ntMarkAllRead')), findsNothing);
    });

    testWidgets('a row reads itself and opens what the push opens', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(inbox: mockInbox());
      final visits = await _pump(tester, const InboxScreen(), _overrides(repo));
      await tester.tap(find.text('Có 3 khoảnh khắc mới'));
      await tester.pumpAndSettle();
      expect(repo.calls.first.$1, 'markRead');
      expect(repo.calls.first.$2, {'n_bn-1'});
      expect(visits, ['/memories']);
    });

    testWidgets('a row for a baby I no longer follow says so', (tester) async {
      final repo = FakeNotificationRepository(
        inbox: [
          inboxItem(
            'n_old-1',
            kind: 'memories',
            category: NotificationCategory.family,
            route: 'memories',
            at: DateTime(2026, 10, 8, 9),
            vi: ('Có 1 khoảnh khắc mới', 'Mở để xem.'),
            en: ('1 new moment', 'Open to see.'),
            babyId: 'b_gone',
          ),
        ],
      );
      final visits = await _pump(tester, const InboxScreen(), _overrides(repo));
      await tester.tap(find.text('Có 1 khoảnh khắc mới'));
      await tester.pumpAndSettle();
      expect(visits, isEmpty);
      expect(find.text('Mục này không còn mở được.'), findsOneWidget);
    });

    testWidgets('a swipe hides a row (archived)', (tester) async {
      final repo = FakeNotificationRepository(inbox: mockInbox());
      await _pump(tester, const InboxScreen(), _overrides(repo));
      await tester.drag(
        find.text('Có 3 khoảnh khắc mới'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, contains(('archive', 'n_bn-1')));
      expect(find.text('Có 3 khoảnh khắc mới'), findsNothing);
    });

    testWidgets('empty, in English', (tester) async {
      await _pump(
        tester,
        const InboxScreen(),
        _overrides(FakeNotificationRepository()),
        locale: const Locale('en'),
      );
      expect(find.text('No notifications yet'), findsOneWidget);
    });
  });

  group('EN07 Cài đặt thông báo', () {
    testWidgets('a switch saves every key; defaults as drawn', (tester) async {
      final repo = FakeNotificationRepository();
      await _pump(tester, const NotificationSettingsScreen(), _overrides(repo));
      ClToggle toggleOf(String key) => tester.widget<ClToggle>(
        find.descendant(
          of: find.byKey(Key('nt-$key')),
          matching: find.byType(ClToggle),
        ),
      );
      expect(toggleOf('reminders').value, isTrue);
      await tester.scrollUntilVisible(
        find.byKey(const Key('nt-articles')),
        200,
      );
      expect(toggleOf('articles').value, isFalse);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('nt-articles')),
          matching: find.byType(ClToggle),
        ),
      );
      await tester.pumpAndSettle();
      final saved = repo.calls.single;
      expect(saved.$1, 'saveSettings');
      expect((saved.$2! as Map)['articles'], isTrue);
      expect((saved.$2! as Map).length, NotificationSettings.keys.length);
      expect(toggleOf('articles').value, isTrue);
    });

    testWidgets('relatives see no reminder or parent-only rows', (
      tester,
    ) async {
      await _pump(
        tester,
        const NotificationSettingsScreen(),
        _overrides(FakeNotificationRepository(), relative: true),
      );
      expect(find.text('NHẮC VIỆC BẠN ĐẶT'), findsNothing);
      await tester.scrollUntilVisible(find.byKey(const Key('nt-quiet')), 200);
      expect(find.byKey(const Key('nt-spending')), findsNothing);
      expect(find.byKey(const Key('nt-storage')), findsNothing);
      expect(find.byKey(const Key('nt-memories')), findsOneWidget);
      expect(find.text('22:00 – 06:00'), findsOneWidget);
    });

    testWidgets('system permission off: the switch asks the OS', (
      tester,
    ) async {
      final os = FakeReminderNotifications(on: false);
      await _pump(
        tester,
        const NotificationSettingsScreen(),
        _overrides(FakeNotificationRepository(), os: os),
      );
      expect(find.text('Đang tắt trong cài đặt hệ thống'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('nt-system')),
          matching: find.byType(ClToggle),
        ),
      );
      await tester.pumpAndSettle();
      expect(os.requests, 1);
      expect(find.text('Đang bật trong cài đặt hệ thống'), findsOneWidget);
    });
  });
}
