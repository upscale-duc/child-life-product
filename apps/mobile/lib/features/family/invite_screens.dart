import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_screens.dart' show looksLikeEmail;
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'family_heroes.dart';
import 'family_labels.dart';
import 'family_models.dart';
import 'family_repository.dart';
import 'family_screen.dart';
import '../premium/premium_entries.dart';

/// Invite progress on 14b → 14c (Figma draws the same ~77 % on both; Q in extract 01).
const _progressRole = 0.5;
const _progressSend = 0.8;

String _draftRelation(AppLocalizations l10n, InviteDraft d) =>
    relationLabel(l10n, d.relation, d.relationCustom ?? '');

/// 14b Mời · Vai trò & quyền (116:11916): relation chips + role radio (+ 14b2), R-032.
class InviteRoleScreen extends ConsumerStatefulWidget {
  const InviteRoleScreen({super.key});

  @override
  ConsumerState<InviteRoleScreen> createState() => _InviteRoleScreenState();
}

class _InviteRoleScreenState extends ConsumerState<InviteRoleScreen> {
  Relation? _relation;
  final _custom = TextEditingController();
  MemberRole _role = MemberRole.caregiver;
  ExtraRights _extra = ExtraRights.none;
  bool _busy = false;

  /// Idempotency key for createFamilyInvite; renewed whenever the draft changes.
  String _requestId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _custom.addListener(_changed);
  }

  void _changed() => setState(() => _requestId = const Uuid().v4());

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  bool get _complete =>
      _relation != null &&
      (_relation != Relation.other || _custom.text.trim().isNotEmpty);

  InviteDraft get _draft => InviteDraft(
    relation: _relation!,
    relationCustom: _relation == Relation.other ? _custom.text.trim() : null,
    role: _role,
    extraRights: _role == MemberRole.relative ? _extra : null,
  );

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context);
    final me = ref.read(selectedMembershipProvider);
    if (me == null) return;
    final nickname = ref.read(babyProvider(me.babyId)).value?.nickname ?? '';
    setState(() => _busy = true);
    try {
      final draft = _draft;
      final ticket = await ref
          .read(familyRepositoryProvider)
          .createInvite(requestId: _requestId, babyId: me.babyId, draft: draft);
      if (!mounted) return;
      final changed = await context.push<bool>(
        Routes.inviteSend,
        extra: InviteSendArgs(
          babyId: me.babyId,
          draft: draft,
          ticket: ticket,
          inviterName: me.displayName,
          babyNickname: nickname,
        ),
      );
      // "Đổi" cancelled that invite; the next one needs a new key.
      if (changed == true && mounted) {
        setState(() => _requestId = const Uuid().v4());
      }
    } on FamilyException catch (e) {
      if (!mounted) return;
      if (e.failure == FamilyFailure.seatsFull) {
        // E12 (D-101): the writer seats are full; Premium (PW05) or invite as a relative.
        final relative = await showSeatsFullSuggestion(context, ref, me.babyId);
        if (relative && mounted) {
          setState(() {
            _role = MemberRole.relative;
            _requestId = const Uuid().v4();
          });
        }
      } else {
        showClToast(context, message: familyMessage(l10n, e.failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _details() {
    if (_role == MemberRole.relative) {
      showRelativeRightsSheet(
        context,
        value: _extra,
        onChanged: (v) => setState(() {
          _extra = v;
          _requestId = const Uuid().v4();
        }),
      );
    } else {
      showRoleDetailsSheet(context, _role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    final ownerCanAddCoParent = me?.isOwner ?? false;

    Widget role(MemberRole r, String hint) => ClOptionRow(
      title: roleLabel(l10n, r),
      subtitle: r == MemberRole.coParent && !ownerCanAddCoParent
          ? l10n.roleCoParentOwnerOnly
          : hint,
      selected: _role == r,
      onTap: () {
        if (r == MemberRole.coParent && !ownerCanAddCoParent) {
          showClToast(context, message: l10n.inviteErrorOwnerOnly);
          return;
        }
        setState(() {
          _role = r;
          _requestId = const Uuid().v4();
        });
      },
    );

    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop(), progress: _progressRole),
      content: [
        // D-118: no subtitle; "Người được mời là" and "Quyền" below say what to choose.
        ScreenHeading(title: l10n.familyInvite),
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.inviteRelationLabel,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        RelationChips(
          options: inviteRelations,
          selected: _relation,
          onSelected: (r) => setState(() {
            _relation = r;
            _requestId = const Uuid().v4();
          }),
        ),
        if (_relation == Relation.other) ...[
          const SizedBox(height: ClSpace.s4),
          ClTextField(
            label: l10n.inviteCustomLabel,
            placeholder: l10n.whoCustomPlaceholder,
            controller: _custom,
            standalone: true,
            textCapitalization: TextCapitalization.sentences,
            maxLength: relationCustomMaxLength,
          ),
        ],
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.inviteRoleLabel,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          children: [
            role(MemberRole.coParent, l10n.roleCoParentHint),
            role(MemberRole.caregiver, l10n.roleCaregiverHint),
            role(MemberRole.relative, l10n.roleRelativeHint),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.inviteSeeDetails,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: _details,
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.inviteNext,
          expand: true,
          onPressed: _complete && !_busy ? _next : null,
          loading: _busy,
        ),
      ],
    );
  }
}

/// 14b2 Quyền Người thân (121:11672): fixed "Luôn có" banner + two view toggles (R-033).
Future<void> showRelativeRightsSheet(
  BuildContext context, {
  required ExtraRights value,
  required ValueChanged<ExtraRights> onChanged,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _RelativeRightsSheet(initial: value, onChanged: onChanged),
);

class _RelativeRightsSheet extends StatefulWidget {
  const _RelativeRightsSheet({required this.initial, required this.onChanged});
  final ExtraRights initial;
  final ValueChanged<ExtraRights> onChanged;

  @override
  State<_RelativeRightsSheet> createState() => _RelativeRightsSheetState();
}

class _RelativeRightsSheetState extends State<_RelativeRightsSheet> {
  late ExtraRights _value = widget.initial;

  void _set(ExtraRights v) {
    setState(() => _value = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.relativeRightsTitle),
        Container(
          padding: const EdgeInsets.all(ClSpace.s3),
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.control),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.check, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.relativeRightsAlways,
                  style: cl.text.label.copyWith(color: cl.colors.mintText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.relativeRightsMore,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        ClSettingRow(
          icon: ClIcons.cake,
          title: l10n.rightBabyInfo,
          subtitle: l10n.rightBabyInfoHint,
          value: _value.viewBabyInfo,
          onChanged: (v) => _set(_value.copyWith(viewBabyInfo: v)),
        ),
        const SizedBox(height: ClSpace.s2),
        ClSettingRow(
          icon: ClIcons.feed,
          title: l10n.rightDailyCare,
          subtitle: l10n.rightDailyCareHint,
          value: _value.viewDailyCare,
          onChanged: (v) => _set(_value.copyWith(viewDailyCare: v)),
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.actionDone,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// "Xem chi tiết quyền" for Cùng nuôi / Người chăm sóc (not drawn; same list as 16's tiles).
Future<void> showRoleDetailsSheet(BuildContext context, MemberRole role) =>
    showClSheet<void>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.roleDetailsTitle(roleLabel(l10n, role))),
            PermissionGrid(permissions: rolePermissions(l10n, role)),
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: l10n.actionDone,
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );

/// Two-column PermissionTiles (23:369), as on 16.
class PermissionGrid extends StatelessWidget {
  const PermissionGrid({required this.permissions, super.key});
  final List<(String, bool)> permissions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - ClSpace.s3) / 2;
      return Wrap(
        spacing: ClSpace.s3,
        runSpacing: ClSpace.s3,
        children: [
          for (final (label, allowed) in permissions)
            SizedBox(
              width: width,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 166,
                  child: Semantics(
                    label: label,
                    enabled: allowed,
                    child: ExcludeSemantics(
                      child: ClPermissionTile(label: label, allowed: allowed),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

enum InviteChannel { qr, link, email }

/// Arguments of 14c / 14d.
class InviteSendArgs {
  const InviteSendArgs({
    required this.babyId,
    required this.draft,
    required this.ticket,
    required this.inviterName,
    required this.babyNickname,
    this.fromPending = false,
    this.email,
  });

  final String babyId;
  final InviteDraft draft;
  final InviteTicket ticket;
  final String inviterName;
  final String babyNickname;

  /// Opened from a "Đang chờ nhận lời" row: no "Đổi", but cancel is offered.
  final bool fromPending;

  /// 14d only: where the email went.
  final String? email;

  InviteSendArgs copyWith({InviteTicket? ticket, String? email}) =>
      InviteSendArgs(
        babyId: babyId,
        draft: draft,
        ticket: ticket ?? this.ticket,
        inviterName: inviterName,
        babyNickname: babyNickname,
        fromPending: fromPending,
        email: email ?? this.email,
      );
}

/// Opens the native share sheet with the invite link and code ("Chia sẻ lời mời").
Future<void> shareInvite(
  BuildContext context,
  WidgetRef ref,
  InviteSendArgs args,
) async {
  final l10n = AppLocalizations.of(context);
  final origin = ref.read(environmentProvider).webOrigin;
  final box = context.findRenderObject() as RenderBox?;
  final code = args.ticket.code;
  await SharePlus.instance.share(
    ShareParams(
      text: l10n.inviteShareText(
        args.inviterName,
        args.babyNickname,
        args.ticket.link(origin),
        '${code.substring(0, 3)} ${code.substring(3)}',
      ),
      subject: l10n.inviteShareSubject(args.babyNickname),
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

String _expiryLabel(AppLocalizations l10n, DateTime expiresAt) {
  final left = expiresAt.difference(DateTime.now());
  if (left.inHours < 24) return l10n.inviteExpiresToday;
  return l10n.inviteExpiresInDays(
    (left.inHours / 24).ceil().clamp(1, inviteTtlDays),
  );
}

/// 14c Mời · Gửi lời mời (117:11435): QR / Link / Email with one 6-digit code (R-032).
/// The Link and Email tabs are not drawn (G-054); they follow the QR tab's layout.
class InviteSendScreen extends ConsumerStatefulWidget {
  const InviteSendScreen({required this.args, super.key});
  final InviteSendArgs args;

  @override
  ConsumerState<InviteSendScreen> createState() => _InviteSendScreenState();
}

class _InviteSendScreenState extends ConsumerState<InviteSendScreen> {
  late InviteSendArgs _args = widget.args;
  InviteChannel _channel = InviteChannel.qr;
  final _email = TextEditingController();
  bool _busy = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() => _emailError = null));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _emailError = l10n.authErrorInvalidEmail);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(familyRepositoryProvider)
          .sendInviteEmail(
            inviteId: _args.ticket.inviteId,
            email: email,
            locale: Localizations.localeOf(context).languageCode,
          );
      if (mounted) {
        unawaited(
          context.push(Routes.inviteSent, extra: _args.copyWith(email: email)),
        );
      }
    } on FamilyException catch (e) {
      if (mounted) setState(() => _emailError = familyMessage(l10n, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Đổi": back to 14b; this invite is cancelled so it does not linger as pending.
  Future<void> _change() async {
    unawaited(
      ref
          .read(familyRepositoryProvider)
          .revokeInvite(_args.ticket.inviteId)
          .catchError((Object _) {}),
    );
    context.pop(true);
  }

  Future<void> _cantScan() => showClSheet<void>(
    context: context,
    builder: (_) => _CantScanSheet(
      args: _args,
      onRegenerated: (ticket) =>
          setState(() => _args = _args.copyWith(ticket: ticket)),
      onEmail: () => setState(() => _channel = InviteChannel.email),
      onRevoked: () => context.go(Routes.family),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final relation = _draftRelation(l10n, _args.draft);
    final origin = ref.watch(environmentProvider).webOrigin;
    final link = _args.ticket.link(origin);
    final code = _args.ticket.code;
    final spaced = '${code.substring(0, 3)} ${code.substring(3)}';

    final subtitle = switch (_channel) {
      InviteChannel.qr => l10n.inviteSendSubtitle(relation),
      InviteChannel.link => l10n.inviteSendLinkSubtitle(relation),
      InviteChannel.email => l10n.inviteSendEmailSubtitle(relation),
    };

    final codeBlock = Column(
      children: [
        Text(
          l10n.inviteOrCode,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s1),
        Semantics(
          label: '${l10n.a11yInviteCode}: ${code.split('').join(' ')}',
          child: ExcludeSemantics(
            child: ClTabularText(
              spaced,
              style: cl.text.title.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: cl.colors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s1),
        Text(
          _expiryLabel(l10n, _args.ticket.expiresAt),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );

    final card = switch (_channel) {
      InviteChannel.qr => Column(
        key: const ValueKey('qr'),
        children: [
          _InviteQr(data: link),
          const SizedBox(height: ClSpace.s4),
          codeBlock,
        ],
      ),
      InviteChannel.link => Column(
        key: const ValueKey('link'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(ClSpace.s3),
            decoration: BoxDecoration(
              color: cl.colors.surface2,
              borderRadius: BorderRadius.circular(ClRadius.control),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.link, size: 18, color: cl.colors.inkMuted),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Text(
                    link,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.label,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: l10n.inviteCopyLink,
            style: ClButtonStyle.tinted,
            icon: ClIcons.link,
            expand: true,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              showClToast(context, message: l10n.inviteLinkCopied);
            },
          ),
          const SizedBox(height: ClSpace.s4),
          codeBlock,
        ],
      ),
      InviteChannel.email => Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClTextField(
            label: l10n.inviteEmailLabel(relation),
            placeholder: l10n.emailPlaceholder,
            controller: _email,
            standalone: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _busy ? null : _sendEmail(),
          ),
          if (_emailError != null) ...[
            const SizedBox(height: ClSpace.s2),
            Semantics(
              liveRegion: true,
              child: Text(
                _emailError!,
                style: cl.text.label.copyWith(color: cl.colors.error),
              ),
            ),
          ],
          const SizedBox(height: ClSpace.s4),
          codeBlock,
        ],
      ),
    };

    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => context.pop(false),
        progress: _progressSend,
      ),
      content: [
        ScreenHeading(
          title: l10n.inviteSendTitle(relation),
          subtitle: subtitle,
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
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
              Expanded(
                child: Text(
                  l10n.memberDetail(
                    relation,
                    roleLabel(l10n, _args.draft.role),
                  ),
                  style: cl.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cl.colors.ink,
                  ),
                ),
              ),
              if (!_args.fromPending)
                ClPressable(
                  onPressed: _change,
                  semanticLabel: l10n.inviteSummaryChange,
                  child: Text(
                    l10n.inviteSummaryChange,
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClSegmented<InviteChannel>(
          options: InviteChannel.values,
          selected: _channel,
          labelOf: (c) => switch (c) {
            InviteChannel.qr => l10n.inviteChannelQr,
            InviteChannel.link => l10n.inviteChannelLink,
            InviteChannel.email => l10n.inviteChannelEmail,
          },
          onChanged: (c) => setState(() => _channel = c),
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.all(ClSpace.s6),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.card),
            boxShadow: cl.shadows.card,
          ),
          child: AnimatedSwitcher(
            duration: context.motion(ClMotion.quick),
            child: card,
          ),
        ),
      ],
      bottom: [
        if (_channel == InviteChannel.email)
          ClButton(
            label: l10n.inviteEmailSend,
            expand: true,
            onPressed: _busy || _email.text.trim().isEmpty ? null : _sendEmail,
            loading: _busy,
          )
        else
          Builder(
            builder: (buttonContext) => ClButton(
              label: l10n.inviteShare,
              expand: true,
              onPressed: () => shareInvite(buttonContext, ref, _args),
            ),
          ),
        ClButton(
          label: l10n.inviteCantScan(relation),
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: _cantScan,
        ),
      ],
    );
  }
}

/// QR (200 px) with the app mark in the centre; high error correction keeps it scannable.
class _InviteQr extends StatelessWidget {
  const _InviteQr({required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    // The code is always dark-on-white so every camera reads it, in Night care too.
    const ink = Color(0xFF173D44);
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ClRadius.control),
          border: Border.all(color: context.cl.colors.separator),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: data,
              size: 200,
              padding: EdgeInsets.zero,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ink,
              ),
            ),
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ClLogo(height: 40, semanticLabel: ''),
            ),
          ],
        ),
      ),
    );
  }
}

/// 14c2 Không quét được (121:12549): steps, "Tạo mã mới" (old code stops working, P-020),
/// "Gửi qua email thay thế", and cancelling the invite (G-033).
class _CantScanSheet extends ConsumerStatefulWidget {
  const _CantScanSheet({
    required this.args,
    required this.onRegenerated,
    required this.onEmail,
    required this.onRevoked,
  });

  final InviteSendArgs args;
  final ValueChanged<InviteTicket> onRegenerated;
  final VoidCallback onEmail;
  final VoidCallback onRevoked;

  @override
  ConsumerState<_CantScanSheet> createState() => _CantScanSheetState();
}

class _CantScanSheetState extends ConsumerState<_CantScanSheet> {
  late InviteTicket _ticket = widget.args.ticket;
  bool _busy = false;

  Future<void> _regenerate() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final ticket = await withClProgress(
        context,
        () => ref
            .read(familyRepositoryProvider)
            .regenerateInvite(_ticket.inviteId),
      );
      widget.onRegenerated(ticket);
      if (!mounted) return;
      setState(() => _ticket = ticket);
      showClToast(context, message: l10n.inviteNewCodeDone);
    } on FamilyException catch (e) {
      if (mounted) {
        showClToast(context, message: familyMessage(l10n, e.failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await withClProgress(
        context,
        () => ref.read(familyRepositoryProvider).revokeInvite(_ticket.inviteId),
      );
      navigator.pop();
      widget.onRevoked();
      toaster.show(message: l10n.inviteRevoked);
    } on FamilyException catch (e) {
      if (mounted) {
        showClToast(context, message: familyMessage(l10n, e.failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final relation = _draftRelation(l10n, widget.args.draft);
    final code = _ticket.code;
    final steps = [
      l10n.cantScanStep1,
      l10n.cantScanStep2('${code.substring(0, 3)} ${code.substring(3)}'),
      l10n.cantScanStep3,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.cantScanTitle(relation)),
        for (final (i, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cl.colors.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: cl.text.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(step, style: cl.text.body),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.cantScanNewCode,
          style: ClButtonStyle.secondary,
          expand: true,
          onPressed: _busy ? null : _regenerate,
        ),
        ClButton(
          label: l10n.cantScanByEmail,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onEmail();
          },
        ),
        ClButton(
          label: l10n.inviteRevoke,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: _busy ? null : _revoke,
        ),
      ],
    );
  }
}

/// 14d Mời · Đã gửi (117:12007).
class InviteSentScreen extends ConsumerWidget {
  const InviteSentScreen({required this.args, super.key});
  final InviteSendArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final relation = _draftRelation(l10n, args.draft);
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop()),
      content: [
        InviteCodeHero(label: relation),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.inviteSentTitle(relation),
          subtitle: args.email,
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.actionDone,
          expand: true,
          onPressed: () => context.go(Routes.family),
        ),
        ClButton(
          label: l10n.inviteNotReceived(relation),
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => showClSheet<void>(
            context: context,
            builder: (_) => _NotReceivedSheet(args: args),
          ),
        ),
      ],
    );
  }
}

/// "Bà không nhận được?" (G-055, not drawn): tips, resend, or share the link instead.
class _NotReceivedSheet extends ConsumerStatefulWidget {
  const _NotReceivedSheet({required this.args});
  final InviteSendArgs args;

  @override
  ConsumerState<_NotReceivedSheet> createState() => _NotReceivedSheetState();
}

class _NotReceivedSheetState extends ConsumerState<_NotReceivedSheet> {
  bool _busy = false;

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final email = widget.args.email;
    if (email == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(familyRepositoryProvider)
          .sendInviteEmail(
            inviteId: widget.args.ticket.inviteId,
            email: email,
            locale: Localizations.localeOf(context).languageCode,
          );
      if (mounted) showClToast(context, message: l10n.familyResent(email));
    } on FamilyException catch (e) {
      if (mounted) {
        showClToast(context, message: familyMessage(l10n, e.failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.notReceivedTitle),
        for (final tip in [
          l10n.notReceivedTip1,
          l10n.notReceivedTip2,
          l10n.notReceivedTip3,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClIcon(
                    ClIcons.check,
                    size: 18,
                    color: cl.colors.mintText,
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
                Expanded(child: Text(tip, style: cl.text.body)),
              ],
            ),
          ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.notReceivedResend,
          style: ClButtonStyle.secondary,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _resend,
        ),
        Builder(
          builder: (buttonContext) => ClButton(
            label: l10n.inviteShare,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => shareInvite(buttonContext, ref, widget.args),
          ),
        ),
      ],
    );
  }
}
