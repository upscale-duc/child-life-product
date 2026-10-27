import 'package:child_life/app/session.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/app_update/app_update_models.dart';
import 'package:child_life/features/app_update/app_update_repository.dart';
import 'package:child_life/features/feedback/feedback_host.dart';
import 'package:child_life/features/feedback/feedback_repository.dart';
import 'package:child_life/features/feedback/feedback_screens.dart';
import 'package:child_life/features/feedback/rate_app.dart';
import 'package:child_life/features/feedback/review_prompt.dart';
import 'package:child_life/features/me/help_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';

// Góp ý & đánh giá (FB1–FB4, D-065).

class _Repo extends Fake implements FeedbackRepository {
  final sent = <Map<String, Object?>>[];
  final requestIds = <String>[];
  var failNext = false;
  List<MyTicket> tickets = const [];

  @override
  Future<String> send({
    required String requestId,
    required FeedbackType type,
    required String message,
    required FeedbackShot? shot,
    required Map<String, Object?>? diagnostics,
    required bool replyByEmail,
    required String locale,
  }) async {
    requestIds.add(requestId);
    if (failNext) {
      failNext = false;
      throw StateError('offline');
    }
    sent.add({
      'type': type,
      'message': message,
      'shot': shot,
      'diagnostics': diagnostics,
      'replyByEmail': replyByEmail,
    });
    return 'CL-1001';
  }

  @override
  Future<List<MyTicket>> mine() async => tickets;
}

class _Shot extends PendingShot {
  _Shot(this.shot);
  final FeedbackShot shot;

  @override
  FeedbackShot? build() => shot;
}

final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Session _signedIn({bool anonymous = false}) => SessionSignedIn(
  user: FakeUser(
    isAnonymous: anonymous,
    email: anonymous ? null : 'mai.nguyen@gmail.com',
  ),
  memberships: const [],
);

Future<(List<String>, ProviderContainer)> _pump(
  WidgetTester tester,
  Widget screen, {
  _Repo? repo,
  Session? session,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
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
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionProvider.overrideWithValue(session ?? _signedIn()),
      feedbackRepositoryProvider.overrideWithValue(repo ?? _Repo()),
      reviewPlatformProvider.overrideWithValue(
        ReviewPlatform(request: () async {}, track: (_) async {}),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  await tester.pumpAndSettle();
  return (visited, container);
}

ClButton _button(WidgetTester tester, String label) => tester.widget<ClButton>(
  find.ancestor(of: find.text(label), matching: find.byType(ClButton)),
);

void main() {
  group('FB2 Góp ý', () {
    testWidgets('type, message, toggles, then FB3', (tester) async {
      final repo = _Repo();
      final (visited, container) = await _pump(
        tester,
        const FeedbackScreen(),
        repo: repo,
      );
      expect(find.text('Góp ý'), findsOneWidget);
      expect(find.text('mai.nguyen@gmail.com'), findsOneWidget);
      expect(_button(tester, 'Gửi góp ý').onPressed, isNull);

      await tester.tap(find.text('Báo lỗi'));
      await tester.enterText(find.byType(EditableText), 'Không lưu được cữ bú');
      // Device info off: no platform snapshot in a widget test.
      await tester.tap(find.text('Gửi kèm thông tin thiết bị'));
      await tester.pump();
      await tester.tap(find.text('Gửi góp ý'));
      await tester.pumpAndSettle();
      expect(repo.sent.single, {
        'type': FeedbackType.bug,
        'message': 'Không lưu được cữ bú',
        'shot': null,
        'diagnostics': null,
        'replyByEmail': true,
      });
      expect(visited, ['/me/feedback/sent']);
      // FB5: a bug report holds the rating prompt.
      expect(
        container.read(reviewPrompterProvider).state.bugReportAt,
        isNotNull,
      );
    });

    testWidgets('FB-1: "Gửi" again after a failure keeps the request id', (
      tester,
    ) async {
      final repo = _Repo()..failNext = true;
      final (visited, _) = await _pump(
        tester,
        const FeedbackScreen(),
        repo: repo,
      );
      await tester.enterText(find.byType(EditableText), 'Không lưu được cữ bú');
      await tester.tap(find.text('Gửi kèm thông tin thiết bị'));
      await tester.pump();
      await tester.tap(find.text('Gửi góp ý'));
      await tester.pumpAndSettle();
      expect(repo.sent, isEmpty);
      await tester.tap(find.text('Gửi góp ý'));
      await tester.pumpAndSettle();
      expect(repo.sent, hasLength(1));
      // One id for the draft: the server files one ticket per id.
      expect(repo.requestIds, hasLength(2));
      expect(repo.requestIds.toSet(), hasLength(1));
      expect(visited, ['/me/feedback/sent']);
    });

    testWidgets('a temporary identity sends without "Cho phép liên hệ lại"', (
      tester,
    ) async {
      final repo = _Repo();
      final (visited, _) = await _pump(
        tester,
        const FeedbackScreen(),
        repo: repo,
        session: _signedIn(anonymous: true),
      );
      expect(find.text('Cần tài khoản có email'), findsOneWidget);
      await tester.tap(find.text('Gửi kèm thông tin thiết bị'));
      await tester.enterText(find.byType(EditableText), 'Ý tưởng hay');
      await tester.pump();
      await tester.tap(find.text('Gửi góp ý'));
      await tester.pumpAndSettle();
      expect(repo.sent.single['replyByEmail'], isFalse);
      expect(visited, ['/me/feedback/sent?reply=0']);
    });

    testWidgets("FB4's screenshot arrives attached and can be removed", (
      tester,
    ) async {
      final repo = _Repo();
      final shot = FeedbackShot(_png, png: true);
      await _pump(
        tester,
        const FeedbackScreen(type: FeedbackType.bug),
        repo: repo,
        overrides: [pendingShotProvider.overrideWith(() => _Shot(shot))],
      );
      expect(find.bySemanticsLabel('Ảnh chụp màn hình'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Bỏ ảnh'));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Ảnh chụp màn hình'), findsOneWidget);
    });
  });

  testWidgets('FB3: without a reply, no promise of an email', (tester) async {
    await _pump(tester, const FeedbackSentScreen(reply: false));
    expect(find.text('Đã nhận góp ý của bạn'), findsOneWidget);
    expect(find.textContaining('2 ngày làm việc'), findsNothing);
    expect(find.textContaining('Trợ giúp & liên hệ'), findsOneWidget);
  });

  testWidgets('Trợ giúp & liên hệ lists what was sent', (tester) async {
    final repo = _Repo()
      ..tickets = [
        MyTicket(
          ticket: 'CL-1002',
          category: 'feedback',
          type: FeedbackType.bug,
          message: 'Không lưu được cữ bú',
          status: 'waiting',
          createdAt: DateTime(2026, 10, 13),
        ),
        MyTicket(
          ticket: 'CL-1001',
          category: 'storage',
          type: null,
          message: 'Hết dung lượng',
          status: 'new',
          createdAt: DateTime(2026, 10, 12),
        ),
      ];
    await _pump(tester, const HelpScreen(), repo: repo);
    await tester.scrollUntilVisible(
      find.text('CL-1001 · Dung lượng'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đã gửi'), findsOneWidget);
    expect(find.text('CL-1002 · Góp ý · Báo lỗi'), findsOneWidget);
    expect(find.text('Đã trả lời'), findsOneWidget);
    expect(find.text('Đã nhận'), findsOneWidget);
  });

  group('FB1 "Đánh giá trên App Store"', () {
    test('opens the store page, on iOS at "write a review"', () {
      final url = Uri.parse('https://apps.apple.com/app/id123');
      expect(
        rateUrlOf(url, ios: true).toString(),
        'https://apps.apple.com/app/id123?action=write-review',
      );
      expect(rateUrlOf(url, ios: false), url);
      expect(rateUrlOf(null, ios: true), isNull);
    });

    testWidgets('UPD-1: a store page that does not open says so', (
      tester,
    ) async {
      final (_, container) = await _pump(
        tester,
        const Scaffold(body: RateAppRow()),
        overrides: [
          appUpdateConfigProvider.overrideWith(
            (ref) => Stream.value(
              AppUpdateConfig(
                ios: PlatformUpdate(
                  storeUrl: Uri.parse('https://apps.apple.com/app/id1'),
                ),
                android: PlatformUpdate(
                  storeUrl: Uri.parse(
                    'https://play.google.com/store/apps/details?id=x',
                  ),
                ),
              ),
            ),
          ),
          openStoreProvider.overrideWithValue(
            (u) async => throw StateError('no store'),
          ),
        ],
      );
      // The row reads the config when tapped: keep it loaded, as the Me screen does.
      container.listen(appUpdateConfigProvider, (_, _) {});
      await tester.pump();
      await tester.tap(find.byType(RateAppRow));
      await tester.pump();
      expect(
        find.text('Chưa mở được cửa hàng ứng dụng. Thử lại sau nhé.'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('before the app is published it says so', (tester) async {
      final opened = <Uri>[];
      await _pump(
        tester,
        const Scaffold(body: RateAppRow()),
        overrides: [
          appUpdateConfigProvider.overrideWith(
            (ref) => Stream.value(const AppUpdateConfig()),
          ),
          openStoreProvider.overrideWithValue((u) async => opened.add(u)),
        ],
      );
      await tester.tap(find.byType(RateAppRow));
      await tester.pump();
      expect(
        find.text('Child Life chưa có trên cửa hàng ứng dụng.'),
        findsOneWidget,
      );
      expect(opened, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('FB4 after a screenshot', () {
    Future<void> screenshot(WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'childlife/screenshot',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('taken'),
          ),
          (_) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
    }

    testWidgets('offers "Báo lỗi" with the capture, once per session', (
      tester,
    ) async {
      resetScreenshotSession();
      final pushed = <String>[];
      final (_, container) = await _pump(
        tester,
        const FeedbackHost(child: Scaffold(body: Text('Hôm nay'))),
        overrides: [
          feedbackNavProvider.overrideWithValue((
            location: () => '/today',
            push: pushed.add,
          )),
        ],
      );
      await screenshot(tester);
      expect(find.text('Có gì chưa ổn ở màn này?'), findsOneWidget);
      await tester.tap(find.text('Báo lỗi'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(pushed, ['/me/feedback?type=bug']);
      expect(container.read(pendingShotProvider)?.png, isTrue);
      expect(find.text('Có gì chưa ổn ở màn này?'), findsNothing);

      await screenshot(tester);
      expect(find.text('Có gì chưa ổn ở màn này?'), findsNothing);
    });

    testWidgets('closes with "×", and not on Góp ý itself', (tester) async {
      resetScreenshotSession();
      var location = '/me/feedback';
      await _pump(
        tester,
        const FeedbackHost(child: Scaffold(body: Text('Hôm nay'))),
        overrides: [
          feedbackNavProvider.overrideWithValue((
            location: () => location,
            push: (_) {},
          )),
        ],
      );
      await screenshot(tester);
      expect(find.text('Có gì chưa ổn ở màn này?'), findsNothing);
      location = '/today';
      await screenshot(tester);
      expect(find.text('Có gì chưa ổn ở màn này?'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Đóng'));
      await tester.pump();
      expect(find.text('Có gì chưa ổn ở màn này?'), findsNothing);
    });
  });
}
