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
/// thân", both editable later in Gia đình; then straight to Hôm nay. A closed or full invite
/// says why; anything unexpected (offline) falls back to the usual 16 Nhận lời mời screen, which
/// says what went wrong and offers "Thử lại" (FJ-1).
class InviteLinkScreen extends ConsumerStatefulWidget {
  const InviteLinkScreen({required this.lookup, super.key});
  final InviteLookup lookup;

  @override
  ConsumerState<InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends ConsumerState<InviteLinkScreen> {
  var _manual = false;

  /// FJ-4: joined, waiting for the membership to reach this phone.
  ({String babyId, String nickname})? _arriving;

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
    void closed(InviteClosedReason reason) =>
        router.go('${Routes.joinClosed}?reason=${reason.name}');
    try {
      // A cold start from the link: wait for the saved account, or "Vào ngay" would replace it.
      if (await settledSession(container) is! SessionSignedIn) {
        await ref.read(authRepositoryProvider).signInAnonymously();
      }
      final preview = await family.previewInvite(widget.lookup);
      if (!mounted) return;
      switch (preview) {
        case ClosedInvite(:final reason):
          closed(reason);
        case LockedInvite():
          // FJ-5: 16 says how long the lockout lasts.
          setState(() => _manual = true);
        case ValidInvite(:final alreadyMember) when alreadyMember:
          // FJ-5: open the baby the invite is for, not the one selected before.
          final babyId = preview.babyId;
          if (babyId != null) {
            container.read(selectedBabyIdProvider.notifier).select(babyId);
          }
          router.go(Routes.today);
          toaster.show(message: l10n.joinAlreadyMember(preview.babyNickname));
        case ValidInvite(:final seatsFull) when seatsFull:
          // D-127 Q3 / FJ-2: no writer seat left, said before anything is created.
          closed(InviteClosedReason.full);
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
          if (!await waitForMembership(container, babyId)) {
            // FJ-4: joined; Today opens when the membership arrives.
            if (mounted) {
              setState(
                () => _arriving = (
                  babyId: babyId,
                  nickname: preview.babyNickname,
                ),
              );
            }
            return;
          }
          container.read(selectedBabyIdProvider.notifier).select(babyId);
          router.go(Routes.today);
          toaster.show(message: l10n.inviteLinkJoined(preview.babyNickname));
      }
    } on FamilyException catch (e) {
      if (!mounted) return;
      switch (e.failure) {
        case FamilyFailure.seatsFull:
          closed(InviteClosedReason.full);
        case FamilyFailure.expired:
          closed(InviteClosedReason.expired);
        case FamilyFailure.revoked:
          closed(InviteClosedReason.revoked);
        case FamilyFailure.used:
          closed(InviteClosedReason.used);
        case FamilyFailure.notFound:
          closed(InviteClosedReason.notFound);
        default:
          // Offline or a hiccup: 16 shows why and offers "Thử lại" (FJ-1).
          setState(() => _manual = true);
      }
    } on Object {
      if (mounted) setState(() => _manual = true);
    }
  }

  void _opened(String babyId, String nickname) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref.read(selectedBabyIdProvider.notifier).select(babyId);
    context.go(Routes.today);
    toaster.show(message: l10n.inviteLinkJoined(nickname));
  }

  @override
  Widget build(BuildContext context) {
    if (_manual) return AcceptInviteScreen(lookup: widget.lookup);
    final l10n = AppLocalizations.of(context);
    final arriving = _arriving;
    if (arriving != null) {
      final session = ref.watch(sessionProvider);
      if (session is SessionSignedIn &&
          session.membershipFor(arriving.babyId) != null) {
        _arriving = null;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _opened(arriving.babyId, arriving.nickname),
        );
      }
    }
    return JoiningProgress(
      message: arriving == null
          ? l10n.inviteLinkJoining
          : l10n.joinArriving(arriving.nickname),
    );
  }
}

/// A join on its way: spinner and one line (the invite link, FJ-4's late membership).
class JoiningProgress extends StatelessWidget {
  const JoiningProgress({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: cl.colors.mintDeep),
              const SizedBox(height: ClSpace.s4),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
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
