import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/care_plan/care_plan_report_calc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';

/// Wall-clock time in Hồ Chí Minh (UTC+7), as `inBabyZone` gives it.
DateTime _vn(DateTime t) {
  final u = t.toUtc().add(const Duration(hours: 7));
  return DateTime(u.year, u.month, u.day, u.hour, u.minute);
}

void main() {
  final today = DateTime(2026, 10, 28);

  test('a later "undone" takes a done task back', () {
    CarePlanChange c(String action, int minute) => CarePlanChange(
      id: '$action$minute',
      at: DateTime.utc(2026, 10, 28, 0, minute),
      by: mai.uid,
      action: action,
      date: carePlanToday,
      itemIds: const ['x'],
      task: CarePlanTask.bath,
      time: '07:00',
    );
    // Newest first.
    expect(carePlanDoneOf([c('undone', 5), c('done', 1)], _vn), isEmpty);
    expect(carePlanDoneOf([c('done', 9), c('undone', 5)], _vn), hasLength(1));
  });

  test('a week of the fixture: share, streak, on rhythm and badges', () {
    final done = carePlanDoneOf(planHistory(), _vn);
    final week = [
      for (final d in done)
        if (d.date.compareTo('2026-10-26') >= 0) d,
    ];
    final r = CarePlanReport(week, today: today, streakFrom: done);
    expect(r.total, 17);
    expect(r.byPerson.first, (lan.uid, 7));
    expect(r.percents.fold<int>(0, (s, e) => s + e.$2), 100);
    expect(r.streak, 7);
    expect(r.onTimePercent, 100);
    final badges = {
      for (final (b, who) in carePlanBadges(done, [mai, minh, lan, hoa], today))
        b: who,
    };
    expect(badges[CarePlanBadge.bath], minh.uid);
    expect(badges[CarePlanBadge.story], hoa.uid);
    expect(badges[CarePlanBadge.grand], hoa.uid);
    expect(badges[CarePlanBadge.team], '');
    expect(badges[CarePlanBadge.night], isNull);
  });

  test('on rhythm is within 30 minutes of the planned time', () {
    CarePlanDone d(int h, int m) => CarePlanDone(
      itemId: 'x',
      date: carePlanToday,
      by: mai.uid,
      at: DateTime(2026, 10, 28, h, m),
      task: CarePlanTask.bottle,
      time: '07:00',
    );
    expect(d(7, 30).onTime, isTrue);
    expect(d(7, 31).onTime, isFalse);
    expect(d(6, 30).onTime, isTrue);
  });
}
