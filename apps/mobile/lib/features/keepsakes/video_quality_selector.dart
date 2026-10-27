import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../premium/premium_v2.dart';
import '../premium/premium_repository.dart';
import '../premium/billing_models.dart';
import '../premium/premium_style.dart';
import '../premium/paywall_screen.dart';

/// The rollout flag keeps legacy exports unchanged. Unknown v2 plans default safely to HD.
bool videoQualityV2Enabled(WidgetRef ref, String babyId) =>
    ref.read(familyPlanV2Provider(babyId)).value?.v2 ??
    ref.read(capabilitiesProvider(babyId)).value?.features.premiumV2 ??
    false;
String videoExportQuality(WidgetRef ref, String babyId, String? selection) {
  if (!videoQualityV2Enabled(ref, babyId)) return 'fullHd1080';
  final premium =
      ref.read(familyPlanV2Provider(babyId)).value?.premium ?? false;
  return selection == 'hd720' || !premium ? 'hd720' : 'fullHd1080';
}

String videoExportLabel(
  WidgetRef ref,
  String babyId,
  String? selection,
  AppLocalizations l,
) => !videoQualityV2Enabled(ref, babyId)
    ? l.ksVideoCreate
    : videoExportQuality(ref, babyId, selection) == 'hd720'
    ? l.videoExportHd
    : l.videoExportFullHd;

/// Visible BEFORE export: choosing a locked quality explains its value without changing the
/// selection or sending a render job. The editor and its draft remain mounted behind the flow.
class VideoQualitySelector extends ConsumerWidget {
  const VideoQualitySelector({
    required this.babyId,
    required this.selection,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });
  final String babyId;
  final String? selection;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plan = ref.watch(familyPlanV2Provider(babyId)).value;
    ref.watch(capabilitiesProvider(babyId));
    if (!videoQualityV2Enabled(ref, babyId)) return const SizedBox.shrink();
    final quality = videoExportQuality(ref, babyId, selection);
    final premium = plan?.premium ?? false;
    return ClListRow(
      title: l10n.videoQuality,
      subtitle: quality == 'hd720'
          ? l10n.videoQualityHd
          : l10n.videoQualityFullHd,
      onTap: !enabled
          ? null
          : () => showClSheet<void>(
              context: context,
              builder: (sheet) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClSheetHeader(title: l10n.videoQuality),
                  ClCardGroup(
                    children: [
                      ClOptionRow(
                        title: l10n.videoQualityHd,
                        subtitle: l10n.videoQualityHdHint,
                        selected: quality == 'hd720',
                        onTap: () {
                          onChanged('hd720');
                          Navigator.of(sheet).pop();
                        },
                      ),
                      ClOptionRow(
                        title: l10n.videoQualityFullHd,
                        subtitle: premium
                            ? l10n.videoQualityFullHdHint
                            : plan == null
                            ? l10n.videoQualityChecking
                            : l10n.videoQualityPremiumHint,
                        selected: quality == 'fullHd1080',
                        onTap: () async {
                          if (plan == null) {
                            ref.invalidate(familyPlanV2Provider(babyId));
                            Navigator.of(sheet).pop();
                            return;
                          }
                          Navigator.of(sheet).pop();
                          if (premium) {
                            onChanged('fullHd1080');
                            return;
                          }
                          final choice = await showPremiumSuggestion(
                            context,
                            title: l10n.videoFullHdIntroTitle,
                            body: l10n.videoFullHdIntroBody,
                            secondary: l10n.videoContinueHd,
                          );
                          if (choice == PremiumSuggestionChoice.primary &&
                              context.mounted) {
                            final upgraded = await openPaywall(
                              context,
                              entry: PaywallEntry.templates,
                              card: PremiumEntry.video,
                            );
                            if (upgraded && context.mounted) {
                              ref.invalidate(familyPlanV2Provider(babyId));
                              onChanged('fullHd1080');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s4),
                ],
              ),
            ),
    );
  }
}
