import 'dart:convert';
import 'dart:io';

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/keepsakes/keepsake_card_content.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_nudges.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/story_fixtures.dart';
import '../helpers/memory_fixtures.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  KeepsakeCatalog? catalog,
  ClPalette palette = ClPalette.light,
}) async {
  tester.view.physicalSize = const Size(375 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...keepsakeOverrides(catalog: catalog),
      ],
      child: MaterialApp(
        theme: buildClTheme(palette),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  group('catalog (portal-managed, D-068 #7)', () {
    test('the seed reads as MM10’s four cards, in order, in three formats', () {
      final c = seedCatalog();
      expect(c.cards.map((t) => t.name.vi), [
        'Tròn trịa',
        'Toàn ảnh',
        'Hồng phấn',
        'Đêm sao',
      ]);
      expect(c.cards.map((t) => t.premium), [false, false, true, true]);
      expect(c.cards.first.formats, KeepsakeFormat.values);
      expect(c.videos.map((t) => t.composition), [
        'FirstMonth',
        'FirstWeek',
        'HundredDays',
        'LittleMoments',
      ]);
      // "Lời nhắn" only where a layer shows the quote.
      expect(c.cards[0].shows(KeepsakeFormat.portrait, 'quote'), isTrue);
      expect(c.cards[1].shows(KeepsakeFormat.portrait, 'quote'), isFalse);
    });

    test(
      'a layer this app cannot draw hides that format; drafts are never shown',
      () {
        final raw =
            jsonDecode(
                  File('test/helpers/keepsake_seed.json').readAsStringSync(),
                )
                as Map;
        final round = Map<String, Object?>.from(
          (raw['templates'] as List).first as Map,
        );
        final layouts = Map<String, Object?>.from(round['layouts']! as Map);
        layouts['square'] = [
          ...(layouts['square']! as List),
          {
            'type': 'lottie',
            'rect': {'x': 0, 'y': 0, 'w': 1, 'h': 1},
          },
        ];
        final t = KeepsakeTemplate.fromJson({...round, 'layouts': layouts})!;
        expect(t.formats, [KeepsakeFormat.portrait, KeepsakeFormat.story]);
        expect(
          KeepsakeTemplate.fromJson({...round, 'status': 'draft'}),
          isNull,
        );
        expect(
          KeepsakeTemplate.fromJson({...round, 'layouts': <String, Object?>{}}),
          isNull,
        );
      },
    );

    test(
      'the portal decides Cao cấp: open, hidden, subscribers, or an unknown mode = hidden',
      () {
        final raw =
            jsonDecode(
                  File('test/helpers/keepsake_seed.json').readAsStringSync(),
                )
                as Map;
        KeepsakeCatalog withPremium(Object? premium) =>
            KeepsakeCatalog.fromJson({...raw, 'premium': premium});
        expect(
          withPremium({'access': 'everyone', 'badges': true}).cards,
          hasLength(4),
        );
        final hidden = withPremium({'access': 'hidden', 'badges': false});
        expect(hidden.cards.map((t) => t.name.vi), ['Tròn trịa', 'Toàn ảnh']);
        expect(hidden.badges, isFalse);
        // Q1: subscribers keeps Cao cấp listed (gated when picked, MO02); a newer unknown
        // mode still reads as hidden.
        expect(withPremium({'access': 'subscribers'}).cards, hasLength(4));
        expect(withPremium({'access': 'later-mode'}).cards, hasLength(2));
        // A catalog published before the setting existed: the beta default.
        expect(withPremium(null).cards, hasLength(4));
      },
    );

    test('assets come from content/keepsakes, never from the app bundle', () {
      expect(
        keepsakeAssetPath('frame-pink_1a2b3c4d.webp'),
        'content/keepsakes/frame-pink_1a2b3c4d.webp',
      );
    });
  });

  group('occasions (MM10 "Chọn dịp")', () {
    final dob = DateTime(2026, 9, 17);

    test('age occasions count from the date of birth', () {
      expect(Occasion.d7.dateFor(dob, const []), DateTime(2026, 9, 24));
      expect(Occasion.m1.dateFor(dob, const []), DateTime(2026, 10, 17));
      expect(Occasion.d100.dateFor(dob, const []), DateTime(2026, 12, 26));
      expect(Occasion.y1.dateFor(dob, const []), DateTime(2027, 9, 17));
      // 31 Jan + 1 month is the end of February, not March.
      expect(
        Occasion.m1.dateFor(DateTime(2027, 1, 31), const []),
        DateTime(2027, 2, 28),
      );
    });

    test('first-time occasions take the newest tagged memory, else none', () {
      final tagged = [
        MilestoneRef(
          id: 'p_first_smile',
          name: 'x',
          date: DateTime(2026, 10, 1),
        ),
        MilestoneRef(
          id: 'p_first_smile',
          name: 'x',
          date: DateTime(2026, 10, 5),
        ),
        MilestoneRef(id: 'p_crawls', name: 'x', date: DateTime(2026, 10, 9)),
      ];
      expect(Occasion.firstSmile.dateFor(dob, tagged), DateTime(2026, 10, 5));
      expect(Occasion.firstSteps.dateFor(dob, tagged), isNull);
    });

    test('"Gợi ý" is the age occasion closest to today', () {
      expect(suggestedOccasion(dob, DateTime(2026, 10, 13)), Occasion.m1);
      expect(suggestedOccasion(dob, DateTime(2026, 9, 20)), Occasion.d7);
      expect(suggestedOccasion(dob, DateTime(2026, 12, 20)), Occasion.d100);
      // Past 100 ngày and far from 1 tuổi: the month just reached (Chapter 01 monthly cards).
      expect(suggestedOccasion(dob, DateTime(2027, 5, 1)), Occasion.m7);
      expect(suggestedOccasion(dob, DateTime(2027, 9, 5)), Occasion.y1);
    });
  });

  test(
    'a saved card: Chỉ ba mẹ, no notice, dated on the occasion, with its template',
    () {
      final t = seedCatalog().cards.first;
      CardDraft draft(DateTime date) => CardDraft(
        babyId: teddyId,
        occasion: Occasion.m1,
        date: date,
        format: KeepsakeFormat.square,
        template: t,
        palette: t.palette,
        quote: 'Một tháng yêu thương',
      );
      final r = cardMemoryRequest(
        draft: draft(DateTime(2026, 10, 17)),
        today: DateTime(2026, 10, 20, 8),
        milestoneName: 'Đầy tháng',
      );
      expect(r['audience'], 'parents');
      expect(r['notifyFamily'], false);
      expect(r['date'], '2026-10-17');
      expect(r['milestone'], {
        'id': 'p_one_month',
        'name': 'Đầy tháng',
        'date': '2026-10-17',
      });
      expect(r['generated'], {
        'kind': 'card',
        'templateId': 'card_round',
        'templateVersion': 1,
        'occasion': 'm1',
        'format': 'square',
      });
      // Made ahead of the day: dated today, never in the future.
      final ahead = cardMemoryRequest(
        draft: draft(DateTime(2026, 11, 14)),
        today: DateTime(2026, 10, 20, 8),
        milestoneName: 'Đầy tháng',
      );
      expect(ahead['date'], '2026-10-20');
    },
  );

  test(
    'a card’s photos are the baby’s own: never a card or video already made',
    () {
      final day = DateTime(2026, 10, 17);
      final card = mediaItem('mem_c', day, generated: 'card');
      final video = mediaItem('mem_v', day, generated: 'video');
      final photo = mediaItem('mem_p', DateTime(2026, 10, 1));
      expect(defaultPhotos([card, video, photo], Occasion.m1, day, count: 4), [
        photo,
      ]);
    },
  );

  group('MM10 · chọn mẫu', () {
    for (final palette in [ClPalette.light, ClPalette.nightCare]) {
      testWidgets(
        'occasions, formats and the four templates (${palette.name})',
        (tester) async {
          await pumpScreen(
            tester,
            const MilestoneCardScreen(),
            palette: palette,
          );
          expect(find.text('Thiệp cột mốc'), findsOneWidget);
          expect(find.text('Gợi ý'), findsOneWidget);
          expect(find.text('Sinh nhật 1 tuổi'), findsOneWidget);
          expect(find.text('Dọc 4:5'), findsOneWidget);
          for (final name in [
            'Tròn trịa',
            'Toàn ảnh',
            'Hồng phấn',
            'Đêm sao',
          ]) {
            expect(find.text(name), findsOneWidget);
          }
          // D-076 #9: basic templates carry no "Miễn phí" badge.
          expect(find.text('Miễn phí'), findsNothing);
          expect(find.text('Cao cấp'), findsNWidgets(2));
          // Teddy (17.9) turns one month on 17.10: the cards say so.
          expect(find.text('17.10.2026'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('a chosen occasion and format re-draw the previews', (
      tester,
    ) async {
      await pumpScreen(tester, const MilestoneCardScreen());
      await tester.ensureVisible(find.text('100 ngày').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('100 ngày').first);
      await tester.pumpAndSettle();
      expect(find.text('26.12.2026'), findsWidgets);
      await tester.tap(find.text('Vuông'));
      await tester.pumpAndSettle();
      expect(find.byType(KeepsakeCardView), findsNWidgets(4));
    });

    testWidgets('no badges when the portal turns them off', (tester) async {
      final raw =
          jsonDecode(File('test/helpers/keepsake_seed.json').readAsStringSync())
              as Map;
      await pumpScreen(
        tester,
        const MilestoneCardScreen(),
        catalog: KeepsakeCatalog.fromJson({
          ...raw,
          'premium': {'access': 'everyone', 'badges': false},
        }),
      );
      expect(find.text('Đêm sao'), findsOneWidget);
      expect(find.text('Miễn phí'), findsNothing);
      expect(find.text('Cao cấp'), findsNothing);
    });

    testWidgets('the dịp chips are one row that scrolls sideways, like Video', (
      tester,
    ) async {
      await pumpScreen(tester, const MilestoneCardScreen());
      final first = tester.getTopLeft(find.text('Chào đời'));
      final last = tester.getTopLeft(find.text('Bước đi đầu tiên'));
      expect(last.dy, first.dy);
    });

    testWidgets('empty catalog and beta off', (tester) async {
      await pumpScreen(
        tester,
        const MilestoneCardScreen(),
        catalog: const KeepsakeCatalog([]),
      );
      expect(find.text('Chưa có mẫu thiệp'), findsOneWidget);
    });
  });

  group('MM11 · chỉnh sửa', () {
    CardDraft draft() {
      final t = seedCatalog().cards.first;
      return CardDraft(
        babyId: teddyId,
        occasion: Occasion.m1,
        date: DateTime(2026, 10, 17),
        format: KeepsakeFormat.portrait,
        template: t,
        palette: t.palette,
        quote: 'Một tháng yêu thương',
        photos: [CardPhoto(MemoryImage(pngOf('mint')))],
      );
    }

    for (final palette in [ClPalette.light, ClPalette.nightCare]) {
      testWidgets('tools, layouts and the prefilled note (${palette.name})', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          MilestoneCardEditScreen(draft: draft()),
          palette: palette,
        );
        for (final t in ['Ảnh', 'Bố cục', 'Lời nhắn', 'Màu', 'Lưu thiệp']) {
          expect(find.text(t), findsOneWidget);
        }
        expect(find.text('Chạm ảnh để đổi · kéo để căn'), findsOneWidget);
        expect(
          find.text('Tên, tuổi và ngày được điền sẵn từ hồ sơ của Teddy'),
          findsOneWidget,
        );
        expect(find.text('“Một tháng yêu thương”'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Lời nhắn edits the card; Toàn ảnh has no message tool', (
      tester,
    ) async {
      await pumpScreen(tester, MilestoneCardEditScreen(draft: draft()));
      await tester.tap(find.text('Lời nhắn'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Con yêu của mẹ');
      await tester.pumpAndSettle();
      expect(find.text('“Con yêu của mẹ”'), findsWidgets);
      await tester.tap(find.text('Bố cục'));
      await tester.pumpAndSettle();
      // The second layout in the strip is "Toàn ảnh".
      await tester.tap(find.byType(KeepsakeCardView).at(2));
      await tester.pumpAndSettle();
      expect(find.text('Lời nhắn'), findsNothing);
    });

    testWidgets(
      'two photo slots (Then & Now): each slot is filled and moved on its own',
      (tester) async {
        // The seed's first card with a second photo slot beside the first.
        final json =
            jsonDecode(
                  File('test/helpers/keepsake_seed.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        final card = (json['templates'] as List)
            .cast<Map<String, dynamic>>()
            .first;
        card['photos'] = {'min': 2, 'max': 2};
        card['layouts'] = {
          'portrait': [
            {'type': 'background', 'color': 'background', 'asset': null},
            for (final (slot, x) in [(0, 0.06), (1, 0.51)])
              {
                'type': 'photo',
                'slot': slot,
                'rect': {'x': x, 'y': 0.16, 'w': 0.43, 'h': 0.54},
                'shape': 'rect',
                'radius': 0.02,
              },
          ],
        };
        final t = KeepsakeCatalog.fromJson(json).cards.first;
        expect(t.photoSlots(KeepsakeFormat.portrait), [0, 1]);
        final then = CardPhoto(MemoryImage(pngOf('mint')));
        await pumpScreen(
          tester,
          MilestoneCardEditScreen(
            draft: CardDraft(
              babyId: teddyId,
              occasion: Occasion.m1,
              date: DateTime(2026, 10, 17),
              format: KeepsakeFormat.portrait,
              template: t,
              palette: t.palette,
              quote: '',
              photos: [then],
            ),
          ),
        );
        CardContent content() => tester
            .widget<KeepsakeCardView>(find.byType(KeepsakeCardView).first)
            .content;
        ClButton save() =>
            tester.widget<ClButton>(find.widgetWithText(ClButton, 'Lưu thiệp'));
        // The second slot is required: not ready yet.
        expect(save().onPressed, isNull);
        // Tap the empty second slot, then a photo from the strip: it goes there.
        await tester.tap(find.text('Chọn ảnh'));
        await tester.pumpAndSettle();
        final strip = find.descendant(
          of: find.byType(ListView).last,
          matching: find.byType(ClPressable),
        );
        await tester.tap(strip.at(1));
        await tester.pumpAndSettle();
        expect(content().photos[0], same(then));
        expect(content().photos[1], isNotNull);
        expect(save().onPressed, isNotNull);
        // Dragging the second photo leaves the first where it was.
        final slot1 =
            tester.getCenter(find.byType(KeepsakeCardView).first) +
            const Offset(60, 0);
        await tester.dragFrom(slot1, const Offset(-30, 0));
        await tester.pumpAndSettle();
        expect(content().photos[0]!.align, Alignment.center);
        expect(content().photos[1]!.align, isNot(Alignment.center));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('no photo yet: Lưu thiệp waits for one', (tester) async {
      final d = draft();
      await pumpScreen(
        tester,
        MilestoneCardEditScreen(
          draft: CardDraft(
            babyId: d.babyId,
            occasion: d.occasion,
            date: d.date,
            format: d.format,
            template: d.template,
            palette: d.palette,
            quote: d.quote,
          ),
        ),
      );
      expect(find.text('Chọn ảnh'), findsWidgets);
    });
  });

  group('render fidelity', () {
    for (final format in KeepsakeFormat.values) {
      testWidgets(
        'the Chapter 01 cards draw in ${format.name} (two photos, new fields)',
        (tester) async {
          // design/keepsake-templates/chapter1.json (scripts/src/keepsakes-chapter1.ts).
          final json = jsonDecode(
            File(
              '../../design/keepsake-templates/chapter1.json',
            ).readAsStringSync(),
          );
          final cards = KeepsakeCatalog.fromJson(json).cards;
          expect(cards, hasLength(12));
          final l10n = lookupAppLocalizations(const Locale('vi'));
          final dob = DateTime(2026, 1, 14);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                keepsakeAssetImageProvider.overrideWithValue(
                  (asset) => MemoryImage(pngOf('peach')),
                ),
              ],
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  children: [
                    for (final t in cards)
                      KeepsakeCardView(
                        template: t,
                        format: format,
                        width: 160,
                        content: keepsakeCardContent(
                          l10n: l10n,
                          locale: const Locale('vi'),
                          template: t,
                          occasion: Occasion.m6,
                          name: 'Nguyễn Hoàng Bảo Ngọc Anh',
                          dob: dob,
                          date: DateTime(2026, 7, 14),
                          note:
                              'Một tháng qua, con dạy ba mẹ biết yêu thương nhiều hơn.',
                          photos: [
                            CardPhoto(MemoryImage(pngOf('mint')), takenAt: dob),
                            CardPhoto(
                              MemoryImage(pngOf('peach')),
                              takenAt: DateTime(2026, 7, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Then & Now labels each photo by age.
          if (format == KeepsakeFormat.portrait) {
            expect(find.text('Ngày đầu'), findsOneWidget);
            expect(find.text('Tháng 5'), findsOneWidget);
          }
        },
      );
    }

    for (final format in KeepsakeFormat.values) {
      testWidgets('every seed card draws in ${format.name} without overflow', (
        tester,
      ) async {
        final cards = seedCatalog().cards;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              keepsakeAssetImageProvider.overrideWithValue(
                (asset) => MemoryImage(pngOf('peach')),
              ),
            ],
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                children: [
                  for (final t in cards)
                    KeepsakeCardView(
                      template: t,
                      format: format,
                      width: 180,
                      content: CardContent(
                        occasion: 'Sinh nhật 1 tuổi của Bé Na',
                        name: 'Nguyễn Hoàng Bảo Ngọc Anh',
                        date: '14.11.2026',
                        quote:
                            'Một tháng qua, con dạy ba mẹ biết yêu thương nhiều hơn.',
                        photos: [CardPhoto(MemoryImage(pngOf('mint')))],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('entries in Kỷ niệm (MM01, MM02, MM15, MM17)', () {
    // MM03 takes MM01's place near an occasion; these cases are about MM01.
    final noNudges = <String, Object>{
      'keepsakes.dismissed': [
        for (final o in Occasion.values) '$teddyId|${o.wire}',
      ],
    };
    List<Override> on({bool cards = true, List<MediaItem> extra = const []}) {
      final j = mockJournal();
      return [
        ...careOverrides(),
        ...memoryOverrides(
          keepsakes: (cards: cards, videos: false),
          keepsakeCatalog: seedCatalog(),
          journal: (memories: j.memories, media: [...extra, ...j.media]),
        ),
      ];
    }

    testWidgets('Ảnh: "Tạo từ kỷ niệm" opens MM10; hidden outside the beta', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: on(),
        prefs: noNudges,
      );
      expect(find.text('Tạo từ kỷ niệm của Teddy'), findsOneWidget);
      expect(find.text('Ảnh PNG để chia sẻ'), findsOneWidget);
      await tester.tap(find.text('Thiệp cột mốc'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/memories/card');
    });

    testWidgets('outside the beta nothing shows', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: on(cards: false),
      );
      expect(find.text('Tạo từ kỷ niệm của Teddy'), findsNothing);
    });

    testWidgets('the + sheet has "Sáng tạo & tự động" with Thiệp cột mốc', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: on(),
      );
      await tester.tap(find.bySemanticsLabel('Thêm vào Kỷ niệm').first);
      await tester.pumpAndSettle();
      expect(find.text('SÁNG TẠO & TỰ ĐỘNG'), findsOneWidget);
      await tester.tap(find.text('Ảnh để chia sẻ'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/memories/card');
    });

    testWidgets(
      'a saved card: "Thiệp" in the grid, counted apart in its week',
      (tester) async {
        await pumpRouted(
          tester,
          const Scaffold(body: MemoriesScreen()),
          overrides: on(extra: [cardItem(DateTime(2026, 10, 8, 12))]),
        );
        expect(find.text('Thiệp'), findsWidgets);
        expect(find.textContaining('1 thiệp'), findsOneWidget);
      },
    );

    testWidgets('Câu chuyện: Thiệp cột mốc first, then today’s stories', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...on(extra: [cardItem(DateTime(2026, 10, 8, 12))]),
          ...storyOverrides(),
          startOn(MemoryTab.stories),
        ],
      );
      expect(find.text('1 thiệp'), findsOneWidget);
      expect(find.text('Câu chuyện của gia đình'), findsOneWidget);
      final cards = tester.getTopLeft(find.text('1 thiệp'));
      final stories = tester.getTopLeft(find.text('Câu chuyện của gia đình'));
      expect(cards.dy, lessThan(stories.dy));
    });
  });

  group('milestone nudges (MM03, D-068 #9)', () {
    final dob = DateTime(2026, 9, 17);
    MediaItem photo(DateTime at, {MilestoneRef? milestone}) =>
        mediaItem('mem1', at, milestone: milestone);
    NudgeBaby baby(List<MediaItem> media) =>
        NudgeBaby(babyId: teddyId, name: 'Teddy', dob: dob, media: media);

    test(
      'on the day: the next two age occasions at 09:00, none once carded',
      () {
        final plan = planNudges(
          babies: [baby(const [])],
          now: DateTime(2026, 10, 8, 10),
          usingSince: DateTime(2026, 10, 8),
          slots: const {},
          dismissed: const {},
        );
        final onTheDay = plan.nudges.where((n) => n.kind == NudgeKind.onTheDay);
        expect(onTheDay.map((n) => (n.occasion, n.fireAt)), [
          (Occasion.m1, DateTime(2026, 10, 17, 9)),
          (Occasion.d100, DateTime(2026, 12, 26, 9)),
        ]);
        final carded = planNudges(
          babies: [
            baby([cardItem(DateTime(2026, 10, 8, 12))]),
          ],
          now: DateTime(2026, 10, 8, 10),
          usingSince: DateTime(2026, 10, 8),
          slots: const {},
          dismissed: {'$teddyId|d100'},
        );
        expect(
          carded.nudges
              .where((n) => n.kind == NudgeKind.onTheDay)
              .map((n) => n.occasion),
          [Occasion.y1],
        );
      },
    );

    test(
      'looking back: after 7 days of use, only with photos, 3 days apart, slots kept',
      () {
        final media = [
          photo(DateTime(2026, 9, 25, 10)), // a day after 7 ngày
          photo(
            DateTime(2026, 10, 5, 9),
            milestone: MilestoneRef(
              id: 'p_first_smile',
              name: 'x',
              date: DateTime(2026, 10, 5),
            ),
          ),
        ];
        // Day 3 of use: nothing yet, but the slots are handed out from day 7.
        final early = planNudges(
          babies: [baby(media)],
          now: DateTime(2026, 10, 11, 10),
          usingSince: DateTime(2026, 10, 8),
          slots: const {},
          dismissed: const {},
        );
        final back = early.nudges
            .where((n) => n.kind == NudgeKind.lookBack)
            .toList();
        expect(back.map((n) => (n.occasion, n.fireAt)), [
          (Occasion.d7, DateTime(2026, 10, 15, 9)),
          (Occasion.firstSmile, DateTime(2026, 10, 18, 9)),
        ]);
        expect(back.first.photos, 1);
        // Opening the app again later keeps the same slots (they never drift).
        final later = planNudges(
          babies: [baby(media)],
          now: DateTime(2026, 10, 14, 10),
          usingSince: DateTime(2026, 10, 8),
          slots: early.newSlots,
          dismissed: const {},
        );
        expect(later.newSlots, isEmpty);
        expect(
          later.nudges
              .where((n) => n.kind == NudgeKind.lookBack)
              .map((n) => n.fireAt),
          [DateTime(2026, 10, 15, 9), DateTime(2026, 10, 18, 9)],
        );
        // Once a slot has passed, it is never scheduled again.
        final after = planNudges(
          babies: [baby(media)],
          now: DateTime(2026, 10, 16, 10),
          usingSince: DateTime(2026, 10, 8),
          slots: early.newSlots,
          dismissed: const {},
        );
        expect(
          after.nudges
              .where((n) => n.kind == NudgeKind.lookBack)
              .map((n) => n.occasion),
          [Occasion.firstSmile],
        );
        // No photos of an occasion: no look-back for it.
        final none = planNudges(
          babies: [baby(const [])],
          now: DateTime(2026, 10, 20, 10),
          usingSince: DateTime(2026, 1, 1),
          slots: const {},
          dismissed: const {},
        );
        expect(none.nudges.where((n) => n.kind == NudgeKind.lookBack), isEmpty);
      },
    );

    test(
      'notifications: the baby’s name, their own ids, a payload that opens MM10',
      () {
        final n = Nudge(
          babyId: teddyId,
          name: 'Teddy',
          occasion: Occasion.m1,
          kind: NudgeKind.onTheDay,
          fireAt: DateTime(2026, 10, 17, 9),
        );
        final l10n = lookupAppLocalizations(const Locale('vi'));
        final local = nudgeNotification(l10n, n);
        expect(local.title, 'Hôm nay Teddy tròn 1 tháng 🎂');
        expect(local.id & 0x40000000, 0x40000000);
        expect(nudgeOfPayload(local.payload), (teddyId, Occasion.m1));
        final back = nudgeNotification(
          l10n,
          Nudge(
            babyId: teddyId,
            name: 'Teddy',
            occasion: Occasion.d7,
            kind: NudgeKind.lookBack,
            fireAt: DateTime(2026, 10, 15, 9),
            photos: 4,
          ),
        );
        expect(back.title, 'Nhìn lại ngày Teddy tròn 7 ngày');
        expect(
          back.body,
          'Có 4 ảnh từ dịp này trong Kỷ niệm. Làm một tấm thiệp nhé?',
        );
        expect(back.id, isNot(local.id));
      },
    );

    testWidgets(
      'MM03 on Ảnh: Tạo thiệp opens the occasion; × moves to the next; Để sau hides',
      (tester) async {
        final j = mockJournal();
        final (visits, _) = await pumpRouted(
          tester,
          const Scaffold(body: MemoriesScreen()),
          overrides: [
            ...careOverrides(),
            ...memoryOverrides(
              keepsakes: (cards: true, videos: false),
              keepsakeCatalog: seedCatalog(),
              journal: j,
            ),
          ],
        );
        // 8 Oct: Teddy's first smile was tagged on 5 Oct (closest), 7 ngày was 24 Sep.
        expect(
          find.text('Lần đầu cười của Teddy! Làm một tấm thiệp kỷ niệm nhé.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Tạo thiệp'));
        await tester.pumpAndSettle();
        expect(visits.last.location, '/memories/card?occasion=first_smile');
        GoRouter.of(tester.element(find.text('stub'))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Đóng').first);
        await tester.pumpAndSettle();
        expect(
          find.text('Teddy vừa tròn 7 ngày! Lưu lại bằng một tấm thiệp nhé.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Để sau'));
        await tester.pumpAndSettle();
        expect(find.text('Tạo từ kỷ niệm của Teddy'), findsOneWidget);
      },
    );
  });
}
