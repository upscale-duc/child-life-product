import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/story_fixtures.dart';

// Thiệp cột mốc (D-068): MM10 `530:9515`, MM11 `530:9663`, and every seed card in every format.
// Figma draws Night care only; Light comes from the same components (D-068 #6).
CardDraft _draft() {
  final t = seedCatalog().cards.first;
  return CardDraft(
    babyId: teddyId,
    occasion: Occasion.m1,
    date: DateTime(2026, 10, 17),
    format: KeepsakeFormat.portrait,
    template: t,
    palette: t.palette,
    quote: 'Một tháng yêu thương',
    photos: const [CardPhoto(StorageImage('photo/mint'))],
  );
}

Widget _cards() => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(8, 60, 8, 8),
    child: Column(
      children: [
        for (final format in KeepsakeFormat.values) ...[
          Wrap(
            spacing: 6,
            children: [
              for (final t in seedCatalog().cards)
                KeepsakeCardView(
                  template: t,
                  format: format,
                  width: 85,
                  content: CardContent(
                    occasion: '1 tháng',
                    name: 'Teddy',
                    date: '17.10.2026',
                    quote: 'Một tháng yêu thương',
                    photos: const [CardPhoto(StorageImage('photo/mint'))],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    ),
  ),
);

/// One journal for the whole file: each mockJournal() call makes new ids.
final _journal = mockJournal();
List<String> _photoIds() => [
  for (final m in _journal.media)
    if (!m.isVideo) m.id,
];

final _readyVideo = mediaItem(
  'mem_v',
  DateTime(2026, 10, 8, 9),
  video: true,
  durationMs: 45000,
  private: true,
);

List<Override> _video({KeepsakeJob? job, List<MediaItem> extra = const []}) {
  final j = _journal;
  return [
    ...memoryOverrides(
      keepsakes: (cards: true, videos: true),
      keepsakeCatalog: seedCatalog(),
      journal: (memories: j.memories, media: [...extra, ...j.media]),
    ),
    keepsakeAssetImageProvider.overrideWithValue(
      (asset) => const StorageImage('keepsake/peach'),
    ),
    keepsakeJobRepositoryProvider.overrideWithValue(
      FakeKeepsakeJobs()..put(job ?? videoJob()),
    ),
  ];
}

final _noNudges = <String, Object>{
  'keepsakes.dismissed': [
    for (final o in Occasion.values) '$teddyId|${o.wire}',
  ],
};

final _cases = <String, (Widget Function(), List<Override>, Map<String, Object>)>{
  'mm10_choose': (() => const MilestoneCardScreen(), const [], const {}),
  'mm11_edit': (
    () => MilestoneCardEditScreen(draft: _draft()),
    const [],
    const {},
  ),
  'cards_all_formats': (_cards, const [], const {}),
  // MM01: "Tạo từ kỷ niệm" on Ảnh, a saved card badged "Thiệp" and counted in its week.
  'mm01_photos': (
    () => const Scaffold(body: MemoriesScreen()),
    [
      ...memoryOverrides(
        keepsakes: (cards: true, videos: false),
        keepsakeCatalog: seedCatalog(),
        journal: (
          memories: mockJournal().memories,
          media: [cardItem(DateTime(2026, 10, 8, 12)), ...mockJournal().media],
        ),
      ),
    ],
    _noNudges,
  ),
  // MM15 with D-068 #2: Thiệp cột mốc first, then today's stories.
  'mm15_stories': (
    () => const Scaffold(body: MemoriesScreen()),
    [
      ...memoryOverrides(
        keepsakes: (cards: true, videos: false),
        keepsakeCatalog: seedCatalog(),
        journal: (
          memories: mockJournal().memories,
          media: [cardItem(DateTime(2026, 10, 8, 12)), ...mockJournal().media],
        ),
      ),
      ...storyOverrides(),
      startOn(MemoryTab.stories),
    ],
    _noNudges,
  ),
  // Video kỷ niệm: MM06 chọn ảnh, MM07 hoàn thiện, MM08 đang tạo, MM09 sẵn sàng, MM14 lỗi.
  'mm06_photos': (
    () => MemoryStoryPhotosScreen(
      draft: VideoDraft(
        babyId: teddyId,
        template: seedCatalog().videos.first,
        occasion: Occasion.m1,
        mediaIds: _photoIds().take(6).toList(),
      ),
    ),
    _video(),
    const {},
  ),
  'mm07_finish': (
    () => MemoryStoryFinishScreen(
      draft: VideoDraft(
        babyId: teddyId,
        template: seedCatalog().videos.first,
        occasion: Occasion.m1,
        mediaIds: _photoIds().take(6).toList(),
      ),
    ),
    _video(),
    const {},
  ),
  'mm08_rendering': (
    () => MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
    _video(job: videoJob(mediaIds: _photoIds().take(6).toList())),
    const {},
  ),
  'mm09_ready': (
    () => MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
    _video(
      job: videoJob(
        status: KeepsakeJobStatus.completed,
        progress: 100,
        mediaIds: _photoIds().take(6).toList(),
        outputMediaId: _readyVideo.id,
      ),
      extra: [_readyVideo],
    ),
    const {},
  ),
  'mm14_failed': (
    () => MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
    _video(
      job: videoJob(
        status: KeepsakeJobStatus.failed,
        error: 'render-failed',
        mediaIds: _photoIds().take(6).toList(),
      ),
    ),
    const {},
  ),
  // MM03: the milestone nudge (8 Oct: Teddy's first smile was tagged on 5 Oct).
  'mm03_nudge': (
    () => const Scaffold(body: MemoriesScreen()),
    [
      ...memoryOverrides(
        keepsakes: (cards: true, videos: false),
        keepsakeCatalog: seedCatalog(),
      ),
    ],
    const {},
  ),
};

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  for (final MapEntry(key: name, value: (build, extra, prefsInit))
      in _cases.entries) {
    for (final palette in ClPalette.values) {
      testWidgets('$name ${palette.name}', (tester) async {
        SharedPreferences.setMockInitialValues(prefsInit);
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...(extra.isEmpty
                  ? keepsakeOverrides()
                  : [
                      ...careOverrides(),
                      minuteClockProvider.overrideWith(
                        (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                      ),
                      ...extra,
                      environmentProvider.overrideWithValue(AppEnvironment.dev),
                      providerDisplayNameProvider.overrideWithValue(null),
                    ]),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 812),
                disableAnimations: true,
                padding: EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: RepaintBoundary(
                key: const ValueKey('golden'),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildClTheme(palette),
                  locale: const Locale('vi'),
                  supportedLocales: const [Locale('vi'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: build(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Media bytes decode outside the fake clock: let every visible image finish first.
        for (var round = 0; round < 2; round++) {
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
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
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('goldens/mm/${name}_${palette.name}.png'),
        );
      });
    }
  }
}
