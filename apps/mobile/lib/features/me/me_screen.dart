import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/save_account.dart';
import '../home/home_shell.dart';
import '../memories/album_models.dart';
import '../memories/memory_repository.dart';
import '../memories/push_registration.dart';
import '../memories/upload_queue.dart';
import '../onboarding/setup_screens.dart';
import 'me_models.dart';
import 'me_repository.dart';
import 'me_widgets.dart';

/// Nicknames of [babyIds] joined "Teddy, Na".
String babyNames(WidgetRef ref, Iterable<String> babyIds) => [
  for (final id in babyIds)
    if ((ref.watch(babyProvider(id)).value?.nickname ?? '').isNotEmpty)
      ref.watch(babyProvider(id)).value!.nickname,
].join(', ');

/// Tab "Tôi" per role (13a parent, 13g caregiver, 13h relative; R-123).
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final me = ref.watch(selectedMembershipProvider);
    if (session is! SessionSignedIn || me == null) {
      return ColoredBox(color: cl.colors.cloud);
    }
    final active = session.active;
    final parent = me.role == MemberRole.coParent;
    final names = babyNames(ref, [
      for (final m in active)
        if (m.role == me.role) m.babyId,
    ]);
    final owned = [
      for (final m in active)
        if (m.isOwner) m.babyId,
    ];
    final relation = relationLabel(l10n, me.relation, me.relationCustom ?? '');
    final roleLine = switch (me.role) {
      MemberRole.coParent when owned.isNotEmpty => l10n.meRoleOwner(
        relation,
        babyNames(ref, owned),
      ),
      MemberRole.coParent => l10n.meRoleParent(relation, names),
      MemberRole.caregiver => l10n.meRoleCaregiver(relation, names),
      MemberRole.relative => l10n.meRoleRelative(relation, names),
    };
    final prefs =
        ref.watch(notificationPrefsProvider(me.uid)).value ??
        const NotificationPrefs();
    final theme = ref.watch(appearanceSettingsProvider).theme;
    final account = ref.watch(accountDocProvider(me.uid)).value;

    return MePage(
      title: l10n.tabMe,
      back: false,
      children: [
        if (account?.offer case final offer?) ...[
          OwnershipOfferCard(offer: offer),
          const SizedBox(height: ClSpace.s3),
        ],
        // Profile → 13m.
        ClCardGroup(
          children: [
            MeRow(
              leading: InitialAvatar(name: me.displayName, size: 52),
              title: me.displayName,
              subtitle: [
                if ((session.user.email ?? '').isNotEmpty) session.user.email!,
                roleLine,
              ].join('\n'),
              onTap: () => context.push(Routes.meProfile),
            ),
          ],
        ),
        if (parent) ...[
          const SizedBox(height: ClSpace.s3),
          StorageCard(babyId: me.babyId),
        ],
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            MeRow(
              icon: ClIcons.cake,
              title: switch (me.role) {
                MemberRole.coParent => l10n.meBabies,
                MemberRole.caregiver => l10n.meAssigned,
                MemberRole.relative => l10n.meFollowing,
              },
              subtitle: names,
              value: '${active.where((m) => m.role == me.role).length}',
              onTap: () => context.push(Routes.meBabies),
            ),
            if (parent) _MessagesRow(me: me),
            MeRow(
              icon: ClIcons.bell,
              title: l10n.meNotifications,
              value: prefs.allOn
                  ? l10n.meOn
                  : prefs.allOff
                  ? l10n.meOff
                  : l10n.meSome,
              onTap: () => context.push(Routes.meNotifications),
            ),
            MeRow(
              icon: ClIcons.globe,
              title: l10n.meAppearance,
              value: switch (theme) {
                ThemePreference.auto => l10n.themeAuto,
                ThemePreference.light => l10n.themeLight,
                ThemePreference.dark => l10n.themeDark,
              },
              onTap: () => context.push(Routes.appearance),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            if (session.isAnonymous)
              MeRow(
                icon: ClIcons.cloudOff,
                title: l10n.saveAccountTitle,
                onTap: () => showSaveAccountSheet(
                  context,
                  ref.read(babyProvider(me.babyId)).value?.nickname ?? '',
                ),
              ),
            MeRow(
              icon: ClIcons.lock,
              title: l10n.meAccount,
              subtitle: l10n.meAccountHint,
              onTap: () => context.push(Routes.meAccount),
            ),
            MeRow(
              icon: ClIcons.mail,
              title: l10n.meHelp,
              onTap: () => context.push(Routes.meHelp),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            MeRow(
              title: l10n.meSignOut,
              destructive: true,
              onTap: () => confirmSignOut(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessagesRow extends ConsumerWidget {
  const _MessagesRow({required this.me});
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = [
      for (final m
          in ref.watch(messagesProvider((me.babyId, me.uid, true))).value ??
              const <ParentMessage>[])
        if (!m.readByUid(me.uid)) m,
    ].length;
    return MeRow(
      icon: ClIcons.mail,
      title: l10n.messagesTitle,
      value: unread > 0 ? l10n.messagesUnread(unread) : null,
      onTap: () => context.push(Routes.messages),
    );
  }
}

/// Round initial ("M") for people (13a, 13m, 13n).
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({required this.name, this.size = 44, super.key});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cl.colors.peachSoft,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: cl.text.headline.copyWith(
            fontSize: size * 0.42,
            color: cl.colors.onWarm,
          ),
        ),
      ),
    );
  }
}

/// 13a storage card: "3,2 GB / 10 GB", one segment per baby, legend → 13b.
class StorageCard extends ConsumerWidget {
  const StorageCard({required this.babyId, super.key});
  final String babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final s = ref.watch(familyStorageProvider(babyId)).value;
    final tints = babyTints(context);
    return ClCardGroup(
      children: [
        MeRow(
          title: l10n.meStorage,
          value: s == null
              ? null
              : l10n.meStorageOf(
                  formatBytes(s.usedBytes, locale),
                  formatBytes(s.quotaBytes, locale),
                ),
          onTap: () => context.push(Routes.meStorage),
        ),
        if (s != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s4,
              0,
              ClSpace.s4,
              ClSpace.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorageBar(
                  segments: [for (final b in s.babies) b.bytes],
                  quota: s.quotaBytes,
                  full: s.state == StorageState.full,
                ),
                const SizedBox(height: ClSpace.s2),
                Wrap(
                  spacing: ClSpace.s3,
                  children: [
                    for (final (i, b) in s.babies.indexed)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tints[i % tints.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${b.nickname} ${formatBytes(b.bytes, locale)}',
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: ClSpace.s1),
                Text(
                  l10n.meStorageShared,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Mai muốn chuyển quyền chủ hồ sơ cho bạn" — Nhận / Từ chối (Q-016).
class OwnershipOfferCard extends ConsumerStatefulWidget {
  const OwnershipOfferCard({required this.offer, super.key});
  final OwnershipOffer offer;

  @override
  ConsumerState<OwnershipOfferCard> createState() => _OwnershipOfferCardState();
}

class _OwnershipOfferCardState extends ConsumerState<OwnershipOfferCard> {
  var _busy = false;

  Future<void> _answer(String answer) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(meRepositoryProvider)
          .answerOwnership(widget.offer.familyId, answer);
      if (answer == 'accept') toaster.show(message: l10n.acOfferAccepted);
    } on AccountActionException {
      toaster.show(message: l10n.toastActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MeNotice(
      title: l10n.acOfferTitle(widget.offer.fromName),
      body: l10n.acOfferBody(babyNames(ref, widget.offer.babyIds)),
      icon: ClIcons.family,
      child: Row(
        children: [
          Expanded(
            child: ClButton(
              label: l10n.acOfferAccept,
              expand: true,
              onPressed: _busy ? null : () => _answer('accept'),
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: ClButton(
              label: l10n.acOfferDecline,
              style: ClButtonStyle.secondary,
              expand: true,
              onPressed: _busy ? null : () => _answer('decline'),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Đăng xuất" with a confirmation; uploads still on the device are named (gap, 13a).
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) {
  final session = ref.read(sessionProvider);
  if (session is SessionSignedIn && session.isAnonymous) {
    return confirmAnonymousSignOut(context, ref);
  }
  final l10n = AppLocalizations.of(context);
  final pending = [
    for (final b in ref.read(uploadQueueProvider).batches)
      for (final i in b.items)
        if (!{
          QueueState.uploaded,
          QueueState.unreadable,
          QueueState.cancelled,
        }.contains(i.state))
          i,
  ].length;
  return showClSheet<void>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.meSignOutTitle),
        Text(
          pending > 0 ? l10n.meSignOutPending(pending) : l10n.meSignOutBody,
          style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.meSignOut,
          style: ClButtonStyle.destructive,
          expand: true,
          onPressed: () {
            Navigator.of(sheet).pop();
            signOutThisDevice(ref);
          },
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.actionCancel,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(),
        ),
      ],
    ),
  );
}
