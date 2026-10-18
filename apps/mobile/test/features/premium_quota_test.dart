import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_jobs.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/billing_repository.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/premium/premium_widgets.dart';
import 'package:child_life/features/premium/purchase_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/pump.dart';
import '../helpers/router_pump.dart';
import 'premium_test.dart' show answer;

/// MO04 video quota (brief p.10, plan §5.3 Q2) and MO03's banner on the phone: the quota line
/// from `getVideoQuota`, "Khi hết lượt" after `QUOTA_EXCEEDED` (never a paywall by itself), the
/// reservation notes on the job, and the editor reopened after a purchase.

/// `requestMemoryStory` refusing: the household's exports are used up.
class _QuotaFull extends FakeKeepsakeJobs {
  @override
  Future<String> request({
    required String requestId,
    required String babyId,
    required KeepsakeTemplate template,
    required List<String> mediaIds,
    required String title,
    required String message,
    Map<String, String> extra = const {},
    String locale = 'vi',
    required Audience audience,
    required Occasion? occasion,
    ({String? id})? music,
  }) async => throw const KeepsakeJobException('QUOTA_EXCEEDED');
}

class _Resumed extends JustResumed {
  @override
  String? build() => 'card_blush';
}

void main() {
  setUp(() => mediaBytes = FakeMediaBytes());

  final quota = VideoQuota(
    limit: 5,
    used: 2,
    reserved: 1,
    resetsAt: DateTime(2026, 11, 1),
  );

  List<Override> on({
    FakeKeepsakeJobs? jobs,
    VideoQuota? q,
    Map<String, Object?>? caps,
  }) {
    final j = mockJournal();
    return [
      ...careOverrides(),
      ...memoryOverrides(
        keepsakes: (cards: true, videos: true),
        keepsakeCatalog: seedCatalog(),
        journal: (memories: j.memories, media: j.media),
      ),
      keepsakeAssetImageProvider.overrideWithValue(
        (asset) => const StorageImage('keepsake/peach'),
      ),
      keepsakeJobRepositoryProvider.overrideWithValue(
        jobs ?? FakeKeepsakeJobs(),
      ),
      videoQuotaProvider.overrideWith((ref, babyId) async => q),
      capabilitiesProvider.overrideWith(
        (ref, babyId) async => Capabilities.fromJson(caps ?? answer()),
      ),
    ];
  }

  List<String> photoIds() => [
    for (final m in mockJournal().media)
      if (!m.isVideo) m.id,
  ];

  VideoDraft draft() => VideoDraft(
    babyId: teddyId,
    template: seedCatalog().videos.first,
    occasion: Occasion.m1,
    mediaIds: photoIds().take(6).toList(),
  );

  group('quota card', () {
    testWidgets('used + reserved of the limit, and when it resets (vi)', (
      tester,
    ) async {
      await pumpCl(tester, VideoQuotaCard(quota: quota));
      expect(find.text('Lượt xuất video kỳ này'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(
        find.text(
          '2 đã dùng · 1 đang giữ chỗ · làm mới 01/11. Thẻ ảnh không tính lượt.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('English dates are never an ambiguous dd/mm', (tester) async {
      await pumpCl(
        tester,
        VideoQuotaCard(quota: quota),
        locale: const Locale('en'),
      );
      expect(
        find.text('2 used · 1 reserved · resets Nov 1. Cards don’t count.'),
        findsOneWidget,
      );
    });
  });

  group('MO04 on the video screens', () {
    // D-081: credits and quotas stay out of the main screens ("Chi tiết" only).
    testWidgets('the templates and MM07 never show this period’s exports', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const MemoryStoryTemplatesScreen(),
        overrides: on(q: quota),
      );
      expect(find.text('3 / 5'), findsNothing);
      expect(find.text('Lượt xuất video kỳ này'), findsNothing);
    });

    testWidgets('MM07 never shows what "Tạo video" takes', (tester) async {
      await pumpRouted(
        tester,
        MemoryStoryFinishScreen(draft: draft()),
        overrides: on(q: quota),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsNothing);
    });

    testWidgets('no ledger answer: nothing about quota', (tester) async {
      await pumpRouted(
        tester,
        const MemoryStoryTemplatesScreen(),
        overrides: on(),
      );
      expect(find.text('Lượt xuất video kỳ này'), findsNothing);
    });

    Future<void> quotaFull(
      WidgetTester tester, {
      required Map<String, Object?> caps,
      required VideoQuota q,
    }) async {
      await pumpRouted(
        tester,
        MemoryStoryFinishScreen(draft: draft()),
        overrides: on(jobs: _QuotaFull(), q: q, caps: caps),
      );
      await tester.tap(find.text('Tạo video'));
      await tester.pumpAndSettle();
      expect(find.text('Đã hết lượt xuất video kỳ này'), findsOneWidget);
      expect(
        find.text(
          'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau, làm mới 01/11.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tạo thẻ ảnh'), findsOneWidget);
    }

    final full = VideoQuota(
      limit: 1,
      used: 1,
      reserved: 0,
      resetsAt: DateTime(2026, 11, 1),
      premiumLimit: 5,
    );

    testWidgets(
      'QUOTA_EXCEEDED, free family with a larger Premium budget: optional',
      (tester) async {
        await quotaFull(tester, caps: answer(), q: full);
        expect(find.text('Xem Premium'), findsOneWidget);
        expect(
          find.text('Premium có 5 lượt xuất video mỗi kỳ.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('QUOTA_EXCEEDED on Premium: no paywall', (tester) async {
      await quotaFull(
        tester,
        caps: answer(plan: 'premium', templates: true),
        q: VideoQuota(
          limit: 5,
          used: 4,
          reserved: 1,
          resetsAt: DateTime(2026, 11, 1),
        ),
      );
      expect(find.text('Xem Premium'), findsNothing);
    });

    testWidgets('QUOTA_EXCEEDED without a known Premium budget: no paywall', (
      tester,
    ) async {
      await quotaFull(
        tester,
        caps: answer(),
        q: VideoQuota(
          limit: 1,
          used: 1,
          reserved: 0,
          resetsAt: DateTime(2026, 11, 1),
        ),
      );
      expect(find.text('Xem Premium'), findsNothing);
    });

    testWidgets('"Tạo thẻ ảnh" goes to cards for the same occasion', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        MemoryStoryFinishScreen(draft: draft()),
        overrides: on(jobs: _QuotaFull(), q: full, caps: answer()),
      );
      await tester.tap(find.text('Tạo video'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo thẻ ảnh'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/memories/card?occasion=m1');
    });

    testWidgets('a failed export says nothing about its reservation', (
      tester,
    ) async {
      final jobs = FakeKeepsakeJobs()
        ..put(
          videoJob(
            status: KeepsakeJobStatus.failed,
            error: 'render-failed',
            mediaIds: photoIds().take(6).toList(),
          ),
        );
      await pumpRouted(
        tester,
        MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
        overrides: on(jobs: jobs, q: quota),
      );
      expect(find.textContaining('lượt'), findsNothing);
    });

    testWidgets('a queued export says nothing about holding one', (
      tester,
    ) async {
      final jobs = FakeKeepsakeJobs()
        ..put(
          videoJob(
            status: KeepsakeJobStatus.queued,
            progress: 0,
            mediaIds: photoIds().take(6).toList(),
          ),
        );
      await pumpRouted(
        tester,
        MemoryStoryJobScreen(babyId: teddyId, jobId: videoJob().id),
        overrides: on(jobs: jobs, q: quota),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('lượt'), findsNothing);
    });
  });

  group('MO03', () {
    CardDraft card() {
      final t = seedCatalog().cards.firstWhere((t) => t.id == 'card_blush');
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

    testWidgets('the editor reopened after a purchase says so, once', (
      tester,
    ) async {
      final (_, container) = await pumpRouted(
        tester,
        MilestoneCardEditScreen(draft: card()),
        overrides: [...on(), justResumedProvider.overrideWith(_Resumed.new)],
      );
      expect(
        find.text('Đã mở Premium · tiếp tục chỗ bạn đang làm'),
        findsOneWidget,
      );
      expect(container.read(justResumedProvider), isNull);
    });

    testWidgets('opened normally: no banner', (tester) async {
      await pumpRouted(
        tester,
        MilestoneCardEditScreen(draft: card()),
        overrides: on(),
      );
      expect(
        find.text('Đã mở Premium · tiếp tục chỗ bạn đang làm'),
        findsNothing,
      );
    });

    testWidgets('a video draft reopened on MM06 says so', (tester) async {
      await pumpRouted(
        tester,
        MemoryStoryPhotosScreen(
          draft: VideoDraft(
            babyId: teddyId,
            template: seedCatalog().videos.first,
            occasion: Occasion.m1,
          ),
        ),
        overrides: [
          ...on(),
          justResumedProvider.overrideWith(
            () => _ResumedVideo(seedCatalog().videos.first.id),
          ),
        ],
      );
      expect(
        find.text('Đã mở Premium · tiếp tục chỗ bạn đang làm'),
        findsOneWidget,
      );
    });
  });

  testWidgets('PR04 strip: renewal only for the owner', (tester) async {
    await pumpCl(
      tester,
      const Column(
        children: [
          PremiumExpiredStrip(canRenew: true),
          PremiumExpiredStrip(canRenew: false),
        ],
      ),
    );
    expect(
      find.text(
        'Premium đã hết hạn. Mọi ghi nhận, phản hồi và bản tóm tắt đã lưu vẫn ở đây.',
      ),
      findsNWidgets(2),
    );
    expect(find.text('Gia hạn Premium'), findsOneWidget);
  });
}

class _ResumedVideo extends JustResumed {
  _ResumedVideo(this.id);
  final String id;
  @override
  String? build() => id;
}
