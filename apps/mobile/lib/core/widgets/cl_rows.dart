import 'package:flutter/widgets.dart';

import '../design/cl_theme.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_inputs.dart';
import 'cl_pressable.dart';
import 'cl_status.dart';

/// Surface card with radius-card and 1px separators between rows (ListRow / DetailRow / OptionRow).
class ClCardGroup extends StatelessWidget {
  const ClCardGroup({
    required this.children,
    this.shadow,
    this.color,
    super.key,
  });

  final List<Widget> children;

  /// D-096: every card on the page wears `shadow-card` like the Care cards, so it
  /// stands off the Light background (Night care has no card shadow). Default: on, unless a
  /// [color] is given (a tinted group inside a sheet).
  final bool? shadow;

  /// Inside sheets the group sits on surface-2 (14f), elsewhere on surface.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    // A group of fields gets the input stroke around it (see [ClInputGroup]).
    final inputs = children.any((c) => c is ClTextField);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Container(height: 1, color: cl.colors.separator),
          children[i],
        ],
      ],
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: inputs
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(ClRadius.card),
              border: Border.all(color: clInputStroke(cl)),
            )
          : null,
      decoration: BoxDecoration(
        color: color ?? cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: (shadow ?? color == null) ? cl.shadows.card : null,
      ),
      child: inputs ? ClInputGroup(child: column) : column,
    );
  }
}

/// Section header (9:140): headline title + optional mint-text link.
class ClSectionHeader extends StatelessWidget {
  const ClSectionHeader({
    required this.title,
    this.linkLabel,
    this.onLink,
    super.key,
  });

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: cl.text.headline),
            ),
          ),
          if (linkLabel != null)
            ClPressable(
              onPressed: onLink,
              semanticLabel: linkLabel,
              child: Text(
                linkLabel!,
                style: cl.text.label.copyWith(color: cl.colors.mintText),
              ),
            ),
        ],
      ),
    );
  }
}

/// List row (9:139): member or invite. Min height 60.
class ClListRow extends StatelessWidget {
  const ClListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.isInvite = false,
    this.subtitleColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool isInvite;

  /// e.g. error for an overdue reminder; ink-muted otherwise.
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return _RowShell(
      onTap: onTap,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      minHeight: 60,
      children: [
        leading ??
            (isInvite
                ? const ClAvatar(style: ClAvatarStyle.add)
                : const SizedBox.shrink()),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: cl.text.body.copyWith(
                  color: isInvite ? cl.colors.mintText : cl.colors.ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: cl.text.label.copyWith(
                    color: subtitleColor ?? cl.colors.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        if (!isInvite && onTap != null)
          ClIcon(ClIcons.chevronRight, size: 20, color: cl.colors.inkMuted),
      ],
    );
  }
}

/// Settings/detail row (23:244): icon tile, label, value, chevron. Height 56.
class ClDetailRow extends StatelessWidget {
  const ClDetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueIsAccent = false,
    this.onTap,
    super.key,
  });

  final ClIcons icon;
  final String label;
  final String? value;
  final bool valueIsAccent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return _RowShell(
      onTap: onTap,
      semanticLabel: value == null ? label : '$label, $value',
      minHeight: 56,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          alignment: Alignment.center,
          child: ClIcon(icon, size: 18, color: cl.colors.mintText),
        ),
        Expanded(
          child: _LabelValue(
            label: Text(label, style: cl.text.body),
            value: value == null
                ? null
                : Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: cl.text.body.copyWith(
                      color: valueIsAccent
                          ? cl.colors.mintText
                          : cl.colors.inkMuted,
                    ),
                  ),
          ),
        ),
        if (onTap != null)
          ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
      ],
    );
  }
}

/// Read-only key/value row (45:394). Height 56.
class ClInfoRow extends StatelessWidget {
  const ClInfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s2,
        ),
        child: _LabelValue(
          label: Text(
            label,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          value: Text(
            value,
            textAlign: TextAlign.end,
            style: cl.text.bodyStrong,
          ),
        ),
      ),
    );
  }
}

/// Single-select list row (37:348): title + subtitle + radio. Figma uses Inter 12 by mistake;
/// implemented with Text/body + Text/label like ListRow.
class ClOptionRow extends StatelessWidget {
  const ClOptionRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: _RowShell(
        onTap: onTap,
        semanticLabel: subtitle == null ? title : '$title, $subtitle',
        minHeight: 60,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: cl.text.body),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
              ],
            ),
          ),
          ClRadio(selected: selected),
        ],
      ),
    );
  }
}

/// Radio (23:257): 24px, mint-deep with check when selected, 1.5px ring otherwise.
class ClRadio extends StatelessWidget {
  const ClRadio({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ExcludeSemantics(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? c.mintDeep : null,
          border: selected
              ? null
              : Border.all(color: c.controlBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: selected
            ? ClIcon(ClIcons.check, size: 14, color: c.onMintDeep)
            : null,
      ),
    );
  }
}

/// Shared row layout: padding 16, gap 12, whole row tappable.
class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.children,
    required this.minHeight,
    this.onTap,
    this.semanticLabel,
  });

  final List<Widget> children;
  final double minHeight;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s2,
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0 && children[i - 1] is! SizedBox)
              const SizedBox(width: ClSpace.s3),
            children[i],
          ],
        ],
      ),
    );
    if (onTap == null) return MergeSemantics(child: row);
    return ClPressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      pressedOpacity: ClPressable.surfaceOpacity,
      child: ExcludeSemantics(child: row),
    );
  }
}

/// Label on the left, value pushed to the right edge; both wrap instead of truncating so long
/// Vietnamese / English text and 200 % type stay readable.
class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, this.value});

  final Widget label;
  final Widget? value;

  /// The label keeps its natural width (at most 45%); the value takes the rest, so short
  /// labels ("Ngày giờ") leave room for long values ("T7, 10 thg 10 · 08:30").
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (value == null)
          Expanded(child: label)
        else ...[
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
            child: label,
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ],
    ),
  );
}

/// D-096: a picture tile on the page (album cover, video, card, milestone) lifts off the Light
/// background with `shadow-tile`, like the cards around it. Night care has its own tile shadow.
class ClTileShadow extends StatelessWidget {
  const ClTileShadow({required this.child, this.radius = 12, super.key});
  final Widget child;
  final double radius;

  /// Room a horizontal strip leaves under its tiles so the shadow is not cut off.
  static const stripPadding = EdgeInsets.only(top: 2, bottom: 18);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: context.cl.shadows.tile,
    ),
    child: child,
  );
}
