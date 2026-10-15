@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/keepsakes/keepsake_access.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/rhythm/rhythm_episodes.dart'
    show episodeIdFor;
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/week_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart' show mediaItem;
import '../helpers/reminder_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/rhythm_week_fixtures.dart';

/// EN09 "Tóm tắt tuần" (561:3102) in Light / Night care × vi / en: the free week (a completed
/// week seen on Thursday 8/10, 5/7 valid days, the gate) and the group A week (Sunday 11/10, the
/// week still running, the look-back), and "Tạo video tuần N" (D-076 #3). Synthetic data; the
/// mock's figures are not copied.
/// Regenerate on macOS:
/// flutter test --tags golden --update-goldens test/golden/rhythm_week_golden_test.dart

typedef _Case = ({double height, List<Override> Function() overrides});

final _cases = <String, _Case>{
  'week_free': (
    height: 1280,
    overrides: () =>
        weekOverrides(repo: FakeRhythmRepository(), reminders: mockReminders()),
  ),
  // D-076 #3: "Tạo video tuần N" with the week's photos (Video kỷ niệm on for the family).
  'week_video': (
    height: 1400,
    overrides: () => [
      ...weekOverrides(
        repo: FakeRhythmRepository(),
        reminders: mockReminders(),
      ),
      keepsakeAccessProvider.overrideWith(
        (ref, id) async => (cards: true, videos: true),
      ),
      mediaProvider.overrideWith(
        (ref, key) => Stream.value([
          for (final (i, day) in const [28, 30].indexed)
            mediaItem('mem_w$i', DateTime.utc(2026, 9, day, 3)),
          mediaItem('mem_w2', DateTime.utc(2026, 10, 3, 3)),
        ]),
      ),
    ],
  ),
  'week_advanced': (
    height: 1960,
    overrides: () => weekOverrides(
      caps: rhythmCaps(plan: 'beta', groupA: true),
      now: sundayNow,
      reminders: mockReminders(),
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
          tester.view.physicalSize = Size(375, c.height);
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
                  size: Size(375, c.height),
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
                    home: const WeekSummaryScreen(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
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
