import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_notifications.dart';
import 'package:child_life/features/reminders/reminder_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'family_fixtures.dart';

/// This test device ("iPhone của Mai").
const testDeviceId = 'd_dddddddddddddddddddddddddddddddd';
NotifyDevice maiPhone() => const NotifyDevice(
  id: testDeviceId,
  uid: 'u_mai',
  label: 'iPhone',
  owner: 'Mai',
);

DateTime _vn(int day, int h, int m) =>
    DateTime.utc(2026, 10, day, h - 7, m).toLocal();

var _seq = 0;
Reminder reminder(
  String title,
  DateTime dueAt,
  Membership by, {
  int lead = 60,
  NotifyDevice? device,
  Membership? doneBy,
  DateTime? doneAt,
  DateTime? createdAt,
}) => Reminder(
  id: 'rm_${(++_seq).toRadixString(16).padLeft(32, '0')}',
  babyId: teddyId,
  title: title,
  dueAt: dueAt,
  leadMinutes: lead,
  notifyDevice: device,
  createdBy: by.uid,
  author: CareAuthor.of(by),
  createdAt: createdAt ?? _vn(8, 9, 0),
  done: doneBy != null,
  doneAt: doneAt,
  doneBy: doneBy?.uid,
  doneAuthor: doneBy == null ? null : CareAuthor.of(doneBy),
);

/// 8a (127:13602) at Thursday 8 Oct 15:05: one overdue, two upcoming, one done.
List<Reminder> mockReminders() => [
  reminder('Mua sữa công thức', _vn(7, 18, 0), minh),
  reminder('Tiêm 6 trong 1', _vn(10, 8, 30), mai, device: maiPhone()),
  reminder('Tái khám rốn', _vn(12, 9, 0), mai, device: maiPhone()),
  reminder(
    'Khám 1 tháng',
    _vn(6, 9, 0),
    minh,
    doneBy: minh,
    doneAt: _vn(6, 10, 0),
  ),
];

/// What the screens asked the repository to do.
class FakeReminderRepository extends Fake implements ReminderRepository {
  final created = <Reminder>[];
  final edited = <(Reminder, Reminder)>[];
  final done = <(Reminder, bool)>[];
  final moved = <(Reminder, NotifyDevice)>[];
  final deleted = <Reminder>[];

  @override
  void create(Reminder r, {void Function(Object error)? onError}) =>
      created.add(r);

  @override
  void edit(
    Reminder before,
    Reminder after,
    String uid, {
    void Function(Object error)? onError,
  }) => edited.add((before, after));

  @override
  void setDone(
    Reminder r,
    Membership me, {
    required bool done,
    void Function(Object error)? onError,
  }) => this.done.add((r, done));

  @override
  void moveNotifications(
    Reminder r,
    NotifyDevice device, {
    void Function(Object error)? onError,
  }) => moved.add((r, device));

  @override
  void delete(Reminder r, {void Function(Object error)? onError}) =>
      deleted.add(r);
}

/// OS side without a platform: permission is [on]; [request] grants when [grant].
class FakeReminderNotifications implements ReminderNotifications {
  FakeReminderNotifications({this.on = true, this.grant = true});

  bool on;
  bool grant;
  var requests = 0;
  List<LocalReminder> scheduled = const [];

  @override
  Future<void> init(void Function(String? payload) onTap) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> enabled() async => on;

  @override
  Future<bool> request() async {
    requests++;
    on = grant;
    return on;
  }

  @override
  Future<void> sync(List<LocalReminder> desired, AppLocalizations l10n) async =>
      scheduled = desired;
}
