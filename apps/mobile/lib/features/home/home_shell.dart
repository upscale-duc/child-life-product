import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/family_labels.dart';
import '../care/care_sheets.dart';
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

/// Branch order of the shell route (Me is a sheet until S10).
const shellTabs = [ClTab.today, ClTab.memories, ClTab.family];

/// Tab shell (NavBar 44:362) with role-aware tabs (R-021, 124:13717 / 124:13778): parents see
/// Hôm nay · Kỷ niệm · Gia đình · Tôi, caregivers no Kỷ niệm, relatives no Hôm nay unless they
/// were granted daily care (D-018). Switching baby can change the tabs.
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
    if (!tabs.contains(active)) {
      // e.g. a relative opening Hôm nay lands on Kỷ niệm (7b "vào Kỷ niệm").
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) shell.goBranch(shellTabs.indexOf(tabs.first));
      });
    }
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Stack(
        children: [
          Positioned.fill(child: shell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ClTabDock(
                role: clRoleOf(membership.role),
                tabs: tabs,
                active: active,
                initial: initialOf(membership.displayName),
                onSelect: (tab) => tab == ClTab.me
                    ? showMeMenu(context, ref)
                    : shell.goBranch(
                        shellTabs.indexOf(tab),
                        initialLocation:
                            shellTabs.indexOf(tab) == shell.currentIndex,
                      ),
                onQuickLog: membership.role == MemberRole.relative
                    ? null
                    : () => showQuickLog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header shared by the tabs: baby switcher (45:321) + Night care toggle, and the 16c banner
/// "Chưa lưu tài khoản · Lưu" while the identity is temporary (R-030).
class BabyHeader extends ConsumerWidget {
  const BabyHeader({super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: baby == null
                    ? const SizedBox.shrink()
                    : ClBabySwitcher(
                        label: _switcherLabel(context, ref, membership, baby),
                        avatar: SavedBabyAvatar(baby: baby, size: 32),
                        hasMultiple: multiple,
                        onTap: multiple ? () => showBabyPicker(context) : null,
                      ),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            const NightCareToggle(),
          ],
        ),
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
    ageShort(l10n, profile.dateOfBirth, DateTime.now()),
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
      pressedScale: 0.99,
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
        child: ClIcon(ClIcons.sleep, size: 20, color: cl.colors.ink),
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
            ageShort(l10n, profile.dateOfBirth, DateTime.now()),
            youAre,
          );
    final name = baby?.nickname ?? '…';
    return Semantics(
      selected: selected,
      child: ClPressable(
        onPressed: onTap,
        pressedScale: 0.99,
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

/// Temporary "Tôi" menu until the Me tab (S10): appearance, add baby, save account, sign out.
Future<void> showMeMenu(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  final session = ref.read(sessionProvider);
  final anonymous = session is SessionSignedIn && session.isAnonymous;
  final membership = ref.read(selectedMembershipProvider);
  final nickname = membership == null
      ? ''
      : ref.read(babyProvider(membership.babyId)).value?.nickname ?? '';
  final owned = session is SessionSignedIn
      ? session.active.where((m) => m.isOwner).length
      : 0;
  return showClSheet<void>(
    context: context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClSheetHeader(title: l10n.tabMe),
        ClCardGroup(
          children: [
            if (anonymous)
              ClDetailRow(
                icon: ClIcons.cloudOff,
                label: l10n.saveAccountTitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showSaveAccountSheet(context, nickname);
                },
              ),
            if (!anonymous)
              ClDetailRow(
                icon: ClIcons.plus,
                label: l10n.babyPickerAdd,
                value: l10n.babyPickerCount(owned, maxOwnedBabies),
                onTap: owned < maxOwnedBabies
                    ? () {
                        Navigator.of(sheetContext).pop();
                        startAddingBaby(context, ref);
                      }
                    : null,
              ),
            ClDetailRow(
              icon: ClIcons.sleep,
              label: l10n.meAppearance,
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(Routes.appearance);
              },
            ),
            ClDetailRow(
              icon: ClIcons.back,
              label: l10n.meSignOut,
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (anonymous) {
                  _confirmAnonymousSignOut(context, ref);
                } else {
                  ref.read(authRepositoryProvider).signOut();
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}

/// A temporary identity cannot sign back in: say so before signing out (R-031).
Future<void> _confirmAnonymousSignOut(BuildContext context, WidgetRef ref) {
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

/// Kỷ niệm tab until Memories ship (S5–S7).
class MemoriesPlaceholderScreen extends StatelessWidget {
  const MemoriesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: context.cl.colors.cloud,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            ClTabDock.contentBottomPadding,
          ),
          children: [
            const BabyHeader(),
            const SizedBox(height: ClSpace.s4),
            ClNavHeader(title: l10n.tabMemories),
            ClEmptyState(
              icon: ClIcons.memories,
              title: l10n.tabMemories,
              message: l10n.memoriesComingSoon,
            ),
          ],
        ),
      ),
    );
  }
}
