import 'dart:async';

import 'package:child_life/app/route_guard.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_widgets.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// D-076 #11 (Lumi 627:62667, first-run tooltip 669:64442) and #12 (no credits pill 612:7737,
/// "Mức dùng" in the top bar 612:7715).

const _title = 'Gặp Lumi, trợ lý của nhà bạn';

Future<void> _button(
  WidgetTester tester, {
  bool reduce = false,
  bool ticker = true,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildClTheme(ClPalette.light),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: TickerMode(
          enabled: ticker,
          child: Scaffold(
            body: Center(child: AsFloatingButton(onPressed: () {})),
          ),
        ),
      ),
    ),
  ),
);

AsFloatingButtonState _state(WidgetTester tester) =>
    tester.state<AsFloatingButtonState>(find.byType(AsFloatingButton).first);

/// The Lumi button on a page of its own, tooltip allowed while [allow] says so.
Future<(List<Visit>, SharedPreferences)> _entry(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool Function()? allow,
  bool images = false,
  Membership? me,
  Future<void> Function()? launchAsk,
}) async {
  final (visits, _) = await pumpRouted(
    tester,
    Scaffold(
      body: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AssistantFloatingEntry(canShowIntro: allow),
        ),
      ),
    ),
    prefs: prefs,
    overrides: [
      ...assistantOverrides(
        repo: FakeAssistantRepository(),
        images: images,
        me: me,
        launchAsk: launchAsk,
      ),
      assistantAccessProvider.overrideWith(
        (ref, babyId) => AssistantAccess(images: images),
      ),
    ],
  );
  await tester.pump();
  return (visits, await SharedPreferences.getInstance());
}

void main() {
  group('Lumi button attention ring (D-076 #11)', () {
    testWidgets('sweeps, rests, sweeps again', (tester) async {
      await _button(tester);
      expect(find.bySemanticsLabel('Mở Lumi'), findsOneWidget);
      expect(_state(tester).attentionRunning, isTrue);
      expect(tester.binding.hasScheduledFrame, isTrue);
      // After one sweep it rests without frames, then sweeps again.
      await tester.pump(
        AsFloatingButton.sweep + const Duration(milliseconds: 50),
      );
      expect(_state(tester).attentionRunning, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(AsFloatingButton.rest);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Reduce Motion: a still ring, nothing moves', (tester) async {
      await _button(tester, reduce: true);
      expect(find.byKey(const ValueKey('lumi.ring')), findsOneWidget);
      expect(_state(tester).attentionRunning, isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(_state(tester).attentionRunning, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('pauses off screen (muted ticker) and resumes', (tester) async {
      await _button(tester, ticker: false);
      expect(_state(tester).attentionRunning, isFalse);
      await _button(tester);
      expect(_state(tester).attentionRunning, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pauses while the app is in the background', (tester) async {
      await _button(tester);
      expect(_state(tester).attentionRunning, isTrue);
      for (final s in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(_state(tester).attentionRunning, isFalse);
      for (final s in const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(_state(tester).attentionRunning, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Lumi first-run tooltip (669:64442)', () {
    testWidgets('waits while the system notification prompt is open (D-098)', (
      tester,
    ) async {
      final prompt = Completer<void>();
      await _entry(tester, launchAsk: () => prompt.future);
      await tester.pump(AssistantFloatingEntry.introDelay);
      await tester.pump(AssistantFloatingEntry.introRetry);
      expect(find.text(_title), findsNothing);
      prompt.complete();
      await tester.pump();
      await tester.pump(AssistantFloatingEntry.introRetry);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('once per person: "Để sau" closes it for good', (tester) async {
      final (_, prefs) = await _entry(tester);
      expect(find.text(_title), findsNothing);
      await tester.pump(AssistantFloatingEntry.introDelay);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Mới'), findsOneWidget);
      // Photo reading off: no receipt promise.
      expect(
        find.text(
          'Chạm để ghi cữ bú bằng một dòng hoặc hỏi về ghi nhận của bé. '
          'Lumi soạn nháp, bạn xem lại rồi lưu.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lumi.intro')), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pump();
      expect(find.text(_title), findsNothing);
      expect(prefs.getBool(LumiIntroSeenNotifier.keyFor(mai.uid)), isTrue);

      // Next launch: never again.
      await tester.pumpWidget(const SizedBox());
      await _entry(
        tester,
        prefs: {LumiIntroSeenNotifier.keyFor(mai.uid): true},
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(_title), findsNothing);
    });

    testWidgets('"Thử ngay" opens the chat and is remembered', (tester) async {
      final (visits, prefs) = await _entry(tester, images: true);
      await tester.pump(AssistantFloatingEntry.introDelay);
      expect(
        find.text(
          'Chạm để ghi cữ bú bằng một dòng, hỏi về ghi nhận của bé hoặc gửi '
          'ảnh hoá đơn. Lumi soạn nháp, bạn xem lại rồi lưu.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Thử ngay'));
      await tester.pumpAndSettle();
      expect(visits.last.location, startsWith(Routes.assistant));
      expect(prefs.getBool(LumiIntroSeenNotifier.keyFor(mai.uid)), isTrue);
    });

    testWidgets('waits while a sheet is open on the tab', (tester) async {
      var allow = false;
      await _entry(tester, allow: () => allow);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(_title), findsNothing);
      allow = true;
      await tester.pump(AssistantFloatingEntry.introRetry);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('never over a dialog', (tester) async {
      await _entry(tester);
      final context = tester.element(find.byType(AssistantFloatingEntry));
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('modal')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('modal'), findsOneWidget);
      expect(find.text(_title), findsNothing);
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      await tester.pump(AssistantFloatingEntry.introRetry);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('a member who only reads is promised asking, not logging', (
      tester,
    ) async {
      await _entry(tester, me: hoa);
      await tester.pump(AssistantFloatingEntry.introDelay);
      expect(find.text('Chạm để hỏi Lumi về ghi nhận của bé.'), findsOneWidget);
    });
  });

  group('Chat top bar (D-076 #12)', () {
    testWidgets('no credits pill; "Mức dùng" opens CH19', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        AssistantChatScreen(scopeKey: teddyScope.key),
        overrides: assistantOverrides(
          repo: FakeAssistantRepository(usage: usageJson(used: 2)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Còn 18/20 lượt hỗ trợ AI'), findsNothing);
      expect(find.text('Chi tiết'), findsNothing);
      expect(find.bySemanticsLabel('Mức dùng'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('as.usage')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '${Routes.assistantUsage}?baby=$teddyId');
    });
  });
}
