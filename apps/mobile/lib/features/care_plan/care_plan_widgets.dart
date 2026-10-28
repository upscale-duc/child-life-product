import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
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
      CarePlanTask.bath => (c.mintSoft, ClIllustration.miniBath, ClIcons.care),
      CarePlanTask.tummy => (c.sunshineSoft, null, ClIcons.hand),
      CarePlanTask.read => (
        c.peachSoft,
        ClIllustration.miniBook,
        ClIcons.journal,
      ),
      CarePlanTask.walk => (c.mintSoft, null, ClIcons.sunrise),
      CarePlanTask.vitamin => (
        c.peachSoft,
        ClIllustration.miniDrop,
        ClIcons.drop,
      ),
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

/// A family member's picture (Figma CCC/Person): Ba, Mẹ, Bà, Ông, or the helper's.
ClIllustration carePlanPersonArt(Membership m) => switch (m.relation) {
  Relation.father => ClIllustration.personBa,
  Relation.mother => ClIllustration.personMe,
  Relation.grandmother => ClIllustration.personBaNoi,
  Relation.grandfather => ClIllustration.personOng,
  Relation.nanny => ClIllustration.personHelper,
  _ =>
    m.role == MemberRole.caregiver
        ? ClIllustration.personHelper
        : ClIllustration.personBa,
};

class CarePlanAvatar extends StatelessWidget {
  const CarePlanAvatar(this.member, {this.size = 24, super.key});

  final Membership member;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: ClArt(carePlanPersonArt(member), width: size, height: size),
  );
}

/// One or two faces side by side, overlapping like the Figma handover header.
class CarePlanFaces extends StatelessWidget {
  const CarePlanFaces(this.members, {this.size = 20, super.key});

  final List<Membership> members;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(2).toList();
    final step = size * 0.6;
    return SizedBox(
      width: size + step * (shown.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: CarePlanAvatar(shown[i], size: size),
            ),
        ],
      ),
    );
  }
}

/// Who does a task (CCC/TaskRow): their faces and names ("Ba và Mẹ"), or a dashed "+ Giao" when
/// nobody does. Tappable for managers.
class CarePlanPeople extends StatelessWidget {
  const CarePlanPeople({
    required this.people,
    required this.names,
    required this.onTap,
    super.key,
  });

  final List<Membership> people;
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
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (empty) ...[
          ClIcon(ClIcons.plus, size: 14, color: c.mintText),
          const SizedBox(width: 2),
        ] else if (people.isNotEmpty) ...[
          CarePlanFaces(people),
          const SizedBox(width: 6),
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
          const SizedBox(width: ClSpace.s1),
          ClIcon(ClIcons.chevronDown, size: 14, color: c.inkMuted),
        ],
      ],
    );
    final padding = EdgeInsets.fromLTRB(
      empty ? ClSpace.s3 : ClSpace.s1 + 2,
      ClSpace.s1,
      onTap == null || empty ? ClSpace.s3 : ClSpace.s2,
      ClSpace.s1,
    );
    final chip = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32, maxWidth: 140),
      child: empty
          ? CustomPaint(
              painter: CarePlanDashedBorder(
                color: c.mint,
                radius: ClRadius.pill,
              ),
              child: Padding(padding: padding, child: row),
            )
          : Container(
              padding: padding,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: row,
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

/// The 1 px dashed outline of the Figma "+ Thêm việc" and "+ Giao" (CCC).
class CarePlanDashedBorder extends CustomPainter {
  const CarePlanDashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = math.min(radius, size.shortestSide / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(r),
        ).deflate(0.6),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(CarePlanDashedBorder old) =>
      old.color != color || old.radius != radius;
}

/// "+ Thêm việc" under each part of the day: a full-width dashed button (Figma 04).
class CarePlanAddButton extends StatelessWidget {
  const CarePlanAddButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: CustomPaint(
        painter: CarePlanDashedBorder(
          color: c.controlBorder,
          radius: ClRadius.card,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: ClSpace.s2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClIcon(ClIcons.plus, size: 16, color: c.mintText),
                const SizedBox(width: ClSpace.s2),
                Flexible(
                  child: Text(
                    label,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.mintText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    this.timeLeading = false,
    super.key,
  });

  /// 02: the time in its own column on the left, the picture smaller (a draft to read through).
  final bool timeLeading;

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
        color: next ? c.mintSoft : c.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
        border: next ? Border.all(color: c.mint, width: 1.5) : null,
      ),
      child: Row(
        children: [
          if (timeLeading) ...[
            SizedBox(
              width: 48,
              child: Text(
                item.time,
                style: cl.text.label.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: c.ink,
                ),
              ),
            ),
            CarePlanArt(item.task, size: 40),
          ] else
            Opacity(opacity: quiet ? 0.6 : 1, child: CarePlanArt(item.task)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!timeLeading)
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

/// The Cùng Chăm Con pages' bar (Figma 04, 01, 13, 17): a bare back chevron, the title beside
/// it, and up to two icon actions on the right.
class CarePlanBar extends StatelessWidget {
  const CarePlanBar({required this.title, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        CarePlanIconButton(
          icon: ClIcons.back,
          semanticLabel: l10n.a11yBack,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.headline.copyWith(color: cl.colors.ink),
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}

class CarePlanIconButton extends StatelessWidget {
  const CarePlanIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final ClIcons icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ClPressable(
    onPressed: onPressed,
    semanticLabel: semanticLabel,
    child: SizedBox.square(
      dimension: ClSpace.tapMin,
      child: Center(
        child: ClIcon(icon, size: 22, color: context.cl.colors.ink),
      ),
    ),
  );
}

/// A Cùng Chăm Con page: [CarePlanBar] pinned on top, the content scrolling under it, and an
/// optional [bottom] action that stays above the home indicator.
class CarePlanPage extends StatelessWidget {
  const CarePlanPage({
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.floating,
    super.key,
  });

  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? bottom;
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final inset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      floatingActionButton: floating,
      body: ClPinnedHeaderScaffold(
        header: CarePlanBar(title: title, actions: actions),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  0,
                  ClSpace.s4,
                  bottom != null
                      ? ClSpace.s4
                      : inset + (floating == null ? ClSpace.s6 : 96),
                ),
                children: children,
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  inset + ClSpace.s3,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}
