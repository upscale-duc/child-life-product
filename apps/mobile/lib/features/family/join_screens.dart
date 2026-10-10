import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_status.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_screens.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'family_heroes.dart';
import 'family_labels.dart';
import 'family_models.dart';
import 'family_repository.dart';
import 'family_screen.dart';
import 'invite_screens.dart';

/// Hosts whose `/i/{token}` links are this environment's invites (plan §3.7).
Set<String> inviteHosts(WidgetRef ref) {
  final env = ref.read(environmentProvider);
  return {Uri.parse(env.webOrigin).host, env.siteHost};
}

/// A valid invite on its way through 16 → 16b → 16a.
class JoinArgs {
  const JoinArgs({required this.lookup, required this.preview});
  final InviteLookup lookup;
  final ValidInvite preview;
}

/// Leaves the join flow: a temporary identity that never joined is signed out (Q-024: "Không
/// phải tôi" just exits; the invite stays pending).
Future<void> leaveJoinFlow(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  if (session is SessionSignedIn && session.isAnonymous && !session.hasBaby) {
    await ref.read(authRepositoryProvider).signOut();
  }
  if (context.mounted) context.go(Routes.welcome);
}

/// 15 Nhập mã mời (30:1222): 6 digits or the in-app QR scanner (R-037, P-020, P-021).
class EnterCodeScreen extends ConsumerStatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  ConsumerState<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends ConsumerState<EnterCodeScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _lookup(InviteLookup lookup) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final preview = await ref
          .read(familyRepositoryProvider)
          .previewInvite(lookup);
      if (!mounted) return;
      switch (preview) {
        case ValidInvite():
          unawaited(
            context.push(
              Routes.joinInvite,
              extra: JoinArgs(lookup: lookup, preview: preview),
            ),
          );
        case ClosedInvite(reason: InviteClosedReason.notFound)
            when lookup.code != null:
          setState(() => _error = l10n.joinCodeWrong);
        case ClosedInvite(:final reason):
          unawaited(context.push('${Routes.joinClosed}?reason=${reason.name}'));
        case LockedInvite(:final retryAfter):
          setState(
            () => _error = l10n.joinLocked((retryAfter.inSeconds / 60).ceil()),
          );
      }
    } on FamilyException catch (e) {
      if (mounted) setState(() => _error = familyMessage(l10n, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final raw = await context.push<String>(Routes.joinScan);
    if (raw == null || !mounted) return;
    final lookup = InviteLookup.parse(raw, allowedHosts: inviteHosts(ref));
    if (lookup == null) {
      showClToast(context, message: l10n.scanNotInvite);
      return;
    }
    if (lookup.code != null) _code.text = lookup.code!;
    await _lookup(lookup);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final complete = _code.text.length == 6;
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () =>
            context.canPop() ? context.pop() : leaveJoinFlow(context, ref),
      ),
      content: [
        const InviteCodeHero(),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.joinCodeTitle,
          subtitle: l10n.joinCodeSubtitle,
        ),
        const SizedBox(height: ClSpace.s4),
        ClCodeInput(
          controller: _code,
          semanticLabel: l10n.a11yInviteCode,
          onCompleted: (code) =>
              _busy ? null : _lookup(InviteLookup.code(code)),
        ),
        if (_error != null) ...[
          const SizedBox(height: ClSpace.s3),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: cl.text.label.copyWith(color: cl.colors.error),
            ),
          ),
        ],
      ],
      bottom: [
        ClButton(
          label: l10n.actionContinue,
          expand: true,
          onPressed: complete && !_busy
              ? () => _lookup(InviteLookup.code(_code.text))
              : null,
        ),
        ClButton(
          label: l10n.joinScan,
          style: ClButtonStyle.plain,
          icon: ClIcons.camera,
          expand: true,
          onPressed: _busy ? null : _scan,
        ),
      ],
    );
  }
}

/// In-app QR scanner ("Quét mã QR"): returns the first code's raw text to 15.
class ScanInviteScreen extends StatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  State<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends State<ScanInviteScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final raw = capture.barcodes
                  .map((b) => b.rawValue)
                  .whereType<String>()
                  .firstOrNull;
              if (raw == null || _done) return;
              _done = true;
              context.pop(raw);
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ClSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.scanCameraDenied,
                      textAlign: TextAlign.center,
                      style: cl.text.body.copyWith(color: Colors.white),
                    ),
                    if (error.errorCode ==
                        MobileScannerErrorCode.permissionDenied) ...[
                      const SizedBox(height: ClSpace.s4),
                      ClButton(
                        label: l10n.actionOpenSettings,
                        style: ClButtonStyle.tinted,
                        onPressed: openAppSettings,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ClRadius.card),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(ClSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClBackButton(
                    semanticLabel: l10n.a11yBack,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ClSpace.s4,
                        vertical: ClSpace.s2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(ClRadius.pill),
                      ),
                      child: Text(
                        l10n.scanHint,
                        style: cl.text.label.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClSpace.s6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 16 Nhận lời mời (30:1259): countdown, who invites, the role and what it allows (R-036).
/// Also the target of invite links `/i/{token}` (QR, email, message).
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({required this.lookup, this.preview, super.key});

  final InviteLookup lookup;
  final ValidInvite? preview;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  ValidInvite? _preview;

  @override
  void initState() {
    super.initState();
    _preview = widget.preview;
    if (_preview == null) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final preview = await ref
          .read(familyRepositoryProvider)
          .previewInvite(widget.lookup);
      if (!mounted) return;
      switch (preview) {
        case ValidInvite():
          setState(() => _preview = preview);
        case ClosedInvite(:final reason):
          context.pushReplacement('${Routes.joinClosed}?reason=${reason.name}');
        case LockedInvite():
          context.pushReplacement(
            '${Routes.joinClosed}?reason=${InviteClosedReason.notFound.name}',
          );
      }
    } on FamilyException {
      if (mounted) {
        context.pushReplacement(
          '${Routes.joinClosed}?reason=${InviteClosedReason.notFound.name}',
        );
      }
    }
  }

  void _join(ValidInvite preview) {
    final l10n = AppLocalizations.of(context);
    if (preview.alreadyMember) {
      // G-036: friendly no-op.
      showClToast(
        context,
        message: l10n.joinAlreadyMember(preview.babyNickname),
      );
      context.go(Routes.today);
      return;
    }
    final args = JoinArgs(lookup: widget.lookup, preview: preview);
    if (ref.read(sessionProvider) is SessionSignedIn) {
      context.push(Routes.joinConfirm, extra: args);
    } else {
      showClSheet<void>(
        context: context,
        builder: (_) => _JoinHowSheet(args: args, host: context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final preview = _preview;
    void back() =>
        context.canPop() ? context.pop() : leaveJoinFlow(context, ref);
    if (preview == null) {
      return OnboardingScaffold(
        topBar: ClTopBar(onBack: back),
        content: const [
          ClSkeleton(height: 212, radius: ClRadius.hero),
          SizedBox(height: ClSpace.s6),
          ClSkeleton(height: 32, width: 220),
          SizedBox(height: ClSpace.s3),
          ClSkeleton(height: 20, width: 260),
        ],
      );
    }
    final hours = preview.expiresAt
        .difference(DateTime.now())
        .inMinutes
        .clamp(60, 1 << 30);
    final inviter =
        '${relationLabel(l10n, preview.inviterRelation, preview.inviterRelationCustom ?? '')} ${preview.inviterName}';
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: back,
        countdown: ClChip(
          label: l10n.joinCountdownHours((hours / 60).floor()),
          icon: ClIcons.clock,
        ),
      ),
      content: [
        InviteHero(initial: initialOf(preview.inviterName)),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.joinInviterTitle(inviter),
          subtitle: l10n.joinRoleLine(preview.babyNickname),
        ),
        const SizedBox(height: ClSpace.s2),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: ClSpace.s1,
            ),
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Text(
              roleLabel(l10n, preview.role),
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.mintText,
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        PermissionGrid(
          permissions: rolePermissions(l10n, preview.role, preview.extraRights),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.joinJoin,
          expand: true,
          onPressed: () => _join(preview),
        ),
        ClButton(
          label: l10n.joinNotMe,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => leaveJoinFlow(context, ref),
        ),
      ],
    );
  }
}

/// 16b Chọn cách vào (123:12571): "Vào ngay" as a temporary identity, or save with Apple /
/// Google now (no email here, as drawn — 16d offers it later).
class _JoinHowSheet extends ConsumerStatefulWidget {
  const _JoinHowSheet({required this.args, required this.host});
  final JoinArgs args;

  /// 16's context, which outlives this sheet.
  final BuildContext host;

  @override
  ConsumerState<_JoinHowSheet> createState() => _JoinHowSheetState();
}

class _JoinHowSheetState extends ConsumerState<_JoinHowSheet> {
  bool _busy = false;

  Future<void> _enter(Future<void> Function(AuthRepository repo) signIn) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await signIn(ref.read(authRepositoryProvider));
      navigator.pop();
      if (widget.host.mounted) {
        unawaited(widget.host.push(Routes.joinConfirm, extra: widget.args));
      }
    } on AuthException catch (e) {
      if (mounted && e.failure != AuthFailure.cancelled) {
        showClToast(context, message: authMessage(l10n, e.failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        MediaQuery.of(context).padding.bottom + ClSpace.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(
            title: l10n.joinHowTitle(widget.args.preview.babyNickname),
          ),
          Text(
            l10n.joinHowBody,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.joinNow,
            expand: true,
            onPressed: _busy
                ? null
                : () => _enter((r) => r.signInAnonymously()),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: cl.colors.separator)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                child: Text(
                  l10n.joinOrSave,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              Expanded(child: Container(height: 1, color: cl.colors.separator)),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          AppleSignInButton(
            onPressed: _busy ? null : () => _enter((r) => r.signInWithApple()),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: l10n.signInGoogle,
            style: ClButtonStyle.outline,
            icon: ClIcons.brandMark,
            expand: true,
            onPressed: _busy ? null : () => _enter((r) => r.signInWithGoogle()),
          ),
        ],
      ),
    );
  }
}

/// 16a Xác nhận vai trò (118:12227): name + relation; the role stays as invited (R-036).
class ConfirmJoinScreen extends ConsumerStatefulWidget {
  const ConfirmJoinScreen({required this.args, super.key});
  final JoinArgs args;

  @override
  ConsumerState<ConfirmJoinScreen> createState() => _ConfirmJoinScreenState();
}

class _ConfirmJoinScreenState extends ConsumerState<ConfirmJoinScreen> {
  late final TextEditingController _name;
  late final TextEditingController _custom;
  late Relation _relation = widget.args.preview.relation;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    final known = session is SessionSignedIn
        ? session.active.firstOrNull?.displayName
        : null;
    final provider = ref.read(providerDisplayNameProvider)?.trim() ?? '';
    _name = TextEditingController(
      text: known ?? (provider.isEmpty ? '' : provider.split(' ').last),
    )..addListener(() => setState(() {}));
    _custom = TextEditingController(
      text: widget.args.preview.relationCustom ?? '',
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _custom.dispose();
    super.dispose();
  }

  bool get _complete =>
      _name.text.trim().isNotEmpty &&
      (_relation != Relation.other || _custom.text.trim().isNotEmpty);

  Future<void> _accept() async {
    final l10n = AppLocalizations.of(context);
    final preview = widget.args.preview;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      final babyId = await ref
          .read(familyRepositoryProvider)
          .acceptInvite(
            lookup: widget.args.lookup,
            displayName: _name.text,
            relation: _relation,
            relationCustom: _custom.text,
          );
      await waitForMembership(container, babyId);
      container.read(selectedBabyIdProvider.notifier).select(babyId);
      if (mounted) context.go(Routes.today);
    } on FamilyException catch (e) {
      if (!mounted) return;
      switch (e.failure) {
        case FamilyFailure.alreadyMember:
          showClToast(
            context,
            message: l10n.joinAlreadyMember(preview.babyNickname),
          );
          context.go(Routes.today);
        case FamilyFailure.expired:
          context.go('${Routes.joinClosed}?reason=expired');
        case FamilyFailure.revoked:
          context.go('${Routes.joinClosed}?reason=revoked');
        case FamilyFailure.used:
          context.go('${Routes.joinClosed}?reason=used');
        case FamilyFailure.notFound:
          context.go('${Routes.joinClosed}?reason=notFound');
        default:
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
    final preview = widget.args.preview;
    final options = [
      ...selfRelations,
      if (preview.relation == Relation.friend) Relation.friend,
    ]..sort((a, b) => a.index.compareTo(b.index));
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop(), progress: 0.8),
      content: [
        ScreenHeading(
          title: l10n.joinConfirmTitle(preview.babyNickname),
          subtitle: l10n.joinConfirmSubtitle(
            preview.inviterName,
            relationLabel(l10n, preview.relation, preview.relationCustom ?? ''),
          ),
        ),
        const SizedBox(height: ClSpace.s6),
        ClTextField(
          label: l10n.whoNameLabel,
          placeholder: l10n.whoNamePlaceholder,
          controller: _name,
          standalone: true,
          textCapitalization: TextCapitalization.words,
          maxLength: displayNameMaxLength,
          autofillHints: const [AutofillHints.givenName],
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: ClSpace.s6),
        Text(
          l10n.whoYouAre,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        RelationChips(
          options: options,
          selected: _relation,
          onSelected: (r) => setState(() => _relation = r),
        ),
        if (_relation == Relation.other) ...[
          const SizedBox(height: ClSpace.s4),
          ClTextField(
            label: l10n.whoCustomLabel,
            placeholder: l10n.whoCustomPlaceholder,
            controller: _custom,
            standalone: true,
            textCapitalization: TextCapitalization.sentences,
            maxLength: relationCustomMaxLength,
          ),
        ],
      ],
      bottom: [
        ClButton(
          label: l10n.joinConfirmGo(preview.babyNickname),
          expand: true,
          onPressed: _complete && !_busy ? _accept : null,
        ),
      ],
    );
  }
}

/// 17 Lời mời hết hạn (30:1346) and the undrawn revoked / used / not-found states (G-035).
class InviteClosedScreen extends ConsumerWidget {
  const InviteClosedScreen({required this.reason, super.key});
  final InviteClosedReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (title, body) = switch (reason) {
      InviteClosedReason.expired => (
        l10n.joinExpiredTitle,
        l10n.joinExpiredBody,
      ),
      InviteClosedReason.revoked => (
        l10n.joinRevokedTitle,
        l10n.joinRevokedBody,
      ),
      InviteClosedReason.used => (l10n.joinUsedTitle, l10n.joinUsedBody),
      InviteClosedReason.notFound => (
        l10n.joinNotFoundTitle,
        l10n.joinNotFoundBody,
      ),
    };
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () =>
            context.canPop() ? context.pop() : leaveJoinFlow(context, ref),
      ),
      content: [
        const ExpiredHero(),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(title: title, subtitle: body),
      ],
      bottom: [
        ClButton(
          label: l10n.joinOtherCode,
          expand: true,
          onPressed: () => context.go(Routes.join),
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.joinBackToStart,
          style: ClButtonStyle.secondary,
          expand: true,
          onPressed: () => leaveJoinFlow(context, ref),
        ),
      ],
    );
  }
}

/// 9d Mất quyền truy cập (127:15135, R-025): access ended (removed, expired, downgraded out)
/// while this device knew the baby. Content is hidden; "Về trang chính" acknowledges it.
class LostAccessScreen extends ConsumerWidget {
  const LostAccessScreen({super.key});

  void _home(BuildContext context, WidgetRef ref) {
    final babyId = ref.read(lostAccessBabyIdProvider);
    if (babyId != null) {
      // P-006 (partial): drop what this device holds in memory for that baby.
      ref.read(babyRepositoryProvider).forgetBaby(babyId);
      ref.invalidate(babyProvider(babyId));
      ref.read(knownBabiesProvider.notifier).forget(babyId);
    }
    context.go(Routes.today);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => _home(context, ref)),
      content: [
        const ExpiredHero(),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.lostAccessTitle,
          subtitle: l10n.lostAccessBody,
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.lostAccessHome,
          expand: true,
          onPressed: () => _home(context, ref),
        ),
        const SizedBox(height: ClSpace.s3),
        Builder(
          builder: (buttonContext) => ClButton(
            label: l10n.lostAccessRequest,
            style: ClButtonStyle.secondary,
            expand: true,
            onPressed: () {
              final box = buttonContext.findRenderObject() as RenderBox?;
              SharePlus.instance.share(
                ShareParams(
                  text: l10n.lostAccessShareText,
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
