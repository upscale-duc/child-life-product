import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/router_pump.dart';

/// Lumi L7 (P-168 #2, #6): what a follow-up shows — "Mình bỏ câu hỏi về …" with "Giữ lại",
/// a plain restate, and the cards that change or delete a record saved minutes ago.
/// Synthetic data only.

String _key(String what) => 'assistant.$what.u_mai:${teddyScope.key}';

Map<String, Object> _thread(List<String> ids) => {
  _key('conversation'): conversation1,
  _key('tasks'): ids,
};

Future<void> _pump(
  WidgetTester tester,
  FakeAssistantRepository repo, {
  required List<String> tasks,
}) async {
  await pumpRouted(
    tester,
    AssistantChatScreen(scopeKey: teddyScope.key),
    prefs: _thread(tasks),
    overrides: assistantOverrides(repo: repo),
  );
  await tester.pumpAndSettle();
}

Map<String, Object?> _op(
  Map<String, Object?> draft,
  String op, {
  String recordId = 'r_00000000000000000000000000000001',
}) => {...draft, 'op': op, 'targetRecordId': recordId};

void main() {
  test('a draft reads its op (absent = a new record)', () {
    final plain = AssistantDraft.fromJson(bottleDraftJson())!;
    expect(plain.op, DraftOp.create);
    expect(plain.targetRecordId, isNull);
    final edit = AssistantDraft.fromJson(_op(bottleDraftJson(), 'update'))!;
    expect(edit.op, DraftOp.update);
    expect(edit.targetRecordId, 'r_00000000000000000000000000000001');
    expect(
      AssistantDraft.fromJson(_op(bottleDraftJson(), 'delete'))!.op,
      DraftOp.delete,
    );
  });

  testWidgets(
    '"Mình bỏ câu hỏi về …" offers "Giữ lại", which sends its words',
    (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(),
            messages: [
              userMessage('hôm nay bé ngủ bao nhiêu rồi'),
              assistantMessage([
                codedText(
                  'Mình bỏ câu hỏi về cữ bú bình 180ml nhé.',
                  'QUESTION_SET_ASIDE',
                ),
                textPart('Giấc ngủ đã ghi hôm nay: 2 giấc.'),
              ]),
            ],
          ),
        },
      );
      await _pump(tester, repo, tasks: [taskA]);
      expect(
        find.text('Mình bỏ câu hỏi về cữ bú bình 180ml nhé.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Giữ lại'));
      await tester.pumpAndSettle();
      expect(repo.named('startTask').single.args['text'], 'Giữ lại');
      expect(repo.named('submitClarification'), isEmpty);
    },
  );

  testWidgets('a restate ("là sao") is a plain Lumi line', (tester) async {
    const said =
        'Mình đang chờ bạn lưu cữ bú bình 180ml lúc 13:00 ở trên. Bấm Lưu để ghi.';
    final repo = FakeAssistantRepository(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(),
          messages: [
            userMessage('là sao'),
            assistantMessage([codedText(said, 'FOLLOW_UP')]),
          ],
        ),
      },
    );
    await _pump(tester, repo, tasks: [taskA]);
    expect(find.text(said), findsOneWidget);
  });

  testWidgets('"180 chứ" after a save: "Sửa cữ bú bình" saves the change', (
    tester,
  ) async {
    final repo = FakeAssistantRepository(
      tasks: {
        taskA: snapshotWith(
          task: taskJson(),
          drafts: [_op(bottleDraftJson(ml: 180), 'update')],
          messages: [
            userMessage('180 chứ'),
            assistantMessage([draftRef(draftOf(taskA, 0))]),
          ],
        ),
      },
    );
    await _pump(tester, repo, tasks: [taskA]);
    expect(find.text('Sửa cữ bú bình'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repo.named('confirmDrafts'), hasLength(1));
  });

  testWidgets(
    '"xoá cái vừa ghi": "Xoá khỏi nhật ký" or "Không xoá", never an edit; then "Đã xoá"',
    (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(),
            drafts: [_op(bottleDraftJson(), 'delete')],
            messages: [
              userMessage('xoá cái vừa ghi'),
              assistantMessage([draftRef(draftOf(taskA, 0))]),
            ],
          ),
          taskB: snapshotWith(
            task: taskJson(id: taskB),
            drafts: [
              _op(
                bottleDraftJson(
                  taskId: taskB,
                  state: 'saved',
                  recordId: 'r_00000000000000000000000000000002',
                ),
                'delete',
              ),
            ],
            messages: [
              userMessage('xoá đi', taskId: taskB),
              assistantMessage([draftRef(draftOf(taskB, 0))], taskId: taskB),
            ],
          ),
        },
      );
      await _pump(tester, repo, tasks: [taskB, taskA]);
      expect(find.text('Xoá cữ bú bình'), findsNWidgets(2));
      expect(find.text('Xoá khỏi nhật ký'), findsOneWidget);
      expect(find.text('Không xoá'), findsOneWidget);
      expect(find.text('Sửa'), findsNothing);
      expect(find.text('Đã xoá'), findsOneWidget);
      await tester.tap(find.text('Không xoá'));
      await tester.pumpAndSettle();
      expect(repo.named('discardDraft'), hasLength(1));
    },
  );
}
