import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../auth/sign_out_sheet.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../reminders/device_identity.dart';
import 'me_models.dart';
import 'me_repository.dart';
import 'me_screen.dart';
import 'me_widgets.dart';
import 'staff_transfer.dart';

/// 13n "Tài khoản": sign-in methods (unlink guard), devices with remote sign-out, ownership
/// transfer (Q-016) and a transfer Child Life Hỗ trợ asks the owner to confirm (A17, P-136),
/// data export (R-187, G-072) and account deletion (R-046).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return ColoredBox(color: cl.colors.cloud);
    final user = session.user;
    final uid = user.uid;
    final providers = {for (final p in user.providerData) p.providerId};
    final owned = [
      for (final m in session.active)
        if (m.isOwner) m.babyId,
    ];
    final ownedNames = babyNames(ref, owned);
    final parentOf = [
      for (final m in session.active)
        if (m.role == MemberRole.coParent) m,
    ];
    final thisDevice = ref.watch(deviceIdentityProvider).value?.id;
    final devices = ref.watch(devicesProvider(uid)).value ?? const [];
    final now = ref.read(timerClockProvider)();
    final exports = ref.watch(exportsProvider(uid)).value ?? const [];
    final familyId = owned.isEmpty
        ? null
        : ref.watch(babyProvider(owned.first)).value?.familyId;
    final offeredTo = familyId == null
        ? null
        : ref.watch(offeredToProvider(familyId)).value;
    final staffTransfer = openStaffTransfer(
      ref,
      ref.watch(accountDocProvider(uid)).value?.staffTransfer,
    );
    final offeredName = offeredTo == null
        ? null
        : [
            for (final m
                in ref.watch(familyMembersProvider(owned.first)).value ??
                    const <Membership>[])
              if (m.uid == offeredTo) m.displayName,
          ].firstOrNull;

    Future<void> unlink(String providerId, String label) async {
      final toaster = ClToaster.of(context);
      if (providers.length < 2) {
        toaster.show(message: l10n.acUnlinkLast);
        return;
      }
      try {
        await withClProgress(context, () => user.unlink(providerId));
        toaster.show(message: l10n.acUnlinked(label));
      } on Object {
        toaster.show(message: l10n.toastActionFailed, error: true);
      }
    }

    return MePage(
      title: l10n.acTitle,
      children: [
        MeSection(l10n.acSignIn),
        ClCardGroup(
          children: [
            if ((user.email ?? '').isNotEmpty)
              MeRow(
                icon: ClIcons.mail,
                title: 'Email',
                subtitle: user.emailVerified
                    ? l10n.acEmailVerified(user.email!)
                    : l10n.acEmailUnverified(user.email!),
              ),
            if (providers.contains('password'))
              MeRow(
                icon: ClIcons.lock,
                title: l10n.acPassword,
                onTap: () async {
                  final toaster = ClToaster.of(context);
                  try {
                    await withClProgress(
                      context,
                      () => ref
                          .read(authRepositoryProvider)
                          .sendPasswordReset(user.email!),
                    );
                    toaster.show(message: l10n.acPasswordSent(user.email!));
                  } on Object {
                    toaster.show(message: l10n.toastActionFailed, error: true);
                  }
                },
              ),
            for (final (id, label) in const [
              ('apple.com', 'Apple'),
              ('google.com', 'Google'),
            ])
              if (providers.contains(id))
                MeRow(
                  icon: ClIcons.lock,
                  title: label,
                  subtitle: l10n.acLinked,
                  trailing: MeRowAction(
                    label: l10n.acUnlink,
                    onPressed: () => unlink(id, label),
                  ),
                ),
          ],
        ),
        MeSection(l10n.acDevices),
        ClCardGroup(
          children: [
            for (final d in devices)
              MeRow(
                title: d.name.isEmpty ? d.platform : d.name,
                subtitle: d.id == thisDevice
                    ? l10n.acThisDevice
                    : d.updatedAt == null
                    ? null
                    : l10n.acActive(relativeAgo(l10n, d.updatedAt!, now)),
                trailing: d.id == thisDevice
                    ? null
                    : MeRowAction(
                        label: l10n.meSignOut,
                        destructive: true,
                        onPressed: () async {
                          final toaster = ClToaster.of(context);
                          try {
                            await withClProgress(
                              context,
                              () => ref
                                  .read(meRepositoryProvider)
                                  .signOutDevice(d.id),
                            );
                            toaster.show(
                              message: l10n.acDeviceSignedOut(
                                d.name.isEmpty ? d.platform : d.name,
                              ),
                            );
                          } on Object {
                            toaster.show(
                              message: l10n.toastActionFailed,
                              error: true,
                            );
                          }
                        },
                      ),
              ),
          ],
        ),
        if (owned.isNotEmpty && familyId != null) ...[
          MeSection(l10n.acOwner),
          if (staffTransfer != null) ...[
            StaffTransferCard(request: staffTransfer),
            const SizedBox(height: ClSpace.s3),
          ],
          ClCardGroup(
            children: [
              if (offeredTo != null)
                MeRow(
                  icon: ClIcons.family,
                  title: l10n.acTransferPending(offeredName ?? ''),
                  trailing: MeRowAction(
                    label: l10n.acTransferCancel,
                    onPressed: () => withClProgress(
                      context,
                      () => ref
                          .read(meRepositoryProvider)
                          .answerOwnership(familyId, 'cancel'),
                    ),
                  ),
                )
              else
                MeRow(
                  icon: ClIcons.family,
                  title: l10n.acTransfer,
                  subtitle: l10n.acTransferHint(ownedNames),
                  onTap: () => _showTransferSheet(context, ref, owned),
                ),
            ],
          ),
        ],
        if (parentOf.isNotEmpty && !session.isAnonymous) ...[
          MeSection(l10n.acExport),
          ClCardGroup(
            children: [
              MeRow(
                icon: ClIcons.download,
                title: l10n.acExport,
                subtitle: l10n.acExportHint,
                onTap: () => _showExportSheet(context, ref, parentOf),
              ),
              for (final job in exports.take(5)) _ExportRow(job: job),
            ],
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        MeNotice(
          tone: MeTone.error,
          title: l10n.acDelete,
          body: owned.isNotEmpty
              ? l10n.acDeleteBlocked(ownedNames)
              : l10n.acDeleteHint,
          onTap: owned.isNotEmpty || session.isAnonymous
              ? null
              : () => _confirmDeleteAccount(context, ref),
        ),
      ],
    );
  }
}

class _ExportRow extends ConsumerWidget {
  const _ExportRow({required this.job});
  final ExportJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = ref.watch(babyProvider(job.babyId)).value?.nickname ?? '';
    final ready =
        job.state == ExportState.ready &&
        (job.expiresAt?.isAfter(ref.read(timerClockProvider)()) ?? false);
    return MeRow(
      title:
          '${job.kind == ExportKind.care ? l10n.acExportCare : l10n.acExportMedia} · $name',
      subtitle: switch (job.state) {
        ExportState.queued || ExportState.running => l10n.acExportQueued,
        // Downloaded from the email link only (owner, 2026-10-12; exportDownload re-checks).
        ExportState.ready when ready => l10n.acExportEmailed(
          DateFormat.MMMd(locale).add_Hm().format(job.expiresAt!.toLocal()),
        ),
        ExportState.failed => l10n.acExportFailed,
        _ => l10n.acExportExpired,
      },
    );
  }
}

/// "Chuyển chủ hồ sơ cho ai?": Cùng nuôi of every owned baby (Q-016).
Future<void> _showTransferSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> owned,
) {
  final me = ref.read(sessionProvider);
  final myUid = me is SessionSignedIn ? me.user.uid : '';
  return showClSheet<void>(
    context: context,
    builder: (sheet) => Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context);
        final cl = context.cl;
        final lists = [
          for (final b in owned)
            ref.watch(familyMembersProvider(b)).value ?? const <Membership>[],
        ];
        final first = lists.firstOrNull ?? const <Membership>[];
        final candidates = [
          for (final m in first)
            if (m.uid != myUid &&
                m.isActive &&
                m.role == MemberRole.coParent &&
                lists.every(
                  (l) => l.any(
                    (x) =>
                        x.uid == m.uid &&
                        x.isActive &&
                        x.role == MemberRole.coParent,
                  ),
                ))
              m,
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.acTransfer),
            Text(
              l10n.acTransferBody(babyNames(ref, owned)),
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            if (candidates.isEmpty)
              MeNotice(title: l10n.acTransferNone)
            else
              ClCardGroup(
                children: [
                  for (final m in candidates)
                    MeRow(
                      leading: InitialAvatar(name: m.displayName, size: 36),
                      title: m.displayName,
                      trailing: MeRowAction(
                        label: l10n.acTransferSend,
                        onPressed: () async {
                          final toaster = ClToaster.of(context);
                          final navigator = Navigator.of(sheet);
                          try {
                            await withClProgress(
                              context,
                              () => ref
                                  .read(meRepositoryProvider)
                                  .offerOwnership(m.uid),
                            );
                            navigator.pop();
                            toaster.show(
                              message: l10n.acTransferSent(m.displayName),
                            );
                          } on AccountActionException catch (e) {
                            toaster.show(
                              message: e.reason == 'receiver-owns-family'
                                  ? l10n.acReceiverOwns
                                  : l10n.toastActionFailed,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}

/// "Xuất dữ liệu" (G-072): a baby, care logs or photos and videos (owner).
Future<void> _showExportSheet(
  BuildContext context,
  WidgetRef ref,
  List<Membership> parentOf,
) {
  var babyId = parentOf.first.babyId;
  var kind = ExportKind.care;
  var busy = false;
  return showClSheet<void>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        final cl = context.cl;
        final owner = parentOf.any((m) => m.babyId == babyId && m.isOwner);
        if (!owner && kind == ExportKind.media) kind = ExportKind.care;
        String nameOf(String id) =>
            ref.read(babyProvider(id)).value?.nickname ?? '';
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.acExportTitle(nameOf(babyId))),
            if (parentOf.length > 1) ...[
              Wrap(
                spacing: ClSpace.s2,
                children: [
                  for (final m in parentOf)
                    ClFilterChip(
                      label: nameOf(m.babyId),
                      selected: m.babyId == babyId,
                      onTap: () => setState(() => babyId = m.babyId),
                    ),
                ],
              ),
              const SizedBox(height: ClSpace.s3),
            ],
            ClCardGroup(
              children: [
                ClOptionRow(
                  title: l10n.acExportCare,
                  subtitle: l10n.acExportCareHint,
                  selected: kind == ExportKind.care,
                  onTap: () => setState(() => kind = ExportKind.care),
                ),
                if (owner)
                  ClOptionRow(
                    title: l10n.acExportMedia,
                    subtitle: l10n.acExportMediaHint,
                    selected: kind == ExportKind.media,
                    onTap: () => setState(() => kind = ExportKind.media),
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.acExportFootnote,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.acExportStart,
              expand: true,
              onPressed: () async {
                final toaster = ClToaster.of(context);
                final navigator = Navigator.of(sheet);
                setState(() => busy = true);
                try {
                  await ref
                      .read(meRepositoryProvider)
                      .requestExport(babyId, kind);
                  navigator.pop();
                  toaster.show(message: l10n.acExportQueued);
                } on AccountActionException catch (e) {
                  setState(() => busy = false);
                  toaster.show(
                    message: e.reason == 'export-running'
                        ? l10n.acExportRunning
                        : l10n.toastActionFailed,
                  );
                }
              },
              loading: busy,
            ),
          ],
        );
      },
    ),
  );
}

/// "Xoá tài khoản?" — authored logs stay as "Người dùng đã xoá" (Q-016). Changes still on this
/// phone are named before they are lost (AU-3); each refusal says its own reason.
Future<void> _confirmDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final cl = sheet.cl;
    var busy = false;

    /// Set once the unsent changes were shown; the next tap deletes anyway.
    int? unsent;
    return StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.acDeleteTitle),
          Text(
            l10n.acDeleteBody,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          if (unsent != null) ...[
            const SizedBox(height: ClSpace.s3),
            Semantics(
              liveRegion: true,
              child: MeNotice(
                title: l10n.acDeleteUnsent(unsent!),
                icon: ClIcons.alert,
                tone: MeTone.warn,
              ),
            ),
          ],
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: busy
                ? l10n.acDeleting
                : unsent != null
                ? l10n.acDeleteAnyway
                : l10n.acDelete,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () async {
              final toaster = ClToaster.of(context);
              setState(() => busy = true);
              if (unsent == null) {
                final waiting = await unsentWrites(ref);
                if (waiting != null) {
                  setState(() {
                    busy = false;
                    unsent = waiting;
                  });
                  return;
                }
              }
              try {
                await ref.read(meRepositoryProvider).deleteAccount();
                // The job removes the account server-side; this device signs out now.
                await ref.read(authRepositoryProvider).signOut();
              } on AccountActionException catch (e) {
                setState(() => busy = false);
                toaster.show(
                  message: switch (e.reason) {
                    'owns-babies' => l10n.acDeleteOwnsBabies,
                    'unavailable' ||
                    'deadline-exceeded' => l10n.toastActionFailed,
                    _ => l10n.familyErrorGeneric,
                  },
                  error: true,
                );
              } on Object {
                setState(() => busy = false);
                toaster.show(message: l10n.familyErrorGeneric, error: true);
              }
            },
            loading: busy,
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
  },
);
