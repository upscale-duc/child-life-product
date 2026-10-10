import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';
import '../care/care_models.dart';

/// Reminders (S7, Figma 8a–8e, 12f). Mirrors `packages/contracts/src/reminders.ts`; the Rules
/// (`validNewReminder`, `validReminderUpdate`) enforce the same shape.

/// "Báo trước" (D-031): Đúng giờ · 10 phút · 30 phút · 1 giờ · 2 giờ · 1 ngày.
const reminderLeadMinutes = [0, 10, 30, 60, 120, 1440];
const defaultReminderLeadMinutes = 60;
const reminderTitleMax = 80;

/// How far ahead the date wheel goes (Rules: 366 days).
const reminderMaxDaysAhead = 366;

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

  /// R-093: overdue is derived — past due and not done.
  ReminderStatus statusAt(DateTime now) => done
      ? ReminderStatus.done
      : (dueAt.isBefore(now)
            ? ReminderStatus.overdue
            : ReminderStatus.upcoming);

  /// D-032: one notification at due time minus "Báo trước".
  DateTime get fireAt => dueAt.subtract(Duration(minutes: leadMinutes));

  Reminder copyWith({
    String? title,
    DateTime? dueAt,
    int? leadMinutes,
    NotifyDevice? notifyDevice,
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
  };

  /// "Sửa nhắc việc" (Rules: Cùng nuôi only). The due time is sent only when it changed, so a
  /// past-due reminder can still be renamed.
  Map<String, Object?> toEditJson(Reminder before, String uid) => {
    'title': title,
    if (dueAt != before.dueAt) 'dueAt': Timestamp.fromDate(dueAt),
    'leadMinutes': leadMinutes,
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
({List<Reminder> overdue, List<Reminder> upcoming, List<Reminder> done})
groupReminders(Iterable<Reminder> all, DateTime now) {
  final overdue = <Reminder>[], upcoming = <Reminder>[], done = <Reminder>[];
  for (final r in all) {
    switch (r.statusAt(now)) {
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
