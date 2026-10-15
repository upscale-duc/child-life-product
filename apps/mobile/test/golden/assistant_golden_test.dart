@Tags(['golden'])
library;

import 'dart:convert';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';

/// Child Life Assistant slice A4, Light / Night care × vi / en (the chat frames have no Night
/// twin; every colour is a token): CH01 Home entry, CH02 empty chat, CH04 drafts, CH05
/// clarification, CH06 edit sheet, CH07 partial save, CH08 read summary, CH19 usage, CH20 photo
/// blocked before send, CH21 Free exhausted, CH24 Premium exhausted, CH25 failure and offline,
/// CH26 consent, CH27 viewer / module / region, CH28 health. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/assistant_golden_test.dart

typedef _Case = ({
  double height,
  Widget Function() build,
  FakeAssistantRepository Function() repo,
  Map<String, Object> Function() prefs,
  Membership? me,
  bool online,
  bool images,
  String plan,
  VideoQuota? video,
  Future<void> Function(WidgetTester tester)? act,
});

String _k(String what, AssistantScope s, [String uid = 'u_mai']) =>
    'assistant.$what.$uid:${s.key}';

/// The stored thread of the chat: its tasks come back from `getAssistantTask`.
Map<String, Object> _thread(List<String> taskIds, [String uid = 'u_mai']) => {
  _k('conversation', teddyScope, uid): conversation1,
  _k('tasks', teddyScope, uid): taskIds,
};

Map<String, Object> _kept(String text, KeptReason reason) => {
  _k('kept', teddyScope): jsonEncode(
    KeptInput(
      text: text,
      requestId: '00000000-0000-4000-8000-000000000099',
      inputKey: '',
      reason: reason,
      at: assistantNow,
    ).toJson(),
  ),
};

Widget _chat() => AssistantChatScreen(scopeKey: teddyScope.key);

/// CH01: the Home entry card and the floating button, on the Hôm nay background.
Widget _home() => Builder(
  builder: (context) => Scaffold(
    backgroundColor: context.cl.colors.cloud,
    body: SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(ClSpace.s4),
            children: const [AssistantTodayCard()],
          ),
          const Positioned(
            right: ClSpace.s4,
            bottom: ClSpace.s4,
            child: AssistantFloatingEntry(),
          ),
        ],
      ),
    ),
  ),
);

FakeAssistantRepository _repo({
  Map<String, Map<String, Object?>> tasks = const {},
  Map<String, Object?>? usage,
  Object? Function(Map<String, Object?>)? quote,
  AssistantConsent consent = const AssistantConsent(
    version: assistantConsentVersion,
  ),
}) => FakeAssistantRepository(
  usage: usage,
  tasks: {...tasks},
  quoteAnswer: quote,
  consent: consent,
);

_Case _c({
  double height = 812,
  Widget Function() build = _chat,
  FakeAssistantRepository Function()? repo,
  Map<String, Object> Function()? prefs,
  Membership? me,
  bool online = true,
  bool images = false,
  String plan = 'free',
  VideoQuota? video,
  Future<void> Function(WidgetTester tester)? act,
}) => (
  height: height,
  build: build,
  repo: repo ?? _repo,
  prefs: prefs ?? () => const {},
  me: me,
  online: online,
  images: images,
  plan: plan,
  video: video,
  act: act,
);

final _cases = <String, _Case>{
  'ch01_home': _c(height: 420, build: _home, images: true),
  'ch02_empty': _c(),
  'ch04_drafts': _c(
    height: 900,
    repo: () => _repo(tasks: {taskA: batchSnapshot()}),
    prefs: () => _thread([taskA]),
  ),
  'ch05_clarify': _c(
    repo: () => _repo(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(
            state: 'awaiting_clarification',
            clarification: clarificationJson(),
          ),
          messages: [
            userMessage('Con bú 120 ml lúc 8 giờ, ngủ từ 10 giờ tới 9 giờ.'),
          ],
        ),
      },
    ),
    prefs: () => _thread([taskA]),
  ),
  'ch06_edit': _c(
    height: 900,
    repo: () => _repo(tasks: {taskA: batchSnapshot()}),
    prefs: () => _thread([taskA]),
    act: (tester) async {
      await tester.tap(find.byWidgetPredicate(_editAction).first);
      await tester.pumpAndSettle();
    },
  ),
  'ch07_partial': _c(
    height: 900,
    repo: () => _repo(
      tasks: {
        taskA: batchSnapshot(
          bottleState: 'saved',
          bottleMl: 150,
          bottleRevision: 2,
          sleepState: 'failed',
          sleepError: 'DOMAIN_CONFLICT',
          text: false,
        ),
      },
    ),
    prefs: () => _thread([taskA]),
  ),
  'ch08_summary': _c(
    repo: () => _repo(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(),
          messages: [
            userMessage('Hôm nay con bú thế nào?'),
            assistantMessage([summaryPart()]),
          ],
        ),
      },
    ),
    prefs: () => _thread([taskA]),
  ),
  'ch19_usage': _c(
    height: 1100,
    video: const VideoQuota(limit: 5, used: 1, reserved: 0),
    build: () => const AssistantUsageScreen(babyId: teddyId),
    repo: () => _repo(
      usage: usageJson(
        used: 5,
        recent: [
          {
            'modality': 'image',
            'credits': 3,
            'at': '2026-10-15T03:00:00.000Z',
            'who': 'Mẹ',
          },
          {
            'modality': 'text',
            'credits': 1,
            'at': '2026-10-15T02:00:00.000Z',
            'who': 'Mẹ',
          },
          {
            'modality': 'image',
            'credits': 0,
            'at': '2026-10-14T02:00:00.000Z',
            'who': 'Ba',
          },
        ],
      ),
    ),
  ),
  'ch20_photo': _c(
    images: true,
    repo: () => _repo(
      usage: usageJson(used: 18),
      quote: (args) => quoteJson(
        modality: 'image',
        allowed: false,
        reason: 'USAGE_EXHAUSTED',
        usage: usageJson(used: 18),
      ),
    ),
    act: (tester) async {
      await tester.tap(find.bySemanticsLabel(RegExp('^(Ảnh|Photo)\$')).first);
      await tester.pumpAndSettle();
    },
  ),
  'ch21_free_out': _c(
    repo: () => _repo(usage: usageJson(used: 20)),
    prefs: () => _kept('Hôm nay con bú thế nào?', KeptReason.blocked),
  ),
  'ch24_premium_out': _c(
    plan: 'premium',
    repo: () => _repo(
      usage: usageJson(
        plan: 'premium',
        limit: 200,
        used: 200,
        resetsAt: '2026-11-13T17:00:00.000Z',
      ),
    ),
    prefs: () => _kept('So với hôm qua thì sao?', KeptReason.blocked),
  ),
  'ch25_failure': _c(
    repo: () => _repo(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(state: 'failed', errorCode: 'AI_UNAVAILABLE'),
          messages: [userMessage('8 giờ con bú bình 120 ml')],
        ),
      },
    ),
    prefs: () => _thread([taskA]),
  ),
  'ch25_offline': _c(
    online: false,
    prefs: () => _kept('8 giờ con bú bình 120 ml', KeptReason.offline),
  ),
  'ch26_consent': _c(
    height: 900,
    repo: () => _repo(consent: const AssistantConsent()),
    prefs: () => _kept('Hôm nay con bú thế nào?', KeptReason.consent),
  ),
  'ch27_viewer': _c(
    height: 900,
    me: hoa,
    repo: () => _repo(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(state: 'failed', errorCode: 'WRITE_DENIED'),
          messages: [userMessage('Ghi giúp bà: 8 giờ con bú 120 ml')],
        ),
        taskB: snapshotWith(
          task: taskJson(
            id: taskB,
            state: 'failed',
            errorCode: 'REGION_UNSUPPORTED',
          ),
          messages: [
            userMessage('Con hay quấy tối, nên làm gì?', taskId: taskB),
          ],
        ),
      },
    ),
    prefs: () => _thread([taskA, taskB], 'u_hoa'),
  ),
  'ch27_module': _c(
    repo: () => _repo(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(state: 'failed', errorCode: 'MODULE_UNAVAILABLE'),
          messages: [userMessage('Thêm “mua bỉm” vào việc cần làm')],
        ),
      },
    ),
    prefs: () => _thread([taskA]),
  ),
  'ch28_health': _c(
    repo: () => _repo(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(),
          messages: [
            userMessage('Con sốt 38,5 độ, thở nhanh'),
            assistantMessage([
              {
                'type': 'health_support',
                'schemaVersion': 1,
                'signs': ['fever_young', 'breathing'],
              },
            ]),
          ],
        ),
      },
    ),
    prefs: () => _thread([taskA]),
  ),
};

/// The bottle card's "Sửa" / "Edit" action.
bool _editAction(Widget w) =>
    w is Semantics &&
    (w.properties.label == 'Sửa' || w.properties.label == 'Edit');

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues(c.prefs());
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = Size(375, c.height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...assistantOverrides(
                  repo: c.repo(),
                  me: c.me,
                  online: c.online,
                  images: c.images,
                  plan: c.plan,
                  video: c.video,
                  paywall: (BuildContext _, PurchaseResume _) async => false,
                ),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(375, c.height),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
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
                    home: c.build(),
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
