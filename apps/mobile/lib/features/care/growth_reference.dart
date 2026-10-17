import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reference/reference_repository.dart';
import 'who_growth.dart';

/// One row of a published growth table (`growthRowSchema` in contracts): the 3rd percentile,
/// median and 97th percentile for a sex at an age in weeks (0–13) or months (0–60), in kg or cm.
@immutable
class GrowthRow {
  const GrowthRow({
    required this.boy,
    required this.weeks,
    required this.age,
    required this.low,
    required this.median,
    required this.high,
  });

  final bool boy;
  final bool weeks;
  final int age;
  final double low;
  final double median;
  final double high;

  /// The age in days, as the 20i table counts it: weeks × 7, months × 30.4375 rounded.
  int get day => weeks ? age * 7 : (age * 30.4375).round();

  /// A row as published, or null when anything is off.
  static GrowthRow? parse(Object? raw) {
    if (raw is! Map) return null;
    final sex = raw['sex'];
    final unit = raw['unit'];
    final age = raw['age'];
    final low = raw['low'];
    final median = raw['median'];
    final high = raw['high'];
    if (sex != 'boy' && sex != 'girl') return null;
    if (unit != 'week' && unit != 'month') return null;
    if (age is! num || age != age.truncate() || age < 0 || age > 60) {
      return null;
    }
    if (low is! num || median is! num || high is! num) return null;
    if (!(low > 0 && low < median && median < high) || !high.isFinite) {
      return null;
    }
    return GrowthRow(
      boy: sex == 'boy',
      weeks: unit == 'week',
      age: age.toInt(),
      low: low.toDouble(),
      median: median.toDouble(),
      high: high.toDouble(),
    );
  }

  Map<String, Object?> toJson() => {
    'sex': boy ? 'boy' : 'girl',
    'unit': weeks ? 'week' : 'month',
    'age': age,
    'low': low,
    'median': median,
    'high': high,
  };
}

/// A growth table approved on the portal (P-138, Figma C01) and published to
/// `publicConfig/reference_growth_weight` / `_length`. Read between rows by day; an age outside
/// the rows falls back to the bundled WHO LMS tables.
@immutable
class GrowthTable {
  GrowthTable._({
    required this.measure,
    required this.version,
    required this.publishedAt,
    required this.rows,
  }) : _boys = _byDay(rows, boy: true),
       _girls = _byDay(rows, boy: false);

  final GrowthMeasure measure;
  final String version;
  final String publishedAt;
  final List<GrowthRow> rows;
  final List<GrowthRow> _boys;
  final List<GrowthRow> _girls;

  /// Week and month rows of one sex merged by day; week 0 and month 0 are the same day, so the
  /// first one listed wins.
  static List<GrowthRow> _byDay(List<GrowthRow> rows, {required bool boy}) {
    final byDay = <int, GrowthRow>{};
    for (final r in rows) {
      if (r.boy == boy) byDay.putIfAbsent(r.day, () => r);
    }
    return List.unmodifiable(
      byDay.values.toList()..sort((a, b) => a.day.compareTo(b.day)),
    );
  }

  /// Only weight and length are reference data; head circumference stays bundled.
  static String? docId(GrowthMeasure m) => switch (m) {
    GrowthMeasure.weight => 'reference_growth_weight',
    GrowthMeasure.length => 'reference_growth_length',
    GrowthMeasure.head => null,
  };

  static String _dataset(GrowthMeasure m) =>
      m == GrowthMeasure.weight ? 'growth.weight' : 'growth.length';

  /// The published document (or its cached copy) when it is a valid table for [m]: all fields
  /// present, 1–400 valid rows, no row listed twice. Otherwise null.
  static GrowthTable? parse(GrowthMeasure m, Object? data) {
    if (docId(m) == null) return null;
    if (data is! Map || data['dataset'] != _dataset(m)) return null;
    final version = data['version'];
    final publishedAt = data['publishedAt'];
    final raw = data['rows'];
    if (version is! String ||
        !RegExp(r'^v\d{4}\.\d{2}(?:\.\d+)?$').hasMatch(version)) {
      return null;
    }
    if (publishedAt is! String) return null;
    if (raw is! List || raw.isEmpty || raw.length > 400) return null;
    final rows = <GrowthRow>[];
    final keys = <String>{};
    for (final r in raw) {
      final row = GrowthRow.parse(r);
      if (row == null) return null;
      if (!keys.add('${row.boy}:${row.weeks}:${row.age}')) return null;
      rows.add(row);
    }
    return GrowthTable._(
      measure: m,
      version: version,
      publishedAt: publishedAt,
      rows: List.unmodifiable(rows),
    );
  }

  Map<String, Object?> toJson() => {
    'dataset': _dataset(measure),
    'version': version,
    'publishedAt': publishedAt,
    'rows': [for (final r in rows) r.toJson()],
  };

  /// The band at [ageDays], interpolated between the two rows around it; null when the table
  /// has no rows on both sides for this sex.
  GrowthRange? range({required bool boy, required int ageDays}) {
    final t = boy ? _boys : _girls;
    if (t.isEmpty || ageDays < t.first.day || ageDays > t.last.day) {
      return null;
    }
    var i = 0;
    while (i < t.length - 1 && t[i + 1].day <= ageDays) {
      i++;
    }
    final a = t[i];
    if (a.day == ageDays || i == t.length - 1) {
      return (low: a.low, median: a.median, high: a.high);
    }
    final b = t[i + 1];
    final f = (ageDays - a.day) / (b.day - a.day);
    double at(double x, double y) => x + (y - x) * f;
    return (
      low: at(a.low, b.low),
      median: at(a.median, b.median),
      high: at(a.high, b.high),
    );
  }
}

/// The growth standards in use: published weight and length tables where there are valid ones,
/// the bundled WHO LMS tables otherwise (and always for head circumference).
@immutable
class GrowthReference {
  const GrowthReference({this.weight, this.length});

  final GrowthTable? weight;
  final GrowthTable? length;

  static const bundled = GrowthReference();

  GrowthTable? _table(GrowthMeasure m) => switch (m) {
    GrowthMeasure.weight => weight,
    GrowthMeasure.length => length,
    GrowthMeasure.head => null,
  };

  /// 3rd percentile, median and 97th percentile at [ageDays].
  GrowthRange? range(
    GrowthMeasure m, {
    required bool boy,
    required int ageDays,
  }) =>
      _table(m)?.range(boy: boy, ageDays: ageDays) ??
      WhoGrowth.range(m, boy: boy, ageDays: ageDays);

  /// Below the 3rd percentile, above the 97th, or inside the band (D-049).
  GrowthBand? band(
    GrowthMeasure m, {
    required bool boy,
    required int ageDays,
    required double value,
  }) {
    final r = _table(m)?.range(boy: boy, ageDays: ageDays);
    if (r == null) {
      return WhoGrowth.band(m, boy: boy, ageDays: ageDays, value: value);
    }
    if (value <= 0) return null;
    if (value < r.low) return GrowthBand.below;
    if (value > r.high) return GrowthBand.above;
    return GrowthBand.normal;
  }
}

/// [GrowthReference] for the app: the last valid published copies on this device, else bundled;
/// [GrowthReferenceController.refresh] runs once at app start (`ChildLifeApp`).
final growthReferenceProvider =
    NotifierProvider<GrowthReferenceController, GrowthReference>(
      GrowthReferenceController.new,
    );

class GrowthReferenceController extends Notifier<GrowthReference> {
  static const _measures = [GrowthMeasure.weight, GrowthMeasure.length];

  @override
  GrowthReference build() {
    final repo = ref.watch(referenceRepositoryProvider);
    GrowthTable? cached(GrowthMeasure m) =>
        repo.cached(GrowthTable.docId(m)!, (d) => GrowthTable.parse(m, d));
    return GrowthReference(
      weight: cached(GrowthMeasure.weight),
      length: cached(GrowthMeasure.length),
    );
  }

  /// Reads both published tables; a table that cannot be read keeps what we have.
  Future<void> refresh() async {
    final repo = ref.read(referenceRepositoryProvider);
    final tables = <GrowthMeasure, GrowthTable?>{
      GrowthMeasure.weight: state.weight,
      GrowthMeasure.length: state.length,
    };
    for (final m in _measures) {
      try {
        tables[m] = await repo.refresh<GrowthTable>(
          GrowthTable.docId(m)!,
          (d) => GrowthTable.parse(m, d),
          (t) => t.toJson(),
        );
      } on Object {
        // Offline with nothing cached, or Firebase unavailable: keep this table.
      }
    }
    state = GrowthReference(
      weight: tables[GrowthMeasure.weight],
      length: tables[GrowthMeasure.length],
    );
  }
}
