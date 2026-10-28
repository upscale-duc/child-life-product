import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import 'auto_save_controller.dart';
import 'auto_save_engine.dart';
import 'auto_save_widgets.dart';

/// Suggestions for the selected baby the Hôm nay banner should mention: pending, and not all
/// put off with "Để sau" (AR02).
final autoSaveBannerProvider = Provider.autoDispose<List<Candidate>>((ref) {
  if (!ref.watch(autoSaveAvailableProvider)) return const [];
  final view = ref.watch(autoSaveProvider);
  final babyId = ref.watch(selectedBabyIdProvider);
  if (!view.active || babyId == null) return const [];
  final pending = [
    for (final c in view.state.pending)
      if (c.match.babyId == babyId) c,
  ];
  if (pending.every((c) => view.state.bannerHidden.contains(c.asset.id))) {
    return const [];
  }
  return pending;
});

/// Whether the Kỷ niệm tab shows a dot (AR02): suggestions wait for the selected baby.
final autoSaveTabDotProvider = Provider.autoDispose<bool>((ref) {
  if (!ref.watch(autoSaveAvailableProvider)) return false;
  final view = ref.watch(autoSaveProvider);
  final babyId = ref.watch(selectedBabyIdProvider);
  return view.active && babyId != null && view.pendingFor(babyId) > 0;
});

/// AR02: "8 ảnh mới có thể có Teddy" on Hôm nay, above the care tiles.
class AutoSaveTodayBanner extends ConsumerWidget {
  const AutoSaveTodayBanner({this.top = ClSpace.s3, super.key});
  final double top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(autoSaveBannerProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final babyId = pending.first.match.babyId;
    final name = ref.watch(babyProvider(babyId)).value?.nickname ?? '';
    // One per group of near-copies, as the review counts them (owner, 2026-10-15).
    final groups = groupAndRank(pending);
    final title = l10n.autoSaveBannerTitle(groups.length, name);
    final later = ref.read(autoSaveProvider.notifier).hideBanner;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Container(
        key: const Key('autoSaveBanner'),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: cl.colors.sunshineSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 486:7227: up to three thumbs side by side, each ringed in the banner's own
                // colour so an overlap reads as a stack, not one blurred picture.
                SizedBox(
                  width: 36.0 + (math.min(groups.length, 3) - 1) * 24,
                  height: 36,
                  child: Stack(
                    children: [
                      for (final (i, c) in [
                        for (final g in groups.take(3)) g.best,
                      ].indexed)
                        Positioned(
                          left: i * 24.0,
                          child: Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cl.colors.sunshineSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LibraryTile(assetId: c.asset.id, radius: 8),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: cl.text.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.autoSaveBannerBody,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClPressable(
                  key: const Key('autoSaveBannerClose'),
                  onPressed: () => unawaited(later()),
                  semanticLabel: l10n.autoSaveBannerLater,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: ClIcon(
                        ClIcons.close,
                        size: 16,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                // The main button takes the room, "Để sau" its own width (486:7227), so
                // "Xem & chọn ảnh" is never cut.
                children: [
                  Expanded(
                    child: ClButton(
                      label: l10n.autoSaveBannerOpen,
                      expand: true,
                      // Straight to the review (AS07), where each photo can be seen and
                      // ticked (owner, 2026-10-15); the AR05 quick sheet is gone.
                      onPressed: () => unawaited(
                        GoRouter.of(context).push(Routes.autoSaveReview),
                      ),
                    ),
                  ),
                  const SizedBox(width: ClSpace.s2),
                  ClButton(
                    label: l10n.autoSaveBannerLater,
                    style: ClButtonStyle.secondary,
                    onPressed: () => unawaited(later()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
