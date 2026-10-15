import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../care/care_models.dart' show CareType;
import '../care/care_repository.dart' show careRecordProvider;
import 'assistant_models.dart';

/// The callables of the assistant server (slice A2, docs/assistant/architecture.md §3). Names in
/// one place so they follow the server when it lands (`firebase/functions/src/index.ts`).
abstract final class AssistantCallables {
  static const quote = 'quoteTask';
  static const start = 'startTask';
  static const clarify = 'submitClarification';
  static const patchDraft = 'patchDraft';
  static const confirm = 'confirmDrafts';
  static const discard = 'discardDraft';
  static const cancel = 'cancelTask';
  static const feedback = 'submitAssistantFeedback';
  static const usage = 'getAssistantUsage';
  static const history = 'listAssistantHistory';
  static const task = 'getAssistantTask';
  static const deleteConversation = 'deleteAssistantConversation';
  static const consent = 'setAssistantConsent';

  /// Slice A3 photos: the owned upload target for one quoted photo.
  static const upload = 'createAttachmentUpload';

  /// Slice A5 care: "Thử tối nay" (an intention, 0 credits).
  static const plan = 'planAssistantActivity';
}

/// A refused or failed assistant call: a closed [AssistantReason] (`details.reason`), or a
/// transport problem (no connection, timeout) when [reason] is null.
class AssistantException implements Exception {
  const AssistantException(this.code, {this.reason, this.retryable = false});

  /// The HttpsError code (`unavailable`, `permission-denied`…) or `timeout` / `invalid`.
  final String code;
  final AssistantReason? reason;
  final bool retryable;

  /// Never reached the server, or no answer in time: nothing was charged or saved.
  bool get offline =>
      reason == null &&
      const {
        'unavailable',
        'deadline-exceeded',
        'timeout',
        'offline',
        'network',
      }.contains(code);

  @override
  String toString() => 'AssistantException($code, ${reason?.wire})';
}

/// What a `startTask` answered: the task, or `blocked` (USAGE_EXHAUSTED at start, kept to resume).
typedef StartAnswer = ({
  TaskSnapshot? snapshot,
  ResponseStatus status,
  AssistantReason? reason,
  AssistantUsage? usage,
});

/// Live pieces of one task from Firestore: the task document, its drafts, its events.
sealed class TaskLive {
  const TaskLive();
}

class TaskDocLive extends TaskLive {
  const TaskDocLive(this.task);
  final AssistantTask task;
}

class TaskDraftsLive extends TaskLive {
  const TaskDraftsLive(this.drafts);
  final List<AssistantDraft> drafts;
}

class TaskEventsLive extends TaskLive {
  const TaskEventsLive(this.events);
  final List<AssistantEvent> events;
}

/// A new idempotency key (`clientRequestId`, a UUID).
String newAssistantRequestId() => const Uuid().v4();

/// How long the phone waits for a callable before keeping the input for a retry.
const assistantCallTimeout = Duration(seconds: 30);

/// The assistant on the phone (slice A4). Every command is a callable with the common envelope
/// (`contractVersion`, `clientRequestId`, `locale`); the owner's task, drafts and events are read
/// from Firestore for progress and reconnect, and the snapshot from `getAssistantTask` is the
/// authority. Consent is read from `users/{uid}/settings/ai` and written by the server. Nothing
/// here logs child data.
class AssistantRepository {
  AssistantRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<AssistantEnvelope> _call(
    String name,
    Map<String, Object?> data, {
    required String locale,
    String? requestId,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: assistantCallTimeout),
      );
      final r = await callable.call<Object?>({
        'contractVersion': assistantContractVersion,
        'clientRequestId': requestId ?? newAssistantRequestId(),
        'locale': locale == 'en' ? 'en' : 'vi',
        ...data,
      });
      return AssistantEnvelope.fromJson(r.data);
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map
          ? AssistantReason.fromWire(details['reason'])
          : AssistantReason.fromWire(e.message);
      throw AssistantException(
        e.code,
        reason: reason,
        retryable: details is Map && details['retryable'] == true,
      );
    } on TimeoutException {
      throw const AssistantException('timeout');
    }
  }

  /// `quoteTask`: exact credits, allowed / reason, usage snapshot. Never calls a model.
  Future<AssistantQuote> quote({
    required AssistantScope scope,
    required String? conversationId,
    required TaskModality modality,
    required String locale,
    int attachmentCount = 0,
    IntentHint? intentHint,
  }) async {
    final r = await _call(AssistantCallables.quote, {
      'conversationId': conversationId,
      'scope': scope.toJson(),
      'modality': modality.wire,
      'attachmentCount': attachmentCount,
      'intentHint': intentHint?.wire,
    }, locale: locale);
    final q = AssistantQuote.fromJson(r.data);
    if (q == null) throw const AssistantException('invalid');
    if (q.allowed || q.reason != null || r.reason == null) return q;
    // `status: blocked` with the reason only on the envelope.
    return AssistantQuote(
      quoteId: q.quoteId,
      modality: q.modality,
      credits: q.credits,
      allowed: false,
      reason: r.reason,
      reasonWire: r.reasonWire,
      expiresAt: q.expiresAt,
      usage: q.usage,
    );
  }

  /// `startTask`: same [requestId] + same input → the same task (M01).
  Future<StartAnswer> start({
    required String requestId,
    required AssistantScope scope,
    required String? conversationId,
    required String quoteId,
    required String? text,
    required String locale,
    List<String> attachmentIds = const [],
  }) async {
    final r = await _call(
      AssistantCallables.start,
      {
        'conversationId': conversationId,
        'scope': scope.toJson(),
        'quoteId': quoteId,
        'text': text,
        'attachmentIds': attachmentIds,
      },
      locale: locale,
      requestId: requestId,
    );
    final data = r.data is Map ? r.data! as Map : const {};
    return (
      snapshot: TaskSnapshot.fromJson(data),
      status: r.status,
      reason: r.reason,
      usage: AssistantUsage.fromJson(data['usage']),
    );
  }

  /// `submitClarification`: continues the same task and reservation (no extra credit).
  Future<TaskSnapshot?> clarify({
    required String taskId,
    required int expectedVersion,
    required String clarificationId,
    required String locale,
    String? choiceId,
    String? text,
  }) async {
    final r = await _call(AssistantCallables.clarify, {
      'taskId': taskId,
      'expectedVersion': expectedVersion,
      'clarificationId': clarificationId,
      'choiceId': choiceId,
      'text': text,
    }, locale: locale);
    return TaskSnapshot.fromJson(r.data);
  }

  /// `patchDraft`: server validation, revision +1, no model, no credit, no domain write.
  Future<AssistantDraft?> patchDraft({
    required String draftId,
    required int expectedRevision,
    required DraftPayload payload,
    required List<String> confirmedFields,
    required String locale,
  }) async {
    final r = await _call(AssistantCallables.patchDraft, {
      'draftId': draftId,
      'expectedRevision': expectedRevision,
      'payload': payload.toJson(),
      'confirmedFields': confirmedFields,
    }, locale: locale);
    final data = r.data is Map ? r.data! as Map : const {};
    return AssistantDraft.fromJson(data['draft'] is Map ? data['draft'] : data);
  }

  /// `confirmDrafts`: per item `saved | failed | conflict`; partial success kept (CH07).
  Future<ConfirmResult> confirm({
    required String taskId,
    required AssistantScope scope,
    required List<ConfirmSelection> selected,
    required String requestId,
    required String locale,
  }) async {
    final r = await _call(
      AssistantCallables.confirm,
      {
        'taskId': taskId,
        'scope': scope.toJson(),
        'selected': [for (final s in selected) s.toJson()],
      },
      locale: locale,
      requestId: requestId,
    );
    return ConfirmResult.fromJson(r.data);
  }

  Future<AssistantDraft?> discard({
    required String draftId,
    required int expectedRevision,
    required String locale,
  }) async {
    final r = await _call(AssistantCallables.discard, {
      'draftId': draftId,
      'expectedRevision': expectedRevision,
    }, locale: locale);
    final data = r.data is Map ? r.data! as Map : const {};
    return AssistantDraft.fromJson(data['draft'] is Map ? data['draft'] : data);
  }

  Future<AssistantTask?> cancel({
    required String taskId,
    required String locale,
  }) async {
    final r = await _call(AssistantCallables.cancel, {
      'taskId': taskId,
    }, locale: locale);
    final data = r.data is Map ? r.data! as Map : const {};
    return AssistantTask.fromJson(data['task'] is Map ? data['task'] : data);
  }

  /// `createAttachmentUpload` (CH09): the owned path for one photo the quote counted. Refused
  /// (no target, nothing uploaded) when the household no longer has the quoted credits, the
  /// consent or the photo flag.
  Future<AssistantUploadTarget> createUpload({
    required String quoteId,
    required String mime,
    required int bytes,
    required String sha256,
    required AttachmentRetention retention,
    required String requestId,
    required String locale,
  }) async {
    final r = await _call(
      AssistantCallables.upload,
      {
        'quoteId': quoteId,
        'mime': mime,
        'bytes': bytes,
        'sha256': sha256,
        'retention': retention.wire,
      },
      locale: locale,
      requestId: requestId,
    );
    final target = AssistantUploadTarget.fromJson(r.data);
    if (target == null) throw const AssistantException('invalid');
    return target;
  }

  /// `planAssistantActivity` ("Thử tối nay", CH16): an intention, not "đã thử"; 0 credits.
  Future<AssistantCarePlan?> plan({
    required String taskId,
    required String contentId,
    required int contentVersion,
    required String requestId,
    required String locale,
  }) async {
    final r = await _call(
      AssistantCallables.plan,
      {
        'taskId': taskId,
        'contentId': contentId,
        'contentVersion': contentVersion,
      },
      locale: locale,
      requestId: requestId,
    );
    final data = r.data is Map ? r.data! as Map : const {};
    return AssistantCarePlan.fromJson(data['plan']);
  }

  /// `submitAssistantFeedback` (CH17, 0 credits).
  Future<void> feedback({
    required String taskId,
    required String contentId,
    required int contentVersion,
    required FeedbackOutcome outcome,
    required String locale,
  }) => _call(AssistantCallables.feedback, {
    'taskId': taskId,
    'contentId': contentId,
    'contentVersion': contentVersion,
    'outcome': outcome.wire,
  }, locale: locale);

  /// `getAssistantUsage` (CH19): the household pool.
  Future<AssistantUsage?> usage(String babyId, {required String locale}) async {
    final r = await _call(AssistantCallables.usage, {
      'babyId': babyId,
    }, locale: locale);
    return AssistantUsage.fromJson(r.data);
  }

  /// `listAssistantHistory` (CH03): my own conversations about [babyId], newest first.
  Future<HistoryPage<AssistantConversation>> conversations(
    String babyId, {
    required String locale,
    String? cursor,
    int limit = 30,
  }) async {
    final r = await _call(AssistantCallables.history, {
      'babyId': babyId,
      'conversationId': null,
      'cursor': cursor,
      'limit': limit,
    }, locale: locale);
    final data = r.data is Map ? r.data! as Map : const {};
    return HistoryPage([
      for (final x
          in (data['items'] is List ? data['items'] as List : const []))
        ?AssistantConversation.fromJson(x),
    ], data['nextCursor'] is String ? data['nextCursor'] as String : null);
  }

  /// The messages of one of my conversations, newest first.
  Future<HistoryPage<AssistantMessage>> messages(
    String babyId,
    String conversationId, {
    required String locale,
    String? cursor,
    int limit = 50,
  }) async {
    final r = await _call(AssistantCallables.history, {
      'babyId': babyId,
      'conversationId': conversationId,
      'cursor': cursor,
      'limit': limit,
    }, locale: locale);
    final data = r.data is Map ? r.data! as Map : const {};
    return HistoryPage([
      for (final x
          in (data['items'] is List ? data['items'] as List : const []))
        ?AssistantMessage.fromJson(x),
    ], data['nextCursor'] is String ? data['nextCursor'] as String : null);
  }

  /// `getAssistantTask`: the authoritative snapshot (reconnect).
  Future<TaskSnapshot?> task(
    String taskId, {
    required String locale,
    int? afterSequence,
  }) async {
    final r = await _call(AssistantCallables.task, {
      'taskId': taskId,
      'afterSequence': afterSequence,
    }, locale: locale);
    return TaskSnapshot.fromJson(r.data);
  }

  /// "Xoá cuộc trò chuyện" (explicit confirmation); domain records stay (`domainRecordsKept`).
  /// The shared baby thread: Cùng nuôi only, for everyone (D-075 #2).
  Future<({int deletedTasks, bool domainRecordsKept})> deleteConversation(
    String conversationId, {
    required String locale,
  }) async {
    final r = await _call(AssistantCallables.deleteConversation, {
      'conversationId': conversationId,
      'confirm': true,
    }, locale: locale);
    final data = r.data is Map ? r.data! as Map : const {};
    return (
      deletedTasks: data['deletedTasks'] is int
          ? data['deletedTasks'] as int
          : 0,
      domainRecordsKept: data['domainRecordsKept'] == true,
    );
  }

  /// Gives ([agree]) or withdraws the assistant consent (P-160).
  Future<void> setConsent({required bool agree, required String locale}) =>
      _call(AssistantCallables.consent, {
        'consent': agree ? {'version': assistantConsentVersion} : null,
      }, locale: locale);

  Stream<AssistantConsent> watchConsent(String uid) => _db
      .doc('users/$uid/settings/ai')
      .snapshots()
      .map((s) => AssistantConsent.fromDoc(_plain(s.data())));

  /// The owner's task document, drafts and events (Rules: owner only).
  Stream<TaskLive> watchTask(String taskId) {
    final ref = _db.doc('assistantTasks/$taskId');
    final controller = StreamController<TaskLive>();
    final subs = <StreamSubscription<Object?>>[];
    controller.onListen = () {
      subs
        ..add(
          ref.snapshots().listen((s) {
            final t = AssistantTask.fromJson(_plain(s.data()), id: s.id);
            if (t != null) controller.add(TaskDocLive(t));
          }, onError: (Object _) {}),
        )
        ..add(
          ref.collection('drafts').snapshots().listen((q) {
            controller.add(
              TaskDraftsLive([
                for (final d in q.docs)
                  ?AssistantDraft.fromJson(_plain(d.data()), id: d.id),
              ]),
            );
          }, onError: (Object _) {}),
        )
        ..add(
          ref
              .collection('events')
              .orderBy('sequence', descending: true)
              .limit(20)
              .snapshots()
              .listen((q) {
                controller.add(
                  TaskEventsLive([
                    for (final d in q.docs)
                      ?AssistantEvent.fromJson(_plain(d.data()), id: d.id),
                  ]),
                );
              }, onError: (Object _) {}),
        );
    };
    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
      await controller.close();
    };
    return controller.stream;
  }
}

/// Firestore values as JSON (Timestamps → ISO strings).
Object? _plain(Object? v) => switch (v) {
  Timestamp t => t.toDate().toUtc().toIso8601String(),
  Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  List l => [for (final x in l) _plain(x)],
  _ => v,
};

// ---------- Kept input on the phone ----------

/// Why an input was kept instead of sent.
enum KeptReason { offline, failed, blocked, consent, photo }

/// The typed input not yet turned into a task (offline, refused, failed, waiting for consent or
/// an upgrade): kept on this phone until sent, with its request id so a retry of the same text
/// is idempotent. Never marked sent or saved while offline.
class KeptInput {
  const KeptInput({
    required this.text,
    required this.requestId,
    required this.inputKey,
    required this.reason,
    required this.at,
    this.resumeUsed = false,
    this.started = false,
    this.conversationId,
  });

  final String text;
  final String requestId;
  final String inputKey;
  final KeptReason reason;
  final DateTime at;

  /// The one resume after a verified purchase was used (CH23 runs once).
  final bool resumeUsed;

  /// `startTask` answered for [requestId] (blocked, kept for resume): a resume sends the same
  /// request id and input (with [conversationId] as first sent) with a fresh quote, and the
  /// server runs that same task once (api.md "Start" step 6).
  final bool started;

  /// The conversation the input was first sent to (part of the task's input key).
  final String? conversationId;

  KeptInput copyWith({
    KeptReason? reason,
    String? requestId,
    bool? resumeUsed,
    bool? started,
  }) => KeptInput(
    text: text,
    requestId: requestId ?? this.requestId,
    inputKey: inputKey,
    reason: reason ?? this.reason,
    at: at,
    resumeUsed: resumeUsed ?? this.resumeUsed,
    started: started ?? this.started,
    conversationId: conversationId,
  );

  Map<String, Object?> toJson() => {
    'text': text,
    'requestId': requestId,
    'inputKey': inputKey,
    'reason': reason.name,
    'at': at.toUtc().toIso8601String(),
    'resumeUsed': resumeUsed,
    'started': started,
    'conversationId': conversationId,
  };

  static KeptInput? fromJson(Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    final id = json['requestId'];
    final reason = KeptReason.values.asNameMap()[json['reason']];
    if (text is! String || id is! String || reason == null) return null;
    return KeptInput(
      text: text,
      requestId: id,
      inputKey: json['inputKey'] is String ? json['inputKey'] as String : '',
      reason: reason,
      at: DateTime.tryParse('${json['at']}') ?? DateTime.now(),
      resumeUsed: json['resumeUsed'] == true,
      started: json['started'] == true,
      conversationId: json['conversationId'] is String
          ? json['conversationId'] as String
          : null,
    );
  }
}

/// Per person and scope on this phone (`<uid>:<scope key>`): the kept input, the open
/// conversation and its tasks (so leaving the chat never loses a task or its drafts; the server
/// snapshot is fetched again on return).
class AssistantLocalStore {
  AssistantLocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _prefix = 'assistant.';
  String _k(String what, String scopeKey) => '$_prefix$what.$scopeKey';

  KeptInput? kept(String scopeKey) {
    final raw = _prefs.getString(_k('kept', scopeKey));
    if (raw == null) return null;
    try {
      return KeptInput.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  void keep(String scopeKey, KeptInput? input) {
    if (input == null) {
      unawaited(_prefs.remove(_k('kept', scopeKey)));
    } else {
      unawaited(
        _prefs.setString(_k('kept', scopeKey), jsonEncode(input.toJson())),
      );
    }
  }

  String? conversation(String scopeKey) =>
      _prefs.getString(_k('conversation', scopeKey));

  List<String> taskIds(String scopeKey) =>
      _prefs.getStringList(_k('tasks', scopeKey)) ?? const [];

  void setConversation(String scopeKey, String? id, List<String> taskIds) {
    if (id == null) {
      unawaited(_prefs.remove(_k('conversation', scopeKey)));
    } else {
      unawaited(_prefs.setString(_k('conversation', scopeKey), id));
    }
    if (taskIds.isEmpty) {
      unawaited(_prefs.remove(_k('tasks', scopeKey)));
    } else {
      // The last few tasks are enough to bring the thread back.
      final keep = taskIds.length > 10
          ? taskIds.sublist(taskIds.length - 10)
          : taskIds;
      unawaited(_prefs.setStringList(_k('tasks', scopeKey), keep));
    }
  }

  /// Logout / leaving a family: this phone forgets every kept assistant input.
  Future<void> clearAll() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(k);
    }
  }
}

// ---------- Providers ----------

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final assistantLocalStoreProvider = Provider<AssistantLocalStore>(
  (ref) => AssistantLocalStore(ref.watch(sharedPreferencesProvider)),
);

/// My assistant consent (per person, P-160).
final assistantConsentProvider =
    StreamProvider.family<AssistantConsent, String>(
      (ref, uid) => ref.watch(assistantRepositoryProvider).watchConsent(uid),
    );

/// The household pool for [babyId] (Home badge, CH19); null while unknown — never a static
/// number. Refreshed by the chat after quotes and answers.
final assistantUsageProvider = FutureProvider.autoDispose
    .family<AssistantUsage?, (String, String)>((ref, key) async {
      try {
        return await ref
            .watch(assistantRepositoryProvider)
            .usage(key.$1, locale: key.$2);
      } on Object {
        return null;
      }
    }, retry: (_, _) => null);

/// CH03: the authoritative snapshot of a conversation's last task (its row status); null when it
/// can't be read. A read: no credits.
final assistantTaskSnapshotProvider = FutureProvider.autoDispose
    .family<TaskSnapshot?, (String, String)>((ref, key) async {
      try {
        return await ref
            .watch(assistantRepositoryProvider)
            .task(key.$1, locale: key.$2);
      } on Object {
        return null;
      }
    }, retry: (_, _) => null);

/// Most source records CH08 reads back for its per-feed times (a day of feeds fits easily).
const summarySourceLimit = 40;

/// CH08: the bottles and nursing sessions a summary counted, by its `sourceIds`
/// (`'<id>,<id>'`), read from the baby's care log the app already syncs; deleted or unreadable
/// records are left out. Null until every one has loaded.
final summarySourcesProvider = Provider.autoDispose
    .family<List<SummaryItem>?, (String, String)>((ref, key) {
      final (babyId, joined) = key;
      final out = <SummaryItem>[];
      for (final id in joined.split(',')) {
        if (id.isEmpty) continue;
        final v = ref.watch(careRecordProvider((babyId, id)));
        if (v.isLoading && !v.hasValue) return null;
        final r = v.hasError ? null : v.value;
        if (r == null || r.deleted) continue;
        switch (r.type) {
          case CareType.bottle:
            out.add(
              SummaryItem(
                id: r.id,
                kind: 'bottle',
                at: r.occurredAt,
                ml: r.amountMl,
              ),
            );
          case CareType.breast:
            out.add(
              SummaryItem(
                id: r.id,
                kind: 'breast',
                at: r.occurredAt,
                minutes: r.durationMin,
              ),
            );
          default:
            break;
        }
      }
      return out;
    });

/// New request ids (tests make them predictable).
final assistantIdsProvider = Provider<String Function()>(
  (ref) => newAssistantRequestId,
);

/// The assistant's clock (draft expiry, form checks); tests pin it.
final assistantClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
