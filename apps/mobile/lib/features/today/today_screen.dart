import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart';

/// 18 Hôm nay (lần đầu) tab (29:904): empty tiles per trackers. Logging, coachmarks (18a–18c)
/// and the totals arrive in S4; relatives granted daily care see it read-only (D-018). Nothing
/// here is marked done in the coverage checklist.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final membership = ref.watch(selectedMembershipProvider);
    if (membership == null) return ColoredBox(color: cl.colors.cloud);
    final baby = ref.watch(babyProvider(membership.babyId)).value;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final trackers = baby?.trackers ?? const <TrackerKind>[];
    final readOnly = membership.role == MemberRole.relative;

    void tap() => showClToast(
      context,
      message: readOnly ? l10n.todayViewOnly : l10n.todayLoggingSoon,
    );

    return ColoredBox(
      color: cl.colors.cloud,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            140,
          ),
          children: [
            const BabyHeader(),
            const SizedBox(height: ClSpace.s4),
            Text(
              toBeginningOfSentenceCase(
                DateFormat('EEEE, d MMMM', locale).format(now),
              ),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            Semantics(
              header: true,
              child: Text(
                l10n.todayTitle,
                style: cl.text.largeTitle.copyWith(color: cl.colors.ink),
              ),
            ),
            const SizedBox(height: ClSpace.s4),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: ClSpace.s3,
              crossAxisSpacing: ClSpace.s3,
              childAspectRatio: 166 / 128,
              children: [
                for (final kind in trackers)
                  _EmptyCareTile(kind: kind, readOnly: readOnly, onTap: tap),
              ],
            ),
            const SizedBox(height: ClSpace.s6),
            Text(
              l10n.todayTitle,
              style: cl.text.headline.copyWith(color: cl.colors.ink),
            ),
            const SizedBox(height: ClSpace.s3),
            Container(
              padding: const EdgeInsets.all(ClSpace.s4),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.card),
                boxShadow: cl.shadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.todaySummaryEmpty,
                    style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                  ),
                  const SizedBox(height: ClSpace.s1),
                  Text(
                    l10n.todaySummaryEmptyBody,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
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

/// First-run tile: "Chưa có / Chạm để ghi" on the tracker's care colour (R-012).
class _EmptyCareTile extends StatelessWidget {
  const _EmptyCareTile({
    required this.kind,
    required this.onTap,
    this.readOnly = false,
  });
  final TrackerKind kind;
  final VoidCallback onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final care = switch (kind) {
      TrackerKind.bottle => cl.care.bottle,
      TrackerKind.breast => cl.care.breast,
      TrackerKind.sleep => cl.care.sleep,
      TrackerKind.diaper => cl.care.diaper,
      TrackerKind.pump => cl.care.pump,
      TrackerKind.growth => cl.care.growth,
    };
    final label = trackerLabel(l10n, kind);
    return ClPressable(
      semanticLabel: readOnly
          ? '$label, ${l10n.todayTileEmpty}'
          : '$label, ${l10n.todayTileEmpty}. ${l10n.todayTileTapToLog}',
      onPressed: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: care.soft,
          borderRadius: BorderRadius.circular(ClRadius.tile),
          border: Border.all(color: cl.colors.cardEdge),
          boxShadow: cl.shadows.tile,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -12,
              child: ClArt(trackerArt(kind), width: 76, height: 76),
            ),
            Padding(
              padding: const EdgeInsets.all(ClSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: cl.text.label.copyWith(color: care.ink)),
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    l10n.todayTileEmpty,
                    style: cl.text.title2.copyWith(color: cl.colors.ink),
                  ),
                  const Spacer(),
                  if (!readOnly)
                    Text(
                      l10n.todayTileTapToLog,
                      style: cl.text.label.copyWith(color: care.ink),
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
