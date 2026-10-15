import 'dart:async';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/app/route_guard.dart';
import 'package:child_life/app/router.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/rhythm/milestone_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/keepsake_fixtures.dart';
import '../../helpers/memory_fixtures.dart';
import '../../helpers/rhythm_fixtures.dart';

/// D-076 #14 on the app's real router: Con có điều mới → "Lưu vào Mốc" (MS01) → a Thiệp cột mốc
/// tile. Before the fix, MS01 (a page above the tab shell) pushed `/memories/card` over itself and
/// the Navigator asserted (`!keyReservation.contains(key)`): neither tile went anywhere. Now each
/// tile lands in the card editor (MM11) with the milestone preselected, for Cơ bản and Cao cấp; a
/// family without `templates.premium` gets MO02 and is never stuck.
final l10n = lookupAppLocalizations(const Locale('vi'));

Map<String, Object?> caps({required bool templates, String plan = 'beta'}) => {
  'familyId': 'f_1',
  'plan': plan,
  'canManageBilling': true,
  'country': 'VN',
  'capabilities': {
    'rhythm.checkin': {'allowed': true, 'reason': null},
    'health.guidance': {'allowed': true, 'reason': null},
    'templates.premium': {
      'allowed': templates,
      'reason': templates ? null : 'PREMIUM_REQUIRED',
      'via': templates ? 'beta' : null,
    },
  },
  'features': {
    'rhythm': true,
    'personalization': true,
    'aiAssist': false,
    'billing': false,
  },
};

Future<(GoRouter, ProviderContainer, FakeMemoryRepository)> _pump(
  WidgetTester tester, {
  required Map<String, Object?> capabilities,
  PremiumAccess access = PremiumAccess.subscribers,
  String note = 'Lần đầu lẫy',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final memories = FakeMemoryRepository();
  final seed = seedCatalog();
  final List<Override> overrides = [
    // The rhythm fixtures' own Kỷ niệm fake is replaced by the one below.
    ...rhythmOverrides(
      repo: FakeRhythmRepository(),
      caps: capabilities,
    ).where((o) => !o.toString().contains('MemoryRepository')),
    ...memoryOverrides(
      repo: memories,
      keepsakes: (cards: true, videos: false),
      keepsakeCatalog: KeepsakeCatalog(seed.templates, premiumAccess: access),
    ),
    keepsakeAssetImageProvider.overrideWithValue(
      (asset) => const StorageImage('keepsake/peach'),
    ),
    sharedPreferencesProvider.overrideWithValue(prefs),
    environmentProvider.overrideWithValue(AppEnvironment.dev),
  ];
  final container = ProviderContainer(overrides: overrides);
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
  router.go(Routes.today);
  await tester.pumpAndSettle();
  // C02 "Con có điều mới" → "Lưu vào Mốc" pushes MS01 with what the parent wrote.
  unawaited(router.push(Routes.rhythmMilestone, extra: note));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.rhSaveToMilestones));
  await tester.pumpAndSettle();
  expect(memories.milestones, [note]);
  expect(find.text(l10n.rhMsKeepTitle), findsOneWidget);
  return (router, container, memories);
}

Future<void> _end(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pump(const Duration(minutes: 1));
}

CardDraft _editorDraft(WidgetTester tester) => tester
    .widget<MilestoneCardEditScreen>(find.byType(MilestoneCardEditScreen))
    .draft;

void main() {
  testWidgets('Thẻ mốc cơ bản → the editor with the milestone preselected', (
    tester,
  ) async {
    final (_, container, _) = await _pump(
      tester,
      capabilities: caps(templates: false, plan: 'free'),
    );
    await tester.tap(find.text(l10n.rhMsBasic));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(RhythmMilestoneScreen), findsNothing);
    expect(find.byType(MilestoneCardEditScreen), findsOneWidget);
    final draft = _editorDraft(tester);
    expect(draft.template.premium, isFalse);
    expect(draft.occasion, Occasion.rollsOver);
    expect(draft.milestone?.id, 'ms_${'9' * 32}');
    expect(draft.milestone?.name, 'Lần đầu lẫy');
    expect(draft.date, draft.milestone?.date);
    // The saved card is tagged with the family's milestone, not the preset.
    final req = cardMemoryRequest(
      draft: draft,
      today: DateTime(2026, 10, 8),
      milestoneName: 'x',
    );
    expect((req['milestone']! as Map)['id'], 'ms_${'9' * 32}');
    expect((req['generated']! as Map)['occasion'], 'rolls_over');
    await _end(tester, container);
  });

  testWidgets('a milestone no occasion fits: the card says its own name', (
    tester,
  ) async {
    final (_, container, _) = await _pump(
      tester,
      capabilities: caps(templates: false, plan: 'free'),
      note: 'Lần đầu về quê',
    );
    await tester.tap(find.text(l10n.rhMsBasic));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final draft = _editorDraft(tester);
    expect(draft.ownTitle, isTrue);
    expect(draft.quote, l10n.ksAchieveAny);
    final req = cardMemoryRequest(
      draft: draft,
      today: DateTime(2026, 10, 8),
      milestoneName: 'x',
    );
    expect((req['milestone']! as Map)['name'], 'Lần đầu về quê');
    expect((req['generated']! as Map)['occasion'], isNull);
    await _end(tester, container);
  });

  testWidgets('Thẻ mốc Premium in a beta with templates.premium → the editor', (
    tester,
  ) async {
    final (_, container, _) = await _pump(
      tester,
      capabilities: caps(templates: true),
    );
    await tester.tap(find.text(l10n.rhMsPremium));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.pmUnlockPremium), findsNothing);
    expect(find.byType(MilestoneCardEditScreen), findsOneWidget);
    final draft = _editorDraft(tester);
    expect(draft.template.premium, isTrue);
    expect(draft.milestone?.name, 'Lần đầu lẫy');
    await _end(tester, container);
  });

  testWidgets(
    'Premium without templates.premium: MO02, then Cơ bản still works',
    (tester) async {
      final (_, container, _) = await _pump(
        tester,
        capabilities: caps(templates: false, plan: 'free'),
      );
      await tester.tap(find.text(l10n.rhMsPremium));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The honest gate (MO02), never a dead end.
      expect(find.text(l10n.pmUnlockPremium), findsOneWidget);
      await tester.tap(find.text(l10n.pmUseFreeTemplate));
      await tester.pumpAndSettle();
      expect(find.byType(MilestoneCardEditScreen), findsNothing);
      expect(find.byType(RhythmMilestoneScreen), findsOneWidget);
      await tester.tap(find.text(l10n.rhMsBasic));
      await tester.pumpAndSettle();
      expect(find.byType(MilestoneCardEditScreen), findsOneWidget);
      expect(_editorDraft(tester).template.premium, isFalse);
      await _end(tester, container);
    },
  );

  testWidgets('everyone mode (free beta): Premium opens straight away', (
    tester,
  ) async {
    final (_, container, _) = await _pump(
      tester,
      capabilities: caps(templates: false, plan: 'free'),
      access: PremiumAccess.everyone,
    );
    await tester.tap(find.text(l10n.rhMsPremium));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_editorDraft(tester).template.premium, isTrue);
    await _end(tester, container);
  });

  testWidgets(
    'hidden Cao cấp: that tile, like "Tạo thẻ mốc", opens the library',
    (tester) async {
      final (router, container, _) = await _pump(
        tester,
        capabilities: caps(templates: false, plan: 'free'),
        access: PremiumAccess.hidden,
      );
      await tester.tap(find.text(l10n.rhMsPremium));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MilestoneCardScreen), findsOneWidget);
      // Back from the library is Hôm nay, not the finished check-in flow.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(MilestoneCardScreen), findsNothing);
      expect(find.byType(RhythmMilestoneScreen), findsNothing);
      await _end(tester, container);
    },
  );
}
