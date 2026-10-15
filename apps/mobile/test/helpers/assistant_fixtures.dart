import 'dart:async';

import 'package:child_life/features/assistant/assistant_controller.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
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

  /// Thrown by any call named here (`{'quoteTask': AssistantException(...)}`).
  Map<String, Object>? error;

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
    final json = quoteAnswer?.call(args) ?? quoteJson(usage: usageJsonValue);
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
    };
    _record(AssistantCallables.start, args);
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
  }) async => _record(AssistantCallables.feedback, {'taskId': taskId});

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
  Future<void> deleteConversation(
    String conversationId, {
    required String locale,
  }) async => _record(AssistantCallables.deleteConversation, {
    'conversationId': conversationId,
  });

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
  PendingPhoto? photo,
  VideoQuota? video,
  Stream<bool>? onlineStream,
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
    ),
    assistantRepositoryProvider.overrideWithValue(repo),
    assistantClockProvider.overrideWithValue(() => assistantNow),
    assistantIdsProvider.overrideWithValue(
      () => '00000000-0000-4000-8000-${(++n).toString().padLeft(12, '0')}',
    ),
    if (paywall != null) assistantPaywallProvider.overrideWithValue(paywall),
    assistantPhotoPickerProvider.overrideWithValue(
      () async => photo ?? const PendingPhoto(name: 'note.jpg'),
    ),
    videoQuotaProvider.overrideWith((ref, babyId) async => video),
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
