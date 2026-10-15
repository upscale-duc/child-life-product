@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/billing_repository.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/plan_screen.dart';
import 'package:child_life/features/premium/premium_gate.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/premium/premium_widgets.dart';
import 'package:child_life/features/premium/purchase_resume.dart';
import 'package:child_life/features/premium/purchase_sheets.dart';
import 'package:child_life/features/premium/store_gateway.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/premium_test.dart' show answer;
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/premium_fixtures.dart';

/// Premium & Cá nhân hoá (plan §7 E4 / Q1, Slice 4 B4 / Q2): PR01 entry A and B, PR02's four
/// states, MO02, MO03, MO04, PR03 and PR04 in Light / Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

List<Override> _caps(
  Map<String, Object?> json, {
  bool owner = true,
  StoreGateway? store,
}) => [
  selectedMembershipProvider.overrideWithValue(owner ? mai : minh),
  ...premiumOverrides(
    household: FakeHousehold(json),
    store: store,
    billing: FakeBilling(),
  ),
];

/// "open" on a blank page runs [show] (sheets).
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

KeepsakeTemplate get _blush =>
    seedCatalog().cards.firstWhere((t) => t.id == 'card_blush');

_Case _sheet(PurchaseSheetKind kind) => (
  build: () => _opener(
    (context) => showPurchaseSheet(
      context,
      kind,
      entry: PaywallEntry.templates,
      resume: const PurchaseResume(
        kind: ResumeKind.card,
        templateId: 'card_blush',
        draftRef: 'd1',
      ),
      templateName: _blush.name.of(Localizations.localeOf(context)),
    ),
  ),
  overrides: const [],
  prefs: const {},
  act: _open,
);

/// MO03 opens the editor as the template just resumed.
class _Resumed extends JustResumed {
  @override
  String? build() => 'card_blush';
}

final _journal = mockJournal();
List<String> _photoIds() => [
  for (final m in _journal.media)
    if (!m.isVideo) m.id,
];

/// 2 used, 1 reserved of 5; resets on 1 Nov (local midnight: the same date on every machine).
final _quotaReset = VideoQuota(
  limit: 5,
  used: 2,
  reserved: 1,
  resetsAt: DateTime(2026, 11, 1),
);

List<Override> _video({KeepsakeJob? job}) => [
  ...careOverrides(),
  minuteClockProvider.overrideWith(
    (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
  ),
  providerDisplayNameProvider.overrideWithValue(null),
  ...memoryOverrides(
    keepsakes: (cards: true, videos: true),
    keepsakeCatalog: seedCatalog(),
    journal: (memories: _journal.memories, media: _journal.media),
  ),
  keepsakeAssetImageProvider.overrideWithValue(
    (asset) => const StorageImage('keepsake/peach'),
  ),
  keepsakeJobRepositoryProvider.overrideWithValue(
    FakeKeepsakeJobs()..put(job ?? videoJob()),
  ),
  videoQuotaProvider.overrideWith((ref, babyId) async => _quotaReset),
  capabilitiesProvider.overrideWith(
    (ref, babyId) async =>
        Capabilities.fromJson(answer(plan: 'premium', templates: true)),
  ),
];

final _cases = <String, _Case>{
  // PR03 593:6931, free household, the owner's view.
  'pr03_free_owner': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(answer()),
    prefs: const {},
    act: null,
  ),
  // PR03, Premium bought by the owner; Ba sees "Hộ đã có Premium" (D-072 #1).
  'pr03_premium_member': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(
      answer(
        plan: 'premium',
        templates: true,
        owner: false,
        validUntil: '2026-11-14T00:00:00.000Z',
        autoRenew: true,
      ),
      owner: false,
    ),
    prefs: const {},
    act: null,
  ),
  // PR03, the owner of a paid plan bought in the App Store: manage there (and restore once the
  // store is open).
  'pr03_premium_owner': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(
      answer(
        plan: 'premium',
        templates: true,
        provider: 'apple',
        validUntil: '2026-11-14T00:00:00.000Z',
        autoRenew: true,
      ),
      store: FakeStore(),
    ),
    prefs: const {},
    act: null,
  ),
  // PR03, beta of group A until a date.
  'pr03_beta': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(
      answer(plan: 'beta', validUntil: '2026-12-01T00:00:00.000Z'),
    ),
    prefs: const {},
    act: null,
  ),
  // PR04 593:6990 on the plan: ended, history kept, renewal for the owner.
  'pr04_expired_owner': (
    build: () => const HouseholdPlanScreen(),
    overrides: _caps(
      answer(plan: 'expired', validUntil: '2026-10-14T00:00:00.000Z'),
    ),
    prefs: const {},
    act: null,
  ),
  // PR01 entry A (Nhịp lớn lên) as the app ships now (D-074): no store, nothing to buy.
  'pr01_rhythm_closed': (
    build: () => const PaywallScreen(entry: PaywallEntry.rhythm),
    overrides: _caps(answer()),
    prefs: const {},
    act: null,
  ),
  // PR01 entry B (592:6826) with a store open: storefront prices, yearly preselected.
  'pr01_templates_buy': (
    build: () => const PaywallScreen(entry: PaywallEntry.templates),
    overrides: _caps(answer(billing: true), store: FakeStore()),
    prefs: const {},
    act: (tester) async {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
    },
  ),
  // PR01 for a member who is not the owner.
  'pr01_member_ask': (
    build: () => const PaywallScreen(entry: PaywallEntry.templates),
    overrides: _caps(answer(owner: false, billing: true), owner: false),
    prefs: const {},
    act: (tester) async {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
    },
  ),
  // PR02 Mua/Trạng thái 592:6781.
  'pr02_pending': _sheet(PurchaseSheetKind.pending),
  'pr02_success': _sheet(PurchaseSheetKind.success),
  'pr02_error': _sheet(PurchaseSheetKind.storeError),
  'pr02_restore': _sheet(PurchaseSheetKind.restoreConfirm),
  'pr02_restore_bound': _sheet(PurchaseSheetKind.alreadyBound),
  // MO02 592:6782 for a beta family: the beta does not include Premium templates.
  'mo02_beta': (
    build: () => Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Center(
          child: TextButton(
            onPressed: () => ensureTemplateAllowed(
              context,
              ref,
              template: _blush,
              catalog: const KeepsakeCatalog(
                [],
                premiumAccess: PremiumAccess.subscribers,
              ),
              babyId: teddyId,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    overrides: _caps(answer(plan: 'beta')),
    prefs: const {},
    act: _open,
  ),
  // MO03 593:6797: back on the same template and photo after the purchase.
  'mo03_card_resumed': (
    build: () => MilestoneCardEditScreen(
      draft: CardDraft(
        babyId: teddyId,
        occasion: Occasion.m1,
        date: DateTime(2026, 10, 17),
        format: KeepsakeFormat.portrait,
        template: _blush,
        palette: _blush.palette,
        quote: 'Một tháng yêu thương',
        photos: const [CardPhoto(StorageImage('photo/mint'))],
      ),
    ),
    overrides: [..._video(), justResumedProvider.overrideWith(_Resumed.new)],
    prefs: const {},
    act: null,
  ),
  // MO04 593:6843: the quota on MM07 before "Tạo video".
  'mo04_finish_quota': (
    build: () => MemoryStoryFinishScreen(
      draft: VideoDraft(
        babyId: teddyId,
        template: seedCatalog().videos.first,
        occasion: Occasion.m1,
        mediaIds: _photoIds().take(6).toList(),
      ),
    ),
    overrides: _video(),
    prefs: const {},
    act: (tester) async {
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
    },
  ),
  // MO04: a failed export gave its reservation back.
  'mo04_failed_released': (
    build: () => MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
    overrides: _video(
      job: videoJob(
        status: KeepsakeJobStatus.failed,
        error: 'render-failed',
        mediaIds: _photoIds().take(6).toList(),
      ),
    ),
    prefs: const {},
    act: null,
  ),
  // MO04 "Khi hết lượt" for a free family whose Premium budget is larger.
  'mo04_quota_sheet': (
    build: () => _opener(
      (context) => showVideoQuotaSheet(
        context,
        quota: VideoQuota(
          limit: 1,
          used: 1,
          reserved: 0,
          resetsAt: DateTime(2026, 11, 1),
          premiumLimit: 5,
        ),
        caps: Capabilities.fromJson(answer()),
      ),
    ),
    overrides: const [],
    prefs: const {},
    act: _open,
  ),
};

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues(c.prefs);
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
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
          // Media bytes decode outside the fake clock: let every visible image finish first.
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
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/pm/${name}_${palette.name}_${locale.languageCode}.png',
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
