import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../today/today_layout.dart' show DragHandle;

/// A card of rows to reorder, like "Tuỳ chỉnh Hôm nay" (370:1525): a long press anywhere on a
/// row lifts it, the three-bar handle drags at once, the lifted row grows a little and casts a
/// shadow. Used by AX14 (Đang hiện) and AX06 (Gợi ý Hôm nay).
class AxReorderGroup<T extends Object> extends StatelessWidget {
  const AxReorderGroup({
    required this.items,
    required this.row,
    required this.onReorder,
    this.header = const [],
    super.key,
  });

  final List<T> items;

  /// The row for [item] at [index]; [handle] goes where the row wants its drag handle.
  final Widget Function(T item, int index, Widget handle) row;
  final void Function(int from, int to) onReorder;

  /// Rows above the reorderable ones that never move (pinned widgets).
  final List<Widget> header;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cl.shadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ...header,
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderStart: (_) => ClHaptics.selection(context),
            onReorderItem: onReorder,
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final t = Curves.easeOut.transform(animation.value);
                return Transform.scale(
                  scale: 1 + 0.02 * t,
                  child: Material(
                    color: cl.colors.surface,
                    elevation: 8 * t,
                    shadowColor: cl.colors.ink.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    child: child,
                  ),
                );
              },
              child: child,
            ),
            children: [
              for (final (i, item) in items.indexed)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(item),
                  index: i,
                  child: Material(
                    color: cl.colors.surface,
                    child: row(
                      item,
                      i,
                      ReorderableDragStartListener(
                        index: i,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: DragHandle(color: cl.colors.inkMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
