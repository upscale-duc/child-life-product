import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/assistant/assistant_cards.dart';
import 'package:child_life/features/assistant/assistant_fix.dart';
import 'package:child_life/features/assistant/assistant_labels.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_rules.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_widgets.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Lumi fixes 2026-10-16 on the phone: "hút sữa 120ml", "thay tã ướt", "bé nặng 5,2kg" become
/// pump / diaper / growth drafts written exactly as the care forms write them (LUMI-01); the app
/// declares the kinds it can show (LUMI-05); every flagged field is named and fixable on the card
/// (a nursing timer's side, LUMI-07; a sleep's start, LUMI-09; a reminder already past, LUMI-11);
/// a part that was not drafted links to its module (LUMI-13). Synthetic data only.

final _vi = lookupAppLocalizations(const Locale('vi'));
const _zone = 'Asia/Ho_Chi_Minh';

/// 14:20 in Asia/Ho_Chi_Minh.
final _now = assistantNow;

AssistantDraft _draft(
  Map<String, Object?> json, {
  List<String> missing = const [],
  List<String> uncertain = const [],
  List<String> problems = const [],
}) => AssistantDraft.fromJson({
  ...reviewed(json, missing: missing, uncertain: uncertain),
  'problems': problems,
})!;

typedef _Patch = ({DraftPayload payload, List<String> confirmed});

List<AsFixRow> _rows(AssistantDraft d, List<_Patch> patches) => fixRowsFor(
  l10n: _vi,
  locale: 'vi',
  d: d,
  zone: _zone,
  now: _now,
  act: FixActions(
    patch: (payload, confirmed) async =>
        patches.add((payload: payload, confirmed: confirmed)),
    edit: () async {},
    pickTime: (_) async => null,
    pickDate: (_, {past = false}) async => null,
  ),
);

AsFixRow _row(List<AsFixRow> rows, String field) =>
    rows.singleWhere((r) => r.field == field);

/// Everything a row shows: its reason and its chips.
String _shown(AsFixRow r) =>
    [r.reason, for (final c in r.chips) c.label].join(' ').toLowerCase();

Future<void> _tapChip(AsFixRow r, String label) =>
    r.chips.singleWhere((c) => c.label == label).onTap();

final Map<String, dynamic> _controls =
    jsonDecode(
          File(
            'test/features/assistant_replay/field_controls.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

List<String> _words(String kind, String field) => [
  for (final w
      in ((((_controls['kinds'] as Map)[kind] as Map)['fields'] as Map)[field]
              as Map)['words']
          as List)
    '$w',
];

class _FakeDb extends Fake implements FirebaseFirestore {}

class _FakeFunctions extends Fake implements FirebaseFunctions {
  final sent = <String, Object?>{};

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _FakeCallable(this);
}

class _FakeCallable extends Fake implements HttpsCallable {
  _FakeCallable(this.f);
  final _FakeFunctions f;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    f.sent
      ..clear()
      ..addAll((parameters as Map).cast<String, Object?>());
    throw FirebaseFunctionsException(code: 'unavailable', message: 'offline');
  }
}

void main() {
  setUpAll(initializeDateFormatting);

  group('LUMI-05: the app declares the kinds it can show', () {
    test('every kind, from one list next to the contract version', () {
      expect(assistantContractVersion, 1);
      expect(assistantClientDraftKinds, [
        'bottle',
        'breast',
        'sleep',
        'expense',
        'reminder',
        'observation',
        'meal',
        'timer',
        'pump',
        'diaper',
        'growth',
      ]);
      expect(assistantEnvelope(requestId: 'r', locale: 'en'), {
        'contractVersion': 1,
        'clientRequestId': 'r',
        'locale': 'en',
        'clientDraftKinds': assistantClientDraftKinds,
      });
    });

    test(
      'every callable request carries clientDraftKinds in its envelope',
      () async {
        final functions = _FakeFunctions();
        final repo = AssistantRepository(_FakeDb(), functions);
        await expectLater(
          repo.patchDraft(
            draftId: 'd1',
            expectedRevision: 1,
            payload: const PumpPayload(
              amountMl: 120,
              side: 'left',
              durationMin: 15,
            ),
            confirmedFields: const ['amountMl'],
            locale: 'vi',
          ),
          throwsA(isA<AssistantException>()),
        );
        expect(functions.sent['contractVersion'], 1);
        expect(functions.sent['locale'], 'vi');
        expect(functions.sent['clientDraftKinds'], assistantClientDraftKinds);
        expect(functions.sent['payload'], {
          'kind': 'pump',
          'amountMl': 120,
          'occurredAt': null,
          'side': 'left',
          'durationMin': 15,
        });
        await expectLater(
          repo.usage(teddyId, locale: 'en'),
          throwsA(isA<AssistantException>()),
        );
        expect(functions.sent['clientDraftKinds'], assistantClientDraftKinds);
      },
    );
  });

  group('LUMI-01: pump / diaper / growth payloads', () {
    test('parse with the server key names, tolerant of bad values', () {
      final pump = DraftPayload.fromJson({
        'kind': 'pump',
        'amountMl': 120,
        'occurredAt': '2026-10-15T03:00:00.000Z',
        'side': 'left',
        'durationMin': 15,
        'linked': {'derived': 'occurredAt'},
      });
      expect(pump, isA<PumpPayload>());
      expect(pump.kind, DraftKind.pump);
      expect(pump.toJson(), {
        'kind': 'pump',
        'amountMl': 120,
        'occurredAt': '2026-10-15T03:00:00.000Z',
        'side': 'left',
        'durationMin': 15,
        'linked': {'derived': 'occurredAt'},
      });
      // A new start set by the person drops the server's link.
      expect(
        (pump as PumpPayload)
            .copyWith(occurredAt: DateTime.utc(2026, 10, 15, 2))
            .toJson()
            .containsKey('linked'),
        isFalse,
      );
      final odd = DraftPayload.fromJson({
        'kind': 'pump',
        'amountMl': 'x',
        'side': 'middle',
        'durationMin': 1.5,
        'occurredAt': 3,
      });
      expect(odd, isA<PumpPayload>());
      expect((odd as PumpPayload).amountMl, isNull);
      expect(odd.side, isNull);
      expect(odd.durationMin, isNull);
      expect(odd.occurredAt, isNull);

      final diaper = DraftPayload.fromJson({
        'kind': 'diaper',
        'diaper': 'both',
        'occurredAt': '2026-10-15T06:00:00.000Z',
      });
      expect(diaper.kind, DraftKind.diaper);
      expect((diaper as DiaperPayload).diaper, 'both');
      expect(diaper.toJson(), {
        'kind': 'diaper',
        'diaper': 'both',
        'occurredAt': '2026-10-15T06:00:00.000Z',
      });
      expect(
        (DraftPayload.fromJson({'kind': 'diaper', 'diaper': 'pee'})
                as DiaperPayload)
            .diaper,
        isNull,
      );

      final growth = DraftPayload.fromJson({
        'kind': 'growth',
        'weightKg': 5.2,
        'lengthCm': 62,
        'measuredOn': '2026-10-15',
      });
      expect(growth.kind, DraftKind.growth);
      expect(growth.toJson(), {
        'kind': 'growth',
        'weightKg': 5.2,
        'lengthCm': 62,
        'measuredOn': '2026-10-15',
        'headCm': null,
      });
      // Owner 2026-10-16: the head circumference rides along (absent = null).
      final withHead =
          DraftPayload.fromJson({
                'kind': 'growth',
                'weightKg': 5.2,
                'measuredOn': '2026-10-15',
                'headCm': 39,
              })
              as GrowthPayload;
      expect(withHead.headCm, 39);
      expect(withHead.withoutLength().headCm, 39);
      expect(withHead.withoutHead().headCm, isNull);
      expect(
        draftProblems(
          withHead.copyWith(headCm: 75),
          DateTime.utc(2026, 10, 15, 8),
        ),
        [DraftProblem.invalidAmount],
      );
      expect(
        problemFields(
          withHead.copyWith(headCm: 75),
          DraftProblem.invalidAmount,
        ),
        ['headCm'],
      );
      final g2 =
          DraftPayload.fromJson({
                'kind': 'growth',
                'weightKg': null,
                'measuredOn': '15/10/2026',
              })
              as GrowthPayload;
      expect(g2.weightKg, isNull);
      expect(g2.lengthCm, isNull);
      expect(g2.measuredOn, isNull);
      expect(
        (growth as GrowthPayload).withoutLength().toJson()['lengthCm'],
        isNull,
      );
    });

    test('the two new notice codes parse', () {
      for (final (wire, code) in [
        ('PART_NOT_SAVED', NoticeCode.partNotSaved),
        ('APP_UPDATE_NEEDED', NoticeCode.appUpdateNeeded),
      ]) {
        final part = AssistantPart.fromJson({
          ...codedText('x', wire),
          'link': '/care/growth',
        });
        expect((part as TextPart).code, code);
        expect(part.link, '/care/growth');
      }
    });
  });

  group('LUMI-01: the care forms\' checks (contracts draftProblems)', () {
    PumpPayload pump({
      num? ml = 120,
      DateTime? at,
      int? minutes,
      bool noTime = false,
    }) => PumpPayload(
      amountMl: ml,
      occurredAt: noTime
          ? null
          : (at ?? _now.subtract(const Duration(hours: 1))),
      durationMin: minutes,
    );

    test('pump: amount 1…1000 whole ml, length ≤ 240, a past start', () {
      expect(draftProblems(pump(), _now), isEmpty);
      expect(draftProblems(pump(ml: 1000), _now), isEmpty);
      expect(draftProblems(pump(ml: null), _now), [DraftProblem.missingAmount]);
      expect(draftProblems(pump(ml: 1001), _now), [DraftProblem.invalidAmount]);
      expect(draftProblems(pump(ml: 120.5), _now), [
        DraftProblem.invalidAmount,
      ]);
      expect(draftProblems(pump(ml: 0), _now), [DraftProblem.invalidAmount]);
      expect(draftProblems(pump(minutes: 241), _now), [
        DraftProblem.invalidAmount,
      ]);
      expect(draftProblems(pump(noTime: true), _now), [
        DraftProblem.missingTime,
      ]);
      expect(
        draftProblems(pump(at: _now.add(const Duration(minutes: 10))), _now),
        [DraftProblem.futureTime],
      );
    });

    test('diaper: only a past time (the kind is required, not a problem)', () {
      expect(
        draftProblems(DiaperPayload(diaper: 'wet', occurredAt: _now), _now),
        isEmpty,
      );
      expect(draftProblems(const DiaperPayload(diaper: 'wet'), _now), [
        DraftProblem.missingTime,
      ]);
      expect(
        draftProblems(
          DiaperPayload(occurredAt: _now.add(const Duration(hours: 1))),
          _now,
        ),
        [DraftProblem.futureTime],
      );
    });

    test('growth: weight 0,3…40 kg, length 20…150 cm, a date not ahead', () {
      const ok = GrowthPayload(
        weightKg: 5.2,
        lengthCm: 62,
        measuredOn: '2026-10-15',
      );
      expect(draftProblems(ok, _now), isEmpty);
      expect(
        draftProblems(
          const GrowthPayload(weightKg: 5.2, measuredOn: '2026-10-15'),
          _now,
        ),
        isEmpty,
      );
      expect(
        draftProblems(const GrowthPayload(measuredOn: '2026-10-15'), _now),
        [DraftProblem.missingAmount],
      );
      expect(draftProblems(ok.copyWith(weightKg: 0.2), _now), [
        DraftProblem.invalidAmount,
      ]);
      expect(draftProblems(ok.copyWith(lengthCm: 160), _now), [
        DraftProblem.invalidAmount,
      ]);
      expect(draftProblems(const GrowthPayload(weightKg: 5.2), _now), [
        DraftProblem.missingDate,
      ]);
      // Tomorrow somewhere on Earth (UTC+14) is still today; the day after is ahead.
      expect(draftProblems(ok.copyWith(measuredOn: '2026-10-16'), _now), [
        DraftProblem.futureTime,
      ]);
    });

    test('required fields and the fields a problem names', () {
      expect(requiredDraftFields[DraftKind.pump], ['amountMl', 'occurredAt']);
      expect(requiredDraftFields[DraftKind.diaper], ['diaper', 'occurredAt']);
      expect(requiredDraftFields[DraftKind.growth], ['weightKg', 'measuredOn']);
      for (final k in DraftKind.values) {
        expect(requiredDraftFields.containsKey(k), isTrue, reason: k.wire);
      }
      expect(
        problemFields(
          const PumpPayload(amountMl: 1200, durationMin: 300),
          DraftProblem.invalidAmount,
        ),
        ['amountMl', 'durationMin'],
      );
      expect(
        problemFields(
          const PumpPayload(amountMl: 120, durationMin: 300),
          DraftProblem.invalidAmount,
        ),
        ['durationMin'],
      );
      expect(
        problemFields(
          const GrowthPayload(weightKg: 5.2, lengthCm: 10),
          DraftProblem.invalidAmount,
        ),
        ['lengthCm'],
      );
      expect(problemFields(const GrowthPayload(), DraftProblem.missingDate), [
        'measuredOn',
      ]);
      expect(problemFields(const DiaperPayload(), DraftProblem.futureTime), [
        'occurredAt',
      ]);
      // LUMI-11: a reminder already past names its time when it has one.
      expect(
        problemFields(
          const ReminderPayload(
            title: 'Gọi bác sĩ',
            date: '2026-10-15',
            time: '10:00',
          ),
          DraftProblem.pastTime,
        ),
        ['time'],
      );
      expect(
        problemFields(
          const ReminderPayload(title: 'Gọi bác sĩ', date: '2026-10-14'),
          DraftProblem.pastTime,
        ),
        ['date'],
      );
    });

    test('a pump too long asks for the length, not the amount', () {
      final d = _draft(pumpDraftJson(minutes: 300));
      expect(reviewGaps(d, _now), [
        (
          field: 'durationMin',
          missing: false,
          problem: DraftProblem.invalidAmount,
        ),
      ]);
    });

    test('care log rights: Cùng nuôi and Người chăm sóc, never a relative', () {
      for (final k in [DraftKind.pump, DraftKind.diaper, DraftKind.growth]) {
        expect(canSaveKind(mai, k), isTrue, reason: k.wire);
        expect(canSaveKind(lan, k), isTrue, reason: k.wire);
        expect(canSaveKind(hoa, k), canSaveKind(hoa, DraftKind.bottle));
      }
    });

    test('a saved log opens its record like a bottle feed', () {
      final saved = AssistantDraft.fromJson(
        growthDraftJson(state: 'saved', recordId: 'r_${'a' * 32}'),
      )!;
      expect(recordLocation(saved), '/care/record/r_${'a' * 32}');
      expect(moduleLocation(DraftKind.pump), '/care/history');
      expect(moduleLocation(DraftKind.diaper), '/care/history');
      expect(moduleLocation(DraftKind.growth), '/care/history?filter=growth');
    });
  });

  group('cards say it in plain words', () {
    String line(DraftPayload p, {String locale = 'vi'}) => draftLine(
      lookupAppLocalizations(Locale(locale)),
      locale,
      p,
      _zone,
      _now,
    );

    test('pump, diaper and growth lines', () {
      final pump = AssistantDraft.fromJson(pumpDraftJson())!.payload;
      expect(line(pump), '120 ml · Bên trái · 15 phút · Hôm nay 15/10 · 10:00');
      final diaper = AssistantDraft.fromJson(diaperDraftJson())!.payload;
      expect(line(diaper), 'Ướt · Hôm nay 15/10 · 13:00');
      final growth = AssistantDraft.fromJson(growthDraftJson())!.payload;
      expect(line(growth), '5,2 kg · 62 cm · Ngày đo 15/10');
      expect(line(growth, locale: 'en'), '5.2 kg · 62 cm · Measured 15 Oct');
      expect(kindLabel(_vi, DraftKind.pump), 'Hút sữa');
      expect(kindLabel(_vi, DraftKind.diaper), 'Thay tã');
      expect(kindLabel(_vi, DraftKind.growth), 'Cân đo');
    });
  });

  group('inline fixes: every flagged field has its own row, named', () {
    // Every field of the controls map, flagged at once, gets a row that names it in the map's
    // words — never the generic "Kiểm tra lại mục này rồi lưu.".
    final cases = <String, Map<String, Object?>>{
      'pump': pumpDraftJson(),
      'diaper': diaperDraftJson(),
      'growth': growthDraftJson(),
      'timer': timerDraftJson(timer: 'breast', side: 'left'),
    };
    for (final MapEntry(key: kind, value: json) in cases.entries) {
      test(kind, () {
        final fields = [
          for (final f
              in (((_controls['kinds'] as Map)[kind] as Map)['fields'] as Map)
                  .keys)
            '$f',
        ];
        final rows = _rows(_draft(json, uncertain: fields), []);
        for (final f in fields) {
          final r = _row(rows, f);
          expect(r.reason, isNot(_vi.asNeedsReview), reason: '$kind.$f');
          expect(
            _words(kind, f).any(_shown(r).contains),
            isTrue,
            reason: '$kind.$f: "${_shown(r)}" names none of ${_words(kind, f)}',
          );
          expect(r.chips, isNotEmpty, reason: '$kind.$f');
        }
      });
    }

    test('pump: amount chips, side chips, a length too long', () async {
      final patches = <_Patch>[];
      final rows = _rows(
        _draft(
          pumpDraftJson(ml: null, side: null, minutes: 300),
          missing: ['amountMl'],
        ),
        patches,
      );
      final amount = _row(rows, 'amountMl');
      expect(amount.reason, 'Chưa có lượng sữa hút (ml)');
      await _tapChip(amount, '120 ml');
      expect((patches.last.payload as PumpPayload).amountMl, 120);
      expect(patches.last.confirmed, ['amountMl']);
      final length = _row(rows, 'durationMin');
      expect(length.reason, 'Mỗi lần hút không quá 240 phút');
      expect(length.chips.first.label, isNot('Đúng rồi'));
      await _tapChip(length, '15 phút');
      expect((patches.last.payload as PumpPayload).durationMin, 15);

      final side = _row(
        _rows(_draft(pumpDraftJson(side: null), missing: ['side']), patches),
        'side',
      );
      expect(side.chips.map((c) => c.label), ['Trái', 'Phải', 'Cả hai']);
      await _tapChip(side, 'Cả hai');
      expect((patches.last.payload as PumpPayload).side, 'both');
    });

    test(
      'pump: "Vừa xong" means it ended now (the start keeps the length)',
      () async {
        final patches = <_Patch>[];
        final rows = _rows(
          _draft(pumpDraftJson(at: null), missing: ['occurredAt']),
          patches,
        );
        final at = _row(rows, 'occurredAt');
        expect(at.reason, 'Chưa có giờ hút sữa');
        await _tapChip(at, 'Vừa xong (14:20)');
        expect(
          (patches.last.payload as PumpPayload).occurredAt,
          _now.subtract(const Duration(minutes: 15)),
        );
      },
    );

    test('diaper: Ướt / Bẩn / Cả hai, and the time', () async {
      final patches = <_Patch>[];
      final rows = _rows(
        _draft(
          diaperDraftJson(diaper: null, at: null),
          missing: ['diaper', 'occurredAt'],
        ),
        patches,
      );
      final kind = _row(rows, 'diaper');
      expect(kind.reason, 'Tã ướt, bẩn hay cả hai?');
      expect(kind.chips.map((c) => c.label), ['Ướt', 'Bẩn', 'Cả hai']);
      await _tapChip(kind, 'Bẩn');
      expect((patches.last.payload as DiaperPayload).diaper, 'dirty');
      expect(patches.last.confirmed, ['diaper']);
      final at = _row(rows, 'occurredAt');
      expect(at.reason, 'Chưa có giờ thay tã');
      await _tapChip(at, '30 phút trước (13:50)');
      expect(
        (patches.last.payload as DiaperPayload).occurredAt,
        _now.subtract(const Duration(minutes: 30)),
      );
    });

    test(
      'growth: weight, an out-of-range length (optional), the date',
      () async {
        final patches = <_Patch>[];
        final rows = _rows(
          _draft(
            growthDraftJson(kg: null, cm: 200, on: null),
            missing: ['weightKg', 'measuredOn'],
          ),
          patches,
        );
        expect(rows.map((r) => r.field), [
          'weightKg',
          'measuredOn',
          'lengthCm',
        ]);
        expect(_row(rows, 'weightKg').reason, 'Chưa có cân nặng (kg)');
        final length = _row(rows, 'lengthCm');
        expect(length.reason, 'Chiều dài từ 20 đến 150 cm.');
        await _tapChip(length, 'Bỏ chiều dài');
        expect((patches.last.payload as GrowthPayload).lengthCm, isNull);
        final date = _row(rows, 'measuredOn');
        expect(date.reason, 'Chưa có ngày đo');
        await _tapChip(date, 'Hôm qua');
        expect(
          (patches.last.payload as GrowthPayload).measuredOn,
          '2026-10-14',
        );
        final unsure = _rows(
          _draft(growthDraftJson(), uncertain: ['weightKg']),
          patches,
        );
        expect(
          _row(unsure, 'weightKg').reason,
          'Cân nặng 5,2 kg có đúng không?',
        );
        await _tapChip(_row(unsure, 'weightKg'), 'Đúng rồi');
        expect(patches.last.confirmed, ['weightKg']);
      },
    );

    test('LUMI-07: a nursing timer\'s side is a row (Trái / Phải)', () async {
      final patches = <_Patch>[];
      final rows = _rows(
        _draft(timerDraftJson(timer: 'breast', side: null), missing: ['side']),
        patches,
      );
      final side = _row(rows, 'side');
      expect(side.reason, _vi.asGapSide);
      expect(side.chips.map((c) => c.label), ['Trái', 'Phải']);
      await _tapChip(side, 'Phải');
      expect((patches.last.payload as TimerPayload).side, 'right');
      expect(patches.last.confirmed, ['side']);
    });

    test('LUMI-10: a flagged day / night with a value is a row', () async {
      final patches = <_Patch>[];
      final rows = _rows(
        _draft(observationDraftJson(), uncertain: ['when']).copyWith(
          payload: const ObservationPayload(
            observation: 'sleep',
            date: '2026-10-15',
            when: 'night',
          ),
        ),
        patches,
      );
      final when = _row(rows, 'when');
      expect(when.optional, isFalse);
      expect(_shown(when), contains('ban đêm'));
      await _tapChip(when, 'Đúng rồi');
      expect(patches.last.confirmed, ['when']);
    });

    test('LUMI-09: a sleep start to check names the start', () {
      final rows = _rows(_draft(sleepDraftJson(), missing: ['startedAt']), []);
      expect(_row(rows, 'startedAt').reason, startsWith('Giờ ngủ '));
    });

    test('LUMI-11: a reminder already past offers a later time', () async {
      final patches = <_Patch>[];
      final d = AssistantDraft.fromJson({
        ...reminderDraftJson(),
        'payload': {
          'kind': 'reminder',
          'title': 'Gọi bác sĩ',
          'date': '2026-10-15',
          'time': '10:00',
          'assigneeUid': null,
        },
        'state': 'needs_review',
        'problems': ['PAST_TIME'],
      })!;
      final rows = _rows(d, patches);
      final time = _row(rows, 'time');
      expect(time.reason, _vi.asProblemPastTime);
      await _tapChip(time, 'Ngày mai 10:00');
      final r = patches.last.payload as ReminderPayload;
      expect((r.date, r.time), ('2026-10-16', '10:00'));
    });
  });

  group('on the chat screen', () {
    Map<String, Object> prefs() => {
      'assistant.conversation.u_mai:${teddyScope.key}': conversation1,
      'assistant.tasks.u_mai:${teddyScope.key}': [taskA],
    };

    Map<String, Object?> one(
      Map<String, Object?> draft,
      String said, {
      List<Map<String, Object?>> before = const [],
    }) => snapshotWith(
      task: taskJson(),
      drafts: [draft],
      messages: [
        userMessage(said),
        assistantMessage([...before, draftRef(draft['id']! as String)]),
      ],
    );

    Future<List<Visit>> pump(
      WidgetTester tester,
      FakeAssistantRepository repo,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        AssistantChatScreen(scopeKey: teddyScope.key),
        prefs: prefs(),
        overrides: assistantOverrides(repo: repo),
      );
      await tester.pumpAndSettle();
      return visits;
    }

    testWidgets('a ready pump saves in one tap from its own card', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: one(pumpDraftJson(), 'hút sữa 120ml bên trái 15 phút lúc 10h'),
        },
      );
      await pump(tester, repo);
      final card = tester.widget<AsDraftCard>(find.byType(AsDraftCard));
      expect(card.kind, DraftKind.pump);
      expect(card.title, 'Hút sữa');
      expect(
        find.text('120 ml · Bên trái · 15 phút · Hôm nay 15/10 · 10:00'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lưu hút sữa'));
      await tester.pumpAndSettle();
      expect(repo.named('confirmDrafts').single.args['selected'], hasLength(1));
    });

    testWidgets('a diaper without its kind: the card asks and fixes in place', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: one(
            reviewed(diaperDraftJson(diaper: null), missing: ['diaper']),
            'thay tã lúc 13h',
          ),
        },
        patchAnswer: (_) => diaperDraftJson(diaper: 'wet', revision: 2),
      );
      await pump(tester, repo);
      final card = tester.widget<AsDraftCard>(find.byType(AsDraftCard));
      expect(card.kind, DraftKind.diaper);
      expect(find.text('Tã ướt, bẩn hay cả hai?'), findsOneWidget);
      expect(card.primary?.onPressed, isNull);
      await tester.tap(find.text('Ướt').last);
      await tester.pumpAndSettle();
      final p =
          repo.named('patchDraft').single.args['payload']!
              as Map<String, Object?>;
      expect(p['diaper'], 'wet');
      expect(
        tester.widget<AsDraftCard>(find.byType(AsDraftCard)).primary?.onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'LUMI-16: a purchase without an amount asks "Hết bao nhiêu tiền?" and saves once typed',
      (tester) async {
        Map<String, Object?> draft({int? total, int revision = 1}) => {
          ...expenseDraftJson(
            uncertain: const [],
            warnings: const [],
            date: '2026-10-15',
            revision: revision,
            state: total == null ? 'needs_review' : 'draft',
          ),
          'payload': {
            'kind': 'expense',
            'merchant': null,
            'totalMinor': total,
            'currency': 'VND',
            'date': '2026-10-15',
            'subtotalMinor': null,
            'taxMinor': null,
            'categoryId': 'c_milk',
            'babyId': teddyId,
            'keepReceipt': false,
            'note': 'hai hộp sữa',
          },
          'missingFields': total == null ? const ['totalMinor'] : const [],
          'problems': total == null ? const ['MISSING_AMOUNT'] : const [],
        };
        final repo = FakeAssistantRepository(
          tasks: {taskA: one(draft(), 'mua hai hộp sữa')},
          patchAnswer: (_) => draft(total: 350000, revision: 2),
        );
        await pump(tester, repo);
        expect(find.text(_vi.asAskAmount), findsOneWidget);
        AsReceiptCard card() =>
            tester.widget<AsReceiptCard>(find.byType(AsReceiptCard));
        expect(card().primary?.onPressed, isNull);
        // "35" → the thousands as people say them; a chip fills the field only.
        await tester.enterText(find.byKey(const Key('spAmount')), '35');
        await tester.pumpAndSettle();
        expect(find.text('35.000'), findsOneWidget);
        expect(find.text('3.500.000'), findsOneWidget);
        await tester.tap(find.text('350.000'));
        await tester.pumpAndSettle();
        expect(repo.named('patchDraft'), isEmpty);
        expect(card().primary?.onPressed, isNotNull);
        await tester.tap(find.text(_vi.asSaveExpense));
        await tester.pumpAndSettle();
        final patch = repo.named('patchDraft').single.args;
        final payload = patch['payload']! as Map<String, Object?>;
        expect((payload['totalMinor'], payload['currency']), (350000, 'VND'));
        expect(patch['confirmedFields'], ['totalMinor', 'currency']);
        // Nothing else to check: saved in the same tap.
        expect(repo.named('confirmDrafts'), hasLength(1));
      },
    );

    testWidgets('growth editor: decimals either way, the care form ranges', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: one(growthDraftJson(), 'bé nặng 5,2kg dài 62cm')},
        patchAnswer: (_) => growthDraftJson(kg: 5.4, revision: 2),
      );
      await pump(tester, repo);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa cân đo'), findsOneWidget);
      expect(find.text(_vi.asFieldWeight), findsOneWidget);
      expect(find.text(_vi.asFieldMeasuredOn), findsOneWidget);
      final weight = find.descendant(
        of: find.byKey(const ValueKey('as.edit.weight')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(weight).controller!.text, '5,2');
      // Out of range: the form's own words, nothing sent.
      await tester.enterText(weight, '45');
      await tester.tap(find.text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      expect(find.text(_vi.growthWeightRequired), findsOneWidget);
      expect(repo.named('patchDraft'), isEmpty);
      await tester.enterText(weight, '5.43');
      // Owner 2026-10-16: the head circumference, optional, 20…60 cm.
      expect(find.text(_vi.asFieldHead), findsOneWidget);
      final head = find.descendant(
        of: find.byKey(const ValueKey('as.edit.head')),
        matching: find.byType(TextField),
      );
      await tester.enterText(head, '75');
      await tester.tap(find.text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      expect(find.text(_vi.growthHeadRange), findsOneWidget);
      expect(repo.named('patchDraft'), isEmpty);
      await tester.enterText(head, '39,5');
      await tester.tap(find.text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      final p =
          repo.named('patchDraft').single.args['payload']!
              as Map<String, Object?>;
      expect(p, {
        'kind': 'growth',
        'weightKg': 5.4,
        'lengthCm': 62,
        'measuredOn': '2026-10-15',
        'headCm': 39.5,
      });
    });

    testWidgets('pump editor: amount, side, length and start', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: one(pumpDraftJson(), 'hút sữa 120ml')},
        patchAnswer: (_) => pumpDraftJson(ml: 150, revision: 2),
      );
      await pump(tester, repo);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa hút sữa'), findsOneWidget);
      await tester.tap(find.text('150 ml'));
      await tester.tap(find.text('Phải'));
      await tester.tap(find.text('20 phút'));
      await tester.pump();
      await tester.tap(find.text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      final p =
          repo.named('patchDraft').single.args['payload']!
              as Map<String, Object?>;
      expect(p['amountMl'], 150);
      expect(p['side'], 'right');
      expect(p['durationMin'], 20);
      expect(p['occurredAt'], '2026-10-15T03:00:00.000Z');
    });

    testWidgets('diaper editor: the three tiles', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: one(diaperDraftJson(), 'thay tã ướt')},
        patchAnswer: (_) => diaperDraftJson(diaper: 'both', revision: 2),
      );
      await pump(tester, repo);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa thay tã'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('as.edit.diaper.both')));
      await tester.pump();
      await tester.tap(find.text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      final p =
          repo.named('patchDraft').single.args['payload']!
              as Map<String, Object?>;
      expect(p['diaper'], 'both');
    });

    testWidgets('LUMI-13: a part not saved links to its module', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: one(
            growthDraftJson(),
            'bé nặng 5,2kg dài 62cm vòng đầu 40cm',
            before: [
              {
                ...codedText(
                  'Mục Tăng trưởng chưa có vòng đầu, nên mình chưa ghi số đo vòng đầu. Cân nặng và chiều dài ở bản nháp bên dưới.',
                  'PART_NOT_SAVED',
                ),
                'link': '/care/growth',
              },
              {
                ...codedText('Cập nhật ứng dụng nhé.', 'APP_UPDATE_NEEDED'),
                'link': 'https://example.com/x',
              },
            ],
          ),
        },
      );
      final visits = await pump(tester, repo);
      expect(find.byType(AsNoticeCard), findsNWidgets(2));
      // An outside link is never followed.
      expect(find.text(_vi.asOpenModule), findsOneWidget);
      await tester.tap(find.text(_vi.asOpenModule));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/growth');
    });

    test('notice links: in-app module paths only', () {
      expect(moduleRoute('/care/growth'), '/care/growth');
      expect(moduleRoute('/care'), '/care');
      expect(moduleRoute('https://x.y/care'), isNull);
      expect(moduleRoute('//evil/care'), isNull);
      expect(moduleRoute('/settings/delete'), isNull);
      expect(moduleRoute(null), isNull);
      expect(timerRoute('/care/timer/breast?babyId=b1'), '/care/timer/breast');
    });
  });
}
