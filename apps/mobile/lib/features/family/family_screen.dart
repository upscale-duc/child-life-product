import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import 'family_labels.dart';
import 'family_models.dart';
import 'family_repository.dart';
import 'invite_screens.dart';

/// Copy for each server failure (G-001: Figma draws no error states).
String familyMessage(AppLocalizations l10n, FamilyFailure failure) =>
    switch (failure) {
      FamilyFailure.emailUnverified => l10n.inviteErrorUnverified,
      FamilyFailure.ownerOnly ||
      FamilyFailure.ownerProtected => l10n.inviteErrorOwnerOnly,
      FamilyFailure.tooSoon => l10n.inviteErrorTooSoon,
      FamilyFailure.tooManyEmails => l10n.inviteErrorTooMany,
      FamilyFailure.suppressed => l10n.inviteErrorSuppressed,
      FamilyFailure.expired ||
      FamilyFailure.revoked ||
      FamilyFailure.used => l10n.inviteErrorClosed,
      FamilyFailure.network => l10n.authErrorNetwork,
      _ => l10n.familyErrorGeneric,
    };

/// Can the caller open 14f for [target]? Cùng nuôi manage others; the owner is protected and
/// only the owner manages other Cùng nuôi (Q-013 → D-017).
bool canManage(Membership caller, Membership target) =>
    caller.role == MemberRole.coParent &&
    target.uid != caller.uid &&
    !target.isOwner &&
    (target.role != MemberRole.coParent || caller.isOwner);

/// 14a order: you, the owner, then Cùng nuôi → Người chăm sóc → Người thân, by join date.
List<Membership> sortMembers(List<Membership> members, String myUid) {
  int rank(Membership m) => m.uid == myUid
      ? 0
      : m.isOwner
      ? 1
      : 2 + m.role.index;
  return [...members]..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final aj = a.joinedAt ?? DateTime(2000);
    final bj = b.joinedAt ?? DateTime(2000);
    return aj.compareTo(bj);
  });
}

/// 14a Gia đình (116:11226): who cares for the selected baby (P-002), pending invites for
/// Cùng nuôi, and the invite entry. Caregivers and relatives get the list view-only (§5, G-030).
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final me = ref.watch(selectedMembershipProvider);
    if (session is! SessionSignedIn || me == null) {
      return ColoredBox(color: cl.colors.cloud);
    }
    final babyId = me.babyId;
    final baby = ref.watch(babyProvider(babyId)).value;
    final nickname = baby?.nickname ?? '';
    final members = ref.watch(familyMembersProvider(babyId));
    final isCoParent = me.role == MemberRole.coParent;
    final pending = isCoParent
        ? ref.watch(pendingInvitesProvider(babyId)).value ?? const []
        : const <PendingInvite>[];
    final fills = [
      cl.colors.peachSoft,
      cl.colors.mintSoft,
      cl.colors.sunshineSoft,
      cl.care.sleep.soft,
    ];

    // The baby header stays pinned while the day scrolls under it.
    return ClPinnedHeaderScaffold(
      header: const BabyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          0,
          ClSpace.s4,
          ClTabDock.contentBottomPadding + ClSpace.s6,
        ),
        children: [
          const SizedBox(height: ClSpace.s2),
          ClNavHeader(
            title: l10n.tabFamily,
            subtitle: l10n.familySubtitle(nickname),
          ),
          switch (members) {
            AsyncData(:final value) => ClCardGroup(
              shadow: true,
              children: [
                for (final (i, m) in sortMembers(
                  value,
                  session.user.uid,
                ).indexed)
                  ClMemberRow(
                    initial: initialOf(m.displayName),
                    name: m.displayName,
                    detail: memberDetail(l10n, m),
                    avatarFill: fills[i % fills.length],
                    status: m.uid == session.user.uid
                        ? ClMemberStatus.you
                        : ClMemberStatus.member,
                    youLabel: l10n.familyYou,
                    onTap: canManage(me, m)
                        ? () => showMemberSheet(
                            context,
                            babyId: babyId,
                            uid: m.uid,
                          )
                        : null,
                  ),
              ],
            ),
            AsyncError() => Padding(
              padding: const EdgeInsets.symmetric(vertical: ClSpace.s4),
              child: Text(
                l10n.familyLoadFailed,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            _ => const ClCardGroup(
              children: [
                Padding(
                  padding: EdgeInsets.all(ClSpace.s4),
                  child: ClSkeleton(height: 44),
                ),
              ],
            ),
          },
          if (pending.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s6),
            ClSectionHeader(title: l10n.familyPending(pending.length)),
            const SizedBox(height: ClSpace.s2),
            for (final invite in pending) ...[
              _PendingCard(
                invite: invite,
                babyId: babyId,
                inviterName: me.displayName,
                babyNickname: nickname,
              ),
              const SizedBox(height: ClSpace.s2),
            ],
          ],
          if (isCoParent) ...[
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: l10n.familyInvite,
              icon: ClIcons.plus,
              expand: true,
              onPressed: () => context.push(Routes.invite),
            ),
            const SizedBox(height: ClSpace.s3),
            Text(
              l10n.familyFootnote,
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Đang chờ nhận lời" row (R-035): email or relation, "Bà ngoại · hết hạn 15 thg 10", and
/// "Gửi lại". Tapping opens 14c again to re-share, make a new code or cancel (G-033).
class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard({
    required this.invite,
    required this.babyId,
    required this.inviterName,
    required this.babyNickname,
  });

  final PendingInvite invite;
  final String babyId;
  final String inviterName;
  final String babyNickname;

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;

  InviteSendArgs _args(InviteTicket ticket) => InviteSendArgs(
    babyId: widget.babyId,
    draft: widget.invite.draft,
    ticket: ticket,
    inviterName: widget.inviterName,
    babyNickname: widget.babyNickname,
    fromPending: true,
  );

  /// "Gửi lại": an expired invite gets a fresh code and 7 days first (business map §9).
  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(familyRepositoryProvider);
    final invite = widget.invite;
    setState(() => _busy = true);
    try {
      var ticket = invite.ticket;
      if (invite.isExpiredAt(DateTime.now())) {
        ticket = await repo.regenerateInvite(invite.inviteId);
      }
      final email = invite.recipientEmail;
      if (email == null) {
        if (mounted) {
          unawaited(context.push(Routes.inviteSend, extra: _args(ticket)));
        }
        return;
      }
      if (!mounted) return;
      await repo.sendInviteEmail(
        inviteId: invite.inviteId,
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
    final invite = widget.invite;
    final relation = relationLabel(
      l10n,
      invite.relation,
      invite.relationCustom ?? '',
    );
    final expired = invite.isExpiredAt(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(ClRadius.card),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClMemberRow(
            initial: '?',
            name: invite.recipientEmail ?? l10n.familyPendingNoEmail(relation),
            detail: expired
                ? l10n.familyPendingExpired(relation)
                : l10n.familyPendingDetail(
                    relation,
                    shortDate(context, invite.expiresAt),
                  ),
            status: ClMemberStatus.pending,
            resendLabel: l10n.familyResend,
            onResend: _busy ? null : _resend,
            onTap: () =>
                context.push(Routes.inviteSend, extra: _args(invite.ticket)),
          ),
          // "Thu hồi" right on the row (owner, 2026-10-11): the code and link stop working.
          Align(
            alignment: Alignment.centerRight,
            child: ClPressable(
              onPressed: _busy ? null : _revoke,
              semanticLabel: l10n.inviteRevoke,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  0,
                  ClSpace.s4,
                  ClSpace.s3,
                ),
                child: Text(
                  l10n.inviteRevoke,
                  style: cl.text.label.copyWith(
                    color: cl.colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    final who =
        widget.invite.recipientEmail ??
        relationLabel(
          l10n,
          widget.invite.relation,
          widget.invite.relationCustom ?? '',
        );
    final confirmed = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.familyRevokeTitle),
          Text(
            l10n.familyRevokeBody(who),
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.inviteRevoke,
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
    if (confirmed != true || !mounted) return;
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(familyRepositoryProvider)
          .revokeInvite(widget.invite.inviteId);
      toaster.show(message: l10n.inviteRevoked);
    } on FamilyException catch (e) {
      toaster.show(message: familyMessage(l10n, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// 14f Thành viên · Đổi quyền (118:12056): role, "Thời hạn", relation, remove. Changes apply
/// immediately (no Save button in Figma).
Future<void> showMemberSheet(
  BuildContext context, {
  required String babyId,
  required String uid,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _MemberSheet(babyId: babyId, uid: uid),
);

class _MemberSheet extends ConsumerStatefulWidget {
  const _MemberSheet({required this.babyId, required this.uid});
  final String babyId;
  final String uid;

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(FamilyRepository repo) action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action(ref.read(familyRepositoryProvider));
      if (mounted) showClToast(context, message: l10n.memberUpdated);
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
    final me = ref.watch(selectedMembershipProvider);
    final members = ref.watch(familyMembersProvider(widget.babyId)).value;
    final member = members?.where((m) => m.uid == widget.uid).firstOrNull;
    if (me == null || member == null) {
      // Removed meanwhile (or by someone else): nothing left to edit.
      return const SizedBox(height: 120);
    }
    final nickname =
        ref.watch(babyProvider(widget.babyId)).value?.nickname ?? '';
    final relation = memberRelation(l10n, member);
    final joined = member.joinedAt;

    Widget role(MemberRole r, String hint) => ClOptionRow(
      title: roleLabel(l10n, r),
      subtitle: r == MemberRole.coParent && !me.isOwner
          ? l10n.roleCoParentOwnerOnly
          : hint,
      selected: member.role == r,
      onTap: () {
        if (_busy || member.role == r) return;
        if (r == MemberRole.coParent && !me.isOwner) {
          showClToast(context, message: l10n.inviteErrorOwnerOnly);
          return;
        }
        _run(
          (repo) => repo.updateRole(
            babyId: widget.babyId,
            uid: member.uid,
            role: r,
            extraRights: r == MemberRole.relative ? member.extraRights : null,
          ),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: member.displayName),
        Text(
          joined == null
              ? relation
              : member.recordCount == null
              ? l10n.memberMeta(relation, shortDate(context, joined))
              : l10n.memberMetaCount(
                  relation,
                  shortDate(context, joined),
                  member.recordCount!,
                ),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.inviteRoleLabel,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          color: cl.colors.surface2,
          children: [
            role(MemberRole.coParent, l10n.roleCoParentHintFull),
            role(MemberRole.caregiver, l10n.roleCaregiverHintFull),
            role(MemberRole.relative, l10n.roleRelativeHintFull),
          ],
        ),
        // Not drawn on 14f: a relative's two extra views, as on 14b2 (open question 14f).
        if (member.role == MemberRole.relative) ...[
          const SizedBox(height: ClSpace.s3),
          ClSettingRow(
            icon: ClIcons.cake,
            title: l10n.rightBabyInfo,
            subtitle: l10n.rightBabyInfoHint,
            value: member.extraRights.viewBabyInfo,
            onChanged: _busy
                ? null
                : (v) => _run(
                    (repo) => repo.updateRole(
                      babyId: widget.babyId,
                      uid: member.uid,
                      role: MemberRole.relative,
                      extraRights: member.extraRights.copyWith(viewBabyInfo: v),
                    ),
                  ),
          ),
          const SizedBox(height: ClSpace.s2),
          ClSettingRow(
            icon: ClIcons.feed,
            title: l10n.rightDailyCare,
            subtitle: l10n.rightDailyCareHint,
            value: member.extraRights.viewDailyCare,
            onChanged: _busy
                ? null
                : (v) => _run(
                    (repo) => repo.updateRole(
                      babyId: widget.babyId,
                      uid: member.uid,
                      role: MemberRole.relative,
                      extraRights: member.extraRights.copyWith(
                        viewDailyCare: v,
                      ),
                    ),
                  ),
          ),
        ],
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            ClDetailRow(
              icon: ClIcons.clock,
              label: l10n.memberAccessUntil,
              value: member.accessUntil == null
                  ? l10n.memberAccessNoLimit
                  : l10n.memberAccessUntilValue(
                      longDate(context, member.accessUntil!),
                    ),
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showAccessUntilSheet(
                        context,
                        name: member.displayName,
                        current: member.accessUntil,
                      );
                      if (picked == null) return;
                      await _run(
                        (repo) => repo.setAccessUntil(
                          babyId: widget.babyId,
                          uid: member.uid,
                          lastDay: picked.$1,
                        ),
                      );
                    },
            ),
            ClDetailRow(
              icon: ClIcons.edit,
              label: l10n.memberRelation,
              value: relation,
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showRelationSheet(
                        context,
                        title: l10n.memberRelation,
                        options: [...selfRelations]
                          ..insert(selfRelations.length - 1, Relation.friend),
                        current: member.relation,
                        custom: member.relationCustom ?? '',
                      );
                      if (picked == null) return;
                      await _run(
                        (repo) => repo.updateRelation(
                          babyId: widget.babyId,
                          uid: member.uid,
                          relation: picked.$1,
                          relationCustom: picked.$2,
                        ),
                      );
                    },
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.memberRemove(member.displayName),
          style: ClButtonStyle.destructive,
          expand: true,
          onPressed: () => _confirmRemove(context, member, nickname),
          loading: _busy,
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.memberRecordsKept(member.displayName),
          textAlign: TextAlign.center,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }

  /// Removal confirmation (not drawn in Figma). Records are kept (R-023).
  Future<void> _confirmRemove(
    BuildContext context,
    Membership member,
    String nickname,
  ) async {
    final l10n = AppLocalizations.of(context);
    final sheetNavigator = Navigator.of(context);
    final confirmed = await showClSheet<bool>(
      context: context,
      builder: (confirmContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(
            title: l10n.memberRemoveConfirmTitle(member.displayName),
          ),
          Text(
            l10n.memberRemoveConfirmBody(member.displayName, nickname),
            style: confirmContext.cl.text.body.copyWith(
              color: confirmContext.cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            label: l10n.memberRemoveConfirm,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(confirmContext).pop(true),
          ),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(confirmContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(familyRepositoryProvider)
          .removeMember(babyId: widget.babyId, uid: member.uid);
      if (!mounted) return;
      final toaster = ClToaster.of(this.context);
      sheetNavigator.pop();
      toaster.show(message: l10n.memberRemoved(member.displayName));
    } on FamilyException catch (e) {
      if (mounted) {
        showClToast(this.context, message: familyMessage(l10n, e.failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// "Thời hạn" picker (not drawn): last day of access, or no limit. Returns (lastDay,) where
/// null means "Bỏ giới hạn"; null result = cancelled.
Future<(DateTime?,)?> showAccessUntilSheet(
  BuildContext context, {
  required String name,
  required DateTime? current,
}) {
  final today = DateUtils.dateOnly(DateTime.now());
  var picked = current != null && !current.isBefore(today)
      ? current
      : today.add(const Duration(days: 30));
  return showClSheet<(DateTime?,)>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final cl = sheetContext.cl;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.memberAccessUntil),
          Text(
            l10n.memberAccessHint(name),
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: cl.isNightCare ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: cl.text.title2.copyWith(
                    color: cl.colors.ink,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: today,
                maximumDate: today.add(const Duration(days: 365 * 5)),
                dateOrder:
                    Localizations.localeOf(sheetContext).languageCode == 'vi'
                    ? DatePickerDateOrder.dmy
                    : null,
                onDateTimeChanged: (d) => picked = DateUtils.dateOnly(d),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop((picked,)),
          ),
          if (current != null)
            ClButton(
              label: l10n.memberAccessClear,
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop((null,)),
            ),
        ],
      );
    },
  );
}

/// Relation chips + "Khác…" text (14f "Là ai với bé"). Returns (relation, custom).
Future<(Relation, String?)?> showRelationSheet(
  BuildContext context, {
  required String title,
  required List<Relation> options,
  required Relation current,
  required String custom,
}) => showClSheet<(Relation, String?)>(
  context: context,
  builder: (_) => _RelationSheet(
    title: title,
    options: options,
    current: current,
    custom: custom,
  ),
);

class _RelationSheet extends StatefulWidget {
  const _RelationSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.custom,
  });

  final String title;
  final List<Relation> options;
  final Relation current;
  final String custom;

  @override
  State<_RelationSheet> createState() => _RelationSheetState();
}

class _RelationSheetState extends State<_RelationSheet> {
  late Relation _relation = widget.current;
  late final _custom = TextEditingController(text: widget.custom)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  bool get _valid =>
      _relation != Relation.other || _custom.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: widget.title),
        RelationChips(
          options: widget.options,
          selected: _relation,
          onSelected: (r) => setState(() => _relation = r),
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
        ClButton(
          label: l10n.actionDone,
          expand: true,
          onPressed: _valid
              ? () => Navigator.of(context).pop((
                  _relation,
                  _relation == Relation.other ? _custom.text.trim() : null,
                ))
              : null,
        ),
      ],
    );
  }
}

/// Wrap of relation chips (10a / 14b / 16a), "Khác…" last.
class RelationChips extends StatelessWidget {
  const RelationChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<Relation> options;
  final Relation? selected;
  final ValueChanged<Relation> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: ClSpace.s2,
      runSpacing: ClSpace.s2,
      children: [
        for (final r in options)
          ClRelationChip(
            label: relationLabel(l10n, r),
            selected: selected == r,
            onTap: () => onSelected(r),
          ),
      ],
    );
  }
}
