import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/keepsakes/keepsake_access.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/rhythm/activity_history_screen.dart';
import 'package:child_life/features/rhythm/activity_screens.dart';
import 'package:child_life/features/rhythm/rhythm_home.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_plans.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/features/rhythm/rhythm_week.dart';
import 'package:child_life/features/rhythm/week_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

/// D-076 #10 (a plan waits for its chance, then asks with "Chưa thử"; "Các cách đã thử") and
/// #3 (EN09 "Tạo video tuần N"). The clock is Thu 08/10 10:00 in Hà Nội.
final l10n = lookupAppLocalizations(const Locale('vi'));
const _zone = 'Asia/Ho_Chi_Minh';

var _n = 0;
RecFeedback _fb(
  FeedbackKind kind, {
  String by = 'u_minh',
  String contentId = 'act_wind_down',
  String date = rhythmToday,
  DateTime? at,
  String? note,
}) => RecFeedback(
  id: 'fb_${(++_n).toRadixString(16).padLeft(32, '0')}',
  babyId: teddyId,
  authorUid: by,
  contentId: contentId,
  contentVersion: contentId == 'act_skin_to_skin' ? 2 : 1,
  kind: kind,
  date: date,
  note: note,
  createdAt: at,
);

Widget _home() => Scaffold(body: ListView(children: const [ForYouSection()]));

Future<(List<Visit>, FakeRhythmRepository)> _pumpHome(
  WidgetTester tester,
  List<RecFeedback> feedback,
) async {
  final repo = FakeRhythmRepository(
    home: HomeComposition.fromJson({
      ...h02Json(),
      'recommendation': recommendationJson(state: 'started'),
    }),
    checkIns: [sleepCheckIn()],
    feedback: feedback,
  );
  final (visits, _) = await pumpRouted(
    tester,
    _home(),
    overrides: rhythmOverrides(
      me: minh,
      repo: repo,
      caps: rhythmCaps(plan: 'beta', groupA: true),
    ),
  );
  await tester.pumpAndSettle();
  return (visits, repo);
}

Map<String, Object?> h02Json() => {
  'state': 'suggestion',
  'recommendation': recommendationJson(),
  'secondary': <Object>[],
  'ageCardId': 'age_week_3',
  'gate': null,
  'sleep': null,
  'lastFeedback': null,
};

void main() {
  group('when the result is asked (CH17 rule)', () {
    DateTime opens(ActivityTime t, DateTime plannedAt) => planFeedbackOpensAt(
      zone: _zone,
      plannedFor: '2026-10-08',
      timeOfDay: t,
      plannedAt: plannedAt,
    );

    test('an evening or any-time plan: the next morning at 05:00', () {
      final morning = DateTime.utc(2026, 10, 8, 22); // 09/10 05:00 in Hà Nội
      expect(
        opens(ActivityTime.evening, DateTime.utc(2026, 10, 8, 3)),
        morning,
      );
      expect(opens(ActivityTime.any, DateTime.utc(2026, 10, 8, 3)), morning);
    });

    test('a daytime plan: 18:00 the same day, after that the next morning', () {
      expect(
        opens(ActivityTime.day, DateTime.utc(2026, 10, 8, 3)),
        DateTime.utc(2026, 10, 8, 11),
      );
      expect(
        opens(ActivityTime.day, DateTime.utc(2026, 10, 8, 12)),
        DateTime.utc(2026, 10, 8, 22),
      );
    });

    test('an open plan is the newest row about the activity', () {
      final plan = _fb(FeedbackKind.started, at: DateTime.utc(2026, 10, 8, 2));
      final now = DateTime.utc(2026, 10, 8, 3);
      final open = openPlan(
        [plan],
        'act_wind_down',
        zone: _zone,
        timeOfDay: ActivityTime.evening,
        now: now,
      );
      expect(open!.due, isFalse);
      expect(
        openPlan(
          [plan],
          'act_wind_down',
          zone: _zone,
          timeOfDay: ActivityTime.evening,
          now: DateTime.utc(2026, 10, 8, 23),
        )!.due,
        isTrue,
      );
      final answered = _fb(
        FeedbackKind.helpful,
        at: DateTime.utc(2026, 10, 8, 2, 30),
      );
      expect(
        openPlan(
          newestFirst([plan, answered]),
          'act_wind_down',
          zone: _zone,
          timeOfDay: ActivityTime.evening,
          now: now,
        ),
        isNull,
      );
      // "Chưa thử" on someone else's plan sets it aside for me.
      expect(
        openPlan(
          [plan],
          'act_wind_down',
          zone: _zone,
          timeOfDay: ActivityTime.evening,
          now: now,
          setAside: {plan.id},
        ),
        isNull,
      );
    });

    test(
      'tries: a plan gathers the answers after it; put-offs are not tries',
      () {
        final p1 = _fb(
          FeedbackKind.started,
          by: 'u_mai',
          date: '2026-10-05',
          at: DateTime.utc(2026, 10, 5, 12),
        );
        final a1 = _fb(
          FeedbackKind.helpful,
          date: '2026-10-06',
          at: DateTime.utc(2026, 10, 6, 1),
        );
        final a2 = _fb(
          FeedbackKind.unsure,
          by: 'u_mai',
          date: '2026-10-06',
          at: DateTime.utc(2026, 10, 6, 2),
        );
        final off = _fb(
          FeedbackKind.notToday,
          date: '2026-10-07',
          at: DateTime.utc(2026, 10, 7, 1),
        );
        final p2 = _fb(FeedbackKind.started, at: DateTime.utc(2026, 10, 8, 1));
        final lone = _fb(
          FeedbackKind.notSuitable,
          contentId: 'act_skin_to_skin',
          date: '2026-10-04',
          at: DateTime.utc(2026, 10, 4, 1),
        );
        final entries = triedEntries([p2, off, a2, lone, a1, p1]);
        expect(entries.length, 3);
        expect(entries[0].plan, p2);
        expect(entries[0].answers, isEmpty);
        expect(entries[1].plan, p1);
        expect(entries[1].answers, [a1, a2]);
        expect(entries[2].plan, isNull);
        expect(entries[2].answers, [lone]);
      },
    );
  });

  group('H02 after "Thử tối nay"', () {
    testWidgets('waits: planned for tonight, no "Kể lại kết quả" yet', (
      tester,
    ) async {
      final plan = _fb(FeedbackKind.started, at: DateTime.utc(2026, 10, 8, 2));
      final (_, repo) = await _pumpHome(tester, [plan]);
      expect(find.text(l10n.rhKickerTonight), findsOneWidget);
      expect(find.text(l10n.rhPlannedTonight), findsOneWidget);
      expect(find.text(l10n.rhPlanAskMorning), findsOneWidget);
      expect(find.text(l10n.rhTellHow), findsNothing);
      expect(find.text(l10n.rhTryTonight), findsNothing);
      // "Bỏ kế hoạch" takes my plan back: the idea can be planned again.
      await tester.tap(find.text(l10n.rhCancelPlan));
      await tester.pumpAndSettle();
      expect(repo.deletedFeedback, [plan.id]);
      expect(find.text(l10n.rhPlanCanceled), findsOneWidget);
      expect(find.text(l10n.rhTryTonight), findsOneWidget);
    });

    testWidgets('someone else\'s plan: who planned it, no "Bỏ kế hoạch"', (
      tester,
    ) async {
      await _pumpHome(tester, [
        _fb(
          FeedbackKind.started,
          by: 'u_mai',
          at: DateTime.utc(2026, 10, 8, 2),
        ),
      ]);
      expect(find.text(l10n.rhPlannedTonight), findsOneWidget);
      expect(find.text('Mẹ lên kế hoạch · tối 08/10'), findsOneWidget);
      expect(find.text(l10n.rhCancelPlan), findsNothing);
    });

    testWidgets('after the chance: "Kể lại kết quả" with "Chưa thử"', (
      tester,
    ) async {
      final plan = _fb(
        FeedbackKind.started,
        date: '2026-10-07',
        at: DateTime.utc(2026, 10, 7, 13),
      );
      final (visits, repo) = await _pumpHome(tester, [plan]);
      expect(find.text(l10n.rhKickerFollowUp), findsOneWidget);
      expect(find.text(l10n.rhPlannedOn('tối 07/10')), findsOneWidget);
      expect(find.text(l10n.rhPlanAskMorning), findsNothing);
      expect(find.text(l10n.rhDidNotTry), findsOneWidget);
      await tester.tap(find.text(l10n.rhTellHow));
      await tester.pumpAndSettle();
      expect(
        visits.last.location,
        '${Routes.rhythmActivity}/act_wind_down/feedback',
      );
      expect(repo.deletedFeedback, isEmpty);
    });

    testWidgets('"Chưa thử" on someone else\'s plan sets it aside for me', (
      tester,
    ) async {
      final plan = _fb(
        FeedbackKind.started,
        by: 'u_mai',
        date: '2026-10-07',
        at: DateTime.utc(2026, 10, 7, 13),
      );
      final (_, repo) = await _pumpHome(tester, [plan]);
      await tester.tap(find.text(l10n.rhDidNotTry));
      await tester.pumpAndSettle();
      // Only its author may delete it: nothing written, set aside on this phone.
      expect(repo.deletedFeedback, isEmpty);
      expect(find.text(l10n.rhDidNotTryToast), findsOneWidget);
      expect(find.text(l10n.rhTryTonight), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('rhythm.plansSetAside.u_minh|$teddyId'), [
        plan.id,
      ]);
    });
  });

  group('AC02 and a plan', () {
    Future<FakeRhythmRepository> pumpAc02(
      WidgetTester tester,
      RecFeedback plan,
    ) async {
      final repo = FakeRhythmRepository(feedback: [plan]);
      await pumpRouted(
        tester,
        const ActivityFeedbackScreen(contentId: 'act_wind_down'),
        overrides: rhythmOverrides(me: minh, repo: repo),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('before the chance: when it will be asked, no answers', (
      tester,
    ) async {
      await pumpAc02(
        tester,
        _fb(FeedbackKind.started, at: DateTime.utc(2026, 10, 8, 2)),
      );
      expect(find.text(l10n.rhPlanAskMorning), findsOneWidget);
      expect(find.text(l10n.rhSaveFeedback), findsNothing);
      expect(find.text(l10n.rhHelpful), findsNothing);
      expect(find.text(l10n.rhCancelPlan), findsOneWidget);
    });

    testWidgets('after it: the answers and "Chưa thử"', (tester) async {
      final plan = _fb(
        FeedbackKind.started,
        date: '2026-10-07',
        at: DateTime.utc(2026, 10, 7, 13),
      );
      final repo = await pumpAc02(tester, plan);
      expect(find.text(l10n.rhHowLastNight), findsOneWidget);
      expect(find.text(l10n.rhSaveFeedback), findsOneWidget);
      await tester.tap(find.text(l10n.rhDidNotTry));
      await tester.pumpAndSettle();
      expect(repo.deletedFeedback, [plan.id]);
      expect(repo.savedFeedback, isEmpty);
    });
  });

  group('"Các cách đã thử"', () {
    testWidgets('every plan and answer, who and when; open ones answerable', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        feedback: [
          _fb(
            FeedbackKind.started,
            by: 'u_mai',
            date: '2026-10-05',
            at: DateTime.utc(2026, 10, 5, 12),
          ),
          _fb(
            FeedbackKind.helpful,
            date: '2026-10-06',
            at: DateTime.utc(2026, 10, 6, 1),
            note: 'Con vào giấc nhanh hơn',
          ),
          _fb(
            FeedbackKind.started,
            by: 'u_mai',
            contentId: 'act_skin_to_skin',
            date: '2026-10-07',
            at: DateTime.utc(2026, 10, 7, 2),
          ),
        ],
      );
      final (visits, _) = await pumpRouted(
        tester,
        const ActivityHistoryScreen(),
        overrides: rhythmOverrides(me: minh, repo: repo),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.rhTriedHistoryTitle), findsOneWidget);
      expect(find.text('Mẹ lên kế hoạch · tối 05/10'), findsOneWidget);
      expect(find.text('Bạn · 06/10 · ${l10n.rhHelpful}'), findsOneWidget);
      expect(find.text('“Con vào giấc nhanh hơn”'), findsOneWidget);
      expect(find.text('Mẹ lên kế hoạch · 07/10'), findsOneWidget);
      // The skin-to-skin plan's chance has passed: answer it here.
      expect(find.text(l10n.rhDidNotTry), findsOneWidget);
      await tester.tap(find.text(l10n.rhTellHow));
      await tester.pumpAndSettle();
      expect(
        visits.last.location,
        '${Routes.rhythmActivity}/act_skin_to_skin/feedback',
      );
    });

    testWidgets('nothing yet', (tester) async {
      await pumpRouted(
        tester,
        const ActivityHistoryScreen(),
        overrides: rhythmOverrides(me: minh, repo: FakeRhythmRepository()),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.rhTriedHistoryEmpty), findsOneWidget);
    });
  });

  group('EN09 "Tạo video tuần N"', () {
    const week = SummaryWeek(
      start: '2026-09-28',
      end: '2026-10-04',
      inProgress: false,
    );
    final inWeek = [
      mediaItem('mem_a', DateTime.utc(2026, 10, 1, 3)),
      mediaItem('mem_b', DateTime.utc(2026, 9, 28, 1)),
    ];
    final outside = [
      mediaItem('mem_c', DateTime.utc(2026, 10, 6, 3)),
      mediaItem('mem_d', DateTime.utc(2026, 10, 2, 3), video: true),
      mediaItem('mem_e', DateTime.utc(2026, 10, 2, 3), generated: 'card'),
    ];

    Future<List<Visit>> pump(
      WidgetTester tester, {
      bool videos = true,
      List<MediaItem>? media,
      int? n = 3,
    }) async {
      final (visits, _) = await pumpRouted(
        tester,
        Scaffold(
          body: WeekVideoButton(
            me: mai,
            week: week,
            zone: _zone,
            weekOfLife: n,
          ),
        ),
        overrides: [
          ...rhythmOverrides(me: mai, repo: FakeRhythmRepository()),
          keepsakeAccessProvider.overrideWith(
            (ref, id) async => (cards: true, videos: videos),
          ),
          mediaProvider.overrideWith(
            (ref, key) => Stream.value(media ?? [...inWeek, ...outside]),
          ),
        ],
      );
      await tester.pumpAndSettle();
      return visits;
    }

    test('the week\'s own photos, oldest first', () {
      final photos = weekPhotos([...inWeek, ...outside], week, _zone);
      expect(photos.map((m) => m.memoryId), ['mem_b', 'mem_a']);
    });

    testWidgets('opens Video kỷ niệm with the week\'s photos', (tester) async {
      final visits = await pump(tester);
      expect(find.text('Tạo video tuần thứ 3'), findsOneWidget);
      expect(find.text('2 ảnh trong tuần được chọn sẵn'), findsOneWidget);
      await tester.tap(find.text('Tạo video tuần thứ 3'));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.memoryStory);
      expect(visits.last.extra, [inWeek[1].id, inWeek[0].id]);
    });

    testWidgets('without the week of life: "Tạo video của tuần"', (
      tester,
    ) async {
      await pump(tester, n: null);
      expect(find.text(l10n.rhWeekMakeVideoPlain), findsOneWidget);
    });

    testWidgets('hidden without the memory_story flag', (tester) async {
      await pump(tester, videos: false);
      expect(find.byKey(const ValueKey('rh.weekVideo')), findsNothing);
    });

    testWidgets('hidden without a photo from the week', (tester) async {
      await pump(tester, media: outside);
      expect(find.byKey(const ValueKey('rh.weekVideo')), findsNothing);
    });
  });
}
