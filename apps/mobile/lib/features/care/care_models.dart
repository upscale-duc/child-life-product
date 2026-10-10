import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../baby/baby_models.dart';

/// Mirrors `packages/contracts/src/care.ts` (S4). Records live in
/// `babies/{babyId}/records/{id}`; Firestore Rules enforce the same shapes and ranges.

enum CareType { bottle, breast, pump, sleep, diaper, growth }

enum MilkType { breastMilk, formula }

enum Side { left, right, both }

enum DiaperKind { wet, dirty, both }

abstract final class CareLimits {
  static const bottleMl = (min: 1, max: 500);
  static const pumpMl = (min: 1, max: 1000);
  static const durationMin = (min: 1, max: 240);
  static const weightKg = (min: 0.3, max: 40.0);
  static const lengthCm = (min: 20.0, max: 150.0);
}

/// `r_` + 32 hex: generated once per sheet so a double tap or a retry writes the same doc.
String newRecordId() => 'r_${const Uuid().v4().replaceAll('-', '')}';

CareType? careTypeOf(TrackerKind kind) => switch (kind) {
  TrackerKind.bottle => CareType.bottle,
  TrackerKind.breast => CareType.breast,
  TrackerKind.sleep => CareType.sleep,
  TrackerKind.diaper => CareType.diaper,
  TrackerKind.pump => CareType.pump,
  TrackerKind.growth => CareType.growth,
};

/// Who logged it, frozen at logging time ("Mẹ ghi", "Cô Lan ghi", D-024).
@immutable
class CareAuthor {
  const CareAuthor({
    required this.name,
    required this.relation,
    this.relationCustom,
  });

  final String name;
  final Relation relation;
  final String? relationCustom;

  factory CareAuthor.of(Membership m) => CareAuthor(
    name: m.displayName,
    relation: m.relation,
    relationCustom: m.relationCustom,
  );

  factory CareAuthor.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return CareAuthor(
      name: map['name'] as String? ?? '',
      relation: Relation.values.asNameMap()[map['relation']] ?? Relation.other,
      relationCustom: map['relationCustom'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'relation': relation.name,
    'relationCustom': relationCustom,
  };
}

/// One care record. Per-type fields are null when they do not apply.
@immutable
class CareRecord {
  const CareRecord({
    required this.id,
    required this.babyId,
    required this.type,
    required this.occurredAt,
    required this.createdBy,
    required this.author,
    this.endedAt,
    this.amountMl,
    this.milk,
    this.side,
    this.durationMin,
    this.diaper,
    this.weightKg,
    this.lengthCm,
    this.measuredOn,
    this.createdAt,
    this.clientCreatedAt,
    this.deleted = false,
    this.pending = false,
  });

  final String id;
  final String babyId;
  final CareType type;

  /// When it happened (the start for breastfeeds, pumping and sleep).
  final DateTime occurredAt;
  final DateTime? endedAt;
  final String createdBy;
  final CareAuthor author;

  final int? amountMl;
  final MilkType? milk;
  final Side? side;
  final int? durationMin;
  final DiaperKind? diaper;
  final double? weightKg;
  final double? lengthCm;

  /// Growth "Ngày đo" (baby-local calendar date).
  final DateTime? measuredOn;

  /// Server time of the first save ("Ghi lúc"); null until it reaches the server.
  final DateTime? createdAt;
  final DateTime? clientCreatedAt;
  final bool deleted;

  /// Saved on this device, waiting to sync ("Chờ đồng bộ", 9a / 9b).
  final bool pending;

  /// "Ghi lúc": the server time, or the device time while pending.
  DateTime get loggedAt => createdAt ?? clientCreatedAt ?? occurredAt;

  /// When it ended (spans) or happened (points) — tiles count "… trước" from here.
  DateTime get finishedAt => endedAt ?? occurredAt;

  CareRecord copyWith({
    DateTime? occurredAt,
    int? amountMl,
    MilkType? milk,
    Side? side,
    int? durationMin,
    DiaperKind? diaper,
    double? weightKg,
    double? lengthCm,
    DateTime? measuredOn,
    bool clearAmount = false,
    bool clearDuration = false,
    bool clearLength = false,
  }) {
    final start = occurredAt ?? this.occurredAt;
    final minutes = clearDuration ? null : (durationMin ?? this.durationMin);
    return CareRecord(
      id: id,
      babyId: babyId,
      type: type,
      occurredAt: start,
      endedAt: _endFor(type, start, minutes) ?? endedAt,
      createdBy: createdBy,
      author: author,
      amountMl: clearAmount ? null : (amountMl ?? this.amountMl),
      milk: milk ?? this.milk,
      side: side ?? this.side,
      durationMin: minutes,
      diaper: diaper ?? this.diaper,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: clearLength ? null : (lengthCm ?? this.lengthCm),
      measuredOn: measuredOn ?? this.measuredOn,
      createdAt: createdAt,
      clientCreatedAt: clientCreatedAt,
      deleted: deleted,
      pending: pending,
    );
  }

  /// Breastfeeds and pumping with a duration end that many minutes after they start.
  static DateTime? _endFor(CareType type, DateTime start, int? minutes) =>
      (type == CareType.breast || type == CareType.pump) && minutes != null
      ? start.add(Duration(minutes: minutes))
      : null;

  static CareRecord create({
    required String id,
    required String babyId,
    required CareType type,
    required DateTime occurredAt,
    required Membership me,
    int? amountMl,
    MilkType? milk,
    Side? side,
    int? durationMin,
    DiaperKind? diaper,
    double? weightKg,
    double? lengthCm,
    DateTime? measuredOn,
  }) => CareRecord(
    id: id,
    babyId: babyId,
    type: type,
    occurredAt: occurredAt,
    endedAt: _endFor(type, occurredAt, durationMin),
    createdBy: me.uid,
    author: CareAuthor.of(me),
    amountMl: amountMl,
    milk: milk,
    side: side,
    durationMin: durationMin,
    diaper: diaper,
    weightKg: weightKg,
    lengthCm: lengthCm,
    measuredOn: measuredOn,
    clientCreatedAt: DateTime.now(),
    pending: true,
  );

  Map<String, Object?> dataJson() => switch (type) {
    CareType.bottle => {
      'amountMl': amountMl,
      'milk': (milk ?? MilkType.formula).name,
    },
    CareType.breast => {
      'side': (side ?? Side.both).name,
      'durationMin': durationMin,
    },
    CareType.pump => {
      'side': (side ?? Side.both).name,
      'amountMl': amountMl,
      'durationMin': durationMin,
    },
    CareType.diaper => {'kind': (diaper ?? DiaperKind.wet).name},
    CareType.growth => {
      'weightKg': weightKg,
      'lengthCm': lengthCm,
      'measuredOn': isoDate(measuredOn ?? occurredAt),
    },
    CareType.sleep => const {},
  };

  /// The whole new document (Rules: `validNewRecord`).
  Map<String, Object?> toCreateJson() => {
    'id': id,
    'babyId': babyId,
    'type': type.name,
    'occurredAt': Timestamp.fromDate(occurredAt),
    'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
    'data': dataJson(),
    'createdBy': createdBy,
    'author': author.toJson(),
    'createdAt': FieldValue.serverTimestamp(),
    'clientCreatedAt': Timestamp.fromDate(clientCreatedAt ?? DateTime.now()),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': createdBy,
    'deleted': false,
    'deletedAt': null,
    'deletedBy': null,
    'source': 'app',
  };

  /// "Sửa": time and details only (Rules: `validRecordUpdate`).
  Map<String, Object?> toEditJson(String uid) => {
    'occurredAt': Timestamp.fromDate(occurredAt),
    'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
    'data': dataJson(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': uid,
  };

  static CareRecord? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data();
    if (json == null) return null;
    final type = CareType.values.asNameMap()[json['type']];
    final occurredAt = dateOf(json['occurredAt']);
    if (type == null || occurredAt == null) return null;
    final data = json['data'] is Map ? json['data'] as Map : const {};
    num? number(String key) => data[key] is num ? data[key] as num : null;
    return CareRecord(
      id: doc.id,
      babyId: json['babyId'] as String? ?? '',
      type: type,
      occurredAt: occurredAt,
      endedAt: dateOf(json['endedAt']),
      createdBy: json['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(json['author']),
      amountMl: number('amountMl')?.toInt(),
      milk: MilkType.values.asNameMap()[data['milk']],
      side: Side.values.asNameMap()[data['side']],
      durationMin: number('durationMin')?.toInt(),
      diaper: DiaperKind.values.asNameMap()[data['kind']],
      weightKg: number('weightKg')?.toDouble(),
      lengthCm: number('lengthCm')?.toDouble(),
      measuredOn: DateTime.tryParse(data['measuredOn'] as String? ?? ''),
      createdAt: dateOf(json['createdAt']),
      clientCreatedAt: dateOf(json['clientCreatedAt']),
      deleted: json['deleted'] == true,
      pending: doc.metadata.hasPendingWrites,
    );
  }
}

/// "Đã ghi hôm nay" (DayRhythm 48:409), computed on the device from what it holds — pending
/// entries included (9a) — with the same rules as the server (`summarizeDay` in contracts).
@immutable
class DayTotals {
  const DayTotals({
    this.bottleCount = 0,
    this.bottleMl = 0,
    this.breastCount = 0,
    this.breastMinutes = 0,
    this.sleepMinutes = 0,
    this.diaperCount = 0,
  });

  final int bottleCount;
  final int bottleMl;
  final int breastCount;
  final int breastMinutes;
  final int sleepMinutes;
  final int diaperCount;

  bool get isEmpty =>
      bottleCount == 0 &&
      breastCount == 0 &&
      sleepMinutes == 0 &&
      diaperCount == 0;

  /// [dayStart]..[dayEnd) are the baby's local day bounds.
  static DayTotals of(
    Iterable<CareRecord> records,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    var bottleCount = 0, bottleMl = 0, breastCount = 0, breastMinutes = 0;
    var sleepMinutes = 0, diaperCount = 0;
    for (final r in records) {
      if (r.deleted) continue;
      final onDay =
          !r.occurredAt.isBefore(dayStart) && r.occurredAt.isBefore(dayEnd);
      switch (r.type) {
        case CareType.bottle when onDay:
          bottleCount++;
          bottleMl += r.amountMl ?? 0;
        case CareType.breast when onDay:
          breastCount++;
          breastMinutes += r.durationMin ?? 0;
        case CareType.sleep when r.endedAt != null:
          final from = r.occurredAt.isAfter(dayStart) ? r.occurredAt : dayStart;
          final to = r.endedAt!.isBefore(dayEnd) ? r.endedAt! : dayEnd;
          if (to.isAfter(from)) sleepMinutes += to.difference(from).inMinutes;
        case CareType.diaper when onDay:
          diaperCount++;
        default:
          break;
      }
    }
    return DayTotals(
      bottleCount: bottleCount,
      bottleMl: bottleMl,
      breastCount: breastCount,
      breastMinutes: breastMinutes,
      sleepMinutes: sleepMinutes,
      diaperCount: diaperCount,
    );
  }
}
