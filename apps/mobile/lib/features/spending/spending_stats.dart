import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import 'spending_calc.dart';
import 'spending_format.dart';
import 'spending_models.dart';
import 'spending_widgets.dart';

enum SpendingWindow { month, sixMonths, sinceBirth }

/// 8d / 8e: statistics (and the month by category). Needs "Xem toàn bộ" (or Cùng nuôi).
class SpendingStatsScreen extends ConsumerStatefulWidget {
  const SpendingStatsScreen({super.key});

  @override
  ConsumerState<SpendingStatsScreen> createState() =>
      _SpendingStatsScreenState();
}

class _SpendingStatsScreenState extends ConsumerState<SpendingStatsScreen> {
  var _window = SpendingWindow.sixMonths;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    return SpPage(
      children: [
        SpTitle(l10n.spStatsTitle),
        const SizedBox(height: ClSpace.s4),
        ClSegmented<SpendingWindow>(
          options: SpendingWindow.values,
          selected: _window,
          labelOf: (w) => switch (w) {
            SpendingWindow.month => l10n.spWindowMonth,
            SpendingWindow.sixMonths => l10n.spWindowSix,
            SpendingWindow.sinceBirth => l10n.spWindowBirth,
          },
          onChanged: (w) => setState(() => _window = w),
        ),
        const SizedBox(height: ClSpace.s4),
        if (!scope.access.viewAll)
          SpBanner(icon: ClIcons.lock, text: l10n.spOwnOnlyNote)
        else
          ...switch (_window) {
            SpendingWindow.month => _month(context, scope),
            SpendingWindow.sixMonths => _six(context, scope),
            SpendingWindow.sinceBirth => _birth(context, scope),
          },
      ],
    );
  }

  List<Widget> _month(BuildContext context, SpendingScope scope) {
    final l10n = AppLocalizations.of(context);
    final locale = spLocale(context);
    final cur = scope.currency;
    final s = MonthSummary.of(
      scope.expenses,
      monthOf(scope.today),
      scope.today,
      currency: cur,
    );
    return [
      _Kpis([
        (moneyShort(l10n, locale, s.total, cur), l10n.spMonthTotal),
        (moneyShort(l10n, locale, s.averagePerDay, cur), l10n.spAvgPerDay),
        ('${s.items.length}', l10n.spCount),
      ]),
      ..._others(context, s.others),
      const SizedBox(height: ClSpace.s6),
      ClSectionHeader(title: l10n.spByCategory),
      const SizedBox(height: ClSpace.s2),
      if (s.ranked.isEmpty)
        SpBanner(icon: ClIcons.today, text: l10n.spMonthEmpty)
      else
        SpGroup(
          children: [
            for (final e in s.ranked)
              CategoryShareRow(
                category: scope.category(e.key),
                amount: e.value,
                currency: cur,
                share: e.value / s.total,
                subline: percent(e.value / s.total),
              ),
          ],
        ),
    ];
  }

  /// D-075 #4: what was spent in other currencies over the same period, never added in.
  List<Widget> _others(BuildContext context, Map<String, int> others) {
    if (others.isEmpty) return const [];
    final cl = context.cl;
    return [
      const SizedBox(height: ClSpace.s2),
      Text(
        AppLocalizations.of(
          context,
        ).spOtherCurrenciesNote(moneyList(spLocale(context), others)),
        key: const Key('spStatsOtherCurrencies'),
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
    ];
  }

  List<Widget> _six(BuildContext context, SpendingScope scope) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final cur = scope.currency;
    final six = SixMonths.of(scope.expenses, scope.today, currency: cur);
    final sixOthers = otherTotals(
      scope.expenses.where((e) => six.months.any((m) => inMonth(e, m))),
      cur,
    );
    String short(int v) => moneyShort(l10n, locale, v, cur);
    final high = six.bars[six.highestIndex];
    final highMonth = six.months[six.highestIndex];
    final colors = [
      for (final id in six.legend)
        tintColors(context, scope.category(id).tint).accent,
    ];
    String legendName(String id) =>
        id == otherCategoryId && six.byCategory.length > six.legend.length
        ? l10n.spOthersFolded
        : categoryName(l10n, scope.category(id));
    final payerColors = [
      cl.colors.mintDeep,
      cl.colors.peach,
      cl.colors.sunshine,
      cl.care.sleep.accent,
      cl.care.bottle.accent,
    ];
    return [
      _Kpis([
        (short(six.total), l10n.spSixTotal),
        (short(six.averagePerMonth), l10n.spAvgPerMonth),
        (short(high.total), l10n.spHighest(highMonth.month)),
      ]),
      ..._others(context, sixOthers),
      const SizedBox(height: ClSpace.s4),
      SpCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.spByMonth, style: cl.text.headline),
            Text(
              l10n.spCountedTo(
                scope.today.month,
                DateFormat('dd/MM').format(scope.today),
              ),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s3),
            SpendingBarsChart(
              bars: six.bars,
              colors: colors.isEmpty ? [cl.colors.mintDeep] : colors,
              labels: [for (final m in six.months) l10n.spMonthTick(m.month)],
              average: six.averagePerMonth,
              averageLabel: l10n.spAvgLine(short(six.averagePerMonth)),
              tickLabel: (v) => moneyTick(l10n, locale, v, cur),
              tipOf: (i) => l10n.spTip(
                l10n.spMonthTick(six.months[i].month),
                short(six.bars[i].total),
              ),
            ),
            if (six.legend.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s3),
              _Legend([
                for (var i = 0; i < six.legend.length; i++)
                  (colors[i], legendName(six.legend[i])),
              ]),
            ],
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s6),
      ClSectionHeader(title: l10n.spByCategory),
      const SizedBox(height: ClSpace.s2),
      if (six.byCategory.isEmpty)
        SpBanner(icon: ClIcons.today, text: l10n.spNothingYet)
      else
        SpGroup(
          children: [
            for (final e in six.byCategory)
              CategoryShareRow(
                category: scope.category(e.key),
                amount: e.value,
                currency: cur,
                share: e.value / six.total,
                subline: percent(e.value / six.total),
              ),
          ],
        ),
      if (six.byPayer.isNotEmpty) ...[
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(title: l10n.spPayer),
        const SizedBox(height: ClSpace.s2),
        SpCard(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      for (var i = 0; i < six.byPayer.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          flex: math.max(1, six.byPayer[i].amount ~/ 1000),
                          child: ColoredBox(
                            color: payerColors[i % payerColors.length],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ClSpace.s3),
              for (var i = 0; i < six.byPayer.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: payerColors[i % payerColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: Text(
                          payerLabel(l10n, six.byPayer[i].payer),
                          style: cl.text.body,
                        ),
                      ),
                      ClTabularText(
                        '${money(locale, six.byPayer[i].amount, cur)} · '
                        '${percent(six.byPayer[i].amount / six.total)}',
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _birth(BuildContext context, SpendingScope scope) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = spLocale(context);
    final dob = ref
        .watch(babyPrivateProfileProvider(scope.babyId))
        .value
        ?.dateOfBirth;
    final cur = scope.currency;
    final b = SinceBirth.of(scope.expenses, scope.today, dob, currency: cur);
    final birthOthers = otherTotals(scope.expenses, cur);
    final name = scope.baby?.nickname ?? '';
    return [
      SpCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dob == null
                  ? l10n.spSinceFirst
                  : b.months == 0
                  ? l10n.spSinceBirthYoung(name)
                  : l10n.spSinceBirth(name, b.months),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            ClTabularText(
              money(locale, b.total, cur),
              style: cl.text.largeTitle.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              l10n.spSinceBirthSub(
                moneyShort(l10n, locale, b.averagePerMonth, cur),
                b.count,
              ),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            ..._others(context, birthOthers),
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s4),
      SpCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.spByAge, style: cl.text.headline),
            const SizedBox(height: ClSpace.s3),
            SpendingBarsChart(
              bars: b.bars,
              colors: [cl.colors.mintDeep],
              labels: [for (final bar in b.bars) bar.label],
              tickLabel: (v) => moneyTick(l10n, locale, v, cur),
              tipOf: (i) => l10n.spTip(
                i == 0 ? l10n.spFirstMonth : l10n.spAgeMonth(i),
                moneyShort(l10n, locale, b.bars[i].total, cur),
              ),
            ),
          ],
        ),
      ),
      if (b.largest.isNotEmpty) ...[
        const SizedBox(height: ClSpace.s6),
        ClSectionHeader(title: l10n.spLargest),
        const SizedBox(height: ClSpace.s2),
        SpGroup(
          children: [
            for (final e in b.largest)
              ExpenseRow(
                expense: e,
                category: scope.category(e.categoryId),
                subline: expenseSubline(
                  l10n,
                  e,
                  lead: DateFormat('MM/yyyy').format(e.spentOn),
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: ClSpace.s6),
      ClButton(
        key: const Key('spExport'),
        label: l10n.spExport,
        icon: ClIcons.download,
        style: ClButtonStyle.secondary,
        expand: true,
        onPressed: scope.expenses.isEmpty
            ? null
            : () => unawaited(_export(context, scope)),
      ),
      const SizedBox(height: ClSpace.s3),
      Text(
        l10n.spOwnFamilyOnly,
        textAlign: TextAlign.center,
        style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
      ),
    ];
  }

  /// P-140: built on the device, shared with the share sheet; no receipts.
  Future<void> _export(BuildContext context, SpendingScope scope) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final csv = expensesCsv(
      scope.expenses,
      header: [
        l10n.spDate,
        l10n.spCategory,
        l10n.spNote,
        l10n.spAmount,
        l10n.spCurrency,
        l10n.spPayer,
        l10n.spRecordedBy,
      ],
      category: (e) => categoryName(l10n, scope.category(e.categoryId)),
      payer: (e) => payerLabel(l10n, e.payer),
      recordedBy: (e) => authorLabel(
        l10n,
        e.author,
        isMe: false,
        relationLabel: (r, c) => relationLabel(l10n, r, c),
      ),
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${l10n.spExportFile(isoDay(scope.today))}.csv',
      );
      await file.writeAsBytes(utf8.encode(csv), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      toaster.show(message: l10n.spExportFailed);
    }
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis(this.items);
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClTabularText(
                    items[i].$1,
                    style: cl.text.headline.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    items[i].$2,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.items);
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Wrap(
      spacing: ClSpace.s3,
      runSpacing: ClSpace.s1,
      children: [
        for (final (color, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
      ],
    );
  }
}

/// 8d / 8e: one bar per month, stacked by category (bottom first), the chosen bar solid with its
/// callout and the others at 55 %; an optional dashed average. Tap a bar to choose it.
class SpendingBarsChart extends StatefulWidget {
  const SpendingBarsChart({
    required this.bars,
    required this.colors,
    required this.labels,
    required this.tickLabel,
    required this.tipOf,
    this.average = 0,
    this.averageLabel = '',
    this.height = 200,
    super.key,
  });

  final List<BarStack> bars;
  final List<Color> colors;
  final List<String> labels;
  final int average;
  final String averageLabel;
  final String Function(double value) tickLabel;
  final String Function(int index) tipOf;
  final double height;

  @override
  State<SpendingBarsChart> createState() => _SpendingBarsChartState();
}

class _SpendingBarsChartState extends State<SpendingBarsChart> {
  int? _chosen;

  int get _index {
    if (_chosen != null) return _chosen!.clamp(0, widget.bars.length - 1);
    // The largest bar by default (8d "T9", 8e "Tháng đầu").
    var best = widget.bars.length - 1;
    for (var i = 0; i < widget.bars.length; i++) {
      if (widget.bars[i].total > widget.bars[best].total) best = i;
    }
    return best;
  }

  static double _step(double peak) {
    if (peak <= 0) return 1000000;
    final raw = peak / 2;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (raw <= m * mag) return m * mag;
    }
    return 10 * mag;
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    if (widget.bars.isEmpty) return const SizedBox.shrink();
    final peak = [
      for (final b in widget.bars) b.total.toDouble(),
      widget.average.toDouble(),
    ].reduce(math.max);
    final step = _step(peak);
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
              borderRadius: BorderRadius.circular(10),
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
            const left = 36.0;
            final slot = (box.maxWidth - left) / widget.bars.length;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final i = ((d.localPosition.dx - left) / slot).floor();
                if (i >= 0 && i < widget.bars.length) {
                  setState(() => _chosen = i);
                }
              },
              child: Semantics(
                label: widget.tipOf(_index),
                child: SizedBox(
                  height: widget.height,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BarsPainter(
                      bars: widget.bars,
                      colors: widget.colors,
                      labels: widget.labels,
                      chosen: _index,
                      max: max,
                      step: step,
                      average: widget.average.toDouble(),
                      averageLabel: widget.averageLabel,
                      tickLabel: widget.tickLabel,
                      grid: cl.colors.separator,
                      ink: cl.colors.ink,
                      backing: cl.colors.surface,
                      label: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                        fontSize: 10,
                      ),
                      bold: cl.text.caption.copyWith(
                        color: cl.colors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                      left: left,
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
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.bars,
    required this.colors,
    required this.labels,
    required this.chosen,
    required this.max,
    required this.step,
    required this.average,
    required this.averageLabel,
    required this.tickLabel,
    required this.grid,
    required this.ink,
    required this.backing,
    required this.label,
    required this.bold,
    required this.left,
  });

  final List<BarStack> bars;
  final List<Color> colors;
  final List<String> labels;
  final int chosen;
  final double max;
  final double step;
  final double average;
  final String averageLabel;
  final String Function(double) tickLabel;
  final Color grid;
  final Color ink;
  final Color backing;
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
    const bottomPad = 20.0;
    const topPad = 10.0;
    final h = size.height - bottomPad - topPad;
    double y(double v) => topPad + h - h * (v / max);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var v = 0.0; v <= max + 0.001; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), gridPaint);
      _text(canvas, tickLabel(v), label, Offset(0, y(v)));
    }
    final n = bars.length;
    final slot = (size.width - left) / n;
    final barW = math.min(26.0, slot * 0.6);
    final r = Radius.circular(math.min(6, barW / 2));
    for (var i = 0; i < n; i++) {
      final cx = left + slot * (i + 0.5);
      final fade = i == chosen ? 1.0 : 0.55;
      final segs = bars[i].segments;
      final total = bars[i].total;
      var base = 0.0;
      // The top-most non-empty part gets the rounded top.
      final last = segs.lastIndexWhere((v) => v > 0);
      for (var s = 0; s < segs.length; s++) {
        final v = segs[s].toDouble();
        if (v <= 0) continue;
        final rect = Rect.fromLTRB(
          cx - barW / 2,
          y(base + v),
          cx + barW / 2,
          y(base),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: s == last ? r : Radius.zero,
            topRight: s == last ? r : Radius.zero,
          ),
          Paint()..color = colors[s % colors.length].withValues(alpha: fade),
        );
        base += v;
      }
      if (total == 0) {
        canvas.drawLine(
          Offset(cx - barW / 2, y(0)),
          Offset(cx + barW / 2, y(0)),
          Paint()
            ..color = grid
            ..strokeWidth = 2,
        );
      }
      final every = n <= 8 ? 1 : (n / 8).ceil();
      if (i == chosen || i % every == 0 || i == n - 1) {
        _text(
          canvas,
          labels[i],
          i == chosen ? bold : label,
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
      final tp = TextPainter(
        text: TextSpan(text: averageLabel, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left + 2,
            ay - 8 - tp.height / 2 - 1,
            tp.width + 4,
            tp.height + 2,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = backing,
      );
      tp.paint(canvas, Offset(left + 4, ay - 8 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.chosen != chosen ||
      old.bars != bars ||
      old.max != max ||
      old.colors != colors;
}
