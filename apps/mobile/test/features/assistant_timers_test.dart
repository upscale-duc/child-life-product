import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_widgets.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Lumi 2026-10-16 on the phone (scripted assistant, no Firebase): ongoing states drive the
/// app's own timers from a chat card ("Bắt đầu tính giờ ngủ · 14:20", the live running timer,
/// "Kết thúc" / "Để tiếp tục", "Mở đồng hồ"); a "Cần kiểm tra" draft says what is missing and
/// fixes it in place, its save enables as soon as it is fixed; one draft saves from its own
/// card; a repeated message leaves the waiting draft alone. Synthetic data only.

const _session = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, Object> _prefs(List<String> ids) => {
  'assistant.conversation.u_mai:${teddyScope.key}': conversation1,
  'assistant.tasks.u_mai:${teddyScope.key}': ids,
};

Future<List<Visit>> _pump(
  WidgetTester tester,
  FakeAssistantRepository repo, {
  List<String> tasks = const [taskA],
  Map<TimerType, CareTimer> timers = const {},
}) async {
  final (visits, _) = await pumpRouted(
    tester,
    AssistantChatScreen(scopeKey: teddyScope.key),
    prefs: _prefs(tasks),
    overrides: assistantOverrides(repo: repo, timers: timers),
  );
  await tester.pumpAndSettle();
  return visits;
}

Map<String, Object?> _one(
  Map<String, Object?> draft, {
  String said = 'Con đang ngủ',
  List<Map<String, Object?>> before = const [],
}) => snapshotWith(
  task: taskJson(),
  drafts: [draft],
  messages: [
    userMessage(said),
    assistantMessage([...before, draftRef(draft['id']! as String)]),
  ],
);

Finder _text(String s) => find.text(s);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// The card's own save button.
AsButton _primary(WidgetTester tester) =>
    tester.widget<AsButton>(find.byKey(const ValueKey('as.card.primary')));

void main() {
  group('timers from chat', () {
    testWidgets(
      '"Con đang ngủ": one tap starts the sleep timer; the card then runs live and opens the timer',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {taskA: _one(timerDraftJson())},
          confirmAnswer: (args) => {
            'items': [
              {
                'draftId': draftOf(taskA, 0),
                'status': 'saved',
                'revision': 1,
                'recordId': 'r_$_session',
                'recordLink': '/care/timer/sleep?babyId=$teddyId',
                'errorCode': null,
                'problems': const <String>[],
              },
            ],
            'partial': false,
          },
        );
        final visits = await _pump(
          tester,
          repo,
          timers: {TimerType.sleep: runningTimer(startedAt: assistantNow)},
        );
        expect(_text('Tính giờ ngủ'), findsOneWidget);
        expect(_text('Từ 14:20'), findsOneWidget);
        // One draft: no tick box, no "Chọn mục muốn lưu" — just the concrete save.
        expect(_text('Chọn mục muốn lưu'), findsNothing);
        expect(_primary(tester).label, 'Bắt đầu tính giờ ngủ · 14:20');
        expect(_primary(tester).onPressed, isNotNull);

        await _tap(tester, _text('Bắt đầu tính giờ ngủ · 14:20'));
        final sent =
            repo.named('confirmDrafts').single.args['selected']! as List;
        expect((sent.single as Map)['draftId'], draftOf(taskA, 0));
        // Saved inline (no navigation): the running timer, live from the timer document.
        expect(_text('Đã lưu'), findsOneWidget);
        expect(_text('Đang ngủ · 00:00:00'), findsOneWidget);
        expect(find.byKey(const ValueKey('as.card.primary')), findsNothing);
        await _tap(tester, _text('Mở đồng hồ'));
        expect(visits.last.location, '/care/timer/sleep');
      },
    );

    testWidgets(
      'already running: says so, shows the live timer, "Kết thúc giấc ngủ · 14:20" or "Để tiếp tục"',
      (tester) async {
        final started = assistantNow.subtract(const Duration(minutes: 40));
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: _one(
              timerDraftJson(
                action: 'stop',
                sessionId: _session,
                startedAt: started.toIso8601String(),
              ),
              before: [
                {
                  ...codedText(
                    'Bé đang ngủ, đồng hồ đã tính giờ từ 13:40. Kết thúc giấc ngủ bây giờ, hay để đồng hồ tiếp tục?',
                    'TIMER_RUNNING',
                  ),
                  'link': '/care/timer/sleep?babyId=$teddyId',
                },
              ],
            ),
          },
        );
        final visits = await _pump(
          tester,
          repo,
          timers: {TimerType.sleep: runningTimer(startedAt: started)},
        );
        expect(_text('Kết thúc giấc ngủ'), findsOneWidget);
        expect(_text('13:40 – 14:20 · 40 phút'), findsOneWidget);
        expect(_text('Đang ngủ · 00:40:00'), findsOneWidget);
        expect(_primary(tester).label, 'Kết thúc giấc ngủ · 14:20');
        // "Mở đồng hồ" on the notice: the timer screen (Back returns here).
        await _tap(tester, _text('Mở đồng hồ').first);
        expect(visits.last.location, '/care/timer/sleep');
        // Back from the timer screen lands on this chat again.
        GoRouter.of(tester.element(find.text('stub'))).pop();
        await tester.pumpAndSettle();
        expect(_text('Kết thúc giấc ngủ'), findsOneWidget);
        await _tap(tester, _text('Để tiếp tục'));
        expect(
          repo.named('discardDraft').single.args['draftId'],
          draftOf(taskA, 0),
        );
      },
    );

    testWidgets('"đang cho bú (trái)": the feed timer starts on the left', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: _one(
            timerDraftJson(timer: 'breast', side: 'left'),
            said: 'đang cho bú (trái)',
          ),
        },
      );
      await _pump(tester, repo);
      expect(_text('Tính giờ bú mẹ'), findsOneWidget);
      expect(_text('Từ 14:20 · bên trái trước'), findsOneWidget);
      await _tap(tester, _text('Bắt đầu tính giờ bú · trái · 14:20'));
      expect(repo.named('confirmDrafts'), hasLength(1));
    });
  });

  group('review cards explain and fix in place', () {
    testWidgets(
      'the second dev report: a breastfeed missing its side opens its fix by itself; "Trái" enables "Lưu cữ bú"',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: _one(
              reviewed(breastDraftJson(), missing: ['side']),
              said: 'Con đã bú mẹ được 20p',
            ),
          },
          patchAnswer: (args) => breastDraftJson(side: 'left', revision: 2),
        );
        await _pump(tester, repo);
        // No "Sửa" tap first: the gap is said and its chips are right there.
        expect(_text('Chưa rõ bé bú bên nào'), findsOneWidget);
        expect(_text('Trái'), findsOneWidget);
        expect(_text('Chọn mục muốn lưu'), findsNothing);
        // Disabled only with its reason next to it.
        expect(_primary(tester).label, 'Lưu cữ bú');
        expect(_primary(tester).onPressed, isNull);
        expect(_text('Chọn ở trên là lưu được ngay.'), findsOneWidget);

        await _tap(tester, _text('Trái'));
        final patch = repo.named('patchDraft').single.args;
        expect((patch['payload']! as Map)['side'], 'left');
        expect(patch['confirmedFields'], ['side']);
        expect(_text('Chưa rõ bé bú bên nào'), findsNothing);
        expect(_primary(tester).onPressed, isNotNull);
        await _tap(tester, _text('Lưu cữ bú'));
        expect(repo.named('confirmDrafts'), hasLength(1));
      },
    );

    testWidgets(
      'the first dev report: an observation flagged "date" (set) is one tap away; day / night is optional',
      (tester) async {
        final obs = {
          ...observationDraftJson(),
          'payload': {
            'kind': 'observation',
            'observation': 'sleep',
            'date': '2026-10-15',
            'when': null,
            'note': 'Con đang ngủ',
          },
        };
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: _one(reviewed(obs, missing: ['date'])),
          },
          patchAnswer: (args) => {
            ...obs,
            'payload': args['payload'],
            'revision': 2,
          },
        );
        await _pump(tester, repo);
        expect(_text('Ngày 15/10 có đúng không?'), findsOneWidget);
        expect(
          _text('Giấc ban ngày hay ban đêm? (không bắt buộc)'),
          findsOneWidget,
        );
        expect(_primary(tester).label, 'Lưu ghi nhận');
        expect(_primary(tester).onPressed, isNull);
        await _tap(tester, _text('Hôm nay'));
        expect(repo.named('patchDraft').single.args['confirmedFields'], [
          'date',
        ]);
        // Fixed: saveable, the optional question still offered but not blocking.
        expect(_primary(tester).onPressed, isNotNull);
        expect(
          _text('Giấc ban ngày hay ban đêm? (không bắt buộc)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a sleep without its wake-up: "Chưa có giờ bé dậy" with "Vừa dậy (14:20)"',
      (tester) async {
        final sleep = reviewed(
          sleepDraftJson(index: 0, start: '2026-10-15T05:00:00.000Z'),
          missing: ['endedAt'],
          payload: {'endedAt': null},
        );
        final repo = FakeAssistantRepository(
          tasks: {taskA: _one(sleep, said: 'bé ngủ từ 12h')},
          patchAnswer: (args) => sleepDraftJson(
            index: 0,
            start: '2026-10-15T05:00:00.000Z',
            end: '2026-10-15T07:20:00.000Z',
            revision: 2,
          ),
        );
        await _pump(tester, repo);
        expect(_text('Chưa có giờ bé dậy'), findsOneWidget);
        await _tap(tester, _text('Vừa dậy (14:20)'));
        final payload = repo.named('patchDraft').single.args['payload']! as Map;
        expect(payload['endedAt'], '2026-10-15T07:20:00.000Z');
        expect(_primary(tester).label, 'Lưu giấc ngủ');
        expect(_primary(tester).onPressed, isNotNull);
      },
    );

    testWidgets(
      'several drafts: the bar says what is left; a fixed draft is ticked by itself → "Lưu 2 mục"',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: taskJson(),
              drafts: [
                reviewed(bottleDraftJson(), uncertain: ['amountMl']),
                reviewed(sleepDraftJson(), uncertain: ['endedAt']),
              ],
              messages: [
                userMessage(
                  '8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.',
                ),
                assistantMessage([
                  draftRef(draftOf(taskA, 0)),
                  draftRef(draftOf(taskA, 1)),
                ]),
              ],
            ),
          },
          patchAnswer: (args) => args['draftId'] == draftOf(taskA, 0)
              ? bottleDraftJson(revision: 2)
              : sleepDraftJson(revision: 2),
        );
        await _pump(tester, repo);
        expect(_text('Lượng 120 ml có đúng không?'), findsOneWidget);
        // LUMI-09: the row names which time ("giờ dậy"), never a bare "Giờ 10:00".
        expect(_text('Giờ dậy 10:00 có đúng không?'), findsOneWidget);
        expect(_text('Còn 2 mục cần bổ sung ở trên'), findsOneWidget);
        await _tap(tester, _text('Đúng rồi').first);
        expect(repo.named('patchDraft').single.args['confirmedFields'], [
          'amountMl',
        ]);
        expect(_text('Lưu 1 mục'), findsOneWidget);
        await _tap(tester, _text('Đúng rồi').first);
        expect(_text('Lưu 2 mục'), findsOneWidget);
      },
    );

    testWidgets(
      'a repeated message leaves the waiting draft as it is (saveable above)',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: _one(bottleDraftJson(), said: 'bé bú 120ml'),
            taskB: snapshotWith(
              task: taskJson(id: taskB),
              messages: [
                userMessage('bé bú 120ml', taskId: taskB),
                assistantMessage([
                  codedText(
                    'Mình đã chuẩn bị mục này ngay ở trên và nó đang chờ bạn lưu. Bạn kiểm tra rồi bấm Lưu ở đó nhé. Không tính lượt.',
                    'SAME_AS_PENDING',
                  ),
                ], taskId: taskB),
              ],
            ),
          },
        );
        await _pump(tester, repo, tasks: const [taskA, taskB]);
        expect(
          _text(
            'Mình đã chuẩn bị mục này ngay ở trên và nó đang chờ bạn lưu. Bạn kiểm tra rồi bấm Lưu ở đó nhé. Không tính lượt.',
          ),
          findsOneWidget,
        );
        expect(_text('Đã bỏ'), findsNothing);
        expect(_primary(tester).label, 'Lưu cữ bú bình');
        expect(_primary(tester).onPressed, isNotNull);
      },
    );
  });

  test(
    'a timer draft parses and round-trips; an unknown timer stays unknown',
    () {
      final d = AssistantDraft.fromJson(
        timerDraftJson(
          action: 'stop',
          sessionId: _session,
          startedAt: '2026-10-15T06:40:00.000Z',
        ),
      )!;
      expect(d.kind, DraftKind.timer);
      final p = d.payload as TimerPayload;
      expect(p.toJson(), {
        'kind': 'timer',
        'timer': 'sleep',
        'action': 'stop',
        'at': '2026-10-15T07:20:00.000Z',
        'side': null,
        'sessionId': _session,
        'startedAt': '2026-10-15T06:40:00.000Z',
      });
      final odd = DraftPayload.fromJson({
        'kind': 'timer',
        'timer': 'pump',
        'action': 'start',
      });
      expect(odd, isA<UnknownPayload>());
    },
  );
}
