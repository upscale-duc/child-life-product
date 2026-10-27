import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'auth_repository.dart';
import 'auth_screens.dart';

/// The address a sign-in link went to, kept on this phone until the link is opened (07b "trên
/// điện thoại này", D-064): Firebase needs it again to finish signing in. Removed once used.
class EmailLinkStore {
  EmailLinkStore(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'auth.linkEmail';

  String? get email => _prefs.getString(_key);
  Future<void> save(String email) => _prefs.setString(_key, email);
  Future<void> clear() => _prefs.remove(_key);
}

final emailLinkStoreProvider = Provider<EmailLinkStore>(
  (ref) => EmailLinkStore(ref.watch(sharedPreferencesProvider)),
);

/// Sends the link and remembers the address on this phone (07a, 07b "Gửi lại").
Future<void> sendEmailSignInLink(
  WidgetRef ref,
  String email,
  String languageCode,
) async {
  await (ref.read(
    authRepositoryProvider,
  )..setLanguage(languageCode)).sendSignInLink(email);
  await ref.read(emailLinkStoreProvider).save(email);
}

/// "Gửi lại sau 0:45" (368:1211).
String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// 07b Kiểm tra email của bạn (368:1184). The link opens the app on `/auth/link/`
/// ([EmailLinkScreen]); Back and "Đổi email" return to 07a.
class EmailLinkSentScreen extends ConsumerStatefulWidget {
  const EmailLinkSentScreen({required this.email, super.key});
  final String email;

  @override
  ConsumerState<EmailLinkSentScreen> createState() =>
      _EmailLinkSentScreenState();
}

class _EmailLinkSentScreenState extends ConsumerState<EmailLinkSentScreen> {
  /// One mail a minute per address on the server (authMailLimits).
  static const _cooldown = 60;
  Timer? _tick;
  int _wait = _cooldown;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _tick?.cancel();
    _wait = _cooldown;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait -= 1);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await sendEmailSignInLink(
        ref,
        widget.email,
        Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      showClToast(context, message: l10n.linkSentResent);
      setState(_startCooldown);
    } on AuthException catch (e) {
      if (mounted) showClToast(context, message: authMessage(l10n, e.failure));
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
        const SizedBox(height: ClSpace.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: ClIcon(ClIcons.mail, size: 40, color: cl.colors.mintDeep),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ScreenHeading(
          title: l10n.linkSentTitle,
          subtitle: l10n.linkSentBody(widget.email),
          large: false,
        ),
        const SizedBox(height: ClSpace.s4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: ClSpace.s3,
          ),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: ClIcon(
                  ClIcons.alert,
                  size: 16,
                  color: cl.colors.inkMuted,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.linkSentSpam,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: [
        ClButton(
          label: l10n.linkSentOpenMail,
          expand: true,
          onPressed: () async {
            if (!await openMailApp() && context.mounted) {
              showClToast(context, message: l10n.verifyNoMailApp);
            }
          },
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: _wait > 0
              ? l10n.linkSentResendIn(_clock(_wait))
              : l10n.linkSentResend,
          style: ClButtonStyle.secondary,
          expand: true,
          loading: _busy,
          onPressed: _wait > 0 || _busy ? null : _resend,
        ),
        ClButton(
          label: l10n.linkSentChangeEmail,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

enum _LinkPhase { signingIn, needEmail, expired, failed }

/// How long signing in with the link may take before "Thử lại" is offered (AU-6).
const _signInTimeout = Duration(seconds: 20);

/// The email sign-in link opened in the app (`/auth/link/?mode=signIn&oobCode=…&exp=…`,
/// D-064). Signs in with the address kept on this phone; without it (another phone, or the app
/// reinstalled) the person types it. The router moves on once signed in (setup or Hôm nay).
/// Not drawn in Figma (G-001).
class EmailLinkScreen extends ConsumerStatefulWidget {
  const EmailLinkScreen({required this.link, super.key});

  /// The full link, on the website's origin.
  final Uri link;

  @override
  ConsumerState<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends ConsumerState<EmailLinkScreen> {
  final _email = TextEditingController();
  var _phase = _LinkPhase.signingIn;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() => _error = null));
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// 07b "trong 15 phút": the server's `exp`; Firebase's own expiry applies after it.
  bool get _expired {
    final exp = int.tryParse(widget.link.queryParameters['exp'] ?? '');
    return exp == null || DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp;
  }

  void _start() {
    if (!mounted) return;
    final repo = ref.read(authRepositoryProvider);
    if (!repo.isSignInLink(widget.link.toString()) || _expired) {
      return setState(() => _phase = _LinkPhase.expired);
    }
    final email = ref.read(emailLinkStoreProvider).email;
    if (email == null) return setState(() => _phase = _LinkPhase.needEmail);
    unawaited(_signIn(email));
  }

  Future<void> _signIn(String email) async {
    setState(() {
      _phase = _LinkPhase.signingIn;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(authRepositoryProvider);
    try {
      // AU-6: a sign-in that never answers falls back to "Thử lại" instead of spinning.
      await repo
          .signInWithEmailLink(email, widget.link.toString())
          .timeout(_signInTimeout);
      await ref.read(emailLinkStoreProvider).clear();
      // The router leaves this screen for setup or Hôm nay.
    } on TimeoutException {
      if (!mounted || repo.currentUser != null) return;
      setState(() {
        _phase = _LinkPhase.failed;
        _error = l10n.authErrorGeneric;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      // AU-6: signed in, only the earlier credential did not link — that is not a failed
      // sign-in. The router moves on; the toast says what is left to do.
      if (e.failure == AuthFailure.linkFailed) {
        await ref.read(emailLinkStoreProvider).clear();
        if (mounted) {
          showClToast(context, message: authMessage(l10n, e.failure));
        }
        return;
      }
      setState(() {
        switch (e.failure) {
          case AuthFailure.linkExpired:
            _phase = _LinkPhase.expired;
          case AuthFailure.invalidEmail:
            // Not the address the link was sent to.
            _phase = _LinkPhase.needEmail;
            _error = l10n.authErrorInvalidEmail;
          default:
            _phase = _LinkPhase.failed;
            _error = authMessage(l10n, e.failure);
        }
      });
    }
  }

  void _confirm() {
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      return setState(
        () => _error = AppLocalizations.of(context).authErrorInvalidEmail,
      );
    }
    unawaited(_signIn(email));
  }

  /// Back to 07a for a new link.
  void _again() => context.go(Routes.email);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final error = _error == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: cl.text.label.copyWith(color: cl.colors.error),
            ),
          );
    return switch (_phase) {
      // AU-6: Back is always there, also while signing in.
      _LinkPhase.signingIn => OnboardingScaffold(
        topBar: ClTopBar(onBack: _again),
        content: [
          const SizedBox(height: ClSpace.s8 * 2),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: ClSpace.s4),
          Center(
            child: Text(
              l10n.linkOpenSigningIn,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
      _LinkPhase.needEmail => OnboardingScaffold(
        topBar: ClTopBar(onBack: _again),
        content: [
          ScreenHeading(
            title: l10n.linkConfirmTitle,
            subtitle: l10n.linkConfirmBody,
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
            onSubmitted: (_) => _confirm(),
          ),
          if (error != null) ...[const SizedBox(height: ClSpace.s3), error],
        ],
        bottom: [
          ClButton(
            label: l10n.emailSignInButton,
            expand: true,
            onPressed: _email.text.trim().isEmpty ? null : _confirm,
          ),
        ],
      ),
      _LinkPhase.expired => OnboardingScaffold(
        topBar: ClTopBar(onBack: _again),
        content: [
          ScreenHeading(
            title: l10n.linkExpiredTitle,
            subtitle: l10n.linkExpiredBody,
            large: false,
          ),
        ],
        bottom: [
          ClButton(
            label: l10n.linkExpiredButton,
            expand: true,
            onPressed: _again,
          ),
        ],
      ),
      // Offline or another failure: the same link can be tried again.
      _LinkPhase.failed => OnboardingScaffold(
        topBar: ClTopBar(onBack: _again),
        content: [
          ScreenHeading(title: _error ?? l10n.authErrorGeneric, large: false),
        ],
        bottom: [
          ClButton(label: l10n.actionRetry, expand: true, onPressed: _start),
          ClButton(
            label: l10n.linkExpiredButton,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: _again,
          ),
        ],
      ),
    };
  }
}
