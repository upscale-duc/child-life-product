import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';
import '../care/care_models.dart';
import 'memory_models.dart';

/// Albums, favourites, loves and messages (S10, Figma 10d–10e10, 11a–11h). Mirrors
/// `packages/contracts/src/albums.ts`.

String newAlbumId() => 'alb_${const Uuid().v4().replaceAll('-', '')}';
String newMessageId() => 'msg_${const Uuid().v4().replaceAll('-', '')}';

/// 10e7: Mới nhất (default) · Cũ nhất · Mới thêm vào album.
enum AlbumSort { newest, oldest, added }

@immutable
class Album {
  const Album({
    required this.id,
    required this.name,
    required this.audience,
    this.sort = AlbumSort.newest,
    this.coverMediaId,
    this.photos = 0,
    this.videos = 0,
    this.loveCount = 0,
    this.createdBy = '',
    this.author,
    this.updatedAt,
  });

  final String id;
  final String name;
  final Audience audience;
  final AlbumSort sort;
  final String? coverMediaId;
  final int photos;
  final int videos;
  final int loveCount;
  final String createdBy;
  final CareAuthor? author;

  /// "cập nhật hôm qua": when something last joined.
  final DateTime? updatedAt;

  int get count => photos + videos;

  static Album? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    final name = j?['name'];
    if (j == null || name is! String) return null;
    final counts = j['counts'] is Map ? j['counts'] as Map : const {};
    return Album(
      id: doc.id,
      name: name,
      audience: Audience.values.asNameMap()[j['audience']] ?? Audience.parents,
      sort: AlbumSort.values.asNameMap()[j['sort']] ?? AlbumSort.newest,
      coverMediaId: j['coverMediaId'] as String?,
      photos: (counts['photos'] as num?)?.toInt() ?? 0,
      videos: (counts['videos'] as num?)?.toInt() ?? 0,
      loveCount: (j['loveCount'] as num?)?.toInt() ?? 0,
      createdBy: j['createdBy'] as String? ?? '',
      author: j['author'] == null ? null : CareAuthor.fromJson(j['author']),
      updatedAt: dateOf(j['contentUpdatedAt']) ?? dateOf(j['createdAt']),
    );
  }
}

/// What can be loved ("Thương").
enum LoveTarget { media, memory, album, story }

String loveIdOf(LoveTarget t, String targetId, String uid) =>
    '${t.name}__${targetId}__$uid';
String favoriteIdOf(String uid, String mediaId) => '${uid}__$mediaId';

@immutable
class Love {
  const Love({
    required this.uid,
    required this.target,
    required this.targetId,
    required this.author,
  });
  final String uid;
  final LoveTarget target;
  final String targetId;
  final CareAuthor author;

  static Love? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    final target = LoveTarget.values.asNameMap()[j?['target']];
    if (j == null || target == null) return null;
    return Love(
      uid: j['uid'] as String? ?? '',
      target: target,
      targetId: j['targetId'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
    );
  }
}

/// "Nhắn ba mẹ" (D-034).
enum MessageContext { media, memory, album, story, record }

@immutable
class ParentMessage {
  const ParentMessage({
    required this.id,
    required this.from,
    required this.author,
    required this.context,
    required this.contextId,
    required this.text,
    required this.createdAt,
    this.readBy = const {},
  });

  final String id;
  final String from;
  final CareAuthor author;
  final MessageContext context;
  final String contextId;
  final String text;
  final DateTime createdAt;
  final Set<String> readBy;

  bool readByUid(String uid) => readBy.contains(uid);

  static ParentMessage? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final j = doc.data();
    if (j == null) return null;
    final ctx = j['context'] is Map ? j['context'] as Map : const {};
    final kind = MessageContext.values.asNameMap()[ctx['kind']];
    if (kind == null) return null;
    return ParentMessage(
      id: doc.id,
      from: j['from'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      context: kind,
      contextId: ctx['id'] as String? ?? '',
      text: j['text'] as String? ?? '',
      createdAt: dateOf(j['createdAt']) ?? DateTime.now(),
      readBy: {
        for (final e
            in (j['readBy'] is Map ? j['readBy'] as Map : const {}).entries)
          if (e.value == true) e.key as String,
      },
    );
  }
}

/// Items of an album in its sort order (10e7). [addedAt] is per item ("Mới thêm vào album").
List<MediaItem> sortAlbumItems(
  List<MediaItem> items,
  AlbumSort sort,
  Map<String, DateTime> addedAt,
) {
  final list = [...items];
  switch (sort) {
    case AlbumSort.newest:
      list.sort((a, b) => b.captureAt.compareTo(a.captureAt));
    case AlbumSort.oldest:
      list.sort((a, b) => a.captureAt.compareTo(b.captureAt));
    case AlbumSort.added:
      list.sort(
        (a, b) => (addedAt[b.id] ?? b.captureAt).compareTo(
          addedAt[a.id] ?? a.captureAt,
        ),
      );
  }
  return list;
}

/// "Bà nội, Ông ngoại thương" (parents) or "2 lượt thương" — names of who loved [targetId].
List<CareAuthor> loversOf(
  Iterable<Love> loves,
  LoveTarget t,
  String targetId,
) => [
  for (final l in loves)
    if (l.target == t && l.targetId == targetId) l.author,
];

/// Membership for the message author check.
CareAuthor authorOf(Membership m) => CareAuthor.of(m);
