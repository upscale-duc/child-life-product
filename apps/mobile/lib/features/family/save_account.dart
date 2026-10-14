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
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_screens.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'family_repository.dart';

/// P-007: the temporary identity already matches an account — sign into it, move the
/// memberships server-side, and keep routing still until the babies show up.
Future<void> mergeIntoExistingAccount(
  ProviderContainer container, {
  String? email,
  String? password,
}) async {
  final merging = container.read(accountMergeInProgressProvider.notifier)
    ..set(true);
  try {
    await container
        .read(authRepositoryProvider)
        .mergeAnonymousInto(
          email: email,
          password: password,
          claim: (token) =>
              container.read(familyRepositoryProvider).claimAnonymous(token),
        );
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(deadline)) {
      final session = container.read(sessionProvider);
      if (session is SessionSignedIn &&
          !session.isAnonymous &&
          session.hasBaby) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  } finally {
    merging.set(false);
  }
}

/// 16d Lưu tài khoản (123:12712): Apple / Google / email / "Để sau" (R-031).
Future<void> showSaveAccountSheet(BuildContext context, String babyNickname) =>
    showClSheet<void>(
      context: context,
      builder: (_) => _SaveAccountSheet(babyNickname: babyNickname),
    );

class _SaveAccountSheet extends ConsumerStatefulWidget {
  const _SaveAccountSheet({required this.babyNickname});
  final String babyNickname;

  @override
  ConsumerState<_SaveAccountSheet> createState() => _SaveAccountSheetState();
}

class _SaveAccountSheetState extends ConsumerState<_SaveAccountSheet> {
  bool _busy = false;

  /// Which provider button is saving, for its spinner (as on the sign-in screen).
  bool _apple = false;

  Future<void> _provider({required bool apple}) async {
    final l10n = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final navigator = Navigator.of(context);
    final toaster = ClToaster.of(context);
    setState(() {
      _busy = true;
      _apple = apple;
    });
    try {
      final linked = await ref
          .read(authRepositoryProvider)
          .saveAnonymousWithProvider(apple: apple);
      if (!linked) await mergeIntoExistingAccount(container);
      navigator.pop();
      toaster.show(
        message: linked ? l10n.saveAccountDone : l10n.saveAccountMerged,
      );
    } on AuthException catch (e) {
      if (mounted && e.failure != AuthFailure.cancelled) {
        showClToast(context, message: authMessage(l10n, e.failure));
      }
    } on FamilyException {
      if (mounted) showClToast(context, message: l10n.familyErrorGeneric);
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
        ClSheetHeader(title: l10n.saveAccountTitle),
        Text(
          l10n.saveAccountBody(widget.babyNickname),
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        AppleSignInButton(
          onPressed: _busy ? null : () => _provider(apple: true),
          loading: _busy && _apple,
        ),
        const SizedBox(height: ClSpace.s3),
        GoogleSignInButton(
          onPressed: _busy ? null : () => _provider(apple: false),
          loading: _busy && !_apple,
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.signInEmail,
          style: ClButtonStyle.secondary,
          icon: ClIcons.mail,
          expand: true,
          onPressed: _busy
              ? null
              : () {
                  Navigator.of(context).pop();
                  context.push(Routes.saveAccountEmail);
                },
        ),
        ClButton(
          label: l10n.actionLater,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// 16d "Dùng email" (not drawn): a new account keeps the same uid; an email that already has
/// an account signs in there and the memberships move over (Q-023 → P-007).
class SaveAccountEmailScreen extends ConsumerStatefulWidget {
  const SaveAccountEmailScreen({super.key});

  @override
  ConsumerState<SaveAccountEmailScreen> createState() =>
      _SaveAccountEmailScreenState();
}

class _SaveAccountEmailScreenState
    extends ConsumerState<SaveAccountEmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  EmailMode _mode = EmailMode.create;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_changed);
    _password.addListener(_changed);
  }

  void _changed() => setState(() => _error = null);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy && _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    if (!looksLikeEmail(email)) {
      return setState(() => _error = l10n.authErrorInvalidEmail);
    }
    if (_mode == EmailMode.create && password.length < 8) {
      return setState(() => _error = l10n.authErrorWeakPassword);
    }
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = ref.read(authRepositoryProvider)
      ..setLanguage(Localizations.localeOf(context).languageCode);
    setState(() => _busy = true);
    try {
      if (_mode == EmailMode.create) {
        await repo.saveAnonymousWithEmail(email, password);
      } else {
        await mergeIntoExistingAccount(
          container,
          email: email,
          password: password,
        );
      }
      if (!mounted) return;
      showClToast(
        context,
        message: _mode == EmailMode.create
            ? l10n.saveAccountDone
            : l10n.saveAccountMerged,
      );
      context.go(Routes.today);
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.failure == AuthFailure.emailInUse) {
        setState(() {
          _mode = EmailMode.signIn;
          _error = l10n.saveEmailExists;
        });
      } else {
        setState(() => _error = authMessage(l10n, e.failure));
      }
    } on FamilyException {
      if (mounted) setState(() => _error = l10n.familyErrorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final create = _mode == EmailMode.create;
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop()),
      content: [
        ScreenHeading(
          title: l10n.saveAccountTitle,
          subtitle: l10n.saveEmailSubtitle,
        ),
        const SizedBox(height: ClSpace.s6),
        ClSegmented<EmailMode>(
          options: EmailMode.values,
          selected: _mode,
          labelOf: (m) => m == EmailMode.create
              ? l10n.emailNewAccount
              : l10n.emailSignInTab,
          onChanged: (m) => setState(() {
            _mode = m;
            _error = null;
          }),
        ),
        const SizedBox(height: ClSpace.s4),
        ClCardGroup(
          shadow: true,
          children: [
            ClTextField(
              label: l10n.emailLabel,
              placeholder: l10n.emailPlaceholder,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            ClTextField(
              label: l10n.passwordLabel,
              placeholder: l10n.passwordPlaceholder,
              controller: _password,
              password: true,
              textInputAction: TextInputAction.done,
              autofillHints: [
                create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onSubmitted: (_) => _canSubmit ? _submit() : null,
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: ClSpace.s3),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: cl.text.label.copyWith(color: cl.colors.error),
            ),
          ),
        ],
      ],
      bottom: [
        ClButton(
          label: create ? l10n.saveAccountTitle : l10n.emailSignInButton,
          expand: true,
          onPressed: _canSubmit ? _submit : null,
          loading: _busy,
        ),
      ],
    );
  }
}
