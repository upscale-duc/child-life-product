@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';

/// Lumi 2026-10-16, Light / Night care × vi / en: the timer card from chat ("Con đang ngủ" →
/// "Bắt đầu tính giờ ngủ · 14:20"), the running timer with "Kết thúc" / "Để tiếp tục", and the
/// review card that explains and fixes in place (a breastfeed missing its side, the single-draft
/// layout with its own save) and, with several drafts, a fixed draft ticked by itself ("Lưu 2
/// mục"). Lumi fixes (LUMI-01): pump, diaper and growth drafts, ready and needing review.
/// Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/assistant_timer_golden_test.dart

const _session = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
final _started = assistantNow.subtract(const Duration(minutes: 40));

Map<String, Object?> _one(
  Map<String, Object?> draft,
  String said, {
  List<Map<String, Object?>> before = const [],
}) => snapshotWith(
  task: taskJson(),
  drafts: [draft],
  messages: [
    userMessage(said),
    assistantMessage([...before, draftRef(draft['id']! as String)]),
  ],
);

Map<String, Object?> _batch() => snapshotWith(
  task: taskJson(),
  drafts: [
    reviewed(bottleDraftJson(), uncertain: ['amountMl']),
    sleepDraftJson(),
  ],
  messages: [
    userMessage('8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.'),
    assistantMessage([
      draftRef(draftOf(taskA, 0)),
      draftRef(draftOf(taskA, 1)),
    ]),
  ],
);

typedef _Case = ({
  FakeAssistantRepository Function() repo,
  Map<TimerType, CareTimer> timers,
  Future<void> Function(WidgetTester tester)? act,
});

final _cases = <String, _Case>{
  'timer_start': (
    repo: () => FakeAssistantRepository(
      tasks: {taskA: _one(timerDraftJson(), 'Con đang ngủ')},
    ),
    timers: const {},
    act: null,
  ),
  'timer_running': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(
          timerDraftJson(
            action: 'stop',
            sessionId: _session,
            startedAt: _started.toIso8601String(),
          ),
          'Con đang ngủ',
          before: [
            {
              ...codedText(
                'Bé đang ngủ, đồng hồ đã tính giờ từ 13:40. Kết thúc giấc ngủ bây giờ, hay để đồng hồ tiếp tục?',
                'TIMER_RUNNING',
              ),
              'link': '/care/timer/sleep',
            },
          ],
        ),
      },
    ),
    timers: {TimerType.sleep: runningTimer(startedAt: _started)},
    act: null,
  ),
  'review_breast': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(
          reviewed(breastDraftJson(), missing: ['side']),
          'Con đã bú mẹ được 20p',
        ),
      },
    ),
    timers: const {},
    act: null,
  ),
  'review_batch': (
    repo: () => FakeAssistantRepository(tasks: {taskA: _batch()}),
    timers: const {},
    act: null,
  ),
  // LUMI-01: a pump, a diaper change and a measurement from chat, ready (one tap saves) and
  // needing review (the fix in place); the measurement says what was not saved (LUMI-13).
  'care_pump': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(pumpDraftJson(), 'hút sữa 120ml bên trái 15 phút lúc 10h'),
      },
    ),
    timers: const {},
    act: null,
  ),
  'care_pump_review': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(
          reviewed(
            pumpDraftJson(ml: null, side: 'both'),
            missing: ['amountMl'],
            uncertain: ['side'],
          ),
          'vừa hút sữa xong',
        ),
      },
    ),
    timers: const {},
    act: null,
  ),
  'care_diaper': (
    repo: () => FakeAssistantRepository(
      tasks: {taskA: _one(diaperDraftJson(), 'thay tã ướt lúc 13h')},
    ),
    timers: const {},
    act: null,
  ),
  'care_diaper_review': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(
          reviewed(diaperDraftJson(diaper: null), missing: ['diaper']),
          'thay tã lúc 13h',
        ),
      },
    ),
    timers: const {},
    act: null,
  ),
  'care_growth': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(
          growthDraftJson(),
          'bé nặng 5,2kg dài 62cm vòng đầu 40cm',
          before: [
            {
              ...codedText(
                'Mục Tăng trưởng chưa có vòng đầu, nên mình chưa ghi số đo vòng đầu. Cân nặng và chiều dài ở bản nháp bên dưới.',
                'PART_NOT_SAVED',
              ),
              'link': '/care/growth',
            },
          ],
        ),
      },
    ),
    timers: const {},
    act: null,
  ),
  'care_growth_review': (
    repo: () => FakeAssistantRepository(
      tasks: {
        taskA: _one(
          reviewed(
            growthDraftJson(cm: 200, on: null),
            missing: ['measuredOn'],
            uncertain: ['weightKg'],
          ),
          'bé nặng 5,2kg dài 200cm',
        ),
      },
    ),
    timers: const {},
    act: null,
  ),
  'review_batch_fixed': (
    repo: () => FakeAssistantRepository(
      tasks: {taskA: _batch()},
      patchAnswer: (_) => bottleDraftJson(revision: 2),
    ),
    timers: const {},
    act: (tester) async {
      await tester.tap(find.byKey(const ValueKey('as.fix.amountMl.0')));
      await tester.pumpAndSettle();
    },
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          final scopeKey = teddyScope.key;
          SharedPreferences.setMockInitialValues({
            'assistant.conversation.u_mai:$scopeKey': conversation1,
            'assistant.tasks.u_mai:$scopeKey': [taskA],
            'assistant.voiceIntro.u_mai': true,
          });
          final prefs = await SharedPreferences.getInstance();
          const size = Size(375, 812);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...assistantOverrides(
                  repo: c.repo(),
                  timers: c.timers,
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
          await c.act?.call(tester);
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
