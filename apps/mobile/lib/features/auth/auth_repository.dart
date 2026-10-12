import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../app/providers.dart';
import 'auth_config.dart';

/// Failures the auth screens turn into copy (G-001: no error states are drawn in Figma).
enum AuthFailure {
  invalidEmail,
  weakPassword,
  wrongCredentials,
  emailInUse,
  tooManyRequests,
  network,
  notConfigured,
  disabled,
  cancelled,
  linkFailed,

  /// An email sign-in link that was used, has expired or is not one (D-064).
  linkExpired,
  other,
}

class AuthException implements Exception {
  const AuthException(this.failure);
  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}

AuthFailure failureOf(FirebaseAuthException e) => switch (e.code) {
  'invalid-email' => AuthFailure.invalidEmail,
  'weak-password' ||
  'password-does-not-meet-requirements' => AuthFailure.weakPassword,
  'wrong-password' ||
  'user-not-found' ||
  'invalid-credential' ||
  'invalid-login-credentials' => AuthFailure.wrongCredentials,
  'email-already-in-use' ||
  'account-exists-with-different-credential' => AuthFailure.emailInUse,
  'too-many-requests' => AuthFailure.tooManyRequests,
  'network-request-failed' => AuthFailure.network,
  'operation-not-allowed' || 'internal-error' => AuthFailure.notConfigured,
  'user-disabled' => AuthFailure.disabled,
  'web-context-canceled' || 'canceled' => AuthFailure.cancelled,
  'invalid-action-code' || 'expired-action-code' => AuthFailure.linkExpired,
  _ => AuthFailure.other,
};

/// Sign-in for 06 / 07 / 09 / 10 (R-001…R-005). One person = one account with linked providers.
class AuthRepository {
  AuthRepository(this._auth, this._config, [this._functions]);

  final FirebaseAuth _auth;
  final AuthProviderConfig _config;

  /// Read only when a branded mail goes out (D-054), so tests without Firebase never touch it.
  final FirebaseFunctions Function()? _functions;
  String _language = 'vi';
  bool _googleReady = false;

  /// Credential the user tried before we found the email already had an account (screen 10).
  /// It is linked to whichever account the user signs into next ("rồi liên kết", R-005).
  AuthCredential? _pendingLink;
  String? pendingEmail;

  User? get currentUser => _auth.currentUser;

  /// Includes profile changes such as emailVerified after reload().
  Stream<User?> userChanges() => _auth.userChanges();

  void setLanguage(String languageCode) {
    _language = languageCode.startsWith('en') ? 'en' : 'vi';
    _auth.setLanguageCode(languageCode);
  }

  /// "Xác minh email" / "Quên mật khẩu" as Child Life's own mail through Resend (D-054). False
  /// when that is not possible yet (no provider, Function not deployed, offline): the caller then
  /// lets Firebase send its own mail, as before.
  Future<bool> _brandedMail(Map<String, Object?> data) async {
    final functions = _functions;
    if (functions == null) return false;
    try {
      await functions().httpsCallable('sendAuthEmail').call<Object?>({
        ...data,
        'locale': _language,
      });
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw const AuthException(AuthFailure.tooManyRequests);
      }
      return false;
    }
  }

  Future<void> _sendVerification(User? user) async {
    if (user == null || user.emailVerified) return;
    if (await _brandedMail({'kind': 'verifyEmail'})) return;
    await user.sendEmailVerification();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(failureOf(e));
    }
  }

  /// "Tạo tài khoản" (07). If the email is taken we first try the same password: an existing
  /// email account then simply signs in. Otherwise the email belongs to Apple / Google → 10.
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _sendVerification(result.user);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') throw AuthException(failureOf(e));
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _linkPending();
      } on FirebaseAuthException {
        _pendingLink = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        pendingEmail = email;
        throw const AuthException(AuthFailure.emailInUse);
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) => _guard(
    () async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _linkPending();
    },
  );

  Future<void> sendVerificationEmail() => _guard(() async {
    await _sendVerification(_auth.currentUser);
  });

  /// Re-reads the account so a link opened in the browser shows up (no universal links yet).
  Future<bool> reloadEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
    } on FirebaseAuthException {
      return user.emailVerified;
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// "Gửi link" (09). Never reveals whether the email has an account (email privacy is on).
  Future<void> sendPasswordReset(String email) async {
    try {
      if (await _brandedMail({'kind': 'resetPassword', 'email': email})) return;
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw AuthException(failureOf(e));
    }
  }

  /// 07a "Gửi link đăng nhập" (D-064): Child Life's own mail, whose link opens the app on the
  /// website's `/auth/link/`. Firebase's own mail has no such link, so there is no fallback.
  /// Signs in or creates the account alike; the answer never tells which.
  Future<void> sendSignInLink(String email) async {
    final functions = _functions;
    if (functions == null) throw const AuthException(AuthFailure.notConfigured);
    try {
      await functions().httpsCallable('sendAuthEmail').call<Object?>({
        'kind': 'appSignInLink',
        'email': email,
        'locale': _language,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(switch (e.code) {
        'resource-exhausted' => AuthFailure.tooManyRequests,
        'invalid-argument' => AuthFailure.invalidEmail,
        'unavailable' when e.message == 'no-provider' =>
          AuthFailure.notConfigured,
        'not-found' => AuthFailure.notConfigured,
        'unavailable' || 'deadline-exceeded' => AuthFailure.network,
        _ => AuthFailure.other,
      });
    }
  }

  bool isSignInLink(String link) => _auth.isSignInWithEmailLink(link);

  /// Opening the link from 07b on this phone (D-064). The email is the one the link was sent to.
  Future<void> signInWithEmailLink(String email, String link) =>
      _guard(() async {
        await _auth.signInWithEmailLink(email: email, emailLink: link);
        await _linkPending();
      });

  Future<void> signInWithGoogle() async =>
      _signInWithCredential(await _googleCredential());

  Future<AuthCredential> _googleCredential() async {
    final serverClientId = _config.googleServerClientId;
    if (serverClientId == null) {
      throw const AuthException(AuthFailure.notConfigured);
    }
    try {
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? _config.googleIosClientId
              : null,
          serverClientId: serverClientId,
        );
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthException(AuthFailure.other);
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw AuthException(switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => AuthFailure.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthFailure.notConfigured,
        _ => AuthFailure.other,
      });
    }
  }

  /// Native on iOS, Firebase web flow on Android (plan §3.6, SP-6). Needs an Apple Developer team.
  Future<void> signInWithApple() async {
    if (!_config.appleOn(defaultTargetPlatform)) {
      throw const AuthException(AuthFailure.notConfigured);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _guard(() async {
        await _auth.signInWithProvider(AppleAuthProvider());
        await _linkPending();
      });
      return;
    }
    await _signInWithCredential(await _appleCredential());
  }

  Future<AuthCredential> _appleCredential() async {
    final rawNonce = _nonce();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      return OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(
        e.code == AuthorizationErrorCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.other,
      );
    }
  }

  // ---------- Temporary identity (16b "Vào ngay", 16d "Lưu tài khoản") ----------

  /// "Vào ngay": join without an account (R-030).
  Future<void> signInAnonymously() => _guard(() async {
    await _auth.signInAnonymously();
  });

  /// 16d "Dùng email" → new account: the same uid keeps its memberships (R-031).
  Future<void> saveAnonymousWithEmail(String email, String password) =>
      _guard(() async {
        final user = _auth.currentUser;
        if (user == null || !user.isAnonymous) {
          throw const AuthException(AuthFailure.other);
        }
        final result = await user.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        // Continue unverified is allowed (P-008); the link still goes out.
        await _sendVerification(result.user);
      });

  /// 16d Apple / Google. Returns false when the credential already has an account: the caller
  /// then signs into it with [mergeAnonymousInto].
  Future<bool> saveAnonymousWithProvider({required bool apple}) async {
    if (apple && !_config.appleOn(defaultTargetPlatform)) {
      throw const AuthException(AuthFailure.notConfigured);
    }
    final credential = apple
        ? await _appleCredential()
        : await _googleCredential();
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw const AuthException(AuthFailure.other);
    }
    try {
      await user.linkWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        _collision = e.credential ?? credential;
        return false;
      }
      throw AuthException(failureOf(e));
    }
  }

  AuthCredential? _collision;

  /// P-007: signs into the account that already owns the credential and lets [claim] move the
  /// temporary identity's memberships there (server verifies the anonymous ID token).
  Future<void> mergeAnonymousInto({
    required Future<void> Function(String anonymousIdToken) claim,
    String? email,
    String? password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw const AuthException(AuthFailure.other);
    }
    final anonymousIdToken = await user.getIdToken();
    if (anonymousIdToken == null) throw const AuthException(AuthFailure.other);
    final credential = email != null && password != null
        ? EmailAuthProvider.credential(email: email, password: password)
        : _collision;
    if (credential == null) throw const AuthException(AuthFailure.other);
    await _guard(() => _auth.signInWithCredential(credential));
    _collision = null;
    await claim(anonymousIdToken);
  }

  Future<void> _signInWithCredential(AuthCredential credential) =>
      _guard(() async {
        await _auth.signInWithCredential(credential);
        await _linkPending();
      });

  Future<void> _linkPending() async {
    final pending = _pendingLink;
    if (pending == null) return;
    _pendingLink = null;
    pendingEmail = null;
    try {
      await _auth.currentUser?.linkWithCredential(pending);
    } on FirebaseAuthException catch (e) {
      // Already linked is success; anything else leaves the user signed in without the link.
      if (e.code != 'provider-already-linked') {
        throw const AuthException(AuthFailure.linkFailed);
      }
    }
  }

  void clearPendingLink() {
    _pendingLink = null;
    pendingEmail = null;
  }

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    authProviderConfigFor(ref.watch(environmentProvider)),
    () => ref.read(functionsProvider),
  ),
);

/// Signed-in user (null when signed out). Emits again when the profile changes.
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// Name Apple / Google shared at sign-in, used to prefill 10a "Tên của bạn".
final providerDisplayNameProvider = Provider<String?>(
  (ref) => ref.watch(authRepositoryProvider).currentUser?.displayName,
);

/// Whether this environment can use each provider (shown, but explains when unavailable).
final authProviderConfigProvider = Provider<AuthProviderConfig>(
  (ref) => authProviderConfigFor(ref.watch(environmentProvider)),
);
