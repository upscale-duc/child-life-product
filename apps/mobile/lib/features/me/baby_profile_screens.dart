import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/navigation.dart' show SafePushContext;
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../family/my_invites.dart' show MyInviteRows;
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../baby/time_zones.dart';
import '../care/care_repository.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_draft.dart';
import '../onboarding/setup_screens.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'me_models.dart';
import 'me_repository.dart';
import 'me_widgets.dart';

DateTime _today(WidgetRef ref) {
  final n = ref.read(timerClockProvider)();
  return DateTime(n.year, n.month, n.day);
}

int _activeMembers(WidgetRef ref, String babyId) => [
  for (final m in ref.watch(familyMembersProvider(babyId)).value ?? const [])
    if (m.isActive) m,
].length;

/// 13i "Hồ sơ các bé": my babies with age and carers, "Thêm bé · n/3" (R-043).
class BabyProfilesScreen extends ConsumerWidget {
  const BabyProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final me = ref.watch(selectedMembershipProvider);
    if (session is! SessionSignedIn || me == null) {
      return ColoredBox(color: cl.colors.cloud);
    }
    final mine = [
      for (final m in session.active)
        if (m.role == me.role) m,
    ];
    final owned = session.active.where((m) => m.isOwner).length;
    final parent = me.role == MemberRole.coParent;
    final soft = babySoftTints(context);
    return MePage(
      title: switch (me.role) {
        MemberRole.coParent => l10n.meBabies,
        MemberRole.caregiver => l10n.meAssigned,
        MemberRole.relative => l10n.meFollowing,
      },
      children: [
        // Invites mailed to me (owner, 2026-10-11): answered from here too.
        const MyInviteRows(padding: EdgeInsets.only(bottom: ClSpace.s4)),
        for (final (i, m) in mine.indexed) ...[
          _BabyCard(membership: m, tint: soft[i % soft.length]),
          const SizedBox(height: ClSpace.s3),
        ],
        if (parent && !session.isAnonymous) ...[
          ClPressable(
            onPressed: owned < maxOwnedBabies
                ? () => startAddingBaby(context, ref)
                : null,
            semanticLabel: '${l10n.bpAdd} $owned/$maxOwnedBabies',
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ClRadius.card - 6),
                border: Border.all(color: cl.colors.separator, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClIcon(ClIcons.plus, size: 20, color: cl.colors.mintText),
                  const SizedBox(width: ClSpace.s2),
                  Text(
                    l10n.bpAdd,
                    style: cl.text.bodyStrong.copyWith(
                      color: cl.colors.mintText,
                    ),
                  ),
                  Text(
                    ' · $owned/$maxOwnedBabies',
                    style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Text(
            l10n.createBabyLimit,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
        // Already have a profile and invited to another baby (owner, 2026-10-11).
        ClPressable(
          key: const Key('profileJoin'),
          onPressed: () => unawaited(context.push(Routes.join)),
          semanticLabel: l10n.joinFromProfile,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ClRadius.card - 6),
              border: Border.all(color: cl.colors.separator, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClIcon(ClIcons.link, size: 20, color: cl.colors.mintText),
                const SizedBox(width: ClSpace.s2),
                Text(
                  l10n.joinFromProfile,
                  style: cl.text.bodyStrong.copyWith(color: cl.colors.mintText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.joinFromProfileHint,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

class _BabyCard extends ConsumerWidget {
  const _BabyCard({required this.membership, required this.tint});
  final Membership membership;
  final Color tint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final baby = ref.watch(babyProvider(membership.babyId)).value;
    if (baby == null) return const SizedBox.shrink();
    final profile = membership.role == MemberRole.caregiver
        ? null
        : ref.watch(babyPrivateProfileProvider(baby.id)).value;
    final carers = _activeMembers(ref, baby.id);
    final age = profile == null
        ? null
        : ageLong(l10n, profile.dateOfBirth, _today(ref));
    final job = baby.deleting && membership.isOwner
        ? ref.watch(deletionJobProvider('del_${baby.id}')).value
        : null;
    final subtitle = baby.deleting
        ? (job?.failed == true ? l10n.bpDelRetrying : l10n.bpDeleting)
        : age == null
        ? null
        : l10n.bpCarers(age, carers);
    return ClCardGroup(
      shadow: true,
      children: [
        MeRow(
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: SavedBabyAvatar(baby: baby, size: 48),
          ),
          title: baby.nickname,
          subtitle: subtitle,
          onTap: baby.deleting
              ? null
              : () => context.push('${Routes.meBabies}/${baby.id}'),
        ),
      ],
    );
  }
}

/// 13j "Hồ sơ bé": age, latest growth, details, family, growth, storage, delete (owner).
class BabyProfileViewScreen extends ConsumerWidget {
  const BabyProfileViewScreen({required this.babyId, super.key});
  final String babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final session = ref.watch(sessionProvider);
    final mine = session is SessionSignedIn
        ? session.membershipFor(babyId)
        : null;
    final baby = ref.watch(babyProvider(babyId)).value;
    if (mine == null || baby == null) return ColoredBox(color: cl.colors.cloud);
    final parent = mine.role == MemberRole.coParent;
    final seesInfo =
        parent ||
        (mine.role == MemberRole.relative && mine.extraRights.viewBabyInfo);
    final profile = seesInfo
        ? ref.watch(babyPrivateProfileProvider(babyId)).value
        : null;
    final members = [
      for (final m
          in ref.watch(familyMembersProvider(babyId)).value ?? const [])
        if (m.isActive) m,
    ];
    final owner = members.where((m) => m.isOwner).firstOrNull;
    final growth = parent || mine.role == MemberRole.caregiver
        ? ref.watch(growthRecordsProvider(babyId)).value ?? const []
        : const [];
    final weight = growth.where((g) => g.weightKg != null).firstOrNull;
    final length = growth.where((g) => g.lengthCm != null).firstOrNull;
    // Owner 2026-10-16: the latest head circumference, when one was measured.
    final head = growth.where((g) => g.headCm != null).firstOrNull;
    final storage = parent
        ? ref.watch(familyStorageProvider(babyId)).value
        : null;
    final usage = storage?.babies.where((b) => b.babyId == babyId).firstOrNull;
    final date = (locale.startsWith('vi')
        ? DateFormat.yMMMMd(locale)
        : DateFormat.yMMMd(locale));
    String when(DateTime at) {
      final d = DateTime(at.year, at.month, at.day);
      return d == _today(ref)
          ? l10n.dayToday
          : DateFormat.MMMd(locale).format(at);
    }

    String number(double v) => NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    ).format(v).replaceAll(RegExp(r'[.,]0$'), '');

    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            ClTabDock.contentBottomPadding,
          ),
          children: [
            ClTopBar(
              onBack: () => context.pop(),
              trailing: parent
                  ? MeRowAction(
                      label: l10n.actionEdit,
                      onPressed: () =>
                          context.push('${Routes.babyEdit}/$babyId'),
                    )
                  : null,
            ),
            const SizedBox(height: ClSpace.s2),
            Center(
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: cl.colors.mintSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SavedBabyAvatar(baby: baby, size: 100),
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            Semantics(
              header: true,
              child: Text(
                baby.nickname,
                textAlign: TextAlign.center,
                style: cl.text.largeTitle.copyWith(fontSize: 28),
              ),
            ),
            if (profile != null)
              Text(
                l10n.bpBorn(
                  ageLong(l10n, profile.dateOfBirth, _today(ref)),
                  date.format(profile.dateOfBirth),
                ),
                textAlign: TextAlign.center,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            if (weight != null || length != null || head != null) ...[
              const SizedBox(height: ClSpace.s4),
              Row(
                children: [
                  for (final (i, tile) in [
                    if (weight != null)
                      _StatCard(
                        value: '${number(weight.weightKg!)} kg',
                        label: l10n.bpWeight(when(weight.occurredAt)),
                        color: cl.colors.peachSoft,
                      ),
                    if (length != null)
                      _StatCard(
                        value: '${number(length.lengthCm!)} cm',
                        label: l10n.bpLength(when(length.occurredAt)),
                        color: cl.colors.sunshineSoft,
                      ),
                    if (head != null)
                      _StatCard(
                        value: '${number(head.headCm!)} cm',
                        label: l10n.bpHead(when(head.occurredAt)),
                        color: cl.colors.mintSoft,
                      ),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: ClSpace.s3),
                    Expanded(child: tile),
                  ],
                ],
              ),
            ],
            if (profile != null) ...[
              MeSection(l10n.bpInfo),
              ClCardGroup(
                children: [
                  MeRow(
                    icon: ClIcons.cake,
                    title: l10n.babyDob,
                    value: DateFormat.yMMMd(locale).format(profile.dateOfBirth),
                  ),
                  MeRow(
                    icon: ClIcons.star,
                    title: l10n.babyGender,
                    value: switch (profile.gender) {
                      Gender.girl => l10n.genderGirl,
                      Gender.boy => l10n.genderBoy,
                      Gender.unspecified => l10n.genderUnspecified,
                    },
                  ),
                  MeRow(
                    icon: ClIcons.globe,
                    title: l10n.babyTimeZone,
                    value: gmtOffsetLabel(baby.timeZone.zone, DateTime.now()),
                  ),
                ],
              ),
            ],
            MeSection(l10n.bpOf),
            ClCardGroup(
              children: [
                MeRow(
                  icon: ClIcons.family,
                  title: l10n.bpFamily(baby.nickname),
                  subtitle: members.map((m) => m.displayName).join(', '),
                  value: '${members.length}',
                  onTap: () {
                    ref.read(selectedBabyIdProvider.notifier).select(babyId);
                    context.go(Routes.family);
                  },
                ),
                if (parent || mine.role == MemberRole.caregiver)
                  MeRow(
                    icon: ClIcons.ruler,
                    // D-117: title only, like the Chăm sóc row.
                    title: l10n.trackerGrowth,
                    onTap: () {
                      ref.read(selectedBabyIdProvider.notifier).select(babyId);
                      // D-076 nav: 13l is above the tabs; Lịch sử is a Chăm sóc page.
                      context.pushSafe('${Routes.history}?filter=growth');
                    },
                  ),
                if (parent && storage != null)
                  MeRow(
                    icon: ClIcons.cloudOff,
                    title: l10n.bpStorage(baby.nickname),
                    subtitle: l10n.bpStorageHint(
                      formatBytes(storage.quotaBytes, locale),
                    ),
                    value: formatBytes(usage?.bytes ?? 0, locale),
                    onTap: () => context.push(Routes.meStorage),
                  ),
              ],
            ),
            if (parent) ...[
              const SizedBox(height: ClSpace.s4),
              MeNotice(
                tone: MeTone.error,
                title: l10n.bpDelete(baby.nickname),
                body: l10n.bpDeleteOwner(owner?.displayName ?? ''),
                onTap: mine.isOwner
                    ? () => showDeleteBabySheet(
                        context,
                        baby: baby,
                        bytes: usage?.bytes ?? 0,
                        members: members.length,
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(ClRadius.card - 6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: cl.text.title.copyWith(color: cl.colors.ink)),
            Text(
              label,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 13k "Sửa hồ sơ bé": the create form (11), filled from the profile; "Lưu thay đổi".
class BabyEditScreen extends ConsumerStatefulWidget {
  const BabyEditScreen({required this.babyId, super.key});
  final String babyId;

  @override
  ConsumerState<BabyEditScreen> createState() => _BabyEditScreenState();
}

class _BabyEditScreenState extends ConsumerState<BabyEditScreen> {
  late final TextEditingController _nickname;
  final _focus = FocusNode();
  Baby? _baby;
  BabyPrivateProfile? _profile;
  var _busy = false;
  var _prefilled = false;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController()
      ..addListener(() {
        final d = ref.read(setupDraftProvider);
        if (d.nickname == _nickname.text) return;
        ref
            .read(setupDraftProvider.notifier)
            .update(d.copyWith(nickname: _nickname.text));
      });
  }

  /// The shared form reads the setup draft: start it from the saved profile.
  void _prefill(Baby baby, BabyPrivateProfile profile) {
    if (!mounted) return;
    _baby = baby;
    _profile = profile;
    ref
        .read(setupDraftProvider.notifier)
        .update(
          SetupDraft(
            nickname: baby.nickname,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender,
            timeZone: baby.timeZone,
            avatarPreset: switch (baby.avatar) {
              PresetAvatar(:final preset) => preset,
              _ => 1,
            },
          ),
        );
    _nickname.text = baby.nickname;
    setState(() {});
  }

  @override
  void dispose() {
    _nickname.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(setupDraftProvider);
    if (draft.nickname.trim().isEmpty) {
      _focus.requestFocus();
      showClToast(context, message: l10n.babyNicknameRequired);
      return;
    }
    final baby = _baby;
    final change = <String, Object?>{
      if (draft.nickname.trim() != baby?.nickname)
        'nickname': draft.nickname.trim(),
      if (_profile == null || draft.dateOfBirth != _profile!.dateOfBirth)
        'dateOfBirth': isoDate(draft.dateOfBirth),
      if (draft.gender != _profile?.gender) 'gender': draft.gender.name,
      if (draft.timeZone != null &&
          (draft.timeZone!.zone != baby?.timeZone.zone ||
              draft.timeZone!.auto != baby?.timeZone.auto))
        'timeZone': draft.timeZone!.toJson(),
    };
    final presetChanged = switch (baby?.avatar) {
      PresetAvatar(:final preset) => preset != draft.avatarPreset,
      _ => draft.avatarPhoto == null,
    };
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      if (change.isNotEmpty) {
        await ref.read(meRepositoryProvider).updateBaby(widget.babyId, change);
      }
      final babies = ref.read(babyRepositoryProvider);
      if (draft.avatarPhoto != null) {
        await babies.setAvatarPhoto(widget.babyId, draft.avatarPhoto!);
      } else if (presetChanged) {
        await babies.setAvatarPreset(widget.babyId, draft.avatarPreset);
      }
      ref.read(setupDraftProvider.notifier).reset();
      toaster.show(message: l10n.bpSaved);
      router.pop();
    } on AccountActionException catch (e) {
      toaster.show(
        message: e.reason == 'dob-in-future'
            ? l10n.createBabyDobFuture
            : l10n.toastSaveFailed,
      );
    } on Object {
      toaster.show(message: l10n.toastSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final baby = ref.watch(babyProvider(widget.babyId)).value;
    final profile = ref.watch(babyPrivateProfileProvider(widget.babyId)).value;
    if (!_prefilled && baby != null && profile != null) {
      _prefilled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _prefill(baby, profile),
      );
    }
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () {
          ref.read(setupDraftProvider.notifier).reset();
          context.pop();
        },
      ),
      content: babyFormFields(context, ref, nickname: _nickname, focus: _focus),
      bottom: [
        ClButton(
          label: l10n.bpSave,
          expand: true,
          onPressed: _save,
          loading: _busy,
        ),
      ],
    );
  }
}

/// 13l "Xoá hồ sơ Teddy?": type the nickname, "Xoá vĩnh viễn" (owner only, R-045).
Future<void> showDeleteBabySheet(
  BuildContext context, {
  required Baby baby,
  required int bytes,
  required int members,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _DeleteBabySheet(baby: baby, bytes: bytes, members: members),
);

class _DeleteBabySheet extends ConsumerStatefulWidget {
  const _DeleteBabySheet({
    required this.baby,
    required this.bytes,
    required this.members,
  });
  final Baby baby;
  final int bytes;
  final int members;

  @override
  ConsumerState<_DeleteBabySheet> createState() => _DeleteBabySheetState();
}

class _DeleteBabySheetState extends ConsumerState<_DeleteBabySheet> {
  final _typed = TextEditingController();
  var _busy = false;

  bool get _matches =>
      _typed.text.trim().toLowerCase() ==
      widget.baby.nickname.trim().toLowerCase();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(meRepositoryProvider)
          .deleteBaby(widget.baby.id, _typed.text.trim());
      navigator.pop();
      toaster.show(message: l10n.bpDelStarted(widget.baby.nickname));
      // Another baby becomes the selected one; the list shows "Đang xoá…" until verified.
      final session = ref.read(sessionProvider);
      if (session is SessionSignedIn) {
        final other = session.active
            .where((m) => m.babyId != widget.baby.id)
            .firstOrNull;
        if (other != null) {
          ref.read(selectedBabyIdProvider.notifier).select(other.babyId);
        }
      }
      router.go(Routes.meBabies);
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = widget.baby.nickname;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.bpDelTitle(name), style: cl.text.title),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.bpDelBody(name),
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        MeNotice(
          title: l10n.bpDelFree(
            formatBytes(widget.bytes, locale),
            widget.members,
          ),
          body: l10n.bpDelTip,
        ),
        const SizedBox(height: ClSpace.s4),
        Text(l10n.bpDelType(name), style: cl.text.bodyStrong),
        const SizedBox(height: ClSpace.s2),
        ClTextField(
          controller: _typed,
          standalone: true,
          placeholder: name,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.bpDelConfirm,
          style: ClButtonStyle.destructive,
          expand: true,
          onPressed: _busy || !_matches ? null : _delete,
          loading: _busy,
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.actionCancel,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Toasts "Đã xoá hồ sơ Teddy" when the owner's purge is verified (flow F: never early).
class DeletionWatcher extends ConsumerStatefulWidget {
  const DeletionWatcher({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<DeletionWatcher> createState() => _DeletionWatcherState();
}

class _DeletionWatcherState extends ConsumerState<DeletionWatcher> {
  final _names = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session is SessionSignedIn) {
      for (final m in session.active.where((m) => m.isOwner)) {
        final baby = ref.watch(babyProvider(m.babyId)).value;
        if (baby?.deleting != true) continue;
        _names[baby!.id] = baby.nickname;
      }
      for (final id in _names.keys.toList()) {
        ref.listen(deletionJobProvider('del_$id'), (_, next) {
          if (next.value?.done == true && _names.containsKey(id)) {
            final name = _names.remove(id)!;
            final l10n = AppLocalizations.of(context);
            unawaited(
              Future.microtask(() {
                // Above the navigator: toast through the router's own context.
                final nav = ref
                    .read(routerProvider)
                    .routerDelegate
                    .navigatorKey
                    .currentState
                    ?.overlay
                    ?.context;
                if (nav != null && nav.mounted) {
                  showClToast(nav, message: l10n.bpDelDone(name));
                }
              }),
            );
          }
        });
      }
    }
    return widget.child;
  }
}
