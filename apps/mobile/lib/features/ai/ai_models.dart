import 'package:flutter/foundation.dart';

import '../premium/premium_models.dart' show GateReason;
import '../rhythm/rhythm_models.dart' show WireEnum, wireOf;

/// Grounded AI, Slice 3 (plan `docs/product/premium-personalization-plan.md` §5.5, A1–A3; P-151,
/// D-003): hand-written mirrors of `packages/contracts/src/ai-summary.ts`. The model only rewords
/// facts the engine produced; every number comes from the engine; anything else is the free
/// template built from the same facts. Parsing is tolerant: an unknown value drops that one item
/// (or falls back), never the whole screen. Nothing here is ever logged (no child data in logs).

/// `aiConsentVersion`: bumped when the consent text changes; an older consent no longer counts.
const aiConsentVersion = 'ai-consent-v1';

/// `aiSummaryKinds`: the handover (SU01), the explanation of one suggestion (PS01 / AC01) and the
/// nudge to keep a confirmed milestone (MS01).
enum AiSummaryKind with WireEnum {
  handover('handover'),
  explain('explain'),
  moment('moment');

  const AiSummaryKind(this.wire);
  @override
  final String wire;
}

/// `ai` (validated model output), `cache` (an earlier validated answer, free) or `fallback` (the
/// template; free, no quota used).
enum SummaryMethod with WireEnum {
  ai('ai'),
  cache('cache'),
  fallback('fallback');

  const SummaryMethod(this.wire);
  @override
  final String wire;
}

/// `summarySectionKinds`: SU01's three parts, plus a closing note.
enum SummarySectionKind with WireEnum {
  noticed('noticed'),
  helped('helped'),
  next('next'),
  note('note');

  const SummarySectionKind(this.wire);
  @override
  final String wire;
}

enum FactKind with WireEnum {
  checkIn('checkin'),
  feedback('feedback'),
  milestone('milestone'),
  sleep('sleep');

  const FactKind(this.wire);
  @override
  final String wire;
}

/// `reportSummaryRequestSchema.problem`: chosen, never free text about the child.
enum ReportProblem with WireEnum {
  wrongFact('wrong_fact'),
  wrongPerson('wrong_person'),
  unsafeAdvice('unsafe_advice'),
  language('language'),
  other('other');

  const ReportProblem(this.wire);
  @override
  final String wire;
}

String? _str(Object? v, {int max = 4000}) =>
    v is String && v.trim().isNotEmpty && v.length <= max ? v : null;

int? _int(Object? v) => v is num && v == v.roundToDouble() ? v.toInt() : null;

Map<String, Object?> _map(Object? v) =>
    v is Map ? v.map((k, x) => MapEntry('$k', x)) : const {};

List<Object?> _list(Object? v) => v is List ? v : const [];

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');

/// YYYY-MM-DD of a date or an ISO instant.
String? _date(Object? v) =>
    v is String && _isoDate.hasMatch(v) ? v.substring(0, 10) : null;

/// One consent (`aiConsentSchema.consent`).
@immutable
class AiConsent {
  const AiConsent({
    required this.version,
    required this.shareMyNotes,
    this.grantedAt,
  });

  final String version;
  final DateTime? grantedAt;

  /// Let my own free-text notes be included when someone else in the family asks for a summary.
  final bool shareMyNotes;

  /// Given for the consent text this app shows.
  bool get current => version == aiConsentVersion;

  static AiConsent? fromJson(Object? json) {
    final m = _map(json);
    final version = _str(m['version'], max: 40);
    if (version == null) return null;
    return AiConsent(
      version: version,
      grantedAt: DateTime.tryParse('${m['grantedAt']}'),
      shareMyNotes: m['shareMyNotes'] == true,
    );
  }
}

/// `users/{uid}/settings/ai`: per person; a household's Premium never replaces it.
@immutable
class AiSettings {
  const AiSettings({this.consent, this.updatedAt});

  final AiConsent? consent;
  final DateTime? updatedAt;

  static const none = AiSettings();

  /// Consent for the current text.
  bool get granted => consent?.current ?? false;

  /// Given once, then taken back ("Bạn đã tắt AI", ST01) — not just never asked.
  bool get withdrawn => consent == null && updatedAt != null;

  /// Given for an older consent text: asked again.
  bool get outdated => consent != null && !consent!.current;

  static AiSettings fromJson(Object? json) {
    final m = _map(json);
    if (m.isEmpty) return none;
    return AiSettings(
      consent: AiConsent.fromJson(m['consent']),
      updatedAt: DateTime.tryParse('${m['updatedAt']}'),
    );
  }
}

/// `SummaryFact`: one fact the engine extracted; the only thing a summary may talk about.
@immutable
class SummaryFact {
  const SummaryFact({
    required this.id,
    required this.kind,
    required this.date,
    required this.text,
    this.authorUid,
  });

  /// `ci_…` check-in, `fb_…` feedback, `ms_…` milestone, `sleep` comparison.
  final String id;
  final FactKind kind;
  final String date;
  final String? authorUid;

  /// Short engine-written line (template), e.g. "Khó vào giấc · giấc đêm · 2–3 ngày".
  final String text;

  /// A note someone wrote down (not the engine's own sleep comparison).
  bool get isRecord => kind != FactKind.sleep;

  static SummaryFact? fromJson(Object? json) {
    final m = _map(json);
    final id = _str(m['id'], max: 80);
    final kind = wireOf(FactKind.values, m['kind']);
    final date = _date(m['date']);
    if (id == null || kind == null || date == null) return null;
    return SummaryFact(
      id: id,
      kind: kind,
      date: date,
      authorUid: _str(m['authorUid'], max: 128),
      text: _str(m['text'], max: 600) ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'date': date,
    'authorUid': authorUid,
    'text': text,
  };
}

/// Inline citations the model may leave in a sentence ("[F1]", "[ci_…]"): the readable record
/// links replace them (SU01 annotation "liên kết ghi nhận thay [F1]").
final _citation = RegExp(r'\s*\[(?:F\d+|(?:ci|fb|ms)_[a-z0-9]+|sleep)\]');

String cleanSummaryText(String text) =>
    text.replaceAll(_citation, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();

@immutable
class SummarySection {
  const SummarySection({
    required this.kind,
    required this.text,
    this.factIds = const [],
  });

  final SummarySectionKind kind;
  final String text;
  final List<String> factIds;

  static SummarySection? fromJson(Object? json) {
    final m = _map(json);
    final kind = wireOf(SummarySectionKind.values, m['kind']);
    final raw = _str(m['text'], max: 600);
    if (kind == null || raw == null) return null;
    final text = cleanSummaryText(raw);
    if (text.isEmpty) return null;
    return SummarySection(
      kind: kind,
      text: text,
      factIds: [
        for (final f in _list(m['factIds']))
          if (_str(f, max: 60) case final String id) id,
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind.wire,
    'text': text,
    'factIds': factIds,
  };
}

/// `QuotaSnapshot`: one AI quota window.
@immutable
class QuotaWindow {
  const QuotaWindow({
    required this.limit,
    required this.used,
    this.reserved = 0,
    this.resetsAt,
  });

  final int limit;
  final int used;
  final int reserved;

  /// Exclusive end of the window.
  final DateTime? resetsAt;

  bool get exhausted => used + reserved >= limit;

  static QuotaWindow? fromJson(Object? json) {
    final m = _map(json);
    final limit = _int(m['limit']);
    final used = _int(m['used']);
    if (limit == null || used == null) return null;
    return QuotaWindow(
      limit: limit,
      used: used,
      reserved: _int(m['reserved']) ?? 0,
      resetsAt: DateTime.tryParse('${m['resetsAt']}'),
    );
  }

  Map<String, Object?> toJson() => {
    'limit': limit,
    'used': used,
    'reserved': reserved,
    'resetsAt': resetsAt?.toUtc().toIso8601String(),
  };
}

/// The technical fallbacks: AI failed, nothing was charged ("Không trừ lượt AI khi lỗi").
const technicalFallbacks = {'timeout', 'invalid', 'unavailable'};

/// `SummaryAnswer` of `generateSummary`, and a stored `babies/{b}/summaries/{id}` snapshot.
@immutable
class SummaryAnswer {
  const SummaryAnswer({
    required this.id,
    required this.kind,
    required this.method,
    required this.sections,
    this.fallbackReason,
    this.facts = const [],
    this.suggestionContentId,
    this.rangeFrom,
    this.rangeTo,
    this.authorUids = const [],
    this.language = 'vi',
    this.generatedAt,
    this.dataVersion,
    this.quotaDay,
    this.quotaMonth,
    this.health = false,
    this.stale = false,
    this.requestedBy,
  });

  final String id;
  final AiSummaryKind kind;
  final SummaryMethod method;

  /// CONSENT_REQUIRED, PREMIUM_REQUIRED, QUOTA_EXCEEDED, FEATURE_DISABLED… or the technical
  /// `timeout` / `invalid` / `unavailable`; null for an AI answer.
  final String? fallbackReason;
  final List<SummarySection> sections;
  final List<SummaryFact> facts;
  final String? suggestionContentId;
  final String? rangeFrom;
  final String? rangeTo;
  final List<String> authorUids;
  final String language;
  final DateTime? generatedAt;
  final int? dataVersion;
  final QuotaWindow? quotaDay;
  final QuotaWindow? quotaMonth;

  /// The facts point to health support: the free health route (HL01), never AI text. The
  /// contract's gate answers `HEALTH_FLOW` before any model call; it may arrive as a flag, a
  /// reason or a method (assumed, the answer shape has no field for it yet).
  final bool health;

  /// Stored before the facts changed (`SummaryView.stale`, from `listSummaries`).
  final bool stale;

  /// Who asked for it (`SummaryView.requestedBy`).
  final String? requestedBy;

  /// Worded by the model (now or from the cache): the AI label shows.
  bool get aiWorded => method != SummaryMethod.fallback && !health;

  GateReason? get gate => GateReason.fromWire(fallbackReason);

  /// AI failed (time, schema, provider): the template, no quota used, "Thử lại".
  bool get technicalFailure =>
      method == SummaryMethod.fallback &&
      technicalFallbacks.contains(fallbackReason);

  /// Notes behind it (check-ins, feedback, milestones; not the sleep comparison).
  List<SummaryFact> get records => [
    for (final f in facts)
      if (f.isRecord) f,
  ];

  SummaryFact? fact(String id) => facts.where((f) => f.id == id).firstOrNull;

  /// Anything unreadable is null (the screen shows its own state), never a crash.
  static SummaryAnswer? fromJson(Object? json, {String? id}) {
    final m = _map(json);
    final docId = _str(m['id'], max: 80) ?? id;
    final kind = wireOf(AiSummaryKind.values, m['kind']);
    final reason = _str(m['fallbackReason'], max: 60);
    final rawMethod = m['method'];
    final health =
        m['health'] == true ||
        reason == 'HEALTH_FLOW' ||
        rawMethod == 'health' ||
        rawMethod == 'health_flow';
    final method =
        wireOf(SummaryMethod.values, rawMethod) ?? SummaryMethod.fallback;
    if (docId == null || kind == null) return null;
    final sections = [
      for (final s in _list(m['sections'])) ?SummarySection.fromJson(s),
    ];
    // An "AI" answer without a single readable sentence is not shown as AI.
    if (sections.isEmpty && !health && method != SummaryMethod.fallback) {
      return null;
    }
    final range = _map(m['range']);
    final quota = _map(m['quota']);
    final language = m['language'] == 'en' ? 'en' : 'vi';
    return SummaryAnswer(
      id: docId,
      kind: kind,
      method: method,
      fallbackReason: reason,
      sections: sections,
      facts: [for (final f in _list(m['facts'])) ?SummaryFact.fromJson(f)],
      suggestionContentId: _str(m['suggestionContentId'], max: 60),
      rangeFrom: _date(range['from']),
      rangeTo: _date(range['to']),
      authorUids: [
        for (final u in _list(m['authorUids']))
          if (_str(u, max: 128) case final String uid) uid,
      ],
      language: language,
      generatedAt: _instant(m['generatedAt']),
      dataVersion: _int(m['dataVersion']),
      quotaDay: QuotaWindow.fromJson(quota['day']),
      quotaMonth: QuotaWindow.fromJson(quota['month']),
      health: health,
      stale: m['stale'] == true || m['status'] == 'stale',
      requestedBy: _str(m['requestedBy'], max: 128),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'method': method.wire,
    'fallbackReason': fallbackReason,
    'sections': [for (final s in sections) s.toJson()],
    'facts': [for (final f in facts) f.toJson()],
    'suggestionContentId': suggestionContentId,
    'range': {'from': rangeFrom, 'to': rangeTo},
    'authorUids': authorUids,
    'language': language,
    'generatedAt': generatedAt?.toUtc().toIso8601String(),
    'dataVersion': dataVersion,
    'quota': quotaDay == null && quotaMonth == null
        ? null
        : {'day': quotaDay?.toJson(), 'month': quotaMonth?.toJson()},
    if (health) 'health': true,
    'stale': stale,
    'requestedBy': requestedBy,
  };
}

/// An ISO string, or anything with `toDate()` (a Firestore Timestamp), or epoch millis.
DateTime? _instant(Object? v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  if (v is DateTime) return v;
  try {
    final d = (v as dynamic).toDate();
    return d is DateTime ? d : null;
  } on Object {
    return null;
  }
}

/// The newest handover, preferring one in [language] (the cache key includes the locale).
SummaryAnswer? latestHandover(List<SummaryAnswer> stored, String language) {
  final handovers = [
    for (final s in stored)
      if (s.kind == AiSummaryKind.handover) s,
  ];
  return handovers.where((s) => s.language == language).firstOrNull ??
      handovers.firstOrNull;
}

/// Newest first by [SummaryAnswer.generatedAt] (unknown times last).
List<SummaryAnswer> newestSummariesFirst(Iterable<SummaryAnswer> rows) =>
    [...rows]..sort((a, b) {
      final at = a.generatedAt, bt = b.generatedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
