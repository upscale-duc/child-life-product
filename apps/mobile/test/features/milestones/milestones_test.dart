import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/upload_queue.dart'
    show uploadQueueProvider;
import 'package:child_life/features/milestones/milestone_models.dart';
import 'package:child_life/features/milestones/milestone_screens.dart';
import 'package:child_life/features/utilities/utilities_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:child_life/features/library/stage_screens.dart'
    show lbMilestoneLinkProvider;
import 'package:child_life/features/today/today_for_baby.dart'
    show milestoneForBabyCardsProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Consumer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/family_fixtures.dart';
import '../../helpers/memory_fixtures.dart';
import '../../helpers/milestone_fixtures.dart';
import '../../helpers/router_pump.dart';

/// Mốc phát triển on the phone (D-076 #6, Figma 3a–3g): the list by group and age window, the
/// detail, recording, following, the memory made from a milestone (Kỷ niệm's upload, linked by
/// id) and an own milestone. Teddy was born 17/09/2026; today is Thursday 08/10/2026.
final l10n = lookupAppLocalizations(const Locale('vi'));

List<Override> _overrides({
  required FakeMilestoneRepository repo,
  Membership? me,
  FakeMemoryRepository? memories,
  ({List<Memory> memories, List<MediaItem> media})? journal,
}) => [
  ...familyOverrides(
    me: me ?? mai,
    now: DateTime(2026, 10, 8, 10),
    milestones: repo,
  ),
  ...memoryOverrides(repo: memories, journal: journal),
];

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// Brings [f] into the (lazily built) page.
Future<void> _see(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 200, scrollable: _vertical.first);
  }
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await _see(t, f);
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  group('3a · Mốc phát triển', () {
    testWidgets('observed records, suggestions around the age, never "late"', (
      tester,
    ) async {
      final repo = FakeMilestoneRepository(records: drawnRecords());
      final (visits, _) = await pumpRouted(
        tester,
        const MilestonesScreen(),
        overrides: _overrides(repo: repo),
      );
      expect(find.text('Teddy đã có 2 mốc'), findsOneWidget);
      expect(find.text(l10n.mtLead), findsOneWidget);
      expect(find.text(l10n.mtSeen), findsOneWidget);
      expect(find.text('05/10'), findsOneWidget);
      expect(find.text('01/10'), findsOneWidget);
      expect(find.text('Lần đầu tắm cùng ba'), findsOneWidget);
      // 3 weeks old: "Mỉm cười đáp lại" (1–3 months) starts within six weeks.
      expect(find.text(l10n.mtAround), findsOneWidget);
      expect(find.text('Mỉm cười đáp lại'), findsOneWidget);
      expect(find.text('Giao tiếp · tham khảo 1–3 tháng'), findsOneWidget);
      expect(find.text(l10n.mtUpcoming), findsWidgets);
      // Nothing reads as late, and the guide says it is a draft.
      expect(find.textContaining('chậm'), findsNothing);
      await _see(tester, find.text(l10n.mtIllustrative));
      expect(find.text(l10n.mtIllustrative), findsOneWidget);
      // The rest stays folded.
      expect(find.text('Tự đi những bước đầu'), findsNothing);
      await _tap(tester, find.textContaining('Xem tất cả mốc'));
      expect(find.text('Tự đi những bước đầu'), findsOneWidget);
      expect(find.text(l10n.mtNotRecorded), findsWidgets);
      await _tap(tester, find.text('Mỉm cười đáp lại'));
      expect(visits.last.location, '${Routes.milestones}/first_smile');
    });

    testWidgets('filters by group and "Mốc riêng"; "Tạo mốc riêng" opens 3g', (
      tester,
    ) async {
      final repo = FakeMilestoneRepository(records: drawnRecords());
      final (visits, _) = await pumpRouted(
        tester,
        const MilestonesScreen(),
        overrides: _overrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.mtOwn).first);
      expect(find.text('Lần đầu tắm cùng ba'), findsOneWidget);
      expect(find.text('Nhìn theo mặt người'), findsNothing);
      expect(find.text(l10n.mtAround), findsNothing);
      await _tap(tester, find.text(l10n.mtGroupCognitive).first);
      expect(find.text('Nhìn theo mặt người'), findsOneWidget);
      expect(find.text('Lần đầu tắm cùng ba'), findsNothing);
      await _tap(tester, find.text(l10n.mtCreateOwn));
      expect(visits.last.location, Routes.milestoneOwn);
    });

    testWidgets('a relative browses the guide, never the records', (
      tester,
    ) async {
      final repo = FakeMilestoneRepository(records: drawnRecords());
      await pumpRouted(
        tester,
        const MilestonesScreen(),
        overrides: _overrides(repo: repo, me: hoa),
      );
      expect(find.text(l10n.mtLeadViewer), findsOneWidget);
      expect(find.text('Lần đầu tắm cùng ba'), findsNothing);
      expect(find.text(l10n.mtCreateOwn), findsNothing);
      expect(find.text(l10n.mtOwn), findsNothing);
      expect(find.text('Mỉm cười đáp lại'), findsOneWidget);
    });

    testWidgets('nothing published: own milestones still work', (tester) async {
      final repo = FakeMilestoneRepository(reference: const []);
      await pumpRouted(
        tester,
        const MilestonesScreen(),
        overrides: _overrides(repo: repo),
      );
      expect(find.text(l10n.mtEmptyTitle), findsOneWidget);
      expect(find.text(l10n.mtCreateOwn), findsOneWidget);
    });
  });

  group('3b → 3c → 3d → 3e → 3f', () {
    testWidgets('follow, record, then keep the moment in Kỷ niệm', (
      tester,
    ) async {
      final repo = FakeMilestoneRepository();
      final memories = FakeMemoryRepository();
      final (_, container) = await pumpRouted(
        tester,
        const MilestoneDetailScreen(id: 'first_smile'),
        // No memory tagged with it yet (the mock journal tags one with "Lần đầu cười").
        overrides: _overrides(
          repo: repo,
          memories: memories,
          journal: (memories: const [], media: const []),
        ),
      );
      // The tab shell's upload pill keeps Kỷ niệm's queue running in the app.
      container.listen(uploadQueueProvider, (_, _) {});
      // 3b
      expect(find.text('Mỉm cười đáp lại'), findsOneWidget);
      expect(find.text(l10n.mtHowTo), findsOneWidget);
      expect(find.text('Tham khảo 1–3 tháng'), findsOneWidget);
      // D-116: the doctor card already reassures; the extra note shows only without it.
      expect(find.text(l10n.mtReassure), findsNothing);
      expect(find.text(l10n.mtTalkToDoctor), findsOneWidget);
      await _tap(tester, find.text(l10n.mtFollow));
      expect(repo.writes, ['follow p_first_smile']);
      expect(find.text(l10n.mtUnfollow), findsOneWidget);

      // 3c
      await _tap(tester, find.text(l10n.mtMarkSeen));
      expect(find.text(l10n.mtDateDid), findsOneWidget);
      expect(find.text('Thứ Năm, 08/10/2026'), findsOneWidget);
      await tester.enterText(
        find.byType(EditableText).first,
        'Bé cười khi mẹ hát sau cữ bú sáng.',
      );
      await _tap(tester, find.text(l10n.mtSave));
      expect(repo.writes.last, 'observe p_first_smile');
      final saved = repo.records.single;
      expect(saved.status, RecordStatus.observed);
      expect(saved.date, DateTime(2026, 10, 8));
      expect(saved.note, 'Bé cười khi mẹ hát sau cữ bú sáng.');

      // 3d
      expect(
        find.text('Thứ Năm, 08/10/2026 · lúc Teddy 3 tuần · Bạn ghi'),
        findsOneWidget,
      );
      await _see(tester, find.text(l10n.mtKeepTitle));
      expect(find.text(l10n.mtKeepTitle), findsOneWidget);

      // 3e: Kỷ niệm's own upload, tagged with the record; the record keeps the memory id.
      await _tap(tester, find.text(l10n.mtCreateMemory));
      expect(find.text(l10n.mtNewMemory), findsOneWidget);
      expect(find.text('Mốc · Mỉm cười đáp lại'), findsOneWidget);
      await _tap(tester, find.text(l10n.mtSaveMemory));
      final request = memories.sessions.single;
      expect(request['milestone'], {
        'id': 'p_first_smile',
        'name': 'Mỉm cười đáp lại',
        'date': '2026-10-08',
      });
      expect(request['audience'], 'family');
      expect(request['caption'], 'Bé cười khi mẹ hát sau cữ bú sáng.');
      expect(repo.writes.last, startsWith('link p_first_smile mem_'));
      // 3f, while the memory is on its way.
      expect(find.text(l10n.mtUploading), findsOneWidget);
      expect(find.text(l10n.mtKeepTitle), findsNothing);
    });

    testWidgets('3f: a memory tagged with the record links back to it', (
      tester,
    ) async {
      final record = observed(
        'p_follows_faces',
        'Nhìn theo mặt người',
        DateTime(2026, 10, 5),
      );
      final tag = record.ref!;
      final media = [
        mediaItem('mem_${'7' * 32}', DateTime(2026, 10, 5, 9), milestone: tag),
        mediaItem(
          'mem_${'7' * 32}',
          DateTime(2026, 10, 5, 9, 1),
          colour: 'peach',
          milestone: tag,
        ),
      ];
      final memory = Memory(
        id: 'mem_${'7' * 32}',
        babyId: teddyId,
        audience: Audience.family,
        occurredAt: DateTime(2026, 10, 5, 9),
        milestone: tag,
        mediaIds: [for (final m in media) m.id],
        photos: 2,
        createdBy: 'u_mai',
        author: CareAuthor.of(mai),
      );
      await pumpRouted(
        tester,
        const MilestoneDetailScreen(id: 'follows_faces'),
        overrides: _overrides(
          repo: FakeMilestoneRepository(records: [record]),
          journal: (memories: [memory], media: media),
        ),
      );
      expect(find.text(l10n.mtInMemories), findsOneWidget);
      expect(find.text('Cả gia đình xem được · 2 ảnh'), findsOneWidget);
      expect(find.text(l10n.mtKeepTitle), findsNothing);
    });

    testWidgets('removing a record goes back to 3b', (tester) async {
      final repo = FakeMilestoneRepository(
        records: [
          observed('p_coos', 'Ê a, tạo âm thanh', DateTime(2026, 10, 7)),
        ],
      );
      await pumpRouted(
        tester,
        const MilestoneDetailScreen(id: 'coos'),
        overrides: _overrides(repo: repo),
      );
      await _tap(tester, find.text(l10n.mtDelete));
      await _tap(tester, find.text(l10n.mtDelete).last);
      expect(repo.writes, ['remove p_coos']);
      await _see(tester, find.text(l10n.mtMarkSeen));
      expect(find.text(l10n.mtMarkSeen), findsOneWidget);
    });

    testWidgets('a caregiver reads the guide, cannot record', (tester) async {
      await pumpRouted(
        tester,
        const MilestoneDetailScreen(id: 'first_smile'),
        overrides: _overrides(repo: FakeMilestoneRepository(), me: lan),
      );
      expect(find.text(l10n.mtHowTo), findsOneWidget);
      await _see(tester, find.text(l10n.mtParentsRecord));
      expect(find.text(l10n.mtMarkSeen), findsNothing);
      expect(find.text(l10n.mtParentsRecord), findsOneWidget);
    });
  });

  group('3g · Tạo mốc riêng', () {
    testWidgets('saves the milestone and a memory with it, then opens it', (
      tester,
    ) async {
      final repo = FakeMilestoneRepository();
      final memories = FakeMemoryRepository();
      final (visits, container) = await pumpRouted(
        tester,
        const OwnMilestoneScreen(),
        overrides: _overrides(repo: repo, memories: memories),
      );
      container.listen(uploadQueueProvider, (_, _) {});
      expect(find.text(l10n.mtOwnLead), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, 'Lần đầu về quê');
      await tester.pumpAndSettle();
      expect(find.text('14/60 ký tự'), findsOneWidget);
      await _tap(tester, find.text(l10n.mtSave));
      final id = repo.records.single.id;
      expect(id, startsWith('ms_'));
      expect(repo.records.single.kind, RecordKind.custom);
      final request = memories.sessions.single;
      expect((request['milestone']! as Map)['id'], id);
      expect(request['caption'], 'Lần đầu về quê');
      expect(repo.writes.last, startsWith('link $id mem_'));
      expect(visits.last.location, '${Routes.milestones}/$id');
    });
  });

  testWidgets('Tiện ích: the Mốc phát triển row with what is recorded', (
    tester,
  ) async {
    final (visits, _) = await pumpRouted(
      tester,
      const UtilitiesScreen(),
      overrides: _overrides(
        repo: FakeMilestoneRepository(records: drawnRecords()),
      ),
    );
    expect(find.text(l10n.mtTitle), findsOneWidget);
    expect(find.text('2 mốc đã ghi'), findsOneWidget);
    await _tap(tester, find.text(l10n.mtTitle));
    expect(visits.last.location, Routes.milestones);
  });

  testWidgets('Giai đoạn của bé (2b) links a stage milestone by id', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      Consumer(
        builder: (context, ref, _) {
          final link = ref.watch(lbMilestoneLinkProvider);
          final a = link?.call(context, 'first_smile');
          final b = link?.call(context, 'not_published');
          return Text('${a?.title}|${a?.route}|$b');
        },
      ),
      overrides: _overrides(repo: FakeMilestoneRepository()),
    );
    expect(
      find.text('Mỉm cười đáp lại|${Routes.milestones}/first_smile|null'),
      findsOneWidget,
    );
  });

  testWidgets('Hôm nay: "Mốc có thể thấy" cards, never one already recorded', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      Consumer(
        builder: (context, ref, _) {
          final cards = ref.watch(
            milestoneForBabyCardsProvider((
              babyId: teddyId,
              uid: 'u_mai',
              languageCode: 'vi',
            )),
          );
          return Text(
            [
              for (final c in cards) '${c.kicker}|${c.title}|${c.action}',
            ].join('\n'),
          );
        },
      ),
      overrides: _overrides(
        repo: FakeMilestoneRepository(records: drawnRecords()),
      ),
    );
    expect(find.textContaining('Nhìn theo mặt người'), findsNothing);
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(text.split('\n'), [
      'Mốc có thể thấy · tham khảo 0–2 tháng|Dịu lại khi được bế, được trò chuyện|${l10n.mtTodayAction}',
      'Mốc có thể thấy · tham khảo 0–3 tháng|Nhận ra giọng ba mẹ|${l10n.mtTodayAction}',
    ]);
  });
}
