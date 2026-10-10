import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../design/cl_theme.dart';
import '../design/haptics.dart';
import '../design/motion.dart';
import '../design/tabular_text.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Text field (23:243): caption label above the value. Grouped = row inside a card;
/// Standalone = its own surface card with shadow-card. Focus = 2px focus-ring (no Figma variant).
class ClTextField extends StatefulWidget {
  const ClTextField({
    required this.label,
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
    super.key,
  });

  final String label;
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

  @override
  State<ClTextField> createState() => _ClTextFieldState();
}

class _ClTextFieldState extends State<ClTextField> {
  final _focus = FocusNode();
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: context.motion(ClMotion.quick),
      curve: ClCurves.quick,
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      decoration: BoxDecoration(
        color: widget.standalone ? cl.colors.surface : null,
        borderRadius: widget.standalone || focused
            ? BorderRadius.circular(ClRadius.card)
            : null,
        boxShadow: widget.standalone ? cl.shadows.card : null,
        border: focused
            ? Border.all(color: cl.colors.focusRing, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                const SizedBox(height: 2),
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
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textCapitalization: widget.textCapitalization,
                  maxLength: widget.maxLength,
                ),
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
        onChanged: onChanged == null
            ? null
            : (v) {
                ClHaptics.tap(context);
                onChanged!(v);
              },
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
            : null,
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
      pressedScale: 1,
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
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          ClIcon(icon, size: 20, color: cl.colors.inkMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: cl.text.body)),
          ClPressable(
            onPressed: onTap,
            semanticLabel: '$label, $value',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cl.colors.mintSoft,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                value,
                style: cl.text.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cl.colors.mintText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
