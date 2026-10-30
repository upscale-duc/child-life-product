import 'package:child_life/features/care_plan/care_plan_models.dart';
import 'package:child_life/features/glance/glance_plan.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_plan_fixtures.dart';
import '../helpers/family_fixtures.dart';

// Cùng Chăm Con widgets (Figma 1356:23340): the plan the widgets draw from the glance snapshot.
final _l = lookupAppLocalizations(const Locale('vi'));
const _day = CarePlanDay(date: carePlanToday, revision: 1, source: 'empty');

Map<String, Object?>? _plan({
  dynamic me,
  CarePlanDay? day = _day,
  List<CarePlanItem>? items,
}) => glancePlanJson(
  l10n: _l,
  me: me ?? minh,
  zone: 'Asia/Ho_Chi_Minh',
  date: carePlanToday,
  day: day,
  items: items ?? planUnderway(),
  members: [mai, minh, lan],
);

void main() {
  test(
    'Ba: his tasks marked, skipped ones left out, "Xong" opens the app for logs',
    () {
      final plan = _plan()!;
      final items = (plan['items']! as List).cast<Map<String, Object?>>();
      expect(plan['me'], 'Ba');
      expect(plan['helper'], isFalse);
      expect(items.any((i) => i['time'] == '14:00'), isFalse);
      final vitamin = items.firstWhere((i) => i['task'] == 'vitamin');
      expect(vitamin, containsPair('mine', true));
      expect(vitamin, containsPair('opensApp', false));
      // 09:00 in Hồ Chí Minh.
      expect(
        vitamin['dueAt'],
        DateTime.utc(2026, 10, 28, 2).millisecondsSinceEpoch,
      );
      final bottle = items.firstWhere((i) => i['time'] == '07:00');
      expect(bottle, containsPair('opensApp', true));
      expect(bottle['name'], contains('120 ml'));
      expect(
        plan['faces'],
        containsAll(<String>['PersonMe', 'PersonBa', 'PersonHelper']),
      );
    },
  );

  test('Cô Lan is a helper; no plan for a draft, no day, or a relative', () {
    expect(_plan(me: lan)!['helper'], isTrue);
    expect(_plan(me: lan)!['me'], 'Cô Lan');
    expect(
      _plan(
        day: const CarePlanDay(
          date: carePlanToday,
          revision: 1,
          source: 'rhythm',
          draft: true,
        ),
      ),
      isNull,
    );
    expect(_plan(day: null), isNull);
    expect(_plan(me: hoa), isNull);
  });
}
