import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/premium_keepsake_editor.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/family_fixtures.dart';
import '../../helpers/care_fixtures.dart';
import '../../helpers/keepsake_fixtures.dart';
import '../../helpers/memory_fixtures.dart';
import '../../helpers/router_pump.dart';

// Explicit visual review export, outside production goldens. Synthetic media only.
// PERSONALIZED_REVIEW=after flutter test test/design_explorations/personalized_editor/editor_review_test.dart
// before / A / B captures are immutable historical evidence from their source snapshots.
void main() {
  WidgetsApp.debugAllowBannerOverride = false;
  tearDownAll(() => WidgetsApp.debugAllowBannerOverride = true);
  final phase = Platform.environment['PERSONALIZED_REVIEW'];
  if (phase != null && phase != 'after') {
    throw ArgumentError(
      'Only after can be exported; baseline and A/B captures are historical.',
    );
  }
  final catalog = seedCatalog();
  final seed = mockJournal();
  final journal = seed;
  final photos = [
    for (final m in journal.media)
      if (!m.isVideo) m.id,
  ].take(6).toList();
  final raw =
      jsonDecode(
            File(
              '../../packages/contracts/test/vectors/premium48.json',
            ).readAsStringSync(),
          )
          as Map;
  final premium = (raw['templates'] as List)
      .map(KeepsakeTemplate.fromJson)
      .nonNulls
      .first;
  final premiumVideo = (raw['templates'] as List)
      .map(KeepsakeTemplate.fromJson)
      .nonNulls
      .firstWhere((t) => t.kind == KeepsakeKind.video);
  final states = [
    'details',
    'wording',
    'media',
    'optional',
    'settings',
    'keyboard',
    'crop',
  ];
  for (final video in [false, true]) {
    for (final state in states.where((s) => video || s != 'crop')) {
      if (phase != null && phase != 'after' && state != 'details') continue;
      final template = video ? premiumVideo : premium;
      final name = '${video ? 'video' : 'card'}_$state';
      for (final scale in [1.0, 2.0]) {
        for (final palette in ClPalette.values) {
          for (final lang in ['vi', 'en']) {
            testWidgets('$name ${palette.name} $lang ${scale}x', (
              tester,
            ) async {
              mediaBytes = FakeMediaBytes();
              final boundary = GlobalKey();
              await pumpRouted(
                tester,
                Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      viewInsets: state == 'keyboard'
                          ? const EdgeInsets.only(bottom: 300)
                          : EdgeInsets.zero,
                    ),
                    child: RepaintBoundary(
                      key: boundary,
                      child: PremiumKeepsakeEditor(
                        template: template,
                        babyId: teddyId,
                        mediaIds: video
                            ? photos.take(template.photosMax).toList()
                            : const [],
                      ),
                    ),
                  ),
                ),
                locale: Locale(lang),
                palette: palette,
                overrides: [
                  ...careOverrides(),
                  ...memoryOverrides(
                    keepsakes: (cards: true, videos: true),
                    keepsakeCatalog: catalog,
                    journal: journal,
                  ),
                  keepsakeAssetImageProvider.overrideWithValue(
                    (asset) => const StorageImage('keepsake/peach'),
                  ),
                ],
              );
              if (state == 'wording' || state == 'keyboard') {
                await tester.tap(find.byKey(const ValueKey('p48-section-1')));
                await tester.pumpAndSettle();
              }
              if (state == 'media' || state == 'crop') {
                await tester.tap(find.byKey(const ValueKey('p48-section-2')));
                await tester.pumpAndSettle();
              }
              if (state == 'crop') {
                await tester.tap(find.byKey(const ValueKey('premium-crop-0')));
                await tester.pumpAndSettle();
              }
              if (state == 'optional') {
                final optional = find.byKey(
                  const ValueKey('p48-optional-details'),
                );
                await tester.ensureVisible(optional);
                await tester.pumpAndSettle();
                await tester.tap(
                  find.text(lang == 'vi' ? 'Thêm chi tiết' : 'More details'),
                );
                await tester.pumpAndSettle();
                expect(
                  find.byKey(const ValueKey('p48-input-birthTime')),
                  findsOneWidget,
                );
                final place = find.byKey(const ValueKey('p48-input-placeName'));
                await tester.ensureVisible(place);
                await tester.pumpAndSettle();
                expect(place.hitTestable(), findsOneWidget);
              }
              if (state == 'settings') {
                await tester.tap(
                  find.byTooltip(lang == 'vi' ? 'Tuỳ chỉnh' : 'Options'),
                );
                await tester.pumpAndSettle();
              }
              if (state == 'keyboard') {
                final field = find.byType(ClTextField).first;
                await tester.scrollUntilVisible(
                  field,
                  100,
                  scrollable: find.byType(Scrollable).first,
                );
                await tester.ensureVisible(field);
                await tester.enterText(
                  field,
                  lang == 'vi' ? 'Chào con yêu' : 'Hello, little one',
                );
                await tester.pumpAndSettle();
                final action = find.byWidgetPredicate(
                  (w) =>
                      w is ClButton &&
                      w.label ==
                          (video
                              ? (lang == 'vi' ? 'Tạo video' : 'Make the video')
                              : (lang == 'vi' ? 'Lưu thiệp' : 'Save card')),
                );
                expect(action.hitTestable(), findsOneWidget);
                expect(
                  tester.getBottomRight(action).dy,
                  lessThanOrEqualTo(512),
                  reason: 'Action stays above the 300px keyboard',
                );
              }
              final errors = <String>[];
              void collect() {
                Object? e;
                while ((e = tester.takeException()) != null) {
                  errors.add(e.toString());
                }
              }

              collect();
              for (var round = 0; round < 2; round++) {
                final images = tester
                    .widgetList<Image>(find.byType(Image))
                    .toList();
                await tester.runAsync(() async {
                  for (final image in images) {
                    await precacheImage(
                      image.image,
                      tester.element(find.byWidget(image).first),
                    );
                  }
                });
                await tester.pumpAndSettle();
              }
              collect();
              if (phase != null) {
                final path =
                    '../../docs/design/reviews/assets/2026-10-26-personalized-editor/$phase/${name}_${palette.name}_${lang}_${scale}x';
                await tester.runAsync(() async {
                  RenderObject render = tester
                      .element(find.byType(MaterialApp))
                      .renderObject!;
                  while (!render.isRepaintBoundary) {
                    render = render.parent!;
                  }
                  final image = await (render.debugLayer! as OffsetLayer)
                      .toImage(render.paintBounds);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  File('$path.png')
                    ..parent.createSync(recursive: true)
                    ..writeAsBytesSync(bytes!.buffer.asUint8List());
                  image.dispose();
                  final log = File('$path.txt');
                  if (errors.isNotEmpty) {
                    log.writeAsStringSync(errors.join('\n'));
                  } else if (log.existsSync()) {
                    log.deleteSync();
                  }
                });
              }
              if (phase != 'before') {
                expect(
                  errors,
                  isEmpty,
                  reason: 'No layout errors at ${scale}x',
                );
              }
            });
          }
        }
      }
    }
  }
}
