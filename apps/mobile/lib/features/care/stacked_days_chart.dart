import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';

/// 20g "Bú mỗi ngày" / 20h "Tổng giờ ngủ mỗi ngày" (v1.0 improvement): one stacked bar per day
/// (bottom part + top part), a dashed average line, and the chosen day — the latest by default —
/// drawn solid with its numbers in a dark callout above the chart. Tap a bar to choose its day.
class StackedDaysChart extends StatefulWidget {
  const StackedDaysChart({
    required this.bottoms,
    required this.tops,
    required this.labels,
    required this.bottomColor,
    required this.topColor,
    required this.average,
    required this.averageLabel,
    required this.tickLabel,
    required this.tipOf,
    this.step,
    this.height = 180,
    super.key,
  }) : assert(bottoms.length == tops.length && tops.length == labels.length);

  final List<double> bottoms;
  final List<double> tops;
  final List<String> labels;
  final Color bottomColor;
  final Color topColor;
  final double average;
  final String averageLabel;

  /// Axis label for a tick value ("4", "6g").
  final String Function(double) tickLabel;

  /// The callout for a day.
  final String Function(int index) tipOf;

  /// Tick spacing; chosen from the data when null.
  final double? step;
  final double height;

  @override
  State<StackedDaysChart> createState() => _StackedDaysChartState();
}

class _StackedDaysChartState extends State<StackedDaysChart> {
  int? _chosen;

  int get _index => (_chosen ?? widget.labels.length - 1).clamp(
    0,
    math.max(0, widget.labels.length - 1),
  );

  @override
  void didUpdateWidget(StackedDaysChart old) {
    super.didUpdateWidget(old);
    if (old.labels.length != widget.labels.length) _chosen = null;
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    if (widget.labels.isEmpty) return const SizedBox.shrink();
    final peak = [
      for (var i = 0; i < widget.tops.length; i++)
        widget.bottoms[i] + widget.tops[i],
      widget.average,
    ].reduce(math.max);
    final step = widget.step ?? _niceStep(peak);
    final max = math.max(step, (peak / step).ceil() * step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: cl.colors.ink,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Text(
              widget.tipOf(_index),
              style: cl.text.caption.copyWith(
                color: cl.colors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        LayoutBuilder(
          builder: (context, box) {
            const left = 28.0;
            final width = box.maxWidth - left;
            final slot = width / widget.labels.length;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final i = ((d.localPosition.dx - left) / slot).floor();
                if (i >= 0 && i < widget.labels.length) {
                  setState(() => _chosen = i);
                }
              },
              child: Semantics(
                label: widget.tipOf(_index),
                child: SizedBox(
                  height: widget.height,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _StackedPainter(
                      bottoms: widget.bottoms,
                      tops: widget.tops,
                      labels: widget.labels,
                      chosen: _index,
                      max: max,
                      step: step,
                      average: widget.average,
                      averageLabel: widget.averageLabel,
                      tickLabel: widget.tickLabel,
                      bottomColor: widget.bottomColor,
                      topColor: widget.topColor,
                      grid: cl.colors.separator,
                      ink: cl.colors.ink,
                      label: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                      bold: cl.text.caption.copyWith(
                        color: cl.colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      left: left,
                      backing: cl.colors.surface,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static double _niceStep(double peak) {
    if (peak <= 0) return 1;
    final raw = peak / 3;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 10.0]) {
      if (raw <= m * mag) return m * mag;
    }
    return 10 * mag;
  }
}

class _StackedPainter extends CustomPainter {
  _StackedPainter({
    required this.bottoms,
    required this.tops,
    required this.labels,
    required this.chosen,
    required this.max,
    required this.step,
    required this.average,
    required this.averageLabel,
    required this.tickLabel,
    required this.bottomColor,
    required this.topColor,
    required this.grid,
    required this.ink,
    required this.label,
    required this.bold,
    required this.left,
    required this.backing,
  });

  final Color backing;

  final List<double> bottoms;
  final List<double> tops;
  final List<String> labels;
  final int chosen;
  final double max;
  final double step;
  final double average;
  final String averageLabel;
  final String Function(double) tickLabel;
  final Color bottomColor;
  final Color topColor;
  final Color grid;
  final Color ink;
  final TextStyle label;
  final TextStyle bold;
  final double left;

  void _text(Canvas c, String t, TextStyle s, Offset at, {double align = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: s),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(at.dx - tp.width * align, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPad = 22.0;
    const topPad = 14.0;
    final h = size.height - bottomPad - topPad;
    final w = size.width - left;
    double y(double v) => topPad + h - h * (v / max);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var v = 0.0; v <= max + 0.001; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), gridPaint);
      _text(canvas, tickLabel(v), label, Offset(0, y(v)));
    }

    final n = labels.length;
    final slot = w / n;
    final barW = math.min(28.0, slot * (n > 10 ? 0.7 : 0.62));
    final everyLabel = n <= 10 ? 1 : (n / 6).ceil();
    for (var i = 0; i < n; i++) {
      final cx = left + slot * (i + 0.5);
      final on = i == chosen;
      final b = bottoms[i];
      final t = tops[i];
      final r = Radius.circular(math.min(6, barW / 2));
      final fade = on ? 1.0 : 0.55;
      if (b + t > 0) {
        // Top part rounded on top; bottom part rounded at the base.
        final topRect = Rect.fromLTRB(
          cx - barW / 2,
          y(b + t),
          cx + barW / 2,
          y(b),
        );
        final bottomRect = Rect.fromLTRB(
          cx - barW / 2,
          y(b),
          cx + barW / 2,
          y(0),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            topRect,
            topLeft: r,
            topRight: r,
            bottomLeft: b == 0 ? r : Radius.zero,
            bottomRight: b == 0 ? r : Radius.zero,
          ),
          Paint()..color = topColor.withValues(alpha: fade),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            bottomRect,
            bottomLeft: r,
            bottomRight: r,
            topLeft: t == 0 ? r : Radius.zero,
            topRight: t == 0 ? r : Radius.zero,
          ),
          Paint()..color = bottomColor.withValues(alpha: fade),
        );
      }
      if (on || i % everyLabel == 0 || i == n - 1) {
        _text(
          canvas,
          labels[i],
          on ? bold : label,
          Offset(cx, size.height - 8),
          align: 0.5,
        );
      }
    }

    if (average > 0) {
      final ay = y(average);
      final dash = Paint()
        ..color = ink
        ..strokeWidth = 1;
      for (var x = left; x < size.width; x += 6) {
        canvas.drawLine(
          Offset(x, ay),
          Offset(math.min(x + 3, size.width), ay),
          dash,
        );
      }
      // On a small backing so it stays readable over a tall bar.
      final tp = TextPainter(
        text: TextSpan(text: averageLabel, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      final box = Rect.fromLTWH(
        size.width - tp.width - 4,
        ay - 8 - tp.height / 2 - 1,
        tp.width + 4,
        tp.height + 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(4)),
        Paint()..color = backing,
      );
      tp.paint(
        canvas,
        Offset(size.width - tp.width - 2, ay - 8 - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_StackedPainter old) =>
      old.chosen != chosen ||
      old.bottoms != bottoms ||
      old.tops != tops ||
      old.max != max ||
      old.bottomColor != bottomColor ||
      old.topColor != topColor;
}
