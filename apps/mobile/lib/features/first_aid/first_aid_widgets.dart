import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../care/care_models.dart';
import '../home/home_shell.dart';
import 'first_aid_models.dart';
import 'first_aid_repository.dart';

/// Shared pieces of the Sơ cứu screens (Figma v1.1 7b–7i, TH01–TH24).

/// The selected baby as first aid uses it: the name, the age in months (null when this member
/// cannot see the date of birth), the age label, and the latest weight for the 7h call sheet.
typedef FaBaby = ({
  String name,
  int? months,
  String? ageLabel,
  double? weightKg,
});

final faBabyProvider = Provider.family<FaBaby?, AppLocalizations>((ref, l10n) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  final baby = ref.watch(babyProvider(me.babyId)).value;
  if (baby == null) return null;
  final dob = me.canViewBabyInfo
      ? ref.watch(babyPrivateProfileProvider(me.babyId)).value?.dateOfBirth
      : null;
  final today = ref.watch(minuteClockProvider).value ?? DateTime.now();
  int? months;
  if (dob != null) {
    months = (today.year - dob.year) * 12 + today.month - dob.month;
    if (today.day < dob.day) months -= 1;
    if (months < 0) months = 0;
  }
  final growth =
      ref.watch(growthRecordsProvider(me.babyId)).value ?? const <CareRecord>[];
  double? kg;
  DateTime? at;
  for (final r in growth) {
    if (r.weightKg != null && (at == null || r.occurredAt.isAfter(at))) {
      kg = r.weightKg;
      at = r.occurredAt;
    }
  }
  return (
    name: baby.nickname,
    months: months,
    ageLabel: dob == null ? null : ageLong(l10n, dob, today),
    weightKg: kg,
  );
});

/// A guide picture (from disk once downloaded).
class FaImage extends ConsumerWidget {
  const FaImage(
    this.id, {
    this.radius = 24,
    this.aspectRatio = 1.6,
    this.semanticLabel,
    super.key,
  });

  final String id;
  final double radius;
  final double aspectRatio;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final image = ref.watch(firstAidImageProvider)(id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => ColoredBox(color: cl.colors.surface2),
          frameBuilder: (_, child, frame, sync) => frame == null && !sync
              ? ColoredBox(color: cl.colors.surface2)
              : child,
        ),
      ),
    );
  }
}

/// A pictogram (Icon/FA, 40–44 px).
class FaIcon extends ConsumerWidget {
  const FaIcon(this.id, {this.size = 44, super.key});
  final String id;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(firstAidImageProvider)(id);
    return SizedBox(
      width: size,
      height: size,
      child: Image(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: context.cl.colors.surface2,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// White round button (back, close, bookmark) of the first-aid pages.
class FaRoundButton extends StatelessWidget {
  const FaRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });

  final ClIcons icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(icon, size: 20, color: color ?? cl.colors.ink),
      ),
    );
  }
}

/// The red "Gọi 115" pill (small in the top row, large in the bottom bar and 7b card).
class FaCallButton extends StatelessWidget {
  const FaCallButton({
    required this.number,
    required this.onPressed,
    this.small = false,
    this.expand = false,
    super.key,
  });

  final String number;
  final VoidCallback onPressed;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final label = l10n.faCall(number);
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClIcon(ClIcons.phone, size: small ? 16 : 20, color: cl.colors.onDanger),
        const SizedBox(width: 8),
        Text(
          label,
          style: cl.text.label.copyWith(
            fontSize: small ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: cl.colors.onDanger,
          ),
        ),
      ],
    );
    return ClPressable(
      key: const Key('faCall'),
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minHeight: small ? ClSpace.tapMin : 52),
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
        decoration: BoxDecoration(
          color: cl.colors.danger,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        alignment: Alignment.center,
        child: row,
      ),
    );
  }
}

/// A small pill tag ("Khẩn cấp", "Dùng được khi không có mạng").
class FaTag extends StatelessWidget {
  const FaTag(
    this.text, {
    required this.background,
    required this.ink,
    super.key,
  });
  final String text;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(ClRadius.pill),
    ),
    child: Text(
      text,
      style: context.cl.text.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
  );
}

(Color, Color) faToneColors(BuildContext context, FaTone tone) {
  final c = context.cl.colors;
  return switch (tone) {
    FaTone.danger => (c.dangerSoft, c.danger),
    FaTone.sunshine => (c.sunshineSoft, c.ink),
    FaTone.mint => (c.mintSoft, c.mintText),
  };
}

/// One situation as a 2-column card (Khẩn cấp) or a list row (7b, 7c, saved).
class FaSituationCard extends StatelessWidget {
  const FaSituationCard({
    required this.situation,
    required this.onTap,
    super.key,
  });
  final FaSituation situation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final title = situation.title.of(context);
    final lead = situation.lead.of(context);
    return ClPressable(
      onPressed: onTap,
      semanticLabel: '$title. $lead',
      // ClPressable centres its child: fill the grid cell so a row's cards match.
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FaIcon(situation.icon),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: cl.text.bodyStrong.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lead,
              style: cl.text.caption.copyWith(
                color: cl.colors.inkMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaSituationRow extends StatelessWidget {
  const FaSituationRow({
    required this.situation,
    required this.onTap,
    this.subline,
    super.key,
  });
  final FaSituation situation;
  final VoidCallback onTap;

  /// 7c shows the matching passage instead of the lead.
  final String? subline;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final title = situation.title.of(context);
    final sub = subline ?? situation.lead.of(context);
    return ClPressable(
      onPressed: onTap,
      semanticLabel: '$title. $sub',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            FaIcon(situation.icon, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// A white group of rows with hairlines (7b lists, 7c results, saved).
class FaGroup extends StatelessWidget {
  const FaGroup({required this.children, super.key});
  final List<Widget> children;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(height: 1, color: cl.colors.separator),
            c,
          ],
        ],
      ),
    );
  }
}

/// "1,5" / "1.5": the locale's decimal for the call sheet weight.
String faKg(Locale locale, double kg) {
  final s = kg.toStringAsFixed(kg == kg.roundToDouble() ? 0 : 1);
  return locale.languageCode == 'vi' ? s.replaceAll('.', ',') : s;
}
