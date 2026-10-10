import 'package:flutter/widgets.dart';

import '../design/cl_theme.dart';
import '../design/motion.dart';
import '../design/tokens.g.dart';
import 'cl_button.dart';
import 'cl_icon.dart';
import 'cl_pressable.dart';
import 'cl_rows.dart';

/// Calm, no-guilt empty state (9:143): icon, headline, one sentence, one Tinted action.
class ClEmptyState extends StatelessWidget {
  const ClEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    super.key,
  });

  final ClIcons icon;
  final String title;
  final String message;
  final String? actionLabel;
  final ClIcons? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s6,
        vertical: ClSpace.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClIcon(icon, color: cl.colors.mintText),
          ),
          const SizedBox(height: ClSpace.s4),
          Text(title, textAlign: TextAlign.center, style: cl.text.headline),
          const SizedBox(height: ClSpace.s1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: actionLabel!,
              icon: actionIcon,
              style: ClButtonStyle.tinted,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// First-run coachmark (23:349): ink bubble with surface text; inverts in Night care.
class ClCoachmark extends StatelessWidget {
  const ClCoachmark({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _Triangle(cl.colors.ink, up: true),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: ClSpace.s2,
            ),
            decoration: BoxDecoration(
              color: cl.colors.ink,
              borderRadius: BorderRadius.circular(ClRadius.control),
            ),
            child: Text(
              text,
              style: cl.text.label.copyWith(color: cl.colors.surface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spotlight tour tooltip (102:631). Pointer x aligns to the target centre.
class ClTourTip extends StatelessWidget {
  const ClTourTip({
    required this.step,
    required this.title,
    required this.body,
    required this.skipLabel,
    required this.nextLabel,
    required this.onSkip,
    required this.onNext,
    this.pointerUp = true,
    this.pointerX = 56,
    super.key,
  });

  final String step;
  final String title;
  final String body;
  final String skipLabel;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool pointerUp;
  final double pointerX;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final pointer = SizedBox(
      height: 9,
      width: 300,
      child: Stack(
        children: [
          Positioned(
            left: pointerX,
            top: pointerUp ? -1 : null,
            bottom: pointerUp ? null : -1,
            child: CustomPaint(
              size: const Size(20, 10),
              painter: _Triangle(c.ink, up: pointerUp),
            ),
          ),
        ],
      ),
    );
    final card = Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cl.shadows.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step,
            style: cl.text.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: c.mint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: cl.text.headline.copyWith(
              fontWeight: FontWeight.w600,
              color: c.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: cl.text.label.copyWith(
              color: c.surface2.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ClPressable(
                onPressed: onSkip,
                semanticLabel: skipLabel,
                child: Text(
                  skipLabel,
                  style: cl.text.label.copyWith(
                    color: c.surface2.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const Spacer(),
              ClPressable(
                onPressed: onNext,
                semanticLabel: nextLabel,
                child: Container(
                  height: 34,
                  constraints: const BoxConstraints(minWidth: 80),
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                  decoration: BoxDecoration(
                    color: c.mint,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nextLabel,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: pointerUp ? [pointer, card] : [card, pointer],
      ),
    );
  }
}

class _Triangle extends CustomPainter {
  _Triangle(this.color, {required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Triangle old) => old.color != color || old.up != up;
}

/// Family member row (115:704): You / Member / Pending.
enum ClMemberStatus { you, member, pending }

class ClMemberRow extends StatelessWidget {
  const ClMemberRow({
    required this.initial,
    required this.name,
    required this.detail,
    required this.status,
    this.youLabel,
    this.resendLabel,
    this.onTap,
    this.onResend,
    super.key,
  });

  final String initial;
  final String name;
  final String detail;
  final ClMemberStatus status;
  final String? youLabel;
  final String? resendLabel;
  final VoidCallback? onTap;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final pending = status == ClMemberStatus.pending;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pending ? c.surface : c.peachSoft,
              border: pending
                  ? Border.all(color: c.controlBorder, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(initial, style: cl.text.bodyStrong.copyWith(height: 1)),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: cl.text.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          switch (status) {
            ClMemberStatus.you => _Badge(
              label: youLabel ?? '',
              fill: c.mintSoft,
              ink: c.mintText,
            ),
            ClMemberStatus.member => ClIcon(
              ClIcons.chevronRight,
              size: 18,
              color: c.inkMuted,
            ),
            ClMemberStatus.pending => ClPressable(
              onPressed: onResend,
              semanticLabel: resendLabel,
              child: _Badge(
                label: resendLabel ?? '',
                fill: c.surface2,
                ink: c.ink,
                vertical: 6,
                horizontal: 12,
              ),
            ),
          },
        ],
      ),
    );
    return status == ClMemberStatus.member && onTap != null
        ? ClPressable(
            onPressed: onTap,
            pressedScale: 0.99,
            semanticLabel: '$name, $detail',
            child: ExcludeSemantics(child: row),
          )
        : MergeSemantics(child: row);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.fill,
    required this.ink,
    this.vertical = 3,
    this.horizontal = 10,
  });

  final String label;
  final Color fill;
  final Color ink;
  final double vertical;
  final double horizontal;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(ClRadius.pill),
    ),
    child: Text(
      label,
      style: context.cl.text.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}

/// Existing account found for this email (23:370).
class ClAccountRow extends StatelessWidget {
  const ClAccountRow({
    required this.initial,
    required this.email,
    required this.provider,
    super.key,
  });

  final String initial;
  final String email;
  final String provider;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          boxShadow: cl.shadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.mintDeep,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: cl.text.bodyStrong.copyWith(
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: c.onMintDeep,
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(child: Text(email, style: cl.text.label)),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s3,
                vertical: ClSpace.s1,
              ),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(ClRadius.pill),
              ),
              child: Text(provider, style: cl.text.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Appearance choice (23:339). The preview uses fixed colours of the theme it shows.
enum ClThemePreview { light, dark, auto }

class ClThemeOption extends StatelessWidget {
  const ClThemeOption({
    required this.preview,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ClThemePreview preview;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: ClPressable(
        onPressed: onTap,
        semanticLabel: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: context.motion(ClMotion.quick),
              width: 84,
              height: 132,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? cl.colors.mintDeep : cl.colors.separator,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _MiniScreen(preview),
              ),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(label, style: cl.text.label),
            const SizedBox(height: ClSpace.s2),
            ClRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Simplified mini screen (Figma artwork 76×124 was not exportable as a component — G-082).
class _MiniScreen extends StatelessWidget {
  const _MiniScreen(this.preview);

  final ClThemePreview preview;

  Widget _half(ClColors c) => ColoredBox(
    color: c.cloud,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 6, width: 30, color: c.ink),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: c.navBar,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => switch (preview) {
    ClThemePreview.light => _half(lightColors),
    ClThemePreview.dark => _half(nightCareColors),
    ClThemePreview.auto => Row(
      children: [
        Expanded(child: _half(lightColors)),
        Expanded(child: _half(nightCareColors)),
      ],
    ),
  };
}
