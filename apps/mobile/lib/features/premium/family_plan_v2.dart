import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/countries.dart';
import '../family/family_labels.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../me/me_widgets.dart';
import 'billing_models.dart';
import 'paywall_screen.dart';
import 'plan_screen.dart' show showRegionSheet;
import 'premium_models.dart';
import 'premium_repository.dart';
import 'premium_style.dart';
import 'premium_v2.dart';
import 'store_gateway.dart';

/// Premium v2 · Quản lý gói (Figma 968:14661, D-101): Gói của gia đình for the manager
/// (PV40 Premium / PV40B Free), for a member (PV45) and after a downgrade (PV43), the usage
/// history (PV41), who keeps writing (PV44), what cancelling means (PV42) and extra storage
/// (PW10, "Sắp có" until in-app purchase). Three separate bars, never one credit meter (Note ·
/// PV40); balances live here only (D-081).

abstract final class PlanV2Routes {
  static const history = '/family-plan/history';
  static const addOn = '/family-plan/storage';
  static const cancel = '/family-plan/cancel';
}

String _day(BuildContext context, DateTime d) => DateFormat(
  'dd/MM/yyyy',
  Localizations.localeOf(context).toLanguageTag(),
).format(d.toLocal());

String _dayShort(BuildContext context, DateTime d) => DateFormat(
  'dd/MM',
  Localizations.localeOf(context).toLanguageTag(),
).format(d.toLocal());

/// Writers of the family (Cùng nuôi + Người chăm sóc, one seat each) across the babies the
/// manager owns, for PV44. A member of another baby only still counts once.
final familyWritersProvider = Provider.autoDispose
    .family<List<Membership>?, String>((ref, babyId) {
      final session = ref.watch(sessionProvider);
      if (session is! SessionSignedIn) return null;
      final familyId = ref.watch(babyProvider(babyId)).value?.familyId;
      final babies = <String>{babyId};
      for (final m in session.memberships) {
        if (m.status != MembershipStatus.active) continue;
        final other = ref.watch(babyProvider(m.babyId)).value;
        if (other != null && other.familyId == familyId) babies.add(m.babyId);
      }
      final seen = <String, Membership>{};
      for (final b in babies) {
        final members = ref.watch(familyMembersProvider(b)).value;
        if (members == null) return null;
        for (final m in members) {
          if (m.status != MembershipStatus.active ||
              m.role == MemberRole.relative) {
            continue;
          }
          seen.putIfAbsent(m.uid, () => m);
        }
      }
      final list = seen.values.toList()
        ..sort((a, b) => a.isOwner == b.isOwner ? 0 : (a.isOwner ? -1 : 1));
      return list;
    });

/// Gói của gia đình v2: what HouseholdPlanScreen draws while `premium_v2` is on.
class FamilyPlanV2Screen extends ConsumerWidget {
  const FamilyPlanV2Screen({
    required this.babyId,
    required this.caps,
    super.key,
  });

  final String babyId;
  final Capabilities caps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final async = ref.watch(familyPlanV2Provider(babyId));
    final plan = async.value;
    final members = ref.watch(familyMembersProvider(babyId)).value ?? const [];
    final me = ref.watch(selectedMembershipProvider);
    final baby = ref.watch(babyProvider(babyId)).value;
    final manager = members.where((m) => m.isOwner).firstOrNull;
    final managerName = manager?.displayName ?? l10n.pv2TheManager;
    final isManager = plan?.isManager ?? caps.canManageBilling;
    final premium = plan?.premium ?? caps.plan == HouseholdPlan.premium;
    final suspendedMe =
        me != null && (plan?.suspended.contains(me.uid) ?? false);
    final store = ref.watch(storeGatewayProvider);
    final downgraded = !premium && caps.plan == HouseholdPlan.expired;

    final children = <Widget>[];
    if (async.isLoading && plan == null) {
      children.add(const ClSkeleton(height: 320));
    } else if (plan == null) {
      children.add(
        MeNotice(
          tone: MeTone.warn,
          icon: ClIcons.cloudOff,
          title: l10n.pv2HistoryError,
        ),
      );
    } else {
      if (downgraded || plan.overLimit || (!premium && plan.storageOver)) {
        children.addAll([
          MeNotice(
            icon: ClIcons.alert,
            title: caps.validUntil == null
                ? l10n.pv2DowngradedBannerNoDate
                : l10n.pv2DowngradedBanner(_day(context, caps.validUntil!)),
          ),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      if (suspendedMe) {
        children.addAll([
          MeNotice(icon: ClIcons.eye, title: l10n.pv2SuspendedNote),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      children.addAll([
        _PlanCard(
          premium: premium,
          isManager: isManager,
          managerName: managerName,
        ),
        const SizedBox(height: ClSpace.s3),
        if (isManager && plan.storageOver && !premium) ...[
          _StateCard(
            icon: ClIcons.cloudOff,
            title: l10n.pv2OverStorageTitle(
              premiumGb(context, plan.usedBytes),
              premiumGb(context, plan.limitBytes),
            ),
            body: l10n.pv2OverStorageBody(premiumGb(context, plan.limitBytes)),
            actions: [
              (l10n.pv2ManageMedia, () => context.push(Routes.meStorage)),
              (
                l10n.pv2UpgradeAgain,
                () => openPaywall(
                  context,
                  entry: PaywallEntry.plan,
                  card: PremiumEntry.storage,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        if (isManager && plan.overLimit) ...[
          _StateCard(
            icon: ClIcons.family,
            title: l10n.pv2OverSeatsTitle(plan.seatsUsed, plan.seatsLimit),
            body: l10n.pv2OverSeatsBody(plan.seatsLimit),
            actions: [
              (
                l10n.pv2ChoosePeople,
                () => showSeatPicker(context, babyId: babyId, plan: plan),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
        ],
        _Allowances(plan: plan),
        const SizedBox(height: ClSpace.s3),
      ]);
      if (isManager && premium) {
        children.addAll([
          ClCardGroup(
            children: [
              if (plan.cycleEnd case final end?)
                MeRow(
                  title: l10n.pv2NextRefill,
                  subtitle: l10n.pv2NextRefillValue(_day(context, end)),
                ),
              if (plan.validUntil case final until?) ...[
                MeRow(title: l10n.pv2Renews, value: _day(context, until)),
                MeRow(
                  title: l10n.pv2IfCancel,
                  subtitle: l10n.pv2IfCancelValue(_day(context, until)),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      if (isManager && !premium) {
        children.addAll([
          _Upsell(
            title: l10n.pv2FreeUpsellTitle(baby?.nickname ?? ''),
            body: l10n.pv2FreeUpsellBody,
            action: l10n.pv2SeePlans,
            onTap: () => openPaywall(
              context,
              entry: PaywallEntry.plan,
              card: PremiumEntry.explore,
            ),
          ),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      if (!isManager) {
        children.addAll([
          MeNotice(icon: ClIcons.lock, title: l10n.pv2MemberNote(managerName)),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      final manageStore = switch (caps.billingProvider) {
        'apple' => StoreProvider.apple,
        'google' => StoreProvider.google,
        _ => null,
      };
      children.add(
        ClCardGroup(
          children: [
            if (isManager && premium)
              MeRow(
                icon: ClIcons.spark,
                title: l10n.pv2BuyStorage,
                onTap: () => context.push(PlanV2Routes.addOn),
              ),
            MeRow(
              icon: ClIcons.clock,
              title: isManager ? l10n.pv2History : l10n.pv2HistoryMine,
              subtitle: isManager ? l10n.pv2HistorySub : null,
              onTap: () => context.push(PlanV2Routes.history),
            ),
            if (isManager && premium && manageStore != null && caps.paidPlan)
              MeRow(
                icon: ClIcons.link,
                title: l10n.pv2ManageRenewal,
                subtitle: l10n.pv2OpenStore(
                  manageStore == StoreProvider.apple
                      ? l10n.pv2StoreApple
                      : l10n.pv2StoreGoogle,
                ),
                onTap: () => context.push(PlanV2Routes.cancel),
              ),
            if (isManager)
              MeRow(
                icon: ClIcons.family,
                title: l10n.pv2Seats,
                value: l10n.pv2SeatsOf(plan.seatsUsed, plan.seatsLimit),
                onTap: plan.overLimit || plan.suspended.isNotEmpty
                    ? () => showSeatPicker(context, babyId: babyId, plan: plan)
                    : null,
              ),
            if (isManager)
              MeRow(
                icon: ClIcons.globe,
                title: l10n.pmRegionRow,
                value: caps.country == null
                    ? l10n.pmRegionUnset
                    : countryName(l10n, caps.country!),
                onTap: () => showRegionSheet(
                  context,
                  babyId: babyId,
                  current: caps.country,
                ),
              ),
            if (isManager && store.available)
              MeRow(
                icon: ClIcons.retry,
                title: l10n.pmRestore,
                onTap: () => openPaywall(context, entry: PaywallEntry.plan),
              ),
          ],
        ),
      );
    }
    return MePage(
      title: l10n.pv2PlanTitle,
      onRefresh: () async {
        ref.invalidate(familyPlanV2Provider(babyId));
        await ref.read(capabilitiesProvider(babyId).future);
      },
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(color: cl.colors.ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.premium,
    required this.isManager,
    required this.managerName,
  });
  final bool premium;
  final bool isManager;
  final String managerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tag = isManager ? l10n.pv2InUse : l10n.pv2PlanShared;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: premium ? cl.colors.mintSoft : cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                premium ? l10n.pv2PlanPremium : l10n.pv2PlanFree,
                style: cl.text.title.copyWith(color: cl.colors.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: premium ? cl.colors.surface : cl.colors.surface2,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  tag,
                  style: cl.text.caption.copyWith(
                    color: premium ? cl.colors.mintText : cl.colors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            isManager
                ? l10n.pv2ManagerYou(managerName)
                : l10n.pv2ManagerOther(managerName),
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// "Hạn mức": Lumi, video and storage as three bars (Note · PV40).
class _Allowances extends StatelessWidget {
  const _Allowances({required this.plan});
  final FamilyPlanV2 plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final premium = plan.premium;
    String refill(PlanBalance b) => b.resetsAt != null
        ? l10n.pv2RefillOn(_dayShort(context, b.resetsAt!))
        : l10n.pv2TrialOnce;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.pv2LimitsTitle, style: cl.text.headline),
          ),
          const SizedBox(height: ClSpace.s3),
          _Bar(
            label: premium ? l10n.pv2Lumi : l10n.pv2LumiTrial,
            value: l10n.pv2CreditsLeft(plan.lumi.left, plan.lumi.limit),
            caption: refill(plan.lumi),
            ratio: plan.lumi.limit == 0 ? 1 : plan.lumi.left / plan.lumi.limit,
            color: cl.colors.mintDeep,
          ),
          const SizedBox(height: ClSpace.s4),
          _Bar(
            label: premium ? l10n.pv2Video : l10n.pv2VideoTrial,
            value: l10n.pv2ExportsLeft(plan.video.left, plan.video.limit),
            caption: refill(plan.video),
            ratio: plan.video.limit == 0
                ? 1
                : plan.video.left / plan.video.limit,
            color: cl.colors.sunshine,
          ),
          const SizedBox(height: ClSpace.s4),
          _Bar(
            label: l10n.pv2Storage,
            value: l10n.pv2StorageOf(
              premiumGb(context, plan.usedBytes),
              premiumGb(context, plan.limitBytes),
            ),
            caption: null,
            ratio: plan.storageRatio,
            color: plan.storageRatio >= 0.9 ? cl.colors.peach : cl.colors.mint,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.caption,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final String? caption;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: [label, value, ?caption].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: cl.text.bodyStrong)),
              ClTabularText(
                value,
                style: cl.text.body.copyWith(color: cl.colors.ink),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1).toDouble(),
              minHeight: 8,
              color: color,
              backgroundColor: cl.colors.surface2,
            ),
          ),
          if (caption case final c?) ...[
            const SizedBox(height: ClSpace.s1),
            Text(c, style: cl.text.caption.copyWith(color: cl.colors.inkMuted)),
          ],
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  final ClIcons icon;
  final String title;
  final String body;
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(icon, size: 22, color: cl.colors.ink),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ink on soft warm fills, also in Night care.
                Text(
                  title,
                  style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                ),
                const SizedBox(height: ClSpace.s1),
                Text(body, style: cl.text.body.copyWith(color: cl.colors.ink)),
                const SizedBox(height: ClSpace.s2),
                Wrap(
                  spacing: ClSpace.s4,
                  runSpacing: ClSpace.s1,
                  children: [
                    for (final (label, onTap) in actions)
                      ClPressable(
                        onPressed: onTap,
                        semanticLabel: label,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: ClSpace.s2,
                          ),
                          child: Text(
                            label,
                            style: cl.text.label.copyWith(
                              color: cl.colors.ink,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Upsell extends StatelessWidget {
  const _Upsell({
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.mintSoft,
        borderRadius: BorderRadius.circular(ClRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: cl.text.headline.copyWith(color: cl.colors.ink)),
          const SizedBox(height: ClSpace.s1),
          Text(body, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(height: ClSpace.s3),
          ClButton(label: action, expand: true, onPressed: onTap),
        ],
      ),
    );
  }
}

// ---------- PV41 Lịch sử sử dụng ----------

class UsageHistoryScreen extends ConsumerStatefulWidget {
  const UsageHistoryScreen({super.key});

  @override
  ConsumerState<UsageHistoryScreen> createState() => _UsageHistoryState();
}

class _UsageHistoryState extends ConsumerState<UsageHistoryScreen> {
  var _filter = UsageFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final plan = ref.watch(familyPlanV2Provider(me.babyId)).value;
    final everyone = plan?.isManager ?? me.isOwner;
    final async = ref.watch(
      usageHistoryProvider((
        babyId: me.babyId,
        filter: _filter,
        everyone: everyone,
      )),
    );
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
    final names = {for (final m in members) m.uid: m.displayName};

    final rows = async.value?.rows;
    final body = <Widget>[];
    if (async.isLoading && rows == null) {
      body.add(const ClSkeleton(height: 240));
    } else if (async.hasError && rows == null) {
      body.add(
        MeNotice(
          tone: MeTone.warn,
          icon: ClIcons.cloudOff,
          title: l10n.pv2HistoryError,
        ),
      );
    } else if (rows == null || rows.isEmpty) {
      body.add(MeNotice(title: l10n.pv2HistoryEmpty));
    } else {
      String? month;
      final group = <Widget>[];
      void flush() {
        if (group.isEmpty) return;
        body.addAll([
          MeSection(month!),
          ClCardGroup(children: [...group]),
          const SizedBox(height: ClSpace.s3),
        ]);
        group.clear();
      }

      final vi = Localizations.localeOf(context).languageCode == 'vi';
      for (final r in rows) {
        final m = vi
            ? l10n.pv2Month('${r.at.toLocal().month}')
            : l10n.pv2Month(DateFormat.MMMM('en').format(r.at.toLocal()));
        if (m != month) {
          flush();
          month = m;
        }
        group.add(
          _UsageLine(
            row: r,
            who: r.uid == null
                ? l10n.pv2System
                : (names[r.uid] ?? l10n.pv2Someone),
          ),
        );
      }
      flush();
    }
    return MePage(
      title: everyone ? l10n.pv2History : l10n.pv2HistoryMine,
      onRefresh: () async => ref.invalidate(usageHistoryProvider),
      children: [
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final (f, label) in [
              (UsageFilter.all, l10n.pv2FilterAll),
              (UsageFilter.lumi, l10n.pv2FilterLumi),
              (UsageFilter.video, l10n.pv2FilterVideo),
              (UsageFilter.grants, l10n.pv2FilterGrants),
            ])
              ClFilterChip(
                label: label,
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        ...body,
        const SizedBox(height: ClSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClIcon(ClIcons.lock, size: 16, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                l10n.pv2HistoryPrivacy,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsageLine extends StatelessWidget {
  const _UsageLine({required this.row, required this.who});
  final UsageRow row;
  final String who;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final r = row;
    final title = r.kind == 'refund'
        ? (r.isVideo ? l10n.pv2TaskRefundVideo : l10n.pv2TaskRefundLumi)
        : switch (r.task) {
            'lumi.summary' => l10n.pv2TaskLumiSummary,
            'lumi.photo' => l10n.pv2TaskLumiPhoto,
            'video.export' => l10n.pv2TaskVideoExport,
            'lumi.trial' => l10n.pv2TaskLumiTrial,
            'lumi.cycle' => l10n.pv2TaskLumiCycle,
            'video.trial' => l10n.pv2TaskVideoTrial,
            'video.cycle' => l10n.pv2TaskVideoCycle,
            'lumi.grant' => l10n.pv2TaskLumiGrant,
            'video.grant' => l10n.pv2TaskVideoGrant,
            _ => l10n.pv2TaskLumiChat,
          };
    final signed = r.amount > 0
        ? '+${r.amount}'
        : '${r.amount}'.replaceFirst('-', '−');
    final amount = r.isVideo ? l10n.pv2AmountExports(signed) : signed;
    final when = DateFormat(
      'dd/MM HH:mm',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(r.at.toLocal());
    final positive = r.amount > 0;
    return Semantics(
      label: '$title, $who, $when, $amount',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cl.colors.surface2,
              child: Text(
                initialOf(who),
                style: cl.text.label.copyWith(
                  color: cl.colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.bodyStrong),
                  Text(
                    [
                      who,
                      when,
                      if (r.state == 'held') l10n.pv2Held,
                    ].join(' · '),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            ClTabularText(
              amount,
              style: cl.text.bodyStrong.copyWith(
                color: positive ? cl.colors.mintText : cl.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- PV44 Chọn người giữ quyền ghi ----------

Future<void> showSeatPicker(
  BuildContext context, {
  required String babyId,
  required FamilyPlanV2 plan,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => SeatPickerSheet(babyId: babyId, plan: plan),
);

class SeatPickerSheet extends ConsumerStatefulWidget {
  const SeatPickerSheet({required this.babyId, required this.plan, super.key});
  final String babyId;
  final FamilyPlanV2 plan;

  @override
  ConsumerState<SeatPickerSheet> createState() => _SeatPickerState();
}

class _SeatPickerState extends ConsumerState<SeatPickerSheet> {
  Set<String>? _keep;
  var _busy = false;

  Future<void> _save(List<Membership> writers) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(premiumV2ApiProvider).chooseWriteSeats(widget.babyId, [
        for (final w in writers)
          if (!w.isOwner && _keep!.contains(w.uid)) w.uid,
      ]);
      ref.invalidate(familyPlanV2Provider(widget.babyId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showClToast(context, message: l10n.pv2PickSaved);
    } on Object {
      if (mounted) {
        showClToast(context, message: l10n.pv2PickFailed, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final writers = ref.watch(familyWritersProvider(widget.babyId));
    final limit = widget.plan.seatsLimit;
    final session = ref.watch(sessionProvider);
    final myUid = session is SessionSignedIn ? session.user.uid : null;
    if (writers != null && _keep == null) {
      // What the manager chose before; else everyone, and Lưu waits for a real choice.
      // What the manager chose before; else only the manager, so nobody is picked silently
      // (Note · PV44).
      final chosen = widget.plan.suspended.isNotEmpty;
      _keep = {
        for (final w in writers)
          if (w.isOwner || (chosen && !widget.plan.suspended.contains(w.uid)))
            w.uid,
      };
    }
    final keep = _keep ?? const <String>{};
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        ClSpace.s3,
        ClSpace.s4,
        bottom + ClSpace.s4,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClRadius.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: cl.colors.separator,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          Semantics(
            header: true,
            child: Text(l10n.pv2PickTitle, style: cl.text.title),
          ),
          const SizedBox(height: ClSpace.s1),
          Text(
            l10n.pv2PickBody(limit),
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          if (writers == null)
            const ClSkeleton(height: 200)
          else
            Flexible(
              child: SingleChildScrollView(
                child: ClCardGroup(
                  color: cl.colors.surface2,
                  children: [
                    for (final w in writers)
                      _SeatRow(
                        member: w,
                        me: w.uid == myUid,
                        checked: keep.contains(w.uid),
                        onChanged: w.isOwner
                            ? null
                            : (v) => setState(() {
                                v ? _keep!.add(w.uid) : _keep!.remove(w.uid);
                              }),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.pv2PickSave(keep.length, limit),
            expand: true,
            loading: _busy,
            onPressed: writers == null || _busy || keep.length > limit
                ? null
                : () => _save(writers),
          ),
        ],
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.member,
    required this.me,
    required this.checked,
    this.onChanged,
  });
  final Membership member;
  final bool me;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final m = member;
    final name = me ? l10n.pv2You(m.displayName) : m.displayName;
    final role = m.isOwner
        ? l10n.pv2PickManager(memberRelation(l10n, m))
        : memberDetail(l10n, m);
    return Semantics(
      checked: checked,
      enabled: onChanged != null,
      label: '$name, $role',
      excludeSemantics: true,
      child: ClPressable(
        onPressed: onChanged == null ? null : () => onChanged!(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s4,
            vertical: ClSpace.s3,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cl.colors.cardPeach,
                child: Text(
                  initialOf(m.displayName),
                  style: cl.text.label.copyWith(
                    color: cl.colors.onCard,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: cl.text.bodyStrong),
                    Text(
                      role,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked
                      ? (onChanged == null
                            ? cl.colors.inkMuted
                            : cl.colors.mintDeep)
                      : null,
                  borderRadius: BorderRadius.circular(7),
                  border: checked
                      ? null
                      : Border.all(color: cl.colors.controlBorder, width: 2),
                ),
                child: checked
                    ? ClIcon(
                        ClIcons.check,
                        size: 18,
                        color: cl.colors.onMintDeep,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- PV42 Huỷ gia hạn ----------

class CancelRenewalScreen extends ConsumerWidget {
  const CancelRenewalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final plan = ref.watch(familyPlanV2Provider(me.babyId)).value;
    final caps = ref.watch(capabilitiesProvider(me.babyId)).value;
    final storeKind = caps?.billingProvider == 'google'
        ? StoreProvider.google
        : StoreProvider.apple;
    final store = ref.watch(storeGatewayProvider);
    final storeName = storeKind == StoreProvider.google
        ? l10n.pv2StoreGoogle
        : l10n.pv2StoreApple;
    final until = plan?.validUntil ?? caps?.validUntil;
    final free = plan?.free ?? PlanOffer.free;
    final rows = <Widget>[
      _Consequence(
        icon: ClIcons.check,
        tint: cl.colors.mintSoft,
        title: l10n.pv2CancelKeep,
        body: l10n.pv2CancelKeepBody,
      ),
      if (plan != null && plan.usedBytes > free.storageBytes)
        _Consequence(
          icon: ClIcons.cloudOff,
          tint: cl.colors.sunshineSoft,
          title: l10n.pv2CancelStorage(
            premiumGb(context, plan.usedBytes),
            premiumGb(context, free.storageBytes),
          ),
          body: l10n.pv2CancelStorageBody,
        ),
      if (plan != null && plan.seatsUsed > free.caregiverSeats)
        _Consequence(
          icon: ClIcons.family,
          tint: cl.colors.sunshineSoft,
          title: l10n.pv2CancelSeats(plan.seatsUsed, free.caregiverSeats),
          body: l10n.pv2CancelSeatsBody(free.caregiverSeats),
        ),
      _Consequence(
        icon: ClIcons.star,
        tint: cl.colors.surface2,
        title: l10n.pv2CancelTemplates,
        body: l10n.pv2CancelTemplatesBody,
      ),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Column(
        children: [
          Expanded(
            child: MePage(
              title: l10n.pv2CancelTitle,
              bottomPadding: ClSpace.s6,
              children: [
                Text(
                  until == null
                      ? l10n.pv2CancelLeadNoDate
                      : l10n.pv2CancelLead(_day(context, until)),
                  style: cl.text.title2,
                ),
                const SizedBox(height: ClSpace.s4),
                MeSection(l10n.pv2CancelAfter),
                ClCardGroup(children: rows),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              ClSpace.s4,
              ClSpace.s3,
              ClSpace.s4,
              bottom + ClSpace.s3,
            ),
            decoration: BoxDecoration(
              color: cl.colors.cloud,
              border: Border(top: BorderSide(color: cl.colors.separator)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClButton(
                  label: l10n.pv2KeepPremium,
                  expand: true,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: ClSpace.s2),
                ClButton(
                  label: l10n.pv2ContinueCancel(storeName),
                  expand: true,
                  style: ClButtonStyle.plain,
                  onPressed: () => unawaited(
                    launchUrl(
                      store.manageUri(storeKind),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });
  final ClIcons icon;
  final Color tint;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClSpace.s4,
        vertical: ClSpace.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: ClIcon(icon, size: 18, color: cl.colors.ink),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- PW10 Mua thêm dung lượng ----------

class StorageAddOnScreen extends ConsumerStatefulWidget {
  const StorageAddOnScreen({super.key});

  @override
  ConsumerState<StorageAddOnScreen> createState() => _StorageAddOnState();
}

class _StorageAddOnState extends ConsumerState<StorageAddOnScreen> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const ColoredBox(color: PremiumPalette.deep);
    final plan = ref.watch(familyPlanV2Provider(me.babyId)).value;
    final caps = ref.watch(capabilitiesProvider(me.babyId)).value;
    final vnd = caps?.country == null || caps?.country == 'VN';
    final addOns = plan?.addOns ?? const <StorageAddOn>[];
    final baseGb =
        ((plan?.limitBytes ?? 0) / (1024 * 1024 * 1024)).round() -
        (plan?.addOnGb ?? 0);
    final bottom = MediaQuery.paddingOf(context).bottom;
    const muted = TextStyle(color: PremiumPalette.textMuted, fontSize: 13);
    // Dark page: white status bar, restored by the screen below when it closes.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PremiumPalette.deep,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PremiumPalette.deepTop, PremiumPalette.deep],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s2,
                    ClSpace.s4,
                    0,
                  ),
                  child: Row(
                    children: [
                      ClPressable(
                        onPressed: () => context.pop(),
                        semanticLabel: l10n.a11yClose,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: PremiumPalette.fill,
                            shape: BoxShape.circle,
                          ),
                          child: const ClIcon(
                            ClIcons.close,
                            size: 20,
                            color: PremiumPalette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      ClSpace.s6,
                      ClSpace.s3,
                      ClSpace.s6,
                      ClSpace.s6,
                    ),
                    children: [
                      const PremiumCrest(),
                      const SizedBox(height: ClSpace.s2),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.pv2AddOnHead,
                          style: const TextStyle(
                            fontFamily: PremiumPalette.serif,
                            color: PremiumPalette.text,
                            fontSize: 28,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: ClSpace.s4),
                      if (plan != null)
                        Container(
                          padding: const EdgeInsets.all(ClSpace.s4),
                          decoration: BoxDecoration(
                            color: PremiumPalette.fill,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: PremiumPalette.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.pv2AddOnUsed, style: muted),
                              const SizedBox(height: ClSpace.s1),
                              ClTabularText(
                                l10n.pv2StorageOf(
                                  premiumGb(context, plan.usedBytes),
                                  premiumGb(context, plan.limitBytes),
                                ),
                                style: const TextStyle(
                                  fontFamily: PremiumPalette.serif,
                                  color: PremiumPalette.text,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: ClSpace.s2),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: plan.storageRatio,
                                  minHeight: 8,
                                  color: PremiumPalette.gold,
                                  backgroundColor: PremiumPalette.line,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: ClSpace.s4),
                      for (final (i, a) in addOns.indexed) ...[
                        _AddOnOption(
                          title: l10n.pv2AddOnOption(a.gb),
                          total: l10n.pv2AddOnTotal(baseGb + a.gb),
                          perYear: l10n.pv2PerYear(
                            premiumPrice(
                              context,
                              vnd ? a.vn.year : a.intl.year,
                              vnd: vnd,
                            ),
                          ),
                          perMonth: l10n.pv2OrPerMonth(
                            premiumPrice(
                              context,
                              vnd ? a.vn.month : a.intl.month,
                              vnd: vnd,
                            ),
                          ),
                          selected: _selected == i,
                          onTap: () => setState(() => _selected = i),
                        ),
                        const SizedBox(height: ClSpace.s3),
                      ],
                      Text(l10n.pv2AddOnNote, style: muted),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    ClSpace.s4,
                    ClSpace.s4,
                    ClSpace.s4,
                    bottom + ClSpace.s3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: PremiumPalette.gold.withValues(alpha: 0.25),
                      ),
                    ),
                    color: const Color(0xFF0A1212),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Owner, 2026-10-25: the CTA as drawn; the store step says it is coming
                      // (Q-102) until in-app purchase opens. Free families are told it is for
                      // Premium.
                      if (plan?.premium == false)
                        Text(
                          l10n.pv2AddOnPremiumOnly,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PremiumPalette.text,
                            fontSize: 14,
                          ),
                        )
                      else if (addOns.isNotEmpty)
                        PremiumGoldButton(
                          label: l10n.pv2AddOnBuy(
                            addOns[_selected.clamp(0, addOns.length - 1)].gb,
                            l10n.pv2PerYear(
                              premiumPrice(
                                context,
                                vnd
                                    ? addOns[_selected.clamp(
                                            0,
                                            addOns.length - 1,
                                          )]
                                          .vn
                                          .year
                                    : addOns[_selected.clamp(
                                            0,
                                            addOns.length - 1,
                                          )]
                                          .intl
                                          .year,
                                vnd: vnd,
                              ),
                            ),
                          ),
                          onPressed: () => showPaymentSoon(context),
                        ),
                      const SizedBox(height: ClSpace.s2),
                      PremiumTextButton(
                        label: l10n.pv2ManageMedia,
                        onPressed: () => context.push(Routes.meStorage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOnOption extends StatelessWidget {
  const _AddOnOption({
    required this.title,
    required this.total,
    required this.perYear,
    required this.perMonth,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String total;
  final String perYear;
  final String perMonth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: '$title, $total, $perYear, $perMonth',
    excludeSemantics: true,
    child: ClPressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: selected
              ? PremiumPalette.gold.withValues(alpha: 0.10)
              : PremiumPalette.fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? PremiumPalette.gold : PremiumPalette.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: PremiumPalette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    total,
                    style: const TextStyle(
                      color: PremiumPalette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  perYear,
                  style: const TextStyle(
                    color: PremiumPalette.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  perMonth,
                  style: const TextStyle(
                    color: PremiumPalette.textFaint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// The v2 plan screens above the tabs (no dock), next to PR01.
List<RouteBase> planV2Routes() => [
  GoRoute(
    path: PlanV2Routes.history,
    builder: (_, _) => const UsageHistoryScreen(),
  ),
  GoRoute(
    path: PlanV2Routes.cancel,
    builder: (_, _) => const CancelRenewalScreen(),
  ),
  GoRoute(
    path: PlanV2Routes.addOn,
    pageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      fullscreenDialog: true,
      child: const StorageAddOnScreen(),
    ),
  ),
];
