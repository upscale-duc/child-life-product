import 'dart:async';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_voice.dart';
import 'package:child_life/features/assistant/assistant_widgets.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Lumi chat rework (owner feedback 2026-10-15, "Lumi chat khá cứng…"): optimistic sending,
/// "Lumi đang soạn…", the keyboard, sticking to the newest message vs "Tin mới", linked time
/// editing, "Khác…" with a computed preview, friendly errors, Reduce Motion and voice input
/// with a scripted recognizer. Synthetic data only.

String _key(String what) => 'assistant.$what.u_mai:${teddyScope.key}';

Map<String, Object> _thread(List<String> ids) => {
  _key('conversation'): conversation1,
  _key('tasks'): ids,
};

Future<void> _pump(
  WidgetTester tester, {
  required FakeAssistantRepository repo,
  Map<String, Object> prefs = const {},
  FakeDictation? dictation,
}) async {
  await pumpRouted(
    tester,
    AssistantChatScreen(scopeKey: teddyScope.key),
    prefs: prefs,
    overrides: assistantOverrides(repo: repo, dictation: dictation),
  );
  await tester.pumpAndSettle();
}

/// The chat with animations on (the default pump turns them off, like Reduce Motion).
Future<void> _pumpMoving(
  WidgetTester tester, {
  required FakeAssistantRepository repo,
  bool reduceMotion = false,
  double textScale = 1,
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        environmentProvider.overrideWithValue(AppEnvironment.dev),
        ...assistantOverrides(repo: repo),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 812),
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: buildClTheme(ClPalette.light),
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AssistantChatScreen(scopeKey: teddyScope.key),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

Finder _text(String s) => find.text(s);

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump();
}

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('as.thread')),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

/// A task with a long question and a long answer (the thread grows past the screen).
String _task(int i) => 'tk_${'$i' * 32}'.substring(0, 35);

Map<String, Object?> _chatty(String id, {bool more = false}) => snapshotWith(
  task: taskJson(id: id),
  messages: [
    userMessage(
      'Câu hỏi số $id về giấc ngủ, cữ bú và mọi thứ của bé hôm nay nhé.',
      taskId: id,
    ),
    assistantMessage([
      textPart(
        'Trả lời dài cho $id: hôm nay bé bú đều, ngủ ngoan, mọi thứ ổn. '
        'Bạn cứ ghi tiếp khi có thêm cữ bú hoặc giấc ngủ mới nhé.',
      ),
    ], taskId: id),
    if (more)
      assistantMessage(
        [textPart('Thêm một tin nhắn mới của Lumi.')],
        taskId: id,
        sequence: 3,
      ),
  ],
);

AssistantEvent _event(String taskId, int seq, String type) => AssistantEvent(
  taskId: taskId,
  eventId: '$taskId:$seq',
  sequence: seq,
  typeWire: type,
);

void main() {
  group('conversation feel', () {
    testWidgets('optimistic send: my bubble and "Lumi đang soạn…" at once', (
      tester,
    ) async {
      final repo = FakeAssistantRepository()..startGate = Completer<void>();
      await _pump(tester, repo: repo);
      const said = '8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.';
      await _type(tester, said);
      await tester.tap(find.bySemanticsLabel('Gửi').last);
      await tester.pump();
      // Before any answer: the words are mine on screen, the field is clear, Lumi is typing.
      expect(_text(said), findsOneWidget);
      expect(_text('Đang gửi…'), findsOneWidget);
      expect(_text('Lumi đang soạn…'), findsOneWidget);
      expect(_field(tester).controller!.text, isEmpty);
      // A second tap cannot send twice.
      expect(repo.named('startTask'), hasLength(1));
      repo.startGate!.complete();
      await tester.pumpAndSettle();
      // The same entry becomes the task's message (one bubble), then the drafts.
      expect(_text(said), findsOneWidget);
      expect(_text('Đang gửi…'), findsNothing);
      expect(_text('Lumi đang soạn…'), findsNothing);
      expect(_text('Cữ bú bình'), findsOneWidget);
      // Lumi's run starts with her name.
      expect(find.byType(AsLumiHeader), findsOneWidget);
    });

    testWidgets('a long press copies, a tap shows the time', (tester) async {
      final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(_text('14:20'), findsNothing);
      await tester.tap(
        _text('8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.'),
      );
      await tester.pumpAndSettle();
      expect(_text('14:20'), findsOneWidget);
      await tester.longPress(
        _text('Mình thấy 2 việc. Kiểm tra rồi chọn mục muốn lưu nhé.'),
      );
      await tester.pumpAndSettle();
      expect(_text('Đã sao chép'), findsOneWidget);
    });

    testWidgets('the keyboard goes away on a tap on the thread or a drag', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      await _pump(tester, repo: repo);
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(_field(tester).focusNode!.hasFocus, isTrue);
      // A tap on the thread (not a control).
      await tester.tap(_text('Hỏi hoặc ghi nhanh cho Teddy'));
      await tester.pump();
      expect(_field(tester).focusNode!.hasFocus, isFalse);
      // A drag on the thread, even while it is too short to scroll.
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(_field(tester).focusNode!.hasFocus, isTrue);
      await tester.drag(
        find.byKey(const ValueKey('as.thread')),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();
      expect(_field(tester).focusNode!.hasFocus, isFalse);
    });

    testWidgets('sticks to the newest only at the bottom; else "Tin mới"', (
      tester,
    ) async {
      final ids = [for (var i = 1; i <= 7; i++) _task(i)];
      final repo = FakeAssistantRepository(
        tasks: {for (final id in ids) id: _chatty(id)},
      );
      await _pump(tester, repo: repo, prefs: _thread(ids));
      var p = _position(tester);
      expect(p.maxScrollExtent, greaterThan(300));
      expect(p.pixels, closeTo(p.maxScrollExtent, 1));
      // Reading further up: a new answer does not move the thread; the pill appears.
      await tester.drag(
        find.byKey(const ValueKey('as.thread')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      final reading = _position(tester).pixels;
      expect(reading, lessThan(p.maxScrollExtent - 100));
      repo.tasks[ids.last] = _chatty(ids.last, more: true);
      repo.push(
        ids.last,
        TaskEventsLive([_event(ids.last, 5, 'answer_ready')]),
      );
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, closeTo(reading, 1));
      expect(_text('Tin mới'), findsOneWidget);
      // The pill takes me down and goes.
      await tester.tap(_text('Tin mới'));
      await tester.pumpAndSettle();
      p = _position(tester);
      expect(p.pixels, closeTo(p.maxScrollExtent, 1));
      expect(_text('Tin mới'), findsNothing);
      expect(_text('Thêm một tin nhắn mới của Lumi.'), findsOneWidget);
      // At the bottom, new content scrolls into view by itself.
      final before = p.maxScrollExtent;
      repo.tasks[ids.first] = _chatty(ids.first, more: true);
      repo.tasks[ids.last] = snapshotWith(
        task: taskJson(id: ids.last),
        messages: [
          ...(_chatty(ids.last, more: true)['messages']! as List)
              .cast<Map<String, Object?>>(),
          assistantMessage(
            [textPart('Và một tin nữa ở cuối.')],
            taskId: ids.last,
            sequence: 4,
          ),
        ],
      );
      repo.push(
        ids.last,
        TaskEventsLive([_event(ids.last, 6, 'answer_ready')]),
      );
      await tester.pumpAndSettle();
      p = _position(tester);
      expect(p.maxScrollExtent, greaterThan(before));
      expect(p.pixels, closeTo(p.maxScrollExtent, 1));
      expect(_text('Tin mới'), findsNothing);
    });

    testWidgets('a failed send: friendly words, "Gửi lại" with the same id', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      repo.error = {'startTask': const AssistantException('internal')};
      await _pump(tester, repo: repo);
      await _type(tester, 'Hôm nay con bú thế nào?');
      await tester.tap(find.bySemanticsLabel('Gửi').last);
      await tester.pumpAndSettle();
      expect(_text('Chưa gửi được'), findsOneWidget);
      expect(
        _text(
          'Mình chưa trả lời được lúc này. Chưa có gì được lưu và không trừ lượt nào — bạn thử lại nhé, hoặc ghi trực tiếp.',
        ),
        findsOneWidget,
      );
      expect(_text('Ghi trực tiếp'), findsOneWidget);
      repo.error = null;
      await tester.tap(_text('Gửi lại'));
      await tester.pumpAndSettle();
      final starts = repo.named('startTask');
      expect(starts, hasLength(2));
      expect(starts[0].args['requestId'], starts[1].args['requestId']);
      expect(_text('Chưa gửi được'), findsNothing);
      expect(_text('Cữ bú bình'), findsOneWidget);
    });
  });

  group('clarification', () {
    Map<String, Object?> asked({String field = 'sleep.start'}) => snapshotWith(
      task: taskJson(
        state: 'awaiting_clarification',
        clarification: {
          'id': 'c1',
          'field': field,
          'question': {
            'vi': 'Bé ngủ lúc mấy giờ?',
            'en': 'When did the sleep start?',
          },
          'choices': [
            {
              'id': 'last_night',
              'label': {'vi': '21:00 tối qua', 'en': '9pm last night'},
            },
          ],
          'allowText': true,
        },
      ),
      messages: [
        userMessage('Bé ngủ 9 tiếng'),
        assistantMessage([
          {
            'type': 'clarification',
            'schemaVersion': 1,
            'clarification': {
              'id': 'c1',
              'field': field,
              'question': {
                'vi': 'Bé ngủ lúc mấy giờ?',
                'en': 'When did the sleep start?',
              },
              'choices': const <Object>[],
              'allowText': true,
            },
          },
        ]),
      ],
    );

    testWidgets('"Khác…" opens a time picker that previews the computed end', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: asked()})
        ..clarifyGate = Completer<void>();
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(_text('21:00 tối qua'), findsOneWidget);
      await tester.tap(_text('Khác…'));
      await tester.pumpAndSettle();
      // The length is known from "9 tiếng": only the start is asked, the end is computed.
      expect(_text('Bé ngủ lúc mấy giờ?'), findsWidgets);
      expect(_text('Theo thời lượng bạn nói: 9 giờ'), findsOneWidget);
      final wheel = tester.widget<CupertinoDatePicker>(
        find.byKey(const ValueKey('as.clarifyWheel')),
      );
      wheel.onDateTimeChanged(DateTime(2000, 1, 1, 21, 30));
      await tester.pump();
      expect(_text('21:30 hôm qua – 06:30 · 9 giờ'), findsOneWidget);
      await tester.tap(_text('Trả lời: 21:30'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Sent in the same task (0 credits); my answer shows at once and the chips step aside.
      final c = repo.named('submitClarification').single.args;
      expect(c['text'], '21:30');
      expect(c['choiceId'], isNull);
      expect(repo.named('quoteTask'), isEmpty);
      expect(_text('21:30'), findsOneWidget);
      expect(_text('Khác…'), findsNothing);
      expect(_text('Lumi đang soạn…'), findsOneWidget);
      // The server's message takes the same place (one bubble), the task goes on.
      repo.tasks[taskA] = snapshotWith(
        task: taskJson(state: 'queued', version: 4),
        messages: [
          ...(asked()['messages']! as List).cast<Map<String, Object?>>(),
          {...userMessage('21:30'), 'id': 'm_answer', 'sequence': 3},
        ],
      );
      repo.clarifyGate!.complete();
      await tester.pumpAndSettle();
      expect(_text('21:30'), findsOneWidget);
      expect(_text('Lumi đang soạn…'), findsOneWidget);
    });

    testWidgets(
      'a chip answers at once; a refused answer gives the chips back',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {taskA: asked(field: 'sleep.period')},
        );
        repo.error = {
          'submitClarification': const AssistantException(
            'failed-precondition',
            reason: AssistantReason.invalidState,
          ),
        };
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        await tester.tap(_text('21:00 tối qua'));
        await tester.pumpAndSettle();
        expect(_text('21:00 tối qua'), findsOneWidget);
        expect(_text('Khác…'), findsOneWidget);
      },
    );
  });

  group('linked time editing', () {
    Future<void> openSleep(
      WidgetTester tester,
      FakeAssistantRepository repo,
    ) async {
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await tester.tap(_text('Sửa').last);
      await tester.pumpAndSettle();
      expect(_text('Sửa giấc ngủ'), findsOneWidget);
    }

    CupertinoDatePicker wheel(WidgetTester tester) =>
        tester.widget<CupertinoDatePicker>(
          find.descendant(
            of: find.byType(BottomSheet).hitTestable().evaluate().isEmpty
                ? find.byType(Navigator).last
                : find.byType(BottomSheet),
            matching: find.byType(CupertinoDatePicker),
          ),
        );

    testWidgets('start keeps the length; length and end move the end', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot()},
        patchAnswer: (args) => sleepDraftJson(revision: 2),
      );
      await openSleep(tester, repo);
      expect(_text('09:00 – 10:00 · 1 giờ'), findsOneWidget);
      // + 15 minutes: the end follows.
      await tester.tap(find.bySemanticsLabel('Dài hơn 15 phút'));
      await tester.pump();
      expect(_text('09:00 – 10:15 · 1 giờ 15 phút'), findsOneWidget);
      // A new start keeps 1 h 15.
      await tester.tap(find.byKey(const ValueKey('as.edit.start')));
      await tester.pumpAndSettle();
      wheel(tester).onDateTimeChanged(DateTime(2000, 1, 1, 8, 0));
      await tester.pump();
      expect(_text('08:00 – 09:15 · 1 giờ 15 phút'), findsOneWidget);
      // A new end changes the length.
      await tester.tap(find.byKey(const ValueKey('as.edit.end')));
      await tester.pumpAndSettle();
      wheel(tester).onDateTimeChanged(DateTime(2000, 1, 1, 10, 0));
      await tester.pump();
      expect(_text('08:00 – 10:00 · 2 giờ'), findsOneWidget);
      await tester.tap(_text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      final payload =
          repo.named('patchDraft').single.args['payload']!
              as Map<String, Object?>;
      expect(payload['startedAt'], '2026-10-15T01:00:00.000Z');
      expect(payload['endedAt'], '2026-10-15T03:00:00.000Z');
    });

    testWidgets('across midnight: "hôm qua", and a new start keeps 9 hours', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(),
            drafts: [
              sleepDraftJson(
                start: '2026-10-14T14:00:00.000Z',
                end: '2026-10-14T23:00:00.000Z',
              ),
            ],
            messages: [
              userMessage('Tối qua bé ngủ 9 tiếng từ 9 giờ'),
              assistantMessage([draftRef(draftOf(taskA, 1))]),
            ],
          ),
        },
      );
      await openSleep(tester, repo);
      expect(_text('21:00 hôm qua – 06:00 · 9 giờ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('as.edit.start')));
      await tester.pumpAndSettle();
      wheel(tester).onDateTimeChanged(DateTime(2000, 1, 1, 22, 0));
      await tester.pump();
      expect(_text('22:00 hôm qua – 07:00 · 9 giờ'), findsOneWidget);
      // An end picked before the start's clock is the next morning.
      await tester.tap(find.byKey(const ValueKey('as.edit.end')));
      await tester.pumpAndSettle();
      wheel(tester).onDateTimeChanged(DateTime(2000, 1, 1, 5, 30));
      await tester.pump();
      expect(_text('22:00 hôm qua – 05:30 · 7 giờ 30 phút'), findsOneWidget);
    });

    testWidgets('bottle: stepper and quick amounts', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot()},
        patchAnswer: (args) => bottleDraftJson(ml: 150, revision: 2),
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await tester.tap(_text('Sửa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Thêm 10 ml'));
      await tester.pump();
      await tester.tap(_text('150 ml'));
      await tester.pump();
      await tester.tap(_text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      final payload =
          repo.named('patchDraft').single.args['payload']!
              as Map<String, Object?>;
      expect(payload['amountMl'], 150);
    });
  });

  group('motion', () {
    testWidgets('a new entry fades and rises in; Reduce Motion only fades', (
      tester,
    ) async {
      for (final reduce in [false, true]) {
        final repo = FakeAssistantRepository()..startGate = Completer<void>();
        await _pumpMoving(tester, repo: repo, reduceMotion: reduce);
        await tester.enterText(find.byType(TextField).first, 'Bé ngủ chưa?');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const ValueKey('as.send')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final enter = find.ancestor(
          of: _text('Bé ngủ chưa?'),
          matching: find.byType(AsEnter),
        );
        final fade = tester.widget<FadeTransition>(
          find
              .descendant(of: enter, matching: find.byType(FadeTransition))
              .first,
        );
        expect(fade.opacity.value, lessThan(1));
        final moving = find.descendant(
          of: enter,
          matching: find.byWidgetPredicate(
            (w) => w is Transform && w.transform.getTranslation().y != 0,
          ),
        );
        expect(moving, reduce ? findsNothing : findsOneWidget);
        await tester.pump(const Duration(milliseconds: 600));
        expect(fade.opacity.value, 1);
        repo.startGate!.complete();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('history appears at once (no entrance on restore)', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      for (final f in tester.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(AsEnter),
          matching: find.byType(FadeTransition),
        ),
      )) {
        expect(f.opacity.value, 1);
      }
      expect(
        tester
            .widgetList<AsEnter>(find.byType(AsEnter))
            .every((e) => !e.animate),
        isTrue,
      );
    });
  });

  group('voice input', () {
    Future<FakeDictation> listen(
      WidgetTester tester, {
      DictationReady ready = DictationReady.ready,
      bool introSeen = false,
      FakeAssistantRepository? repo,
    }) async {
      final dictation = FakeDictation(ready: ready);
      await _pump(
        tester,
        repo: repo ?? FakeAssistantRepository(),
        dictation: dictation,
        prefs: {if (introSeen) 'assistant.voiceIntro.u_mai': true},
      );
      await tester.tap(find.bySemanticsLabel('Nói với Lumi'));
      await tester.pumpAndSettle();
      return dictation;
    }

    testWidgets(
      'explainer once, then words stream into the field; sent only on "Gửi"',
      (tester) async {
        final repo = FakeAssistantRepository();
        final d = await listen(tester, repo: repo);
        // First time: what is heard, who turns it into words, nothing kept, no credits.
        expect(_text('Nói với Lumi thay vì gõ'), findsOneWidget);
        expect(
          _text(
            'Child Life không ghi âm, không lưu và không gửi âm thanh. Chỉ phần chữ bạn bấm Gửi mới tới Lumi.',
          ),
          findsOneWidget,
        );
        expect(d.prepared, 0);
        await tester.tap(_text('Bật micro'));
        await tester.pumpAndSettle();
        expect(d.languages, ['vi']);
        expect(_text('Đang nghe… vuốt sang trái để huỷ'), findsOneWidget);
        d.level(0.8);
        d.say('con bú');
        await tester.pump();
        expect(_field(tester).controller!.text, 'con bú');
        d.say('con bú 120 ml lúc 8 giờ', done: true);
        await tester.pumpAndSettle();
        expect(_field(tester).controller!.text, 'con bú 120 ml lúc 8 giờ');
        expect(d.stops, 1);
        expect(_text('Đang nghe…'), findsNothing);
        // Nothing went to Lumi: the parent still taps "Gửi".
        expect(repo.named('quoteTask'), isEmpty);
        expect(find.bySemanticsLabel('Gửi'), findsWidgets);
        // The explainer does not come back.
        _field(tester).controller!.clear();
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Nói với Lumi'));
        await tester.pumpAndSettle();
        expect(_text('Nói với Lumi thay vì gõ'), findsNothing);
        expect(d.languages, ['vi', 'vi']);
      },
    );

    testWidgets('× and a swipe left put the field back as it was', (
      tester,
    ) async {
      final d = FakeDictation();
      await _pump(
        tester,
        repo: FakeAssistantRepository(),
        dictation: d,
        prefs: {'assistant.voiceIntro.u_mai': true},
      );
      await _type(tester, 'Ghi:');
      // With words in the field the trailing button is "Gửi"; the mic shows on an empty field.
      expect(find.bySemanticsLabel('Nói với Lumi'), findsNothing);
      _field(tester).controller!.clear();
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Nói với Lumi'));
      await tester.pumpAndSettle();
      d.say('ngủ từ 9 giờ');
      await tester.pump();
      expect(_field(tester).controller!.text, 'ngủ từ 9 giờ');
      await tester.tap(find.bySemanticsLabel('Bỏ lời vừa nói'));
      await tester.pumpAndSettle();
      expect(_field(tester).controller!.text, isEmpty);
      expect(d.cancels, 1);
      // Swipe left on the listening composer.
      await tester.tap(find.bySemanticsLabel('Nói với Lumi'));
      await tester.pumpAndSettle();
      d.say('abc');
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('as.voice.listening')),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      expect(_field(tester).controller!.text, isEmpty);
      expect(d.cancels, 2);
    });

    testWidgets('stops by itself after a pause; nothing heard says so', (
      tester,
    ) async {
      final d = await listen(tester, introSeen: true);
      d.say('bé ngủ 9 tiếng');
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(d.stops, 1);
      expect(_field(tester).controller!.text, 'bé ngủ 9 tiếng');
      _field(tester).controller!.clear();
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Nói với Lumi'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(d.stops, 2);
      expect(
        _text('Mình chưa nghe thấy gì. Thử nói gần máy hơn nhé.'),
        findsOneWidget,
      );
    });

    testWidgets('denied: the way to Settings; the mic stays', (tester) async {
      await listen(tester, ready: DictationReady.denied, introSeen: true);
      expect(
        _text(
          'Chưa có quyền dùng micro hoặc nhận dạng giọng nói. Bật trong Cài đặt để nói với Lumi.',
        ),
        findsOneWidget,
      );
      expect(_text('Mở Cài đặt'), findsOneWidget);
      expect(find.bySemanticsLabel('Nói với Lumi'), findsOneWidget);
    });

    testWidgets('no recogniser / no language: explained, then the mic hides', (
      tester,
    ) async {
      await listen(tester, ready: DictationReady.unavailable, introSeen: true);
      expect(
        _text('Máy này chưa nhận dạng giọng nói được. Bạn gõ chữ nhé.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Nói với Lumi'), findsNothing);
      expect(find.bySemanticsLabel('Gửi'), findsWidgets);
    });

    testWidgets('the app going to the background stops and keeps the words', (
      tester,
    ) async {
      final d = await listen(tester, introSeen: true);
      d.say('con bú 90 ml');
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(d.stops, 1);
      expect(_field(tester).controller!.text, 'con bú 90 ml');
    });
  });

  testWidgets('large text: header, thread, composer and the sleep editor fit', (
    tester,
  ) async {
    final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
    await _pumpMoving(
      tester,
      repo: repo,
      reduceMotion: true,
      textScale: 1.6,
      stored: _thread([taskA]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_text('Sửa').last);
    await tester.pumpAndSettle();
    await tester.tap(_text('Sửa').last);
    await tester.pumpAndSettle();
    expect(_text('Sửa giấc ngủ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('as.edit.start')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a viewer never sees the mic or log suggestions', (tester) async {
    await pumpRouted(
      tester,
      AssistantChatScreen(scopeKey: teddyScope.key),
      prefs: {
        'assistant.conversation.u_hoa:${teddyScope.key}': conversation1,
        'assistant.tasks.u_hoa:${teddyScope.key}': [taskA],
      },
      overrides: assistantOverrides(
        repo: FakeAssistantRepository(tasks: {taskA: batchSnapshot()}),
        me: hoa,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Nói với Lumi'), findsNothing);
    expect(_text('Ghi cữ bú'), findsNothing);
    expect(_text('Cữ bú hôm nay'), findsOneWidget);
  });
}
