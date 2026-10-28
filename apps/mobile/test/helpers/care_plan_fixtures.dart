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
}) => CarePlanItem(
  id: 'pi_${(++_seq).toRadixString(16).padLeft(32, '0')}',
  task: task,
  title: title,
  time: time,
  assignees: who,
  status: status,
  doneBy: doneBy,
  templateId: everyDay ? 'pt_${_seq.toRadixString(16).padLeft(32, '0')}' : null,
);

/// 04: ten tasks, nothing done yet (Mai = Mẹ, Minh = Ba, Lan = Cô Lan).
List<CarePlanItem> planFresh() => sortedPlan([
  planItem(CarePlanTask.bottle, '07:00', who: [mai.uid], everyDay: true),
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
  }) async => calls.add((
    'save',
    {
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
  ) async =>
      calls.add(('assign', {'itemIds': itemIds, 'assignees': assignees}));

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The plan as the screen reads it: [days] by date (null = no plan that day), the everyday
/// count, this person's reminder [prefs], and [repo] for the calls. With [familyOverrides], pass
/// it `carePlan: false`.
List<Override> carePlanOverrides({
  Map<String, List<CarePlanItem>?> days = const {},
  int everyday = 0,
  FakeCarePlanRepository? repo,
  CarePlanPrefs prefs = const CarePlanPrefs(),
}) => [
  carePlanPrefsProvider.overrideWith((ref, uid) => Stream.value(prefs)),
  carePlanRepositoryProvider.overrideWithValue(
    repo ?? FakeCarePlanRepository(),
  ),
  carePlanDayProvider.overrideWith(
    (ref, k) => Stream.value(
      days[k.$2] == null
          ? null
          : CarePlanDay(date: k.$2, revision: 1, source: 'empty'),
    ),
  ),
  carePlanItemsProvider.overrideWith(
    (ref, k) => Stream.value(days[k.$2] ?? const []),
  ),
  carePlanEverydayCountProvider.overrideWith(
    (ref, babyId) => Stream.value(everyday),
  ),
];
