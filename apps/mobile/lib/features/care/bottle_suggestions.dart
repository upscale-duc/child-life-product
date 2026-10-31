import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reference/reference_repository.dart';

/// 22 "Ghi bú bình · gợi ý nhanh" (v1.0 improvement 346:47151): four quick-pick amounts for the
/// baby's age. Figma draws only "bé 3 tuần → 60 · 90 · 120 · 150 ml"; the other rows are an
/// engineering draft from common bottle-feeding guidance, approved by the owner (P-126, D-158). They are
/// shortcuts, not advice: the field stays free and optional (R-012).
///
/// Since the portal (P-138, Figma C02) the table is reference data `bottle.quickPicks`: bands
/// `[fromDay, toDay)` (toDay null = open-ended), four increasing picks and the ± step. An
/// approved version is published to `publicConfig/reference_bottle`; the app validates it and
/// otherwise uses [BottleTable.bundled], which is version 1 = the P-126 table above.
List<int> bottleSuggestions(
  int? ageDays, [
  BottleTable table = BottleTable.bundled,
]) => table.bandFor(ageDays).picks;

/// The ± step (ml) for the baby's age; for an amount adjuster (C02), none is drawn in 22 yet.
int bottleStepMl(int? ageDays, [BottleTable table = BottleTable.bundled]) =>
    table.bandFor(ageDays).stepMl;

/// One C02 row: quick picks for ages in `[fromDay, toDay)`.
@immutable
class BottleBand {
  const BottleBand({
    required this.fromDay,
    required this.toDay,
    required this.picks,
    required this.stepMl,
  });

  final int fromDay;

  /// Exclusive; null = and older.
  final int? toDay;
  final List<int> picks;
  final int stepMl;

  bool contains(int ageDays) =>
      ageDays >= fromDay && (toDay == null || ageDays < toDay!);

  /// A row as published (`bottleRowSchema` in contracts), or null when anything is off:
  /// fromDay 0–3650, toDay null or after fromDay (≤ 3650), four increasing picks of 5–400 ml,
  /// a step of 1–50 ml.
  static BottleBand? parse(Object? raw) {
    if (raw is! Map || !raw.containsKey('toDay')) return null;
    final from = _int(raw['fromDay']);
    final to = raw['toDay'] == null ? null : _int(raw['toDay']);
    final step = _int(raw['stepMl']);
    final picksRaw = raw['picks'];
    if (from == null || from < 0 || from > 3650) return null;
    if (raw['toDay'] != null && (to == null || to <= from || to > 3650)) {
      return null;
    }
    if (step == null || step < 1 || step > 50) return null;
    if (picksRaw is! List || picksRaw.length != 4) return null;
    final picks = <int>[];
    for (final p in picksRaw) {
      final ml = _int(p);
      if (ml == null || ml < 5 || ml > 400) return null;
      if (picks.isNotEmpty && ml <= picks.last) return null;
      picks.add(ml);
    }
    return BottleBand(
      fromDay: from,
      toDay: to,
      picks: List.unmodifiable(picks),
      stepMl: step,
    );
  }

  Map<String, Object?> toJson() => {
    'fromDay': fromDay,
    'toDay': toDay,
    'picks': picks,
    'stepMl': stepMl,
  };
}

/// Whole numbers only (Firestore may hand back 30.0 for 30).
int? _int(Object? v) {
  if (v is int) return v;
  if (v is double && v.isFinite && v == v.truncateToDouble()) return v.toInt();
  return null;
}

/// The `bottle.quickPicks` table in use.
@immutable
class BottleTable {
  const BottleTable({
    required this.version,
    required this.publishedAt,
    required this.bands,
  });

  final String version;
  final String publishedAt;

  /// Sorted by fromDay, never overlapping.
  final List<BottleBand> bands;

  static const docId = 'reference_bottle';
  static const dataset = 'bottle.quickPicks';

  /// Without a date of birth (the viewer cannot see it), the band that holds three weeks: the
  /// age Figma draws (60 · 90 · 120 · 150 ml in version 1).
  static const unknownAgeDay = 21;

  /// Version 1 = the P-126 table the app shipped (`bottleQuickPicksV1` in contracts).
  static const bundled = BottleTable(
    version: 'v1',
    publishedAt: '',
    bands: [
      BottleBand(fromDay: 0, toDay: 7, picks: [30, 45, 60, 75], stepMl: 5),
      BottleBand(fromDay: 7, toDay: 28, picks: [60, 90, 120, 150], stepMl: 10),
      BottleBand(
        fromDay: 28,
        toDay: 61,
        picks: [90, 120, 150, 180],
        stepMl: 10,
      ),
      BottleBand(
        fromDay: 61,
        toDay: 122,
        picks: [120, 150, 180, 210],
        stepMl: 10,
      ),
      BottleBand(
        fromDay: 122,
        toDay: null,
        picks: [150, 180, 210, 240],
        stepMl: 10,
      ),
    ],
  );

  /// The band for [ageDays] (a date of birth in the future counts as day 0). An age a published
  /// table does not cover falls back to the bundled band.
  BottleBand bandFor(int? ageDays) {
    final day = math.max(0, ageDays ?? unknownAgeDay);
    for (final b in bands) {
      if (b.contains(day)) return b;
    }
    if (!identical(this, bundled)) return bundled.bandFor(day);
    return bands.last;
  }

  /// `publicConfig/reference_bottle` (or its cached copy) when it is a valid bottle table:
  /// all fields present, 1–20 valid rows, bands that do not overlap (only the last may be
  /// open-ended). Otherwise null, and the caller uses [bundled].
  static BottleTable? parse(Object? data) {
    if (data is! Map || data['dataset'] != dataset) return null;
    final version = data['version'];
    final publishedAt = data['publishedAt'];
    final rows = data['rows'];
    if (version is! String ||
        !RegExp(r'^v\d{4}\.\d{2}(?:\.\d+)?$').hasMatch(version)) {
      return null;
    }
    if (publishedAt is! String) return null;
    if (rows is! List || rows.isEmpty || rows.length > 20) return null;
    final bands = <BottleBand>[];
    for (final r in rows) {
      final band = BottleBand.parse(r);
      if (band == null) return null;
      bands.add(band);
    }
    bands.sort((a, b) => a.fromDay.compareTo(b.fromDay));
    for (var i = 1; i < bands.length; i++) {
      final previousEnd = bands[i - 1].toDay;
      if (previousEnd == null || bands[i].fromDay < previousEnd) return null;
    }
    return BottleTable(
      version: version,
      publishedAt: publishedAt,
      bands: List.unmodifiable(bands),
    );
  }

  Map<String, Object?> toJson() => {
    'dataset': dataset,
    'version': version,
    'publishedAt': publishedAt,
    'rows': [for (final b in bands) b.toJson()],
  };
}

/// The bottle table in use: the last valid published copy on this device, else the bundled
/// one; [BottleTableController.refresh] runs once at app start (`ChildLifeApp`).
final bottleTableProvider =
    NotifierProvider<BottleTableController, BottleTable>(
      BottleTableController.new,
    );

class BottleTableController extends Notifier<BottleTable> {
  @override
  BottleTable build() =>
      ref
          .watch(referenceRepositoryProvider)
          .cached(BottleTable.docId, BottleTable.parse) ??
      BottleTable.bundled;

  /// Reads `publicConfig/reference_bottle`; keeps the current table when it cannot be read.
  Future<void> refresh() async {
    try {
      final table = await ref
          .read(referenceRepositoryProvider)
          .refresh<BottleTable>(
            BottleTable.docId,
            BottleTable.parse,
            (t) => t.toJson(),
          );
      state = table ?? BottleTable.bundled;
    } on Object {
      // Offline with nothing cached, or Firebase unavailable: keep what we have.
    }
  }
}
