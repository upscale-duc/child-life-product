import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'family_fixtures.dart';
import 'rhythm_fixtures.dart';

/// U1 "Chuẩn bị đi khám" fixtures, shared by its widget and golden tests.
var _n = 0;
CareRecord _rec(
  CareType type,
  DateTime at, {
  DateTime? end,
  int? ml,
  DiaperKind? diaper,
  double? kg,
  double? cm,
}) => CareRecord(
  id: 'r_${(++_n).toRadixString(16).padLeft(32, '0')}',
  babyId: teddyId,
  type: type,
  occurredAt: at,
  endedAt: end,
  amountMl: ml,
  diaper: diaper,
  weightKg: kg,
  lengthCm: cm,
  createdBy: 'u_mai',
  author: CareAuthor.of(mai),
);

/// rhythmNow is 2026-10-08 10:00 in Hà Nội: the last complete week is 1–7 Oct, the one before
/// 24–30 Sep. Bottles 120 ml every 3 h (5 a day) and two wet diapers a day; 3 feeds in the week
/// before.
DateTime _vn(int month, int day, int h) =>
    DateTime.utc(2026, month, day, h).subtract(const Duration(hours: 7));

final _log = [
  for (var d = 1; d <= 7; d++) ...[
    for (final h in [7, 10, 13, 16, 19])
      _rec(CareType.bottle, _vn(10, d, h), ml: 120),
    _rec(CareType.diaper, _vn(10, d, 8), diaper: DiaperKind.wet),
    _rec(CareType.diaper, _vn(10, d, 15), diaper: DiaperKind.wet),
  ],
  for (var d = 24; d <= 30; d++)
    for (final h in [7, 13, 19]) _rec(CareType.bottle, _vn(9, d, h), ml: 100),
];

final _growth = [_rec(CareType.growth, _vn(10, 5, 9), kg: 6.2, cm: 61)];

List<Override> visitOverrides({bool premium = true}) => [
  ...rhythmOverrides(
    repo: FakeRhythmRepository(),
    caps: rhythmCaps(groupA: premium),
    growth: _growth,
  ),
  rangeRecordsProvider.overrideWith(
    (ref, key) => Stream.value([
      for (final r in _log)
        if (!r.occurredAt.isBefore(key.$2) && r.occurredAt.isBefore(key.$3)) r,
    ]),
  ),
];
