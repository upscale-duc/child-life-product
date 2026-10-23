import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/rhythm/activity_screens.dart';
import 'package:child_life/features/rhythm/checkin_screens.dart';
import 'package:child_life/features/rhythm/health_screen.dart';
import 'package:child_life/features/rhythm/result_screen.dart';
import 'package:child_life/features/rhythm/rhythm_home.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

/// Nhịp lớn lên, Slice 2 part 1 on the phone (plan §7.1): Home "Dành cho bé hôm nay" (H01 /
/// H02 / PS02 / health), the check-in C01 → C02 → NL05b → HL01 / PS01 / PS01F, AC01 / AC02.
/// Writes go through a fake repository; the server is never called.
final l10n = lookupAppLocalizations(const Locale('vi'));

Widget _home() => Scaffold(body: ListView(children: const [ForYouSection()]));

void main() {
  group('Home · Dành cho bé hôm nay', () {
    testWidgets('nothing when the family\'s rhythm flag is off', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          caps: rhythmCaps(rhythm: false),
        ),
      );
      expect(find.text(l10n.rhCheckInEntry), findsNothing);
      expect(find.text(l10n.rhAgeHeading('Teddy')), findsNothing);
    });

    testWidgets('H01 free: check-in, age card, calendar, optional support → plan', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhCheckInEntry), findsOneWidget);
      expect(find.text(l10n.rhAgeHeading('Teddy')), findsOneWidget);
      // Week of life 4 (21 days: three completed weeks); the teaser is the age card's
      // first sentence and the card says what tapping does.
      expect(find.text('3 tuần tuổi'), findsOneWidget);
      expect(
        find.text(
          'Nhiều bé ở tuần này nhìn theo khuôn mặt ở gần và quay về phía giọng nói quen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Xem 2 gợi ý cho tuần này'), findsOneWidget);
      // The reference calendar is a row of the same card, not a card of its own.
      expect(find.text('Còn 4 ngày đến giai đoạn 1'), findsOneWidget);
      expect(find.text('Wonder Weeks · dự kiến 12/10 – 21/10'), findsOneWidget);
      expect(find.text('LỊCH THAM KHẢO'), findsNothing);
      await tester.tap(find.byKey(const Key('forBabyWeek')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.rhythmAge}/age_week_3');
      GoRouter.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      // The owner reads the date of birth: the free Home needs no server call.
      expect(repo.composeCalls, 0);
      await tester.tap(find.text(l10n.rhSupportTitle));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.premium}?entry=rhythm');
    });

    testWidgets('no upsell when group A is missing for another reason', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          caps: rhythmCaps(reason: 'REGION_UNAVAILABLE'),
        ),
      );
      expect(find.text(l10n.rhSupportTitle), findsNothing);
      expect(find.text(l10n.rhCheckInEntry), findsOneWidget);
    });

    testWidgets('a relative cannot check in; the due date stays unread', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(
          me: hoa,
          repo: FakeRhythmRepository(home: h02Home()),
          caps: rhythmCaps(plan: 'beta', groupA: true),
        ),
      );
      expect(find.text(l10n.rhCheckInEntry), findsNothing);
      // Hoa has "Thông tin bé" (age card from the DOB) but not "Chăm sóc hằng ngày".
      expect(find.text(l10n.rhAgeHeading('Teddy')), findsOneWidget);
      expect(find.text(l10n.rhKickerTonight), findsNothing);
    });

    testWidgets('a caregiver gets the age card from composeHome, no calendar', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        home: HomeComposition.fromJson({
          'state': 'free_content',
          'ageCardId': 'age_week_3',
          'gate': 'PREMIUM_REQUIRED',
        }),
      );
      await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(me: lan, repo: repo),
      );
      expect(repo.composeCalls, 1);
      // No date of birth: the week of life comes from the age card's range (days 21–27).
      expect(find.text('Tuần thứ 4'), findsOneWidget);
      expect(
        find.text(
          'Nhiều bé ở tuần này nhìn theo khuôn mặt ở gần và quay về phía giọng nói quen.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Wonder Weeks'), findsNothing);
      expect(find.text(l10n.rhCheckInEntry), findsOneWidget);
    });

    for (final scenario in ['deleted', 'edited', 'previous day']) {
      testWidgets('P-172: cached invitation disappears: $scenario source', (
        tester,
      ) async {
        final checkIns = switch (scenario) {
          'deleted' => <CheckIn>[],
          'edited' => [sleepCheckIn(date: rhythmToday).copyWith(revision: 2)],
          _ => [sleepCheckIn()],
        };
        await pumpRouted(
          tester,
          _home(),
          overrides: rhythmOverrides(
            repo: FakeRhythmRepository(home: h02Home(), checkIns: checkIns),
            caps: rhythmCaps(plan: 'beta', groupA: true),
            online: false,
          ),
        );
        expect(find.text(l10n.rhKickerTonight), findsNothing);
      });
    }

    testWidgets('H02: "Thử tối nay" starts it and opens the activity', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        home: h02Home(),
        checkIns: [sleepCheckIn(date: rhythmToday)],
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
      expect(find.text(l10n.rhKickerTonight), findsOneWidget);
      expect(
        find.text('Vì hôm nay Mẹ ghi nhận con khó vào giấc.'),
        findsOneWidget,
      );
      expect(find.text(l10n.rhReviewPending), findsOneWidget);
      // The calendar is a row of "Tuần này của Teddy", below the suggestion.
      expect(find.textContaining('đến giai đoạn 1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('forBabySuggestion'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('forBabyRhythm'))).dy),
      );
      expect(find.text(l10n.rhSupportTitle), findsNothing);

      await tester.tap(find.text(l10n.rhTryTonight));
      await tester.pumpAndSettle();
      expect(repo.savedFeedback.single.kind, FeedbackKind.started);
      expect(repo.savedFeedback.single.authorUid, 'u_minh');
      expect(repo.savedFeedback.single.date, rhythmToday);
      expect(
        visits.last.location,
        '${Routes.rhythmActivity}/act_wind_down?ci=${sleepCheckIn(date: rhythmToday).id}',
      );
    });

    testWidgets('H02: "Không phải hôm nay" puts it off and hides it', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        home: h02Home(),
        checkIns: [sleepCheckIn(date: rhythmToday)],
      );
      await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(
          repo: repo,
          caps: rhythmCaps(plan: 'beta', groupA: true),
        ),
      );
      await tester.tap(find.text(l10n.rhNotToday));
      await tester.pumpAndSettle();
      expect(repo.savedFeedback.single.kind, FeedbackKind.notToday);
      expect(find.text(l10n.rhKickerTonight), findsNothing);
      expect(find.text(l10n.rhPutOffToast), findsOneWidget);
    });

    testWidgets('PS02: the feedback behind it and what changed', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(
          me: minh,
          repo: FakeRhythmRepository(
            home: ps02Home(),
            checkIns: [sleepCheckIn(date: rhythmToday)],
            feedback: [helpfulFeedback()],
          ),
          caps: rhythmCaps(plan: 'beta', groupA: true),
        ),
      );
      // Compact on Home: one line of why; the feedback behind it is in "Vì sao gợi ý này?".
      expect(find.text(l10n.hnWhyFeedbackShort), findsOneWidget);
      expect(find.text(l10n.rhBasedOnFeedback), findsNothing);
      expect(find.text(l10n.rhTryAgainTonight), findsOneWidget);
      expect(find.text(l10n.rhSomethingElse), findsOneWidget);
      await tester.tap(find.byKey(const Key('forBabyWhy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('forBabyWhySheet')), findsOneWidget);
      expect(find.text(l10n.rhBasedOnFeedback), findsOneWidget);
      expect(
        find.text(
          'Tối 07/10 Mẹ chọn “Có ích” cho “Giảm kích thích 30 phút trước giấc đêm” — '
          '“Con vào giấc nhanh hơn sau khi tắm”.',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.rhChangePrefersHelpful), findsOneWidget);
      // Ba's own answers can be changed: the link leaves the sheet for the history.
      await tester.tap(find.text(l10n.rhEditHistoryLink));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('forBabyWhySheet')), findsNothing);
      expect(visits.last.location, Routes.rhythmFeedbackHistory);
    });

    testWidgets('a health sign today comes first and pauses suggestions', (
      tester,
    ) async {
      final health = CheckIn(
        id: checkInIdFor(
          babyId: teddyId,
          uid: 'u_mai',
          date: rhythmToday,
          observation: Observation.health,
        ),
        babyId: teddyId,
        date: rhythmToday,
        authorUid: 'u_mai',
        observation: Observation.health,
        healthSigns: const [HealthSign.breathing],
      );
      final (visits, _) = await pumpRouted(
        tester,
        _home(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(
            home: h02Home(),
            checkIns: [
              health,
              sleepCheckIn(date: rhythmToday),
            ],
          ),
          caps: rhythmCaps(plan: 'beta', groupA: true),
        ),
      );
      expect(find.text(l10n.rhHealthCardTitle), findsOneWidget);
      expect(find.text(l10n.rhKickerTonight), findsNothing);
      expect(find.textContaining('Wonder Weeks'), findsNothing);
      await tester.tap(find.text(l10n.rhHealthCardTitle));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.rhythmHealth}?signs=breathing');
    });
  });

  group('Check-in C01 → C02 → NL05b', () {
    testWidgets('C01: no default; "Như mọi ngày" saves quietly', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const CheckInScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      await tester.tap(find.text(l10n.rhContinue));
      await tester.pumpAndSettle();
      expect(repo.savedCheckIns, isEmpty);
      await tester.tap(find.text(l10n.rhObsUsual));
      await tester.pump();
      await tester.tap(find.text(l10n.rhContinue));
      await tester.pumpAndSettle();
      final saved = repo.savedCheckIns.single;
      expect(saved.observation, Observation.usual);
      expect(saved.date, rhythmToday);
      expect(saved.authorUid, 'u_mai');
      expect(saved.revision, 1);
      expect(visits, isEmpty);
      expect(find.text(l10n.rhUsualSaved), findsOneWidget);
    });

    testWidgets('C01: an observation asks C02; the health row asks NL05b', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const CheckInScreen(),
        overrides: rhythmOverrides(repo: FakeRhythmRepository()),
      );
      await tester.tap(find.text(l10n.rhObsSleep));
      await tester.pump();
      await tester.tap(find.text(l10n.rhContinue));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.rhythmCheckInMore}?o=sleep');
      GoRouter.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.rhObsHealth));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.rhythmCheckInHealth);
    });

    testWidgets('C02 saves the answers and opens the result', (tester) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const CheckInMoreScreen(observation: Observation.sleep),
        overrides: rhythmOverrides(repo: repo, records: lastNightSleep()),
      );
      // Care facts reused, not asked again.
      expect(
        find.text(
          'Từ nhật ký: giấc đêm qua được ghi 7 giờ 50 phút (Ba ghi). Bạn không cần nhập lại.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.rhWhenNightSleep));
      await tester.tap(find.text(l10n.rhSince23));
      await tester.tap(find.text(l10n.rhTriedRocking));
      await tester.tap(find.text(l10n.rhTriedWhiteNoise));
      // "Chưa" clears the others.
      await tester.tap(find.text(l10n.rhTriedNone));
      await tester.tap(find.text(l10n.rhTriedRocking));
      await tester.tap(find.text(l10n.rhSaveNote));
      await tester.pumpAndSettle();
      final saved = repo.savedCheckIns.single;
      expect(saved.when, CheckInWhen.night);
      expect(saved.since, CheckInSince.days2to3);
      expect(saved.tried, [Tried.rocking]);
      expect(saved.healthSigns, isEmpty);
      expect(visits.last.location, Routes.rhythmResult);
      expect((visits.last.extra! as CheckIn).id, saved.id);
    });

    testWidgets('C02 again the same day edits the same check-in', (
      tester,
    ) async {
      final mine = sleepCheckIn(date: rhythmToday);
      final repo = FakeRhythmRepository(checkIns: [mine]);
      await pumpRouted(
        tester,
        const CheckInMoreScreen(observation: Observation.sleep),
        overrides: rhythmOverrides(repo: repo),
      );
      await tester.tap(find.text(l10n.rhSkipQuestions));
      await tester.pumpAndSettle();
      final saved = repo.savedCheckIns.single;
      expect(saved.id, mine.id);
      expect(saved.revision, 2);
      expect(saved.when, isNull);
      expect(saved.tried, isEmpty);
    });

    testWidgets('something new: a short text and "Lưu vào Mốc"', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const CheckInMoreScreen(observation: Observation.newSkill),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhQWhen), findsNothing);
      await tester.enterText(find.byType(EditableText), 'Lần đầu lẫy');
      await tester.tap(find.text(l10n.rhSaveToMilestones));
      await tester.pumpAndSettle();
      expect(visits.last.location, Routes.rhythmMilestone);
      expect(visits.last.extra, 'Lần đầu lẫy');
    });

    testWidgets('NL05b: any "Có" saves the sign and opens HL01', (
      tester,
    ) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const HealthQuestionsScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      // Teddy is 3 weeks old: fever is asked.
      expect(find.text('Sốt (bé dưới 3 tháng)'), findsOneWidget);
      await tester.tap(find.text(l10n.rhAnswerYes).first);
      await tester.tap(find.text(l10n.rhAnswerUnsure).at(1));
      await tester.pumpAndSettle();
      expect(find.text(l10n.rhHealthUnsureHint), findsOneWidget);
      await tester.tap(find.text(l10n.rhContinue));
      await tester.pumpAndSettle();
      final saved = repo.savedCheckIns.single;
      expect(saved.observation, Observation.health);
      expect(saved.healthSigns, [HealthSign.feverYoung]);
      expect(visits.last.location, '${Routes.rhythmHealth}?signs=fever_young');
    });

    testWidgets('NL05b without "Có" saves quietly', (tester) async {
      final repo = FakeRhythmRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const HealthQuestionsScreen(),
        overrides: rhythmOverrides(repo: repo),
      );
      await tester.tap(find.text(l10n.rhAnswerNo).first);
      await tester.tap(find.text(l10n.rhContinue));
      await tester.pumpAndSettle();
      expect(repo.savedCheckIns.single.healthSigns, isEmpty);
      expect(visits, isEmpty);
      expect(find.text(l10n.rhSavedTitle), findsOneWidget);
    });
  });

  group('After saving · PS01 / PS01F', () {
    final checkIn = sleepCheckIn(date: rhythmToday);

    testWidgets(
      'PS01: one action, why, review label; "Thử tối nay" starts it',
      (tester) async {
        final repo = FakeRhythmRepository(
          answer: NextActionAnswer.fromJson(nextActionJson()),
        );
        final (visits, _) = await pumpRouted(
          tester,
          RhythmResultScreen(checkIn: checkIn),
          overrides: rhythmOverrides(
            repo: repo,
            caps: rhythmCaps(plan: 'beta', groupA: true),
          ),
        );
        expect(repo.nextActionCalls, [checkIn.id]);
        expect(
          find.text(
            'Khó vào giấc · giấc đêm · 2–3 ngày · Ba và Cô Lan sẽ thấy',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Giảm kích thích 30 phút trước giấc đêm'),
          findsOneWidget,
        );
        expect(find.textContaining('Bế ru đã thử rồi'), findsOneWidget);
        expect(find.text(l10n.rhReviewPending), findsOneWidget);
        expect(find.textContaining('Premium'), findsNothing);
        await tester.tap(find.text(l10n.rhTryTonight));
        await tester.pumpAndSettle();
        expect(repo.savedFeedback.single.kind, FeedbackKind.started);
        expect(repo.savedFeedback.single.contentId, 'act_wind_down');
        expect(
          visits.last.location,
          '${Routes.rhythmActivity}/act_wind_down?ci=${checkIn.id}',
        );
      },
    );

    testWidgets('PS01: "Để sau" puts it off', (tester) async {
      final repo = FakeRhythmRepository(
        answer: NextActionAnswer.fromJson(nextActionJson()),
      );
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: checkIn),
        overrides: rhythmOverrides(repo: repo),
      );
      await tester.tap(find.text(l10n.rhLater));
      await tester.pumpAndSettle();
      expect(repo.savedFeedback.single.kind, FeedbackKind.notToday);
    });

    testWidgets(
      'PS01F: age content; "Tìm hiểu thêm" only on PREMIUM_REQUIRED',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          RhythmResultScreen(checkIn: checkIn),
          overrides: rhythmOverrides(
            repo: FakeRhythmRepository(
              answer: NextActionAnswer.fromJson({
                'state': 'free_content',
                'ageCardId': 'age_month_0',
                'gate': 'PREMIUM_REQUIRED',
              }),
            ),
          ),
        );
        expect(find.text(l10n.rhMoreForAge), findsOneWidget);
        expect(find.text(l10n.rhDone), findsOneWidget);
        await tester.tap(find.text(l10n.rhLearnMoreOptional));
        await tester.pumpAndSettle();
        expect(visits.last.location, '${Routes.premium}?entry=rhythm');
      },
    );

    testWidgets('PS01F in a region without group A: no upsell', (tester) async {
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: checkIn),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(
            answer: NextActionAnswer.fromJson({
              'state': 'free_content',
              'ageCardId': 'age_month_0',
              'gate': 'REGION_UNAVAILABLE',
            }),
          ),
        ),
      );
      expect(find.text(l10n.rhMoreForAge), findsOneWidget);
      expect(find.text(l10n.rhUpsellTitle), findsNothing);
    });

    testWidgets('nothing fits: "Chưa có gợi ý phù hợp" with the age content', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: checkIn),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(
            answer: NextActionAnswer.fromJson({
              'state': 'no_suggestion',
              'ageCardId': 'age_week_3',
            }),
          ),
        ),
      );
      expect(find.text(l10n.rhNoSuggestionTitle), findsOneWidget);
      await tester.tap(find.text(l10n.rhSeeAgeContent));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.rhythmAge}/age_week_3');
    });

    testWidgets('offline: saved on the phone, no call', (tester) async {
      final repo = FakeRhythmRepository();
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: checkIn),
        overrides: rhythmOverrides(repo: repo, online: false),
      );
      expect(find.text(l10n.rhOfflineTitle), findsOneWidget);
      expect(repo.nextActionCalls, isEmpty);
    });

    testWidgets('a failed call: saved anyway, "Thử lại" asks again', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        answerError: const RhythmException('internal'),
      );
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: checkIn),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhErrorTitle), findsOneWidget);
      repo
        ..answerError = null
        ..answer = NextActionAnswer.fromJson(nextActionJson());
      await tester.tap(find.text(l10n.rhRetry));
      await tester.pumpAndSettle();
      expect(repo.nextActionCalls, hasLength(2));
      expect(find.text(l10n.rhOneThing), findsOneWidget);
    });
  });

  group('HL01 · always free', () {
    testWidgets('the household region\'s number, no paywall', (tester) async {
      final dialled = <String>[];
      await pumpRouted(
        tester,
        const HealthSupportScreen(signs: [HealthSign.feverYoung]),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          caps: rhythmCaps(plan: 'expired'),
          dialled: dialled,
        ),
      );
      expect(find.text(l10n.rhSignFeverYoung), findsOneWidget);
      expect(find.textContaining('Premium'), findsNothing);
      expect(find.text(l10n.rhHlAlwaysFree), findsOneWidget);
      await tester.tap(find.text(l10n.rhHlCallEmergency('115')));
      await tester.pumpAndSettle();
      expect(dialled, ['115']);
    });

    testWidgets('no approved number for the region: never a default hotline', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const HealthSupportScreen(),
        overrides: rhythmOverrides(
          repo: FakeRhythmRepository(),
          caps: rhythmCaps(country: 'FR'),
        ),
      );
      expect(find.textContaining('115'), findsNothing);
      expect(find.text(l10n.rhHlNoRegion), findsOneWidget);
      expect(find.text(l10n.rhHlCallDoctor), findsOneWidget);
    });

    testWidgets(
      'no country yet and no content: still the doctor and the disclaimer',
      (tester) async {
        await pumpRouted(
          tester,
          const HealthSupportScreen(),
          overrides: rhythmOverrides(
            repo: FakeRhythmRepository()..content = null,
            caps: rhythmCaps(country: null),
          ),
        );
        expect(find.text(l10n.rhHlCallDoctor), findsOneWidget);
        expect(find.text(l10n.rhHlDisclaimer), findsOneWidget);
      },
    );
  });

  group('AC01 / AC02', () {
    testWidgets('AC01: steps, safety, review; "Mình sẽ thử" then AC02', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(checkIns: [sleepCheckIn()]);
      final (visits, _) = await pumpRouted(
        tester,
        ActivityScreen(
          contentId: 'act_wind_down',
          checkInId: sleepCheckIn().id,
        ),
        overrides: rhythmOverrides(me: minh, repo: repo),
      );
      expect(find.text(l10n.rhNotTried), findsOneWidget);
      expect(
        find.text('Vì: “khó vào giấc, giấc đêm, 2–3 ngày” (Mẹ ghi 07/10)'),
        findsOneWidget,
      );
      expect(find.text('Cho bú yên tĩnh'), findsOneWidget);
      expect(find.text(l10n.rhSafety), findsOneWidget);
      await tester.tap(find.text(l10n.rhIllTry));
      await tester.pumpAndSettle();
      expect(repo.savedFeedback.single.kind, FeedbackKind.started);
      // D-076 #10: a plan waits for its chance; no "Kể lại kết quả" yet.
      expect(find.text(l10n.rhPlannedTonight), findsWidgets);
      expect(find.text(l10n.rhTriedOn('08/10')), findsNothing);
      expect(find.text(l10n.rhTellHow), findsNothing);
      expect(find.text(l10n.rhCancelPlan), findsOneWidget);
      expect(visits, isEmpty);
    });

    testWidgets('AC01: "Không phù hợp với con" rules it out', (tester) async {
      final repo = FakeRhythmRepository();
      await pumpRouted(
        tester,
        const ActivityScreen(contentId: 'act_wind_down'),
        overrides: rhythmOverrides(repo: repo),
      );
      await tester.tap(find.text(l10n.rhNotRight));
      await tester.pumpAndSettle();
      expect(repo.savedFeedback.single.kind, FeedbackKind.notSuitable);
    });

    testWidgets('AC01: a relative reads it without the actions', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const ActivityScreen(contentId: 'act_wind_down'),
        overrides: rhythmOverrides(me: hoa, repo: FakeRhythmRepository()),
      );
      expect(
        find.text('Giảm kích thích 30 phút trước giấc đêm'),
        findsOneWidget,
      );
      expect(find.text(l10n.rhIllTry), findsNothing);
      expect(find.text(l10n.rhNotRight), findsNothing);
    });

    testWidgets('AC02: a choice is needed; the note travels with it', (
      tester,
    ) async {
      final repo = FakeRhythmRepository(
        feedback: [
          RecFeedback(
            id: newFeedbackId(),
            babyId: teddyId,
            authorUid: 'u_mai',
            contentId: 'act_wind_down',
            contentVersion: 1,
            kind: FeedbackKind.started,
            date: '2026-10-07',
          ),
        ],
      );
      await pumpRouted(
        tester,
        const ActivityFeedbackScreen(contentId: 'act_wind_down'),
        overrides: rhythmOverrides(repo: repo),
      );
      expect(find.text(l10n.rhHowLastNight), findsOneWidget);
      expect(find.text(l10n.rhFeedbackInfo), findsOneWidget);
      await tester.tap(find.text(l10n.rhSaveFeedback));
      await tester.pumpAndSettle();
      expect(repo.savedFeedback, isEmpty);
      await tester.tap(find.text(l10n.rhHelpful));
      await tester.enterText(find.byType(EditableText), '  Ngủ nhanh hơn  ');
      await tester.pump();
      await tester.tap(find.text(l10n.rhSaveFeedback));
      await tester.pumpAndSettle();
      final saved = repo.savedFeedback.last;
      expect(saved.kind, FeedbackKind.helpful);
      expect(saved.note, 'Ngủ nhanh hơn');
      expect(saved.date, rhythmToday);
      expect(find.text(l10n.rhFeedbackSaved), findsOneWidget);
    });
  });

  group('Tuỳ chỉnh Hôm nay', () {
    test(
      '"Dành cho bé hôm nay" joins saved layouts after the tiles, only with the flag',
      () {
        final layout = TodayLayout.fromJson({
          'order': ['tiles', 'reminders', 'rhythm'],
        });
        // D-076 #8: right after the quick-track tiles.
        expect(layout.order.take(2), [TodaySection.tiles, TodaySection.forYou]);
        expect(layout.shows(TodaySection.forYou), isTrue);
        expect(
          allowedSections(mai, hasTiles: true),
          isNot(contains(TodaySection.forYou)),
        );
        expect(
          allowedSections(mai, hasTiles: true, rhythm: true),
          contains(TodaySection.forYou),
        );
      },
    );
  });
}
