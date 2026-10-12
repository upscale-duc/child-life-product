import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/appearance/appearance_providers.dart';
import 'background_uploads.dart';
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
    this.error,
    this.thumbPath,
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

  /// A small picture kept once the bytes are sent and the copy is deleted, so the "Đã tải lên"
  /// row still shows what it was (10i); deleted with the batch.
  String? thumbPath;

  /// The last failure's code (`storage/unauthorized`, `object-not-found`, …), never content:
  /// a rejected upload stays visible as "Chưa tải lên được" instead of disappearing.
  String? error;

  bool get rejected => error != null && error!.startsWith('rejected');

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
    'error': error,
    'thumbPath': thumbPath,
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
      error: j['error'] as String?,
      thumbPath: j['thumbPath'] as String?,
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
    this.blocked,
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

  /// Why the server refused the upload session: `uploads-paused` (A11 kill switch, retried by
  /// itself) or a refusal shown as "Chưa tải lên được" with "Thử lại" (`not-allowed`, ...).
  String? blocked;

  bool get paused => !sessionCreated && blocked == 'uploads-paused';
  bool get refused => !sessionCreated && blocked != null && !paused;

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
    'blocked': blocked,
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
    blocked: j['blocked'] as String?,
  );
}

// ---------- I/O seams (replaced in tests) ----------

class UploadRejected implements Exception {
  const UploadRejected([this.code = 'unauthorized']);
  final String code;
}

class UploadCancelled implements Exception {}

/// One file to send: the item's bytes or its video poster.
@immutable
class UploadJob {
  const UploadJob({
    required this.path,
    required this.file,
    required this.contentType,
    required this.babyId,
    this.video = false,
    this.wifiOnly = false,
  });

  /// `babies/<babyId>/uploads/<mediaId>[.poster]`.
  final String path;
  final File file;
  final String contentType;
  final String babyId;

  /// The item's video bytes (not its poster): counted for "1 video đang chờ Wi‑Fi".
  final bool video;

  /// Held until Wi-Fi (D-033), even when the platform carries on without the app.
  final bool wifiOnly;
}

/// Raw bytes into the reserved slot (Storage Rules check it, ADR-004).
abstract class UploadTransport {
  /// Sends [job] and completes when Storage has it. A file already handed over (or already
  /// finished while the app was gone) is joined, not sent again.
  Future<void> upload(UploadJob job, void Function(int sent) onProgress);

  /// 10j: gives the platform every file that may go now, so uploads continue with the phone
  /// locked or the app closed. A no-op where uploads only run in the app.
  Future<void> handOff(List<UploadJob> jobs);

  void cancel(String storagePath);

  /// "Tạm dừng": stops everything handed over.
  void cancelAll();
}

class StorageTransport implements UploadTransport {
  StorageTransport([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;
  final _tasks = <String, UploadTask>{};

  @override
  Future<void> upload(UploadJob job, void Function(int sent) onProgress) async {
    final storagePath = job.path;
    final task = _storage
        .ref(storagePath)
        .putFile(job.file, SettableMetadata(contentType: job.contentType));
    _tasks[storagePath] = task;
    final sub = task.snapshotEvents.listen(
      (s) => onProgress(s.bytesTransferred),
      onError: (_) {},
    );
    try {
      await task;
    } on FirebaseException catch (e) {
      if (e.code == 'canceled') throw UploadCancelled();
      if (e.code == 'unauthorized') throw UploadRejected(e.code);
      rethrow;
    } finally {
      await sub.cancel();
      _tasks.remove(storagePath);
    }
  }

  @override
  Future<void> handOff(List<UploadJob> jobs) async {}

  @override
  void cancel(String storagePath) => _tasks[storagePath]?.cancel();

  @override
  void cancelAll() {
    for (final t in [..._tasks.values]) {
      unawaited(t.cancel());
    }
  }
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

  /// After the bytes are sent: deletes the copy (and poster) but keeps a small thumbnail for the
  /// row; returns its path, or null when none could be made.
  Future<String?> finish(QueueItem item);

  /// Deletes everything the item left on the phone: copy, poster and row thumbnail.
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
    // iOS: the index moved to the front, nothing re-encoded, so playback can start after the
    // first bytes (owner, 2026-10-12); otherwise the file as it is.
    if (!await faststartVideo(picked.file.path, out)) {
      await picked.file.copy(out);
    }
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
  Future<String?> finish(QueueItem item) async {
    final source = item.isVideo ? item.posterPath : item.localPath;
    String? thumb;
    if (source != null) {
      try {
        final out = '${(await _dir()).path}/${item.mediaId}.thumb.jpg';
        final file = await FlutterImageCompress.compressAndGetFile(
          source,
          out,
          quality: 70,
          keepExif: false,
          minWidth: 240,
          minHeight: 240,
        );
        thumb = file?.path;
      } on Object {
        thumb = null;
      }
    }
    await _delete([item.localPath, item.posterPath]);
    return thumb;
  }

  @override
  Future<void> discard(QueueItem item) =>
      _delete([item.localPath, item.posterPath, item.thumbPath]);

  Future<void> _delete(List<String?> paths) async {
    for (final p in paths) {
      if (p == null) continue;
      try {
        await File(p).delete();
      } on Object {
        // Already gone.
      }
    }
  }
}

/// iOS sends through a background URLSession (10j, background_uploads.dart); elsewhere the
/// Storage SDK uploads while the app runs.
final uploadTransportProvider = Provider<UploadTransport>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS
      ? BackgroundTransport.forApp()
      : StorageTransport(),
);
final mediaPreparerProvider = Provider<MediaPreparer>(
  (ref) => DeviceMediaPreparer(),
);

/// Where the queue is saved (a JSON file); tests keep it in memory.
abstract class QueueStore {
  Future<List<QueueBatch>> load();
  Future<void> save(List<QueueBatch> batches);
}

/// iOS gives the app a new data-container path on every update, so saved absolute paths go
/// stale while the files themselves move with the app. A path whose file is gone is looked up
/// by name in the current `uploads` folder.
String? rebaseUploadPath(String? path, String supportDir) {
  if (path == null || File(path).existsSync()) return path;
  final moved = '$supportDir/uploads/${path.split('/').last}';
  return File(moved).existsSync() ? moved : path;
}

Map<String, Object?> rebaseQueuePaths(
  Map<String, Object?> batch,
  String supportDir,
) => {
  ...batch,
  'items': [
    for (final i in (batch['items'] as List? ?? const []))
      {
        ...(i as Map).cast<String, Object?>(),
        'localPath': rebaseUploadPath(i['localPath'] as String?, supportDir),
        'posterPath': rebaseUploadPath(i['posterPath'] as String?, supportDir),
        'thumbPath': rebaseUploadPath(i['thumbPath'] as String?, supportDir),
      },
  ],
};

class FileQueueStore implements QueueStore {
  Future<File> _file() async => File(
    '${(await getApplicationSupportDirectory()).path}/upload_queue.json',
  );

  @override
  Future<List<QueueBatch>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final support = (await getApplicationSupportDirectory()).path;
      final json = jsonDecode(await f.readAsString()) as List;
      return [
        for (final b in json)
          QueueBatch.fromJson(
            rebaseQueuePaths((b as Map).cast<String, Object?>(), support),
          ),
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
  Timer? _sessionRetry;

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
    // Files handed over keep the Wi-Fi rule they were given: hand the videos over again.
    ref.listen(videoWifiOnlyProvider, (_, _) {
      final transport = ref.read(uploadTransportProvider);
      for (final b in _batches) {
        for (final i in b.items.where(
          (i) => i.isVideo && !_terminal(i.state),
        )) {
          transport.cancel(_path(b, i));
        }
      }
      unawaited(_kick());
    });
    ref.onDispose(() => _sessionRetry?.cancel());
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
    if (paused) ref.read(uploadTransportProvider).cancelAll();
    if (!paused) {
      for (final i in _items) {
        if (i.state == QueueState.paused) i.state = QueueState.queued;
      }
    }
    _publish();
    unawaited(_kick());
  }

  static const _transientCodes = {
    'unavailable',
    'internal',
    'unknown',
    'deadline-exceeded',
    'resource-exhausted',
    'aborted',
    'unauthenticated',
  };

  void _retrySessionsLater(Duration after) {
    if (_sessionRetry?.isActive ?? false) return;
    _sessionRetry = Timer(after, () {
      if (ref.mounted) unawaited(_kick());
    });
  }

  /// "Thử lại" / "Thử lại tất cả (N)".
  Future<void> retry([String? mediaId]) async {
    for (final b in _batches) {
      if (b.refused &&
          b.items.any((i) => mediaId == null || i.mediaId == mediaId)) {
        b.blocked = null;
      }
    }
    for (final i in _items) {
      if ((mediaId == null || i.mediaId == mediaId) &&
          i.state == QueueState.failed) {
        i.state = QueueState.queued;
        i.sent = 0;
        i.error = null;
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
    final gone = _batches.where((b) => b.batchId == batchId && b.done).toList();
    _batches.removeWhere(gone.contains);
    await _persist();
    final preparer = ref.read(mediaPreparerProvider);
    for (final i in gone.expand((b) => b.items)) {
      await preparer.discard(i);
    }
  }

  Future<void> _kick() async {
    if (_running || !_loaded) return;
    _running = true;
    try {
      await _createSessions();
      await _retryQuota();
      await _handOff();
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
          .where(
            (i) =>
                i.state != QueueState.unreadable &&
                i.state != QueueState.cancelled,
          )
          .toList();
      // Everything removed before the session existed: nothing to ask the server.
      if (live.isEmpty && b.items.isNotEmpty) continue;
      try {
        final r = await ref.read(memoryRepositoryProvider).createSession({
          ...b.request,
          'items': [for (final i in live) i.requestJson()],
        });
        b.sessionCreated = true;
        b.blocked = null;
        for (final i in live) {
          if (r.reserved.contains(i.mediaId)) {
            i.state = QueueState.queued;
          } else if (r.waitingQuota.contains(i.mediaId)) {
            i.state = QueueState.waitingQuota;
          }
        }
      } on FirebaseFunctionsException catch (e) {
        final details = e.details;
        final reason = details is Map ? details['reason'] as String? : null;
        if (_transientCodes.contains(e.code)) {
          _retrySessionsLater(const Duration(seconds: 30));
        } else if (reason == 'uploads-paused') {
          // A11: uploads are switched off; the items wait and go on by themselves.
          b.blocked = reason;
          _retrySessionsLater(const Duration(minutes: 1));
        } else {
          b.blocked = reason ?? e.code;
          for (final i in live) {
            i.state = QueueState.failed;
          }
        }
      } on Object {
        // Offline or no answer: try again shortly (and on the next network change).
        _retrySessionsLater(const Duration(seconds: 30));
      }
    }
    // A note has nothing to upload once its memory exists; a batch whose items were all
    // removed before it had a session is dropped.
    _batches.removeWhere(
      (b) =>
          (b.sessionCreated && b.items.isEmpty) ||
          (!b.sessionCreated &&
              b.items.isNotEmpty &&
              b.items.every((i) => i.state == QueueState.cancelled)),
    );
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

  /// A file that reached Storage earlier (while the app was gone, or whose answer was lost)
  /// counts as uploaded: the server has processed it, so sending it again can only fail.
  Future<bool> _alreadyThere(QueueBatch b, QueueItem i) async {
    String? status;
    try {
      status = await ref
          .read(memoryRepositoryProvider)
          .mediaStatus(b.babyId, i.mediaId);
    } on Object {
      return false;
    }
    if (status != 'ready' && status != 'unreadable') return false;
    i.state = QueueState.uploaded;
    i.error = null;
    i.sent = i.bytes;
    i.thumbPath = await ref.read(mediaPreparerProvider).finish(i);
    return true;
  }

  String _path(QueueBatch b, QueueItem i) =>
      'babies/${b.babyId}/uploads/${i.mediaId}';

  List<UploadJob> _jobs(QueueBatch b, QueueItem i) {
    final base = _path(b, i);
    final wifiOnly = i.isVideo && ref.read(videoWifiOnlyProvider);
    return [
      if (i.posterPath != null && File(i.posterPath!).existsSync())
        UploadJob(
          path: '$base.poster',
          file: File(i.posterPath!),
          contentType: 'image/jpeg',
          babyId: b.babyId,
          wifiOnly: wifiOnly,
        ),
      UploadJob(
        path: base,
        file: File(i.localPath),
        contentType: i.contentType,
        babyId: b.babyId,
        video: i.isVideo,
        wifiOnly: wifiOnly,
      ),
    ];
  }

  /// 10j: everything that may go now is handed to the platform at once, videos held for Wi-Fi
  /// included, so it all continues with the phone locked; the loop below then joins each file.
  Future<void> _handOff() async {
    if (_paused || _network == NetworkKind.none) return;
    final jobs = [
      for (final b in _batches.where((b) => b.sessionCreated))
        for (final i in b.items)
          if (i.state == QueueState.queued ||
              (i.state == QueueState.waitingWifi && i.isVideo))
            ..._jobs(b, i),
    ];
    if (jobs.isEmpty) return;
    try {
      await ref.read(uploadTransportProvider).handOff(jobs);
    } on Object {
      // The loop sends them one by one instead.
    }
  }

  /// Failure codes only (no names, paths or ids), so a field problem can be diagnosed.
  void _report(String code) {
    try {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          'memory upload failed: $code',
          null,
          reason: 'upload queue',
        ),
      );
    } on Object {
      // No Crashlytics (tests).
    }
  }

  Future<void> _upload(QueueBatch b, QueueItem i) async {
    final transport = ref.read(uploadTransportProvider);
    i.state = QueueState.uploading;
    i.sent = 0;
    _publish();
    try {
      for (final job in _jobs(b, i)) {
        await transport.upload(
          job,
          job.path.endsWith('.poster')
              ? (_) {}
              : (sent) {
                  i.sent = sent;
                  _publish();
                },
        );
      }
      i.state = QueueState.uploaded;
      i.error = null;
      i.sent = i.bytes;
      i.thumbPath = await ref.read(mediaPreparerProvider).finish(i);
    } on UploadCancelled {
      if (i.state == QueueState.uploading) {
        i.state = _paused ? QueueState.paused : QueueState.queued;
      }
    } on UploadRejected catch (e) {
      // Storage refused the bytes (slot expired, or a rule): shown, kept, retried or removed —
      // unless it refused because it already has them.
      if (await _alreadyThere(b, i)) return;
      i.state = QueueState.failed;
      i.error = 'rejected:${e.code}';
      _report(i.error!);
    } on Object catch (e) {
      if (_network != NetworkKind.none && await _alreadyThere(b, i)) return;
      i.state = _network == NetworkKind.none
          ? QueueState.paused
          : QueueState.failed;
      i.error = e is FirebaseException
          ? '${e.plugin}/${e.code}'
          : e.runtimeType.toString();
      if (i.state == QueueState.failed) _report(i.error!);
    } finally {
      if (ref.mounted) await _persist();
    }
  }
}
