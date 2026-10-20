import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../baby/baby_models.dart' show dateOf;
import '../memories/memory_models.dart';
import 'keepsake_catalog.dart';
import 'keepsake_occasions.dart';

/// Video kỷ niệm jobs (D-068; contracts `keepsake-jobs.ts`). The server renders; the app asks
/// (`requestMemoryStory`), follows `babies/{b}/keepsakeJobs/{id}` (its own jobs only, Rules) and
/// shows MM08 / MM09 / MM14 from it. Rendering goes on with the app closed (push when done).

enum KeepsakeJobStatus { queued, rendering, completed, failed }

@immutable
class KeepsakeJob {
  const KeepsakeJob({
    required this.id,
    required this.babyId,
    required this.status,
    required this.templateId,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.step,
    this.progress = 0,
    this.error,
    this.mediaIds = const [],
    this.occasion,
    this.outputMediaId,
    this.durationMs,
    this.audience = Audience.parents,
    this.mark,
    this.palette,
    this.templateName,
  });

  final String id;
  final String babyId;
  final KeepsakeJobStatus status;
  final String templateId;
  final String? templateName;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// arrange · compose · export (MM08's three lines).
  final String? step;
  final int progress;

  /// timeout · photo-missing · render-failed · upload-failed · unavailable.
  final String? error;
  final List<String> mediaIds;
  final Occasion? occasion;
  final String? outputMediaId;
  final int? durationMs;
  final Audience audience;
  final String? mark;
  final KeepsakePalette? palette;

  bool get active =>
      status == KeepsakeJobStatus.queued ||
      status == KeepsakeJobStatus.rendering;

  static KeepsakeJob? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data();
    if (j == null) return null;
    final status = KeepsakeJobStatus.values.asNameMap()[j['status']];
    if (status == null) return null;
    final input = j['input'] is Map ? j['input'] as Map : const {};
    final template = input['template'] is Map
        ? input['template'] as Map
        : const {};
    final texts = input['texts'] is Map ? input['texts'] as Map : const {};
    final output = j['output'] is Map ? j['output'] as Map : const {};
    return KeepsakeJob(
      id: d.id,
      babyId: j['babyId'] as String? ?? '',
      status: status,
      templateId: j['templateId'] as String? ?? '',
      templateName: Localized.fromJson(template['name'])?.vi,
      title: texts['title'] as String? ?? '',
      createdAt: dateOf(j['createdAt']) ?? DateTime(2000),
      updatedAt: dateOf(j['updatedAt']),
      step: j['step'] as String?,
      progress: (j['progress'] as num?)?.toInt() ?? 0,
      error: j['error'] as String?,
      mediaIds: [
        for (final m in (j['mediaIds'] as List? ?? const []))
          if (m is String) m,
      ],
      occasion: Occasion.fromWire(j['occasion'] as String?),
      outputMediaId: j['outputMediaId'] as String?,
      durationMs: (output['durationMs'] as num?)?.toInt(),
      audience: Audience.values.asNameMap()[j['audience']] ?? Audience.parents,
      mark: input['mark'] as String?,
      palette: KeepsakePalette.fromJson(template['palette']),
    );
  }
}

class KeepsakeJobException implements Exception {
  const KeepsakeJobException(this.reason);

  /// busy · daily-limit · quota-full · photo-unavailable · template-unavailable · not-enabled …
  final String reason;
}

class KeepsakeJobRepository {
  KeepsakeJobRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<KeepsakeJob?> watch(String babyId, String jobId) => _db
      .doc('babies/$babyId/keepsakeJobs/$jobId')
      .snapshots()
      .map(KeepsakeJob.fromSnapshot);

  /// This person's recent jobs for a baby (Rules let each see only their own).
  Stream<List<KeepsakeJob>> watchMine(String babyId, String uid) => _db
      .collection('babies/$babyId/keepsakeJobs')
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?KeepsakeJob.fromSnapshot(d)]);

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final r = await _functions.httpsCallable(name).call<Object?>(data);
      return r.data is Map
          ? (r.data! as Map).cast<String, Object?>()
          : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw KeepsakeJobException(
        (details is Map ? details['reason'] as String? : null) ?? e.code,
      );
    }
  }

  /// MM07 "Tạo video": the job id (the same one if this request was already sent).
  Future<String> request({
    required String requestId,
    required String babyId,
    required KeepsakeTemplate template,
    required List<String> mediaIds,
    required String title,
    required String message,
    Map<String, String> extra = const {},
    String locale = 'vi',
    Map<String, Object?>? presentation,
    required Audience audience,
    required Occasion? occasion,
    ({String? id})? music,
  }) async {
    final r = await _call('requestMemoryStory', {
      'requestId': requestId,
      'babyId': babyId,
      'templateId': template.id,
      'templateVersion': template.version,
      'mediaIds': mediaIds,
      'texts': {'title': title, 'message': message, ...extra},
      'locale': locale == 'en' ? 'en' : 'vi',
      'presentation': ?presentation,
      'audience': audience.name,
      'occasion': occasion?.wire,
      // Left out: the template's default track; null: "Không dùng nhạc".
      if (music != null) 'musicId': music.id,
    });
    return r['jobId']! as String;
  }

  Future<void> retry(String babyId, String jobId) =>
      _call('retryMemoryStory', {'babyId': babyId, 'jobId': jobId});

  /// MM14 "Xoá bản nháp": a video that could not be made (only the person who asked).
  Future<void> delete(String babyId, String jobId) =>
      _call('deleteMemoryStory', {'babyId': babyId, 'jobId': jobId});

  /// MM08 on iPhone: the job's Live Activity (its push token and this device's FCM token).
  /// [token]: the Live Activity's (iPhone); null on Android, which follows by FCM (A6).
  Future<void> attachLive({
    required String babyId,
    required String jobId,
    required String? token,
    required String fcm,
  }) => _call('attachMemoryStoryLive', {
    'babyId': babyId,
    'jobId': jobId,
    'token': token,
    'fcm': fcm,
  });
}

final keepsakeJobRepositoryProvider = Provider<KeepsakeJobRepository>(
  (ref) => KeepsakeJobRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final keepsakeJobProvider =
    StreamProvider.family<KeepsakeJob?, (String, String)>(
      (ref, key) =>
          ref.watch(keepsakeJobRepositoryProvider).watch(key.$1, key.$2),
    );

/// The signed-in person's recent jobs for [babyId].
final myKeepsakeJobsProvider = StreamProvider.family<List<KeepsakeJob>, String>(
  (ref, babyId) {
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return Stream.value(const []);
    return ref
        .watch(keepsakeJobRepositoryProvider)
        .watchMine(babyId, session.user.uid);
  },
);

/// A new request id per press of "Tạo video" (kept on retry of the same press).
String newKeepsakeRequestId() => const Uuid().v4();
