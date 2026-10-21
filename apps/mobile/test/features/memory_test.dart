import 'dart:async';

import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_sheets.dart';
import 'package:child_life/features/memories/memory_widgets.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

QueueItem _queued(String id, QueueState state, DateTime at) => QueueItem(
  mediaId: id,
  type: MediaKind.photo,
  name: 'IMG.jpg',
  localPath: '/nowhere/$id.jpg',
  contentType: 'image/jpeg',
  bytes: 10,
  captureAt: at,
  state: state,
);

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// v1.0 10b groups Ảnh by week of age; these cases are about calendar months.
Future<void> _byMonth(WidgetTester tester) async {
  await tester.tap(find.text('Theo tuần tuổi'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tháng trong năm'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  group('model', () {
    test('age weeks: week n holds days 7(n−1)…7n−1 after birth (R-113)', () {
      final dob = DateTime(2026, 9, 17);
      expect(ageWeekOf(dob, DateTime(2026, 9, 24)), 2);
      expect(ageWeekOf(dob, DateTime(2026, 9, 30)), 2);
      expect(ageWeekOf(dob, DateTime(2026, 10, 1)), 3);
      expect(ageWeekOf(dob, DateTime(2026, 10, 8)), 4);
      expect(ageWeekOf(dob, DateTime(2026, 9, 1)), 0);
      expect(ageWeekRange(dob, 3).first, DateTime(2026, 10, 1));
      expect(ageWeekRange(dob, 3).last, DateTime(2026, 10, 7));
    });

    test('landing: on its way until the server has it ready', () {
      final at = DateTime(2026, 10, 9, 9);
      QueueItem item(String id, QueueState state) => _queued(id, state, at);
      final processing = mediaItem('mem1', at, status: MediaStatus.uploading);
      final ready = mediaItem('mem1', at);
      // Left "uploading" on the server with nothing on this phone (abandoned or removed).
      final orphan = mediaItem('mem1', at, status: MediaStatus.uploading);
      final queue = QueueView(
        batches: [
          QueueBatch(
            batchId: 'b1',
            babyId: teddyId,
            memoryId: 'mem1',
            request: const {'audience': 'family'},
            createdAt: at,
            sessionCreated: true,
            items: [
              item(processing.id, QueueState.uploaded),
              item(ready.id, QueueState.uploaded),
              item('med_sending', QueueState.uploading),
              item('med_failed', QueueState.failed),
              // Sent, then deleted: its server item is gone from the list.
              item('med_deleted', QueueState.uploaded),
            ],
          ),
        ],
      );
      final cells = landingCells(
        queue,
        [processing, ready, orphan],
        const MemoryView(),
        teddyId,
      );
      // Sent but still processing, and still sending; not the ready, failed, deleted or
      // orphaned ones (they once read "Đang thêm 3 mục…" for good).
      expect(
        cells.map((c) => c.id),
        unorderedEquals([processing.id, 'med_sending']),
      );
      expect(
        landingCells(
          queue,
          [processing, ready],
          const MemoryView(show: MemoryShow.videos),
          teddyId,
        ),
        isEmpty,
      );
    });

    test('presets follow the baby’s age (10h3)', () {
      expect(
        PresetMilestone.forAgeWeeks(2),
        contains(PresetMilestone.firstSmile),
      );
      expect(
        PresetMilestone.forAgeWeeks(2),
        isNot(contains(PresetMilestone.firstSteps)),
      );
      expect(
        PresetMilestone.forAgeWeeks(50),
        contains(PresetMilestone.firstBirthday),
      );
    });
  });

  group('tabs', () {
    testWidgets('opens on Ảnh; a swipe moves to Album, then Nhật ký', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      final pages = find.byKey(const Key('memoryPages'));
      // Owner request: Ảnh · Album · Nhật ký · Câu chuyện, Ảnh first.
      expect(find.text('Theo tuần tuổi'), findsOneWidget);
      expect(find.byType(JournalView), findsNothing);
      await tester.fling(pages, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Album mới'), findsOneWidget);
      await tester.fling(pages, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Tuần thứ 4'), findsOneWidget);
      // A tap on a title slides back.
      await tester.ensureVisible(find.text('Ảnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('Theo tuần tuổi'), findsOneWidget);
    });

    testWidgets('Ảnh says what is still landing, as a tile in the grid', (
      tester,
    ) async {
      final j = mockJournal();
      final at = DateTime(2026, 10, 8, 14);
      final processing = mediaItem('mem1', at, status: MediaStatus.uploading);
      // Sent from this phone; the server is still making its thumbnail.
      final store = MemoryQueueStore()
        ..saved = [
          QueueBatch(
            batchId: 'b1',
            babyId: teddyId,
            memoryId: 'mem1',
            request: const {'audience': 'family'},
            createdAt: at,
            sessionCreated: true,
            items: [_queued(processing.id, QueueState.uploaded, at)],
          ),
        ];
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          startOn(MemoryTab.journal),
          ...memoryOverrides(
            journal: (memories: j.memories, media: [processing, ...j.media]),
            store: store,
          ),
        ],
      );
      // The spinners never settle.
      await tester.tap(find.text('Ảnh').last);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Đang thêm 1 mục…'), findsOneWidget);
      // The line over the grid and the tile in it.
      expect(find.bySemanticsLabel('Đang thêm 1 mục…'), findsNWidgets(2));
    });
  });

  testWidgets('Ảnh: the filters stay pinned while the grid scrolls', (
    tester,
  ) async {
    await pumpRouted(
      tester,
      const Scaffold(body: MemoriesScreen()),
      overrides: [...careOverrides(), ...memoryOverrides()],
    );
    await _tab(tester, 'Ảnh');
    final pill = find.text('Theo tuần tuổi');
    final before = tester.getTopLeft(pill);
    final section = find.byType(MediaTile).first;
    final sectionBefore = tester.getTopLeft(section).dy;
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    // The grid moved; the filters did not.
    expect(tester.getTopLeft(section).dy, lessThan(sectionBefore));
    expect(tester.getTopLeft(pill), before);
    await tester.tap(pill);
    await tester.pumpAndSettle();
    expect(find.text('Xem ảnh theo'), findsOneWidget);
  });

  testWidgets('a thumbnail that is only a picture is not dimmed', (
    tester,
  ) async {
    final video = mediaItem(
      'mem1',
      DateTime(2026, 10, 8, 9),
      video: true,
      durationMs: 34000,
    );
    await pumpRouted(
      tester,
      Scaffold(
        body: Column(
          children: [
            // "Đi tới tuần" row: no tap, 56 wide.
            SizedBox.square(dimension: 56, child: MediaTile(item: video)),
            SizedBox.square(
              dimension: 120,
              child: MediaTile(item: video, onTap: () {}),
            ),
          ],
        ),
      ),
    );
    final small = find.byType(MediaTile).first;
    expect(
      find.descendant(of: small, matching: find.byType(AnimatedOpacity)),
      findsNothing,
    );
    // Too small for "0:34"; the grid tile keeps it.
    expect(
      find.descendant(of: small, matching: find.text('0:34')),
      findsNothing,
    );
    expect(find.text('0:34'), findsOneWidget);
  });

  testWidgets('"Ai thấy": two cards share the width, 8 apart', (tester) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AudienceCards(value: Audience.family, onChanged: (_) {}),
        ),
      ),
    );
    Rect card(String title) => tester.getRect(
      find
          .ancestor(
            of: find.text(title),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final parents = card('Chỉ ba mẹ');
    final family = card('Gia đình');
    expect(parents.width, family.width);
    expect(parents.left, 16);
    expect(family.right, 375 - 16);
    expect(family.left - parents.right, 8);
  });

  group('10a Nhật ký', () {
    testWidgets('weeks of life with ranges and counts; entries with labels', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          startOn(MemoryTab.journal),
          ...memoryOverrides(),
        ],
      );
      expect(find.text('Tuần thứ 4'), findsOneWidget);
      expect(find.text('8 – 14 tháng 10 · 1 ảnh'), findsOneWidget);
      expect(find.text('Hôm nay · 9:20'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Tuần thứ 1'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      expect(find.text('Tuần thứ 1'), findsOneWidget);
      expect(find.text('17 – 23 tháng 9 · 3 ảnh'), findsOneWidget);
    });

    testWidgets(
      'a parent sees the private note; a relative never does (R-119)',
      (tester) async {
        const note = 'Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ.';
        await pumpRouted(
          tester,
          const Scaffold(body: MemoriesScreen()),
          overrides: [
            ...careOverrides(),
            startOn(MemoryTab.journal),
            ...memoryOverrides(),
          ],
        );
        await tester.dragUntilVisible(
          find.text(note),
          find.byType(CustomScrollView),
          const Offset(0, -300),
        );
        expect(find.text(note), findsOneWidget);

        await pumpRouted(
          tester,
          const Scaffold(body: MemoriesScreen()),
          overrides: [
            ...careOverrides(me: hoa),
            ...memoryOverrides(),
          ],
        );
        expect(find.bySemanticsLabel('Thêm vào Kỷ niệm'), findsNothing);
        await tester.dragUntilVisible(
          find.text('Tuần thứ 1'),
          find.byType(CustomScrollView),
          const Offset(0, -300),
        );
        expect(find.text(note), findsNothing);
        // Unmount here so Riverpod's zero-delay dispose timer runs inside the test.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 1));
      },
    );

    testWidgets(
      '"Xem như người thân" hides private things until "Thoát" (10c)',
      (tester) async {
        await pumpRouted(
          tester,
          const Scaffold(body: MemoriesScreen()),
          overrides: [...careOverrides(), ...memoryOverrides()],
        );
        await tester.tap(find.bySemanticsLabel('Cách xem'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xem như người thân'));
        await tester.pumpAndSettle();
        expect(find.text('Đang xem như người thân'), findsOneWidget);
        expect(find.text('1 – 7 tháng 10 · 5 ảnh, 3 video'), findsOneWidget);
        await tester.tap(find.text('Thoát'));
        await tester.pumpAndSettle();
        expect(find.text('1 – 7 tháng 10 · 6 ảnh, 3 video'), findsOneWidget);
      },
    );

    testWidgets('"Viết ghi chú" saves a note through the queue', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(repo: repo),
        ],
      );
      await tester.tap(find.bySemanticsLabel('Thêm vào Kỷ niệm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Viết ghi chú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu ghi chú'));
      await tester.pump();
      expect(find.text('Viết vài chữ cho ghi chú.'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Con biết lật rồi!');
      await tester.tap(find.text('Lưu ghi chú'));
      await tester.pumpAndSettle();
      final r = repo.sessions.single;
      expect(r['caption'], 'Con biết lật rồi!');
      expect(r['items'], isEmpty);
      expect(r['audience'], 'family');
      expect(r['dateMode'], 'single');
      expect(r['date'], '2026-10-08');
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('10b Ảnh', () {
    testWidgets('months with counts; select a month; delete with undo (10b4)', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      final journal = mockJournal();
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(journal: journal, repo: repo),
        ],
      );
      await _tab(tester, 'Ảnh');
      await _byMonth(tester);
      expect(find.text('Tháng 10, 2026'), findsOneWidget);
      expect(find.text('7 ảnh, 3 video'), findsOneWidget);
      await tester.tap(find.byKey(const Key('photoSelect')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn cả tháng').first);
      await tester.pumpAndSettle();
      expect(find.text('10 mục đã chọn'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Xoá mục đã chọn'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá 10 mục?'), findsOneWidget);
      expect(find.text('Chỉ ba mẹ mới xoá được.'), findsOneWidget);
      await tester.tap(find.text('Xoá 10 mục'));
      await tester.pumpAndSettle();
      expect(repo.updates.single.$1, hasLength(10));
      expect(repo.updates.single.$2, {'kind': 'delete'});
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(repo.updates.last.$2, {'kind': 'restore'});
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('sharing private items goes through 10o with one notice', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(repo: repo),
        ],
      );
      await _tab(tester, 'Ảnh');
      await _byMonth(tester);
      await tester.tap(find.byKey(const Key('photoSelect')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn cả tháng').first);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Chia sẻ và tuỳ chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ai thấy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gia đình'));
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(find.text('Chia sẻ với gia đình?'), findsOneWidget);
      expect(find.text('1 ảnh riêng tư'), findsOneWidget);
      expect(
        find.text('Người chăm (Cô Lan) không thấy Kỷ niệm.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Chia sẻ 1 ảnh'));
      await tester.pumpAndSettle();
      final (ids, change) = repo.updates.single;
      expect(ids, hasLength(1));
      expect(change, {
        'kind': 'audience',
        'audience': 'family',
        'notifyFamily': true,
      });
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('"Đổi ngày" moves the selection to another day', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(repo: repo),
        ],
      );
      await _tab(tester, 'Ảnh');
      await _byMonth(tester);
      await tester.tap(find.byKey(const Key('photoSelect')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn cả tháng').last);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Chia sẻ và tuỳ chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi ngày'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không chọn được ngày trước khi Teddy chào đời.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Xong').last);
      await tester.pumpAndSettle();
      expect(repo.updates.single.$2, {'kind': 'date', 'date': '2026-09-20'});
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('v1.0 10b: by week of age, Hiển thị, Đi tới tuần, tháng tuổi', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      await _tab(tester, 'Ảnh');
      expect(find.text('Theo tuần tuổi'), findsOneWidget);
      expect(find.text('Ảnh & video'), findsOneWidget);
      expect(find.text('Tuần thứ 4'), findsOneWidget);
      expect(find.textContaining('8 – 14 tháng 10 ·'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photoScrubber')));
      await tester.pumpAndSettle();
      expect(find.text('Đi tới tuần'), findsOneWidget);
      expect(find.text('Tuần thứ 4'), findsNWidgets(2));
      Navigator.of(tester.element(find.text('Đi tới tuần'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ảnh & video'));
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị'), findsOneWidget);
      expect(find.text('Chỉ ảnh'), findsOneWidget);
      expect(find.text('Đã yêu thích'), findsOneWidget);
      await tester.tap(find.text('Chỉ video'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉ video'), findsOneWidget);
      expect(find.textContaining('ảnh,'), findsNothing);

      await tester.tap(find.text('Theo tuần tuổi'));
      await tester.pumpAndSettle();
      expect(find.text('Xem ảnh theo'), findsOneWidget);
      await tester.tap(find.text('Tháng tuổi'));
      await tester.pumpAndSettle();
      expect(find.text('Theo tháng tuổi'), findsOneWidget);
      expect(find.text('Tháng thứ 1'), findsOneWidget);
    });

    testWidgets('"Đi tới tháng": months without media are disabled (10b5)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      await _tab(tester, 'Ảnh');
      await _byMonth(tester);
      await tester.tap(find.byKey(const Key('photoScrubber')));
      await tester.pumpAndSettle();
      expect(find.text('Đi tới tháng'), findsOneWidget);
      expect(find.text('10 mục'), findsOneWidget);
      expect(find.text('3 mục'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(10));
    });
  });

  group('10h compose', () {
    testWidgets(
      'a milestone from the age-based list and Chỉ ba mẹ reach the session',
      (tester) async {
        final repo = FakeMemoryRepository();
        await pumpRouted(
          tester,
          const Scaffold(body: MemoriesScreen()),
          overrides: [
            ...careOverrides(),
            ...memoryOverrides(repo: repo),
          ],
        );
        // Compose for two picked photos, as after 10g.
        final element = tester.element(find.byType(MemoriesScreen));
        final ref = element as WidgetRef;
        unawaited(
          showComposeSheet(element, ref, memoryCtx(element, ref)!, [
            pickedPhoto('a.HEIC'),
            pickedPhoto('b.HEIC'),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tải lên 2 mục'), findsOneWidget);
        await tester.tap(find.text('Mốc'));
        await tester.pumpAndSettle();
        expect(find.text('Gợi ý cho bé 3 tuần'), findsOneWidget);
        await tester.tap(find.text('Lần đầu tắm'));
        await tester.tap(find.text('Xong'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chỉ ba mẹ'));
        await tester.pump();
        expect(find.text('Báo cho gia đình'), findsNothing);
        await tester.tap(find.text('Tải lên 2 mục'));
        await tester.pumpAndSettle();
        final r = repo.sessions.single;
        expect(r['audience'], 'parents');
        expect(r['notifyFamily'], false);
        expect((r['milestone']! as Map)['name'], 'Lần đầu tắm');
        expect(r['items'], hasLength(2));
      },
    );
  });
}
