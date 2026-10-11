import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../care/care_models.dart';

/// Rule reminders (v1.0 improvement 370:1247, D-051): mirrors
/// `packages/contracts/src/reminder-rules.ts`. The server owns the schedule; the app reads the
/// rules and asks the Functions to change them.

/// 1b "Bạn muốn nhắc việc gì?" — Bú counts bottle and breast.
enum RuleType {
  feed([CareType.bottle, CareType.breast]),
  sleep([CareType.sleep]),
  diaper([CareType.diaper]),
  pump([CareType.pump]);

  const RuleType(this.careTypes);
  final List<CareType> careTypes;
}

/// 1b "Cách nhắc".
enum RuleMode { afterLast, fixed }

/// 1h "Gần đây".
enum RuleOutcome { logged, snoozed, skipped, missed }

abstract final class RuleLimits {
  static const intervalMin = 30;
  static const intervalMax = 12 * 60;
  static const intervalStep = 15;
  static const presets = [120, 150, 180, 210];
  static const timesMax = 8;
  static const snooze = [10, 15, 30];
  static const allDays = [1, 2, 3, 4, 5, 6, 7];
}

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

class RuleOccurrence {
  const RuleOccurrence({
    required this.dueAt,
    required this.outcome,
    required this.at,
    this.by,
    this.author,
    this.recordId,
    this.minutes,
  });

  final DateTime dueAt;
  final RuleOutcome outcome;
  final DateTime at;
  final String? by;
  final CareAuthor? author;
  final String? recordId;
  final int? minutes;

  static RuleOccurrence? fromJson(Object? json) {
    if (json is! Map) return null;
    final dueAt = _date(json['dueAt']);
    final at = _date(json['at']);
    final outcome = RuleOutcome.values.asNameMap()[json['outcome']];
    if (dueAt == null || at == null || outcome == null) return null;
    return RuleOccurrence(
      dueAt: dueAt,
      outcome: outcome,
      at: at,
      by: json['by'] as String?,
      author: json['author'] == null
          ? null
          : CareAuthor.fromJson(json['author']),
      recordId: json['recordId'] as String?,
      minutes: (json['minutes'] as num?)?.toInt(),
    );
  }
}

class ReminderRule {
  const ReminderRule({
    required this.id,
    required this.babyId,
    required this.type,
    required this.mode,
    required this.intervalMinutes,
    required this.times,
    required this.days,
    required this.quietNight,
    required this.recipients,
    required this.enabled,
    this.anchorAt,
    this.nextDueAt,
    this.pendingDueAt,
    this.snoozedUntil,
    this.lastOutcome,
    this.createdAt,
  });

  final String id;
  final String babyId;
  final RuleType type;
  final RuleMode mode;
  final int? intervalMinutes;
  final List<String> times;
  final List<int> days;
  final bool quietNight;
  final List<String> recipients;
  final bool enabled;
  final DateTime? anchorAt;
  final DateTime? nextDueAt;

  /// Rang and nobody has answered or logged yet (1g).
  final DateTime? pendingDueAt;
  final DateTime? snoozedUntil;
  final RuleOccurrence? lastOutcome;
  final DateTime? createdAt;

  bool get everyDay => days.length == 7;

  static ReminderRule? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data();
    if (j == null) return null;
    final type = RuleType.values.asNameMap()[j['type']];
    final mode = RuleMode.values.asNameMap()[j['mode']];
    if (type == null || mode == null) return null;
    return ReminderRule(
      id: d.id,
      babyId: j['babyId'] as String? ?? '',
      type: type,
      mode: mode,
      intervalMinutes: (j['intervalMinutes'] as num?)?.toInt(),
      times: [for (final t in (j['times'] as List? ?? const [])) '$t'],
      days: [
        for (final n in (j['days'] as List? ?? const [])) (n as num).toInt(),
      ],
      quietNight: j['quietNight'] == true,
      recipients: [
        for (final r in (j['recipients'] as List? ?? const [])) '$r',
      ],
      enabled: j['enabled'] == true,
      anchorAt: _date(j['anchorAt']),
      nextDueAt: _date(j['nextDueAt']),
      pendingDueAt: _date(j['pendingDueAt']),
      snoozedUntil: _date(j['snoozedUntil']),
      lastOutcome: RuleOccurrence.fromJson(j['lastOutcome']),
      createdAt: _date(j['createdAt']),
    );
  }
}

/// What the create / edit flow (1b–1d) sends to `saveRuleReminder`.
class RuleDraft {
  const RuleDraft({
    required this.id,
    this.type = RuleType.feed,
    this.mode = RuleMode.afterLast,
    this.intervalMinutes = 180,
    this.times = const ['09:00', '13:00', '19:30'],
    this.days = RuleLimits.allDays,
    this.quietNight = false,
    this.recipients = const [],
  });

  factory RuleDraft.of(ReminderRule r) => RuleDraft(
    id: r.id,
    type: r.type,
    mode: r.mode,
    intervalMinutes: r.intervalMinutes ?? 180,
    times: r.mode == RuleMode.fixed
        ? r.times
        : const ['09:00', '13:00', '19:30'],
    days: r.days,
    quietNight: r.quietNight,
    recipients: r.recipients,
  );

  final String id;
  final RuleType type;
  final RuleMode mode;
  final int intervalMinutes;
  final List<String> times;
  final List<int> days;
  final bool quietNight;
  final List<String> recipients;

  RuleDraft copyWith({
    RuleType? type,
    RuleMode? mode,
    int? intervalMinutes,
    List<String>? times,
    List<int>? days,
    bool? quietNight,
    List<String>? recipients,
  }) => RuleDraft(
    id: id,
    type: type ?? this.type,
    mode: mode ?? this.mode,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    times: times ?? this.times,
    days: days ?? this.days,
    quietNight: quietNight ?? this.quietNight,
    recipients: recipients ?? this.recipients,
  );

  Map<String, Object?> toCall(String babyId) => {
    'babyId': babyId,
    'ruleId': id,
    'type': type.name,
    'mode': mode.name,
    'intervalMinutes': mode == RuleMode.afterLast ? intervalMinutes : null,
    'times': mode == RuleMode.fixed ? ([...times]..sort()) : const <String>[],
    'days': [...days]..sort(),
    'quietNight': mode == RuleMode.afterLast && quietNight,
    'recipients': recipients,
  };
}

/// `rr_` + 32 hex, made here so a retried save is idempotent.
String newRuleId([Random? random]) {
  final r = random ?? Random.secure();
  final hex = List.generate(32, (_) => r.nextInt(16).toRadixString(16)).join();
  return 'rr_$hex';
}

int minuteOfClock(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String clockOf(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
