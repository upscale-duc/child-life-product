import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/who_growth.dart';
import 'package:child_life/features/nutrition/nutrition_calc.dart';
import 'package:child_life/features/nutrition/nutrition_growth_screen.dart';
import 'package:child_life/features/nutrition/nutrition_milk_screen.dart';
import 'package:child_life/features/nutrition/nutrition_models.dart';
import 'package:child_life/features/nutrition/nutrition_nutrient_screen.dart';
import 'package:child_life/features/nutrition/nutrition_screens.dart';
import 'package:child_life/features/nutrition/nutrition_vitamin_screen.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/nutrition_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/router_pump.dart';

/// Dinh dưỡng (D-083, Figma 9a–9g, plan §4 and §8 acceptance) on the care mock: Thursday
/// 8 Oct 2026, 15:05 in Hồ Chí Minh. Teddy is 7 months old here (born 8 Mar 2026), a boy.

final _born = DateTime(2026, 3, 8);

BabyPrivateProfile _profile(DateTime dob) =>
    BabyPrivateProfile(dateOfBirth: dob, gender: Gender.boy);

/// Bottle feeds on 4–8 Oct: 700, 720, 730, 710, 730 ml (average 718 → 720).
List<CareRecord> _bottles({
  List<int> totals = const [700, 720, 730, 710, 730],
}) => [
  for (final (i, ml) in totals.indexed) ...[
    rec(
      CareType.bottle,
      vn(8 - (totals.length - 1 - i), 7, 0),
      mai,
      amountMl: ml ~/ 2,
    ),
    rec(
      CareType.bottle,
      vn(8 - (totals.length - 1 - i), 11, 0),
      mai,
      amountMl: ml - ml ~/ 2,
    ),
  ],
];

double _p(DateTime on, {required bool low}) {
  final r = WhoGrowth.range(
    GrowthMeasure.weight,
    boy: true,
    ageDays: nuDaysBetween(_born, on),
  )!;
  return low ? r.low - 0.4 : r.median;
}

/// Two weights on 20 Sep and 5 Oct, both under P3 when [low], else on the median.
List<CareRecord> _growth({bool low = false}) => [
  for (final on in [DateTime(2026, 10, 5), DateTime(2026, 9, 20)])
    rec(
      CareType.growth,
      on.add(const Duration(hours: 9)),
      mai,
      weightKg: double.parse(_p(on, low: low).toStringAsFixed(1)),
      lengthCm: 66,
      measuredOn: on,
    ),
];

List<Override> _overrides({
  Membership? me,
  DateTime? dob,
  bool noDob = false,
  List<CareRecord>? bottles,
  List<CareRecord> growth = const [],
  List<NuStage>? stages,
  List<NuRule> rules = const [],
  Map<String, String> taken = const {},
  List<Reminder> reminders = const [],
  FakeReminderRepository? reminderRepo,
  FakeNutritionStore? store,
  ShareLog? share,
}) => [
  ...careOverrides(
    me: me,
    growth: growth,
    range: bottles ?? _bottles(),
    reminders: reminders,
    // Caregivers read the date of birth kept on the vaccine plan (P-133).
    vaccinePlan: VaccinePlan(scheduleFrom: noDob ? null : (dob ?? _born)),
  ).where(
    (o) =>
        !'$o'.contains('<BabyPrivateProfile?') &&
        (reminderRepo == null ||
            !'$o'.contains('Provider<ReminderRepository>')),
  ),
  babyPrivateProfileProvider.overrideWith(
    (ref, id) => Stream.value(
      noDob
          ? BabyPrivateProfile.fromJson(const {'dateOfBirth': ''})
          : _profile(dob ?? _born),
    ),
  ),
  ...nutritionOverrides(
    stages: stages,
    rules: rules,
    taken: taken,
    store: store,
    share: share,
  ),
  if (reminderRepo != null)
    reminderRepositoryProvider.overrideWithValue(reminderRepo),
];

/// Back from a stub page the screen pushed.
Future<void> _back(WidgetTester tester) async {
  GoRouter.of(tester.element(find.text('stub'))).pop();
  await tester.pumpAndSettle();
}

Future<void> _see(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  group('9b Dinh dưỡng', () {
    testWidgets('Cùng nuôi: stage, milk, growth, nutrients, sample day, tips', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(growth: _growth()),
      );
      expect(find.text('Dinh dưỡng'), findsOneWidget);
      expect(find.text('7 tháng · giai đoạn 6–8 tháng'), findsOneWidget);
      expect(find.text('Bắt đầu ăn dặm'), findsOneWidget);
      // Acceptance #2: the average of 5 days, 718 → 720, marker and line.
      expect(
        find.textContaining('Teddy trung bình 720 ml/ngày (7 ngày qua)'),
        findsOneWidget,
      );
      expect(find.textContaining('4–5 cữ, 180–240 ml mỗi cữ'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Trung bình 720 ml')),
        findsOneWidget,
      );
      await _see(tester, find.byKey(const Key('nuGrowthCard')));
      expect(find.text('Lần đo gần nhất 05/10'), findsOneWidget);
      expect(find.text('Trong khoảng chuẩn'), findsWidgets);
      expect(
        find.byKey(const Key('nuGrowthBanner_nru_weight_low')),
        findsNothing,
      );
      await _see(tester, find.text('Vitamin A'));
      expect(find.text('Sắt'), findsOneWidget);
      // The next campaign round on the vitamin A row (8 Oct → 1–2/12).
      expect(find.text('1–2/12'), findsOneWidget);
      await _see(tester, find.text('Đêm'));
      expect(find.text('Sáng'), findsOneWidget);
      await _see(tester, find.text('Gợi ý cho Teddy'));
      await _see(
        tester,
        find.text('Thịt bò, gan gà, lòng đỏ trứng cho Teddy.'),
      );
      await _see(tester, find.byKey(const Key('nuFootnote')));
      final footer = tester.widget<Text>(find.byKey(const Key('nuFootnote')));
      expect(footer.data, contains('Biên soạn theo hướng dẫn WHO'));
      expect(
        footer.data,
        contains('Thuốc, vi chất dạng uống: theo chỉ định bác sĩ.'),
      );
      expect(footer.data, isNot(contains('Không thay thế tư vấn của bác sĩ.')));
    });

    testWidgets('cards open 9c, 9f, 9d, 9g and Tăng trưởng', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(growth: _growth()),
      );
      await tester.tap(find.byKey(const Key('nuSeeStages')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition/stages');
      await _back(tester);
      await tester.tap(find.byKey(const Key('nuMilkCard')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition/milk');
      await _back(tester);
      await _see(tester, find.byKey(const Key('nuGrowthCard')));
      await tester.tap(find.byKey(const Key('nuGrowthCard')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/history?filter=growth');
      await _back(tester);
      await _see(tester, find.byKey(const Key('nuNutrient_nut_vitamin_a')));
      await tester.tap(find.byKey(const Key('nuNutrient_nut_iron')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition/n/nut_iron');
      await _back(tester);
      await tester.tap(find.byKey(const Key('nuNutrient_nut_vitamin_a')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition/vitamin/nut_vitamin_a');
    });

    testWidgets('a growth rule fires: calm banner → 9e, the rule\'s tips', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(
          growth: _growth(low: true),
          rules: rulesOf([ruleDoc()]),
        ),
      );
      final banner = find.byKey(const Key('nuGrowthBanner_nru_weight_low'));
      expect(banner, findsOneWidget);
      expect(
        find.text(
          '2 lần đo gần nhất của Teddy thấp hơn khoảng chuẩn. Đây không phải chẩn đoán.',
        ),
        findsOneWidget,
      );
      await _see(tester, find.text('Thấp hơn khoảng chuẩn'));
      await _see(tester, find.text('Duy trì sữa đều đặn'));
      expect(find.text('Mỗi ngày một món giàu sắt'), findsNothing);
      await tester.scrollUntilVisible(
        banner,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(banner);
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition/growth/nru_weight_low');
    });

    testWidgets('caregiver: no growth card or banner (acceptance #6)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(
          me: lan,
          growth: _growth(low: true),
          rules: rulesOf([ruleDoc()]),
        ),
      );
      // The stage follows the date of birth Cùng nuôi keep on the vaccine plan.
      expect(find.text('Bắt đầu ăn dặm'), findsOneWidget);
      expect(find.byKey(const Key('nuMilkCard')), findsOneWidget);
      expect(
        find.byKey(const Key('nuGrowthBanner_nru_weight_low')),
        findsNothing,
      );
      await _see(tester, find.byKey(const Key('nuFootnote')));
      expect(find.byKey(const Key('nuGrowthCard')), findsNothing);
      expect(find.text('Gợi ý cho Teddy'), findsOneWidget);
    });

    testWidgets('fewer than 3 bottle days: no marker, the "chưa đủ" line', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(bottles: _bottles(totals: [700, 0, 720])),
      );
      expect(
        find.textContaining('Chưa đủ cữ bú bình 7 ngày qua để tính trung bình'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Trung bình')), findsNothing);
    });

    testWidgets(
      '1,000 ml against 600–900: the milk rule line (acceptance #3)',
      (tester) async {
        await pumpRouted(
          tester,
          const NutritionScreen(),
          overrides: _overrides(
            bottles: _bottles(totals: [1000, 1000, 1000]),
            rules: rulesOf([
              ruleDoc(
                id: 'nru_milk',
                metric: 'milk',
                condition: 'milkOutsideStage',
                banner: 'Mỗi bé mỗi khác. Trao đổi với bác sĩ nếu kéo dài.',
              ),
            ]),
          ),
        );
        expect(find.byKey(const Key('nuMilkRule')), findsOneWidget);
        expect(
          find.text('Mỗi bé mỗi khác. Trao đổi với bác sĩ nếu kéo dài.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('no date of birth: one card to the profile (acceptance #7)', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(noDob: true),
      );
      expect(find.byKey(const Key('nuNoDob')), findsOneWidget);
      expect(find.byKey(const Key('nuStageCard')), findsNothing);
      await tester.tap(find.byKey(const Key('nuAddDob')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/baby-edit/${teddy.id}');
    });

    testWidgets('nothing published for the age: a calm empty state', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(
          stages: stagesOf([stageDoc(id: 'nst_late', from: 24, to: 37)]),
        ),
      );
      expect(
        find.text('Nội dung dinh dưỡng đang được chuẩn bị'),
        findsOneWidget,
      );
    });

    testWidgets('past 36 months: the last stage, "đã qua" (acceptance #9)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: _overrides(
          dob: DateTime(2022, 9, 1),
          stages: stagesOf([
            stageDoc(id: 'nst_late', from: 24, to: 37, title: 'Tự lập bữa ăn'),
          ]),
        ),
      );
      expect(find.text('Tự lập bữa ăn'), findsOneWidget);
      expect(find.byKey(const Key('nuPast')), findsOneWidget);
    });

    testWidgets('English and Night care render', (tester) async {
      await pumpRouted(
        tester,
        const NutritionScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: _overrides(growth: _growth()),
      );
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Starting solids'), findsOneWidget);
      expect(find.text('7 months · 6–8 months stage'), findsOneWidget);
      expect(
        find.textContaining('Teddy averages 720 ml a day (last 7 days)'),
        findsOneWidget,
      );
      await _see(tester, find.text('Ideas for Teddy'));
      expect(tester.takeException(), isNull);
    });
  });

  group('9c, 9d, 9f', () {
    testWidgets('9c: 14 bars over the band; tap a bar; the stage table', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionMilkScreen(),
        overrides: _overrides(),
      );
      expect(find.text('Lượng sữa'), findsOneWidget);
      expect(
        find.text('Vùng màu: khoảng tham khảo 600–900 ml'),
        findsOneWidget,
      );
      expect(find.text('08/10 · 730 ml'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nuBar_12')));
      await tester.pump();
      expect(find.text('07/10 · 710 ml'), findsOneWidget);
      await _see(tester, find.byKey(const Key('nuMilkRow_nst_solids')));
      expect(
        find.descendant(
          of: find.byKey(const Key('nuMilkRow_nst_solids')),
          matching: find.text('Hiện tại'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('9f: past · current · future; a stage opens read-only', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const NutritionStagesScreen(),
        overrides: _overrides(),
      );
      expect(find.text('Các giai đoạn'), findsOneWidget);
      expect(find.text('Những ngày đầu'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nuTimeline_nst_first')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition/stages/nst_first');
    });

    testWidgets('a stage from 9f: no personal cards (P-163 #14)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutritionStageScreen(stageId: 'nst_first'),
        overrides: _overrides(
          growth: _growth(low: true),
          rules: rulesOf([ruleDoc()]),
        ),
      );
      expect(find.text('Những ngày đầu'), findsOneWidget);
      expect(find.textContaining('Teddy trung bình'), findsNothing);
      expect(find.byKey(const Key('nuSeeStages')), findsNothing);
      expect(
        find.byKey(const Key('nuGrowthBanner_nru_weight_low')),
        findsNothing,
      );
      await _see(tester, find.byKey(const Key('nuFootnote')));
      expect(find.byKey(const Key('nuGrowthCard')), findsNothing);
    });

    testWidgets('9d: the by-age row covering the baby is highlighted', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const NutrientScreen(nutrientId: 'nut_iron'),
        overrides: _overrides(),
      );
      expect(find.text('Sắt'), findsOneWidget);
      expect(find.text('Quan trọng từ 6 tháng'), findsOneWidget);
      await _see(tester, find.byKey(const Key('nuByAge_1')));
      expect(
        find.descendant(
          of: find.byKey(const Key('nuByAge_1')),
          matching: find.text('Hiện tại'),
        ),
        findsOneWidget,
      );
      expect(find.text('Hiện tại'), findsOneWidget);
    });
  });

  group('9e Gợi ý theo tăng trưởng', () {
    testWidgets('re-measure in 14 days creates an all-day reminder; export', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      final share = ShareLog();
      await pumpRouted(
        tester,
        const NutritionGrowthScreen(ruleId: 'nru_weight_low'),
        overrides: _overrides(
          growth: _growth(low: true),
          rules: rulesOf([ruleDoc()]),
          reminderRepo: repo,
          share: share,
        ),
      );
      expect(find.text('Cân nặng của Teddy'), findsOneWidget);
      expect(find.text('Theo chuẩn WHO · bé trai'), findsOneWidget);
      expect(find.byKey(const Key('nuGrowthRuleBanner')), findsOneWidget);
      await _see(tester, find.byKey(const Key('nuRemind')));
      expect(find.text('Nhắc đo lại sau 2 tuần'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nuRemind')));
      await tester.pumpAndSettle();
      final r = repo.created.single;
      expect(r.allDay, isTrue);
      expect(r.dueDate, '2026-10-22');
      expect(r.title, 'Đo lại cân nặng cho bé');
      expect(r.leadMinutes, 0);
      expect(r.notifyDevice?.id, testDeviceId);
      expect(find.text('Đã đặt nhắc đo lại ngày 22/10/2026'), findsOneWidget);

      await _see(tester, find.byKey(const Key('nuExport')));
      await tester.tap(find.byKey(const Key('nuExport')));
      await tester.pumpAndSettle();
      final text = share.calls.single.text!;
      expect(text, contains('Tóm tắt tăng trưởng · Child Life'));
      expect(text, contains('Tuổi: 7 tháng tuổi'));
      expect(text, contains('(thấp hơn khoảng chuẩn)'));
      expect(text, contains('720 ml/ngày'));
      expect(text, contains('2 lần đo gần nhất của bé'));
      expect(text, isNot(contains('Teddy')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('an open re-measure reminder: "Đã đặt nhắc · 22/10"', (
      tester,
    ) async {
      final open = Reminder(
        id: 'rm_${'a' * 32}',
        babyId: teddyId,
        title: 'Đo lại cân nặng cho bé',
        dueAt: allDayDueAt('Asia/Ho_Chi_Minh', DateTime(2026, 10, 22)),
        leadMinutes: 0,
        notifyDevice: null,
        createdBy: mai.uid,
        author: CareAuthor.of(mai),
        allDay: true,
        dueDate: '2026-10-22',
      );
      await pumpRouted(
        tester,
        const NutritionGrowthScreen(ruleId: 'nru_weight_low'),
        overrides: _overrides(
          growth: _growth(low: true),
          rules: rulesOf([ruleDoc()]),
          reminders: [open],
        ),
      );
      await _see(tester, find.byKey(const Key('nuReminded')));
      expect(find.text('Đã đặt nhắc · 22/10'), findsOneWidget);
      expect(find.byKey(const Key('nuRemind')), findsNothing);
    });

    testWidgets('caregivers get no growth suggestions', (tester) async {
      await pumpRouted(
        tester,
        const NutritionGrowthScreen(ruleId: 'nru_weight_low'),
        overrides: _overrides(
          me: lan,
          growth: _growth(low: true),
          rules: rulesOf([ruleDoc()]),
        ),
      );
      expect(find.text('Không có gợi ý lúc này'), findsOneWidget);
      expect(find.byKey(const Key('nuRemind')), findsNothing);
    });
  });

  group('9g Vitamin A', () {
    testWidgets(
      'a 7-month baby: June too young, December next (acceptance #8)',
      (tester) async {
        await pumpRouted(
          tester,
          const VitaminScreen(nutrientId: 'nut_vitamin_a'),
          overrides: _overrides(),
        );
        expect(find.text('Vitamin A'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('nuRound_2026-06')),
            matching: find.textContaining('Chưa tới tuổi'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('nuRound_2026-12')),
            matching: find.text('Sắp tới'),
          ),
          findsOneWidget,
        );
        // A round not begun cannot be recorded.
        await tester.tap(find.byKey(const Key('nuRound_2026-12')));
        await tester.pump();
        expect(find.text('Đợt này chưa tới.'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets('Cùng nuôi marks a round taken with its date, then undoes', (
      tester,
    ) async {
      final store = FakeNutritionStore();
      await pumpRouted(
        tester,
        const VitaminScreen(nutrientId: 'nut_vitamin_a'),
        overrides: _overrides(dob: DateTime(2025, 1, 10), store: store),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('nuRound_2026-06')),
          matching: find.textContaining('Đã qua, chưa ghi nhận'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('nuRound_2026-06')));
      await tester.pumpAndSettle();
      expect(find.text('01/06/2026'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nuVitaMark')));
      await tester.pumpAndSettle();
      expect(store.calls, [('2026-06', '2026-06-01', 'u_mai')]);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a taken round reads "Đã uống dd/mm/yyyy" and can be undone', (
      tester,
    ) async {
      final store = FakeNutritionStore();
      await pumpRouted(
        tester,
        const VitaminScreen(nutrientId: 'nut_vitamin_a'),
        overrides: _overrides(
          dob: DateTime(2025, 1, 10),
          store: store,
          taken: const {'2026-06': '2026-06-02'},
        ),
      );
      expect(find.textContaining('Đã uống 02/06/2026'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nuRound_2026-06')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nuVitaUnmark')));
      await tester.pumpAndSettle();
      expect(store.calls, [('2026-06', null, 'u_mai')]);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('caregivers read only', (tester) async {
      await pumpRouted(
        tester,
        const VitaminScreen(nutrientId: 'nut_vitamin_a'),
        overrides: _overrides(me: lan, dob: DateTime(2025, 1, 10)),
      );
      expect(find.byKey(const Key('nuVitaRemind')), findsNothing);
      await tester.tap(find.byKey(const Key('nuRound_2026-06')));
      await tester.pump();
      expect(find.text('Chỉ Cùng nuôi ghi được đợt đã uống.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('"Đặt nhắc": 08:00 the day before, for me, with an .ics file', (
      tester,
    ) async {
      final repo = FakeReminderRepository();
      final share = ShareLog();
      await pumpRouted(
        tester,
        const VitaminScreen(nutrientId: 'nut_vitamin_a'),
        overrides: _overrides(reminderRepo: repo, share: share),
      );
      await _see(tester, find.byKey(const Key('nuVitaRemind')));
      await tester.tap(find.byKey(const Key('nuVitaRemind')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nhắc trước 1 ngày, lúc 8:00 sáng 30/11.'),
        findsOneWidget,
      );
      expect(find.text('Bạn'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nuVitaSetReminder')));
      await tester.pumpAndSettle();
      final r = repo.created.single;
      expect(r.allDay, isFalse);
      expect(r.leadMinutes, 1440);
      expect(
        r.dueAt,
        instantInZone('Asia/Ho_Chi_Minh', DateTime(2026, 12, 1, 8)),
      );
      expect(
        r.fireAt('Asia/Ho_Chi_Minh').toUtc(),
        DateTime.utc(2026, 11, 30, 1),
      );
      expect(r.assigneeUid, 'u_mai');
      expect(r.title, 'Uống Vitamin A tại trạm y tế · 1–2/12');
      final file = share.calls.single.file!;
      expect(file.name, endsWith('.ics'));
      expect(file.mimeType, 'text/calendar');
      expect(file.content, contains('DTSTART;VALUE=DATE:20261201'));
      expect(find.text('Đã đặt nhắc lúc 8:00 ngày 30/11'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a reminder already set: "Đã đặt nhắc · 30/11"', (
      tester,
    ) async {
      final set = Reminder(
        id: 'rm_${'b' * 32}',
        babyId: teddyId,
        title: 'Uống Vitamin A tại trạm y tế · 1–2/12',
        dueAt: instantInZone('Asia/Ho_Chi_Minh', DateTime(2026, 12, 1, 8)),
        leadMinutes: 1440,
        notifyDevice: null,
        createdBy: mai.uid,
        author: CareAuthor.of(mai),
      );
      await pumpRouted(
        tester,
        const VitaminScreen(nutrientId: 'nut_vitamin_a'),
        overrides: _overrides(reminders: [set]),
      );
      await _see(tester, find.byKey(const Key('nuVitaReminded')));
      expect(find.text('Đã đặt nhắc · 30/11'), findsOneWidget);
    });

    testWidgets('before 6 months: from when, and the first round', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const VitaminScreen(nutrientId: 'nut_vitamin_a'),
        overrides: _overrides(dob: DateTime(2026, 9, 17)),
      );
      expect(find.byKey(const Key('nuVitaTooYoung')), findsOneWidget);
      expect(
        find.text(
          'Teddy sẽ được uống từ 6 tháng tuổi. Đợt đầu tiên: 1–2/6/2027.',
        ),
        findsOneWidget,
      );
    });
  });

  group('9a tile in Chăm sóc', () {
    testWidgets('live: the current stage; opens 9b (acceptance #1)', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: _overrides(),
      );
      final tile = find.byKey(const Key('careNutrition'));
      await _see(tester, tile);
      expect(
        find.descendant(of: tile, matching: find.text('Giai đoạn 6–8 tháng')),
        findsOneWidget,
      );
      expect(find.text('Ăn dặm'), findsNothing);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/nutrition');
    });

    testWidgets('no date of birth: "Cần ngày sinh của bé"', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: _overrides(noDob: true),
      );
      await _see(tester, find.byKey(const Key('careNutrition')));
      expect(find.text('Cần ngày sinh của bé'), findsOneWidget);
    });

    testWidgets('no stage for the age: a teaser that only says so', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: _overrides(
          stages: stagesOf([stageDoc(id: 'nst_late', from: 24, to: 37)]),
        ),
      );
      final tile = find.byKey(const Key('careNutrition'));
      await _see(tester, tile);
      expect(find.text('Theo từng giai đoạn tuổi'), findsOneWidget);
      await tester.tap(tile);
      await tester.pump();
      expect(
        find.text('Phần này sẽ có trong bản cập nhật tới.'),
        findsOneWidget,
      );
      expect(visits, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
