import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../onboarding/setup_screens.dart';

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

ClRole _roleOf(MemberRole role) => switch (role) {
  MemberRole.coParent => ClRole.parent,
  MemberRole.caregiver => ClRole.caregiver,
  MemberRole.relative => ClRole.relative,
};

/// 18 Hôm nay (lần đầu) shell (29:904): header, baby switcher, empty tiles per trackers and the
/// tab dock. Logging, coachmarks (18a–18c) and the other tabs arrive in S3–S10; nothing here is
/// marked done in the coverage checklist.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final babyId = ref.watch(selectedBabyIdProvider);
    if (session is! SessionSignedIn || babyId == null) {
      return Scaffold(backgroundColor: cl.colors.cloud);
    }
    final membership = session.active.firstWhere((m) => m.babyId == babyId);
    final baby = ref.watch(babyProvider(babyId)).value;
    final profile = membership.role == MemberRole.caregiver
        ? null
        : ref.watch(babyPrivateProfileProvider(babyId)).value;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final trackers = baby?.trackers ?? const <TrackerKind>[];

    void soon() => showClToast(context, message: l10n.todayLoggingSoon);

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                140,
              ),
              children: [
                Row(
                  children: [
                    if (baby != null)
                      Flexible(
                        child: ClBabySwitcher(
                          label: profile == null
                              ? baby.nickname
                              : l10n.babySwitcherLabel(
                                  baby.nickname,
                                  ageShort(l10n, profile.dateOfBirth, now),
                                ),
                          avatar: SavedBabyAvatar(baby: baby, size: 32),
                          hasMultiple: session.active.length > 1,
                          onTap: session.active.length > 1
                              ? () => _pickBaby(context, ref, session)
                              : null,
                        ),
                      ),
                    const Spacer(),
                    _NightToggle(),
                  ],
                ),
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
                      _EmptyCareTile(kind: kind, onTap: soon),
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
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.ink,
                        ),
                      ),
                      const SizedBox(height: ClSpace.s1),
                      Text(
                        l10n.todaySummaryEmptyBody,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ClTabDock(
                role: _roleOf(membership.role),
                active: ClTab.today,
                initial:
                    membership.displayName.characters.firstOrNull
                        ?.toUpperCase() ??
                    '',
                onSelect: (tab) => tab == ClTab.me
                    ? _showMeMenu(context, ref)
                    : (tab == ClTab.today ? null : soon()),
                onQuickLog: membership.role == MemberRole.relative
                    ? null
                    : soon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBaby(
    BuildContext context,
    WidgetRef ref,
    SessionSignedIn session,
  ) => showClSheet<void>(
    context: context,
    builder: (sheetContext) => _BabyList(session: session),
  );

  /// Temporary "Tôi" menu until the Me tab (S10): appearance and sign out.
  Future<void> _showMeMenu(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showClSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          ClSpace.s4,
          0,
          ClSpace.s4,
          MediaQuery.of(sheetContext).padding.bottom + ClSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClSheetHeader(
              title: l10n.tabMe,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
            ClCardGroup(
              children: [
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
                    ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BabyList extends ConsumerWidget {
  const _BabyList({required this.session});
  final SessionSignedIn session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBabyIdProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        MediaQuery.of(context).padding.bottom + ClSpace.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClSheetHeader(
            title: AppLocalizations.of(context).todayTitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          ClCardGroup(
            children: [
              for (final m in session.active)
                Consumer(
                  builder: (context, ref, _) {
                    final baby = ref.watch(babyProvider(m.babyId)).value;
                    return ClOptionRow(
                      title: baby?.nickname ?? '…',
                      selected: selected == m.babyId,
                      onTap: () {
                        ref
                            .read(selectedBabyIdProvider.notifier)
                            .select(m.babyId);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round moon button: switches Light ↔ Night care immediately (a11y "Night care").
class _NightToggle extends ConsumerWidget {
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

/// First-run tile: "Chưa có / Chạm để ghi" on the tracker's care colour (R-012).
class _EmptyCareTile extends StatelessWidget {
  const _EmptyCareTile({required this.kind, required this.onTap});
  final TrackerKind kind;
  final VoidCallback onTap;

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
      semanticLabel:
          '$label, ${l10n.todayTileEmpty}. ${l10n.todayTileTapToLog}',
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
