@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
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

/// Child Life Assistant slice A5, Light / Night care × vi / en (the chat frames have no Night
/// twin; every colour is a token): CH09 photo sheet and chosen photo with its exact quote,
/// CH10 uploading and reading, CH11 receipt to check, CH12 saved expense, CH13 note lines,
/// CH14 unreadable and mixed, CH15 sleep questions, CH16 guidance, CH17 follow-up, CH18
/// recipes. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/assistant_a5_golden_test.dart

typedef _Case = ({
  double height,
  AssistantScope scope,
  FakeAssistantRepository Function() repo,
  List<String> tasks,
  Membership? me,
  FakeUploader Function()? uploader,
  Future<void> Function(WidgetTester tester, FakeUploader uploader)? act,
});

_Case _c({
  double height = 812,
  AssistantScope? scope,
  FakeAssistantRepository Function()? repo,
  List<String> tasks = const [taskA],
  Membership? me,
  FakeUploader Function()? uploader,
  Future<void> Function(WidgetTester tester, FakeUploader uploader)? act,
}) => (
  height: height,
  scope: scope ?? householdScope,
  repo: repo ?? FakeAssistantRepository.new,
  tasks: tasks,
  me: me,
  uploader: uploader,
  act: act,
);

FakeAssistantRepository _one(Map<String, Object?> snapshot) =>
    FakeAssistantRepository(tasks: {taskA: snapshot});

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp(r'^(Ảnh|Photo)$')).last);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester) async {
  await _openSheet(tester);
  await tester.tap(
    find.textContaining(RegExp(r'^(Chọn từ thư viện|Choose from library)$')),
  );
  await tester.pumpAndSettle();
}

Map<String, Object?> _noteDrafts() => photoSnapshot(
  task: photoTaskJson(),
  parts: [
    textPart(
      'Không chuyển thành việc:\n“Bé cười nhiều quá!”: ghi chú, không phải việc '
      'cần làm.\n1 dòng về thuốc: không tạo lịch hay liều dùng thuốc. Hỏi bác sĩ.',
    ),
    draftRef(draftOf(taskA, 0)),
    draftRef(draftOf(taskA, 1)),
    draftRef(draftOf(taskA, 2)),
  ],
  drafts: [
    // D-075 #5: the assignee the person picked (never a name read from the photo).
    reminderDraftJson(assignee: 'u_minh'),
    // A date without a time saves as an all-day reminder.
    reminderDraftJson(
      index: 1,
      title: 'Mua bỉm size S',
      date: '2026-10-17',
      time: null,
    ),
    reminderDraftJson(
      index: 2,
      title: 'Gọi phòng khám',
      date: '2026-10-14',
      state: 'needs_review',
      problems: ['PAST_TIME'],
    ),
  ],
);

Map<String, Object?> _care({
  Map<String, Object?>? care,
  bool draft = true,
  bool reviewed = false,
}) => snapshotWith(
  task: careTaskJson(care: care ?? sleepCare()),
  drafts: [if (draft) observationDraftJson()],
  messages: [
    userMessage('Khó vào giấc · giấc đêm'),
    assistantMessage([
      guidancePart(reviewed: reviewed),
      if (draft) draftRef(draftOf(taskA, 0)),
    ]),
  ],
);

/// D-075 #2: Cô Lan's feed (saved by her) and Mẹ's own question in the baby's shared thread.
FakeAssistantRepository _shared() {
  final lanMessage = sharedUserMessage('8 giờ con bú bình 120 ml', lan);
  final maiMessage = sharedUserMessage(
    'Hôm nay con bú thế nào?',
    mai,
    taskId: taskB,
    sequence: 4,
  );
  return FakeAssistantRepository(
    tasks: {
      taskA: snapshotWith(
        task: sharedTaskJson(by: lan),
        drafts: [
          {
            ...bottleDraftJson(state: 'saved', recordId: 'r_${'c' * 32}'),
            'confirmedBy': authorJson(lan),
          },
        ],
        messages: [
          lanMessage,
          assistantMessage([draftRef(draftOf(taskA, 0))]),
          {
            ...assistantMessage([
              {
                'type': 'action_result',
                'schemaVersion': 1,
                'items': [
                  {
                    'draftId': draftOf(taskA, 0),
                    'status': 'saved',
                    'recordLink': null,
                    'errorCode': null,
                  },
                ],
              },
            ], sequence: 3),
            'author': authorJson(lan),
          },
        ],
      ),
      taskB: snapshotWith(
        task: sharedTaskJson(by: mai, id: taskB),
        messages: [
          maiMessage,
          assistantMessage([summaryPart()], taskId: taskB, sequence: 5),
        ],
      ),
    },
    messagesAnswer: () => [lanMessage, maiMessage],
  );
}

final _cases = <String, _Case>{
  'd075_shared_thread': _c(
    height: 1000,
    scope: teddyScope,
    repo: _shared,
    tasks: const [],
  ),
  'ch09_sheet': _c(act: (t, _) => _openSheet(t)),
  'ch09_photo': _c(height: 900, act: (t, _) => _choose(t)),
  'ch10_upload': _c(
    uploader: () => FakeUploader(auto: false),
    act: (t, u) async {
      await _choose(t);
      await t.tap(find.textContaining(RegExp(r'^(Gửi ảnh|Send photo)$')));
      await t.pump();
      await t.pump();
      u.uploads.single.push(0.6);
      await t.pump();
      await t.pump();
    },
  ),
  'ch10_reading': _c(
    repo: () => _one(photoSnapshot(task: photoTaskJson(state: 'processing'))),
  ),
  'ch11_receipt': _c(
    height: 1000,
    repo: () => _one(
      photoSnapshot(
        task: photoTaskJson(),
        parts: [
          textPart(
            'Tổng tiền đã gồm thuế: chỉ ghi một khoản, không cộng thêm tạm tính '
            'hay thuế.',
          ),
          draftRef(draftOf(taskA, 0)),
        ],
        drafts: [expenseDraftJson()],
      ),
    ),
  ),
  // D-075 #4: a USD receipt, in Chi tiêu's money format.
  'ch11_receipt_usd': _c(
    height: 900,
    repo: () => _one(
      photoSnapshot(
        task: photoTaskJson(),
        parts: [draftRef(draftOf(taskA, 0))],
        drafts: [
          {
            ...expenseDraftJson(state: 'draft', uncertain: [], warnings: []),
            'payload': {
              ...(expenseDraftJson()['payload']! as Map<String, Object?>),
              'merchant': 'Target',
              'currency': 'USD',
              'totalMinor': 4599,
              'subtotalMinor': 4250,
              'taxMinor': 349,
            },
          },
        ],
      ),
    ),
  ),
  'ch12_saved': _c(
    repo: () => _one(
      photoSnapshot(
        task: photoTaskJson(),
        parts: [draftRef(draftOf(taskA, 0))],
        drafts: [
          expenseDraftJson(
            state: 'saved',
            uncertain: [],
            warnings: [],
            recordId: 'x_${'e' * 32}',
          ),
        ],
        attachments: [attachmentJson(state: 'deleted', kept: true)],
      ),
    ),
  ),
  'ch13_notes': _c(height: 1100, repo: () => _one(_noteDrafts())),
  'ch14_unreadable': _c(
    scope: teddyScope,
    repo: () => _one(
      photoSnapshot(
        task: photoTaskJson(
          state: 'failed',
          errorCode: 'OCR_UNREADABLE',
          scopeType: 'child',
        ),
        parts: [
          textPart(
            'Ảnh hơi mờ nên mình chưa đọc chắc được. Bạn chụp lại gần hơn, đủ '
            'sáng, hoặc nhập tay nhé.',
          ),
        ],
        attachments: [
          attachmentJson(
            state: 'deleted',
            retention: 'delete_after_read',
            deletedAt: '2026-10-15T07:21:00.000Z',
          ),
        ],
      ),
    ),
  ),
  'ch14_mixed': _c(
    scope: teddyScope,
    repo: () => _one(
      photoSnapshot(
        task: photoTaskJson(
          state: 'awaiting_clarification',
          scopeType: 'child',
          clarification: {
            'id': 'c3',
            'field': 'image.intent',
            'question': {
              'vi': 'Bạn muốn làm gì với ảnh này?',
              'en': 'What would you like to do with this photo?',
            },
            'choices': [
              {
                'id': 'expense',
                'label': {'vi': 'Ghi chi tiêu', 'en': 'Log expense'},
              },
              {
                'id': 'none',
                'label': {'vi': 'Không làm gì', 'en': 'Nothing'},
              },
            ],
            'allowText': false,
          },
        ),
        parts: [
          textPart(
            'Ảnh có nhiều loại nội dung. Mình sẽ không tự xử lý tất cả.',
          ),
          textPart(
            'Phần thuốc trong ảnh sẽ không được chuyển thành lịch hay liều.',
          ),
        ],
      ),
    ),
  ),
  'ch15_sleep': _c(
    scope: teddyScope,
    repo: () => _one(
      snapshotWith(
        task: careTaskJson(
          state: 'awaiting_clarification',
          clarification: sleepClarification('sleep.when'),
          care: {'topic': 'sleep_concern'},
        ),
        messages: [
          userMessage('Con hôm nay khó ngủ'),
          assistantMessage([
            {
              'type': 'clarification',
              'schemaVersion': 1,
              'clarification': sleepClarification('sleep.period'),
            },
          ]),
          {...userMessage('Khó vào giấc'), 'id': 'm_a_u2', 'sequence': 3},
        ],
      ),
    ),
  ),
  'ch16_guidance': _c(
    height: 1100,
    scope: teddyScope,
    repo: () => _one(_care()),
  ),
  'ch17_feedback': _c(
    height: 1200,
    scope: teddyScope,
    repo: () => _one(
      _care(draft: false, care: sleepCare(plan: planJson(), followUp: true)),
    ),
  ),
  'ch18_recipes': _c(
    height: 900,
    scope: teddyScope,
    repo: () => _one(
      snapshotWith(
        task: careTaskJson(care: {'topic': 'meal_ideas'}),
        messages: [
          userMessage('Hôm nay con ăn gì?'),
          assistantMessage([recipesPart()]),
        ],
      ),
    ),
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          final uid = (c.me ?? mai).uid;
          SharedPreferences.setMockInitialValues({
            if (c.tasks.isNotEmpty && c.act == null) ...{
              'assistant.conversation.$uid:${c.scope.key}': conversation1,
              'assistant.tasks.$uid:${c.scope.key}': c.tasks,
            },
          });
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = Size(375, c.height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final uploader = c.uploader?.call() ?? FakeUploader();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...assistantOverrides(
                  repo: c.repo(),
                  me: c.me,
                  images: true,
                  uploader: uploader,
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
                    home: AssistantChatScreen(scopeKey: c.scope.key),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await c.act?.call(tester, uploader);
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
