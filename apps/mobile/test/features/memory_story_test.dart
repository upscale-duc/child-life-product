import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/keepsakes/keepsake_card_content.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_entries.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import 'package:child_life/features/keepsakes/keepsake_live.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/keepsake_preview.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/push_registration.dart'
    show keepsakeJobPushOf;
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/story_fixtures.dart';

// Video kỷ niệm in the app (D-068; MM04–MM09, MM13–MM17): template list, picking photos in scene
// order, finishing and asking the server, following the job, and the entries in Kỷ niệm.
void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  List<Override> on({
    FakeKeepsakeJobs? jobs,
    List<MediaItem> extra = const [],
    KeepsakeCatalog? catalog,
  }) {
    final j = mockJournal();
    return [
      ...careOverrides(),
      ...memoryOverrides(
        keepsakes: (cards: true, videos: true),
        keepsakeCatalog: catalog ?? seedCatalog(),
        journal: (memories: j.memories, media: [...extra, ...j.media]),
      ),
      keepsakeAssetImageProvider.overrideWithValue(
        (asset) => const StorageImage('keepsake/peach'),
      ),
      keepsakeJobRepositoryProvider.overrideWithValue(
        jobs ?? FakeKeepsakeJobs(),
      ),
    ];
  }

  final template = seedCatalog().videos.first; // Tháng đầu tiên: 6–8 photos.
  List<String> photoIds() => [
    for (final m in mockJournal().media)
      if (!m.isVideo) m.id,
  ];

  testWidgets('Thiệp and Video are two pages of one screen, swiped sideways', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const KeepsakeKindsScreen(video: false),
      overrides: on(),
    );
    await tester.pumpAndSettle();
    // Thiệp first: its dịp chips and formats.
    expect(find.text('Dọc 4:5'), findsOneWidget);
    expect(find.text('Tháng đầu tiên'), findsNothing);
    // Swipe left: Video kỷ niệm, in the same screen (owner, 2026-10-14).
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Tháng đầu tiên'), findsOneWidget);
    expect(find.text('Dọc 4:5'), findsNothing);
    // Tapping "Thiệp" goes back; the page kept its place.
    await tester.tap(find.text('Thiệp'));
    await tester.pumpAndSettle();
    expect(find.text('Dọc 4:5'), findsOneWidget);
  });

  testWidgets('with videos off, Thiệp stays a screen of its own', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const KeepsakeKindsScreen(video: false),
      overrides: [
        ...careOverrides(),
        ...memoryOverrides(
          keepsakes: (cards: true, videos: false),
          keepsakeCatalog: seedCatalog(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Thiệp cột mốc'), findsOneWidget);
  });

  testWidgets(
    'MM04 (G-107): the dịp we came for filters the templates, Tất cả shows all',
    (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const MemoryStoryTemplatesScreen(occasion: Occasion.m1),
        overrides: on(),
      );
      // 1 tháng: its own template (Gợi ý) and the one made for any day.
      expect(find.text('Tháng đầu tiên'), findsOneWidget);
      expect(find.text('Khoảnh khắc nhỏ'), findsOneWidget);
      expect(find.text('100 ngày yêu thương'), findsNothing);
      expect(find.text('Cần 6–8 ảnh'), findsOneWidget);
      // The row opened on 1 tháng; Tất cả is back at its start.
      await tester.ensureVisible(find.text('Tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      for (final name in [
        'Tháng đầu tiên',
        '7 ngày đầu đời',
        '100 ngày yêu thương',
        'Khoảnh khắc nhỏ',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      // The dịp chips are one row that scrolls sideways.
      await tester.ensureVisible(find.text('1 tháng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 tháng'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Khoảnh khắc nhỏ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khoảnh khắc nhỏ'));
      await tester.pumpAndSettle();
      // A template opens its preview first (owner, 2026-10-14).
      expect(visits.last.location, '/memories/video/preview');
      expect(
        (visits.last.extra! as VideoPreviewArgs).draft.occasion,
        Occasion.m1,
      );
    },
  );

  testWidgets('a card template’s preview: the card, its facts, then MM11', (
    tester,
  ) async {
    final t = seedCatalog().cards.first; // Tròn trịa
    final draft = CardDraft(
      babyId: teddyId,
      occasion: Occasion.m1,
      date: DateTime(2026, 10, 17),
      format: KeepsakeFormat.portrait,
      template: t,
      palette: t.palette,
      quote: 'Một tháng yêu thương',
      photos: const [],
    );
    final (visits, _) = await pumpRouted(
      tester,
      Builder(
        builder: (context) => CardTemplatePreviewScreen(
          args: CardPreviewArgs(
            draft: draft,
            content: keepsakeCardContent(
              l10n: AppLocalizations.of(context),
              locale: const Locale('vi'),
              template: t,
              occasion: Occasion.m1,
              name: 'Teddy',
              dob: DateTime(2026, 9, 17),
              date: DateTime(2026, 10, 17),
              note: 'Một tháng yêu thương',
              photos: const [],
            ),
          ),
        ),
      ),
      overrides: on(),
    );
    expect(find.byType(KeepsakeCardView), findsOneWidget);
    expect(find.text('Tròn trịa'), findsOneWidget);
    expect(find.text('Miễn phí'), findsOneWidget);
    expect(find.text('Ảnh cần'), findsOneWidget);
    expect(find.text('Dọc 4:5 · Vuông · Story 9:16'), findsOneWidget);
    await tester.tap(find.text('Dùng mẫu này'));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/memories/card/edit');
    expect(visits.last.extra, same(draft));
  });

  testWidgets(
    'a video template’s preview: what it needs, then "Dùng mẫu này"',
    (tester) async {
      final draft = VideoDraft(babyId: teddyId, template: template);
      final (visits, _) = await pumpRouted(
        tester,
        VideoTemplatePreviewScreen(
          args: VideoPreviewArgs(draft: draft, name: 'Teddy', suggested: true),
        ),
        overrides: on(),
      );
      expect(find.text('Tháng đầu tiên'), findsOneWidget);
      expect(find.text('Gợi ý'), findsOneWidget);
      expect(find.text('6–8 ảnh'), findsOneWidget);
      expect(find.text('Story 9:16'), findsOneWidget);
      expect(find.text('1 tháng'), findsOneWidget);
      // "Xem mẫu" on the cover plays the template with sample pictures.
      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PlayGlyph'),
        findsOneWidget,
      );
      await tester.tap(find.text('Dùng mẫu này'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/memories/video/photos');
      expect(visits.last.extra, same(draft));
    },
  );

  testWidgets('MM04: a template’s own cover, not the baby’s photos', (
    tester,
  ) async {
    final json =
        jsonDecode(File('test/helpers/keepsake_seed.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final t in json['templates'] as List) {
      if ((t as Map)['id'] == 'video_first_month') t['thumb'] = 'cover.webp';
    }
    await pumpRouted(
      tester,
      const MemoryStoryTemplatesScreen(occasion: Occasion.m1),
      overrides: on(catalog: KeepsakeCatalog.fromJson(json)),
    );
    final cover = tester.widget<VideoCover>(
      find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is Image && w.image == const StorageImage('keepsake/peach'),
        ),
        matching: find.byType(VideoCover),
      ),
    );
    expect(cover.photoPath, isNull);
    // Its title is in the cover itself; the name stays under it.
    expect(cover.title, isEmpty);
    expect(find.text('Tháng đầu tiên'), findsOneWidget);
  });

  testWidgets(
    'from MM01 / +: the templates for the baby’s age come first, Gợi ý',
    (tester) async {
      // Teddy (17.9) on 13.10: close to 1 tháng (17.10) and within 7 ngày đầu đời's window.
      await pumpRouted(
        tester,
        const MemoryStoryTemplatesScreen(),
        overrides: on(),
      );
      expect(find.text('Gợi ý'), findsWidgets);
      final first = tester.getTopLeft(find.text('Tháng đầu tiên'));
      final last = tester.getTopLeft(find.text('100 ngày yêu thương'));
      expect(first.dy < last.dy, isTrue);
    },
  );

  test('MM06: each scene suggests its own photos', () {
    final dob = DateTime(2026, 1, 1);
    final t = seedCatalog().videos.firstWhere(
      (t) => t.id == 'video_hundred_days',
    );
    MediaItem at(int day, {MilestoneRef? milestone}) => mediaItem(
      'mem_$day',
      DateTime(2026, 1, 1 + day, 10),
      milestone: milestone,
    );
    final born = at(1);
    final week = at(7);
    final week2 = at(5);
    final hundred = at(100);
    final tagged = at(
      120,
      milestone: MilestoneRef(
        id: 'p_hundred_days',
        name: '100 ngày',
        date: DateTime(2026, 5, 1),
      ),
    );
    final card = mediaItem('mem_c', DateTime(2026, 1, 8), generated: 'card');
    final all = [born, week, week2, hundred, tagged, card];
    // Tuần đầu (days 4–10): those taken then, closest to its middle first.
    expect(scenePhotos(all, t, t.scenes[1], dob: dob), [week, week2]);
    // Ngày 100 (days 96–115, the 100-day milestone): the tagged photo first.
    expect(scenePhotos(all, t, t.scenes[7], dob: dob), [tagged, hundred]);
    // A scene with no time: the template's photos, newest first; never a card.
    final little = seedCatalog().videos.firstWhere(
      (t) => t.id == 'video_little_moments',
    );
    expect(scenePhotos(all, little, little.scenes[0], dob: dob), [
      tagged,
      hundred,
      week,
      week2,
      born,
    ]);
  });

  testWidgets('MM06: photos in pick order, Tiếp tục from the minimum', (
    tester,
  ) async {
    final (visits, _) = await pumpRouted(
      tester,
      MemoryStoryPhotosScreen(
        draft: VideoDraft(
          babyId: teddyId,
          template: template,
          occasion: Occasion.m1,
        ),
      ),
      overrides: on(),
    );
    expect(find.text('Chọn ảnh cho video'), findsOneWidget);
    expect(find.text('Tối thiểu 6'), findsOneWidget);
    expect(find.text('Cần thêm 6'), findsOneWidget);
    final tiles = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_PickTile',
    );
    // Scene by scene: each tap fills the chosen scene and moves on to the next.
    expect(find.text('Gợi ý cho cảnh 1 · Ngày chào đời'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();
    }
    expect(find.text('Gợi ý cho cảnh 7 · Cả nhà'), findsOneWidget);
    expect(find.text('Đã chọn 6 ảnh'), findsOneWidget);
    expect(find.text('Có thể thêm 2'), findsOneWidget);
    expect(find.text('6/8 cảnh đã có ảnh'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(visits.last.location, '/memories/video/finish');
    expect((visits.last.extra! as VideoDraft).mediaIds, hasLength(6));
  });

  testWidgets(
    'MM13: not enough suitable photos offers the phone and a shorter template',
    (tester) async {
      final hundred = seedCatalog().videos.firstWhere(
        (t) => t.id == 'video_hundred_days',
      );
      await pumpRouted(
        tester,
        MemoryStoryPhotosScreen(
          draft: VideoDraft(
            babyId: teddyId,
            template: hundred,
            occasion: Occasion.d100,
          ),
        ),
        overrides: on(),
      );
      expect(
        find.text(
          'Kỷ niệm của Teddy hiện chỉ có 0 ảnh phù hợp. Mẫu này cần ít nhất 8 ảnh.',
        ),
        findsOneWidget,
      );
      expect(find.text('Chọn thêm từ thư viện máy'), findsOneWidget);
      await tester.tap(find.text('Đổi sang mẫu ngắn hơn'));
      await tester.pumpAndSettle();
      // The longest template that still has enough suited photos (7 ngày đầu đời here).
      expect(find.text('Tối thiểu 8'), findsNothing);
      expect(find.textContaining('chỉ có 0 ảnh phù hợp'), findsNothing);
    },
  );

  testWidgets(
    'MM07: prefilled, then Tạo video asks the server with the photos in order',
    (tester) async {
      final jobs = FakeKeepsakeJobs();
      final ids = photoIds().take(6).toList();
      final (visits, _) = await pumpRouted(
        tester,
        MemoryStoryFinishScreen(
          draft: VideoDraft(
            babyId: teddyId,
            template: template,
            occasion: Occasion.m1,
            mediaIds: ids,
          ),
        ),
        overrides: on(jobs: jobs),
      );
      expect(find.text('Hoàn thiện video'), findsOneWidget);
      expect(find.text('Tháng đầu tiên của Teddy'), findsWidgets);
      expect(find.text('Teddy · 1 tháng'), findsOneWidget);
      expect(find.text('17.10.2026'), findsOneWidget);
      expect(find.text('Chỉ ba mẹ · lưu vào Kỷ niệm'), findsOneWidget);
      await tester.tap(find.text('Tạo video'));
      await tester.pumpAndSettle();
      expect(jobs.requests.single['mediaIds'], ids);
      expect(jobs.requests.single['title'], 'Tháng đầu tiên của Teddy');
      expect(jobs.requests.single['audience'], 'parents');
      expect(jobs.requests.single['occasion'], 'm1');
      expect(visits.last.location, startsWith('/memories/video/job/ksj_'));
    },
  );

  group('Thư viện nhạc (MM07 "Nhạc nền")', () {
    // The seed with two licensed tracks, the first the default of Tháng đầu tiên, and a
    // portal-made preview video.
    KeepsakeCatalog withMusic() {
      final json =
          jsonDecode(File('test/helpers/keepsake_seed.json').readAsStringSync())
              as Map<String, dynamic>;
      Map<String, Object?> track(String id, String vi, int order) => {
        'id': id,
        'title': {'vi': vi, 'en': vi},
        'artist': 'Studio A',
        'mood': 'gentle',
        'durationSec': 62,
        'asset': '${id.substring(6)}_0a0b0c0d.mp3',
        'licence': {'kind': 'licensed', 'source': 'A', 'reference': 'B'},
        'status': 'published',
        'order': order,
      };
      json['music'] = [
        track('music_lullaby', 'Ru con', 10),
        track('music_sunny', 'Nắng mai', 20),
        {...track('music_hidden', 'Chưa duyệt', 30), 'status': 'draft'},
      ];
      final first = (json['templates'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((t) => t['id'] == template.id);
      first['defaultMusic'] = 'music_lullaby';
      first['preview'] = 'first-month_0a0b0c0d.mp4';
      return KeepsakeCatalog.fromJson(json);
    }

    Future<FakeKeepsakeJobs> finish(
      WidgetTester tester,
      FakeTrackSampler sampler,
    ) async {
      final jobs = FakeKeepsakeJobs();
      final catalog = withMusic();
      await pumpRouted(
        tester,
        MemoryStoryFinishScreen(
          draft: VideoDraft(
            babyId: teddyId,
            template: catalog.videos.firstWhere((t) => t.id == template.id),
            occasion: Occasion.m1,
            mediaIds: photoIds().take(6).toList(),
          ),
        ),
        overrides: [
          ...on(jobs: jobs, catalog: catalog),
          trackSamplerProvider.overrideWithValue(() => sampler),
        ],
      );
      return jobs;
    }

    test('only published tracks reach the app, in order', () {
      final c = withMusic();
      expect([for (final m in c.music) m.id], ['music_lullaby', 'music_sunny']);
      final t = c.videos.firstWhere((t) => t.id == template.id);
      expect(t.defaultMusic, 'music_lullaby');
      expect(t.preview, 'first-month_0a0b0c0d.mp4');
    });

    testWidgets('the template’s default plays unless the parent picks', (
      tester,
    ) async {
      final jobs = await finish(tester, FakeTrackSampler());
      expect(find.text('Ru con'), findsOneWidget);
      await tester.tap(find.text('Tạo video'));
      await tester.pumpAndSettle();
      // Left out: the server uses the template's default.
      expect(jobs.requests.single.containsKey('musicId'), isFalse);
    });

    testWidgets('pick another track after listening, or no music', (
      tester,
    ) async {
      final sampler = FakeTrackSampler();
      final jobs = await finish(tester, sampler);
      await tester.tap(find.text('Ru con'));
      await tester.pumpAndSettle();
      expect(find.text('Nắng mai'), findsOneWidget);
      expect(find.text('Chưa duyệt'), findsNothing);
      expect(find.text('Studio A · 1:02 · Mặc định của mẫu'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Nghe thử Nắng mai'));
      await tester.pump();
      expect(sampler.played, hasLength(1));
      expect(find.bySemanticsLabel('Dừng nghe thử'), findsOneWidget);
      await tester.tap(find.text('Nắng mai'));
      await tester.pumpAndSettle();
      expect(sampler.stopped, isTrue);
      expect(find.text('Nắng mai'), findsOneWidget);

      await tester.tap(find.text('Nắng mai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không dùng nhạc'));
      await tester.pumpAndSettle();
      expect(find.text('Không dùng nhạc'), findsOneWidget);
      await tester.tap(find.text('Tạo video'));
      await tester.pumpAndSettle();
      expect(jobs.requests.single, containsPair('musicId', null));
    });

    testWidgets('Xem mẫu plays the portal’s preview video when there is one', (
      tester,
    ) async {
      final seen = <KeepsakePreviewRequest>[];
      await pumpRouted(
        tester,
        const MemoryStoryTemplatesScreen(occasion: Occasion.m1),
        overrides: [
          ...on(catalog: withMusic()),
          keepsakePreviewLauncherProvider.overrideWithValue(
            (context, r) async => seen.add(r),
          ),
        ],
      );
      await tester.tap(find.bySemanticsLabel('Xem mẫu').first);
      await tester.pumpAndSettle();
      expect(seen.single.videoUrl, isNotNull);
    });
  });

  group('MM08 / MM09 / MM14', () {
    Future<FakeKeepsakeJobs> job(
      WidgetTester tester,
      KeepsakeJob j, {
      List<MediaItem> extra = const [],
    }) async {
      final jobs = FakeKeepsakeJobs()..put(j);
      await pumpRouted(
        tester,
        MemoryStoryJobScreen(babyId: teddyId, jobId: j.id),
        overrides: on(jobs: jobs, extra: extra),
      );
      return jobs;
    }

    testWidgets('rendering: progress and the three steps', (tester) async {
      await job(tester, videoJob(mediaIds: photoIds().take(6).toList()));
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('Đang tạo video cho Teddy…'), findsOneWidget);
      expect(find.text('Sắp xếp 6 ảnh theo mẫu'), findsOneWidget);
      expect(find.text('Xuất video 9:16'), findsOneWidget);
      expect(find.text('Về Kỷ niệm'), findsOneWidget);
    });

    testWidgets(
      'completed: saved in Kỷ niệm, save / share / open, and the matching card',
      (tester) async {
        final video = mediaItem(
          'mem_v',
          DateTime(2026, 10, 13, 9),
          video: true,
          durationMs: 45000,
          private: true,
        );
        await job(
          tester,
          videoJob(
            status: KeepsakeJobStatus.completed,
            progress: 100,
            outputMediaId: video.id,
          ),
          extra: [video],
        );
        expect(find.text('Video đã sẵn sàng!'), findsOneWidget);
        expect(
          find.text('Đã lưu vào Kỷ niệm · Tuần 4 · Chỉ ba mẹ'),
          findsOneWidget,
        );
        for (final a in ['Lưu vào máy', 'Chia sẻ', 'Xem trong Kỷ niệm']) {
          expect(find.text(a), findsOneWidget);
        }
        expect(find.text('Tạo thêm thiệp “1 tháng”'), findsOneWidget);
      },
    );

    testWidgets('failed: Thử lại asks again with the same inputs', (
      tester,
    ) async {
      final jobs = await job(
        tester,
        videoJob(status: KeepsakeJobStatus.failed, error: 'render-failed'),
      );
      expect(find.text('Chưa tạo được video'), findsOneWidget);
      expect(
        find.text('Bản nháp được lưu trong Câu chuyện · Bản nháp'),
        findsOneWidget,
      );
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(jobs.retried, [videoJob().id]);
    });

    testWidgets('failed: Xoá bản nháp, after a confirm, deletes it', (
      tester,
    ) async {
      final jobs = await job(
        tester,
        videoJob(status: KeepsakeJobStatus.failed, error: 'render-failed'),
      );
      await tester.ensureVisible(find.text('Xoá bản nháp'));
      await tester.tap(find.text('Xoá bản nháp'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá bản nháp video này?'), findsOneWidget);
      await tester.tap(find.text('Xoá bản nháp').last);
      await tester.pumpAndSettle();
      expect(jobs.deleted, [videoJob().id]);
      expect(find.text('Đã xoá bản nháp'), findsOneWidget);
    });
  });

  group('entries in Kỷ niệm', () {
    final noNudges = <String, Object>{
      'keepsakes.dismissed': [
        for (final o in Occasion.values) '$teddyId|${o.wire}',
      ],
    };

    testWidgets('MM01 has both tiles; the video one opens the template list', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: on(),
        prefs: noNudges,
      );
      expect(find.text('Video kỷ niệm'), findsOneWidget);
      expect(find.text('Thiệp cột mốc'), findsOneWidget);
      await tester.tap(find.text('Ảnh + chữ + nhạc'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/memories/video');
    });

    testWidgets('MM15: a draft to continue; MM17: a video just finished', (
      tester,
    ) async {
      final jobs = FakeKeepsakeJobs()
        ..put(videoJob(status: KeepsakeJobStatus.failed, error: 'timeout'));
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...on(jobs: jobs),
          ...storyOverrides(),
          startOn(MemoryTab.stories),
        ],
        prefs: noNudges,
      );
      expect(find.text('Làm tiếp'), findsOneWidget);
      jobs.put(
        KeepsakeJob(
          id: 'ksj_${'b' * 32}',
          babyId: teddyId,
          status: KeepsakeJobStatus.completed,
          templateId: 'video_first_month',
          title: 'Tháng đầu tiên của Teddy',
          createdAt: DateTime(2026, 10, 8, 14),
          updatedAt: DateTime(2026, 10, 8, 14, 50),
          durationMs: 45000,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('“Tháng đầu tiên của Teddy” · 0:45'), findsOneWidget);
      expect(find.text('Xem'), findsOneWidget);
      // Closed: it goes (the video stays in Kỷ niệm).
      await tester.tap(
        find.descendant(
          of: find.byType(KeepsakeReadyBanner),
          matching: find.bySemanticsLabel('Đóng'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('“Tháng đầu tiên của Teddy” · 0:45'), findsNothing);
    });
  });

  testWidgets(
    'a video being made: "Đang tạo video · 45%" on any Kỷ niệm tab opens MM08',
    (tester) async {
      final jobs = FakeKeepsakeJobs()
        ..put(
          KeepsakeJob(
            id: 'ksj_${'c' * 32}',
            babyId: teddyId,
            status: KeepsakeJobStatus.rendering,
            step: 'export',
            progress: 45,
            templateId: 'video_first_month',
            templateName: 'Tháng đầu tiên',
            title: 'Tháng đầu tiên của Teddy',
            createdAt: DateTime(2026, 10, 13, 8, 50),
          ),
        );
      final (visits, _) = await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...on(jobs: jobs),
          startOn(MemoryTab.photos),
        ],
        prefs: {
          'keepsakes.dismissed': [
            for (final o in Occasion.values) '$teddyId|${o.wire}',
          ],
        },
      );
      expect(find.text('Đang tạo video · 45%'), findsOneWidget);
      expect(find.text('Tháng đầu tiên'), findsOneWidget);
      await tester.tap(find.text('Đang tạo video · 45%'));
      await tester.pumpAndSettle();
      expect(
        visits.last.location,
        '/memories/video/job/ksj_${'c' * 32}?baby=$teddyId',
      );
    },
  );

  test(
    'the Live Activity carries every key its views read (vi and en)',
    () async {
      final swift = File('ios/widget/KeepsakeLive.swift').readAsStringSync();
      final read = {
        for (final m in RegExp(r'copyText\("([A-Za-z]+)"').allMatches(swift))
          m.group(1)!,
      };
      expect(read.length, greaterThan(8));
      for (final locale in const [Locale('vi'), Locale('en')]) {
        final copy = keepsakeLiveCopy(
          await AppLocalizations.delegate.load(locale),
          'Tháng đầu tiên',
        );
        expect(read.difference(copy.keys.toSet()), isEmpty);
      }
    },
  );

  test(
    'a Video kỷ niệm push opens its job (ready, not made, older notices)',
    () {
      final id = 'ksj_${'a' * 32}';
      expect(
        keepsakeJobPushOf({
          'kind': 'keepsakeVideoFailed',
          'babyId': 'b1',
          'noticeId': 'keepsake_${id}_failed_0',
          'jobId': id,
        }),
        (babyId: 'b1', jobId: id, failed: true),
      );
      expect(
        keepsakeJobPushOf({
          'kind': 'keepsakeVideo',
          'babyId': 'b1',
          'noticeId': 'keepsake_$id',
        }),
        (babyId: 'b1', jobId: id, failed: false),
      );
      expect(
        keepsakeJobPushOf({'kind': 'memories', 'babyId': 'b1', 'jobId': id}),
        isNull,
      );
      expect(
        keepsakeJobPushOf({
          'kind': 'keepsakeVideo',
          'babyId': 'b1',
          'jobId': 'x',
        }),
        isNull,
      );
    },
  );

  group('previews (renderer compositions on the phone)', () {
    testWidgets(
      'Xem mẫu plays the template with sample pictures and the baby’s name',
      (tester) async {
        final seen = <KeepsakePreviewRequest>[];
        await pumpRouted(
          tester,
          const MemoryStoryTemplatesScreen(occasion: Occasion.m1),
          overrides: [
            ...on(),
            keepsakePreviewLauncherProvider.overrideWithValue(
              (context, r) async => seen.add(r),
            ),
          ],
        );
        await tester.tap(find.bySemanticsLabel('Xem mẫu').first);
        await tester.pumpAndSettle();
        final r = seen.single;
        expect(r.composition, 'FirstMonth');
        expect(r.props['photos'], hasLength(8));
        expect((r.props['photos']! as List).first, '/samples/1.jpg');
        expect(r.props['title'], 'Tháng đầu tiên của Teddy');
        expect(r.props['palette'], {
          'background': '#E4F4F1',
          'ink': '#173D44',
          'accent': '#2BA89A',
        });
      },
    );

    testWidgets(
      'MM07 Xem trước: the chosen photos (on the phone only) and the texts',
      (tester) async {
        final seen = <KeepsakePreviewRequest>[];
        final ids = photoIds().take(6).toList();
        await pumpRouted(
          tester,
          MemoryStoryFinishScreen(
            draft: VideoDraft(
              babyId: teddyId,
              template: template,
              occasion: Occasion.m1,
              mediaIds: ids,
            ),
          ),
          overrides: [
            ...on(),
            keepsakePreviewLauncherProvider.overrideWithValue(
              (context, r) async => seen.add(r),
            ),
          ],
        );
        await tester.tap(find.text('Xem trước'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
        final r = seen.single;
        expect(r.props['title'], 'Tháng đầu tiên của Teddy');
        expect(r.props['dateLine'], '17.10.2026');
        expect(r.props['mark'], '1');
        for (final p in r.props['photos']! as List) {
          expect(p, startsWith('data:image/jpeg;base64,'));
        }
      },
    );
  });
}

class FakeTrackSampler implements TrackSampler {
  final played = <String>[];
  var stopped = false;

  @override
  Future<void> play(String url) async => played.add(url);

  @override
  Future<void> stop() async => stopped = true;

  @override
  void dispose() {}
}
