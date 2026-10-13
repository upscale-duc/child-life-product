import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/auth/auth_screens.dart';
import 'package:child_life/features/auth/email_link.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Đăng nhập bằng link qua email (07a / 07b / 07c, D-064).

class _Auth extends Fake implements AuthRepository {
  final sent = <String>[];
  final signedIn = <(String, String)>[];
  AuthFailure? sendFails;
  AuthFailure? signInFails;

  @override
  void setLanguage(String languageCode) {}

  @override
  Future<void> sendSignInLink(String email) async {
    final failure = sendFails;
    if (failure != null) throw AuthException(failure);
    sent.add(email);
  }

  @override
  bool isSignInLink(String link) =>
      link.contains('mode=signIn') && link.contains('oobCode=');

  @override
  Future<void> signInWithEmailLink(String email, String link) async {
    final failure = signInFails;
    if (failure != null) throw AuthException(failure);
    signedIn.add((email, link));
  }
}

int _inMinutes(int minutes) =>
    DateTime.now().add(Duration(minutes: minutes)).millisecondsSinceEpoch ~/
    1000;

Uri _link({int? exp}) => Uri.parse(
  'https://dev.childlife.app/auth/link/?mode=signIn&oobCode=abcDEF123_-xyz'
  '&apiKey=AIzaSyA-abcdefghijklmnopqrstu&lang=vi&exp=${exp ?? _inMinutes(15)}',
);

/// Pumps [screen] at '/' with stubs for the other routes; returns the visited locations.
Future<(List<String>, SharedPreferences)> _pump(
  WidgetTester tester,
  Widget screen,
  _Auth auth, {
  Map<String, Object> prefs = const {},
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  final visited = <String>[];
  Widget stub(GoRouterState s) {
    visited.add(s.uri.toString());
    return const Scaffold(body: Text('stub'));
  }

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(path: '/:a', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a/:b', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a/:b/:c', builder: (_, s) => stub(s)),
    ],
  );
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: MaterialApp.router(
        theme: buildClTheme(ClPalette.light),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // "Đang đăng nhập…" spins until the router leaves (not here).
    await tester.pump();
    await tester.pump();
  }
  return (visited, preferences);
}

ClButton _button(WidgetTester tester, String label) => tester.widget<ClButton>(
  find.ancestor(of: find.text(label), matching: find.byType(ClButton)),
);

void main() {
  testWidgets(
    'Đăng nhập: password first; "Gửi link đăng nhập" needs only the email',
    (tester) async {
      final auth = _Auth();
      final (visited, prefs) = await _pump(tester, const EmailScreen(), auth);
      expect(
        tester.getTopLeft(find.text('Đăng nhập').at(1)).dx,
        lessThan(tester.getTopLeft(find.text('Tài khoản mới')).dx),
      );
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(
        _button(tester, 'Gửi link đăng nhập').style,
        ClButtonStyle.secondary,
      );
      // Always there: without an email it asks for one (owner, 2026-10-13).
      await tester.tap(find.text('Gửi link đăng nhập'));
      await tester.pump();
      expect(find.text('Nhập email để nhận link đăng nhập.'), findsOneWidget);
      expect(auth.sent, isEmpty);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );

      await tester.enterText(
        find.byType(EditableText).first,
        'mai@example.com',
      );
      await tester.pump();
      // "Đăng nhập" (the main button) waits for the password; the link does not.
      expect(
        tester
            .widgetList<ClButton>(find.byType(ClButton))
            .firstWhere(
              (b) => b.label == 'Đăng nhập' && b.style == ClButtonStyle.primary,
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Gửi link đăng nhập'));
      await tester.pumpAndSettle();
      expect(auth.sent, ['mai@example.com']);
      expect(prefs.getString('auth.linkEmail'), 'mai@example.com');
      expect(visited, ['/auth/email/sent?email=mai%40example.com']);
    },
  );

  testWidgets('07a: a bad address or too many links say so on the screen', (
    tester,
  ) async {
    final auth = _Auth()..sendFails = AuthFailure.tooManyRequests;
    await _pump(tester, const EmailScreen(), auth);
    await tester.enterText(find.byType(EditableText).first, 'mai@');
    await tester.pump();
    await tester.tap(find.text('Gửi link đăng nhập'));
    await tester.pump();
    expect(find.text('Email chưa đúng, bạn kiểm tra lại nhé.'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'mai@example.com');
    await tester.pump();
    await tester.tap(find.text('Gửi link đăng nhập'));
    await tester.pumpAndSettle();
    expect(auth.sent, isEmpty);
    expect(find.textContaining('Bạn thử hơi nhiều lần'), findsOneWidget);
  });

  testWidgets('"Đăng ký" on 06 opens "Tài khoản mới", with a password', (
    tester,
  ) async {
    await _pump(tester, const EmailScreen(mode: EmailMode.create), _Auth());
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.text('Gửi link đăng nhập'), findsNothing);
  });

  testWidgets('07b: the address, a m:ss countdown, then "Gửi lại"', (
    tester,
  ) async {
    final auth = _Auth();
    await _pump(
      tester,
      const EmailLinkSentScreen(email: 'mai.nguyen@email.com'),
      auth,
    );
    expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
    expect(find.textContaining('mai.nguyen@email.com'), findsOneWidget);
    expect(
      find.text('Không thấy email? Xem thư mục Quảng cáo hoặc Spam.'),
      findsOneWidget,
    );
    expect(_button(tester, 'Gửi lại sau 1:00').onPressed, isNull);
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Gửi lại sau 0:45'), findsOneWidget);
    await tester.pump(const Duration(seconds: 45));
    await tester.tap(find.text('Gửi lại'));
    await tester.pump();
    expect(auth.sent, ['mai.nguyen@email.com']);
    expect(find.text('Gửi lại sau 1:00'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  group('the link opened in the app', () {
    testWidgets('signs in with the address kept on this phone', (tester) async {
      final auth = _Auth();
      final link = _link();
      final (_, prefs) = await _pump(
        tester,
        EmailLinkScreen(link: link),
        auth,
        prefs: {'auth.linkEmail': 'mai@example.com'},
        settle: false,
      );
      expect(auth.signedIn, [('mai@example.com', link.toString())]);
      expect(prefs.getString('auth.linkEmail'), isNull);
    });

    testWidgets('on another phone, asks for the address first', (tester) async {
      final auth = _Auth();
      await _pump(tester, EmailLinkScreen(link: _link()), auth);
      expect(find.text('Xác nhận email'), findsOneWidget);
      expect(auth.signedIn, isEmpty);
      await tester.enterText(find.byType(EditableText), 'mai@example.com');
      await tester.pump();
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump();
      expect(auth.signedIn.single.$1, 'mai@example.com');
    });

    testWidgets('after 15 minutes, or used, it has expired', (tester) async {
      final auth = _Auth();
      final (visited, _) = await _pump(
        tester,
        EmailLinkScreen(link: _link(exp: _inMinutes(-1))),
        auth,
        prefs: {'auth.linkEmail': 'mai@example.com'},
      );
      expect(find.text('Link đã hết hạn'), findsOneWidget);
      expect(auth.signedIn, isEmpty);
      await tester.tap(find.text('Gửi link mới'));
      await tester.pumpAndSettle();
      expect(visited, ['/auth/email']);
    });

    testWidgets('a link Firebase refuses shows the same', (tester) async {
      final auth = _Auth()..signInFails = AuthFailure.linkExpired;
      await _pump(
        tester,
        EmailLinkScreen(link: _link()),
        auth,
        prefs: {'auth.linkEmail': 'mai@example.com'},
      );
      expect(find.text('Link đã hết hạn'), findsOneWidget);
    });

    testWidgets('offline: try the same link again', (tester) async {
      final auth = _Auth()..signInFails = AuthFailure.network;
      await _pump(
        tester,
        EmailLinkScreen(link: _link()),
        auth,
        prefs: {'auth.linkEmail': 'mai@example.com'},
      );
      expect(find.text('Thử lại'), findsOneWidget);
      auth.signInFails = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(auth.signedIn, hasLength(1));
    });
  });

  testWidgets('the website link reaches the route despite its trailing slash', (
    tester,
  ) async {
    // Universal / App Links arrive as `/auth/link/?…` (D-064).
    String? oobCode;
    final router = GoRouter(
      initialLocation: '/auth/link/?mode=signIn&oobCode=x',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/auth/link',
          builder: (_, s) {
            oobCode = s.uri.queryParameters['oobCode'];
            return const Text('link');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('link'), findsOneWidget);
    expect(oobCode, 'x');
  });
}
