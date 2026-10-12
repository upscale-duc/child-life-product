import 'dart:convert';

import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/reference/reference_repository.dart';
import 'package:child_life/features/care/bottle_suggestions.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/router_pump.dart';

/// P-138 (Figma C02): bottle quick picks from `publicConfig/reference_bottle`, validated, with
/// the bundled P-126 table as the fallback.

/// The table the app shipped before the portal (P-126), as it was written.
List<int> _shipped(int? ageDays) {
  if (ageDays == null) return const [60, 90, 120, 150];
  if (ageDays < 7) return const [30, 45, 60, 75];
  if (ageDays < 28) return const [60, 90, 120, 150];
  if (ageDays < 61) return const [90, 120, 150, 180];
  if (ageDays < 122) return const [120, 150, 180, 210];
  return const [150, 180, 210, 240];
}

Map<String, dynamic> _published({
  List<Map<String, dynamic>>? rows,
  String version = 'v2026.10',
}) => {
  'dataset': 'bottle.quickPicks',
  'version': version,
  'publishedAt': '2026-10-10T08:00:00.000Z',
  'rows':
      rows ??
      [
        {
          'fromDay': 0,
          'toDay': 14,
          'picks': [20, 30, 45, 60],
          'stepMl': 5,
        },
        {
          'fromDay': 14,
          'toDay': 61,
          'picks': [70, 100, 130, 160],
          'stepMl': 10,
        },
        {
          'fromDay': 61,
          'toDay': null,
          'picks': [120, 150, 180, 210],
          'stepMl': 15,
        },
      ],
};

Map<String, dynamic> _row(
  int fromDay,
  int? toDay, [
  List<Object> picks = const [60, 90, 120, 150],
  Object stepMl = 10,
]) => {'fromDay': fromDay, 'toDay': toDay, 'picks': picks, 'stepMl': stepMl};

/// Serves [published] (or fails, like offline with nothing cached) instead of Firestore.
class _FakeReference extends ReferenceRepository {
  _FakeReference(SharedPreferences prefs)
    : super(() => throw StateError('no Firebase in tests'), prefs);

  Map<String, dynamic>? published;
  var offline = false;
  var reads = 0;

  @override
  Future<Map<String, dynamic>?> read(String docId) async {
    reads++;
    expect(docId, 'reference_bottle');
    if (offline) throw Exception('unavailable');
    return published;
  }
}

class _Host extends StatelessWidget {
  const _Host(this.open);
  final void Function(BuildContext) open;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  group('bundled table (version 1 = P-126)', () {
    test('equals what the app shipped, for every age', () {
      expect(bottleSuggestions(null), _shipped(null));
      for (var day = -3; day <= 800; day++) {
        expect(bottleSuggestions(day), _shipped(day), reason: 'day $day');
      }
    });

    test('steps: 5 ml the first week, 10 ml after; 10 without an age', () {
      expect(bottleStepMl(0), 5);
      expect(bottleStepMl(6), 5);
      expect(bottleStepMl(7), 10);
      expect(bottleStepMl(400), 10);
      expect(bottleStepMl(null), 10);
    });
  });

  group('published table', () {
    test('a valid table replaces the picks and the step', () {
      final table = BottleTable.parse(_published())!;
      expect(table.version, 'v2026.10');
      expect(bottleSuggestions(3, table), [20, 30, 45, 60]);
      expect(bottleSuggestions(13, table), [20, 30, 45, 60]);
      expect(bottleSuggestions(14, table), [
        70,
        100,
        130,
        160,
      ], reason: '[from, to)');
      expect(bottleSuggestions(900, table), [120, 150, 180, 210]);
      expect(bottleStepMl(900, table), 15);
      // No date of birth: the band that holds three weeks.
      expect(bottleSuggestions(null, table), [70, 100, 130, 160]);
    });

    test('rows may come unsorted and as whole doubles', () {
      final table = BottleTable.parse(
        _published(
          rows: [
            _row(28, null, [90.0, 120, 150, 180]),
            _row(0, 28, [30, 45, 60, 75], 5.0),
          ],
        ),
      )!;
      expect(table.bands.map((b) => b.fromDay), [0, 28]);
      expect(bottleSuggestions(40, table), [90, 120, 150, 180]);
      expect(bottleStepMl(1, table), 5);
    });

    test('an age the table does not cover uses the bundled band', () {
      final table = BottleTable.parse(
        _published(
          rows: [
            _row(0, 7, [30, 45, 60, 75], 5),
            _row(28, null),
          ],
        ),
      )!;
      expect(bottleSuggestions(10, table), _shipped(10));
      expect(bottleSuggestions(30, table), [60, 90, 120, 150]);
    });

    test('anything off falls back to the bundled table', () {
      Map<String, dynamic> withField(String key, Object? value) =>
          {..._published(), key: value}..removeWhere((k, v) => v == #remove);
      final invalid = <String, Object?>{
        'not a map': 'rows',
        'wrong dataset': withField('dataset', 'growth.weight'),
        'bad version': withField('version', '2026.10'),
        'no publishedAt': withField('publishedAt', #remove),
        'rows missing': withField('rows', #remove),
        'rows empty': withField('rows', <Object>[]),
        'rows not a list': withField('rows', {'0': _row(0, null)}),
        'three picks': _published(
          rows: [
            _row(0, null, [60, 90, 120]),
          ],
        ),
        'five picks': _published(
          rows: [
            _row(0, null, [30, 60, 90, 120, 150]),
          ],
        ),
        'not increasing': _published(
          rows: [
            _row(0, null, [60, 90, 90, 150]),
          ],
        ),
        'pick too small': _published(
          rows: [
            _row(0, null, [4, 30, 60, 90]),
          ],
        ),
        'pick too large': _published(
          rows: [
            _row(0, null, [120, 200, 300, 401]),
          ],
        ),
        'pick not whole': _published(
          rows: [
            _row(0, null, [60.5, 90, 120, 150]),
          ],
        ),
        'pick as text': _published(
          rows: [
            _row(0, null, ['60', 90, 120, 150]),
          ],
        ),
        'step 0': _published(
          rows: [
            _row(0, null, [60, 90, 120, 150], 0),
          ],
        ),
        'step 51': _published(
          rows: [
            _row(0, null, [60, 90, 120, 150], 51),
          ],
        ),
        'toDay before fromDay': _published(rows: [_row(10, 10)]),
        'toDay key missing': _published(
          rows: [
            {
              'fromDay': 0,
              'picks': [60, 90, 120, 150],
              'stepMl': 10,
            },
          ],
        ),
        'overlap': _published(rows: [_row(0, 30), _row(28, null)]),
        'two open-ended': _published(rows: [_row(0, null), _row(28, null)]),
        'same start': _published(rows: [_row(0, 28), _row(0, null)]),
        'too many rows': _published(
          rows: [for (var i = 0; i < 21; i++) _row(i, i + 1)],
        ),
      };
      for (final MapEntry(:key, :value) in invalid.entries) {
        expect(BottleTable.parse(value), isNull, reason: key);
      }
      expect(BottleTable.parse(null), isNull);
    });

    test('round-trips through its cached JSON', () {
      final table = BottleTable.parse(_published())!;
      final again = BottleTable.parse(jsonDecode(jsonEncode(table.toJson())))!;
      expect(again.version, table.version);
      expect(
        again.bands.map((b) => b.toJson()),
        table.bands.map((b) => b.toJson()),
      );
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

    test(
      'bundled until a valid version is read, then kept for the next start',
      () async {
        final first = start();
        expect(
          identical(first.read(bottleTableProvider), BottleTable.bundled),
          isTrue,
        );
        reference.published = _published();
        await first.read(bottleTableProvider.notifier).refresh();
        expect(first.read(bottleTableProvider).version, 'v2026.10');

        // Next launch, offline: the cached copy at once, kept when the read fails.
        reference.offline = true;
        final second = start();
        expect(second.read(bottleTableProvider).version, 'v2026.10');
        await second.read(bottleTableProvider.notifier).refresh();
        expect(second.read(bottleTableProvider).version, 'v2026.10');
        expect(bottleSuggestions(3, second.read(bottleTableProvider)), [
          20,
          30,
          45,
          60,
        ]);
      },
    );

    test(
      'an invalid or missing version goes back to the bundled table',
      () async {
        reference.published = _published();
        final c = start();
        await c.read(bottleTableProvider.notifier).refresh();
        expect(c.read(bottleTableProvider).version, 'v2026.10');

        reference.published = _published(rows: [_row(0, 30), _row(28, null)]);
        await c.read(bottleTableProvider.notifier).refresh();
        expect(
          identical(c.read(bottleTableProvider), BottleTable.bundled),
          isTrue,
        );
        expect(prefs.getString('reference.reference_bottle'), isNull);

        reference.published = null;
        await c.read(bottleTableProvider.notifier).refresh();
        expect(
          identical(c.read(bottleTableProvider), BottleTable.bundled),
          isTrue,
        );
      },
    );

    test('a corrupt cached copy is ignored', () {
      prefs.setString('reference.reference_bottle', '{"rows": 3');
      expect(
        identical(start().read(bottleTableProvider), BottleTable.bundled),
        isTrue,
      );
    });
  });

  testWidgets('22: the quick picks follow the published table', (tester) async {
    final table = BottleTable.parse(_published())!;
    await pumpRouted(
      tester,
      _Host((c) => openCareLog(c, CareType.bottle)),
      overrides: careOverrides(),
      prefs: {'reference.reference_bottle': jsonEncode(table.toJson())},
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Teddy is three weeks old: the 14–60 day band of v2026.10.
    expect(find.text('Gợi ý cho bé 3 tuần'), findsOneWidget);
    expect(find.text('60 ml', findRichText: true), findsNothing);
    for (final ml in const ['70', '100', '130', '160']) {
      expect(find.text('$ml ml', findRichText: true), findsOneWidget);
    }
    // The last amount still comes first (C02: "app ưu tiên hiện lượng lần trước").
    expect(find.text('Lượng sữa · đã điền theo lần trước'), findsOneWidget);
  });
}
