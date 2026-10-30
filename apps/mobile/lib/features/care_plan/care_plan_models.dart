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
    this.draft = false,
  });

  final String date;
  final int revision;

  /// How the day was made (`CarePlanMethod`): everyday, yesterday, empty, rhythm, basic, …
  final String source;

  /// A draft (D-136): looked over and edited by the plan managers, not anyone's to-do and not
  /// reminded until "Dùng lịch này". A day without `status` is in use.
  final bool draft;

  static CarePlanDay? fromJson(String date, Map<String, dynamic>? d) =>
      d == null
      ? null
      : CarePlanDay(
          date: date,
          revision: (d['revision'] as num?)?.toInt() ?? 0,
          source: d['source'] as String? ?? 'empty',
          draft: d['status'] == 'draft',
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
    this.draft = false,
    this.assignedBy,
    this.amountMl,
    this.reactions = const {},
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

  /// Part of a draft day (D-136): nobody's to-do yet.
  final bool draft;

  /// Who gave it to [assignees] ("Mẹ nhờ Ba nhé", Figma 15); null for a day started from
  /// yesterday or a template.
  final String? assignedBy;

  /// D-138: the ml planned for a bottle or pumping; the log opens with it.
  final int? amountMl;

  /// 10 Vừa xong: who sent a heart and / or a thanks (`CarePlanThanks.key`) for it.
  final Map<String, CarePlanReaction> reactions;

  int get hearts => reactions.values.where((r) => r.heart).length;

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
        draft: draft,
        assignedBy: assignedBy,
        amountMl: amountMl,
        reactions: reactions,
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
      draft: d['draft'] == true,
      assignedBy: d['assignedBy'] as String?,
      amountMl: (d['amountMl'] as num?)?.toInt(),
      reactions: {
        for (final e in ((d['reactions'] as Map?) ?? const {}).entries)
          if (e.key is String && e.value is Map)
            e.key as String: CarePlanReaction(
              heart: (e.value as Map)['heart'] == true,
              thanks: CarePlanThanks.of((e.value as Map)['thanks']),
            ),
      },
    );
  }
}

/// 10 Vừa xong: the thanks lines (mirrors `carePlanThanks`; keys, never typed text).
enum CarePlanThanks {
  thanks,
  great,
  thanksName,
  proud,
  love;

  static CarePlanThanks? of(Object? key) =>
      values.where((t) => t.name == key).firstOrNull;
}

/// One person's heart and thanks for a task.
@immutable
class CarePlanReaction {
  const CarePlanReaction({this.heart = false, this.thanks});

  final bool heart;
  final CarePlanThanks? thanks;
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
  const CarePlanPrefs({
    this.leadMinutes = 5,
    this.quietHours = true,
    this.team = true,
  });

  /// 5 / 10 / 15 minutes before the task; 0 = no reminder.
  final int leadMinutes;

  /// "Nhắc cả trong giờ yên lặng": on by default.
  final bool quietHours;

  /// "Khi người khác làm xong" (N2) and the hearts / thanks for mine (N3): on by default.
  final bool team;

  bool get on => leadMinutes > 0;

  static CarePlanPrefs fromJson(Map<String, dynamic>? d) {
    final lead = d?['leadMinutes'];
    return CarePlanPrefs(
      leadMinutes: lead is int && carePlanReminderLeads.contains(lead)
          ? lead
          : 5,
      quietHours: d?['quietHours'] is bool ? d!['quietHours'] as bool : true,
      team: d?['team'] is bool ? d!['team'] as bool : true,
    );
  }

  CarePlanPrefs copyWith({int? leadMinutes, bool? quietHours, bool? team}) =>
      CarePlanPrefs(
        leadMinutes: leadMinutes ?? this.leadMinutes,
        quietHours: quietHours ?? this.quietHours,
        team: team ?? this.team,
      );

  @override
  bool operator ==(Object other) =>
      other is CarePlanPrefs &&
      other.leadMinutes == leadMinutes &&
      other.quietHours == quietHours &&
      other.team == team;

  @override
  int get hashCode => Object.hash(leadMinutes, quietHours, team);
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

/// D-136 #2: "Theo nhịp của bé" needs this many days before today, each with a feed and a sleep
/// (mirrors `carePlanRhythmDays`).
const carePlanRhythmDays = 7;

/// The reference templates (D-136 #1), offered on dev only until the owner reviews them.
/// D-138: tasks that carry a planned amount (mirrors `carePlanAmountTasks`), and presets.
const carePlanAmountTasks = {CarePlanTask.bottle, CarePlanTask.pump};
const carePlanMlPresets = [60, 90, 120, 150, 180];

const carePlanTemplateMethods = ['basic', 'easy35', 'easy4'];

/// D-136 #4: EASY fits babies under this many months (mirrors `carePlanEasyMaxMonths`).
const carePlanEasyMaxMonths = 6;

/// Whole calendar months from [dob] to [today] (mirrors `ageInMonths`).
int carePlanAgeMonths(DateTime dob, DateTime today) {
  var months = (today.year - dob.year) * 12 + today.month - dob.month;
  final lastDay = DateTime.utc(today.year, today.month + 1, 0).day;
  if (today.day < (dob.day < lastDay ? dob.day : lastDay)) months -= 1;
  return months < 0 ? 0 : months;
}

/// Whether the template [method] is offered to a baby [ageMonths] old (null: unknown, all are;
/// mirrors `templateOffered`).
bool carePlanTemplateOffered(String method, int? ageMonths) =>
    method == 'basic' || ageMonths == null || ageMonths < carePlanEasyMaxMonths;

/// The family's plan settings (`babies/{b}/carePlanSettings/family`, server-written).
@immutable
class CarePlanFamilySettings {
  const CarePlanFamilySettings({this.autoDraft = false, this.method});

  /// "Tự tạo lịch mỗi sáng" (D-136 #3): off by default.
  final bool autoDraft;

  /// The way the family last started a day; the morning draft uses it.
  final String? method;

  static CarePlanFamilySettings fromJson(Map<String, dynamic>? d) =>
      CarePlanFamilySettings(
        autoDraft: d?['autoDraft'] == true,
        method: d?['method'] as String?,
      );
}

/// One line of `carePlanHistory` (20 Lịch sử thay đổi, and the report's done tasks): who did
/// what to the plan, and when. Written only by the plan Functions.
@immutable
class CarePlanChange {
  const CarePlanChange({
    required this.id,
    required this.at,
    required this.by,
    required this.action,
    required this.date,
    this.itemIds = const [],
    this.task,
    this.title,
    this.time,
    this.oldTime,
    this.scope,
    this.assignees,
    this.from,
  });

  final String id;
  final DateTime at;

  /// A uid, or `system` (the morning draft, D-136 #3).
  final String by;

  /// start · publish · add · edit · delete · assign · done · undone · skip.
  final String action;
  final String date;
  final List<String> itemIds;
  final CarePlanTask? task;
  final String? title;
  final String? time;
  final String? oldTime;

  /// `today` / `everyDay` for add, edit and delete.
  final String? scope;
  final List<String>? assignees;

  /// The way a day was started (start).
  final String? from;

  static CarePlanChange? fromJson(String id, Map<String, dynamic> d) {
    final at = d['at'];
    final by = d['by'];
    final action = d['action'];
    final date = d['date'];
    if (at is! Timestamp ||
        by is! String ||
        action is! String ||
        date is! String) {
      return null;
    }
    return CarePlanChange(
      id: id,
      at: at.toDate(),
      by: by,
      action: action,
      date: date,
      itemIds: [
        for (final i in (d['itemIds'] as List?) ?? const []) ?i as String?,
      ],
      task: CarePlanTask.of(d['task']),
      title: d['title'] as String?,
      time: d['time'] as String?,
      oldTime: d['oldTime'] as String?,
      scope: d['scope'] as String?,
      assignees: (d['assignees'] as List?)?.whereType<String>().toList(),
      from: d['from'] as String?,
    );
  }
}
