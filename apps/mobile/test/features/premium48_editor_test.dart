import 'dart:convert';
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
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tết · hoa và phong bao').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(KeepsakeCardView),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
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
      expect(
        tester
            .widget<KeepsakeCardView>(find.byType(KeepsakeCardView))
            .content
            .field('headline'),
        'MÓN ĐỒ MUỐN GIỮ',
      );
      final confirmation = find.text('Tôi xác nhận món đồ đã không còn vừa bé');
      await tester.scrollUntilVisible(
        confirmation,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(confirmation);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(KeepsakeCardView),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
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
        (w) => w is TextField && w.decoration?.hintText == 'những bước nhỏ',
      );
      await tester.scrollUntilVisible(
        input,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
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
      await tester.scrollUntilVisible(
        find.byType(KeepsakeCardView),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
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
    await tester.scrollUntilVisible(
      find.byType(KeepsakeCardView),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
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
        (w) => w is TextField && w.decoration?.hintText == 'những cái ôm',
      );
      await tester.scrollUntilVisible(
        favorite,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final favoriteController = tester.widget<TextField>(favorite).controller!;
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
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'một biểu cảm rất riêng',
      );
      await tester.scrollUntilVisible(
        detail,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<TextField>(detail).controller!.text,
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
      expect(find.text('Một cái ôm muốn nhớ.'), findsWidgets);
      expect(find.text('Our first embrace.'), findsNothing);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('An embrace to remember.'), findsWidgets);
      expect(find.text('Ngôn ngữ thành phẩm'), findsOneWidget);
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
}
