import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/adaptive_engine.dart' show AgeBand;
import '../baby/baby_models.dart';
import '../reminders/reminder_screens.dart' show assigneeName;
import 'care_plan_models.dart';

/// The task's name: its own title for a custom task, else the catalogue name.
String carePlanTaskName(AppLocalizations l10n, CarePlanItem item) =>
    item.task == CarePlanTask.custom && (item.title ?? '').isNotEmpty
    ? item.title!
    : carePlanTaskLabel(l10n, item.task);

String carePlanTaskLabel(AppLocalizations l10n, CarePlanTask t) => switch (t) {
  CarePlanTask.bottle => l10n.cpTaskBottle,
  CarePlanTask.breast => l10n.cpTaskBreast,
  CarePlanTask.pump => l10n.cpTaskPump,
  CarePlanTask.solids => l10n.cpTaskSolids,
  CarePlanTask.water => l10n.cpTaskWater,
  CarePlanTask.sleep => l10n.cpTaskSleep,
  CarePlanTask.diaper => l10n.cpTaskDiaper,
  CarePlanTask.bath => l10n.cpTaskBath,
  CarePlanTask.tummy => l10n.cpTaskTummy,
  CarePlanTask.read => l10n.cpTaskRead,
  CarePlanTask.walk => l10n.cpTaskWalk,
  CarePlanTask.vitamin => l10n.cpTaskVitamin,
  CarePlanTask.medicine => l10n.cpTaskMedicine,
  CarePlanTask.temperature => l10n.cpTaskTemperature,
  CarePlanTask.teeth => l10n.cpTaskTeeth,
  CarePlanTask.potty => l10n.cpTaskPotty,
  CarePlanTask.custom => l10n.cpTaskCustom,
};

String carePlanPeriodLabel(AppLocalizations l10n, CarePlanPeriod p) =>
    switch (p) {
      CarePlanPeriod.morning => l10n.cpMorning,
      CarePlanPeriod.afternoon => l10n.cpAfternoon,
      CarePlanPeriod.evening => l10n.cpEvening,
    };

ClIcons carePlanPeriodIcon(CarePlanPeriod p) => switch (p) {
  CarePlanPeriod.morning => ClIcons.sunrise,
  CarePlanPeriod.afternoon => ClIcons.today,
  CarePlanPeriod.evening => ClIcons.sleep,
};

/// 06 "Hay dùng cho bé …": the tasks a child of this age usually has, first in the picker.
List<CarePlanTask> carePlanSuggested(AgeBand? band) => switch (band) {
  null || AgeBand.b0_1 => const [
    CarePlanTask.bottle,
    CarePlanTask.breast,
    CarePlanTask.sleep,
    CarePlanTask.diaper,
    CarePlanTask.bath,
    CarePlanTask.tummy,
  ],
  AgeBand.b1_3 => const [
    CarePlanTask.solids,
    CarePlanTask.sleep,
    CarePlanTask.bath,
    CarePlanTask.teeth,
    CarePlanTask.potty,
    CarePlanTask.read,
  ],
  AgeBand.b3_6 || AgeBand.b6_12 => const [
    CarePlanTask.teeth,
    CarePlanTask.bath,
    CarePlanTask.read,
    CarePlanTask.walk,
    CarePlanTask.sleep,
  ],
};

/// "Ba" / "Mẹ" / "Cô Lan" / "Bạn" for a uid, or null when they are no longer in the family.
String? carePlanPersonName(
  AppLocalizations l10n,
  List<Membership> members,
  String uid,
  String meUid,
) {
  final m = members.where((m) => m.uid == uid).firstOrNull;
  return m == null ? null : assigneeName(l10n, m, meUid);
}

/// [s] with a capital first letter: "you" / "bạn" standing alone as a label.
String carePlanCapitalized(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Ba", "Ba và Mẹ", "Ba và 2 người".
String carePlanNames(AppLocalizations l10n, List<String> names) =>
    switch (names.length) {
      0 => '',
      1 => names.first,
      2 => l10n.cpNamesTwo(names[0], names[1]),
      _ => l10n.cpNamesMore(names.first, names.length - 1),
    };

/// The task's picture: the care illustrations where the app has one, else an icon chip.
class CarePlanArt extends StatelessWidget {
  const CarePlanArt(this.task, {this.size = 48, super.key});

  final CarePlanTask task;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final care = cl.care;
    final c = cl.colors;
    final (Color soft, ClIllustration? art, ClIcons icon) = switch (task) {
      CarePlanTask.bottle => (
        care.bottle.soft,
        ClIllustration.miniBottle,
        ClIcons.feed,
      ),
      CarePlanTask.breast => (
        care.breast.soft,
        ClIllustration.miniDrop,
        ClIcons.drop,
      ),
      CarePlanTask.pump => (
        care.pump.soft,
        ClIllustration.miniPump,
        ClIcons.drop,
      ),
      CarePlanTask.sleep => (
        care.sleep.soft,
        ClIllustration.miniMoon,
        ClIcons.sleep,
      ),
      CarePlanTask.diaper => (
        care.diaper.soft,
        ClIllustration.miniDiaper,
        ClIcons.diaper,
      ),
      CarePlanTask.solids => (care.bottle.soft, null, ClIcons.bowl),
      CarePlanTask.water => (care.bottle.soft, null, ClIcons.cup),
      CarePlanTask.bath => (c.mintSoft, null, ClIcons.care),
      CarePlanTask.tummy => (c.sunshineSoft, null, ClIcons.hand),
      CarePlanTask.read => (c.peachSoft, null, ClIcons.journal),
      CarePlanTask.walk => (c.mintSoft, null, ClIcons.sunrise),
      CarePlanTask.vitamin => (c.peachSoft, null, ClIcons.drop),
      CarePlanTask.medicine => (c.peachSoft, null, ClIcons.shield),
      CarePlanTask.temperature => (c.peachSoft, null, ClIcons.heart),
      CarePlanTask.teeth => (c.mintSoft, null, ClIcons.spark),
      CarePlanTask.potty => (care.diaper.soft, null, ClIcons.diaper),
      CarePlanTask.custom => (c.surface2, null, ClIcons.star),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(ClRadius.control + 2),
      ),
      alignment: Alignment.center,
      child: art != null
          ? ClArt(art, width: size * 0.7, height: size * 0.7)
          : ClIcon(icon, size: size * 0.45, color: c.ink),
    );
  }
}

/// Who does a task: their names ("Ba và Mẹ"), or "+ Giao" when nobody does. Tappable for
/// managers. Names only: an initial beside "Ba" would say the same thing twice.
class CarePlanPeople extends StatelessWidget {
  const CarePlanPeople({required this.names, required this.onTap, super.key});

  final List<String> names;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final l10n = AppLocalizations.of(context);
    final empty = names.isEmpty;
    final joined = carePlanNames(l10n, names);
    // "you" / "bạn" opens the chip, so it starts with a capital.
    final label = empty ? l10n.cpAssignShort : carePlanCapitalized(joined);
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 32, maxWidth: 132),
      padding: EdgeInsets.fromLTRB(
        ClSpace.s3,
        ClSpace.s1,
        onTap == null || empty ? ClSpace.s3 : ClSpace.s2,
        ClSpace.s1,
      ),
      decoration: BoxDecoration(
        color: empty ? c.surface : c.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        border: empty ? Border.all(color: c.controlBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (empty) ...[
            ClIcon(ClIcons.plus, size: 14, color: c.mintText),
            const SizedBox(width: ClSpace.s1),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: empty ? c.mintText : c.ink,
              ),
            ),
          ),
          if (onTap != null && !empty) ...[
            const SizedBox(width: 2),
            ClIcon(ClIcons.chevronDown, size: 14, color: c.inkMuted),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: label,
        child: ExcludeSemantics(child: chip),
      );
    }
    return ClPressable(onPressed: onTap, semanticLabel: label, child: chip);
  }
}

/// The ring on a task: empty while open, a mint check when done. 44 pt target.
class CarePlanRing extends StatelessWidget {
  const CarePlanRing({
    required this.done,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final bool done;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      selected: done,
      child: SizedBox(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? c.mintDeep : c.surface,
              border: done ? null : Border.all(color: c.inkMuted, width: 2),
            ),
            alignment: Alignment.center,
            child: done
                ? ClIcon(ClIcons.check, size: 16, color: c.onMintDeep)
                : null,
          ),
        ),
      ),
    );
  }
}

/// One task (04): picture, time and name, who, the ring. The next open task has a mint edge.
class CarePlanTaskCard extends StatelessWidget {
  const CarePlanTaskCard({
    required this.item,
    required this.name,
    required this.people,
    required this.status,
    required this.ring,
    this.next = false,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final CarePlanItem item;
  final String name;
  final Widget people;

  /// "Ba đã làm" / "Bỏ qua hôm nay", or null.
  final String? status;
  final Widget? ring;
  final bool next;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final quiet = item.done || item.skipped;
    final body = Container(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s3,
        ClSpace.s3,
        ClSpace.s1,
        ClSpace.s3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
        border: next ? Border.all(color: c.mint, width: 2) : null,
      ),
      child: Row(
        children: [
          Opacity(opacity: quiet ? 0.6 : 1, child: CarePlanArt(item.task)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: cl.text.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: next ? c.mintText : c.inkMuted,
                  ),
                ),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.bodyStrong.copyWith(
                    color: quiet ? c.inkMuted : c.ink,
                    decoration: item.skipped
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: c.inkMuted,
                  ),
                ),
                if (status case final s?)
                  Text(s, style: cl.text.caption.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          people,
          ?ring,
          if (ring == null) const SizedBox(width: ClSpace.s3),
        ],
      ),
    );
    if (onTap == null) return body;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: semanticLabel ?? name,
      child: body,
    );
  }
}

/// 04b: how much of the day is done, as a ring with "3/10".
class CarePlanProgressRing extends StatelessWidget {
  const CarePlanProgressRing({
    required this.done,
    required this.total,
    super.key,
  });

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.cpProgressA11y(done, total),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 64,
          height: 64,
          child: CustomPaint(
            painter: _RingPainter(
              value: total == 0 ? 0 : done / total,
              track: cl.colors.surface,
              fill: cl.colors.mintDeep,
            ),
            child: Center(
              child: Text(
                '$done/$total',
                style: cl.text.bodyStrong.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: cl.colors.onCard,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * value.clamp(0, 1),
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}
