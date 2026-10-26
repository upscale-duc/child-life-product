import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tabular_text.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Text field (23:243): caption label above the value. Grouped = row inside a card;
/// Resting stroke of every input, so a field reads as a field on any surface (owner feedback,
/// 2026-10-11): ink-muted at 35 %, visible on Light and Night care sheets alike.
Color clInputStroke(ClTheme cl) => cl.colors.inkMuted.withValues(alpha: 0.35);

/// Marks fields stacked inside a [ClCardGroup]: the group draws the one stroke around them, so
/// each field only shows its focus ring.
class ClInputGroup extends InheritedWidget {
  const ClInputGroup({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClInputGroup>() != null;

  @override
  bool updateShouldNotify(ClInputGroup oldWidget) => false;
}

/// Standalone = its own surface card with shadow-card. Focus = 2px focus-ring (no Figma variant).
class ClTextField extends StatefulWidget {
  const ClTextField({
    this.label,
    this.controller,
    this.placeholder,
    this.standalone = false,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.maxLines = 1,
    this.focusNode,
    super.key,
  });

  /// Caption above the value. Without one, the placeholder sits alone in the field, centred
  /// like a labelled field's value (an empty label used to leave a blank line above it).
  final String? label;
  final TextEditingController? controller;
  final String? placeholder;
  final bool standalone;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  /// Hard limit without a visible counter (names: 30 / 40 / 24 characters, contracts).
  final int? maxLength;

  /// More than 1: grows with the text up to this many lines (captions, messages).
  final int maxLines;

  /// To focus the field from outside (e.g. "Gửi link đăng nhập" without an email); owned by
  /// the caller. Null = the field's own.
  final FocusNode? focusNode;

  @override
  State<ClTextField> createState() => _ClTextFieldState();
}

class _ClTextFieldState extends State<ClTextField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());
  bool _obscured = true;

  void _focusChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(ClTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _own)?.removeListener(_focusChanged);
      _focus.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _own?.dispose();
    super.dispose();
  }

  bool get _literal =>
      widget.password || widget.keyboardType == TextInputType.emailAddress;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final focused = _focus.hasFocus;
    final grouped = ClInputGroup.of(context);
    final label = widget.label;
    final multiline = widget.maxLines > 1;
    // Width of the resting border the focus ring replaces.
    final stroke = grouped ? 0.0 : 1.0;
    return AnimatedContainer(
      duration: context.motion(ClMotion.quick),
      curve: ClCurves.quick,
      // Alone, the 1 px resting stroke becomes the 2 px focus ring; in a group the group carries
      // the stroke and the field shows only the ring. Padding gives back the ring's extra width
      // so the text never shifts.
      padding: EdgeInsets.symmetric(
        horizontal: ClSpace.s4 - (focused ? 2 - stroke : 0),
        vertical: ClSpace.s3 - (focused ? 2 - stroke : 0),
      ),
      decoration: BoxDecoration(
        color: widget.standalone ? cl.colors.surface : null,
        borderRadius: grouped && !focused
            ? null
            : BorderRadius.circular(ClRadius.card),
        boxShadow: widget.standalone ? cl.shadows.card : null,
        border: focused
            ? Border.all(color: cl.colors.focusRing, width: 2)
            : grouped
            ? null
            : Border.all(color: clInputStroke(cl)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null && label.isNotEmpty) ...[
                  Text(
                    label,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                  const SizedBox(height: 2),
                ] else
                  // The same height as a labelled field: half the caption line above and below.
                  SizedBox(height: _captionLine(cl) / 2 + 1),
                CupertinoTextField.borderless(
                  controller: widget.controller,
                  focusNode: _focus,
                  padding: EdgeInsets.zero,
                  placeholder: widget.placeholder,
                  placeholderStyle: cl.text.body.copyWith(
                    color: cl.colors.inkMuted,
                  ),
                  style: cl.text.body,
                  cursorColor: cl.colors.mintDeep,
                  obscureText: widget.password && _obscured,
                  minLines: 1,
                  maxLines: widget.maxLines,
                  keyboardType:
                      widget.keyboardType ??
                      (multiline ? TextInputType.multiline : null),
                  textInputAction:
                      widget.textInputAction ??
                      (multiline ? TextInputAction.newline : null),
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textCapitalization: widget.textCapitalization,
                  maxLength: widget.maxLength,
                  // Emails and passwords must arrive exactly as typed (no autocorrect,
                  // suggestions or smart punctuation).
                  autocorrect: !_literal,
                  enableSuggestions: !_literal,
                  smartDashesType: _literal ? SmartDashesType.disabled : null,
                  smartQuotesType: _literal ? SmartQuotesType.disabled : null,
                ),
                if (label == null || label.isEmpty)
                  SizedBox(height: _captionLine(cl) / 2 + 1),
              ],
            ),
          ),
          if (widget.password)
            ClPressable(
              semanticLabel: _obscured ? l10n.showPassword : l10n.hidePassword,
              onPressed: () => setState(() => _obscured = !_obscured),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ClIcon(ClIcons.eye, size: 18, color: cl.colors.ink),
              ),
            ),
        ],
      ),
    );
  }
}

double _captionLine(ClTheme cl) =>
    (cl.text.caption.fontSize ?? 12) * (cl.text.caption.height ?? 1.3);

/// iOS-style switch (23:262): mint-deep on, separator off, white knob (both modes).
class ClToggle extends StatelessWidget {
  const ClToggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Semantics(
      label: semanticLabel,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: c.mintDeep,
        inactiveTrackColor: c.separator,
        thumbColor: const Color(0xFFFFFFFF),
      ),
    );
  }
}

/// Setting row with a switch (23:340): standalone surface card.
class ClSettingRow extends StatelessWidget {
  const ClSettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final ClIcons icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cl.colors.cardNight,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon, size: 20, color: nightCareColors.ink),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: cl.text.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            ClToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Invite code entry (23:355). Screens use 6 digits (P-020), so the default is 6 numeric chars.
class ClCodeInput extends StatelessWidget {
  const ClCodeInput({
    this.controller,
    this.length = 6,
    this.onCompleted,
    this.semanticLabel,
    super.key,
  });

  final TextEditingController? controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: clInputStroke(cl)),
        ),
        alignment: Alignment.center,
        child: Semantics(
          label: semanticLabel,
          textField: true,
          child: CupertinoTextField.borderless(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            cursorColor: cl.colors.mintDeep,
            style: cl.text.title2.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 6,
              height: 1.2,
            ),
            onChanged: (value) {
              if (value.length == length) onCompleted?.call(value);
            },
          ),
        ),
      ),
    );
  }
}

/// Numeric amount (45:403) in numeral-xl with steady digits. Focused = mint-soft + 2px mint-deep.
class ClAmountField extends StatelessWidget {
  const ClAmountField({
    required this.value,
    required this.unit,
    this.focused = false,
    this.onTap,
    super.key,
  });

  final String value;
  final String unit;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final field = AnimatedContainer(
      duration: context.motion(ClMotion.quick),
      height: 88,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: focused ? cl.colors.mintSoft : cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.card),
        border: focused
            ? Border.all(color: cl.colors.mintDeep, width: 2)
            : Border.all(color: clInputStroke(cl)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ClTabularText(value, style: cl.text.numeralXl),
          const SizedBox(width: ClSpace.s2),
          Text(
            unit,
            style: cl.text.headline.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: '$value $unit',
        child: ExcludeSemantics(child: field),
      );
    }
    return ClPressable(
      onPressed: onTap,
      pressedOpacity: 1,
      semanticLabel: '$value $unit',
      child: field,
    );
  }
}

/// "When it happened" row (45:387): default now; tapping the chip opens a wheel.
class ClTimeRow extends StatelessWidget {
  const ClTimeRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = ClIcons.clock,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final ClIcons icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final chip = ClPressable(
      onPressed: onTap,
      semanticLabel: '$label, $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cl.colors.mintSoft,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        // A min-size Row centres the value in the pill's height without stretching its width.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: cl.text.body.copyWith(
                fontWeight: FontWeight.w500,
                color: cl.colors.mintText,
              ),
            ),
          ],
        ),
      ),
    );
    final head = [
      ClIcon(icon, size: 20, color: cl.colors.inkMuted),
      const SizedBox(width: 10),
    ];
    // Large text: the value goes under the label instead of crushing it to "Th…".
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...head,
                Expanded(child: Text(label, style: cl.text.body)),
              ],
            ),
            const SizedBox(height: ClSpace.s1),
            chip,
          ],
        ),
      );
    }
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          ...head,
          Expanded(child: Text(label, style: cl.text.body)),
          chip,
        ],
      ),
    );
  }
}
