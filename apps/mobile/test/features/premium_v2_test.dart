import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/core/design/tabular_text.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/family/invite_screens.dart';
import 'package:child_life/features/keepsakes/video_quality_selector.dart';
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
  List<Override> overrides, {
  bool reduceMotion = false,
  double textScale = 1,
  Size viewport = const Size(375, 812),
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = viewport;
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
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
  testWidgets(
    'Free sees Full HD requires Premium before tapping; cancel keeps HD',
    (tester) async {
      String? quality;
      await _pump(
        tester,
        Scaffold(
          body: VideoQualitySelector(
            babyId: teddyId,
            selection: quality,
            onChanged: (q) => quality = q,
          ),
        ),
        premiumV2Overrides(plan: freePlan),
      );
      await tester.tap(find.text('Chất lượng video'));
      await tester.pumpAndSettle();
      expect(find.text('Cần Premium · Tìm hiểu'), findsOneWidget);
      expect(quality, isNull);
      await tester.tap(find.text('Full HD 1080p'));
      await tester.pumpAndSettle();
      expect(find.text('Xuất Full HD với Premium'), findsOneWidget);
      expect(quality, isNull);
      await tester.tap(find.text('Tiếp tục với HD 720p'));
      await tester.pumpAndSettle();
      expect(find.text('HD 720p'), findsOneWidget);
      expect(quality, isNull);
    },
  );
  testWidgets('Premium defaults to Full HD and can choose HD without upsell', (
    tester,
  ) async {
    String? quality;
    await _pump(
      tester,
      Scaffold(
        body: VideoQualitySelector(
          babyId: teddyId,
          selection: quality,
          onChanged: (q) => quality = q,
        ),
      ),
      premiumV2Overrides(plan: premiumPlan),
    );
    expect(find.text('Full HD 1080p'), findsOneWidget);
    await tester.tap(find.text('Chất lượng video'));
    await tester.pumpAndSettle();
    expect(find.text('Cần Premium · Tìm hiểu'), findsNothing);
    await tester.tap(find.text('HD 720p'));
    await tester.pumpAndSettle();
    expect(quality, 'hd720');
    expect(find.text('Xuất Full HD với Premium'), findsNothing);
  });
  testWidgets(
    'full Free writer seats explain Premium before the invite action',
    (tester) async {
      await _pump(
        tester,
        const InviteRoleScreen(),
        premiumV2Overrides(plan: freePlan),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(InviteRoleScreen)),
      );
      expect(find.text(l.pv2SeePremium), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.pv2E12Body(6)), 160);
      expect(find.text(l.pv2E12Body(6)), findsOneWidget);
    },
  );
  testWidgets('legacy rollout hides the new quality control', (tester) async {
    await _pump(
      tester,
      Scaffold(
        body: VideoQualitySelector(
          babyId: teddyId,
          selection: null,
          onChanged: (_) {},
        ),
      ),
      premiumV2Overrides(plan: null, caps: answer()),
    );
    expect(find.text('Chất lượng video'), findsNothing);
  });
  test('unlimited video snapshots never become an exhausted allowance', () {
    final quota = VideoQuota.fromJson({
      'limit': 0,
      'used': 100,
      'reserved': 2,
      'unlimited': true,
    });
    expect(quota!.unlimited, isTrue);
    expect(quota.exhausted, isFalse);
  });
  testWidgets(
    'an unknown family plan never assumes Free or offers an upgrade',
    (tester) async {
      await _pump(
        tester,
        _opener((context, ref) async {
          await showSeatsFullSuggestion(context, ref, teddyId);
        }),
        premiumV2Overrides(plan: null),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa kiểm tra được gói gia đình'), findsOneWidget);
      expect(find.text('Xem Premium'), findsNothing);
    },
  );
  group('paywall (PW01–PW07)', () {
    testWidgets(
      'Figma plan layout retains unavailable billing and five feature destinations',
      (tester) async {
        await _pump(
          tester,
          const PaywallScreen(
            entry: PaywallEntry.plan,
            v2Entry: PremiumEntry.lumi,
          ),
          premiumV2Overrides(plan: freePlan),
        );
        expect(find.text('Nâng cấp lên Premium'), findsOneWidget);
        expect(find.text('Chọn gói'), findsOneWidget);
        expect(find.text('Trợ lý Lumi'), findsOneWidget);
        await tester.tap(find.text('Đăng ký gói năm · 599.000đ'));
        await tester.pumpAndSettle();
        expect(find.text('Bước thanh toán sắp mở'), findsOneWidget);
      },
    );
    testWidgets('all five benefits and shared monthly/yearly plans', (
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
        find.text('Cả nhà dùng chung, dù chọn gói năm hay gói tháng.'),
        findsOneWidget,
      );
      expect(find.text('Tìm hiểu Premium cho tính năng này'), findsNothing);
      await tester.tap(find.text('Gói tháng'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng ký gói tháng · 59.000đ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Thiệp & video kỷ niệm'),
        180,
        scrollable: _page,
      );
      await tester.tap(find.text('Thiệp & video kỷ niệm'));
      await tester.pumpAndSettle();
      expect(find.text('1/5 · Thiệp & video kỷ niệm'), findsOneWidget);
      expect(
        find.text('Không giới hạn lượt xuất chất lượng cao'),
        findsOneWidget,
      );
      expect(find.text('Mọi mẫu · Full HD 1080p'), findsNothing);
      expect(find.text('Mẫu cơ bản · Video 720p'), findsNothing);
      await tester.fling(
        find.text('Kỷ niệm mang dấu ấn của con'),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('2/5 · Hỏi Lumi'), findsOneWidget);
      await tester.fling(
        find.text('Hỏi Lumi mọi thứ về con'),
        const Offset(200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('1/5 · Thiệp & video kỷ niệm'), findsOneWidget);
      await tester.tap(find.text('Quay lại chọn gói'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng ký gói tháng · 59.000đ'), findsOneWidget);
    });
    for (final reduced in [false, true]) {
      testWidgets(
        'benefit paging keeps sheet and footer stable; reduced motion $reduced',
        (tester) async {
          await _pump(
            tester,
            const PaywallScreen(
              entry: PaywallEntry.plan,
              v2Entry: PremiumEntry.explore,
            ),
            premiumV2Overrides(plan: freePlan),
            reduceMotion: reduced,
            textScale: reduced ? 2 : 1,
            viewport: reduced ? const Size(375, 640) : const Size(375, 812),
          );
          final benefit = find.text('Thiệp & video kỷ niệm').hitTestable();
          if (benefit.evaluate().isEmpty) {
            await tester.scrollUntilVisible(benefit, 140, scrollable: _page);
          }
          await tester.tap(benefit);
          await tester.pumpAndSettle();
          final sheet = find.byKey(const ValueKey('premium-benefit-sheet'));
          final pager = find.byType(PageView);
          final controller = tester.widget<PageView>(pager).controller!;
          final initial = controller.page!;
          final frame = tester.getRect(sheet);
          final pageFrame = tester.getRect(pager);
          final footer = tester.getRect(find.text('Quay lại chọn gói'));
          final next = MaterialLocalizations.of(
            tester.element(pager),
          ).nextPageTooltip;
          final nextButton = find.byWidgetPredicate(
            (w) => w is ClPressable && w.semanticLabel == next,
          );
          void stable() {
            expect(tester.getRect(sheet), frame);
            expect(tester.getRect(pager), pageFrame);
            expect(tester.getRect(find.text('Quay lại chọn gói')), footer);
            expect(footer.bottom, lessThanOrEqualTo(reduced ? 640 : 812));
          }

          if (!reduced) {
            final drag = await tester.startGesture(tester.getCenter(pager));
            await drag.moveBy(const Offset(-20, 0));
            await tester.pump(const Duration(milliseconds: 16));
            await drag.moveBy(const Offset(-120, 0));
            await tester.pump(const Duration(milliseconds: 16));
            expect(controller.page, greaterThan(initial));
            expect(controller.page, lessThan(initial + 1));
            stable();
            await drag.moveBy(const Offset(-110, 0));
            await drag.up();
            await tester.pumpAndSettle();
            expect(find.text('2/5 · Hỏi Lumi'), findsOneWidget);
          } else {
            await tester.tap(nextButton);
            await tester.pump();
            expect(controller.page, initial + 1);
          }
          stable();
          await tester.tap(nextButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          if (!reduced) {
            expect(controller.page, greaterThan(initial + 1));
            expect(controller.page, lessThan(initial + 2));
          } else {
            expect(controller.page, initial + 2);
          }
          stable();
          await tester.pumpAndSettle();
          for (var i = 0; i < 3; i++) {
            await tester.tap(nextButton);
            await tester.pumpAndSettle();
            stable();
          }
          expect(find.text('1/5 · Thiệp & video kỷ niệm'), findsOneWidget);
          if (reduced) {
            await tester.drag(pager, const Offset(0, -900));
            await tester.pumpAndSettle();
            expect(
              find
                  .text('Không giới hạn lượt xuất chất lượng cao')
                  .hitTestable(),
              findsOneWidget,
            );
            stable();
          }
        },
      );
    }
    testWidgets('member asks the manager and has no purchase option', (
      tester,
    ) async {
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
      expect(find.text('Nhờ Mai nâng cấp'), findsOneWidget);
      expect(find.text('Gói năm'), findsNothing);
    });
    testWidgets('advanced rhythm intro has no Lumi credit promise', (
      tester,
    ) async {
      await _pump(
        tester,
        const PaywallScreen(entry: PaywallEntry.rhythm),
        premiumV2Overrides(plan: freePlan),
      );
      expect(find.text('Gợi ý cá nhân & nhịp nâng cao'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Gợi ý cá nhân & nhịp nâng cao'),
        120,
        scrollable: _page,
      );
      await tester.tap(find.text('Gợi ý cá nhân & nhịp nâng cao'));
      await tester.pumpAndSettle();
      expect(find.text('Hiểu con hơn mỗi ngày.'), findsOneWidget);
      expect(find.text('Có trong Premium'), findsNothing);
      expect(find.text('3/5 · Gợi ý & nhịp nâng cao'), findsOneWidget);
    });
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
    testWidgets('a Free manager sees one-time allowances and "Xem Premium"', (
      tester,
    ) async {
      await _pump(
        tester,
        const HouseholdPlanScreen(),
        premiumV2Overrides(plan: freePlan),
      );
      expect(find.text('Lumi · trải nghiệm'), findsOneWidget);
      expect(_rich('còn 2 / 30 lượt'), findsOneWidget);
      expect(_rich('còn 0 / 2 lượt'), findsNothing);
      expect(find.text('Dùng một lần, không cấp lại'), findsOneWidget);
      expect(find.text('Xuất video không giới hạn lượt'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Xem Premium'), 200);
      expect(find.text('Xem Premium'), findsOneWidget);
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
      expect(_rich('còn 132 / 200 lượt'), findsOneWidget);
      expect(find.text('Cấp lại 24/11'), findsOneWidget);
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
        expect(find.text('Vượt chỗ người ghi · 5 / 3'), findsOneWidget);
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
        await tester.tap(find.text('Dùng mẫu miễn phí'));
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
      expect(find.text('Gia đình đã dùng 3/3 chỗ người ghi'), findsOneWidget);
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

  test(
    'unknown limit and prices stay unknown, never 0 / full / 0đ (ST-1, P-3)',
    () {
      final p = FamilyPlanV2.fromJson({
        'v2': true,
        'plan': 'free',
        'storage': {'usedBytes': 10, 'reservedBytes': 5},
        'storageAddOns': [
          {'id': 'no_price', 'gb': 20},
          {
            'id': 'storage_50',
            'gb': 50,
            'price': {
              'vn': {'month': 79000, 'year': 799000},
              'intl': {'month': 3.99, 'year': 39.99},
            },
          },
        ],
      });
      expect(p.limitBytes, isNull);
      expect(p.storageKnown, isFalse);
      expect(p.storageFull, isFalse);
      expect(p.storageRatio, 0);
      expect(p.priceVn, isNull);
      expect(p.price(vnd: false), isNull);
      expect(p.addOns.map((a) => a.gb), [50]);

      final full = FamilyPlanV2.fromJson({
        'storage': {'usedBytes': 90, 'reservedBytes': 10, 'limitBytes': 100},
      });
      // D-127 Q2: reserved space counts, as on the server.
      expect(full.storageFull, isTrue);
      expect(full.storageOver, isFalse);
    },
  );
}
