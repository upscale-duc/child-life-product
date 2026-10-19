import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/features/library/content_calc.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/content_repository.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/library/library_widgets.dart';
import 'package:child_life/features/milestones/milestone_models.dart';
import 'package:child_life/features/milestones/milestone_repository.dart';
import 'package:child_life/features/nutrition/nutrition_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/solids/solids_calc.dart';
import 'package:child_life/features/solids/solids_family_screens.dart';
import 'package:child_life/features/solids/solids_models.dart';
import 'package:child_life/features/solids/solids_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/library_fixtures.dart';
import '../helpers/milestone_fixtures.dart';
import '../helpers/nutrition_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/solids_fixtures.dart';

/// Library readability, thumbnails and families abroad (D-087, P-166; plan
/// docs/product/library-readability-intl-plan.md): `{emergency}` in content, the 4d reading
/// layouts shared by Chăm bé and Ăn dặm, and the Ăn dặm pictures.

const _guideId = 'art_solids_first_meal_guide';

/// The 4d reader on [readerGuideDoc] (parsed with [emergency]) next to the other fixtures.
Future<(List<Visit>, ProviderContainer)> _reader(
  WidgetTester tester, {
  String? country,
  String emergency = '115',
  Locale locale = const Locale('vi'),
  ClPalette palette = ClPalette.light,
  FakeFirstAidDevice? device,
  String id = _guideId,
}) => pumpRouted(
  tester,
  ArticleScreen(articleId: id),
  locale: locale,
  palette: palette,
  overrides: [
    ...careOverrides(firstAid: seedFirstAidPack(), firstAidDevice: device),
    ...libraryOverrides(
      articles: [
        ...articlesWithSolids(),
        readerGuide(emergency: emergency),
      ],
    ),
    if (country != null)
      selectedFamilyCountryProvider.overrideWithValue(country),
  ],
);

ScrollPosition _body(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

void main() {
  group('{emergency} in content (P-166 #1)', () {
    test('the family number: VN 115, US 911, no or unknown country 115', () {
      expect(lbEmergencyNumber('VN'), '115');
      expect(lbEmergencyNumber('US'), '911');
      expect(lbEmergencyNumber('GB'), '999');
      expect(lbEmergencyNumber(null), '115');
      expect(lbEmergencyNumber('XX'), '115');
      for (final (country, number) in [
        ('VN', '115'),
        ('US', '911'),
        (null, '115'),
      ]) {
        final c = ProviderContainer(
          overrides: [selectedFamilyCountryProvider.overrideWithValue(country)],
        );
        addTearDown(c.dispose);
        expect(c.read(contentEmergencyNumberProvider), number);
      }
    });

    test('articles: title, summary, every block, keywords and search', () {
      final doc = {
        ...readerGuideDoc,
        'title': {
          'vi': 'Khi nào gọi {emergency}',
          'en': 'When to call {emergency}',
        },
        'body': {
          'vi': [
            {'type': 'paragraph', 'text': 'Gọi {emergency}.'},
            {'type': 'heading', 'text': 'Số {emergency}'},
            {
              'type': 'bullets',
              'items': ['Bấm {emergency}', 'Bình tĩnh'],
            },
            {
              'type': 'callout',
              'tone': 'doctor',
              'title': 'Gọi {emergency} khi',
              'text': 'bé lả đi: {emergency}',
            },
            {
              'type': 'image',
              'image': 'call-help_0a1b2c3d',
              'caption': 'Gọi {emergency}',
              'alt': 'Điện thoại gọi {emergency}',
            },
          ],
          'en': <Object?>[],
        },
      };
      for (final (number, other) in [('911', '115'), ('115', '911')]) {
        final a = LbArticle.fromDoc(_guideId, doc, emergency: number)!;
        final texts = [
          ...a.searchTexts(),
          for (final b in a.body.vi)
            if (b is LbFigure) ...[?b.alt],
        ];
        expect(texts.where((t) => t.contains('{emergency}')), isEmpty);
        expect(texts.where((t) => t.contains(number)), hasLength(12));
        expect(texts.where((t) => t.contains(other)), isEmpty);
        expect(a.title.vi, 'Khi nào gọi $number');
        expect(a.keywords.vi, ['gọi $number']);
      }
      // No number given (fixtures, older callers): 115.
      expect(readerGuide().summary!.en, contains('when to call 115'));
      // Search finds the family's number, not another country's.
      expect(SdLibraryFilter(query: '911').apply([readerGuide()]), isEmpty);
      expect(
        SdLibraryFilter(
          query: '911',
        ).apply([readerGuide(emergency: '911')]).map((a) => a.id),
        [_guideId],
      );
    });

    test('recipes, stages, reference milestones and nutrition', () {
      final recipe = SdRecipe.fromDoc('rcp_chao_bi_do', {
        ...recipeDocs.first,
        'tip': {
          'vi': 'Bé khó thở: gọi {emergency}.',
          'en': 'Breathing trouble: call {emergency}.',
        },
        'steps': {
          'vi': ['Nấu chín.', 'Nếu bé hóc, gọi {emergency}.'],
          'en': ['Cook.', 'If baby chokes, call {emergency}.'],
        },
      }, emergency: '000')!;
      expect(recipe.tip!.vi, 'Bé khó thở: gọi 000.');
      expect(recipe.steps.en.last, 'If baby chokes, call 000.');

      final stage = LbStage.fromDoc('stg_w0', {
        ...stageDocs.first,
        'doing': {
          'vi': ['Gọi {emergency} nếu bé tím tái'],
          'en': ['Call {emergency} if baby turns blue'],
        },
      }, emergency: '112')!;
      expect(stage.doing.vi.single, 'Gọi 112 nếu bé tím tái');

      final nutrient = NuNutrient.fromDoc('nut_vitamin_a', {
        ...vitaminADoc(),
        'warning': {
          'vi': 'Uống nhầm nhiều: gọi {emergency}.',
          'en': 'Too much by mistake: call {emergency}.',
        },
      }, emergency: '911')!;
      expect(nutrient.warning!.en, 'Too much by mistake: call 911.');

      final m = seedMilestones().first;
      const talk = MtText('Gọi {emergency} ngay', 'Call {emergency} now');
      final withToken = ReferenceMilestone(
        id: m.id,
        group: m.group,
        order: m.order,
        ageRange: m.ageRange,
        title: m.title,
        howToRecognise: m.howToRecognise,
        talkToDoctor: talk,
      ).withEmergency('119');
      expect(withToken.talkToDoctor!.vi, 'Gọi 119 ngay');
      expect(withToken.talkToDoctor!.en, 'Call 119 now');
    });

    test('reference milestones arrive with the family number', () async {
      final m = seedMilestones().first;
      final c = ProviderContainer(
        overrides: [
          selectedFamilyCountryProvider.overrideWithValue('US'),
          milestoneRepositoryProvider.overrideWithValue(
            FakeMilestoneRepository(
              reference: [
                ReferenceMilestone(
                  id: m.id,
                  group: m.group,
                  order: m.order,
                  ageRange: m.ageRange,
                  title: m.title,
                  howToRecognise: m.howToRecognise,
                  talkToDoctor: const MtText(
                    'Gọi {emergency} nếu bé co giật',
                    'Call {emergency} if baby has a seizure',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(referenceMilestonesProvider, (_, _) {});
      final list = await c.read(referenceMilestonesProvider.future);
      expect(list.single.talkToDoctor!.vi, 'Gọi 911 nếu bé co giật');
    });
  });

  group('4d reading layouts (P-166 #2, #3)', () {
    test('myths, steps and lead-ins are read from the bullets', () {
      expect(lbMyth('A → B → C'), (myth: 'A', why: 'B', instead: 'C'));
      expect(lbMyth('“A.” → C'), (myth: '“A.”', why: null, instead: 'C'));
      expect(lbMyth('Ngáp, dụi mắt'), isNull);
      expect(lbMyth('A → B → C → D'), isNull);
      expect(lbMyth('A → '), isNull);
      expect(lbStep('Bước 3 · Món đầu: cháo'), (n: 3, text: 'Món đầu: cháo'));
      expect(lbStep('Step 10 · After the meal'), (
        n: 10,
        text: 'After the meal',
      ));
      expect(lbStep('Bước đầu tiên'), isNull);
      expect(lbLeadIn('Chỗ ngồi: chọn ghế'), (
        lead: 'Chỗ ngồi',
        rest: 'chọn ghế',
      ));
      expect(lbLeadIn('Lúc 8:00 cho bé ăn'), isNull);
      expect(lbLeadIn('${'x' * 41}: quá dài'), isNull);
    });

    test('"Bài tiếp theo": the next guide of the library and age band', () {
      final all = [...articlesWithSolids(), readerGuide()];
      final bands = [for (final b in SdBand.values) (b.fromWeeks, b.toWeeks)];
      final guide = readerGuide();
      // 4–5 months band (from week 22): the guide with a group first, then by age.
      expect(lbNextGuide(all, guide, bands: bands)?.id, 'art_solids_readiness');
      final readiness = all.firstWhere((a) => a.id == 'art_solids_readiness');
      expect(
        lbNextGuide(all, readiness, bands: bands)?.id,
        'art_solids_first_meals',
      );
      // It wraps around, and skips what the related list already shows.
      final firstMeals = all.firstWhere(
        (a) => a.id == 'art_solids_first_meals',
      );
      expect(lbNextGuide(all, firstMeals, bands: bands)?.id, _guideId);
      expect(
        lbNextGuide(all, firstMeals, bands: bands, skip: {_guideId})?.id,
        'art_solids_readiness',
      );
      // Care articles stay in their library.
      final care = fixtureArticles().firstWhere(
        (a) => a.id == 'art_newborn_sleep',
      );
      final next = lbNextGuide(
        all,
        care,
        bands: [for (final b in LbAgeBand.values) (b.fromWeeks, b.toWeeks)],
      );
      expect(next?.library, LbLibrary.care);
    });

    testWidgets('urgent callout: red, "Gọi 911" dials the family, Sơ cứu', (
      tester,
    ) async {
      final device = FakeFirstAidDevice();
      final (visits, _) = await _reader(
        tester,
        country: 'US',
        emergency: '911',
        device: device,
      );
      final call = find.byKey(const Key('lbUrgentCall'));
      await tester.ensureVisible(call);
      await tester.pumpAndSettle();
      expect(find.text('Gọi 911 ngay khi'), findsOneWidget);
      expect(
        find.descendant(of: call, matching: find.text('Gọi 911')),
        findsOneWidget,
      );
      expect(find.textContaining('115'), findsNothing);
      final box = tester.widget<Container>(
        find.byKey(const Key('lbCallout_urgent')),
      );
      final colors = buildClTheme(ClPalette.light).extension<ClTheme>()!.colors;
      expect((box.decoration! as BoxDecoration).color, colors.errorSoft);
      await tester.tap(call);
      await tester.pumpAndSettle();
      expect(device.dialled, ['911']);
      await tester.ensureVisible(find.byKey(const Key('lbUrgentFirstAid')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lbUrgentFirstAid')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/utilities/first-aid');
    });

    testWidgets('urgent callout without a country: 115', (tester) async {
      final device = FakeFirstAidDevice();
      await _reader(tester, device: device);
      final call = find.byKey(const Key('lbUrgentCall'));
      await tester.ensureVisible(call);
      await tester.pumpAndSettle();
      expect(find.text('Gọi 115 ngay khi'), findsOneWidget);
      expect(
        find.descendant(of: call, matching: find.text('Gọi 115')),
        findsOneWidget,
      );
      await tester.tap(call);
      await tester.pumpAndSettle();
      expect(device.dialled, ['115']);
    });

    testWidgets('"Trong bài này": a tap scrolls to the heading', (
      tester,
    ) async {
      await _reader(tester);
      final contents = find.byKey(const Key('lbContents'));
      expect(contents, findsOneWidget);
      for (final h in [
        'Chuẩn bị',
        'Hiểu lầm thường gặp',
        'Theo dõi sau bữa ăn',
      ]) {
        expect(
          find.descendant(of: contents, matching: find.text(h)),
          findsOneWidget,
        );
      }
      // After the key takeaways, before the first heading.
      expect(
        tester.getTopLeft(contents).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(const Key('lbTakeaways'))).dy,
        ),
      );
      expect(_body(tester).pixels, 0);
      await tester.tap(find.byKey(const Key('lbContents_2')));
      await tester.pumpAndSettle();
      expect(_body(tester).pixels, greaterThan(0));
      final heading = find.text('Theo dõi sau bữa ăn').last;
      final top = tester.getTopLeft(heading).dy;
      final bodyTop = tester.getTopLeft(find.byType(ListView)).dy;
      // The heading sits just under the top of the body (12 pt of room).
      expect(top - bodyTop, inInclusiveRange(8, 24));
      // Headings stay headers for screen readers.
      expect(
        tester.getSemantics(heading),
        matchesSemantics(label: 'Theo dõi sau bữa ăn', isHeader: true),
      );
    });

    testWidgets('reading progress and "Lên đầu" after one screen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _reader(tester);
      double read() => tester
          .widget<FractionallySizedBox>(
            find.descendant(
              of: find.byKey(const Key('lbProgress')),
              matching: find.byType(FractionallySizedBox),
            ),
          )
          .widthFactor!;
      expect(read(), 0);
      expect(find.byKey(const Key('lbBackToTop')), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(read(), greaterThan(0));
      // Less than one screen down: no button yet.
      expect(find.byKey(const Key('lbBackToTop')), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(_body(tester).pixels, greaterThan(700));
      expect(find.byKey(const Key('lbBackToTop')), findsOneWidget);
      expect(find.bySemanticsLabel('Lên đầu'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lbBackToTop')));
      await tester.pumpAndSettle();
      expect(_body(tester).pixels, 0);
      expect(read(), 0);
      expect(find.byKey(const Key('lbBackToTop')), findsNothing);
      handle.dispose();
    });

    testWidgets('takeaways, myth cards, numbered steps, lead-ins (vi)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _reader(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('lbTakeaways')),
          matching: find.text('Tóm tắt nhanh'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('lbMyth')), findsNWidgets(2));
      expect(find.text('Hiểu lầm'), findsNWidgets(2));
      expect(find.text('Vì sao'), findsOneWidget);
      expect(find.text('Nên làm'), findsNWidgets(2));
      expect(find.text('Bữa đầu phải ăn hết chén'), findsOneWidget);
      expect(find.text('Giữ vị tự nhiên của món.'), findsOneWidget);
      expect(find.textContaining('→'), findsNothing);
      for (final n in [1, 2, 3]) {
        expect(
          find.descendant(
            of: find.byKey(Key('lbStep_$n')),
            matching: find.text('$n'),
          ),
          findsOneWidget,
        );
      }
      expect(find.textContaining('Bước 1'), findsNothing);
      // The step reads as written for screen readers (the badge adds nothing).
      expect(
        tester.getSemantics(find.byKey(const Key('lbStep_1'))).label,
        contains('Bước 1 · Chỗ ngồi: chọn ghế ăn chắc chắn, có đai an toàn.'),
      );
      // Lead-ins in semibold, in steps and plain bullets alike.
      for (final lead in ['Chỗ ngồi: ', 'Ho, ọe nhẹ: ']) {
        final text = tester.widget<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.textSpan is TextSpan &&
                (w.textSpan! as TextSpan).children?.first.toPlainText() == lead,
          ),
        );
        final span = (text.textSpan! as TextSpan).children!.first as TextSpan;
        expect(span.style!.fontWeight, FontWeight.w600);
      }
      expect(
        find.text('Ho, ọe nhẹ: phản xạ bình thường khi bé học nuốt.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('English, Night care: Myth / Why / Instead, steps, Up next', (
      tester,
    ) async {
      final (visits, _) = await _reader(
        tester,
        locale: const Locale('en'),
        palette: ClPalette.nightCare,
      );
      expect(find.text('Key takeaways'), findsOneWidget);
      expect(find.text('In this article'), findsOneWidget);
      expect(find.text('Myth'), findsNWidgets(2));
      expect(find.text('Why'), findsOneWidget);
      expect(find.text('Instead'), findsNWidgets(2));
      expect(find.byKey(const Key('lbStep_3')), findsOneWidget);
      expect(find.textContaining('Step 1'), findsNothing);
      final next = find.byKey(const Key('lbNext_art_solids_readiness'));
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Call 115 right away if'), findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/a/art_solids_readiness');
    });

    testWidgets('older content reads as before: no contents, no takeaways', (
      tester,
    ) async {
      await _reader(tester, id: 'art_newborn_sleep');
      expect(find.text('Nhận biết bé buồn ngủ'), findsOneWidget);
      expect(find.byKey(const Key('lbContents')), findsNothing);
      expect(find.byKey(const Key('lbTakeaways')), findsNothing);
      expect(find.byKey(const Key('lbMyth')), findsNothing);
      expect(find.byKey(const Key('lbCallout_doctor')), findsOneWidget);
    });

    testWidgets('a note further down stays a note; repeated step numbers', (
      tester,
    ) async {
      final doc = {
        ...readerGuideDoc,
        'body': {
          'vi': [
            {'type': 'heading', 'text': 'Một'},
            {
              'type': 'bullets',
              'items': ['Bước 1 · Rửa tay', 'Bước 1 · Rửa tay lần nữa'],
            },
            {'type': 'callout', 'tone': 'note', 'text': 'Ghi chú cuối bài.'},
          ],
          'en': <Object?>[],
        },
      };
      await pumpRouted(
        tester,
        const ArticleScreen(articleId: _guideId),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(articles: [LbArticle.fromDoc(_guideId, doc)!]),
        ],
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('lbTakeaways')), findsNothing);
      expect(find.byKey(const Key('lbCallout_note')), findsOneWidget);
      expect(find.byKey(const Key('lbContents')), findsNothing);
      expect(find.byKey(const Key('lbStep_1')), findsNWidgets(2));
    });

    testWidgets('the body is at most 640 pt wide, centred on a tablet', (
      tester,
    ) async {
      await _reader(tester);
      tester.view.physicalSize = const Size(1024, 1366);
      await tester.pumpAndSettle();
      final takeaways = tester.getRect(find.byKey(const Key('lbTakeaways')));
      expect(takeaways.width, 640);
      expect(takeaways.left, (1024 - 640) / 2);
    });
  });

  group('pictures (P-166 #5)', () {
    testWidgets('each Ăn dặm group has its icon and tint', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildClTheme(ClPalette.light),
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final cl = context.cl;
      final icons = {
        for (final s in LbSubtopic.values) s: lbSubtopicLook(context, s).icon,
      };
      expect(icons, {
        LbSubtopic.start: ClIcons.spoon,
        LbSubtopic.methods: ClIcons.hand,
        LbSubtopic.textures: ClIcons.bowl,
        LbSubtopic.nutrition: ClIcons.carrot,
        LbSubtopic.allergy: ClIcons.egg,
        LbSubtopic.safety: ClIcons.shield,
        LbSubtopic.menus: ClIcons.calendar,
        LbSubtopic.skills: ClIcons.hand,
        LbSubtopic.health: ClIcons.cup,
        LbSubtopic.gear: ClIcons.highChair,
        LbSubtopic.family: ClIcons.bowl,
      });
      expect(
        lbSubtopicLook(context, LbSubtopic.start).soft,
        cl.colors.sunshineSoft,
      );
      expect(lbSubtopicLook(context, LbSubtopic.start).ink, cl.colors.ink);
      expect(
        lbSubtopicLook(context, LbSubtopic.safety).soft,
        cl.care.breast.soft,
      );
      expect(lbSubtopicLook(context, LbSubtopic.gear).ink, cl.care.pump.ink);
      // Distinct looks: no two groups share both icon and tint.
      final looks = {
        for (final s in LbSubtopic.values)
          (lbSubtopicLook(context, s).icon, lbSubtopicLook(context, s).soft),
      };
      expect(looks, hasLength(LbSubtopic.values.length));
      // Unknown or absent groups: the topic's picture.
      expect(LbSubtopic.parse('toys'), isNull);
      expect(readerGuide().subtopic, LbSubtopic.start);
      final care = fixtureArticles().first;
      expect(care.subtopic, isNull);
      expect(
        lbArticleLook(context, care).icon,
        lbTopicLook(context, care.topic).icon,
      );
    });

    test('a recipe takes its main ingredient\'s picture', () {
      final foods = {for (final f in fixtureFoods()) f.id: f};
      SdRecipeArt art(List<String> ids, [SdTexture? t]) =>
          sdRecipeArt(ids, foods, texture: t);
      // The first food that is not a grain (rice first, then pumpkin).
      expect(art(['fd_rice', 'fd_pumpkin']), SdRecipeArt.vegetable);
      expect(art(['fd_rice', 'fd_chicken']), SdRecipeArt.animalProtein);
      expect(art(['fd_egg', 'fd_chicken']), SdRecipeArt.egg);
      expect(art(['fd_banana', 'fd_egg']), SdRecipeArt.fruit);
      expect(art(['fd_peas']), SdRecipeArt.legumeNut);
      expect(art(['fd_rice', 'fd_sweet_potato']), SdRecipeArt.grain);
      // A fat is never the dish; no catalogue food: the texture.
      expect(art(['fd_honey'], SdTexture.finger), SdRecipeArt.finger);
      expect(art([], SdTexture.smooth), SdRecipeArt.puree);
      expect(art([], SdTexture.softPieces), SdRecipeArt.pieces);
      expect(art([]), SdRecipeArt.dish);
      final dairy = SdFood(
        id: 'fd_yogurt',
        name: const LbText('Sữa chua', 'Yogurt'),
        group: SdGroup.dairy,
      );
      expect(
        sdRecipeArt(['fd_rice', 'fd_yogurt'], {...foods, 'fd_yogurt': dairy}),
        SdRecipeArt.dairy,
      );
    });

    testWidgets('5f rows: guides by group, recipes by ingredient', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SolidsLibraryScreen(),
        overrides: solidsOverrides(
          articles: [...articlesWithSolids(), readerGuide()],
          recipes: fixtureRecipes(),
        ),
      );
      ClIcons icon(String key) =>
          tester.widget<LbPicture>(find.byKey(Key(key))).look!.icon;
      // The newest guide of the band is featured, with its group's spoon.
      expect(icon('lbThumb_$_guideId'), ClIcons.spoon);
      // A guide without a group keeps the topic's picture.
      expect(icon('lbThumb_art_solids_iron'), ClIcons.feed);
      expect(icon('sdRecipeThumb_rcp_chao_bi_do'), ClIcons.carrot);
      expect(icon('sdRecipeThumb_rcp_trung_ga'), ClIcons.egg);
    });

    testWidgets('a family recipe without a photo: its ingredient', (
      tester,
    ) async {
      final recipe = familyRecipe('Cháo bí đỏ nhà làm');
      await pumpRouted(
        tester,
        Scaffold(
          body: SdFamilyRecipeRow(recipe: recipe, onTap: () {}),
        ),
        palette: ClPalette.nightCare,
        overrides: solidsOverrides(),
      );
      final thumb = find.byKey(Key('sdFamilyThumb_${recipe.id}'));
      final icon = tester.widget<ClIcon>(
        find.descendant(of: thumb, matching: find.byType(ClIcon)),
      );
      expect(icon.icon, ClIcons.carrot);
      final night = buildClTheme(ClPalette.nightCare).extension<ClTheme>()!;
      expect(icon.color, night.care.diaper.ink);
    });
  });
}
