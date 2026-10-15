import 'dart:async';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/navigation.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/router.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/care_screens.dart';
import 'package:child_life/features/care/history_screen.dart';
import 'package:child_life/features/first_aid/first_aid_screens.dart';
import 'package:child_life/features/keepsakes/keepsake_access.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/keepsake_resume.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/library_routes.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/library/stage_screens.dart';
import 'package:child_life/features/me/baby_profile_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/milestones/milestone_screens.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/purchase_resume.dart';
import 'package:child_life/features/reminders/reminder_screens.dart';
import 'package:child_life/features/rhythm/week_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/library_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/milestone_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/rhythm_week_fixtures.dart';

/// D-076 nav on the app's real router: every link from a page above the tab shell (Nhịp lớn lên,
/// Thư viện, Trợ lý, Tôi, Tăng trưởng, a paywall that just closed, a notification tap) into a
/// tab page (Kỷ niệm, Chăm sóc, Tiện ích) goes through `pushSafe`. A plain push there built a
/// second tab shell with the same page keys and the Navigator asserted
/// (`!keyReservation.contains(key)`), as MS01 did before D-076 #14: the flow froze.
final l10n = lookupAppLocalizations(const Locale('vi'));

/// Care, Kỷ niệm (cards and videos on) and Thư viện / Sơ cứu content, signed in as Mai.
List<Override> _base({List<LbStage>? stages}) => [
  ...careOverrides(firstAid: seedFirstAidPack(), growth: mockGrowth()),
  ...memoryOverrides(
    keepsakes: (cards: true, videos: true),
    keepsakeCatalog: seedCatalog(),
  ),
  ...libraryOverrides(stages: stages),
  keepsakeAssetImageProvider.overrideWithValue(
    (asset) => const StorageImage('keepsake/peach'),
  ),
];

/// The real router on a phone, opened on [tab].
Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester,
  List<Override> overrides, {
  String tab = Routes.care,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      ...overrides,
      sharedPreferencesProvider.overrideWithValue(preferences),
      environmentProvider.overrideWithValue(AppEnvironment.dev),
    ],
  );
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildClTheme(ClPalette.light),
        locale: const Locale('vi'),
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
  );
  await tester.pump(const Duration(seconds: 1));
  router.go(tab);
  await tester.pumpAndSettle();
  return (router, container);
}

Future<void> _open(
  WidgetTester tester,
  GoRouter router,
  String location,
) async {
  unawaited(router.push(location));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _end(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pump(const Duration(minutes: 1));
}

/// One tab shell, and nothing above it: the page pushed from above the shell replaced it.
void _landedInTabs(WidgetTester tester, GoRouter router) {
  expect(tester.takeException(), isNull);
  expect(router.aboveShell, isFalse);
  expect(
    router.routerDelegate.currentConfiguration.matches
        .whereType<ShellRouteMatch>(),
    hasLength(1),
  );
}

void main() {
  group('the helper', () {
    // A plain push in this state is what froze (the Navigator's duplicate page keys); it is not
    // replayed here because the broken tree also breaks the tests after it.
    testWidgets('tells tab pages and pages above the shell apart', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      expect(router.aboveShell, isFalse);
      for (final tab in [
        Routes.history,
        '${Routes.history}?filter=growth',
        Routes.firstAid,
        '${Routes.milestones}/p_x',
        Routes.memoryStory,
        Routes.milestoneCardEdit,
        Routes.spendingHistory,
      ]) {
        expect(router.isTabLocation(tab), isTrue, reason: tab);
      }
      for (final above in [
        Routes.growth,
        '${Routes.record}/r1',
        Routes.rhythmWeek,
        LbRoutes.stage('stg_w3'),
        Routes.assistant,
        Routes.premium,
        '${Routes.meBabies}/$teddyId',
      ]) {
        expect(router.isTabLocation(above), isFalse, reason: above);
      }
      await _open(tester, router, Routes.growth);
      expect(router.aboveShell, isTrue);
      await _end(tester, container);
    });

    testWidgets(
      'tab pages from the tabs and full-screen pages stay plain pushes',
      (tester) async {
        final (router, container) = await _app(tester, _base());
        // Inside the shell: the Chăm sóc page stays under the next one.
        unawaited(router.pushSafe(Routes.history));
        await tester.pumpAndSettle();
        unawaited(router.pushSafe(Routes.growth));
        await tester.pumpAndSettle();
        expect(find.byType(GrowthScreen), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(HistoryScreen), findsOneWidget);
        // From above the shell: Tăng trưởng closes, the Chăm sóc page under it stays.
        unawaited(router.pushSafe(Routes.growth));
        await tester.pumpAndSettle();
        unawaited(router.pushSafe(Routes.feedStats));
        await tester.pumpAndSettle();
        _landedInTabs(tester, router);
        expect(find.byType(GrowthScreen), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(HistoryScreen), findsOneWidget);
        await _end(tester, container);
      },
    );

    testWidgets('notification taps land on tab pages from anywhere', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, Routes.growth);
      // reminder_notifications: a one-time reminder, then a milestone nudge.
      final id = mockReminders().first.id;
      unawaited(router.pushSafe('${Routes.reminders}/$id'));
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(ReminderDetailScreen), findsOneWidget);
      await _open(tester, router, Routes.growth);
      unawaited(
        router.pushSafe('${Routes.milestoneCard}?occasion=${Occasion.m1.wire}'),
      );
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(MilestoneCardScreen), findsOneWidget);
      await _end(tester, container);
    });
  });

  group('links from above the tabs', () {
    testWidgets('28 Tăng trưởng "Xem tất cả" → Lịch sử (growth)', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, Routes.growth);
      await _tap(tester, find.text(l10n.growthSeeAll));
      _landedInTabs(tester, router);
      expect(find.byType(GrowthScreen), findsNothing);
      expect(
        tester.widget<HistoryScreen>(find.byType(HistoryScreen)).filter,
        HistoryFilter.growth,
      );
      await _end(tester, container);
    });

    testWidgets('13l hồ sơ bé "Tăng trưởng" → Lịch sử (growth)', (
      tester,
    ) async {
      final (router, container) = await _app(tester, [
        ..._base(),
        ...meOverrides(),
      ]);
      await _open(tester, router, '${Routes.meBabies}/$teddyId');
      expect(find.byType(BabyProfileViewScreen), findsOneWidget);
      await _tap(tester, find.text(l10n.bpGrowthHint));
      _landedInTabs(tester, router);
      expect(find.byType(BabyProfileViewScreen), findsNothing);
      expect(find.byType(HistoryScreen), findsOneWidget);
      await _end(tester, container);
    });

    testWidgets('4d doctor callout → Sơ cứu', (tester) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, LbRoutes.articleOf('art_newborn_sleep'));
      expect(find.byType(ArticleScreen), findsOneWidget);
      await _tap(tester, find.byKey(const Key('lbOpenFirstAid')));
      _landedInTabs(tester, router);
      expect(find.byType(ArticleScreen), findsNothing);
      expect(find.byType(FirstAidHomeScreen), findsOneWidget);
      await _end(tester, container);
    });

    testWidgets('2b "Mốc thường gặp" → the milestone (3b)', (tester) async {
      final milestone = seedMilestones().first;
      final stage = LbStage.fromDoc('stg_w3', {
        ...stageDocs.firstWhere((d) => d['id'] == 'stg_w3'),
        'milestoneIds': [milestone.id],
      })!;
      final (router, container) = await _app(
        tester,
        _base(
          stages: [
            for (final s in fixtureStages()) s.id == stage.id ? stage : s,
          ],
        ),
      );
      await _open(tester, router, LbRoutes.stage(stage.id));
      expect(find.byType(StageDetailScreen), findsOneWidget);
      await _tap(tester, find.text(milestone.title.of('vi')));
      _landedInTabs(tester, router);
      expect(find.byType(StageDetailScreen), findsNothing);
      expect(find.byType(MilestoneDetailScreen), findsOneWidget);
      await _end(tester, container);
    });

    testWidgets('a purchase resumed onto a page above the tabs → MM11', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      // The paywall has just closed onto Tăng trưởng (any page above the tabs, e.g. MS01).
      await _open(tester, router, Routes.growth);
      final template = seedCatalog().cards.firstWhere(
        (t) => t.id == 'card_blush',
      );
      final draft = CardDraft(
        babyId: teddyId,
        occasion: Occasion.m1,
        date: DateTime(2026, 10, 17),
        format: KeepsakeFormat.portrait,
        template: template,
        palette: template.palette,
        quote: 'Một tháng yêu thương',
        photos: const [],
      );
      final key = container
          .read(resumeDraftsProvider)
          .keep(draft, cardDraftToJson(draft));
      final done = resumeAfterPurchase(
        router,
        container,
        PurchaseResume(
          kind: ResumeKind.card,
          templateId: template.id,
          draftRef: key,
        ),
      );
      await tester.pumpAndSettle();
      await done;
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(GrowthScreen), findsNothing);
      expect(
        tester
            .widget<MilestoneCardEditScreen>(
              find.byType(MilestoneCardEditScreen),
            )
            .draft
            .template
            .id,
        'card_blush',
      );
      await _end(tester, container);
    });

    testWidgets('EN09 "Tạo video tuần N" → Video kỷ niệm with the photos', (
      tester,
    ) async {
      final media = [
        mediaItem('mem_a', DateTime.utc(2026, 9, 29, 3)),
        mediaItem('mem_b', DateTime.utc(2026, 9, 30, 3)),
        mediaItem('mem_c', DateTime.utc(2026, 10, 6, 3)),
        mediaItem('mem_d', DateTime.utc(2026, 10, 7, 3)),
      ];
      final (router, container) = await _app(tester, [
        ...weekOverrides(repo: FakeRhythmRepository()),
        ...libraryOverrides(),
        dayMarksProvider.overrideWith((ref, key) => Stream.value(const {})),
        keepsakeAccessProvider.overrideWith(
          (ref, id) async => (cards: true, videos: true),
        ),
        keepsakeCatalogProvider.overrideWith(
          (ref) => Stream.value(seedCatalog()),
        ),
        mediaProvider.overrideWith((ref, key) => Stream.value(media)),
        keepsakeAssetImageProvider.overrideWithValue(
          (asset) => const StorageImage('keepsake/peach'),
        ),
      ]);
      await _open(tester, router, Routes.rhythmWeek);
      expect(find.byType(WeekSummaryScreen), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('rh.weekVideo')));
      _landedInTabs(tester, router);
      expect(find.byType(WeekSummaryScreen), findsNothing);
      final kinds = tester.widget<KeepsakeKindsScreen>(
        find.byType(KeepsakeKindsScreen),
      );
      expect(kinds.video, isTrue);
      expect(kinds.photoIds, isNotEmpty);
      await _end(tester, container);
    });

    testWidgets('Trợ lý: a saved feed "Mở nhật ký" → Lịch sử', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot(bottleState: 'saved')},
      );
      String key(String what) => 'assistant.$what.u_mai:${teddyScope.key}';
      final (router, container) = await _app(
        tester,
        [
          ...assistantOverrides(repo: repo),
          ...libraryOverrides(),
          rangeRecordsProvider.overrideWith(
            (ref, key) => Stream.value(const []),
          ),
          dayMarksProvider.overrideWith((ref, key) => Stream.value(const {})),
        ],
        prefs: {
          key('conversation'): conversation1,
          key('tasks'): [taskA],
        },
      );
      await _open(tester, router, assistantLocation(teddyScope));
      expect(find.byType(AssistantChatScreen), findsOneWidget);
      await _tap(tester, find.text(l10n.asOpenLog).first);
      _landedInTabs(tester, router);
      expect(find.byType(AssistantChatScreen), findsNothing);
      expect(find.byType(HistoryScreen), findsOneWidget);
      await _end(tester, container);
    });
  });

  group('Chăm sóc', () {
    testWidgets('"Mốc phát triển" is live and opens 3a', (tester) async {
      final (router, container) = await _app(tester, _base());
      expect(find.byType(CareHubScreen), findsOneWidget);
      await _tap(tester, find.byKey(const Key('careMilestones')));
      _landedInTabs(tester, router);
      expect(find.byType(MilestonesScreen), findsOneWidget);
      await _end(tester, container);
    });
  });
}
