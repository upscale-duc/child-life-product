import '../baby/baby_models.dart';
import 'care_plan_models.dart';

/// A task done, as the plan history last says (a later "undone" takes it back).
class CarePlanDone {
  const CarePlanDone({
    required this.itemId,
    required this.date,
    required this.by,
    required this.at,
    required this.task,
    required this.time,
  });

  final String itemId;

  /// The plan day ("2026-10-28") and the task's planned time ("07:00").
  final String date;
  final String? time;
  final String by;

  /// When it was ticked, as wall-clock time in the baby's zone.
  final DateTime at;
  final CarePlanTask? task;

  /// Within 30 minutes of its planned time ("đúng nhịp").
  bool get onTime {
    final t = time;
    if (t == null) return false;
    final p = t.split(':');
    final d = DateTime.parse(date);
    final planned = DateTime(
      d.year,
      d.month,
      d.day,
      int.tryParse(p.first) ?? 0,
      int.tryParse(p.last) ?? 0,
    );
    return at.difference(planned).inMinutes.abs() <= 30;
  }
}

/// The tasks done, from [changes] (newest first) of the plan history; [local] turns an instant
/// into the baby's wall-clock time.
List<CarePlanDone> carePlanDoneOf(
  List<CarePlanChange> changes,
  DateTime Function(DateTime) local,
) {
  final seen = <String>{};
  final out = <CarePlanDone>[];
  for (final c in changes) {
    if (c.action != 'done' && c.action != 'undone') continue;
    for (final id in c.itemIds) {
      if (!seen.add('${c.date}/$id')) continue;
      if (c.action == 'done') {
        out.add(
          CarePlanDone(
            itemId: id,
            date: c.date,
            by: c.by,
            at: local(c.at),
            task: c.task,
            time: c.time,
          ),
        );
      }
    }
  }
  return out;
}

/// 11's numbers for a range: how many, by whom, days in a row and on rhythm.
class CarePlanReport {
  /// [streakFrom]: the tasks "ngày liền" counts back through (more days than the range).
  CarePlanReport(
    List<CarePlanDone> done, {
    required DateTime today,
    List<CarePlanDone>? streakFrom,
  }) : total = done.length,
       byPerson = _count(done),
       onTimePercent = done.isEmpty
           ? 0
           : (done.where((d) => d.onTime).length * 100 / done.length).round(),
       streak = _streak(streakFrom ?? done, today);

  final int total;

  /// uid → tasks done, most first.
  final List<(String, int)> byPerson;
  final int onTimePercent;
  final int streak;

  static List<(String, int)> _count(List<CarePlanDone> done) {
    final m = <String, int>{};
    for (final d in done) {
      m[d.by] = (m[d.by] ?? 0) + 1;
    }
    return m.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  /// Days in a row up to today (or yesterday, while today has nothing yet) with a task done.
  static int _streak(List<CarePlanDone> done, DateTime today) {
    final days = {for (final d in done) d.date};
    var day = DateTime(today.year, today.month, today.day);
    if (!days.contains(carePlanDateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (days.contains(carePlanDateKey(day))) {
      n += 1;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  /// Whole percentages per person that add up to 100 (largest remainder).
  List<(String, int)> get percents {
    if (total == 0) return const [];
    final raw = [for (final (u, n) in byPerson) (u, n * 100 / total)];
    final floors = [for (final (u, p) in raw) (u, p.floor())];
    var left = 100 - floors.fold<int>(0, (s, e) => s + e.$2);
    final order = [for (var i = 0; i < raw.length; i++) i]
      ..sort(
        (a, b) => (raw[b].$2 - raw[b].$2.floor()).compareTo(
          raw[a].$2 - raw[a].$2.floor(),
        ),
      );
    final out = [...floors];
    for (final i in order) {
      if (left == 0) break;
      out[i] = (out[i].$1, out[i].$2 + 1);
      left -= 1;
    }
    return out;
  }
}

/// The badges of 11 / 12. Rules are engineering drafts for owner review (D-138).
enum CarePlanBadge {
  bath,
  night,
  story,
  bottle,
  diaper,
  grand,
  onTime,
  team,
  vitamin,
}

/// Draft thresholds for a week (D-138, owner review).
abstract final class CarePlanBadgeRules {
  static const bath = 3;
  static const night = 3;
  static const story = 3;
  static const feeds = 10;
  static const diapers = 10;
  static const grand = 5;
  static const onTimeDays = 7;
  static const onTimeShare = 80;
  static const teamPeople = 3;
  static const teamEach = 3;
  static const vitaminDays = 5;
}

/// A badge and who earned it: a uid, '' for the whole family, or null while it is locked.
typedef CarePlanBadgeResult = (CarePlanBadge, String?);

/// The last 7 days' badges ("Huy hiệu tuần này") from their tasks done. A person's badge goes to whoever did the most of it.
List<CarePlanBadgeResult> carePlanBadges(
  List<CarePlanDone> week,
  List<Membership> members,
  DateTime today,
) {
  String? leader(bool Function(CarePlanDone) f, int min) {
    final m = <String, int>{};
    for (final d in week.where(f)) {
      m[d.by] = (m[d.by] ?? 0) + 1;
    }
    final top = m.entries.where((e) => e.value >= min).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return top.firstOrNull?.key;
  }

  bool task(CarePlanDone d, Set<CarePlanTask> t) => t.contains(d.task);
  final grandparents = {
    for (final m in members)
      if (m.relation == Relation.grandmother ||
          m.relation == Relation.grandfather)
        m.uid,
  };

  // On rhythm all week: each of the last 7 days has a task, and most were on time.
  final last7 = [
    for (var i = 0; i < CarePlanBadgeRules.onTimeDays; i++)
      carePlanDateKey(DateTime(today.year, today.month, today.day - i)),
  ];
  final inLast7 = week.where((d) => last7.contains(d.date)).toList();
  final everyDay = last7.every((k) => inLast7.any((d) => d.date == k));
  final onTime =
      everyDay &&
      inLast7.where((d) => d.onTime).length * 100 >=
          CarePlanBadgeRules.onTimeShare * inLast7.length;

  final perPerson = <String, int>{};
  for (final d in week) {
    perPerson[d.by] = (perPerson[d.by] ?? 0) + 1;
  }
  final team =
      perPerson.values.where((n) => n >= CarePlanBadgeRules.teamEach).length >=
      CarePlanBadgeRules.teamPeople;
  final vitaminDays = {
    for (final d in week)
      if (d.task == CarePlanTask.vitamin) d.date,
  }.length;

  return [
    (
      CarePlanBadge.bath,
      leader((d) => task(d, {CarePlanTask.bath}), CarePlanBadgeRules.bath),
    ),
    (
      CarePlanBadge.night,
      leader((d) => d.at.hour >= 22 || d.at.hour < 5, CarePlanBadgeRules.night),
    ),
    (
      CarePlanBadge.story,
      leader((d) => task(d, {CarePlanTask.read}), CarePlanBadgeRules.story),
    ),
    (
      CarePlanBadge.bottle,
      leader(
        (d) => task(d, {CarePlanTask.bottle, CarePlanTask.breast}),
        CarePlanBadgeRules.feeds,
      ),
    ),
    (
      CarePlanBadge.diaper,
      leader((d) => task(d, {CarePlanTask.diaper}), CarePlanBadgeRules.diapers),
    ),
    (
      CarePlanBadge.grand,
      leader((d) => grandparents.contains(d.by), CarePlanBadgeRules.grand),
    ),
    (CarePlanBadge.onTime, onTime ? '' : null),
    (CarePlanBadge.team, team ? '' : null),
    (
      CarePlanBadge.vitamin,
      vitaminDays >= CarePlanBadgeRules.vitaminDays ? '' : null,
    ),
  ];
}
