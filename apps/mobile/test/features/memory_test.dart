import 'dart:async';

import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_sheets.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
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
      QueueItem item(String id, QueueState state) => QueueItem(
        mediaId: id,
        type: MediaKind.photo,
        name: 'IMG.jpg',
        localPath: '/nowhere/$id.jpg',
        contentType: 'image/jpeg',
        bytes: 10,
        captureAt: at,
        state: state,
      );
      final processing = mediaItem('mem1', at, status: MediaStatus.uploading);
      final ready = mediaItem('mem1', at);
      final queue = QueueView(
        batches: [
          QueueBatch(
            batchId: 'b1',
            babyId: teddyId,
            memoryId: 'mem1',
            request: const {'audience': 'family'},
            createdAt: at,
            items: [
              item(processing.id, QueueState.uploaded),
              item(ready.id, QueueState.uploaded),
              item('med_sending', QueueState.uploading),
              item('med_failed', QueueState.failed),
            ],
          ),
        ],
      );
      final cells = landingCells(
        queue,
        [processing, ready],
        const MemoryView(),
        teddyId,
      );
      // Sent but still processing, and still sending; not the ready or the failed one.
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
    testWidgets('a swipe moves between Nhật ký, Ảnh and Album', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      final pages = find.byKey(const Key('memoryPages'));
      expect(find.text('Tuần thứ 4'), findsOneWidget);
      await tester.fling(pages, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Tuần thứ 4'), findsNothing);
      await tester.fling(pages, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Album mới'), findsOneWidget);
      // A tap on a title slides back.
      await tester.ensureVisible(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      expect(find.text('Tuần thứ 4'), findsOneWidget);
    });

    testWidgets('Ảnh says what is still landing, as a tile in the grid', (
      tester,
    ) async {
      final j = mockJournal();
      final processing = mediaItem(
        'mem1',
        DateTime(2026, 10, 8, 14),
        status: MediaStatus.uploading,
      );
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(
            journal: (memories: j.memories, media: [processing, ...j.media]),
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

  group('10a Nhật ký', () {
    testWidgets('weeks of life with ranges and counts; entries with labels', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [...careOverrides(), ...memoryOverrides()],
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
          overrides: [...careOverrides(), ...memoryOverrides()],
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
      expect(find.text('Tháng 10, 2026'), findsOneWidget);
      expect(find.text('7 ảnh · 3 video'), findsOneWidget);
      await tester.tap(find.text('Chọn'));
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
      await tester.tap(find.text('Chọn'));
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
      await tester.tap(find.text('Chọn'));
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

    testWidgets('"Đi tới tháng": months without media are disabled (10b5)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [...careOverrides(), ...memoryOverrides()],
      );
      await _tab(tester, 'Ảnh');
      await tester.tap(find.text('Tháng'));
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
