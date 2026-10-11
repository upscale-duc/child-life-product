import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'rule_models.dart';

/// Rule reminders (D-051): read from Firestore, changed only through the Functions, which keep
/// the schedule and push to the recipients. Calls throw [FirebaseFunctionsException].
class RuleRepository {
  RuleRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _col(String babyId) =>
      _db.collection('babies/$babyId/reminderRules');

  Stream<List<ReminderRule>> watch(String babyId) => _col(babyId)
      .orderBy('createdAt')
      .limit(50)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?ReminderRule.fromSnapshot(d)]);

  Stream<List<RuleOccurrence>> occurrences(String babyId, String ruleId) =>
      _col(babyId)
          .doc(ruleId)
          .collection('occurrences')
          .orderBy('at', descending: true)
          .limit(10)
          .snapshots()
          .map(
            (s) => [for (final d in s.docs) ?RuleOccurrence.fromJson(d.data())],
          );

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    final r = await _functions.httpsCallable(name).call<Object?>(data);
    final out = r.data;
    return out is Map ? out.cast<String, Object?>() : const {};
  }

  /// 1d "Lưu nhắc"; returns the next time it rings (null = waiting for a log).
  Future<DateTime?> save(String babyId, RuleDraft draft) async {
    final r = await _call('saveRuleReminder', draft.toCall(babyId));
    return _ms(r['nextDueAt']);
  }

  /// 1a toggle: off = "Đang tạm dừng".
  Future<void> setEnabled(String babyId, String ruleId, bool enabled) => _call(
    'setRuleReminderEnabled',
    {'babyId': babyId, 'ruleId': ruleId, 'enabled': enabled},
  );

  Future<void> delete(String babyId, String ruleId) =>
      _call('deleteRuleReminder', {'babyId': babyId, 'ruleId': ruleId});

  /// 1f / 1g: snooze [minutes] or skip the reminder that rang at [dueAt]. False when someone
  /// had already handled it (1h).
  Future<bool> answer(
    String babyId,
    String ruleId,
    DateTime dueAt, {
    int? snoozeMinutes,
  }) async {
    final r = await _call('answerRuleReminder', {
      'babyId': babyId,
      'ruleId': ruleId,
      'action': snoozeMinutes == null ? 'skip' : 'snooze',
      'minutes': ?snoozeMinutes,
      'dueAt': dueAt.millisecondsSinceEpoch,
    });
    return r['status'] == 'done';
  }

  static DateTime? _ms(Object? v) =>
      v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
}

final ruleRepositoryProvider = Provider<RuleRepository>(
  (ref) => RuleRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final reminderRulesProvider = StreamProvider.family<List<ReminderRule>, String>(
  (ref, babyId) => ref.watch(ruleRepositoryProvider).watch(babyId),
);

final ruleOccurrencesProvider =
    StreamProvider.family<List<RuleOccurrence>, (String, String)>(
      (ref, key) =>
          ref.watch(ruleRepositoryProvider).occurrences(key.$1, key.$2),
    );
