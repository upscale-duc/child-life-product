import 'package:flutter/foundation.dart';

import '../rhythm/rhythm_models.dart' show WireEnum, wireOf;

/// Child Life Assistant v3, slice A4 (docs/assistant/architecture.md, P-155–P-161): hand-written
/// mirrors of `packages/contracts/src/assistant.ts`. The model only reads and prepares; every
/// domain write is a typed draft the person confirms. Parsing is tolerant and versioned: an
/// unknown part type (or a part of a newer schema) becomes [UnsupportedPart], an unknown draft
/// kind [UnknownPayload]; one bad item never drops the whole answer. Nothing here is ever logged
/// (no child data in logs, analytics or crash keys).

/// `assistantContractVersion`, sent with every request.
const assistantContractVersion = 1;

/// `assistantConsentVersion` (P-160): an older consent no longer counts.
const assistantConsentVersion = 'assistant-consent-v1';

/// `assistantTaskLimits` (QA values).
abstract final class AssistantLimits {
  static const maxClarificationRounds = 4;
  static const maxTextChars = 2000;
  static const maxClarificationChars = 200;
  static const maxImagesPerTask = 3;
  static const draftTtl = Duration(hours: 24);
}

/// `assistantErrors` (brief p.11). Unknown codes parse to null and read as a generic failure.
enum AssistantReason with WireEnum {
  authRequired('AUTH_REQUIRED'),
  notMember('NOT_MEMBER'),
  readDenied('READ_DENIED'),
  writeDenied('WRITE_DENIED'),
  consentRequired('CONSENT_REQUIRED'),
  usageExhausted('USAGE_EXHAUSTED'),
  quoteExpired('QUOTE_EXPIRED'),
  quoteMismatch('QUOTE_MISMATCH'),
  scopeChanged('SCOPE_CHANGED'),
  draftStale('DRAFT_STALE'),
  draftExpired('DRAFT_EXPIRED'),
  draftSaved('DRAFT_SAVED'),
  reviewRequired('REVIEW_REQUIRED'),
  duplicateSuspected('DUPLICATE_SUSPECTED'),
  domainConflict('DOMAIN_CONFLICT'),
  moduleUnavailable('MODULE_UNAVAILABLE'),
  regionUnsupported('REGION_UNSUPPORTED'),
  featureDisabled('FEATURE_DISABLED'),
  ocrUnreadable('OCR_UNREADABLE'),
  aiUnavailable('AI_UNAVAILABLE'),
  validationFailed('VALIDATION_FAILED'),
  idempotencyConflict('IDEMPOTENCY_CONFLICT'),
  invalidState('INVALID_STATE');

  const AssistantReason(this.wire);
  @override
  final String wire;

  static AssistantReason? fromWire(Object? v) =>
      wireOf(AssistantReason.values, v);
}

enum ScopeType with WireEnum {
  child('child'),
  household('household');

  const ScopeType(this.wire);
  @override
  final String wire;
}

/// One child, or the household (expenses, notes); [babyId] only identifies the household then.
@immutable
class AssistantScope {
  const AssistantScope(this.type, this.babyId);
  const AssistantScope.child(this.babyId) : type = ScopeType.child;
  const AssistantScope.household(this.babyId) : type = ScopeType.household;

  final ScopeType type;
  final String babyId;

  bool get household => type == ScopeType.household;

  /// `child:b_…` / `household:b_…`: the chat's provider key and local storage key.
  String get key => '${type.wire}:$babyId';

  static AssistantScope? fromKey(String? key) {
    if (key == null) return null;
    final i = key.indexOf(':');
    if (i <= 0) return null;
    final type = wireOf(ScopeType.values, key.substring(0, i));
    final baby = key.substring(i + 1);
    if (type == null || baby.isEmpty || baby.length > 128) return null;
    return AssistantScope(type, baby);
  }

  Map<String, Object?> toJson() => {'type': type.wire, 'babyId': babyId};

  static AssistantScope? fromJson(Object? json) {
    final m = _map(json);
    final type = wireOf(ScopeType.values, m['type']);
    final baby = _str(m['babyId'], max: 128);
    return type == null || baby == null ? null : AssistantScope(type, baby);
  }

  @override
  bool operator ==(Object other) =>
      other is AssistantScope && other.type == type && other.babyId == babyId;

  @override
  int get hashCode => Object.hash(type, babyId);
}

enum TaskModality with WireEnum {
  text('text'),
  image('image');

  const TaskModality(this.wire);
  @override
  final String wire;
}

/// `quoteTaskRequestSchema.intentHint`: set by a module entry (CH01b), never by the model.
enum IntentHint with WireEnum {
  care('care'),
  expense('expense'),
  reminder('reminder'),
  question('question'),
  meal('meal');

  const IntentHint(this.wire);
  @override
  final String wire;
}

/// Generation states (brief p.9); `ready` = an answer or drafts exist, nothing written yet.
enum TaskState with WireEnum {
  received('received'),
  blocked('blocked'),
  uploading('uploading'),
  queued('queued'),
  processing('processing'),
  awaitingClarification('awaiting_clarification'),
  ready('ready'),
  failed('failed'),
  canceled('canceled');

  const TaskState(this.wire);
  @override
  final String wire;

  bool get terminal =>
      this == ready || this == failed || this == canceled || this == blocked;

  /// The worker still has it: "Trợ lý đang đọc…".
  bool get working =>
      this == received ||
      this == uploading ||
      this == queued ||
      this == processing;
}

/// Draft states map the "Thẻ nháp" component (611:7695). Badge text is never the source.
enum DraftState with WireEnum {
  draft('draft'),
  needsReview('needs_review'),
  saving('saving'),
  saved('saved'),
  failed('failed'),
  discarded('discarded');

  const DraftState(this.wire);
  @override
  final String wire;

  /// Saved and discarded never go back (a late listener snapshot cannot undo them).
  bool get settled => this == saved || this == discarded;
}

enum DraftKind with WireEnum {
  bottle('bottle'),
  breast('breast'),
  sleep('sleep'),
  expense('expense'),
  reminder('reminder'),
  observation('observation'),
  meal('meal');

  const DraftKind(this.wire);
  @override
  final String wire;
}

/// `DraftProblem`: the same checks as the forms.
enum DraftProblem with WireEnum {
  missingAmount('MISSING_AMOUNT'),
  invalidAmount('INVALID_AMOUNT'),
  missingTime('MISSING_TIME'),
  futureTime('FUTURE_TIME'),
  invalidTime('INVALID_TIME'),
  missingDate('MISSING_DATE'),
  currencyUnsupported('CURRENCY_UNSUPPORTED'),
  missingTitle('MISSING_TITLE');

  const DraftProblem(this.wire);
  @override
  final String wire;
}

/// A warning the person acknowledges to save anyway ("Vẫn lưu riêng").
enum DraftWarning with WireEnum {
  duplicateSuspected('duplicate_suspected'),
  overlap('overlap');

  const DraftWarning(this.wire);
  @override
  final String wire;
}

enum TaskEventType with WireEnum {
  accepted('accepted'),
  progress('progress'),
  clarificationRequired('clarification_required'),
  draftsReady('drafts_ready'),
  answerReady('answer_ready'),
  usageUpdated('usage_updated'),
  itemSaved('item_saved'),
  itemFailed('item_failed'),
  taskFailed('task_failed');

  const TaskEventType(this.wire);
  @override
  final String wire;
}

/// Where the reservation of a task stands (never the model cost).
enum TaskUsageState with WireEnum {
  none('none'),
  reserved('reserved'),
  committed('committed'),
  released('released');

  const TaskUsageState(this.wire);
  @override
  final String wire;
}

enum UsagePlan with WireEnum {
  free('free'),
  premium('premium');

  const UsagePlan(this.wire);
  @override
  final String wire;
}

enum ConfirmStatus with WireEnum {
  saved('saved'),
  failed('failed'),
  conflict('conflict');

  const ConfirmStatus(this.wire);
  @override
  final String wire;
}

/// `submitAssistantFeedback.outcome` ("Chưa thử" is valid, CH17).
enum FeedbackOutcome with WireEnum {
  helpful('helpful'),
  unsure('unsure'),
  notSuitable('not_suitable'),
  notTried('not_tried');

  const FeedbackOutcome(this.wire);
  @override
  final String wire;
}

// ---------- Small parsers ----------

String? _str(Object? v, {int max = 4000}) =>
    v is String && v.trim().isNotEmpty && v.length <= max ? v : null;

int? _int(Object? v) => v is num && v == v.roundToDouble() ? v.toInt() : null;

num? _num(Object? v) => v is num && v.isFinite ? v : null;

Map<String, Object?> _map(Object? v) =>
    v is Map ? v.map((k, x) => MapEntry('$k', x)) : const {};

List<Object?> _list(Object? v) => v is List ? v : const [];

List<String> _strings(Object? v, {int max = 200}) => [
  for (final x in _list(v)) ?_str(x, max: max),
];

DateTime? _instant(Object? v) => v is String ? DateTime.tryParse(v) : null;

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

String? _date(Object? v) => v is String && _isoDate.hasMatch(v) ? v : null;

String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

/// `{vi, en}` text chosen by the app's language.
@immutable
class LocalizedText {
  const LocalizedText({required this.vi, required this.en});
  final String vi;
  final String en;

  String of(String languageCode) =>
      languageCode == 'en' && en.isNotEmpty ? en : (vi.isNotEmpty ? vi : en);

  static LocalizedText? fromJson(Object? json) {
    final m = _map(json);
    final vi = m['vi'] is String ? m['vi']! as String : '';
    final en = m['en'] is String ? m['en']! as String : '';
    if (vi.trim().isEmpty && en.trim().isEmpty) return null;
    return LocalizedText(vi: vi, en: en);
  }
}

// ---------- Clarification ----------

@immutable
class ClarificationChoice {
  const ClarificationChoice({required this.id, required this.label});
  final String id;
  final LocalizedText label;
}

@immutable
class Clarification {
  const Clarification({
    required this.id,
    required this.field,
    required this.question,
    required this.choices,
    required this.allowText,
  });

  final String id;

  /// The field the answer fills (`sleep.period`, `bottle.ampm`…).
  final String field;
  final LocalizedText question;
  final List<ClarificationChoice> choices;

  /// A typed answer is allowed ("Tự nhập").
  final bool allowText;

  static Clarification? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id'], max: 60);
    final question = LocalizedText.fromJson(m['question']);
    if (id == null || question == null) return null;
    return Clarification(
      id: id,
      field: _str(m['field'], max: 60) ?? '',
      question: question,
      choices: [
        for (final c in _list(m['choices']).take(6))
          if ((
                _str(_map(c)['id'], max: 40),
                LocalizedText.fromJson(_map(c)['label']),
              )
              case (final String cid, final LocalizedText label))
            ClarificationChoice(id: cid, label: label),
      ],
      allowText: m['allowText'] == true,
    );
  }
}

// ---------- Read summary (CH08) ----------

@immutable
class CountAmount {
  const CountAmount(this.count, this.amount);
  final int count;

  /// ml for bottles, minutes for nursing and sleep.
  final int amount;

  static CountAmount _of(Object? json, String key) {
    final m = _map(json);
    return CountAmount(
      (_int(m['count']) ?? 0).clamp(0, 1 << 20),
      (_num(m[key])?.round() ?? 0).clamp(0, 1 << 30),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CountAmount && other.count == count && other.amount == amount;

  @override
  int get hashCode => Object.hash(count, amount);
}

enum SummaryCoverage { complete, partial, unknown }

/// Engine-computed figures (`careSummary`); the model never adds numbers.
@immutable
class CareSummary {
  const CareSummary({
    required this.date,
    required this.bottle,
    required this.breast,
    required this.sleep,
    required this.coverage,
    required this.until,
  });

  final String date;
  final CountAmount bottle;

  /// Nursing kept apart: minutes, never ml.
  final CountAmount breast;
  final CountAmount sleep;
  final SummaryCoverage coverage;
  final DateTime? until;

  bool get empty => bottle.count + breast.count + sleep.count == 0;

  static CareSummary? fromJson(Object? json) {
    final m = _map(json);
    final date = _date(m['date']) ?? _date('${m['date']}'.split('T').first);
    if (date == null) return null;
    return CareSummary(
      date: date,
      bottle: CountAmount._of(m['bottle'], 'ml'),
      breast: CountAmount._of(m['breast'], 'minutes'),
      sleep: CountAmount._of(m['sleep'], 'minutes'),
      coverage:
          SummaryCoverage.values.asNameMap()[m['coverage']] ??
          SummaryCoverage.unknown,
      until: _instant(m['until']),
    );
  }
}

// ---------- Parts (brief p.11) ----------

/// A typed result part; the app renders only these.
@immutable
sealed class AssistantPart {
  const AssistantPart();

  static AssistantPart fromJson(Object? json) {
    final m = _map(json);
    final type = m['type'];
    final version = _int(m['schemaVersion']) ?? 1;
    if (version != 1) return UnsupportedPart('$type');
    final part = switch (type) {
      'text' => switch (_str(m['text'], max: 8000)) {
        final t? => TextPart(t),
        null => null,
      },
      'clarification' => switch (Clarification.fromJson(m['clarification'])) {
        final c? => ClarificationPart(c),
        null => null,
      },
      'draft_reference' => switch (_str(m['draftId'], max: 120)) {
        final id? => DraftRefPart(id, _int(m['revision']) ?? 1),
        null => null,
      },
      'source_summary' => switch (CareSummary.fromJson(m['summary'])) {
        final s? => SourceSummaryPart(s, _strings(m['sourceIds'])),
        null => null,
      },
      'approved_content' => switch (_str(m['contentId'], max: 80)) {
        final id? => ApprovedContentPart(
          contentId: id,
          contentVersion: _int(m['contentVersion']) ?? 1,
          reason: _str(m['reason'], max: 600) ?? '',
          reviewed: m['reviewed'] == true,
        ),
        null => null,
      },
      'recipe_list' => RecipeListPart(
        _strings(m['recipeIds'], max: 80),
        _str(m['caveat'], max: 600),
      ),
      'usage_notice' => switch (AssistantReason.fromWire(m['reason'])) {
        _ when m['reason'] == 'NEAR_LIMIT' => UsageNoticePart(
          null,
          _int(m['remaining']) ?? 0,
        ),
        final r? => UsageNoticePart(r, _int(m['remaining']) ?? 0),
        null => null,
      },
      'action_result' => ActionResultPart([
        for (final x in _list(m['items'])) ?ConfirmItemResult.fromJson(x),
      ]),
      'health_support' => HealthSupportPart(_strings(m['signs'], max: 40)),
      _ => null,
    };
    return part ?? UnsupportedPart('$type');
  }
}

class TextPart extends AssistantPart {
  const TextPart(this.text);
  final String text;
}

class ClarificationPart extends AssistantPart {
  const ClarificationPart(this.clarification);
  final Clarification clarification;
}

class DraftRefPart extends AssistantPart {
  const DraftRefPart(this.draftId, this.revision);
  final String draftId;
  final int revision;
}

class SourceSummaryPart extends AssistantPart {
  const SourceSummaryPart(this.summary, this.sourceIds);
  final CareSummary summary;
  final List<String> sourceIds;
}

class ApprovedContentPart extends AssistantPart {
  const ApprovedContentPart({
    required this.contentId,
    required this.contentVersion,
    required this.reason,
    required this.reviewed,
  });
  final String contentId;
  final int contentVersion;
  final String reason;
  final bool reviewed;
}

class RecipeListPart extends AssistantPart {
  const RecipeListPart(this.recipeIds, this.caveat);
  final List<String> recipeIds;
  final String? caveat;
}

/// [reason] null = `NEAR_LIMIT`.
class UsageNoticePart extends AssistantPart {
  const UsageNoticePart(this.reason, this.remaining);
  final AssistantReason? reason;
  final int remaining;
}

class ActionResultPart extends AssistantPart {
  const ActionResultPart(this.items);
  final List<ConfirmItemResult> items;
}

class HealthSupportPart extends AssistantPart {
  const HealthSupportPart(this.signs);

  /// Health sign wires (`breathing`, `fever_young`…), as HL01 reads them.
  final List<String> signs;
}

/// A part this app version does not know (or a newer schema): a safe placeholder, no action.
class UnsupportedPart extends AssistantPart {
  const UnsupportedPart(this.type);
  final String type;
}

// ---------- Draft payloads ----------

@immutable
sealed class DraftPayload {
  const DraftPayload();

  DraftKind? get kind;

  Map<String, Object?> toJson();

  static DraftPayload fromJson(Object? json) {
    final m = _map(json);
    return switch (wireOf(DraftKind.values, m['kind'])) {
      DraftKind.bottle => BottlePayload(
        amountMl: _num(m['amountMl']),
        occurredAt: _instant(m['occurredAt']),
        milk: _str(m['milk'], max: 20),
      ),
      DraftKind.breast => BreastPayload(
        occurredAt: _instant(m['occurredAt']),
        durationMin: _int(m['durationMin']),
        side: _str(m['side'], max: 10),
      ),
      DraftKind.sleep => SleepPayload(
        startedAt: _instant(m['startedAt']),
        endedAt: _instant(m['endedAt']),
      ),
      DraftKind.expense => ExpensePayload(
        merchant: _str(m['merchant'], max: 120),
        totalMinor: _int(m['totalMinor']),
        currency: _str(m['currency'], max: 3),
        date: _date(m['date']),
        subtotalMinor: _int(m['subtotalMinor']),
        taxMinor: _int(m['taxMinor']),
        categoryId: _str(m['categoryId'], max: 80),
        babyId: _str(m['babyId'], max: 128),
        keepReceipt: m['keepReceipt'] == true,
      ),
      DraftKind.reminder => ReminderPayload(
        title: m['title'] is String ? m['title']! as String : '',
        date: _date(m['date']),
        time: m['time'] is String && _hhmm.hasMatch(m['time']! as String)
            ? m['time']! as String
            : null,
        assigneeUid: _str(m['assigneeUid'], max: 128),
      ),
      DraftKind.observation => ObservationPayload(
        observation: _str(m['observation'], max: 20) ?? 'usual',
        date: _date(m['date']) ?? '',
        when: _str(m['when'], max: 10),
        note: _str(m['note'], max: 500),
      ),
      DraftKind.meal => MealPayload(
        recipeId: _str(m['recipeId'], max: 80),
        title: m['title'] is String ? m['title']! as String : '',
        occurredAt: _instant(m['occurredAt']),
      ),
      null => UnknownPayload('${m['kind']}', m),
    };
  }
}

class BottlePayload extends DraftPayload {
  const BottlePayload({this.amountMl, this.occurredAt, this.milk});

  /// Positive, within the module's limits.
  final num? amountMl;
  final DateTime? occurredAt;
  final String? milk;

  @override
  DraftKind get kind => DraftKind.bottle;

  BottlePayload copyWith({num? amountMl, DateTime? occurredAt}) =>
      BottlePayload(
        amountMl: amountMl ?? this.amountMl,
        occurredAt: occurredAt ?? this.occurredAt,
        milk: milk,
      );

  @override
  Map<String, Object?> toJson() => {
    'kind': 'bottle',
    'amountMl': amountMl,
    'occurredAt': _iso(occurredAt),
    'milk': milk,
  };
}

class BreastPayload extends DraftPayload {
  const BreastPayload({this.occurredAt, this.durationMin, this.side});

  final DateTime? occurredAt;

  /// Nursing is minutes, never converted to ml.
  final int? durationMin;

  /// `left` / `right` / `both`.
  final String? side;

  @override
  DraftKind get kind => DraftKind.breast;

  BreastPayload copyWith({
    DateTime? occurredAt,
    int? durationMin,
    String? side,
  }) => BreastPayload(
    occurredAt: occurredAt ?? this.occurredAt,
    durationMin: durationMin ?? this.durationMin,
    side: side ?? this.side,
  );

  @override
  Map<String, Object?> toJson() => {
    'kind': 'breast',
    'occurredAt': _iso(occurredAt),
    'durationMin': durationMin,
    'side': side,
  };
}

class SleepPayload extends DraftPayload {
  const SleepPayload({this.startedAt, this.endedAt});
  final DateTime? startedAt;
  final DateTime? endedAt;

  @override
  DraftKind get kind => DraftKind.sleep;

  SleepPayload copyWith({DateTime? startedAt, DateTime? endedAt}) =>
      SleepPayload(
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  @override
  Map<String, Object?> toJson() => {
    'kind': 'sleep',
    'startedAt': _iso(startedAt),
    'endedAt': _iso(endedAt),
  };
}

class ExpensePayload extends DraftPayload {
  const ExpensePayload({
    this.merchant,
    this.totalMinor,
    this.currency,
    this.date,
    this.subtotalMinor,
    this.taxMinor,
    this.categoryId,
    this.babyId,
    this.keepReceipt = false,
  });

  final String? merchant;

  /// Integer minor units (VND đồng); never a float.
  final int? totalMinor;
  final String? currency;
  final String? date;
  final int? subtotalMinor;
  final int? taxMinor;
  final String? categoryId;
  final String? babyId;
  final bool keepReceipt;

  @override
  DraftKind get kind => DraftKind.expense;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'expense',
    'merchant': merchant,
    'totalMinor': totalMinor,
    'currency': currency,
    'date': date,
    'subtotalMinor': subtotalMinor,
    'taxMinor': taxMinor,
    'categoryId': categoryId,
    'babyId': babyId,
    'keepReceipt': keepReceipt,
  };
}

class ReminderPayload extends DraftPayload {
  const ReminderPayload({
    required this.title,
    this.date,
    this.time,
    this.assigneeUid,
  });

  final String title;
  final String? date;

  /// "HH:mm" local; never a silent 09:00.
  final String? time;
  final String? assigneeUid;

  @override
  DraftKind get kind => DraftKind.reminder;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'reminder',
    'title': title,
    'date': date,
    'time': time,
    'assigneeUid': assigneeUid,
  };
}

class ObservationPayload extends DraftPayload {
  const ObservationPayload({
    required this.observation,
    required this.date,
    this.when,
    this.note,
  });

  final String observation;
  final String date;
  final String? when;
  final String? note;

  @override
  DraftKind get kind => DraftKind.observation;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'observation',
    'observation': observation,
    'date': date,
    'when': when,
    'note': note,
  };
}

class MealPayload extends DraftPayload {
  const MealPayload({required this.title, this.recipeId, this.occurredAt});
  final String? recipeId;
  final String title;
  final DateTime? occurredAt;

  @override
  DraftKind get kind => DraftKind.meal;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'meal',
    'recipeId': recipeId,
    'title': title,
    'occurredAt': _iso(occurredAt),
  };
}

/// A draft kind this app version does not know: shown, never edited or saved here.
class UnknownPayload extends DraftPayload {
  const UnknownPayload(this.wire, this.raw);
  final String wire;
  final Map<String, Object?> raw;

  @override
  DraftKind? get kind => null;

  @override
  Map<String, Object?> toJson() => raw;
}

// ---------- Drafts ----------

/// `AssistantDraftView` (`assistantTasks/{t}/drafts/{d}`): server-written; edited through
/// `patchDraft` (revision +1), saved through `confirmDrafts`.
@immutable
class AssistantDraft {
  const AssistantDraft({
    required this.id,
    required this.taskId,
    required this.itemIndex,
    required this.scope,
    required this.payload,
    required this.revision,
    required this.state,
    this.missingFields = const [],
    this.uncertainFields = const [],
    this.expiresAt,
    this.sourceRefs = const [],
    this.recordId,
    this.recordLink,
    this.errorCode,
    this.warnings = const [],
    this.problems = const [],
  });

  final String id;
  final String taskId;
  final int itemIndex;
  final AssistantScope? scope;
  final DraftPayload payload;
  final List<String> missingFields;
  final List<String> uncertainFields;
  final int revision;
  final DraftState state;
  final DateTime? expiresAt;
  final List<String> sourceRefs;

  /// Set once saved, built by the server's module adapter.
  final String? recordId;
  final String? recordLink;

  /// A wire reason (`DOMAIN_CONFLICT`…) or a server code this app does not know.
  final String? errorCode;
  final List<DraftWarning> warnings;

  /// Server-side form checks against the confirm time.
  final List<DraftProblem> problems;

  DraftKind? get kind => payload.kind;
  AssistantReason? get error => AssistantReason.fromWire(errorCode);

  bool expiredAt(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);

  AssistantDraft copyWith({
    DraftPayload? payload,
    int? revision,
    DraftState? state,
    List<String>? uncertainFields,
    List<String>? missingFields,
    String? recordId,
    String? recordLink,
    String? errorCode,
    bool clearError = false,
    List<DraftProblem>? problems,
  }) => AssistantDraft(
    id: id,
    taskId: taskId,
    itemIndex: itemIndex,
    scope: scope,
    payload: payload ?? this.payload,
    missingFields: missingFields ?? this.missingFields,
    uncertainFields: uncertainFields ?? this.uncertainFields,
    revision: revision ?? this.revision,
    state: state ?? this.state,
    expiresAt: expiresAt,
    sourceRefs: sourceRefs,
    recordId: recordId ?? this.recordId,
    recordLink: recordLink ?? this.recordLink,
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    warnings: warnings,
    problems: problems ?? this.problems,
  );

  static AssistantDraft? fromJson(Object? json, {String? id}) {
    final m = _map(json);
    final draftId = _str(m['id'], max: 120) ?? id;
    final state = wireOf(DraftState.values, m['state']);
    if (draftId == null || state == null || m['payload'] is! Map) return null;
    return AssistantDraft(
      id: draftId,
      taskId: _str(m['taskId'], max: 80) ?? '',
      itemIndex: _int(m['itemIndex']) ?? 0,
      scope: AssistantScope.fromJson(m['scope']),
      payload: DraftPayload.fromJson(m['payload']),
      missingFields: _strings(m['missingFields'], max: 60),
      uncertainFields: _strings(m['uncertainFields'], max: 60),
      revision: _int(m['revision']) ?? 1,
      state: state,
      expiresAt: _instant(m['expiresAt']),
      sourceRefs: _strings(m['sourceRefs']),
      recordId: _str(m['recordId'], max: 120),
      recordLink: _str(m['recordLink'], max: 300),
      errorCode: _str(m['errorCode'], max: 60),
      warnings: [
        for (final w in _list(m['warnings'])) ?wireOf(DraftWarning.values, w),
      ],
      problems: [
        for (final p in _list(m['problems'])) ?wireOf(DraftProblem.values, p),
      ],
    );
  }
}

// ---------- Usage and quotes ----------

/// One line of CH19 "Gần đây" when the server sends it (household tasks: role, date, credits;
/// never content).
@immutable
class UsageEntry {
  const UsageEntry({
    required this.modality,
    required this.credits,
    this.at,
    this.who,
  });
  final TaskModality modality;
  final int credits;
  final DateTime? at;

  /// The member's relation or display label as the server gives it ("Mẹ").
  final String? who;

  static UsageEntry? fromJson(Object? json) {
    final m = _map(json);
    final credits = _int(m['credits']);
    if (credits == null) return null;
    return UsageEntry(
      modality: wireOf(TaskModality.values, m['modality']) ?? TaskModality.text,
      credits: credits.clamp(0, 1000),
      at: _instant(m['at'] ?? m['createdAt']),
      who: _str(m['who'], max: 60),
    );
  }
}

/// `getAssistantUsage` / quote snapshot ("Mức dùng"): the household pool, reset date, plan.
@immutable
class AssistantUsage {
  const AssistantUsage({
    required this.plan,
    required this.limit,
    required this.used,
    required this.reserved,
    required this.remaining,
    required this.resetsAt,
    this.policyVersion = '',
    this.textCredits = 1,
    this.imageCredits = 3,
    this.recent = const [],
  });

  final UsagePlan plan;
  final int limit;
  final int used;
  final int reserved;

  /// As the server computed it; the app never adds its own static number.
  final int remaining;
  final DateTime? resetsAt;
  final String policyVersion;
  final int textCredits;
  final int imageCredits;
  final List<UsageEntry> recent;

  static AssistantUsage? fromJson(Object? json) {
    var m = _map(json);
    if (m['usage'] is Map) m = _map(m['usage']);
    final limit = _int(m['limit']);
    final plan = wireOf(UsagePlan.values, m['plan']);
    if (limit == null || plan == null) return null;
    final used = (_int(m['used']) ?? 0).clamp(0, 1 << 20);
    final reserved = (_int(m['reserved']) ?? 0).clamp(0, 1 << 20);
    return AssistantUsage(
      plan: plan,
      limit: limit.clamp(0, 1 << 20),
      used: used,
      reserved: reserved,
      remaining: (_int(m['remaining']) ?? (limit - used - reserved)).clamp(
        0,
        limit.clamp(0, 1 << 20),
      ),
      resetsAt: _instant(m['resetsAt']),
      policyVersion: _str(m['policyVersion'], max: 40) ?? '',
      textCredits: (_int(m['textCredits']) ?? 1).clamp(0, 20),
      imageCredits: (_int(m['imageCredits']) ?? 3).clamp(0, 20),
      recent: [
        for (final x in _list(m['recent']).take(20)) ?UsageEntry.fromJson(x),
      ],
    );
  }
}

@immutable
class AssistantQuote {
  const AssistantQuote({
    required this.quoteId,
    required this.modality,
    required this.credits,
    required this.allowed,
    this.reason,
    this.reasonWire,
    this.expiresAt,
    this.usage,
  });

  final String quoteId;
  final TaskModality modality;

  /// Exact credits charged on a useful result; never more.
  final int credits;
  final bool allowed;
  final AssistantReason? reason;
  final String? reasonWire;
  final DateTime? expiresAt;
  final AssistantUsage? usage;

  static AssistantQuote? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['quoteId'], max: 80);
    if (id == null) return null;
    return AssistantQuote(
      quoteId: id,
      modality: wireOf(TaskModality.values, m['modality']) ?? TaskModality.text,
      credits: (_int(m['credits']) ?? 0).clamp(0, 20),
      allowed: m['allowed'] == true,
      reason: AssistantReason.fromWire(m['reason']),
      reasonWire: _str(m['reason'], max: 60),
      expiresAt: _instant(m['expiresAt']),
      usage: AssistantUsage.fromJson(m['usage']),
    );
  }
}

// ---------- Tasks, events, messages ----------

@immutable
class AssistantTask {
  const AssistantTask({
    required this.id,
    required this.state,
    required this.version,
    this.conversationId,
    this.scope,
    this.modality = TaskModality.text,
    this.credits = 0,
    this.plan,
    this.usage = TaskUsageState.none,
    this.errorCode,
    this.round = 0,
    this.clarification,
    this.clarificationExpiresAt,
    this.anchorInstant,
    this.timezone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? conversationId;
  final AssistantScope? scope;
  final TaskState state;
  final int version;
  final TaskModality modality;

  /// Credits quoted for this task (0 for health support).
  final int credits;
  final UsagePlan? plan;
  final TaskUsageState usage;
  final String? errorCode;
  final int round;

  /// The open question while `awaiting_clarification`.
  final Clarification? clarification;
  final DateTime? clarificationExpiresAt;
  final DateTime? anchorInstant;

  /// The baby's zone at start (care days).
  final String? timezone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AssistantReason? get error => AssistantReason.fromWire(errorCode);

  /// Reads the API view (`AssistantTaskView`) or the stored document (`clarifications[]`).
  static AssistantTask? fromJson(Object? json, {String? id}) {
    final m = _map(json);
    final taskId = _str(m['id'], max: 80) ?? id;
    final state = wireOf(TaskState.values, m['state']);
    if (taskId == null || state == null) return null;
    var clarification = Clarification.fromJson(m['clarification']);
    if (clarification == null && state == TaskState.awaitingClarification) {
      final list = _list(m['clarifications']);
      if (list.isNotEmpty) {
        final last = _map(list.last);
        clarification = Clarification.fromJson(
          last['clarification'] is Map ? last['clarification'] : last,
        );
      }
    }
    return AssistantTask(
      id: taskId,
      conversationId: _str(m['conversationId'], max: 80),
      scope: AssistantScope.fromJson(m['scope']),
      state: state,
      version: _int(m['version']) ?? 1,
      modality: wireOf(TaskModality.values, m['modality']) ?? TaskModality.text,
      credits: (_int(m['credits']) ?? 0).clamp(0, 20),
      plan: wireOf(UsagePlan.values, m['plan']),
      usage: wireOf(TaskUsageState.values, m['usage']) ?? TaskUsageState.none,
      errorCode: _str(m['errorCode'], max: 60),
      round: _int(m['round']) ?? 0,
      clarification: clarification,
      clarificationExpiresAt: _instant(m['clarificationExpiresAt']),
      anchorInstant: _instant(m['anchorInstant']),
      timezone: _str(m['timezone'], max: 64),
      createdAt: _instant(m['createdAt']),
      updatedAt: _instant(m['updatedAt']),
    );
  }
}

@immutable
class AssistantEvent {
  const AssistantEvent({
    required this.eventId,
    required this.sequence,
    required this.typeWire,
    this.taskId = '',
    this.emittedAt,
    this.payload = const {},
  });

  final String taskId;
  final String eventId;
  final int sequence;

  /// Kept as the wire: an event type this app does not know is still ordered and deduplicated.
  final String typeWire;
  final DateTime? emittedAt;
  final Map<String, Object?> payload;

  TaskEventType? get type => wireOf(TaskEventType.values, typeWire);

  static AssistantEvent? fromJson(Object? json, {String? id}) {
    final m = _map(json);
    final eventId = _str(m['eventId'], max: 120) ?? id;
    final sequence = _int(m['sequence']);
    final type = _str(m['type'], max: 60);
    if (eventId == null || sequence == null || type == null) return null;
    return AssistantEvent(
      taskId: _str(m['taskId'], max: 80) ?? '',
      eventId: eventId,
      sequence: sequence,
      typeWire: type,
      emittedAt: _instant(m['emittedAt']),
      payload: _map(m['payload']),
    );
  }
}

enum MessageRole { user, assistant }

@immutable
class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.parts,
    required this.sequence,
    this.conversationId = '',
    this.taskId,
    this.createdAt,
    this.attachmentIds = const [],
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final List<AssistantPart> parts;
  final String? taskId;
  final int sequence;
  final DateTime? createdAt;
  final List<String> attachmentIds;

  /// The plain text of a user message (its text parts).
  String get text => [
    for (final p in parts)
      if (p is TextPart) p.text,
  ].join('\n');

  static AssistantMessage? fromJson(Object? json, {String? id}) {
    final m = _map(json);
    final messageId = _str(m['id'], max: 120) ?? id;
    final role = MessageRole.values.asNameMap()[m['role']];
    if (messageId == null || role == null) return null;
    return AssistantMessage(
      id: messageId,
      conversationId: _str(m['conversationId'], max: 80) ?? '',
      role: role,
      parts: [for (final p in _list(m['parts'])) AssistantPart.fromJson(p)],
      taskId: _str(m['taskId'], max: 80),
      sequence: _int(m['sequence']) ?? 0,
      createdAt: _instant(m['createdAt']),
      attachmentIds: _strings(m['attachmentIds'], max: 80),
    );
  }
}

/// `getAssistantTask`: the authoritative snapshot (M11).
@immutable
class TaskSnapshot {
  const TaskSnapshot({
    required this.task,
    this.drafts = const [],
    this.events = const [],
    this.messages = const [],
  });

  final AssistantTask task;
  final List<AssistantDraft> drafts;

  /// Ordered by `sequence`; the snapshot (not the events) is the authority.
  final List<AssistantEvent> events;
  final List<AssistantMessage> messages;

  TaskSnapshot copyWith({
    AssistantTask? task,
    List<AssistantDraft>? drafts,
    List<AssistantMessage>? messages,
  }) => TaskSnapshot(
    task: task ?? this.task,
    drafts: drafts ?? this.drafts,
    events: events,
    messages: messages ?? this.messages,
  );

  /// Reads `{task, drafts, events, messages}`, or a bare task view.
  static TaskSnapshot? fromJson(Object? json) {
    final m = _map(json);
    final task = AssistantTask.fromJson(m['task'] is Map ? m['task'] : m);
    if (task == null) return null;
    final events = [
      for (final e in _list(m['events'])) ?AssistantEvent.fromJson(e),
    ]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final messages = [
      for (final x in _list(m['messages'])) ?AssistantMessage.fromJson(x),
    ]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final drafts = [
      for (final d in _list(m['drafts'])) ?AssistantDraft.fromJson(d),
    ]..sort((a, b) => a.itemIndex.compareTo(b.itemIndex));
    return TaskSnapshot(
      task: task,
      drafts: drafts,
      events: events,
      messages: messages,
    );
  }
}

// ---------- Confirm ----------

@immutable
class ConfirmItemResult {
  const ConfirmItemResult({
    required this.draftId,
    required this.status,
    this.revision,
    this.recordId,
    this.recordLink,
    this.errorCode,
    this.problems = const [],
  });

  final String draftId;
  final ConfirmStatus status;
  final int? revision;
  final String? recordId;
  final String? recordLink;
  final String? errorCode;
  final List<DraftProblem> problems;

  static ConfirmItemResult? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['draftId'], max: 120);
    final status = wireOf(ConfirmStatus.values, m['status']);
    if (id == null || status == null) return null;
    return ConfirmItemResult(
      draftId: id,
      status: status,
      revision: _int(m['revision']),
      recordId: _str(m['recordId'], max: 120),
      recordLink: _str(m['recordLink'], max: 300),
      errorCode: _str(m['errorCode'], max: 60),
      problems: [
        for (final p in _list(m['problems'])) ?wireOf(DraftProblem.values, p),
      ],
    );
  }
}

@immutable
class ConfirmResult {
  const ConfirmResult({required this.items, required this.partial});
  final List<ConfirmItemResult> items;

  /// Some selected items were not saved; saved ones stay saved (CH07).
  final bool partial;

  static ConfirmResult fromJson(Object? json) {
    final m = _map(json);
    final items = [
      for (final x in _list(m['items'])) ?ConfirmItemResult.fromJson(x),
    ];
    return ConfirmResult(
      items: items,
      partial:
          m['partial'] == true ||
          items.any((i) => i.status != ConfirmStatus.saved),
    );
  }
}

/// One item of a `confirmDrafts` request.
@immutable
class ConfirmSelection {
  const ConfirmSelection(
    this.draftId,
    this.revision, [
    this.acknowledge = const [],
  ]);
  final String draftId;
  final int revision;
  final List<DraftWarning> acknowledge;

  Map<String, Object?> toJson() => {
    'draftId': draftId,
    'revision': revision,
    'acknowledge': [for (final w in acknowledge) w.wire],
  };
}

// ---------- History ----------

@immutable
class AssistantConversation {
  const AssistantConversation({
    required this.id,
    required this.scope,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.lastTaskId,
  });

  final String id;
  final AssistantScope? scope;
  final String? title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lastTaskId;

  static AssistantConversation? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id'], max: 80);
    if (id == null || m['archivedAt'] is String) return null;
    return AssistantConversation(
      id: id,
      scope: AssistantScope.fromJson(m['scope']),
      title: _str(m['title'], max: 200),
      createdAt: _instant(m['createdAt']),
      updatedAt: _instant(m['updatedAt']),
      lastTaskId: _str(m['lastTaskId'], max: 80),
    );
  }
}

@immutable
class HistoryPage<T> {
  const HistoryPage(this.items, this.nextCursor);
  final List<T> items;
  final String? nextCursor;
}

// ---------- Consent ----------

/// `users/{uid}/settings/ai.assistant` (P-160, per person).
@immutable
class AssistantConsent {
  const AssistantConsent({this.version, this.grantedAt, this.known = true});

  /// Still loading: nothing is decided yet.
  static const unknown = AssistantConsent(known: false);

  final String? version;
  final DateTime? grantedAt;
  final bool known;

  bool get granted => version == assistantConsentVersion;

  static AssistantConsent fromDoc(Object? json) {
    final m = _map(_map(json)['assistant']);
    return AssistantConsent(
      version: _str(m['version'], max: 40),
      grantedAt: _instant(m['grantedAt']),
    );
  }
}

// ---------- Response envelope ----------

enum ResponseStatus { ok, blocked, partial }

/// `AssistantResponse<T>` (brief p.10): `blocked` / `partial` are answers, not errors.
@immutable
class AssistantEnvelope {
  const AssistantEnvelope({
    required this.status,
    required this.data,
    this.requestId,
    this.taskId,
    this.serverTime,
    this.dataVersion = 0,
    this.reason,
    this.reasonWire,
    this.retryable = false,
  });

  final ResponseStatus status;
  final Object? data;
  final String? requestId;
  final String? taskId;
  final DateTime? serverTime;
  final int dataVersion;
  final AssistantReason? reason;
  final String? reasonWire;
  final bool retryable;

  /// Reads the envelope; a bare answer (older server) is taken as `ok` data.
  static AssistantEnvelope fromJson(Object? json) {
    final m = _map(json);
    if (!m.containsKey('data') || !m.containsKey('status')) {
      return AssistantEnvelope(status: ResponseStatus.ok, data: m);
    }
    return AssistantEnvelope(
      status:
          ResponseStatus.values.asNameMap()[m['status']] ?? ResponseStatus.ok,
      data: m['data'],
      requestId: _str(m['requestId'], max: 80),
      taskId: _str(m['taskId'], max: 80),
      serverTime: _instant(m['serverTime']),
      dataVersion: _int(m['dataVersion']) ?? 0,
      reason: AssistantReason.fromWire(m['reasonCode']),
      reasonWire: _str(m['reasonCode'], max: 60),
      retryable: m['retryable'] == true,
    );
  }
}
