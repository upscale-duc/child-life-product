import 'package:child_life/features/auth/auth_config.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/family/family_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// AU-1 (G3): saving a temporary identity into an existing account claims its families before
// this phone leaves it. AU-2: only "not this password" opens "Email đã có tài khoản".

class _User extends Fake implements User {
  _User({required this.uid, this.isAnonymous = false});
  @override
  final String uid;
  @override
  final bool isAnonymous;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'anon-token-$uid-$forceRefresh';
}

class _Credential extends Fake implements UserCredential {}

class _Functions extends Fake implements FirebaseFunctions {}

/// A FirebaseAuth that logs what happens, in order, into [log].
class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.name, this.log, {User? user}) : _current = user;
  final String name;
  final List<String> log;
  User? _current;
  FirebaseAuthException? signInFails;
  FirebaseAuthException? createFails;
  FirebaseAuthException? passwordFails;

  @override
  User? get currentUser => _current;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    log.add('$name.signIn');
    final failure = signInFails;
    if (failure != null) throw failure;
    _current = _User(uid: 'u_account');
    return _Credential();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw createFails!;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw passwordFails!;

  @override
  Future<void> signOut() async {
    log.add('$name.signOut');
    _current = null;
  }
}

void main() {
  late List<String> log;
  late _Auth phone;
  late _Auth second;
  late AuthRepository repo;

  setUp(() {
    log = [];
    phone = _Auth('phone', log, user: _User(uid: 'u_guest', isAnonymous: true));
    second = _Auth('second', log);
    repo = AuthRepository(
      phone,
      const AuthProviderConfig(),
      null,
      () async => (auth: second, functions: _Functions()),
    );
  });

  Future<MergeResult> merge(
    Future<List<String>> Function(String token, FirebaseFunctions as) claim,
  ) => repo.mergeAnonymousInto(
    email: 'mai@example.com',
    password: 'secret123',
    claim: claim,
  );

  test('claims with the second app first, then signs this phone in', () async {
    final result = await merge((token, _) async {
      log.add('claim:$token');
      return ['b_1', 'b_2'];
    });
    expect(log, [
      'second.signIn',
      'claim:anon-token-u_guest-true',
      'phone.signIn',
      'second.signOut',
    ]);
    expect(result.babyIds, ['b_1', 'b_2']);
    expect(result.signedIn, isTrue);
  });

  test('a wrong password leaves the temporary identity untouched', () async {
    second.signInFails = FirebaseAuthException(code: 'wrong-password');
    await expectLater(
      merge((_, _) async => throw StateError('no claim')),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.wrongCredentials,
        ),
      ),
    );
    expect(log, ['second.signIn', 'second.signOut']);
    expect(phone.currentUser?.isAnonymous, isTrue);
  });

  test(
    'a failed claim keeps the temporary identity, so a retry works',
    () async {
      await expectLater(
        merge(
          (_, _) async => throw const FamilyException(FamilyFailure.network),
        ),
        throwsA(isA<FamilyException>()),
      );
      expect(log, ['second.signIn', 'second.signOut']);
      expect(phone.currentUser?.isAnonymous, isTrue);

      final again = await merge((_, _) async => ['b_1']);
      expect(again.signedIn, isTrue);
    },
  );

  test(
    'merged but this phone cannot sign in: signed out, sign in again',
    () async {
      phone.signInFails = FirebaseAuthException(code: 'network-request-failed');
      final result = await merge((_, _) async => ['b_1']);
      expect(result.babyIds, ['b_1']);
      expect(result.signedIn, isFalse);
      expect(log, contains('phone.signOut'));
      expect(phone.currentUser, isNull);
    },
  );

  group('AU-2: "Tạo tài khoản" with an email that has an account', () {
    setUp(() {
      phone.createFails = FirebaseAuthException(code: 'email-already-in-use');
    });

    test('another password or method → 10 Email đã có tài khoản', () async {
      phone.passwordFails = FirebaseAuthException(code: 'wrong-password');
      await expectLater(
        repo.signUpWithEmail('mai@example.com', 'secret123'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.emailInUse,
          ),
        ),
      );
      expect(repo.pendingEmail, 'mai@example.com');
    });

    for (final (code, failure) in [
      ('network-request-failed', AuthFailure.network),
      ('too-many-requests', AuthFailure.tooManyRequests),
    ]) {
      test('$code is said as such, not as "đã có tài khoản"', () async {
        phone.passwordFails = FirebaseAuthException(code: code);
        await expectLater(
          repo.signUpWithEmail('mai@example.com', 'secret123'),
          throwsA(
            isA<AuthException>().having((e) => e.failure, 'failure', failure),
          ),
        );
        expect(repo.pendingEmail, isNull);
      });
    }
  });
}
