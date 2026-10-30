import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../baby/baby_models.dart';
import '../care/care_models.dart';
import '../../l10n/app_localizations.dart';
import '../reminders/device_identity.dart';
import '../reminders/reminder_models.dart';
import '../reminders/reminder_repository.dart';
import '../reminders/reminder_titles.dart';

/// One-time reminders made by Dinh dưỡng (P-163 #7, #13): ordinary reminders in Nhắc nhở,
/// visible to the family (D-075 #5), written like the 8b sheet writes them (queued offline).

/// The open (not done, not overdue) reminder titled [title], if there is one: the button then
/// reads "Đã đặt nhắc · {date}". A title written in another language or an earlier wording
/// counts too (reminder_titles.dart), so the button never makes a second one.
Reminder? nuOpenReminder(
  AppLocalizations l10n,
  Iterable<Reminder> all,
  String title,
  DateTime now,
  String zone,
) => all
    .where(
      (r) =>
          reminderTitle(l10n, r.title) == title &&
          r.statusAt(now, zone) == ReminderStatus.upcoming,
    )
    .firstOrNull;

/// Creates a reminder for [me]'s baby. All day on [day], or timed at [dueAt] with [lead] minutes
/// of "Báo trước". A job for someone else ([assigneeUid]) rings on their devices, not this one
/// (as the 8b sheet does).
Future<Reminder> nuCreateReminder(
  WidgetRef ref, {
  required Membership me,
  required String zone,
  required String title,
  DateTime? day,
  DateTime? dueAt,
  int lead = 0,
  String? assigneeUid,
  void Function(Object error)? onError,
}) async {
  assert(day != null || dueAt != null);
  final device = await ref.read(deviceIdentityProvider.future);
  final forSomeoneElse = assigneeUid != null && assigneeUid != me.uid;
  final reminder = Reminder(
    id: newReminderId(),
    babyId: me.babyId,
    title: title.length > reminderTitleMax
        ? title.substring(0, reminderTitleMax)
        : title,
    dueAt: day != null ? allDayDueAt(zone, day) : dueAt!,
    leadMinutes: lead,
    notifyDevice: forSomeoneElse
        ? null
        : NotifyDevice(
            id: device.id,
            uid: me.uid,
            label: device.label,
            owner: me.displayName,
          ),
    createdBy: me.uid,
    author: CareAuthor.of(me),
    allDay: day != null,
    dueDate: day == null ? null : isoDay(day),
    assigneeUid: assigneeUid,
  );
  ref.read(reminderRepositoryProvider).create(reminder, onError: onError);
  return reminder;
}
