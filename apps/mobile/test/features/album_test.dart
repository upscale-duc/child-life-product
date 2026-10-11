import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/album_models.dart';
import 'package:child_life/features/memories/album_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

class _View extends MemoryViewState {
  _View(this.initial);
  final MemoryView initial;
  @override
  MemoryView build() => initial;
}

final _journal = mockJournal();
final _albums = mockAlbums(_journal.media);
final _bath = _albums.albums.first;

Future<void> _pumpAlbums(
  WidgetTester tester, {
  FakeMemoryRepository? repo,
  Membership? me,
}) => pumpRouted(
  tester,
  const Scaffold(body: MemoriesScreen()),
  overrides: [
    ...careOverrides(me: me),
    ...memoryOverrides(journal: _journal, repo: repo),
    memoryViewProvider.overrideWith(
      () => _View(const MemoryView(tab: MemoryTab.albums)),
    ),
  ],
);

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  group('model', () {
    test('album items sort by capture or by when they were added (10e7)', () {
      final items = _journal.media.take(3).toList();
      final byCapture = [...items]
        ..sort((a, b) => b.captureAt.compareTo(a.captureAt));
      expect(sortAlbumItems(items, AlbumSort.newest, const {}), byCapture);
      expect(
        sortAlbumItems(items, AlbumSort.oldest, const {}),
        byCapture.reversed.toList(),
      );
      final added = {
        items[0].id: DateTime.utc(2026, 10, 1),
        items[1].id: DateTime.utc(2026, 10, 9),
        items[2].id: DateTime.utc(2026, 10, 5),
      };
      expect(sortAlbumItems(items, AlbumSort.added, added).map((m) => m.id), [
        items[1].id,
        items[2].id,
        items[0].id,
      ]);
    });

    test('lovers of one target only', () {
      final loves = mockLoves(_journal);
      final first = _journal.memories.first.id;
      expect(loversOf(loves, LoveTarget.memory, first).map((a) => a.name), [
        hoa.displayName,
        minh.displayName,
      ]);
      expect(loversOf(loves, LoveTarget.media, first), isEmpty);
    });
  });

  group('10d Album', () {
    testWidgets('a parent sees Yêu thích, every album and "Album mới"', (
      tester,
    ) async {
      await _pumpAlbums(tester);
      expect(find.text('3 album'), findsOneWidget);
      expect(find.text('Yêu thích'), findsOneWidget);
      expect(find.text('Giờ tắm'), findsOneWidget);
      expect(find.text('Ngủ ngoan'), findsOneWidget);
      expect(find.text('Album mới'), findsOneWidget);
    });

    testWidgets('an empty album says so on its cover, not "0 ảnh"', (
      tester,
    ) async {
      final empty = Album(
        id: 'alb_${'e' * 32}',
        name: 'Ngày đầu đi dạo',
        audience: Audience.family,
        photos: 0,
        videos: 0,
        loveCount: 0,
        createdBy: 'u_mai',
        author: CareAuthor.of(mai),
        updatedAt: DateTime.utc(2026, 10, 8, 12),
      );
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(
            journal: _journal,
            withAlbums: false,
            extraAlbums: [empty],
            favorites: const {},
          ),
          memoryViewProvider.overrideWith(
            () => _View(const MemoryView(tab: MemoryTab.albums)),
          ),
        ],
      );
      await tester.pumpAndSettle();
      // Yêu thích and the new album are both empty; only the album invites adding.
      expect(find.text('Chưa có ảnh'), findsNWidgets(2));
      expect(find.text('Thêm ảnh'), findsOneWidget);
      expect(find.text('0 ảnh'), findsNothing);
    });

    testWidgets(
      'a relative sees only Gia đình albums and cannot create (11e)',
      (tester) async {
        await _pumpAlbums(tester, me: hoa);
        expect(find.text('2 album ba mẹ chia sẻ'), findsOneWidget);
        expect(find.text('Giờ tắm'), findsOneWidget);
        expect(find.text('Ngủ ngoan'), findsNothing);
        expect(find.text('Album mới'), findsNothing);
      },
    );

    testWidgets('"Album mới" needs a name, then creates it (10e10)', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      await _pumpAlbums(tester, repo: repo);
      await tester.tap(find.text('Album mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo album'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt tên cho album.'), findsOneWidget);
      expect(repo.albumCalls, isEmpty);

      await tester.tap(find.text('Bàn tay nhỏ').last);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^Chỉ ba mẹ')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo album'));
      await tester.pumpAndSettle();
      expect(repo.albumCalls.single.$1, 'create');
      expect(repo.albumCalls.single.$2, {
        'name': 'Bàn tay nhỏ',
        'audience': 'parents',
        'mediaIds': <String>[],
      });
      expect(find.text('Đã tạo album “Bàn tay nhỏ”'), findsOneWidget);
    });
  });

  group('10e album', () {
    testWidgets('"Ai thấy album này" → Chỉ ba mẹ asks the server once (10e6)', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      await pumpRouted(
        tester,
        AlbumDetailScreen(albumKey: _bath.id),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(journal: _journal, repo: repo),
        ],
      );
      await tester.tap(find.bySemanticsLabel('Tuỳ chọn album'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ai thấy album này'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^Chỉ ba mẹ')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(repo.albumCalls.single.$2, {
        'albumId': _bath.id,
        'kind': 'audience',
        'audience': 'parents',
        'notifyFamily': false,
      });
      expect(find.text('Đã đổi ai thấy album'), findsOneWidget);
    });

    testWidgets('a relative has no album options (R-104)', (tester) async {
      await pumpRouted(
        tester,
        AlbumDetailScreen(albumKey: _bath.id),
        overrides: [
          ...careOverrides(me: hoa),
          ...memoryOverrides(journal: _journal),
        ],
      );
      expect(find.text('Giờ tắm'), findsWidgets);
      expect(find.bySemanticsLabel('Tuỳ chọn album'), findsNothing);
    });
  });

  group('11c loves and messages', () {
    testWidgets('a relative loves an entry and messages the parents', (
      tester,
    ) async {
      final repo = FakeMemoryRepository();
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(me: hoa),
          startOn(MemoryTab.journal),
          ...memoryOverrides(journal: _journal, repo: repo),
        ],
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Thương')).first);
      await tester.pumpAndSettle();
      expect(repo.loves.single, (
        LoveTarget.memory,
        _journal.memories.first.id,
        true,
      ));

      await tester.tap(find.bySemanticsLabel(RegExp('^Nhắn ba mẹ')).first);
      await tester.pumpAndSettle();
      expect(find.text('Gửi'), findsOneWidget);
      await tester.enterText(
        find.byType(EditableText),
        '  Bà thương con quá!  ',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();
      expect(repo.messages.single, (
        MessageContext.memory,
        _journal.memories.first.id,
        'Bà thương con quá!',
      ));
      expect(find.text('Đã gửi lời nhắn'), findsOneWidget);
    });

    testWidgets('a parent reads who loved it, not a love count (10a)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: [
          ...careOverrides(),
          startOn(MemoryTab.journal),
          ...memoryOverrides(journal: _journal, loves: mockLoves(_journal)),
        ],
      );
      expect(find.textContaining(' thương'), findsWidgets);
      expect(find.textContaining('lượt thương'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Nhắn ba mẹ')), findsNothing);
    });

    testWidgets('"Lời nhắn" lists messages for the parents (D-034)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const MessagesScreen(),
        overrides: [
          ...careOverrides(),
          ...memoryOverrides(
            journal: _journal,
            messages: mockMessages(_journal),
          ),
        ],
      );
      expect(find.text('Lời nhắn'), findsWidgets);
      expect(
        find.text('Bà thương con quá! Cuối tuần bà sang nhé.'),
        findsOneWidget,
      );
    });
  });
}
