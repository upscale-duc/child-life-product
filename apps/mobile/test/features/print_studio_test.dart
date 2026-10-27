import 'dart:async';
import 'package:child_life/features/print_studio/print_screen.dart';
import 'package:child_life/features/print_studio/print_checkout.dart';
import 'package:child_life/features/print_studio/print_address_editor.dart';
import 'package:child_life/features/print_studio/print_book.dart';
import 'package:child_life/features/print_studio/print_product_details.dart';
import 'package:child_life/features/print_studio/print_policy.dart';
import 'package:child_life/features/print_studio/print_ui.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/features/print_studio/print_models.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:child_life/features/print_studio/print_book_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/print_fixtures.dart';
import '../helpers/router_pump.dart';

Future<void> tap(WidgetTester t, String text) async {
  final f = find.text(text).last;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> photos(WidgetTester t) async {
  await t.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await t.pumpAndSettle();
}

Future<void> golden(WidgetTester t, String name) async {
  final heights = {
    'preview': 935.0,
    'options': 776.0,
    'checkout': 1089.0,
    'book': 1168.0,
  };
  final oldSize = t.view.physicalSize;
  debugDisableShadows = false;
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  for (final root in t.binding.renderViews) {
    repaint(root);
  }
  t.view.physicalSize = name == 'book_landscape'
      ? oldSize
      : Size(375, heights[name] ?? 812);
  t.view.padding = const FakeViewPadding(top: 40);
  await t.pumpAndSettle();
  await photos(t);
  await expectLater(
    find.byType(Scaffold).first,
    matchesGoldenFile('../golden/goldens/print/current_$name.png'),
  );
  expect(t.takeException(), isNull);
  debugDisableShadows = true;
  for (final root in t.binding.renderViews) {
    repaint(root);
  }
  t.view.physicalSize = oldSize;
  t.view.padding = FakeViewPadding.zero;
  await t.pumpAndSettle();
}

Future<void> checkout(WidgetTester t) async {
  await tap(t, 'Tiếp tục');
  await tap(t, 'Đặt in');
  expect(find.byType(PrintCheckout), findsOneWidget);
}

void main() {
  setUp(() => mediaBytes = PrintFixtureBytes());
  test('gift wrapping is per order and shipping threshold uses subtotal', () {
    const d = PrintDesign(name: 'Teddy', title: '100 ngày', date: '2026-11-25');
    expect(printCatalog.totals(d, 1).total, 379000);
    expect(printCatalog.totals(d, 1, giftWrap: true).total, 409000);
    expect(printCatalog.totals(d, 2, giftWrap: true).total, 728000);
  });
  testWidgets(
    'current Figma PS15 → PS11 → PS14 → PS30N, single checkout and success',
    (t) async {
      final requests = <Map<String, dynamic>>[];
      final (visits, _) = await pumpRouted(
        t,
        const PrintStudioScreen(detail: true),
        overrides: printOverrides(
          action: (name, data) async {
            if (name == 'printStudioOrder') {
              requests.add(Map<String, dynamic>.from(data));
            }
            return {'id': 'CL26110832'};
          },
        ),
      );
      expect(find.byType(PrintProductDetails), findsOneWidget);
      await golden(t, 'details');
      await tap(t, 'Xem thiết kế của Teddy');
      await golden(t, 'preview');
      await tap(t, 'Tiếp tục');
      await golden(t, 'options');
      await tap(t, 'Đặt in');
      expect(find.byType(PrintCheckout), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      await golden(t, 'checkout');
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await tap(t, 'Đặt hàng');
      expect(requests.length, 1);
      expect(requests.single['approved'], true);
      expect(requests.single['paymentMethod'], 'cod');
      expect(requests.single.containsKey('deposit'), false);
      expect(find.byType(PrintOrderSuccess), findsOneWidget);
      await golden(t, 'success');
      await tap(t, 'Xem đơn');
      expect(visits.last.location, contains('/orders/CL26110832'));
    },
  );
  testWidgets(
    'first address is a sheet that saves back into the same checkout',
    (t) async {
      await pumpRouted(
        t,
        const PrintStudioScreen(),
        overrides: printOverrides(savedAddress: false),
      );
      await checkout(t);
      await tap(t, 'Sửa');
      expect(find.byType(PrintAddressEditor), findsOneWidget);
      final fields = find.byType(EditableText);
      await t.enterText(fields.at(0), 'Mai Nguyễn');
      await t.enterText(fields.at(1), '0905123456');
      await t.enterText(fields.at(2), '12 Lê Duẩn, Đà Nẵng');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await tap(t, 'Xong');
      expect(find.byType(PrintAddressEditor), findsNothing);
      expect(find.byType(PrintCheckout), findsOneWidget);
      expect(find.textContaining('12 Lê Duẩn'), findsOneWidget);
    },
  );
  testWidgets(
    'retry keeps id, busy prevents double submit, success stays on success page',
    (t) async {
      final requests = <Map<String, dynamic>>[],
          pending = Completer<Map<String, dynamic>>();
      await pumpRouted(
        t,
        const PrintStudioScreen(),
        overrides: printOverrides(
          action: (name, data) async {
            if (name != 'printStudioOrder') return {};
            requests.add(Map<String, dynamic>.from(data));
            if (requests.length == 1) {
              throw FirebaseFunctionsException(
                code: 'unavailable',
                message: 'offline',
              );
            }
            return pending.future;
          },
        ),
      );
      await checkout(t);
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await tap(t, 'Đặt hàng');
      expect(requests.length, 1);
      await t.tap(find.text('Đặt hàng').last);
      await t.pump();
      await t.tap(find.text('Đặt hàng').last, warnIfMissed: false);
      await t.pump();
      expect(requests.length, 2);
      expect(requests.first['requestId'], requests.last['requestId']);
      pending.complete({'id': 'CLTEST'});
      await t.pumpAndSettle();
      expect(find.byType(PrintOrderSuccess), findsOneWidget);
    },
  );
  testWidgets(
    'book has a photo library, editable page sheet and black fullscreen',
    (t) async {
      await pumpRouted(
        t,
        const PrintStudioScreen(product: 'book'),
        overrides: printOverrides(),
      );
      await tap(t, 'Xem thiết kế');
      expect(find.byType(PrintBookViewer), findsOneWidget);
      await golden(t, 'book');
      await t.tap(find.byTooltip('Toàn màn hình'));
      await t.pumpAndSettle();
      expect(find.byType(PrintBookFullscreen), findsOneWidget);
      await golden(t, 'book_fullscreen');
      t.view.physicalSize = const Size(812, 375);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await golden(t, 'book_landscape');
      t.view.physicalSize = const Size(375, 812);
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Đóng'));
      await t.pumpAndSettle();
      expect(find.byType(PrintBookViewer), findsOneWidget);
      await tap(t, 'Đặt in');
      expect(find.textContaining('40'), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('policies open as a full page and return to checkout', (t) async {
    await pumpRouted(t, const PrintStudioScreen(), overrides: printOverrides());
    await checkout(t);
    final f = find.textContaining('Sản phẩm in riêng');
    await t.scrollUntilVisible(
      f,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    expect(find.byType(PrintPolicy), findsOneWidget);
    await t.tap(
      find
          .descendant(
            of: find.byType(PrintHeader).last,
            matching: find.byType(ClPressable),
          )
          .first,
    );
    await t.pumpAndSettle();
    expect(find.byType(PrintCheckout), findsOneWidget);
  });
  testWidgets('gift wrap and transfer preference stay in the order request', (
    t,
  ) async {
    Map<String, dynamic>? submitted;
    await pumpRouted(
      t,
      const PrintStudioScreen(),
      overrides: printOverrides(
        action: (name, data) async {
          if (name == 'printStudioOrder') {
            submitted = Map<String, dynamic>.from(data);
          }
          return {'id': 'CLGIFT'};
        },
      ),
    );
    await checkout(t);
    await t.scrollUntilVisible(
      find.byType(CupertinoSwitch),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      t.element(find.byType(CupertinoSwitch)),
      alignment: .3,
    );
    await t.pumpAndSettle();
    await t.tap(find.byType(CupertinoSwitch));
    await t.pumpAndSettle();
    await t.enterText(find.byType(EditableText), 'Cả nhà thương con');
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await tap(t, 'Chuyển khoản / VietQR');
    await t.scrollUntilVisible(
      find.byType(Checkbox),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      t.element(find.byType(Checkbox)),
      alignment: .3,
    );
    await t.pumpAndSettle();
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    await tap(t, 'Đặt hàng');
    expect(submitted!['paymentMethod'], 'bankTransfer');
    expect((submitted!['address'] as Map)['gift'], true);
    expect((submitted!['address'] as Map)['giftMessage'], 'Cả nhà thương con');
    expect(
      t.widget<PrintOrderSuccess>(find.byType(PrintOrderSuccess)).total,
      409000,
    );
  });
  testWidgets('book text edits save to the selected page', (t) async {
    await pumpRouted(
      t,
      const PrintStudioScreen(product: 'book'),
      overrides: printOverrides(),
    );
    await tap(t, 'Xem thiết kế');
    t.widget<PrintBookViewer>(find.byType(PrintBookViewer)).onEdit(1);
    await t.pumpAndSettle();
    expect(find.byType(PrintBookPageEditor), findsOneWidget);
    await t.enterText(find.byType(EditableText).first, 'Lời nhắn riêng');
    await t.enterText(find.byType(EditableText).last, 'Cả nhà thương con');
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await tap(t, 'Xong');
    final d = t.widget<PrintBookViewer>(find.byType(PrintBookViewer)).design;
    expect(d.pageTitles[1], 'Lời nhắn riêng');
    expect(d.pageSubtitles[1], 'Cả nhà thương con');
    expect(find.byType(PrintBookPageEditor), findsNothing);
    expect(t.takeException(), isNull);
  });
  for (final palette in ClPalette.values) {
    for (final locale in [const Locale('vi'), const Locale('en')]) {
      if (palette == ClPalette.light && locale.languageCode == 'vi') {
        continue;
      }
      testWidgets('checkout layout ${palette.name} ${locale.languageCode}', (
        t,
      ) async {
        await pumpRouted(
          t,
          const PrintStudioScreen(),
          palette: palette,
          locale: locale,
          overrides: printOverrides(),
        );
        final l = await AppLocalizations.delegate.load(locale);
        await tap(t, l.psNext);
        await tap(t, l.psOrder);
        expect(find.byType(PrintCheckout), findsOneWidget);
        await t.drag(find.byType(ListView).first, const Offset(0, -600));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
  // PR-1 (D-127 Q8): the print file builds in the background; the draft remembers it.
  Map<String, dynamic> job(String status, {int done = 1}) => {
    'status': status,
    'done': done,
    'total': 3,
    'pages': status == 'ready' ? 3 : null,
    'format': 'pdf',
    'error': status == 'failed' ? 'photo-unavailable' : null,
    'createdAt': DateTime.now(),
    'leaseUntil': DateTime.now().add(const Duration(minutes: 5)),
    'expiresAt': DateTime.now().add(const Duration(hours: 20)),
  };
  for (final palette in ClPalette.values) {
    for (final locale in const [Locale('vi'), Locale('en')]) {
      testWidgets('export progress ${palette.name} ${locale.languageCode}', (
        t,
      ) async {
        await pumpRouted(
          t,
          const PrintStudioScreen(resume: true),
          palette: palette,
          locale: locale,
          overrides: printOverrides(
            exportJobId: 'px_1',
            exportJob: job('rendering'),
          ),
        );
        final l = await AppLocalizations.delegate.load(locale);
        await tap(t, l.psExportProgress(1, 3));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text(l.psExportLeave), findsOneWidget);
        t.view.physicalSize = const Size(375, 812);
        t.view.devicePixelRatio = 1;
        debugDisableShadows = false;
        await t.pumpAndSettle();
        await photos(t);
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../golden/goldens/print/export_progress_${palette.name}_${locale.languageCode}.png',
          ),
        );
        debugDisableShadows = true;
        t.view.reset();
      });
    }
  }
  testWidgets('a ready print file opens through a fresh link (PR-1)', (
    t,
  ) async {
    final calls = <String>[];
    await pumpRouted(
      t,
      const PrintStudioScreen(resume: true),
      overrides: printOverrides(
        exportJobId: 'px_1',
        exportJob: job('ready', done: 3),
        action: (name, data) async {
          calls.add(name);
          return {'url': 'https://example.invalid/f.pdf'};
        },
      ),
    );
    await tap(t, 'File in đã sẵn sàng · Mở');
    expect(find.text('3 trang · PDF'), findsOneWidget);
    // launchUrl never answers in a widget test: tap and pump, no settling.
    await t.tap(find.text('Lưu / chia sẻ file'));
    await t.pump();
    expect(calls, contains('printStudioExportUrl'));
  });
  testWidgets('a failed print file says why and offers a retry (PR-1)', (
    t,
  ) async {
    final calls = <String>[];
    await pumpRouted(
      t,
      const PrintStudioScreen(resume: true),
      overrides: printOverrides(
        exportJobId: 'px_1',
        exportJob: job('failed'),
        action: (name, data) async {
          calls.add(name);
          return {'jobId': 'px_2'};
        },
      ),
    );
    // A failed job is not advertised on the preview; the export step says why.
    expect(find.textContaining('File in'), findsNothing);
    await tap(t, 'Tiếp tục');
    await tap(t, 'Tải file');
    expect(find.text('Thêm ảnh để hoàn thiện bản in'), findsOneWidget);
    await tap(t, 'Thử lại');
    expect(calls, contains('printStudioExportStart'));
  });
  testWidgets('Save persists a newly generated design before any edits', (
    t,
  ) async {
    final saved = <Map<String, dynamic>>[];
    await pumpRouted(
      t,
      const PrintStudioScreen(),
      overrides: printOverrides(
        action: (name, data) async {
          if (name == 'printStudioSaveDraft') {
            saved.add(Map<String, dynamic>.from(data));
          }
          return {};
        },
      ),
    );
    await tap(t, 'Lưu nháp');
    expect(saved.length, 1);
    expect((saved.single['design'] as Map)['product'], 'trio');
    expect((saved.single['design'] as Map)['pagePhotos'], isA<Map>());
  });
  test(
    'a print file job past its lease is failed, an expired one is gone (PR-1)',
    () {
      final now = DateTime(2026, 10, 26, 12);
      final stale = PrintExportJob.fromMap('px', {
        'status': 'rendering',
        'leaseUntil': now.subtract(const Duration(minutes: 1)),
        'expiresAt': now.add(const Duration(hours: 1)),
      }, now)!;
      expect(stale.state, PrintExportState.failed);
      expect(stale.error, 'render-failed');
      expect(
        PrintExportJob.fromMap('px', {
          'status': 'ready',
          'expiresAt': now.subtract(const Duration(minutes: 1)),
        }, now),
        isNull,
      );
    },
  );
  test('serialization preserves explicit page layouts and photo slots', () {
    const d = PrintDesign(
      name: 'Teddy',
      title: '100 ngày',
      date: '2026-11-25',
      product: 'book',
      mediaIds: ['a', 'b'],
      pageLayouts: ['portrait', 'collage', 'text'],
      pagePhotos: [
        [0],
        [0, 1, 0, 1],
        [],
      ],
    );
    final round = PrintDesign.fromJson(d.toJson());
    expect(round.slots(1), [0, 1, 0, 1]);
    expect(round.slots(2), isEmpty);
    expect(round.bookLayout(2), 'text');
  });
}
