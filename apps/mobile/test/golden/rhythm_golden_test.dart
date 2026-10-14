@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/rhythm/activity_screens.dart';
import 'package:child_life/features/rhythm/checkin_screens.dart';
import 'package:child_life/features/rhythm/health_screen.dart';
import 'package:child_life/features/rhythm/result_screen.dart';
import 'package:child_life/features/rhythm/rhythm_home.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';

/// Nhịp lớn lên, Slice 2 part 1 (plan §7.1): H01, H02, PS02, C01, C02, NL05b, PS01, PS01F, AC01,
/// AC02 and HL01 in Light / Night care × vi / en. Synthetic data only (review: null content).
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
  // HL01 594:7066: fever under 3 months, household in VN (115 from the approved pack).
  'hl01_health': (
    build: () => const HealthSupportScreen(signs: [HealthSign.feverYoung]),
    overrides: () => rhythmOverrides(
      caps: rhythmCaps(plan: 'expired'),
      repo: FakeRhythmRepository(),
    ),
    act: null,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
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
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
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
