import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import 'nutrition_format.dart';
import 'nutrition_models.dart';
import 'nutrition_state.dart';
import 'nutrition_widgets.dart';

/// 9c Lượng sữa (Figma `440:4105`, P-163 #2–#5): the last 14 local days of bottle totals against
/// the current stage's daily band (today highlighted; tap a bar for "dd/mm · N ml"), the amounts
/// of every stage (current highlighted), a calm "talk to a paediatrician" note and the sources.
class NutritionMilkScreen extends ConsumerWidget {
  const NutritionMilkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final c = ref.watch(nuContentProvider);
    final data = ref.watch(nuDataProvider);
    if (c == null || data == null) return ColoredBox(color: cl.colors.cloud);
    final b = c.baby;
    final stage = c.stage;
    final band = stage?.milk?.perDayMl;
    final note = nuText(stage?.milk?.breastfeedingNote, locale, b.name);
    final rows = [
      for (final s in c.stages)
        if (s.milk?.perFeedMl != null || s.milk?.perDayMl != null) s,
    ];
    return NuPage(
      children: [
        NuTitle(l10n.nuMilkPageTitle),
        const SizedBox(height: ClSpace.s2),
        Text(
          [
            l10n.nuMilkPageIntro,
            if (note.isNotEmpty) l10n.nuMilkBreast(note),
          ].join(' '),
          style: cl.text.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: cl.colors.inkMuted,
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        NuCard(
          key: const Key('nuMilkChart'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.nuChartTitle,
                  style: cl.text.headline.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                band == null
                    ? l10n.nuChartNoBand
                    : l10n.nuChartBand(nuRangeText(tag, band)),
                style: cl.text.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cl.colors.inkMuted,
                ),
              ),
              const SizedBox(height: ClSpace.s3),
              if (data.daily.every((v) => v == 0))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClSpace.s6),
                  child: Text(
                    l10n.nuChartEmpty,
                    key: const Key('nuChartEmpty'),
                    style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                  ),
                )
              else
                NuMilkChart(daily: data.daily, today: b.today, band: band),
            ],
          ),
        ),
        if (rows.isNotEmpty) ...[
          NuSection(l10n.nuByStageTitle),
          NuGroup(
            inset: 0,
            children: [
              for (final s in rows)
                _StageAmountRow(stage: s, current: s.id == stage?.id),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        NuBanner(text: l10n.nuMilkTalkDoctor, warm: false),
        if (stage != null) NuFootnote(item: stage, doctor: false),
      ],
    );
  }
}

/// "Theo giai đoạn" row: age · amount (per feed, else per day) · feeds and the daily band.
class _StageAmountRow extends StatelessWidget {
  const _StageAmountRow({required this.stage, required this.current});
  final NuStage stage;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final milk = stage.milk!;
    final bottle = cl.care.bottle;
    final amount = milk.perFeedMl != null
        ? l10n.nuPerFeed(nuRangeText(tag, milk.perFeedMl!))
        : l10n.nuPerDay(nuRangeText(tag, milk.perDayMl!));
    final detail = [
      if (milk.feedsPerDay != null)
        l10n.nuFeeds(nuRangeText(tag, milk.feedsPerDay!)),
      if (milk.perFeedMl != null && milk.perDayMl != null)
        l10n.nuPerDay(nuRangeText(tag, milk.perDayMl!)),
    ].join(' · ');
    final age = nuAgeLabel(l10n, stage.age);
    return MergeSemantics(
      child: Container(
        key: Key('nuMilkRow_${stage.id}'),
        color: current ? bottle.soft : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                age,
                style: cl.text.bodyStrong.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: cl.text.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (current) ...[
              const SizedBox(width: 8),
              NuTag(l10n.nuCurrent, fill: cl.colors.surface, ink: bottle.ink),
            ],
          ],
        ),
      ),
    );
  }
}

/// 14 bars of daily bottle totals (oldest first) over the reference band; today's bar is solid,
/// the others at 55 %. Tapping a bar (or its accessibility node) shows "dd/mm · N ml".
class NuMilkChart extends StatefulWidget {
  const NuMilkChart({
    required this.daily,
    required this.today,
    this.band,
    super.key,
  });
  final List<int> daily;
  final DateTime today;
  final NuRange? band;

  @override
  State<NuMilkChart> createState() => _NuMilkChartState();
}

class _NuMilkChartState extends State<NuMilkChart> {
  late int _selected = widget.daily.length - 1;

  DateTime _dayAt(int i) => DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day - (widget.daily.length - 1 - i),
  );

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final bottle = cl.care.bottle;
    final n = widget.daily.length;
    final selected = _selected.clamp(0, n - 1);
    final top = [widget.band?.max ?? 0, ...widget.daily].reduce(math.max);
    final yMax = math.max(1000, (top / 500).ceil() * 500);
    String tip(int i) =>
        l10n.nuChartTooltip(nuDayMonth(_dayAt(i)), nuMl(tag, widget.daily[i]));
    const left = 32.0, bottom = 22.0, chartTop = 6.0, height = 206.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Semantics(
          liveRegion: true,
          child: Container(
            key: const Key('nuChartTip'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cl.colors.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tip(selected),
              style: cl.text.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cl.colors.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _BarsPainter(
                      daily: widget.daily,
                      selected: selected,
                      yMax: yMax,
                      band: widget.band,
                      left: left,
                      bottom: bottom,
                      top: chartTop,
                      bandFill: bottle.soft,
                      bar: bottle.accent,
                      grid: cl.colors.separator,
                      label: cl.text.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: cl.colors.inkMuted,
                      ),
                      todayLabel: cl.text.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cl.colors.ink,
                      ),
                      dayOf: (i) => '${_dayAt(i).day}',
                    ),
                  ),
                ),
              ),
              // One tap target per day, which is also its accessibility node.
              Positioned(
                left: left,
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == selected,
                          label: tip(i),
                          child: GestureDetector(
                            key: Key('nuBar_$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selected = i),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.daily,
    required this.selected,
    required this.yMax,
    required this.band,
    required this.left,
    required this.bottom,
    required this.top,
    required this.bandFill,
    required this.bar,
    required this.grid,
    required this.label,
    required this.todayLabel,
    required this.dayOf,
  });

  final List<int> daily;
  final int selected;
  final int yMax;
  final NuRange? band;
  final double left;
  final double bottom;
  final double top;
  final Color bandFill;
  final Color bar;
  final Color grid;
  final TextStyle label;
  final TextStyle todayLabel;
  final String Function(int) dayOf;

  void _text(
    Canvas c,
    String t,
    Offset at,
    TextStyle style, {
    double align = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(at.dx - tp.width * align, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - left;
    final h = size.height - bottom - top;
    double y(num ml) => top + h - h * (ml / yMax);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var v = 0; v <= yMax; v += 500) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), gridPaint);
      _text(canvas, '$v', Offset(0, y(v)), label);
    }
    final b = band;
    if (b != null) {
      canvas.drawRect(
        Rect.fromLTRB(left, y(b.max), size.width, y(b.min)),
        Paint()..color = bandFill,
      );
    }
    final n = daily.length;
    final slot = w / n;
    final barWidth = math.min(12.0, slot * 0.6);
    for (var i = 0; i < n; i++) {
      final cx = left + slot * (i + 0.5);
      final today = i == n - 1;
      if (daily[i] > 0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            cx - barWidth / 2,
            y(math.min(daily[i], yMax)),
            cx + barWidth / 2,
            y(0),
          ),
          const Radius.circular(5),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = today || i == selected
                ? bar
                : bar.withValues(alpha: 0.55),
        );
      }
      if (i.isEven || today) {
        _text(
          canvas,
          dayOf(i),
          Offset(cx, size.height - 8),
          today ? todayLabel : label,
          align: 0.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.daily != daily ||
      old.selected != selected ||
      old.band != band ||
      old.bar != bar ||
      old.bandFill != bandFill;
}
