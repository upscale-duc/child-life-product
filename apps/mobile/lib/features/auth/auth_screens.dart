import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../onboarding/widgets/journey_hero.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'auth_repository.dart';
import 'email_link.dart';

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
      AuthFailure.linkExpired => l10n.linkExpiredBody,
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

/// "Tiếp tục với Apple" as drawn in Figma (Button style apple, 8:33): black pill with Apple's
/// logo (`assets/brands/apple.svg`) in place of the design's placeholder mark (brand-mark 22:197).
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
    // Apple's logo, tinted like the label (white button in Night care, black in Light).
    leading: SvgPicture.asset(
      'assets/brands/apple.svg',
      height: 20,
      colorFilter: ColorFilter.mode(
        context.cl.colors.appleButtonInk,
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
    ),
    expand: true,
    onPressed: onPressed,
    loading: loading,
  );
}

/// "Tiếp tục với Google" with Google's own "G" (brand guidelines) in place of the design's
/// placeholder mark (owner, 2026-10-13).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.onPressed,
    this.loading = false,
    super.key,
  });
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => ClButton(
    label: AppLocalizations.of(context).signInGoogle,
    style: ClButtonStyle.outline,
    leading: SvgPicture.asset(
      'assets/brands/google-g.svg',
      width: 20,
      height: 20,
      excludeFromSemantics: true,
    ),
    expand: true,
    onPressed: onPressed,
    loading: loading,
  );
}

/// 06 Chọn cách đăng nhập (27:488).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({this.returning = false, super.key});

  /// R1 "Chào mừng trở lại" (368:1266): this device has signed in before, so no onboarding
  /// and no Back (368:837).
  final bool returning;

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
    final returning = widget.returning;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: media.padding.top + ClSpace.s6),
              // v1.0 (368:1056 / 368:1266): the growth journey from 01, above the sheet and
              // scaled to the room left, so the sheet never covers it (owner, 2026-10-13).
              const Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: ClSpace.s3),
                    child: JourneyHero(),
                  ),
                ),
              ),
              Container(
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
                  // "Điều khoản · Quyền riêng tư" sits just above the home indicator.
                  media.padding.bottom > 0 ? media.padding.bottom : ClSpace.s4,
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
                      title: returning
                          ? l10n.welcomeBackTitle
                          : l10n.signInTitle,
                      subtitle: returning
                          ? l10n.welcomeBackBody
                          : l10n.signInSubtitle,
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
                    GoogleSignInButton(
                      onPressed: _busy
                          ? null
                          : () => _provider(
                              (r) => r.signInWithGoogle(),
                              via: 'google',
                            ),
                      loading: _busy && _via == 'google',
                    ),
                    const SizedBox(height: ClSpace.s3),
                    // Email: "Đăng nhập" and "Đăng ký" side by side (owner, 2026-10-13, D-067).
                    Row(
                      children: [
                        Expanded(
                          child: ClButton(
                            label: l10n.emailSignInTab,
                            style: ClButtonStyle.secondary,
                            expand: true,
                            onPressed: _busy
                                ? null
                                : () => context.push(
                                    '${Routes.email}?mode=${EmailMode.signIn.name}',
                                  ),
                          ),
                        ),
                        const SizedBox(width: ClSpace.s3),
                        Expanded(
                          child: ClButton(
                            label: l10n.signInRegister,
                            style: ClButtonStyle.secondary,
                            expand: true,
                            onPressed: _busy
                                ? null
                                : () => context.push(
                                    '${Routes.email}?mode=${EmailMode.create.name}',
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s3),
                    // Joining someone's baby starts from the code too (owner, 2026-10-11).
                    ClButton(
                      label: l10n.signInHaveCode,
                      style: ClButtonStyle.plain,
                      icon: ClIcons.family,
                      expand: true,
                      // `go`, not `push`: the guard reads the bottom of the stack, and over
                      // R1 "Vào ngay" / Apple / Google would send 16a back to 15 or to "Bạn là
                      // ai" (owner, 2026-10-12). Back from 15 returns here (leaveJoinFlow).
                      onPressed: _busy ? null : () => context.go(Routes.join),
                    ),
                    const SizedBox(height: ClSpace.s1),
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
            ],
          ),
          if (!returning)
            Positioned(
              top: media.padding.top + ClSpace.s2,
              left: ClSpace.s4,
              child: ClBackButton(
                semanticLabel: l10n.a11yBack,
                onPressed: () => context.pop(),
              ),
            ),
        ],
      ),
    );
  }
}

/// In the order of 07a (368:1139): "Đăng nhập" first.
enum EmailMode { signIn, create }

const _kEmailMode = 'auth.emailMode';

/// 07 Email: "Đăng nhập" / "Tài khoản mới"; opens on the segment chosen on 06 ("Đăng nhập" /
/// "Đăng ký"), else the last one (Segmented 9:124). "Đăng nhập" keeps the password with
/// "Đăng nhập" as the main action and "Gửi link đăng nhập" (D-064) as the second (owner,
/// 2026-10-13, D-067, instead of 07a's link first); "Tài khoản mới" creates an account with a
/// password (27:538).
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({this.mode, super.key});

  /// From 06; null = the last segment used.
  final EmailMode? mode;

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late EmailMode _mode;
  String? _error;
  bool _busy = false;

  /// "Gửi link đăng nhập" on its way.
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(sharedPreferencesProvider).getString(_kEmailMode);
    _mode =
        widget.mode ??
        (saved == EmailMode.create.name ? EmailMode.create : EmailMode.signIn);
    _email.addListener(_changed);
    _password.addListener(_changed);
  }

  /// The texts last seen: focusing a field moves its selection, which is not an edit.
  String _seen = '\u0000';

  void _changed() {
    final now = '${_email.text}\u0000${_password.text}';
    if (now == _seen) return setState(() {});
    _seen = now;
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      !_sending &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  final _emailFocus = FocusNode();

  /// "Gửi link đăng nhập": always there; only the email is needed, so an empty one is asked
  /// for (owner, 2026-10-13).
  void _link() {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _emailFocus.requestFocus();
      return setState(
        () => _error = AppLocalizations.of(context).emailLinkNeedsEmail,
      );
    }
    if (!looksLikeEmail(email)) {
      return setState(
        () => _error = AppLocalizations.of(context).authErrorInvalidEmail,
      );
    }
    unawaited(_sendLink(email));
  }

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

  /// 07a "Gửi link đăng nhập" → 07b.
  Future<void> _sendLink(String email) async {
    setState(() => _sending = true);
    try {
      await sendEmailSignInLink(
        ref,
        email,
        Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      unawaited(
        context.push(
          Uri(
            path: Routes.emailLinkSent,
            queryParameters: {'email': email},
          ).toString(),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = authMessage(AppLocalizations.of(context), e.failure),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
        ScreenHeading(title: create ? l10n.emailTitle : l10n.emailSignInTitle),
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
              focusNode: _emailFocus,
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
        // The link needs no password (D-064); "Đăng nhập" stays the main action (D-067).
        if (!create) ...[
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: l10n.emailLinkSend,
            style: ClButtonStyle.secondary,
            icon: ClIcons.mail,
            expand: true,
            onPressed: _busy || _sending ? null : _link,
            loading: _sending,
          ),
        ],
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
      await withClProgress(
        context,
        () => ref.read(authRepositoryProvider).sendVerificationEmail(),
      );
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
          ClAccountRow(email: email, provider: l10n.existsProvider),
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
        GoogleSignInButton(
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
