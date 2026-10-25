// Runs against dev with the device's existing parent session. Never submits an order.
import 'package:child_life/main.dart' as app;
import 'package:child_life/features/print_studio/print_screen.dart';
import 'package:child_life/features/print_studio/print_product_details.dart';
import 'package:child_life/features/print_studio/print_checkout.dart';
import 'package:child_life/features/print_studio/print_book.dart';
import 'package:child_life/features/print_studio/print_ui.dart';
import 'package:child_life/features/print_studio/print_widgets.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'dev device: product → preview → options → checkout; book preview',
    (t) async {
      final testErrorHandler = FlutterError.onError;
      try {
        await app.main().timeout(const Duration(seconds: 30));
      } finally {
        FlutterError.onError = testErrorHandler;
      }
      debugPrint('Print Studio smoke: bootstrap ready');
      Future<void> wait(bool Function() done, String stage) async {
        debugPrint('Print Studio smoke: $stage');
        for (var i = 0; i < 300 && !done(); i++) {
          await t.pump(const Duration(milliseconds: 200));
        }
        expect(done(), true, reason: 'Dev screen not ready: $stage');
      }

      Future<void> primary() async {
        final button = find
            .descendant(
              of: find.byType(PrintBottomBar),
              matching: find.byType(ClButton),
            )
            .last;
        expect(
          t.widget<ClButton>(button).onPressed,
          isNotNull,
          reason: 'Primary action must be enabled',
        );
        await t.tap(button);
        await t.pump();
        await t.pump(const Duration(milliseconds: 75));
        // The route stays mounted while its next step fades into view.
        await t.pump(const Duration(milliseconds: 400));
      }

      await wait(
        () =>
            find.byType(Scaffold).evaluate().isNotEmpty &&
            FirebaseAuth.instance.currentUser != null,
        'signed-in parent',
      );
      final router = GoRouter.of(t.element(find.byType(Scaffold).first));
      router.go('/memories/print?detail=1');
      await wait(
        () => find.byType(PrintProductDetails).evaluate().isNotEmpty,
        'product details',
      );
      final details = t.widget<PrintProductDetails>(
        find.byType(PrintProductDetails),
      );
      expect(
        details.media.isNotEmpty,
        true,
        reason: 'This smoke test needs existing ready family photos',
      );
      await primary();
      await wait(
        () => find.text('Tiếp tục').evaluate().isNotEmpty,
        'design preview',
      );
      await primary();
      await wait(
        () => find.text('Đặt in').evaluate().isNotEmpty,
        'print options',
      );
      await primary();
      await wait(
        () => find.byType(PrintCheckout).evaluate().isNotEmpty,
        'checkout',
      );
      expect(
        t.widget<PrintCheckout>(find.byType(PrintCheckout)).payment,
        'cod',
      );
      expect(find.byType(PrintStudioScreen), findsOneWidget);
      // No approval, address edit, order submission or fake family data is written.
      router.pushReplacement<void>('/memories/print?product=book');
      await wait(
        () => find.text('Xem thiết kế').evaluate().isNotEmpty,
        'book introduction',
      );
      await primary();
      await wait(
        () => find.byType(PrintBookViewer).evaluate().isNotEmpty,
        'book spread',
      );
      await t.tap(find.byTooltip('Toàn màn hình'));
      await wait(
        () => find.byType(PrintBookFullscreen).evaluate().isNotEmpty,
        'book fullscreen',
      );
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.byTooltip('Đóng'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(PrintBookFullscreen), findsNothing);
      await wait(
        () => find.byType(PrintHeader).evaluate().isNotEmpty,
        'return from fullscreen',
      );
      expect(t.takeException(), isNull);
    },
  );
}
