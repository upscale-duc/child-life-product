import 'package:flutter/widgets.dart';

import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_pressable.dart';

/// Pill segmented control (9:124, item 9:111). 2–3 short options; the thumb slides in
/// duration-quick. Callers persist the last choice ("Remembers the last choice as the default").
class ClSegmented<T> extends StatelessWidget {
  const ClSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    super.key,
  }) : assert(
         options.length >= 2 && options.length <= 3,
         'Segmented takes 2–3 options',
       );

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final index = options.indexOf(selected);
    const pad = 5.0;
    const gap = 4.0;
    return Container(
      height: 56,
      padding: const EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth =
              (constraints.maxWidth - gap * (options.length - 1)) /
              options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: context.motion(ClMotion.quick),
                curve: ClCurves.quick,
                left: index * (itemWidth + gap),
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                    boxShadow: cl.shadows.card,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: itemWidth,
                      child: ClPressable(
                        onPressed: () => onChanged(options[i]),
                        semanticLabel: labelOf(options[i]),
                        selected: i == index,
                        pressedScale: 1,
                        child: SizedBox(
                          height: 46,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: context.motion(ClMotion.quick),
                              style: i == index
                                  ? cl.text.body.copyWith(
                                      fontWeight: FontWeight.w500,
                                    )
                                  : cl.text.body.copyWith(
                                      color: cl.colors.inkMuted,
                                    ),
                              child: Text(
                                labelOf(options[i]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
