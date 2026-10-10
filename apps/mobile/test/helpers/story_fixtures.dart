import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/stories/story_models.dart';
import 'package:child_life/features/stories/story_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'family_fixtures.dart';
import 'memory_fixtures.dart';

/// S12 fixtures on the 10a mock: the 14a list (suggestion, collage, 1 photo, letter draft, AI
/// draft row) and the 14g story "Tuần Teddy biết cười".

String sid(int n) => 'sto_${n.toString().padLeft(32, '0')}';

List<Story> mockStories(({List<Memory> memories, List<MediaItem> media}) j) {
  final photos = [
    for (final m in j.media)
      if (!m.isVideo) m.id,
  ];
  final at = DateTime.utc(2026, 10, 8, 3);
  final mom = CareAuthor.of(mai);
  final dad = CareAuthor.of(minh);
  Story story(
    int n, {
    required String title,
    required List<StoryBlock> blocks,
    String? cover,
    StoryStatus status = StoryStatus.saved,
    String origin = 'manual',
    bool suggestion = false,
    StoryKind kind = StoryKind.story,
    Audience audience = Audience.family,
    String createdBy = 'u_mai',
    CareAuthor? author,
    DateTime? when,
    int loves = 0,
    ({String name, DateTime date})? milestone,
  }) => Story(
    id: sid(n),
    babyId: teddyId,
    kind: kind,
    origin: origin,
    suggestion: suggestion,
    status: status,
    title: title,
    coverMediaId: cover,
    blocks: blocks,
    audience: audience,
    createdBy: createdBy,
    author: author ?? mom,
    createdAt: when ?? at,
    updatedAt: when ?? at,
    savedAt: status == StoryStatus.saved ? (when ?? at) : null,
    rangeStart: DateTime(2026, 10, 1),
    rangeEnd: DateTime(2026, 10, 8),
    sourcePhotos: 9,
    milestone: milestone,
    loveCount: loves,
  );

  return [
    story(
      1,
      title: 'Tuần Teddy biết cười',
      cover: photos[0],
      origin: 'ai',
      suggestion: true,
      status: StoryStatus.draft,
      createdBy: 'ai',
      milestone: (name: 'Lần đầu cười', date: DateTime(2026, 10, 5)),
      blocks: [
        const ParagraphBlock(
          'b0',
          'Sáng thứ Hai, khi mẹ vừa hát xong câu ru quen thuộc, Teddy bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất.',
          ai: true,
        ),
        PhotosBlock('b1', [StoryPhoto(photos[1]), StoryPhoto(photos[2])]),
        const ParagraphBlock(
          'b2',
          'Chiều hôm đó, ba bế con ra ban công. Nắng nhạt, gió nhẹ, và con lại cười lần nữa — lần này nhìn thẳng vào ba.',
          ai: true,
        ),
        MilestoneBlock('b3', 'Lần đầu cười', DateTime(2026, 10, 5)),
      ],
    ),
    story(
      2,
      title: 'Tuần Teddy biết cười',
      cover: photos[0],
      loves: 6,
      milestone: (name: 'Lần đầu cười', date: DateTime(2026, 10, 5)),
      blocks: [
        const ParagraphBlock(
          'b0',
          'Sáng thứ Hai, khi mẹ vừa hát xong câu ru “Ầu ơ ví dầu”, Teddy bỗng nhoẻn miệng cười.',
        ),
        PhotosBlock('b1', [
          StoryPhoto(photos[1], 'Ban công'),
          StoryPhoto(photos[2]),
        ]),
        const QuoteBlock('b2', 'Như thể con cũng thuộc lời ru ấy.'),
        const ParagraphBlock(
          'b3',
          'Chiều hôm đó, ba bế con ra ban công. Nắng nhạt, gió nhẹ, và con lại cười lần nữa.',
        ),
        PhotosBlock('b4', [
          for (final p in photos.skip(3).take(4)) StoryPhoto(p),
        ]),
      ],
    ),
    story(
      3,
      title: 'Đêm đầu ngủ một mạch',
      cover: photos[3],
      loves: 4,
      when: at.subtract(const Duration(days: 3)),
      blocks: [const ParagraphBlock('b0', '4 tiếng không thức giấc.')],
    ),
    story(
      4,
      title: 'Thư gửi Teddy tuổi 18',
      kind: StoryKind.letter,
      status: StoryStatus.draft,
      audience: Audience.parents,
      when: at.subtract(const Duration(days: 1)),
      blocks: [
        const ParagraphBlock(
          'b0',
          'Con yêu, khi con đọc những dòng này, có lẽ con đã cao hơn mẹ rồi. Mẹ muốn kể con nghe về đêm đầu tiên…',
        ),
      ],
    ),
    story(
      5,
      title: 'Lần đầu gặp ông bà',
      cover: photos[4],
      origin: 'ai',
      suggestion: true,
      status: StoryStatus.draft,
      createdBy: 'ai',
      when: at.subtract(const Duration(days: 2)),
      blocks: [const ParagraphBlock('b0', 'Ông bà sang thăm.', ai: true)],
    ),
    story(
      6,
      title: 'Lần đầu nắm tay ba',
      cover: photos[5],
      author: dad,
      createdBy: 'u_minh',
      audience: Audience.parents,
      when: at.subtract(const Duration(days: 6)),
      blocks: [const ParagraphBlock('b0', 'Bàn tay nhỏ xíu.')],
    ),
  ];
}

/// What the story screens asked for.
class FakeStoryRepository extends Fake implements StoryRepository {
  final saves = <(String, Audience, bool)>[];
  final drafts = <Story>[];
  final deleted = <String>[];
  final assists = <(StoryAssistOp, String)>[];
  List<String> assistReply = const [
    'Teddy bỗng nhoẻn miệng cười, như thể con cũng thuộc lời ru ấy.',
  ];
  String? assistError;

  @override
  Future<void> saveDraft(
    Story story,
    String uid,
    Map<String, Object?> author, {
    required bool exists,
  }) async => drafts.add(story);

  @override
  Future<void> discard(String babyId, String storyId) async =>
      deleted.add(storyId);

  @override
  Future<({int madeVisible, bool notified})> save(
    String babyId,
    String storyId,
    Audience audience,
    bool notifyFamily,
  ) async {
    saves.add((storyId, audience, notifyFamily));
    return (madeVisible: 1, notified: notifyFamily);
  }

  @override
  Future<void> delete(String babyId, String storyId) async =>
      deleted.add(storyId);

  @override
  Future<List<String>> assist(
    Story story,
    String blockId,
    StoryAssistOp op,
    String text,
    String locale,
  ) async {
    assists.add((op, text));
    if (assistError != null) throw StoryActionException(assistError!);
    return assistReply;
  }
}

List<Override> storyOverrides({
  List<Story>? stories,
  FakeStoryRepository? repo,
}) {
  final list = stories ?? mockStories(mockJournal());
  return [
    storiesProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final s in list)
          if (key.$3
              ? (s.saved || s.createdBy == key.$2 || s.createdBy == 'ai')
              : (s.saved && s.audience == Audience.family))
            s,
      ]),
    ),
    storyProvider.overrideWith(
      (ref, key) => Stream.value(list.where((s) => s.id == key.$2).firstOrNull),
    ),
    storyRepositoryProvider.overrideWithValue(repo ?? FakeStoryRepository()),
  ];
}
