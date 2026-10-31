@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/nutrition/nutrition_state.dart';
import 'package:child_life/features/rhythm/personal_day_pages.dart';
import 'package:child_life/features/rhythm/personalization_sources.dart';
import 'package:child_life/features/rhythm/personalization_v2_repository.dart';
import 'package:child_life/features/rhythm/personalization_v2_screen.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/tried_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';

/// "Hôm nay của nhà mình" (P-172, owner 2026-10-22): the Home card and the screen with what
/// the person already did today (a plan, an attempt, a save), the handover and the history
/// pages — Light / Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/personal_day_golden_test.dart

List<Activity> get _ideas => rhythmContent().activities
    .where((a) => a.status == ContentStatus.published)
    .toList();

/// rhythmNow is 2026-10-08 10:00 in Hà Nội: a plan at 09:00, an attempt at 08:00.
PersonalDay _day() => PersonalDay({
  'asOf': '2026-10-08T03:00:00Z',
  'expiresAt': '2026-10-08T17:00:00Z',
  'today': '2026-10-08',
  'zone': 'Asia/Ho_Chi_Minh',
  'ageCardId': 'age_week_3',
  'writable': true,
  'parent': true,
  'contentVersion': rhythmContent().version,
  'context': 'few_minutes',
  'focus': 'play',
  'reason': 'WEEKLY_FOCUS',
  'activityIds': [_ideas[0].id, _ideas[2].id],
  'notes': [],
  'patterns': [],
  'lastRecords': [
    {'type': 'bottle', 'at': '2026-10-08T02:30:00Z', 'amountMl': 90},
    {'type': 'diaper', 'at': '2026-10-08T02:10:00Z'},
  ],
  'work': [
    {
      'id': 'rm_bath',
      'title': 'Tắm cho bé',
      'dueAt': '2026-10-08T10:00:00Z',
      'assigneeUid': null,
      'state': 'accepted',
      'actorUid': mai.uid,
      'revision': 1,
      'canAct': true,
    },
  ],
  'weekly': {'tried': 2, 'helpful': 1},
  'responses': {
    _ideas[0].id: {
      'value': 'intend',
      'at': '2026-10-08T02:00:00Z',
      'intendedAt': '2026-10-08T02:00:00Z',
      'saved': true,
    },
    _ideas[1].id: {
      'value': 'tried',
      'at': '2026-10-08T01:00:00Z',
      'triedAt': '2026-10-08T01:00:00Z',
      'until': '2026-10-08T17:00:00Z',
    },
  },
});

/// D-154 Q5: a child older than the published pack, nothing suggested: the line that ideas stop
/// at 3 years, and no "Điều chỉnh gợi ý".
PersonalDay _upToAgeDay() => PersonalDay({
  ..._day().data,
  'activityIds': <String>[],
  'responses': <String, Object?>{},
  'ideasMaxAgeDays': 1095,
});

class _HomeCard extends ConsumerWidget {
  const _HomeCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref
        .watch(
          personalizedSourceCardsProvider((
            babyId: teddyId,
            uid: mai.uid,
            languageCode: Localizations.localeOf(context).languageCode,
          )),
        )
        .where((c) => c.id.startsWith('act_'))
        .toList();
    return Scaffold(
      backgroundColor: context.cl.colors.cloud,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ClSpace.s4),
          children: [PersonalDayHome(primary: cards.firstOrNull)],
        ),
      ),
    );
  }
}

final _cases =
    <String, (Widget Function(), double, Future<void> Function(WidgetTester)?)>{
      'home_card': (() => const _HomeCard(), 620, null),
      'day': (() => const PersonalizationDayScreen(), 2300, null),
      'day_upto_age': (
        () => const PersonalizationDayScreen(),
        1800,
        (tester) async {
          expect(find.byKey(const Key('personalIdeasUpToAge')), findsOneWidget);
          expect(find.byKey(const Key('personalDayFocus')), findsNothing);
        },
      ),
      'handover': (() => const PersonalHandoverScreen(), 900, null),
      'week_block': (
        () => Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.cl.colors.cloud,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(ClSpace.s4),
                children: const [PersonalWeekBlock()],
              ),
            ),
          ),
        ),
        700,
        null,
      ),
      'history': (() => const TriedScreen(), 900, null),
      // The notebook editor: one caption per group, the same gap between groups.
      'notes_editor': (
        () => const PersonalNotesScreen(),
        900,
        (tester) async {
          await tester.tap(find.byType(ClButton).last);
          await tester.pumpAndSettle();
        },
      ),
    };

void main() {
  for (final MapEntry(key: name, value: (build, height, act))
      in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = Size(375, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...rhythmOverrides(
                  repo: FakeRhythmRepository(),
                  personalDay: name == 'day_upto_age' ? _upToAgeDay() : _day(),
                ),
                nuDataProvider.overrideWithValue(null),
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
                    home: build(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await act?.call(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/pd/${name}_${palette.name}_${locale.languageCode}.png',
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
