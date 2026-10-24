import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../design/cl_theme.dart';
import '../design/haptics.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_button.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Membership role of the current user for the selected baby (business map §2.1).
enum ClRole { parent, caregiver, relative }

/// Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích (v1.0 improvement 450:6597, R1–R4): Tiện ích replaced
/// Gia đình, which now opens from Tiện ích. There is no "Tôi" tab: it opens from the header avatar.
/// [explore] and [profile] are NavBar v2 · Adaptive (917:3012, P-178): Khám phá gathers Chăm sóc
/// and Tiện ích, Hồ sơ replaces the avatar's Tôi.
enum ClTab { today, memories, care, utilities, explore, profile }

/// NavBar v2 · Adaptive (917:3012, P-178): parent Hôm nay · Kỷ niệm · Khám phá · Hồ sơ; caregiver
/// Hôm nay · Khám phá · Hồ sơ; relative Kỷ niệm · Hồ sơ, plus Hôm nay when granted daily care
/// (D-018, which the Figma relative variant does not draw).
List<ClTab> tabsForRoleV2(ClRole role, {bool relativeSeesToday = false}) =>
    switch (role) {
      ClRole.parent => const [
        ClTab.today,
        ClTab.memories,
        ClTab.explore,
        ClTab.profile,
      ],
      ClRole.caregiver => const [ClTab.today, ClTab.explore, ClTab.profile],
      ClRole.relative when relativeSeesToday => const [
        ClTab.today,
        ClTab.memories,
        ClTab.profile,
      ],
      ClRole.relative => const [ClTab.memories, ClTab.profile],
    };

/// Tabs per role: parent Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích; caregiver without Kỷ niệm
/// (450:6873); relative Kỷ niệm · Tiện ích, plus a read-only Hôm nay when granted daily care
/// (D-018; the relative dock is not drawn, so they keep their view).
List<ClTab> tabsForRole(ClRole role, {bool relativeSeesToday = false}) =>
    switch (role) {
      ClRole.parent => const [
        ClTab.today,
        ClTab.memories,
        ClTab.care,
        ClTab.utilities,
      ],
      ClRole.caregiver => const [ClTab.today, ClTab.care, ClTab.utilities],
      ClRole.relative when relativeSeesToday => const [
        ClTab.today,
        ClTab.memories,
        ClTab.utilities,
      ],
      ClRole.relative => const [ClTab.memories, ClTab.utilities],
    };

/// Quick log is available to parents and caregivers only (no "+" for relatives).
bool roleCanQuickLog(ClRole role) => role != ClRole.relative;

/// Floating tab bar (NavBar v1.0.1, 369:2540): every tab shows its icon over its label, always
/// (owner, 2026-10-14, D-069); the tabs share the bar equally and the active one sits on a light
/// rounded fill. The fill, label and icon colours move together on one spring when the tab
/// changes (D-048).
class ClNavBar extends StatefulWidget {
  const ClNavBar({
    required this.role,
    required this.active,
    required this.onSelect,
    this.tabs,
    this.dots = const {},
    this.dotLabel,
    super.key,
  });

  final ClRole role;

  /// Overrides [tabsForRole] (e.g. a relative with daily care).
  final List<ClTab>? tabs;
  final ClTab active;
  final ValueChanged<ClTab> onSelect;

  /// Tabs with something new waiting (Tự lưu suggestions on Kỷ niệm, AR02): a small dot.
  final Set<ClTab> dots;

  /// What the dot means, for screen readers.
  final String? dotLabel;

  @override
  State<ClNavBar> createState() => _ClNavBarState();
}

class _ClNavBarState extends State<ClNavBar>
    with SingleTickerProviderStateMixin {
  static const _pad = 6.0;

  // Each tab's selection progress (0 = plain, 1 = on the active fill). A change hands progress straight
  // from the tabs as they are now to the new tab, so tabs in between never grow.
  late List<double> _from = _oneHot(_activeIndex);
  late List<double> _to = _from;
  late final AnimationController _move = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  List<ClTab> get _tabs => widget.tabs ?? tabsForRole(widget.role);
  int get _activeIndex => math.max(_tabs.indexOf(widget.active), 0);

  List<double> _oneHot(int index) => [
    for (var i = 0; i < _tabs.length; i++) i == index ? 1.0 : 0.0,
  ];

  List<double> get _current => [
    for (var i = 0; i < _to.length; i++)
      (_from[i] + (_to[i] - _from[i]) * _move.value).clamp(0.0, 1.0),
  ];

  @override
  void didUpdateWidget(ClNavBar old) {
    super.didUpdateWidget(old);
    final oldTabs = old.tabs ?? tabsForRole(old.role);
    if (!listEquals(oldTabs, _tabs)) {
      _from = _to = _oneHot(_activeIndex);
      _move.value = 1;
    } else if (old.active != widget.active) {
      _from = _current;
      _to = _oneHot(_activeIndex);
      if (context.reduceMotion) {
        _move.value = 1;
      } else {
        _move
          ..value = 0
          ..animateWith(
            SpringSimulation(standardSpring(), 0, 1, 0, snapToEnd: true),
          );
      }
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final tabs = _tabs;
    String label(ClTab t) => switch (t) {
      ClTab.today => l10n.tabToday,
      ClTab.memories => l10n.tabMemories,
      ClTab.care => l10n.tabCare,
      ClTab.utilities => l10n.tabUtilities,
      ClTab.explore => l10n.tabExplore,
      ClTab.profile => l10n.tabProfile,
    };
    ClIcons icon(ClTab t) => switch (t) {
      ClTab.today => ClIcons.today,
      ClTab.memories => ClIcons.memories,
      ClTab.care => ClIcons.care,
      ClTab.utilities || ClTab.explore => ClIcons.grid,
      ClTab.profile => ClIcons.profile,
    };

    return Container(
      height: 68,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: cl.colors.navBar,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        boxShadow: cl.shadows.nav,
      ),
      child: AnimatedBuilder(
        animation: _move,
        builder: (context, _) {
          final progress = _current;
          return Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _tabAt(
                    tab: tabs[i],
                    t: progress[i],
                    label: label(tabs[i]),
                    icon: icon(tabs[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabAt({
    required ClTab tab,
    required double t,
    required String label,
    required ClIcons icon,
  }) => _NavTab(
    t: t,
    active: tab == widget.active,
    label: label,
    onTap: () {
      if (tab != widget.active) ClHaptics.selection(context);
      widget.onSelect(tab);
    },
    icon: (ink) => widget.dots.contains(tab) && tab != widget.active
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              ClIcon(icon, size: 20, color: ink),
              Positioned(
                top: -1,
                right: -2,
                child: Semantics(
                  label: widget.dotLabel,
                  child: Container(
                    key: ValueKey('tabDot.${tab.name}'),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: context.cl.colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.cl.colors.navBar,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : ClIcon(icon, size: 20, color: ink),
  );
}

/// One tab at selection progress [t] (0 = plain, 1 = on the active fill): the icon over the label
/// (Tab/* in NavBar v1.0.1: 20 px icon, 3 px gap, 11 px label, Bold when active).
class _NavTab extends StatelessWidget {
  /// The active fill: a little wider than Figma's 64 so longer labels ("Chăm sóc") breathe.
  static const _fillWidth = 76.0;

  const _NavTab({
    required this.t,
    required this.active,
    required this.label,
    required this.onTap,
    required this.icon,
  });

  final double t;
  final bool active;
  final String label;
  final VoidCallback onTap;
  final Widget Function(Color ink) icon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = Color.lerp(cl.colors.navIcon, cl.colors.onNavActive, t)!;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      excludeSemantics: true,
      child: ClPressable(
        onPressed: onTap,
        pressedOpacity: 1,
        isButton: false,
        // The whole share of the bar takes the tap; the fill is a fixed 76 wide in its middle,
        // so the label never touches its edges (owner, 2026-10-14).
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: constraints.maxWidth,
            height: 56,
            child: Center(
              child: Container(
                width: math.min(constraints.maxWidth, _fillWidth),
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  color: cl.colors.navActive.withValues(
                    alpha: cl.colors.navActive.a * t,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon(ink),
                    const SizedBox(height: 3),
                    // Large text sizes shrink the label rather than cut it.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: cl.text.caption.copyWith(
                          fontSize: 11,
                          height: 16 / 11,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.lerp(
                            FontWeight.w500,
                            FontWeight.w700,
                            t,
                          ),
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "+" quick-log button (44:363), 68px, opens the quick-log chooser.
class ClQuickLogButton extends StatelessWidget {
  const ClQuickLogButton({
    required this.onPressed,
    this.semanticLabel,
    this.size = 68,
    super.key,
  });

  final VoidCallback onPressed;

  /// "Ghi nhanh" unless the button does something else (Kỷ niệm: add photos).
  final String? semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? AppLocalizations.of(context).a11yQuickLog,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.mintDeep,
          shape: BoxShape.circle,
          boxShadow: context.cl.shadows.nav,
        ),
        alignment: Alignment.center,
        child: ClIcon(ClIcons.plus, size: 28, color: c.onMintDeep),
      ),
    );
  }
}

/// The current tab's own "+" on the dock: Ghi nhanh on Hôm nay, add photos on Kỷ niệm.
@immutable
class ClDockAction {
  const ClDockAction({required this.label, required this.onPressed, this.key});
  final String label;
  final VoidCallback onPressed;

  /// Lets the first-run tour point at "+" (18c).
  final Key? key;
}

/// Tab dock (10:169), floating 24 above the bottom safe area: the NavBar full width, and the
/// tab's "+" (if it has one) floating above its right end (owner, 2026-10-11; it used to sit
/// beside the bar on every tab).
class ClTabDock extends StatelessWidget {
  const ClTabDock({
    required this.role,
    required this.active,
    required this.onSelect,
    this.action,
    this.tabs,
    this.dots = const {},
    this.dotLabel,
    this.trailing,
    super.key,
  });

  final ClRole role;
  final List<ClTab>? tabs;
  final ClTab active;
  final ValueChanged<ClTab> onSelect;
  final ClDockAction? action;

  /// At the end of the bar's row, outside the bar (NavBar v2: Lumi, owner 2026-10-24 "nút Lumi ở
  /// cuối, tách ra khỏi tabbar").
  final Widget? trailing;

  /// See [ClNavBar.dots].
  final Set<ClTab> dots;
  final String? dotLabel;

  /// Clearance scrolling content needs so its last item stays above the dock (47: 120).
  static const double contentBottomPadding = 120;

  /// Height the "+" adds above the bar.
  static const double actionExtent = _actionSize + ClSpace.s3;
  static const double _actionSize = 56;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final bar = ClNavBar(
      role: role,
      active: active,
      onSelect: onSelect,
      tabs: tabs,
      dots: dots,
      dotLabel: dotLabel,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        bottom > 0 ? bottom : ClSpace.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (action case final a?)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: ClSpace.s3),
                child: ClQuickLogButton(
                  key: a.key,
                  onPressed: a.onPressed,
                  semanticLabel: a.label,
                  size: _actionSize,
                ),
              ),
            ),
          if (trailing case final t?)
            Row(
              children: [
                Expanded(child: bar),
                const SizedBox(width: ClSpace.s2),
                t,
              ],
            )
          else
            bar,
        ],
      ),
    );
  }
}

/// Large-title header (11:138): subtitle above a large title, optional trailing control.
class ClNavHeader extends StatelessWidget {
  const ClNavHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2, bottom: ClSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                Semantics(
                  header: true,
                  child: Text(title, style: cl.text.largeTitle),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Onboarding / auth top bar (23:226). Compose: back, skip, progress, countdown or brand.
class ClTopBar extends StatelessWidget {
  const ClTopBar({
    this.onBack,
    this.onSkip,
    this.progress,
    this.countdown,
    this.brand,
    this.trailing,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  /// 0–1 setup progress (23:190).
  final double? progress;

  /// e.g. a neutral chip "Còn 68 giờ".
  final Widget? countdown;

  /// Logo lockup for the Brand type.
  final Widget? brand;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: ClSpace.tapMin,
      child: Row(
        children: [
          if (brand != null)
            brand!
          else if (onBack != null)
            ClBackButton(semanticLabel: l10n.a11yBack, onPressed: onBack)
          else
            const SizedBox(width: ClSpace.tapMin),
          if (progress != null) ...[
            Expanded(child: ClProgress(value: progress!)),
            const SizedBox(width: 28),
          ] else
            const Spacer(),
          ?countdown,
          if (onSkip != null)
            ClPressable(
              onPressed: onSkip,
              semanticLabel: l10n.actionSkip,
              child: Text(
                l10n.actionSkip,
                style: cl.text.label.copyWith(color: cl.colors.mintText),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Setup progress bar (23:190), 4px.
class ClProgress extends StatelessWidget {
  const ClProgress({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: c.separator,
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: context.motion(ClMotion.quick),
          curve: ClCurves.quick,
          widthFactor: value.clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              color: c.mintDeep,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Onboarding pagination (23:185): active 24px pill, others 6px dots.
class ClPageDots extends StatelessWidget {
  const ClPageDots({required this.count, required this.index, super.key});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return Semantics(
      label: '${index + 1}/$count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: context.motion(ClMotion.quick),
              curve: ClCurves.quick,
              width: i == index ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? c.mintDeep : c.separator,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Baby switcher chip (45:321): avatar + name (+ chevron when there is more than one baby).
/// [onTap] opens the baby's profile (one baby) or the baby picker (several).
class ClBabySwitcher extends StatelessWidget {
  const ClBabySwitcher({
    required this.label,
    required this.avatar,
    this.hasMultiple = false,
    this.onTap,
    super.key,
  });

  final String label;
  final Widget avatar;
  final bool hasMultiple;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final chip = Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(child: SizedBox(width: 32, height: 32, child: avatar)),
          const SizedBox(width: ClSpace.s2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (hasMultiple) ...[
            const SizedBox(width: ClSpace.s2),
            ClIcon(ClIcons.chevronDown, size: 16, color: cl.colors.ink),
          ],
        ],
      ),
    );
    return onTap != null
        ? ClPressable(
            onPressed: onTap,
            pressedOpacity: ClPressable.surfaceOpacity,
            semanticLabel: label,
            child: chip,
          )
        : Semantics(
            label: label,
            child: ExcludeSemantics(child: chip),
          );
  }
}

/// Tab and Me screens: [header] (baby switcher row, back bar, title tabs) stays pinned while
/// [body] scrolls under it (owner feedback, 2026-10-11). A hairline shows once content has
/// scrolled beneath; [collapsedTitle] fades into the bar after the large title scrolls away,
/// like an iOS large-title navigation bar.
class ClPinnedHeaderScaffold extends StatefulWidget {
  const ClPinnedHeaderScaffold({
    required this.body,
    this.header,
    this.collapsedTitle,
    this.collapseAfter = 48,
    this.scrollDepth = 0,
    super.key,
  });

  final Widget? header;
  final Widget body;

  /// How deep the body's vertical scroll sits: 1 when the body pages sideways (a PageView of
  /// scrolling tabs), so the separator still follows it.
  final int scrollDepth;
  final String? collapsedTitle;

  /// Scroll offset after which [collapsedTitle] shows (about one large-title line).
  final double collapseAfter;

  @override
  State<ClPinnedHeaderScaffold> createState() => _ClPinnedHeaderScaffoldState();
}

class _ClPinnedHeaderScaffoldState extends State<ClPinnedHeaderScaffold> {
  bool _under = false;
  bool _collapsed = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != widget.scrollDepth || n.metrics.axis != Axis.vertical) {
      return false;
    }
    final pixels = n.metrics.pixels - n.metrics.minScrollExtent;
    final under = pixels > 0.5;
    final collapsed = pixels > widget.collapseAfter;
    if (under != _under || collapsed != _collapsed) {
      setState(() {
        _under = under;
        _collapsed = collapsed;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final duration = context.motion(ClMotion.quick);
    final title = widget.collapsedTitle;
    final listener = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.body,
    );
    // No header: the page starts at the top as before, and a compact bar with the title covers
    // it only once the large title has scrolled away.
    if (widget.header == null) {
      return ColoredBox(
        color: cl.colors.cloud,
        child: Stack(
          children: [
            Positioned.fill(child: SafeArea(bottom: false, child: listener)),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _collapsed ? 1 : 0,
                  duration: duration,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cl.colors.cloud,
                      border: Border(
                        bottom: BorderSide(color: cl.colors.separator),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: ClSpace.tapMin,
                        child: Center(
                          child: Text(
                            title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.bodyStrong,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ColoredBox(
      color: cl.colors.cloud,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                ClSpace.s2,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  widget.header!,
                  if (title != null)
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _collapsed ? 1 : 0,
                        duration: duration,
                        child: Semantics(
                          excludeSemantics: true,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.bodyStrong,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: duration,
            height: 1,
            color: _under ? cl.colors.separator : cl.colors.cloud,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: listener,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps a hidden tab still. `StatefulShellRoute.indexedStack` keeps every tab mounted and turns
/// [TickerMode] off for the hidden ones (also for a screen covered by a pushed route); Riverpod
/// then pauses their `ref.watch`es, but an inherited change still rebuilds them, e.g. the bottom
/// padding when the keyboard opens on another tab. While hidden, [child] keeps the [MediaQuery]
/// it last showed with and catches up the moment it shows again. Visible, it passes the live
/// [MediaQuery] through unchanged.
class ClHiddenTabFreeze extends StatefulWidget {
  const ClHiddenTabFreeze({required this.child, super.key});

  final Widget child;

  @override
  State<ClHiddenTabFreeze> createState() => _ClHiddenTabFreezeState();
}

class _ClHiddenTabFreezeState extends State<ClHiddenTabFreeze> {
  ValueListenable<TickerModeData>? _shown;
  MediaQueryData? _frozen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.getValuesNotifier(context);
    if (shown != _shown) {
      _shown?.removeListener(_onShown);
      _shown = shown..addListener(_onShown);
    }
  }

  void _onShown() => setState(() {});

  @override
  void dispose() {
    _shown?.removeListener(_onShown);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.of(context);
    if (_shown?.value.enabled ?? true) _frozen = live;
    return MediaQuery(data: _frozen ?? live, child: widget.child);
  }
}
