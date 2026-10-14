import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';

/// Building blocks of the v2.0 Nhịp lớn lên frames (extract 30): white cards with the card
/// shadow (or a hairline / mint-deep outline), `surface-2` explanation boxes, mint selection.

/// Radius of the v2.0 cards (Figma 20).
const rhCardRadius = 20.0;

/// A white card (Figma `shadow-card`), optionally outlined: [outline] mint-deep for the active
/// task (H02, AC02), [hairline] for the quiet optional card (H01 "Hỗ trợ phù hợp").
class RhCard extends StatelessWidget {
  const RhCard({
    required this.child,
    this.outline = false,
    this.hairline = false,
    this.color,
    this.padding = const EdgeInsets.all(ClSpace.s4),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final bool outline;
  final bool hairline;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cl.colors.surface,
        borderRadius: BorderRadius.circular(rhCardRadius),
        border: outline
            ? Border.all(color: cl.colors.mintDeep)
            : hairline
            ? Border.all(color: cl.colors.separator)
            : null,
        boxShadow: hairline || color != null ? null : cl.shadows.card,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: semanticLabel,
      child: card,
    );
  }
}

/// The `surface-2` box with an icon: "Vì sao" (H02), "Từ nhật ký" (C02), info strips (AC02).
class RhInfoBox extends StatelessWidget {
  const RhInfoBox({
    required this.text,
    this.icon = ClIcons.eye,
    this.label,
    this.tone = RhInfoTone.neutral,
    this.child,
    super.key,
  });

  final String text;
  final ClIcons? icon;
  final String? label;
  final RhInfoTone tone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (fill, ink, labelInk) = switch (tone) {
      RhInfoTone.neutral => (
        cl.colors.surface2,
        cl.colors.inkMuted,
        cl.colors.ink,
      ),
      RhInfoTone.mint => (
        cl.colors.mintSoft,
        cl.colors.ink,
        cl.colors.mintText,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: ClIcon(icon!, size: 16, color: labelInk),
            ),
            const SizedBox(width: ClSpace.s2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  Text(
                    label!,
                    style: cl.text.label.copyWith(
                      color: labelInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  text,
                  style: cl.text.label.copyWith(color: ink, height: 1.45),
                ),
                ?child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum RhInfoTone { neutral, mint }

/// "Nội dung minh hoạ · chờ chuyên môn duyệt" (11 px, ink-muted).
class RhReviewNote extends StatelessWidget {
  const RhReviewNote(this.review, {this.center = false, super.key});
  final ContentReview? review;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Text(
      reviewLabel(AppLocalizations.of(context), review),
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: cl.text.caption.copyWith(color: cl.colors.inkMuted, fontSize: 11),
    );
  }
}

/// White 44 pt round close / back button of the flow screens (C01, PS01, AC01, HL01).
class RhRoundIcon extends StatelessWidget {
  const RhRoundIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final ClIcons icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      semanticLabel: label,
      onPressed: onPressed,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: cl.colors.ink),
      ),
    );
  }
}

/// A status pill (AC01 "Chưa thử", AC02 "Đã thử · tối 08/10").
class RhPill extends StatelessWidget {
  const RhPill({required this.label, this.icon, this.mint = false, super.key});
  final String label;
  final ClIcons? icon;
  final bool mint;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = mint ? cl.colors.mintText : cl.colors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: 6),
      decoration: BoxDecoration(
        color: mint ? cl.colors.mintSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 14, color: ink),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.caption.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One C01 observation row: 16 radius, icon, label; selected = mint-soft + 1.5 mint-deep.
class RhOptionRow extends StatelessWidget {
  const RhOptionRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final String label;
  final ClIcons icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = selected ? cl.colors.mintText : cl.colors.ink;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cl.colors.mintDeep : cl.colors.separator,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClIcon(icon, size: 18, color: ink),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(
                label,
                style: cl.text.body.copyWith(
                  color: ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Wrap chip of the question cards (C02, NL05b, AC02): selected = mint-soft + 1.5 mint-deep +
/// mint-text bold; unselected = surface + control-border.
class RhChip extends StatelessWidget {
  const RhChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: context.motion(ClMotion.quick),
        width: expand ? double.infinity : null,
        alignment: expand ? Alignment.center : null,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s3,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? cl.colors.mintSoft : cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.control),
          border: Border.all(
            color: selected ? cl.colors.mintDeep : cl.colors.controlBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: cl.text.label.copyWith(
            color: selected ? cl.colors.mintText : cl.colors.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A white question card with a title and wrap chips (C02).
class RhQuestionCard extends StatelessWidget {
  const RhQuestionCard({
    required this.title,
    required this.children,
    super.key,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(rhCardRadius),
        border: Border.all(color: cl.colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: cl.text.bodyStrong),
          const SizedBox(height: ClSpace.s3),
          Wrap(spacing: ClSpace.s2, runSpacing: ClSpace.s2, children: children),
        ],
      ),
    );
  }
}

/// PS01 / PS01F saved banner: mint-soft, a check in a mint-deep circle.
class RhSavedBanner extends StatelessWidget {
  const RhSavedBanner({required this.title, this.subtitle, super.key});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(rhCardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cl.colors.mintDeep,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(
                ClIcons.check,
                size: 16,
                color: cl.colors.onMintDeep,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(
                      color: cl.colors.mintText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: cl.text.label.copyWith(color: cl.colors.mintText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A centred text link (`mint-text`, 13 SemiBold) with a 44 pt target.
class RhLink extends StatelessWidget {
  const RhLink({
    required this.label,
    required this.onTap,
    this.muted = false,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ClSpace.tapMin),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: cl.text.label.copyWith(
              color: muted ? cl.colors.inkMuted : cl.colors.mintText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact pill button inside a card (H02 "Thử hôm nay" / "Không phải hôm nay"): 44 pt,
/// primary mint-deep or secondary surface-2.
class RhPillButton extends StatelessWidget {
  const RhPillButton({
    required this.label,
    required this.onTap,
    this.primary = true,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: ClSpace.tapMin,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: primary ? cl.colors.mintDeep : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cl.text.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primary ? cl.colors.onMintDeep : cl.colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A heading line inside a card ("Cách làm", "Trong lúc chờ").
class RhCardHeading extends StatelessWidget {
  const RhCardHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.cl.text.headline),
  );
}

/// Numbered steps (AC01 "Cách làm", HL01 "Trong lúc chờ").
class RhSteps extends StatelessWidget {
  const RhSteps(this.steps, {super.key});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      children: [
        for (final (i, step) in steps.indexed) ...[
          if (i > 0) const SizedBox(height: ClSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: cl.text.caption.copyWith(
                    color: cl.colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(step, style: cl.text.body),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Bulleted lines ("Đã thay đổi", age card tips).
class RhBullets extends StatelessWidget {
  const RhBullets(this.items, {this.color, super.key});
  final List<String> items;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final style = cl.text.label.copyWith(
      color: color ?? cl.colors.ink,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: style),
                Expanded(child: Text(item, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The icon tile on the left of an activity row (PS01: heart on peach-soft).
class RhIconTile extends StatelessWidget {
  const RhIconTile({required this.icon, this.size = 40, super.key});
  final ClIcons icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cl.colors.peachSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      // Ink on soft warm fills, also in Night care.
      child: ClIcon(icon, size: 20, color: cl.colors.ink),
    );
  }
}

/// Icon for an observation (C01).
ClIcons observationIcon(Observation o) => switch (o) {
  Observation.sleep => ClIcons.sleep,
  Observation.feeding => ClIcons.feed,
  Observation.soothing => ClIcons.heart,
  Observation.newSkill => ClIcons.star,
  Observation.usual => ClIcons.check,
  Observation.health => ClIcons.alert,
};

/// Icon for an activity by its first need.
ClIcons activityIcon(Activity? a) => switch (a?.needs.firstOrNull) {
  Need.sleep => ClIcons.sleep,
  Need.feeding => ClIcons.feed,
  Need.milestone || Need.play => ClIcons.star,
  _ => ClIcons.heart,
};
