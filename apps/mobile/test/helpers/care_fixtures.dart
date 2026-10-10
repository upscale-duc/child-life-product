import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'family_fixtures.dart';

/// The 19 Hôm nay mock: Thursday 8 Oct 2026, 15:05 in Hồ Chí Minh (GMT+7).
final careNow = DateTime.utc(2026, 10, 8, 8, 5).toLocal();
DateTime vn(int day, int hour, int minute) =>
    DateTime.utc(2026, 10, day, hour - 7, minute).toLocal();

var _seq = 0;
CareRecord rec(
  CareType type,
  DateTime at,
  Membership by, {
  DateTime? endedAt,
  int? amountMl,
  MilkType? milk,
  Side? side,
  int? durationMin,
  DiaperKind? diaper,
  double? weightKg,
  double? lengthCm,
  DateTime? measuredOn,
  bool pending = false,
}) => CareRecord(
  id: 'r_${(++_seq).toRadixString(16).padLeft(32, '0')}',
  babyId: teddyId,
  type: type,
  occurredAt: at,
  endedAt: endedAt,
  createdBy: by.uid,
  author: CareAuthor.of(by),
  amountMl: amountMl,
  milk: milk,
  side: side,
  durationMin: durationMin,
  diaper: diaper,
  weightKg: weightKg,
  lengthCm: lengthCm,
  measuredOn: measuredOn,
  createdAt: pending ? null : at.add(const Duration(minutes: 2)),
  clientCreatedAt: at.add(const Duration(minutes: 2)),
  pending: pending,
);

/// Today's records, newest first, as on 19 / 9a (bottle and diaper pending when [offline]).
List<CareRecord> mockDay({bool offline = false}) => [
  rec(
    CareType.bottle,
    vn(8, 14, 20),
    mai,
    amountMl: 120,
    milk: MilkType.breastMilk,
    pending: offline,
  ),
  rec(
    CareType.diaper,
    vn(8, 13, 40),
    lan,
    diaper: DiaperKind.wet,
    pending: offline,
  ),
  rec(
    CareType.breast,
    vn(8, 11, 30),
    mai,
    endedAt: vn(8, 11, 45),
    side: Side.both,
    durationMin: 15,
  ),
  rec(
    CareType.pump,
    vn(8, 10, 15),
    mai,
    side: Side.both,
    amountMl: 90,
    durationMin: 15,
  ),
  rec(CareType.diaper, vn(8, 9, 10), mai, diaper: DiaperKind.both),
  rec(
    CareType.bottle,
    vn(8, 8, 0),
    minh,
    amountMl: 120,
    milk: MilkType.formula,
  ),
];

/// 28's previous measurements: 1 Oct and at birth (17 Sep).
List<CareRecord> mockGrowth() => [
  rec(
    CareType.growth,
    vn(1, 12, 0),
    mai,
    weightKg: 3.9,
    lengthCm: 53,
    measuredOn: DateTime(2026, 10, 1),
  ),
  rec(
    CareType.growth,
    DateTime.utc(2026, 9, 17, 5).toLocal(),
    minh,
    weightKg: 3.2,
    lengthCm: 50,
    measuredOn: DateTime(2026, 9, 17),
  ),
];

/// What the sheets and screens asked the repository to do.
class FakeCareRepository extends Fake implements CareRepository {
  final created = <CareRecord>[];
  final edited = <CareRecord>[];
  final deleted = <CareRecord>[];
  final restored = <CareRecord>[];

  @override
  void create(CareRecord record, {void Function(Object error)? onError}) =>
      created.add(record);

  @override
  void edit(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) => edited.add(record);

  @override
  void softDelete(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) => deleted.add(record);

  @override
  void restore(
    CareRecord record,
    String uid, {
    void Function(Object error)? onError,
  }) => restored.add(record);

  @override
  Future<bool> retryNow() async => true;
}

/// Family overrides plus care data at the mock's fixed time.
List<Override> careOverrides({
  Membership? me,
  List<CareRecord>? records,
  List<CareRecord>? growth,
  bool online = true,
  FakeCareRepository? repo,
  Map<String, CareRecord>? byId,
}) => [
  ...familyOverrides(
    me: me,
    records: records ?? mockDay(),
    growth: growth ?? const [],
    online: online,
    now: careNow,
  ),
  careRepositoryProvider.overrideWithValue(repo ?? FakeCareRepository()),
  careRecordProvider.overrideWith((ref, key) => Stream.value(byId?[key.$2])),
];
