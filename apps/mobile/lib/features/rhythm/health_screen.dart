import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/premium_repository.dart';
import 'rhythm_actions.dart';
import 'rhythm_labels.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// HL01 (594:7066 / 594:7195), "luôn miễn phí (kể cả khi hết gói)": free in every plan state,
/// no paywall, no upsell, no AI. The emergency number comes only from the published health pack
/// for the household's country (D-072 #3); without one, only "Gọi bác sĩ của bé" — never a
/// default hotline. While-waiting steps and the disclaimer come from the same reviewed pack.
class HealthSupportScreen extends ConsumerWidget {
  const HealthSupportScreen({this.signs = const [], super.key});

  /// The signs answered "Có" (NL05b).
  final List<HealthSign> signs;

  Future<void> _dial(BuildContext context, WidgetRef ref, String number) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final ok = await ref.read(rhythmDialerProvider)(number);
    if (!ok) toaster.show(message: l10n.rhHlDialFailed, error: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final pack = ref.watch(rhythmContentProvider).value?.health;
    final country = ref.watch(selectedCapabilitiesProvider)?.country;
    final number = pack?.emergencyNumberFor(country);
    final waiting = pack?.whileWaiting.of(locale) ?? const <String>[];
    return OnboardingScaffold(
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: RhRoundIcon(
          icon: ClIcons.close,
          label: l10n.a11yClose,
          onPressed: () => closeFlow(context),
        ),
      ),
      content: [
        Semantics(
          header: true,
          child: Text(
            l10n.rhHlTitle,
            style: cl.text.title2.copyWith(color: cl.colors.ink),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Text(l10n.rhHlBody, style: cl.text.body.copyWith(color: cl.colors.ink)),
        if (signs.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          Text(
            l10n.rhHlNoted,
            style: cl.text.label.copyWith(
              color: cl.colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          RhBullets([for (final s in signs) signLabel(l10n, s)]),
        ],
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.dangerSoft,
            borderRadius: BorderRadius.circular(rhCardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (number != null) ...[
                _CallButton(
                  label: l10n.rhHlCallEmergency(number),
                  onPressed: () => _dial(context, ref, number),
                ),
                const SizedBox(height: ClSpace.s2),
              ] else ...[
                Text(
                  l10n.rhHlNoRegion,
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                ),
                const SizedBox(height: ClSpace.s3),
              ],
              ClButton(
                label: l10n.rhHlCallDoctor,
                icon: ClIcons.phone,
                style: ClButtonStyle.outline,
                expand: true,
                // The doctor's number is not stored: this opens the phone app.
                onPressed: () => _dial(context, ref, ''),
              ),
              const SizedBox(height: ClSpace.s3),
              Text(
                l10n.rhHlHelper,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          RhCard(
            hairline: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RhCardHeading(l10n.rhHlWhileWaiting),
                const SizedBox(height: ClSpace.s3),
                RhSteps(waiting),
                const SizedBox(height: ClSpace.s3),
                RhReviewNote(pack?.review),
              ],
            ),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        Text(
          pack?.disclaimer?.of(locale) ?? l10n.rhHlDisclaimer,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          children: [
            ClIcon(ClIcons.check, size: 14, color: cl.colors.mintText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.rhHlAlwaysFree,
                style: cl.text.caption.copyWith(
                  color: cl.colors.mintText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.rhDone,
          style: ClButtonStyle.secondary,
          expand: true,
          onPressed: () => closeFlow(context),
        ),
      ],
    );
  }
}

/// The solid red call button (first aid "Gọi 115" colours: danger + onDanger).
class _CallButton extends StatelessWidget {
  const _CallButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        height: ClSpace.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.danger,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClIcon(ClIcons.phone, size: 18, color: cl.colors.onDanger),
            const SizedBox(width: ClSpace.s2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cl.text.bodyStrong.copyWith(color: cl.colors.onDanger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
