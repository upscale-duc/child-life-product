import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../care/care_models.dart' show CareType;
import '../care/care_sheets.dart' show lastSavedProvider, openCareLog;
import '../care/timer_models.dart' show TimerType;
import '../care/timer_screens.dart' show openOrStartTimer;
import 'care_plan_models.dart';

/// D-138: Cùng Chăm Con and Care are one record. The care log a finished task writes: a bottle,
/// a breastfeed, pumping or a diaper; null for tasks that are only a row of the day in Lịch sử.
CareType? carePlanLogType(CarePlanTask t) => switch (t) {
  CarePlanTask.bottle => CareType.bottle,
  CarePlanTask.breast => CareType.breast,
  CarePlanTask.pump => CareType.pump,
  CarePlanTask.diaper => CareType.diaper,
  _ => null,
};

/// Finishing [item] writes its care log first (D-138): its sheet opens, "Bú bình" prefilled with
/// the planned ml, and the task is done only when the log was saved. "Ngủ" starts the sleep
/// timer. Other tasks need nothing. True when the task should now be marked done.
Future<bool> carePlanLogFor(
  BuildContext context,
  WidgetRef ref,
  CarePlanItem item,
) async {
  if (item.task == CarePlanTask.sleep) {
    openOrStartTimer(context, TimerType.sleep);
    return true;
  }
  final type = carePlanLogType(item.task);
  if (type == null) return true;
  final before = ref.read(lastSavedProvider);
  await openCareLog(context, type, amountMl: item.amountMl);
  final after = ref.read(lastSavedProvider);
  return after != before && after?.$1 == type;
}
