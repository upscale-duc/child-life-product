import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../spending/spending_currency.dart'
    show isSpCurrency, spCurrencies, spCurrency;
import 'assistant_models.dart';

/// Pure Dart ports of `packages/contracts/src/assistant.ts` (`draftProblems`, `confirmBlocker`,
/// `careSummary`, `creditsFor`, `taskInputKey`) checked against the same simulation pack
/// (`packages/contracts/test/vectors/assistant-v3/`), plus the app's own pure helpers: the credit
/// display math of "Mức dùng", the event cursor that drops duplicate / old events on reconnect,
/// and the merges that keep a late snapshot from undoing a newer one.

/// `bottleLimits`: a technical limit for one bottle feed (not a clinical norm).
const bottleMaxMl = 500;

/// Longest nursing session the forms accept.
const breastMaxMinutes = 180;

/// LUMI-01: the care forms' own limits (contracts `careLimits`, app `CareLimits`).
const pumpMaxMl = 1000;
const careMaxMinutes = 240;
const growthWeightKg = (min: 0.3, max: 40.0);
const growthLengthCm = (min: 20.0, max: 150.0);

/// The pump form's amount: whole ml, 1…[pumpMaxMl].
bool pumpMlOk(num ml) => ml == ml.roundToDouble() && ml >= 1 && ml <= pumpMaxMl;
bool growthWeightOk(num kg) =>
    kg >= growthWeightKg.min && kg <= growthWeightKg.max;
bool growthLengthOk(num cm) =>
    cm >= growthLengthCm.min && cm <= growthLengthCm.max;

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The currencies an expense can be kept in: Chi tiêu's own list (D-075 #4, contracts
/// `expenseCurrencies`), never a copy.
final supportedCurrencies = {for (final c in spCurrencies) c.code};

/// Same checks as the forms, before any save (brief p.12): positive amounts within limits, a
/// time for completed logs not after [anchor], sleep end after start, an explicit date and a
/// supported currency for expenses, a title and a date for reminders.
List<DraftProblem> draftProblems(DraftPayload p, DateTime anchor) {
  final out = <DraftProblem>[];
  bool after(DateTime? v) => v != null && v.isAfter(anchor);
  switch (p) {
    case BottlePayload():
      final ml = p.amountMl;
      if (ml == null) {
        out.add(DraftProblem.missingAmount);
      } else if (ml <= 0 || ml > bottleMaxMl) {
        out.add(DraftProblem.invalidAmount);
      }
      if (p.occurredAt == null) {
        out.add(DraftProblem.missingTime);
      } else if (after(p.occurredAt)) {
        out.add(DraftProblem.futureTime);
      }
    case BreastPayload():
      if (p.occurredAt == null) {
        out.add(DraftProblem.missingTime);
      } else if (after(p.occurredAt)) {
        out.add(DraftProblem.futureTime);
      }
      if (p.durationMin != null && p.durationMin! > breastMaxMinutes) {
        out.add(DraftProblem.invalidAmount);
      }
    case SleepPayload():
      if (p.startedAt == null || p.endedAt == null) {
        out.add(DraftProblem.missingTime);
      } else {
        if (!p.endedAt!.isAfter(p.startedAt!)) {
          out.add(DraftProblem.invalidTime);
        }
        if (after(p.endedAt)) out.add(DraftProblem.futureTime);
      }
    case ExpensePayload():
      if (p.totalMinor == null) {
        out.add(DraftProblem.missingAmount);
      } else if (p.totalMinor! <= 0) {
        out.add(DraftProblem.invalidAmount);
      }
      if (p.date == null) out.add(DraftProblem.missingDate);
      if (p.currency == null || !supportedCurrencies.contains(p.currency)) {
        out.add(DraftProblem.currencyUnsupported);
      }
    case ReminderPayload():
      if (p.title.trim().isEmpty) out.add(DraftProblem.missingTitle);
      if (p.date == null) out.add(DraftProblem.missingDate);
    case ObservationPayload():
      break;
    case MealPayload():
      if (after(p.occurredAt)) out.add(DraftProblem.futureTime);
    case TimerPayload():
      final at = p.at;
      if (at == null) {
        out.add(DraftProblem.missingTime);
        break;
      }
      if (after(at)) out.add(DraftProblem.futureTime);
      if (p.isStart) {
        if (anchor.difference(at) > timerMaxRun(p.timer)) {
          out.add(DraftProblem.invalidTime);
        }
      } else if (p.startedAt == null || !at.isAfter(p.startedAt!)) {
        out.add(DraftProblem.invalidTime);
      }
    // ---- LUMI-01: the care forms' own checks (contracts `draftProblems`) ----
    case PumpPayload():
      final ml = p.amountMl;
      if (ml == null) {
        out.add(DraftProblem.missingAmount);
      } else if (!pumpMlOk(ml)) {
        out.add(DraftProblem.invalidAmount);
      }
      if ((p.durationMin ?? 0) > careMaxMinutes &&
          !out.contains(DraftProblem.invalidAmount)) {
        out.add(DraftProblem.invalidAmount);
      }
      if (p.occurredAt == null) {
        out.add(DraftProblem.missingTime);
      } else if (after(p.occurredAt)) {
        out.add(DraftProblem.futureTime);
      }
    case DiaperPayload():
      if (p.occurredAt == null) {
        out.add(DraftProblem.missingTime);
      } else if (after(p.occurredAt)) {
        out.add(DraftProblem.futureTime);
      }
    case GrowthPayload():
      if (p.weightKg == null) out.add(DraftProblem.missingAmount);
      if ((p.weightKg != null && !growthWeightOk(p.weightKg!)) ||
          (p.lengthCm != null && !growthLengthOk(p.lengthCm!))) {
        out.add(DraftProblem.invalidAmount);
      }
      if (p.measuredOn == null) {
        out.add(DraftProblem.missingDate);
      } else if (p.measuredOn!.compareTo(
            // A date after the anchor's local date in any zone (UTC+14) is in the future.
            _ymd(anchor.toUtc().add(const Duration(hours: 14))),
          ) >
          0) {
        out.add(DraftProblem.futureTime);
      }
    case UnknownPayload():
      break;
  }
  return out;
}

/// Contracts `timerMaxRunMs`: how long a timer may already have run when started from chat.
Duration timerMaxRun(String timer) =>
    timer == 'sleep' ? const Duration(hours: 24) : const Duration(minutes: 240);

/// Contracts `requiredDraftFields` (Lumi 2026-10-16): empty → missing, blocking; everything
/// else is optional (an observation without `when`, a feed without a length or side).
const requiredDraftFields = <DraftKind, List<String>>{
  DraftKind.bottle: ['amountMl', 'occurredAt', 'milk'],
  DraftKind.breast: ['occurredAt'],
  DraftKind.sleep: ['startedAt', 'endedAt'],
  DraftKind.expense: ['totalMinor', 'date', 'currency'],
  DraftKind.reminder: ['title', 'date'],
  DraftKind.observation: ['observation', 'date'],
  DraftKind.meal: ['title'],
  DraftKind.timer: ['at'],
  // LUMI-01: what each care form cannot save without (a pump's side takes the form's default).
  DraftKind.pump: ['amountMl', 'occurredAt'],
  DraftKind.diaper: ['diaper', 'occurredAt'],
  DraftKind.growth: ['weightKg', 'measuredOn'],
};

/// Contracts `draftReviewFields` / `draftProblemFields`: the fields a form problem points at
/// — an out-of-range value names the value that is out of range (a pump's amount and / or its
/// length, a weight and / or a length), a reminder already past its time (LUMI-11) names the
/// time when one is set.
List<String> problemFields(DraftPayload p, DraftProblem pr) =>
    switch ((p, pr)) {
      (final PumpPayload x, DraftProblem.invalidAmount) => [
        if (x.amountMl != null && !pumpMlOk(x.amountMl!)) 'amountMl',
        if ((x.durationMin ?? 0) > careMaxMinutes) 'durationMin',
      ],
      (final GrowthPayload x, DraftProblem.invalidAmount) => [
        if (x.weightKg != null && !growthWeightOk(x.weightKg!)) 'weightKg',
        if (x.lengthCm != null && !growthLengthOk(x.lengthCm!)) 'lengthCm',
      ],
      (final ReminderPayload x, DraftProblem.pastTime) => [
        x.time != null ? 'time' : 'date',
      ],
      _ => [?problemField(p, pr)],
    };

/// Contracts `draftProblemFields`: the field a form problem points at, for [p]'s kind.
String? problemField(DraftPayload p, DraftProblem pr) => switch (p) {
  BottlePayload() => switch (pr) {
    DraftProblem.missingAmount || DraftProblem.invalidAmount => 'amountMl',
    DraftProblem.missingTime ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'occurredAt',
    _ => null,
  },
  BreastPayload() => switch (pr) {
    DraftProblem.invalidAmount => 'durationMin',
    DraftProblem.missingTime ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'occurredAt',
    _ => null,
  },
  SleepPayload() => switch (pr) {
    DraftProblem.missingTime => p.startedAt == null ? 'startedAt' : 'endedAt',
    DraftProblem.futureTime || DraftProblem.invalidTime => 'endedAt',
    _ => null,
  },
  ExpensePayload() => switch (pr) {
    DraftProblem.missingAmount || DraftProblem.invalidAmount => 'totalMinor',
    DraftProblem.missingDate ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime ||
    DraftProblem.pastTime => 'date',
    DraftProblem.currencyUnsupported => 'currency',
    _ => null,
  },
  ReminderPayload() => switch (pr) {
    DraftProblem.missingTime => 'time',
    DraftProblem.missingDate ||
    DraftProblem.invalidTime ||
    DraftProblem.pastTime => 'date',
    DraftProblem.missingTitle || DraftProblem.invalidTitle => 'title',
    DraftProblem.invalidAssignee => 'assigneeUid',
    _ => null,
  },
  ObservationPayload() => switch (pr) {
    DraftProblem.missingDate ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'date',
    _ => null,
  },
  MealPayload() => switch (pr) {
    DraftProblem.missingTitle || DraftProblem.invalidTitle => 'title',
    DraftProblem.missingTime ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'occurredAt',
    _ => null,
  },
  TimerPayload() => switch (pr) {
    DraftProblem.missingTime ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'at',
    _ => null,
  },
  PumpPayload() => switch (pr) {
    DraftProblem.missingAmount || DraftProblem.invalidAmount => 'amountMl',
    DraftProblem.missingTime ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'occurredAt',
    _ => null,
  },
  DiaperPayload() => switch (pr) {
    DraftProblem.missingTime ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'occurredAt',
    _ => null,
  },
  GrowthPayload() => switch (pr) {
    DraftProblem.missingAmount || DraftProblem.invalidAmount => 'weightKg',
    DraftProblem.missingDate ||
    DraftProblem.futureTime ||
    DraftProblem.invalidTime => 'measuredOn',
    _ => null,
  },
  UnknownPayload() => null,
};

/// One thing the person must fill or check on a draft, with the problem behind it (if any).
typedef ReviewGap = ({String field, bool missing, DraftProblem? problem});

/// Lumi 2026-10-16: what a "Cần kiểm tra" card asks for, in order — the server's missing
/// fields, then its unsure ones, then the form's own problems against [now] (a time that is
/// now in the future, a sleep ending before it starts). Never a field the kind does not have; a
/// "missing" field that does hold a value (older drafts) is shown as one to confirm.
List<ReviewGap> reviewGaps(AssistantDraft d, DateTime now) {
  final p = d.payload;
  final json = p.toJson();
  bool empty(String f) => switch (json[f]) {
    null => true,
    final String s => s.trim().isEmpty,
    _ => false,
  };
  final problems = {...draftProblems(p, now), ...d.problems};
  final out = <String, ReviewGap>{};
  void add(String f, {required bool missing, DraftProblem? problem}) {
    if (!json.containsKey(f) || f == 'kind') return;
    final cur = out[f];
    out[f] = (
      field: f,
      missing: (cur?.missing ?? false) || (missing && empty(f)),
      problem: cur?.problem ?? problem,
    );
  }

  for (final f in d.missingFields) {
    add(f, missing: true);
  }
  for (final f in d.uncertainFields) {
    add(f, missing: false);
  }
  for (final pr in problems) {
    final isMissing =
        pr == DraftProblem.missingAmount ||
        pr == DraftProblem.missingTime ||
        pr == DraftProblem.missingDate ||
        pr == DraftProblem.missingTitle;
    for (final f in problemFields(p, pr)) {
      add(f, missing: isMissing, problem: isMissing ? null : pr);
    }
  }
  return out.values.toList();
}

/// Confirm preconditions shared by server and app (D04, D05, review).
AssistantReason? confirmBlocker(
  AssistantDraft d,
  int seenRevision,
  DateTime now,
) {
  if (d.state == DraftState.saved) return AssistantReason.draftSaved;
  if (d.state == DraftState.discarded) return AssistantReason.invalidState;
  if (d.expiresAt != null && !now.isBefore(d.expiresAt!)) {
    return AssistantReason.draftExpired;
  }
  if (d.revision != seenRevision) return AssistantReason.draftStale;
  if (d.state == DraftState.needsReview ||
      d.uncertainFields.isNotEmpty ||
      d.missingFields.isNotEmpty) {
    return AssistantReason.reviewRequired;
  }
  return null;
}

/// One logged record as `careSummary` reads it.
typedef SummaryRecord = ({String id, String kind, num? ml, num? minutes});

/// Deterministic figures from logged records only (R01): bottle ml and nursing minutes apart.
({CareSummary summary, List<String> sourceIds}) careSummary(
  Iterable<SummaryRecord> records,
  String date,
  DateTime until, {
  SummaryCoverage coverage = SummaryCoverage.unknown,
}) {
  var bottle = const CountAmount(0, 0);
  var breast = const CountAmount(0, 0);
  var sleep = const CountAmount(0, 0);
  final ids = <String>[];
  for (final r in records) {
    switch (r.kind) {
      case 'bottle':
        bottle = CountAmount(
          bottle.count + 1,
          bottle.amount + (r.ml ?? 0).round(),
        );
      case 'breast' || 'nursing':
        breast = CountAmount(
          breast.count + 1,
          breast.amount + (r.minutes ?? 0).round(),
        );
      case 'sleep':
        sleep = CountAmount(
          sleep.count + 1,
          sleep.amount + (r.minutes ?? 0).round(),
        );
      default:
        continue;
    }
    ids.add(r.id);
  }
  return (
    summary: CareSummary(
      date: date,
      bottle: bottle,
      breast: breast,
      sleep: sleep,
      coverage: coverage,
      until: until,
    ),
    sourceIds: ids,
  );
}

/// CH08 per-feed times ("08:00 150 ml · 11:10 120 ml"): the bottles and nursing sessions the
/// summary counted, oldest first, per kind — only while they still add up to the summary's own
/// count and amount. A record edited or deleted since the answer would show times that
/// contradict the totals, so that kind then shows its totals only (never a guessed list).
({List<SummaryItem>? bottle, List<SummaryItem>? breast}) summaryFeeds(
  CareSummary summary,
  Iterable<SummaryItem> items,
) {
  final byId = {for (final i in items) i.id: i};
  List<SummaryItem>? pick(
    String kind,
    CountAmount want,
    int? Function(SummaryItem) amount,
  ) {
    if (want.count == 0) return null;
    final list = [
      for (final i in byId.values)
        if (i.kind == kind) i,
    ]..sort((a, b) => a.at.compareTo(b.at));
    final total = list.fold<int>(0, (t, i) => t + (amount(i) ?? 0));
    return list.length == want.count && total == want.amount ? list : null;
  }

  return (
    bottle: pick('bottle', summary.bottle, (i) => i.ml),
    breast: pick('breast', summary.breast, (i) => i.minutes),
  );
}

/// Contracts `aiSummaryCredits` (D-075 #1): an AI summary worded by the model (handover,
/// explanation, moment) takes 1 credit from the same household pool as the chat; a cached or
/// template answer takes none.
const aiSummaryCredits = 1;

/// CH03: where one conversation stands, read from its last task's snapshot only.
@immutable
class ThreadStatus {
  const ThreadStatus({
    this.saved = 0,
    this.pending = 0,
    this.needsAnswer = false,
    this.awaitingFeedback = false,
  });

  /// Drafts saved into the modules ("2 mục đã lưu").
  final int saved;

  /// Drafts still waiting to be saved and not expired ("1 nháp").
  final int pending;

  /// The assistant asked a question that is still open.
  final bool needsAnswer;

  /// A care try waiting for "Có ích / Chưa rõ…" (CH17, "Đang chờ phản hồi sau khi thử").
  final bool awaitingFeedback;

  bool get isEmpty =>
      saved == 0 && pending == 0 && !needsAnswer && !awaitingFeedback;

  @override
  bool operator ==(Object other) =>
      other is ThreadStatus &&
      other.saved == saved &&
      other.pending == pending &&
      other.needsAnswer == needsAnswer &&
      other.awaitingFeedback == awaitingFeedback;

  @override
  int get hashCode =>
      Object.hash(saved, pending, needsAnswer, awaitingFeedback);
}

/// The CH03 status of a conversation from its last task (never invented): a canceled task shows
/// nothing; drafts count as saved or as waiting until their 24 h expire; an open question only
/// while it can still be answered.
ThreadStatus threadStatus(TaskSnapshot s, DateTime now) {
  final t = s.task;
  if (t.state == TaskState.canceled) return const ThreadStatus();
  var saved = 0;
  var pending = 0;
  for (final d in s.drafts) {
    switch (d.state) {
      case DraftState.saved:
        saved++;
      case DraftState.discarded:
        break;
      case DraftState.draft ||
          DraftState.needsReview ||
          DraftState.saving ||
          DraftState.failed:
        if (d.expiresAt == null || d.expiresAt!.isAfter(now)) pending++;
    }
  }
  final open =
      t.state == TaskState.awaitingClarification &&
      (t.clarificationExpiresAt == null ||
          t.clarificationExpiresAt!.isAfter(now));
  final care = t.care;
  return ThreadStatus(
    saved: saved,
    pending: pending,
    needsAnswer: open,
    awaitingFeedback:
        care != null && care.followUp != null && care.feedback == null,
  );
}

/// Exact charge for a task from the server's policy (text 1, a photo task 3; health is 0 and
/// decided by the server, never guessed here).
int creditsFor(TaskModality modality, AssistantUsage? usage) =>
    modality == TaskModality.image
    ? (usage?.imageCredits ?? 3)
    : (usage?.textCredits ?? 1);

/// `taskInputKey`: the same request id with a different input is a different task, so a kept
/// input reuses its request id only while the text is unchanged.
String taskInputKey({
  required String? conversationId,
  required AssistantScope scope,
  required TaskModality modality,
  required String? text,
  List<String> attachmentIds = const [],
}) => jsonEncode([
  conversationId ?? '',
  scope.type.wire,
  scope.babyId,
  modality.wire,
  (text ?? '').trim(),
  [...attachmentIds]..sort(),
]);

// ---------- "Mức dùng" display math ----------

/// Chat/Mức dùng `Mức`.
enum UsageLevel { ok, near, out }

/// What the pill and CH19 show, all from the server's snapshot.
@immutable
class UsageView {
  const UsageView._(this.usage, this.remaining, this.level);

  factory UsageView.of(AssistantUsage u) {
    final remaining = math.min(math.max(u.remaining, 0), math.max(0, u.limit));
    final level = remaining <= 0 || remaining < u.textCredits
        ? UsageLevel.out
        : (remaining < u.imageCredits || remaining * 10 <= u.limit)
        ? UsageLevel.near
        : UsageLevel.ok;
    return UsageView._(u, remaining, level);
  }

  final AssistantUsage usage;
  final int remaining;
  final UsageLevel level;

  int get limit => math.max(0, usage.limit);
  bool get premium => usage.plan == UsagePlan.premium;

  /// The bar on CH19 (remaining over the limit, 0–1).
  double get fraction => limit == 0 ? 0 : remaining / limit;

  /// Enough for a task of [credits] (a quote is still the authority).
  bool affords(int credits) => remaining >= credits;
}

// ---------- Events and merges (brief p.11 "client bỏ event duplicate/old") ----------

/// Remembers which events of one task were applied; [accept] returns only new ones, in order.
class EventCursor {
  EventCursor([this._last = -1]);

  int _last;
  final _seen = <String>{};

  int get lastSequence => _last;

  List<AssistantEvent> accept(Iterable<AssistantEvent> events) {
    final sorted = [...events]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final out = <AssistantEvent>[];
    for (final e in sorted) {
      if (e.sequence <= _last || !_seen.add(e.eventId)) continue;
      _last = e.sequence;
      out.add(e);
    }
    return out;
  }
}

/// The newer task view wins; an older version (a late listener, a stale response) is ignored.
/// The stored task document (live listener) has no computed CH17 `followUp`: a still-open
/// question survives it until an answer (or a newer snapshot) settles it.
/// A plan or an answer the server confirmed never goes away (the server writes them without a
/// new task version, so a snapshot read just before can arrive after).
AssistantTask mergeTask(AssistantTask current, AssistantTask incoming) {
  if (incoming.version < current.version) return current;
  final kept = current.care;
  final next = incoming.care;
  if (kept == null) return incoming;
  if (next == null) return incoming.copyWith(care: kept);
  final feedback = next.feedback ?? kept.feedback;
  return incoming.copyWith(
    care: AssistantCareView(
      topic: next.topic,
      sleep: next.sleep ?? kept.sleep,
      guidance: next.guidance ?? kept.guidance,
      recipeIds: next.recipeIds.isEmpty ? kept.recipeIds : next.recipeIds,
      plan: next.plan ?? kept.plan,
      feedback: feedback,
      followUp: feedback != null ? null : (next.followUp ?? kept.followUp),
    ),
  );
}

/// How far a draft has come within one revision: a same-revision snapshot never moves it back
/// (a listener snapshot written before the confirm landed cannot undo "Đã lưu" or "Chưa lưu").
int _progress(DraftState s) => switch (s) {
  DraftState.draft || DraftState.needsReview => 0,
  DraftState.saving => 1,
  DraftState.failed => 2,
  DraftState.saved || DraftState.discarded => 3,
};

/// A draft never goes back: an older revision is ignored, and within a revision the state only
/// moves forward (saved and discarded are final).
AssistantDraft mergeDraft(AssistantDraft current, AssistantDraft incoming) {
  if (incoming.revision < current.revision) return current;
  if (incoming.revision == current.revision &&
      (current.state.settled && incoming.state != current.state ||
          _progress(incoming.state) < _progress(current.state))) {
    return current;
  }
  return incoming;
}

List<AssistantDraft> mergeDrafts(
  List<AssistantDraft> current,
  List<AssistantDraft> incoming,
) {
  final byId = {for (final d in current) d.id: d};
  for (final d in incoming) {
    final c = byId[d.id];
    byId[d.id] = c == null ? d : mergeDraft(c, d);
  }
  return byId.values.toList()
    ..sort((a, b) => a.itemIndex.compareTo(b.itemIndex));
}

TaskSnapshot mergeSnapshot(TaskSnapshot current, TaskSnapshot incoming) {
  final task = mergeTask(current.task, incoming.task);
  final messages = {
    for (final m in current.messages) m.id: m,
    for (final m in incoming.messages) m.id: m,
  }.values.toList()..sort((a, b) => a.sequence.compareTo(b.sequence));
  return TaskSnapshot(
    task: task,
    drafts: mergeDrafts(current.drafts, incoming.drafts),
    events: current.events,
    messages: messages,
    // Retention moves only forward (G05): a late snapshot never brings "đã xoá" back to pending.
    attachments: mergeAttachments(current.attachments, incoming.attachments),
  );
}

int _retentionProgress(AttachmentView a) => switch (a.state) {
  AttachmentState.uploading => 0,
  AttachmentState.ready => 1,
  AttachmentState.deletionPending => 2,
  AttachmentState.deleted => 3,
};

List<AttachmentView> mergeAttachments(
  List<AttachmentView> current,
  List<AttachmentView> incoming,
) {
  if (incoming.isEmpty) return current;
  final byId = {for (final a in current) a.id: a};
  return [
    for (final a in incoming)
      if (byId[a.id] case final c?
          when _retentionProgress(c) > _retentionProgress(a) ||
              (c.keptWithRecord && !a.keptWithRecord))
        c
      else
        a,
  ];
}

// ---------- Photos (slice A5: CH09–CH14) ----------

/// The photo limit of `createAttachmentUpload` (`assistantTaskLimits.maxImageBytes`).
const maxPhotoBytes = 8 * 1024 * 1024;

/// What the attachment bubble says about one photo of a task (Chat/Tệp đính kèm).
enum PhotoStatus { reading, read, blurry, refused, canceled }

PhotoStatus photoStatus(AssistantTask task, AttachmentView? a) {
  if (a?.rejected ?? false) return PhotoStatus.refused;
  return switch (task.state) {
    TaskState.received ||
    TaskState.uploading ||
    TaskState.queued ||
    TaskState.processing ||
    TaskState.blocked => PhotoStatus.reading,
    TaskState.canceled => PhotoStatus.canceled,
    TaskState.failed => switch (task.error) {
      AssistantReason.ocrUnreadable => PhotoStatus.blurry,
      AssistantReason.validationFailed => PhotoStatus.refused,
      _ => PhotoStatus.read,
    },
    TaskState.awaitingClarification || TaskState.ready => PhotoStatus.read,
  };
}

/// G05: what the app may say about a task's photo, only from the server's confirmed state.
enum RetentionLine {
  /// A copy is kept with the saved expense (D-075 #3).
  keptWithExpense,

  /// "Giữ ảnh hoá đơn" is on but nothing is saved yet: kept only if the expense is saved.
  keptIfSaved,

  /// Deletion requested or retried, not confirmed: never "đã xoá".
  deleting,

  /// Storage confirmed the deletion.
  deleted,

  /// "Xoá sau khi đọc" chosen, not deleted yet.
  willDelete,
}

/// [forExpense]: the task holds (or may still hold) an expense draft; otherwise nothing can keep
/// a copy, so "giữ cùng khoản chi" never shows (the server deletes the photo).
RetentionLine? retentionLine(
  List<AttachmentView> photos, {
  bool forExpense = true,
}) {
  if (photos.isEmpty) return null;
  if (photos.any((a) => a.keptWithRecord)) return RetentionLine.keptWithExpense;
  if (photos.every((a) => a.deletionConfirmed)) return RetentionLine.deleted;
  if (photos.any(
    (a) =>
        a.state == AttachmentState.deletionPending ||
        a.state == AttachmentState.deleted,
  )) {
    return RetentionLine.deleting;
  }
  return forExpense &&
          photos.any((a) => a.retention == AttachmentRetention.keepWithRecord)
      ? RetentionLine.keptIfSaved
      : RetentionLine.willDelete;
}

/// ISO 4217 exponent of a currency's minor unit, from Chi tiêu's list (VND, JPY, KRW 0); an
/// unknown code is shown with 2.
int currencyDigits(String? currency) => currency == null
    ? 0
    : (isSpCurrency(currency) ? spCurrency(currency).exponent : 2);

/// A reminder draft needs a time only while the server says so (MISSING_TIME / a missing
/// `time`): when the module takes date-only reminders (D-075 #5) the server stops asking.
bool reminderNeedsTimeFor(AssistantDraft d) =>
    d.missingFields.contains('time') ||
    d.problems.contains(DraftProblem.missingTime);

/// Applies `confirmDrafts` results to the drafts they name (per item; never a fake "all saved").
List<AssistantDraft> applyConfirm(
  List<AssistantDraft> drafts,
  List<ConfirmItemResult> items,
) {
  final byId = {for (final i in items) i.draftId: i};
  return [
    for (final d in drafts)
      if (byId[d.id] case final r?)
        r.status == ConfirmStatus.saved
            ? d.copyWith(
                state: DraftState.saved,
                revision: r.revision,
                recordId: r.recordId,
                recordLink: r.recordLink,
                clearError: true,
              )
            : d.copyWith(
                state: DraftState.failed,
                revision: r.revision,
                errorCode:
                    r.errorCode ??
                    (r.status == ConfirmStatus.conflict
                        ? AssistantReason.domainConflict.wire
                        : null),
                problems: r.problems.isEmpty ? null : r.problems,
              )
      else
        d,
  ];
}

/// A failed item a plain retry can fix (a system failure), unlike a conflict, a duplicate or a
/// refused role, which need the person (CH07: retry only failed items).
bool retryable(AssistantDraft d) {
  if (d.state != DraftState.failed) return false;
  return switch (d.error) {
    AssistantReason.domainConflict ||
    AssistantReason.duplicateSuspected ||
    AssistantReason.writeDenied ||
    AssistantReason.validationFailed ||
    AssistantReason.draftExpired ||
    AssistantReason.moduleUnavailable ||
    AssistantReason.scopeChanged ||
    AssistantReason.timerRunning ||
    AssistantReason.timerChanged ||
    AssistantReason.reviewRequired => false,
    _ => true,
  };
}

/// A conflict the person may still save with an acknowledgement ("Vẫn lưu riêng").
bool canSaveAnyway(AssistantDraft d) =>
    d.state == DraftState.failed &&
    (d.error == AssistantReason.domainConflict ||
        d.error == AssistantReason.duplicateSuspected);
