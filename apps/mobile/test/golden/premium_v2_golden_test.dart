@Tags(['golden'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/keepsakes/video_quality_selector.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/family_plan_v2.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/paywall_v2.dart';
import 'package:child_life/features/premium/plan_screen.dart';
import 'package:child_life/features/premium/premium_entries.dart';
import 'package:child_life/features/premium/premium_style.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/premium_v2_fixtures.dart';

/// Premium v2 (Figma 958:13863, D-101): paywall by entry (PW01 / PW03 / PW05 / PW06 / PW07),
/// the suggestion sheet and inline cards (E01, E12, E13), Gói của gia đình (PV40, PV40B, PV43,
/// PV45), PV41, PV42, PV44 and PW10, in Light / Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/premium_v2_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> overrides,
  Future<void> Function(WidgetTester tester)? act,
});

Widget _opener(void Function(BuildContext context) show) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => show(context),
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

_Case _paywall(PremiumEntry entry, {bool owner = true, String? subject}) => (
  build: () =>
      PaywallScreen(entry: PaywallEntry.plan, v2Entry: entry, subject: subject),
  overrides: premiumV2Overrides(
    plan: owner ? freePlan : asMember(freePlan),
    caps: v2Answer(owner: owner),
    me: owner ? mai : minh,
  ),
  act: null,
);

_Case _plan(
  FamilyPlanV2 plan, {
  Map<String, Object?>? caps,
  bool owner = true,
}) => (
  build: () => const HouseholdPlanScreen(),
  overrides: premiumV2Overrides(
    plan: owner ? plan : asMember(plan),
    caps:
        caps ?? v2Answer(plan: plan.premium ? 'premium' : 'free', owner: owner),
    me: owner ? mai : minh,
  ),
  act: null,
);

/// Component · Premium · Thẻ tính năng (1019:17008), three at a time at their own 300 width.
_Case _cards(List<PremiumCard> cards) => (
  build: () => Scaffold(
    backgroundColor: PremiumPalette.deep,
    body: FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in cards) ...[
            PremiumFeatureCard(
              card: c,
              free: PlanOffer.free,
              premium: PlanOffer.premium,
              babyName: 'Teddy',
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  ),
  overrides: premiumV2Overrides(plan: freePlan),
  act: null,
);

_Case _detail(PremiumEntry entry) => (
  build: () => PaywallScreen(entry: PaywallEntry.plan, v2Entry: entry),
  overrides: premiumV2Overrides(plan: freePlan),
  act: (tester) async {
    final l = AppLocalizations.of(tester.element(find.byType(PaywallV2View)));
    final index = switch (entry) {
      PremiumEntry.video || PremiumEntry.card || PremiumEntry.explore => 0,
      PremiumEntry.lumi => 1,
      PremiumEntry.rhythm => 2,
      PremiumEntry.storage => 3,
      PremiumEntry.caregivers => 4,
    };
    // Follow the Figma pager prototype, keeping the same underlying plan position.
    final first = find.text(l.premiumMemories).hitTestable();
    if (first.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.tap(first);
    await tester.pumpAndSettle();
    final next = MaterialLocalizations.of(
      tester.element(find.byType(PaywallV2View)),
    ).nextPageTooltip;
    for (var i = 0; i < index; i++) {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is ClPressable && widget.semanticLabel == next,
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('/5 · '), findsOneWidget);
  },
);
_Case _quality(bool premium) => (
  build: () => Scaffold(
    body: VideoQualitySelector(
      babyId: teddyId,
      selection: null,
      onChanged: (_) {},
    ),
  ),
  overrides: premiumV2Overrides(plan: premium ? premiumPlan : freePlan),
  act: (tester) async {
    final l = AppLocalizations.of(
      tester.element(find.byType(VideoQualitySelector)),
    );
    await tester.tap(find.text(l.videoQuality));
    await tester.pumpAndSettle();
  },
);

_Case _planChoice({bool monthly = false, bool details = false}) => (
  build: () => const PaywallScreen(
    entry: PaywallEntry.plan,
    v2Entry: PremiumEntry.explore,
  ),
  overrides: premiumV2Overrides(plan: freePlan),
  act: (tester) async {
    final l = AppLocalizations.of(tester.element(find.byType(PaywallV2View)));
    if (monthly) {
      await tester.tap(find.text(l.pv2PeriodMonth));
      await tester.pumpAndSettle();
    }
    if (details) {
      await tester.tap(find.text(l.premiumTodayTotal));
      await tester.pumpAndSettle();
    }
  },
);

final _cases = <String, _Case>{
  'pw_monthly': _planChoice(monthly: true),
  'payment_details': _planChoice(details: true),
  'detail_memories': _detail(PremiumEntry.video),
  'detail_lumi': _detail(PremiumEntry.lumi),
  'detail_rhythm': _detail(PremiumEntry.rhythm),
  'detail_storage': _detail(PremiumEntry.storage),
  'detail_seats': _detail(PremiumEntry.caregivers),
  'quality_free': _quality(false),
  'quality_premium': _quality(true),
  'pw_large': _paywall(PremiumEntry.explore),
  'detail_large': _detail(PremiumEntry.video),
  'pw01_video': _paywall(PremiumEntry.video, subject: '100 ngày yêu thương'),
  'pw02_card': _paywall(PremiumEntry.card, subject: 'Hồng phấn'),
  'pw03_lumi': _paywall(PremiumEntry.lumi),
  'pw05_caregivers': _paywall(PremiumEntry.caregivers),
  'pw_rhythm': _paywall(PremiumEntry.rhythm),
  'pw06_explore': _paywall(PremiumEntry.explore),
  'pw07_member': _paywall(PremiumEntry.video, owner: false),
  'e01_sheet': (
    build: () => _opener(
      (context) => showPremiumSuggestion(
        context,
        title: AppLocalizations.of(context).pv2E01Title('100 ngày yêu thương'),
        body: AppLocalizations.of(context).pv2E01Body(4),
        secondary: AppLocalizations.of(context).pv2E01Secondary,
      ),
    ),
    overrides: premiumV2Overrides(plan: freePlan),
    act: _open,
  ),
  'e12_sheet': (
    build: () => Consumer(
      builder: (context, ref, _) =>
          _opener((context) => showSeatsFullSuggestion(context, ref, teddyId)),
    ),
    overrides: premiumV2Overrides(plan: freePlan),
    act: _open,
  ),
  'e13_inline': (
    build: () => const Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 80, 16, 0),
        child: Column(
          children: [
            MePremiumInline(babyId: teddyId),
            StoragePremiumInline(babyId: teddyId),
          ],
        ),
      ),
    ),
    overrides: premiumV2Overrides(plan: freePlan),
    act: null,
  ),
  'pv40_premium': _plan(
    premiumPlan,
    caps: v2Answer(
      plan: 'premium',
      provider: 'apple',
      validUntil: '2027-10-24T03:00:00.000Z',
    ),
  ),
  'pv40b_free': _plan(freePlan),
  'pv43_downgraded': _plan(
    downgradedPlan,
    caps: v2Answer(plan: 'expired', validUntil: '2026-10-24T03:00:00.000Z'),
  ),
  'pv45_member': _plan(premiumPlan, owner: false),
  'pv41_history': (
    build: () => const UsageHistoryScreen(),
    overrides: premiumV2Overrides(plan: premiumPlan),
    act: null,
  ),
  'pv42_cancel': (
    build: () => const CancelRenewalScreen(),
    overrides: premiumV2Overrides(
      plan: FamilyPlanV2(
        v2: true,
        premium: true,
        isManager: true,
        lumi: premiumPlan.lumi,
        video: premiumPlan.video,
        usedBytes: premiumPlan.usedBytes,
        limitBytes: premiumPlan.limitBytes,
        seatsUsed: 5,
        seatsLimit: 6,
        validUntil: premiumPlan.validUntil,
      ),
      caps: v2Answer(plan: 'premium', provider: 'apple'),
    ),
    act: null,
  ),
  'pv44_picker': (
    build: () => _opener(
      (context) =>
          showSeatPicker(context, babyId: teddyId, plan: downgradedPlan),
    ),
    overrides: [
      ...premiumV2Overrides(plan: downgradedPlan),
      familyWritersProvider.overrideWith(
        (ref, id) => [
          mai,
          minh,
          lan,
          member(
            'u_ong',
            'Ông nội',
            MemberRole.caregiver,
            Relation.grandfather,
          ),
          member('u_ba', 'Bà nội', MemberRole.caregiver, Relation.grandmother),
        ],
      ),
    ],
    act: _open,
  ),
  'cards_a': _cards(const [
    PremiumCard.video,
    PremiumCard.card,
    PremiumCard.lumi,
  ]),
  'cards_b': _cards(const [
    PremiumCard.rhythm,
    PremiumCard.storage,
    PremiumCard.caregivers,
  ]),
  'pw10_addon': (
    build: () => const StorageAddOnScreen(),
    overrides: premiumV2Overrides(plan: premiumPlan),
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
          SharedPreferences.setMockInitialValues(const {});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          // Enable before constructing painters; toggling after pump leaves cached flat shadows.
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = true);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...c.overrides,
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
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          name.endsWith('large') ? 2 : 1,
                        ),
                      ),
                      child: child!,
                    ),
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
          // Demo photos decode outside the fake clock.
          for (var round = 0; round < 2; round++) {
            final images = tester
                .widgetList<Image>(find.byType(Image))
                .toList();
            await tester.runAsync(() async {
              for (final image in images) {
                await precacheImage(
                  image.image,
                  tester.element(find.byWidget(image).first),
                );
              }
            });
            await tester.pumpAndSettle();
          }
          debugDisableShadows = false;
          try {
            await tester.pump();
            // Optional retina evidence for direct comparison with Figma. Baselines stay 1x.
            const captureDirectory = String.fromEnvironment(
              'PREMIUM_CAPTURE_DIRECTORY',
            );
            if (captureDirectory.isNotEmpty) {
              await tester.runAsync(() async {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('golden')),
                );
                final image = await boundary.toImage(pixelRatio: 3);
                try {
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final file = File(
                    '$captureDirectory/${name}_${palette.name}_${locale.languageCode}.png',
                  );
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes!.buffer.asUint8List());
                } finally {
                  image.dispose();
                }
              });
            }
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/pv2/${name}_${palette.name}_${locale.languageCode}.png',
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
