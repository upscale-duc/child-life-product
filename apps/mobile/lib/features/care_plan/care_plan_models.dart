import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../baby/baby_models.dart';

/// Cùng Chăm Con (D-135): the day's shared plan of care tasks
/// (`babies/{b}/carePlanDays/{yyyy-mm-dd}` + `items`), shapes in
/// `packages/contracts/src/care-plan.ts`. Written by the server only.

/// What a task is (`carePlanTasks`); `custom` carries its own title.
enum CarePlanTask {
  bottle,
  breast,
  pump,
  solids,
  water,
  sleep,
  diaper,
  bath,
  tummy,
  read,
  walk,
  vitamin,
  medicine,
  temperature,
  teeth,
  potty,
  custom;

  static CarePlanTask? of(Object? wire) =>
      CarePlanTask.values.asNameMap()[wire as String? ?? ''];
}

enum CarePlanStatus {
  open,
  done,
  skipped;

  static CarePlanStatus of(Object? wire) =>
      CarePlanStatus.values.asNameMap()[wire as String? ?? ''] ?? open;
}

/// Sáng / Chiều / Tối: the day's tasks grouped by time, never a parent's shift.
enum CarePlanPeriod {
  morning,
  afternoon,
  evening;

  /// Before 12:00 morning, before 18:00 afternoon, else evening.
  static CarePlanPeriod ofTime(String hhmm) {
    final h = int.tryParse(hhmm.split(':').first) ?? 0;
    return h < 12
        ? morning
        : h < 18
        ? afternoon
        : evening;
  }

  /// The time a new task in this group starts at (06 "Thêm việc").
  String get defaultTime => switch (this) {
    morning => '08:00',
    afternoon => '14:00',
    evening => '19:00',
  };
}

/// Who may do what with the plan (13; defaults by role, mirrors `carePlanCan`).
bool carePlanCanManage(Membership m) => m.role == MemberRole.coParent;
bool carePlanCanComplete(Membership m) =>
    m.role == MemberRole.coParent || m.role == MemberRole.caregiver;

/// Who can be given a task (mirrors `carePlanAssignable`): those who care for the baby.
bool carePlanAssignable(Membership m, DateTime now) =>
    m.isActiveAt(now) &&
    (m.role == MemberRole.coParent || m.role == MemberRole.caregiver);

@immutable
class CarePlanDay {
  const CarePlanDay({
    required this.date,
    required this.revision,
    required this.source,
  });

  final String date;
  final int revision;
  final String source;

  static CarePlanDay? fromJson(String date, Map<String, dynamic>? d) =>
      d == null
      ? null
      : CarePlanDay(
          date: date,
          revision: (d['revision'] as num?)?.toInt() ?? 0,
          source: d['source'] as String? ?? 'empty',
        );
}

@immutable
class CarePlanItem {
  const CarePlanItem({
    required this.id,
    required this.task,
    required this.time,
    required this.assignees,
    required this.status,
    this.title,
    this.templateId,
    this.doneBy,
    this.doneAt,
  });

  final String id;
  final CarePlanTask task;
  final String? title;
  final String time;
  final List<String> assignees;
  final CarePlanStatus status;
  final String? templateId;
  final String? doneBy;
  final DateTime? doneAt;

  bool get done => status == CarePlanStatus.done;
  bool get skipped => status == CarePlanStatus.skipped;
  bool get everyDay => templateId != null;
  CarePlanPeriod get period => CarePlanPeriod.ofTime(time);

  CarePlanItem copyWith({CarePlanStatus? status, String? doneBy}) =>
      CarePlanItem(
        id: id,
        task: task,
        title: title,
        time: time,
        assignees: assignees,
        status: status ?? this.status,
        templateId: templateId,
        doneBy: status == null
            ? this.doneBy
            : status == CarePlanStatus.done
            ? doneBy
            : null,
        doneAt: doneAt,
      );

  static CarePlanItem? fromJson(Map<String, dynamic> d) {
    final task = CarePlanTask.of(d['task']);
    final id = d['id'];
    final time = d['time'];
    if (task == null || id is! String || time is! String) return null;
    return CarePlanItem(
      id: id,
      task: task,
      title: d['title'] as String?,
      time: time,
      assignees: [
        for (final a in (d['assignees'] as List?) ?? const []) ?a as String?,
      ],
      status: CarePlanStatus.of(d['status']),
      templateId: d['templateId'] as String?,
      doneBy: d['doneBy'] as String?,
      doneAt: (d['doneAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// The day's tasks in time order (then by id, so two at 07:00 never swap).
List<CarePlanItem> sortedPlan(Iterable<CarePlanItem> items) =>
    [...items]..sort((a, b) {
      final t = a.time.compareTo(b.time);
      return t != 0 ? t : a.id.compareTo(b.id);
    });

/// "2026-10-28" for a wall-clock day.
String carePlanDateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// A new task id (`pi_` + 32 hex), made on the phone so a retried save is the same task.
String newCarePlanItemId([Random? random]) {
  final r = random ?? Random.secure();
  final hex = StringBuffer('pi_');
  for (var i = 0; i < 16; i++) {
    hex.write(r.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return hex.toString();
}

/// "Nhắc trước" choices in minutes, 0 = Tắt (mirrors `carePlanReminderLeads`).
const carePlanReminderLeads = [5, 10, 15, 0];

/// This person's task reminders (N1, D-135 Q5): `users/{uid}/settings/carePlan`, written by its
/// owner (mirrors `carePlanPrefsOf`).
@immutable
class CarePlanPrefs {
  const CarePlanPrefs({this.leadMinutes = 5, this.quietHours = true});

  /// 5 / 10 / 15 minutes before the task; 0 = no reminder.
  final int leadMinutes;

  /// "Nhắc cả trong giờ yên lặng": on by default.
  final bool quietHours;

  bool get on => leadMinutes > 0;

  static CarePlanPrefs fromJson(Map<String, dynamic>? d) {
    final lead = d?['leadMinutes'];
    return CarePlanPrefs(
      leadMinutes: lead is int && carePlanReminderLeads.contains(lead)
          ? lead
          : 5,
      quietHours: d?['quietHours'] is bool ? d!['quietHours'] as bool : true,
    );
  }

  CarePlanPrefs copyWith({int? leadMinutes, bool? quietHours}) => CarePlanPrefs(
    leadMinutes: leadMinutes ?? this.leadMinutes,
    quietHours: quietHours ?? this.quietHours,
  );

  @override
  bool operator ==(Object other) =>
      other is CarePlanPrefs &&
      other.leadMinutes == leadMinutes &&
      other.quietHours == quietHours;

  @override
  int get hashCode => Object.hash(leadMinutes, quietHours);
}

/// The tasks of [uid] that are open on [items], in time order.
List<CarePlanItem> carePlanMine(Iterable<CarePlanItem> items, String uid) => [
  for (final i in items)
    if (i.status == CarePlanStatus.open && i.assignees.contains(uid)) i,
];

/// Minutes after midnight of "07:30".
int carePlanMinutes(String hhmm) {
  final p = hhmm.split(':');
  return (int.tryParse(p.first) ?? 0) * 60 +
      (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
}
