import 'dart:convert';
import 'dart:math';

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
  _ => AuthFailure.other,
};

/// Sign-in for 06 / 07 / 09 / 10 (R-001…R-005). One person = one account with linked providers.
class AuthRepository {
  AuthRepository(this._auth, this._config);

  final FirebaseAuth _auth;
  final AuthProviderConfig _config;
  bool _googleReady = false;

  /// Credential the user tried before we found the email already had an account (screen 10).
  /// It is linked to whichever account the user signs into next ("rồi liên kết", R-005).
  AuthCredential? _pendingLink;
  String? pendingEmail;

  User? get currentUser => _auth.currentUser;

  /// Includes profile changes such as emailVerified after reload().
  Stream<User?> userChanges() => _auth.userChanges();

  void setLanguage(String languageCode) => _auth.setLanguageCode(languageCode);

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
      await result.user?.sendEmailVerification();
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
    await _auth.currentUser?.sendEmailVerification();
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
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw AuthException(failureOf(e));
    }
  }

  Future<void> signInWithGoogle() async {
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
      await _signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
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
    if (!_config.appleConfigured) {
      throw const AuthException(AuthFailure.notConfigured);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _guard(() async {
        await _auth.signInWithProvider(AppleAuthProvider());
        await _linkPending();
      });
      return;
    }
    final rawNonce = _nonce();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      await _signInWithCredential(
        OAuthProvider('apple.com').credential(
          idToken: apple.identityToken,
          rawNonce: rawNonce,
          accessToken: apple.authorizationCode,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(
        e.code == AuthorizationErrorCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.other,
      );
    }
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
