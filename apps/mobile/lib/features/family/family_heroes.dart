import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_art.dart';
import '../onboarding/widgets/onboarding_layout.dart';

/// Illustration/InviteCode (15, 14d): a ticket on sunshine; the pink dot carries the invitee's
/// relation ("Bà"), drawn live so it follows the language and the invite.
class InviteCodeHero extends StatelessWidget {
  const InviteCodeHero({this.label = '', super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return HeroArt(
      illustration: ClIllustration.inviteCode,
      size: const Size(343, 236),
      color: cl.colors.cardSun,
      overlays: [
        if (label.isNotEmpty)
          Positioned(
            left: 109.5 - 30,
            top: 108 - 12,
            width: 60,
            height: 24,
            child: Transform.rotate(
              angle: -0.137,
              child: Center(
                child: FittedBox(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173D44),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Illustration/Invite (16): the inviter's initial beside the baby, on mint.
class InviteHero extends StatelessWidget {
  const InviteHero({required this.initial, super.key});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return HeroArt(
      illustration: ClIllustration.invite,
      size: const Size(343, 212),
      color: cl.colors.cardMint,
      overlays: [
        Positioned(
          left: 124 - 40,
          top: 106 - 24,
          width: 80,
          height: 48,
          child: Center(
            child: Text(
              initial,
              style: cl.text.title.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Illustration/Expired (17, 9d): "calm hourglass on surface-2 — no alarm colours".
class ExpiredHero extends StatelessWidget {
  const ExpiredHero({super.key});

  @override
  Widget build(BuildContext context) => HeroArt(
    illustration: ClIllustration.expired,
    size: const Size(343, 320),
    color: context.cl.colors.surface2,
  );
}
