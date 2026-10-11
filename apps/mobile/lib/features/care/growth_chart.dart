import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import 'who_growth.dart';

/// 20d growth card chart (v1.0 improvement): the WHO normal band (3rd–97th percentile) shaded,
/// the WHO median dashed, and the baby's measurements as a line with dots — the latest one solid.
/// Ages run in weeks for the first 13 weeks, then in months.
class WhoGrowthChart extends StatelessWidget {
  const WhoGrowthChart({
    required this.measure,
    required this.boy,
    required this.points,
    required this.unit,
    required this.axisLabel,
    this.height = 180,
    super.key,
  });

  final GrowthMeasure measure;
  final bool boy;

  /// (age in days, value), oldest first.
  final List<(int, double)> points;
  final String unit;

  /// "Sinh" / "1 tuần" / "3 tháng" for an age tick.
  final String Function(GrowthAge) axisLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _GrowthPainter(
          measure: measure,
          boy: boy,
          points: points,
          unit: unit,
          axisLabel: axisLabel,
          band: cl.colors.mintSoft,
          median: cl.colors.mintDeep,
          line: cl.colors.peach,
          dotFill: cl.colors.surface,
          grid: cl.colors.separator,
          label: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  _GrowthPainter({
    required this.measure,
    required this.boy,
    required this.points,
    required this.unit,
    required this.axisLabel,
    required this.band,
    required this.median,
    required this.line,
    required this.dotFill,
    required this.grid,
    required this.label,
  });

  final GrowthMeasure measure;
  final bool boy;
  final List<(int, double)> points;
  final String unit;
  final String Function(GrowthAge) axisLabel;
  final Color band;
  final Color median;
  final Color line;
  final Color dotFill;
  final Color grid;
  final TextStyle label;

  void _text(Canvas c, String t, Offset at, {double align = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: label),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(at.dx - tp.width * align, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lastAge = points.isEmpty ? 0 : points.last.$1;
    // Two ticks past the latest measurement, in weeks while the baby is under 13 weeks.
    final weeks = lastAge < 13 * 7;
    final ages = WhoGrowth.ages(weeks: weeks);
    final lastRow = WhoGrowth.rowFor(ages, lastAge);
    final shown = ages.sublist(
      0,
      math.min(ages.length, math.max(lastRow + 3, 4)),
    );
    final maxDays = shown.last.days.toDouble();

    // Value range from the band and the points, rounded to whole ticks.
    var lo = double.infinity, hi = 0.0;
    for (var d = 0; d <= maxDays; d += math.max(1, maxDays ~/ 40)) {
      final r = WhoGrowth.range(measure, boy: boy, ageDays: d);
      if (r == null) continue;
      lo = math.min(lo, r.low);
      hi = math.max(hi, r.high);
    }
    for (final p in points) {
      lo = math.min(lo, p.$2);
      hi = math.max(hi, p.$2);
    }
    if (!lo.isFinite) return;
    final step = measure == GrowthMeasure.weight
        ? ((hi - lo) / 2 > 2 ? 4.0 : 2.0)
        : ((hi - lo) / 2 > 10 ? 10.0 : 5.0);
    lo = (lo / step).floor() * step;
    hi = (hi / step).ceil() * step;

    const left = 34.0, bottom = 22.0, top = 6.0;
    final w = size.width - left - 6;
    final h = size.height - bottom - top;
    double x(num days) => left + w * (days / maxDays);
    double y(double v) => top + h - h * ((v - lo) / (hi - lo));

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var v = lo; v <= hi + 0.001; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), gridPaint);
      _text(canvas, '${v.round()} $unit', Offset(0, y(v)));
    }
    for (final a in shown) {
      _text(
        canvas,
        axisLabel(a),
        Offset(x(a.days), size.height - 8),
        align: 0.5,
      );
    }

    // Band and median.
    final upper = <Offset>[];
    final lower = <Offset>[];
    final mid = <Offset>[];
    for (var d = 0; d <= maxDays; d += math.max(1, maxDays ~/ 60)) {
      final r = WhoGrowth.range(measure, boy: boy, ageDays: d)!;
      upper.add(Offset(x(d), y(r.high)));
      lower.add(Offset(x(d), y(r.low)));
      mid.add(Offset(x(d), y(r.median)));
    }
    final area = Path()..addPolygon([...upper, ...lower.reversed], true);
    canvas.drawPath(area, Paint()..color = band);
    final dash = Paint()
      ..color = median
      ..strokeWidth = 1.5;
    for (var i = 0; i < mid.length - 1; i += 2) {
      canvas.drawLine(mid[i], mid[i + 1], dash);
    }

    // The baby.
    if (points.isEmpty) return;
    final pts = [for (final p in points) Offset(x(p.$1), y(p.$2))];
    canvas.drawPath(
      Path()..addPolygon(pts, false),
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    for (final (i, p) in pts.indexed) {
      final last = i == pts.length - 1;
      canvas.drawCircle(
        p,
        last ? 6 : 4,
        Paint()..color = last ? line : dotFill,
      );
      if (!last) {
        canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GrowthPainter old) =>
      old.points != points ||
      old.measure != measure ||
      old.boy != boy ||
      old.band != band;
}
