import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';

/// Pages under "Tôi" (13b–13n): back, large title, content above the tab dock.
class MePage extends StatelessWidget {
  const MePage({
    required this.title,
    required this.children,
    this.back = true,
    this.trailing,
    this.onRefresh,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final bool back;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        ClTabDock.contentBottomPadding,
      ),
      children: [
        const SizedBox(height: ClSpace.s2),
        Semantics(header: true, child: Text(title, style: cl.text.largeTitle)),
        const SizedBox(height: ClSpace.s4),
        ...children,
      ],
    );
    // The back bar stays pinned, and the title moves into it once the large one scrolls away.
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: ClPinnedHeaderScaffold(
        collapsedTitle: title,
        header: back || trailing != null
            ? ClTopBar(
                onBack: back ? () => context.pop() : null,
                trailing: trailing,
              )
            : null,
        body: onRefresh == null
            ? list
            : RefreshIndicator(onRefresh: onRefresh!, child: list),
      ),
    );
  }
}

class MeRow extends StatelessWidget {
  const MeRow({
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.iconTint,
    super.key,
  });

  final String title;
  final ClIcons? icon;
  final Widget? leading;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = destructive ? cl.colors.error : cl.colors.ink;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s2,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: ClSpace.s3),
          ] else if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconTint ?? cl.colors.mintSoft,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              alignment: Alignment.center,
              child: ClIcon(icon!, size: 18, color: cl.colors.mintText),
            ),
            const SizedBox(width: ClSpace.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: cl.text.body.copyWith(color: ink)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: cl.text.label.copyWith(
                      color: destructive ? cl.colors.error : cl.colors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: ClSpace.s2),
            Text(
              value!,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          ?trailing,
          if (onTap != null && trailing == null) ...[
            const SizedBox(width: ClSpace.s1),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ],
      ),
    );
    final label = [title, ?subtitle, ?value].join(', ');
    return onTap == null
        ? MergeSemantics(child: row)
        : ClPressable(onPressed: onTap, semanticLabel: label, child: row);
  }
}

/// A plain text action at the end of a row ("Gỡ", "Đăng xuất").
class MeRowAction extends StatelessWidget {
  const MeRowAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s2,
          vertical: ClSpace.s2,
        ),
        child: Text(
          label,
          style: cl.text.label.copyWith(
            fontWeight: FontWeight.w600,
            color: destructive ? cl.colors.error : cl.colors.mintText,
          ),
        ),
      ),
    );
  }
}

/// Section label above a card group ("Theo bé", "Thiết bị đang đăng nhập").
class MeSection extends StatelessWidget {
  const MeSection(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClSpace.s1,
        ClSpace.s4,
        ClSpace.s1,
        ClSpace.s2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: cl.text.label.copyWith(
            color: cl.colors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A tinted card: warning (13c), full (13d), delete (13j, 13n) and info cards.
class MeNotice extends StatelessWidget {
  const MeNotice({
    required this.title,
    this.body,
    this.icon,
    this.tone = MeTone.info,
    this.onTap,
    this.child,
    super.key,
  });
  final String title;
  final String? body;
  final ClIcons? icon;
  final MeTone tone;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (bg, ink) = switch (tone) {
      MeTone.info => (cl.colors.surface2, cl.colors.ink),
      MeTone.warn => (cl.colors.sunshineSoft, cl.colors.ink),
      MeTone.error => (cl.colors.errorSoft, cl.colors.error),
    };
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClRadius.card - 6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 20, color: ink),
            const SizedBox(width: ClSpace.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.bodyStrong.copyWith(color: ink)),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    style: cl.text.label.copyWith(
                      color: tone == MeTone.error
                          ? cl.colors.error
                          : cl.colors.inkMuted,
                    ),
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: ClSpace.s3),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return onTap == null
        ? MergeSemantics(child: card)
        : ClPressable(
            onPressed: onTap,
            semanticLabel: [title, ?body].join('. '),
            child: card,
          );
  }
}

enum MeTone { info, warn, error }

/// Per-baby colours, shared by the storage bar and the baby rows (13a, 13b, 13i).
List<Color> babyTints(BuildContext context) {
  final c = context.cl.colors;
  return [c.mintDeep, c.peach, c.sunshine];
}

List<Color> babySoftTints(BuildContext context) {
  final c = context.cl.colors;
  return [c.mintSoft, c.peachSoft, c.sunshineSoft];
}

/// Segmented usage bar, one segment per baby; the first turns red when full (13d).
class StorageBar extends StatelessWidget {
  const StorageBar({
    required this.segments,
    required this.quota,
    this.full = false,
    this.height = 10,
    super.key,
  });

  final List<int> segments;
  final int quota;
  final bool full;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final tints = babyTints(context);
    final total = quota <= 0 ? 1 : quota;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: cl.colors.separator,
        child: LayoutBuilder(
          builder: (context, c) {
            var left = c.maxWidth;
            return Row(
              children: [
                for (final (i, bytes) in segments.indexed)
                  Builder(
                    builder: (_) {
                      final w = (c.maxWidth * bytes / total).clamp(0.0, left);
                      left -= w;
                      return Container(
                        width: w,
                        color: full && i == 0
                            ? cl.colors.error
                            : tints[i % tints.length],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
