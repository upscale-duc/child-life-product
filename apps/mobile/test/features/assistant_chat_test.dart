import 'dart:async';
import 'dart:convert';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_controller.dart';
import 'package:child_life/features/assistant/assistant_entry.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart'
    show recentRecordsProvider;
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/billing_repository.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/store_gateway.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/premium_fixtures.dart';
import '../helpers/router_pump.dart';

/// Slice A4 on the phone with a scripted assistant (no Firebase): entry points, the chat states
/// CH02–CH08 and CH19–CH28, roles, exhaustion, offline, consent, partial save, stale drafts,
/// reconnect and the resume after a verified purchase (fake store).

String _key(String what, AssistantScope s, [String uid = 'u_mai']) =>
    'assistant.$what.$uid:${s.key}';

Map<String, Object> _thread(
  List<String> ids, [
  AssistantScope? s,
  String uid = 'u_mai',
]) => {
  _key('conversation', s ?? teddyScope, uid): conversation1,
  _key('tasks', s ?? teddyScope, uid): ids,
};

Map<String, Object> _kept(
  String text,
  KeptReason reason, {
  String requestId = 'req-kept',
  bool started = false,
  AssistantReason? blockReason,
}) => {
  _key('kept', teddyScope): jsonEncode(
    KeptInput(
      text: text,
      requestId: requestId,
      inputKey: '',
      reason: reason,
      at: assistantNow,
      started: started,
      blockReason: blockReason,
    ).toJson(),
  ),
};

Future<(List<Visit>, ProviderContainer)> _pump(
  WidgetTester tester, {
  required FakeAssistantRepository repo,
  Widget? screen,
  Map<String, Object> prefs = const {},
  Membership? me,
  bool online = true,
  bool images = false,
  String plan = 'free',
  Map<String, Object?>? caps,
  List<String>? dialled,
  Future<bool> Function(BuildContext, PurchaseResume)? paywall,
  Stream<bool>? onlineStream,
  List<Override> extra = const [],
  GoRouter? router,
  VideoQuota? video,
}) async {
  final r = await pumpRouted(
    tester,
    screen ?? AssistantChatScreen(scopeKey: teddyScope.key),
    prefs: prefs,
    router: router,
    overrides: [
      ...assistantOverrides(
        repo: repo,
        me: me,
        online: online,
        images: images,
        plan: plan,
        caps: caps,
        dialled: dialled,
        paywall: paywall,
        onlineStream: onlineStream,
        video: video,
      ),
      ...extra,
    ],
  );
  await tester.pumpAndSettle();
  return r;
}

Finder _text(String s, {bool rich = false}) => find.text(s, findRichText: rich);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).last, text);
  await tester.pump();
}

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Gửi').last);
  await tester.pumpAndSettle();
}

void main() {
  group('CH01 / CH01b entry points', () {
    testWidgets('Home card: no credit line (D-081); chips only prefill', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        screen: const Scaffold(body: AssistantTodayCard()),
      );
      expect(_text('Trợ lý Child Life'), findsOneWidget);
      // D-081: credits live only on the usage page, not the Home card.
      expect(_text('Còn 18/20 lượt'), findsNothing);
      await tester.tap(_text('Ghi cữ bú'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/assistant?scope=child%3A$teddyId');
      final launch = visits.last.extra! as AssistantLaunch;
      expect(launch.prefill, 'Con bú bình lúc ');
      // Opening costs nothing: no quote, no task.
      expect(repo.named('quoteTask'), isEmpty);
      expect(repo.named('startTask'), isEmpty);
    });

    testWidgets('dark until the family has the assistant flag', (tester) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(),
        caps: assistantCaps(assistant: false),
        screen: const Scaffold(
          body: Column(
            children: [
              AssistantTodayCard(),
              AssistantModuleEntry(babyId: teddyId),
              AssistantFloatingEntry(),
            ],
          ),
        ),
      );
      expect(_text('Trợ lý Child Life'), findsNothing);
      expect(_text('Nhắn để ghi khoản chi'), findsNothing);
      expect(find.bySemanticsLabel('Mở Lumi'), findsNothing);
    });

    testWidgets('a viewer sees the entry to ask, never "Ghi cữ bú"', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(),
        me: hoa,
        screen: const Scaffold(body: AssistantTodayCard()),
      );
      expect(_text('Trợ lý Child Life'), findsOneWidget);
      expect(_text('Ghi cữ bú'), findsNothing);
      expect(_text('Hỏi về nhật ký của bé…'), findsOneWidget);
    });

    testWidgets('Chi tiêu entry opens the household chat with its hint', (
      tester,
    ) async {
      final (visits, _) = await _pump(
        tester,
        repo: FakeAssistantRepository(),
        screen: const Scaffold(body: AssistantModuleEntry(babyId: teddyId)),
      );
      await tester.tap(_text('Nhắn để ghi khoản chi'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/assistant?scope=household%3A$teddyId');
      expect((visits.last.extra! as AssistantLaunch).hint, IntentHint.expense);
    });
  });

  group('CH02 / CH26 consent and sending', () {
    testWidgets('an example prefills; nothing is sent until "Gửi"', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      await _pump(tester, repo: repo);
      expect(_text('Hỏi hoặc ghi nhanh cho Teddy'), findsOneWidget);
      await tester.tap(_text('“8 giờ con bú bình 120 ml”'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '8 giờ con bú bình 120 ml',
      );
      expect(repo.named('quoteTask'), isEmpty);
    });

    testWidgets('no consent: nothing reaches the provider until agreed', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(consent: const AssistantConsent());
      await _pump(tester, repo: repo);
      await _type(tester, 'Hôm nay con bú thế nào?');
      await _send(tester);
      expect(_text('Trước khi dùng trợ lý'), findsOneWidget);
      expect(repo.named('quoteTask'), isEmpty);
      expect(repo.named('startTask'), isEmpty);
      // The question is kept on the phone, marked not sent.
      expect(_text('Hôm nay con bú thế nào?'), findsOneWidget);
      expect(_text('Chưa gửi'), findsOneWidget);
      await tester.tap(_text('Đồng ý và bắt đầu'));
      await tester.pumpAndSettle();
      expect(repo.named('setAssistantConsent').single.args['agree'], isTrue);
      // Lumi L2: text goes straight to startTask (it quotes inline).
      expect(repo.named('quoteTask'), isEmpty);
      expect(
        repo.named('startTask').single.args['text'],
        'Hôm nay con bú thế nào?',
      );
      expect(_text('Trước khi dùng trợ lý'), findsNothing);
    });

    testWidgets('declining sends nothing and keeps the app usable', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(consent: const AssistantConsent());
      await _pump(tester, repo: repo);
      await _type(tester, 'x');
      await _send(tester);
      await tester.tap(_text('Không dùng trợ lý'));
      await tester.pumpAndSettle();
      expect(repo.named('setAssistantConsent'), isEmpty);
      expect(repo.named('quoteTask'), isEmpty);
      expect(
        _text('Đã không dùng trợ lý. Ghi trực tiếp vẫn dùng như bình thường.'),
        findsOneWidget,
      );
    });

    testWidgets('a text task: no quote, start with a request id, drafts', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      await _pump(tester, repo: repo);
      await _type(
        tester,
        '8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.',
      );
      await _send(tester);
      // Lumi L2 (D-088 §4.4): one call — startTask quotes inline and answers with the snapshot.
      expect(repo.named('quoteTask'), isEmpty);
      final start = repo.named('startTask').single.args;
      expect(start['scope'], teddyScope.key);
      expect(start['requestId'], '00000000-0000-4000-8000-000000000001');
      expect(start['quoteId'], isNull);
      expect(_text('Cữ bú bình'), findsOneWidget);
      expect(_text('Giấc ngủ'), findsOneWidget);
      // Labels come from the state enum.
      expect(_text('Nháp'), findsNWidgets(2));
      expect(_text('Hôm nay 15/10 · 08:00 · 120 ml'), findsOneWidget);
      expect(_text('Lưu 2 mục'), findsOneWidget);
      // Nothing was written: no confirm before the person taps save.
      expect(repo.named('confirmDrafts'), isEmpty);
    });
  });

  group('CH04 / CH07 drafts and saving', () {
    Future<FakeAssistantRepository> drafts(
      WidgetTester tester, {
      Object? Function(Map<String, Object?>)? confirm,
      bool online = true,
      Membership? me,
    }) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot()},
        confirmAnswer: confirm,
      );
      await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA], null, me?.uid ?? 'u_mai'),
        online: online,
        me: me,
      );
      return repo;
    }

    testWidgets('save both: per-item results, "Mở nhật ký" / "Mở bản ghi"', (
      tester,
    ) async {
      final repo = await drafts(tester);
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      final sel = repo.named('confirmDrafts').single.args['selected']! as List;
      expect(sel.map((s) => (s as Map)['draftId']), [
        draftOf(taskA, 0),
        draftOf(taskA, 1),
      ]);
      expect((sel.first as Map)['revision'], 1);
      expect(_text('Đã lưu'), findsNWidgets(2));
      expect(_text('Lưu 2 mục'), findsNothing);
      expect(_text('Mở nhật ký'), findsNWidgets(2));
      expect(_text('Mở bản ghi'), findsNWidgets(2));
    });

    testWidgets('"Mở bản ghi" opens the record in its module (G02, L10 A8)', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA]),
      );
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      await tester.tap(_text('Mở bản ghi').first);
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/record/r_${'c' * 32}');
      // Nothing was deleted.
      expect(repo.calls.map((c) => c.name), isNot(contains('discardDraft')));
    });

    testWidgets('CH07 partial: conflict kept, no fake 2/2, no retry for it', (
      tester,
    ) async {
      final repo = await drafts(
        tester,
        confirm: (args) => {
          'items': [
            {
              'draftId': draftOf(taskA, 0),
              'status': 'saved',
              'revision': 1,
              'recordId': 'r_1',
            },
            {
              'draftId': draftOf(taskA, 1),
              'status': 'conflict',
              'revision': 1,
              'errorCode': 'DOMAIN_CONFLICT',
            },
          ],
          'partial': true,
        },
      );
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      expect(_text('1/2 mục đã lưu · 1 mục chưa lưu'), findsOneWidget);
      expect(_text('Chưa lưu'), findsOneWidget);
      expect(_text('Trùng với một bản đã ghi. Chưa lưu.'), findsOneWidget);
      expect(_text('Thử lại mục lỗi'), findsNothing);
      // "Vẫn lưu riêng" asks first, then sends only that item with its acknowledgement.
      await tester.tap(_text('Vẫn lưu riêng'));
      await tester.pumpAndSettle();
      expect(_text('Vẫn lưu riêng?'), findsOneWidget);
      repo.confirmAnswer = null;
      await tester.tap(_text('Lưu riêng'));
      await tester.pumpAndSettle();
      final last = repo.named('confirmDrafts').last.args['selected']! as List;
      expect(last, [
        {
          'draftId': draftOf(taskA, 1),
          'revision': 1,
          'acknowledge': ['overlap'],
        },
      ]);
      expect(_text('Đã lưu'), findsNWidgets(2));
    });

    testWidgets('retry sends only the failed item, never the saved one', (
      tester,
    ) async {
      final repo = await drafts(
        tester,
        confirm: (args) => {
          'items': [
            {'draftId': draftOf(taskA, 0), 'status': 'saved', 'revision': 1},
            {
              'draftId': draftOf(taskA, 1),
              'status': 'failed',
              'revision': 1,
              'errorCode': 'AI_UNAVAILABLE',
            },
          ],
          'partial': true,
        },
      );
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      expect(_text('Thử lại mục lỗi'), findsOneWidget);
      // D-081: no "costs no credit" footnote in the chat.
      expect(_text('Thử lại không trừ lượt.'), findsNothing);
      repo.confirmAnswer = null;
      await tester.tap(_text('Thử lại mục lỗi'));
      await tester.pumpAndSettle();
      final retry = repo.named('confirmDrafts').last.args['selected']! as List;
      expect(retry.map((s) => (s as Map)['draftId']), [draftOf(taskA, 1)]);
      expect(_text('Đã lưu'), findsNWidgets(2));
    });

    testWidgets('offline: nothing is marked saved', (tester) async {
      final repo = await drafts(tester, online: false);
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      expect(repo.named('confirmDrafts'), isEmpty);
      expect(_text('Đã lưu'), findsNothing);
      expect(_text('Nháp'), findsNWidgets(2));
      expect(
        _text('Đang ngoại tuyến · chưa lưu gì. Có mạng rồi lưu lại.'),
        findsOneWidget,
      );
    });

    testWidgets('stale draft: refreshed, unticked, checked again', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
      repo.error = {
        'confirmDrafts': const AssistantException(
          'failed-precondition',
          reason: AssistantReason.draftStale,
        ),
      };
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      // Someone edited the bottle meanwhile (revision 2, 150 ml).
      repo.tasks[taskA] = batchSnapshot(bottleMl: 150, bottleRevision: 2);
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      expect(_text('Bản nháp vừa thay đổi. Xem lại rồi lưu.'), findsWidgets);
      expect(_text('Hôm nay 15/10 · 08:00 · 150 ml'), findsOneWidget);
      // Re-ticking is the person's choice: the stale items are unticked.
      expect(_text('Chọn mục muốn lưu'), findsOneWidget);
      expect(_text('Đã lưu'), findsNothing);
    });

    testWidgets('"Bỏ mục này" discards (no record, no delete elsewhere)', (
      tester,
    ) async {
      final repo = await drafts(tester);
      // The thread is reversed (newest first in the tree): `.last` is the top one.
      await tester.tap(_text('Bỏ mục này').last);
      await tester.pumpAndSettle();
      expect(
        repo.named('discardDraft').single.args['draftId'],
        draftOf(taskA, 0),
      );
      expect(_text('Đã bỏ'), findsOneWidget);
      expect(_text('Lưu 1 mục'), findsOneWidget);
    });

    testWidgets('a viewer gets no checks and no save actions (CH27)', (
      tester,
    ) async {
      final repo = await drafts(tester, me: hoa);
      expect(_text('Lưu 2 mục'), findsNothing);
      expect(_text('Sửa'), findsNothing);
      expect(_text('Chỉ xem · không lưu qua chat'), findsNWidgets(2));
      expect(_text('Hỏi về nhật ký của bé…'), findsOneWidget);
      expect(find.bySemanticsLabel('Ảnh'), findsNothing);
      expect(repo.named('confirmDrafts'), isEmpty);
    });

    testWidgets('an unknown part shows a safe card and offers nothing', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(),
              messages: [
                userMessage('x'),
                assistantMessage([
                  {'type': 'open_url', 'schemaVersion': 1, 'url': 'x'},
                ]),
              ],
            ),
          },
        ),
        prefs: _thread([taskA]),
      );
      expect(
        _text(
          'Nội dung này cần bản app mới hơn để hiển thị. Không có gì được lưu.',
        ),
        findsOneWidget,
      );
    });
  });

  group('CH05 / CH06 clarification and edits', () {
    testWidgets('a chip answers in the same task (no new quote)', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(
              state: 'awaiting_clarification',
              clarification: clarificationJson(),
            ),
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      // D-081: no "costs no credit" footnote in the chat.
      expect(
        _text('Câu hỏi làm rõ thuộc cùng tác vụ, không trừ thêm lượt.'),
        findsNothing,
      );
      repo.tasks[taskA] = batchSnapshot();
      await tester.tap(_text('9:00 – 10:00'));
      await tester.pumpAndSettle();
      final c = repo.named('submitClarification').single.args;
      expect(c['taskId'], taskA);
      expect(c['expectedVersion'], 3);
      expect(c['clarificationId'], 'c1');
      expect(c['choiceId'], 'a');
      expect(repo.named('quoteTask'), isEmpty);
      expect(repo.named('startTask'), isEmpty);
      expect(_text('Lưu 2 mục'), findsOneWidget);
      // Lumi L2: the answer's snapshot is the next round — no second read (one on open only).
      expect(repo.named('getAssistantTask'), hasLength(1));
    });

    testWidgets('"Tự nhập": the typed answer goes to the same task', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(
              state: 'awaiting_clarification',
              clarification: clarificationJson(),
            ),
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await tester.tap(_text('Khác…'));
      await tester.pumpAndSettle();
      expect(_text('Trả lời câu hỏi…'), findsOneWidget);
      await _type(tester, '21:30 đến 6:00');
      await _send(tester);
      expect(
        repo.named('submitClarification').single.args['text'],
        '21:30 đến 6:00',
      );
      expect(repo.named('startTask'), isEmpty);
    });

    testWidgets(
      'L1 / L7 (P-168 #2): typed while my question waits → the server reads it against it',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(
                state: 'awaiting_clarification',
                clarification: clarificationJson(),
              ),
            ),
          },
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        // No "Khác…" tap: the composer already says it answers the question above.
        expect(_text('Trả lời câu hỏi…'), findsOneWidget);
        await _type(tester, 'Sáng');
        await _send(tester);
        // L7: the words go to the server, whose resolver answers my question with them (or
        // reads a new topic) — the same for any app build, voice or a lost listener.
        final c = repo.named('startTask').single.args;
        expect(c['text'], 'Sáng');
        expect(repo.named('submitClarification'), isEmpty);
        expect(repo.named('quoteTask'), isEmpty);
      },
    );

    testWidgets(
      'L10 A8: the answer routed into my task keeps its first words and request id',
      (tester) async {
        final asked = snapshotWith(
          task: taskJson(
            state: 'awaiting_clarification',
            clarification: clarificationJson(),
          ),
        );
        final repo = FakeAssistantRepository(
          startAnswer: (args) => envelope(
            args['text'] == 'Sáng' ? batchSnapshot() : asked,
            taskId: taskA,
          ),
        );
        final (_, container) = await _pump(tester, repo: repo);
        await _type(tester, 'bé bú 120ml lúc 8h');
        await _send(tester);
        final first = repo.named('startTask').single.args['requestId'];
        expect(_text('Trả lời câu hỏi…'), findsOneWidget);
        await _type(tester, 'Sáng');
        await _send(tester);
        final calls = repo.named('startTask');
        expect(calls, hasLength(2));
        expect(calls.last.args['requestId'], isNot(first));
        final chat = container.read(assistantChatProvider(teddyScope.key));
        final thread = chat.thread(taskA)!;
        expect(thread.text, 'bé bú 120ml lúc 8h');
        expect(thread.requestId, first);
      },
    );

    testWidgets(
      'L10 A8: a newer message of mine after the question hides "Trả lời câu hỏi…"',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(
                state: 'awaiting_clarification',
                clarification: clarificationJson(),
              ),
            ),
          },
          startAnswer: (args) => envelope(
            snapshotWith(task: taskJson(id: taskB)),
            taskId: taskB,
          ),
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        expect(_text('Trả lời câu hỏi…'), findsOneWidget);
        await _type(tester, 'hôm nay bé ngủ bao nhiêu rồi');
        await _send(tester);
        expect(_text('Trả lời câu hỏi…'), findsNothing);
      },
    );

    testWidgets(
      "L1: another member's open question is not mine: typed words start a task",
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: {
                ...taskJson(
                  state: 'awaiting_clarification',
                  clarification: clarificationJson(),
                ),
                'visibility': 'shared',
                'author': {
                  'uid': 'u_minh',
                  'name': 'Minh',
                  'relation': 'father',
                  'relationCustom': null,
                },
              },
            ),
          },
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        await _type(tester, 'bé bú 120ml lúc 8h');
        await _send(tester);
        expect(repo.named('submitClarification'), isEmpty);
        expect(repo.named('startTask'), hasLength(1));
      },
    );

    testWidgets('CH06 edit: the form checks first, then patchDraft', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot()},
        patchAnswer: (args) => bottleDraftJson(ml: 150, revision: 2),
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      // The thread is reversed (newest first in the tree): `.last` is the top one.
      await tester.tap(_text('Sửa').last);
      await tester.pumpAndSettle();
      expect(_text('Sửa cữ bú bình'), findsOneWidget);
      final amount = find.descendant(
        of: find.byType(BottomSheet).hitTestable(),
        matching: find.byType(TextField),
      );
      final field = amount.evaluate().isEmpty
          ? find.byType(TextField).last
          : amount.first;
      await tester.enterText(field, '0');
      await tester.tap(_text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      expect(_text('Lượng chưa hợp lệ.'), findsOneWidget);
      expect(repo.named('patchDraft'), isEmpty);
      await tester.enterText(field, '150');
      await tester.tap(_text('Cập nhật bản nháp'));
      await tester.pumpAndSettle();
      final p = repo.named('patchDraft').single.args;
      expect(p['expectedRevision'], 1);
      expect((p['payload']! as Map)['amountMl'], 150);
      expect(_text('Sửa cữ bú bình'), findsNothing);
      expect(_text('Hôm nay 15/10 · 08:00 · 150 ml'), findsOneWidget);
      // An edit is not a save.
      expect(repo.named('confirmDrafts'), isEmpty);
    });
  });

  group('CH08 read summary', () {
    testWidgets('bottle ml and nursing minutes apart; coverage wording', (
      tester,
    ) async {
      final (visits, _) = await _pump(
        tester,
        repo: FakeAssistantRepository(
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
        prefs: _thread([taskA]),
      );
      expect(_text('Bú bình · 3 cữ · 390 ml'), findsOneWidget);
      expect(_text('Bú mẹ · 2 lần · 35 phút'), findsOneWidget);
      expect(_text('Tính theo phút, không quy đổi ra ml'), findsOneWidget);
      expect(
        _text('Tính trên các cữ đã ghi — có thể chưa đầy đủ.'),
        findsOneWidget,
      );
      expect(_text('Câu hỏi không tạo cữ bú mới'), findsNothing);
      expect(_text('Hôm nay 15/10 · đến 14:20'), findsOneWidget);
      await tester.tap(_text('Mở nhật ký nguồn'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/history');
    });

    testWidgets('a finished day shows its date, not "đến 00:00"', (
      tester,
    ) async {
      final part = summaryPart();
      final summary = {...part['summary']! as Map<String, Object?>};
      summary['date'] = '2026-10-14';
      summary['until'] = '2026-10-14T17:00:00.000Z'; // 00:00 on 15/10, Hà Nội
      await _pump(
        tester,
        repo: FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(),
              messages: [
                userMessage('Hôm qua con bú thế nào?'),
                assistantMessage([
                  {...part, 'summary': summary},
                ]),
              ],
            ),
          },
        ),
        prefs: _thread([taskA]),
      );
      expect(_text('Hôm qua 14/10'), findsOneWidget);
      expect(find.textContaining('đến 00:00'), findsNothing);
    });
  });

  group('CH19 usage', () {
    testWidgets('household pool, reset, costs, video quota separate', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(usage: usageJson(used: 5)),
        screen: const AssistantUsageScreen(babyId: teddyId),
        video: const VideoQuota(limit: 5, used: 1, reserved: 0),
      );
      expect(_text('15 / 20 lượt còn lại', rich: true), findsOneWidget);
      expect(
        _text('Làm mới 01/11 theo múi giờ của hộ · dùng chung cho cả hộ'),
        findsOneWidget,
      );
      expect(_text('Không thêm'), findsOneWidget);
      // D-076 #9: a factual cost, never a "Miễn phí" label.
      expect(_text('Không trừ lượt'), findsOneWidget);
      expect(_text('Miễn phí'), findsNothing);
      expect(
        _text('Quota riêng, không dùng lượt hỗ trợ AI · còn 4/5'),
        findsOneWidget,
      );
      expect(_text('Xem Premium'), findsOneWidget);
    });

    testWidgets('large text: "Không thêm" never breaks, no overflow', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        repo: FakeAssistantRepository(usage: usageJson(used: 5)),
        screen: const AssistantUsageScreen(babyId: teddyId),
      );
      expect(tester.takeException(), isNull);
      final value = tester.widget<Text>(_text('Không thêm'));
      expect(value.softWrap, isFalse);
      expect(tester.getSize(_text('Không thêm')).height, lessThan(80));
    });

    testWidgets('Premium: no upsell', (tester) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(
          usage: usageJson(plan: 'premium', limit: 200, used: 10),
        ),
        plan: 'premium',
        screen: const AssistantUsageScreen(babyId: teddyId),
      );
      expect(_text('Xem Premium'), findsNothing);
      expect(
        _text('Hộ đang dùng Premium. Không có gói chat riêng.'),
        findsOneWidget,
      );
    });
  });

  group('CH20–CH24 credits', () {
    testWidgets('CH20: a photo over the balance is never uploaded', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        usage: usageJson(used: 18),
        quoteAnswer: (args) => quoteJson(
          modality: 'image',
          allowed: false,
          reason: 'USAGE_EXHAUSTED',
          usage: usageJson(used: 18),
        ),
      );
      await _pump(tester, repo: repo, images: true);
      await _type(tester, 'Mua bỉm 310k');
      await tester.tap(find.bySemanticsLabel('Ảnh'));
      await tester.pumpAndSettle();
      // CH09 sheet first: nothing quoted or uploaded until a photo is chosen.
      expect(repo.named('quoteTask'), isEmpty);
      await tester.tap(_text('Chọn từ thư viện'));
      await tester.pumpAndSettle();
      final q = repo.named('quoteTask').single.args;
      expect(q['modality'], 'image');
      expect(q['attachmentCount'], 1);
      expect(_text('Đọc ảnh này cần 3 lượt, bạn còn 2.'), findsOneWidget);
      expect(_text('Ảnh · chưa gửi'), findsOneWidget);
      expect(repo.named('startTask'), isEmpty);
      expect(repo.named('createAttachmentUpload'), isEmpty);
      // The typed input stays.
      await tester.tap(_text('Nhập tay'));
      await tester.pumpAndSettle();
      expect(_text('Ảnh · chưa gửi'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Mua bỉm 310k',
      );
    });

    testWidgets('CH21: locked composer, kept question, health and logs open', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        usage: usageJson(used: 20),
        tasks: {taskA: batchSnapshot()},
      );
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        prefs: {
          ..._thread([taskA]),
          ..._kept('Hôm nay con bú thế nào?', KeptReason.blocked),
        },
      );
      expect(
        _text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'),
        findsOneWidget,
      );
      // D-076 #12: no credits pill in the chat; the numbers are in CH19.
      expect(_text('Đã dùng hết 20/20 lượt · làm mới 01/11'), findsNothing);
      expect(_text('Đã hết lượt AI tháng này'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      expect(_text('Xem Premium để hỏi tiếp'), findsOneWidget);
      // Ready drafts still save at 0 credits (brief p.17); D-081 dropped the
      // footnote saying so.
      expect(
        _text('Bản nháp đã sẵn sàng vẫn lưu được, không cần lượt.'),
        findsNothing,
      );
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      expect(repo.named('confirmDrafts'), hasLength(1));
      await tester.tap(_text('Mở Hướng dẫn sức khoẻ'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/rhythm/health');
    });

    testWidgets(
      'CH21 with assistant_upsell off: no purchase prompt, the rest unchanged',
      (tester) async {
        await _pump(
          tester,
          repo: FakeAssistantRepository(
            usage: usageJson(used: 20),
            tasks: {taskA: batchSnapshot()},
          ),
          caps: assistantCaps(upsell: false),
          prefs: {
            ..._thread([taskA]),
            ..._kept('Hôm nay con bú thế nào?', KeptReason.blocked),
          },
        );
        expect(
          _text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'),
          findsOneWidget,
        );
        expect(_text('Xem Premium để hỏi tiếp'), findsNothing);
        expect(_text('Mở Hướng dẫn sức khoẻ'), findsOneWidget);
      },
    );

    testWidgets('CH24: Premium exhausted sells nothing more', (tester) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(
          usage: usageJson(
            plan: 'premium',
            limit: 200,
            used: 200,
            resetsAt: '2026-11-13T17:00:00.000Z',
          ),
        ),
        plan: 'premium',
        prefs: _kept('So với hôm qua?', KeptReason.blocked),
      );
      expect(_text('Hộ đã dùng hết lượt hỗ trợ AI kỳ này.'), findsOneWidget);
      expect(_text('Xem Premium để hỏi tiếp'), findsNothing);
      expect(_text('Xem Premium'), findsNothing);
      expect(_text('Hết lượt AI · vẫn ghi trực tiếp được'), findsOneWidget);
      expect(_text('Mở Hướng dẫn sức khoẻ'), findsOneWidget);
    });

    testWidgets('CH22 → CH23: after a verified purchase the question runs once', (
      tester,
    ) async {
      final caps = assistantCaps(billing: true);
      final store = FakeStore();
      final billing = FakeBilling(
        onActive: () => caps
          ..clear()
          ..addAll(assistantCaps(plan: 'premium', billing: true)),
      );
      final repo = FakeAssistantRepository(usage: usageJson(used: 20));
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => AssistantChatScreen(scopeKey: teddyScope.key),
          ),
          ...premiumRoutes(),
          GoRoute(path: '/:a/:b', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/:a', builder: (_, _) => const SizedBox()),
        ],
      );
      await _pump(
        tester,
        repo: repo,
        caps: caps,
        router: router,
        prefs: _kept(
          'Hôm nay con bú thế nào?',
          KeptReason.blocked,
          requestId: 'req-blocked',
          started: true,
        ),
        extra: [
          storeGatewayProvider.overrideWithValue(store),
          billingApiProvider.overrideWithValue(billing),
        ],
      );
      await tester.tap(_text('Xem Premium để hỏi tiếp'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(PaywallScreen), findsOneWidget);
      // The fake billing records what the app asks; the real repository drops the
      // chat's resume before `startPurchase` (not in the server's schema).
      repo.usageJsonValue = usageJson(plan: 'premium', limit: 200, used: 0);
      await tester.tap(_text('Tiếp tục với Premium'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(billing.starts.single['resume'], {
        'kind': 'assistant',
        'templateId': null,
        'draftRef': teddyScope.key,
      });
      store.emit(store.purchase(StorePurchaseStatus.purchased));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(_text('Tiếp tục câu hỏi'));
      await tester.pumpAndSettle();
      final start = repo.named('startTask').single.args;
      expect(start['text'], 'Hôm nay con bú thế nào?');
      // The same request id with a fresh quote: the server runs the blocked task once.
      expect(start['requestId'], 'req-blocked');
      expect(_text('Còn 200/200 lượt hỗ trợ AI'), findsNothing);
      // Above the resumed task (just off the top while the thread sticks to the newest).
      expect(
        find.text(
          'Hộ đã có Premium · tiếp tục câu hỏi đang chờ',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('the resume runs once only', (tester) async {
      var opened = 0;
      final repo = FakeAssistantRepository(
        usage: usageJson(used: 20),
        quoteAnswer: (args) => quoteJson(
          allowed: false,
          reason: 'USAGE_EXHAUSTED',
          usage: usageJson(used: 20),
        ),
        startAnswer: (args) => envelope(
          {'task': taskJson(state: 'blocked'), 'usage': usageJson(used: 20)},
          status: 'blocked',
          reason: 'USAGE_EXHAUSTED',
        ),
      );
      await _pump(
        tester,
        repo: repo,
        prefs: _kept('Hôm nay con bú thế nào?', KeptReason.blocked),
        paywall: (_, resume) async {
          opened++;
          expect(resume.kind, ResumeKind.assistant);
          expect(resume.draftRef, teddyScope.key);
          return true;
        },
      );
      await tester.tap(_text('Xem Premium để hỏi tiếp'));
      await tester.pumpAndSettle();
      // Still blocked (the server did not grant yet): the button is spent, so it goes
      // (AI-3: never a disabled button with no reason).
      expect(_text('Xem Premium để hỏi tiếp'), findsNothing);
      expect(opened, 1);
      expect(repo.named('quoteTask'), isEmpty);
      // Still kept, still blocked: nothing was charged or shown as answered.
      expect(repo.named('startTask').single.args['requestId'], 'req-kept');
      expect(_text('Chưa gửi'), findsOneWidget);
    });

    testWidgets(
      'out of credits: the start still goes; health comes back free',
      (tester) async {
        final repo = FakeAssistantRepository(
          usage: usageJson(used: 19),
          quoteAnswer: (args) => quoteJson(
            allowed: false,
            reason: 'USAGE_EXHAUSTED',
            usage: usageJson(used: 20),
          ),
          startAnswer: (args) => envelope(
            snapshotWith(
              task: taskJson(),
              messages: [
                userMessage('Con sốt 38,5 độ, thở nhanh'),
                assistantMessage([
                  {
                    'type': 'health_support',
                    'schemaVersion': 1,
                    'signs': ['breathing'],
                  },
                ]),
              ],
            ),
          ),
        );
        await _pump(tester, repo: repo);
        await _type(tester, 'Con sốt 38,5 độ, thở nhanh');
        await _send(tester);
        expect(repo.named('startTask'), hasLength(1));
        expect(_text('Hãy liên hệ hỗ trợ y tế ngay'), findsOneWidget);
        expect(
          _text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'),
          findsNothing,
        );
        expect(_text('Chưa gửi'), findsNothing);
      },
    );

    testWidgets(
      'out of credits: a blocked start keeps the question to resume',
      (tester) async {
        final repo = FakeAssistantRepository(
          usage: usageJson(used: 19),
          quoteAnswer: (args) => quoteJson(
            allowed: false,
            reason: 'USAGE_EXHAUSTED',
            usage: usageJson(used: 20),
          ),
          startAnswer: (args) => envelope(
            {'task': taskJson(state: 'blocked'), 'usage': usageJson(used: 20)},
            status: 'blocked',
            reason: 'USAGE_EXHAUSTED',
          ),
        );
        final (_, container) = await _pump(tester, repo: repo);
        await _type(tester, 'Hôm nay con bú thế nào?');
        await _send(tester);
        expect(
          _text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'),
          findsOneWidget,
        );
        expect(_text('Chưa gửi'), findsOneWidget);
        final kept = container
            .read(assistantLocalStoreProvider)
            .kept('u_mai:${teddyScope.key}')!;
        expect(kept.started, isTrue);
        expect(kept.conversationId, isNull);
        expect(
          kept.requestId,
          repo.named('startTask').single.args['requestId'],
        );
      },
    );
  });

  group('CH25 failure and offline', () {
    testWidgets('AI failure: "Thử lại" makes a new task, same words', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(state: 'failed', errorCode: 'AI_UNAVAILABLE'),
            messages: [userMessage('8 giờ con bú bình 120 ml')],
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      // CH25 as Lumi says it: no blame, nothing saved (D-081: no credit talk).
      expect(
        _text(
          'Mình chưa trả lời được lúc này. Chưa có gì được lưu — bạn thử lại nhé, hoặc ghi trực tiếp.',
        ),
        findsOneWidget,
      );
      expect(_text('Ghi trực tiếp'), findsOneWidget);
      await tester.tap(_text('Thử lại'));
      await tester.pumpAndSettle();
      expect(
        repo.named('startTask').single.args['text'],
        '8 giờ con bú bình 120 ml',
      );
      expect(
        _text(
          'Mình chưa trả lời được lúc này. Chưa có gì được lưu — bạn thử lại nhé, hoặc ghi trực tiếp.',
        ),
        findsNothing,
      );
    });

    testWidgets('no answer from the server: kept, retried with the same id', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      repo.error = {'startTask': const AssistantException('unavailable')};
      await _pump(tester, repo: repo);
      await _type(tester, 'Hôm nay con bú thế nào?');
      await _send(tester);
      // Kept under my bubble with its own "Gửi" (never sent by itself).
      expect(_text('Chưa gửi · đang ngoại tuyến'), findsOneWidget);
      repo.error = null;
      await tester.tap(_text('Gửi').last);
      await tester.pumpAndSettle();
      final starts = repo.named('startTask');
      expect(starts, hasLength(2));
      // The same request id: a replay of a start that did land returns the same task.
      expect(starts[0].args['requestId'], starts[1].args['requestId']);
      expect(_text('Chưa gửi · đang ngoại tuyến'), findsNothing);
    });

    testWidgets('offline: kept, never auto-sent; sent on a tap once online', (
      tester,
    ) async {
      final online = StreamController<bool>.broadcast();
      addTearDown(online.close);
      final repo = FakeAssistantRepository();
      await _pump(tester, repo: repo, onlineStream: online.stream);
      online.add(false);
      await tester.pumpAndSettle();
      await _type(tester, '8 giờ con bú bình 120 ml');
      await _send(tester);
      expect(repo.named('quoteTask'), isEmpty);
      expect(
        _text(
          'Đang ngoại tuyến. Tin nhắn được giữ lại và chỉ gửi khi bạn bấm Gửi. Ghi trực tiếp vẫn dùng được.',
        ),
        findsOneWidget,
      );
      expect(_text('Chưa gửi · đang ngoại tuyến'), findsOneWidget);
      // Offline, the bubble offers no "Gửi" yet.
      expect(_text('Gửi'), findsNothing);
      online.add(true);
      await tester.pumpAndSettle();
      // Back online: nothing goes out by itself (no charge without a tap).
      expect(repo.named('startTask'), isEmpty);
      await tester.tap(_text('Gửi').last);
      await tester.pumpAndSettle();
      expect(repo.named('startTask'), hasLength(1));
    });
  });

  group('CH27 roles, module, region · CH28 health', () {
    testWidgets('viewer refused a write; region card keeps health', (
      tester,
    ) async {
      final (visits, _) = await _pump(
        tester,
        me: hoa,
        repo: FakeAssistantRepository(
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
            ),
          },
        ),
        prefs: _thread([taskA, taskB], null, 'u_hoa'),
      );
      expect(_text('Bạn đang có quyền xem'), findsOneWidget);
      expect(_text('Khu vực chưa hỗ trợ'), findsOneWidget);
      expect(_text('Lưu thành nhắc việc'), findsNothing);
      await tester.tap(_text('Mở Hướng dẫn sức khoẻ'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/rhythm/health');
    });

    testWidgets('module unavailable: explained, never a direct save', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(state: 'failed', errorCode: 'MODULE_UNAVAILABLE'),
            ),
          },
        ),
        prefs: _thread([taskA]),
      );
      expect(_text('Chưa có nơi lưu việc này'), findsOneWidget);
      expect(_text('Lưu thành nhắc việc'), findsNothing);
    });

    testWidgets(
      'CH28 at 0 credits: the region number and First aid, never a paywall',
      (tester) async {
        final dialled = <String>[];
        final (visits, _) = await _pump(
          tester,
          dialled: dialled,
          repo: FakeAssistantRepository(
            usage: usageJson(used: 20),
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
          prefs: _thread([taskA]),
        );
        expect(_text('Hãy liên hệ hỗ trợ y tế ngay'), findsOneWidget);
        // D-081: no "costs no credit" note on the health card.
        expect(_text('Không trừ lượt'), findsNothing);
        expect(_text('Xem Premium để hỏi tiếp'), findsNothing);
        await tester.tap(_text('Gọi 115'));
        await tester.pumpAndSettle();
        expect(dialled, ['115']);
        await tester.tap(_text('Mở Sơ cứu'));
        await tester.pumpAndSettle();
        expect(visits.last.location, '/utilities/first-aid');
      },
    );

    testWidgets(
      'CH28 without a number for the country: the doctor, no hotline',
      (tester) async {
        await _pump(
          tester,
          caps: assistantCaps(country: 'FR'),
          repo: FakeAssistantRepository(
            tasks: {
              taskA: snapshotWith(
                task: taskJson(),
                messages: [
                  assistantMessage([
                    {
                      'type': 'health_support',
                      'schemaVersion': 1,
                      'signs': <String>[],
                    },
                  ]),
                ],
              ),
            },
          ),
          prefs: _thread([taskA]),
        );
        expect(_text('Gọi bác sĩ của bé'), findsOneWidget);
        expect(find.textContaining('Gọi 1'), findsNothing);
      },
    );
  });

  group('reconnect, scope, history', () {
    testWidgets('duplicate / old events and older snapshots are ignored', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(repo.named('getAssistantTask'), hasLength(1));
      // The events the snapshot already had: nothing to do.
      repo.push(
        taskA,
        TaskEventsLive([
          for (final e in TaskSnapshot.fromJson(batchSnapshot())!.events) e,
        ]),
      );
      // An older task version (a late listener snapshot) does not undo "ready".
      repo.push(
        taskA,
        TaskDocLive(
          AssistantTask.fromJson(taskJson(state: 'processing', version: 1))!,
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.named('getAssistantTask'), hasLength(1));
      expect(_text('Lumi đang soạn…'), findsNothing);
      expect(_text('Lưu 2 mục'), findsOneWidget);
      // A new event asks for the authoritative snapshot once; its duplicate does not.
      final saved = AssistantEvent(
        taskId: taskA,
        eventId: 'ev3',
        sequence: 3,
        typeWire: 'item_saved',
      );
      repo.tasks[taskA] = batchSnapshot(bottleState: 'saved');
      repo.push(taskA, TaskEventsLive([saved]));
      await tester.pumpAndSettle();
      repo.push(taskA, TaskEventsLive([saved]));
      await tester.pumpAndSettle();
      expect(repo.named('getAssistantTask'), hasLength(2));
      expect(_text('Đã lưu'), findsOneWidget);
      // A same-revision drafts snapshot written before the save cannot undo it.
      repo.push(
        taskA,
        TaskDraftsLive([
          for (final d in TaskSnapshot.fromJson(batchSnapshot())!.drafts) d,
        ]),
      );
      await tester.pumpAndSettle();
      expect(_text('Đã lưu'), findsOneWidget);
    });

    testWidgets(
      'Lumi L2: a sent log draws from the start answer and its listeners, no getAssistantTask',
      (tester) async {
        final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
        await _pump(tester, repo: repo);
        await _type(tester, 'bé bú 120ml lúc 8h');
        await _send(tester);
        expect(_text('Lưu 2 mục'), findsOneWidget);
        // The listener's first batch holds the events the answer already had.
        repo.push(
          taskA,
          TaskEventsLive([
            for (final e in TaskSnapshot.fromJson(batchSnapshot())!.events) e,
          ]),
        );
        repo.push(
          taskA,
          TaskDraftsLive([
            for (final d in TaskSnapshot.fromJson(batchSnapshot())!.drafts) d,
          ]),
        );
        await tester.pumpAndSettle();
        expect(repo.named('getAssistantTask'), isEmpty);
        expect(_text('Lưu 2 mục'), findsOneWidget);
        // A result the answer did not cover (the trigger's, a gap) is read once.
        repo.push(
          taskA,
          TaskEventsLive([
            AssistantEvent(
              taskId: taskA,
              eventId: 'ev4',
              sequence: 4,
              typeWire: 'answer_ready',
            ),
          ]),
        );
        await tester.pumpAndSettle();
        expect(repo.named('getAssistantTask'), hasLength(1));
      },
    );

    testWidgets('back online: open tasks are fetched again', (tester) async {
      final online = StreamController<bool>.broadcast();
      addTearDown(online.close);
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(task: taskJson(state: 'processing', version: 2)),
        },
      );
      await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA]),
        onlineStream: online.stream,
      );
      expect(_text('Lumi đang soạn…'), findsOneWidget);
      online.add(false);
      await tester.pumpAndSettle();
      repo.tasks[taskA] = batchSnapshot();
      online.add(true);
      await tester.pumpAndSettle();
      expect(repo.named('getAssistantTask'), hasLength(2));
      expect(_text('Lưu 2 mục'), findsOneWidget);
    });

    testWidgets('"Huỷ" while preparing cancels the task', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(task: taskJson(state: 'processing', version: 2)),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await tester.tap(_text('Huỷ'));
      await tester.pumpAndSettle();
      expect(repo.named('cancelTask').single.args['taskId'], taskA);
      // D-081: the cancel note no longer mentions credits.
      expect(_text('Đã huỷ.'), findsOneWidget);
      expect(_text('Đã huỷ. Không trừ lượt.'), findsNothing);
    });

    testWidgets('another scope is another chat: nothing carries across', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(),
        screen: AssistantChatScreen(scopeKey: householdScope.key),
        prefs: _kept('Hôm nay con bú thế nào?', KeptReason.offline),
      );
      expect(_text('Hôm nay con bú thế nào?'), findsNothing);
      expect(_text('Hỏi hoặc ghi nhanh cho cả nhà'), findsOneWidget);
    });

    testWidgets('CH03: open a conversation; delete only after the server', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot()},
        conversationsAnswer: () => [
          {
            'id': conversation1,
            'scope': {'type': 'child', 'babyId': teddyId},
            'title': 'Ghi bú và ngủ buổi sáng',
            'createdAt': '2026-10-15T02:12:00.000Z',
            'updatedAt': '2026-10-15T02:12:00.000Z',
            'lastTaskId': taskA,
          },
          {
            'id': 'cv_2',
            'scope': {'type': 'child', 'babyId': teddyId},
            'title': 'Con khó ngủ',
            'createdAt': '2026-10-15T01:00:00.000Z',
            'updatedAt': '2026-10-15T01:00:00.000Z',
          },
        ],
        messagesAnswer: () => [
          userMessage('8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.'),
        ],
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => AssistantChatScreen(scopeKey: teddyScope.key),
          ),
          ...assistantRoutes(),
          GoRoute(path: '/:a/:b', builder: (_, _) => const SizedBox()),
        ],
      );
      await _pump(tester, repo: repo, router: router);
      await tester.tap(find.bySemanticsLabel('Lịch sử'));
      await tester.pumpAndSettle();
      expect(_text('Hội thoại'), findsOneWidget);
      expect(_text('HÔM NAY'), findsOneWidget);
      expect(
        _text(
          'Mỗi bé có lịch sử riêng. Đổi bé không chuyển bản nháp đang chờ sang bé khác.',
        ),
        findsOneWidget,
      );
      // Delete: confirm explains domain records stay; the row goes only after the server.
      repo.error = {
        'deleteAssistantConversation': const AssistantException('unavailable'),
      };
      await tester.tap(find.bySemanticsLabel('Xoá cuộc trò chuyện').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('vẫn giữ nguyên'), findsOneWidget);
      await tester.tap(_text('Xoá'));
      await tester.pumpAndSettle();
      expect(_text('Con khó ngủ'), findsOneWidget);
      expect(_text('Chưa xoá được. Thử lại sau.'), findsOneWidget);
      repo.error = null;
      await tester.tap(find.bySemanticsLabel('Xoá cuộc trò chuyện').last);
      await tester.pumpAndSettle();
      await tester.tap(_text('Xoá'));
      await tester.pumpAndSettle();
      expect(_text('Con khó ngủ'), findsNothing);
      // The server says the saved records stay (`domainRecordsKept`).
      expect(
        _text('Đã xoá cuộc trò chuyện. Bản ghi đã lưu vẫn giữ nguyên.'),
        findsOneWidget,
      );
      expect(
        repo.named('deleteAssistantConversation').last.args['conversationId'],
        'cv_2',
      );
      // Open the other one: its tasks come back from the server.
      await tester.tap(_text('Ghi bú và ngủ buổi sáng'));
      await tester.pumpAndSettle();
      expect(_text('Hội thoại'), findsNothing);
      // (Opening the chat also read the baby's shared thread, D-075 #2.)
      expect(repo.named('getAssistantTask').last.args['taskId'], taskA);
      expect(_text('Lưu 2 mục'), findsOneWidget);
    });

    testWidgets('the composer stays above the keyboard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget app(double keyboard) => ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          environmentProvider.overrideWithValue(AppEnvironment.dev),
          ...assistantOverrides(repo: FakeAssistantRepository()),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(375, 812),
            padding: EdgeInsets.only(top: 47, bottom: keyboard > 0 ? 0 : 34),
            viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
            viewInsets: EdgeInsets.only(bottom: keyboard),
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
      );
      await tester.pumpWidget(app(0));
      await tester.pumpAndSettle();
      // Above the home indicator without a keyboard…
      expect(tester.getRect(find.byType(TextField)).bottom, lessThan(812 - 34));
      await tester.pumpWidget(app(300));
      await tester.pumpAndSettle();
      // …and above the keyboard with one.
      expect(
        tester.getRect(find.byType(TextField)).bottom,
        lessThanOrEqualTo(812 - 300),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Flow audit 2026-10-26 (AI-1 … AI-9)', () {
    testWidgets('AI-1: a region refusal keeps its reason and never locks the '
        'composer', (tester) async {
      final repo = FakeAssistantRepository(
        error: {
          'startTask': const AssistantException(
            'failed-precondition',
            reason: AssistantReason.regionUnsupported,
          ),
        },
      );
      await _pump(tester, repo: repo);
      await _type(tester, 'Con hay quấy tối, nên làm gì?');
      await _send(tester);
      expect(_text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
      // A resend cannot help: the words can go back to the composer.
      expect(_text('Sửa lại'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final kept = KeptInput.fromJson(
        jsonDecode(prefs.getString(_key('kept', teddyScope))!),
      )!;
      expect(kept.reason, KeptReason.blocked);
      expect(kept.blockReason, AssistantReason.regionUnsupported);
      await tester.tap(_text('Sửa lại'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Con hay quấy tối, nên làm gì?',
      );
      expect(_text('Chưa gửi'), findsNothing);
    });

    testWidgets('AI-1: a kept refusal reopens as that refusal', (tester) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(),
        prefs: _kept(
          'Thêm “mua bỉm” vào việc cần làm',
          KeptReason.blocked,
          blockReason: AssistantReason.moduleUnavailable,
        ),
      );
      expect(_text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
    });

    testWidgets('AI-2: after the reset the used-up card goes and "Gửi" resumes '
        'the same request', (tester) async {
      final repo = FakeAssistantRepository(usage: usageJson(used: 0));
      await _pump(
        tester,
        repo: repo,
        prefs: _kept(
          'Hôm nay con bú thế nào?',
          KeptReason.blocked,
          requestId: 'req-blocked',
          started: true,
        ),
      );
      expect(_text('Bạn đã dùng hết lượt hỗ trợ AI tháng này.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
      await tester.tap(_text('Gửi').first);
      await tester.pumpAndSettle();
      expect(repo.named('startTask').single.args['requestId'], 'req-blocked');
    });

    testWidgets('AI-4: no reset date known → "kỳ tới", never a blank date', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeAssistantRepository(
          usage: {...usageJson(used: 20), 'resetsAt': null},
        ),
        prefs: _kept('Hôm nay con bú thế nào?', KeptReason.blocked),
      );
      expect(find.textContaining('Lượt mới có vào kỳ tới.'), findsOneWidget);
      expect(find.textContaining('Credit'), findsNothing);
    });

    testWidgets('AI-5: a typed answer that did not go comes back to the box', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(
              state: 'awaiting_clarification',
              clarification: clarificationJson(),
            ),
          ),
        },
        error: {'submitClarification': const AssistantException('internal')},
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await tester.tap(_text('Khác…'));
      await tester.pumpAndSettle();
      await _type(tester, '21:30 đến 6:00');
      await _send(tester);
      expect(repo.named('submitClarification'), hasLength(1));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '21:30 đến 6:00',
      );
      // AI-7: about the answer, not a draft.
      expect(
        _text('Chưa gửi được câu trả lời. Chữ vẫn ở ô nhập, bạn thử lại nhé.'),
        findsOneWidget,
      );
      expect(_text('Chưa lưu được. Bản nháp vẫn giữ nguyên.'), findsNothing);
    });

    testWidgets('AI-6: a timeout is "Đang kiểm tra…", then the same request id '
        'again', (tester) async {
      final repo = FakeAssistantRepository(
        error: {'startTask': const AssistantException('timeout')},
      );
      await _pump(tester, repo: repo);
      await _type(tester, '8 giờ con bú bình 120 ml');
      await tester.tap(find.bySemanticsLabel('Gửi').last);
      await tester.pump();
      await tester.pump();
      expect(_text('Đang kiểm tra…'), findsOneWidget);
      expect(_text('Chưa gửi · đang ngoại tuyến'), findsNothing);
      repo.error = null;
      await tester.pump(AssistantChat.checkDelay);
      await tester.pumpAndSettle();
      final starts = repo.named('startTask');
      expect(starts, hasLength(2));
      expect(starts[1].args['requestId'], starts[0].args['requestId']);
      expect(_text('Đang kiểm tra…'), findsNothing);
    });

    testWidgets('AI-6: a confirm after a timeout keeps its request id', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {taskA: batchSnapshot()},
        error: {'confirmDrafts': const AssistantException('deadline-exceeded')},
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      expect(_text('Mạng chậm · đang kiểm tra lại…'), findsOneWidget);
      repo.error = null;
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      final confirms = repo.named('confirmDrafts');
      expect(confirms, hasLength(2));
      expect(confirms[1].args['requestId'], confirms[0].args['requestId']);
    });

    testWidgets('AI-8: a refusal offers no endless "Thử lại"', (tester) async {
      final repo = FakeAssistantRepository(
        error: {'startTask': const AssistantException('resource-exhausted')},
      );
      await _pump(tester, repo: repo);
      await _type(tester, 'Hôm nay con bú thế nào?');
      await _send(tester);
      expect(
        _text(
          'Mình chưa làm được việc này. Chưa có gì được lưu — bạn ghi trực tiếp nhé.',
        ),
        findsOneWidget,
      );
      expect(_text('Thử lại'), findsNothing);
      expect(_text('Gửi lại'), findsNothing);
      expect(_text('Sửa lại'), findsOneWidget);
    });

    testWidgets('AI-8: another member\'s failed question has no "Thử lại"', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: {
              ...sharedTaskJson(by: minh, state: 'failed'),
              'errorCode': 'AI_UNAVAILABLE',
            },
            messages: [userMessage('8 giờ con bú bình 120 ml')],
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(
        _text(
          'Mình chưa trả lời được lúc này. Chưa có gì được lưu — bạn thử lại nhé, hoặc ghi trực tiếp.',
        ),
        findsOneWidget,
      );
      expect(_text('Thử lại'), findsNothing);
    });

    testWidgets(
      'AI-9: a task that does not move says so, then offers a way out',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(state: 'processing', version: 2),
              messages: [userMessage('Hôm nay con bú thế nào?')],
            ),
          },
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        expect(_text('Lumi đang soạn…'), findsOneWidget);
        await tester.pump(AssistantChat.slowAfter);
        await tester.pump();
        expect(_text('Lumi vẫn đang xử lý…'), findsOneWidget);
        await tester.pump(AssistantChat.stuckAfter);
        await tester.pump();
        expect(
          _text('Lumi đang lâu hơn thường lệ. Chưa có gì được lưu từ câu này.'),
          findsOneWidget,
        );
        // The task finished meanwhile: "Kiểm tra lại" reads it.
        repo.tasks[taskA] = batchSnapshot();
        await tester.tap(_text('Kiểm tra lại'));
        await tester.pumpAndSettle();
        expect(_text('Lưu 2 mục'), findsOneWidget);
        expect(_text('Lumi vẫn đang xử lý…'), findsNothing);
      },
    );
  });

  group('L4 next step (lumi-plan §7, sprint wow)', () {
    /// Bottles every 3 h, 07:00–19:00 in Hà Nội, 10–14 Oct: a usual gap of 180 min.
    final log = [
      for (var d = 10; d <= 14; d++)
        for (var m = 7 * 60; m <= 19 * 60; m += 180)
          CareRecord(
            id: 'r_${'$d$m'.padLeft(32, '0')}',
            babyId: teddyId,
            type: CareType.bottle,
            occurredAt: DateTime.utc(
              2026,
              10,
              d,
              m ~/ 60,
              m % 60,
            ).subtract(const Duration(hours: 7)),
            createdBy: 'u_mai',
            author: CareAuthor.of(mai),
          ),
    ];
    final recentFeed = {
      ...batchSnapshot(),
      'drafts': [
        bottleDraftJson(at: '2026-10-15T07:00:00.000Z'),
        sleepDraftJson(),
      ],
    };

    testWidgets('a feed just saved offers "Nhắc cữ tiếp" with the usual gap', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: recentFeed});
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA]),
        extra: [
          recentRecordsProvider(teddyId).overrideWith((_) => Stream.value(log)),
        ],
      );
      expect(_text('Nhắc cữ tiếp'), findsNothing);
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      // Only on the feed, not on the sleep.
      expect(_text('Nhắc cữ tiếp'), findsOneWidget);
      await tester.tap(_text('Nhắc cữ tiếp'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/care/reminders/rules/new?interval=180');
    });

    testWidgets('no usual gap, or an older feed: no chip', (tester) async {
      final repo = FakeAssistantRepository(tasks: {taskA: batchSnapshot()});
      await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA]),
        extra: [
          recentRecordsProvider(teddyId).overrideWith((_) => Stream.value(log)),
        ],
      );
      await tester.tap(_text('Lưu 2 mục'));
      await tester.pumpAndSettle();
      // The batch's bottle was at 08:00, more than 3 h before now (14:20).
      expect(_text('Nhắc cữ tiếp'), findsNothing);
    });
  });
}
