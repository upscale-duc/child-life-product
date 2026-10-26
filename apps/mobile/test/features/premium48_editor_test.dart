import 'dart:async';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import '../helpers/keepsake_fixtures.dart';
import 'dart:convert';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/home/home_shell.dart'
    show selectedMembershipProvider;
import 'dart:io';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/keepsakes/premium_keepsake_editor.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/memory_fixtures.dart';
import 'keepsake_test.dart' show pumpScreen;

void main() {
  testWidgets(
    'celebration decoration is explicitly selected and keeps its identity in the preview',
    (tester) async {
      final raw =
          jsonDecode(
                File(
                  '../../packages/contracts/test/vectors/premium48-phase10.json',
                ).readAsStringSync(),
              )
              as Map;
      final ts = (raw['templates'] as List)
          .map(KeepsakeTemplate.fromJson)
          .nonNulls
          .toList();
      final card = ts.singleWhere((t) => t.id == 'card_premium48_20');
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(template: card, babyId: teddyId),
        catalog: KeepsakeCatalog(ts),
      );
      final dropdown = find.byKey(const ValueKey('p48-field-celebrationTheme'));
      await tester.scrollUntilVisible(
        dropdown,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<DropdownButtonFormField<String>>(dropdown).initialValue,
        isNull,
      );
      // The editor now pins Preview/Save; reveal the field inside the shorter body.
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tết · hoa và phong bao').last);
      await tester.pumpAndSettle();
      await section(tester, 2);
      final content = tester
          .widget<KeepsakeCardView>(find.byType(KeepsakeCardView))
          .content;
      expect(content.field('theme'), 'tet');
      expect(content.field('title'), isNot(contains('đầu tiên')));
    },
  );
  late List<KeepsakeTemplate> templates;
  setUp(() {
    mediaBytes = FakeMediaBytes();
    final json =
        jsonDecode(
              File(
                '../../packages/contracts/test/vectors/premium48.json',
              ).readAsStringSync(),
            )
            as Map;
    templates = (json['templates'] as List)
        .map(KeepsakeTemplate.fromJson)
        .nonNulls
        .toList();
  });
  for (final kind in KeepsakeKind.values) {
    for (final edit in ['untouched', 'typed', 'cleared']) {
      testWidgets('late profile fills ${kind.name}, preserves $edit name', (
        tester,
      ) async {
        final babies = StreamController<Baby?>();
        final profiles = StreamController<BabyPrivateProfile?>();
        addTearDown(babies.close);
        addTearDown(profiles.close);
        final template = templates.firstWhere((t) => t.kind == kind);
        await pumpRouted(
          tester,
          PremiumKeepsakeEditor(template: template, babyId: teddyId),
          overrides: [
            ...careOverrides(),
            selectedMembershipProvider.overrideWithValue(mai),
            ...memoryOverrides(
              keepsakes: (cards: true, videos: true),
              keepsakeCatalog: KeepsakeCatalog(templates),
            ),
            babyProvider(teddyId).overrideWith((ref) => babies.stream),
            babyPrivateProfileProvider(
              teddyId,
            ).overrideWith((ref) => profiles.stream),
            keepsakeAssetImageProvider.overrideWithValue(
              (asset) => const StorageImage('keepsake/peach'),
            ),
          ],
        );
        final name = find.byWidgetPredicate(
          (w) => w is ClTextField && w.label == 'Tên bé',
        );
        await tester.scrollUntilVisible(
          name,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<ClTextField>(name).controller!.text, isEmpty);
        if (edit != 'untouched') {
          await tester.enterText(name, 'An');
          if (edit == 'cleared') await tester.enterText(name, '');
          tester.testTextInput.hide();
        }
        babies.add(teddy);
        profiles.add(teddyProfile());
        await tester.pumpAndSettle();
        expect(
          tester.widget<ClTextField>(name).controller!.text,
          edit == 'untouched'
              ? 'Teddy'
              : edit == 'typed'
              ? 'An'
              : '',
        );
        final date = find.byKey(const ValueKey('p48-input-birthDate'));
        await tester.scrollUntilVisible(
          date,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<TextField>(date).controller!.text, '2026-09-17');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'phase 5 requires a parent confirmation before claiming an item was outgrown',
    (tester) async {
      final raw =
          jsonDecode(
                File(
                  '../../packages/contracts/test/vectors/premium48-phase5.json',
                ).readAsStringSync(),
              )
              as Map;
      final ts = (raw['templates'] as List)
          .map(KeepsakeTemplate.fromJson)
          .nonNulls
          .toList();
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(template: ts.first, babyId: teddyId),
        catalog: KeepsakeCatalog(ts),
      );
      await section(tester, 2);
      expect(
        tester
            .widget<KeepsakeCardView>(find.byType(KeepsakeCardView))
            .content
            .field('headline'),
        'MÓN ĐỒ MUỐN GIỮ',
      );
      await section(tester, 0);
      final confirmation = find.text('Tôi xác nhận món đồ đã không còn vừa bé');
      await tester.scrollUntilVisible(
        confirmation,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(confirmation);
      await tester.pumpAndSettle();
      await section(tester, 2);
      expect(
        tester
            .widget<KeepsakeCardView>(find.byType(KeepsakeCardView))
            .content
            .field('headline'),
        'NHỮNG MÓN ĐỒ ĐÃ CHẬT',
      );
    },
  );

  testWidgets(
    'phase 6 milestone is entered by a parent and photo confirmation changes the preview',
    (tester) async {
      final raw =
          jsonDecode(
                File(
                  '../../packages/contracts/test/vectors/premium48-phase6.json',
                ).readAsStringSync(),
              )
              as Map;
      final ts = (raw['templates'] as List)
          .map(KeepsakeTemplate.fromJson)
          .nonNulls
          .toList();
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(template: ts.first, babyId: teddyId),
        catalog: KeepsakeCatalog(ts),
      );
      final input = find.byWidgetPredicate(
        (w) => w is ClTextField && w.placeholder == 'những bước nhỏ',
      );
      await tester.scrollUntilVisible(
        input,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<ClTextField>(input).controller!.text, isEmpty);
      await tester.enterText(input, 'tự lật');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final confirmation = find.text('Ảnh ghi lại đúng khoảnh khắc đạt mốc');
      await tester.scrollUntilVisible(
        confirmation,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(confirmation);
      await tester.pumpAndSettle();
      await section(tester, 2);
      final copy = tester
          .widget<KeepsakeCardView>(find.byType(KeepsakeCardView))
          .content;
      expect(copy.field('headline'), 'CON LÀM ĐƯỢC RỒI');
      expect(copy.field('label0'), 'tự lật');
      expect(copy.field('title'), contains('tự lật'));
    },
  );

  testWidgets('phase 4 month picker updates the authored chapter number', (
    tester,
  ) async {
    final raw =
        jsonDecode(
              File(
                '../../packages/contracts/test/vectors/premium48-phase4.json',
              ).readAsStringSync(),
            )
            as Map;
    final ts = (raw['templates'] as List)
        .map(KeepsakeTemplate.fromJson)
        .nonNulls
        .toList();
    await pumpScreen(
      tester,
      PremiumKeepsakeEditor(template: ts.first, babyId: teddyId),
      catalog: KeepsakeCatalog(ts),
    );
    await tester.scrollUntilVisible(
      find.text('Tháng tuổi (01–12)'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('12').last,
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('12').last);
    await tester.pumpAndSettle();
    await section(tester, 2);
    expect(
      tester
          .widget<KeepsakeCardView>(find.byType(KeepsakeCardView))
          .content
          .field('ageNumber'),
      '12',
    );
  });

  testWidgets(
    'proposed phase 3 notes require an explicit action and preserve notes already entered',
    (tester) async {
      final raw =
          jsonDecode(
                File(
                  '../../packages/contracts/test/vectors/premium48-phase3.json',
                ).readAsStringSync(),
              )
              as Map;
      final ts = (raw['templates'] as List)
          .map(KeepsakeTemplate.fromJson)
          .nonNulls
          .toList();
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(template: ts.first, babyId: teddyId),
        catalog: KeepsakeCatalog(ts),
      );
      final favorite = find.byWidgetPredicate(
        (w) => w is ClTextField && w.placeholder == 'những cái ôm',
      );
      await tester.scrollUntilVisible(
        favorite,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final favoriteController = tester
          .widget<ClTextField>(favorite)
          .controller!;
      expect(favoriteController.text, isEmpty);
      await tester.enterText(favorite, 'nghe giọng mẹ');
      tester.testTextInput.hide();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Dùng ghi chú gợi ý'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Dùng ghi chú gợi ý'));
      await tester.pump();
      expect(favoriteController.text, 'nghe giọng mẹ');
      final detail = find.byWidgetPredicate(
        (w) => w is ClTextField && w.placeholder == 'một biểu cảm rất riêng',
      );
      await tester.scrollUntilVisible(
        detail,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<ClTextField>(detail).controller!.text,
        'một biểu cảm rất riêng',
      );
    },
  );

  testWidgets('a two-photo premium card edits each slot independently', (
    tester,
  ) async {
    final raw =
        jsonDecode(
              File(
                '../../packages/contracts/test/vectors/premium48-phase2.json',
              ).readAsStringSync(),
            )
            as Map;
    final ts = (raw['templates'] as List)
        .map(KeepsakeTemplate.fromJson)
        .nonNulls
        .toList();
    final t = ts.first;
    final first = CardPhoto(MemoryImage(pngOf('peach')), zoom: 1.2);
    final second = CardPhoto(
      MemoryImage(pngOf('mint')),
      align: Alignment.topLeft,
    );
    await pumpScreen(
      tester,
      PremiumKeepsakeEditor(
        template: t,
        babyId: teddyId,
        cardDraft: CardDraft(
          babyId: teddyId,
          occasion: Occasion.birth,
          date: DateTime(2026, 10, 13),
          format: KeepsakeFormat.portrait,
          template: t,
          palette: t.palette,
          quote: '',
          photos: [first, second],
        ),
      ),
      catalog: KeepsakeCatalog(ts),
    );
    await section(tester, 2);
    var view = tester.widget<KeepsakeCardView>(find.byType(KeepsakeCardView));
    expect(view.content.photos.length, 2);
    view.onPhotoChanged!(
      1,
      second.copyWith(zoom: 1.7, align: Alignment.bottomRight),
    );
    await tester.pump();
    view = tester.widget<KeepsakeCardView>(find.byType(KeepsakeCardView));
    expect(view.content.photos[0], same(first));
    expect(view.content.photos[1]!.zoom, 1.7);
    expect(view.content.photos[1]!.align, Alignment.bottomRight);
    expect(view.content.personalized['photoLabel0'], 'Một ngày đáng nhớ');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'a three-photo card keeps missing slots empty instead of duplicating a selected photo',
    (tester) async {
      final raw =
          jsonDecode(
                File(
                  '../../packages/contracts/test/vectors/premium48-phase2.json',
                ).readAsStringSync(),
              )
              as Map;
      final ts = (raw['templates'] as List)
          .map(KeepsakeTemplate.fromJson)
          .nonNulls
          .toList();
      final t = ts[1];
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(
          template: t,
          babyId: teddyId,
          cardDraft: CardDraft(
            babyId: teddyId,
            occasion: Occasion.m1,
            date: DateTime(2026, 10, 13),
            format: KeepsakeFormat.portrait,
            template: t,
            palette: t.palette,
            quote: '',
            photos: [CardPhoto(MemoryImage(pngOf('peach')))],
          ),
        ),
        catalog: KeepsakeCatalog(ts),
      );
      await section(tester, 2);
      final view = tester.widget<KeepsakeCardView>(
        find.byType(KeepsakeCardView),
      );
      expect(view.content.photos.length, 3);
      expect(view.content.photos[1], isNull);
      expect(view.content.photos[2], isNull);
      expect(view.activeSlot, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an unconfirmed first embrace has neutral copy; the same editor preserves app language while switching output',
    (tester) async {
      final t = templates[1];
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(
          template: t,
          babyId: teddyId,
          cardDraft: CardDraft(
            babyId: teddyId,
            occasion: Occasion.birth,
            date: DateTime(2026, 10, 13),
            format: KeepsakeFormat.portrait,
            template: t,
            palette: t.palette,
            quote: '',
            photos: [CardPhoto(MemoryImage(pngOf('peach')))],
          ),
        ),
        catalog: KeepsakeCatalog(templates),
      );
      await section(tester, 2);
      expect(find.text('Một cái ôm muốn nhớ.'), findsWidgets);
      expect(find.text('Our first embrace.'), findsNothing);
      await tester.tap(find.byTooltip('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('Ngôn ngữ thành phẩm'), findsOneWidget);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.text('An embrace to remember.'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing a photo prevents export; 4-second card preview settles without moving the static export',
    (tester) async {
      final t = templates[0];
      await pumpScreen(
        tester,
        PremiumKeepsakeEditor(template: t, babyId: teddyId),
        catalog: KeepsakeCatalog(templates),
      );
      await section(tester, 2);
      final view = tester.widget<KeepsakeCardView>(
        find.byType(KeepsakeCardView),
      );
      expect(view.previewProgress, isNull);
      expect(view.content.personalized['detail1'], '');
      expect(view.content.personalized['detail2'], '');
      expect(find.text('Chọn ảnh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'switching sections preserves details, copy, crop and output settings in the video request',
    (tester) async {
      final template = templates.firstWhere(
        (t) => t.kind == KeepsakeKind.video,
      );
      final journal = mockJournal();
      final photos = journal.media
          .where((m) => !m.isVideo)
          .take(template.photosMax)
          .map((m) => m.id)
          .toList();
      final jobs = FakeKeepsakeJobs();
      await pumpRouted(
        tester,
        PremiumKeepsakeEditor(
          template: template,
          babyId: teddyId,
          mediaIds: photos,
        ),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(
            keepsakes: (cards: true, videos: true),
            keepsakeCatalog: KeepsakeCatalog(templates),
            journal: journal,
          ),
          keepsakeJobRepositoryProvider.overrideWithValue(jobs),
        ],
      );
      await tester.enterText(
        find.byKey(const ValueKey('p48-input-babyName')),
        'An',
      );
      tester.testTextInput.hide();
      await tester.tap(find.byTooltip('Xoá giá trị'));
      await tester.tap(find.byKey(const ValueKey('p48-optional-details')));
      await tester.pumpAndSettle();
      final place = find.byKey(const ValueKey('p48-input-placeName'));
      await tester.ensureVisible(place);
      await tester.enterText(place, 'Huế');
      tester.testTextInput.hide();
      await section(tester, 1);
      final copyKey = template.personalization!.copy
          .firstWhere((c) => c.editable)
          .key;
      await tester.enterText(find.byKey(ValueKey('vi:$copyKey')), 'Chào An');
      tester.testTextInput.hide();
      await section(tester, 2);
      await tester.tap(find.byKey(const ValueKey('premium-crop-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lấp đầy khung').last);
      await tester.pumpAndSettle();
      await section(tester, 0);
      expect(
        tester
            .widget<ClTextField>(
              find.byKey(const ValueKey('p48-input-babyName')),
            )
            .controller!
            .text,
        'An',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('p48-input-birthDate')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.widget<ClTextField>(place).controller!.text, 'Huế');
      await tester.tap(find.byTooltip('Tuỳ chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<KeepsakeFormat>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4:5').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      await section(tester, 1);
      await tester.enterText(
        find.byKey(ValueKey('en:$copyKey')),
        'Welcome, An',
      );
      tester.testTextInput.hide();
      await section(tester, 0);
      await tester.tap(find.text('Tạo video'));
      await tester.pumpAndSettle();
      final request = jobs.requests.single;
      final presentation = request['presentation'] as Map;
      expect(request['mediaIds'], photos);
      expect(request['locale'], 'en');
      expect(request['audience'], 'parents');
      expect(presentation['values'], containsPair('babyName', 'An'));
      expect(presentation['values'], containsPair('birthDate', ''));
      expect(presentation['values'], containsPair('placeName', 'Huế'));
      expect(presentation['overrides'], containsPair(copyKey, 'Welcome, An'));
      expect(presentation['format'], 'portrait');
      expect(presentation['reducedMotion'], false);
      expect(
        (presentation['crops'] as List).first,
        containsPair('fit', 'cover'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('validation links open the section that can resolve the issue', (
    tester,
  ) async {
    final t = templates.first;
    await pumpScreen(
      tester,
      PremiumKeepsakeEditor(template: t, babyId: teddyId),
      catalog: KeepsakeCatalog(templates),
    );
    await tester.tap(find.text('Chọn thêm 1 ảnh để lưu thiệp'));
    await tester.pumpAndSettle();
    expect(find.byType(KeepsakeCardView), findsOneWidget);
    await section(tester, 0);
    expect(find.byType(KeepsakeCardView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> section(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey('p48-section-$index')));
  await tester.pumpAndSettle();
}
