import 'dart:async';
import 'dart:convert';

import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/paywall_price_cache.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/paywall_v2.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/premium_v2_fixtures.dart';
import '../helpers/router_pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 28, 10);
  const price = PlanPrice(month: 59000, year: 599000);

  test(
    'valid cached prices survive recreation; account, baby and currency stay separate',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await PaywallPriceCache(
        prefs,
        now: () => now,
      ).write(mai.uid, teddyId, true, price);
      final cache = PaywallPriceCache(prefs, now: () => now);
      expect(cache.read(mai.uid, teddyId, true)?.month, 59000);
      expect(cache.read(minh.uid, teddyId, true), isNull);
      expect(cache.read(mai.uid, 'other-baby', true), isNull);
      expect(cache.read(mai.uid, teddyId, false), isNull);
      expect(
        PaywallPriceCache(
          prefs,
          now: () => now.add(const Duration(days: 1)),
        ).read(mai.uid, teddyId, true),
        isNull,
      );
      expect(
        PaywallPriceCache(
          prefs,
          now: () => now.subtract(const Duration(seconds: 1)),
        ).read(mai.uid, teddyId, true),
        isNull,
      );
      await cache.write(mai.uid, teddyId, true, null);
      expect(cache.read(mai.uid, teddyId, true), isNull);
    },
  );
  test(
    'corrupt or non-positive cached prices never appear as a purchasable amount',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = PaywallPriceCache(prefs, now: () => now);
      final key = PaywallPriceCache.key(mai.uid, teddyId, true);
      for (final raw in [
        'broken',
        '{}',
        jsonEncode({
          'at': now.millisecondsSinceEpoch,
          'month': 0,
          'year': 599000,
        }),
      ]) {
        await prefs.setString(key, raw);
        expect(cache.read(mai.uid, teddyId, true), isNull);
      }
    },
  );

  testWidgets(
    'first opening waits for prices before showing any plan choices',
    (tester) async {
      final pending = Completer<FamilyPlanV2?>();
      await pumpRouted(
        tester,
        const PaywallScreen(entry: PaywallEntry.plan),
        overrides: [
          ...premiumV2Overrides(plan: null, loadPlan: () => pending.future),
        ],
      );
      expect(find.text('Đang tải giá Premium…'), findsOneWidget);
      expect(find.byType(PaywallV2View), findsNothing);
      pending.complete(freePlan);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallV2View), findsOneWidget);
      expect(find.text('Gói năm'), findsOneWidget);
      expect(find.text('Đang tải giá Premium…'), findsNothing);
    },
  );

  testWidgets(
    'cached price renders immediately during slow read and remains after failure',
    (tester) async {
      final pending = Completer<FamilyPlanV2?>();
      final (_, container) = await pumpRouted(
        tester,
        const PaywallScreen(entry: PaywallEntry.plan),
        prefs: {
          PaywallPriceCache.key(mai.uid, teddyId, true): jsonEncode({
            'at': DateTime.now().millisecondsSinceEpoch,
            'month': price.month,
            'year': price.year,
          }),
        },
        overrides: [
          ...premiumV2Overrides(plan: null, loadPlan: () => pending.future),
        ],
      );
      expect(find.text('Gói năm'), findsOneWidget);
      expect(find.text('Đang tải giá Premium…'), findsNothing);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Gói năm'), findsOneWidget);
      expect(find.textContaining('Chưa tải được giá'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );

  testWidgets('failure without cache offers retry, then opens priced plans', (
    tester,
  ) async {
    var calls = 0;
    await pumpRouted(
      tester,
      const PaywallScreen(entry: PaywallEntry.plan),
      overrides: [
        ...premiumV2Overrides(
          plan: null,
          loadPlan: () async => ++calls == 1 ? null : freePlan,
        ),
      ],
    );
    expect(find.text('Chưa tải được giá Premium'), findsOneWidget);
    expect(find.byType(PaywallV2View), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Gói năm'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('successful response removing a price clears cached price', (
    tester,
  ) async {
    final (_, container) = await pumpRouted(
      tester,
      const PaywallScreen(entry: PaywallEntry.plan),
      prefs: {
        PaywallPriceCache.key(mai.uid, teddyId, true): jsonEncode({
          'at': DateTime.now().millisecondsSinceEpoch,
          'month': price.month,
          'year': price.year,
        }),
      },
      overrides: premiumV2Overrides(plan: FamilyPlanV2.fromJson({})),
    );
    expect(find.byType(PaywallV2View), findsNothing);
    expect(
      container.read(paywallPriceCacheProvider).read(mai.uid, teddyId, true),
      isNull,
    );
  });
  testWidgets(
    'preloading prices before navigation avoids another request on entry',
    (tester) async {
      var calls = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Consumer(
              builder: (context, ref, _) {
                ref.watch(paywallPriceProvider((babyId: teddyId, vnd: true)));
                return Scaffold(
                  body: TextButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/premium',
            builder: (_, _) => const PaywallScreen(entry: PaywallEntry.plan),
          ),
        ],
      );
      addTearDown(router.dispose);
      await pumpRouted(
        tester,
        const SizedBox(),
        router: router,
        overrides: premiumV2Overrides(
          plan: null,
          loadPlan: () async {
            calls++;
            return freePlan;
          },
        ),
      );
      expect(calls, 1);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Gói năm'), findsOneWidget);
      expect(calls, 1);
    },
  );

  testWidgets('cached price expires even while an offline screen stays open', (
    tester,
  ) async {
    var clock = DateTime.now();
    final pending = Completer<FamilyPlanV2?>();
    await pumpRouted(
      tester,
      const PaywallScreen(entry: PaywallEntry.plan),
      prefs: {
        PaywallPriceCache.key(mai.uid, teddyId, true): jsonEncode({
          'at': clock
              .subtract(const Duration(hours: 24))
              .add(const Duration(seconds: 2))
              .millisecondsSinceEpoch,
          'month': price.month,
          'year': price.year,
        }),
      },
      overrides: [
        ...premiumV2Overrides(plan: null, loadPlan: () => pending.future),
        paywallPriceCacheProvider.overrideWith(
          (ref) => PaywallPriceCache(
            ref.watch(sharedPreferencesProvider),
            now: () => clock,
          ),
        ),
      ],
    );
    expect(find.byType(PaywallV2View), findsOneWidget);
    clock = clock.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallV2View), findsNothing);
    expect(find.text('Đang tải giá Premium…'), findsOneWidget);
  });
}
