import 'package:flutter/cupertino.dart';

import '../design/cl_theme.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Button styles from Figma 8:33.
enum ClButtonStyle {
  primary,
  secondary,
  tinted,
  plain,
  outline,
  destructive,
  apple,
}

/// Pill button; label is a 1–2 word verb. One Primary per screen, in the thumb zone.
class ClButton extends StatelessWidget {
  const ClButton({
    required this.label,
    required this.onPressed,
    this.style = ClButtonStyle.primary,
    this.icon,
    this.leading,
    this.expand = false,
    this.loading = false,
    this.wrapLabel = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ClButtonStyle style;

  /// Submitting: a spinner replaces the icon, the label stays, taps are ignored and the button
  /// is not dimmed (it is busy, not unavailable).
  final bool loading;

  /// Let longer action labels grow with accessibility text size instead of truncating.
  final bool wrapLabel;
  final ClIcons? icon;

  /// Custom leading mark (e.g. the Apple logo) when a line icon does not fit.
  final Widget? leading;

  /// Block button: stretch to the parent width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final (fill, ink, border) = switch (style) {
      ClButtonStyle.primary => (c.mintDeep, c.onMintDeep, null),
      ClButtonStyle.secondary => (c.surface2, c.ink, null),
      ClButtonStyle.tinted => (c.mintSoft, c.mintText, null),
      ClButtonStyle.plain => (null, c.mintText, null),
      ClButtonStyle.outline => (
        c.surface,
        c.ink,
        Border.all(color: c.controlBorder, width: 1.5),
      ),
      ClButtonStyle.destructive => (c.errorSoft, c.error, null),
      ClButtonStyle.apple => (c.appleButton, c.appleButtonInk, null),
    };
    final height = switch (style) {
      ClButtonStyle.secondary => 52.0,
      ClButtonStyle.plain => ClSpace.tapMin,
      _ => ClSpace.buttonHeight,
    };
    final padding = style == ClButtonStyle.plain ? ClSpace.s3 : ClSpace.s6;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          CupertinoActivityIndicator(color: ink, radius: 9),
          const SizedBox(width: ClSpace.s2),
        ] else if (leading != null) ...[
          IconTheme(
            data: IconThemeData(color: ink, size: 20),
            child: leading!,
          ),
          const SizedBox(width: ClSpace.s2),
        ] else if (icon != null) ...[
          ClIcon(icon!, size: 18, color: ink),
          const SizedBox(width: ClSpace.s2),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: wrapLabel ? null : 1,
            overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
            style: context.cl.text.bodyStrong.copyWith(color: ink),
          ),
        ),
      ],
    );

    final button = ClPressable(
      onPressed: loading ? () {} : onPressed,
      semanticLabel: label,
      child: Container(
        height: wrapLabel ? null : height,
        constraints: wrapLabel ? BoxConstraints(minHeight: height) : null,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: wrapLabel ? ClSpace.s3 : 0,
        ),
        decoration: BoxDecoration(
          color: fill,
          border: border,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: ExcludeSemantics(child: content),
      ),
    );
    if (!loading) return button;
    return Semantics(liveRegion: true, child: IgnorePointer(child: button));
  }
}

/// Round 64px "next" button (8:34). Icon-only, so the label is mandatory ("Tiếp tục").
class ClRoundButton extends StatelessWidget {
  const ClRoundButton({
    required this.semanticLabel,
    required this.onPressed,
    this.icon = ClIcons.arrowRight,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final ClIcons icon;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: Container(
        width: ClSpace.nextButton,
        height: ClSpace.nextButton,
        decoration: BoxDecoration(color: c.mintDeep, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ClIcon(icon, color: c.onMintDeep),
      ),
    );
  }
}

/// Round 44px back button (8:37). Label "Quay lại" comes from localizations.
class ClBackButton extends StatelessWidget {
  const ClBackButton({
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ClIcon(ClIcons.back, color: c.ink),
      ),
    );
  }
}
