import 'package:child_life/app/session.dart';
import 'package:child_life/features/memories/push_registration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';

void main() {
  test('R-030 temporary invited family members have push endpoints', () {
    for (final membership in [mai, lan, hoa]) {
      final session = SessionSignedIn(
        user: FakeUser(uid: membership.uid, isAnonymous: true),
        memberships: [membership],
      );
      expect(canRegisterFamilyPush(session), isTrue);
    }
  });
  test('registered accounts still register their family device', () {
    expect(
      canRegisterFamilyPush(
        SessionSignedIn(
          user: FakeUser(uid: mai.uid),
          memberships: [mai],
        ),
      ),
      isTrue,
    );
  });
  test('no endpoint before authentication or joining a family', () {
    expect(canRegisterFamilyPush(const SessionLoading()), isFalse);
    expect(canRegisterFamilyPush(const SessionSignedOut()), isFalse);
    expect(
      canRegisterFamilyPush(
        SessionSignedIn(
          user: FakeUser(uid: mai.uid, isAnonymous: true),
          memberships: const [],
        ),
      ),
      isFalse,
    );
  });
}
