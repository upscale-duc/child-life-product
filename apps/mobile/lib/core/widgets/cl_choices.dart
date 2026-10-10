import 'package:flutter/widgets.dart';

import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';
import 'cl_rows.dart';

/// Single-select filter chip (45:347), h40 with hit slop to 44.
class ClFilterChip extends StatelessWidget {
  const ClFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: selected,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        curve: ClCurves.quick,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintDeep : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: cl.text.body.copyWith(
              fontWeight: FontWeight.w500,
              color: selected ? cl.colors.onMintDeep : cl.colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Relationship chip (115:709): Mẹ, Ba, Bà… SemiBold 14/20.
class ClRelationChip extends StatelessWidget {
  const ClRelationChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: selected,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintDeep : cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: selected ? null : Border.all(color: cl.colors.separator),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: cl.text.label.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? cl.colors.onMintDeep : cl.colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Day strip pill (45:342), 44×64; today is right-most.
class ClDayPill extends StatelessWidget {
  const ClDayPill({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String weekday;
  final String day;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = selected ? cl.colors.onMintDeep : cl.colors.ink;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: semanticLabel ?? '$weekday $day',
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        width: 44,
        height: 64,
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintDeep : cl.colors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected ? null : cl.shadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: cl.text.caption.copyWith(
                color: selected ? cl.colors.onMintDeep : cl.colors.inkMuted,
              ),
            ),
            Text(
              day,
              style: cl.text.headline.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big single-choice tile for one-hand logging (45:386), 106×120, fixed-colour mini art.
class ClChoiceTile extends StatelessWidget {
  const ClChoiceTile({
    required this.label,
    required this.art,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Widget art;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        width: 106,
        height: 120,
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.tile),
          border: selected
              ? Border.all(color: cl.colors.mintDeep, width: 2.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 52, height: 52, child: art),
            const SizedBox(height: ClSpace.s2),
            Text(label, style: cl.text.headline),
          ],
        ),
      ),
    );
  }
}

/// Multi-select tile for trackers (25:399), 166×128.
class ClSelectTile extends StatelessWidget {
  const ClSelectTile({
    required this.label,
    required this.art,
    required this.selected,
    required this.onTap,
    this.width = 166,
    super.key,
  });

  final String label;
  final Widget art;
  final bool selected;
  final VoidCallback onTap;

  /// 166 in the 375 pt frame; pass `double.infinity` inside an Expanded to fill the column.
  final double width;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      checked: selected,
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: context.motion(ClMotion.quick),
          width: width,
          height: 128,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? cl.colors.mintSoft : cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.tile),
            border: selected
                ? Border.all(color: cl.colors.mintDeep, width: 2)
                : null,
            boxShadow: selected ? null : cl.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 48, height: 48, child: art),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: cl.colors.mintDeep,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: ClIcon(
                        ClIcons.check,
                        size: 14,
                        color: cl.colors.onMintDeep,
                      ),
                    ),
                ],
              ),
              Text(label, style: cl.text.headline),
            ],
          ),
        ),
      ),
    );
  }
}

/// What an invited role can / cannot do (23:369), 166×56.
class ClPermissionTile extends StatelessWidget {
  const ClPermissionTile({
    required this.label,
    required this.allowed,
    super.key,
  });

  final String label;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      width: 166,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s3,
        vertical: ClSpace.s2,
      ),
      decoration: BoxDecoration(
        color: allowed ? c.surface : c.surface2,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: allowed ? cl.shadows.card : null,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: allowed ? c.mintDeep : c.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(
              allowed ? ClIcons.check : ClIcons.lock,
              size: allowed ? 14 : 13,
              color: allowed ? c.onMintDeep : c.inkMuted,
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: cl.text.label.copyWith(
                color: allowed ? c.ink : c.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Invite role card (115:679): title, who it is for, permission list.
class ClRoleOption extends StatelessWidget {
  const ClRoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.permissions,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ClIcons icon;
  final String title;
  final String subtitle;

  /// (label, allowed)
  final List<(String, bool)> permissions;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: ClPressable(
        onPressed: onTap,
        pressedScale: 0.98,
        semanticLabel: '$title. $subtitle',
        child: AnimatedContainer(
          duration: context.motion(ClMotion.quick),
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: selected ? c.mintSoft : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? c.mintDeep : c.separator,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? c.mintDeep : c.surface2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: ClIcon(
                      icon,
                      size: 20,
                      color: selected ? c.onMintDeep : c.ink,
                    ),
                  ),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: cl.text.bodyStrong),
                        Text(
                          subtitle,
                          style: cl.text.caption.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  ClRadio(selected: selected),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
              for (final (label, allowed) in permissions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClIcon(
                        allowed ? ClIcons.check : ClIcons.lock,
                        size: 16,
                        color: allowed ? c.ink : c.inkMuted,
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: Text(
                          label,
                          style: cl.text.label.copyWith(
                            color: allowed ? c.ink : c.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large entry choice (69:609). Colours follow a care category (sleep in Figma).
class ClEntryOption extends StatelessWidget {
  const ClEntryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.care,
    required this.onTap,
    this.primary = false,
    super.key,
  });

  final ClIcons icon;
  final String title;
  final String subtitle;
  final ClCareColor care;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      pressedScale: 0.98,
      semanticLabel: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: primary ? care.soft : cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary ? care.accent : cl.colors.separator,
            width: primary ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary ? care.accent : care.soft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(
                icon,
                color: primary ? const Color(0xFFFFFFFF) : care.ink,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.headline),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 20, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
