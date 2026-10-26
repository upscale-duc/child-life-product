import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/care/care_sheets.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/nutrition/nutrition_screens.dart';
import 'package:child_life/features/solids/solids_history.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:child_life/features/solids/solids_sheet.dart';
import 'package:child_life/features/solids/solids_widgets.dart';
import 'package:child_life/features/today/today_layout.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/nutrition_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// Ăn dặm screens (D-085; Figma 5a–5h; plan §5 and the §10 QA seeds 1–5 of phases A and B) on the
/// care mock: Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh; the baby born 1 Mar 2026 (7 months).

Future<void> _see(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

Finder _in(String key, Finder matching) =>
    find.descendant(of: find.byKey(Key(key)), matching: matching);

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = _in(key, find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Opens 5c from 5b and fills QA seed #3: "Cháo cà rốt thịt gà" with Gạo, Cà rốt, Thịt gà.
Future<void> _logChickenPorridge(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('sdLogMeal')));
  await tester.pumpAndSettle();
  expect(find.text('Ghi bữa ăn'), findsOneWidget);
  await _type(tester, 'sdDish', 'Cháo cà rốt thịt gà');
  await _tap(tester, 'sdAddFood');
  for (final id in ['fd_rice', 'fd_carrot', 'fd_chicken']) {
    await _tap(tester, 'sdFood_$id');
  }
  await _tap(tester, 'sdFoodsDone');
}

/// A ✦ first-try chip in 5b.
Finder _firstTry(String name) => find.byWidgetPredicate(
  (w) => w is SdFoodChip && w.label == name && w.look == SdChipLook.firstTry,
  description: 'first-try chip $name',
);

void main() {
  group('Care tile (plan §5)', () {
    Future<String> line(WidgetTester tester, List<dynamic> overrides) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: overrides.cast(),
      );
      await _see(tester, find.byKey(const Key('careSolids')));
      final texts = tester
          .widgetList<Text>(_in('careSolids', find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(texts.first, 'Ăn dặm');
      return texts.last!;
    }

    testWidgets('QA #1: under 4 months, "Từ 6 tháng"', (tester) async {
      expect(
        await line(
          tester,
          solidsOverrides(dob: DateTime(2026, 7, 1), store: FakeSolidsStore()),
        ),
        'Từ 6 tháng',
      );
    });

    testWidgets('QA #2: 5 months 20 days, "Sắp đến lúc ăn dặm"', (
      tester,
    ) async {
      expect(
        await line(
          tester,
          solidsOverrides(dob: DateTime(2026, 4, 18), store: FakeSolidsStore()),
        ),
        'Sắp đến lúc ăn dặm',
      );
    });

    testWidgets('6 months, off: "Bắt đầu theo dõi"; on: "Hôm nay · 2 bữa"', (
      tester,
    ) async {
      expect(
        await line(
          tester,
          solidsOverrides(dob: DateTime(2026, 4, 8), store: FakeSolidsStore()),
        ),
        'Bắt đầu theo dõi',
      );
    });

    testWidgets(
      'tracking on: today\'s meals; before Dinh dưỡng (D-113); opens Ăn dặm',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const Scaffold(body: CareHubScreen()),
          overrides: solidsOverrides(),
        );
        final tile = find.byKey(const Key('careSolids'));
        await _see(tester, tile);
        expect(_in('careSolids', find.text('Hôm nay · 2 bữa')), findsOneWidget);
        expect(
          tester.getTopLeft(tile).dy,
          lessThan(
            tester.getTopLeft(find.byKey(const Key('careNutrition'))).dy,
          ),
        );
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(visits.last.location, '/care/solids');
      },
    );

    testWidgets('caregivers read the age from the vaccine plan (P-133)', (
      tester,
    ) async {
      expect(
        await line(
          tester,
          solidsOverrides(
            me: lan,
            dob: DateTime(2026, 7, 1),
            store: FakeSolidsStore(),
          ),
        ),
        'Từ 6 tháng',
      );
    });
  });

  group('5a Bật theo dõi', () {
    testWidgets('QA #1: under 4 months the diary waits; the reminder at '
        '5 months 2 weeks', (tester) async {
      final reminders = FakeReminderRepository();
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(
          dob: DateTime(2026, 7, 1),
          store: FakeSolidsStore(),
          articles: articlesWithSolids(),
          reminderRepo: reminders,
        ),
      );
      expect(find.text('Chưa đến lúc ăn dặm'), findsOneWidget);
      expect(find.byKey(const Key('sdStart')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('sdNotYet'))).data,
        contains('01/01/2027'),
      );
      // The readiness guide opens the reader.
      await tester.tap(find.byKey(const Key('sdReadiness')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/a/art_solids_readiness');
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();
      await _tap(tester, 'sdRemind');
      final r = reminders.created.single;
      expect(r.allDay, isTrue);
      expect(r.dueDate, '2026-12-15');
      expect(r.title, 'Teddy gần 6 tháng: xem cách bắt đầu ăn dặm');
      expect(find.text('Đã đặt nhắc ngày 15/12/2026'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('QA #2: at 5 months 20 days still no start', (tester) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(
          dob: DateTime(2026, 4, 18),
          store: FakeSolidsStore(),
        ),
      );
      expect(find.text('Chưa đến lúc ăn dặm'), findsOneWidget);
      expect(find.byKey(const Key('sdStart')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('sdNotYet'))).data,
        contains('sắp đến lúc ăn dặm'),
      );
    });

    testWidgets('QA #2: at 6 months 0 days a parent starts tracking', (
      tester,
    ) async {
      final store = FakeSolidsStore();
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(dob: DateTime(2026, 4, 8), store: store),
      );
      expect(find.text('Theo dõi ăn dặm'), findsOneWidget);
      // Optional method (default Kết hợp) and the Today toggle (default on).
      await _tap(tester, 'sdMethod_blw');
      await tester.tap(find.byKey(const Key('sdStart')));
      await tester.pumpAndSettle();
      final (settings, uid) = store.saved.single;
      expect(uid, mai.uid);
      expect(settings.enabled, isTrue);
      expect(settings.method, SdMethod.blw);
      expect(settings.showOnToday, isTrue);
      // The diary replaces 5a at once (the local cache).
      expect(find.byKey(const Key('sdSegments')), findsOneWidget);
      expect(find.text('Hôm nay · 0 bữa'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a caregiver asks the parents; the library stays open', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(me: lan, store: FakeSolidsStore()),
      );
      expect(find.text('Nhờ ba mẹ bật theo dõi ăn dặm'), findsOneWidget);
      expect(find.byKey(const Key('sdStart')), findsNothing);
      expect(find.byKey(const Key('sdMethod_blw')), findsNothing);
      await _tap(tester, 'sdOpenLibrary');
      expect(visits.last.location, '/care/solids/library');
    });

    testWidgets('no date of birth: "Cần ngày sinh của bé"', (tester) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(noDob: true, store: FakeSolidsStore()),
      );
      expect(find.byKey(const Key('sdNoDob')), findsOneWidget);
      expect(find.byKey(const Key('sdAddDob')), findsOneWidget);
      expect(find.byKey(const Key('sdStart')), findsNothing);
    });
  });

  group('5b Nhật ký', () {
    testWidgets('week strip, day header, stage line, cards, tried chips', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: [...solidsOverrides(), ...nutritionOverrides()],
      );
      expect(find.text('Ăn dặm'), findsOneWidget);
      expect(find.text('Nhật ký'), findsOneWidget);
      expect(find.text('Hôm nay · 2 bữa'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('sdStageLine'))).data,
        'Giai đoạn 6–8 tháng · 2–3 bữa · Bột loãng → cháo rây',
      );
      // vi times read "8:10" (DateFormat.Hm, as care records).
      expect(find.text('Bữa sáng · 8:10'), findsOneWidget);
      expect(find.text('Cháo bí đỏ'), findsOneWidget);
      expect(find.text('4 thìa · Thích'), findsOneWidget);
      expect(find.text('½ chén · Bình thường'), findsOneWidget);
      // Who logged it; ✦ for Khoai lang (first try today).
      expect(find.text('Bạn ghi'), findsOneWidget);
      expect(find.text('Cô Lan ghi'), findsOneWidget);
      expect(_firstTry('Khoai lang'), findsOneWidget);
      expect(_firstTry('Gạo'), findsNothing);
      expect(find.text('✦ Lần đầu bé thử'), findsOneWidget);
      await _see(tester, find.byKey(const Key('sdTriedChips')));
      expect(find.text('Món đã thử · 14'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      // An earlier day.
      await tester.tap(find.byKey(const Key('sdDay_2026-10-6')));
      await tester.pumpAndSettle();
      expect(find.text('Thứ Ba 06/10 · 2 bữa'), findsOneWidget);
      expect(find.text('Cà rốt hấp nghiền'), findsOneWidget);
      expect(find.text('Vài thìa · Chưa hợp'), findsOneWidget);
    });

    testWidgets('an empty day; earlier weeks; the library segment', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(articles: articlesWithSolids()),
      );
      // The suggestion cards sit above the strip (plan §5 5b #1).
      await tester.ensureVisible(find.byKey(const Key('sdWeekStrip')));
      await tester.pumpAndSettle();
      // Swipe right twice: the week of 21/09, before the first meal (after the 6-month day).
      for (var i = 0; i < 2; i++) {
        await tester.drag(
          find.byKey(const Key('sdWeekStrip')),
          const Offset(400, 0),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('sdDay_2026-9-27')));
      await tester.pumpAndSettle();
      expect(find.text('Chủ Nhật 27/09 · 0 bữa'), findsOneWidget);
      expect(find.byKey(const Key('sdEmptyDay')), findsOneWidget);
      expect(find.text('Chưa có bữa nào trong ngày này'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Thư viện ăn dặm'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Thư viện ăn dặm'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sdLibraryQuery')), findsOneWidget);
      expect(find.byKey(const Key('sdLogMeal')), findsNothing);
    });

    testWidgets('QA #3: "Thịt gà · lần đầu" in 5c, then in 5b; 15 foods', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      await _logChickenPorridge(tester);
      Finder sheet(String text) => find.descendant(
        of: find.byType(MealSheet),
        matching: find.text(text),
      );
      expect(sheet('Thịt gà · lần đầu'), findsOneWidget);
      expect(sheet('Gạo'), findsOneWidget);
      expect(sheet('Cà rốt'), findsOneWidget);
      // The slot comes from the time (15:05 → Chiều); amount and reaction.
      await _tap(tester, 'sdAmount_halfBowl');
      await _tap(tester, 'sdReaction_liked');
      await _tap(tester, 'sdSaveMeal');
      final saved = store.meals.last;
      expect(saved.dish, 'Cháo cà rốt thịt gà');
      expect(saved.foodIds, ['fd_rice', 'fd_carrot', 'fd_chicken']);
      expect(saved.slot, SdSlot.afternoon);
      expect(saved.amount, const SdAmount.preset(SdAmountPreset.halfBowl));
      expect(saved.reaction, SdReaction.liked);
      expect(saved.createdBy, mai.uid);
      expect(saved.pending, isTrue);
      expect(find.text('Đã ghi · Cháo cà rốt thịt gà'), findsOneWidget);
      expect(find.text('Hôm nay · 3 bữa'), findsOneWidget);
      expect(_firstTry('Thịt gà'), findsOneWidget);
      expect(_firstTry('Cà rốt'), findsNothing);
      // The usual pending state while it syncs.
      expect(find.textContaining('Chờ đồng bộ'), findsOneWidget);
      await _see(tester, find.byKey(const Key('sdTriedChips')));
      expect(find.text('Món đã thử · 15'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('QA #4: "Khó thở" shows the 115 card before saving', (
      tester,
    ) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      final device = FakeFirstAidDevice();
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(
          store: store,
          firstAid: seedFirstAidPack(),
          firstAidDevice: device,
        ),
      );
      await _logChickenPorridge(tester);
      expect(find.byKey(const Key('sdUrgentCard')), findsNothing);
      await _tap(tester, 'sdSymptom_breathing');
      expect(find.byKey(const Key('sdUrgentCard')), findsOneWidget);
      expect(
        find.text('Gọi 115 ngay nếu bé khó thở, sưng môi hoặc lưỡi, lả đi.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sdAnaphylaxis')), findsOneWidget);
      await _tap(tester, 'faCall');
      expect(device.dialled, ['115']);
      await _tap(tester, 'sdSaveMeal');
      expect(store.meals.last.symptoms, [SdSymptom.breathing]);
      expect(
        _in('sdMeal_${store.meals.last.id}', find.text('Có dấu hiệu')),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 5e: Thịt gà (new in that meal) is marked; Gạo is not.
      await pumpRouted(
        tester,
        const MealHistoryScreen(foods: true),
        overrides: solidsOverrides(store: store),
      );
      expect(find.text('Tất cả · 15'), findsOneWidget);
      expect(
        _in('sdTried_fd_chicken', find.text('Có dấu hiệu')),
        findsOneWidget,
      );
      expect(_in('sdTried_fd_rice', find.text('Có dấu hiệu')), findsNothing);
    });

    testWidgets('the Sơ cứu link closes the sheet and opens TH05', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(firstAid: seedFirstAidPack()),
      );
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      await _tap(tester, 'sdSymptom_swelling');
      await _tap(tester, 'sdAnaphylaxis');
      expect(visits.last.location, '/utilities/first-aid/s/anaphylaxis');
    });

    testWidgets('a meal needs a dish or an ingredient', (tester) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      await _tap(tester, 'sdSaveMeal');
      expect(find.byKey(const Key('sdSheetError')), findsOneWidget);
      expect(store.calls, isEmpty);
      // A free name is enough (group Khác).
      await _tap(tester, 'sdAddFood');
      await tester.enterText(find.byKey(const Key('sdFoodQuery')), 'Nước hầm');
      await tester.pumpAndSettle();
      await _tap(tester, 'sdAddFree');
      await _tap(tester, 'sdFoodsDone');
      await _tap(tester, 'sdAmount_custom');
      await _type(tester, 'sdAmountValue', '3');
      await _tap(tester, 'sdSaveMeal');
      expect(store.meals.last.freeFoods, ['Nước hầm']);
      expect(store.meals.last.amount, const SdAmount.custom(3, SdUnit.spoon));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('roles (QA #5, P-164 #13)', () {
    testWidgets('a caregiver logs a meal and edits their own', (tester) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(me: lan, store: store),
      );
      // No settings for caregivers.
      expect(find.byKey(const Key('sdSettings')), findsNothing);
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      await _type(tester, 'sdDish', 'Chuối nghiền');
      await _tap(tester, 'sdSaveMeal');
      final mine = store.meals.last;
      expect(mine.createdBy, lan.uid);
      expect(mine.author.name, 'Cô Lan');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await pumpRouted(
        tester,
        MealDetailScreen(mealId: mine.id),
        overrides: solidsOverrides(me: lan, store: store),
      );
      expect(find.byKey(const Key('sdEditMeal')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sdEditMeal')));
      await tester.pumpAndSettle();
      expect(find.text('Sửa bữa ăn'), findsOneWidget);
      await _tap(tester, 'sdReaction_liked');
      await _tap(tester, 'sdSaveMeal');
      expect(store.calls.last, 'edit ${mine.id}');
      expect(store.meals.last.reaction, SdReaction.liked);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a caregiver cannot edit a parent\'s meal or clear a food', (
      tester,
    ) async {
      final meals = [
        ...naMeals(),
        meal(
          DateTime.utc(2026, 10, 8, 7, 0).toLocal(),
          foods: ['fd_chicken'],
          symptoms: [SdSymptom.rash],
        ),
      ];
      final store = FakeSolidsStore(meals: meals, settings: naSettings());
      await pumpRouted(
        tester,
        MealDetailScreen(mealId: meals.first.id),
        overrides: solidsOverrides(me: lan, store: store),
      );
      expect(find.byKey(const Key('sdEditMeal')), findsNothing);
      expect(find.byKey(const Key('sdDeleteMeal')), findsNothing);
      expect(find.byKey(const Key('sdViewOnly')), findsOneWidget);

      await pumpRouted(
        tester,
        const FoodDetailScreen(foodKey: 'fd_chicken'),
        overrides: solidsOverrides(me: lan, store: store),
      );
      expect(find.byKey(const Key('sdFoodSigns')), findsOneWidget);
      expect(find.byKey(const Key('sdCleared')), findsNothing);
      expect(find.byKey(const Key('sdHide')), findsNothing);
    });

    testWidgets('a parent: "Bác sĩ đã cho ăn lại" and "Không gợi ý món này"', (
      tester,
    ) async {
      final meals = [
        ...naMeals(),
        meal(
          DateTime.utc(2026, 10, 8, 7, 0).toLocal(),
          foods: ['fd_chicken'],
          symptoms: [SdSymptom.rash],
        ),
      ];
      final store = FakeSolidsStore(meals: meals, settings: naSettings());
      await pumpRouted(
        tester,
        const FoodDetailScreen(foodKey: 'fd_chicken'),
        overrides: solidsOverrides(store: store),
      );
      await _tap(tester, 'sdCleared');
      expect(store.saved.last.$1.cleared, ['fd_chicken']);
      await _tap(tester, 'sdHide');
      expect(store.saved.last.$1.hidden, ['fd_chicken']);
      expect(store.saved.last.$1.cleared, ['fd_chicken']);
      expect(find.text('Gợi ý lại món này'), findsOneWidget);
    });

    testWidgets('a parent deletes a meal with undo', (tester) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      final target = store.meals.last;
      await pumpRouted(
        tester,
        MealDetailScreen(mealId: target.id),
        overrides: solidsOverrides(store: store),
      );
      // Cô Lan's meal: any Cùng nuôi edits it.
      expect(find.text('Cô Lan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sdDeleteMeal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sdDeleteConfirm')));
      await tester.pumpAndSettle();
      expect(store.calls.last, 'delete ${target.id}');
      expect(find.text('Đã xoá bữa ăn'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(store.calls.last, 'restore ${target.id}');
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('settings (P-164 #3, Cùng nuôi)', () {
    testWidgets('method, "Hiện trên Hôm nay", stop tracking', (tester) async {
      final store = FakeSolidsStore(meals: naMeals(), settings: naSettings());
      await pumpRouted(
        tester,
        const SolidsScreen(),
        overrides: solidsOverrides(store: store),
      );
      await tester.tap(find.byKey(const Key('sdSettings')));
      await tester.pumpAndSettle();
      expect(find.text('28/09'), findsOneWidget);
      await tester.tap(find.text('Truyền thống'));
      await tester.tap(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Hiện “Ăn dặm hôm nay” trên Hôm nay'),
                matching: find.byType(Row),
              )
              .first,
          matching: find.byType(ClToggle),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'sdSettingsSave');
      final (saved, uid) = store.saved.last;
      expect(uid, mai.uid);
      expect(saved.method, SdMethod.spoon);
      expect(saved.showOnToday, isFalse);
      expect(saved.enabled, isTrue);
      expect(saved.startedOn, DateTime(2026, 9, 28));

      await tester.tap(find.byKey(const Key('sdSettings')));
      await tester.pumpAndSettle();
      await _tap(tester, 'sdStop');
      await _tap(tester, 'sdStopConfirm');
      expect(store.saved.last.$1.enabled, isFalse);
      // The meals stay; 5a comes back.
      expect(store.meals, hasLength(15));
      expect(find.byKey(const Key('sdStart')), findsOneWidget);
    });
  });

  group('5d / 5e', () {
    testWidgets('5d: days newest first, rows with who and time', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const MealHistoryScreen(),
        overrides: solidsOverrides(),
      );
      expect(find.text('Lịch sử bữa ăn'), findsOneWidget);
      expect(find.text('Hôm nay · Thứ Năm 08/10'), findsOneWidget);
      expect(find.text('Hôm qua · Thứ Tư 07/10'), findsOneWidget);
      expect(find.text('11:30 · ½ chén · Bình thường'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Khoai lang nghiền')).dy,
        lessThan(tester.getTopLeft(find.text('Cháo bí đỏ').first).dy),
      );
      await tester.tap(find.text('Khoai lang nghiền'));
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith('/care/solids/meal/m_'));
    });

    testWidgets('5e: groups, first tried, latest reaction, footnote', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const MealHistoryScreen(foods: true),
        overrides: solidsOverrides(),
      );
      expect(find.text('Tất cả · 14'), findsOneWidget);
      expect(find.text('Rau củ · 5'), findsOneWidget);
      expect(find.text('Tinh bột · 3'), findsOneWidget);
      expect(find.text('Trái cây · 5'), findsOneWidget);
      expect(find.text('Đậu và hạt · 1'), findsOneWidget);
      expect(
        _in('sdTried_fd_sweet_potato', find.text('Lần đầu hôm nay · 1 lần')),
        findsOneWidget,
      );
      expect(_in('sdTried_fd_carrot', find.text('Chưa hợp')), findsOneWidget);
      await _tap(tester, 'sdGroup_legumeNut');
      expect(find.byKey(const Key('sdTried_fd_peas')), findsOneWidget);
      expect(find.byKey(const Key('sdTried_fd_rice')), findsNothing);
      await _see(tester, find.byKey(const Key('sdFootnote')));
      expect(
        find.text(
          'Đây là ghi chép của gia đình bạn, không phải đánh giá hay khuyến nghị '
          'dinh dưỡng.',
        ),
        findsOneWidget,
      );
    });
  });

  group('5f Thư viện ăn dặm', () {
    testWidgets('solids guides, the band preset from the baby, filters', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(articles: articlesWithSolids()),
      );
      expect(find.text('Thư viện ăn dặm'), findsOneWidget);
      // 7 months: "6–8 tháng" is preset (12–23 months guides stay out); the newest guide for
      // the band is featured.
      expect(
        find.byKey(const Key('sdFeatured_art_solids_first_meals')),
        findsOneWidget,
      );
      expect(find.text('Hướng dẫn · Từng bước'), findsOneWidget);
      expect(find.byKey(const Key('sdGuide_art_solids_iron')), findsOneWidget);
      // Care articles and other bands stay out; no recipes published here.
      expect(find.byKey(const Key('sdGuide_art_newborn_sleep')), findsNothing);
      expect(find.byKey(const Key('sdGuide_art_puree')), findsOneWidget);
      expect(
        find.byKey(const Key('sdGuide_art_solids_family_meals')),
        findsNothing,
      );
      expect(find.byKey(const Key('sdRecipes')), findsNothing);
      await _tap(tester, 'sdFormat_quickQa');
      expect(
        find.byKey(const Key('sdFeatured_art_solids_readiness')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sdGuide_art_solids_iron')), findsNothing);
      await _tap(tester, 'sdFormat_quickQa');
      await _tap(tester, 'sdBand_m6to8');
      await tester.enterText(
        find.byKey(const Key('sdLibraryQuery')),
        'gia đình',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('sdGuide_art_solids_family_meals')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('sdGuide_art_solids_family_meals')),
      );
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/a/art_solids_family_meals');
    });

    testWidgets('4f Đã lưu: Chăm bé | Ăn dặm', (tester) async {
      await pumpRouted(
        tester,
        const SavedArticlesScreen(),
        overrides: solidsOverrides(
          articles: articlesWithSolids(),
          saved: [
            (
              id: 'art_solids_iron',
              savedAt: DateTime(2026, 10, 2),
              revision: 1,
            ),
            (
              id: 'art_diaper_rash',
              savedAt: DateTime(2026, 9, 28),
              revision: 1,
            ),
          ],
        ),
      );
      expect(find.byKey(const Key('lbSaved_art_diaper_rash')), findsOneWidget);
      expect(find.byKey(const Key('lbSaved_art_solids_iron')), findsNothing);
      await tester.tap(find.text('Ăn dặm'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lbSaved_art_solids_iron')), findsOneWidget);
      expect(find.byKey(const Key('lbSaved_art_diaper_rash')), findsNothing);
    });
  });

  group('5h, quick log, Dinh dưỡng', () {
    testWidgets('5h: today\'s meals, the latest, first tries, "Ghi bữa"', (
      tester,
    ) async {
      final store = FakeSolidsStore(
        meals: [
          ...naMeals(),
          meal(
            DateTime.utc(2026, 10, 8, 8, 0).toLocal(),
            foods: ['fd_rice', 'fd_carrot', 'fd_chicken'],
            dish: 'Cháo cà rốt thịt gà',
            slot: SdSlot.afternoon,
          ),
        ],
        settings: naSettings(),
      );
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: solidsOverrides(store: store),
      );
      await _see(tester, find.byKey(const Key('sdTodayCard')));
      expect(find.text('Ăn dặm hôm nay · 3 bữa'), findsOneWidget);
      expect(
        find.text('Gần nhất: Cháo cà rốt thịt gà · 15:00'),
        findsOneWidget,
      );
      // QA #3: Thịt gà · lần đầu in 5h too.
      expect(find.text('Lần đầu: Khoai lang, Thịt gà'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sdTodayLog')));
      await tester.pumpAndSettle();
      expect(find.text('Ghi bữa ăn'), findsOneWidget);
      Navigator.of(tester.element(find.text('Ghi bữa ăn'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn dặm hôm nay · 3 bữa'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/solids');
    });

    testWidgets('5h follows the 5a toggle and the Tuỳ chỉnh row', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: solidsOverrides(
          store: FakeSolidsStore(
            meals: naMeals(),
            settings: naSettings(showOnToday: false),
          ),
        ),
      );
      expect(find.byKey(const Key('sdTodayCard')), findsNothing);

      final (_, container) = await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: solidsOverrides(),
      );
      await _see(tester, find.byKey(const Key('sdTodayCard')));
      expect(find.byKey(const Key('sdTodayCard')), findsOneWidget);
      showTodayCustomizeSheet(tester.element(find.byType(TodayScreen)));
      await tester.pumpAndSettle();
      expect(find.text('Ăn dặm hôm nay'), findsOneWidget);
      Navigator.of(tester.element(find.text('Ăn dặm hôm nay'))).pop();
      await tester.pumpAndSettle();
      container
          .read(todayLayoutProvider(teddyId).notifier)
          .set(const TodayLayout().copyWith(hidden: {TodaySection.solids}));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sdTodayCard')), findsNothing);
    });

    testWidgets('the quick log offers Ăn dặm while tracking is on', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: solidsOverrides(),
      );
      showQuickLog(tester.element(find.byType(TodayScreen)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quickSolids')));
      await tester.pumpAndSettle();
      expect(find.text('Ghi bữa ăn'), findsOneWidget);
    });

    testWidgets('no Ăn dặm in the quick log while tracking is off', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: solidsOverrides(store: FakeSolidsStore()),
      );
      showQuickLog(tester.element(find.byType(TodayScreen)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quickSolids')), findsNothing);
    });

    testWidgets('Dinh dưỡng 9b: "Ăn dặm hôm nay · 2 bữa · Mở nhật ký"', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const NutritionScreen(),
        overrides: [...solidsOverrides(), ...nutritionOverrides()],
      );
      final row = find.byKey(const Key('sdNutritionRow'));
      await _see(tester, row);
      expect(
        _in('sdNutritionRow', find.text('Ăn dặm hôm nay · 2 bữa')),
        findsOneWidget,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/solids');
    });
  });

  group('Night care and English (P-164 #18)', () {
    for (final (name, screen, text) in [
      ('5b', const SolidsScreen(), 'Today · 2 meals'),
      ('5d', const MealHistoryScreen(), 'Today · Thursday 08/10'),
      ('5e', const MealHistoryScreen(foods: true), 'All · 14'),
      ('5f', const SolidsLibraryScreen(), 'Solids library'),
    ]) {
      testWidgets('$name renders in Night care, English', (tester) async {
        await pumpRouted(
          tester,
          screen,
          locale: const Locale('en'),
          palette: ClPalette.nightCare,
          overrides: [
            ...solidsOverrides(articles: articlesWithSolids()),
            ...nutritionOverrides(),
          ],
        );
        expect(tester.takeException(), isNull);
        expect(find.text(text), findsOneWidget);
      });
    }

    testWidgets('5c in English: slots, amounts, signs', (tester) async {
      await pumpRouted(
        tester,
        const SolidsScreen(),
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      await tester.tap(find.byKey(const Key('sdLogMeal')));
      await tester.pumpAndSettle();
      expect(find.text('Log a meal'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      await _tap(tester, 'sdSymptom_swelling');
      expect(
        find.text(
          'Call 115 now if baby has trouble breathing, swollen lips or tongue, '
          'or goes floppy.',
        ),
        findsOneWidget,
      );
    });
  });
}
