import 'dart:async';

import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/care_plan/care_plan_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'family_fixtures.dart';

/// Cùng Chăm Con (D-135) fixtures: Teddy's plan on Wednesday 28/10/2026, 09:05 in Hồ Chí Minh.
final carePlanNow = DateTime.utc(2026, 10, 28, 2, 5).toLocal();
const carePlanToday = '2026-10-28';

var _seq = 0;
CarePlanItem planItem(
  CarePlanTask task,
  String time, {
  List<String> who = const [],
  CarePlanStatus status = CarePlanStatus.open,
  String? doneBy,
  String? title,
  bool everyDay = false,
  int? amountMl,
}) => CarePlanItem(
  id: 'pi_${(++_seq).toRadixString(16).padLeft(32, '0')}',
  task: task,
  title: title,
  time: time,
  assignees: who,
  status: status,
  doneBy: doneBy,
  templateId: everyDay ? 'pt_${_seq.toRadixString(16).padLeft(32, '0')}' : null,
  amountMl: amountMl,
);

/// 04: ten tasks, nothing done yet (Mai = Mẹ, Minh = Ba, Lan = Cô Lan).
List<CarePlanItem> planFresh() => sortedPlan([
  planItem(
    CarePlanTask.bottle,
    '07:00',
    who: [mai.uid],
    everyDay: true,
    amountMl: 120,
  ),
  planItem(CarePlanTask.sleep, '08:30', who: [lan.uid]),
  planItem(CarePlanTask.vitamin, '09:00', who: [minh.uid], everyDay: true),
  planItem(CarePlanTask.diaper, '10:30', who: [lan.uid]),
  planItem(CarePlanTask.bottle, '13:00', who: [lan.uid]),
  planItem(CarePlanTask.sleep, '14:00'),
  planItem(CarePlanTask.bath, '18:30', who: [minh.uid, mai.uid]),
  planItem(CarePlanTask.read, '20:00', who: [minh.uid]),
  planItem(CarePlanTask.custom, '20:30', title: 'Ru con ngủ', who: [minh.uid]),
]);

/// 04b: the morning partly done (Cô Lan did two, Ba did one Mẹ was down for), one skipped.
List<CarePlanItem> planUnderway() {
  final items = planFresh();
  CarePlanItem at(String time) => items.firstWhere((i) => i.time == time);
  return sortedPlan([
    for (final i in items)
      if (i == at('07:00'))
        i.copyWith(status: CarePlanStatus.done, doneBy: minh.uid)
      else if (i == at('08:30') || i == at('10:30'))
        i.copyWith(status: CarePlanStatus.done, doneBy: lan.uid)
      else if (i == at('14:00'))
        i.copyWith(status: CarePlanStatus.skipped)
      else
        i,
  ]);
}

/// Records what the screen asked the plan Functions to do.
class FakeCarePlanRepository implements CarePlanRepository {
  final calls = <(String, Map<String, Object?>)>[];

  @override
  Future<void> startDay(String babyId, String date, String from) async =>
      calls.add(('start', {'date': date, 'from': from}));

  @override
  Future<void> saveItem(
    String babyId,
    String date, {
    required String itemId,
    required CarePlanTask task,
    required String? title,
    required String time,
    required List<String> assignees,
    required bool everyDay,
    int? amountMl,
  }) async => calls.add((
    'save',
    {
      'amountMl': ?amountMl,
      'itemId': itemId,
      'task': task.name,
      'title': title,
      'time': time,
      'assignees': assignees,
      'everyDay': everyDay,
    },
  ));

  @override
  Future<void> deleteItem(
    String babyId,
    String date,
    String itemId, {
    required bool everyDay,
  }) async => calls.add(('delete', {'itemId': itemId, 'everyDay': everyDay}));

  @override
  Future<void> assign(
    String babyId,
    String date,
    List<String> itemIds,
    List<String> assignees,
  ) async {
    calls.add(('assign', {'itemIds': itemIds, 'assignees': assignees}));
    await assignGate?.future;
  }

  /// Holds [assign] open until completed (the sheet's loading state).
  Completer<void>? assignGate;

  @override
  Future<void> setStatus(
    String babyId,
    String date,
    String itemId,
    CarePlanStatus status,
  ) async => calls.add(('status', {'itemId': itemId, 'status': status.name}));

  @override
  Future<void> savePrefs(String uid, CarePlanPrefs prefs) async => calls.add((
    'prefs',
    {'leadMinutes': prefs.leadMinutes, 'quietHours': prefs.quietHours},
  ));

  @override
  Future<void> publishDay(String babyId, String date) async =>
      calls.add(('publish', {'date': date}));

  @override
  Future<void> setAutoDraft(String babyId, {required bool on}) async =>
      calls.add(('autoDraft', {'on': on}));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The plan as the screen reads it: [days] by date (null = no plan that day), the everyday
/// count, this person's reminder [prefs], and [repo] for the calls. [drafts]: the dates whose
/// plan is a draft (D-136); [loggedDays]: how many days before today have a feed and a sleep
/// ("Theo nhịp của bé" needs 7), left to the care fixtures when null. With [familyOverrides],
/// pass it `carePlan: false`.
List<Override> carePlanOverrides({
  Map<String, List<CarePlanItem>?> days = const {},
  int everyday = 0,
  FakeCarePlanRepository? repo,
  CarePlanPrefs prefs = const CarePlanPrefs(),
  Set<String> drafts = const {},
  int? loggedDays,
  CarePlanFamilySettings family = const CarePlanFamilySettings(),
  List<CarePlanChange>? history,
}) => [
  carePlanHistoryProvider.overrideWith(
    (ref, k) => Stream.value(history ?? planHistory()),
  ),
  carePlanFamilySettingsProvider.overrideWith(
    (ref, babyId) => Stream.value(family),
  ),
  if (loggedDays != null)
    dayMarksProvider.overrideWith(
      (ref, key) => Stream.value({
        for (var i = 1; i <= loggedDays; i++)
          carePlanDateKey(
            DateTime.parse(key.$3).subtract(Duration(days: i - 1)),
          ): const DayMarks(
            feeds: true,
            sleep: true,
            diapers: false,
            other: false,
          ),
      }),
    ),
  carePlanPrefsProvider.overrideWith((ref, uid) => Stream.value(prefs)),
  carePlanRepositoryProvider.overrideWithValue(
    repo ?? FakeCarePlanRepository(),
  ),
  carePlanDayProvider.overrideWith(
    (ref, k) => Stream.value(
      days[k.$2] == null
          ? null
          : CarePlanDay(
              date: k.$2,
              revision: 1,
              source: drafts.contains(k.$2) ? 'rhythm' : 'empty',
              draft: drafts.contains(k.$2),
            ),
    ),
  ),
  carePlanItemsProvider.overrideWith(
    (ref, k) => Stream.value([
      for (final i in days[k.$2] ?? const <CarePlanItem>[])
        drafts.contains(k.$2) ? i.asDraft() : i,
    ]),
  ),
  carePlanEverydayCountProvider.overrideWith(
    (ref, babyId) => Stream.value(everyday),
  ),
];

extension CarePlanItemDraft on CarePlanItem {
  /// The same task inside a draft day (D-136).
  CarePlanItem asDraft() => CarePlanItem(
    id: id,
    task: task,
    title: title,
    time: time,
    assignees: assignees,
    status: status,
    templateId: templateId,
    doneBy: doneBy,
    doneAt: doneAt,
    draft: true,
    amountMl: amountMl,
  );
}

/// The plan history of the week to 28/10 (newest first): every day Ba bathes Teddy, Bà nội Hoa
/// reads, Mẹ gives the vitamin and Cô Lan the feeds and diapers, all on time; and this week's
/// changes (Mẹ moved a feed, Ba added "Đọc sách" every day, Mẹ gave the morning to Cô Lan).
List<CarePlanChange> planHistory() {
  final out = <CarePlanChange>[];
  var n = 0;
  CarePlanChange ch(
    String date,
    String time,
    String by,
    String action, {
    CarePlanTask? task,
    String? oldTime,
    String? scope,
    List<String>? assignees,
    List<String>? ids,
    String? from,
    int lateMin = 0,
  }) {
    final d = DateTime.parse(date);
    final p = time.split(':');
    // Hồ Chí Minh is UTC+7.
    final at = DateTime.utc(
      d.year,
      d.month,
      d.day,
      int.parse(p.first) - 7,
      int.parse(p.last) + lateMin,
    );
    return CarePlanChange(
      id: 'h${++n}',
      at: at,
      by: by,
      action: action,
      date: date,
      itemIds: ids ?? ['pi_$date$time$action'],
      task: task,
      time: time,
      oldTime: oldTime,
      scope: scope,
      assignees: assignees,
      from: from,
    );
  }

  for (var day = 22; day <= 28; day++) {
    final date = '2026-10-$day';
    if (day < 28) {
      out
        ..add(ch(date, '18:30', minh.uid, 'done', task: CarePlanTask.bath))
        ..add(ch(date, '20:00', hoa.uid, 'done', task: CarePlanTask.read))
        ..add(ch(date, '13:00', lan.uid, 'done', task: CarePlanTask.bottle))
        ..add(ch(date, '15:30', lan.uid, 'done', task: CarePlanTask.diaper));
    }
    out
      ..add(ch(date, '07:00', mai.uid, 'done', task: CarePlanTask.bottle))
      ..add(ch(date, '09:00', mai.uid, 'done', task: CarePlanTask.vitamin))
      ..add(ch(date, '08:30', lan.uid, 'done', task: CarePlanTask.sleep));
  }
  out
    ..add(
      ch(
        '2026-10-28',
        '06:30',
        mai.uid,
        'start',
        from: 'rhythm',
        ids: const [],
      ),
    )
    ..add(
      ch(
        '2026-10-28',
        '07:05',
        mai.uid,
        'assign',
        assignees: [lan.uid],
        ids: const ['a', 'b', 'c'],
      ),
    )
    ..add(
      ch(
        '2026-10-28',
        '08:40',
        minh.uid,
        'add',
        task: CarePlanTask.read,
        scope: 'everyDay',
      ),
    )
    ..add(
      ch(
        '2026-10-28',
        '13:30',
        mai.uid,
        'edit',
        task: CarePlanTask.bottle,
        oldTime: '13:00',
        lateMin: -200,
      ),
    )
    ..add(
      ch(
        '2026-10-27',
        '15:30',
        mai.uid,
        'delete',
        task: CarePlanTask.diaper,
        scope: 'today',
      ),
    );
  out.sort((a, b) => b.at.compareTo(a.at));
  return out;
}
