import 'dart:convert';

import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/ai/ai_repository.dart' show aiShareProvider;
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_format.dart' show durationLabel;
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart';
import 'package:child_life/features/rhythm/rhythm_episodes.dart'
    show episodeIdFor;
import 'package:child_life/features/rhythm/rhythm_home.dart';
import 'package:child_life/features/rhythm/rhythm_local.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_overview.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart'
    show checkInIdFor, newestFirst;
import 'package:child_life/features/rhythm/rhythm_setup.dart';
import 'package:child_life/features/rhythm/rhythm_week.dart';
import 'package:child_life/features/rhythm/week_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/rhythm_week_fixtures.dart';
import '../helpers/router_pump.dart';

/// EN09 "Tóm tắt tuần" (561:3102) and its Sunday 20:30 notification (EN07): the week (Mon–Sun
/// in the baby's zone), valid days counted automatically with their coverage, averages over valid
/// days only (missing is never zero), entries per person without ranking, the group A look-back
/// or its gate by reason, visibility by `history.read`, the share text and the NL02c switch.
final l10n = lookupAppLocalizations(const Locale('vi'));
final en = lookupAppLocalizations(const Locale('en'));
const _zone = 'Asia/Ho_Chi_Minh';

/// The completed week 28/9 – 4/10 seen on Thursday 8/10.
WeekFacts _facts({
  List<CareRecord>? log,
  List<CareRecord> growth = const [],
  DateTime? now,
  String today = rhythmToday,
}) => weekFacts(
  zone: _zone,
  week: summaryWeekFor(today),
  now: now ?? rhythmNow,
  records: log ?? weekLog(),
  growth: growth,
  memories: weekMemories(),
);

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// A relative (Bà nội) with or without "Chăm sóc hằng ngày".
Membership _grandma({required bool dailyCare}) => member(
  'u_hoa',
  'Bà nội Hoa',
  MemberRole.relative,
  Relation.grandmother,
  extra: ExtraRights(viewBabyInfo: true, viewDailyCare: dailyCare),
);

CheckIn _ci(String uid, String date, Observation o) => CheckIn(
  id: checkInIdFor(babyId: teddyId, uid: uid, date: date, observation: o),
  babyId: teddyId,
  date: date,
  authorUid: uid,
  observation: o,
);

void main() {
  setUpAll(initializeDateFormatting);

  group('the week', () {
    test('Mon–Sun in the baby’s zone; a Sunday is the week still running', () {
      final thu = summaryWeekFor('2026-10-08');
      expect(
        (thu.start, thu.end, thu.inProgress),
        ('2026-09-28', '2026-10-04', false),
      );
      expect(thu.dates.first, '2026-09-28');
      expect(thu.dates.last, '2026-10-04');
      expect((thu.nextStart, thu.nextEnd), ('2026-10-05', '2026-10-11'));
      final sun = summaryWeekFor('2026-10-11');
      expect(
        (sun.start, sun.end, sun.inProgress),
        ('2026-10-05', '2026-10-11', true),
      );
      final mon = summaryWeekFor('2026-10-12');
      expect(
        (mon.start, mon.end, mon.inProgress),
        ('2026-10-05', '2026-10-11', false),
      );
      // Across a year end.
      final jan = summaryWeekFor('2027-01-02');
      expect((jan.start, jan.end), ('2026-12-21', '2026-12-27'));
    });

    test('"Tuần n" counts weeks of life from the date of birth', () {
      final dob = DateTime(2026, 9, 17);
      expect(weekOfLife(dob, summaryWeekFor('2026-10-08')), 3);
      expect(weekOfLife(dob, summaryWeekFor('2026-10-11')), 4);
      expect(
        weekOfLife(DateTime(2026, 10, 4), summaryWeekFor('2026-10-08')),
        1,
      );
      expect(
        weekOfLife(DateTime(2026, 10, 5), summaryWeekFor('2026-10-08')),
        null,
      );
      // A whole week has passed once the baby was born by the week's Monday.
      expect(
        weekHasPassed(DateTime(2026, 9, 28), summaryWeekFor('2026-10-08')),
        true,
      );
      expect(
        weekHasPassed(DateTime(2026, 9, 29), summaryWeekFor('2026-10-08')),
        false,
      );
      expect(weekHasPassed(null, summaryWeekFor('2026-10-08')), true);
    });

    test('labels: "28 tháng 9 – 4 tháng 10", "5 – 11 tháng 10"', () {
      expect(
        weekRangeLabel(l10n, const Locale('vi'), '2026-09-28', '2026-10-04'),
        '28 tháng 9 – 4 tháng 10',
      );
      expect(
        weekRangeLabel(l10n, const Locale('vi'), '2026-10-05', '2026-10-11'),
        '5 – 11 tháng 10',
      );
      expect(
        weekRangeLabel(en, const Locale('en'), '2026-10-05', '2026-10-11'),
        '5 – 11 October',
      );
    });
  });

  group('free records', () {
    test('feeds in ml and minutes apart, diapers, valid days, authors', () {
      final f = _facts(growth: weekGrowth());
      expect(f.feeds, 20);
      expect((f.bottleCount, f.bottleMl), (10, 950));
      // Breastfeeding stays in minutes (never converted to ml).
      expect((f.breastCount, f.breastMinutes), (10, 175));
      expect((f.diapers, f.wet, f.dirty), (10, 5, 5));
      expect(f.validDays, 5);
      expect(
        [for (final d in f.days) d.valid],
        [true, true, false, false, true, true, true],
      );
      // The night before the week crosses into Monday and counts there.
      expect(f.days.first.sleepMinutes, 13 * 60);
      // Wednesday logged sleep but has long gaps: reported, never averaged.
      expect(f.days[2].reasons, contains(DayInvalidReason.sparse));
      expect(f.days[2].sleepMinutes, 6 * 60);
      // (4 × 13 h + 14 h) / 5 valid days, not / 7.
      expect(f.averageSleepMinutes, 792);
      // In the order people first logged, never by count.
      expect(
        [for (final a in f.authors) (a.uid, a.count)],
        [('u_mai', 15), ('u_lan', 10), ('u_minh', 16)],
      );
      expect(f.growth?.weightKg, 4.3);
      expect(f.previousWeight?.weightKg, 3.9);
      expect((f.photos, f.videos, f.notes), (3, 1, 1));
    });

    test(
      'missing days are never zero: under the minimum there is no average',
      () {
        final f = _facts(log: weekLog(fullDays: const {0, 1, 4}));
        expect(f.validDays, 3);
        expect(f.minValidDays, defaultRhythmRules.baselineMinDays);
        expect(f.averageSleepMinutes, isNull);
        final empty = _facts(log: const []);
        expect(empty.validDays, 0);
        expect(empty.averageSleepMinutes, isNull);
        expect(empty.feeds, 0);
        expect(empty.authors, isEmpty);
        for (final d in empty.days) {
          expect(d.reasons, contains(DayInvalidReason.noSleep));
        }
      },
    );

    test('a running Sunday: today is not a valid day yet', () {
      final f = weekFacts(
        zone: _zone,
        week: summaryWeekFor('2026-10-11'),
        now: sundayNow,
        records: weekLog(monday: '2026-10-05', until: sundayNow),
      );
      expect(f.week.inProgress, true);
      expect(f.days.last.reasons, contains(DayInvalidReason.notFinished));
      expect(f.validDays, 4);
      expect(f.averageSleepMinutes, isNull);
    });

    test('deleted records and other weeks are left out', () {
      final deleted = rec(
        CareType.bottle,
        vnAt('2026-09-29', 8),
        mai,
        amountMl: 500,
      );
      final f = _facts(
        log: [
          ...weekLog(),
          CareRecord(
            id: deleted.id,
            babyId: teddyId,
            type: CareType.bottle,
            occurredAt: deleted.occurredAt,
            createdBy: 'u_mai',
            author: CareAuthor.of(mai),
            amountMl: 500,
            deleted: true,
          ),
          rec(CareType.bottle, vnAt('2026-10-05', 8), mai, amountMl: 300),
        ],
      );
      expect(f.bottleMl, 950);
      expect(f.authors.first.count, 15);
    });

    test('growth: the week’s last measurement against the weighing before', () {
      final f = _facts(
        growth: [
          ...weekGrowth(),
          rec(
            CareType.growth,
            vnAt('2026-10-06', 9),
            mai,
            weightKg: 4.5,
            measuredOn: DateTime(2026, 10, 6),
          ),
        ],
      );
      expect(f.growth?.weightKg, 4.3);
      expect(f.previousWeight?.weightKg, 3.9);
      expect(_facts().growth, isNull);
    });
  });

  group('look-back facts', () {
    test('check-ins: changed, usual and mixed days; health left out', () {
      final week = summaryWeekFor('2026-10-11');
      final notes = weekNotes([
        ...recentCheckIns(),
        _ci('u_mai', '2026-10-09', Observation.usual),
        _ci('u_mai', '2026-10-10', Observation.health),
        _ci('u_mai', '2026-10-01', Observation.sleep),
      ], week);
      expect(notes.changedDays, 3);
      expect(notes.mixedDays, 1);
      expect(notes.usualDays, 1);
      expect(
        [for (final o in notes.observations) (o.observation, o.days)],
        [(Observation.sleep, 1), (Observation.soothing, 2)],
      );
      expect(weekNotes(const [], week).isEmpty, true);
    });

    test('tried: the latest answer per activity in the week, no put-offs', () {
      final week = summaryWeekFor('2026-10-11');
      RecFeedback fb(String id, String content, FeedbackKind k, String date) =>
          RecFeedback(
            id: 'fb_${id * 32}',
            babyId: teddyId,
            authorUid: 'u_mai',
            contentId: content,
            contentVersion: 1,
            kind: k,
            date: date,
          );
      final tried = weekTried(
        newestFirst([
          fb('a', 'act_wind_down', FeedbackKind.started, '2026-10-06'),
          fb('b', 'act_wind_down', FeedbackKind.helpful, '2026-10-07'),
          fb('c', 'act_skin_to_skin', FeedbackKind.notToday, '2026-10-08'),
          fb('d', 'act_evening_repeat', FeedbackKind.unsure, '2026-10-01'),
        ]),
        week,
      );
      expect(
        [for (final f in tried) (f.contentId, f.kind)],
        [('act_wind_down', FeedbackKind.helpful)],
      );
    });
  });

  group('weekly notification (EN07 Chủ nhật 20:30)', () {
    test(
      'the next Sundays at 20:30, before quiet hours, never earlier than allowed',
      () {
        final thu = DateTime(2026, 10, 8, 10);
        expect(weeklySummaryPlan(enabled: true, now: thu), [
          DateTime(2026, 10, 11, 20, 30),
          DateTime(2026, 10, 18, 20, 30),
        ]);
        expect(weeklySummaryPlan(enabled: false, now: thu), isEmpty);
        // Quiet from 20:00: half an hour before it.
        expect(
          weeklySummaryPlan(
            enabled: true,
            now: thu,
            quietFrom: '20:00',
            quietTo: '06:00',
          ).first,
          DateTime(2026, 10, 11, 19, 30),
        );
        // Quiet from 18:00: no evening time is left.
        expect(
          weeklySummaryPlan(
            enabled: true,
            now: thu,
            quietFrom: '18:00',
            quietTo: '07:00',
          ),
          isEmpty,
        );
        // Sunday after 20:30: the next two.
        expect(
          weeklySummaryPlan(enabled: true, now: DateTime(2026, 10, 11, 21)),
          [DateTime(2026, 10, 18, 20, 30), DateTime(2026, 10, 25, 20, 30)],
        );
        // Not before the first whole week of life.
        expect(
          weeklySummaryPlan(
            enabled: true,
            now: thu,
            earliest: DateTime(2026, 10, 18),
          ),
          [DateTime(2026, 10, 18, 20, 30), DateTime(2026, 10, 25, 20, 30)],
        );
        expect(
          firstWeeklySummaryDay(DateTime(2026, 9, 28)),
          DateTime(2026, 10, 4),
        );
        expect(
          firstWeeklySummaryDay(DateTime(2026, 9, 29)),
          DateTime(2026, 10, 11),
        );
      },
    );

    test('no baby name, its own ids, the payload opens the week', () {
      final n = rhythmWeeklyNotification(l10n, (
        babyId: teddyId,
        fireAt: DateTime(2026, 10, 11, 20, 30),
      ));
      expect(n.title, l10n.rhWeekTitle);
      expect(n.body, l10n.rhWeekNotifBody);
      expect('${n.title} ${n.body}', isNot(contains('Teddy')));
      expect(n.id & (1 << 30), isNot(0));
      expect(n.id & (1 << 29), isNot(0));
      expect(n.id, lessThan(1 << 31));
      expect(rhythmWeekOfPayload(n.payload), teddyId);
      expect(rhythmOfPayload(n.payload), isNull);
      expect(rhythmCheckInOfPayload(n.payload), isNull);
      expect(jsonDecode(n.payload)['k'], 'rhythm_week');
    });

    testWidgets('scheduled for who reads care, with the switch on', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        overrides: weekOverrides(repo: FakeRhythmRepository()),
      );
      final sub = container.listen(rhythmWeeklyPlanProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      expect(
        [for (final p in sub.read()) p.fireAt],
        [DateTime(2026, 10, 11, 20, 30), DateTime(2026, 10, 18, 20, 30)],
      );
      container
          .read(rhythmRemindersProvider('u_mai').notifier)
          .set(const RhythmReminders(weekly: false));
      await tester.pump();
      expect(sub.read(), isEmpty);
    });

    testWidgets('never for a relative without daily care', (tester) async {
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        overrides: weekOverrides(
          me: _grandma(dailyCare: false),
          repo: FakeRhythmRepository(),
        ),
      );
      final sub = container.listen(rhythmWeeklyPlanProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      expect(sub.read(), isEmpty);
    });

    testWidgets('the evening prompt gives way on a summary Sunday (1 a day)', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        prefs: {
          'rhythm.reminders.u_mai': jsonEncode(
            const RhythmReminders(evening: true).toJson(),
          ),
        },
        overrides: weekOverrides(
          repo: FakeRhythmRepository(),
          now: sundayNow.subtract(const Duration(hours: 5)),
        ),
      );
      final sub = container.listen(rhythmEveningPlanProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      final evenings = [for (final p in sub.read()) p.fireAt];
      expect(evenings, isNot(contains(DateTime(2026, 10, 11, 20, 30))));
      expect(evenings, contains(DateTime(2026, 10, 12, 20, 30)));
    });
  });

  group('EN09 screen', () {
    testWidgets(
      'free: the logged week with coverage, the family, the gate → plan',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const WeekSummaryScreen(),
          overrides: weekOverrides(
            repo: FakeRhythmRepository(),
            reminders: mockReminders(),
          ),
        );
        expect(find.text('Tuần thứ 3 của Teddy'), findsOneWidget);
        expect(find.text('28 tháng 9 – 4 tháng 10'), findsOneWidget);
        expect(find.text(l10n.rhWeekInProgress), findsNothing);
        expect(find.text(l10n.rhWeekFeedCount(20)), findsOneWidget);
        expect(find.text(l10n.rhWeekBottle('950')), findsOneWidget);
        expect(
          find.text(l10n.rhWeekBreast(durationLabel(l10n, 175))),
          findsOneWidget,
        );
        expect(find.text(durationLabel(l10n, 792)), findsOneWidget);
        expect(find.text(l10n.rhWeekCoverage(5, 7)), findsOneWidget);
        expect(find.text(l10n.rhWeekDiaperCount(10)), findsOneWidget);
        expect(find.text(l10n.rhWeekDiaperKinds(5, 5)), findsOneWidget);
        expect(find.text('4,3 kg'), findsOneWidget);
        expect(find.text('+0,4 kg so với 24/09'), findsOneWidget);
        expect(find.text(l10n.rhWeekPhotos(3)), findsOneWidget);
        expect(
          find.text('Bạn 15 lần · Cô Lan 10 lần · Ba 16 lần'),
          findsOneWidget,
        );
        // Tuần tới (5 – 11/10): the reminder still ahead; the past ones are gone.
        expect(find.text('Tiêm 6 trong 1'), findsOneWidget);
        expect(find.text('Mua sữa công thức'), findsNothing);
        expect(find.text(l10n.rhWeekNoScore), findsOneWidget);
        // No interpretation without rhythm.advanced, and nothing fake behind it.
        expect(find.text(l10n.rhWeekGatePremium), findsOneWidget);
        expect(find.text(l10n.rhSleepSame), findsNothing);
        expect(find.text(l10n.rhWeekNotesTitle), findsNothing);
        await _tap(tester, find.text(l10n.rhLearnMore));
        expect(visits.last.location, '${Routes.premium}?entry=rhythm');
      },
    );

    testWidgets('another reason is explained, never sold', (tester) async {
      await pumpRouted(
        tester,
        const WeekSummaryScreen(),
        overrides: weekOverrides(
          caps: rhythmCaps(reason: 'REGION_UNAVAILABLE'),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.rhWeekGateOther), findsOneWidget);
      expect(find.text(l10n.rhLearnMore), findsNothing);
      await _tap(tester, find.text(l10n.rhWhy));
      expect(find.text(l10n.pmGateRegionTitle), findsOneWidget);
    });

    testWidgets('not enough valid days: "Chưa đủ dữ liệu", never a zero', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const WeekSummaryScreen(),
        overrides: weekOverrides(
          repo: FakeRhythmRepository(),
          log: weekLog(fullDays: const {0, 1, 4}),
        ),
      );
      expect(find.text(l10n.rhWeekSleepSparse), findsOneWidget);
      expect(find.text(l10n.rhWeekCoverage(3, 7)), findsOneWidget);
      expect(find.text(l10n.rhWeekSleepNeed(5)), findsOneWidget);
      expect(find.text(durationLabel(l10n, 0)), findsNothing);
    });

    testWidgets(
      'advanced: sleep against the usual level, notes, tried, one idea',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const WeekSummaryScreen(),
          overrides: weekOverrides(
            caps: rhythmCaps(plan: 'beta', groupA: true),
            now: sundayNow,
            log: [
              ...longLog(),
              ...weekLog(
                monday: '2026-10-05',
                fullDays: allDays,
                until: sundayNow,
                nightBefore: false,
              ),
            ],
            repo: FakeRhythmRepository(
              checkIns: recentCheckIns(),
              feedback: familyFeedback(),
              episodes: [
                ObservationEpisode(
                  id: episodeIdFor(teddyId, '2026-10-06'),
                  babyId: teddyId,
                  startDate: '2026-10-06',
                  confirmedBy: 'u_mai',
                  checkInIds: [recentCheckIns().last.id],
                ),
              ],
              recommendations: [
                Recommendation.fromJson(
                  recommendationJson(contentId: 'act_evening_repeat'),
                )!,
              ],
            ),
          ),
        );
        expect(find.text('Tuần thứ 4 của Teddy'), findsOneWidget);
        expect(find.text('5 – 11 tháng 10'), findsOneWidget);
        expect(find.text(l10n.rhWeekInProgress), findsOneWidget);
        // Sunday is still running: 6/7.
        expect(find.text(l10n.rhWeekCoverage(6, 7)), findsOneWidget);
        expect(find.text(l10n.rhWeekGatePremium), findsNothing);
        expect(find.text(l10n.rhSleepSame), findsOneWidget);
        expect(
          find.text(l10n.rhSleepBasis(3, '08/10 – 10/10', 7)),
          findsOneWidget,
        );
        expect(find.text(l10n.rhWeekChangedDays(3)), findsOneWidget);
        expect(find.text(l10n.rhWeekMixedDays(1)), findsOneWidget);
        expect(find.text(l10n.rhEpOpenTitle('06/10')), findsOneWidget);
        expect(
          find.text('Giảm kích thích 30 phút trước giấc đêm'),
          findsOneWidget,
        );
        expect(find.text(l10n.rhHelpful), findsOneWidget);
        expect(find.text(l10n.rhUnsure), findsOneWidget);
        expect(find.text(l10n.rhWeekNextIdea), findsOneWidget);
        // Tuần tới 12 – 18/10: the reference window, labelled as such.
        expect(find.text(l10n.rhStageName(1)), findsOneWidget);
        expect(
          find.text(l10n.rhWeekReference('12/10 – 21/10')),
          findsOneWidget,
        );
        await _tap(tester, find.text(l10n.rhHow));
        expect(
          visits.last.location,
          '${Routes.rhythmActivity}/act_evening_repeat?ci=${sleepCheckIn().id}',
        );
      },
    );

    testWidgets('a caregiver: the date range as title, no due-date window', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const WeekSummaryScreen(),
        overrides: weekOverrides(
          me: lan,
          now: sundayNow,
          log: weekLog(monday: '2026-10-05', until: sundayNow),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text('5 – 11 tháng 10'), findsOneWidget);
      expect(find.textContaining('Tuần 4'), findsNothing);
      expect(find.text(l10n.rhWeekTitle), findsOneWidget);
      expect(find.text(l10n.rhStageName(1)), findsNothing);
      // Bạn = Cô Lan herself; Mẹ and Ba by their family labels.
      expect(find.textContaining('Bạn 10 lần'), findsOneWidget);
      expect(find.textContaining('Mẹ 15 lần'), findsOneWidget);
    });

    testWidgets('a relative sees it only with "Chăm sóc hằng ngày"', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const WeekSummaryScreen(),
        overrides: weekOverrides(
          me: _grandma(dailyCare: false),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.rhWeekNoAccess), findsOneWidget);
      expect(find.text(l10n.rhWeekRecordedTitle), findsNothing);
      expect(find.text(l10n.rhWeekShare), findsNothing);
    });

    testWidgets('a relative with daily care reads the week', (tester) async {
      await pumpRouted(
        tester,
        const WeekSummaryScreen(),
        overrides: weekOverrides(
          me: _grandma(dailyCare: true),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.rhWeekNoAccess), findsNothing);
      expect(find.text('Tuần thứ 3 của Teddy'), findsOneWidget);
      expect(find.text(l10n.rhWeekFeedCount(20)), findsOneWidget);
    });

    testWidgets('"Gửi cho…": the free figures with coverage as plain text', (
      tester,
    ) async {
      final shared = <String>[];
      await pumpRouted(
        tester,
        const WeekSummaryScreen(),
        overrides: [
          ...weekOverrides(
            caps: rhythmCaps(plan: 'beta', groupA: true),
            repo: FakeRhythmRepository(
              checkIns: recentCheckIns(),
              feedback: familyFeedback(),
            ),
            log: longLog(),
          ),
          aiShareProvider.overrideWithValue((text, subject, origin) async {
            shared.add(text);
          }),
        ],
      );
      await _tap(tester, find.text(l10n.rhWeekShare));
      final text = shared.single;
      expect(
        text,
        startsWith('Tuần thứ 3 của Teddy · 28 tháng 9 – 4 tháng 10'),
      );
      expect(text, contains(l10n.rhWeekCoverage(5, 7)));
      expect(text, contains(l10n.rhWeekShareSleep(durationLabel(l10n, 792))));
      expect(text, contains('Bú bình 950 ml'));
      // Family labels for the reader, never "Bạn"; no ranking.
      expect(text, contains('Mẹ 15 lần · Cô Lan 10 lần · Ba 16 lần'));
      expect(text, isNot(contains('Bạn')));
      // The look-back stays in the app.
      expect(text, isNot(contains(l10n.rhSleepSame)));
      expect(text, isNot(contains(l10n.rhWeekNotesTitle)));
      expect(text, contains(l10n.rhWeekNoScore));
    });
  });

  group('entry points', () {
    testWidgets('NL01 → EN09', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: {'rhythm.setupSeen.u_mai.$teddyId': true},
        overrides: weekOverrides(repo: FakeRhythmRepository()),
      );
      await _tap(tester, find.text(l10n.rhWeekTitle));
      expect(visits.last.location, Routes.rhythmWeek);
    });

    testWidgets('Hôm nay once a whole week has passed', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: SingleChildScrollView(child: ForYouSection())),
        overrides: weekOverrides(repo: FakeRhythmRepository()),
      );
      await _tap(tester, find.text(l10n.hnWeekSummaryLast));
      expect(visits.last.location, Routes.rhythmWeek);
    });

    testWidgets('not on Hôm nay before a whole week of life', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: SingleChildScrollView(child: ForYouSection())),
        overrides: weekOverrides(
          repo: FakeRhythmRepository(
            profile: RhythmProfile(dateOfBirth: DateTime(2026, 9, 30)),
          ),
        ),
      );
      expect(find.text(l10n.hnWeekSummaryLast), findsNothing);
    });

    testWidgets('not for a relative without daily care', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: SingleChildScrollView(child: ForYouSection())),
        overrides: weekOverrides(
          me: _grandma(dailyCare: false),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.hnWeekSummaryLast), findsNothing);
    });

    testWidgets('NL02c: the "Tóm tắt tuần" switch is stored with the others', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        const RhythmSetupScreen(start: RhythmSetupStep.reminders, single: true),
        overrides: weekOverrides(repo: FakeRhythmRepository()),
      );
      expect(find.text(l10n.rhWeekRemindSub), findsOneWidget);
      await _tap(tester, find.text(l10n.rhWeekTitle));
      await _tap(tester, find.text(l10n.rhDone));
      expect(
        container.read(rhythmRemindersProvider('u_mai')),
        const RhythmReminders(weekly: false),
      );
    });
  });
}
