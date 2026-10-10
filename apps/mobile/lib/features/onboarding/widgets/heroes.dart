import 'package:flutter/material.dart';

import '../../../core/design/cl_theme.dart';
import '../../../core/design/tabular_text.dart';
import '../../../core/widgets/cl_art.dart';
import '../../../core/widgets/cl_icon.dart';
import '../../../core/widgets/cl_status.dart';
import '../../../l10n/app_localizations.dart';
import 'onboarding_layout.dart';

/// Hero cards of section 1–2 (26:4…26:277, 27:488…27:673). Positions are measured from the
/// Figma frames in the 343-wide artboard of each illustration.
const _card = Size(343, 408);

Widget _chip(
  int index,
  double? left,
  double top,
  Widget chip, {
  double? right,
}) => Positioned(
  left: left,
  right: right,
  top: top,
  child: PopIn(index: index, child: chip),
);

class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeroArt(
      illustration: ClIllustration.welcome,
      size: const Size(343, 392),
      color: context.cl.colors.cardMint,
      overlays: [
        _chip(
          0,
          16,
          20,
          const ClFloatChip(value: '120 ml', icon: ClIcons.feed),
        ),
        _chip(
          1,
          null,
          98,
          const ClFloatChip(value: '1:24', icon: ClIcons.sleep),
          right: 20,
        ),
        _chip(
          2,
          16,
          336,
          ClFloatChip(value: l10n.welcomeChipMilestone, icon: ClIcons.heart),
        ),
      ],
    );
  }
}

class TourCareHero extends StatelessWidget {
  const TourCareHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return HeroArt(
      illustration: ClIllustration.care,
      size: _card,
      color: cl.colors.cardMint,
      overlays: [
        _chip(
          0,
          16,
          76,
          ClFloatChip(
            value: l10n.tourCareChipBottle,
            lead: ClFloatChipLead.check,
          ),
        ),
        _chip(
          1,
          null,
          22,
          right: 16,
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cl.colors.sunshine,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClTabularText(
                  '3',
                  style: cl.text.title.copyWith(
                    color: cl.colors.onWarm,
                    height: 1,
                  ),
                ),
                Text(
                  l10n.tourCareTaps,
                  style: cl.text.caption.copyWith(color: cl.colors.onWarm),
                ),
              ],
            ),
          ),
        ),
        _chip(
          2,
          16,
          352,
          ClFloatChip(value: l10n.tourCareChipDiaper, icon: ClIcons.diaper),
        ),
        _chip(
          3,
          null,
          352,
          ClFloatChip(value: l10n.tourCareChipSleep, icon: ClIcons.sleep),
          right: 16,
        ),
      ],
    );
  }
}

class TourShareHero extends StatelessWidget {
  const TourShareHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return HeroArt(
      illustration: ClIllustration.handover,
      size: _card,
      color: cl.colors.cardNight,
      overlays: [
        Positioned(
          left: 71,
          width: 200,
          top: 182,
          child: Column(
            children: [
              Text(
                l10n.tourShareAsleep,
                style: cl.text.label.copyWith(color: const Color(0xB3FFFFFF)),
              ),
              ClTabularText(
                '01:24:08',
                style: cl.text.numeral.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ),
        _chip(
          0,
          16,
          20,
          ClFloatChip(value: l10n.tourShareSynced, lead: ClFloatChipLead.check),
        ),
        _chip(
          1,
          16,
          314,
          ClFloatChip(
            value: l10n.tourShareChipMom,
            lead: ClFloatChipLead.avatar,
            initial: l10n.tourShareInitialMom,
          ),
        ),
        _chip(
          2,
          null,
          362,
          right: 16,
          ClFloatChip(
            value: l10n.tourShareChipDad,
            lead: ClFloatChipLead.avatar,
            initial: l10n.tourShareInitialDad,
          ),
        ),
      ],
    );
  }
}

class TourStoryHero extends StatelessWidget {
  const TourStoryHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeroArt(
      illustration: ClIllustration.growthStory,
      size: _card,
      color: context.cl.colors.cardPeach,
      overlays: [
        _chip(
          0,
          16,
          20,
          ClFloatChip(value: l10n.tourStoryChipCard, icon: ClIcons.spark),
        ),
        _chip(
          1,
          null,
          348,
          ClFloatChip(value: l10n.tourStoryChipJournal, icon: ClIcons.journal),
          right: 16,
        ),
      ],
    );
  }
}

class TourPrivateHero extends StatelessWidget {
  const TourPrivateHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final initials = l10n.tourPrivateInitials.split('|');
    Widget initial(
      int i,
      double centerX,
      double top,
      double size,
      Color color,
    ) => Positioned(
      left: centerX - 40,
      width: 80,
      top: top,
      child: Text(
        initials.elementAtOrNull(i) ?? '',
        textAlign: TextAlign.center,
        style: cl.text.title2.copyWith(
          fontSize: size,
          color: color,
          height: 1.25,
        ),
      ),
    );
    return HeroArt(
      illustration: ClIllustration.family,
      size: _card,
      color: cl.colors.cardSun,
      overlays: [
        initial(0, 64, 79, 24, Colors.white),
        initial(1, 292, 99.5, 20, Colors.white),
        initial(2, 286, 270.5, 18, const Color(0xFF173D44)),
        initial(3, 66, 278.5, 18, const Color(0xFF173D44)),
        _chip(
          0,
          null,
          17,
          ClFloatChip(value: l10n.tourPrivateChipAccess, icon: ClIcons.lock),
          right: 16,
        ),
        _chip(
          1,
          16,
          353,
          ClFloatChip(value: l10n.tourPrivateChipInvite, icon: ClIcons.plus),
        ),
      ],
    );
  }
}

/// 06 full-bleed hero (375 × 440): toy blocks "B" "é" and a heart.
class SignInHero extends StatelessWidget {
  const SignInHero({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final letters = AppLocalizations.of(context).signInHeroLetters.split('|');
    Widget letter(String text, double cx, double cy, double turns) =>
        Positioned(
          left: cx - 40,
          top: cy - 40,
          width: 80,
          height: 80,
          child: Transform.rotate(
            angle: turns,
            child: Center(
              child: Text(
                text,
                style: cl.text.display.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173D44),
                ),
              ),
            ),
          ),
        );
    return HeroArt(
      illustration: ClIllustration.signIn,
      size: const Size(375, 440),
      color: cl.colors.cardMint,
      radius: 0,
      overlays: [
        letter(letters.first, 150, 237, -0.07),
        letter(letters.last, 230, 255, 0.07),
      ],
    );
  }
}

class VerifyEmailHero extends StatelessWidget {
  const VerifyEmailHero({super.key});

  @override
  Widget build(BuildContext context) => HeroArt(
    illustration: ClIllustration.verifyEmail,
    size: const Size(343, 300),
    color: context.cl.colors.cardMint,
  );
}

class RecoverHero extends StatelessWidget {
  const RecoverHero({super.key});

  @override
  Widget build(BuildContext context) => HeroArt(
    illustration: ClIllustration.recover,
    size: const Size(343, 200),
    color: context.cl.colors.cardSun,
  );
}

class AccountLinkHero extends StatelessWidget {
  const AccountLinkHero({required this.initial, super.key});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return HeroArt(
      illustration: ClIllustration.accountLink,
      size: const Size(343, 236),
      color: cl.colors.cardMint,
      overlays: [
        Positioned(
          left: 69,
          top: 98,
          width: 80,
          child: Text(
            initial,
            textAlign: TextAlign.center,
            style: cl.text.title.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
