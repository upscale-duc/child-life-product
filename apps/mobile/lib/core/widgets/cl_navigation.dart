import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_button.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';

/// Membership role of the current user for the selected baby (business map §2.1).
enum ClRole { parent, caregiver, relative }

enum ClTab { today, memories, family, me }

/// Tabs per role (NavBar 44:362): parent 4, caregiver 3 (no Kỷ niệm), relative 3 (no Hôm nay).
/// A relative granted "Chăm sóc hằng ngày" also gets a read-only Hôm nay (D-018).
List<ClTab> tabsForRole(ClRole role, {bool relativeSeesToday = false}) =>
    switch (role) {
      ClRole.parent => const [
        ClTab.today,
        ClTab.memories,
        ClTab.family,
        ClTab.me,
      ],
      ClRole.caregiver => const [ClTab.today, ClTab.family, ClTab.me],
      ClRole.relative when relativeSeesToday => const [
        ClTab.today,
        ClTab.memories,
        ClTab.family,
        ClTab.me,
      ],
      ClRole.relative => const [ClTab.memories, ClTab.family, ClTab.me],
    };

/// Quick log is available to parents and caregivers only (no "+" for relatives).
bool roleCanQuickLog(ClRole role) => role != ClRole.relative;

/// Floating tab bar (44:362): active tab is a labelled pill, others icon-only 52 wide.
class ClNavBar extends StatelessWidget {
  const ClNavBar({
    required this.role,
    required this.active,
    required this.onSelect,
    required this.initial,
    this.tabs,
    super.key,
  });

  final ClRole role;

  /// Overrides [tabsForRole] (e.g. a relative with daily care).
  final List<ClTab>? tabs;
  final ClTab active;
  final ValueChanged<ClTab> onSelect;

  /// Initial of the signed-in user for the "Tôi" ring.
  final String initial;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final tabs = this.tabs ?? tabsForRole(role);
    const pad = 6.0;
    const inactiveWidth = 52.0;
    String label(ClTab t) => switch (t) {
      ClTab.today => l10n.tabToday,
      ClTab.memories => l10n.tabMemories,
      ClTab.family => l10n.tabFamily,
      ClTab.me => l10n.tabMe,
    };
    ClIcons icon(ClTab t) => switch (t) {
      ClTab.today => ClIcons.today,
      ClTab.memories => ClIcons.memories,
      ClTab.family => ClIcons.family,
      ClTab.me => ClIcons.today,
    };

    return Container(
      height: 68,
      padding: const EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: cl.colors.navBar,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        boxShadow: cl.shadows.nav,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final activeWidth =
              constraints.maxWidth - inactiveWidth * (tabs.length - 1);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tab in tabs)
                _NavTab(
                  inactiveWidth: inactiveWidth,
                  activeWidth: activeWidth,
                  active: tab == active,
                  label: label(tab),
                  onTap: () => onSelect(tab),
                  child: tab == ClTab.me
                      ? _MeRing(initial: initial, active: tab == active)
                      : ClIcon(
                          icon(tab),
                          size: 22,
                          color: tab == active
                              ? cl.colors.onNavActive
                              : cl.colors.navIcon,
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.inactiveWidth,
    required this.activeWidth,
    required this.active,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final double inactiveWidth;
  final double activeWidth;
  final bool active;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final duration = context.motion(ClMotion.quick);
    return Semantics(
      selected: active,
      button: true,
      label: label,
      excludeSemantics: true,
      child: ClPressable(
        onPressed: onTap,
        pressedScale: 1,
        isButton: false,
        // Each tab animates its share of the bar (0 = inactive, 1 = active) so the tabs always sum
        // to the bar width, even while the bar itself resizes.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: active ? 1 : 0),
          duration: duration,
          curve: ClCurves.quick,
          builder: (context, t, child) => Container(
            width: inactiveWidth + (activeWidth - inactiveWidth) * t,
            height: 56,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0x00000000),
                cl.colors.navActive,
                t,
              ),
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              if (active) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: cl.text.label.copyWith(
                      height: 16 / 14,
                      letterSpacing: 0.2,
                      color: cl.colors.onNavActive,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MeRing extends StatelessWidget {
  const _MeRing({required this.initial, required this.active});

  final String initial;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final ink = active ? c.onNavActive : c.navIcon;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink, width: 1.6),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: context.cl.text.caption.copyWith(
          fontSize: 11,
          height: 1,
          letterSpacing: 0,
          fontWeight: active ? FontWeight.w500 : FontWeight.w600,
          color: ink,
        ),
      ),
    );
  }
}

/// "+" quick-log button (44:363), 68px, opens the quick-log chooser.
class ClQuickLogButton extends StatelessWidget {
  const ClQuickLogButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: AppLocalizations.of(context).a11yQuickLog,
      child: Container(
        width: 68,
        height: 68,
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

/// Tab dock (10:169): NavBar + QuickLogButton, floating 24 above the bottom safe area.
class ClTabDock extends StatelessWidget {
  const ClTabDock({
    required this.role,
    required this.active,
    required this.onSelect,
    required this.initial,
    this.onQuickLog,
    this.tabs,
    super.key,
  });

  final ClRole role;
  final List<ClTab>? tabs;
  final ClTab active;
  final ValueChanged<ClTab> onSelect;
  final String initial;
  final VoidCallback? onQuickLog;

  /// Clearance scrolling content needs so its last item stays above the dock (47: 120).
  static const double contentBottomPadding = 120;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        bottom > 0 ? bottom : ClSpace.s6,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClNavBar(
              role: role,
              active: active,
              onSelect: onSelect,
              initial: initial,
              tabs: tabs,
            ),
          ),
          if (roleCanQuickLog(role) && onQuickLog != null) ...[
            const SizedBox(width: ClSpace.s3),
            ClQuickLogButton(onPressed: onQuickLog!),
          ],
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
    return hasMultiple && onTap != null
        ? ClPressable(onPressed: onTap, semanticLabel: label, child: chip)
        : Semantics(
            label: label,
            child: ExcludeSemantics(child: chip),
          );
  }
}
