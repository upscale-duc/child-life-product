import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_personalization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// Optional visual exports use the exact Flutter card renderer, bundled fonts and cleared samples.
// P48_RENDER=1 flutter test test/render/premium48_review_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<KeepsakeTemplate> templates;
  late Map<String, dynamic> fixtures;
  setUpAll(() async {
    final collections = [
      for (final filename in [
        'premium48.json',
        'premium48-phase2.json',
        'premium48-phase3.json',
        'premium48-phase4.json',
        'premium48-phase5.json',
        'premium48-phase6.json',
        for (var p = 7; p <= 12; p++) 'premium48-phase$p.json',
      ])
        jsonDecode(
              File(
                '../../packages/contracts/test/vectors/$filename',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
    ];
    fixtures = {
      'templates': [for (final c in collections) ...c['templates'] as List],
      'cases': [for (final c in collections) ...c['cases'] as List],
    };
    templates = (fixtures['templates'] as List)
        .map(KeepsakeTemplate.fromJson)
        .nonNulls
        .toList();
    await initializeDateFormatting('vi');
    await initializeDateFormatting('en');
    for (final face in [
      ('Lora', ['Lora-Regular', 'Lora-SemiBold']),
      (
        'Be Vietnam Pro Keepsake',
        ['BeVietnamPro-Regular', 'BeVietnamPro-SemiBold', 'BeVietnamPro-Bold'],
      ),
    ]) {
      final loader = FontLoader(face.$1);
      for (final file in face.$2) {
        loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
      }
      await loader.load();
    }
  });

  test(
    'same authored fields, first confirmation and formatted dates as the server',
    () {
      for (final raw in fixtures['cases'] as List) {
        final c = raw as Map<String, dynamic>;
        final template = templates.singleWhere((t) => t.id == c['id']);
        final actual = resolveKeepsakeCopy(
          template.personalization!,
          (c['values'] as Map).cast<String, String>(),
          Locale(c['locale'] as String),
        );
        expect(actual, c['expected'], reason: '${c['id']}/${c['locale']}');
      }
    },
  );

  test('phase 4 derives UTC days and leaves unknown dates uncounted', () {
    final t = templates.singleWhere((t) => t.id == 'card_premium48_08');
    for (final sample in [
      ('2024-02-28', '2024-02-29', '1', 'day'),
      ('2024-02-28', '2024-03-01', '2', 'days'),
      ('2026-10-01', '2026-10-01', '0', 'days'),
    ]) {
      final copy = resolveKeepsakeCopy(t.personalization!, {
        'babyName': 'An',
        'thenDate': sample.$1,
        'nowDate': sample.$2,
      }, const Locale('en'));
      expect(copy['detail1'], sample.$3);
      expect(copy['detail2'], sample.$4);
    }
    final missing = resolveKeepsakeCopy(t.personalization!, {
      'babyName': 'An',
      'thenDate': '2026-09-01',
    }, const Locale('en'));
    expect(missing['detail1'], '');
    expect(missing['photoLabel0'], 'Then');
    expect(missing['photoLabel1'], 'Now');
  });

  test(
    'birthday letter paragraphs stay inside their authored bounds with a signature',
    () {
      final t = templates.singleWhere((t) => t.id == 'card_premium48_23');
      final copy = resolveKeepsakeCopy(t.personalization!, {
        'babyName': 'Oscar',
      }, const Locale('en'));
      final content = CardContent(
        occasion: '',
        name: 'Oscar',
        date: '',
        quote: '',
        personalized: copy,
      );
      for (final format in [KeepsakeFormat.portrait, KeepsakeFormat.story]) {
        final before = t.layouts[format]!
            .whereType<KeepsakeTextLayer>()
            .singleWhere((l) => l.field == 'detail0');
        final after = premiumCardLayers(t, format, content)
            .whereType<KeepsakeTextLayer>()
            .singleWhere((l) => l.field == 'detail0');
        expect(after.rect.x, before.rect.x);
        expect(after.rect.w, before.rect.w);
      }
    },
  );

  test('each occasion shows exactly its two ornaments in either language', () {
    final t = templates.singleWhere((t) => t.id == 'card_premium48_20');
    for (final theme in ['neutral', 'tet', 'christmas']) {
      for (final locale in [const Locale('vi'), const Locale('en')]) {
        final copy = resolveKeepsakeCopy(t.personalization!, {
          'babyName': 'Chloe',
          'occasionName': 'Tết',
          'celebrationTheme': theme,
        }, locale);
        final layers = premiumCardLayers(
          t,
          KeepsakeFormat.portrait,
          CardContent(
            occasion: '',
            name: 'Chloe',
            date: '',
            quote: '',
            personalized: copy,
          ),
        );
        final ornaments = layers
            .whereType<KeepsakeImage>()
            .where((l) => l.when != null)
            .toList();
        expect(ornaments.length, 2);
        expect(ornaments.every((l) => l.when!.equals == theme), isTrue);
      }
    }
  });

  testWidgets(
    'all premium cards fit VI/EN in both ratios; long names never silently clip',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final render = Platform.environment['P48_RENDER'] == '1';
      for (final t in templates.where((t) => t.kind == KeepsakeKind.card)) {
        final number = int.parse(t.id.substring(t.id.length - 2));
        final phase = (number + 1) ~/ 2;
        final out = Directory('../../artifacts/premium48-phase$phase');
        final export =
            render && (Platform.environment['P48_PHASE'] ?? '1') == '$phase';
        if (export) out.createSync(recursive: true);
        for (final locale in [const Locale('vi'), const Locale('en')]) {
          for (final format in [
            KeepsakeFormat.portrait,
            KeepsakeFormat.story,
          ]) {
            for (final long in [false, true]) {
              final finalDemos = phase >= 7
                  ? (jsonDecode(
                              File(
                                '../../design/keepsake-templates/premium48-phase$phase.json',
                              ).readAsStringSync(),
                            )
                            as Map)['demos']
                        as Map
                  : null;
              final values = {
                for (final f in t.personalization!.fields)
                  f.key: switch (f.key) {
                    'babyName' =>
                      long
                          ? 'Nguyễn Hoàng Bảo An Minh Khôi'
                          : (phase == 6
                                ? (number == 12 ? 'Emma' : 'Oliver')
                                : phase == 5
                                ? (number == 10 ? 'Lily' : 'Noah')
                                : 'Bảo An'),
                    'birthDate' => '2026-09-17',
                    'birthTime' => '09:35',
                    'placeName' => 'Đà Nẵng',
                    'narratorName' => 'Linh',
                    'momentDate' =>
                      phase >= 5
                          ? ''
                          : phase == 2
                          ? '2026-09-20'
                          : '2026-09-18',
                    'favoriteThing' =>
                      locale.languageCode == 'vi' ? 'những cái ôm' : 'cuddles',
                    'littleDetail' =>
                      locale.languageCode == 'vi'
                          ? 'bàn tay bé xíu'
                          : 'tiny fingers',
                    'milestoneName' =>
                      locale.languageCode == 'vi'
                          ? 'những bước nhỏ'
                          : 'little steps',
                    'momentPhotoConfirmed' => 'false',
                    'objectPhotoConfirmed' => 'false',
                    'companionConfirmed' => 'false',
                    'monthNumber' => '01',
                    'discovery' =>
                      phase == 6
                          ? ''
                          : locale.languageCode == 'vi'
                          ? 'bàn tay bé xíu'
                          : 'tiny hands',
                    'thenDate' => '',
                    'nowDate' => '',
                    'memoryLine' =>
                      phase == 4
                          ? (locale.languageCode == 'vi'
                                ? 'một buổi chiều bên nhau'
                                : 'an afternoon together')
                          : locale.languageCode == 'vi'
                          ? 'chơi cùng mẹ'
                          : 'playing together',
                    'itemName' =>
                      locale.languageCode == 'vi'
                          ? 'áo cotton'
                          : 'cotton outfit',
                    'outgrownConfirmed' => 'false',
                    'reactionConfirmed' => 'false',
                    'storedDate' => '',
                    'firstConfirmed' => 'false',
                    _ => '',
                  },
                if (finalDemos != null)
                  ...(finalDemos[t.id][locale.languageCode] as Map)
                      .cast<String, String>(),
                if (long) 'babyName': 'Nguyễn Hoàng Bảo An Minh Khôi',
              };
              final copy = resolveKeepsakeCopy(
                t.personalization!,
                values,
                locale,
              );
              final key = GlobalKey();
              const samples = [
                '02-WWBJ9TUT2B.jpg',
                '04-8J6SO4AGN0.jpg',
                '06-VOSXS4YBX2.jpg',
              ];
              final phase2Samples =
                  (jsonDecode(
                            File(
                              '../../design/sample-photos/premium48-phase${phase >= 2 ? phase : 2}-licence.json',
                            ).readAsStringSync(),
                          )
                          as List)
                      .cast<Map<String, dynamic>>();
              final selected = number == 19
                  ? [1, 2, 0]
                  : phase >= 7
                  ? [
                      for (var i = 0; i < phase2Samples.length; i++)
                        if ((phase2Samples[i]['templates'] as List).contains(
                          'C$number',
                        ))
                          i,
                    ].take(t.photosMax).toList()
                  : phase == 6
                  ? (number == 11 ? [0, 1, 3] : [7, 6])
                  : phase == 5
                  ? (number == 9 ? [3, 0, 2] : [6])
                  : phase == 4
                  ? (number == 7 ? [0, 2, 4] : [5, 6])
                  : phase == 3
                  ? (number == 5 ? [0] : [5])
                  : number == 3
                  ? [0, 4]
                  : [5, 6, 9];
              final photos = [
                for (var slot = 0; slot < t.photosMax; slot++)
                  if (export)
                    FileImage(
                      File(
                        phase >= 2
                            ? '/tmp/child-life-p48-phase$phase-photos/${phase2Samples[selected[slot]]['file']}'
                            : '/tmp/child-life-p48-photos/${number == 2 ? '18-BNAI6KA86B.jpg' : samples[slot % samples.length]}',
                      ),
                    ),
              ];
              final content = CardContent(
                occasion: '',
                name: values['babyName']!,
                date: '',
                quote: '',
                personalized: copy,
                photos: [
                  for (final photo in photos)
                    CardPhoto(
                      photo,
                      align: number == 19 && photos.indexOf(photo) == 2
                          ? const Alignment(0, -0.6)
                          : number == 22 &&
                                [0, 9].contains(photos.indexOf(photo))
                          ? Alignment.topCenter
                          : phase >= 7 || phase == 6 && number == 12
                          ? Alignment.center
                          : phase == 4 && number == 8
                          ? (photos.indexOf(photo) == 0
                                ? Alignment.bottomCenter
                                : Alignment.centerRight)
                          : Alignment.topCenter,
                    ),
                ],
              );
              if (phase >= 3 && !long) {
                final neutral = resolveKeepsakeCopy(t.personalization!, {
                  'babyName': 'Bảo An',
                  if (phase >= 7 && number == 20) ...{
                    'occasionName': 'Christmas',
                    'celebrationTheme': 'christmas',
                  },
                  if (phase == 6 && number == 11)
                    'milestoneName': locale.languageCode == 'vi'
                        ? 'những bước nhỏ'
                        : 'little steps',
                }, locale);
                expect(
                  premiumCardFits(
                    t,
                    format,
                    CardContent(
                      occasion: '',
                      name: 'Bảo An',
                      date: '',
                      quote: '',
                      personalized: neutral,
                    ),
                  ),
                  isTrue,
                  reason:
                      'neutral ${t.id}/${locale.languageCode}/${format.name}: ${t.layouts[format]!.whereType<KeepsakeTextLayer>().where((l) => neutral[l.field]?.isNotEmpty == true && !premiumTextFit(neutral[l.field]!, l, Size(1080, 1080 / format.aspect)).fits).map((l) => l.field).join(', ')}',
                );
              }
              if (phase == 4 && number == 8 && !long) {
                final dated = resolveKeepsakeCopy(t.personalization!, {
                  'babyName': 'Bảo An',
                  'thenDate': '2026-07-01',
                  'nowDate': '2026-10-01',
                }, locale);
                expect(
                  premiumCardFits(
                    t,
                    format,
                    CardContent(
                      occasion: '',
                      name: 'Bảo An',
                      date: '',
                      quote: '',
                      personalized: dated,
                    ),
                  ),
                  isTrue,
                  reason: 'dated ${t.id}/${locale.languageCode}/${format.name}',
                );
              }
              if (phase == 5 && !long) {
                final confirmed = resolveKeepsakeCopy(t.personalization!, {
                  'babyName': number == 10 ? 'Lily' : 'Noah',
                  if (number == 9) ...{
                    'itemName': locale.languageCode == 'vi'
                        ? 'áo cotton'
                        : 'cotton outfit',
                    'outgrownConfirmed': 'true',
                    'storedDate': '2026-10-20',
                  },
                  if (number == 10) 'momentDate': '2026-10-20',
                }, locale);
                expect(
                  premiumCardFits(
                    t,
                    format,
                    CardContent(
                      occasion: '',
                      name: number == 10 ? 'Lily' : 'Noah',
                      date: '',
                      quote: '',
                      personalized: confirmed,
                    ),
                  ),
                  isTrue,
                  reason:
                      'confirmed ${t.id}/${locale.languageCode}/${format.name}',
                );
              }
              final fits = premiumCardFits(t, format, content);
              // Long text may be rejected with an actionable editor message, never silently truncated.
              if (!long) {
                expect(
                  fits,
                  isTrue,
                  reason: '${t.id}/${locale.languageCode}/${format.name}',
                );
              }
              if (!export || long) continue;
              final assetBytes = {
                for (final a in t.assets(format))
                  a: File('${out.path}/$a').readAsBytesSync(),
              };
              await tester.pumpWidget(MaterialApp(home: SizedBox(key: key)));
              await tester.runAsync(() async {
                for (final photo in photos) {
                  await precacheImage(photo, key.currentContext!);
                }
                for (final bytes in assetBytes.values) {
                  await precacheImage(MemoryImage(bytes), key.currentContext!);
                }
                await precacheKeepsakeBrand();
              });
              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    keepsakeAssetImageProvider.overrideWithValue(
                      (a) => MemoryImage(assetBytes[a]!),
                    ),
                  ],
                  child: MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: RepaintBoundary(
                          key: key,
                          child: KeepsakeCardView(
                            template: t,
                            format: format,
                            content: content,
                            width: 1080,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage(
                  pixelRatio:
                      (format == KeepsakeFormat.portrait ? 2400 : 2160) / 1080,
                );
                final data = (await image.toByteData(
                  format: ui.ImageByteFormat.png,
                ))!;
                File(
                  '${out.path}/C${t.id.substring(t.id.length - 2)}-${locale.languageCode}-${format.name}.png',
                ).writeAsBytesSync(data.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
    },
  );
}
