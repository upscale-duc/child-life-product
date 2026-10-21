import 'dart:io';
import 'package:child_life/app/local_privacy_guard.dart';
import 'package:child_life/app/session.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/privacy/local_privacy.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/family_fixtures.dart';

final _session = NotifierProvider<_Session, Session>(_Session.new);

class _Session extends Notifier<Session> {
  @override
  Session build() => SessionSignedIn(
    user: FakeUser(uid: 'a'),
    memberships: [mai],
  );
  void update(Session value) => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'the root guard invalidates authority and local providers across accounts and sign-out',
    () async {
      final dir = Directory.systemTemp.createTempSync('privacy-guard');
      SharedPreferences.setMockInitialValues({'privacy.migratedV2': true});
      final prefs = await SharedPreferences.getInstance();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      const uploads = MethodChannel('childlife/uploads');
      var cancelled = 0;
      messenger.setMockMethodCallHandler(paths, (_) async => dir.path);
      messenger.setMockMethodCallHandler(uploads, (call) async {
        if (call.method == 'cancelAll') cancelled++;
        return null;
      });
      localPrivacy.bind(null, {});
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authUserProvider.overrideWith(
            (ref) => Stream.value(FakeUser(uid: 'b')),
          ),
          sessionProvider.overrideWith((ref) => ref.watch(_session)),
          careClockProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      final listener = c.listen(localPrivacyGuardProvider, (_, _) {});
      await pumpEventQueue();
      final epoch = c.read(localPrivacyGuardProvider);
      expect(
        localPrivacy.authorize('a', 'babies/$teddyId/media/x/p.jpg'),
        epoch,
      );
      c.read(_session.notifier).update(const SessionLoading());
      await pumpEventQueue();
      expect(localPrivacy.owner, 'b');
      expect(
        localPrivacy.babies,
        isEmpty,
        reason: 'auth changed before memberships finished loading',
      );
      expect(() => localPrivacy.check(epoch), throwsStateError);
      c
          .read(_session.notifier)
          .update(
            SessionSignedIn(
              user: FakeUser(uid: 'b'),
              memberships: const [],
            ),
          );
      await pumpEventQueue();
      expect(c.read(localPrivacyGuardProvider), greaterThan(epoch));
      expect(
        () => localPrivacy.authorize('b', 'babies/$teddyId/media/x/p.jpg'),
        throwsStateError,
      );
      expect(prefs.getString('privacy.owner'), 'b');
      c.read(_session.notifier).update(const SessionSignedOut());
      await pumpEventQueue();
      expect(localPrivacy.owner, isNull);
      expect(prefs.getString('privacy.owner'), isNull);
      expect(cancelled, greaterThanOrEqualTo(2));
      listener.close();
      c.dispose();
      localPrivacy.cleanup = null;
      messenger.setMockMethodCallHandler(paths, null);
      messenger.setMockMethodCallHandler(uploads, null);
      dir.deleteSync(recursive: true);
    },
  );
}
