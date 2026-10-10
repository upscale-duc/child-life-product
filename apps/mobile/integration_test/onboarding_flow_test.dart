// End-to-end S2 flow on a simulator / emulator against the local Firebase emulators:
//
//   firebase emulators:start --only auth,firestore,functions,storage --project child-life-dev
//   flutter test integration_test --flavor dev --dart-define=CL_EMULATORS=true -d <device>
//
// New parent: splash → 01 → 06 → 07 (new account) → 08 (Bỏ qua, P-008) → 10a → 11 → 12 → Today,
// then the profile is checked in Firestore; returning parent: sign out → sign in → Today.
import 'dart:convert';

import 'package:child_life/features/auth/auth_screens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:child_life/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// Test-only account that exists solely in the local Auth emulator.
const _email = 'parent.e2e@example.com';
const _password = 'e2e-only-password';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S2: new parent from splash to Today, then signs back in', (
    tester,
  ) async {
    await resetEmulators();
    // bootstrap() installs Crashlytics error handlers; keep the test framework's own.
    final testOnError = FlutterError.onError;
    await app.main();
    FlutterError.onError = testOnError;
    // Start signed out (a previous run's session survives in the keychain).
    await FirebaseAuth.instance.signOut();
    await tester.pump(const Duration(seconds: 2));
    final l10n = l10nOf(tester);

    // 01 → 06 → 07
    await tapText(tester, l10n.welcomeSignIn);
    await tapText(tester, l10n.signInEmail);
    await pumpUntil(tester, find.text(l10n.emailCreateAccount));
    await tester.enterText(find.byType(EditableText).at(0), _email);
    await tester.enterText(find.byType(EditableText).at(1), _password);
    await tapText(tester, l10n.emailCreateAccount);

    // 08: the account exists, unverified; continue without verifying (P-008).
    await pumpUntil(tester, find.text(l10n.verifyTitle));
    expect(
      find.descendant(
        of: find.byType(VerifyEmailScreen),
        matching: find.text(_email),
      ),
      findsOneWidget,
    );
    await tapText(tester, l10n.actionSkip);

    // 10a
    await pumpUntil(tester, find.text(l10n.whoTitle));
    await tester.enterText(find.byType(EditableText).first, 'Mai');
    await tester.pump();
    await tapText(tester, l10n.actionNext);

    // 11
    await pumpUntil(tester, find.text(l10n.babyNicknameLabel));
    await tester.enterText(find.byType(EditableText).first, 'Teddy');
    await tester.pump();
    await tapText(tester, l10n.actionNext);

    // 12 → createBabyProfile → Today
    await tapText(tester, l10n.trackersDone(4));
    await pumpUntil(
      tester,
      find.text(l10n.todayTileEmpty),
      timeout: const Duration(seconds: 45),
    );
    await skipTourIfShown(tester);
    expect(find.text(l10n.todayTileEmpty), findsNWidgets(4));
    expect(find.textContaining('Teddy'), findsWidgets);

    // Server state: one baby, owned by this account, with its restricted profile.
    final babies =
        jsonDecode(
              await http(
                'GET',
                'http://$host:8080/v1/projects/$project/databases/(default)/documents/babies',
                headers: {'Authorization': 'Bearer owner'},
              ),
            )
            as Map<String, dynamic>;
    final docs = babies['documents'] as List;
    expect(docs, hasLength(1));
    final fields = (docs.single as Map)['fields'] as Map;
    expect((fields['nickname'] as Map)['stringValue'], 'Teddy');
    expect(
      ((fields['trackers'] as Map)['arrayValue'] as Map)['values'],
      hasLength(4),
    );

    // Returning parent: sign out from Tôi (13a, with confirmation), sign in again → Today.
    final meTab = find.bySemanticsLabel(l10n.tabMe);
    await pumpUntil(tester, meTab);
    await tester.tap(meTab.first);
    await tester.pump(const Duration(milliseconds: 600));
    await signOutFromMe(tester, l10n.meSignOut);
    await tapText(tester, l10n.welcomeSignIn);
    await tapText(tester, l10n.signInEmail);
    await tapText(tester, l10n.emailSignInTab);
    await tester.enterText(find.byType(EditableText).at(0), _email);
    await tester.enterText(find.byType(EditableText).at(1), _password);
    await tester.pump();
    await tapText(tester, l10n.emailSignInButton);
    await pumpUntil(
      tester,
      find.text(l10n.todayTileEmpty),
      timeout: const Duration(seconds: 45),
    );
    expect(find.text(l10n.whoTitle), findsNothing);
  });
}
