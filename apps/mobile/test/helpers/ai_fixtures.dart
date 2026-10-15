import 'dart:async';

import 'package:child_life/features/ai/ai_models.dart';
import 'package:child_life/features/ai/ai_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:flutter/widgets.dart' show Rect;
import 'package:flutter_riverpod/misc.dart' show Override;

import 'family_fixtures.dart';
import 'rhythm_fixtures.dart';

/// Grounded-AI fixtures (Premium Slice 3), synthetic and shaped like `SummaryView` from the
/// server (`firebase/functions/src/ai-summary.ts`): the SU01 frame's story (06–08/10, Mẹ, Ba,
/// Cô Lan) on the rhythm fixtures' notes, with readable fact ids instead of "[F1]".

/// Mẹ 06/10 "Cần dỗ nhiều hơn", Ba 07/10 "Khó vào giấc", Cô Lan 08/10 (from [recentCheckIns]).
final _mai06 = recentCheckIns()[3];
final _minh07 = recentCheckIns()[1];
final _lan08 = recentCheckIns()[0];

List<Map<String, Object?>> _facts(bool en) => [
  {
    'id': _minh07.id,
    'kind': 'checkin',
    'date': _minh07.date,
    'authorUid': _minh07.authorUid,
    'text': en
        ? 'Hard to settle · night sleep · 2–3 days'
        : 'Khó vào giấc · giấc đêm · 2–3 ngày',
  },
  {
    'id': _mai06.id,
    'kind': 'checkin',
    'date': _mai06.date,
    'authorUid': _mai06.authorUid,
    'text': en ? 'Needs more soothing' : 'Cần dỗ nhiều hơn',
  },
  {
    'id': _lan08.id,
    'kind': 'checkin',
    'date': _lan08.date,
    'authorUid': _lan08.authorUid,
    'text': en ? 'Needs more soothing' : 'Cần dỗ nhiều hơn',
  },
  {
    'id': helpfulFeedback().id,
    'kind': 'feedback',
    'date': helpfulFeedback().date,
    'authorUid': helpfulFeedback().authorUid,
    'text': en
        ? 'Wind down 30 minutes before night sleep · Helpful'
        : 'Giảm kích thích 30 phút trước giấc đêm · Có ích',
  },
];

/// SU01 worded by AI (`method: ai`), as `generateSummary` / `listSummaries` answer it.
Map<String, Object?> handoverJson({
  String method = 'ai',
  String? reason,
  String language = 'vi',
  int dataVersion = 7,
  bool stale = false,
  Map<String, Object?>? quota,
  String id = 'sum_handover_1',
}) {
  final en = language == 'en';
  final ai = method != 'fallback';
  return {
    'id': id,
    'kind': 'handover',
    'method': method,
    'fallbackReason': reason,
    'sections': [
      {
        'kind': 'noticed',
        'text': ai
            ? (en
                  ? 'Teddy has been harder to settle at night for 2–3 days and needs more soothing. [F1]'
                  : 'Teddy khó vào giấc đêm 2–3 ngày qua và cần được dỗ nhiều hơn. [F1]')
            : (en
                  ? 'Hard to settle · night sleep · 2–3 days (Dad, 7 Oct). Needs more soothing (Mum, 6 Oct; Lan, 8 Oct).'
                  : 'Khó vào giấc · giấc đêm · 2–3 ngày (Ba, 07/10). Cần dỗ nhiều hơn (Mẹ, 06/10; Cô Lan, 08/10).'),
        'factIds': [_minh07.id, _mai06.id],
      },
      {
        'kind': 'helped',
        'text': ai
            ? (en
                  ? 'Wind-down before night sleep with a warm bath — Mum: Helpful.'
                  : 'Giảm kích thích trước giấc đêm, tắm ấm — Mẹ đánh giá “Có ích”.')
            : (en
                  ? 'Wind down 30 minutes before night sleep · Helpful (Mum, 7 Oct).'
                  : 'Giảm kích thích 30 phút trước giấc đêm · Có ích (Mẹ, 07/10).'),
        'factIds': [helpfulFeedback().id],
      },
      {
        'kind': 'next',
        'text': ai
            ? (en
                  ? 'Repeat the wind-down this evening, or add a note if tonight is different.'
                  : 'Lặp lại nếp thư giãn tối nay, hoặc ghi nhận lại nếu tối nay khác.')
            : (en
                  ? 'Repeat what helped, or add a note if tonight is different.'
                  : 'Lặp lại cách đã có ích, hoặc ghi nhận lại nếu tối nay khác.'),
        'factIds': <String>[],
      },
    ],
    'facts': _facts(en),
    'suggestionContentId': 'act_evening_repeat',
    'range': {'from': '2026-10-06', 'to': rhythmToday},
    'authorUids': ['u_mai', 'u_minh', 'u_lan'],
    'language': language,
    // 20:12 in Hồ Chí Minh.
    'generatedAt': '2026-10-08T13:12:00.000Z',
    'dataVersion': dataVersion,
    'quota': quota,
    'requestedBy': 'u_mai',
    'stale': stale,
  };
}

SummaryAnswer handover({
  String method = 'ai',
  String? reason,
  String language = 'vi',
  int dataVersion = 7,
  bool stale = false,
  Map<String, Object?>? quota,
}) => SummaryAnswer.fromJson(
  handoverJson(
    method: method,
    reason: reason,
    language: language,
    dataVersion: dataVersion,
    stale: stale,
    quota: quota,
  ),
)!;

/// The daily window used up (1/1), the month not.
Map<String, Object?> quotaDayUsed() => {
  'day': {
    'limit': 1,
    'used': 1,
    'reserved': 0,
    'resetsAt': '2026-10-08T17:00:00.000Z',
  },
  'month': {
    'limit': 10,
    'used': 4,
    'reserved': 0,
    'resetsAt': '2026-10-31T17:00:00.000Z',
  },
};

/// An explanation (kind explain) or milestone nudge (kind moment).
SummaryAnswer shortAnswer(
  AiSummaryKind kind,
  String text, {
  String method = 'ai',
  String? reason,
}) => SummaryAnswer.fromJson({
  'id': 'sum_${kind.wire}',
  'kind': kind.wire,
  'method': method,
  'fallbackReason': reason,
  'sections': [
    if (text.isNotEmpty) {'kind': 'note', 'text': text, 'factIds': <String>[]},
  ],
  'facts': <Object>[],
  'range': {'from': '2026-10-06', 'to': rhythmToday},
  'authorUids': <String>[],
  'language': 'vi',
  'generatedAt': '2026-10-08T03:00:00.000Z',
  'dataVersion': 7,
  'quota': null,
})!;

/// A `getCapabilities` answer with the rhythm and `ai_assist` rollouts on and group A.
Map<String, Object?> aiCaps({
  bool ai = true,
  String reason = 'PREMIUM_REQUIRED',
  bool aiAssist = true,
}) {
  final caps = rhythmCaps(plan: 'beta', groupA: true);
  return {
    ...caps,
    'capabilities': {
      ...(caps['capabilities']! as Map<String, Object?>),
      'ai.assistance': {'allowed': ai, 'reason': ai ? null : reason},
    },
    'features': {
      ...(caps['features']! as Map<String, Object?>),
      'aiAssist': aiAssist,
    },
  };
}

class _Live<T> {
  _Live(this.value);
  T value;
  final _changes = StreamController<T>.broadcast();

  Stream<T> get stream async* {
    yield value;
    yield* _changes.stream;
  }

  void set(T v) {
    value = v;
    _changes.add(v);
  }
}

typedef GenerateCall = ({
  AiSummaryKind kind,
  String requestId,
  String locale,
  String? recommendationId,
  String? milestoneId,
});

/// Answers the AI callables from fixtures and records what the screens asked.
class FakeAiRepository implements AiRepository {
  FakeAiRepository({
    this.answer,
    Map<AiSummaryKind, SummaryAnswer>? answers,
    this.error,
    List<SummaryAnswer> stored = const [],
    AiSettings settings = const AiSettings(
      consent: AiConsent(version: aiConsentVersion, shareMyNotes: true),
    ),
    int? dataVersion,
    this.consentError,
  }) : answers = answers ?? {},
       stored = [...stored],
       _settings = _Live(settings),
       _dataVersion = _Live(dataVersion);

  /// The handover answer (kind handover), or per kind in [answers].
  SummaryAnswer? answer;
  final Map<AiSummaryKind, SummaryAnswer> answers;
  Object? error;
  Object? consentError;
  List<SummaryAnswer> stored;
  final _Live<AiSettings> _settings;
  final _Live<int?> _dataVersion;

  final calls = <GenerateCall>[];
  final reports = <(String, ReportProblem)>[];

  /// `shareMyNotes` of each consent given; null for a withdrawal.
  final consents = <bool?>[];
  var forgot = 0;

  AiSettings get settings => _settings.value;

  @override
  Stream<AiSettings> watchSettings(String uid) => _settings.stream;

  @override
  Future<void> setConsent({required bool shareMyNotes}) async {
    if (consentError case final e?) throw e;
    consents.add(shareMyNotes);
    _settings.set(
      AiSettings(
        consent: AiConsent(
          version: aiConsentVersion,
          shareMyNotes: shareMyNotes,
          grantedAt: DateTime.utc(2026, 10, 8, 3),
        ),
        updatedAt: DateTime.utc(2026, 10, 8, 3),
      ),
    );
  }

  @override
  Future<void> withdrawConsent() async {
    if (consentError case final e?) throw e;
    consents.add(null);
    _settings.set(AiSettings(updatedAt: DateTime.utc(2026, 10, 8, 3)));
  }

  @override
  Future<SummaryAnswer> generate({
    required String babyId,
    required AiSummaryKind kind,
    required String locale,
    required String requestId,
    String? recommendationId,
    String? milestoneId,
  }) async {
    calls.add((
      kind: kind,
      requestId: requestId,
      locale: locale,
      recommendationId: recommendationId,
      milestoneId: milestoneId,
    ));
    if (error case final e?) throw e;
    final a = answers[kind] ?? (kind == AiSummaryKind.handover ? answer : null);
    if (a == null) throw const AiException('unavailable');
    return a;
  }

  @override
  Future<void> report({
    required String babyId,
    required String summaryId,
    required ReportProblem problem,
  }) async => reports.add((summaryId, problem));

  @override
  Future<List<SummaryAnswer>> handovers(String babyId) async => stored;

  @override
  List<SummaryAnswer>? cachedHandovers(String babyId) => stored;

  @override
  Future<void> forgetHandovers() async => forgot++;

  @override
  Stream<int?> watchDataVersion(String babyId) => _dataVersion.stream;

  void setDataVersion(int v) => _dataVersion.set(v);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What the share sheet got.
typedef Shared = ({String text, String subject});

/// [rhythmOverrides] plus the AI fake and a share-sheet recorder.
List<Override> aiOverrides({
  required FakeAiRepository ai,
  FakeRhythmRepository? repo,
  Map<String, Object?>? caps,
  bool online = true,
  List<Shared>? shared,
  Membership? member,
}) => [
  ...rhythmOverrides(
    repo:
        repo ??
        FakeRhythmRepository(
          checkIns: recentCheckIns(),
          feedback: familyFeedback(),
        ),
    me: member ?? mai,
    caps: caps ?? aiCaps(),
    online: online,
  ),
  aiRepositoryProvider.overrideWithValue(ai),
  aiShareProvider.overrideWithValue((text, subject, Rect? origin) async {
    shared?.add((text: text, subject: subject));
  }),
];

/// A check-in today by Cô Lan with a health sign (HL01 first, no AI text).
CheckIn healthCheckIn() => CheckIn(
  id: 'ci_${'d' * 32}',
  babyId: teddyId,
  date: rhythmToday,
  authorUid: 'u_lan',
  observation: Observation.health,
  healthSigns: const [HealthSign.breathing],
);
