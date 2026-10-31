import 'package:flutter/foundation.dart';

import '../baby/baby_models.dart' show dateOf;
import '../care/care_models.dart';

/// Hiểu con · "Điều đáng chú ý" (D-150 Premium, D-151): what the server computed in
/// `babies/{b}/insights/current` (contracts `insights.ts`, functions `insights.ts`). The app only
/// reads it: the numbers are never recomputed on the phone, so Hôm nay, Hiểu con, Thống kê and
/// Lumi say the same thing.

enum InsightKind {
  nightLongest('night_longest'),
  nightTotal('night_total'),
  nightFeeds('night_feeds');

  const InsightKind(this.wire);
  final String wire;

  bool get isSleep => this != nightFeeds;

  static InsightKind? fromWire(Object? w) {
    for (final k in values) {
      if (k.wire == w) return k;
    }
    return null;
  }
}

/// Why a night was left out (contracts `nightExclusions`).
enum NightExclusion { notEnded, timerOpen, overlap, noSleep, gap }

NightExclusion? _exclusion(Object? w) => switch (w) {
  'not_ended' => NightExclusion.notEnded,
  'timer_open' => NightExclusion.timerOpen,
  'overlap' => NightExclusion.overlap,
  'no_sleep' => NightExclusion.noSleep,
  'gap' => NightExclusion.gap,
  _ => null,
};

@immutable
class InsightPoint {
  const InsightPoint({required this.date, this.value, this.reason});

  /// Baby-local date the night starts on.
  final DateTime date;

  /// Null when the night is not counted.
  final num? value;
  final NightExclusion? reason;
}

@immutable
class Insight {
  const Insight({
    required this.kind,
    required this.up,
    required this.value,
    required this.baselineValue,
    required this.delta,
    required this.recentFrom,
    required this.recentTo,
    required this.baselineFrom,
    required this.baselineTo,
    required this.validNights,
    required this.totalNights,
    required this.points,
    required this.authors,
    required this.todayEligible,
  });

  final InsightKind kind;

  /// Longer / more (true) or shorter / fewer (false) than the week before.
  final bool up;

  /// Minutes for sleep kinds, feeds a night (one decimal) for night feeds.
  final num value;
  final num baselineValue;
  final num delta;
  final DateTime recentFrom;
  final DateTime recentTo;
  final DateTime baselineFrom;
  final DateTime baselineTo;
  final int validNights;
  final int totalNights;

  /// Baseline nights first, then the recent ones.
  final List<InsightPoint> points;

  /// Names as frozen on the records (D-024), never ranked.
  final List<String> authors;
  final bool todayEligible;

  /// Recent nights not counted (for "Đêm 20/10 chưa ghi đủ nên không tính").
  List<DateTime> get leftOut => [
    for (final p in points.skip(points.length - totalNights))
      if (p.value == null) p.date,
  ];

  static Insight? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = InsightKind.fromWire(raw['kind']);
    final recent = raw['recent'], baseline = raw['baseline'];
    final coverage = raw['coverage'];
    DateTime? day(Object? m, String k) =>
        m is Map ? DateTime.tryParse(m[k] as String? ?? '') : null;
    final rf = day(recent, 'from'), rt = day(recent, 'to');
    final bf = day(baseline, 'from'), bt = day(baseline, 'to');
    if (kind == null ||
        rf == null ||
        rt == null ||
        bf == null ||
        bt == null ||
        coverage is! Map ||
        raw['value'] is! num ||
        raw['baselineValue'] is! num ||
        raw['delta'] is! num) {
      return null;
    }
    return Insight(
      kind: kind,
      up: raw['direction'] == 'up',
      value: raw['value'] as num,
      baselineValue: raw['baselineValue'] as num,
      delta: raw['delta'] as num,
      recentFrom: rf,
      recentTo: rt,
      baselineFrom: bf,
      baselineTo: bt,
      validNights: (coverage['valid'] as num? ?? 0).toInt(),
      totalNights: (coverage['total'] as num? ?? 0).toInt(),
      points: [
        for (final p in raw['points'] as List? ?? const [])
          if (p is Map && DateTime.tryParse(p['date'] as String? ?? '') != null)
            InsightPoint(
              date: DateTime.parse(p['date'] as String),
              value: p['value'] as num?,
              reason: _exclusion(p['reason']),
            ),
      ],
      authors: [
        for (final a in raw['authors'] as List? ?? const [])
          if (a is Map && a['name'] is String) a['name'] as String,
      ],
      todayEligible: raw['todayEligible'] != false,
    );
  }
}

/// `babies/{b}/insights/current`.
@immutable
class InsightState {
  const InsightState({
    required this.computedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.lastNight,
    required this.premium,
    required this.items,
    required this.validNights,
    required this.neededNights,
    this.today,
    this.todayOn,
    this.teaser,
    this.teaserUp = true,
    this.teaserOn,
  });

  final DateTime computedAt;

  /// First instant of the baseline: a record saved later from here on makes this stale.
  final DateTime windowStart;

  /// End of the last night counted (06:00): later records do not touch the figures.
  final DateTime windowEnd;

  /// Baby-local date of the last night counted.
  final DateTime lastNight;
  final bool premium;

  /// Best first; empty for a Free household (figures never leave the server, D-151 #9).
  final List<Insight> items;
  final int validNights;
  final int neededNights;

  /// The one insight for Hôm nay on [todayOn] (D-151 #4).
  final InsightKind? today;
  final String? todayOn;

  /// Free: the kind the invite names on [teaserOn].
  final InsightKind? teaser;
  final bool teaserUp;
  final String? teaserOn;

  bool get enoughNights => validNights >= neededNights;

  Insight? item(InsightKind kind) {
    for (final i in items) {
      if (i.kind == kind) return i;
    }
    return null;
  }

  static InsightState? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final computedAt = dateOf(json['computedAt']);
    final windowStart = dateOf(json['windowStart']);
    final windowEnd = dateOf(json['windowEnd']);
    final to = DateTime.tryParse(json['to'] as String? ?? '');
    if (computedAt == null ||
        windowStart == null ||
        windowEnd == null ||
        to == null) {
      return null;
    }
    final progress = json['progress'];
    final teaser = json['teaser'];
    return InsightState(
      computedAt: computedAt,
      windowStart: windowStart,
      windowEnd: windowEnd,
      lastNight: to,
      premium: json['premium'] == true,
      items: [
        for (final raw in json['items'] as List? ?? const [])
          ?Insight.fromJson(raw),
      ],
      validNights: progress is Map
          ? (progress['validNights'] as num? ?? 0).toInt()
          : 0,
      neededNights: progress is Map
          ? (progress['neededNights'] as num? ?? 5).toInt()
          : 5,
      today: InsightKind.fromWire(json['today']),
      todayOn: json['todayOn'] as String?,
      teaser: teaser is Map ? InsightKind.fromWire(teaser['kind']) : null,
      teaserUp: teaser is Map ? teaser['direction'] == 'up' : true,
      teaserOn: json['teaserOn'] as String?,
    );
  }

  /// D-151: once a record of the window was saved after the computation (an edit, a late
  /// entry, a save still pending), the figures are hidden until the server recomputes (≈10 min).
  /// A deletion is not seen here (the live list drops it); the server's recompute covers it.
  bool staleFor(Iterable<CareRecord> records) => records.any(
    (r) =>
        !r.finishedAt.isBefore(windowStart) &&
        r.occurredAt.isBefore(windowEnd) &&
        (r.pending ||
            (r.updatedAt ?? r.createdAt ?? computedAt).isAfter(computedAt)),
  );
}

/// `yyyy-MM-dd` of a baby-local date.
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
