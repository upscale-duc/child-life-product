import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/me/me_screen.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/rhythm/activity_screens.dart';
import 'package:child_life/features/rhythm/milestone_screen.dart';
import 'package:child_life/features/rhythm/preferences_screens.dart';
import 'package:child_life/features/rhythm/rhythm_calendar.dart';
import 'package:child_life/features/ai/ai_repository.dart';
import 'package:child_life/features/rhythm/rhythm_local.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_overview.dart';
import 'package:child_life/features/rhythm/rhythm_setup.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/ai_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

/// Nhịp lớn lên, Slice 2 part 2 on the phone (plan §7.1): NL01 / NL01b, the first open (region,
/// setup), NL02a–c, NL03 / NL04, MS01, EN01 / EN02 / EN05, the feedback history and the entry
/// points (Chăm sóc tile, Tôi row). Everything through fakes; the server is never called.
final l10n = lookupAppLocalizations(const Locale('vi'));

/// This phone already ran the setup for Mai and Minh (NL01 would push it otherwise).
final _seen = <String, Object>{
  'rhythm.setupSeen.u_mai.$teddyId': true,
  'rhythm.setupSeen.u_minh.$teddyId': true,
};

/// Brings [f] on screen (in whichever scrollable holds it), taps it and settles.
Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  group('NL01 · two layers', () {
    testWidgets('free: calendar from the due date, notes by author, gate → plan', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(
            checkIns: recentCheckIns(),
            feedback: familyFeedback(),
          ),
        ),
      );
      expect(find.text(l10n.rhStageComingN(1)), findsOneWidget);
      expect(
        find.text('Dự kiến 12/10 – 21/10 · còn 4 ngày'), // D-116
        findsOneWidget,
      );
      // The estimate keeps its label (brief p.13).
      expect(
        find.textContaining(l10n.rhByDueDateEstimated('21/09')),
        findsOneWidget,
      );
      // 7/10: Ba "Khó vào giấc", Mẹ "Như mọi ngày" — both kept, the day says so (X03); the
      // 7-day strip opens the day (owner 2026-10-22).
      await _tap(tester, find.byKey(const Key('checkInDay:2026-10-07')));
      expect(find.text(l10n.rhMixedNote), findsOneWidget);
      expect(find.text('Ba'), findsWidgets);
      Navigator.of(tester.element(find.text(l10n.rhMixedNote))).pop();
      await tester.pumpAndSettle();
      // No blurred insight without rhythm.advanced: an explanation and the plan.
      expect(find.text(l10n.rhSleepGateTitle), findsOneWidget);
      expect(find.text(l10n.rhSleepLower('2 giờ')), findsNothing);
      // "Cách nhà mình đã thử".
      expect(find.text(l10n.rhTriedHeading), findsOneWidget);
      expect(find.text(l10n.rhHelpful), findsOneWidget);
      await _tap(tester, find.text(l10n.pv2SeePremium));
      // PR01 from Nhịp lớn lên (entry A).
      expect(visits.last.location, '${Routes.premium}?entry=rhythm');
    });

    testWidgets(
      'links: "Xem lịch" → NL03, the stage → NL04, "Ghi nhận" → C01',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const RhythmOverviewScreen(),
          prefs: _seen,
          overrides: rhythmOverrides(repo: FakeRhythmRepository()),
        );
        await _tap(tester, find.text(l10n.rhSeeCalendar));
        expect(visits.last.location, Routes.rhythmCalendar);
        Navigator.of(tester.element(find.text('stub'))).pop();
        await tester.pumpAndSettle();
        await _tap(tester, find.text(l10n.rhStageComingN(1)));
        expect(visits.last.location, '${Routes.rhythmCalendar}/stage_1');
        Navigator.of(tester.element(find.text('stub'))).pop();
        await tester.pumpAndSettle();
        await _tap(tester, find.text(l10n.rhRecordToday));
        expect(visits.last.location, Routes.rhythmCheckIn);
      },
    );

    testWidgets('another gate reason is explained, never sold', (tester) async {
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          caps: rhythmCaps(reason: 'REGION_UNAVAILABLE'),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.rhSleepGateOther), findsOneWidget);
      expect(find.text(l10n.pv2SeePremium), findsNothing);
      await _tap(tester, find.text(l10n.rhWhy));
      expect(find.text(l10n.pmGateRegionTitle), findsOneWidget);
    });

    testWidgets('advanced: the sleep comparison computed on the phone', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          caps: rhythmCaps(plan: 'beta', groupA: true),
          sleepRecords: sleepLog(),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.rhSleepGateTitle), findsNothing);
      expect(find.text(l10n.rhSleepLower('2 giờ')), findsOneWidget);
      expect(
        find.text(l10n.rhSleepBasis(3, '05/10 – 07/10', 7)),
        findsOneWidget,
      );
      expect(find.text(l10n.rhSleepUsual('13 giờ')), findsOneWidget);
    });

    testWidgets(
      'NL01b: no due date, 2/5 valid days counted, no "ghi đủ" button',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const RhythmOverviewScreen(),
          prefs: _seen,
          overrides: rhythmOverrides(
            caps: rhythmCaps(plan: 'beta', groupA: true),
            sleepRecords: sleepLog(days: 5, sparseDay: null),
            online: false,
            repo: FakeRhythmRepository(
              profile: teddyRhythmProfile(dueDate: false),
            ),
          ),
        );
        expect(find.text(l10n.rhCalendarUnsetPill), findsOneWidget);
        expect(find.text(l10n.rhOwnSparsePill), findsOneWidget);
        expect(find.text(l10n.rhSleepSparseShort(2, 5)), findsOneWidget);
        expect(find.text(l10n.rhOfflineNote), findsOneWidget);
        // D-073 #1: valid days are automatic; nothing asks the parent to mark one.
        for (final b in tester.widgetList<ClButton>(find.byType(ClButton))) {
          expect(b.label.toLowerCase(), isNot(contains('ghi đủ')));
        }
        await _tap(tester, find.text(l10n.rhAddDueDate));
        expect(visits.last.location, Routes.rhythmDueDate);
        Navigator.of(tester.element(find.text('stub'))).pop();
        await tester.pumpAndSettle();
        await _tap(tester, find.text(l10n.rhDontRemember));
        expect(visits.last.location, '${Routes.rhythmDueDate}?estimate=1');
      },
    );

    testWidgets(
      'a caregiver: notes yes, the restricted due date no, no setup',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const RhythmOverviewScreen(),
          overrides: rhythmOverrides(
            me: lan,
            repo: FakeRhythmRepository(checkIns: recentCheckIns()),
          ),
        );
        expect(find.text(l10n.rhCalendarNoAccess), findsOneWidget);
        await _tap(tester, find.byKey(const Key('checkInDay:2026-10-07')));
        expect(find.text(l10n.rhMixedNote), findsOneWidget);
        Navigator.of(tester.element(find.text(l10n.rhMixedNote))).pop();
        await tester.pumpAndSettle();
        expect(visits, isEmpty);
      },
    );

    testWidgets('a health sign today pauses the calendar', (tester) async {
      final sick = sleepCheckIn(date: rhythmToday);
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(
            checkIns: [
              CheckIn(
                id: sick.id,
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
      expect(find.text(l10n.rhHealthCardTitle), findsOneWidget);
      expect(find.text(l10n.rhStageComingN(1)), findsNothing);
    });
  });

  group('first open (D-072 #3, NL02)', () {
    testWidgets('a Cùng nuôi gets the setup once', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        overrides: rhythmOverrides(repo: FakeRhythmRepository()),
      );
      expect(visits.single.location, Routes.rhythmSetup);
    });

    testWidgets('the owner is asked the region first', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        overrides: rhythmOverrides(
          caps: rhythmCaps(country: null),
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.pmRegionBody), findsOneWidget);
      // The setup waits for the region sheet.
      expect(visits, isEmpty);
    });

    testWidgets('others wait for the owner; free parts keep working', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const RhythmOverviewScreen(),
        prefs: _seen,
        overrides: rhythmOverrides(
          me: minh,
          caps: {...rhythmCaps(country: null), 'canManageBilling': false},
          repo: FakeRhythmRepository(),
        ),
      );
      expect(find.text(l10n.pmRegionBody), findsNothing);
      expect(find.text(l10n.rhRegionWaiting), findsOneWidget);
      expect(find.text(l10n.rhStageComingN(1)), findsOneWidget);
    });
  });

  group('NL02 setup', () {
    testWidgets('a → b (estimate 38 weeks) → c: setDueDate, reminders, seen', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        profile: teddyRhythmProfile(dueDate: false),
      );
      final (visits, container) = await pumpRouted(
        tester,
        const RhythmSetupScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhLayerCalendarTitle), findsOneWidget);
      expect(find.text(l10n.rhLayerOwnTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.rhStart));
      expect(find.text(l10n.rhDueTitle('Teddy')), findsOneWidget);
      await _tap(tester, find.text(l10n.rhWeeks(39)));
      await _tap(tester, find.text(l10n.rhWeeks(38)));
      expect(find.text(l10n.rhEstimateResult('01/10/2026')), findsOneWidget);
      await _tap(tester, find.text(l10n.rhContinue));
      expect(
        repo.dueDates.single,
        const DueDate(
          date: '2026-10-01',
          estimated: true,
          gestationWeeks: 38,
          gestationDays: 0,
        ),
      );
      expect(find.text(l10n.rhRemindTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.rhRemindEvening));
      await _tap(tester, find.text(l10n.rhDone));
      expect(
        container.read(rhythmRemindersProvider('u_mai')),
        const RhythmReminders(stage: true, evening: true),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rhythm.setupSeen.u_mai.$teddyId'), isTrue);
      expect(visits.last.location, Routes.today);
    });

    testWidgets('NL02b: like the server, 4 weeks before to 18 after birth', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        profile: teddyRhythmProfile(dueDate: false),
      );
      await pumpRouted(
        tester,
        const RhythmSetupScreen(
          start: RhythmSetupStep.dueDate,
          single: true,
          estimate: true,
        ),
        overrides: rhythmOverrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.rhWeeks(39)));
      await _tap(tester, find.text(l10n.rhWeeks(44)));
      await _tap(tester, find.text(l10n.rhPlusDays(0)));
      await _tap(tester, find.text(l10n.rhPlusDays(6)));
      expect(find.text(l10n.rhDueOutOfRange), findsOneWidget);
      await _tap(tester, find.text(l10n.actionSave));
      expect(repo.dueDates, isEmpty);
    });

    testWidgets('NL02b: only a Cùng nuôi sets the due date', (tester) async {
      await pumpRouted(
        tester,
        const RhythmSetupScreen(start: RhythmSetupStep.dueDate, single: true),
        overrides: rhythmOverrides(me: lan, repo: FakeRhythmRepository()),
      );
      expect(find.text(l10n.rhDueSetupOnly), findsOneWidget);
    });

    testWidgets('NL02b edit: "Xoá ngày dự sinh" clears it', (tester) async {
      final repo = FakeRhythmRepository();
      await pumpRouted(
        tester,
        const RhythmSetupScreen(start: RhythmSetupStep.dueDate, single: true),
        overrides: rhythmOverrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.rhDueRemove));
      expect(repo.dueDates, [null]);
    });

    test('stage reminders: 3 days before each stage still ahead', () {
      final plan = stageReminderPlan(
        dueDate: '2026-09-21',
        stages: referenceModel().stages,
        now: DateTime(2026, 10, 8, 10),
        enabled: true,
      );
      expect(
        [for (final p in plan) p.stage.id],
        ['stage_1', 'stage_2', 'stage_3'],
      );
      expect(plan.first.fireAt, DateTime(2026, 10, 9, stageReminderHour));
      expect(
        stageReminderPlan(
          dueDate: '2026-09-21',
          stages: referenceModel().stages,
          now: DateTime(2026, 10, 8),
          enabled: false,
        ),
        isEmpty,
      );
    });

    test(
      'a stage reminder becomes one local notification: notice text, no name, own id range',
      () {
        const stage = ReferenceStage(
          id: 'stage_1',
          number: 1,
          startOffsetDays: 28,
          endOffsetDays: 38,
          name: Localized('Giai đoạn 1', 'Stage 1'),
          noticeTitle: Localized('Sắp đến giai đoạn 1', 'Stage 1 coming up'),
          noticeBody: Localized('Mỗi bé mỗi khác.', 'Every baby is different.'),
        );
        final n = rhythmStageNotification(const Locale('vi'), (
          babyId: teddyId,
          stage: stage,
          fireAt: DateTime(2026, 10, 9, stageReminderHour),
        ));
        expect(n.title, stage.noticeTitle!.vi);
        expect(n.body, stage.noticeBody!.vi);
        expect(n.id & (1 << 29), isNonZero);
        expect(n.id & (1 << 30), isZero);
        expect(rhythmOfPayload(n.payload), teddyId);
        expect(rhythmOfPayload('{"k":"reminder","b":"x"}'), isNull);
        expect(rhythmOfPayload('not json'), isNull);
      },
    );
  });

  group('NL03 / NL04', () {
    testWidgets('NL03: today, every window, overlaps, "Đổi" for a Cùng nuôi', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const ReferenceCalendarScreen(),
        overrides: rhythmOverrides(repo: FakeRhythmRepository()),
      );
      expect(find.text(l10n.rhTodayBefore('08/10', 1)), findsOneWidget);
      expect(find.text(l10n.rhStageUpcoming(4)), findsOneWidget);
      expect(find.text(l10n.rhStagesOverlap(1, 2)), findsOneWidget);
      expect(find.text(l10n.rhReviewPending), findsOneWidget);
      await _tap(tester, find.text(l10n.rhChange));
      expect(visits.last.location, Routes.rhythmDueDate);
    });

    testWidgets('NL04: possibilities, skills, the linked activity → AC01', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const StageDetailScreen(stageId: 'stage_1'),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhSignsNormal), findsOneWidget);
      expect(find.text(l10n.rhSkillsNote), findsOneWidget);
      // An id missing from the published content is left out, never a broken row.
      expect(
        find.text('Bế áp da trong phòng ánh sáng dịu, 10 phút'),
        findsOneWidget,
      );
      await _tap(tester, find.text(l10n.rhSameAsUsual));
      expect(repo.savedCheckIns.single.observation, Observation.usual);
      expect(visits.last.location, Routes.today);
    });
  });

  group('MS01 · Lưu vào Mốc', () {
    testWidgets('a Cùng nuôi confirms; the card flow opens with the occasion', (
      tester,
    ) async {
      final memories = FakeMemoryRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const RhythmMilestoneScreen(note: 'Lần đầu lẫy'),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          memories: memories,
        ),
      );
      await _tap(tester, find.text(l10n.rhSaveToMilestones));
      expect(memories.milestones, ['Lần đầu lẫy']);
      expect(find.text(l10n.rhMsSavedTitle), findsOneWidget);
      expect(find.text(l10n.rhMsKeepTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.rhMsCreateCard));
      expect(
        visits.last.location,
        '${Routes.milestoneCard}?occasion=${Occasion.rollsOver.wire}',
      );
    });

    testWidgets('a caregiver is told why (role, not a paywall)', (
      tester,
    ) async {
      final memories = FakeMemoryRepository();
      await pumpRouted(
        tester,
        const RhythmMilestoneScreen(note: 'Lần đầu lẫy'),
        overrides: rhythmOverrides(
          me: lan,
          repo: FakeRhythmRepository(),
          memories: memories,
        ),
      );
      expect(find.text(l10n.rhMsRoleTitle), findsOneWidget);
      expect(find.text(l10n.rhSaveToMilestones), findsNothing);
      expect(memories.milestones, isEmpty);
    });

    test('occasions read from the words parents write', () {
      expect(occasionFor('Lần đầu lẫy'), Occasion.rollsOver);
      expect(occasionFor('Rolled over!'), Occasion.rollsOver);
      expect(occasionFor('Cười thành tiếng'), Occasion.laughs);
      expect(occasionFor('Ngẩng đầu khi nằm sấp'), isNull);
    });
  });

  group('EN01 / EN02 / EN05 / feedback history', () {
    testWidgets('EN01: interests saved; a topic turned down can be undone', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        preferences: const UserPreferences(
          interests: [Interest.sleep],
          fewer: [Interest.nutrition],
        ),
      );
      await pumpRouted(
        tester,
        const InterestsScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhInterestsToday), findsOneWidget);
      await _tap(tester, find.text(l10n.rhIntVaccines));
      await _tap(tester, find.text(l10n.rhFewerUndo));
      await _tap(tester, find.text(l10n.rhSaveCount(2)));
      final saved = repo.savedPreferences.single;
      expect(saved.interests, [Interest.sleep, Interest.vaccines]);
      expect(saved.fewer, isEmpty);
    });

    testWidgets('EN01 "Bỏ qua" leaves without saving', (tester) async {
      final repo = FakeRhythmRepository();
      await pumpRouted(
        tester,
        const InterestsScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.rhSkip));
      expect(repo.savedPreferences, isEmpty);
    });

    testWidgets('EN02: the morning round-up and no quiet hours', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      await pumpRouted(
        tester,
        const DigestScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.rhDigestMorning));
      await _tap(tester, find.text(l10n.rhQuietHours));
      await _tap(tester, find.text(l10n.actionSave));
      final saved = repo.savedPreferences.single;
      expect(saved.digestTime, '08:00');
      expect(saved.quietFrom, isNull);
    });

    testWidgets('EN05 on AC01: "Ít gợi ý kiểu này hơn" at once', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      await pumpRouted(
        tester,
        const ActivityScreen(contentId: 'act_wind_down'),
        overrides: rhythmOverrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.rhFewerLikeThis));
      expect(repo.savedPreferences.single.fewer, [Interest.sleep]);
      // Already turned down: the link goes away.
      expect(find.text(l10n.rhFewerLikeThis), findsNothing);
    });

    testWidgets('feedback history: only my answers, delete and reset', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        feedback: familyFeedback(),
        preferences: const UserPreferences(interests: [Interest.sleep]),
      );
      await pumpRouted(
        tester,
        const FeedbackHistoryScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(
        find.text('Giảm kích thích 30 phút trước giấc đêm'),
        findsOneWidget,
      );
      // Ba's answer is his to change.
      expect(
        find.text('Bế áp da trong phòng ánh sáng dịu, 10 phút'),
        findsNothing,
      );
      await _tap(tester, find.text(l10n.rhDelete));
      await _tap(tester, find.text(l10n.rhDelete).last);
      expect(repo.deletedFeedback, [helpfulFeedback().id]);
      expect(find.text(l10n.rhHistoryEmpty), findsOneWidget);
      await _tap(tester, find.text(l10n.rhResetInterests));
      await _tap(tester, find.text(l10n.rhResetInterests).last);
      expect(repo.savedPreferences.single.interests, isEmpty);
    });

    testWidgets('"Cá nhân hoá" hub: rows to EN01, EN02, NL02c and history', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const PersonalizeScreen(),
        overrides: [
          ...rhythmOverrides(repo: FakeRhythmRepository()),
          // The consent row reads the person's AI settings even with the rollout off.
          aiRepositoryProvider.overrideWithValue(FakeAiRepository()),
        ],
      );
      for (final (label, route) in [
        (l10n.rhInterestsRow, Routes.rhythmInterests),
        (l10n.rhDigestRow, Routes.rhythmDigest),
        (l10n.rhRemindRow, Routes.rhythmReminders),
        (l10n.rhHistoryRow, Routes.rhythmFeedbackHistory),
      ]) {
        await _tap(tester, find.text(label));
        expect(visits.last.location, route);
        Navigator.of(tester.element(find.text('stub'))).pop();
        await tester.pumpAndSettle();
      }
    });
  });

  group('entry points', () {
    testWidgets('Chăm sóc "Wonder Weeks" opens NL01 with the flag', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: [
          ...careOverrides(),
          capabilitiesProvider.overrideWith(
            (ref, babyId) async => Capabilities.fromJson(rhythmCaps()),
          ),
        ],
      );
      await _tap(tester, find.text(l10n.careWonderWeek));
      expect(visits.last.location, Routes.rhythm);
    });

    testWidgets('…and stays a teaser without it', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: [
          ...careOverrides(),
          capabilitiesProvider.overrideWith(
            (ref, babyId) async =>
                Capabilities.fromJson(rhythmCaps(rhythm: false)),
          ),
        ],
      );
      await _tap(tester, find.text(l10n.careWonderWeek));
      expect(visits, isEmpty);
    });

    for (final rhythm in [true, false]) {
      testWidgets(
        'Tôi "Cá nhân hoá" ${rhythm ? 'with' : 'not without'} the flag',
        (tester) async {
          final (visits, _) = await pumpRouted(
            tester,
            const MeScreen(),
            overrides: [
              ...familyOverrides(email: 'mai@gmail.com'),
              ...memoryOverrides(),
              ...meOverrides(),
              capabilitiesProvider.overrideWith(
                (ref, babyId) async =>
                    Capabilities.fromJson(rhythmCaps(rhythm: rhythm)),
              ),
            ],
          );
          if (!rhythm) {
            expect(find.text(l10n.rhPersonalize), findsNothing);
            return;
          }
          await _tap(tester, find.text(l10n.rhPersonalize));
          expect(visits.last.location, Routes.rhythmPersonalize);
        },
      );
    }
  });
}
