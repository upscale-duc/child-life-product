import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../family/save_account.dart';
import '../home/home_shell.dart';
import '../memories/push_registration.dart';
import '../memories/upload_queue.dart';
import 'auth_repository.dart';

/// AU-3: changes still waiting on this phone before an account leaves it. Firestore gets [wait]
/// to send them: null when everything went. Otherwise the care writes are counted, the larger of
/// this run's outbox (SY-3) and the logs Today marks pending (the outbox restarts at 0 after a
/// relaunch); 0 means something waits that the app cannot count.
Future<int?> unsentWrites(
  WidgetRef ref, {
  Duration wait = const Duration(seconds: 5),
}) async {
  try {
    await ref.read(firestoreProvider).waitForPendingWrites().timeout(wait);
    return null;
  } on Object {
    // Timed out (offline) or no Firestore: count what is known.
  }
  var pending = 0;
  final session = ref.read(sessionProvider);
  if (session is SessionSignedIn) {
    for (final m in session.active) {
      final records = recentRecordsProvider(m.babyId);
      if (!ref.exists(records)) continue;
      pending += (ref.read(records).value ?? const [])
          .where((r) => r.pending)
          .length;
    }
  }
  return max(pending, ref.read(careOutboxProvider));
}

/// Uploads still on the phone (13a): they stop when the account signs out.
int uploadsWaiting(WidgetRef ref) => [
  for (final b in ref.read(uploadQueueProvider).batches)
    for (final i in b.items)
      if (!{
        QueueState.uploaded,
        QueueState.unreadable,
        QueueState.cancelled,
      }.contains(i.state))
        i,
].length;

/// "Đăng xuất" (13a) and the temporary identity's sign-out (R-031), after checking for unsent
/// changes (AU-3), so the sheet never says everything is saved while it is not.
Future<void> showSignOutSheet(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  final anonymous = session is SessionSignedIn && session.isAnonymous;
  final unsent = await withClProgress(context, () => unsentWrites(ref));
  if (!context.mounted) return;
  return showClSheet<void>(
    context: context,
    builder: (_) => SignOutSheet(
      anonymous: anonymous,
      unsent: unsent,
      uploads: anonymous ? 0 : uploadsWaiting(ref),
      host: context,
    ),
  );
}

class SignOutSheet extends ConsumerStatefulWidget {
  const SignOutSheet({
    required this.anonymous,
    required this.unsent,
    required this.uploads,
    required this.host,
    super.key,
  });

  /// A temporary identity ("Vào ngay"): signing out loses it (R-031).
  final bool anonymous;

  /// From [unsentWrites]: null when everything was sent.
  final int? unsent;

  /// Uploads still on the phone.
  final int uploads;

  /// The screen that opened the sheet, which outlives it ("Lưu tài khoản" opens 16d there).
  final BuildContext host;

  @override
  ConsumerState<SignOutSheet> createState() => _SignOutSheetState();
}

class _SignOutSheetState extends ConsumerState<SignOutSheet> {
  late int? _unsent = widget.unsent;
  bool _sending = false;

  /// "Thử gửi ngay": the network is nudged and the queue gets a few seconds to drain.
  Future<void> _sendNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    final retry = await ref.read(careRepositoryProvider).retryNow();
    if (!mounted) return;
    // A refused write has its own toast and will never send: nothing is left waiting for it.
    final sent = retry != CareRetry.waiting;
    setState(() {
      _sending = false;
      if (sent) _unsent = null;
    });
    if (!sent) showClToast(context, message: l10n.unsentStillPending);
  }

  void _signOut() {
    Navigator.of(context).pop();
    if (widget.anonymous) {
      unawaited(ref.read(authRepositoryProvider).signOut());
    } else {
      unawaited(signOutThisDevice(ref));
    }
  }

  void _saveAccount() {
    Navigator.of(context).pop();
    final m = ref.read(selectedMembershipProvider);
    final name = m == null
        ? ''
        : ref.read(babyProvider(m.babyId)).value?.nickname ?? '';
    if (widget.host.mounted) showSaveAccountSheet(widget.host, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final unsent = _unsent;
    final body = cl.text.body.copyWith(color: cl.colors.inkMuted);
    final cancel = ClButton(
      label: l10n.actionCancel,
      style: ClButtonStyle.plain,
      expand: true,
      onPressed: () => Navigator.of(context).pop(),
    );
    if (widget.anonymous) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.signOutAnonTitle),
          Text(
            [
              l10n.signOutAnonBody,
              if (unsent != null) l10n.signOutAnonUnsent(unsent),
            ].join(' '),
            style: body,
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.saveAccountTitle,
            expand: true,
            onPressed: _saveAccount,
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.signOutAnonConfirm,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: _signOut,
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.meSignOutTitle),
        if (unsent != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(l10n.signOutUnsent(unsent), style: body),
          ),
          if (widget.uploads > 0) ...[
            const SizedBox(height: ClSpace.s2),
            Text(l10n.meSignOutPending(widget.uploads), style: body),
          ],
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.unsentSendNow,
            expand: true,
            loading: _sending,
            onPressed: _sending ? null : _sendNow,
          ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: l10n.meSignOutAnyway,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: _sending ? null : _signOut,
          ),
        ] else ...[
          Text(
            widget.uploads > 0
                ? l10n.meSignOutPending(widget.uploads)
                : l10n.meSignOutBody,
            style: body,
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.meSignOut,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: _signOut,
          ),
        ],
        const SizedBox(height: ClSpace.s2),
        cancel,
      ],
    );
  }
}
