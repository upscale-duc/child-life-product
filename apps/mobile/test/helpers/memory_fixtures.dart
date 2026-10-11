import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/memories/album_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/memories/memory_repository.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'family_fixtures.dart';

/// Solid-colour stand-ins for media bytes ("Illustration/Photo — privacy-safe").
const _png = {
  'peach':
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGP4dmQFVsQwtCQAqb2YgeXVOTYAAAAASUVORK5CYII=',
  'mint':
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGNY8egCVsQwtCQAxC6WgZK3vlgAAAAASUVORK5CYII=',
  'sky':
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGPYcO4DVsQwtCQAskybgfIiSUsAAAAASUVORK5CYII=',
  'sun':
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGP49WAaVsQwtCQADVucASDPH/kAAAAASUVORK5CYII=',
  'lilac':
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGO4cuQDVsQwtCQARXmiAS65nLcAAAAASUVORK5CYII=',
};

Uint8List pngOf(String colour) => base64Decode(_png[colour] ?? _png['mint']!);

class FakeMediaBytes implements MediaBytes {
  @override
  Future<Uint8List> read(String path) async => pngOf(path.split('/').last);

  @override
  Future<File> file(String path) async =>
      throw UnsupportedError('no files in tests');
}

DateTime _vn(int month, int day, int h, int m) =>
    DateTime.utc(2026, month, day, h - 7, m).toLocal();

var _seq = 0;
String _id(String p) => '${p}_${(++_seq).toRadixString(16).padLeft(32, '0')}';

MediaItem mediaItem(
  String memoryId,
  DateTime at, {
  String colour = 'mint',
  bool video = false,
  int? durationMs,
  bool private = false,
  Membership? by,
  MilestoneRef? milestone,
  int position = 0,
  MediaStatus status = MediaStatus.ready,
}) {
  final author = by ?? mai;
  final audience = private ? Audience.parents : Audience.family;
  return MediaItem(
    id: _id('med'),
    babyId: teddyId,
    memoryId: memoryId,
    position: position,
    type: video ? MediaKind.video : MediaKind.photo,
    status: status,
    audience: audience,
    effectiveAudience: audience,
    captureAt: at,
    createdBy: author.uid,
    author: CareAuthor.of(author),
    durationMs: durationMs,
    width: 1200,
    height: 900,
    milestone: milestone,
    paths: MediaPaths(
      original: 'mock/$colour',
      display: 'mock/$colour',
      thumb: 'mock/$colour',
      poster: video ? 'mock/$colour' : null,
    ),
  );
}

/// The 10a journal at Thursday 8 Oct 15:05: two entries this week, a note and a milestone
/// grid last week (one private tile), "Ngày đầu về nhà" two weeks back.
({List<Memory> memories, List<MediaItem> media}) mockJournal() {
  final media = <MediaItem>[];
  final memories = <Memory>[];
  void add(
    Membership by,
    DateTime at,
    String? caption,
    List<MediaItem> Function(String id) items, {
    Audience audience = Audience.family,
    MilestoneRef? milestone,
    int loveCount = 0,
  }) {
    final id = _id('mem');
    final list = items(id);
    media.addAll(list);
    memories.add(
      Memory(
        id: id,
        babyId: teddyId,
        caption: caption,
        audience: audience,
        occurredAt: at,
        milestone: milestone,
        mediaIds: [for (final i in list) i.id],
        photos: list.where((i) => !i.isVideo).length,
        videos: list.where((i) => i.isVideo).length,
        createdBy: by.uid,
        author: CareAuthor.of(by),
        loveCount: loveCount,
      ),
    );
  }

  final smile = MilestoneRef(
    id: 'p_first_smile',
    name: 'Lần đầu cười',
    date: DateTime(2026, 10, 5),
  );
  final home = MilestoneRef(
    id: 'ms_${'1' * 32}',
    name: 'Ngày đầu về nhà',
    date: DateTime(2026, 9, 20),
  );
  add(
    mai,
    _vn(10, 8, 9, 20),
    'Ngủ trưa ngon lành sau giờ tắm.',
    (id) => [mediaItem(id, _vn(10, 8, 9, 20), colour: 'peach')],
    loveCount: 2,
  );
  add(
    minh,
    _vn(10, 7, 19, 5),
    'Lần đầu nắm chặt ngón tay ba.',
    (id) => [
      mediaItem(
        id,
        _vn(10, 7, 19, 5),
        colour: 'sky',
        video: true,
        durationMs: 42000,
        by: minh,
      ),
    ],
  );
  add(
    mai,
    _vn(10, 6, 16, 0),
    'Bà nội sang thăm, mang theo đôi tất len tự đan.',
    (id) => [
      mediaItem(id, _vn(10, 6, 16, 0), colour: 'sun'),
      mediaItem(id, _vn(10, 6, 16, 2), colour: 'lilac', position: 1),
    ],
  );
  add(
    mai,
    _vn(10, 5, 21, 0),
    'Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ.',
    (_) => const [],
    audience: Audience.parents,
  );
  add(
    mai,
    _vn(10, 5, 10, 0),
    null,
    (id) => [
      for (final (n, c) in [
        ('mint', false, null, false),
        ('sky', true, 24000, false),
        ('peach', false, null, false),
        ('lilac', false, null, true),
        ('sun', true, 12000, false),
        ('mint', false, null, false),
      ].indexed)
        mediaItem(
          id,
          _vn(10, 5, 10, n),
          colour: c.$1,
          video: c.$2,
          durationMs: c.$3,
          private: c.$4,
          milestone: smile,
          position: n,
        ),
    ],
    milestone: smile,
  );
  add(
    minh,
    _vn(9, 20, 11, 0),
    null,
    (id) => [
      for (final (n, c) in ['peach', 'sun', 'mint'].indexed)
        mediaItem(
          id,
          _vn(9, 20, 11, n),
          colour: c,
          by: minh,
          milestone: home,
          position: n,
        ),
    ],
    milestone: home,
  );
  media.sort((a, b) => b.captureAt.compareTo(a.captureAt));
  return (memories: memories, media: media);
}

/// What the screens asked the server to do.
class FakeMemoryRepository extends Fake implements MemoryRepository {
  final sessions = <Map<String, Object?>>[];
  final updates = <(List<String>, Map<String, Object?>)>[];
  final cancelled = <String>[];
  final waitingWifi = <String>[];
  final milestones = <String>[];
  Set<String> overQuota = {};

  /// Reserve only this many items per session; the rest wait for quota (R-121).
  int? reserveOnly;

  /// Thrown by createSession instead of answering (kill switch, refusals, outages).
  Object? refuseWith;

  /// Per-batch refusals (by `batchId`), for screens that show several states at once.
  Map<String, Object> refuseBatches = {};

  @override
  Future<({List<String> reserved, List<String> waitingQuota})> createSession(
    Map<String, Object?> request,
  ) async {
    sessions.add(request);
    if (refuseWith != null) throw refuseWith!;
    final refusal = refuseBatches[request['batchId']];
    if (refusal != null) throw refusal;
    final ids = [
      for (final i in request['items']! as List)
        (i as Map)['mediaId'] as String,
    ];
    final over = {
      ...overQuota,
      if (reserveOnly != null) ...ids.skip(reserveOnly!),
    };
    return (
      reserved: [
        for (final id in ids)
          if (!over.contains(id)) id,
      ],
      waitingQuota: [
        for (final id in ids)
          if (over.contains(id)) id,
      ],
    );
  }

  @override
  Future<List<String>> reserve(String babyId, List<String> mediaIds) async =>
      [];

  @override
  Future<void> cancel(String babyId, List<String> mediaIds) async =>
      cancelled.addAll(mediaIds);

  @override
  Future<void> markWaitingWifi(
    String babyId,
    String mediaId,
    bool waiting,
  ) async {
    if (waiting) waitingWifi.add(mediaId);
  }

  @override
  Future<void> update(
    String babyId,
    List<String> mediaIds,
    Map<String, Object?> change,
  ) async => updates.add((mediaIds, change));

  final albumCalls = <(String, Map<String, Object?>)>[];
  final favorites = <(String, bool)>[];
  final loves = <(LoveTarget, String, bool)>[];
  final messages = <(MessageContext, String, String)>[];

  @override
  Future<void> createAlbum(
    String babyId,
    String albumId,
    String name,
    Audience audience,
    List<String> mediaIds,
  ) async => albumCalls.add((
    'create',
    {'name': name, 'audience': audience.name, 'mediaIds': mediaIds},
  ));

  @override
  Future<int> updateAlbum(
    String babyId,
    String albumId,
    Map<String, Object?> change,
  ) async {
    albumCalls.add(('update', {'albumId': albumId, ...change}));
    return 0;
  }

  @override
  Future<void> addToAlbum(
    String babyId,
    String albumId,
    List<String> mediaIds,
  ) async =>
      albumCalls.add(('add', {'albumId': albumId, 'mediaIds': mediaIds}));

  @override
  Future<void> removeFromAlbum(
    String babyId,
    String albumId,
    List<String> mediaIds,
  ) async =>
      albumCalls.add(('remove', {'albumId': albumId, 'mediaIds': mediaIds}));

  @override
  Future<void> deleteAlbum(String babyId, String albumId) async =>
      albumCalls.add(('delete', {'albumId': albumId}));

  @override
  Future<void> setFavorite(
    String babyId,
    String uid,
    String mediaId,
    bool on,
  ) async => favorites.add((mediaId, on));

  @override
  Future<void> setLove(
    Membership me,
    LoveTarget target,
    String targetId,
    bool on,
  ) async => loves.add((target, targetId, on));

  @override
  Future<void> sendMessage(
    Membership me,
    MessageContext context,
    String contextId,
    String text,
  ) async => messages.add((context, contextId, text));

  @override
  Future<void> markRead(String babyId, String messageId, String uid) async {}

  @override
  Future<MilestoneRef> createMilestone(
    String babyId,
    Membership me,
    String name,
    DateTime date,
  ) async {
    milestones.add(name);
    return MilestoneRef(id: 'ms_${'9' * 32}', name: name, date: date);
  }
}

class MemoryQueueStore implements QueueStore {
  List<QueueBatch> saved = [];
  @override
  Future<List<QueueBatch>> load() async => saved;
  @override
  Future<void> save(List<QueueBatch> batches) async => saved = [...batches];
}

/// Uploads finish at once unless [fail] names the path.
class FakeTransport implements UploadTransport {
  final uploaded = <String>[];
  Set<String> fail = {};

  /// Fail this many uploads ("Mất kết nối khi đang tải").
  int failTimes = 0;

  @override
  Future<void> upload(
    String storagePath,
    File file,
    String contentType,
    void Function(int sent) onProgress,
  ) async {
    if (fail.contains(storagePath) || failTimes > 0) {
      if (failTimes > 0) failTimes--;
      throw const SocketException('offline');
    }
    onProgress(1000);
    uploaded.add(storagePath);
  }

  @override
  void cancel(String storagePath) {}
}

class FakePreparer implements MediaPreparer {
  @override
  Future<QueueItem> prepare(PickedMedia picked, String mediaId) async =>
      QueueItem(
        mediaId: mediaId,
        type: picked.type,
        name: picked.name,
        localPath: picked.file.path,
        posterPath: picked.type == MediaKind.video
            ? '${picked.file.path}.jpg'
            : null,
        contentType: picked.type == MediaKind.photo
            ? 'image/jpeg'
            : 'video/quicktime',
        bytes: picked.type == MediaKind.photo ? 3400000 : 48000000,
        captureAt: picked.captureAt,
        durationMs: picked.durationMs,
      );

  @override
  Future<void> discard(QueueItem item) async {}
}

PickedMedia pickedPhoto(String name, {DateTime? at}) => PickedMedia(
  file: File('/tmp/$name'),
  type: MediaKind.photo,
  name: name,
  captureAt: at ?? _vn(10, 8, 9, 20),
  thumbBytes: pngOf('peach'),
);

PickedMedia pickedVideo(String name, {DateTime? at}) => PickedMedia(
  file: File('/tmp/$name'),
  type: MediaKind.video,
  name: name,
  captureAt: at ?? _vn(10, 8, 9, 25),
  durationMs: 24000,
  thumbBytes: pngOf('sky'),
);

/// 10d: "Giờ tắm" (Gia đình), "Ngủ ngoan" (Chỉ ba mẹ), "Bàn tay nhỏ" (Gia đình).
({List<Album> albums, Map<String, Map<String, DateTime>> items}) mockAlbums(
  List<MediaItem> media,
) {
  final bath = 'alb_${'a' * 32}';
  final sleep = 'alb_${'b' * 32}';
  final hands = 'alb_${'c' * 32}';
  final at = DateTime.utc(2026, 10, 7, 12);
  Map<String, DateTime> of(Iterable<MediaItem> m) => {
    for (final i in m) i.id: at,
  };
  final photos = media.where((m) => !m.isVideo).toList();
  final items = {
    bath: of(media.take(4)),
    sleep: of(photos.skip(2).take(3)),
    hands: of(photos.skip(5).take(2)),
  };
  Album album(String id, String name, Audience audience) {
    final list = [
      for (final m in media)
        if (items[id]!.containsKey(m.id)) m,
    ];
    return Album(
      id: id,
      name: name,
      audience: audience,
      coverMediaId: list.firstOrNull?.id,
      photos: list.where((m) => !m.isVideo).length,
      videos: list.where((m) => m.isVideo).length,
      loveCount: id == bath ? 2 : 0,
      createdBy: 'u_mai',
      author: CareAuthor.of(mai),
      updatedAt: at,
    );
  }

  return (
    albums: [
      album(bath, 'Giờ tắm', Audience.family),
      album(sleep, 'Ngủ ngoan', Audience.parents),
      album(hands, 'Bàn tay nhỏ', Audience.family),
    ],
    items: items,
  );
}

/// Memories on top of the family / care overrides.
List<Override> memoryOverrides({
  ({List<Memory> memories, List<MediaItem> media})? journal,
  FakeMemoryRepository? repo,
  MemoryQueueStore? store,
  FakeTransport? transport,
  List<FamilyMilestone> milestones = const [],
  List<CareAuthor>? notified,
  NetworkKind network = NetworkKind.wifi,
  bool withAlbums = true,
  Set<String>? favorites,
  List<Love> loves = const [],
  List<ParentMessage> messages = const [],
}) {
  final j = journal ?? mockJournal();
  final a = withAlbums
      ? mockAlbums(j.media)
      : (
          albums: const <Album>[],
          items: const <String, Map<String, DateTime>>{},
        );
  return [
    albumsProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final al in a.albums)
          if (key.$2 || al.audience == Audience.family) al,
      ]),
    ),
    albumItemsProvider.overrideWith(
      (ref, key) => Stream.value(a.items[key.$2] ?? const {}),
    ),
    favoritesProvider.overrideWith(
      (ref, key) => Stream.value(
        favorites ?? {for (final m in j.media.skip(1).take(3)) m.id},
      ),
    ),
    lovesProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final l in loves)
          if (key.$3 || l.uid == key.$2) l,
      ]),
    ),
    messagesProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final m in messages)
          if (key.$3 || m.from == key.$2) m,
      ]),
    ),
    memoriesProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final m in j.memories)
          if (key.$2 || m.audience == Audience.family) m,
      ]),
    ),
    mediaProvider.overrideWith(
      (ref, key) => Stream.value([
        for (final i in j.media)
          if (key.$2 || (i.effectiveAudience == Audience.family && i.isReady))
            i,
      ]),
    ),
    familyMilestonesProvider.overrideWith(
      (ref, id) => Stream.value(milestones),
    ),
    notifiedProvider.overrideWith((ref, key) => Stream.value(notified)),
    publicLimitsProvider.overrideWith(
      (ref) => Stream.value(const PublicLimits()),
    ),
    memoryRepositoryProvider.overrideWithValue(repo ?? FakeMemoryRepository()),
    networkKindProvider.overrideWith((ref) => Stream.value(network)),
    queueStoreProvider.overrideWithValue(store ?? MemoryQueueStore()),
    uploadTransportProvider.overrideWithValue(transport ?? FakeTransport()),
    mediaPreparerProvider.overrideWithValue(FakePreparer()),
  ];
}

/// "Bà nội, Ba thương" on the first entry (10a).
List<Love> mockLoves(({List<Memory> memories, List<MediaItem> media}) j) => [
  for (final m in [hoa, minh])
    Love(
      uid: m.uid,
      target: LoveTarget.memory,
      targetId: j.memories.first.id,
      author: CareAuthor.of(m),
    ),
];

/// "Bà thương con quá!" from Bà nội about the first photo (D-034).
List<ParentMessage> mockMessages(
  ({List<Memory> memories, List<MediaItem> media}) j,
) => [
  ParentMessage(
    id: 'msg_${'1' * 32}',
    from: hoa.uid,
    author: CareAuthor.of(hoa),
    context: MessageContext.media,
    contextId: j.memories.first.mediaIds.first,
    text: 'Bà thương con quá! Cuối tuần bà sang nhé.',
    createdAt: DateTime.utc(2026, 10, 8, 4, 10),
  ),
];
