import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'family_labels.dart';
import 'family_models.dart';
import 'family_repository.dart';
import 'family_screen.dart' show familyMessage;
import 'join_screens.dart' show JoinArgs;

/// Invites mailed to my own verified email (owner, 2026-10-11): a signed-in person sees them
/// and accepts or declines without typing the code. With a baby already, they live in the baby
/// list (Chọn bé, Hồ sơ các bé) behind a red dot on the baby switcher; before any baby, on the
/// setup screen. Refetched when the account changes and after an answer.
final myInvitesProvider = FutureProvider<List<MyInvite>>((ref) async {
  // The account, and how many babies it is in: joining one refetches (that invite is used).
  final key = ref.watch(
    sessionProvider.select(
      (s) => s is SessionSignedIn && !s.isAnonymous
          ? '${s.user.uid}:${s.active.length}'
          : null,
    ),
  );
  if (key == null) return const [];
  try {
    return await ref.read(familyRepositoryProvider).listMyInvites();
  } on Object {
    // Offline or the call failed: nothing to show (the code path still works).
    return const [];
  }
});

/// The invite's sentence and its role · expiry, shared by the row, the sheet and the card.
String _line(AppLocalizations l10n, ValidInvite p) => l10n.myInviteLine(
  '${relationLabel(l10n, p.inviterRelation, p.inviterRelationCustom ?? '')} '
  '${p.inviterName}',
  p.babyNickname,
);

String _meta(BuildContext context, AppLocalizations l10n, ValidInvite p) =>
    l10n.myInviteMeta(roleLabel(l10n, p.role), shortDate(context, p.expiresAt));

/// "Đồng ý": 16 → 16a as for a code, with the invite already known (relation and name, then
/// join). [context] must stay mounted (a screen, or the root navigator's).
void acceptMyInvite(BuildContext context, MyInvite invite) {
  final args = JoinArgs(
    lookup: InviteLookup.id(invite.inviteId),
    preview: invite.preview,
  );
  unawaited(
    GoRouter.of(context).push(args.location(Routes.joinInvite), extra: args),
  );
}

/// "Từ chối", after asking. True when the invite was closed.
Future<bool> declineMyInvite(
  BuildContext context,
  WidgetRef ref,
  MyInvite invite,
) async {
  final l10n = AppLocalizations.of(context);
  final preview = invite.preview;
  final confirmed = await showClSheet<bool>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.myInviteDeclineTitle(preview.babyNickname)),
        Text(
          l10n.myInviteDeclineBody(preview.inviterName),
          style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.myInviteDecline,
          style: ClButtonStyle.destructive,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
        ClButton(
          label: l10n.actionCancel,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final toaster = ClToaster.of(context);
  try {
    await withClProgress(
      context,
      () => ref.read(familyRepositoryProvider).declineInvite(invite.inviteId),
    );
    toaster.show(message: l10n.myInviteDeclined(preview.babyNickname));
    return true;
  } on FamilyException catch (e) {
    toaster.show(message: familyMessage(l10n, e.failure));
    return false;
  } finally {
    ref.invalidate(myInvitesProvider);
  }
}

/// The invite on its own: who, which baby, the role and expiry, then Đồng ý / Từ chối.
Future<void> showMyInviteSheet(BuildContext context, MyInvite invite) {
  // Stays mounted after this sheet closes (it may be opened from another sheet).
  final host = Navigator.of(context, rootNavigator: true).context;
  return showClSheet<void>(
    context: context,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final l10n = AppLocalizations.of(sheet);
        final cl = sheet.cl;
        final p = invite.preview;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.myInviteSheetTitle),
            _InviteSummary(invite: invite),
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: l10n.myInviteAccept,
              expand: true,
              onPressed: () {
                Navigator.of(sheet).pop();
                acceptMyInvite(host, invite);
              },
            ),
            ClButton(
              label: l10n.myInviteDecline,
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: () async {
                final navigator = Navigator.of(sheet);
                if (await declineMyInvite(sheet, ref, invite)) {
                  navigator.pop();
                }
              },
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.myInviteSheetHint(p.babyNickname),
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        );
      },
    ),
  );
}

class _InviteSummary extends StatelessWidget {
  const _InviteSummary({required this.invite});
  final MyInvite invite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final p = invite.preview;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: ClIcon(ClIcons.family, size: 20, color: cl.colors.mintText),
        ),
        const SizedBox(width: ClSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_line(l10n, p), style: cl.text.bodyStrong),
              const SizedBox(height: 2),
              Text(
                _meta(context, l10n, p),
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The red dot that says something waits behind a control (the baby switcher, an invite row).
class ClRedDot extends StatelessWidget {
  const ClRedDot({this.size = 10, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cl.colors.error,
        shape: BoxShape.circle,
        border: Border.all(color: cl.colors.surface, width: 1.5),
      ),
    );
  }
}

/// "Lời mời đang chờ bạn" in the baby lists (Chọn bé, Hồ sơ các bé): a row per invite with a
/// red dot; a row opens [showMyInviteSheet] (or [onOpen]). Nothing when there are none.
class MyInviteRows extends ConsumerWidget {
  const MyInviteRows({this.onOpen, this.padding = EdgeInsets.zero, super.key});

  /// Instead of opening the sheet here (the picker closes itself first).
  final void Function(MyInvite invite)? onOpen;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(myInvitesProvider).value ?? const [];
    if (invites.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.myInvitesPending,
            style: cl.text.label.copyWith(
              color: cl.colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ClSpace.s2),
          for (final (i, invite) in invites.indexed) ...[
            if (i > 0) const SizedBox(height: ClSpace.s2),
            ClPressable(
              key: ValueKey('myInvite-${invite.inviteId}'),
              onPressed: () => onOpen != null
                  ? onOpen!(invite)
                  : unawaited(showMyInviteSheet(context, invite)),
              semanticLabel: _line(l10n, invite.preview),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s4,
                  vertical: ClSpace.s3,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.mintSoft,
                  borderRadius: BorderRadius.circular(ClRadius.control),
                ),
                child: Row(
                  children: [
                    const ClRedDot(),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _line(l10n, invite.preview),
                            style: cl.text.bodyStrong,
                          ),
                          Text(
                            _meta(context, l10n, invite.preview),
                            style: cl.text.caption.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
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
        ],
      ),
    );
  }
}

/// Before any baby (setup): the invites as cards to answer in place.
class MyInvitesSection extends ConsumerWidget {
  const MyInvitesSection({this.padding = EdgeInsets.zero, super.key});

  /// Around the section when it shows (callers keep their own rhythm).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(myInvitesProvider).value ?? const [];
    if (invites.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSectionHeader(title: l10n.myInvitesTitle),
          const SizedBox(height: ClSpace.s2),
          for (final (i, invite) in invites.indexed) ...[
            if (i > 0) const SizedBox(height: ClSpace.s3),
            MyInviteCard(invite: invite),
          ],
        ],
      ),
    );
  }
}

class MyInviteCard extends ConsumerStatefulWidget {
  const MyInviteCard({required this.invite, super.key});
  final MyInvite invite;

  @override
  ConsumerState<MyInviteCard> createState() => _MyInviteCardState();
}

class _MyInviteCardState extends ConsumerState<MyInviteCard> {
  var _busy = false;

  Future<void> _decline() async {
    setState(() => _busy = true);
    await declineMyInvite(context, ref, widget.invite);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InviteSummary(invite: widget.invite),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              Expanded(
                child: ClButton(
                  label: l10n.myInviteDecline,
                  style: ClButtonStyle.secondary,
                  expand: true,
                  loading: _busy,
                  onPressed: _busy ? null : _decline,
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: ClButton(
                  label: l10n.myInviteAccept,
                  expand: true,
                  onPressed: _busy
                      ? null
                      : () => acceptMyInvite(context, widget.invite),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
