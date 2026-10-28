import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/cl_theme.dart';

/// Fixed-colour illustrations exported from Figma (24:365). Decorative unless labelled.
enum ClIllustration {
  welcome('welcome'),
  signIn('sign-in'),
  verifyEmail('verify-email'),
  recover('recover'),
  accountLink('account-link'),
  inviteCode('invite-code'),
  invite('invite'),
  expired('expired'),
  babyAvatar('baby-avatar'),
  babyFace('baby-face'),
  todayHeroEmpty('today-hero-empty'),
  care('care'),
  handover('handover'),
  growthStory('growth-story'),
  family('family'),
  miniBottle('mini-bottle'),
  miniDrop('mini-drop'),
  miniMoon('mini-moon'),
  miniDiaper('mini-diaper'),
  miniRuler('mini-ruler'),
  miniWetDirty('mini-wet-dirty'),
  miniPump('mini-pump'),
  miniBath('mini-bath'),
  miniBook('mini-book'),
  personBa('person-ba'),
  personMe('person-me'),
  personBaNoi('person-ba-noi'),
  personOng('person-ong'),
  personHelper('person-helper');

  const ClIllustration(this.file);
  final String file;

  String get asset => 'assets/illustrations/$file.svg';
}

class ClArt extends StatelessWidget {
  const ClArt(
    this.illustration, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  final ClIllustration illustration;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      illustration.asset,
      width: width,
      height: height,
      fit: fit,
    ),
  );
}

/// Official "Khoảnh khắc" logo (Logo 33:2). Colour variants follow the palette (logo/* night palette).
enum ClLogoKind { mark, lockup }

class ClLogo extends StatelessWidget {
  const ClLogo({
    this.kind = ClLogoKind.mark,
    this.height = 28,
    this.semanticLabel = 'Child Life',
    super.key,
  });

  final ClLogoKind kind;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final night = context.cl.isNightCare;
    final file = switch (kind) {
      ClLogoKind.mark => night ? 'mark-night' : 'mark-color',
      ClLogoKind.lockup => night ? 'lockup-h-night' : 'lockup-h-color',
    };
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SvgPicture.asset('assets/logo/$file.svg', height: height),
      ),
    );
  }
}
