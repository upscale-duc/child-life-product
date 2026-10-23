import 'package:child_life/app/router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:child_life/core/widgets/cl_choices.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/notifications/inbox_screen.dart';
import 'package:child_life/features/notifications/notification_bell.dart';
import 'package:child_life/features/notifications/notification_destinations.dart';
import 'package:child_life/features/notifications/notification_models.dart';
import 'package:child_life/features/notifications/notification_repository.dart'
    show inboxPageSize;
import 'package:child_life/features/notifications/notification_settings_screen.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  FakeNotificationOpenReporter? reporter,
  FakeEngagementOpener? engagement,
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
  notificationOpenReporterProvider.overrideWithValue(
    reporter ?? FakeNotificationOpenReporter(),
  ),
  notificationEngagementOpenerProvider.overrideWithValue(
    (engagement ?? FakeEngagementOpener()).call,
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
      GoRoute(path: '/:a/:b/:c/:d', builder: (_, s) => stub(s)),
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

      // P-174 groups: vaccine, rule and spending are Chăm sóc; memories Kỷ niệm; message
      // Gia đình.
      Future<void> tapChip(String label) async {
        final chip = find.widgetWithText(ClFilterChip, label);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }

      await tapChip('Gia đình');
      expect(find.text('Ngày mai có lịch tiêm của bé'), findsNothing);
      expect(find.text('Có 3 khoảnh khắc mới'), findsNothing);
      expect(find.text('Có lời nhắn mới'), findsOneWidget);
      await tapChip('Kỷ niệm');
      expect(find.text('Có 3 khoảnh khắc mới'), findsOneWidget);
      expect(find.text('Có lời nhắn mới'), findsNothing);
      await tapChip('Chăm sóc');
      expect(find.text('Ngày mai có lịch tiêm của bé'), findsOneWidget);
      expect(find.text('Chi tiêu đã dùng 80% ngân sách tháng'), findsOneWidget);
      expect(find.text('Có 3 khoảnh khắc mới'), findsNothing);
      await tapChip('Khác');
      expect(find.text('Chưa có thông báo nào trong mục này.'), findsOneWidget);
      await tapChip('Tất cả');

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
      // D-094: the baby's name shows by default.
      expect(toggleOf('babyName').value, isTrue);
      await tester.scrollUntilVisible(
        find.byKey(const Key('nt-articles')),
        200,
      );
      expect(toggleOf('articles').value, isFalse);
      // The row may stop at the edge after the scroll (D-094 added a row above): bring it in.
      await tester.ensureVisible(find.byKey(const Key('nt-articles')));
      await tester.pumpAndSettle();
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

    testWidgets('Thành viên gia đình (D-092) is on by default and saves', (
      tester,
    ) async {
      final repo = FakeNotificationRepository();
      await _pump(
        tester,
        const NotificationSettingsScreen(),
        _overrides(repo, relative: true),
      );
      final row = find.byKey(const Key('nt-familyMembers'));
      await tester.scrollUntilVisible(row, 200);
      expect(find.text('Thành viên gia đình'), findsOneWidget);
      final toggle = find.descendant(of: row, matching: find.byType(ClToggle));
      expect(tester.widget<ClToggle>(toggle).value, isTrue);
      // Clear of the pinned header and the screen edge.
      await tester.scrollUntilVisible(find.byKey(const Key('nt-quiet')), 200);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final saved = repo.calls.single.$2! as Map;
      expect(saved['familyMembers'], isFalse);
      expect(saved.length, NotificationSettings.keys.length);
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

  group('EN06 pages, errors and refresh (P-174)', () {
    List<InboxItem> many(int n) => [
      for (var i = 0; i < n; i++)
        inboxItem(
          'n_page${i.toString().padLeft(4, '0')}',
          kind: 'memories',
          category: NotificationCategory.family,
          route: 'memories',
          at: _now.subtract(Duration(hours: i)),
          vi: ('Khoảnh khắc $i', 'Mở để xem.'),
          en: ('Moment $i', 'Open to see.'),
          read: true,
        ),
    ];

    testWidgets('30 rows first, 30 more from the end of the list', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(inbox: many(35));
      await _pump(tester, const InboxScreen(), _overrides(repo));
      expect(repo.limits, [inboxPageSize]);
      final list = find.byType(Scrollable).first;
      final more = find.byKey(const Key('ntLoadMore'));
      await tester.scrollUntilVisible(more, 400, scrollable: list);
      expect(find.text('Khoảnh khắc 34'), findsNothing);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(repo.limits, [inboxPageSize, inboxPageSize * 2]);
      await tester.scrollUntilVisible(
        find.text('Khoảnh khắc 34'),
        400,
        scrollable: list,
      );
      expect(find.byKey(const Key('ntLoadMore')), findsNothing);
    });

    testWidgets('a load error offers Retry, which re-subscribes', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(inbox: mockInbox())
        ..failWith = StateError('offline');
      await _pump(tester, const InboxScreen(), _overrides(repo));
      expect(find.byKey(const Key('ntError')), findsOneWidget);
      expect(find.text('Chưa tải được thông báo'), findsOneWidget);
      repo.failWith = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ntError')), findsNothing);
      expect(find.text('Ngày mai có lịch tiêm của bé'), findsOneWidget);
      expect(repo.limits.length, 2);
    });

    testWidgets('pull to refresh re-subscribes', (tester) async {
      final repo = FakeNotificationRepository(inbox: mockInbox());
      await _pump(tester, const InboxScreen(), _overrides(repo));
      await tester.fling(find.text('HÔM NAY'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(repo.limits.length, 2);
    });

    testWidgets('server group wins; unknown kinds show under Khác', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(
        inbox: [
          inboxItem(
            'n_future0001',
            kind: 'somethingNew',
            category: NotificationCategory.general,
            route: 'inbox',
            at: DateTime(2026, 10, 8, 9),
            vi: ('Tính năng mới', 'Mở để xem.'),
            en: ('Something new', 'Open to see.'),
          ),
          inboxItem(
            'n_grouped001',
            kind: 'memories',
            category: NotificationCategory.family,
            route: 'memories',
            at: DateTime(2026, 10, 8, 8),
            vi: ('Gia đình có cập nhật', 'Mở để xem.'),
            en: ('Family update', 'Open to see.'),
            group: 'family',
          ),
        ],
      );
      await _pump(tester, const InboxScreen(), _overrides(repo));
      await tester.ensureVisible(find.byKey(const Key('ntChip-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ntChip-other')));
      await tester.pumpAndSettle();
      expect(find.text('Tính năng mới'), findsOneWidget);
      expect(find.text('Gia đình có cập nhật'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('ntChip-family')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ntChip-family')));
      await tester.pumpAndSettle();
      expect(find.text('Gia đình có cập nhật'), findsOneWidget);
    });
  });

  group('catalog mirror (P-174)', () {
    test('chips follow the contract; unknown kinds are Khác', () {
      expect(inboxGroupOf('reminderRule'), InboxGroup.care);
      expect(inboxGroupOf('spending'), InboxGroup.care);
      expect(inboxGroupOf('keepsakePrompt'), InboxGroup.memories);
      expect(inboxGroupOf('storageGranted'), InboxGroup.family);
      expect(inboxGroupOf('familyActivity'), InboxGroup.family);
      expect(inboxGroupOf('rhythm'), InboxGroup.other);
      expect(inboxGroupOf('test'), InboxGroup.other);
      expect(inboxGroupOf('fromTheFuture'), InboxGroup.other);
      // D-092 membership events.
      for (final kind in [
        'memberJoined',
        'inviteDeclined',
        'roleChanged',
        'memberRemoved',
      ]) {
        expect(inboxGroupOf(kind), InboxGroup.family, reason: kind);
      }
      expect(destinationFor('memberJoined', const {}), 'FAMILY_MEMBERS');
      expect(destinationFor('roleChanged', const {}), 'FAMILY_MEMBERS');
      expect(destinationFor('memberRemoved', const {}), 'INBOX');
      expect(inboxGroupFor('memories', 'care'), InboxGroup.care);
      expect(inboxGroupFor('memories', 'nonsense'), InboxGroup.memories);
    });

    test('legacy rows derive their destination from kind and ids', () {
      expect(
        destinationFor('spending', {'babyId': 'b', 'importId': 'im_x'}),
        'SPENDING_IMPORT',
      );
      expect(destinationFor('spending', {'babyId': 'b'}), 'SPENDING');
      expect(
        destinationFor('story', {
          'sourceCollection': 'stories',
          'sourceId': 's1',
        }),
        'MEMORIES_STORY',
      );
      // "Có 7 khoảnh khắc mới" names its share; older rows (no share) open Kỷ niệm.
      expect(
        destinationFor('shared', {
          'sourceCollection': 'shares',
          'sourceId': 'sh_${'a' * 32}',
        }),
        'MEMORIES_SHARED',
      );
      expect(destinationFor('shared', {'babyId': 'b'}), 'MEMORIES');
      expect(destinationFor('keepsakeVideo', {'babyId': 'b'}), 'MEMORIES');
      expect(destinationFor('memories', {'destination': 'INBOX'}), 'INBOX');
      expect(
        destinationFor('memories', {'destination': 'https://x'}),
        'MEMORIES',
      );
      expect(destinationFor('fromTheFuture', const {}), 'INBOX');
    });

    test('params are validated; chains end at INBOX', () {
      expect(
        destinationParams('MEMORIES_VIDEO_JOB', {'babyId': 'b1', 'jobId': 'x'}),
        isNull,
      );
      expect(destinationParams('SPENDING', const {}), isNull);
      expect(destinationParams('FAMILY_STORAGE', const {}), isEmpty);
      expect(destinationChain('SPENDING_IMPORT'), [
        'SPENDING_IMPORT',
        'SPENDING',
        'INBOX',
      ]);
      expect(destinationChain('CARE_RULE_REMINDER'), [
        'CARE_RULE_REMINDER',
        'CARE_REMINDERS',
        'INBOX',
      ]);
      expect(destinationChain('nope'), ['INBOX']);
      for (final id in notificationDestinations.keys) {
        expect(destinationChain(id).last, 'INBOX');
      }
      expect(notificationDestinations.length, 19);
    });

    test('rows parse the P-174 fields and hide when expired', () {
      final item = InboxItem.fromDoc('n_parse00001', {
        'kind': 'album',
        'title': {'vi': 'A', 'en': 'A'},
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 8)),
        'expireAt': Timestamp.fromDate(DateTime(2027, 1, 6)),
        'destination': 'MEMORIES_ALBUM',
        'group': 'memories',
        'templateId': 'memories.new_moments',
        'templateVersion': 3,
        'babyId': teddyId,
        'data': {'albumId': 'a1'},
      })!;
      expect(item.destination, 'MEMORIES_ALBUM');
      expect(item.templateVersion, 3);
      expect(item.inboxGroup, InboxGroup.memories);
      expect(item.hiddenAt(DateTime(2026, 12, 1)), isFalse);
      expect(item.hiddenAt(DateTime(2027, 1, 6)), isTrue);
      expect(item.target.destination, 'MEMORIES_ALBUM');
      expect(item.target.inboxId, 'n_parse00001');
    });

    test('legacy album, story and job ids map onto the params', () {
      final album = NotificationTarget.fromPush({
        'kind': 'album',
        'babyId': teddyId,
        'sourceCollection': 'albums',
        'sourceId': 'a1',
      });
      expect(album.data['albumId'], 'a1');
      final id = 'ksj_${'a' * 32}';
      final job = NotificationTarget.fromPush({
        'kind': 'keepsakeVideo',
        'babyId': teddyId,
        'noticeId': 'keepsake_$id',
      });
      expect(job.destination, 'MEMORIES_VIDEO_JOB');
      expect(job.data['jobId'], id);
    });
  });

  group('one resolver for pushes and rows (P-174)', () {
    late WidgetRef captured;
    final probe = Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          captured = ref;
          return const SizedBox.shrink();
        },
      ),
    );

    Future<NotificationOpenOutcome> open(
      WidgetTester tester,
      NotificationTarget target, {
      NotificationSurface surface = NotificationSurface.inbox,
      Duration wait = Duration.zero,
    }) async {
      final f = openNotification(captured, target, surface: surface);
      if (wait > Duration.zero) await tester.pump(wait);
      await tester.pumpAndSettle();
      final outcome = await f;
      await tester.pumpAndSettle();
      return outcome;
    }

    NotificationTarget push(Map<String, String> data) =>
        NotificationTarget.fromPush({'inboxId': 'n_push000001', ...data});

    testWidgets('each destination opens its screen', (tester) async {
      final reporter = FakeNotificationOpenReporter();
      final engagement = FakeEngagementOpener();
      final visits = await _pump(
        tester,
        probe,
        _overrides(
          FakeNotificationRepository(),
          reporter: reporter,
          engagement: engagement,
        ),
      );
      final importId = 'im_${'b' * 32}';
      final jobId = 'ksj_${'c' * 32}';
      final eng = 'e' * 64;
      final cases = <(Map<String, String>, List<String>)>[
        (
          {
            'kind': 'vaccine',
            'babyId': teddyId,
            'date': '2026-10-09',
            'months': '2',
          },
          ['/care/vaccines/age/2'],
        ),
        (
          {'kind': 'spending', 'babyId': teddyId},
          ['/utilities/spending'],
        ),
        (
          {'kind': 'spending', 'babyId': teddyId, 'importId': importId},
          ['/utilities/spending/import/$importId'],
        ),
        ({'kind': 'memories', 'babyId': teddyId}, ['/memories']),
        (
          {'kind': 'album', 'babyId': teddyId, 'albumId': 'a1'},
          ['/memories/album/a1'],
        ),
        (
          {'kind': 'story', 'babyId': teddyId, 'storyId': 's1'},
          ['/story/s1'],
        ),
        (
          {'kind': 'keepsakeVideo', 'babyId': teddyId, 'jobId': jobId},
          ['/memories/video/job/$jobId?baby=$teddyId'],
        ),
        (
          {
            'kind': 'shared',
            'babyId': teddyId,
            'sourceCollection': 'shares',
            'sourceId': 'sh_${'d' * 32}',
          },
          ['/memories/album/share:sh_${'d' * 32}'],
        ),
        ({'kind': 'message', 'babyId': teddyId}, ['/messages']),
        ({'kind': 'storage', 'babyId': teddyId}, ['/me/storage']),
        ({'kind': 'weeklySummary', 'babyId': teddyId, 'engagementId': eng}, []),
        (
          {
            'kind': 'memories',
            'babyId': teddyId,
            'destination': 'CARE_REMINDERS',
          },
          ['/care/reminders'],
        ),
        ({'kind': 'test'}, ['/notifications']),
      ];
      for (final (data, expected) in cases) {
        // Back to the probe alone (each destination opens on top of it).
        ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        ).read(routerProvider).go('/');
        await tester.pumpAndSettle();
        visits.clear();
        final outcome = await open(
          tester,
          push(data),
          surface: NotificationSurface.push,
        );
        expect(outcome, NotificationOpenOutcome.navigated, reason: '$data');
        expect(visits, unorderedEquals(expected), reason: '$data');
      }
      expect(engagement.ids, [eng]);
      expect(reporter.records, hasLength(cases.length));
      expect(
        reporter.records.every(
          (r) =>
              r.surface == NotificationSurface.push &&
              r.outcome == NotificationOpenOutcome.navigated &&
              r.inboxId == 'n_push000001',
        ),
        isTrue,
      );
      expect(reporter.records.first.destination, 'CARE_VACCINES');
    });

    testWidgets('bad params fall back to the parent screen, with a toast', (
      tester,
    ) async {
      final reporter = FakeNotificationOpenReporter();
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository(), reporter: reporter),
      );
      final outcome = await open(
        tester,
        push({'kind': 'spending', 'babyId': teddyId, 'importId': 'im_nope'}),
        surface: NotificationSurface.push,
      );
      expect(outcome, NotificationOpenOutcome.fallback);
      expect(visits, ['/utilities/spending']);
      expect(
        find.text('Không mở được đúng mục này, đã mở trang gần nhất.'),
        findsOneWidget,
      );
      expect(reporter.records.single.outcome, NotificationOpenOutcome.fallback);
      expect(reporter.records.single.destination, 'SPENDING');
    });

    testWidgets('an expired engagement falls back to Kỷ niệm', (tester) async {
      final visits = await _pump(
        tester,
        probe,
        _overrides(
          FakeNotificationRepository(),
          engagement: FakeEngagementOpener(opens: false),
        ),
      );
      final outcome = await open(
        tester,
        push({
          'kind': 'photoSuggestion',
          'babyId': teddyId,
          'engagementId': 'f' * 64,
        }),
        surface: NotificationSurface.push,
      );
      expect(outcome, NotificationOpenOutcome.fallback);
      expect(visits, ['/memories']);
    });

    testWidgets('a push for spending without membership opens the inbox', (
      tester,
    ) async {
      final reporter = FakeNotificationOpenReporter();
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository(), reporter: reporter),
      );
      final outcome = await open(
        tester,
        push({'kind': 'spending', 'babyId': 'b_someone_else'}),
        surface: NotificationSurface.push,
        wait: const Duration(seconds: 11),
      );
      expect(outcome, NotificationOpenOutcome.unavailable);
      expect(visits, ['/notifications']);
      expect(find.text('Mục này không còn mở được.'), findsOneWidget);
      expect(
        reporter.records.single.outcome,
        NotificationOpenOutcome.unavailable,
      );
    });

    testWidgets('another account\'s row never navigates, whatever it names', (
      tester,
    ) async {
      final engagement = FakeEngagementOpener();
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository(), engagement: engagement),
      );
      for (final data in [
        {'kind': 'memories', 'destination': 'MEMORIES'},
        {'kind': 'storage', 'destination': 'FAMILY_STORAGE'},
        {'kind': 'weeklySummary', 'engagementId': 'e' * 64},
        {'kind': 'reminderRule', 'ruleId': 'r1'},
      ]) {
        final outcome = await open(
          tester,
          NotificationTarget(
            kind: data['kind']!,
            babyId: 'b_other_account',
            data: data,
            inboxId: 'n_other00001',
          ),
        );
        expect(outcome, NotificationOpenOutcome.unavailable, reason: '$data');
      }
      expect(visits, isEmpty);
      expect(engagement.ids, isEmpty);
    });

    testWidgets('a relative cannot open parent-only messages', (tester) async {
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository(), relative: true),
      );
      final outcome = await open(
        tester,
        NotificationTarget(kind: 'message', babyId: teddyId),
      );
      expect(outcome, NotificationOpenOutcome.unavailable);
      expect(visits, isEmpty);
      expect(find.text('Mục này không còn mở được.'), findsOneWidget);
    });

    testWidgets('an inbox tap records the open with the inbox surface', (
      tester,
    ) async {
      final reporter = FakeNotificationOpenReporter();
      final repo = FakeNotificationRepository(
        inbox: [
          inboxItem(
            'n_album00001',
            kind: 'album',
            category: NotificationCategory.family,
            route: 'memories',
            at: DateTime(2026, 10, 8, 9),
            vi: ('Album được cập nhật', 'Mở để xem.'),
            en: ('Album updated', 'Open to see.'),
            // A row written before P-174: no destination, the album by its source.
            data: {'sourceCollection': 'albums', 'sourceId': 'a1'},
          ),
          inboxItem(
            'n_unknown001',
            kind: 'fromTheFuture',
            category: NotificationCategory.general,
            route: 'inbox',
            at: DateTime(2026, 10, 8, 8),
            vi: ('Tính năng mới', 'Mở để xem.'),
            en: ('Something new', 'Open to see.'),
          ),
        ],
      );
      final visits = await _pump(
        tester,
        const InboxScreen(),
        _overrides(repo, reporter: reporter),
      );
      await tester.tap(find.text('Album được cập nhật'));
      await tester.pumpAndSettle();
      // On top of the inbox: Back returns to it.
      expect(visits, ['/memories/album/a1']);
      final r = reporter.records.single;
      expect(r.inboxId, 'n_album00001');
      expect(r.surface, NotificationSurface.inbox);
      expect(r.outcome, NotificationOpenOutcome.navigated);
      expect(r.destination, 'MEMORIES_ALBUM');
    });

    testWidgets('an unknown kind stays in the inbox, without a toast', (
      tester,
    ) async {
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository()),
      );
      final outcome = await open(
        tester,
        NotificationTarget(kind: 'fromTheFuture', babyId: teddyId),
      );
      expect(outcome, NotificationOpenOutcome.navigated);
      expect(visits, isEmpty);
      expect(find.text('Mục này không còn mở được.'), findsNothing);
    });

    testWidgets('membership events (D-092): Gia đình chip, Thành viên screen', (
      tester,
    ) async {
      final reporter = FakeNotificationOpenReporter();
      final repo = FakeNotificationRepository(
        inbox: [
          inboxItem(
            'n_joined0001',
            kind: 'memberJoined',
            category: NotificationCategory.family,
            route: 'inbox',
            at: DateTime(2026, 10, 8, 9),
            vi: ('Có người vừa tham gia gia đình', 'Mở để xem.'),
            en: ('Someone joined the family', 'Open to see.'),
            data: {'babyId': teddyId},
          ),
          inboxItem(
            'n_removed001',
            kind: 'memberRemoved',
            category: NotificationCategory.family,
            route: 'inbox',
            at: DateTime(2026, 10, 8, 8),
            vi: ('Bạn không còn trong gia đình của bé', 'Mở để xem.'),
            en: ('You are no longer in the family', 'Open to see.'),
            // The removed person no longer follows this baby.
            babyId: 'b_removed_from',
            destination: 'INBOX',
          ),
        ],
      );
      final visits = await _pump(
        tester,
        const InboxScreen(),
        _overrides(repo, relative: true, reporter: reporter),
      );
      await tester.ensureVisible(find.byKey(const Key('ntChip-family')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ntChip-family')));
      await tester.pumpAndSettle();
      expect(find.text('Có người vừa tham gia gia đình'), findsOneWidget);
      expect(find.text('Bạn không còn trong gia đình của bé'), findsOneWidget);

      // Removed: the inbox is where it opens; no "gone" toast, nowhere else.
      await tester.tap(find.text('Bạn không còn trong gia đình của bé'));
      await tester.pumpAndSettle();
      expect(visits, isEmpty);
      expect(find.text('Mục này không còn mở được.'), findsNothing);
      expect(reporter.records.last.outcome, NotificationOpenOutcome.navigated);
      expect(reporter.records.last.destination, 'INBOX');

      // Joined: any member (here a relative) opens Gia đình.
      await tester.tap(find.text('Có người vừa tham gia gia đình'));
      await tester.pumpAndSettle();
      expect(visits, ['/utilities/family']);
      expect(reporter.records.last.destination, 'FAMILY_MEMBERS');
    });

    testWidgets('a memberRemoved push opens the inbox at once', (tester) async {
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository()),
      );
      final outcome = await open(
        tester,
        push({'kind': 'memberRemoved', 'babyId': 'b_removed_from'}),
        surface: NotificationSurface.push,
      );
      expect(outcome, NotificationOpenOutcome.navigated);
      expect(visits, ['/notifications']);
      expect(find.text('Mục này không còn mở được.'), findsNothing);
    });

    testWidgets('FAMILY_MEMBERS for a baby not in the session: inbox only', (
      tester,
    ) async {
      final visits = await _pump(
        tester,
        probe,
        _overrides(FakeNotificationRepository()),
      );
      final outcome = await open(
        tester,
        NotificationTarget(kind: 'roleChanged', babyId: 'b_other_account'),
      );
      expect(outcome, NotificationOpenOutcome.unavailable);
      expect(visits, isEmpty);
    });
  });
}
