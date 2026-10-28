import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// One action behind a row: "Sửa" (warm) or "Xoá" (destructive).
@immutable
class ClSwipeAction {
  const ClSwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final ClIcons icon;
  final VoidCallback onPressed;
  final bool destructive;
}

/// A row that slides left to show its actions (Cùng Chăm Con 02/04: "Vuốt sang trái để sửa hoặc
/// xoá"). Swiping is a shortcut, never the only way: the actions are also screen-reader custom
/// actions, and the screen offers them on tap too. Tapping the row while open closes it.
class ClSwipeActions extends StatefulWidget {
  const ClSwipeActions({
    required this.child,
    required this.actions,
    this.radius = ClRadius.card,
    super.key,
  });

  final Widget child;
  final List<ClSwipeAction> actions;

  /// The row's own corner radius, so the actions sit inside the same shape.
  final double radius;

  static const actionWidth = 72.0;

  @override
  State<ClSwipeActions> createState() => _ClSwipeActionsState();
}

class _ClSwipeActionsState extends State<ClSwipeActions>
    with SingleTickerProviderStateMixin {
  late final _open = AnimationController(vsync: this);

  double get _width => ClSwipeActions.actionWidth * widget.actions.length;

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _settle(bool open) {
    _open.animateTo(
      open ? 1 : 0,
      duration: context.motion(ClMotion.quick),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return widget.child;
    final c = context.cl.colors;
    final text = context.cl.text;
    return Semantics(
      customSemanticsActions: {
        for (final a in widget.actions)
          CustomSemanticsAction(label: a.label): a.onPressed,
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) =>
              _open.value = (_open.value - d.delta.dx / _width).clamp(0, 1),
          onHorizontalDragEnd: (d) => _settle(
            d.primaryVelocity != null && d.primaryVelocity!.abs() > 300
                ? d.primaryVelocity! < 0
                : _open.value > 0.5,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final a in widget.actions)
                        ClPressable(
                          onPressed: () {
                            _settle(false);
                            a.onPressed();
                          },
                          semanticLabel: a.label,
                          child: Container(
                            width: ClSwipeActions.actionWidth,
                            color: a.destructive ? c.errorSoft : c.sunshineSoft,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClIcon(
                                  a.icon,
                                  size: 18,
                                  color: a.destructive ? c.error : c.ink,
                                ),
                                const SizedBox(height: ClSpace.s1),
                                Text(
                                  a.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: a.destructive ? c.error : c.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _open,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-_width * _open.value, 0),
                  // While open, a tap on the row closes it instead of opening the row.
                  child: _open.value == 0
                      ? child
                      : Stack(
                          children: [
                            AbsorbPointer(child: child),
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _settle(false),
                              ),
                            ),
                          ],
                        ),
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
