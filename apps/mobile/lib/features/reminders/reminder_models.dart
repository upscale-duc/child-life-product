import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';
import '../baby/time_zones.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart' show babyToday;

/// Reminders (S7, Figma 8a–8e, 12f). Mirrors `packages/contracts/src/reminders.ts`; the Rules
/// (`validNewReminder`, `validReminderUpdate`) enforce the same shape.

/// "Báo trước" (D-031): Đúng giờ · 10 phút · 30 phút · 1 giờ · 2 giờ · 1 ngày.
const reminderLeadMinutes = [0, 10, 30, 60, 120, 1440];
const defaultReminderLeadMinutes = 60;
const reminderTitleMax = 80;

/// How far ahead the date wheel goes (Rules: 366 days).
const reminderMaxDaysAhead = 366;

// ---- D-075 #5: date-only (all day) and an assignee
// (docs/product/reminders-allday-assignee-plan.md) ----

/// "Báo trước" for an all-day reminder: "Đúng ngày" or "1 ngày" (the day before).
const reminderAllDayLeadMinutes = [0, 1440];
const defaultReminderAllDayLeadMinutes = 0;

/// The person's "Giờ nhắc việc cả ngày" until they pick one: 08:00 in the baby's zone.
const defaultReminderAllDayMinutes = 8 * 60;

/// Who may be assigned a reminder: the roles that see reminders (D-018).
bool canBeAssignedReminders(Membership m, DateTime now) =>
    m.isActiveAt(now) &&
    (m.role == MemberRole.coParent || m.role == MemberRole.caregiver);

/// Wall-clock time in [zone] → the absolute instant.
DateTime instantInZone(String zone, DateTime wall) {
  ensureTimeZones();
  try {
    return tz.TZDateTime(
      tz.getLocation(zone),
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    ).toUtc();
  } on Object {
    return wall;
  }
}

/// `YYYY-MM-DD` of a calendar day.
String isoDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The calendar day of `YYYY-MM-DD`, or null.
DateTime? dayOfIso(String? iso) {
  if (iso == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

/// `dueAt` of an all-day reminder: 23:59 on [day] in the baby's [zone] (older apps read it as a
/// timed reminder at 23:59 on the right day).
DateTime allDayDueAt(String zone, DateTime day) =>
    instantInZone(zone, DateTime(day.year, day.month, day.day, 23, 59));

/// Keeps a nullable field in [Reminder.copyWith].
const _keep = Object();
// ---- end D-075 #5 ----

String newReminderId() => 'rm_${const Uuid().v4().replaceAll('-', '')}';

enum ReminderStatus { overdue, upcoming, done }

/// "iPhone của Mai" (8e): the one device that holds the local notification (R-091, D-029).
@immutable
class NotifyDevice {
  const NotifyDevice({
    required this.id,
    required this.uid,
    required this.label,
    required this.owner,
  });

  final String id;
  final String uid;

  /// "iPhone", "iPad", "Pixel 8" — never a hardware identifier.
  final String label;

  /// The owner's display name when it was bound.
  final String owner;

  static NotifyDevice? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], uid = json['uid'];
    if (id is! String || uid is! String) return null;
    return NotifyDevice(
      id: id,
      uid: uid,
      label: json['label'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'uid': uid,
    'label': label,
    'owner': owner,
  };

  @override
  bool operator ==(Object other) =>
      other is NotifyDevice &&
      other.id == id &&
      other.uid == uid &&
      other.label == label &&
      other.owner == owner;

  @override
  int get hashCode => Object.hash(id, uid, label, owner);
}

@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.babyId,
    required this.title,
    required this.dueAt,
    required this.leadMinutes,
    required this.notifyDevice,
    required this.createdBy,
    required this.author,
    this.createdAt,
    this.done = false,
    this.doneAt,
    this.doneBy,
    this.doneAuthor,
    this.pending = false,
    this.allDay = false,
    this.dueDate,
    this.assigneeUid,
  });

  final String id;
  final String babyId;
  final String title;

  /// An absolute instant; shown in the baby's time zone (P-014).
  final DateTime dueAt;
  final int leadMinutes;
  final NotifyDevice? notifyDevice;
  final String createdBy;
  final CareAuthor author;
  final DateTime? createdAt;
  final bool done;
  final DateTime? doneAt;
  final String? doneBy;
  final CareAuthor? doneAuthor;

  /// Saved on this device, not yet on the server.
  final bool pending;

  /// D-075 #5: due the whole of [dueDate] (`YYYY-MM-DD` in the baby's zone); [dueAt] is then
  /// 23:59 that day and only orders the list.
  final bool allDay;
  final String? dueDate;

  /// D-075 #5: the member who should do it (Cùng nuôi or Người chăm sóc), or nobody.
  final String? assigneeUid;

  /// The calendar day of an all-day reminder.
  DateTime? get dueDay => allDay ? dayOfIso(dueDate) : null;

  /// R-093: overdue is derived — past due and not done. An all-day reminder is due all of its
  /// date in the baby's [zone] and overdue from the next day (D-075 #5).
  ReminderStatus statusAt(DateTime now, String zone) {
    if (done) return ReminderStatus.done;
    final day = dueDay;
    if (day != null) {
      return babyToday(zone, now).isAfter(day)
          ? ReminderStatus.overdue
          : ReminderStatus.upcoming;
    }
    return dueAt.isBefore(now)
        ? ReminderStatus.overdue
        : ReminderStatus.upcoming;
  }

  /// D-032: one notification at due time minus "Báo trước". An all-day reminder rings at the
  /// person's chosen time ([allDayMinutes] after midnight, baby's [zone]) on its day, or the
  /// day before for "1 ngày" (D-075 #5; never a silent 09:00).
  DateTime fireAt(
    String zone, {
    int allDayMinutes = defaultReminderAllDayMinutes,
  }) {
    final day = dueDay;
    if (day == null) return dueAt.subtract(Duration(minutes: leadMinutes));
    final ringDay = leadMinutes >= 1440
        ? DateTime(day.year, day.month, day.day - 1)
        : day;
    return instantInZone(
      zone,
      DateTime(
        ringDay.year,
        ringDay.month,
        ringDay.day,
        allDayMinutes ~/ 60,
        allDayMinutes % 60,
      ),
    );
  }

  /// Whether this reminder rings on an install of [uid] holding [deviceId]: the device it was
  /// put on (R-091, D-029) or any device of its assignee (D-075 #5).
  bool ringsOn({required String deviceId, required String uid}) =>
      notifyDevice?.id == deviceId ||
      (assigneeUid != null && assigneeUid == uid);

  Reminder copyWith({
    String? title,
    DateTime? dueAt,
    int? leadMinutes,
    NotifyDevice? notifyDevice,
    bool? allDay,
    Object? dueDate = _keep,
    Object? assigneeUid = _keep,
  }) => Reminder(
    id: id,
    babyId: babyId,
    title: title ?? this.title,
    dueAt: dueAt ?? this.dueAt,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    notifyDevice: notifyDevice ?? this.notifyDevice,
    createdBy: createdBy,
    author: author,
    createdAt: createdAt,
    done: done,
    doneAt: doneAt,
    doneBy: doneBy,
    doneAuthor: doneAuthor,
    pending: pending,
    allDay: allDay ?? this.allDay,
    dueDate: identical(dueDate, _keep) ? this.dueDate : dueDate as String?,
    assigneeUid: identical(assigneeUid, _keep)
        ? this.assigneeUid
        : assigneeUid as String?,
  );

  static Reminder? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data();
    if (json == null) return null;
    final dueAt = dateOf(json['dueAt']);
    final title = json['title'];
    if (dueAt == null || title is! String) return null;
    return Reminder(
      id: doc.id,
      babyId: json['babyId'] as String? ?? '',
      title: title,
      dueAt: dueAt,
      leadMinutes: (json['leadMinutes'] as num?)?.toInt() ?? 0,
      notifyDevice: NotifyDevice.fromJson(json['notifyDevice']),
      createdBy: json['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(json['author']),
      createdAt: dateOf(json['createdAt']),
      done: json['done'] == true,
      doneAt: dateOf(json['doneAt']),
      doneBy: json['doneBy'] as String?,
      doneAuthor: json['doneAuthor'] == null
          ? null
          : CareAuthor.fromJson(json['doneAuthor']),
      pending: doc.metadata.hasPendingWrites,
      // D-075 #5: absent on older documents (timed, unassigned).
      allDay:
          json['allDay'] == true &&
          dayOfIso(json['dueDate'] as String?) != null,
      dueDate: json['dueDate'] as String?,
      assigneeUid: switch (json['assigneeUid']) {
        final String uid when uid.isNotEmpty => uid,
        _ => null,
      },
    );
  }

  Map<String, Object?> toCreateJson() => {
    'id': id,
    'babyId': babyId,
    'title': title,
    'dueAt': Timestamp.fromDate(dueAt),
    'leadMinutes': leadMinutes,
    'notifyDevice': notifyDevice?.toJson(),
    'createdBy': createdBy,
    'author': author.toJson(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': createdBy,
    'done': false,
    'doneAt': null,
    'doneBy': null,
    'doneAuthor': null,
    // D-075 #5.
    'allDay': allDay,
    'dueDate': allDay ? dueDate : null,
    'assigneeUid': assigneeUid,
  };

  /// "Sửa nhắc việc" (Rules: Cùng nuôi only). The due time is sent only when it changed, so a
  /// past-due reminder can still be renamed; likewise the day and the assignee (D-075 #5), so
  /// an assignee who has since left does not block a rename.
  Map<String, Object?> toEditJson(Reminder before, String uid) => {
    'title': title,
    if (dueAt != before.dueAt) 'dueAt': Timestamp.fromDate(dueAt),
    'leadMinutes': leadMinutes,
    if (allDay != before.allDay || dueDate != before.dueDate) ...{
      'allDay': allDay,
      'dueDate': allDay ? dueDate : null,
    },
    if (assigneeUid != before.assigneeUid) 'assigneeUid': assigneeUid,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': uid,
  };
}

/// "Đánh dấu đã xong" / undo (D-030).
Map<String, Object?> reminderDoneJson(Membership me, {required bool done}) => {
  'done': done,
  'doneAt': done ? FieldValue.serverTimestamp() : null,
  'doneBy': done ? me.uid : null,
  'doneAuthor': done ? CareAuthor.of(me).toJson() : null,
  'updatedAt': FieldValue.serverTimestamp(),
  'updatedBy': me.uid,
};

/// 8a groups in order: Quá hạn (oldest first), Sắp tới (soonest first), Đã xong (latest first).
/// All-day reminders are grouped by date in the baby's [zone] (D-075 #5).
({List<Reminder> overdue, List<Reminder> upcoming, List<Reminder> done})
groupReminders(Iterable<Reminder> all, DateTime now, String zone) {
  final overdue = <Reminder>[], upcoming = <Reminder>[], done = <Reminder>[];
  for (final r in all) {
    switch (r.statusAt(now, zone)) {
      case ReminderStatus.overdue:
        overdue.add(r);
      case ReminderStatus.upcoming:
        upcoming.add(r);
      case ReminderStatus.done:
        done.add(r);
    }
  }
  overdue.sort((a, b) => a.dueAt.compareTo(b.dueAt));
  upcoming.sort((a, b) => a.dueAt.compareTo(b.dueAt));
  done.sort((a, b) => (b.doneAt ?? b.dueAt).compareTo(a.doneAt ?? a.dueAt));
  return (overdue: overdue, upcoming: upcoming, done: done);
}
