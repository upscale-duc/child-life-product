@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/rhythm/activity_history_screen.dart';
import 'package:child_life/features/rhythm/activity_screens.dart';
import 'package:child_life/features/rhythm/checkin_screens.dart';
import 'package:child_life/features/rhythm/health_screen.dart';
import 'package:child_life/features/rhythm/milestone_screen.dart';
import 'package:child_life/features/rhythm/preferences_screens.dart';
import 'package:child_life/features/rhythm/result_screen.dart';
import 'package:child_life/features/rhythm/rhythm_calendar.dart';
import 'package:child_life/features/rhythm/rhythm_home.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_overview.dart';
import 'package:child_life/features/rhythm/rhythm_own.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/features/rhythm/rhythm_setup.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';

/// Nhịp lớn lên, Slice 2 (plan §7.1): part 1 — H01, H02, PS02, C01, C02, NL05b, PS01, PS01F,
/// AC01, AC02, HL01; part 2 — NL01 (free / advanced), NL01b (no due date, sparse), NL02b, NL03,
/// NL04, the NL07 section (with the NL07b suggestion, Premium Slice 3 leftovers), EN01, EN02,
/// MS01 — in Light / Night care × vi / en. Synthetic data
/// only (review: null content). Long screens are drawn taller ([_heights]).
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/rhythm_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

/// Hôm nay's section as it sits under the title.
Widget _home() => Builder(
  builder: (context) => Scaffold(
    backgroundColor: context.cl.colors.cloud,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        children: const [ForYouSection()],
      ),
    ),
  ),
);

/// Screens drawn taller than a phone, to see them whole.
const _heights = {
  'nl01_free': 1760.0,
  'nl01_advanced': 1960.0,
  'nl01b_sparse': 1200.0,
  'nl04_stage': 1200.0,
  'en01_interests': 1000.0,
  'tried_history': 1000.0,
};

/// D-076 #10: a plan (`started`) by [by] on [date], made at [at].
RecFeedback _plan(
  String by,
  String date,
  DateTime at, {
  String contentId = 'act_wind_down',
}) => RecFeedback(
  id: 'fb_${by.hashCode.toRadixString(16).padLeft(8, '0')}${'c' * 24}',
  babyId: teddyId,
  authorUid: by,
  contentId: contentId,
  contentVersion: contentId == 'act_skin_to_skin' ? 2 : 1,
  kind: FeedbackKind.started,
  date: date,
  createdAt: at,
);

HomeComposition _startedHome() => HomeComposition.fromJson({
  'state': 'suggestion',
  'recommendation': recommendationJson(state: 'started'),
  'secondary': <Object>[],
  'ageCardId': 'age_week_3',
  'gate': null,
  'sleep': null,
  'lastFeedback': null,
});

/// NL07's own-rhythm card alone.
Widget _ownCard() => Consumer(
  builder: (context, ref, _) => Scaffold(
    backgroundColor: context.cl.colors.cloud,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(ClSpace.s4),
        children: [
          OwnRhythmCard(
            me: mai,
            caps: ref.watch(capabilitiesProvider(teddyId)).value,
            zone: 'Asia/Ho_Chi_Minh',
            today: rhythmToday,
          ),
        ],
      ),
    ),
  ),
);

final _cases = <String, _Case>{
  // H01 589:6281: free household, the owner (age card, calendar, "Hỗ trợ phù hợp").
  'h01_free': (
    build: _home,
    overrides: () => rhythmOverrides(repo: FakeRhythmRepository()),
    act: null,
  ),
  // H02 589:6368: group A (beta), Ba sees the suggestion from Mẹ's check-in.
  'h02_suggestion': (
    build: _home,
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(home: h02Home(), checkIns: [sleepCheckIn()]),
    ),
    act: null,
  ),
  // PS02 591:6495: the next open after Mẹ's "Có ích".
  'ps02_feedback_used': (
    build: _home,
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        home: ps02Home(),
        checkIns: [sleepCheckIn()],
        feedback: [helpfulFeedback()],
      ),
    ),
    act: null,
  ),
  // C01 589:6451 with "Khó vào giấc / hay thức" chosen.
  'c01_checkin': (
    build: () => const CheckInScreen(),
    overrides: () => rhythmOverrides(repo: FakeRhythmRepository()),
    act: (t) async {
      final l10n = AppLocalizations.of(t.element(find.byType(CheckInScreen)));
      await t.tap(find.text(l10n.rhObsSleep));
      await t.pumpAndSettle();
    },
  ),
  // C02 589:6492: sleep follow-ups, with last night from the care log.
  'c02_more': (
    build: () => const CheckInMoreScreen(observation: Observation.sleep),
    overrides: () => rhythmOverrides(
      repo: FakeRhythmRepository(),
      records: lastNightSleep(),
    ),
    act: (t) async {
      final l10n = AppLocalizations.of(
        t.element(find.byType(CheckInMoreScreen)),
      );
      for (final label in [
        l10n.rhWhenNightSleep,
        l10n.rhSince23,
        l10n.rhTriedRocking,
      ]) {
        await t.tap(find.text(label));
      }
      await t.pumpAndSettle();
    },
  ),
  // NL05b 572:1161: one answer per sign; "Có" on fever (Teddy is 3 weeks old).
  'nl05b_health_questions': (
    build: () => const HealthQuestionsScreen(),
    overrides: () => rhythmOverrides(repo: FakeRhythmRepository()),
    act: (t) async {
      final l10n = AppLocalizations.of(
        t.element(find.byType(HealthQuestionsScreen)),
      );
      await t.tap(find.text(l10n.rhAnswerYes).first);
      await t.tap(find.text(l10n.rhAnswerUnsure).at(1));
      await t.pumpAndSettle();
    },
  ),
  // PS01 590:6445: group A, the suggestion with its reason and the review label.
  'ps01_suggestion': (
    build: () => RhythmResultScreen(checkIn: sleepCheckIn(date: rhythmToday)),
    overrides: () => rhythmOverrides(
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        answer: NextActionAnswer.fromJson(nextActionJson()),
      ),
    ),
    act: null,
  ),
  // PS01F 590:6481: free, age content and the optional "Tìm hiểu thêm".
  'ps01f_free': (
    build: () => RhythmResultScreen(checkIn: sleepCheckIn(date: rhythmToday)),
    overrides: () => rhythmOverrides(
      repo: FakeRhythmRepository(
        answer: NextActionAnswer.fromJson({
          'state': 'free_content',
          'ageCardId': 'age_month_0',
          'gate': 'PREMIUM_REQUIRED',
        }),
      ),
    ),
    act: null,
  ),
  // AC01 590:6515: not tried yet; Ba reads Mẹ's reason.
  'ac01_activity': (
    build: () => ActivityScreen(
      contentId: 'act_wind_down',
      checkInId: sleepCheckIn().id,
    ),
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(checkIns: [sleepCheckIn()]),
    ),
    act: null,
  ),
  // AC02 590:6558: tried last evening → "Tối qua thế nào?", "Có ích" and a note.
  'ac02_feedback': (
    build: () => const ActivityFeedbackScreen(contentId: 'act_wind_down'),
    overrides: () => rhythmOverrides(
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        feedback: [
          RecFeedback(
            id: newFeedbackId(),
            babyId: teddyId,
            authorUid: 'u_mai',
            contentId: 'act_wind_down',
            contentVersion: 1,
            kind: FeedbackKind.started,
            date: '2026-10-07',
            createdAt: DateTime.utc(2026, 10, 7, 13),
          ),
        ],
      ),
    ),
    act: (t) async {
      final l10n = AppLocalizations.of(
        t.element(find.byType(ActivityFeedbackScreen)),
      );
      await t.tap(find.text(l10n.rhHelpful));
      await t.enterText(
        find.byType(EditableText),
        'Con vào giấc nhanh hơn sau khi tắm',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
    },
  ),
  // D-076 #10: after "Thử tối nay" H02 waits — "Đã lên kế hoạch · tối nay", "Bỏ kế hoạch".
  'h02_planned': (
    build: _home,
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        home: _startedHome(),
        checkIns: [sleepCheckIn()],
        feedback: [_plan('u_minh', rhythmToday, DateTime.utc(2026, 10, 8, 2))],
      ),
    ),
    act: null,
  ),
  // …and once the chance has passed (Mẹ planned it last evening): the result, "Chưa thử".
  'h02_follow_up': (
    build: _home,
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        home: _startedHome(),
        checkIns: [sleepCheckIn()],
        feedback: [_plan('u_mai', '2026-10-07', DateTime.utc(2026, 10, 7, 13))],
      ),
    ),
    act: null,
  ),
  // AC01 with Ba's plan for tonight: the status and "Bỏ kế hoạch", no "Kể lại kết quả" yet.
  'ac01_planned': (
    build: () => ActivityScreen(
      contentId: 'act_wind_down',
      checkInId: sleepCheckIn().id,
    ),
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        checkIns: [sleepCheckIn()],
        feedback: [_plan('u_minh', rhythmToday, DateTime.utc(2026, 10, 8, 2))],
      ),
    ),
    act: null,
  ),
  // "Các cách đã thử": an answered plan, an open one past its chance, one waiting.
  'tried_history': (
    build: () => const ActivityHistoryScreen(),
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      repo: FakeRhythmRepository(
        feedback: [
          _plan('u_mai', '2026-10-05', DateTime.utc(2026, 10, 5, 12)),
          helpfulFeedback(),
          _plan(
            'u_mai',
            '2026-10-07',
            DateTime.utc(2026, 10, 7, 2),
            contentId: 'act_skin_to_skin',
          ),
          _plan(
            'u_minh',
            rhythmToday,
            DateTime.utc(2026, 10, 8, 2),
            contentId: 'act_evening_repeat',
          ),
        ],
      ),
    ),
    act: null,
  ),
  // HL01 594:7066: fever under 3 months, household in VN (115 from the approved pack).
  'hl01_health': (
    build: () => const HealthSupportScreen(signs: [HealthSign.feverYoung]),
    overrides: () => rhythmOverrides(
      caps: rhythmCaps(plan: 'expired'),
      repo: FakeRhythmRepository(),
    ),
    act: null,
  ),
  // NL01 569:973: free household (no rhythm.advanced), due date set, a mixed day, feedback.
  'nl01_free': (
    build: () => const RhythmOverviewScreen(),
    overrides: () => rhythmOverrides(
      repo: FakeRhythmRepository(
        checkIns: recentCheckIns(),
        feedback: familyFeedback(),
      ),
    ),
    act: null,
  ),
  // NL01 with rhythm.advanced: the sleep comparison computed on the phone (NL07).
  'nl01_advanced': (
    build: () => const RhythmOverviewScreen(),
    overrides: () => rhythmOverrides(
      me: minh,
      caps: rhythmCaps(plan: 'beta', groupA: true),
      sleepRecords: sleepLog(),
      repo: FakeRhythmRepository(
        checkIns: recentCheckIns(),
        feedback: familyFeedback(),
      ),
    ),
    act: null,
  ),
  // NL01b 570:1002: no due date, 2/5 valid days (counted automatically), offline.
  'nl01b_sparse': (
    build: () => const RhythmOverviewScreen(),
    overrides: () => rhythmOverrides(
      caps: rhythmCaps(plan: 'beta', groupA: true),
      sleepRecords: sleepLog(days: 5, sparseDay: null),
      online: false,
      repo: FakeRhythmRepository(profile: teddyRhythmProfile(dueDate: false)),
    ),
    act: null,
  ),
  // NL02b 570:1108: "Không nhớ" → estimate from 39 weeks + 3 days.
  'nl02b_due_date': (
    build: () => const RhythmSetupScreen(
      start: RhythmSetupStep.dueDate,
      single: true,
      estimate: true,
    ),
    overrides: () => rhythmOverrides(
      repo: FakeRhythmRepository(profile: teddyRhythmProfile(dueDate: false)),
    ),
    act: null,
  ),
  // NL03 571:1054: the stages from the due date (1 and 2 overlap).
  'nl03_calendar': (
    build: () => const ReferenceCalendarScreen(),
    overrides: () => rhythmOverrides(repo: FakeRhythmRepository()),
    act: null,
  ),
  // NL04 571:1158: stage 1 with signs, skills, a linked activity and sources.
  'nl04_stage': (
    build: () => const StageDetailScreen(stageId: 'stage_1'),
    overrides: () => rhythmOverrides(repo: FakeRhythmRepository()),
    act: null,
  ),
  // NL07 573:1109: the own-rhythm section with rhythm.advanced.
  'nl07_own_rhythm': (
    build: _ownCard,
    overrides: () => rhythmOverrides(
      caps: rhythmCaps(plan: 'beta', groupA: true),
      sleepRecords: sleepLog(),
      repo: FakeRhythmRepository(checkIns: recentCheckIns()),
    ),
    act: null,
  ),
  // EN01 559:2288: three interests chosen, one topic turned down (EN05).
  'en01_interests': (
    build: () => const InterestsScreen(),
    overrides: () => rhythmOverrides(
      repo: FakeRhythmRepository(
        preferences: const UserPreferences(
          interests: [Interest.sleep, Interest.feeding, Interest.milestones],
          fewer: [Interest.nutrition],
        ),
      ),
    ),
    act: null,
  ),
  // EN02 559:2383: the evening round-up and quiet hours.
  'en02_digest': (
    build: () => const DigestScreen(),
    overrides: () => rhythmOverrides(
      repo: FakeRhythmRepository(
        preferences: const UserPreferences(digestTime: '20:30'),
      ),
    ),
    act: null,
  ),
  // MS01 591:6632: "Lần đầu lẫy" saved as a milestone → "Giữ khoảnh khắc này?".
  'ms01_milestone': (
    build: () => const RhythmMilestoneScreen(note: 'Lần đầu lẫy'),
    overrides: () => rhythmOverrides(repo: FakeRhythmRepository()),
    act: (t) async {
      final l10n = AppLocalizations.of(
        t.element(find.byType(RhythmMilestoneScreen)),
      );
      await t.tap(find.text(l10n.rhSaveToMilestones));
      await t.pumpAndSettle();
    },
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          // NL01's first-open setup already ran for these people.
          SharedPreferences.setMockInitialValues({
            'rhythm.setupSeen.u_mai.$teddyId': true,
            'rhythm.setupSeen.u_minh.$teddyId': true,
          });
          final prefs = await SharedPreferences.getInstance();
          final height = _heights[name] ?? 812;
          tester.view.physicalSize = Size(375, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(375, height),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: buildClTheme(palette),
                    locale: locale,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: c.build(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await c.act?.call(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/rh/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
