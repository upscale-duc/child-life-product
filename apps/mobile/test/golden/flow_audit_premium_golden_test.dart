@Tags(['golden'])
library;

import 'dart:async';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/storage_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/billing_repository.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:child_life/features/premium/store_gateway.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/premium_fixtures.dart';
import '../features/premium_test.dart' show answer;
import '../helpers/premium_v2_fixtures.dart';

/// The 2026-10-26 flow audit's Premium and storage states (D-127): an unknown limit, reserved
/// space, full with the plan unknown, full for a member who is not the manager, the paywall
/// while the plan loads or cannot be read, and prices that are not known. Light / Night care
/// × vi / en at 375 × 812. Regenerate on macOS: flutter test --tags golden --update-goldens.

const _gb = 1024 * 1024 * 1024;

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
});

FamilyStorage _storage({
  int? quota = 10 * _gb,
  double teddyGb = 2.4,
  int reserved = 0,
  int reservedItems = 0,
}) {
  final s = mockStorage(teddyGb: teddyGb);
  return FamilyStorage(
    familyId: s.familyId,
    isOwner: s.isOwner,
    quotaBytes: quota,
    usedBytes: s.usedBytes,
    reservedBytes: reserved,
    reservedItems: reservedItems,
    binBytes: s.binBytes,
    notesBytes: s.notesBytes,
    babies: s.babies,
    largestVideos: s.largestVideos,
  );
}

/// Dung lượng, with or without Premium v2; [plan] null means the plan could not be read.
List<Override> _storageCase(
  FamilyStorage storage, {
  bool v2 = false,
  FamilyPlanV2? plan,
  bool premium = false,
  bool owner = true,
}) => [
  ...familyOverrides(
    me: owner ? mai : minh,
    now: DateTime(2026, 10, 8, 10),
    email: 'mai@gmail.com',
    providers: const ['password'],
  ),
  ...memoryOverrides(),
  ...meOverrides(storage: storage),
  ...premiumOverrides(
    household: FakeHousehold(
      v2
          ? v2Answer(plan: premium ? 'premium' : 'free', owner: owner)
          : answer(owner: owner),
    ),
  ),
  premiumV2ApiProvider.overrideWithValue(FakePremiumV2Api(plan)),
  familyPlanV2Provider.overrideWith((ref, id) async => plan),
];

/// The paywall while `getCapabilities` is [caps].
List<Override> _paywallCase(Future<Capabilities?> Function() caps) => [
  selectedMembershipProvider.overrideWithValue(mai),
  babyProvider.overrideWith((ref, id) => Stream.value(teddy)),
  familyMembersProvider.overrideWith(
    (ref, id) => Stream.value([mai, minh, lan, hoa]),
  ),
  capabilitiesProvider.overrideWith((ref, id) => caps()),
  storeGatewayProvider.overrideWithValue(const UnavailableStoreGateway()),
  billingApiProvider.overrideWithValue(FakeBilling()),
  premiumV2ApiProvider.overrideWithValue(FakePremiumV2Api(freePlan)),
  familyPlanV2Provider.overrideWith((ref, id) async => freePlan),
];

/// Premium with the storage full (10 GB used + 0,4 GB reserved over a 10 GB limit).
final _premiumFull = FamilyPlanV2(
  v2: true,
  premium: true,
  isManager: false,
  lumi: premiumPlan.lumi,
  video: premiumPlan.video,
  usedBytes: (9.8 * _gb).round(),
  reservedBytes: (0.4 * _gb).round(),
  limitBytes: 10 * _gb,
  seatsUsed: 3,
  seatsLimit: 6,
  addOns: freePlan.addOns,
);

/// A Free plan whose prices are not configured (P-3).
final _noPrice = FamilyPlanV2(
  v2: true,
  premium: false,
  isManager: true,
  lumi: freePlan.lumi,
  video: freePlan.video,
  usedBytes: freePlan.usedBytes,
  limitBytes: freePlan.limitBytes,
  seatsUsed: freePlan.seatsUsed,
  seatsLimit: freePlan.seatsLimit,
  priceVn: null,
  priceIntl: null,
);

final _cases = <String, _Case>{
  // ST-1: the limit was not read: what is used, and a retry; never "full" or "0 B".
  'storage_unknown': (
    build: () => const StorageScreen(),
    overrides: () => _storageCase(_storage(quota: null)),
  ),
  // D-127 Q2: reserved space has its own line and counts towards "Sắp đầy".
  'storage_reserved': (
    build: () => const StorageScreen(),
    overrides: () => _storageCase(
      _storage(teddyGb: 7.2, reserved: (0.6 * _gb).round(), reservedItems: 3),
    ),
  ),
  // ST-3: v2, full, the plan cannot be read: a retry and "Xoá bớt video lớn".
  'storage_v2_full_plan_unknown': (
    build: () => const StorageScreen(),
    overrides: () => _storageCase(_storage(teddyGb: 9.4), v2: true),
  ),
  // ST-4 / D-127 Q7: Premium, full, a Cùng nuôi who is not the manager asks the manager.
  'storage_v2_member_full': (
    build: () => const StorageScreen(),
    overrides: () => _storageCase(
      _storage(teddyGb: 9.4, reserved: (0.4 * _gb).round(), reservedItems: 2),
      v2: true,
      plan: _premiumFull,
      premium: true,
      owner: false,
    ),
  ),
  // P-1: the plan is loading: a neutral skeleton, neither the light nor the dark paywall.
  'paywall_loading': (
    build: () => const PaywallScreen(entry: PaywallEntry.plan),
    overrides: () => _paywallCase(() => Completer<Capabilities?>().future),
  ),
  // P-1: no answer and nothing kept: say so, with a retry.
  'paywall_unknown': (
    build: () => const PaywallScreen(entry: PaywallEntry.plan),
    overrides: () => _paywallCase(() async => null),
  ),
  // P-3: no configured price: no "0đ", the CTA waits.
  'paywall_price_unknown': (
    build: () => const PaywallScreen(
      entry: PaywallEntry.plan,
      v2Entry: PremiumEntry.explore,
    ),
    overrides: () => premiumV2Overrides(plan: _noPrice),
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          mediaBytes = FakeMediaBytes();
          SharedPreferences.setMockInitialValues(const {});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
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
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
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
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          if (!name.endsWith('loading')) await tester.pumpAndSettle();
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/flow_audit/${name}_${palette.name}_${locale.languageCode}.png',
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
