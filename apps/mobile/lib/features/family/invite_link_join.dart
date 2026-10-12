import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../home/home_shell.dart';
import 'family_models.dart';
import 'family_repository.dart';
import 'join_screens.dart';

/// A tapped invite link `/i/<token>` (owner, 2026-10-12, D-059): the invite web page's "Mở app
/// và nhận lời mời", the email, a QR or a message. Joins without questions: no account yet → a
/// temporary ("Vào ngay") one; the relation is the one the inviter chose and the name "Người
/// thân", both editable later in Gia đình; then straight to Hôm nay. A closed invite says why;
/// anything unexpected (offline) falls back to the usual 16 Nhận lời mời screen.
class InviteLinkScreen extends ConsumerStatefulWidget {
  const InviteLinkScreen({required this.lookup, super.key});
  final InviteLookup lookup;

  @override
  ConsumerState<InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends ConsumerState<InviteLinkScreen> {
  var _manual = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_join()));
  }

  Future<void> _join() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final toaster = ClToaster.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final family = ref.read(familyRepositoryProvider);
    try {
      // A cold start from the link: wait for the saved account, or "Vào ngay" would replace it.
      if (await settledSession(container) is! SessionSignedIn) {
        await ref.read(authRepositoryProvider).signInAnonymously();
      }
      final preview = await family.previewInvite(widget.lookup);
      if (!mounted) return;
      switch (preview) {
        case ClosedInvite(:final reason):
          router.go('${Routes.joinClosed}?reason=${reason.name}');
        case LockedInvite():
          router.go(
            '${Routes.joinClosed}?reason=${InviteClosedReason.notFound.name}',
          );
        case ValidInvite(:final alreadyMember) when alreadyMember:
          router.go(Routes.today);
          toaster.show(message: l10n.joinAlreadyMember(preview.babyNickname));
        case ValidInvite():
          final session = ref.read(sessionProvider);
          final known = session is SessionSignedIn
              ? session.active.firstOrNull?.displayName
              : null;
          final babyId = await family.acceptInvite(
            lookup: widget.lookup,
            displayName: known ?? l10n.inviteLinkDefaultName,
            relation: preview.relation,
            relationCustom: preview.relationCustom,
          );
          await waitForMembership(container, babyId);
          container.read(selectedBabyIdProvider.notifier).select(babyId);
          router.go(Routes.today);
          toaster.show(message: l10n.inviteLinkJoined(preview.babyNickname));
      }
    } on Object {
      // Offline or a hiccup: the usual screen lets the person retry by hand.
      if (mounted) setState(() => _manual = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_manual) return AcceptInviteScreen(lookup: widget.lookup);
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cl.colors.mintDeep),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.inviteLinkJoining,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The session once the saved account (and its babies) has loaded.
Future<Session> settledSession(ProviderContainer container) async {
  final now = container.read(sessionProvider);
  if (now is! SessionLoading) return now;
  final settled = Completer<Session>();
  final sub = container.listen<Session>(sessionProvider, (_, next) {
    if (next is! SessionLoading && !settled.isCompleted) settled.complete(next);
  });
  try {
    return await settled.future.timeout(const Duration(seconds: 15));
  } finally {
    sub.close();
  }
}
