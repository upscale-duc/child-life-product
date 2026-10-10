import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../care/care_models.dart';
import '../memories/memory_models.dart';

/// Stories (S12, 14a–14g, 11i). Mirrors `packages/contracts/src/stories.ts`.

String newStoryId() => 'sto_${const Uuid().v4().replaceAll('-', '')}';

int _blockSeq = 0;
String newBlockId() =>
    'b${DateTime.now().microsecondsSinceEpoch.toRadixString(36).substring(4)}${(_blockSeq++ % 36).toRadixString(36)}';

/// Limits shared with the server (R-133, R-196).
abstract final class StoryLimits {
  static const titleMax = 120;
  static const paragraphMax = 2000;
  static const quoteMax = 280;
  static const captionMax = 140;
  static const photosPerGroup = 4;
  static const blocksMax = 40;
}

enum StoryKind { story, letter }

enum StoryStatus { draft, saved }

@immutable
sealed class StoryBlock {
  const StoryBlock(this.id);
  final String id;

  Map<String, Object?> toJson();

  static StoryBlock? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'] as String? ?? newBlockId();
    return switch (json['type']) {
      'paragraph' => ParagraphBlock(
        id,
        json['text'] as String? ?? '',
        ai: json['ai'] == true,
      ),
      'photos' => PhotosBlock(id, [
        for (final i in (json['items'] as List? ?? const []))
          if (i is Map && i['mediaId'] is String)
            StoryPhoto(i['mediaId'] as String, i['caption'] as String?),
      ]),
      'milestone' => MilestoneBlock(
        id,
        json['name'] as String? ?? '',
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
      ),
      'quote' => QuoteBlock(id, json['text'] as String? ?? ''),
      _ => null,
    };
  }
}

class ParagraphBlock extends StoryBlock {
  const ParagraphBlock(super.id, this.text, {this.ai = false});
  final String text;

  /// Still the AI's words ("Đã sửa · không còn là văn AI" once edited, R-132).
  final bool ai;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'type': 'paragraph',
    'text': text,
    'ai': ai,
  };
}

@immutable
class StoryPhoto {
  const StoryPhoto(this.mediaId, [this.caption]);
  final String mediaId;
  final String? caption;
}

class PhotosBlock extends StoryBlock {
  const PhotosBlock(super.id, this.items);
  final List<StoryPhoto> items;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'type': 'photos',
    'items': [
      for (final i in items) {'mediaId': i.mediaId, 'caption': i.caption},
    ],
  };
}

class MilestoneBlock extends StoryBlock {
  const MilestoneBlock(super.id, this.name, this.date);
  final String name;
  final DateTime date;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'type': 'milestone',
    'name': name,
    'date': isoDateOf(date),
  };
}

class QuoteBlock extends StoryBlock {
  const QuoteBlock(super.id, this.text);
  final String text;

  @override
  Map<String, Object?> toJson() => {'id': id, 'type': 'quote', 'text': text};
}

@immutable
class Story {
  const Story({
    required this.id,
    required this.babyId,
    required this.kind,
    required this.origin,
    required this.suggestion,
    required this.status,
    required this.title,
    required this.coverMediaId,
    required this.blocks,
    required this.audience,
    required this.createdBy,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.savedAt,
    this.rangeStart,
    this.rangeEnd,
    this.sourcePhotos = 0,
    this.milestone,
    this.loveCount = 0,
  });

  final String id;
  final String babyId;
  final StoryKind kind;

  /// 'ai' (weekly suggestion) or 'manual' ("Viết").
  final String origin;

  /// A suggestion nobody took yet ("Nháp từ gợi ý · chưa lưu").
  final bool suggestion;
  final StoryStatus status;
  final String title;
  final String? coverMediaId;
  final List<StoryBlock> blocks;
  final Audience audience;
  final String createdBy;
  final CareAuthor? author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? savedAt;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final int sourcePhotos;
  final ({String name, DateTime date})? milestone;
  final int loveCount;

  bool get isAiDraft => origin == 'ai' && status == StoryStatus.draft;
  bool get saved => status == StoryStatus.saved;

  /// Cover first, then every photo in the blocks.
  List<String> get mediaIds => {
    ?coverMediaId,
    for (final b in blocks)
      if (b is PhotosBlock)
        for (final i in b.items) i.mediaId,
  }.toList();

  String get firstText => blocks
      .whereType<ParagraphBlock>()
      .map((b) => b.text)
      .firstWhere((t) => t.trim().isNotEmpty, orElse: () => '');

  factory Story.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    DateTime? date(Object? v) =>
        v is Timestamp ? v.toDate() : DateTime.tryParse('${v ?? ''}');
    final ms = m['milestone'];
    return Story(
      id: d.id,
      babyId: m['babyId'] as String? ?? '',
      kind: m['kind'] == 'letter' ? StoryKind.letter : StoryKind.story,
      origin: m['origin'] as String? ?? 'manual',
      suggestion: m['suggestion'] == true,
      status: m['status'] == 'saved' ? StoryStatus.saved : StoryStatus.draft,
      title: m['title'] as String? ?? '',
      coverMediaId: m['coverMediaId'] as String?,
      blocks: [
        for (final b in (m['blocks'] as List? ?? const []))
          ?StoryBlock.fromJson(b),
      ],
      audience: m['audience'] == 'parents' ? Audience.parents : Audience.family,
      createdBy: m['createdBy'] as String? ?? '',
      author: m['author'] == null ? null : CareAuthor.fromJson(m['author']),
      createdAt: date(m['createdAt']) ?? DateTime(2000),
      updatedAt: date(m['updatedAt']) ?? DateTime(2000),
      savedAt: date(m['savedAt']),
      rangeStart: date(m['rangeStart']),
      rangeEnd: date(m['rangeEnd']),
      sourcePhotos: (m['sourcePhotos'] as num?)?.toInt() ?? 0,
      milestone: ms is Map && ms['name'] is String
          ? (
              name: ms['name'] as String,
              date: DateTime.tryParse('${ms['date']}') ?? DateTime(2000),
            )
          : null,
      loveCount: (m['loveCount'] as num?)?.toInt() ?? 0,
    );
  }

  Story copyWith({
    StoryKind? kind,
    String? title,
    String? coverMediaId,
    bool clearCover = false,
    List<StoryBlock>? blocks,
    Audience? audience,
  }) => Story(
    id: id,
    babyId: babyId,
    kind: kind ?? this.kind,
    origin: origin,
    suggestion: suggestion,
    status: status,
    title: title ?? this.title,
    coverMediaId: clearCover ? null : coverMediaId ?? this.coverMediaId,
    blocks: blocks ?? this.blocks,
    audience: audience ?? this.audience,
    createdBy: createdBy,
    author: author,
    createdAt: createdAt,
    updatedAt: updatedAt,
    savedAt: savedAt,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    sourcePhotos: sourcePhotos,
    milestone: milestone,
    loveCount: loveCount,
  );

  /// A new, empty story or letter ("Viết").
  factory Story.blank({
    required String babyId,
    required String uid,
    required CareAuthor author,
    StoryKind kind = StoryKind.story,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return Story(
      id: newStoryId(),
      babyId: babyId,
      kind: kind,
      origin: 'manual',
      suggestion: false,
      status: StoryStatus.draft,
      title: '',
      coverMediaId: null,
      blocks: [ParagraphBlock(newBlockId(), '')],
      // Letters are private by default ("Thư gửi Teddy tuổi 18 · Chỉ ba mẹ").
      audience: kind == StoryKind.letter ? Audience.parents : Audience.family,
      createdBy: uid,
      author: author,
      createdAt: at,
      updatedAt: at,
    );
  }
}

/// Words in a paragraph ("42 từ").
int wordCount(String text) =>
    text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

enum StoryAssistOp { rewrite, shorter, warmer, suggest }

class StoryActionException implements Exception {
  const StoryActionException(this.reason);
  final String reason;
}
