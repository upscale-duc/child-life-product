import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
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
// KEEPSAKE_REVIEW=before|after flutter test test/design_explorations/keepsake_flows/flow_review_test.dart
void main() {
  final phase = Platform.environment['KEEPSAKE_REVIEW'];
  final catalog = seedCatalog();
  final seed = mockJournal();
  final output = mediaItem(
    'review-video',
    DateTime(2026, 10, 8, 9),
    video: true,
    durationMs: 45000,
    private: true,
  );
  final journal = (memories: seed.memories, media: [output, ...seed.media]);
  final photos = [
    for (final m in journal.media)
      if (!m.isVideo) m.id,
  ].take(6).toList();
  final card = catalog.cards.first;
  final draft = CardDraft(
    babyId: teddyId,
    occasion: Occasion.m1,
    date: DateTime(2026, 10, 17),
    format: KeepsakeFormat.portrait,
    template: card,
    palette: card.palette,
    quote: 'Một tháng yêu thương',
    photos: const [CardPhoto(StorageImage('photo/mint'))],
  );
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
  final cases = <String, Widget Function()>{
    if (phase != 'before') ...{
      'premium_video': () => PremiumKeepsakeEditor(
        template: premiumVideo,
        babyId: teddyId,
        mediaIds: photos.take(premiumVideo.photosMax).toList(),
      ),
      'card_templates': () => const KeepsakeKindsScreen(video: false),
      'video_templates': () => const KeepsakeKindsScreen(video: true),
      'card_keyboard': () => MilestoneCardEditScreen(draft: draft),
      'video_rendering': () =>
          MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
      'video_ready': () =>
          MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
      'video_failed': () =>
          MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
    },
    'card_edit': () => MilestoneCardEditScreen(draft: draft),
    'card_missing': () =>
        MilestoneCardEditScreen(draft: draft.copyWith(photos: [])),
    'video_photos': () => MemoryStoryPhotosScreen(
      draft: VideoDraft(
        babyId: teddyId,
        template: catalog.videos.first,
        mediaIds: photos,
        occasion: Occasion.m1,
      ),
    ),
    'video_finish': () => MemoryStoryFinishScreen(
      draft: VideoDraft(
        babyId: teddyId,
        template: catalog.videos.first,
        mediaIds: photos,
        occasion: Occasion.m1,
      ),
    ),
    'premium_card': () =>
        PremiumKeepsakeEditor(template: premium, babyId: teddyId),
  };
  for (final entry in cases.entries) {
    for (final scale in [1.0, 2.0]) {
      for (final palette in ClPalette.values) {
        for (final lang in ['vi', 'en']) {
          testWidgets('${entry.key} ${palette.name} $lang ${scale}x', (
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
                    viewInsets: entry.key == 'card_keyboard'
                        ? const EdgeInsets.only(bottom: 300)
                        : EdgeInsets.zero,
                  ),
                  child: RepaintBoundary(key: boundary, child: entry.value()),
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
                keepsakeJobRepositoryProvider.overrideWithValue(
                  FakeKeepsakeJobs()..put(
                    videoJob(
                      status: entry.key == 'video_ready'
                          ? KeepsakeJobStatus.completed
                          : entry.key == 'video_failed'
                          ? KeepsakeJobStatus.failed
                          : KeepsakeJobStatus.rendering,
                      error: entry.key == 'video_failed'
                          ? 'render-failed'
                          : null,
                      mediaIds: photos,
                      outputMediaId: entry.key == 'video_ready'
                          ? output.id
                          : null,
                    ),
                  ),
                ),
              ],
            );
            if (entry.key == 'card_keyboard') {
              await tester.ensureVisible(
                find.text(lang == 'vi' ? 'Lời nhắn' : 'Message'),
              );
              await tester.tap(
                find.text(lang == 'vi' ? 'Lời nhắn' : 'Message'),
              );
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.byType(EditableText));
              await tester.enterText(find.byType(EditableText), 'Love you');
              await tester.pumpAndSettle();
              final save = find.byWidgetPredicate(
                (w) =>
                    w is ClButton &&
                    w.label == (lang == 'vi' ? 'Lưu thiệp' : 'Save card'),
              );
              expect(
                save.hitTestable(),
                findsOneWidget,
                reason: 'Save stays reachable above a 300px keyboard',
              );
              expect(
                tester.getBottomRight(save).dy,
                lessThanOrEqualTo(512),
                reason: 'Primary action is above the simulated keyboard',
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
                  '../../docs/design/reviews/assets/2026-10-26-keepsake-flows/$phase/${entry.key}_${palette.name}_${lang}_${scale}x';
              await tester.runAsync(() async {
                final render =
                    boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await render.toImage();
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
              expect(errors, isEmpty, reason: 'No layout errors at ${scale}x');
            }
          });
        }
      }
    }
  }
}
