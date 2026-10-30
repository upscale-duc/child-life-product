import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/today_adaptive.dart' show AxCard;
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../care/timer_models.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart' show selectedCapabilitiesProvider;
import '../premium/premium_v2.dart' show PremiumEntry;
import 'coming_up.dart';
import 'rhythm_access.dart';

/// "Sắp tới" on Hôm nay (sprint wow W1, owner 2026-10-30): the next feed and the next sleep (or
/// the waking) as clock ranges from this baby's own last 14 days. For those who read care in a
/// household with `rhythm.advanced`. D-147 (the app is not live, purchase comes later): a Free
/// household sees the invite instead, only when this baby's log already gives ranges; nothing
/// while the plan or the log is unknown (D-125, SY-1) or for another gate reason. Read-only; it
/// reuses the records Hôm nay already listens to.
class ComingUpCard extends ConsumerWidget {
  const ComingUpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    if (me == null || !familyCan(me, FamilyAction.historyRead)) {
      return const SizedBox.shrink();
    }
    final caps = ref.watch(selectedCapabilitiesProvider);
    if (caps == null) return const SizedBox.shrink();
    final advanced = caps.allows(Capability.rhythmAdvanced);
    final invite =
        !advanced &&
        caps.reasonFor(Capability.rhythmAdvanced) == GateReason.premiumRequired;
    if (!advanced && !invite) return const SizedBox.shrink();
    final records = ref.watch(recentRecordsProvider(me.babyId)).value;
    if (records == null) return const SizedBox.shrink();
    final zone =
        ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
        'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final sleepTimer = ref
        .watch(careTimerProvider((me.babyId, TimerType.sleep)))
        .value;
    final breastTimer = ref
        .watch(careTimerProvider((me.babyId, TimerType.breast)))
        .value;
    final up = comingUp(
      records: records,
      now: now,
      zone: zone,
      sleepTimerSince: sleepTimer?.startedAt,
      feedTimerRunning: breastTimer != null,
    );
    if (up.isEmpty) return const SizedBox.shrink();
    if (invite) {
      return ComingUpInvite(
        babyName: ref.watch(babyProvider(me.babyId)).value?.nickname ?? '',
      );
    }
    return ComingUpView(up: up, zone: zone);
  }
}

/// D-147: "Sắp tới" for a Free household whose log already gives ranges: what Premium would
/// show here, without the times, and the way to Premium.
class ComingUpInvite extends StatelessWidget {
  const ComingUpInvite({required this.babyName, super.key});

  final String babyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return AxCard(
      key: const Key('comingUpInvite'),
      icon: ClIcons.clock,
      chip: cl.colors.mintSoft,
      title: l10n.cuTitle,
      subtitle: l10n.pmInPremium,
      link: l10n.pv2SeePremium,
      onLink: () => unawaited(
        openPaywall(
          context,
          entry: PaywallEntry.rhythm,
          card: PremiumEntry.rhythm,
        ),
      ),
      child: Text(
        l10n.cuInvite(babyName),
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
    );
  }
}

/// The card itself, separate from the providers for goldens and widget tests.
class ComingUpView extends StatelessWidget {
  const ComingUpView({required this.up, required this.zone, super.key});

  final ComingUp up;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final hm = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    String clock(DateTime at) => hm.format(inBabyZone(zone, at));

    Widget row(ComingUpRow r) {
      final (icon, tone, label, since) = switch (r.kind) {
        ComingUpKind.feed => (
          ClIcons.feed,
          cl.care.bottle,
          l10n.cuFeed,
          l10n.cuLastFeed(clock(r.since)),
        ),
        ComingUpKind.sleep => (
          ClIcons.sleep,
          cl.care.sleep,
          l10n.cuSleep,
          l10n.cuWokeAt(clock(r.since)),
        ),
        ComingUpKind.wake => (
          ClIcons.sunrise,
          cl.care.sleep,
          l10n.cuWake,
          l10n.cuAsleepSince(clock(r.since)),
        ),
      };
      final from = clock(r.from), to = clock(r.to);
      final window = from == to ? l10n.cuAround(from) : l10n.cuWindow(from, to);
      return MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(ClSpace.s2),
                decoration: BoxDecoration(
                  color: tone.soft,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                ),
                child: ClIcon(icon, size: 18, color: tone.ink),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                    Text(
                      window,
                      style: cl.text.bodyStrong.copyWith(
                        color: cl.colors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      since,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AxCard(
      key: const Key('comingUp'),
      icon: ClIcons.clock,
      chip: cl.colors.mintSoft,
      title: l10n.cuTitle,
      subtitle: l10n.cuBasis(comingUpLookbackDays),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (up.feed case final f?) row(f),
          if (up.sleep case final s?) row(s),
        ],
      ),
    );
  }
}
