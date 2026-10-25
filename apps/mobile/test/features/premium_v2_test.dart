import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tabular_text.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/family_plan_v2.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/plan_screen.dart';
import 'package:child_life/features/premium/premium_entries.dart';
import 'package:child_life/features/premium/premium_gate.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_v2.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/premium_v2_fixtures.dart';
import 'premium_test.dart' show answer;

/// Premium v2 on the phone (Figma 958:13863, D-101): the paywall by entry, Gói của gia đình by
/// role, the usage history and the seat picker; the old screens stay while the flag is off.

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  List<Override> overrides,
) async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        environmentProvider.overrideWithValue(AppEnvironment.dev),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildClTheme(ClPalette.light),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _opener(
  Future<void> Function(BuildContext context, WidgetRef ref) show,
) => Consumer(
  builder: (context, ref, _) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => show(context, ref),
        child: const Text('open'),
      ),
    ),
  ),
);

/// The page's own list (the carousel scrolls too).
Finder get _page => find.byType(Scrollable).first;

/// Numbers draw per digit (ClTabularText): find the widget by its text.
Finder _rich(String text) =>
    find.byWidgetPredicate((w) => w is ClTabularText && w.text == text);

void main() {
  group('paywall (PW01–PW07)', () {
    testWidgets(
      'from Lumi: reason line, the Lumi card first, "Bạn đang cần" on Credit Lumi',
      (tester) async {
        await _pump(
          tester,
          const PaywallScreen(
            entry: PaywallEntry.plan,
            v2Entry: PremiumEntry.lumi,
          ),
          premiumV2Overrides(plan: freePlan),
        );
        expect(find.text('Tiếp tục hỏi Lumi về Teddy'), findsOneWidget);
        expect(
          find.text(
            'Câu hỏi của bạn đang chờ · đã dùng hết 30 credit trải nghiệm.',
          ),
          findsOneWidget,
        );
        expect(find.text('Hỏi một câu, Lumi tóm tắt giúp'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Bạn đang cần'),
          200,
          scrollable: _page,
        );
        expect(find.text('Bạn đang cần'), findsOneWidget);
        // The CTA as drawn; before in-app purchase it says the payment step is coming.
        await tester.tap(find.text('Đăng ký Premium · 599.000đ/năm'));
        await tester.pumpAndSettle();
        expect(find.text('Bước thanh toán sắp mở'), findsOneWidget);
      },
    );

    testWidgets('opened on purpose (PW06): no reason line, no "Bạn đang cần"', (
      tester,
    ) async {
      await _pump(
        tester,
        const PaywallScreen(
          entry: PaywallEntry.plan,
          v2Entry: PremiumEntry.explore,
        ),
        premiumV2Overrides(plan: freePlan),
      );
      expect(
        find.text('Những năm đầu của con, giữ trọn vẹn hơn'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Kỷ niệm luôn là của bạn'),
        200,
        scrollable: _page,
      );
      expect(find.text('Bạn đang cần'), findsNothing);
    });

    testWidgets(
      'a member who does not manage the plan asks the manager (PW07)',
      (tester) async {
        await _pump(
          tester,
          const PaywallScreen(
            entry: PaywallEntry.templates,
            v2Entry: PremiumEntry.video,
          ),
          premiumV2Overrides(
            plan: asMember(freePlan),
            caps: v2Answer(owner: false),
            me: minh,
          ),
        );
        expect(find.text('Gói của nhà do Mai quản lý'), findsOneWidget);
        expect(find.text('Nhờ Mai nâng cấp'), findsOneWidget);
        expect(
          find.text('Có trong Premium — gói dùng chung của cả nhà.'),
          findsOneWidget,
        );
        expect(find.text('Theo năm'), findsNothing);
      },
    );

    testWidgets('flag off: the PR01 page as before', (tester) async {
      await _pump(
        tester,
        const PaywallScreen(
          entry: PaywallEntry.plan,
          v2Entry: PremiumEntry.lumi,
        ),
        premiumV2Overrides(plan: freePlan, caps: answer()),
      );
      expect(find.text('Tiếp tục hỏi Lumi về Teddy'), findsNothing);
    });
  });

  group('Gói của gia đình (PV40 / PV40B / PV43 / PV45)', () {
    testWidgets('a Free manager sees one-time allowances and "Xem các gói"', (
      tester,
    ) async {
      await _pump(
        tester,
        const HouseholdPlanScreen(),
        premiumV2Overrides(plan: freePlan),
      );
      expect(find.text('Lumi · trải nghiệm'), findsOneWidget);
      expect(_rich('còn 2 / 30 credit'), findsOneWidget);
      expect(_rich('còn 0 / 2 lượt'), findsOneWidget);
      expect(find.text('Dùng một lần, không cấp lại'), findsNWidgets(2));
      await tester.scrollUntilVisible(find.text('Xem các gói'), 200);
      expect(find.text('Xem các gói'), findsOneWidget);
    });

    testWidgets('Premium: refill dates, renewal and what cancelling means', (
      tester,
    ) async {
      await _pump(
        tester,
        const HouseholdPlanScreen(),
        premiumV2Overrides(
          plan: premiumPlan,
          caps: v2Answer(
            plan: 'premium',
            validUntil: '2027-10-24T03:00:00.000Z',
          ),
        ),
      );
      expect(_rich('còn 132 / 200 credit'), findsOneWidget);
      expect(find.text('Cấp lại 24/11'), findsNWidgets(2));
      await tester.scrollUntilVisible(find.text('Nếu huỷ'), 200);
      expect(find.textContaining('Premium còn tới 24/10/2027'), findsOneWidget);
    });

    testWidgets(
      'a member sees the shared allowances, never price or others\' history',
      (tester) async {
        await _pump(
          tester,
          const HouseholdPlanScreen(),
          premiumV2Overrides(
            plan: asMember(premiumPlan),
            caps: v2Answer(plan: 'premium', owner: false),
            me: minh,
          ),
        );
        expect(find.text('Cả nhà dùng chung'), findsOneWidget);
        expect(find.text('Quản lý bởi Mai'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Lịch sử sử dụng của tôi'),
          200,
        );
        expect(find.text('Gia hạn'), findsNothing);
        expect(find.text('Mua thêm dung lượng'), findsNothing);
      },
    );

    testWidgets(
      'after a downgrade: nothing deleted, choose who keeps writing',
      (tester) async {
        await _pump(
          tester,
          const HouseholdPlanScreen(),
          premiumV2Overrides(
            plan: downgradedPlan,
            caps: v2Answer(
              plan: 'expired',
              validUntil: '2026-10-24T03:00:00.000Z',
            ),
          ),
        );
        expect(
          find.text('Nhà mình đã về Free từ 24/10/2026. Không có gì bị xoá.'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(find.text('Chọn người'), 200);
        expect(find.text('Vượt chỗ người chăm sóc · 5 / 3'), findsOneWidget);
      },
    );
  });

  testWidgets('PV41: filters by kind; people, task and amount only', (
    tester,
  ) async {
    await _pump(
      tester,
      const UsageHistoryScreen(),
      premiumV2Overrides(plan: premiumPlan),
    );
    expect(find.text('Lumi · Tóm tắt hôm nay'), findsOneWidget);
    expect(_rich('−1 lượt'), findsOneWidget);
    expect(_rich('+200'), findsOneWidget);
    expect(find.textContaining('đang giữ'), findsOneWidget);
    await tester.tap(find.text('Cấp & hoàn'));
    await tester.pumpAndSettle();
    expect(find.text('Lumi · Tóm tắt hôm nay'), findsNothing);
    expect(find.text('Cấp credit tháng'), findsOneWidget);
  });

  testWidgets('PV44: only the manager is pre-checked; Lưu sends the choice', (
    tester,
  ) async {
    final api = FakePremiumV2Api(downgradedPlan);
    await _pump(
      tester,
      _opener(
        (context, ref) =>
            showSeatPicker(context, babyId: teddyId, plan: downgradedPlan),
      ),
      [
        ...premiumV2Overrides(plan: downgradedPlan, api: api),
        familyWritersProvider.overrideWith((ref, id) => [mai, minh, lan]),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu · 1/3'), findsOneWidget);
    await tester.tap(find.text('Cô Lan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu · 2/3'));
    await tester.pumpAndSettle();
    expect(api.kept, [
      ['u_lan'],
    ]);
  });

  group('entry points', () {
    testWidgets(
      'E01: a Premium video template opens Gợi ý Premium, the free way keeps going',
      (tester) async {
        PremiumTemplateChoice? choice;
        await _pump(
          tester,
          _opener((context, ref) async {
            choice = await showPremiumTemplateSheet(
              context,
              templateName: '100 ngày yêu thương',
              caps: Capabilities.fromJson(v2Answer()),
            );
          }),
          premiumV2Overrides(plan: freePlan),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(
          find.text('Mẫu “100 ngày yêu thương” thuộc Premium'),
          findsOneWidget,
        );
        await tester.tap(find.text('Dùng mẫu miễn phí tương tự'));
        await tester.pumpAndSettle();
        expect(choice, PremiumTemplateChoice.useFree);
      },
    );

    testWidgets('E02: a Premium card names the card template', (tester) async {
      await _pump(
        tester,
        _opener(
          (context, ref) => showPremiumTemplateSheet(
            context,
            templateName: 'Hồng phấn',
            caps: Capabilities.fromJson(v2Answer()),
            kind: KeepsakeKind.card,
          ),
        ),
        premiumV2Overrides(plan: freePlan),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Mẫu thiệp “Hồng phấn” thuộc Premium'), findsOneWidget);
    });

    testWidgets('E12: seats full offers Premium or inviting as a relative', (
      tester,
    ) async {
      bool? relative;
      await _pump(
        tester,
        _opener((context, ref) async {
          relative = await showSeatsFullSuggestion(context, ref, teddyId);
        }),
        premiumV2Overrides(plan: freePlan),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.text('Gia đình đã dùng 3/3 chỗ người chăm sóc'),
        findsOneWidget,
      );
      await tester.tap(find.text('Mời làm người thân'));
      await tester.pumpAndSettle();
      expect(relative, isTrue);
    });

    testWidgets('E12 for a Premium family: no paywall', (tester) async {
      await _pump(
        tester,
        _opener(
          (context, ref) => showSeatsFullSuggestion(context, ref, teddyId),
        ),
        premiumV2Overrides(
          plan: premiumPlan,
          caps: v2Answer(plan: 'premium'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Gia đình đã dùng hết 6 chỗ người ghi'), findsOneWidget);
      expect(find.text('Xem Premium'), findsNothing);
    });

    testWidgets('E13 shows for a Free manager only', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: MePremiumInline(babyId: teddyId)),
        premiumV2Overrides(plan: freePlan),
      );
      expect(find.text('Child Life Premium'), findsOneWidget);
    });

    testWidgets('E13 stays away from a member', (tester) async {
      await _pump(
        tester,
        const Scaffold(body: MePremiumInline(babyId: teddyId)),
        premiumV2Overrides(
          plan: asMember(freePlan),
          caps: v2Answer(owner: false),
          me: minh,
        ),
      );
      expect(find.text('Child Life Premium'), findsNothing);
    });
  });

  test('getFamilyPlan answer parses limits, offer and seats', () {
    final p = FamilyPlanV2.fromJson({
      'v2': true,
      'plan': 'premium',
      'isManager': true,
      'cycle': {
        'start': '2026-10-24T03:00:00.000Z',
        'end': '2026-11-24T03:00:00.000Z',
      },
      'validUntil': '2027-10-24T03:00:00.000Z',
      'lumi': {
        'limit': 200,
        'used': 68,
        'reserved': 2,
        'resetsAt': '2026-11-24T03:00:00.000Z',
      },
      'video': {'limit': 4, 'used': 1, 'reserved': 0, 'resetsAt': null},
      'storage': {'usedBytes': 10, 'limitBytes': 100, 'addOnGb': 20},
      'seats': {
        'used': 7,
        'limit': 6,
        'suspended': ['u_x'],
        'overLimit': true,
      },
      'premiumTemplates': true,
      'offer': {
        'free': {
          'lumiCredits': 30,
          'videoExports': 2,
          'storageBytes': 1,
          'caregiverSeats': 3,
        },
        'premium': {
          'lumiCredits': 200,
          'videoExports': 4,
          'storageBytes': 10,
          'caregiverSeats': 6,
        },
      },
      'prices': {
        'vn': {'month': 59000, 'year': 599000},
        'intl': {'month': 5.99, 'year': 49.99},
      },
      'storageAddOns': [
        {
          'id': 'storage_20',
          'gb': 20,
          'price': {
            'vn': {'month': 39000, 'year': 399000},
            'intl': {'month': 1.99, 'year': 19.99},
          },
        },
      ],
    });
    expect(p.premium, isTrue);
    expect(p.lumi.left, 130);
    expect(p.video.resetsAt, isNull);
    expect(p.addOnGb, 20);
    expect(p.suspended, ['u_x']);
    expect(p.overLimit, isTrue);
    expect(p.free.caregiverSeats, 3);
    expect(p.addOns.single.vn.year, 399000);
    expect(p.cycleEnd, DateTime.utc(2026, 11, 24, 3));
  });
}
