import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/assistant/assistant_entry.dart'
    show AssistantTodayCard;
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/onboarding/setup_screens.dart';
import 'package:child_life/features/reminders/reminder_screens.dart'
    show notificationsAskedProvider;
import 'package:child_life/features/rhythm/rhythm_home.dart'
    show firstSentence, weekKicker;
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_personalize.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/hn_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

/// D-076 #1 (EN01–EN03 after a baby is created, the Home invite), #4 ("Dành cho bé hôm nay"),
/// #8 (its place in Tuỳ chỉnh) and #13 (no assistant card on Hôm nay).

class _FakeBabyRepository implements BabyRepository {
  @override
  Future<String> createBaby(NewBabyInput input) async => 'b_new';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _invite = Key('personalizeInvite');
const _today = Scaffold(body: TodayScreen());

void main() {
  group('Tuỳ chỉnh Hôm nay (D-076 #8)', () {
    test('"Dành cho bé hôm nay" comes right after the tiles by default', () {
      const d = TodayLayout();
      expect(d.order.take(4), [
        TodaySection.tiles,
        TodaySection.forYou,
        // D-085: 5h "Ăn dặm hôm nay" (while solids tracking is on).
        TodaySection.solids,
        TodaySection.reminders,
      ]);
      expect(d.toJson()['v'], TodayLayout.version);
    });

    test('a layout saved with it first moves it after the tiles', () {
      final layout = TodayLayout.fromJson({
        'order': [
          'forYou',
          'rhythm',
          'tiles',
          'reminders',
          'quickActions',
          'vaccine',
          'spending',
        ],
        'hidden': ['quickActions', 'vaccine', 'spending'],
      });
      expect(layout.order, [
        TodaySection.rhythm,
        TodaySection.tiles,
        TodaySection.forYou,
        TodaySection.solids,
        TodaySection.reminders,
        TodaySection.quickActions,
        TodaySection.vaccine,
        TodaySection.spending,
      ]);
      expect(layout.shows(TodaySection.forYou), isTrue);
      expect(layout.shows(TodaySection.solids), isTrue);
    });

    test('hidden stays hidden; a version-2 order is the person\'s own', () {
      final migrated = TodayLayout.fromJson({
        'order': ['forYou', 'tiles', 'reminders', 'rhythm'],
        'hidden': ['forYou'],
      });
      expect(migrated.shows(TodaySection.forYou), isFalse);
      expect(migrated.order.indexOf(TodaySection.forYou), 1);

      final own = TodayLayout.fromJson({
        'v': 2,
        'order': ['rhythm', 'forYou', 'tiles', 'reminders'],
      });
      expect(own.order.take(3), [
        TodaySection.rhythm,
        TodaySection.forYou,
        TodaySection.tiles,
      ]);
      expect(TodayLayout.fromJson(own.toJson()).toJson(), own.toJson());
    });

    testWidgets('Tuỳ chỉnh lists it after the tiles', (tester) async {
      await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
        ),
      );
      await tester.tap(find.text('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      final group = find.byKey(const Key('customizeSections'));
      double y(String text) => tester
          .getTopLeft(find.descendant(of: group, matching: find.text(text)))
          .dy;
      expect(y('Ô theo dõi nhanh'), lessThan(y('Dành cho bé hôm nay')));
      expect(y('Dành cho bé hôm nay'), lessThan(y('Nhắc việc sắp tới')));
    });
  });

  group('Hôm nay (D-076 #13, #4)', () {
    testWidgets('no assistant card; the section sits after the tiles', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
        ),
      );
      expect(find.byType(AssistantTodayCard), findsNothing);
      final tile = tester.getTopLeft(find.byType(CareTile).first).dy;
      final section = tester.getTopLeft(find.text('Dành cho bé hôm nay')).dy;
      expect(section, greaterThan(tile));
    });

    testWidgets('without the rhythm rollout: no section, no invite', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(repo: StampingRhythmRepository(), rhythm: false),
      );
      expect(find.text('Dành cho bé hôm nay'), findsNothing);
      expect(find.byKey(_invite), findsNothing);
    });
  });

  group('Home invite 559:57870 (D-076 #1)', () {
    testWidgets('shows until personalised; Bắt đầu opens EN01', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(repo: StampingRhythmRepository()),
      );
      expect(find.byKey(_invite), findsOneWidget);
      expect(find.text('Hôm nay theo cách của nhà bạn'), findsOneWidget);
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(visits.last.location, TodayRoutes.personalize);
    });

    testWidgets('× hides it for this person', (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(repo: StampingRhythmRepository()),
      );
      await tester.tap(find.bySemanticsLabel('Ẩn lời mời cá nhân hoá'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đã ẩn. Bạn vẫn chỉnh được trong Tôi › Cá nhân hoá.'),
        findsOne,
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.byKey(_invite), findsNothing);
      expect(container.read(personalizeInviteHiddenProvider(mai.uid)), isTrue);
    });

    for (final (who, me, shown) in [
      ('Mai', mai, false),
      ('Minh', minh, true),
    ]) {
      testWidgets(
        'read back after a restart: $who ${shown ? 'still sees' : 'does not see'} it',
        (tester) async {
          // Hidden by Mai on this phone; another person still sees it.
          await pumpRouted(
            tester,
            _today,
            overrides: hnOverrides(repo: StampingRhythmRepository(), me: me),
            prefs: {'today.personalizeInvite.hidden.${mai.uid}': true},
          );
          expect(find.byKey(_invite), shown ? findsOneWidget : findsNothing);
        },
      );
    }

    testWidgets('someone who already chose sees no invite', (tester) async {
      await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
        ),
      );
      expect(find.byKey(_invite), findsNothing);
    });
  });

  group('After creating a baby (D-076 #1)', () {
    testWidgets('12 "Xong" asks Hôm nay to open EN01 for the new baby', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const TrackersScreen(),
        overrides: [
          babyRepositoryProvider.overrideWithValue(_FakeBabyRepository()),
        ],
      );
      await tester.tap(find.text('Xong · 4 mục'));
      await tester.pumpAndSettle();
      expect(container.read(personalizeAfterSetupProvider), 'b_new');
    });

    testWidgets('Hôm nay opens EN01 once, for that baby', (tester) async {
      final (visits, container) = await pumpRouted(
        tester,
        _today,
        overrides: hnOverrides(repo: StampingRhythmRepository()),
      );
      expect(visits, isEmpty);
      container.read(personalizeAfterSetupProvider.notifier).request(teddyId);
      await tester.pumpAndSettle();
      expect(visits.map((v) => v.location), [TodayRoutes.personalize]);
      expect(container.read(personalizeAfterSetupProvider), isNull);
    });

    for (final (name, rhythm, prefs) in [
      ('without the rollout', false, UserPreferences.defaults),
      ('when this person already chose', true, personalized()),
    ]) {
      testWidgets('not $name', (tester) async {
        final (visits, container) = await pumpRouted(
          tester,
          _today,
          overrides: hnOverrides(
            repo: StampingRhythmRepository(preferences: prefs),
            rhythm: rhythm,
          ),
        );
        container.read(personalizeAfterSetupProvider.notifier).request(teddyId);
        await tester.pumpAndSettle();
        expect(visits, isEmpty);
        expect(container.read(personalizeAfterSetupProvider), isNull);
      });
    }
  });

  group('Notifications after onboarding (D-077 #1)', () {
    testWidgets('12 "Xong" asks for them too', (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        const TrackersScreen(),
        overrides: [
          babyRepositoryProvider.overrideWithValue(_FakeBabyRepository()),
        ],
      );
      await tester.tap(find.text('Xong · 4 mục'));
      await tester.pumpAndSettle();
      expect(container.read(notificationsAfterOnboardingProvider), 'b_new');
    });

    for (final (name, rhythm, prefs) in [
      ('joined by invite', true, personalized()),
      ('created without the rollout', false, UserPreferences.defaults),
    ]) {
      testWidgets('$name: Hôm nay opens EN03 on its own', (tester) async {
        final (visits, container) = await pumpRouted(
          tester,
          _today,
          overrides: hnOverrides(
            repo: StampingRhythmRepository(preferences: prefs),
            rhythm: rhythm,
            notifications: FakeReminderNotifications(on: false),
          ),
        );
        if (!rhythm) {
          container
              .read(personalizeAfterSetupProvider.notifier)
              .request(teddyId);
        }
        container
            .read(notificationsAfterOnboardingProvider.notifier)
            .request(teddyId);
        await tester.pumpAndSettle();
        expect(visits.map((v) => v.location), [TodayRoutes.notifications]);
        expect(container.read(notificationsAfterOnboardingProvider), isNull);
      });
    }

    for (final (name, on, asked) in [
      ('already on', true, false),
      ('asked before on this phone', false, true),
    ]) {
      testWidgets('not when $name', (tester) async {
        final (visits, container) = await pumpRouted(
          tester,
          _today,
          overrides: hnOverrides(
            repo: StampingRhythmRepository(preferences: personalized()),
            notifications: FakeReminderNotifications(on: on),
          ),
        );
        if (asked) {
          await container.read(notificationsAskedProvider.notifier).mark();
        }
        container
            .read(notificationsAfterOnboardingProvider.notifier)
            .request(teddyId);
        await tester.pumpAndSettle();
        expect(visits, isEmpty);
      });
    }

    testWidgets('EN03 on its own: what every family gets, then the system', (
      tester,
    ) async {
      final notifications = FakeReminderNotifications(on: false);
      final (visits, container) = await pumpRouted(
        tester,
        const PersonalizeFlowScreen(notificationsOnly: true),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(),
          rhythm: false,
          notifications: notifications,
        ),
      );
      expect(find.text('Để Child Life nhắc bạn đúng lúc'), findsOneWidget);
      expect(
        find.text(
          'Lịch tiêm, nhắc việc bạn tự đặt và những ngày đáng nhớ của con. '
          'Không quảng cáo.',
        ),
        findsOneWidget,
      );
      expect(find.text('“Hôm nay Teddy tròn 1 tháng.”'), findsOneWidget);
      expect(find.text('Nhịp lớn lên'), findsNothing);
      expect(find.text('Bỏ qua'), findsNothing);
      await tester.tap(find.text('Bật thông báo'));
      await tester.pumpAndSettle();
      expect(notifications.requests, 1);
      expect(container.read(notificationsAskedProvider), isTrue);
      expect(visits.last.location, Routes.today);
    });
  });

  group('EN01 → EN02 → EN03', () {
    testWidgets('each step saves; only "Bật thông báo" asks the system', (
      tester,
    ) async {
      final repo = StampingRhythmRepository();
      final notifications = FakeReminderNotifications(on: false);
      final (visits, container) = await pumpRouted(
        tester,
        const PersonalizeFlowScreen(),
        overrides: hnOverrides(repo: repo, notifications: notifications),
      );
      expect(find.text('Bạn muốn đồng hành cùng Teddy ở những gì?'), findsOne);
      expect(find.text('Tiếp tục'), findsOneWidget);
      await tester.tap(find.text('Giấc ngủ'));
      await tester.tap(find.text('Mốc phát triển'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục · 2 mục'));
      await tester.pumpAndSettle();
      expect(repo.preferences.interests, [Interest.sleep, Interest.milestones]);

      expect(find.text('Khi nào bạn tiện đọc gợi ý?'), findsOneWidget);
      await tester.tap(find.text('Buổi sáng · 08:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(repo.preferences.digestTime, '08:00');
      expect(repo.preferences.interests, [Interest.sleep, Interest.milestones]);
      expect(notifications.requests, 0);

      expect(find.text('Để Child Life nhắc bạn đúng lúc'), findsOneWidget);
      await tester.tap(find.text('Bật thông báo'));
      await tester.pumpAndSettle();
      expect(notifications.requests, 1);
      expect(container.read(notificationsAskedProvider), isTrue);
      expect(visits.last.location, Routes.today);
    });

    testWidgets('"Để sau" never asks the system', (tester) async {
      final notifications = FakeReminderNotifications(on: false);
      final (_, container) = await pumpRouted(
        tester,
        const PersonalizeFlowScreen(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(),
          notifications: notifications,
        ),
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(notifications.requests, 0);
      expect(container.read(notificationsAskedProvider), isFalse);
    });

    testWidgets('notifications already on: EN03 is not shown', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const PersonalizeFlowScreen(),
        overrides: hnOverrides(repo: StampingRhythmRepository()),
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Để Child Life nhắc bạn đúng lúc'), findsNothing);
      expect(visits.last.location, Routes.today);
    });

    testWidgets('"Bỏ qua" on EN01 saves nothing: the invite stays', (
      tester,
    ) async {
      final repo = StampingRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const PersonalizeFlowScreen(),
        overrides: hnOverrides(repo: repo),
      );
      await tester.tap(find.text('Giấc ngủ'));
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      expect(repo.savedPreferences, isEmpty);
      expect(visits.last.location, Routes.today);
      expect(hasPersonalized(repo.preferences), isFalse);
    });
  });

  group('"Dành cho bé hôm nay" (D-076 #4)', () {
    Widget section() =>
        Scaffold(body: ListView(children: const [TodayForBabySection()]));

    testWidgets('heading, interests line and the Nhịp lớn lên card', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        section(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
        ),
      );
      expect(find.text('Dành cho bé hôm nay'), findsOneWidget);
      // Owner 2026-10-18: interests are a button by the title, not a line under it.
      expect(find.text('Theo điều bạn quan tâm'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('^Theo điều bạn quan tâm · Đổi')),
        findsOneWidget,
      );
      // Nhịp lớn lên is a compact row of "Tuần này của Teddy" (no "Beta" pill to parents).
      expect(find.text('Tuần này của Teddy'), findsOneWidget);
      expect(find.text('Nhịp lớn lên · Beta'), findsNothing);
      expect(find.text('Còn 4 ngày đến giai đoạn 1'), findsOneWidget);
      expect(find.text('Wonder Weeks · dự kiến 12/10 – 21/10'), findsOne);
      expect(find.text('LỊCH THAM KHẢO'), findsNothing);
      await tester.tap(find.byKey(const Key('forBabyRhythm')));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.rhythm);
      GoRouter.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('forBabyCarousel')), findsNothing);
      await tester.tap(find.byKey(const Key('forBabyChange')));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.rhythmInterests);
    });

    testWidgets('no interests yet: "Chọn"; soothing check-ins are told', (
      tester,
    ) async {
      CheckIn soothing(String date, String uid) => CheckIn(
        id: 'ci_$date$uid',
        babyId: teddyId,
        date: date,
        authorUid: uid,
        observation: Observation.soothing,
      );
      await pumpRouted(
        tester,
        section(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(
            checkIns: [
              soothing('2026-10-07', 'u_mai'),
              soothing('2026-10-06', 'u_minh'),
              soothing('2026-10-07', 'u_minh'),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Chưa chọn điều bạn quan tâm · Chọn')),
        findsOneWidget,
      );
      expect(
        find.textContaining('cần được dỗ nhiều hơn 2 ngày qua'),
        findsOneWidget,
      );
    });

    testWidgets('a health day hides the Nhịp lớn lên card', (tester) async {
      await pumpRouted(
        tester,
        section(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(
            checkIns: [
              CheckIn(
                id: 'ci_health',
                babyId: teddyId,
                date: rhythmToday,
                authorUid: 'u_mai',
                observation: Observation.health,
                healthSigns: const [HealthSign.feverYoung],
              ),
            ],
          ),
        ),
      );
      expect(find.byKey(const Key('forBabyRhythm')), findsNothing);
    });

    testWidgets('small cards from other modules, interests first', (
      tester,
    ) async {
      final opened = <String>[];
      await pumpRouted(
        tester,
        section(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(
            preferences: personalized(interests: [Interest.milestones]),
          ),
          articles: sampleForBabyCards(opened: opened).take(1).toList(),
          milestones: sampleForBabyCards(opened: opened).skip(1).toList(),
        ),
      );
      final milestone = find.text('Bé ngẩng đầu khi nằm sấp');
      final article = find.text('Vì sao bé hay giật mình khi ngủ?');
      expect(
        tester.getTopLeft(milestone).dx,
        lessThan(tester.getTopLeft(article).dx),
      );
      await tester.ensureVisible(milestone);
      await tester.pumpAndSettle();
      await tester.tap(milestone);
      await tester.tap(find.bySemanticsLabel('Tuỳ chọn cho thẻ này').first);
      expect(opened, ['milestone', 'dismiss']);
    });

    testWidgets('Tuần này: the stage teaser first; its small card leaves the '
        'carousel', (tester) async {
      final opened = <String>[];
      await pumpRouted(
        tester,
        section(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
          articles: [sampleStageCard(), ...sampleForBabyCards().take(1)],
          milestones: sampleForBabyCards().skip(1).toList(),
          weekTeaser: sampleStageTeaser(opened: opened),
        ),
      );
      // Week of life 4 = three completed weeks (Teddy is 21 days old on 8/10).
      expect(find.text('3 tuần tuổi'), findsOneWidget);
      expect(
        find.text('Bé bắt đầu nhìn theo mặt người khi được bế gần'),
        findsOneWidget,
      );
      expect(find.text('Xem 3 gợi ý cho tuần này'), findsOneWidget);
      // Not the age card's teaser, and the stage is not on Home twice.
      expect(find.textContaining('Nhiều bé ở tuần này'), findsNothing);
      expect(find.text('Tuần 3–4: nhìn, nghe và được ôm'), findsNothing);
      expect(find.text('Để ý tuần này'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('forBabyWeek')));
      await tester.tap(find.byKey(const Key('forBabyWeek')));
      expect(opened, ['stage']);
    });

    testWidgets('order: today (carousel, check-in), then "Tuần này" with its '
        'rows', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        section(),
        overrides: hnOverrides(
          repo: StampingRhythmRepository(preferences: personalized()),
          articles: sampleForBabyCards().take(1).toList(),
          milestones: sampleForBabyCards().skip(1).toList(),
        ),
      );
      double y(Finder f) => tester.getTopLeft(f).dy;
      final order = [
        find.text('Dành cho bé hôm nay'),
        find.byKey(const Key('forBabyCarousel')),
        find.byKey(const Key('forBabyCheckIn')),
        find.text('Tuần này của Teddy'),
        find.byKey(const Key('forBabyWeek')),
        find.byKey(const Key('forBabyRhythm')),
        find.byKey(const Key('forBabyWeekSummary')),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(y(order[i]), greaterThan(y(order[i - 1])), reason: '$i');
      }
      // The summary row uses the same dates as EN09 and no week number of its own.
      expect(find.text('Tóm tắt tuần trước'), findsOneWidget);
      expect(find.text('28/09 – 04/10'), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('forBabyWeekSummary')));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.rhythmWeek);
    });

    testWidgets('nothing published: no teaser, the rows stay', (tester) async {
      final repo = StampingRhythmRepository(preferences: personalized())
        ..content = null;
      await pumpRouted(tester, section(), overrides: hnOverrides(repo: repo));
      expect(find.text('Dành cho bé hôm nay'), findsOneWidget);
      expect(find.byKey(const Key('forBabyCheckIn')), findsOneWidget);
      expect(find.byKey(const Key('forBabyWeek')), findsNothing);
      expect(find.text('Tuần này của Teddy'), findsOneWidget);
      expect(find.byKey(const Key('forBabyRhythm')), findsOneWidget);
      expect(find.byKey(const Key('forBabyWeekSummary')), findsOneWidget);
    });

    test('the kicker is the age alone, weeks with their extra days '
        '(owner 2026-10-22)', () {
      final vi = lookupAppLocalizations(const Locale('vi'));
      final dob = DateTime(2026, 9, 17);
      String? k(DateTime today) => weekKicker(vi, dob: dob, today: today);
      expect(k(DateTime(2026, 9, 17)), 'mới chào đời');
      expect(k(DateTime(2026, 9, 22)), '5 ngày tuổi');
      expect(k(DateTime(2026, 10, 1)), '2 tuần tuổi');
      expect(k(DateTime(2026, 10, 7)), '2 tuần 6 ngày tuổi');
      expect(k(DateTime(2026, 10, 8)), '3 tuần tuổi');
      expect(k(DateTime(2026, 10, 24)), '5 tuần 2 ngày tuổi');
      // From 13 weeks, months, as the age chip and the content say it.
      expect(k(DateTime(2026, 12, 17)), '3 tháng tuổi');
      expect(k(DateTime(2027, 1, 30)), '4 tháng tuổi');
      expect(k(DateTime(2026, 9, 1)), isNull);
      // Without the date of birth (caregivers): from the age card's range.
      AgeCard card(int from, int to) => AgeCard(
        id: 'age_x',
        version: 1,
        status: ContentStatus.published,
        ageDays: AgeRange(from, to),
        title: const Localized('', ''),
        body: const Localized('', ''),
      );
      expect(
        weekKicker(
          vi,
          dob: null,
          today: DateTime(2026, 10, 8),
          card: card(28, 34),
        ),
        'Tuần thứ 5',
      );
      expect(
        weekKicker(
          vi,
          dob: null,
          today: DateTime(2026, 10, 8),
          card: card(122, 151),
        ),
        'Tháng thứ 5',
      );
      expect(weekKicker(vi, dob: null, today: DateTime(2026, 10, 8)), isNull);
    });

    test('teaser: the first sentence of the content', () {
      expect(
        firstSentence(
          'Khóc thường tăng dần và hay nhiều nhất vào khoảng 6–8 tuần tuổi, rồi giảm dần. '
          'Nhiều bé quấy nhiều vào chiều tối.',
        ),
        'Khóc thường tăng dần và hay nhiều nhất vào khoảng 6–8 tuần tuổi, rồi giảm dần.',
      );
      expect(
        firstSentence(' Một câu không dấu chấm '),
        'Một câu không dấu chấm',
      );
      expect(
        firstSentence('Cân 3.5 kg là thường gặp. Tiếp.'),
        'Cân 3.5 kg là thường gặp.',
      );
    });

    test(
      'ranking: interests first, fewer topics last, at most two supporting cards',
      () {
        ForBabyCard card(String id, Interest? i) => ForBabyCard(
          id: id,
          kicker: id,
          title: id,
          action: id,
          interest: i,
          onOpen: (_) {},
        );
        final prefs = UserPreferences.fromJson({
          'interests': ['milestones'],
          'digestTime': null,
          'quietHours': null,
          'fewer': ['feeding'],
          'updatedAt': null,
        });
        final ranked = rankForBabyCards([
          card('a', Interest.sleep),
          card('b', Interest.feeding),
          card('c', Interest.milestones),
          card('a', Interest.sleep),
          card('d', null),
          card('e', Interest.milestones),
        ], prefs);
        expect(ranked.map((c) => c.id), ['c', 'e']);
      },
    );

    test('soothing days count the last three days', () {
      CheckIn ci(String date, Observation o) => CheckIn(
        id: '$date${o.name}',
        babyId: teddyId,
        date: date,
        authorUid: 'u_mai',
        observation: o,
      );
      expect(
        soothingDays([
          ci('2026-10-08', Observation.soothing),
          ci('2026-10-06', Observation.soothing),
          ci('2026-10-05', Observation.soothing),
          ci('2026-10-07', Observation.sleep),
        ], '2026-10-08'),
        2,
      );
    });
  });
}
