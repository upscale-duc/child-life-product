@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';

/// The Lumi chat rework (2026-10-15), Light / Night care × vi / en: the empty chat, a
/// conversation (my words, Lumi's run with her name, a draft card and the save bar), "Lumi đang
/// soạn…", the sleep editor with linked times across midnight, a spending draft with its
/// "Chỉ bạn thấy", a question with chips and "Khác…", its time picker with the computed
/// wake-up, and voice input while listening. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/assistant_chat_golden_test.dart

typedef _Case = ({
  AssistantScope scope,
  FakeAssistantRepository Function() repo,
  List<String> tasks,
  FakeDictation Function()? dictation,
  Future<void> Function(WidgetTester tester, FakeDictation d)? act,
});

_Case _c({
  AssistantScope? scope,
  FakeAssistantRepository Function()? repo,
  List<String> tasks = const [],
  Future<void> Function(WidgetTester tester, FakeDictation d)? act,
}) => (
  scope: scope ?? teddyScope,
  repo: repo ?? FakeAssistantRepository.new,
  tasks: tasks,
  dictation: null,
  act: act,
);

/// "Bé ngủ 9 tiếng từ 9 giờ tối qua": one sleep, 21:00 yesterday → 06:00.
Map<String, Object?> _sleepNight() => snapshotWith(
  task: taskJson(),
  drafts: [
    sleepDraftJson(
      index: 0,
      start: '2026-10-14T14:00:00.000Z',
      end: '2026-10-14T23:00:00.000Z',
    ),
  ],
  messages: [
    userMessage('Tối qua bé ngủ 9 tiếng từ 9 giờ'),
    assistantMessage([
      textPart('Mình ghi giấc ngủ đêm qua nhé. Kiểm tra giờ rồi lưu.'),
      draftRef(draftOf(taskA, 0)),
    ]),
  ],
);

Map<String, Object?> _asked() {
  final c = {
    'id': 'c1',
    'field': 'sleep.start',
    'question': {
      'vi': 'Bé bắt đầu ngủ lúc mấy giờ?',
      'en': 'What time did the sleep start?',
    },
    'choices': [
      {
        'id': 'a',
        'label': {'vi': '20:00 tối qua', 'en': '8pm last night'},
      },
      {
        'id': 'b',
        'label': {'vi': '21:00 tối qua', 'en': '9pm last night'},
      },
    ],
    'allowText': true,
  };
  return snapshotWith(
    task: taskJson(state: 'awaiting_clarification', clarification: c),
    messages: [
      userMessage('Bé ngủ 9 tiếng'),
      assistantMessage([
        {'type': 'clarification', 'schemaVersion': 1, 'clarification': c},
      ]),
    ],
  );
}

final _cases = <String, _Case>{
  'chat_empty': _c(),
  'chat_conversation': _c(
    repo: () => FakeAssistantRepository(tasks: {taskA: batchSnapshot()}),
    tasks: [taskA],
  ),
  'chat_typing': _c(
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(state: 'processing', version: 2),
          messages: [userMessage('Hôm nay con bú thế nào?')],
        ),
      },
    ),
    tasks: [taskA],
  ),
  'chat_sleep_edit': _c(
    repo: () => FakeAssistantRepository(tasks: {taskA: _sleepNight()}),
    tasks: [taskA],
    act: (tester, _) async {
      await tester.tap(find.byWidgetPredicate(_editAction).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('as.edit.start')));
      await tester.pumpAndSettle();
    },
  ),
  'chat_expense_draft': _c(
    scope: householdScope,
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(scopeType: 'household'),
          drafts: [
            expenseDraftJson(
              state: 'draft',
              uncertain: const [],
              warnings: const [],
            ),
          ],
          messages: [
            userMessage('Mua sữa ở Con Cưng 486k hôm qua'),
            assistantMessage([
              textPart('Mình soạn một khoản chi. Kiểm tra rồi lưu nhé.'),
              draftRef(draftOf(taskA, 0)),
            ]),
          ],
        ),
      },
    ),
    tasks: [taskA],
  ),
  'chat_clarify': _c(
    repo: () => FakeAssistantRepository(tasks: {taskA: _asked()}),
    tasks: [taskA],
  ),
  'chat_clarify_time': _c(
    repo: () => FakeAssistantRepository(tasks: {taskA: _asked()}),
    tasks: [taskA],
    act: (tester, _) async {
      // Opens at "woke up now" for the said 9 hours; the wake-up is computed live.
      await tester.tap(find.byWidgetPredicate(_otherChip).first);
      await tester.pumpAndSettle();
    },
  ),
  'chat_voice': _c(
    repo: () => FakeAssistantRepository(tasks: {taskA: batchSnapshot()}),
    tasks: [taskA],
    act: (tester, d) async {
      await tester.tap(find.byWidgetPredicate(_micButton).first);
      await tester.pumpAndSettle();
      d
        ..level(0.7)
        ..say('Con bú bình 120 ml lúc 8 giờ');
      await tester.pumpAndSettle();
    },
  ),
};

bool _editAction(Widget w) =>
    w is Semantics &&
    (w.properties.label == 'Sửa' || w.properties.label == 'Edit');

bool _otherChip(Widget w) =>
    w is Semantics &&
    (w.properties.label == 'Khác…' || w.properties.label == 'Other…');

bool _micButton(Widget w) =>
    w is Semantics &&
    (w.properties.label == 'Nói với Lumi' ||
        w.properties.label == 'Talk to Lumi');

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          final scopeKey = c.scope.key;
          SharedPreferences.setMockInitialValues({
            if (c.tasks.isNotEmpty) ...{
              'assistant.conversation.u_mai:$scopeKey': conversation1,
              'assistant.tasks.u_mai:$scopeKey': c.tasks,
            },
            'assistant.voiceIntro.u_mai': true,
          });
          final prefs = await SharedPreferences.getInstance();
          const size = Size(375, 812);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final dictation = FakeDictation();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...assistantOverrides(
                  repo: c.repo(),
                  dictation: dictation,
                  paywall: (BuildContext _, PurchaseResume _) async => false,
                ),
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: size,
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp(
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
                    home: AssistantChatScreen(scopeKey: scopeKey),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await c.act?.call(tester, dictation);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/as/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
