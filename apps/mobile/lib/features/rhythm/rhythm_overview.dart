import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../ai/handover_screen.dart' show HandoverEntry;
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/plan_screen.dart' show showRegionSheet;
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart';
import 'rhythm_access.dart';
import 'rhythm_actions.dart';
import 'rhythm_calc.dart';
import 'rhythm_calendar.dart';
import 'rhythm_home.dart' show RhHealthCard;
import 'rhythm_local.dart';
import 'rhythm_models.dart';
import 'rhythm_own.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// Nhịp lớn lên supports babies up to 12 months (NL01b); older babies keep what was logged.
const rhythmMaxAgeDays = 365;

/// NL01 (569:973) / NL01b (570:1002) "Nhịp lớn lên": two layers that never mix — LỊCH THAM
/// KHẢO (free, from the published model and the due date) and NHỊP RIÊNG CỦA CON (the family's
/// notes; the sleep comparison with `rhythm.advanced`) — then "Cách nhà mình đã thử". Honest
/// states: no due date, not enough data (counted automatically, D-073 #1), region not chosen,
/// out of age, offline. On first open the owner is asked the household's region (D-072 #3) and
/// a Cùng nuôi gets the setup NL02a–c once.
class RhythmOverviewScreen extends ConsumerStatefulWidget {
  const RhythmOverviewScreen({super.key});

  @override
  ConsumerState<RhythmOverviewScreen> createState() =>
      _RhythmOverviewScreenState();
}

class _RhythmOverviewScreenState extends ConsumerState<RhythmOverviewScreen> {
  var _firstOpenDone = false;

  /// Region first (owner only), then the setup (Cùng nuôi, once per baby on this phone).
  Future<void> _firstOpen(Membership me, Capabilities caps) async {
    if (caps.country == null &&
        caps.canManageBilling &&
        !rhythmRegionAsked(ref, me.uid, me.babyId)) {
      markRhythmRegionAsked(ref, me.uid, me.babyId);
      await showRegionSheet(context, babyId: me.babyId, current: null);
      if (!mounted) return;
    }
    if (familyCan(me, FamilyAction.rhythmSetup) &&
        !rhythmSetupSeen(ref, me.uid, me.babyId)) {
      unawaited(context.push(Routes.rhythmSetup));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    final caps = ref.watch(selectedCapabilitiesProvider);
    final topBar = Align(
      alignment: Alignment.centerLeft,
      child: RhRoundIcon(
        icon: ClIcons.back,
        label: l10n.a11yBack,
        onPressed: () => leaveRhythm(context),
      ),
    );
    if (me == null) {
      return OnboardingScaffold(topBar: topBar, content: const []);
    }
    if (caps != null && !caps.features.rhythm) {
      return OnboardingScaffold(
        topBar: topBar,
        content: [
          Text(l10n.rhTitle, style: cl.text.title),
          const SizedBox(height: ClSpace.s3),
          RhInfoBox(icon: ClIcons.lock, text: l10n.pmGateDisabledBody),
        ],
      );
    }
    if (caps != null && !_firstOpenDone) {
      _firstOpenDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_firstOpen(me, caps));
      });
    }

    final baby = ref.watch(babyProvider(me.babyId)).value;
    final name = baby?.nickname ?? '';
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final todayDate = babyToday(zone, now);
    final today = isoOf(todayDate);
    final online = ref.watch(onlineProvider).value ?? true;
    final profile = me.canViewBabyInfo
        ? ref.watch(rhythmProfileProvider(me.babyId)).value
        : null;
    final dob = profile?.dateOfBirth;
    final canRead = familyCan(me, FamilyAction.historyRead);
    final health = canRead
        ? (ref.watch(checkInsProvider(me.babyId)).value ?? const <CheckIn>[])
              .where((c) => c.date == today && c.needsHealthSupport)
              .firstOrNull
        : null;
    final outOfAge =
        dob != null && ageInDays(dob, todayDate) > rhythmMaxAgeDays;

    return OnboardingScaffold(
      topBar: topBar,
      content: [
        Semantics(
          header: true,
          child: Text(l10n.rhTitle, style: cl.text.title),
        ),
        const SizedBox(height: ClSpace.s1),
        Text(
          dob == null
              ? name
              : l10n.rhBabyAge(name, ageLong(l10n, dob, todayDate)),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        if (!online) ...[
          RhInfoBox(icon: ClIcons.cloudOff, text: l10n.rhOfflineNote),
          const SizedBox(height: ClSpace.s3),
        ],
        if (caps != null && caps.country == null) ...[
          _RegionNotice(me: me, owner: caps.canManageBilling),
          const SizedBox(height: ClSpace.s3),
        ],
        if (outOfAge) ...[
          RhInfoBox(icon: ClIcons.cake, text: l10n.rhOutOfAge),
          const SizedBox(height: ClSpace.s3),
        ],
        if (health != null) ...[
          // Health first; calendar talk pauses ("Child Life dừng gợi ý theo lịch").
          RhHealthCard(signs: health.healthSigns),
          const SizedBox(height: ClSpace.s3),
        ] else ...[
          ReferenceCalendarCard(me: me, today: today, babyName: name),
          const SizedBox(height: ClSpace.s3),
        ],
        OwnRhythmCard(me: me, caps: caps, zone: zone, today: today),
        // SU01 (Premium Slice 3): the handover for the next carer.
        if (HandoverEntry.visibleFor(
          ref,
          me,
          caps,
          Localizations.localeOf(context).languageCode,
        )) ...[
          const SizedBox(height: ClSpace.s3),
          const HandoverEntry(),
        ],
        if (canRead) ...[
          const SizedBox(height: ClSpace.s4),
          TriedSection(me: me),
        ],
        const SizedBox(height: ClSpace.s4),
        RhNote(l10n.rhFooterFacts),
      ],
    );
  }
}

/// D-072 #3: the owner chooses the region (never inferred); everyone else waits for them, and
/// the free parts keep working.
class _RegionNotice extends StatelessWidget {
  const _RegionNotice({required this.me, required this.owner});
  final Membership me;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (!owner) {
      return RhInfoBox(icon: ClIcons.globe, text: l10n.rhRegionWaiting);
    }
    return RhCard(
      hairline: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.globe, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(l10n.pmRegionTitle, style: cl.text.bodyStrong),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.rhRegionOwnerBody,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          RhPillButton(
            label: l10n.rhRegionPick,
            onTap: () =>
                showRegionSheet(context, babyId: me.babyId, current: null),
          ),
        ],
      ),
    );
  }
}
