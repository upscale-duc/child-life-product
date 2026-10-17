import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/reference/reference_repository.dart';
import 'package:child_life/features/care/growth_reference.dart';
import 'package:child_life/features/care/who_growth.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';
import 'package:child_life/features/vaccines/vaccine_reference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P-138 (Figma C01, C03): growth and vaccine tables approved on the portal reach the app from
/// `publicConfig/reference_*`, validated, with the bundled tables as the fallback.

/// Rows like the builtin v1 (contracts `who-reference.g.ts`): P3 / median / P97 from today's
/// LMS at weeks 0–13 and months 0–60, rounded to 2 decimals, scaled by [scale].
List<Map<String, Object>> _rows(GrowthMeasure m, {double scale = 1}) {
  double r2(double v) => (v * scale * 100).round() / 100;
  return [
    for (final boy in [true, false])
      for (final (unit, ages) in [
        ('week', [for (var w = 0; w <= 13; w++) w]),
        ('month', [for (var mo = 0; mo <= 60; mo++) mo]),
      ])
        for (final age in ages)
          () {
            final day = unit == 'week' ? age * 7 : (age * 30.4375).round();
            final r = WhoGrowth.range(m, boy: boy, ageDays: day)!;
            return <String, Object>{
              'sex': boy ? 'boy' : 'girl',
              'unit': unit,
              'age': age,
              'low': r2(r.low),
              'median': r2(r.median),
              'high': r2(r.high),
            };
          }(),
  ];
}

Map<String, dynamic> _growthDoc(
  GrowthMeasure m, {
  List<Map<String, Object>>? rows,
  String version = 'v2026.10',
}) => {
  'dataset': m == GrowthMeasure.weight ? 'growth.weight' : 'growth.length',
  'version': version,
  'publishedAt': '2026-10-17T08:00:00.000Z',
  'rows': rows ?? _rows(m),
};

Map<String, dynamic> _vaccineDoc({
  List<Map<String, Object?>>? rows,
  String version = 'v2026.10',
}) => {
  ...VaccineScheduleTable.bundled.toJson(),
  'version': version,
  'publishedAt': '2026-10-17T08:00:00.000Z',
  'rows': ?rows,
};

class _FakeReference extends ReferenceRepository {
  _FakeReference(SharedPreferences prefs)
    : super(() => throw StateError('no Firebase in tests'), prefs);

  final published = <String, Map<String, dynamic>?>{};
  var offline = false;

  @override
  Future<Map<String, dynamic>?> read(String docId) async {
    if (offline) throw Exception('unavailable');
    return published[docId];
  }
}

void main() {
  group('growth tables', () {
    test('a v1-like table gives the bundled LMS results', () {
      for (final m in [GrowthMeasure.weight, GrowthMeasure.length]) {
        final table = GrowthTable.parse(m, _growthDoc(m))!;
        final reference = m == GrowthMeasure.weight
            ? GrowthReference(weight: table)
            : GrowthReference(length: table);
        for (final boy in [true, false]) {
          for (var d = 0; d <= 1826; d += 7) {
            final lms = WhoGrowth.range(m, boy: boy, ageDays: d)!;
            final t = reference.range(m, boy: boy, ageDays: d)!;
            expect(t.median, closeTo(lms.median, lms.median * 0.01));
            expect(t.low, closeTo(lms.low, lms.low * 0.01));
            expect(t.high, closeTo(lms.high, lms.high * 0.01));
          }
        }
      }
    });

    test('a published table moves the band and the verdict', () {
      final table = GrowthTable.parse(
        GrowthMeasure.weight,
        _growthDoc(
          GrowthMeasure.weight,
          rows: _rows(GrowthMeasure.weight, scale: 1.2),
        ),
      )!;
      final reference = GrowthReference(weight: table);
      final lms = WhoGrowth.range(
        GrowthMeasure.weight,
        boy: true,
        ageDays: 61,
      )!;
      final r = reference.range(GrowthMeasure.weight, boy: true, ageDays: 61)!;
      expect(r.median, closeTo(lms.median * 1.2, 0.05));
      // A weight just inside the bundled band is below a band 20 % higher.
      expect(
        GrowthReference.bundled.band(
          GrowthMeasure.weight,
          boy: true,
          ageDays: 61,
          value: lms.low * 1.1,
        ),
        GrowthBand.normal,
      );
      expect(
        reference.band(
          GrowthMeasure.weight,
          boy: true,
          ageDays: 61,
          value: lms.low * 1.1,
        ),
        GrowthBand.below,
      );
      // Length and head circumference stay on the bundled tables.
      expect(
        reference.range(GrowthMeasure.head, boy: true, ageDays: 61),
        WhoGrowth.range(GrowthMeasure.head, boy: true, ageDays: 61),
      );
      expect(
        reference.range(GrowthMeasure.length, boy: true, ageDays: 61),
        WhoGrowth.range(GrowthMeasure.length, boy: true, ageDays: 61),
      );
    });

    test('ages the table does not cover fall back to the bundled tables', () {
      final shortRows = _rows(
        GrowthMeasure.weight,
      ).where((r) => r['unit'] == 'week').toList();
      final reference = GrowthReference(
        weight: GrowthTable.parse(
          GrowthMeasure.weight,
          _growthDoc(GrowthMeasure.weight, rows: shortRows),
        ),
      );
      expect(
        reference.range(GrowthMeasure.weight, boy: false, ageDays: 400),
        WhoGrowth.range(GrowthMeasure.weight, boy: false, ageDays: 400),
      );
    });

    test('invalid tables are refused', () {
      const m = GrowthMeasure.weight;
      final good = _rows(m);
      Map<String, Object> bad(Map<String, Object> change) => {
        ...good.first,
        ...change,
      };
      expect(GrowthTable.parse(m, _growthDoc(m)), isNotNull);
      for (final doc in <Object?>[
        null,
        {..._growthDoc(m), 'dataset': 'growth.length'},
        {..._growthDoc(m), 'version': '2026.10'},
        {..._growthDoc(m), 'publishedAt': null},
        _growthDoc(m, rows: []),
        _growthDoc(m, rows: [...good, good.first]),
        _growthDoc(
          m,
          rows: [
            bad({'low': 9.0, 'median': 4.0}),
          ],
        ),
        _growthDoc(
          m,
          rows: [
            bad({'sex': 'other'}),
          ],
        ),
        _growthDoc(
          m,
          rows: [
            bad({'unit': 'day'}),
          ],
        ),
        _growthDoc(
          m,
          rows: [
            bad({'age': 61}),
          ],
        ),
        _growthDoc(
          m,
          rows: [
            bad({'age': 1.5}),
          ],
        ),
      ]) {
        expect(GrowthTable.parse(m, doc), isNull, reason: '$doc');
      }
      expect(GrowthTable.parse(GrowthMeasure.head, _growthDoc(m)), isNull);
    });

    test('JSON round trip', () {
      const m = GrowthMeasure.length;
      final table = GrowthTable.parse(m, _growthDoc(m))!;
      final again = GrowthTable.parse(m, table.toJson())!;
      expect(again.version, table.version);
      expect(again.rows.length, table.rows.length);
      expect(
        again.range(boy: true, ageDays: 200),
        table.range(boy: true, ageDays: 200),
      );
    });
  });

  group('vaccine schedule', () {
    test('the bundled schedule survives a publish round trip', () {
      final table = VaccineScheduleTable.parse(_vaccineDoc())!;
      expect(table.defs.length, VaccineScheduleTable.bundled.defs.length);
      for (final (i, d) in table.defs.indexed) {
        final b = VaccineScheduleTable.bundled.defs[i];
        expect(
          VaccineScheduleTable.rowJson(d),
          VaccineScheduleTable.rowJson(b),
        );
      }
    });

    test('the book follows the published schedule', () {
      final rows = [
        for (final d in VaccineScheduleTable.bundled.defs)
          if (d.id == 'bcg')
            {
              ...VaccineScheduleTable.rowJson(d),
              'months': [1],
            }
          else
            VaccineScheduleTable.rowJson(d),
      ];
      final table = VaccineScheduleTable.parse(_vaccineDoc(rows: rows))!;
      final book = VaccineBook.of(
        dob: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 10),
        plan: const VaccinePlan(),
        records: const {},
        schedule: table.defs,
      );
      expect(book.rowOf('bcg').single.months, 1);
      expect(vaccineById('bcg', book.schedule)!.months, [1]);
    });

    test('invalid schedules are refused', () {
      final good = VaccineScheduleTable.rowJson(
        VaccineScheduleTable.bundled.defs.first,
      );
      Map<String, Object?> bad(Map<String, Object?> change) => {
        ...good,
        ...change,
      };
      for (final doc in <Object?>[
        null,
        {..._vaccineDoc(), 'dataset': 'bottle.quickPicks'},
        {..._vaccineDoc(), 'version': 'v1'},
        _vaccineDoc(rows: []),
        _vaccineDoc(rows: [good, good]),
        _vaccineDoc(
          rows: [
            bad({'id': 'BCG'}),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({'programme': 'free'}),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({'route': 'nasal'}),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({
              'months': [2, 2],
            }),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({
              'months': [73],
            }),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({'name': 'BCG'}),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({'yearly': 'yes'}),
          ],
        ),
        _vaccineDoc(
          rows: [
            bad({'minIntervalWeeks': 0}),
          ],
        ),
      ]) {
        expect(VaccineScheduleTable.parse(doc), isNull, reason: '$doc');
      }
    });
  });

  group('delivery (offline-first)', () {
    late SharedPreferences prefs;
    late _FakeReference reference;

    ProviderContainer start() {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          referenceRepositoryProvider.overrideWithValue(reference),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      reference = _FakeReference(prefs);
    });

    test('bundled until a valid version is read, then kept', () async {
      final first = start();
      expect(first.read(growthReferenceProvider).weight, isNull);
      expect(
        identical(
          first.read(vaccineScheduleProvider),
          VaccineScheduleTable.bundled,
        ),
        isTrue,
      );
      reference.published['reference_growth_weight'] = _growthDoc(
        GrowthMeasure.weight,
      );
      reference.published['reference_vaccines'] = _vaccineDoc();
      await first.read(growthReferenceProvider.notifier).refresh();
      await first.read(vaccineScheduleProvider.notifier).refresh();
      expect(first.read(growthReferenceProvider).weight!.version, 'v2026.10');
      expect(first.read(growthReferenceProvider).length, isNull);
      expect(first.read(vaccineScheduleProvider).version, 'v2026.10');

      // Next launch, offline: the cached copies at once, kept when the read fails.
      reference.offline = true;
      final second = start();
      await second.read(growthReferenceProvider.notifier).refresh();
      await second.read(vaccineScheduleProvider.notifier).refresh();
      expect(second.read(growthReferenceProvider).weight!.version, 'v2026.10');
      expect(second.read(vaccineScheduleProvider).version, 'v2026.10');
    });

    test('an invalid version goes back to the bundled tables', () async {
      reference.published['reference_growth_weight'] = _growthDoc(
        GrowthMeasure.weight,
      );
      final c = start();
      await c.read(growthReferenceProvider.notifier).refresh();
      expect(c.read(growthReferenceProvider).weight, isNotNull);

      reference.published['reference_growth_weight'] = _growthDoc(
        GrowthMeasure.weight,
        rows: [],
      );
      reference.published['reference_vaccines'] = _vaccineDoc(rows: []);
      await c.read(growthReferenceProvider.notifier).refresh();
      await c.read(vaccineScheduleProvider.notifier).refresh();
      expect(c.read(growthReferenceProvider).weight, isNull);
      expect(prefs.getString('reference.reference_growth_weight'), isNull);
      expect(
        identical(
          c.read(vaccineScheduleProvider),
          VaccineScheduleTable.bundled,
        ),
        isTrue,
      );
    });
  });
}
