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
import 'package:child_life/features/care/stats_screens.dart';
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
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/reminder_screens.dart';
import 'package:child_life/features/rhythm/week_screen.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/features/utilities/utilities_screen.dart';
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
/// tab page (Kỷ niệm, Chăm sóc, Tiện ích) opens that page's overlay twin ON TOP of the opener:
/// one tab shell, and Back returns to the opener with its state. A plain push of the tab page
/// there built a second tab shell with the same page keys and the Navigator asserted
/// (`!keyReservation.contains(key)`, D-076 #14); closing the opener instead sent Back to Hôm nay
/// (owner: "mở nhật ký từ Lumi chat, khi back lại thì nó về Home").
final l10n = lookupAppLocalizations(const Locale('vi'));

/// Care, Kỷ niệm (cards and videos on) and Thư viện / Sơ cứu content, signed in as Mai.
List<Override> _base({
  List<LbStage>? stages,
  ReminderNotifications? notifications,
}) => [
  ...careOverrides(
    firstAid: seedFirstAidPack(),
    growth: mockGrowth(),
    notifications: notifications,
  ),
  ...memoryOverrides(
    keepsakes: (cards: true, videos: true),
    keepsakeCatalog: seedCatalog(),
  ),
  ...libraryOverrides(stages: stages),
  keepsakeAssetImageProvider.overrideWithValue(
    (asset) => const StorageImage('keepsake/peach'),
  ),
];

/// The real router on a phone, opened on [tab] ([tab] null: left where the guard puts a cold
/// start), under [wrap] (the app's notification layer, say).
Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester,
  List<Override> overrides, {
  String? tab = Routes.care,
  Map<String, Object> prefs = const {},
  Widget Function(Widget app)? wrap,
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
  final app = MaterialApp.router(
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
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: wrap == null ? app : wrap(app),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  if (tab != null) router.go(tab);
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

int _shells(GoRouter router) => router
    .routerDelegate
    .currentConfiguration
    .matches
    .whereType<ShellRouteMatch>()
    .length;

/// One tab shell, and nothing above it: the page landed inside the tabs.
void _landedInTabs(WidgetTester tester, GoRouter router) {
  expect(tester.takeException(), isNull);
  expect(router.aboveShell, isFalse);
  expect(_shells(router), 1);
}

/// One tab shell, the opener still above it, and [location]'s overlay twin on top.
void _onOpener(WidgetTester tester, GoRouter router, String location) {
  expect(tester.takeException(), isNull);
  expect(router.aboveShell, isTrue);
  expect(_shells(router), 1);
  expect(router.state.uri.toString(), OverlayTwin.of(location));
}

/// How Back is pressed.
enum _Back {
  /// The page's own Back (`context.pop()`).
  page,

  /// Android's back button (the router's back button dispatcher).
  system,

  /// iOS edge swipe (Cupertino transition on an iOS target platform).
  swipe,
}

Future<void> _back(WidgetTester tester, GoRouter router, _Back how) async {
  switch (how) {
    case _Back.page:
      router.pop();
    case _Back.system:
      await tester.binding.handlePopRoute();
    case _Back.swipe:
      await tester.dragFrom(const Offset(2, 400), const Offset(340, 0));
  }
  await tester.pumpAndSettle();
}

/// [open] from the page [opener] shows: [target] opens on top of it as [location]'s twin (the
/// opener stays, covered), then Back ([how]) returns to the very same opener element, so its
/// state (scroll position, inputs) is kept.
Future<void> _opensOnOpener(
  WidgetTester tester,
  GoRouter router, {
  required Type opener,
  required Future<void> Function() open,
  required String location,
  required Finder target,
  _Back how = _Back.page,
  Future<void> Function()? inside,
}) async {
  final before = tester.element(find.byType(opener));
  await open();
  _onOpener(tester, router, location);
  expect(target, findsOneWidget);
  expect(find.byType(opener), findsNothing);
  expect(find.byType(opener, skipOffstage: false), findsOneWidget);
  await inside?.call();
  await _back(tester, router, how);
  expect(tester.takeException(), isNull);
  expect(target, findsNothing);
  expect(tester.element(find.byType(opener)), same(before));
  expect(_shells(router), 1);
}

/// A notification layer whose app launch came from [launch], and whose later taps go through
/// [tap].
class _Notifications extends FakeReminderNotifications {
  _Notifications({this.launch});
  final String? launch;
  void Function(String? payload)? tap;

  @override
  Future<void> init(void Function(String? payload) onTap) async => tap = onTap;

  @override
  Future<String?> launchPayload() async => launch;
}

/// A one-time reminder's notification: its payload and the location it opens.
({String payload, String location}) _reminderTap() {
  final r = mockReminders().first;
  return (
    payload: reminderPayload(r, DateTime.utc(2026, 10, 10, 1), r.title, ''),
    location: '${Routes.reminders}/${r.id}',
  );
}

void main() {
  group('the helper', () {
    // A plain push in this state is what froze (the Navigator's duplicate page keys); it is not
    // replayed here because the broken tree also breaks the tests after it.
    testWidgets(
      'tells tab pages, their twins and pages above the shell apart',
      (tester) async {
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
          '${Routes.spendingExpense}/e1',
        ]) {
          expect(router.isTabLocation(tab), isTrue, reason: tab);
          expect(router.overlayTwinOf(tab), OverlayTwin.of(tab), reason: tab);
          expect(
            router.isTabLocation(OverlayTwin.of(tab)),
            isFalse,
            reason: tab,
          );
        }
        // Tab roots have no twin: they open in the tabs, with the dock.
        for (final root in [
          Routes.today,
          Routes.memories,
          Routes.care,
          Routes.utilities,
        ]) {
          expect(router.isTabLocation(root), isTrue, reason: root);
          expect(router.overlayTwinOf(root), isNull, reason: root);
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
          expect(router.overlayTwinOf(above), isNull, reason: above);
        }
        expect(
          OverlayTwin.original('/o${Routes.reminders}/x'),
          '${Routes.reminders}/x',
        );
        expect(OverlayTwin.original(Routes.history), Routes.history);
        await _open(tester, router, Routes.growth);
        expect(router.aboveShell, isTrue);
        await _end(tester, container);
      },
    );

    testWidgets('tab pages from the tabs stay plain pushes; from above, on top', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      // Inside the shell: the Chăm sóc page stays under the next one.
      unawaited(router.pushSafe(Routes.history));
      await tester.pumpAndSettle();
      unawaited(router.pushSafe(Routes.growth));
      await tester.pumpAndSettle();
      expect(find.byType(GrowthScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(HistoryScreen), findsOneWidget);
      // From above the shell: Thống kê opens on Tăng trưởng, Back returns to it, then Lịch sử.
      unawaited(router.pushSafe(Routes.growth));
      await tester.pumpAndSettle();
      await _opensOnOpener(
        tester,
        router,
        opener: GrowthScreen,
        open: () async {
          unawaited(router.pushSafe(Routes.feedStats));
          await tester.pumpAndSettle();
        },
        location: Routes.feedStats,
        target: find.byType(FeedStatsScreen),
      );
      router.pop();
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(HistoryScreen), findsOneWidget);
      await _end(tester, container);
    });

    testWidgets('a tab root from above the shell still opens in the tabs', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, Routes.growth);
      unawaited(router.pushSafe(Routes.utilities));
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(GrowthScreen, skipOffstage: false), findsNothing);
      expect(find.byType(UtilitiesScreen), findsOneWidget);
      // A plain push of a tab root does the same (never a second shell).
      await _open(tester, router, Routes.growth);
      await _open(tester, router, Routes.care);
      _landedInTabs(tester, router);
      expect(find.byType(CareHubScreen), findsOneWidget);
      await _end(tester, container);
    });

    testWidgets(
      'plain pushes, replacements and links inside a twin stack on the opener',
      (tester) async {
        final (router, container) = await _app(tester, _base());
        await _open(tester, router, Routes.growth);
        final growth = tester.element(find.byType(GrowthScreen));
        // A screen that never heard of pushSafe (`context.push`).
        await _open(tester, router, Routes.history);
        _onOpener(tester, router, Routes.history);
        // A tab page from inside the twin: on top of it, not a second shell.
        await _open(tester, router, Routes.feedStats);
        _onOpener(tester, router, Routes.feedStats);
        expect(find.byType(FeedStatsScreen), findsOneWidget);
        // Replaced in place: still a twin, still on the opener.
        unawaited(router.pushReplacement(Routes.sleepStats));
        await tester.pumpAndSettle();
        _onOpener(tester, router, Routes.sleepStats);
        unawaited(router.replace<void>(Routes.feedStats));
        await tester.pumpAndSettle();
        _onOpener(tester, router, Routes.feedStats);
        await _back(tester, router, _Back.system);
        _onOpener(tester, router, Routes.history);
        expect(find.byType(HistoryScreen), findsOneWidget);
        await _back(tester, router, _Back.system);
        expect(tester.takeException(), isNull);
        expect(tester.element(find.byType(GrowthScreen)), same(growth));
        // Back from the opener: the tab it was opened from.
        await _back(tester, router, _Back.system);
        _landedInTabs(tester, router);
        expect(find.byType(CareHubScreen), findsOneWidget);
        await _end(tester, container);
      },
    );

    testWidgets('a pushed page waits for its twin and gets its result', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, Routes.growth);
      final result = router.push<String>(Routes.firstAidSaved);
      await tester.pumpAndSettle();
      _onOpener(tester, router, Routes.firstAidSaved);
      router.pop('done');
      await tester.pumpAndSettle();
      expect(await result, 'done');
      expect(find.byType(GrowthScreen), findsOneWidget);
      await _end(tester, container);
    });
  });

  group('notification taps', () {
    testWidgets('above the tabs: the reminder and the nudge open on top', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, Routes.growth);
      final id = mockReminders().first.id;
      // reminder_notifications: a one-time reminder, then a milestone nudge.
      await _opensOnOpener(
        tester,
        router,
        opener: GrowthScreen,
        open: () async {
          unawaited(router.pushSafe('${Routes.reminders}/$id'));
          await tester.pumpAndSettle();
        },
        location: '${Routes.reminders}/$id',
        target: find.byType(ReminderDetailScreen),
        how: _Back.system,
      );
      final nudge = '${Routes.milestoneCard}?occasion=${Occasion.m1.wire}';
      await _opensOnOpener(
        tester,
        router,
        opener: GrowthScreen,
        open: () async {
          unawaited(router.pushSafe(nudge));
          await tester.pumpAndSettle();
        },
        location: nudge,
        target: find.byType(MilestoneCardScreen),
      );
      await _end(tester, container);
    });

    testWidgets('a tap while the app runs above the tabs (the real handler)', (
      tester,
    ) async {
      final notifications = _Notifications();
      final (router, container) = await _app(
        tester,
        _base(notifications: notifications),
        wrap: (app) => ReminderNotificationSync(child: app),
      );
      await _open(tester, router, Routes.growth);
      final tap = _reminderTap();
      await _opensOnOpener(
        tester,
        router,
        opener: GrowthScreen,
        open: () async {
          notifications.tap!(tap.payload);
          await tester.pumpAndSettle();
        },
        location: tap.location,
        target: find.byType(ReminderDetailScreen),
        how: _Back.system,
      );
      await _end(tester, container);
    });

    testWidgets('a cold start from a reminder lands on it in the tabs', (
      tester,
    ) async {
      final (router, container) = await _app(
        tester,
        _base(notifications: _Notifications(launch: _reminderTap().payload)),
        tab: null,
        wrap: (app) => ReminderNotificationSync(child: app),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      _landedInTabs(tester, router);
      expect(find.byType(ReminderDetailScreen), findsOneWidget);
      // Back: the tab underneath.
      await _back(tester, router, _Back.system);
      _landedInTabs(tester, router);
      expect(find.byType(ReminderDetailScreen), findsNothing);
      await _end(tester, container);
    });
  });

  group('links from above the tabs', () {
    testWidgets(
      '28 Tăng trưởng "Xem tất cả" → Lịch sử (growth), iOS swipe back',
      (tester) async {
        final (router, container) = await _app(tester, _base());
        await _open(tester, router, Routes.growth);
        await _opensOnOpener(
          tester,
          router,
          opener: GrowthScreen,
          open: () => _tap(tester, find.text(l10n.growthSeeAll)),
          location: '${Routes.history}?filter=growth',
          target: find.byType(HistoryScreen),
          how: _Back.swipe,
          inside: () async => expect(
            tester.widget<HistoryScreen>(find.byType(HistoryScreen)).filter,
            HistoryFilter.growth,
          ),
        );
        await _end(tester, container);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('13l hồ sơ bé "Tăng trưởng" → Lịch sử (growth)', (
      tester,
    ) async {
      final (router, container) = await _app(tester, [
        ..._base(),
        ...meOverrides(),
      ]);
      await _open(tester, router, '${Routes.meBabies}/$teddyId');
      await _opensOnOpener(
        tester,
        router,
        opener: BabyProfileViewScreen,
        open: () => _tap(tester, find.text(l10n.bpGrowthHint)),
        location: '${Routes.history}?filter=growth',
        target: find.byType(HistoryScreen),
        how: _Back.system,
      );
      await _end(tester, container);
    });

    testWidgets('4d doctor callout → Sơ cứu, then a Sơ cứu page on top of it', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      await _open(tester, router, LbRoutes.articleOf('art_newborn_sleep'));
      // Read down to the callout: the article keeps that scroll position.
      final callout = find.byKey(const Key('lbOpenFirstAid'));
      await tester.ensureVisible(callout);
      await tester.pumpAndSettle();
      double read() => Scrollable.of(tester.element(callout)).position.pixels;
      final offset = read();
      expect(offset, greaterThan(0));
      await _opensOnOpener(
        tester,
        router,
        opener: ArticleScreen,
        open: () => _tap(tester, callout),
        location: Routes.firstAid,
        target: find.byType(FirstAidHomeScreen),
        // A link inside the twin (a plain `context.push`) stacks on it, Back returns to it.
        inside: () async {
          await _opensOnOpener(
            tester,
            router,
            opener: FirstAidHomeScreen,
            open: () => _tap(tester, find.byKey(const Key('faSavedList'))),
            location: Routes.firstAidSaved,
            target: find.byType(FirstAidSavedScreen),
            how: _Back.system,
          );
          _onOpener(tester, router, Routes.firstAid);
        },
      );
      expect(read(), offset);
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
      await _opensOnOpener(
        tester,
        router,
        opener: StageDetailScreen,
        open: () => _tap(tester, find.text(milestone.title.of('vi'))),
        location: '${Routes.milestones}/${milestone.id}',
        target: find.byType(MilestoneDetailScreen),
        how: _Back.system,
      );
      await _end(tester, container);
    });

    CardDraft blush() {
      final template = seedCatalog().cards.firstWhere(
        (t) => t.id == 'card_blush',
      );
      return CardDraft(
        babyId: teddyId,
        occasion: Occasion.m1,
        date: DateTime(2026, 10, 17),
        format: KeepsakeFormat.portrait,
        template: template,
        palette: template.palette,
        quote: 'Một tháng yêu thương',
        photos: const [],
      );
    }

    Future<void> resume(
      WidgetTester tester,
      GoRouter router,
      ProviderContainer container,
    ) async {
      final draft = blush();
      final key = container
          .read(resumeDraftsProvider)
          .keep(draft, cardDraftToJson(draft));
      final done = resumeAfterPurchase(
        router,
        container,
        PurchaseResume(
          kind: ResumeKind.card,
          templateId: draft.template.id,
          draftRef: key,
        ),
      );
      await tester.pumpAndSettle();
      await done;
      await tester.pumpAndSettle();
    }

    String editedTemplate(WidgetTester tester) => tester
        .widget<MilestoneCardEditScreen>(find.byType(MilestoneCardEditScreen))
        .draft
        .template
        .id;

    testWidgets('a purchase resumed onto a page above the tabs → MM11', (
      tester,
    ) async {
      final (router, container) = await _app(tester, _base());
      // The paywall has just closed onto Tăng trưởng (any page above the tabs, e.g. MS01).
      await _open(tester, router, Routes.growth);
      await _opensOnOpener(
        tester,
        router,
        opener: GrowthScreen,
        open: () => resume(tester, router, container),
        location: Routes.milestoneCardEdit,
        target: find.byType(MilestoneCardEditScreen),
        inside: () async => expect(editedTemplate(tester), 'card_blush'),
      );
      await _end(tester, container);
    });

    testWidgets(
      'a purchase resumed on a fresh start (Hôm nay) → MM11 in the tabs',
      (tester) async {
        final (router, container) = await _app(
          tester,
          _base(),
          tab: Routes.today,
        );
        await resume(tester, router, container);
        _landedInTabs(tester, router);
        expect(editedTemplate(tester), 'card_blush');
        await _back(tester, router, _Back.system);
        _landedInTabs(tester, router);
        expect(find.byType(TodayScreen), findsOneWidget);
        await _end(tester, container);
      },
    );

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
      await _opensOnOpener(
        tester,
        router,
        opener: WeekSummaryScreen,
        open: () => _tap(tester, find.byKey(const ValueKey('rh.weekVideo'))),
        location: Routes.memoryStory,
        target: find.byType(KeepsakeKindsScreen),
        how: _Back.system,
        inside: () async {
          final kinds = tester.widget<KeepsakeKindsScreen>(
            find.byType(KeepsakeKindsScreen),
          );
          expect(kinds.video, isTrue);
          expect(kinds.photoIds, isNotEmpty);
        },
      );
      await _end(tester, container);
    });

    testWidgets('Trợ lý: a saved feed "Mở nhật ký" → Lịch sử, back to the chat', (
      tester,
    ) async {
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
      // Something the parent was typing: the chat keeps it (the same chat, not a new one).
      const typing = 'Bé vừa bú 90 ml';
      await tester.enterText(
        find.descendant(
          of: find.byType(AssistantChatScreen),
          matching: find.byType(TextField),
        ),
        typing,
      );
      await tester.pumpAndSettle();
      final link = find.text(l10n.asOpenLog).first;
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await _opensOnOpener(
        tester,
        router,
        opener: AssistantChatScreen,
        open: () async {
          await tester.tap(link);
          await tester.pumpAndSettle();
        },
        location: Routes.history,
        target: find.byType(HistoryScreen),
        how: _Back.system,
        // A further tab page from the log stacks too, and Back returns to the log.
        inside: () async {
          await _opensOnOpener(
            tester,
            router,
            opener: HistoryScreen,
            open: () => _open(tester, router, Routes.feedStats),
            location: Routes.feedStats,
            target: find.byType(FeedStatsScreen),
          );
        },
      );
      expect(find.text(typing), findsOneWidget);
      // Back from the chat: the tab it was opened from.
      await _back(tester, router, _Back.system);
      _landedInTabs(tester, router);
      expect(find.byType(CareHubScreen), findsOneWidget);
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
