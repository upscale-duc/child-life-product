import 'dart:convert';

import 'package:child_life/features/assistant/assistant_controller.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_photos.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_rules.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/spending/spending_currency.dart';
import 'package:child_life/features/spending/spending_format.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// Slice A5 on the phone with a scripted assistant (no Firebase): photos CH09–CH14 (exact quote,
/// retention choice, upload and cancel, reconnect, receipt review with date confirm and
/// duplicate acknowledge, honest retention G05, note lines, unreadable / mixed) and care
/// CH15–CH18 (sleep questions with the safety note, approved guidance reviewed / not, "Thử tối
/// nay" as an intention, the follow-up only once due, feedback at 0 credits, recipes with
/// exclusions and the empty state, health support with the region's number).

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

Future<(List<Visit>, ProviderContainer)> _pump(
  WidgetTester tester, {
  required FakeAssistantRepository repo,
  AssistantScope? scope,
  Map<String, Object> prefs = const {},
  Membership? me,
  bool images = true,
  FakeUploader? uploader,
  bool tall = true,
}) async {
  final r = await pumpRouted(
    tester,
    AssistantChatScreen(scopeKey: (scope ?? teddyScope).key),
    prefs: prefs,
    overrides: assistantOverrides(
      repo: repo,
      me: me,
      images: images,
      uploader: uploader,
    ),
  );
  if (tall) {
    // Long threads: every card built (the chat list is lazy).
    tester.view.physicalSize = const Size(375, 2400);
    await tester.pump();
  }
  await tester.pumpAndSettle();
  return r;
}

Finder _text(String s) => find.text(s);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// CH09: camera → sheet → library → the exact quote in the thread.
Future<void> _choose(WidgetTester tester) async {
  await _tap(tester, find.bySemanticsLabel('Ảnh').last);
  await _tap(tester, _text('Chọn từ thư viện'));
}

Map<String, Object?> _processing() =>
    photoSnapshot(task: photoTaskJson(state: 'processing'));

void main() {
  group('models and rules (A5)', () {
    test(
      'typed parts: guidance words, recipes, health number, notice codes',
      () {
        final g = AssistantPart.fromJson(guidancePart()) as ApprovedContentPart;
        expect(g.content!.title, 'Giảm kích thích 30 phút trước giấc đêm');
        expect(g.content!.steps, hasLength(3));
        expect(g.content!.timeOfDay, ContentTimeOfDay.evening);
        expect(g.reviewed, isFalse);
        expect(g.alternatives.single.contentId, 'act_white_noise');
        final r = AssistantPart.fromJson(recipesPart()) as RecipeListPart;
        expect(r.items.map((i) => i.title), [
          'Cháo bí đỏ yến mạch',
          'Cà rốt hấp nghiền',
        ]);
        expect(r.excludedCount, 1);
        expect(r.mealLogAvailable, isFalse);
        final h =
            AssistantPart.fromJson({
                  'type': 'health_support',
                  'schemaVersion': 1,
                  'signs': ['breathing'],
                  'emergency': {'country': 'VN', 'number': '115'},
                })
                as HealthSupportPart;
        expect(h.emergency?.number, '115');
        final t =
            AssistantPart.fromJson(
                  codedText('Chưa có công thức', 'RECIPES_NONE_APPROVED'),
                )
                as TextPart;
        expect(t.code, NoticeCode.recipesNoneApproved);
        // An A2 approved_content without words still parses (reason only).
        final old =
            AssistantPart.fromJson({
                  'type': 'approved_content',
                  'schemaVersion': 1,
                  'contentId': 'x',
                  'contentVersion': 1,
                  'reason': 'r',
                  'reviewed': true,
                })
                as ApprovedContentPart;
        expect(old.content, isNull);
      },
    );

    test('snapshot: care view, follow-up choices, photos and problems', () {
      final s = TaskSnapshot.fromJson({
        'task': careTaskJson(care: sleepCare(plan: planJson(), followUp: true)),
        'drafts': [
          reminderDraftJson(problems: ['PAST_TIME', 'INVALID_TITLE']),
        ],
        'attachments': [attachmentJson(state: 'deletion_pending')],
      })!;
      final care = s.task.care!;
      expect(care.sleep?.kind, 'falling_asleep');
      expect(care.plan?.feedbackOpensAt, DateTime.utc(2026, 10, 15, 22));
      expect(care.followUp!.choices.map((c) => c.outcome), [
        FeedbackOutcome.helpful,
        FeedbackOutcome.unsure,
        FeedbackOutcome.notSuitable,
        FeedbackOutcome.notTried,
      ]);
      expect(s.drafts.single.problems, [
        DraftProblem.pastTime,
        DraftProblem.invalidTitle,
      ]);
      expect(s.attachments.single.state, AttachmentState.deletionPending);
    });

    test('upload target: only the owned assistant folder', () {
      expect(AssistantUploadTarget.fromJson(uploadTargetJson()), isNotNull);
      expect(
        AssistantUploadTarget.fromJson({
          ...uploadTargetJson(),
          'uploadPath': 'babies/b_1/expenses/x.jpg',
        }),
        isNull,
      );
      expect(
        AssistantUploadTarget.fromJson(uploadTargetJson())!.retention,
        AttachmentRetention.keepWithRecord,
      );
      expect(defaultAttachmentRetention, AttachmentRetention.keepWithRecord);
    });

    test('G05: "đã xoá" only when Storage confirmed it', () {
      AttachmentView a(String state, {String? at, bool kept = false}) =>
          AttachmentView.fromJson(
            attachmentJson(state: state, deletedAt: at, kept: kept),
          )!;
      expect(retentionLine(const []), isNull);
      expect(retentionLine([a('ready')]), RetentionLine.keptIfSaved);
      expect(
        retentionLine([
          AttachmentView.fromJson(
            attachmentJson(retention: 'delete_after_read'),
          )!,
        ]),
        RetentionLine.willDelete,
      );
      expect(retentionLine([a('deletion_pending')]), RetentionLine.deleting);
      // `deleted` without the confirmed instant is still not "đã xoá".
      expect(retentionLine([a('deleted')]), RetentionLine.deleting);
      expect(
        retentionLine([a('deleted', at: '2026-10-15T07:30:00Z')]),
        RetentionLine.deleted,
      );
      expect(
        retentionLine([a('deleted', at: '2026-10-15T07:30:00Z', kept: true)]),
        RetentionLine.keptWithExpense,
      );
      // A late snapshot never moves a confirmed deletion back to pending.
      final merged = mergeAttachments(
        [a('deleted', at: '2026-10-15T07:30:00Z')],
        [a('deletion_pending')],
      );
      expect(merged.single.deletionConfirmed, isTrue);
    });

    test('a live task document keeps the open CH17 question', () {
      final view = AssistantTask.fromJson(
        careTaskJson(care: sleepCare(plan: planJson(), followUp: true)),
      )!;
      final doc = AssistantTask.fromJson(
        careTaskJson(care: sleepCare(plan: planJson())),
      )!;
      expect(mergeTask(view, doc).care?.followUp, isNotNull);
      final answered = AssistantTask.fromJson(
        careTaskJson(
          care: sleepCare(plan: planJson(), feedback: 'helpful'),
        ),
      )!;
      expect(mergeTask(view, answered).care?.followUp, isNull);
    });

    test('photo status from the task and its attachment', () {
      AssistantTask task(String state, [String? error]) =>
          AssistantTask.fromJson(
            photoTaskJson(state: state, errorCode: error),
          )!;
      expect(photoStatus(task('processing'), null), PhotoStatus.reading);
      expect(photoStatus(task('ready'), null), PhotoStatus.read);
      expect(
        photoStatus(task('failed', 'OCR_UNREADABLE'), null),
        PhotoStatus.blurry,
      );
      expect(
        photoStatus(
          task('failed', 'VALIDATION_FAILED'),
          AttachmentView.fromJson(attachmentJson(rejected: true)),
        ),
        PhotoStatus.refused,
      );
    });

    test('money in minor units and reminder time from the server', () {
      // The assistant's currency list is Chi tiêu's (D-075 #4), never a copy.
      expect(supportedCurrencies, {for (final c in spCurrencies) c.code});
      expect(
        supportedCurrencies,
        containsAll(['THB', 'HKD', 'CNY', 'CHF', 'MYR']),
      );
      expect(currencyDigits('VND'), 0);
      expect(currencyDigits('USD'), 2);
      expect(currencyDigits('JPY'), 0);
      final missing = AssistantDraft.fromJson(
        reminderDraftJson(time: null, missing: ['time'], state: 'needs_review'),
      )!;
      expect(reminderNeedsTimeFor(missing), isTrue);
      // Date-only accepted by the server (D-075 #5): no MISSING_TIME, no missing field.
      final dateOnly = AssistantDraft.fromJson(reminderDraftJson(time: null))!;
      expect(reminderNeedsTimeFor(dateOnly), isFalse);
      // A "Cần kiểm tra" draft is never pre-ticked; nor one the server finds a problem in.
      expect(defaultSelected(missing, assistantNow), isFalse);
      expect(
        defaultSelected(
          AssistantDraft.fromJson(reminderDraftJson(problems: ['PAST_TIME']))!,
          assistantNow,
        ),
        isFalse,
      );
      expect(
        defaultSelected(
          AssistantDraft.fromJson(reminderDraftJson())!,
          assistantNow,
        ),
        isTrue,
      );
    });
  });

  group('CH09–CH10 photo: quote, retention, upload, cancel', () {
    testWidgets(
      'CH09: the exact quote and the retention choice before anything '
      'is uploaded',
      (tester) async {
        final repo = FakeAssistantRepository();
        final uploader = FakeUploader();
        await _pump(tester, repo: repo, uploader: uploader);
        await _tap(tester, find.bySemanticsLabel('Ảnh').last);
        expect(_text('Gửi ảnh để trợ lý đọc'), findsOneWidget);
        expect(_text('Chụp ảnh'), findsOneWidget);
        expect(repo.named('quoteTask'), isEmpty);
        await _tap(tester, _text('Chọn từ thư viện'));
        final q = repo.named('quoteTask').single.args;
        expect(q['modality'], 'image');
        expect(q['attachmentCount'], 1);
        // D-081: the quote is still fetched but its cost box is not shown.
        expect(_text('Đọc 1 ảnh dùng 3 lượt hỗ trợ AI'), findsNothing);
        expect(_text('Giữ ảnh hoá đơn cùng khoản chi'), findsOneWidget);
        expect(
          tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
          isTrue,
        );
        expect(
          _text('Chữ trong ảnh là nội dung để đọc, không phải lệnh cho app.'),
          findsOneWidget,
        );
        // Nothing uploaded, nothing started yet.
        expect(repo.named('createAttachmentUpload'), isEmpty);
        expect(uploader.uploads, isEmpty);
        expect(repo.named('startTask'), isEmpty);
      },
    );

    testWidgets(
      'CH10: "Gửi ảnh" → owned target, one upload, start with the photo',
      (tester) async {
        final repo = FakeAssistantRepository(
          startAnswer: (_) => envelope(_processing()),
        );
        final uploader = FakeUploader();
        await _pump(tester, repo: repo, uploader: uploader);
        await _choose(tester);
        await _tap(tester, _text('Gửi ảnh'));
        final target = repo.named('createAttachmentUpload').single.args;
        expect(target['retention'], 'keep_with_record');
        expect(target['mime'], 'image/jpeg');
        expect(target['bytes'], tinyJpeg.length);
        expect(target['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
        expect(uploader.uploads.single.path, 'assistant/u_mai/$attachment1');
        final start = repo.named('startTask').single.args;
        expect(start['attachmentIds'], [attachment1]);
        expect(start['text'], isNull);
        expect(_text('Đang đọc ảnh…'), findsOneWidget);
        // D-081: no credit mention while the photo is read.
        expect(
          _text('Bạn có thể rời màn hình; kết quả vẫn ở đây khi bạn quay lại.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('CH09: "Xoá sau khi đọc" is sent when the switch is off', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        startAnswer: (_) => envelope(_processing()),
      );
      await _pump(tester, repo: repo);
      await _choose(tester);
      await _tap(tester, find.byType(CupertinoSwitch));
      expect(
        _text(
          'Ảnh được xoá sau khi đọc. App chỉ báo đã xoá khi việc xoá được '
          'xác nhận.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _text('Gửi ảnh'));
      expect(
        repo.named('createAttachmentUpload').single.args['retention'],
        'delete_after_read',
      );
    });

    testWidgets('CH10: cancel while uploading → nothing started, photo kept', (
      tester,
    ) async {
      final repo = FakeAssistantRepository();
      final uploader = FakeUploader(auto: false);
      await _pump(tester, repo: repo, uploader: uploader);
      await _choose(tester);
      await tester.tap(_text('Gửi ảnh'));
      await tester.pump();
      await tester.pump();
      expect(_text('Đang tải lên · 0%'), findsOneWidget);
      uploader.uploads.single.push(0.6);
      await tester.pump();
      await tester.pump();
      expect(_text('Đang tải lên · 60%'), findsOneWidget);
      await _tap(tester, _text('Huỷ'));
      expect(uploader.uploads.single.canceled, isTrue);
      expect(repo.named('startTask'), isEmpty);
      // D-081: the cancel note no longer mentions credits.
      expect(_text('Đã huỷ tải lên. Ảnh vẫn được chọn.'), findsOneWidget);
      // The same photo can still be sent.
      expect(_text('Gửi ảnh'), findsOneWidget);
    });

    testWidgets('the pool moved since the quote: no target, nothing uploaded', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        error: {
          'createAttachmentUpload': const AssistantException(
            'resource-exhausted',
            reason: AssistantReason.usageExhausted,
          ),
        },
      );
      final uploader = FakeUploader();
      await _pump(tester, repo: repo, uploader: uploader);
      await _choose(tester);
      await _tap(tester, _text('Gửi ảnh'));
      expect(uploader.uploads, isEmpty);
      expect(repo.named('startTask'), isEmpty);
      expect(_text('Ảnh · chưa gửi'), findsOneWidget);
      expect(find.textContaining('Đọc ảnh này cần 3 lượt'), findsOneWidget);
    });

    testWidgets('an expired quote is replaced once, never reused', (
      tester,
    ) async {
      var calls = 0;
      final repo = FakeAssistantRepository(
        startAnswer: (_) => envelope(_processing()),
      );
      await _pump(tester, repo: repo);
      await _choose(tester);
      repo.uploadAnswer = (args) {
        if (calls++ == 0) {
          throw const AssistantException(
            'failed-precondition',
            reason: AssistantReason.quoteExpired,
          );
        }
        return uploadTargetJson();
      };
      await _tap(tester, _text('Gửi ảnh'));
      expect(repo.named('quoteTask'), hasLength(2));
      expect(repo.named('createAttachmentUpload'), hasLength(2));
      expect(repo.named('startTask'), hasLength(1));
    });

    testWidgets(
      'leaving the screen keeps the task: the snapshot brings it back '
      'and the reading arrives',
      (tester) async {
        final repo = FakeAssistantRepository(tasks: {taskA: _processing()});
        await _pump(
          tester,
          repo: repo,
          scope: householdScope,
          prefs: _thread([taskA], householdScope),
        );
        expect(_text('Đang đọc ảnh…'), findsOneWidget);
        expect(_text('Lumi đang đọc ảnh…'), findsOneWidget);
        repo.tasks[taskA] = photoSnapshot(
          task: photoTaskJson(),
          drafts: [expenseDraftJson()],
          parts: [draftRef(draftOf(taskA, 0))],
        );
        repo.push(
          taskA,
          TaskEventsLive([
            AssistantEvent.fromJson({
              'taskId': taskA,
              'eventId': 'ev9',
              'sequence': 9,
              'type': 'drafts_ready',
              'payload': const <String, Object?>{},
            })!,
          ]),
        );
        await tester.pumpAndSettle();
        expect(_text('Chi tiêu từ hoá đơn'), findsOneWidget);
        expect(_text('Đã đọc'), findsOneWidget);
      },
    );
  });

  group('CH11–CH12 receipt', () {
    Map<String, Object?> receipt({
      Map<String, Object?>? draft,
    }) => photoSnapshot(
      task: photoTaskJson(),
      parts: [
        textPart(
          'Tổng tiền đã gồm thuế: chỉ ghi một khoản, không cộng thêm tạm tính '
          'hay thuế.',
        ),
        draftRef(draftOf(taskA, 0)),
      ],
      drafts: [draft ?? expenseDraftJson()],
    );

    testWidgets(
      'date "?" must be confirmed; duplicate needs "Vẫn lưu"; then save '
      'with the acknowledgement',
      (tester) async {
        final repo = FakeAssistantRepository(tasks: {taskA: receipt()});
        await _pump(
          tester,
          repo: repo,
          scope: householdScope,
          prefs: _thread([taskA], householdScope),
        );
        expect(_text('Con Cưng'), findsOneWidget);
        expect(_text('14/10/2026 ?'), findsOneWidget);
        expect(_text('486.000 ₫'), findsOneWidget);
        expect(_text('Sữa & ăn dặm'), findsOneWidget);
        expect(_text('Gia đình · cho Teddy'), findsOneWidget);
        expect(_text('Cần kiểm tra'), findsOneWidget);
        // Blocked: tapping "Lưu chi tiêu" sends nothing.
        await _tap(tester, _text('Lưu chi tiêu'));
        expect(repo.named('confirmDrafts'), isEmpty);
        // The date row opens the picker; "Xong" confirms the date only.
        repo.patchAnswer = (_) =>
            expenseDraftJson(state: 'draft', uncertain: [], revision: 2);
        await _tap(tester, _text('14/10/2026 ?'));
        await _tap(tester, _text('Xong'));
        final patch = repo.named('patchDraft').single.args;
        expect(patch['confirmedFields'], ['date']);
        expect((patch['payload']! as Map)['date'], '2026-10-14');
        expect(_text('14/10/2026'), findsOneWidget);
        // Still a suspected duplicate: not saved until "Vẫn lưu".
        await _tap(tester, _text('Lưu chi tiêu'));
        expect(repo.named('confirmDrafts'), isEmpty);
        await _tap(tester, _text('Vẫn lưu'));
        expect(_text('Bạn chọn vẫn lưu riêng · không gộp.'), findsOneWidget);
        await _tap(tester, _text('Lưu chi tiêu'));
        final selected =
            (repo.named('confirmDrafts').single.args['selected']! as List)
                    .single
                as Map;
        expect(selected['acknowledge'], ['duplicate_suspected']);
        expect(selected['revision'], 2);
      },
    );

    testWidgets('"Mở khoản chi trùng" opens the logged expenses', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(tasks: {taskA: receipt()});
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      await _tap(tester, _text('Mở khoản chi trùng'));
      expect(visits.last.location, '/utilities/spending/history');
    });

    testWidgets('a currency the module refuses (server problem) blocks save', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: receipt(
            draft: expenseDraftJson(
              uncertain: [],
              warnings: [],
              currency: 'USD',
              problems: ['CURRENCY_UNSUPPORTED'],
            ),
          ),
        },
      );
      await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      expect(_text('${money('vi', 486000, 'USD')} ?'), findsOneWidget);
      expect(_text('Chi tiêu chưa hỗ trợ đơn vị tiền này.'), findsOneWidget);
      await _tap(tester, _text('Lưu chi tiêu'));
      expect(repo.named('confirmDrafts'), isEmpty);
    });

    testWidgets(
      'the same currency once the server accepts it (D-075 #4) saves',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: receipt(
              draft: expenseDraftJson(
                state: 'draft',
                uncertain: [],
                warnings: [],
                currency: 'USD',
              ),
            ),
          },
        );
        await _pump(
          tester,
          repo: repo,
          scope: householdScope,
          prefs: _thread([taskA], householdScope),
        );
        // Chi tiêu's own money format, from minor units (D-075 #4).
        expect(_text(money('vi', 486000, 'USD')), findsOneWidget);
        expect(find.textContaining('USD'), findsNothing);
        await _tap(tester, _text('Lưu chi tiêu'));
        expect(repo.named('confirmDrafts'), hasLength(1));
      },
    );

    testWidgets('CH12: saved → the Chi tiêu record; the photo kept with it', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
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
        },
      );
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      expect(_text('Sữa & ăn dặm · Con Cưng'), findsOneWidget);
      expect(_text('Đã lưu'), findsOneWidget);
      expect(_text('14/10/2026 · 486.000 ₫'), findsOneWidget);
      expect(
        _text('Ảnh hoá đơn được giữ cùng khoản chi trong Chi tiêu.'),
        findsOneWidget,
      );
      await _tap(tester, _text('Mở Chi tiêu'));
      expect(visits.last.location, '/utilities/spending/expense/x_${'e' * 32}');
    });

    testWidgets('G05: deletion pending is never shown as deleted', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
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
            attachments: [
              attachmentJson(
                state: 'deletion_pending',
                retention: 'delete_after_read',
              ),
            ],
          ),
        },
      );
      await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      expect(
        _text(
          'Đang xoá ảnh gốc. App chỉ báo đã xoá khi việc xoá được xác nhận.',
        ),
        findsOneWidget,
      );
      expect(_text('Ảnh gốc đã được xoá.'), findsNothing);
    });
  });

  group('CH13–CH14 notes, unreadable, mixed', () {
    testWidgets('CH13: lines become drafts only after "Lưu thành nhắc việc"', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
            task: photoTaskJson(
              state: 'awaiting_clarification',
              clarification: {
                'id': 'c1',
                'field': 'note.convert',
                'question': {
                  'vi':
                      'Chưa có mục Công việc. Lưu các việc cần làm thành nhắc việc?',
                  'en':
                      'There’s no Tasks section yet. Save the to-dos as reminders?',
                },
                'choices': [
                  {
                    'id': 'reminders',
                    'label': {
                      'vi': 'Lưu thành nhắc việc',
                      'en': 'Save as reminders',
                    },
                  },
                  {
                    'id': 'none',
                    'label': {'vi': 'Không lưu', 'en': 'Don’t save'},
                  },
                ],
                'allowText': false,
              },
            ),
            parts: [
              textPart('Mình thấy 4 dòng. 2 dòng có thể thành nhắc việc.'),
              textPart(
                'Không chuyển thành việc:\n1 dòng về thuốc: không tạo lịch hay '
                'liều dùng thuốc. Hỏi bác sĩ.',
              ),
            ],
          ),
        },
      );
      await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      expect(
        _text('Mình thấy 4 dòng. 2 dòng có thể thành nhắc việc.'),
        findsOneWidget,
      );
      expect(find.textContaining('1 dòng về thuốc'), findsOneWidget);
      expect(find.text('Lưu 2 mục'), findsNothing);
      await _tap(tester, _text('Lưu thành nhắc việc'));
      final c = repo.named('submitClarification').single.args;
      expect(c['choiceId'], 'reminders');
    });

    testWidgets('CH13: weekday ≠ date asks; the chips are the server\'s', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
            task: photoTaskJson(
              state: 'awaiting_clarification',
              clarification: {
                'id': 'c2',
                'field': 'reminder.date.0',
                'question': {
                  'vi':
                      '“Đặt lịch khám 2 tháng” ghi Thứ Hai nhưng 20/10 là Thứ Ba. Bạn muốn nhắc ngày nào?',
                  'en': 'x',
                },
                'choices': [
                  {
                    'id': 'written',
                    'label': {'vi': 'Thứ Ba 20/10', 'en': 'Tue 20/10'},
                  },
                  {
                    'id': 'weekday',
                    'label': {'vi': 'Thứ Hai 19/10', 'en': 'Mon 19/10'},
                  },
                  {
                    'id': 'later',
                    'label': {'vi': 'Chọn sau', 'en': 'Pick later'},
                  },
                ],
                'allowText': false,
              },
            ),
          ),
        },
      );
      await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      expect(find.textContaining('20/10 là Thứ Ba'), findsOneWidget);
      await _tap(tester, _text('Thứ Hai 19/10'));
      expect(
        repo.named('submitClarification').single.args['choiceId'],
        'weekday',
      );
    });

    testWidgets(
      'CH13: a reminder without a time is never pre-ticked; picking the '
      'time patches the draft',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: photoSnapshot(
              task: photoTaskJson(),
              parts: [
                draftRef(draftOf(taskA, 0)),
                draftRef(draftOf(taskA, 1)),
                textPart(
                  'Nhắc việc cần ngày và giờ: bạn chọn trước khi lưu (mình không '
                  'tự đặt giờ).',
                ),
              ],
              drafts: [
                reminderDraftJson(),
                reminderDraftJson(
                  index: 1,
                  title: 'Mua bỉm size S',
                  date: '2026-10-17',
                  time: null,
                  state: 'needs_review',
                  missing: ['time'],
                  problems: ['MISSING_TIME'],
                ),
              ],
            ),
          },
        );
        await _pump(
          tester,
          repo: repo,
          scope: householdScope,
          prefs: _thread([taskA], householdScope),
        );
        // G03: the real weekday of 20/10/2026.
        expect(_text('Nhắc: Thứ Ba 20/10 · 09:00'), findsOneWidget);
        expect(_text('Nhắc: Thứ Bảy 17/10 · chưa có giờ'), findsOneWidget);
        expect(_text('Teddy · Nhắc việc'), findsNWidgets(2));
        expect(_text('Lưu 1 mục'), findsOneWidget);
        expect(_text('Thêm giờ trước khi lưu.'), findsOneWidget);
        repo.patchAnswer = (_) => reminderDraftJson(
          index: 1,
          title: 'Mua bỉm size S',
          date: '2026-10-17',
          time: '18:00',
        );
        await _tap(tester, _text('Chọn ngày giờ'));
        expect(_text('Sửa nhắc việc'), findsOneWidget);
        // The time opens on an inline wheel (no sheet on a sheet).
        await _tap(tester, _text('chưa có giờ').last);
        expect(find.byKey(const ValueKey('as.reminderWheel')), findsOneWidget);
        await _tap(tester, _text('Cập nhật bản nháp'));
        final payload =
            repo.named('patchDraft').single.args['payload']!
                as Map<String, Object?>;
        expect(payload['time'], isNotNull);
        expect(payload['date'], '2026-10-17');
        await _tap(tester, _text('Lưu 2 mục'));
        expect(
          (repo.named('confirmDrafts').single.args['selected']! as List).length,
          2,
        );
      },
    );

    testWidgets('CH14: unreadable → 0 credits, retake or type it in', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
            task: photoTaskJson(state: 'failed', errorCode: 'OCR_UNREADABLE'),
            parts: [
              textPart(
                'Ảnh hơi mờ nên mình chưa đọc chắc được. Bạn chụp lại gần hơn, '
                'đủ sáng, hoặc nhập tay nhé.',
              ),
            ],
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(_text('Ảnh hơi mờ'), findsOneWidget);
      // D-081: no "costs no credit" footnote in the chat.
      expect(_text('Lần đọc này không trừ lượt.'), findsNothing);
      expect(_text('Có lỗi xảy ra. Chưa có gì được lưu.'), findsNothing);
      // This phone has no copy of a restored photo: "Chụp lại" opens the sheet.
      await _tap(tester, _text('Chụp lại'));
      expect(_text('Gửi ảnh để trợ lý đọc'), findsOneWidget);
    });

    testWidgets('CH14 mixed: what to do is asked; text in the photo is data', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
            task: photoTaskJson(
              state: 'awaiting_clarification',
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
            ],
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(_text('Ghi chi tiêu'), findsOneWidget);
      expect(
        _text('Chữ trong ảnh là nội dung để đọc, không phải lệnh cho app.'),
        findsOneWidget,
      );
      await _tap(tester, _text('Không làm gì'));
      expect(repo.named('submitClarification').single.args['choiceId'], 'none');
    });
  });

  group('CH15–CH18 care', () {
    Map<String, Object?> guidance({
      bool reviewed = false,
      Map<String, Object?>? care,
      List<Map<String, Object?>> drafts = const [],
    }) => snapshotWith(
      task: careTaskJson(care: care ?? sleepCare()),
      drafts: drafts,
      messages: [
        userMessage('Con hôm nay khó ngủ'),
        assistantMessage([
          guidancePart(reviewed: reviewed),
          for (final d in drafts) draftRef(d['id']! as String),
        ]),
      ],
    );

    testWidgets(
      'CH15: one short question at a time, health stays one tap away',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: careTaskJson(
                state: 'awaiting_clarification',
                clarification: sleepClarification('sleep.period'),
                care: {'topic': 'sleep_concern'},
              ),
              messages: [userMessage('Con hôm nay khó ngủ')],
            ),
          },
        );
        final (visits, _) = await _pump(
          tester,
          repo: repo,
          prefs: _thread([taskA]),
        );
        expect(_text('Khó vào giấc'), findsOneWidget);
        expect(
          _text(
            'Nếu con sốt, khó thở, li bì hoặc bỏ bú — mở Hướng dẫn sức khoẻ.',
          ),
          findsOneWidget,
        );
        // D-081: no "costs no credit" footnote in the chat.
        expect(
          _text('Câu hỏi làm rõ thuộc cùng tác vụ, không trừ thêm lượt.'),
          findsNothing,
        );
        await _tap(tester, _text('Khó vào giấc'));
        final c = repo.named('submitClarification').single.args;
        expect(c['choiceId'], 'falling_asleep');
        expect(repo.named('quoteTask'), isEmpty);
        await _tap(tester, _text('Mở Hướng dẫn sức khoẻ'));
        expect(visits.last.location, '/rhythm/health');
      },
    );

    testWidgets(
      'CH16 unreviewed: steps from the content, "chờ chuyên môn duyệt", '
      '"Thử tối nay" is an intention',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: guidance(drafts: [observationDraftJson()]),
          },
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        expect(_text('Giảm kích thích 30 phút trước giấc đêm'), findsOneWidget);
        expect(_text('Tắm ấm hoặc lau người.'), findsOneWidget);
        expect(
          _text(
            'Nội dung minh hoạ · chờ chuyên môn duyệt. Không khẳng định nguyên '
            'nhân.',
          ),
          findsOneWidget,
        );
        expect(
          _text('Vì sao: bạn chọn “khó vào giấc, giấc đêm”.'),
          findsOneWidget,
        );
        // G01: an observation draft, not a reminder; saved from its own card.
        expect(_text('Ghi nhận (tuỳ chọn)'), findsOneWidget);
        expect(_text('Teddy · Nhịp lớn lên'), findsOneWidget);
        expect(find.textContaining('Lưu 1 mục'), findsNothing);
        // No feedback before the chance to try.
        expect(_text('Có ích'), findsNothing);
        await _tap(tester, _text('Thử tối nay'));
        final plan = repo.named('planAssistantActivity').single.args;
        expect(plan['contentId'], 'act_wind_down');
        expect(plan['contentVersion'], 1);
        expect(_text('Bạn định thử tối nay'), findsOneWidget);
        expect(find.textContaining('Mình sẽ hỏi lại từ'), findsOneWidget);
        expect(_text('Có ích'), findsNothing);
        await _tap(tester, _text('Lưu ghi nhận'));
        final selected =
            (repo.named('confirmDrafts').single.args['selected']! as List)
                    .single
                as Map;
        expect(selected['draftId'], draftOf(taskA, 0));
      },
    );

    testWidgets('CH16 reviewed, "Gợi ý khác", "Không cần"', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: guidance(reviewed: true, drafts: [observationDraftJson()]),
        },
      );
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA]),
      );
      expect(
        _text(
          'Nội dung đã được chuyên môn duyệt. Không khẳng định nguyên nhân.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _text('Không cần'));
      expect(repo.named('discardDraft'), hasLength(1));
      await _tap(tester, _text('Gợi ý khác'));
      expect(visits.last.location, '/rhythm/activity/act_white_noise');
    });

    testWidgets('a relative sees the guidance but cannot plan or answer', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: guidance(care: sleepCare(plan: planJson(), followUp: true)),
        },
      );
      await _pump(
        tester,
        repo: repo,
        me: hoa,
        prefs: _thread([taskA], null, 'u_hoa'),
      );
      expect(_text('Giảm kích thích 30 phút trước giấc đêm'), findsOneWidget);
      expect(_text('Thử tối nay'), findsNothing);
      expect(_text('Có ích'), findsNothing);
    });

    testWidgets(
      'CH17: asked only once due, with "Chưa thử"; feedback is free',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: guidance(care: sleepCare(plan: planJson(), followUp: true)),
          },
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        expect(find.textContaining('Bạn có dịp thử'), findsOneWidget);
        expect(_text('Chưa thử'), findsOneWidget);
        // D-081: no "costs no credit" footnote in the chat.
        expect(_text('Phản hồi không trừ lượt hỗ trợ AI.'), findsNothing);
        await _tap(tester, _text('Có ích'));
        final fb = repo.named('submitAssistantFeedback').single.args;
        expect(fb['outcome'], 'helpful');
        expect(fb['contentId'], 'act_wind_down');
        expect(
          _text(
            'Đã ghi phản hồi. Lần sau mình sẽ ưu tiên cách này. “Có ích” không '
            'có nghĩa cách này là nguyên nhân thay đổi.',
          ),
          findsOneWidget,
        );
        expect(_text('Phản hồi hoạt động'), findsOneWidget);
        expect(_text('Có ích · 15/10'), findsOneWidget);
        // 0 credits: no quote, no task.
        expect(repo.named('quoteTask'), isEmpty);
        expect(repo.named('startTask'), isEmpty);
      },
    );

    testWidgets('CH17 "Chưa thử": nothing claimed as saved in Nhịp lớn lên', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: guidance(care: sleepCare(plan: planJson(), followUp: true)),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      await _tap(tester, _text('Chưa thử'));
      expect(
        repo.named('submitAssistantFeedback').single.args['outcome'],
        'not_tried',
      );
      expect(_text('Phản hồi hoạt động'), findsNothing);
      expect(find.textContaining('Không sao.'), findsOneWidget);
    });

    testWidgets(
      'CH17 too early (INVALID_STATE): a toast, nothing shown as saved',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: guidance(care: sleepCare(plan: planJson(), followUp: true)),
          },
          error: {
            'submitAssistantFeedback': const AssistantException(
              'failed-precondition',
              reason: AssistantReason.invalidState,
            ),
          },
        );
        await _pump(tester, repo: repo, prefs: _thread([taskA]));
        await _tap(tester, _text('Có ích'));
        expect(_text('Phản hồi hoạt động'), findsNothing);
      },
    );

    testWidgets('CH18: approved recipes, exclusions are recorded reactions, '
        '"Ghi bữa ăn" unavailable', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: careTaskJson(care: {'topic': 'meal_ideas'}),
            messages: [
              userMessage('Hôm nay con ăn gì?'),
              assistantMessage([recipesPart(excluded: 2)]),
            ],
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(_text('Cháo bí đỏ yến mạch'), findsOneWidget);
      expect(
        _text('15 phút · Từ 6 tháng · đã được chuyên môn duyệt'),
        findsOneWidget,
      );
      expect(
        _text(
          'Đã loại 2 món có nguyên liệu con từng có phản ứng (phản ứng đã ghi, '
          'không phải chẩn đoán dị ứng).',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('không có nghĩa là con đã dung nạp tốt'),
        findsOneWidget,
      );
      expect(_text('Ghi bữa ăn'), findsOneWidget);
      expect(
        _text('Chưa có nhật ký bữa ăn trong app nên chưa ghi được từ đây.'),
        findsOneWidget,
      );
      await _tap(tester, _text('Ghi bữa ăn'));
      expect(repo.named('confirmDrafts'), isEmpty);
    });

    testWidgets('CH18 empty: "chưa có công thức được duyệt", no recipe card', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: careTaskJson(care: {'topic': 'meal_ideas'}),
            messages: [
              userMessage('Hôm nay con ăn gì?'),
              assistantMessage([
                recipesPart(empty: true),
                codedText(
                  'Chưa có công thức được duyệt phù hợp với con.',
                  'RECIPES_NONE_APPROVED',
                ),
              ]),
            ],
          ),
        },
      );
      await _pump(tester, repo: repo, prefs: _thread([taskA]));
      expect(
        _text('Chưa có công thức được duyệt phù hợp với con.'),
        findsOneWidget,
      );
      expect(_text('Gợi ý từ Thư viện công thức'), findsNothing);
      expect(_text('Ghi bữa ăn'), findsNothing);
    });

    testWidgets('no approved guidance → the care library, honestly', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: careTaskJson(care: {'topic': 'sleep_concern'}),
            messages: [
              userMessage('Con hôm nay khó ngủ'),
              assistantMessage([
                codedText(
                  'Chưa có gợi ý đã duyệt phù hợp với con lúc này. Bạn có thể '
                      'xem Thư viện chăm bé.',
                  'CARE_NO_APPROVED_CONTENT',
                ),
              ]),
            ],
          ),
        },
      );
      final (visits, _) = await _pump(
        tester,
        repo: repo,
        prefs: _thread([taskA]),
      );
      await _tap(tester, _text('Mở Thư viện chăm bé'));
      expect(visits.last.location, '/rhythm');
    });

    testWidgets(
      'health from care: free, the region\'s number from the server',
      (tester) async {
        final dialled = <String>[];
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: careTaskJson(),
              messages: [
                userMessage('Con khó ngủ, thở nhanh'),
                assistantMessage([
                  {
                    'type': 'health_support',
                    'schemaVersion': 1,
                    'signs': ['breathing'],
                    'emergency': {'country': 'VN', 'number': '115'},
                  },
                ]),
              ],
            ),
          },
        );
        await pumpRouted(
          tester,
          AssistantChatScreen(scopeKey: teddyScope.key),
          prefs: _thread([taskA]),
          overrides: assistantOverrides(repo: repo, dialled: dialled),
        );
        await tester.pumpAndSettle();
        expect(_text('Gọi 115'), findsOneWidget);
        // D-081: no "costs no credit" note on the health card.
        expect(_text('Không trừ lượt'), findsNothing);
        await _tap(tester, _text('Gọi 115'));
        expect(dialled, ['115']);
        expect(repo.named('quoteTask'), isEmpty);
      },
    );
  });

  group('D-075 #2 shared thread', () {
    testWidgets('another member\'s message and draft: labelled, saveable, her '
        'question only she answers', (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: sharedTaskJson(by: lan),
            drafts: [bottleDraftJson()],
            messages: [
              sharedUserMessage('8 giờ con bú bình 120 ml', lan),
              assistantMessage([draftRef(draftOf(taskA, 0))]),
            ],
          ),
          taskB: snapshotWith(
            task: sharedTaskJson(
              by: lan,
              id: taskB,
              state: 'awaiting_clarification',
              clarification: clarificationJson(),
            ),
            messages: [
              sharedUserMessage(
                'Con ngủ từ 10 giờ tới 9 giờ',
                lan,
                taskId: taskB,
                sequence: 3,
              ),
            ],
          ),
        },
        messagesAnswer: () => [
          sharedUserMessage('8 giờ con bú bình 120 ml', lan),
          sharedUserMessage(
            'Con ngủ từ 10 giờ tới 9 giờ',
            lan,
            taskId: taskB,
            sequence: 3,
          ),
        ],
      );
      await _pump(tester, repo: repo);
      // The shared thread is read even though this phone never sent anything.
      expect(
        repo.named('listAssistantHistory').single.args['conversationId'],
        sharedConversation,
      );
      expect(_text('Cô Lan'), findsNWidgets(2));
      expect(_text('8 giờ con bú bình 120 ml'), findsOneWidget);
      expect(_text('Chờ Cô Lan trả lời câu hỏi này.'), findsOneWidget);
      expect(_text('9:00 – 10:00'), findsNothing);
      // Lumi 2026-10-16: a single draft saves from its own card (no batch bar).
      await _tap(tester, _text('Lưu cữ bú bình'));
      expect(repo.named('confirmDrafts').single.args['taskId'], taskA);
    });

    testWidgets(
      'a caregiver sees Mẹ\'s guidance without the author-only actions',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: snapshotWith(
              task: sharedTaskJson(
                by: mai,
                care: sleepCare(plan: planJson(), followUp: true),
              ),
              messages: [
                sharedUserMessage('Con hôm nay khó ngủ', mai),
                assistantMessage([guidancePart()]),
              ],
            ),
            taskB: snapshotWith(
              task: sharedTaskJson(by: mai, id: taskB, state: 'processing'),
              messages: [
                sharedUserMessage(
                  'Hôm nay con bú thế nào?',
                  mai,
                  taskId: taskB,
                ),
              ],
            ),
          },
          messagesAnswer: () => [
            sharedUserMessage('Con hôm nay khó ngủ', mai),
            sharedUserMessage('Hôm nay con bú thế nào?', mai, taskId: taskB),
          ],
        );
        await _pump(tester, repo: repo, me: lan);
        expect(_text('Mẹ'), findsNWidgets(2));
        expect(_text('Giảm kích thích 30 phút trước giấc đêm'), findsOneWidget);
        expect(_text('Thử tối nay'), findsNothing);
        expect(_text('Có ích'), findsNothing);
        expect(_text('Lumi đang soạn…'), findsOneWidget);
        expect(find.bySemanticsLabel('Huỷ'), findsNothing);
      },
    );

    testWidgets(
      'a shared task lands in cv_<baby>; a photo after it stays private',
      (tester) async {
        final repo = FakeAssistantRepository(
          startAnswer: (args) =>
              args['attachmentIds'] is List &&
                  (args['attachmentIds']! as List).isNotEmpty
              ? envelope(_processing())
              : envelope({
                  'task': sharedTaskJson(by: mai, state: 'processing'),
                }),
        );
        final (_, container) = await _pump(tester, repo: repo);
        await tester.enterText(find.byType(TextField).last, 'Con bú 120 ml');
        await tester.pump();
        await _tap(tester, find.bySemanticsLabel('Gửi').last);
        expect(
          container.read(assistantChatProvider(teddyScope.key)).conversationId,
          sharedConversation,
        );
        await _choose(tester);
        await _tap(tester, _text('Gửi ảnh'));
        final quotes = repo.named('quoteTask');
        expect(quotes.last.args['conversationId'], isNull);
        expect(repo.named('startTask').last.args['conversationId'], isNull);
        expect(
          _text(
            'Chỉ bạn thấy: ảnh và chi tiêu không vào cuộc trò chuyện chung của bé.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('history: shared thread first; a caregiver cannot delete it', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        conversationsAnswer: () => [
          sharedConversationJson(),
          {
            'id': conversation1,
            'ownerUid': 'u_lan',
            'scope': {'type': 'child', 'babyId': teddyId},
            'title': 'Cữ bú sáng nay',
            'updatedAt': '2026-10-15T06:00:00.000Z',
          },
        ],
      );
      await pumpRouted(
        tester,
        AssistantHistoryScreen(scopeKey: teddyScope.key),
        overrides: assistantOverrides(repo: repo, me: lan),
      );
      await tester.pumpAndSettle();
      expect(_text('CUỘC TRÒ CHUYỆN CHUNG'), findsOneWidget);
      expect(_text('Trò chuyện chung về bé'), findsOneWidget);
      expect(_text('Cữ bú sáng nay'), findsOneWidget);
      // Only the private one has "Xoá".
      expect(find.bySemanticsLabel('Xoá cuộc trò chuyện'), findsOneWidget);
    });

    testWidgets(
      'history: a Cùng nuôi deletes the shared thread; records stay',
      (tester) async {
        final repo = FakeAssistantRepository(
          conversationsAnswer: () => [sharedConversationJson()],
        );
        await pumpRouted(
          tester,
          AssistantHistoryScreen(scopeKey: teddyScope.key),
          overrides: assistantOverrides(repo: repo),
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.bySemanticsLabel('Xoá cuộc trò chuyện'));
        expect(_text('Xoá cuộc trò chuyện chung?'), findsOneWidget);
        await _tap(tester, _text('Xoá'));
        expect(
          repo
              .named('deleteAssistantConversation')
              .single
              .args['conversationId'],
          sharedConversation,
        );
        expect(
          _text('Đã xoá cuộc trò chuyện. Bản ghi đã lưu vẫn giữ nguyên.'),
          findsOneWidget,
        );
      },
    );
  });

  group('D-075 #5 reminder drafts: all day and assignee', () {
    Map<String, Object?> notes(List<Map<String, Object?>> drafts) =>
        photoSnapshot(
          task: photoTaskJson(),
          parts: [for (final d in drafts) draftRef(d['id']! as String)],
          drafts: drafts,
        );

    testWidgets('"Cả ngày" without a time; the assignee by member label', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: notes([
            reminderDraftJson(assignee: 'u_minh'),
            reminderDraftJson(
              index: 1,
              title: 'Mua bỉm size S',
              date: '2026-10-17',
              time: null,
              problems: ['INVALID_ASSIGNEE', 'SOMETHING_NEW'],
            ),
          ]),
        },
      );
      await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      expect(_text('Nhắc: Thứ Ba 20/10 · 09:00 · Giao cho Ba'), findsOneWidget);
      expect(_text('Nhắc: Thứ Bảy 17/10 · Cả ngày'), findsOneWidget);
      // A new problem code is tolerated; INVALID_ASSIGNEE explained.
      expect(
        _text(
          'Người được giao không còn trong gia đình. Chọn lại người phụ trách.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'edit: "Giao cho" lists active Cùng nuôi / Người chăm sóc only',
      (tester) async {
        final repo = FakeAssistantRepository(
          tasks: {
            taskA: notes([reminderDraftJson(time: null)]),
          },
          patchAnswer: (args) =>
              reminderDraftJson(time: null, assignee: 'u_lan'),
        );
        await _pump(
          tester,
          repo: repo,
          scope: householdScope,
          prefs: _thread([taskA], householdScope),
        );
        await _tap(tester, _text('Sửa'));
        expect(_text('Giao cho'), findsOneWidget);
        expect(_text('Không giao ai'), findsOneWidget);
        expect(_text('Cô Lan'), findsOneWidget);
        // A relative is never offered.
        expect(_text('Bà nội Hoa'), findsNothing);
        await _tap(tester, _text('Cô Lan'));
        await _tap(tester, _text('Cập nhật bản nháp'));
        final payload =
            repo.named('patchDraft').single.args['payload']!
                as Map<String, Object?>;
        expect(payload['assigneeUid'], 'u_lan');
        expect(payload['time'], isNull);
      },
    );

    testWidgets('"Giao việc này cho ai?": the server\'s choices', (
      tester,
    ) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: photoSnapshot(
            task: photoTaskJson(
              state: 'awaiting_clarification',
              clarification: {
                'id': 'c4',
                'field': 'reminder.assignee.0',
                'question': {
                  'vi':
                      'Ảnh ghi “Mẹ” cạnh “Đặt lịch khám”. Giao việc này cho ai?',
                  'en': 'x',
                },
                'choices': [
                  {
                    'id': 'u_mai',
                    'label': {'vi': 'Bạn (Mai)', 'en': 'You (Mai)'},
                  },
                  {
                    'id': 'none',
                    'label': {'vi': 'Không giao', 'en': 'No one'},
                  },
                ],
                'allowText': false,
              },
            ),
          ),
        },
      );
      await _pump(
        tester,
        repo: repo,
        scope: householdScope,
        prefs: _thread([taskA], householdScope),
      );
      await _tap(tester, _text('Bạn (Mai)'));
      expect(
        repo.named('submitClarification').single.args['choiceId'],
        'u_mai',
      );
    });
  });

  test('kept input JSON stays readable (A4 compatibility)', () {
    final k = KeptInput.fromJson(
      jsonDecode(
        jsonEncode(
          KeptInput(
            text: 't',
            requestId: 'r',
            inputKey: '',
            reason: KeptReason.photo,
            at: assistantNow,
          ).toJson(),
        ),
      ),
    );
    expect(k?.reason, KeptReason.photo);
  });

  test('retention default follows D-075 #3', () {
    expect(retentionFor(keep: true), AttachmentRetention.keepWithRecord);
    expect(retentionFor(keep: false), AttachmentRetention.deleteAfterRead);
  });
}
