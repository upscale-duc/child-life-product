@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_rows.dart';
import 'package:child_life/features/ai/ai_repository.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/library/library_today.dart'
    show lbWeekTeaserProvider;
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:child_life/features/rhythm/rhythm_home.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_personalize.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/ai_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/hn_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';

/// Hôm nay · cá nhân hoá (D-076 #1, #4, #8): EN01, EN02, EN03, Hôm nay with the invite
/// (559:57870), "Dành cho bé hôm nay" (559:57583) and Tuỳ chỉnh Hôm nay with the section after
/// the tiles — Light / Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/hn_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
  double height,
});

Future<void> _continue(WidgetTester t) async {
  await t.tap(find.byType(ClButton).first);
  await t.pumpAndSettle();
}

/// The section as it sits on Hôm nay, under the tiles.
Widget _section() => Builder(
  builder: (context) => Scaffold(
    backgroundColor: context.cl.colors.cloud,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        children: const [TodayForBabySection()],
      ),
    ),
  ),
);

CheckIn _soothing(String date, String uid) => CheckIn(
  id: 'ci_$date$uid',
  babyId: teddyId,
  date: date,
  authorUid: uid,
  observation: Observation.soothing,
);

final _cases = <String, _Case>{
  // EN01 559:2288 with three interests picked.
  'en01_interests': (
    build: () => const PersonalizeFlowScreen(),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: (t) async {
      final tiles = find.byType(InterestTile);
      for (final i in const [0, 1, 2]) {
        await t.tap(tiles.at(i));
      }
      await t.pumpAndSettle();
    },
    height: 900,
  ),
  // EN02 559:2383: the evening round-up, quiet hours on.
  'en02_digest': (
    build: () => const PersonalizeFlowScreen(),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: _continue,
    height: 812,
  ),
  // EN03 559:2458, on a phone that does not show notifications yet.
  'en03_notifications': (
    build: () => const PersonalizeFlowScreen(),
    overrides: () => hnOverrides(
      repo: StampingRhythmRepository(),
      notifications: FakeReminderNotifications(on: false),
    ),
    act: (t) async {
      await _continue(t);
      await _continue(t);
    },
    height: 812,
  ),
  // 559:57870 for someone who has not personalised (joined by invite, or skipped).
  'home_invite': (
    build: () => const Scaffold(body: TodayScreen()),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: null,
    height: 812,
  ),
  // 559:57583: interests line, Nhịp lớn lên card with the family's soothing notes, the
  // check-in and age cards of Nhịp lớn lên, then small cards from other modules.
  'home_for_baby': (
    build: _section,
    overrides: () => hnOverrides(
      repo: StampingRhythmRepository(
        preferences: personalized(),
        checkIns: [
          _soothing('2026-10-07', 'u_mai'),
          _soothing('2026-10-06', 'u_minh'),
        ],
      ),
      articles: sampleForBabyCards().take(1).toList(),
      milestones: sampleForBabyCards().skip(1).toList(),
    ),
    act: null,
    height: 900,
  ),
  // "Tuần này của Teddy" (owner, 2026-10-15): one card, the week of life and the age, a teaser
  // from the current stage, then the Nhịp lớn lên and week summary rows.
  'week_card': (
    build: () => const _WeekCardAlone(),
    overrides: () => hnOverrides(repo: StampingRhythmRepository()),
    act: null,
    height: 440,
  ),
  // Tuỳ chỉnh Hôm nay: "Dành cho bé hôm nay" right after the tiles (D-076 #8).
  'customize': (
    build: () => const Scaffold(body: TodayScreen()),
    overrides: () => hnOverrides(
      repo: StampingRhythmRepository(preferences: personalized()),
    ),
    act: (t) async {
      showTodayCustomizeSheet(t.element(find.byType(TodayScreen)));
      await t.pumpAndSettle();
    },
    height: 900,
  ),
};

/// The week card alone, as "Tuần này của Teddy" draws it (Teddy is 21 days old on 8/10).
class _WeekCardAlone extends StatelessWidget {
  const _WeekCardAlone();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.cl.colors.cloud,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ClSpace.s4),
          children: [
            ClSectionHeader(title: l10n.rhAgeHeading('Teddy')),
            const SizedBox(height: ClSpace.s3),
            WeekCard(
              kicker: weekKicker(
                l10n,
                dob: DateTime(2026, 9, 17),
                today: DateTime(2026, 10, 8),
              ),
              teaser: (
                id: 'stage:stg_3_4w',
                text: Localizations.localeOf(context).languageCode == 'en'
                    ? 'Your baby starts to follow faces held close'
                    : 'Bé bắt đầu nhìn theo mặt người khi được bế gần',
                ideas: 3,
                onOpen: (_) {},
              ),
              rows: [
                (
                  key: const Key('forBabyRhythm'),
                  icon: ClIcons.sleep,
                  tone: WeekRowTone.rhythm,
                  title: l10n.hnRhythmComingDays(1, 4),
                  sub: l10n.hnWeekRhythmSub('12/10 – 21/10'),
                  onOpen: (_) {},
                ),
                (
                  key: const Key('forBabyWeekSummary'),
                  icon: ClIcons.journal,
                  tone: WeekRowTone.mint,
                  title: l10n.hnWeekSummaryLast,
                  sub: l10n.rhDateRange('28/09', '04/10'),
                  onOpen: (_) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hôm nay whole, in the real tab shell (dock, "+", Lumi), tall enough to see every section and
/// that the last one ends above Lumi (owner, 2026-10-15).
GoRouter _shell() => GoRouter(
  initialLocation: Routes.today,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HomeShell(shell: shell),
      branches: [
        for (final root in [
          Routes.today,
          Routes.memories,
          Routes.care,
          Routes.family,
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: root,
                builder: (_, _) => root == Routes.today
                    ? const TodayScreen()
                    : const Scaffold(body: SizedBox()),
              ),
            ],
          ),
      ],
    ),
  ],
);

typedef _HomeCase = ({List<Override> Function() overrides, double height});

/// Overrides for the whole Hôm nay of [me]: the day's care log, reminders, the rhythm rollout
/// with [caps], the small cards and the stage teaser, the AI handover, and Lumi.
List<Override> _homeOverrides({
  required Membership me,
  required FakeRhythmRepository repo,
  required Map<String, Object?> caps,
  List<ForBabyCard> cards = const [],
  WeekTeaser? teaser,
  FakeAiRepository? ai,
}) => [
  articleForBabyCardsProvider.overrideWith(
    (ref, q) => [
      for (final c in cards)
        if (!c.id.startsWith('milestone')) c,
    ],
  ),
  milestoneForBabyCardsProvider.overrideWith(
    (ref, q) => [
      for (final c in cards)
        if (c.id.startsWith('milestone')) c,
    ],
  ),
  lbWeekTeaserProvider.overrideWith((ref, q) => teaser),
  ...rhythmOverrides(
    repo: repo,
    me: me,
    caps: caps,
    now: careNow,
    records: mockDay(),
    reminders: mockReminders(),
  ),
  aiRepositoryProvider.overrideWithValue(ai ?? FakeAiRepository()),
  networkKindProvider.overrideWith((ref) => Stream.value(NetworkKind.none)),
  queueStoreProvider.overrideWithValue(MemoryQueueStore()),
  assistantAccessProvider.overrideWith(
    (ref, babyId) => const AssistantAccess(),
  ),
];

final _homeCases = <String, _HomeCase>{
  // A parent with everything published: the suggestion (group A), "Để ý tuần này", the
  // check-in, the week card with the stage teaser, the handover with the tiles.
  'home_parent': (
    overrides: () => _homeOverrides(
      me: mai,
      repo: StampingRhythmRepository(
        preferences: personalized(),
        home: h02Home(),
        checkIns: [sleepCheckIn()],
      ),
      caps: aiCaps(),
      cards: [sampleStageCard(), ...sampleForBabyCards()],
      teaser: sampleStageTeaser(),
      ai: FakeAiRepository(answer: handover()),
    ),
    height: 2560,
  ),
  // A parent on the free plan before any content is published: the check-in, the quiet upsell
  // and the week summary row; nothing invented.
  'home_parent_empty': (
    overrides: () => _homeOverrides(
      me: mai,
      repo: StampingRhythmRepository(preferences: personalized())
        ..content = null
        ..reference = null,
      caps: rhythmCaps(),
    ),
    height: 2000,
  ),
  // Cô Lan (Người chăm sóc): no date of birth, so the week of life comes from the age card the
  // server picked; the latest handover to read; no reference calendar.
  'home_caregiver': (
    overrides: () => _homeOverrides(
      me: lan,
      repo: StampingRhythmRepository(home: h02Home()),
      caps: aiCaps(),
      cards: sampleForBabyCards().take(1).toList(),
      ai: FakeAiRepository(stored: [handover()]),
    ),
    height: 2640,
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({
            // The first-run tour already ran.
            'tour.today.done': true,
            'rhythm.setupSeen.u_mai.$teddyId': true,
          });
          final prefs = await SharedPreferences.getInstance();
          final size = Size(375, c.height);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(
                path: '/:a',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
              GoRoute(
                path: '/:a/:b',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp.router(
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
                    routerConfig: router,
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
                'goldens/hn/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
  for (final MapEntry(key: name, value: c) in _homeCases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({
            'tour.today.done': true,
            'rhythm.setupSeen.u_mai.$teddyId': true,
            'rhythm.setupSeen.u_lan.$teddyId': true,
            LumiIntroSeenNotifier.keyFor('u_mai'): true,
            LumiIntroSeenNotifier.keyFor('u_lan'): true,
          });
          final prefs = await SharedPreferences.getInstance();
          final size = Size(375, c.height);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp.router(
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
                    routerConfig: _shell(),
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
                'goldens/hn/${name}_${palette.name}_${locale.languageCode}.png',
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
