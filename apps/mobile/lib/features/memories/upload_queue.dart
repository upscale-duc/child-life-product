import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/appearance/appearance_providers.dart';
import 'memory_models.dart';
import 'memory_repository.dart';

/// The device side of uploads (10i "Hàng đợi", UploadPill 132:898, business map §6.5). Picked
/// files are copied into the app's support directory and the queue is saved to disk, so nothing
/// is lost when the app is killed: unfinished items start again on the next launch (ADR-004,
/// SP-2 fallback). Videos wait for Wi-Fi when "Video chỉ tải qua Wi-Fi" is on (default).

enum QueueState {
  /// Waiting for the upload session (offline when composed).
  pendingSession,
  queued,
  waitingWifi,

  /// Over the family quota: kept on the device (R-121, 13d).
  waitingQuota,
  uploading,

  /// No network or "Tạm dừng"; resumes by itself.
  paused,

  /// "Mất kết nối khi đang tải" → "Thử lại" (or by itself when back online).
  failed,

  /// Bytes are on the server; processing decides ready / unreadable.
  uploaded,

  /// "Tệp bị lỗi · không thử lại được".
  unreadable,
  cancelled,
}

bool _terminal(QueueState s) =>
    s == QueueState.uploaded ||
    s == QueueState.unreadable ||
    s == QueueState.cancelled;

class QueueItem {
  QueueItem({
    required this.mediaId,
    required this.type,
    required this.name,
    required this.localPath,
    required this.contentType,
    required this.bytes,
    required this.captureAt,
    this.posterPath,
    this.durationMs,
    this.width,
    this.height,
    this.state = QueueState.pendingSession,
    this.sent = 0,
  });

  final String mediaId;
  final MediaKind type;

  /// "IMG_2041.HEIC" — the name the user knows (10i rows).
  final String name;
  final String localPath;
  final String? posterPath;
  final String contentType;
  final int bytes;
  final DateTime captureAt;
  final int? durationMs;
  final int? width;
  final int? height;
  QueueState state;
  int sent;

  bool get isVideo => type == MediaKind.video;

  Map<String, Object?> toJson() => {
    'mediaId': mediaId,
    'type': type.name,
    'name': name,
    'localPath': localPath,
    'posterPath': posterPath,
    'contentType': contentType,
    'bytes': bytes,
    'captureAt': captureAt.toUtc().toIso8601String(),
    'durationMs': durationMs,
    'width': width,
    'height': height,
    'state': state.name,
  };

  static QueueItem fromJson(Map<String, Object?> j) {
    var state =
        QueueState.values.asNameMap()[j['state']] ?? QueueState.pendingSession;
    // A killed app loses its transfers: start them again.
    if (state == QueueState.uploading || state == QueueState.paused) {
      state = QueueState.queued;
    }
    return QueueItem(
      mediaId: j['mediaId']! as String,
      type: MediaKind.values.byName(j['type']! as String),
      name: j['name'] as String? ?? '',
      localPath: j['localPath']! as String,
      posterPath: j['posterPath'] as String?,
      contentType: j['contentType']! as String,
      bytes: (j['bytes']! as num).toInt(),
      captureAt: DateTime.parse(j['captureAt']! as String),
      durationMs: (j['durationMs'] as num?)?.toInt(),
      width: (j['width'] as num?)?.toInt(),
      height: (j['height'] as num?)?.toInt(),
      state: state,
    );
  }

  Map<String, Object?> requestJson() => {
    'mediaId': mediaId,
    'type': type.name,
    'contentType': contentType,
    'sizeBytes': bytes,
    'captureAt': captureAt.toUtc().toIso8601String(),
    'durationMs': durationMs,
    'width': width,
    'height': height,
    'hasPoster': posterPath != null,
  };
}

/// One "Tải lên N mục" (10h) or share-extension "Thêm".
class QueueBatch {
  QueueBatch({
    required this.batchId,
    required this.babyId,
    required this.memoryId,
    required this.request,
    required this.items,
    required this.createdAt,
    this.sessionCreated = false,
    this.dismissed = false,
  });

  final String batchId;
  final String babyId;
  final String memoryId;

  /// The createMemorySession request without its items.
  final Map<String, Object?> request;
  final List<QueueItem> items;
  final DateTime createdAt;
  bool sessionCreated;
  bool dismissed;

  bool get notifyFamily =>
      request['notifyFamily'] == true && request['audience'] == 'family';
  bool get done => items.every((i) => _terminal(i.state));

  Map<String, Object?> toJson() => {
    'batchId': batchId,
    'babyId': babyId,
    'memoryId': memoryId,
    'request': request,
    'items': [for (final i in items) i.toJson()],
    'createdAt': createdAt.toUtc().toIso8601String(),
    'sessionCreated': sessionCreated,
    'dismissed': dismissed,
  };

  static QueueBatch fromJson(Map<String, Object?> j) => QueueBatch(
    batchId: j['batchId']! as String,
    babyId: j['babyId']! as String,
    memoryId: j['memoryId']! as String,
    request: (j['request']! as Map).cast<String, Object?>(),
    items: [
      for (final i in j['items']! as List)
        QueueItem.fromJson((i as Map).cast<String, Object?>()),
    ],
    createdAt: DateTime.parse(j['createdAt']! as String),
    sessionCreated: j['sessionCreated'] == true,
    dismissed: j['dismissed'] == true,
  );
}

// ---------- I/O seams (replaced in tests) ----------

class UploadRejected implements Exception {}

class UploadCancelled implements Exception {}

/// Raw bytes into the reserved slot (Storage Rules check it, ADR-004).
abstract class UploadTransport {
  Future<void> upload(
    String storagePath,
    File file,
    String contentType,
    void Function(int sent) onProgress,
  );
  void cancel(String storagePath);
}

class StorageTransport implements UploadTransport {
  StorageTransport([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;
  final _tasks = <String, UploadTask>{};

  @override
  Future<void> upload(
    String storagePath,
    File file,
    String contentType,
    void Function(int sent) onProgress,
  ) async {
    final task = _storage
        .ref(storagePath)
        .putFile(file, SettableMetadata(contentType: contentType));
    _tasks[storagePath] = task;
    final sub = task.snapshotEvents.listen(
      (s) => onProgress(s.bytesTransferred),
      onError: (_) {},
    );
    try {
      await task;
    } on FirebaseException catch (e) {
      if (e.code == 'canceled') throw UploadCancelled();
      if (e.code == 'unauthorized') throw UploadRejected();
      rethrow;
    } finally {
      await sub.cancel();
      _tasks.remove(storagePath);
    }
  }

  @override
  void cancel(String storagePath) => _tasks[storagePath]?.cancel();
}

enum NetworkKind { none, wifi, cellular }

final networkKindProvider = StreamProvider<NetworkKind>((ref) async* {
  NetworkKind kind(List<ConnectivityResult> r) =>
      r.contains(ConnectivityResult.wifi) ||
          r.contains(ConnectivityResult.ethernet)
      ? NetworkKind.wifi
      : r.any((x) => x != ConnectivityResult.none)
      ? NetworkKind.cellular
      : NetworkKind.none;
  final c = Connectivity();
  yield kind(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(kind);
});

/// A picked photo or video before it joins the queue.
@immutable
class PickedMedia {
  const PickedMedia({
    required this.file,
    required this.type,
    required this.name,
    required this.captureAt,
    this.durationMs,
    this.width,
    this.height,
    this.thumbBytes,
  });

  final File file;
  final MediaKind type;
  final String name;
  final DateTime captureAt;
  final int? durationMs;
  final int? width;
  final int? height;

  /// What compose shows in its strip (10h).
  final Uint8List? thumbBytes;
}

/// Copies into the queue folder; photos become JPEG without metadata (SP-3 fallback, P-033),
/// videos keep their bytes and get a poster frame.
abstract class MediaPreparer {
  Future<QueueItem> prepare(PickedMedia picked, String mediaId);
  Future<void> discard(QueueItem item);
}

class DeviceMediaPreparer implements MediaPreparer {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/uploads').create(recursive: true);
  }

  @override
  Future<QueueItem> prepare(PickedMedia picked, String mediaId) async {
    final dir = await _dir();
    if (picked.type == MediaKind.photo) {
      final out = '${dir.path}/$mediaId.jpg';
      final file = await FlutterImageCompress.compressAndGetFile(
        picked.file.absolute.path,
        out,
        quality: 90,
        keepExif: false,
        minWidth: picked.width ?? 4096,
        minHeight: picked.height ?? 4096,
      );
      if (file == null) throw const FormatException('unreadable');
      final f = File(file.path);
      return QueueItem(
        mediaId: mediaId,
        type: MediaKind.photo,
        name: picked.name,
        localPath: f.path,
        contentType: 'image/jpeg',
        bytes: await f.length(),
        captureAt: picked.captureAt,
        width: picked.width,
        height: picked.height,
      );
    }
    final mov = picked.file.path.toLowerCase().endsWith('.mov');
    final out = '${dir.path}/$mediaId.${mov ? 'mov' : 'mp4'}';
    await picked.file.copy(out);
    String? poster = '${dir.path}/$mediaId.poster.jpg';
    try {
      final ok = await FcNativeVideoThumbnail().saveThumbnailToFile(
        srcFile: out,
        destFile: poster,
        width: 1280,
        height: 1280,
        format: 'jpeg',
        quality: 80,
      );
      if (!ok) poster = null;
    } on Object {
      poster = null;
    }
    return QueueItem(
      mediaId: mediaId,
      type: MediaKind.video,
      name: picked.name,
      localPath: out,
      posterPath: poster,
      contentType: mov ? 'video/quicktime' : 'video/mp4',
      bytes: await File(out).length(),
      captureAt: picked.captureAt,
      durationMs: picked.durationMs,
      width: picked.width,
      height: picked.height,
    );
  }

  @override
  Future<void> discard(QueueItem item) async {
    for (final p in [item.localPath, item.posterPath]) {
      if (p == null) continue;
      try {
        await File(p).delete();
      } on Object {
        // Already gone.
      }
    }
  }
}

final uploadTransportProvider = Provider<UploadTransport>(
  (ref) => StorageTransport(),
);
final mediaPreparerProvider = Provider<MediaPreparer>(
  (ref) => DeviceMediaPreparer(),
);

/// Where the queue is saved (a JSON file); tests keep it in memory.
abstract class QueueStore {
  Future<List<QueueBatch>> load();
  Future<void> save(List<QueueBatch> batches);
}

class FileQueueStore implements QueueStore {
  Future<File> _file() async => File(
    '${(await getApplicationSupportDirectory()).path}/upload_queue.json',
  );

  @override
  Future<List<QueueBatch>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final json = jsonDecode(await f.readAsString()) as List;
      return [
        for (final b in json)
          QueueBatch.fromJson((b as Map).cast<String, Object?>()),
      ];
    } on Object {
      return [];
    }
  }

  @override
  Future<void> save(List<QueueBatch> batches) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode([for (final b in batches) b.toJson()]));
    await tmp.rename(f.path);
  }
}

final queueStoreProvider = Provider<QueueStore>((ref) => FileQueueStore());

/// "Video chỉ tải qua Wi-Fi" (10i), on by default (R-115, `config/limits`).
final videoWifiOnlyProvider = NotifierProvider<VideoWifiOnly, bool>(
  VideoWifiOnly.new,
);

class VideoWifiOnly extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool('uploads.videoWifiOnly') ??
      true;

  void set(bool on) {
    ref.read(sharedPreferencesProvider).setBool('uploads.videoWifiOnly', on);
    state = on;
  }
}

// ---------- The queue ----------

@immutable
class QueueView {
  const QueueView({this.batches = const [], this.paused = false});
  final List<QueueBatch> batches;

  /// "Tạm dừng" (10i).
  final bool paused;
}

final uploadQueueProvider = NotifierProvider<UploadQueue, QueueView>(
  UploadQueue.new,
);

class UploadQueue extends Notifier<QueueView> {
  final _batches = <QueueBatch>[];
  var _paused = false;
  var _running = false;
  var _loaded = false;
  DateTime? _lastQuotaTry;
  String? _currentPath;

  @override
  QueueView build() {
    ref.listen(networkKindProvider, (_, next) {
      if (next.value != null && next.value != NetworkKind.none) {
        // Back online: "tự thử lại khi có mạng" (10i).
        for (final i in _items) {
          if (i.state == QueueState.failed || i.state == QueueState.paused) {
            i.state = QueueState.queued;
          }
        }
      }
      unawaited(_kick());
    });
    unawaited(_load());
    return const QueueView();
  }

  Iterable<QueueItem> get _items => _batches.expand((b) => b.items);

  NetworkKind get _network =>
      ref.read(networkKindProvider).value ?? NetworkKind.wifi;

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    _batches.addAll(await ref.read(queueStoreProvider).load());
    _publish();
    await _kick();
  }

  void _publish() {
    if (!ref.mounted) return;
    state = QueueView(batches: List.unmodifiable(_batches), paused: _paused);
  }

  Future<void> _persist() async {
    _publish();
    await ref.read(queueStoreProvider).save(_batches);
  }

  /// 10h "Tải lên N mục": prepare the files, save the batch, start.
  Future<void> enqueue({
    required String babyId,
    required Map<String, Object?> request,
    required List<PickedMedia> picked,
  }) async {
    await _load();
    final preparer = ref.read(mediaPreparerProvider);
    final items = <QueueItem>[];
    for (final p in picked) {
      try {
        items.add(await preparer.prepare(p, newMediaId()));
      } on Object {
        // Unreadable on the device: shown once, never uploaded.
        items.add(
          QueueItem(
            mediaId: newMediaId(),
            type: p.type,
            name: p.name,
            localPath: p.file.path,
            contentType: p.type == MediaKind.photo ? 'image/jpeg' : 'video/mp4',
            bytes: 1,
            captureAt: p.captureAt,
            state: QueueState.unreadable,
          ),
        );
      }
    }
    _batches.add(
      QueueBatch(
        batchId: request['batchId']! as String,
        babyId: babyId,
        memoryId: request['memoryId']! as String,
        request: request,
        items: items,
        createdAt: DateTime.now(),
      ),
    );
    await _persist();
    await _kick();
  }

  void setPaused(bool paused) {
    _paused = paused;
    if (paused && _currentPath != null) {
      ref.read(uploadTransportProvider).cancel(_currentPath!);
    }
    if (!paused) {
      for (final i in _items) {
        if (i.state == QueueState.paused) i.state = QueueState.queued;
      }
    }
    _publish();
    unawaited(_kick());
  }

  /// "Thử lại" / "Thử lại tất cả (N)".
  Future<void> retry([String? mediaId]) async {
    for (final i in _items) {
      if ((mediaId == null || i.mediaId == mediaId) &&
          i.state == QueueState.failed) {
        i.state = QueueState.queued;
        i.sent = 0;
      }
    }
    await _persist();
    await _kick();
  }

  /// "×" on a row: stops it, gives the reservation back, forgets the copy.
  Future<void> cancel(String mediaId) async {
    for (final b in _batches) {
      for (final i in b.items) {
        if (i.mediaId != mediaId || _terminal(i.state)) continue;
        if (i.state == QueueState.uploading) {
          ref
              .read(uploadTransportProvider)
              .cancel('babies/${b.babyId}/uploads/${i.mediaId}');
        }
        final hadSession = b.sessionCreated;
        i.state = QueueState.cancelled;
        await ref.read(mediaPreparerProvider).discard(i);
        if (hadSession) {
          try {
            await ref.read(memoryRepositoryProvider).cancel(b.babyId, [
              mediaId,
            ]);
          } on Object {
            // The 24 h job releases it anyway (P-031).
          }
        }
      }
    }
    await _persist();
  }

  /// Hide a finished batch's pill ("Đã tải xong 7 mục").
  Future<void> dismiss(String batchId) async {
    _batches.removeWhere((b) => b.batchId == batchId && b.done);
    await _persist();
  }

  Future<void> _kick() async {
    if (_running || !_loaded) return;
    _running = true;
    try {
      await _createSessions();
      await _retryQuota();
      while (true) {
        final next = _next();
        if (next == null) break;
        await _upload(next.$1, next.$2);
      }
    } finally {
      _running = false;
      if (ref.mounted) _publish();
    }
  }

  Future<void> _createSessions() async {
    if (_network == NetworkKind.none) return;
    for (final b in _batches.where((b) => !b.sessionCreated)) {
      final live = b.items
          .where((i) => i.state != QueueState.unreadable)
          .toList();
      try {
        final r = await ref.read(memoryRepositoryProvider).createSession({
          ...b.request,
          'items': [for (final i in live) i.requestJson()],
        });
        b.sessionCreated = true;
        for (final i in live) {
          if (r.reserved.contains(i.mediaId)) {
            i.state = QueueState.queued;
          } else if (r.waitingQuota.contains(i.mediaId)) {
            i.state = QueueState.waitingQuota;
          }
        }
      } on Object {
        // Offline or the server is unhappy: try again on the next kick.
      }
    }
    // A note has nothing to upload once its memory exists.
    _batches.removeWhere((b) => b.sessionCreated && b.items.isEmpty);
    await _persist();
  }

  Future<void> _retryQuota() async {
    final waiting = _batches
        .where((b) => b.items.any((i) => i.state == QueueState.waitingQuota))
        .toList();
    if (waiting.isEmpty || _network == NetworkKind.none) return;
    final now = DateTime.now();
    if (_lastQuotaTry != null &&
        now.difference(_lastQuotaTry!) < const Duration(minutes: 10)) {
      return;
    }
    _lastQuotaTry = now;
    for (final b in waiting) {
      final ids = [
        for (final i in b.items)
          if (i.state == QueueState.waitingQuota) i.mediaId,
      ];
      try {
        final reserved = await ref
            .read(memoryRepositoryProvider)
            .reserve(b.babyId, ids);
        for (final i in b.items) {
          if (reserved.contains(i.mediaId)) i.state = QueueState.queued;
        }
      } on Object {
        // Still full or offline.
      }
    }
    await _persist();
  }

  (QueueBatch, QueueItem)? _next() {
    if (_paused) return null;
    final network = _network;
    if (network == NetworkKind.none) {
      for (final i in _items) {
        if (i.state == QueueState.queued) i.state = QueueState.paused;
      }
      return null;
    }
    final wifiOnly = ref.read(videoWifiOnlyProvider);
    for (final b in _batches.where((b) => b.sessionCreated)) {
      for (final i in b.items) {
        final waitingWifi = i.state == QueueState.waitingWifi;
        if (i.state != QueueState.queued && !waitingWifi) continue;
        if (i.isVideo && wifiOnly && network != NetworkKind.wifi) {
          if (!waitingWifi) {
            i.state = QueueState.waitingWifi;
            // The family notice need not wait for it (D-033).
            unawaited(
              ref
                  .read(memoryRepositoryProvider)
                  .markWaitingWifi(b.babyId, i.mediaId, true)
                  .catchError((Object _) {}),
            );
            _publish();
          }
          continue;
        }
        return (b, i);
      }
    }
    return null;
  }

  Future<void> _upload(QueueBatch b, QueueItem i) async {
    final transport = ref.read(uploadTransportProvider);
    final base = 'babies/${b.babyId}/uploads/${i.mediaId}';
    i.state = QueueState.uploading;
    i.sent = 0;
    _publish();
    try {
      if (i.posterPath != null && await File(i.posterPath!).exists()) {
        _currentPath = '$base.poster';
        await transport.upload(
          '$base.poster',
          File(i.posterPath!),
          'image/jpeg',
          (_) {},
        );
      }
      _currentPath = base;
      await transport.upload(base, File(i.localPath), i.contentType, (sent) {
        i.sent = sent;
        _publish();
      });
      i.state = QueueState.uploaded;
      i.sent = i.bytes;
      await ref.read(mediaPreparerProvider).discard(i);
    } on UploadCancelled {
      if (i.state == QueueState.uploading) {
        i.state = _paused ? QueueState.paused : QueueState.queued;
      }
    } on UploadRejected {
      // The slot is gone (cancelled elsewhere or expired after 24 h).
      i.state = QueueState.cancelled;
    } on Object {
      i.state = _network == NetworkKind.none
          ? QueueState.paused
          : QueueState.failed;
    } finally {
      _currentPath = null;
      if (ref.mounted) await _persist();
    }
  }
}
