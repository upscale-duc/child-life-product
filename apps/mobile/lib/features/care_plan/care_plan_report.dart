import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart'
    show babyDateBounds, careClockProvider, inBabyZone;
import '../family/family_repository.dart' show familyMembersProvider;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../me/me_widgets.dart';
import 'care_plan_models.dart';
import 'care_plan_report_calc.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

enum CarePlanRange { week, month, year }

/// The first day of [range] around [today] (weeks start on Monday).
DateTime carePlanRangeStart(CarePlanRange range, DateTime today) =>
    switch (range) {
      CarePlanRange.week => DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - 1),
      ),
      CarePlanRange.month => DateTime(today.year, today.month),
      CarePlanRange.year => DateTime(today.year),
    };

/// ISO week number ("Tuần 17").
int carePlanIsoWeek(DateTime d) {
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final first = DateTime(thursday.year);
  return 1 + thursday.difference(first).inDays ~/ 7;
}

/// Everything 11 and 12 draw for one range.
class _ReportData {
  _ReportData({
    required this.range,
    required this.report,
    required this.badges,
    required this.members,
    required this.meUid,
    required this.today,
    required this.babyName,
    this.hearts = 0,
  });

  final CarePlanRange range;
  final CarePlanReport report;
  final List<CarePlanBadgeResult> badges;
  final List<Membership> members;
  final String meUid;
  final DateTime today;
  final String babyName;

  /// Hearts sent in the range (10 Vừa xong, N3).
  final int hearts;

  Membership? member(String uid) =>
      members.where((m) => m.uid == uid).firstOrNull;
}

/// 11 Cùng nhau chăm (Figma 1353:22754, D-138): who did how much this week, month or year, days
/// in a row, on rhythm, and this week's badges; "Khoe cả nhà" opens the share card (12).
class CarePlanReportScreen extends ConsumerStatefulWidget {
  const CarePlanReportScreen({super.key});

  @override
  ConsumerState<CarePlanReportScreen> createState() =>
      _CarePlanReportScreenState();
}

class _CarePlanReportScreenState extends ConsumerState<CarePlanReportScreen> {
  CarePlanRange _range = CarePlanRange.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final babyId = me.babyId;
    final baby = ref.watch(babyProvider(babyId)).value;
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final today = DateUtils.dateOnly(inBabyZone(zone, now));
    final start = carePlanRangeStart(_range, today);
    // Badges are for the last 7 days; "ngày liền" looks back up to 60 days.
    final weekStart = DateTime(today.year, today.month, today.day - 6);
    final streakStart = DateTime(today.year, today.month, today.day - 60);
    final from = start.isBefore(streakStart) ? start : streakStart;
    final since = babyDateBounds(zone, from).start;
    final async = ref.watch(carePlanHistoryProvider((babyId, since)));
    final members = ref.watch(familyMembersProvider(babyId)).value ?? const [];

    final List<Widget> body;
    _ReportData? data;
    if (async.hasError && !async.hasValue) {
      body = [
        MeNotice(
          tone: MeTone.error,
          icon: ClIcons.cloudOff,
          title: l10n.cpLoadFailed,
          onTap: () => ref.invalidate(carePlanHistoryProvider((babyId, since))),
        ),
      ];
    } else if (!async.hasValue) {
      body = const [ClSkeleton(height: 200, radius: ClRadius.card)];
    } else {
      final done = carePlanDoneOf(async.value!, (t) => inBabyZone(zone, t));
      String key(DateTime d) => carePlanDateKey(d);
      final inRange = [
        for (final d in done)
          if (d.date.compareTo(key(start)) >= 0) d,
      ];
      final week = [
        for (final d in done)
          if (d.date.compareTo(key(weekStart)) >= 0) d,
      ];
      data = _ReportData(
        range: _range,
        report: CarePlanReport(inRange, today: today, streakFrom: done),
        badges: carePlanBadges(week, members, today),
        members: members,
        meUid: me.uid,
        today: today,
        babyName: baby?.nickname ?? '',
        hearts: async.value!
            .where(
              (c) => c.action == 'heart' && c.date.compareTo(key(start)) >= 0,
            )
            .length,
      );
      body = [_ReportBody(data: data), const SizedBox(height: ClSpace.s4)];
    }

    final d = data;
    return CarePlanPage(
      title: l10n.cpReportTitle,
      actions: [
        if (d != null && d.report.total > 0)
          CarePlanIconButton(
            key: const Key('cpReportShare'),
            icon: ClIcons.upload,
            semanticLabel: l10n.cpShareTitle,
            onPressed: () => unawaited(_openShare(context, d)),
          ),
      ],
      bottom: d != null && d.report.total > 0
          ? ClButton(
              key: const Key('cpReportShow'),
              label: l10n.cpShowFamily,
              expand: true,
              onPressed: () => unawaited(_openShare(context, d)),
            )
          : null,
      children: [
        const SizedBox(height: ClSpace.s2),
        ClSegmented<CarePlanRange>(
          options: CarePlanRange.values,
          selected: _range,
          onChanged: (r) => setState(() => _range = r),
          labelOf: (r) => switch (r) {
            CarePlanRange.week => l10n.cpRangeWeek,
            CarePlanRange.month => l10n.cpRangeMonth,
            CarePlanRange.year => l10n.cpRangeYear,
          },
        ),
        const SizedBox(height: ClSpace.s4),
        ...body,
      ],
    );
  }
}

/// The donut, the three numbers and the badges.
class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.data});

  final _ReportData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final r = data.report;

    Widget card(Widget child, {EdgeInsets? padding}) => Container(
      padding: padding ?? const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: child,
    );

    final stats = [
      (ClIcons.heart, c.peachSoft, '${data.hearts}', l10n.cpReportHearts),
      (ClIcons.star, c.sunshineSoft, '${r.streak}', l10n.cpReportStreak),
      (ClIcons.clock, c.mintSoft, '${r.onTimePercent}%', l10n.cpReportOnTime),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(
          r.total == 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClSpace.s6),
                  child: Text(
                    l10n.cpReportEmpty,
                    textAlign: TextAlign.center,
                    style: cl.text.body.copyWith(color: c.inkMuted),
                  ),
                )
              : _ShareOfCare(data: data),
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            for (final (i, (icon, tint, value, label)) in stats.indexed) ...[
              if (i > 0) const SizedBox(width: ClSpace.s2),
              Expanded(
                child: card(
                  Semantics(
                    label: '$value $label',
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: tint,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: ClIcon(icon, size: 16, color: c.ink),
                          ),
                          const SizedBox(height: ClSpace.s2),
                          Text(
                            value,
                            style: cl.text.title2.copyWith(
                              color: c.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            label,
                            style: cl.text.caption.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(ClSpace.s3),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.cpBadgesWeek,
                        style: cl.text.headline.copyWith(color: c.ink),
                      ),
                    ),
                  ),
                  Text(
                    '${data.badges.where((b) => b.$2 != null).length}/'
                    '${data.badges.length}',
                    style: cl.text.label.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              _BadgeGrid(
                badges: [
                  // Earned first, as in the frame.
                  ...data.badges.where((b) => b.$2 != null),
                  ...data.badges.where((b) => b.$2 == null),
                ],
                data: data,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The ring of who did how much, and the list beside it ("Mẹ 45%").
class _ShareOfCare extends StatelessWidget {
  const _ShareOfCare({required this.data, this.size = 132});

  final _ReportData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final r = data.report;
    final colors = [
      c.peach,
      c.mint,
      c.sunshine,
      cl.care.sleep.accent,
      cl.care.bottle.accent,
      c.inkMuted,
    ];
    final rows = r.percents;
    String name(String uid) => uid == data.meUid
        ? carePlanCapitalized(
            carePlanPersonName(l10n, data.members, uid, '') ?? '',
          )
        : carePlanCapitalized(
            carePlanPersonName(l10n, data.members, uid, data.meUid) ??
                l10n.cpHistSomeone,
          );
    return Row(
      children: [
        Semantics(
          label: '${r.total} ${l10n.cpReportTasks(r.total)}',
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _DonutPainter(
                  values: [for (final (_, n) in r.byPerson) n.toDouble()],
                  colors: colors,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.total}',
                        style: cl.text.title.copyWith(
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        l10n.cpReportTasks(r.total),
                        style: cl.text.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: ClSpace.s4),
        Expanded(
          child: Column(
            children: [
              for (final (i, (uid, pct)) in rows.take(6).indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      if (data.member(uid) case final m?) ...[
                        CarePlanAvatar(m, size: 24),
                        const SizedBox(width: ClSpace.s2),
                      ],
                      Expanded(
                        child: Text(
                          name(uid),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.label.copyWith(color: c.ink),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: cl.text.bodyStrong.copyWith(
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
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

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return;
    final stroke = size.width * 0.16;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    // A small gap between people, unless one did everything.
    final gap = values.length > 1 ? 0.04 : 0.0;
    var start = -math.pi / 2;
    for (final (i, v) in values.indexed) {
      final sweep = math.pi * 2 * v / total;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        paint..color = colors[i % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.colors != colors;
}

String carePlanBadgeName(AppLocalizations l10n, CarePlanBadge b) => switch (b) {
  CarePlanBadge.bath => l10n.cpBadgeBath,
  CarePlanBadge.night => l10n.cpBadgeNight,
  CarePlanBadge.story => l10n.cpBadgeStory,
  CarePlanBadge.bottle => l10n.cpBadgeBottle,
  CarePlanBadge.diaper => l10n.cpBadgeDiaper,
  CarePlanBadge.grand => l10n.cpBadgeGrand,
  CarePlanBadge.onTime => l10n.cpBadgeOnTime,
  CarePlanBadge.team => l10n.cpBadgeTeam,
  CarePlanBadge.vitamin => l10n.cpBadgeVitamin,
};

/// A badge's picture: the care art where there is one, else an icon.
Widget _badgeArt(BuildContext context, CarePlanBadge b, double size) {
  final c = context.cl.colors;
  final task = switch (b) {
    CarePlanBadge.bath => CarePlanTask.bath,
    CarePlanBadge.night => CarePlanTask.sleep,
    CarePlanBadge.story => CarePlanTask.read,
    CarePlanBadge.bottle => CarePlanTask.bottle,
    CarePlanBadge.diaper => CarePlanTask.diaper,
    _ => null,
  };
  if (task != null) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(child: CarePlanArtBare(task)),
    );
  }
  return ClIcon(
    switch (b) {
      CarePlanBadge.grand => ClIcons.star,
      CarePlanBadge.onTime => ClIcons.clock,
      CarePlanBadge.team => ClIcons.family,
      _ => ClIcons.drop,
    },
    size: size * 0.6,
    color: c.ink,
  );
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.data, this.size = 72});

  final List<CarePlanBadgeResult> badges;
  final _ReportData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 2 * ClSpace.s2) / 3;
        return Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s3,
          children: [
            for (final (b, who) in badges)
              SizedBox(
                width: width,
                child: Semantics(
                  label: who == null
                      ? l10n.cpBadgeLocked(carePlanBadgeName(l10n, b))
                      : who.isEmpty
                      ? carePlanBadgeName(l10n, b)
                      : l10n.cpBadgeBy(
                          carePlanBadgeName(l10n, b),
                          carePlanCapitalized(
                            carePlanPersonName(
                                  l10n,
                                  data.members,
                                  who,
                                  data.meUid,
                                ) ??
                                '',
                          ),
                        ),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        SizedBox.square(
                          dimension: size,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: who == null
                                      ? c.surface2
                                      : c.sunshineSoft,
                                  shape: BoxShape.circle,
                                  border: who == null
                                      ? null
                                      : Border.all(color: c.sunshine, width: 3),
                                ),
                                alignment: Alignment.center,
                                child: Opacity(
                                  opacity: who == null ? 0.5 : 1,
                                  child: _badgeArt(context, b, size * 0.6),
                                ),
                              ),
                              if (who == null)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: ClIcon(
                                      ClIcons.lock,
                                      size: 12,
                                      color: c.inkMuted,
                                    ),
                                  ),
                                )
                              else if (data.member(who) case final m?)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CarePlanAvatar(m, size: 24),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ClSpace.s1),
                        Text(
                          carePlanBadgeName(l10n, b),
                          textAlign: TextAlign.center,
                          style: cl.text.caption.copyWith(
                            color: who == null ? c.inkMuted : c.ink,
                            fontWeight: who == null
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------------------------
// 12 Thẻ chia sẻ
// ---------------------------------------------------------------------------------------------

String _headline(AppLocalizations l10n, _ReportData d) => switch (d.range) {
  CarePlanRange.week => l10n.cpShareHeadline(d.babyName),
  CarePlanRange.month => l10n.cpShareHeadlineMonth(d.babyName),
  CarePlanRange.year => l10n.cpShareHeadlineYear(d.babyName),
};

Future<void> _openShare(BuildContext context, _ReportData data) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        fullscreenDialog: true,
        pageBuilder: (_, _, _) => _ShareCardPage(data: data),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

/// 12 (Figma 1382:22199): the week on one card, and Story / Sao chép / Khác.
class _ShareCardPage extends StatefulWidget {
  const _ShareCardPage({required this.data});

  final _ReportData data;

  @override
  State<_ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<_ShareCardPage> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<File> _image() async {
    final box =
        _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await box.toImage(pixelRatio: 1080 / box.size.width);
    final png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/cung-cham-con-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  String _text(AppLocalizations l10n) {
    final d = widget.data;
    final people = [
      for (final (uid, pct) in d.report.percents)
        '${carePlanCapitalized(carePlanPersonName(l10n, d.members, uid, '') ?? '')} $pct%',
    ].join(' · ');
    return l10n.cpShareText(_headline(l10n, d), d.report.total, people);
  }

  Future<void> _share({required bool withText}) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final file = await _image();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: withText ? _text(l10n) : null,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      toaster.show(message: l10n.cpShareFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final d = widget.data;
    final earned = [
      for (final b in d.badges)
        if (b.$2 != null) b,
    ].take(3).toList();
    final tag = switch (d.range) {
      CarePlanRange.week => l10n.cpShareWeek(carePlanIsoWeek(d.today)),
      CarePlanRange.month => l10n.cpShareMonth(d.today.month),
      CarePlanRange.year => '${d.today.year}',
    };
    final actions = [
      (ClIcons.camera, l10n.cpShareStory, () => _share(withText: false)),
      (
        ClIcons.link,
        l10n.cpShareCopy,
        () async {
          final toaster = ClToaster.of(context);
          await Clipboard.setData(ClipboardData(text: _text(l10n)));
          toaster.show(message: l10n.cpShareCopied);
        },
      ),
      (ClIcons.upload, l10n.cpShareMore, () => _share(withText: true)),
    ];
    return Scaffold(
      backgroundColor: c.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.cpShareTitle,
                        style: cl.text.headline.copyWith(color: c.surface),
                      ),
                    ),
                  ),
                  ClPressable(
                    key: const Key('cpShareClose'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    semanticLabel: l10n.a11yClose,
                    child: SizedBox.square(
                      dimension: ClSpace.tapMin,
                      child: Center(
                        child: ClIcon(
                          ClIcons.close,
                          size: 22,
                          color: c.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              Expanded(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _card,
                    child: Container(
                      padding: const EdgeInsets.all(ClSpace.s4),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(ClRadius.sheet),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c.mintDeep,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: ClIcon(
                                  ClIcons.brandMark,
                                  size: 16,
                                  color: c.onMintDeep,
                                ),
                              ),
                              const SizedBox(width: ClSpace.s2),
                              Expanded(
                                child: Text(
                                  'Child Life',
                                  style: cl.text.label.copyWith(color: c.ink),
                                ),
                              ),
                              Text(
                                tag,
                                style: cl.text.caption.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: ClSpace.s4),
                          Text(
                            _headline(l10n, d),
                            style: cl.text.title2.copyWith(color: c.ink),
                          ),
                          const SizedBox(height: ClSpace.s4),
                          _ShareOfCare(data: d, size: 124),
                          if (earned.isNotEmpty) ...[
                            const SizedBox(height: ClSpace.s4),
                            _BadgeGrid(badges: earned, data: d, size: 64),
                          ],
                          if (d.hearts > 0) ...[
                            const SizedBox(height: ClSpace.s4),
                            Container(
                              padding: const EdgeInsets.all(ClSpace.s3),
                              decoration: BoxDecoration(
                                color: c.peachSoft,
                                borderRadius: BorderRadius.circular(
                                  ClRadius.control,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClIcon(ClIcons.heart, size: 16, color: c.ink),
                                  const SizedBox(width: ClSpace.s2),
                                  Expanded(
                                    child: Text(
                                      l10n.cpShareThanks(d.hearts),
                                      style: cl.text.label.copyWith(
                                        color: c.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (icon, label, onTap) in actions)
                    ClPressable(
                      key: ValueKey('cpShare_$label'),
                      onPressed: _busy ? null : () => unawaited(onTap()),
                      semanticLabel: label,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: c.surface,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: ClIcon(icon, size: 22, color: c.ink),
                          ),
                          const SizedBox(height: ClSpace.s2),
                          Text(
                            label,
                            style: cl.text.caption.copyWith(color: c.surface),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ClSpace.s4),
            ],
          ),
        ),
      ),
    );
  }
}
