import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memories_screen.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/stories/story_editor.dart';
import 'package:child_life/features/stories/story_models.dart';
import 'package:child_life/features/stories/story_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/story_fixtures.dart';

class _View extends MemoryViewState {
  @override
  MemoryView build() => const MemoryView(tab: MemoryTab.stories);
}

final _journal = mockJournal();
final _stories = mockStories(_journal);

List<Override> _overrides({
  Membership? me,
  FakeStoryRepository? repo,
  List<Story>? stories,
}) => [
  ...careOverrides(me: me),
  ...memoryOverrides(journal: _journal),
  ...storyOverrides(stories: stories ?? _stories, repo: repo),
  memoryViewProvider.overrideWith(_View.new),
];

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  test('word count and blank stories (14c, "Viết")', () {
    expect(wordCount('Sáng thứ Hai, Teddy cười.'), 5);
    expect(wordCount('  '), 0);
    final letter = Story.blank(
      babyId: teddyId,
      uid: 'u_mai',
      author: CareAuthor.of(mai),
      kind: StoryKind.letter,
    );
    expect(letter.audience, Audience.parents);
    expect(letter.id, matches(RegExp(r'^sto_[a-f0-9]{32}$')));
  });

  group('14a list', () {
    testWidgets('parents: the suggestion, drafts and saved stories', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: _overrides(),
      );
      expect(find.text('Gợi ý tuần này'), findsOneWidget);
      expect(find.text('Bản nháp · 3'), findsOneWidget);
      expect(find.text('Thư gửi Teddy tuổi 18'), findsOneWidget);
    });

    testWidgets('relatives read saved Gia đình stories only (11i)', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: MemoriesScreen()),
        overrides: _overrides(me: hoa),
      );
      expect(find.text('Gợi ý tuần này'), findsNothing);
      expect(find.text('Viết'), findsNothing);
      expect(find.text('Thư gửi Teddy tuổi 18'), findsNothing);
      await tester.dragUntilVisible(
        find.text('Đêm đầu ngủ một mạch'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      expect(find.text('Lần đầu nắm tay ba'), findsNothing);
    });
  });

  group('14b–14f editor', () {
    testWidgets(
      '"Ấm hơn" → "Dùng câu này" → preview → saved for the family with a notice',
      (tester) async {
        final repo = FakeStoryRepository();
        await pumpRouted(
          tester,
          StoryEditorScreen(storyId: sid(1)),
          overrides: _overrides(repo: repo),
        );
        await tester.tap(find.text(_stories.first.firstText));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ấm hơn').last);
        await tester.pumpAndSettle();
        expect(repo.assists.single.$1, StoryAssistOp.warmer);
        await tester.tap(find.text('Dùng câu này'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xong'));
        await tester.pumpAndSettle();
        expect(find.text(repo.assistReply.first), findsOneWidget);

        await tester.tap(find.text('Xem trước & lưu'));
        await tester.pumpAndSettle();
        expect(
          repo.drafts.single.blocks.whereType<ParagraphBlock>().first.text,
          repo.assistReply.first,
        );
        await tester.tap(find.text('Lưu câu chuyện').last);
        await tester.pumpAndSettle();
        expect(repo.saves.single, (sid(1), Audience.family, true));
      },
    );

    testWidgets(
      'AI unavailable is said plainly; editing by hand still works (G-051)',
      (tester) async {
        final repo = FakeStoryRepository()..assistError = 'ai-unavailable';
        await pumpRouted(
          tester,
          StoryEditorScreen(storyId: sid(1)),
          overrides: _overrides(repo: repo),
        );
        await tester.tap(find.text(_stories.first.firstText));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Viết lại').last);
        await tester.pumpAndSettle();
        expect(
          find.text('AI chưa sẵn sàng. Bạn vẫn sửa tay được.'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(EditableText).first, 'Teddy cười.');
        await tester.pump();
        expect(find.text('Đã sửa · không còn là văn AI'), findsOneWidget);
      },
    );

    testWidgets('a story needs a title before preview', (tester) async {
      final blank = Story.blank(
        babyId: teddyId,
        uid: 'u_mai',
        author: CareAuthor.of(mai),
      );
      await pumpRouted(
        tester,
        StoryEditorScreen(storyId: blank.id, initial: blank),
        overrides: _overrides(),
      );
      await tester.tap(find.text('Xem trước & lưu'));
      await tester.pump();
      expect(find.text('Đặt tiêu đề cho câu chuyện.'), findsOneWidget);
    });

    testWidgets('14e: swiping a block away removes it', (tester) async {
      await pumpRouted(
        tester,
        StoryEditorScreen(storyId: sid(1)),
        overrides: _overrides(),
      );
      await tester.tap(find.text('Sắp xếp'));
      await tester.pumpAndSettle();
      final row = find.textContaining('Chiều hôm đó');
      await tester.drag(row, const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chiều hôm đó'), findsNothing);
    });
  });

  group('14g / 11i reader', () {
    testWidgets('a parent deletes a story (G-050)', (tester) async {
      final repo = FakeStoryRepository();
      await pumpRouted(
        tester,
        StoryReaderScreen(storyId: sid(2)),
        overrides: _overrides(repo: repo),
      );
      await tester.tap(find.bySemanticsLabel('Tuỳ chọn câu chuyện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá câu chuyện').last);
      await tester.pumpAndSettle();
      expect(repo.deleted, [sid(2)]);
    });

    testWidgets('a relative loves it and writes to the parents', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        StoryReaderScreen(storyId: sid(2)),
        overrides: _overrides(me: hoa),
      );
      expect(find.text('Sửa'), findsNothing);
      await tester.tap(find.text('Nhắn ba mẹ…'));
      await tester.pumpAndSettle();
      expect(find.text('Gửi'), findsOneWidget);
    });
  });
}
