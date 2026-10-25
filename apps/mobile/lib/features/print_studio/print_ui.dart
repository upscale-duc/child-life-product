import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';

/// Print Studio's Figma frames use explicit text sizes, not the app's larger body style.
TextStyle psText(
  BuildContext c,
  double size, {
  FontWeight weight = FontWeight.w500,
  Color? color,
  double height = 1.3,
}) => TextStyle(
  fontFamily: 'Be Vietnam Pro Keepsake',
  fontSize: size,
  height: height,
  fontWeight: weight,
  color: color ?? c.cl.colors.ink,
  leadingDistribution: TextLeadingDistribution.even,
);

class PrintHeader extends StatelessWidget {
  const PrintHeader({
    required this.onBack,
    this.title,
    this.action,
    this.onAction,
    this.mutedAction = false,
    super.key,
  });
  final VoidCallback? onBack, onAction;
  final String? title, action;
  final bool mutedAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: SizedBox(
      height: 36,
      child: Row(
        children: [
          ClPressable(
            onPressed: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.cl.colors.surface,
                shape: BoxShape.circle,
              ),
              child: const Center(child: ClIcon(ClIcons.back, size: 18)),
            ),
          ),
          if (title != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title!,
                style: psText(context, 20, weight: FontWeight.w700),
              ),
            ),
          ] else
            const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 36),
              ),
              child: Text(
                action!,
                style: psText(
                  context,
                  mutedAction ? 11 : 14,
                  weight: FontWeight.w600,
                  color: mutedAction
                      ? context.cl.colors.inkMuted
                      : context.cl.colors.mintText,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// PS12 / PS13 / PS41: 42px rounded rectangle, deliberately separate from the app's pill control.
class PrintSegments<T> extends StatelessWidget {
  const PrintSegments({
    required this.values,
    required this.value,
    required this.label,
    required this.onChanged,
    super.key,
  });
  final List<T> values;
  final T value;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.cl.colors.surface2,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (final v in values)
          Expanded(
            child: ClPressable(
              onPressed: () => onChanged(v),
              selected: v == value,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == value ? context.cl.colors.surface : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  label(v),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: psText(
                    context,
                    14,
                    weight: v == value ? FontWeight.w600 : FontWeight.w500,
                    color: v == value
                        ? context.cl.colors.ink
                        : context.cl.colors.inkMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class PrintRadio extends StatelessWidget {
  const PrintRadio(this.selected, {super.key});
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? context.cl.colors.mintDeep : null,
      border: Border.all(
        color: selected
            ? context.cl.colors.mintDeep
            : context.cl.colors.controlBorder,
        width: 1.3,
      ),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: context.cl.colors.onMintDeep,
                shape: BoxShape.circle,
              ),
            ),
          )
        : null,
  );
}

class PrintToggle extends StatelessWidget {
  const PrintToggle({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 51,
    height: 32,
    child: FittedBox(
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: context.cl.colors.mintDeep,
      ),
    ),
  );
}
