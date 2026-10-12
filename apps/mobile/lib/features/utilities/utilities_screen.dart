import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../first_aid/first_aid_repository.dart';
import '../home/home_shell.dart';
import '../spending/spending_calc.dart';
import '../spending/spending_format.dart';
import '../spending/spending_models.dart';
import '../spending/spending_repository.dart';

/// Tiện ích tab (v1.0 improvement 450:6597; caregiver 450:6873), which replaced the Gia đình tab:
/// "Cho bé" (Sơ cứu trẻ em, Chi tiêu, Thư viện chăm bé — coming soon) and "Gia đình" (Thành viên &
/// chia sẻ; Mời người thân for Cùng nuôi). Rows show only what this member may open: Sơ cứu once a
/// guide is on the device, Chi tiêu with a spending right (D-055).
class UtilitiesScreen extends ConsumerWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final parent = me.role == MemberRole.coParent;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final pack = ref.watch(firstAidPackProvider).value;

    final spending = SpendingAccess.of(me);
    _Row? spendingRow;
    if (spending.viewAll) {
      final expenses =
          ref.watch(expensesProvider((me.babyId, spending))).value ??
          const <Expense>[];
      final zone =
          ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
          'Asia/Ho_Chi_Minh';
      final now = ref.watch(careClockProvider).value ?? DateTime.now();
      final today = babyToday(zone, now);
      final total = MonthSummary.of(expenses, monthOf(today), today).total;
      spendingRow = _Row(
        key: const Key('utSpending'),
        icon: ClIcons.grid,
        title: l10n.spTitle,
        subtitle: total == 0
            ? l10n.spTileEmpty
            : l10n.utSpendingMonth(money(locale, total)),
        onTap: () => context.push(Routes.spending),
      );
    } else if (spending.record) {
      // 450:6873: someone allowed to record what they paid.
      spendingRow = _Row(
        key: const Key('utSpending'),
        icon: ClIcons.grid,
        title: l10n.utMySpending,
        subtitle: l10n.utMySpendingSub,
        onTap: () => context.push(Routes.spending),
      );
    }

    final String membersLine;
    if (parent) {
      final members =
          (ref.watch(familyMembersProvider(me.babyId)).value ??
                  const <Membership>[])
              .where((m) => m.isActive)
              .length;
      final pending =
          (ref.watch(pendingInvitesProvider(me.babyId)).value ?? const [])
              .length;
      membersLine = [
        l10n.utMembersCount(members),
        if (pending > 0) l10n.utMembersPending(pending),
      ].join(' · ');
    } else {
      membersLine = l10n.utMembersView;
    }

    return ClPinnedHeaderScaffold(
      header: const BabyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s4,
          ClTabDock.contentBottomPadding + ClSpace.s6,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.utTitle, style: cl.text.largeTitle),
          ),
          _Section(l10n.utForBaby),
          _Group(
            children: [
              if (pack != null)
                _Row(
                  key: const Key('utFirstAid'),
                  icon: ClIcons.alert,
                  title: l10n.faEntryTitle,
                  subtitle: l10n.faEntrySub(pack.situations.length),
                  onTap: () => context.push(Routes.firstAid),
                ),
              ?spendingRow,
              _Row(
                icon: ClIcons.bookmark,
                title: l10n.careLibrary,
                subtitle: l10n.careLibrarySub,
                soon: true,
                onTap: () => showClToast(context, message: l10n.careSoonToast),
              ),
            ],
          ),
          _Section(l10n.tabFamily),
          _Group(
            children: [
              _Row(
                key: const Key('utMembers'),
                icon: ClIcons.family,
                title: l10n.utMembers,
                subtitle: membersLine,
                onTap: () => context.push(Routes.family),
              ),
              if (parent)
                _Row(
                  key: const Key('utInvite'),
                  icon: ClIcons.plus,
                  title: l10n.utInvite,
                  subtitle: l10n.utInviteSub,
                  onTap: () => context.push(Routes.invite),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s6, bottom: ClSpace.s3),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: context.cl.text.headline.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// The design's white group card: radius 16, no shadow, no dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cl.colors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soon = false,
    super.key,
  });

  final ClIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      onPressed: onTap,
      semanticLabel: soon ? '$title. ${l10n.careSoon}' : '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClIcon(icon, size: 18, color: cl.colors.ink),
            ),
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
                    subtitle,
                    style: cl.text.caption.copyWith(
                      color: cl.colors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (soon)
              const CareSoonBadge()
            else
              ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// The sunshine "Sớm ra mắt" badge (450:6424, 450:6597).
class CareSoonBadge extends StatelessWidget {
  const CareSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cl.colors.sunshine,
        borderRadius: BorderRadius.circular(ClRadius.pill),
      ),
      child: Text(
        AppLocalizations.of(context).careSoon,
        style: cl.text.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cl.colors.ink,
        ),
      ),
    );
  }
}
