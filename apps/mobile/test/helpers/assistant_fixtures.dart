import 'dart:async';
import 'dart:typed_data';

import 'package:child_life/features/assistant/assistant_controller.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_photos.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_voice.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/billing_repository.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'family_fixtures.dart';
import 'rhythm_fixtures.dart';

/// Child Life Assistant (slice A4) fixtures, synthetic and shaped like the contracts
/// (`packages/contracts/src/assistant.ts`): the simulation pack's clock (2026-10-15 07:20Z =
/// 14:20 in Hồ Chí Minh), Teddy's text batch (bottle 08:00 120 ml, sleep 09:00–10:00), the CH08
/// summary (390 ml over 3 bottles, 35 nursing minutes over 2), and a scripted repository that
/// records every call. No Firebase.

final assistantNow = DateTime.utc(2026, 10, 15, 7, 20);
final teddyScope = const AssistantScope.child(teddyId);
final householdScope = const AssistantScope.household(teddyId);

const taskA = 'tk_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const taskB = 'tk_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const conversation1 = 'cv_11111111111111111111111111111111';
String draftOf(String taskId, int i) => 'dr_${taskId.substring(3)}_$i';

Map<String, Object?> usageJson({
  String plan = 'free',
  int limit = 20,
  int used = 2,
  int reserved = 0,
  int? remaining,
  String resetsAt = '2026-10-31T17:00:00.000Z',
  List<Map<String, Object?>> recent = const [],
}) => {
  'plan': plan,
  'limit': limit,
  'used': used,
  'reserved': reserved,
  'remaining': remaining ?? (limit - used - reserved),
  'resetsAt': resetsAt,
  'policyVersion': 'assistant-qa-v3',
  'textCredits': 1,
  'imageCredits': 3,
  'recent': recent,
};

Map<String, Object?> quoteJson({
  bool allowed = true,
  String? reason,
  String modality = 'text',
  int? credits,
  Map<String, Object?>? usage,
}) => {
  'quoteId': 'qt_1',
  'modality': modality,
  'credits': credits ?? (modality == 'image' ? 3 : 1),
  'allowed': allowed,
  'reason': reason,
  'expiresAt': '2026-10-15T07:25:00.000Z',
  'usage': usage ?? usageJson(),
};

Map<String, Object?> taskJson({
  String id = taskA,
  String state = 'ready',
  int version = 3,
  String? errorCode,
  Map<String, Object?>? clarification,
  String plan = 'free',
  String scopeType = 'child',
}) => {
  'id': id,
  'conversationId': conversation1,
  'scope': {'type': scopeType, 'babyId': teddyId},
  'state': state,
  'version': version,
  'modality': 'text',
  'credits': 1,
  'plan': plan,
  'usage': state == 'failed' ? 'released' : 'committed',
  'errorCode': errorCode,
  'round': clarification == null ? 0 : 1,
  'clarification': clarification,
  'clarificationExpiresAt': clarification == null
      ? null
      : '2026-10-15T07:50:00.000Z',
  'anchorInstant': '2026-10-15T07:20:00.000Z',
  'timezone': 'Asia/Ho_Chi_Minh',
  'createdAt': '2026-10-15T07:20:00.000Z',
  'updatedAt': '2026-10-15T07:20:05.000Z',
};

Map<String, Object?> bottleDraftJson({
  String taskId = taskA,
  int index = 0,
  num? ml = 120,
  String at = '2026-10-15T01:00:00.000Z',
  String state = 'draft',
  int revision = 1,
  List<String> uncertain = const [],
  String? errorCode,
  String? recordId,
}) => {
  'id': draftOf(taskId, index),
  'taskId': taskId,
  'itemIndex': index,
  'scope': {'type': 'child', 'babyId': teddyId},
  'payload': {'kind': 'bottle', 'amountMl': ml, 'occurredAt': at, 'milk': null},
  'missingFields': const <String>[],
  'uncertainFields': uncertain,
  'revision': revision,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': recordId,
  'recordLink': recordId == null ? null : '/care/record/$recordId',
  'errorCode': errorCode,
  'warnings': const <String>[],
  'problems': const <String>[],
};

Map<String, Object?> sleepDraftJson({
  String taskId = taskA,
  int index = 1,
  String start = '2026-10-15T02:00:00.000Z',
  String end = '2026-10-15T03:00:00.000Z',
  String state = 'draft',
  int revision = 1,
  String? errorCode,
}) => {
  'id': draftOf(taskId, index),
  'taskId': taskId,
  'itemIndex': index,
  'scope': {'type': 'child', 'babyId': teddyId},
  'payload': {'kind': 'sleep', 'startedAt': start, 'endedAt': end},
  'missingFields': const <String>[],
  'uncertainFields': const <String>[],
  'revision': revision,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': null,
  'recordLink': null,
  'errorCode': errorCode,
  'warnings': errorCode == 'DOMAIN_CONFLICT' ? ['overlap'] : const <String>[],
  'problems': const <String>[],
};

Map<String, Object?> userMessage(String text, {String taskId = taskA}) => {
  'id': 'm_${taskId}_u',
  'conversationId': conversation1,
  'role': 'user',
  'parts': [
    {'type': 'text', 'schemaVersion': 1, 'text': text},
  ],
  'taskId': taskId,
  'sequence': 1,
  'createdAt': '2026-10-15T07:20:00.000Z',
  'attachmentIds': const <String>[],
};

Map<String, Object?> assistantMessage(
  List<Map<String, Object?>> parts, {
  String taskId = taskA,
  int sequence = 2,
}) => {
  'id': 'm_${taskId}_$sequence',
  'conversationId': conversation1,
  'role': 'assistant',
  'parts': parts,
  'taskId': taskId,
  'sequence': sequence,
  'createdAt': '2026-10-15T07:20:05.000Z',
  'attachmentIds': const <String>[],
};

Map<String, Object?> textPart(String text) => {
  'type': 'text',
  'schemaVersion': 1,
  'text': text,
};

Map<String, Object?> draftRef(String id, [int revision = 1]) => {
  'type': 'draft_reference',
  'schemaVersion': 1,
  'draftId': id,
  'revision': revision,
};

/// CH08 / R01: 3 bottles 390 ml, 2 nursing 35 min, coverage unknown, until 14:20.
Map<String, Object?> summaryPart() => {
  'type': 'source_summary',
  'schemaVersion': 1,
  'summary': {
    'date': '2026-10-15',
    'bottle': {'count': 3, 'ml': 390},
    'breast': {'count': 2, 'minutes': 35},
    'sleep': {'count': 0, 'minutes': 0},
    'coverage': 'unknown',
    'until': '2026-10-15T07:20:00.000Z',
  },
  'sourceIds': ['test_b1', 'test_b2', 'test_b3', 'test_n1', 'test_n2'],
};

/// The care records [summaryPart] counted (Hà Nội time): bottles 08:00 150 ml, 11:10 120 ml,
/// 13:50 120 ml; nursing 09:30 20 min, 12:40 15 min.
Map<String, CareRecord> summaryRecords({int firstBottleMl = 150}) {
  DateTime vn(int h, int m) => DateTime.utc(2026, 10, 15, h - 7, m);
  CareRecord r(String id, CareType type, DateTime at, {int? ml, int? min}) =>
      CareRecord(
        id: id,
        babyId: teddyId,
        type: type,
        occurredAt: at,
        createdBy: 'u_mai',
        author: const CareAuthor(name: 'Mai', relation: Relation.mother),
        amountMl: ml,
        durationMin: min,
      );
  return {
    'test_b1': r('test_b1', CareType.bottle, vn(8, 0), ml: firstBottleMl),
    'test_b2': r('test_b2', CareType.bottle, vn(11, 10), ml: 120),
    'test_b3': r('test_b3', CareType.bottle, vn(13, 50), ml: 120),
    'test_n1': r('test_n1', CareType.breast, vn(9, 30), min: 20),
    'test_n2': r('test_n2', CareType.breast, vn(12, 40), min: 15),
  };
}

Map<String, Object?> clarificationJson() => {
  'id': 'c1',
  'field': 'sleep.period',
  'question': {
    'vi': 'Giấc ngủ có giờ kết thúc trước giờ bắt đầu. Bạn muốn ghi thế nào?',
    'en': 'The sleep ends before it starts. How should I log it?',
  },
  'choices': [
    {
      'id': 'a',
      'label': {'vi': '9:00 – 10:00', 'en': '9:00 – 10:00'},
    },
    {
      'id': 'b',
      'label': {'vi': '22:00 – 9:00 sáng nay', 'en': '10pm – 9am today'},
    },
  ],
  'allowText': true,
};

/// CH04: Teddy's text batch as two drafts, ready.
Map<String, Object?> batchSnapshot({
  String bottleState = 'draft',
  String sleepState = 'draft',
  String? sleepError,
  num bottleMl = 120,
  int bottleRevision = 1,
  bool text = true,
}) => {
  'task': taskJson(),
  'drafts': [
    bottleDraftJson(ml: bottleMl, state: bottleState, revision: bottleRevision),
    sleepDraftJson(state: sleepState, errorCode: sleepError),
  ],
  'events': [
    {
      'taskId': taskA,
      'eventId': 'ev1',
      'sequence': 1,
      'type': 'accepted',
      'emittedAt': '2026-10-15T07:20:00.000Z',
      'payload': const <String, Object?>{},
    },
    {
      'taskId': taskA,
      'eventId': 'ev2',
      'sequence': 2,
      'type': 'drafts_ready',
      'emittedAt': '2026-10-15T07:20:05.000Z',
      'payload': const <String, Object?>{},
    },
  ],
  'messages': [
    userMessage('8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.'),
    assistantMessage([
      if (text)
        textPart('Mình thấy 2 việc. Kiểm tra rồi chọn mục muốn lưu nhé.'),
      draftRef(draftOf(taskA, 0), bottleRevision),
      draftRef(draftOf(taskA, 1)),
    ]),
  ],
};

Map<String, Object?> snapshotWith({
  required Map<String, Object?> task,
  List<Map<String, Object?>> drafts = const [],
  List<Map<String, Object?>> messages = const [],
}) => {
  'task': task,
  'drafts': drafts,
  'events': const <Object>[],
  'messages': messages,
};

/// Envelope `{contractVersion, requestId, …, data}` as every assistant callable answers.
Map<String, Object?> envelope(
  Object? data, {
  String status = 'ok',
  String? reason,
  String? taskId,
}) => {
  'contractVersion': 1,
  'requestId': 'req',
  'taskId': taskId,
  'serverTime': '2026-10-15T07:20:00.000Z',
  'dataVersion': 1,
  'status': status,
  'reasonCode': reason,
  'retryable': false,
  'data': data,
};

/// Every call the screens made, in order.
typedef AssistantCall = ({String name, Map<String, Object?> args});

/// Answers the assistant callables from fixtures (a function per call), keeps live task
/// streams a test can push to, and records the calls.
class FakeAssistantRepository implements AssistantRepository {
  FakeAssistantRepository({
    Map<String, Object?>? usage,
    this.quoteAnswer,
    this.startAnswer,
    Map<String, Map<String, Object?>>? tasks,
    this.confirmAnswer,
    this.patchAnswer,
    this.error,
    this.conversationsAnswer,
    this.messagesAnswer,
    this.uploadAnswer,
    this.planAnswer,
    AssistantConsent consent = const AssistantConsent(
      version: assistantConsentVersion,
    ),
  }) : usageJsonValue = usage ?? usageJson(),
       tasks = tasks ?? {},
       _consent = StreamController<AssistantConsent>.broadcast(),
       consentValue = consent;

  Map<String, Object?> usageJsonValue;

  /// The next answers; a function gets the call's args.
  Object? Function(Map<String, Object?> args)? quoteAnswer;
  Object? Function(Map<String, Object?> args)? startAnswer;
  Object? Function(Map<String, Object?> args)? confirmAnswer;
  Object? Function(Map<String, Object?> args)? patchAnswer;
  Object? Function()? conversationsAnswer;
  Object? Function()? messagesAnswer;
  Object? Function(Map<String, Object?> args)? uploadAnswer;
  Object? Function(Map<String, Object?> args)? planAnswer;

  /// Thrown by any call named here (`{'quoteTask': AssistantException(...)}`).
  Map<String, Object>? error;

  /// Holds `startTask` / `submitClarification` until completed (optimistic UI while waiting).
  Completer<void>? startGate;
  Completer<void>? clarifyGate;

  /// `getAssistantTask` answers per task id (a snapshot JSON).
  final Map<String, Map<String, Object?>> tasks;
  AssistantConsent consentValue;
  final StreamController<AssistantConsent> _consent;
  final live = <String, StreamController<TaskLive>>{};
  final calls = <AssistantCall>[];

  List<AssistantCall> named(String name) => [
    for (final c in calls)
      if (c.name == name) c,
  ];

  void _record(String name, Map<String, Object?> args) {
    calls.add((name: name, args: args));
    if (error?[name] case final e?) throw e;
  }

  void push(String taskId, TaskLive update) => live
      .putIfAbsent(taskId, StreamController<TaskLive>.broadcast)
      .add(update);

  @override
  Future<AssistantQuote> quote({
    required AssistantScope scope,
    required String? conversationId,
    required TaskModality modality,
    required String locale,
    int attachmentCount = 0,
    IntentHint? intentHint,
  }) async {
    final args = {
      'scope': scope.key,
      'conversationId': conversationId,
      'modality': modality.wire,
      'attachmentCount': attachmentCount,
      'intentHint': intentHint?.wire,
    };
    _record(AssistantCallables.quote, args);
    final json =
        quoteAnswer?.call(args) ??
        quoteJson(modality: modality.wire, usage: usageJsonValue);
    return AssistantQuote.fromJson(json)!;
  }

  @override
  Future<StartAnswer> start({
    required String requestId,
    required AssistantScope scope,
    required String? conversationId,
    required String quoteId,
    required String? text,
    required String locale,
    List<String> attachmentIds = const [],
  }) async {
    final args = {
      'requestId': requestId,
      'scope': scope.key,
      'conversationId': conversationId,
      'quoteId': quoteId,
      'text': text,
      'attachmentIds': attachmentIds,
    };
    _record(AssistantCallables.start, args);
    if (startGate case final g?) await g.future;
    final e = AssistantEnvelope.fromJson(
      startAnswer?.call(args) ?? envelope(batchSnapshot()),
    );
    final data = e.data is Map ? e.data! as Map : const {};
    return (
      snapshot: TaskSnapshot.fromJson(data),
      status: e.status,
      reason: e.reason,
      usage: AssistantUsage.fromJson(data['usage']),
    );
  }

  @override
  Future<TaskSnapshot?> clarify({
    required String taskId,
    required int expectedVersion,
    required String clarificationId,
    required String locale,
    String? choiceId,
    String? text,
  }) async {
    _record(AssistantCallables.clarify, {
      'taskId': taskId,
      'expectedVersion': expectedVersion,
      'clarificationId': clarificationId,
      'choiceId': choiceId,
      'text': text,
    });
    if (clarifyGate case final g?) await g.future;
    return TaskSnapshot.fromJson(tasks[taskId]);
  }

  @override
  Future<AssistantDraft?> patchDraft({
    required String draftId,
    required int expectedRevision,
    required DraftPayload payload,
    required List<String> confirmedFields,
    required String locale,
  }) async {
    final args = {
      'draftId': draftId,
      'expectedRevision': expectedRevision,
      'payload': payload.toJson(),
      'confirmedFields': confirmedFields,
    };
    _record(AssistantCallables.patchDraft, args);
    return AssistantDraft.fromJson(patchAnswer?.call(args));
  }

  @override
  Future<ConfirmResult> confirm({
    required String taskId,
    required AssistantScope scope,
    required List<ConfirmSelection> selected,
    required String requestId,
    required String locale,
  }) async {
    final args = {
      'taskId': taskId,
      'scope': scope.key,
      'requestId': requestId,
      'selected': [for (final s in selected) s.toJson()],
    };
    _record(AssistantCallables.confirm, args);
    return ConfirmResult.fromJson(
      confirmAnswer?.call(args) ??
          {
            'items': [
              for (final s in selected)
                {
                  'draftId': s.draftId,
                  'status': 'saved',
                  'revision': s.revision,
                  'recordId': 'r_${'c' * 32}',
                  'recordLink': '/care/record/r_${'c' * 32}',
                  'errorCode': null,
                  'problems': const <String>[],
                },
            ],
            'partial': false,
          },
    );
  }

  @override
  Future<AssistantDraft?> discard({
    required String draftId,
    required int expectedRevision,
    required String locale,
  }) async {
    _record(AssistantCallables.discard, {
      'draftId': draftId,
      'expectedRevision': expectedRevision,
    });
    return null;
  }

  @override
  Future<AssistantTask?> cancel({
    required String taskId,
    required String locale,
  }) async {
    _record(AssistantCallables.cancel, {'taskId': taskId});
    return AssistantTask.fromJson(
      taskJson(id: taskId, state: 'canceled', version: 9),
    );
  }

  @override
  Future<void> feedback({
    required String taskId,
    required String contentId,
    required int contentVersion,
    required FeedbackOutcome outcome,
    required String locale,
  }) async => _record(AssistantCallables.feedback, {
    'taskId': taskId,
    'contentId': contentId,
    'contentVersion': contentVersion,
    'outcome': outcome.wire,
  });

  @override
  Future<AssistantUploadTarget> createUpload({
    required String quoteId,
    required String mime,
    required int bytes,
    required String sha256,
    required AttachmentRetention retention,
    required String requestId,
    required String locale,
  }) async {
    final args = {
      'quoteId': quoteId,
      'mime': mime,
      'bytes': bytes,
      'sha256': sha256,
      'retention': retention.wire,
      'requestId': requestId,
    };
    _record(AssistantCallables.upload, args);
    return AssistantUploadTarget.fromJson(
      uploadAnswer?.call(args) ?? uploadTargetJson(retention: retention.wire),
    )!;
  }

  @override
  Future<AssistantCarePlan?> plan({
    required String taskId,
    required String contentId,
    required int contentVersion,
    required String requestId,
    required String locale,
  }) async {
    final args = {
      'taskId': taskId,
      'contentId': contentId,
      'contentVersion': contentVersion,
    };
    _record(AssistantCallables.plan, args);
    return AssistantCarePlan.fromJson(
      planAnswer?.call(args) ?? planJson(contentId: contentId),
    );
  }

  @override
  Future<AssistantUsage?> usage(String babyId, {required String locale}) async {
    _record(AssistantCallables.usage, {'babyId': babyId});
    return AssistantUsage.fromJson(usageJsonValue);
  }

  @override
  Future<HistoryPage<AssistantConversation>> conversations(
    String babyId, {
    required String locale,
    String? cursor,
    int limit = 30,
  }) async {
    _record(AssistantCallables.history, {'babyId': babyId});
    final raw = conversationsAnswer?.call();
    return HistoryPage([
      for (final x in (raw is List ? raw : const []))
        ?AssistantConversation.fromJson(x),
    ], null);
  }

  @override
  Future<HistoryPage<AssistantMessage>> messages(
    String babyId,
    String conversationId, {
    required String locale,
    String? cursor,
    int limit = 50,
  }) async {
    _record(AssistantCallables.history, {
      'babyId': babyId,
      'conversationId': conversationId,
    });
    final raw = messagesAnswer?.call();
    return HistoryPage([
      for (final x in (raw is List ? raw : const []))
        ?AssistantMessage.fromJson(x),
    ], null);
  }

  @override
  Future<TaskSnapshot?> task(
    String taskId, {
    required String locale,
    int? afterSequence,
  }) async {
    _record(AssistantCallables.task, {
      'taskId': taskId,
      'afterSequence': afterSequence,
    });
    return TaskSnapshot.fromJson(tasks[taskId]);
  }

  @override
  Future<({int deletedTasks, bool domainRecordsKept})> deleteConversation(
    String conversationId, {
    required String locale,
  }) async {
    _record(AssistantCallables.deleteConversation, {
      'conversationId': conversationId,
    });
    return (deletedTasks: 1, domainRecordsKept: true);
  }

  @override
  Future<void> setConsent({required bool agree, required String locale}) async {
    _record(AssistantCallables.consent, {'agree': agree});
    consentValue = AssistantConsent(
      version: agree ? assistantConsentVersion : null,
    );
    _consent.add(consentValue);
  }

  @override
  Stream<AssistantConsent> watchConsent(String uid) async* {
    yield consentValue;
    yield* _consent.stream;
  }

  @override
  Stream<TaskLive> watchTask(String taskId) =>
      live.putIfAbsent(taskId, StreamController<TaskLive>.broadcast).stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A `getCapabilities` answer with the assistant flag (and photo reading) on.
Map<String, Object?> assistantCaps({
  bool assistant = true,
  bool images = false,
  String plan = 'free',
  String? country = 'VN',
  bool billing = false,
  bool upsell = true,
}) {
  final caps = rhythmCaps(plan: plan, country: country);
  return {
    ...caps,
    'capabilities': {
      ...(caps['capabilities']! as Map<String, Object?>),
      'templates.premium': {
        'allowed': plan == 'premium',
        'reason': plan == 'premium' ? null : 'PREMIUM_REQUIRED',
        'via': plan == 'premium' ? 'paid' : null,
      },
    },
    'features': {
      ...(caps['features']! as Map<String, Object?>),
      'assistant': assistant,
      'assistantImages': images,
      'assistantCare': true,
      'assistantUpsell': upsell,
      'billing': billing,
    },
  };
}

/// Family, rhythm (health pack with 115 for VN, dialer), capabilities and the assistant fake.
List<Override> assistantOverrides({
  required FakeAssistantRepository repo,
  Membership? me,
  bool online = true,
  bool images = false,
  String plan = 'free',
  Map<String, Object?>? caps,
  List<String>? dialled,
  Future<bool> Function(BuildContext, PurchaseResume)? paywall,
  PickedPhoto? photo,
  VideoQuota? video,
  Stream<bool>? onlineStream,
  FakeUploader? uploader,

  /// The care log CH08 reads its per-feed times from (by record id); none by default.
  Map<String, CareRecord> careRecords = const {},

  /// Lumi voice input (a scripted recognizer; ready by default).
  FakeDictation? dictation,

  /// Lumi 2026-10-16: the baby's running timers (none by default; the timer clock is
  /// [assistantNow]).
  Map<TimerType, CareTimer> timers = const {},
}) {
  var n = 0;
  return [
    ...rhythmOverrides(
      repo: FakeRhythmRepository(),
      me: me ?? mai,
      caps: caps ?? assistantCaps(images: images, plan: plan),
      online: online,
      dialled: dialled,
      now: assistantNow,
      timers: timers,
    ),
    assistantRepositoryProvider.overrideWithValue(repo),
    assistantClockProvider.overrideWithValue(() => assistantNow),
    assistantIdsProvider.overrideWithValue(
      () => '00000000-0000-4000-8000-${(++n).toString().padLeft(12, '0')}',
    ),
    if (paywall != null) assistantPaywallProvider.overrideWithValue(paywall),
    assistantPhotoPickerProvider.overrideWithValue(
      (source) async => photo ?? PickedPhoto(name: 'note.jpg', bytes: tinyJpeg),
    ),
    assistantUploaderProvider.overrideWithValue(uploader ?? FakeUploader()),
    assistantPhotoCacheProvider.overrideWithValue(AssistantPhotoCache()),
    assistantDictationProvider.overrideWithValue(dictation ?? FakeDictation()),
    videoQuotaProvider.overrideWith((ref, babyId) async => video),
    careRecordProvider.overrideWith(
      (ref, key) => Stream.value(careRecords[key.$2]),
    ),
    if (onlineStream != null)
      assistantOnlineProvider.overrideWith(
        (ref) => ref.watch(_onlineStream(onlineStream)),
      ),
  ];
}

final _streams = <Stream<bool>, StreamProvider<bool>>{};

/// One provider per test stream (a connectivity a test switches on and off).
StreamProvider<bool> _onlineStream(Stream<bool> s) =>
    _streams.putIfAbsent(s, () => StreamProvider<bool>((ref) => s));

// ---------- Slice A5: photos and care ----------

/// A 1×1 JPEG (synthetic; the app shows it as the local thumbnail).
final tinyJpeg = Uint8List.fromList(const [
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, //
  0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
  0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
  0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
  0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
  0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
  0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
  0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
  0x00, 0x00, 0x3F, 0x00, 0x2A, 0x9F, 0xFF, 0xD9,
]);

const attachment1 = 'at_11111111111111111111111111111111';

Map<String, Object?> uploadTargetJson({
  String id = attachment1,
  String retention = 'keep_with_record',
}) => {
  'attachmentId': id,
  'uploadPath': 'assistant/u_mai/$id',
  'mime': 'image/jpeg',
  'maxBytes': 1024,
  'expiresAt': '2026-10-15T07:35:00.000Z',
  'retention': retention,
};

Map<String, Object?> planJson({String contentId = 'act_wind_down'}) => {
  'contentId': contentId,
  'contentVersion': 1,
  'plannedFor': '2026-10-15',
  'plannedAt': '2026-10-15T07:20:00.000Z',
  'feedbackOpensAt': '2026-10-15T22:00:00.000Z',
};

/// A scripted upload: progress the test pushes, completion it controls, cancel it sees.
class FakeUploader implements AssistantUploader {
  FakeUploader({this.auto = true});

  /// Completes every upload at once (100 %).
  final bool auto;
  final uploads = <FakeUpload>[];

  @override
  AssistantUpload start(String path, Uint8List bytes, String mime) {
    final u = FakeUpload(path, bytes.length, mime);
    uploads.add(u);
    if (auto) u.finish();
    return u;
  }
}

class FakeUpload implements AssistantUpload {
  FakeUpload(this.path, this.size, this.mime);
  final String path;
  final int size;
  final String mime;
  final _progress = StreamController<double>.broadcast();
  final _done = Completer<void>();
  var canceled = false;

  void push(double v) => _progress.add(v);

  void finish() {
    if (!_done.isCompleted) _done.complete();
  }

  void fail(Object e) {
    if (!_done.isCompleted) _done.completeError(e);
  }

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> cancel() async {
    canceled = true;
    if (!_done.isCompleted) _done.completeError(const UploadCanceled());
  }
}

Map<String, Object?> photoTaskJson({
  String id = taskA,
  String state = 'ready',
  int version = 3,
  String? errorCode,
  Map<String, Object?>? clarification,
  String scopeType = 'household',
}) => {
  ...taskJson(
    id: id,
    state: state,
    version: version,
    errorCode: errorCode,
    clarification: clarification,
    scopeType: scopeType,
  ),
  'modality': 'image',
  'credits': 3,
  'usage': state == 'failed'
      ? 'released'
      : (state == 'awaiting_clarification' || state == 'processing'
            ? 'reserved'
            : 'committed'),
};

/// A care task (text) with its `task.care` view.
Map<String, Object?> careTaskJson({
  String id = taskA,
  String state = 'ready',
  Map<String, Object?>? clarification,
  Map<String, Object?>? care,
}) => {
  ...taskJson(id: id, state: state, clarification: clarification),
  'care': care,
};

Map<String, Object?> photoMessage({
  String taskId = taskA,
  String attachmentId = attachment1,
}) => {
  'id': 'm_${taskId}_u',
  'conversationId': conversation1,
  'role': 'user',
  'parts': const <Object>[],
  'taskId': taskId,
  'sequence': 1,
  'createdAt': '2026-10-15T07:20:00.000Z',
  'attachmentIds': [attachmentId],
};

Map<String, Object?> attachmentJson({
  String id = attachment1,
  String state = 'ready',
  String retention = 'keep_with_record',
  bool kept = false,
  String? deletedAt,
  bool rejected = false,
}) => {
  'id': id,
  'mime': 'image/jpeg',
  'bytes': 1024,
  'retention': retention,
  'state': state,
  'keptWithRecord': kept,
  'deletedAt': deletedAt,
  'rejected': rejected,
};

/// A photo task snapshot: the user's photo, the assistant's parts, drafts and photo state.
Map<String, Object?> photoSnapshot({
  required Map<String, Object?> task,
  List<Map<String, Object?>> parts = const [],
  List<Map<String, Object?>> drafts = const [],
  List<Map<String, Object?>> attachments = const [],
}) => {
  'task': task,
  'drafts': drafts,
  'events': const <Object>[],
  'messages': [
    photoMessage(taskId: task['id']! as String),
    if (parts.isNotEmpty)
      assistantMessage(parts, taskId: task['id']! as String),
  ],
  'attachments': attachments.isEmpty ? [attachmentJson()] : attachments,
};

/// CH11: the Con Cưng receipt (486.000 ₫ incl. 36.000 ₫ tax, 14/10 uncertain).
Map<String, Object?> expenseDraftJson({
  String taskId = taskA,
  String state = 'needs_review',
  List<String> uncertain = const ['date'],
  List<String> warnings = const ['duplicate_suspected'],
  List<String> problems = const [],
  String? currency = 'VND',
  int revision = 1,
  String? recordId,
  String? date = '2026-10-14',
}) => {
  'id': draftOf(taskId, 0),
  'taskId': taskId,
  'itemIndex': 0,
  'scope': {'type': 'household', 'babyId': teddyId},
  'payload': {
    'kind': 'expense',
    'merchant': 'Con Cưng',
    'totalMinor': 486000,
    'currency': currency,
    'date': date,
    'subtotalMinor': 450000,
    'taxMinor': 36000,
    'categoryId': 'c_milk',
    'babyId': teddyId,
    'keepReceipt': true,
  },
  'missingFields': const <String>[],
  'uncertainFields': uncertain,
  'revision': revision,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': recordId,
  'recordLink': recordId == null
      ? null
      : '/utilities/spending/expense/$recordId?babyId=$teddyId',
  'errorCode': null,
  'warnings': warnings,
  'problems': problems,
};

Map<String, Object?> reminderDraftJson({
  String taskId = taskA,
  int index = 0,
  String title = 'Đặt lịch khám 2 tháng',
  String? date = '2026-10-20',
  String? time = '09:00',
  String state = 'draft',
  List<String> missing = const [],
  List<String> uncertain = const [],
  List<String> problems = const [],
  String? assignee,
}) => {
  'id': draftOf(taskId, index),
  'taskId': taskId,
  'itemIndex': index,
  'scope': {'type': 'household', 'babyId': teddyId},
  'payload': {
    'kind': 'reminder',
    'title': title,
    'date': date,
    'time': time,
    'assigneeUid': assignee,
  },
  'missingFields': missing,
  'uncertainFields': uncertain,
  'revision': 1,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': null,
  'recordLink': null,
  'errorCode': null,
  'warnings': const <String>[],
  'problems': problems,
};

Map<String, Object?> observationDraftJson({
  String taskId = taskA,
  String state = 'draft',
}) => {
  'id': draftOf(taskId, 0),
  'taskId': taskId,
  'itemIndex': 0,
  'scope': {'type': 'child', 'babyId': teddyId},
  'payload': {
    'kind': 'observation',
    'observation': 'sleep',
    'date': '2026-10-15',
    'when': 'night',
    'note': null,
  },
  'missingFields': const <String>[],
  'uncertainFields': const <String>[],
  'revision': 1,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': state == 'saved' ? 'ci_${'d' * 32}' : null,
  'recordLink': state == 'saved'
      ? '/rhythm/checkins/$teddyId/ci_${'d' * 32}'
      : null,
  'errorCode': null,
  'warnings': const <String>[],
  'problems': const <String>[],
};

Map<String, Object?> sleepClarification(String field) => {
  'id': 'c_$field',
  'field': field,
  'question': field == 'sleep.period'
      ? {
          'vi':
              'Mình hỏi nhanh để gợi ý đúng hơn nhé. Con khó vào giấc hay hay thức giấc?',
          'en':
              'A quick question so I can help. Is it hard to fall asleep, or waking often?',
        }
      : {'vi': 'Giấc ngày hay giấc đêm?', 'en': 'Naps or night sleep?'},
  'choices': field == 'sleep.period'
      ? [
          {
            'id': 'falling_asleep',
            'label': {'vi': 'Khó vào giấc', 'en': 'Hard to fall asleep'},
          },
          {
            'id': 'night_waking',
            'label': {'vi': 'Hay thức giấc', 'en': 'Waking often'},
          },
          {
            'id': 'both',
            'label': {'vi': 'Cả hai', 'en': 'Both'},
          },
        ]
      : [
          {
            'id': 'night',
            'label': {'vi': 'Giấc đêm', 'en': 'Night'},
          },
          {
            'id': 'day',
            'label': {'vi': 'Giấc ngày', 'en': 'Naps'},
          },
          {
            'id': 'unknown',
            'label': {'vi': 'Chưa rõ', 'en': 'Not sure'},
          },
        ],
  'allowText': false,
};

/// CH16: the published wind-down item (illustrative content, unreviewed by default).
Map<String, Object?> guidancePart({
  bool reviewed = false,
  bool alternatives = true,
}) => {
  'type': 'approved_content',
  'schemaVersion': 1,
  'contentId': 'act_wind_down',
  'contentVersion': 1,
  'reason': 'Vì sao: bạn chọn “khó vào giấc, giấc đêm”.',
  'reviewed': reviewed,
  'reasonCode': 'SELF_REPORTED_NEED',
  'content': {
    'title': 'Giảm kích thích 30 phút trước giấc đêm',
    'summary': 'Một nếp nhẹ nhàng trước giấc đêm.',
    'steps': [
      'Giảm đèn và tiếng ồn.',
      'Tắm ấm hoặc lau người.',
      'Cho bú yên tĩnh, đặt xuống khi buồn ngủ.',
    ],
    'safety': null,
    'durationMin': 30,
    'timeOfDay': 'evening',
  },
  'alternatives': alternatives
      ? [
          {'contentId': 'act_white_noise', 'contentVersion': 2},
        ]
      : const <Object>[],
};

Map<String, Object?> sleepCare({
  Map<String, Object?>? plan,
  bool followUp = false,
  String? feedback,
}) => {
  'topic': 'sleep_concern',
  'sleep': {'kind': 'falling_asleep', 'when': 'night', 'since': null},
  'guidance': {
    'contentId': 'act_wind_down',
    'contentVersion': 1,
    'reasonCode': 'SELF_REPORTED_NEED',
    'reviewed': false,
  },
  'recipeIds': const <String>[],
  'plan': plan,
  'followUp': followUp
      ? {
          'contentId': 'act_wind_down',
          'contentVersion': 1,
          'question': {
            'vi':
                'Bạn có dịp thử “Giảm kích thích 30 phút trước giấc đêm” chưa? Nếu đã thử, thấy thế nào?',
            'en':
                'Did you get a chance to try “Wind down 30 minutes before night sleep”? If you did, how did it go?',
          },
          'choices': [
            {
              'id': 'helpful',
              'label': {'vi': 'Có ích', 'en': 'Helpful'},
            },
            {
              'id': 'unsure',
              'label': {'vi': 'Chưa rõ', 'en': 'Not sure'},
            },
            {
              'id': 'not_suitable',
              'label': {'vi': 'Không phù hợp', 'en': 'Not a fit'},
            },
            {
              'id': 'not_tried',
              'label': {'vi': 'Chưa thử', 'en': 'Didn’t try'},
            },
          ],
        }
      : null,
  'feedback': feedback == null
      ? null
      : {
          'contentId': 'act_wind_down',
          'contentVersion': 1,
          'outcome': feedback,
        },
};

Map<String, Object?> recipesPart({bool empty = false, int excluded = 1}) => {
  'type': 'recipe_list',
  'schemaVersion': 1,
  'recipeIds': empty ? const <String>[] : ['rc_pumpkin', 'rc_carrot'],
  'caveat': empty
      ? null
      : 'Đã loại món có nguyên liệu con từng có phản ứng (theo ghi nhận của gia đình, không phải chẩn đoán dị ứng). Món chưa có ghi nhận phản ứng không có nghĩa là con đã dung nạp tốt.',
  'items': empty
      ? const <Object>[]
      : [
          {
            'recipeId': 'rc_pumpkin',
            'recipeVersion': 1,
            'title': 'Cháo bí đỏ yến mạch',
            'summary': 'Bí đỏ hấp nghiền với yến mạch nấu mềm.',
            'durationMin': 15,
            'minAgeMonths': 6,
            'why': 'Từ 6 tháng · đã được chuyên môn duyệt',
          },
          {
            'recipeId': 'rc_carrot',
            'recipeVersion': 1,
            'title': 'Cà rốt hấp nghiền',
            'summary': 'Cà rốt hấp chín, nghiền mịn.',
            'durationMin': 10,
            'minAgeMonths': 6,
            'why': 'Từ 6 tháng · đã được chuyên môn duyệt',
          },
        ],
  'excludedCount': empty ? 0 : excluded,
  'mealLogAvailable': false,
};

Map<String, Object?> codedText(String text, String code) => {
  'type': 'text',
  'schemaVersion': 1,
  'text': text,
  'code': code,
};

// ---------- D-075 #2: the baby's shared thread ----------

final sharedConversation = 'cv_$teddyId';

Map<String, Object?> authorJson(Membership m) => {
  'uid': m.uid,
  'name': m.displayName,
  'relation': m.relation.name,
  'relationCustom': m.relationCustom,
};

/// A task of the shared thread asked by [by].
Map<String, Object?> sharedTaskJson({
  required Membership by,
  String id = taskA,
  String state = 'ready',
  Map<String, Object?>? clarification,
  Map<String, Object?>? care,
}) => {
  ...taskJson(id: id, state: state, clarification: clarification),
  'conversationId': sharedConversation,
  'visibility': 'shared',
  'author': authorJson(by),
  'care': ?care,
};

Map<String, Object?> sharedUserMessage(
  String text,
  Membership by, {
  String taskId = taskA,
  int sequence = 1,
}) => {
  ...userMessage(text, taskId: taskId),
  'id': 'm_${taskId}_u$sequence',
  'conversationId': sharedConversation,
  'sequence': sequence,
  'author': authorJson(by),
};

Map<String, Object?> sharedConversationJson() => {
  'id': sharedConversation,
  'ownerUid': null,
  'shared': true,
  'familyId': 'f_1',
  'scope': {'type': 'child', 'babyId': teddyId},
  'title': null,
  'locale': 'vi',
  'createdAt': '2026-10-14T01:00:00.000Z',
  'updatedAt': '2026-10-15T07:00:00.000Z',
  'archivedAt': null,
  'lastTaskId': taskA,
};

// ---------- Voice input ----------

/// A scripted recognizer: [ready] answers `prepare`; a test pushes words, levels and the end
/// with [say], [level] and [finish], and sees the stops and cancels.
class FakeDictation implements AssistantDictation {
  FakeDictation({this.ready = DictationReady.ready});

  DictationReady ready;
  StreamController<DictationEvent>? _events;
  final languages = <String>[];
  var prepared = 0;
  var stops = 0;
  var cancels = 0;

  bool get listening => _events != null && !_events!.isClosed;

  @override
  Future<DictationReady> prepare(String languageCode) async {
    prepared++;
    return ready;
  }

  @override
  Stream<DictationEvent> listen(String languageCode) {
    languages.add(languageCode);
    final c = StreamController<DictationEvent>();
    _events = c;
    return c.stream;
  }

  void say(String words, {bool done = false}) =>
      _events?.add(DictationWords(words, done: done));

  void level(double v) => _events?.add(DictationLevel(v));

  void finish({bool failed = false}) {
    final c = _events;
    if (c == null || c.isClosed) return;
    c.add(DictationEnded(failed: failed));
    unawaited(c.close());
  }

  @override
  Future<void> stop() async {
    stops++;
    finish();
  }

  @override
  Future<void> cancel() async {
    cancels++;
    final c = _events;
    if (c != null && !c.isClosed) unawaited(c.close());
  }
}

// ---------- Lumi 2026-10-16: timers and inline review fixes ----------

/// A `timer` draft ("Con đang ngủ" → start; "dậy rồi" → stop of [sessionId]).
Map<String, Object?> timerDraftJson({
  String taskId = taskA,
  int index = 0,
  String timer = 'sleep',
  String action = 'start',
  String at = '2026-10-15T07:20:00.000Z',
  String? side,
  String? sessionId,
  String? startedAt,
  String state = 'draft',
  int revision = 1,
  String? recordId,
  String? recordLink,
  String? errorCode,
}) => {
  'id': draftOf(taskId, index),
  'taskId': taskId,
  'itemIndex': index,
  'scope': {'type': 'child', 'babyId': teddyId},
  'payload': {
    'kind': 'timer',
    'timer': timer,
    'action': action,
    'at': at,
    'side': side,
    'sessionId': sessionId,
    'startedAt': startedAt,
  },
  'missingFields': const <String>[],
  'uncertainFields': const <String>[],
  'revision': revision,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': recordId,
  'recordLink': recordLink,
  'errorCode': errorCode,
  'warnings': const <String>[],
  'problems': const <String>[],
};

/// Any draft JSON with its review lists and state replaced.
Map<String, Object?> reviewed(
  Map<String, Object?> draft, {
  List<String> missing = const [],
  List<String> uncertain = const [],
  Map<String, Object?> payload = const {},
  int? revision,
}) => {
  ...draft,
  'payload': {...(draft['payload']! as Map<String, Object?>), ...payload},
  'missingFields': missing,
  'uncertainFields': uncertain,
  'state': missing.isEmpty && uncertain.isEmpty ? 'draft' : 'needs_review',
  'revision': ?revision ?? draft['revision'],
};

/// A breastfeed draft (the second dev report: 00:48 · 20 phút, no side).
Map<String, Object?> breastDraftJson({
  String taskId = taskA,
  int index = 0,
  String? at = '2026-10-15T06:48:00.000Z',
  int? minutes = 20,
  String? side,
  String state = 'draft',
  int revision = 1,
}) => {
  'id': draftOf(taskId, index),
  'taskId': taskId,
  'itemIndex': index,
  'scope': {'type': 'child', 'babyId': teddyId},
  'payload': {
    'kind': 'breast',
    'occurredAt': at,
    'durationMin': minutes,
    'side': side,
  },
  'missingFields': const <String>[],
  'uncertainFields': const <String>[],
  'revision': revision,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': null,
  'recordLink': null,
  'errorCode': null,
  'warnings': const <String>[],
  'problems': const <String>[],
};

/// The app's running timer document as `CareTimer` (Mai started it).
CareTimer runningTimer({
  TimerType type = TimerType.sleep,
  String sessionId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  DateTime? startedAt,
}) {
  final at = startedAt ?? assistantNow.subtract(const Duration(minutes: 40));
  return CareTimer(
    babyId: teddyId,
    type: type,
    sessionId: sessionId,
    startedAt: at,
    startedBy: mai.uid,
    author: CareAuthor.of(mai),
    left: type == TimerType.sleep ? null : TimerSide(runningSince: at),
    right: type == TimerType.sleep ? null : const TimerSide(),
  );
}

// ---------- LUMI-01: pump, diaper and growth drafts ----------

Map<String, Object?> _careLogDraft(
  Map<String, Object?> payload, {
  required String taskId,
  required int index,
  required String state,
  required int revision,
  String? recordId,
}) => {
  'id': draftOf(taskId, index),
  'taskId': taskId,
  'itemIndex': index,
  'scope': {'type': 'child', 'babyId': teddyId},
  'payload': payload,
  'missingFields': const <String>[],
  'uncertainFields': const <String>[],
  'revision': revision,
  'state': state,
  'expiresAt': '2026-10-16T07:20:00.000Z',
  'sourceRefs': const <String>[],
  'recordId': recordId,
  'recordLink': recordId == null ? null : '/care/records/$teddyId/$recordId',
  'errorCode': null,
  'warnings': const <String>[],
  'problems': const <String>[],
};

/// "hút sữa 120ml bên trái 15 phút lúc 10h" (10:00 Asia/Ho_Chi_Minh).
Map<String, Object?> pumpDraftJson({
  String taskId = taskA,
  int index = 0,
  num? ml = 120,
  String? at = '2026-10-15T03:00:00.000Z',
  String? side = 'left',
  int? minutes = 15,
  String state = 'draft',
  int revision = 1,
  String? recordId,
}) => _careLogDraft(
  {
    'kind': 'pump',
    'amountMl': ml,
    'occurredAt': at,
    'side': side,
    'durationMin': minutes,
  },
  taskId: taskId,
  index: index,
  state: state,
  revision: revision,
  recordId: recordId,
);

/// "thay tã ướt lúc 13h".
Map<String, Object?> diaperDraftJson({
  String taskId = taskA,
  int index = 0,
  String? diaper = 'wet',
  String? at = '2026-10-15T06:00:00.000Z',
  String state = 'draft',
  int revision = 1,
  String? recordId,
}) => _careLogDraft(
  {'kind': 'diaper', 'diaper': diaper, 'occurredAt': at},
  taskId: taskId,
  index: index,
  state: state,
  revision: revision,
  recordId: recordId,
);

/// "bé nặng 5,2kg dài 62cm".
Map<String, Object?> growthDraftJson({
  String taskId = taskA,
  int index = 0,
  num? kg = 5.2,
  num? cm = 62,
  String? on = '2026-10-15',
  String state = 'draft',
  int revision = 1,
  String? recordId,
}) => _careLogDraft(
  {'kind': 'growth', 'weightKg': kg, 'lengthCm': cm, 'measuredOn': on},
  taskId: taskId,
  index: index,
  state: state,
  revision: revision,
  recordId: recordId,
);
