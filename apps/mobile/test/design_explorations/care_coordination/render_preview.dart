// Explicit design artifact renderer. Writes only docs/design/explorations/care-coordination/assets.
// flutter test --update-goldens test/design_explorations/care_coordination/render_preview.dart
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'preview.dart';

const assets =
    '../../../../../docs/design/explorations/care-coordination/assets';
Future<void> pumpPreview(
  WidgetTester tester,
  Widget child, {
  ClPalette palette = ClPalette.light,
  Locale locale = const Locale('vi'),
  Size viewport = const Size(375, 812),
  TextScaler? textScaler,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildClTheme(palette),
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: textScaler ?? TextScaler.noScaling),
        child: child!,
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester t, String name) async {
  expect(t.takeException(), isNull);
  try {
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile('$assets/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  for (final view in CareView.values) {
    for (final palette in ClPalette.values) {
      for (final language in ['vi', 'en']) {
        testWidgets('${view.name} ${palette.name} $language', (tester) async {
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = true);
          await pumpPreview(
            tester,
            CoordinationPreview(initialView: view),
            palette: palette,
            locale: Locale(language),
            viewport: const Size(390, 1000),
          );
          await capture(tester, '${view.name}_${palette.name}_$language');
        });
      }
    }
  }
  for (final state in PreviewState.values.where(
    (s) => s != PreviewState.ready,
  )) {
    testWidgets('state ${state.name}', (tester) async {
      await pumpPreview(
        tester,
        CoordinationPreview(state: state),
        viewport: const Size(375, 812),
      );
      await capture(tester, 'state_${state.name}_vi');
    });
  }
  for (final view in CareView.values) {
    for (final language in ['vi', 'en']) {
      testWidgets('200 percent ${view.name} $language', (tester) async {
        await pumpPreview(
          tester,
          CoordinationPreview(initialView: view),
          locale: Locale(language),
          textScaler: TextScaler.linear(2),
        );
        await capture(tester, '${view.name}_text200_$language');
      });
    }
  }
  testWidgets('assignment changes owner and time, then returns to overview', (
    tester,
  ) async {
    await pumpPreview(
      tester,
      const CoordinationPreview(initialView: CareView.assignment),
    );
    await tester.tap(find.text('Ba').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mẹ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('18:30').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('19:00').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu phân công'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cùng chăm bé').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('19:00 · Mẹ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('send does not change carer', (tester) async {
    await pumpPreview(
      tester,
      const CoordinationPreview(initialView: CareView.outgoing),
    );
    await tester.tap(find.text('Gửi cho Ba'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Đã gửi · Chờ Ba nhận'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'sent_light_vi');
    expect(find.text('Đã gửi · Chờ Ba nhận'), findsOneWidget);
    expect(find.text('Bạn đang chăm bé'), findsNothing);
  });
  testWidgets('receipt explicitly changes carer and preserves assigned tasks', (
    tester,
  ) async {
    await pumpPreview(
      tester,
      const CoordinationPreview(initialView: CareView.incoming),
    );
    await tester.tap(find.text('Tôi đã nhận bàn giao'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đang chăm bé'), findsOneWidget);
    await capture(tester, 'received_light_vi');
    await tester.tap(find.text('Xem việc của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Tắm cho bé'), findsOneWidget);
  });
  testWidgets(
    'simple mode: complete then undo; measured feed cannot save empty',
    (tester) async {
      await pumpPreview(
        tester,
        const CoordinationPreview(initialView: CareView.simple),
      );
      await tester.tap(find.text('Nhận việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đánh dấu đã xong'));
      await tester.pumpAndSettle();
      expect(find.text('Đã xong · Bạn vừa đánh dấu'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(find.text('Nhận việc'), findsOneWidget);
      await tester.tap(find.text('Ghi cữ bú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu ghi nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Lưu ghi nhận'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '110');
      await capture(tester, 'bottle_input_light_vi');
      await tester.tap(find.text('Lưu ghi nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Lưu ghi nhận'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('routine applies once, caregiver has no assignment control', (
    tester,
  ) async {
    await pumpPreview(
      tester,
      const CoordinationPreview(initialView: CareView.routine),
    );
    await tester.tap(find.text('Dùng lịch cho hôm nay'));
    await tester.pumpAndSettle();
    expect(find.text('Dùng lịch cho hôm nay'), findsNothing);
    expect(find.text('Đã dùng lịch cho hôm nay'), findsOneWidget);
    await pumpPreview(
      tester,
      const CoordinationPreview(
        initialView: CareView.simple,
        key: ValueKey('caregiver'),
      ),
    );
    await tester.tap(find.text('Gia đình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cùng chăm bé').last);
    await tester.pumpAndSettle();
    expect(find.text('Phân việc'), findsNothing);
  });
  testWidgets('offline blocks handover receipt', (tester) async {
    await pumpPreview(
      tester,
      const CoordinationPreview(
        initialView: CareView.incoming,
        state: PreviewState.offline,
      ),
    );
    await tester.tap(find.text('Tôi đã nhận bàn giao'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Bạn đang chăm bé'), findsNothing);
  });
  for (final palette in ClPalette.values) {
    for (final language in ['vi', 'en']) {
      testWidgets('long name ${palette.name} $language', (tester) async {
        await pumpPreview(
          tester,
          const CoordinationPreview(carerName: 'Nguyễn Hoàng Bảo Ngọc Anh'),
          locale: Locale(language),
          palette: palette,
          textScaler: TextScaler.linear(2),
        );
        await capture(tester, 'long_name_${palette.name}_$language');
      });
    }
  }
  testWidgets(
    'lock screen hides task; quick complete stays pending, not family success',
    (tester) async {
      await pumpPreview(
        tester,
        const CoordinationPreview(initialView: CareView.quickAction),
      );
      expect(find.text('Rửa bình sữa'), findsNothing);
      expect(find.text('Đánh dấu đã xong'), findsNothing);
      await tester.tap(find.byType(ClToggle));
      await tester.pumpAndSettle();
      expect(find.text('Rửa bình sữa'), findsOneWidget);
      await capture(tester, 'quick_unlocked_light_vi');
      await tester.tap(find.text('Đánh dấu đã xong'));
      await tester.pumpAndSettle();
      expect(
        find.text('Chờ đồng bộ · Chưa báo đã xong cho gia đình'),
        findsOneWidget,
      );
      expect(find.text('Đã xong · Bạn vừa đánh dấu'), findsNothing);
      await capture(tester, 'quick_pending_light_vi');
    },
  );
  testWidgets(
    'thanks is voluntary, sends once in preview and has no rankings',
    (tester) async {
      await pumpPreview(
        tester,
        const CoordinationPreview(initialView: CareView.gratitude),
      );
      await tester.tap(find.text('Gửi lời cảm ơn'));
      await tester.pumpAndSettle();
      expect(find.text('Đã gửi lời cảm ơn'), findsOneWidget);
      expect(find.text('Gửi lời cảm ơn'), findsNothing);
      await capture(tester, 'thanks_sent_light_vi');
    },
  );
  testWidgets('caregiver may release accepted task before finishing', (
    tester,
  ) async {
    await pumpPreview(
      tester,
      const CoordinationPreview(initialView: CareView.simple),
    );
    await tester.tap(find.text('Nhận việc'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã nhận việc này'), findsOneWidget);
    await tester.tap(find.text('Trả lại việc'));
    await tester.pumpAndSettle();
    expect(find.text('Nhận việc'), findsOneWidget);
    expect(find.text('Đánh dấu đã xong'), findsNothing);
  });
}
