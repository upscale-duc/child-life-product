import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/reminders/rule_models.dart';

import 'care_fixtures.dart';
import 'family_fixtures.dart';

/// v1.0 rule reminders (370:1247) on the 8 Oct mock: Nhắc bú every 3 h (next 17:20), Nhắc
/// chuẩn bị ngủ at 09:00 · 13:00 · 19:30, Nhắc thay tã paused.
ReminderRule rule(
  String id,
  RuleType type, {
  RuleMode mode = RuleMode.afterLast,
  int? interval = 180,
  List<String> times = const [],
  bool enabled = true,
  DateTime? next,
  DateTime? pending,
  RuleOccurrence? last,
  List<String> recipients = const ['u_mai', 'u_minh', 'u_lan'],
}) => ReminderRule(
  id: id,
  babyId: teddyId,
  type: type,
  mode: mode,
  intervalMinutes: mode == RuleMode.afterLast ? interval : null,
  times: times,
  days: RuleLimits.allDays,
  quietNight: false,
  recipients: recipients,
  enabled: enabled,
  nextDueAt: next,
  pendingDueAt: pending,
  lastOutcome: last,
);

final feed = rule('rr_feed', RuleType.feed, next: vn(8, 17, 20));
final sleep = rule(
  'rr_sleep',
  RuleType.sleep,
  mode: RuleMode.fixed,
  times: const ['09:00', '13:00', '19:30'],
  next: vn(8, 19, 30),
);
final diaper = rule(
  'rr_diaper',
  RuleType.diaper,
  interval: 150,
  enabled: false,
);

/// 1h: Ba logged the 14:45 feed at 14:52; Mai snoozed the 11:45 one; the 08:30 one was skipped.
List<RuleOccurrence> mockOccurrences() => [
  RuleOccurrence(
    dueAt: vn(8, 14, 45),
    outcome: RuleOutcome.logged,
    at: vn(8, 14, 52),
    by: 'u_minh',
    author: const CareAuthor(name: 'Minh', relation: Relation.father),
  ),
  RuleOccurrence(
    dueAt: vn(8, 11, 45),
    outcome: RuleOutcome.snoozed,
    at: vn(8, 11, 46),
    by: 'u_mai',
    minutes: 15,
    author: const CareAuthor(name: 'Mai', relation: Relation.mother),
  ),
  RuleOccurrence(
    dueAt: vn(8, 8, 30),
    outcome: RuleOutcome.skipped,
    at: vn(8, 8, 31),
    by: 'u_mai',
  ),
];
