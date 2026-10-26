import 'package:flutter/widgets.dart';

import '../design/cl_theme.dart';
import '../design/tabular_text.dart';
import '../design/tokens.g.dart';
import 'cl_icon.dart';

/// Audience & milestone chips (8:56). Warm and Sun only on memory screens.
enum ClChipStyle { neutral, warm, sun }

class ClChip extends StatelessWidget {
  const ClChip({
    required this.label,
    this.style = ClChipStyle.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final ClChipStyle style;
  final ClIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final (fill, ink) = switch (style) {
      ClChipStyle.neutral => (c.surface2, c.ink),
      ClChipStyle.warm => (c.peachSoft, c.ink),
      ClChipStyle.sun => (c.sunshine, c.onWarm),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s3,
        vertical: ClSpace.s1,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ClIcon(icon!, size: 18, color: ink),
            const SizedBox(width: ClSpace.s1),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.cl.text.label.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync pill (8:84): always icon + words, never colour alone.
enum ClSyncState { synced, pending, error }

class ClSyncStatus extends StatelessWidget {
  const ClSyncStatus({required this.state, required this.label, super.key});

  final ClSyncState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final (fill, ink, icon) = switch (state) {
      ClSyncState.synced => (c.mintSoft, c.mintText, ClIcons.check),
      ClSyncState.pending => (c.sunshineSoft, c.pending, ClIcons.cloudOff),
      ClSyncState.error => (c.errorSoft, c.error, ClIcons.alert),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        // A minimum, not a fixed height: the words stay whole at large text sizes.
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(icon, size: 18, color: ink),
            const SizedBox(width: ClSpace.s1),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.cl.text.label.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Save-failed banner (8:85): bold lead in error + reassuring sentence in ink.
class ClErrorBanner extends StatelessWidget {
  const ClErrorBanner({required this.lead, required this.message, super.key});

  final String lead;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.errorSoft,
          borderRadius: BorderRadius.circular(ClRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClIcon(ClIcons.alert, color: cl.colors.error),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$lead ',
                      style: cl.text.body.copyWith(
                        color: cl.colors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(text: message, style: cl.text.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating chip on illustration cards (23:164). Value uses steady digits.
enum ClFloatChipLead { icon, check, avatar }

class ClFloatChip extends StatelessWidget {
  const ClFloatChip({
    required this.value,
    this.lead = ClFloatChipLead.icon,
    this.icon = ClIcons.feed,
    this.initial,
    super.key,
  });

  final String value;
  final ClFloatChipLead lead;
  final ClIcons icon;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final leadWidget = switch (lead) {
      ClFloatChipLead.icon => _circle(
        c.mintSoft,
        ClIcon(icon, size: 16, color: c.mintText),
      ),
      ClFloatChipLead.check => _circle(
        c.mintDeep,
        ClIcon(ClIcons.check, size: 16, color: c.onMintDeep),
      ),
      ClFloatChipLead.avatar => _circle(
        c.mintDeep,
        Text(
          initial ?? '',
          style: cl.text.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.onMintDeep,
            height: 1,
          ),
        ),
      ),
    };
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(ClRadius.pill),
        boxShadow: cl.shadows.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leadWidget,
          const SizedBox(width: ClSpace.s2),
          ClTabularText(value, style: cl.text.label),
        ],
      ),
    );
  }

  Widget _circle(Color fill, Widget child) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: child,
  );
}

/// 40px avatar (8:97). Mint = parents/caregivers; Warm = baby and view-only relatives; Add = invite.
enum ClAvatarStyle { mint, warm, add }

class ClAvatar extends StatelessWidget {
  const ClAvatar({
    this.style = ClAvatarStyle.mint,
    this.initial,
    this.size = 40,
    super.key,
  });

  final ClAvatarStyle style;
  final String? initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final (fill, ink) = switch (style) {
      ClAvatarStyle.mint || ClAvatarStyle.add => (c.mintSoft, c.mintText),
      ClAvatarStyle.warm => (c.peachSoft, c.ink),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: style == ClAvatarStyle.add
          ? ClIcon(ClIcons.plus, size: 18, color: ink)
          : Text(
              initial ?? '',
              style: cl.text.bodyStrong.copyWith(color: ink, height: 1),
            ),
    );
  }
}
