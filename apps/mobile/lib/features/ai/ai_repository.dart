import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../premium/premium_models.dart' show GateReason;
import 'ai_models.dart';

/// A refused or failed AI call. [reason] is a gate code (`ROLE_DENIED`…), a request problem or a
/// transport code (`unavailable`, `timeout`).
class AiException implements Exception {
  const AiException(this.reason);
  final String reason;

  GateReason? get gate => GateReason.fromWire(reason);

  /// No connection, or the server could not be reached in time.
  bool get offline => const {
    'unavailable',
    'deadline-exceeded',
    'timeout',
    'offline',
  }.contains(reason);

  @override
  String toString() => 'AiException($reason)';
}

/// A new idempotency key for one attempt: retrying the same key returns the same snapshot and
/// uses one quota at most; "Thử lại" / "Tạo lại" start a new attempt.
String newAiRequestId() => const Uuid().v4();

/// How long the phone waits for `generateSummary` before showing what it has.
const generateTimeout = Duration(seconds: 40);

/// Grounded AI on the phone (plan §5.5, A1–A3). `generateSummary`, `setAiConsent` and
/// `reportSummary` are callables (consent is written by the server so it can stop queued work
/// and clear cached AI text on withdrawal); stored handovers come from `listSummaries` (the Rules
/// keep milestone nudges from caregivers, so the app does not query the collection) and the last
/// list is kept on the phone for offline. My consent and the data version are read from Firestore.
/// Never logs child data.
class AiRepository {
  AiRepository(this._db, this._functions, this._prefs);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final SharedPreferences _prefs;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data, {
    Duration? timeout,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        name,
        options: timeout == null
            ? null
            : HttpsCallableOptions(timeout: timeout),
      );
      final r = await callable.call<Object?>(data);
      return r.data is Map
          ? Map<String, dynamic>.from(r.data! as Map)
          : const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw AiException(
        details is Map && details['reason'] is String
            ? details['reason'] as String
            : (e.message != null && GateReason.fromWire(e.message) != null)
            ? e.message!
            : e.code,
      );
    } on TimeoutException {
      throw const AiException('timeout');
    }
  }

  /// `users/{uid}/settings/ai` (owner only).
  Stream<AiSettings> watchSettings(String uid) => _db
      .doc('users/$uid/settings/ai')
      .snapshots()
      .map((s) => AiSettings.fromJson(_plain(s.data())));

  /// Gives (or updates) consent for [aiConsentVersion]; [shareMyNotes] lets my notes be used when
  /// someone else in the family asks for a summary.
  Future<void> setConsent({required bool shareMyNotes}) =>
      _call('setAiConsent', {
        'consent': {'version': aiConsentVersion, 'shareMyNotes': shareMyNotes},
      });

  /// "Thu hồi đồng ý": queued work stops and cached AI text is cleared by the server.
  Future<void> withdrawConsent() => _call('setAiConsent', {'consent': null});

  /// `generateSummary`. Gate reasons come back as a template answer with `fallbackReason`; a
  /// thrown [AiException] means no answer at all (offline, refused).
  Future<SummaryAnswer> generate({
    required String babyId,
    required AiSummaryKind kind,
    required String locale,
    required String requestId,
    String? recommendationId,
    String? milestoneId,
  }) async {
    final data = await _call('generateSummary', {
      'babyId': babyId,
      'kind': kind.wire,
      'locale': locale == 'en' ? 'en' : 'vi',
      'requestId': requestId,
      'recommendationId': ?recommendationId,
      'milestoneId': ?milestoneId,
    }, timeout: generateTimeout);
    final answer = SummaryAnswer.fromJson(data);
    if (answer == null) throw const AiException('invalid');
    return answer;
  }

  /// "Chưa đúng? Báo lại".
  Future<void> report({
    required String babyId,
    required String summaryId,
    required ReportProblem problem,
  }) => _call('reportSummary', {
    'babyId': babyId,
    'summaryId': summaryId,
    'problem': problem.wire,
  });

  /// D-093 "Gửi cho Jun": sends [summaryId] to [recipientUid] in the app (a push and an inbox
  /// row with no child data). Idempotent per summary and recipient.
  Future<HandoverSendResult> sendHandover({
    required String babyId,
    required String summaryId,
    required String recipientUid,
  }) async {
    final data = await _call('sendHandover', {
      'babyId': babyId,
      'summaryId': summaryId,
      'recipientUid': recipientUid,
    });
    return (
      sendId: data['sendId'] as String? ?? '',
      sentAt: DateTime.tryParse('${data['sentAt']}') ?? DateTime.now(),
      pushable: data['pushable'] == true,
    );
  }

  /// D-093: the recipient opened (`seen`) or acknowledged (`received`) a sent handover.
  Future<void> markHandover({
    required String babyId,
    required String sendId,
    required bool received,
  }) => _call('markHandover', {
    'babyId': babyId,
    'sendId': sendId,
    'action': received ? 'received' : 'seen',
  });

  /// The handovers I sent ([sent]) or was sent, newest first (Rules: sender and recipient only).
  Stream<List<HandoverSend>> watchHandoverSends(
    String babyId,
    String uid, {
    required bool sent,
  }) => _db
      .collection('babies/$babyId/handoverSends')
      .where(sent ? 'senderUid' : 'recipientUid', isEqualTo: uid)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            HandoverSend.fromJson(
              Map<String, dynamic>.from(_plain(d.data())! as Map),
            ),
        ]..sort((a, b) => b.sentAt.compareTo(a.sentAt)),
      );

  static String _listKey(String babyId) => 'ai.handovers.$babyId';

  /// The handovers this phone last read for [babyId] (offline: "the last stored version").
  List<SummaryAnswer>? cachedHandovers(String babyId) {
    final raw = _prefs.getString(_listKey(babyId));
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw);
      return [
        for (final x in (list is List ? list : const []))
          ?SummaryAnswer.fromJson(x),
      ];
    } on FormatException {
      return null;
    }
  }

  /// The stored handovers of a baby, newest first (`listSummaries`: `history.read` roles; it
  /// marks the ones older than the facts `stale`). Offline or failing: the last list this phone
  /// read; a member who may not read them any more forgets them.
  Future<List<SummaryAnswer>> handovers(String babyId) async {
    try {
      final data = await _call('listSummaries', {
        'babyId': babyId,
        'kind': AiSummaryKind.handover.wire,
        'limit': 5,
      });
      final raw = data['summaries'];
      final list = newestSummariesFirst([
        for (final x in (raw is List ? raw : const []))
          if (x is! Map || !_unfinished(x['status']))
            ?SummaryAnswer.fromJson(x),
      ]);
      unawaited(
        _prefs.setString(
          _listKey(babyId),
          jsonEncode([for (final s in list) s.toJson()]),
        ),
      );
      return list;
    } on AiException catch (e) {
      if (e.gate == GateReason.roleDenied || e.gate == GateReason.notMember) {
        unawaited(_prefs.remove(_listKey(babyId)));
        return const [];
      }
      return cachedHandovers(babyId) ?? const [];
    } on Object {
      return cachedHandovers(babyId) ?? const [];
    }
  }

  /// After withdrawing consent the server drops the AI text; this phone drops its copies too.
  Future<void> forgetHandovers() async {
    for (final k in _prefs.getKeys().where(
      (k) => k.startsWith('ai.handovers.'),
    )) {
      await _prefs.remove(k);
    }
  }

  /// `babies/{b}/facts/state.dataVersion`, bumped on every check-in, feedback or care edit.
  Stream<int?> watchDataVersion(String babyId) =>
      _db.doc('babies/$babyId/facts/state').snapshots().map((s) {
        final v = s.data()?['dataVersion'];
        return v is num ? v.toInt() : null;
      });
}

/// A summary still being made (the request id is claimed), or taken down.
bool _unfinished(Object? status) =>
    const {'pending', 'deleted'}.contains(status);

/// Firestore values as JSON (Timestamps → ISO strings).
Object? _plain(Object? v) => switch (v) {
  Timestamp t => t.toDate().toUtc().toIso8601String(),
  Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  List l => [for (final x in l) _plain(x)],
  _ => v,
};

// ---------- Providers ----------

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// My consent (per person).
final aiSettingsProvider = StreamProvider.family<AiSettings, String>(
  (ref, uid) => ref.watch(aiRepositoryProvider).watchSettings(uid),
);

/// Stored handovers of a baby, newest first; refreshed after a new one is made.
final handoversProvider = FutureProvider.autoDispose
    .family<List<SummaryAnswer>, String>(
      (ref, babyId) => ref.watch(aiRepositoryProvider).handovers(babyId),
      retry: (_, _) => null,
    );

typedef HandoverSendKey = ({String babyId, String uid});

/// D-093: handovers this person sent (the button's "Đã gửi cho Jun · Jun đã xem").
final sentHandoversProvider = StreamProvider.autoDispose
    .family<List<HandoverSend>, HandoverSendKey>(
      (ref, k) => ref
          .watch(aiRepositoryProvider)
          .watchHandoverSends(k.babyId, k.uid, sent: true),
    );

/// D-093: handovers sent to this person (the "Mới" dot, "Tôi đã nhận bàn giao").
final receivedHandoversProvider = StreamProvider.autoDispose
    .family<List<HandoverSend>, HandoverSendKey>(
      (ref, k) => ref
          .watch(aiRepositoryProvider)
          .watchHandoverSends(k.babyId, k.uid, sent: false),
    );

/// The baby's current data version; null when unknown (never "stale" then).
final dataVersionProvider = StreamProvider.family<int?, String>(
  (ref, babyId) => ref.watch(aiRepositoryProvider).watchDataVersion(babyId),
);

/// Opens the OS share sheet with plain text (no photos). Tests replace it.
final aiShareProvider =
    Provider<Future<void> Function(String text, String subject, Rect? origin)>(
      (ref) => (text, subject, origin) async {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: subject,
            sharePositionOrigin: origin,
          ),
        );
      },
    );
