import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_status.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/widgets/heroes.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'auth_repository.dart';

/// Copy for each failure (G-001: Figma draws no error states; text is engineering-supplied).
String authMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure) {
      AuthFailure.invalidEmail => l10n.authErrorInvalidEmail,
      AuthFailure.weakPassword => l10n.authErrorWeakPassword,
      AuthFailure.wrongCredentials => l10n.authErrorWrongCredentials,
      AuthFailure.tooManyRequests => l10n.authErrorTooManyRequests,
      AuthFailure.network => l10n.authErrorNetwork,
      AuthFailure.notConfigured => l10n.authErrorNotConfigured,
      AuthFailure.disabled => l10n.authErrorDisabled,
      AuthFailure.linkFailed => l10n.authErrorLinkFailed,
      AuthFailure.emailInUse ||
      AuthFailure.cancelled ||
      AuthFailure.other => l10n.authErrorGeneric,
    };

bool looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

/// Runs a provider sign-in from 06 or 10, showing failures as a toast. Returns true on success.
Future<bool> _runProvider(
  BuildContext context,
  Future<void> Function() action,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    return true;
  } on AuthException catch (e) {
    if (e.failure == AuthFailure.emailInUse && context.mounted) {
      // A Google / Apple email that already has another sign-in method → 10.
      unawaited(context.push(Routes.exists));
    } else if (e.failure != AuthFailure.cancelled && context.mounted) {
      showClToast(context, message: authMessage(l10n, e.failure));
    }
    return false;
  }
}

/// "Tiếp tục với Apple" as drawn in Figma (Button style apple, 8:33): black pill with the
/// Apple logo in place of the design's placeholder mark (brand-mark 22:197).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    required this.onPressed,
    this.loading = false,
    super.key,
  });
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => ClButton(
    label: AppLocalizations.of(context).signInApple,
    style: ClButtonStyle.apple,
    leading: const Icon(Icons.apple),
    expand: true,
    onPressed: onPressed,
    loading: loading,
  );
}

/// 06 Chọn cách đăng nhập (27:488).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;

  /// Which provider button is signing in ('apple' / 'google'), for its spinner.
  String? _via;

  Future<void> _provider(
    Future<void> Function(AuthRepository) action, {
    required String via,
  }) async {
    setState(() {
      _busy = true;
      _via = via;
    });
    final repo = ref.read(authRepositoryProvider);
    await _runProvider(context, () => action(repo));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cardMint,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: SignInHero()),
          Positioned(
            top: media.padding.top + ClSpace.s2,
            left: ClSpace.s4,
            child: ClBackButton(
              semanticLabel: l10n.a11yBack,
              onPressed: () => context.pop(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ClRadius.sheet),
                ),
                boxShadow: cl.shadows.sheet,
              ),
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                media.padding.bottom + ClSpace.s4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cl.colors.separator,
                        borderRadius: BorderRadius.circular(ClRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClSpace.s6),
                  ScreenHeading(
                    title: l10n.signInTitle,
                    subtitle: l10n.signInSubtitle,
                    large: false,
                  ),
                  const SizedBox(height: ClSpace.s6),
                  AppleSignInButton(
                    onPressed: _busy
                        ? null
                        : () => _provider(
                            (r) => r.signInWithApple(),
                            via: 'apple',
                          ),
                    loading: _busy && _via == 'apple',
                  ),
                  const SizedBox(height: ClSpace.s3),
                  ClButton(
                    label: l10n.signInGoogle,
                    style: ClButtonStyle.outline,
                    icon: ClIcons.brandMark,
                    expand: true,
                    onPressed: _busy
                        ? null
                        : () => _provider(
                            (r) => r.signInWithGoogle(),
                            via: 'google',
                          ),
                    loading: _busy && _via == 'google',
                  ),
                  const SizedBox(height: ClSpace.s3),
                  ClButton(
                    label: l10n.signInEmail,
                    style: ClButtonStyle.secondary,
                    icon: ClIcons.mail,
                    expand: true,
                    onPressed: _busy ? null : () => context.push(Routes.email),
                  ),
                  const SizedBox(height: ClSpace.s4),
                  Center(
                    child: ClPressable(
                      semanticLabel: l10n.signInLegal,
                      onPressed: () => openLegal(
                        ref.read(environmentProvider),
                        Localizations.localeOf(context).languageCode,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(ClSpace.s2),
                        child: Text(
                          l10n.signInLegal,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.mintText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum EmailMode { create, signIn }

const _kEmailMode = 'auth.emailMode';

/// 07 Email (27:538): "Tài khoản mới" / "Đăng nhập"; remembers the last segment (Segmented 9:124).
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late EmailMode _mode;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(sharedPreferencesProvider).getString(_kEmailMode);
    _mode = saved == EmailMode.signIn.name
        ? EmailMode.signIn
        : EmailMode.create;
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
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider)
      ..setLanguage(Localizations.localeOf(context).languageCode);
    try {
      if (_mode == EmailMode.create) {
        await repo.signUpWithEmail(email, password);
      } else {
        await repo.signInWithEmail(email, password);
      }
      // The router moves on (08 after sign-up, setup or Today after sign-in).
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.failure == AuthFailure.emailInUse) {
        unawaited(context.push(Routes.exists));
      } else if (e.failure == AuthFailure.linkFailed) {
        showClToast(context, message: authMessage(l10n, e.failure));
      } else {
        setState(() => _error = authMessage(l10n, e.failure));
      }
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
        ScreenHeading(title: l10n.emailTitle),
        const SizedBox(height: ClSpace.s6),
        ClSegmented<EmailMode>(
          options: EmailMode.values,
          selected: _mode,
          labelOf: (m) => m == EmailMode.create
              ? l10n.emailNewAccount
              : l10n.emailSignInTab,
          onChanged: (m) {
            ref.read(sharedPreferencesProvider).setString(_kEmailMode, m.name);
            setState(() {
              _mode = m;
              _error = null;
            });
          },
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
        if (!create) ...[
          const SizedBox(height: ClSpace.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: l10n.emailForgot,
              style: ClButtonStyle.plain,
              onPressed: () => context.push(
                Uri(
                  path: Routes.forgot,
                  queryParameters: {'email': _email.text.trim()},
                ).toString(),
              ),
            ),
          ),
        ],
      ],
      bottom: [
        ClButton(
          label: create ? l10n.emailCreateAccount : l10n.emailSignInButton,
          expand: true,
          onPressed: _canSubmit ? _submit : null,
          loading: _busy,
        ),
        if (create)
          ClButton(
            label: l10n.emailUsedWithProvider,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => context.push(Routes.exists),
          ),
      ],
    );
  }
}

/// 08 Xác minh email (27:588). P-008: "Bỏ qua" lets the user continue unverified; Back signs out
/// to change the email ("Back is the only route"). Without universal links yet, verification is
/// detected when the app returns to the foreground and every few seconds while shown.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  static const _cooldown = 60;
  Timer? _poll;
  Timer? _tick;
  int _wait = _cooldown;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    _startCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _startCooldown() {
    _tick?.cancel();
    setState(() => _wait = _cooldown);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait -= 1);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _check() async {
    if (_verified) return;
    final repo = ref.read(authRepositoryProvider);
    if (await repo.reloadEmailVerified()) {
      _verified = true;
      _poll?.cancel();
      // Refresh the ID token so `email_verified` is current for the router and the backend.
      await repo.currentUser?.getIdToken(true);
      if (mounted) {
        showClToast(context, message: AppLocalizations.of(context).verifyDone);
      }
      ref.invalidate(authUserProvider);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(authRepositoryProvider).sendVerificationEmail();
      if (mounted) showClToast(context, message: l10n.verifyResent);
      _startCooldown();
    } on AuthException catch (e) {
      if (mounted) showClToast(context, message: authMessage(l10n, e.failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final email = ref.watch(authRepositoryProvider).currentUser?.email ?? '';
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () => ref.read(authRepositoryProvider).signOut(),
        onSkip: () {
          final uid = ref.read(authRepositoryProvider).currentUser?.uid;
          if (uid != null) ref.read(verifyDeferredProvider.notifier).defer(uid);
        },
      ),
      content: [
        const VerifyEmailHero(),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.verifyTitle,
          subtitle: l10n.verifyBody,
          large: false,
        ),
        const SizedBox(height: ClSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: ClChip(label: email),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.verifyLaterHint,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.verifyOpenMail,
          expand: true,
          onPressed: () async {
            if (!await openMailApp() && context.mounted) {
              showClToast(context, message: l10n.verifyNoMailApp);
            }
          },
        ),
        ClButton(
          label: _wait > 0 ? l10n.verifyResendIn(_wait) : l10n.verifyResend,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: _wait > 0 ? null : _resend,
        ),
      ],
    );
  }
}

/// 09 Quên mật khẩu (27:634).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.initialEmail = '', super.key});
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail)
    ..addListener(() => setState(() {}));
  String? _message;
  bool _isError = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      return setState(() {
        _message = l10n.authErrorInvalidEmail;
        _isError = true;
      });
    }
    setState(() => _busy = true);
    try {
      await (ref.read(authRepositoryProvider)
            ..setLanguage(Localizations.localeOf(context).languageCode))
          .sendPasswordReset(email);
      setState(() {
        _message = l10n.forgotSent;
        _isError = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _message = authMessage(l10n, e.failure);
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return OnboardingScaffold(
      topBar: ClTopBar(onBack: () => context.pop()),
      content: [
        const RecoverHero(),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.forgotTitle,
          subtitle: l10n.forgotBody,
          large: false,
        ),
        const SizedBox(height: ClSpace.s4),
        ClTextField(
          label: l10n.emailLabel,
          placeholder: l10n.emailPlaceholder,
          controller: _email,
          standalone: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _send(),
        ),
        if (_message != null) ...[
          const SizedBox(height: ClSpace.s3),
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              style: cl.text.label.copyWith(
                color: _isError ? cl.colors.error : cl.colors.mintText,
              ),
            ),
          ),
        ],
      ],
      bottom: [
        ClButton(
          label: l10n.forgotSend,
          expand: true,
          onPressed: _busy || _email.text.trim().isEmpty ? null : _send,
          loading: _busy,
        ),
      ],
    );
  }
}

/// 10 Email đã có tài khoản (27:673). With email privacy on, Firebase does not reveal which
/// provider owns the email, so both are offered; the typed password is linked after sign-in.
class AccountExistsScreen extends ConsumerStatefulWidget {
  const AccountExistsScreen({super.key});

  @override
  ConsumerState<AccountExistsScreen> createState() =>
      _AccountExistsScreenState();
}

class _AccountExistsScreenState extends ConsumerState<AccountExistsScreen> {
  bool _busy = false;

  /// Which provider button is signing in ('apple' / 'google'), for its spinner.
  String? _via;

  Future<void> _provider(
    Future<void> Function(AuthRepository) action, {
    required String via,
  }) async {
    setState(() {
      _busy = true;
      _via = via;
    });
    final repo = ref.read(authRepositoryProvider);
    final linking = repo.pendingEmail != null;
    final ok = await _runProvider(context, () => action(repo));
    if (ok && linking && mounted) {
      showClToast(context, message: AppLocalizations.of(context).existsLinked);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.watch(authRepositoryProvider);
    final email = repo.pendingEmail;
    return OnboardingScaffold(
      topBar: ClTopBar(
        onBack: () {
          repo.clearPendingLink();
          context.pop();
        },
      ),
      content: [
        const AccountLinkHero(),
        const SizedBox(height: ClSpace.s6),
        ScreenHeading(
          title: l10n.existsTitle,
          subtitle: l10n.existsBody,
          large: false,
        ),
        if (email != null) ...[
          const SizedBox(height: ClSpace.s4),
          ClAccountRow(
            email: email,
            provider: l10n.existsProvider,
          ),
        ],
      ],
      bottom: [
        AppleSignInButton(
          onPressed: _busy
              ? null
              : () => _provider((r) => r.signInWithApple(), via: 'apple'),
          loading: _busy && _via == 'apple',
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.signInGoogle,
          style: ClButtonStyle.outline,
          icon: ClIcons.brandMark,
          expand: true,
          onPressed: _busy
              ? null
              : () => _provider((r) => r.signInWithGoogle(), via: 'google'),
          loading: _busy && _via == 'google',
        ),
        ClButton(
          label: l10n.existsUseOtherEmail,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () {
            repo.clearPendingLink();
            context.pop();
          },
        ),
      ],
    );
  }
}
