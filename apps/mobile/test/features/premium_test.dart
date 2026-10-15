import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/premium/plan_screen.dart';
import 'package:child_life/features/premium/premium_gate.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/pump.dart';

/// Premium & Cá nhân hoá, Slice 1 on the phone (plan §7 E4 / Q1): the `getCapabilities` answer,
/// Cao cấp templates in `subscribers` mode (MO02) and the household plan (PR03).
Map<String, Object?> answer({
  String plan = 'free',
  bool templates = false,
  bool owner = true,
  String? country = 'VN',
  String? validUntil,
  bool? autoRenew,
  bool billing = false,
  String? provider,
  String via = 'paid',
  String? rhythmReason,
}) => {
  'familyId': 'f_test',
  'policyVersion': 'policy-v2-draft',
  'entitlementVersion': 3,
  'plan': plan,
  'validUntil': validUntil,
  'autoRenew': autoRenew,
  'isBillingOwner': false,
  'canManageBilling': owner,
  'country': country,
  'provider': provider,
  'capabilities': {
    'rhythm.checkin': {'allowed': true, 'reason': null, 'via': 'free'},
    'rhythm.advanced': {
      'allowed': templates && rhythmReason == null,
      'reason': templates && rhythmReason == null
          ? null
          : (rhythmReason ?? 'PREMIUM_REQUIRED'),
      'via': templates ? via : null,
    },
    'templates.premium': {
      'allowed': templates,
      'reason': templates ? null : 'PREMIUM_REQUIRED',
      'via': templates ? via : null,
    },
    'ai.assistance': {'allowed': false, 'reason': 'ROLE_DENIED', 'via': null},
  },
  'features': {
    'rhythm': true,
    'personalization': true,
    'aiAssist': false,
    'billing': billing,
  },
};

void main() {
  group('Capabilities', () {
    test('reads the server answer and survives the offline copy', () {
      final caps = Capabilities.fromJson(
        answer(plan: 'beta', validUntil: '2026-10-20T00:00:00.000Z'),
      )!;
      expect(caps.plan, HouseholdPlan.beta);
      expect(caps.validUntil, DateTime.utc(2026, 10, 20));
      expect(caps.allows(Capability.rhythmCheckin), isTrue);
      expect(
        caps.reasonFor(Capability.templatesPremium),
        GateReason.premiumRequired,
      );
      expect(caps.reasonFor(Capability.aiAssistance), GateReason.roleDenied);
      // Unknown to the answer: never allowed.
      expect(caps.allows(Capability.personalizationCrossModule), isFalse);
      expect(caps.features.rhythm, isTrue);
      final again = Capabilities.fromJson(caps.toJson())!;
      expect(again.plan, caps.plan);
      expect(again.reasonFor(Capability.aiAssistance), GateReason.roleDenied);
      expect(again.country, 'VN');
    });

    test('anything malformed is no answer, not an unlock', () {
      expect(Capabilities.fromJson(null), isNull);
      expect(Capabilities.fromJson({'plan': 'premium'}), isNull);
      expect(
        Capabilities.fromJson({'familyId': 'f', 'plan': 'gold'})!.plan,
        HouseholdPlan.free,
      );
    });
  });

  group('catalog premium access', () {
    Map<String, Object?> catalog(String access) => {
      'templates': const [],
      'premium': {'access': access, 'badges': true},
    };

    test('subscribers is understood; an unknown mode reads as hidden', () {
      expect(
        KeepsakeCatalog.fromJson(catalog('subscribers')).premiumAccess,
        PremiumAccess.subscribers,
      );
      expect(
        KeepsakeCatalog.fromJson(catalog('everyone')).premiumAccess,
        PremiumAccess.everyone,
      );
      expect(
        KeepsakeCatalog.fromJson(catalog('later-mode')).premiumAccess,
        PremiumAccess.hidden,
      );
    });
  });

  group('MO02 · Cao cấp in subscribers mode', () {
    Future<bool?> pick(
      WidgetTester tester, {
      required Map<String, Object?> caps,
    }) async {
      bool? result;
      final template = seedCatalog().cards.firstWhere(
        (t) => t.id == 'card_blush',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capabilitiesProvider.overrideWith(
              (ref, babyId) async => Capabilities.fromJson(caps),
            ),
          ],
          child: clHarness(
            Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async => result = await ensureTemplateAllowed(
                  context,
                  ref,
                  template: template,
                  catalog: const KeepsakeCatalog(
                    [],
                    premiumAccess: PremiumAccess.subscribers,
                  ),
                  babyId: teddyId,
                ),
                child: const Text('use'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('use'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('a beta family sees MO02, told the beta excludes Premium', (
      tester,
    ) async {
      await pick(tester, caps: answer(plan: 'beta'));
      expect(find.text('Hồng phấn'), findsOneWidget);
      expect(find.text('Mở với Premium'), findsOneWidget);
      expect(find.text('Dùng mẫu cơ bản'), findsOneWidget);
      expect(
        find.textContaining('Gói beta hiện tại của nhà mình chưa gồm mẫu Premium'),
        findsOneWidget,
      );
      expect(
        find.text('Thẻ Premium không trừ lượt xuất video'),
        findsOneWidget,
      );
      await tester.tap(find.text('Dùng mẫu cơ bản'));
      await tester.pumpAndSettle();
      expect(find.text('Mở với Premium'), findsNothing);
    });

    testWidgets('a Premium family goes straight on', (tester) async {
      expect(
        await pick(tester, caps: answer(plan: 'premium', templates: true)),
        isTrue,
      );
      expect(find.text('Mở với Premium'), findsNothing);
    });
  });

  group('PR03 · Gói của hộ', () {
    Future<void> pumpPlan(
      WidgetTester tester,
      Map<String, Object?> caps, {
      bool owner = true,
      Locale locale = const Locale('vi'),
    }) async {
      final me = owner ? mai : minh;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedMembershipProvider.overrideWithValue(me),
            capabilitiesProvider.overrideWith(
              (ref, babyId) async => Capabilities.fromJson(caps),
            ),
          ],
          child: clHarness(const HouseholdPlanScreen(), locale: locale),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('free: what stays free; the owner may set the region', (
      tester,
    ) async {
      await pumpPlan(tester, answer());
      expect(find.text('Đang dùng gói cơ bản'), findsOneWidget);
      expect(find.text('Gói nào cũng có'), findsWidgets);
      expect(find.text('Việt Nam'), findsOneWidget);
      // Slice 4: the owner opens PR01; restore waits for the store (D-074).
      expect(find.text('Xem Premium'), findsOneWidget);
      expect(find.text('Khôi phục'), findsNothing);
      expect(find.textContaining('sẽ có ở bản sau'), findsNothing);
    });

    testWidgets('premium with renewal off keeps access until the date', (
      tester,
    ) async {
      await pumpPlan(
        tester,
        answer(
          plan: 'premium',
          templates: true,
          validUntil: '2026-11-14T00:00:00.000Z',
          autoRenew: false,
        ),
        locale: const Locale('en'),
      );
      expect(find.text('Child Life Premium'), findsOneWidget);
      expect(find.textContaining('Active until Nov 14, 2026'), findsOneWidget);
    });

    testWidgets(
      'a member who is not the owner cannot manage or change the region',
      (tester) async {
        await pumpPlan(
          tester,
          answer(plan: 'premium', templates: true, owner: false, country: null),
          owner: false,
        );
        expect(find.textContaining('Hộ đã có Premium'), findsOneWidget);
        expect(
          find.textContaining('Chỉ chủ hộ mua và quản lý gói'),
          findsOneWidget,
        );
        expect(find.text('Chưa chọn'), findsOneWidget);
        await tester.tap(find.text('Khu vực của hộ'));
        await tester.pumpAndSettle();
        expect(find.text('Gia đình đang sống ở đâu?'), findsNothing);
      },
    );

    testWidgets('the owner opens the region sheet', (tester) async {
      await pumpPlan(tester, answer(country: null));
      await tester.tap(find.text('Khu vực của hộ'));
      await tester.pumpAndSettle();
      expect(find.text('Gia đình đang sống ở đâu?'), findsOneWidget);
      expect(find.text('Singapore'), findsOneWidget);
    });
  });
}
