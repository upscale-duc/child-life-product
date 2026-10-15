import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_entry.dart' show AssistantFloatingEntry;
import '../auto_save/auto_save_today.dart';
import '../auto_save/auto_save_widgets.dart';
import '../auth/auth_repository.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/family_labels.dart';
import '../family/my_invites.dart'
    show ClRedDot, MyInviteRows, myInvitesProvider, showMyInviteSheet;
import '../memories/memories_screen.dart' show GlobalUploadPill, memoryCtx;
import '../memories/memory_sheets.dart' show showAddSheet;
import '../care/care_repository.dart';
import '../care/care_sheets.dart';
import '../care/timer_models.dart';
import 'today_tour.dart';
import '../family/save_account.dart';
import '../onboarding/setup_draft.dart';

const _kSelectedBaby = 'today.selectedBabyId';

/// Selected baby for the shell (per device). Falls back to the first active membership.
final selectedBabyIdProvider = NotifierProvider<SelectedBabyId, String?>(
  SelectedBabyId.new,
);

class SelectedBabyId extends Notifier<String?> {
  @override
  String? build() {
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn || !session.hasBaby) return null;
    final saved = ref.read(sharedPreferencesProvider).getString(_kSelectedBaby);
    final ids = [for (final m in session.active) m.babyId];
    return ids.contains(saved) ? saved : ids.first;
  }

  void select(String babyId) {
    ref.read(sharedPreferencesProvider).setString(_kSelectedBaby, babyId);
    state = babyId;
  }
}

/// The caller's membership on the selected baby: role, relation and rights drive the shell.
final selectedMembershipProvider = Provider<Membership?>((ref) {
  final session = ref.watch(sessionProvider);
  final babyId = ref.watch(selectedBabyIdProvider);
  if (session is! SessionSignedIn || babyId == null) return null;
  return session.membershipFor(babyId);
});

ClRole clRoleOf(MemberRole role) => switch (role) {
  MemberRole.coParent => ClRole.parent,
  MemberRole.caregiver => ClRole.caregiver,
  MemberRole.relative => ClRole.relative,
};

List<ClTab> tabsFor(Membership m) => tabsForRole(
  clRoleOf(m.role),
  relativeSeesToday: m.role == MemberRole.relative && m.canViewToday,
);

/// Overlap conflicts already opened on this device (27 shows once by itself).
final _shownConflicts = <String>{};

/// Branch order of the shell route.
const shellTabs = [ClTab.today, ClTab.memories, ClTab.care, ClTab.utilities];

/// The tabs' own screens: the only places that show the dock.
const _tabRoots = {
  Routes.today,
  Routes.memories,
  Routes.care,
  Routes.utilities,
};

/// Tab shell (NavBar v1.0.1, v1.0 improvement 370:1246) with role-aware tabs (R-021): parents see
/// Hôm nay · Kỷ niệm · Chăm sóc · Gia đình, caregivers no Kỷ niệm, relatives no Hôm nay unless
/// they were granted daily care (D-018). Tôi opens from the header avatar. Switching baby can
/// change the tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final membership = ref.watch(selectedMembershipProvider);
    if (membership == null) return Scaffold(backgroundColor: cl.colors.cloud);
    final tabs = tabsFor(membership);
    final active = shellTabs[shell.currentIndex];
    final babyId = membership.babyId;

    // R-071 / 13: Night care turns on while your sleep timer runs, outside the schedule too.
    final sleepTimer = ref
        .watch(careTimerProvider((babyId, TimerType.sleep)))
        .value;
    final mySleepRunning =
        sleepTimer != null && sleepTimer.startedBy == membership.uid;
    if (ref.read(nightCareTimerRunningProvider) != mySleepRunning) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref
            .read(nightCareTimerRunningProvider.notifier)
            .set(mySleepRunning),
      );
    }

    // 27 opens by itself for the member whose sync revealed the overlap (R-075).
    ref.listen(openConflictsProvider(babyId), (_, next) {
      final conflict = next.value
          ?.where(
            (c) => c.laterAuthor == membership.uid && _shownConflicts.add(c.id),
          )
          .firstOrNull;
      if (conflict != null) context.push('${Routes.overlap}/${conflict.id}');
    });

    // 18 / 18b / 18c: first visit to an empty Today, for those who log.
    final recent = ref.watch(recentRecordsProvider(babyId));
    final growth = ref.watch(growthRecordsProvider(babyId));
    final nothingLogged =
        recent.hasValue &&
        growth.hasValue &&
        recent.value!.isEmpty &&
        growth.value!.isEmpty;
    final tourDone = ref.watch(todayTourDoneProvider);
    if (!tourDone && recent.hasValue && recent.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(todayTourDoneProvider.notifier).finish(),
      );
    }
    final showTour =
        !tourDone &&
        nothingLogged &&
        active == ClTab.today &&
        membership.role != MemberRole.relative;
    final nickname = ref.watch(babyProvider(babyId)).value?.nickname ?? '';
    if (!tabs.contains(active)) {
      // e.g. a relative opening Hôm nay lands on Kỷ niệm (7b "vào Kỷ niệm").
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) shell.goBranch(shellTabs.indexOf(tabs.first));
      });
    }
    final path = shell.shellRouteContext.routerState.uri.path;
    final l10n = AppLocalizations.of(context);
    // Only Hôm nay (for those who log) and Kỷ niệm (for parents, who upload) have a "+".
    final action = switch (active) {
      ClTab.today when membership.role != MemberRole.relative => ClDockAction(
        label: l10n.a11yQuickLog,
        key: TourTargets.quickLog,
        onPressed: () => showQuickLog(context),
      ),
      ClTab.memories when membership.role == MemberRole.coParent =>
        ClDockAction(
          label: l10n.a11yAddMemory,
          onPressed: () {
            final c = memoryCtx(context, ref);
            if (c != null) unawaited(showAddSheet(context, ref, c));
          },
        ),
      _ => null,
    };
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Stack(
        children: [
          Positioned.fill(
            child: _HideDockOnScroll(
              resetKey: path,
              // A screen opened from a tab (Lịch sử, Nhắc nhở, an album…) has no dock, like
              // iOS hidesBottomBarWhenPushed (owner, 2026-10-11); it slides back on return.
              hideDock: !_tabRoots.contains(path),
              dockExtra: action == null ? 0 : ClTabDock.actionExtent,
              content: shell,
              // Keeps Tự lưu loaded so it checks when the app opens (AR01).
              banner: const AutoSaveKeeper(child: GlobalUploadPill()),
              dock: ClTabDock(
                role: clRoleOf(membership.role),
                tabs: tabs,
                active: active,
                onSelect: (tab) => shell.goBranch(
                  shellTabs.indexOf(tab),
                  initialLocation: shellTabs.indexOf(tab) == shell.currentIndex,
                ),
                action: action,
                // AR02: Tự lưu suggestions wait for the selected baby.
                dots: {if (ref.watch(autoSaveTabDotProvider)) ClTab.memories},
                dotLabel: l10n.autoSaveTabDot,
              ),
            ),
          ),
          // Chat/Nút trợ lý (628:9074) 12 pt above the "+", on Hôm nay itself; nothing unless
          // the `assistant` flag is on.
          if (active == ClTab.today && path == Routes.today && !showTour)
            Positioned(
              right: ClSpace.s4,
              bottom:
                  (MediaQuery.paddingOf(context).bottom > 0
                      ? MediaQuery.paddingOf(context).bottom
                      : ClSpace.s6) +
                  68 +
                  (action == null ? 0 : ClTabDock.actionExtent) +
                  ClSpace.s3,
              child: const AssistantFloatingEntry(),
            ),
          if (showTour)
            Positioned.fill(child: TodayTour(babyNickname: nickname)),
        ],
      ),
    );
  }
}

/// Header shared by the tabs: baby switcher (45:321) + Night care toggle, and the 16c banner
/// "Chưa lưu tài khoản · Lưu" while the identity is temporary (R-030).
class BabyHeader extends ConsumerWidget {
  const BabyHeader({this.actions, super.key});

  /// Replaces the Night care toggle (Kỷ niệm: "Cách xem" + "+", 10a).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final membership = ref.watch(selectedMembershipProvider);
    if (session is! SessionSignedIn || membership == null) {
      return const SizedBox(height: ClSpace.tapMin);
    }
    final baby = ref.watch(babyProvider(membership.babyId)).value;
    final multiple = session.active.length > 1;
    final invited = (ref.watch(myInvitesProvider).value ?? const []).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // v1.0 improvement 370:1248: who you are, at the far left; opens Tôi.
            UserAvatar(membership: membership),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: baby == null
                    ? const SizedBox.shrink()
                    : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClBabySwitcher(
                            label: _switcherLabel(
                              context,
                              ref,
                              membership,
                              baby,
                            ),
                            avatar: SavedBabyAvatar(baby: baby, size: 32),
                            hasMultiple: multiple || invited,
                            // One baby: their profile; several, or an invite waiting: the
                            // list, where invites are answered.
                            onTap: multiple || invited
                                ? () => showBabyPicker(context)
                                : () =>
                                      context.push('${Routes.baby}/${baby.id}'),
                          ),
                          // An invite to another baby waits (owner, 2026-10-11).
                          if (invited)
                            const Positioned(
                              key: Key('babySwitcherDot'),
                              top: 0,
                              right: 0,
                              child: ClRedDot(),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            ...?actions,
            if (actions == null) const NightCareToggle(),
          ],
        ),
        // Writes are locked while the owner's delete runs (13l, Q-037).
        if (baby?.deleting == true) ...[
          const SizedBox(height: ClSpace.s3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: context.cl.colors.errorSoft,
              borderRadius: BorderRadius.circular(ClRadius.control + 4),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.lock, size: 18, color: context.cl.colors.error),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Text(
                    l10n.bpLocked,
                    style: context.cl.text.label.copyWith(
                      color: context.cl.colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (session.isAnonymous) ...[
          const SizedBox(height: ClSpace.s3),
          _UnsavedBanner(
            onSave: () => showSaveAccountSheet(context, baby?.nickname ?? ''),
            label: l10n.unsavedBannerTitle,
            action: l10n.unsavedBannerAction,
          ),
        ],
      ],
    );
  }
}

/// The signed-in member's initial in their role colour (Mẹ / Ba peach, người chăm diaper-soft,
/// người thân sunshine-soft); tapping opens Tôi (370:1898), a pushed screen without the dock.
class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.membership, super.key});
  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final bg = switch (membership.role) {
      MemberRole.coParent => cl.colors.peachSoft,
      MemberRole.caregiver => cl.care.diaper.soft,
      MemberRole.relative => cl.colors.sunshineSoft,
    };
    return ClPressable(
      onPressed: () => context.push(Routes.me),
      semanticLabel: AppLocalizations.of(context).a11yOpenMe,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          initialOf(membership.displayName),
          style: cl.text.bodyStrong.copyWith(
            fontSize: 16,
            height: 1,
            color: cl.colors.ink,
          ),
        ),
      ),
    );
  }
}

String _switcherLabel(
  BuildContext context,
  WidgetRef ref,
  Membership membership,
  Baby baby,
) {
  final l10n = AppLocalizations.of(context);
  if (!membership.canViewBabyInfo) return baby.nickname;
  final profile = ref.watch(babyPrivateProfileProvider(baby.id)).value;
  if (profile == null) return baby.nickname;
  return l10n.babySwitcherLabel(
    baby.nickname,
    ageShort(l10n, profile.dateOfBirth, ref.read(timerClockProvider)()),
  );
}

/// 16c save banner: sunshine-soft with the cloud-off icon.
class _UnsavedBanner extends StatelessWidget {
  const _UnsavedBanner({
    required this.label,
    required this.action,
    required this.onSave,
  });

  final String label;
  final String action;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onSave,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$label. $action',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.sunshineSoft,
          borderRadius: BorderRadius.circular(ClRadius.control),
        ),
        child: Row(
          children: [
            ClIcon(ClIcons.cloudOff, size: 18, color: cl.colors.ink),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                label,
                style: cl.text.label.copyWith(color: cl.colors.ink),
              ),
            ),
            Text(
              action,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round moon button: switches Light ↔ Night care immediately (a11y "Night care").
class NightCareToggle extends ConsumerWidget {
  const NightCareToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    // The target palette, so the icon starts turning as soon as the colours start fading.
    final night = ref.watch(paletteProvider) == ClPalette.nightCare;
    return ClPressable(
      semanticLabel: AppLocalizations.of(context).a11yNightCareToggle,
      onPressed: () {
        final settings = ref.read(appearanceSettingsProvider);
        final night = ref.read(paletteProvider) == ClPalette.nightCare;
        ref
            .read(appearanceSettingsProvider.notifier)
            .update(
              settings.copyWith(
                theme: night ? ThemePreference.light : ThemePreference.dark,
              ),
            );
      },
      child: Container(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        // Moon in Light, sun in Night care: the icon turns and cross-fades with the palette
        // (MaterialApp's theme animation, motion.gentle).
        child: AnimatedSwitcher(
          duration: context.motion(ClMotion.gentle),
          switchInCurve: ClCurves.gentle,
          switchOutCurve: ClCurves.gentle,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: RotationTransition(
              turns: Tween(begin: -0.25, end: 0.0).animate(animation),
              child: ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(animation),
                child: child,
              ),
            ),
          ),
          child: ClIcon(
            night ? ClIcons.today : ClIcons.sleep,
            key: ValueKey(night),
            size: 20,
            color: cl.colors.ink,
          ),
        ),
      ),
    );
  }
}

/// 9x "Chọn bé" (125:13223, R-039): every baby you can see with "age · Bạn là role",
/// "Thêm hồ sơ bé · N/3" and the 3-profile footnote (R-043).
Future<void> showBabyPicker(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (_) => const _BabyPickerSheet(),
);

class _BabyPickerSheet extends ConsumerWidget {
  const _BabyPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return const SizedBox.shrink();
    final selected = ref.watch(selectedBabyIdProvider);
    final owned = session.active.where((m) => m.isOwner).length;
    final canAdd = owned < maxOwnedBabies && !session.isAnonymous;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.babyPickerTitle),
        // Invites mailed to me, behind the switcher's red dot (owner, 2026-10-11).
        MyInviteRows(
          padding: const EdgeInsets.only(bottom: ClSpace.s4),
          onOpen: (invite) {
            final host = Navigator.of(context, rootNavigator: true).context;
            Navigator.of(context).pop();
            unawaited(showMyInviteSheet(host, invite));
          },
        ),
        for (final m in session.active) ...[
          _BabyRow(
            membership: m,
            selected: m.babyId == selected,
            onTap: () {
              Navigator.of(context).pop();
              if (m.babyId == selected) return;
              ref.read(selectedBabyIdProvider.notifier).select(m.babyId);
              final name = ref.read(babyProvider(m.babyId)).value?.nickname;
              if (name != null) {
                showClToast(context, message: l10n.babySwitched(name));
              }
            },
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        if (!session.isAnonymous) ...[
          ClPressable(
            onPressed: canAdd
                ? () {
                    Navigator.of(context).pop();
                    startAddingBaby(context, ref);
                  }
                : null,
            semanticLabel:
                '${l10n.babyPickerAdd}, ${l10n.babyPickerCount(owned, maxOwnedBabies)}',
            child: Opacity(
              opacity: canAdd ? 1 : 0.5,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                  border: Border.all(color: cl.colors.mintDeep),
                ),
                child: Row(
                  children: [
                    ClIcon(ClIcons.plus, size: 18, color: cl.colors.mintText),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: Text(
                        l10n.babyPickerAdd,
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.mintText,
                        ),
                      ),
                    ),
                    Text(
                      l10n.babyPickerCount(owned, maxOwnedBabies),
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.babyPickerLimit(maxOwnedBabies),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        // Already have a profile and invited to another baby (owner, 2026-10-11).
        ClPressable(
          key: const Key('pickerJoin'),
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            unawaited(router.push(Routes.join));
          },
          semanticLabel: l10n.joinFromProfile,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.control),
              border: Border.all(color: cl.colors.separator),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.link, size: 18, color: cl.colors.mintText),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Text(
                    l10n.joinFromProfile,
                    style: cl.text.bodyStrong.copyWith(
                      color: cl.colors.mintText,
                    ),
                  ),
                ),
                ClIcon(
                  ClIcons.chevronRight,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BabyRow extends ConsumerWidget {
  const _BabyRow({
    required this.membership,
    required this.selected,
    required this.onTap,
  });

  final Membership membership;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final baby = ref.watch(babyProvider(membership.babyId)).value;
    final profile = membership.canViewBabyInfo
        ? ref.watch(babyPrivateProfileProvider(membership.babyId)).value
        : null;
    // Parents read as their relation ("Bạn là Mẹ"), everyone else as their role (125:13223).
    final youAre = l10n.babyPickerYouAre(
      membership.role == MemberRole.coParent
          ? memberRelation(l10n, membership)
          : roleLabel(l10n, membership.role),
    );
    final detail = profile == null
        ? youAre
        : l10n.babyPickerRowDetail(
            ageShort(l10n, profile.dateOfBirth, ref.read(timerClockProvider)()),
            youAre,
          );
    final name = baby?.nickname ?? '…';
    return Semantics(
      selected: selected,
      child: ClPressable(
        onPressed: onTap,
        pressedOpacity: ClPressable.surfaceOpacity,
        semanticLabel: '$name, $detail',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ClSpace.s3,
            vertical: ClSpace.s3,
          ),
          decoration: BoxDecoration(
            color: selected ? cl.colors.mintSoft : cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: baby == null
                      ? ColoredBox(color: cl.colors.surface)
                      : SavedBabyAvatar(baby: baby, size: 40),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: cl.text.bodyStrong),
                    Text(
                      detail,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                ClIcon(ClIcons.check, size: 20, color: cl.colors.mintText),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Thêm hồ sơ bé": setup 10a → 11 → 12 again, with the name used on the current baby.
void startAddingBaby(BuildContext context, WidgetRef ref) {
  final me = ref.read(selectedMembershipProvider);
  ref
      .read(setupDraftProvider.notifier)
      .update(SetupDraft().copyWith(displayName: me?.displayName ?? ''));
  ref.read(addingBabyProvider.notifier).set(true);
  context.push(Routes.who);
}

/// A temporary identity cannot sign back in: say so before signing out (R-031).
Future<void> confirmAnonymousSignOut(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  return showClSheet<void>(
    context: context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.signOutAnonTitle),
        Text(
          l10n.signOutAnonBody,
          style: sheetContext.cl.text.body.copyWith(
            color: sheetContext.cl.colors.inkMuted,
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.saveAccountTitle,
          expand: true,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            final m = ref.read(selectedMembershipProvider);
            final name = m == null
                ? ''
                : ref.read(babyProvider(m.babyId)).value?.nickname ?? '';
            showSaveAccountSheet(context, name);
          },
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.signOutAnonConfirm,
          style: ClButtonStyle.destructive,
          expand: true,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            ref.read(authRepositoryProvider).signOut();
          },
        ),
      ],
    ),
  );
}

/// Hides the tab dock while the content scrolls down and brings it back as soon as the user
/// scrolls back up 8 px, at the top, or on a tab change (Motion spec P4 270:296; the owner asked
/// for it to leave the screen rather than fade to 30 %, D-048): it slides, it does not fade.
/// Reduce Motion fades only.
class _HideDockOnScroll extends StatefulWidget {
  const _HideDockOnScroll({
    required this.content,
    required this.dock,
    required this.resetKey,
    this.banner,
    this.hideDock = false,
    this.dockExtra = 0,
  });

  final Widget content;
  final Widget dock;

  /// Kept hidden whatever the scroll (a screen opened from a tab).
  final bool hideDock;

  /// The tab's "+" above the bar: the banner sits above it too.
  final double dockExtra;

  /// Floats above the dock (the upload pill) and drops to the bottom edge while the dock is
  /// hidden, so it is always visible.
  final Widget? banner;

  /// Changing it (another tab or screen) shows the dock again.
  final Object resetKey;

  @override
  State<_HideDockOnScroll> createState() => _HideDockOnScrollState();
}

class _HideDockOnScrollState extends State<_HideDockOnScroll> {
  static const _reveal = 8.0;
  static const _hideAfter = 24.0;

  bool _hidden = false;
  double _run = 0; // scrolled in the current direction

  @override
  void didUpdateWidget(_HideDockOnScroll old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey) _show(true);
  }

  void _show(bool show) {
    if (_hidden == !show) return;
    setState(() => _hidden = !show);
  }

  bool _onScroll(ScrollNotification n) {
    // The page's own vertical scroll (finger or momentum); not nested or sideways lists.
    if (n is! ScrollUpdateNotification ||
        n.depth != 0 ||
        n.metrics.axis != Axis.vertical) {
      return false;
    }
    final delta = n.scrollDelta ?? 0;
    final m = n.metrics;
    if (m.pixels <= m.minScrollExtent) {
      _run = 0;
      _show(true);
      return false;
    }
    // Ignore the bounce past the end.
    if (m.pixels >= m.maxScrollExtent) return false;
    if ((delta > 0) != (_run > 0)) _run = 0;
    _run += delta;
    if (_run > _hideAfter) _show(false);
    if (_run < -_reveal) _show(true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    final duration = context.motion(ClMotion.quick);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // ClTabDock: 68 tall, 24 above the safe area.
    const dockHeight = 68.0 + ClSpace.s6;
    final banner = widget.banner;
    final hidden = _hidden || widget.hideDock;
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.content,
          ),
        ),
        if (banner != null)
          AnimatedPositioned(
            duration: duration,
            curve: ClCurves.quick,
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom:
                safeBottom +
                ClSpace.s3 +
                (hidden ? 0 : dockHeight + widget.dockExtra),
            child: banner,
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: hidden,
            child: AnimatedSlide(
              offset: hidden && !reduce ? const Offset(0, 1.2) : Offset.zero,
              duration: duration,
              curve: hidden ? ClCurves.exit : ClCurves.quick,
              // Slides only: a half-faded dock over the content reads as disabled buttons.
              // Reduce Motion has no slide, so it fades instead.
              child: AnimatedOpacity(
                opacity: hidden && reduce ? 0 : 1,
                duration: duration,
                curve: ClCurves.quick,
                child: SafeArea(top: false, child: widget.dock),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
