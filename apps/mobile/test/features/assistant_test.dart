import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/assistant/assistant_labels.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_repository.dart';
import 'package:child_life/features/assistant/assistant_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/assistant_fixtures.dart';
import '../helpers/family_fixtures.dart' show teddyId;

/// Slice A4 pure parts: DTO parsing (tolerant, versioned parts, unknown → UnsupportedPart), the
/// Dart ports of the contracts' pure functions against the same simulation pack as
/// packages/contracts/test/assistant.test.ts, the credit display math, the event cursor and the
/// merges that keep reconnects from undoing newer state.

const _pack = '../../packages/contracts/test/vectors/assistant-v3';
Object? _vector(String name) =>
    jsonDecode(File('$_pack/$name').readAsStringSync());

final _context = _vector('context.json')! as Map<String, Object?>;
final _outputs = _vector('provider_outputs.json')! as Map<String, Object?>;
final _logs = (_vector('logs.json')! as List).cast<Map<String, Object?>>();
final _anchor = DateTime.parse(_context['now']! as String);

BottlePayload _bottle(num? ml, [String at = '2026-10-15T01:00:00Z']) =>
    BottlePayload(amountMl: ml, occurredAt: DateTime.parse(at));
SleepPayload _sleep(String s, String e) =>
    SleepPayload(startedAt: DateTime.parse(s), endedAt: DateTime.parse(e));

AssistantDraft _draft({
  DraftState state = DraftState.draft,
  int revision = 2,
  String expiresAt = '2026-10-16T07:20:00Z',
  List<String> uncertain = const [],
}) => AssistantDraft(
  id: 'dr_1',
  taskId: 'tk_1',
  itemIndex: 0,
  scope: teddyScope,
  payload: _bottle(120),
  revision: revision,
  state: state,
  expiresAt: DateTime.parse(expiresAt),
  uncertainFields: uncertain,
);

AssistantEvent _event(int seq, String id, [String type = 'progress']) =>
    AssistantEvent(eventId: id, sequence: seq, typeWire: type);

void main() {
  group('DTO parsing', () {
    test('a snapshot with the CH04 drafts, in item order', () {
      final s = TaskSnapshot.fromJson(batchSnapshot())!;
      expect(s.task.state, TaskState.ready);
      expect(s.task.timezone, 'Asia/Ho_Chi_Minh');
      expect(s.drafts.map((d) => d.kind), [DraftKind.bottle, DraftKind.sleep]);
      final bottle = s.drafts.first.payload as BottlePayload;
      expect(bottle.amountMl, 120);
      expect(bottle.occurredAt, DateTime.utc(2026, 10, 15, 1));
      expect(s.messages.first.text, contains('120 ml'));
      expect(s.events.map((e) => e.sequence), [1, 2]);
    });

    test('an unknown part type or a newer schema is a safe placeholder', () {
      final m = AssistantMessage.fromJson(
        assistantMessage([
          {'type': 'run_javascript', 'schemaVersion': 1, 'code': 'x'},
          {'type': 'text', 'schemaVersion': 2, 'text': 'v2'},
          {'type': 'text', 'schemaVersion': 1},
          textPart('ok'),
        ]),
      )!;
      expect(m.parts[0], isA<UnsupportedPart>());
      expect((m.parts[0] as UnsupportedPart).type, 'run_javascript');
      expect(m.parts[1], isA<UnsupportedPart>());
      // A known part missing its fields is not trusted either.
      expect(m.parts[2], isA<UnsupportedPart>());
      expect((m.parts[3] as TextPart).text, 'ok');
    });

    test('every allowlisted part parses', () {
      final parts = [
        for (final p in [
          textPart('a'),
          {
            'type': 'clarification',
            'schemaVersion': 1,
            'clarification': clarificationJson(),
          },
          draftRef('dr_x', 2),
          summaryPart(),
          {
            'type': 'approved_content',
            'schemaVersion': 1,
            'contentId': 'act_1',
            'contentVersion': 3,
            'reason': 'r',
            'reviewed': true,
          },
          {
            'type': 'recipe_list',
            'schemaVersion': 1,
            'recipeIds': ['test_recipe_1'],
            'caveat': null,
          },
          {
            'type': 'usage_notice',
            'schemaVersion': 1,
            'reason': 'NEAR_LIMIT',
            'remaining': 2,
          },
          {'type': 'action_result', 'schemaVersion': 1, 'items': <Object>[]},
          {
            'type': 'health_support',
            'schemaVersion': 1,
            'signs': ['breathing'],
          },
        ])
          AssistantPart.fromJson(p),
      ];
      expect(parts.whereType<UnsupportedPart>(), isEmpty);
      final summary = (parts[3] as SourceSummaryPart).summary;
      expect(summary.bottle, const CountAmount(3, 390));
      // Nursing stays in minutes, never ml.
      expect(summary.breast, const CountAmount(2, 35));
      expect(summary.coverage, SummaryCoverage.unknown);
      expect((parts[6] as UsageNoticePart).reason, isNull);
      expect((parts[8] as HealthSupportPart).signs, ['breathing']);
      final c = (parts[1] as ClarificationPart).clarification;
      expect(c.choices.map((x) => x.id), ['a', 'b']);
      expect(c.question.of('en'), startsWith('The sleep'));
    });

    test('an unknown draft kind is kept but never editable', () {
      final d = AssistantDraft.fromJson({
        ...bottleDraftJson(),
        'payload': {'kind': 'task', 'title': 'x'},
      })!;
      expect(d.payload, isA<UnknownPayload>());
      expect(d.kind, isNull);
      // Its own problems list is empty, so only the app's refusal keeps it unsaved.
      expect(draftProblems(d.payload, _anchor), isEmpty);
    });

    test('a bad item drops itself, not the answer', () {
      final r = ConfirmResult.fromJson({
        'items': [
          {'draftId': 'dr_1', 'status': 'saved', 'revision': 1},
          {'draftId': 'dr_2', 'status': 'exploded'},
          'nonsense',
        ],
        'partial': false,
      });
      expect(r.items.map((i) => i.draftId), ['dr_1']);
      expect(r.partial, isFalse);
    });

    test(
      'envelope: blocked / partial are answers; a bare answer is ok data',
      () {
        final e = AssistantEnvelope.fromJson(
          envelope(null, status: 'blocked', reason: 'USAGE_EXHAUSTED'),
        );
        expect(e.status, ResponseStatus.blocked);
        expect(e.reason, AssistantReason.usageExhausted);
        final bare = AssistantEnvelope.fromJson({'quoteId': 'q'});
        expect(bare.status, ResponseStatus.ok);
        expect((bare.data! as Map)['quoteId'], 'q');
      },
    );

    test('usage: remaining from the server, clamped; unknown plan → none', () {
      final u = AssistantUsage.fromJson(usageJson(used: 25, remaining: -5))!;
      expect(u.remaining, 0);
      expect(AssistantUsage.fromJson({'limit': 20, 'plan': 'gold'}), isNull);
      // Wrapped in `{usage: …}` (a quote).
      expect(AssistantUsage.fromJson({'usage': usageJson()})!.limit, 20);
    });

    test('the task document form (pendingClarification) reads like the view', () {
      // What the server stores: the open question in `pendingClarification`, the rounds in
      // `clarifications[]` without their question (L1b, P-168 #4).
      final t = AssistantTask.fromJson({
        ...taskJson(state: 'awaiting_clarification'),
        'clarification': null,
        'pendingClarification': clarificationJson(),
        'clarifications': [
          {'id': 'c1', 'field': 'sleep.period', 'round': 0, 'answer': null},
        ],
      })!;
      expect(t.clarification?.id, 'c1');
      expect(t.clarification?.choices, hasLength(2));
    });

    test('the same version without the question never replaces it', () {
      final asked = AssistantTask.fromJson(
        taskJson(
          state: 'awaiting_clarification',
          clarification: clarificationJson(),
        ),
      )!;
      final bare = AssistantTask.fromJson({
        ...taskJson(state: 'awaiting_clarification'),
        'clarification': null,
        'clarifications': [
          {'id': 'c1', 'field': 'sleep.period', 'round': 0, 'answer': null},
        ],
      })!;
      expect(mergeTask(asked, bare), same(asked));
      // A newer version (the answer went) does replace it.
      final answered = AssistantTask.fromJson(
        taskJson(state: 'processing', version: 4),
      )!;
      expect(mergeTask(asked, answered), same(answered));
    });

    test('scope keys round-trip and reject junk', () {
      expect(AssistantScope.fromKey(teddyScope.key), teddyScope);
      expect(AssistantScope.fromKey(householdScope.key), householdScope);
      expect(AssistantScope.fromKey('pet:1'), isNull);
      expect(AssistantScope.fromKey('child:'), isNull);
      expect(AssistantScope.fromKey(null), isNull);
    });

    test('consent counts only for the current version', () {
      expect(
        AssistantConsent.fromDoc({
          'assistant': {'version': assistantConsentVersion},
        }).granted,
        isTrue,
      );
      expect(
        AssistantConsent.fromDoc({
          'assistant': {'version': 'assistant-consent-v0'},
        }).granted,
        isFalse,
      );
      // The summaries consent is a different one (P-160).
      expect(
        AssistantConsent.fromDoc({
          'consent': {'version': 'ai-consent-v1'},
        }).granted,
        isFalse,
      );
    });
  });

  group('pack · drafts (D06, D07, I02, I04, I07)', () {
    test('text batch maps to valid bottle + sleep drafts', () {
      final items = ((_outputs['text_batch']! as Map)['items']! as List)
          .cast<Map<String, Object?>>();
      final b = items[0], s = items[1];
      expect(
        draftProblems(_bottle(b['ml']! as num, b['at']! as String), _anchor),
        isEmpty,
      );
      expect(
        draftProblems(
          _sleep(s['start']! as String, s['end']! as String),
          _anchor,
        ),
        isEmpty,
      );
    });

    test('D06 non-positive / over-limit amounts, D07 sleep ending first', () {
      expect(draftProblems(_bottle(-1), _anchor), [DraftProblem.invalidAmount]);
      expect(draftProblems(_bottle(501), _anchor), [
        DraftProblem.invalidAmount,
      ]);
      expect(draftProblems(_bottle(null), _anchor), [
        DraftProblem.missingAmount,
      ]);
      expect(
        draftProblems(
          _sleep('2026-10-15T02:00:00Z', '2026-10-15T01:00:00Z'),
          _anchor,
        ),
        [DraftProblem.invalidTime],
      );
    });

    test('a completed log after the send time is refused', () {
      expect(draftProblems(_bottle(120, '2026-10-15T09:00:00Z'), _anchor), [
        DraftProblem.futureTime,
      ]);
      expect(
        draftProblems(
          _sleep('2026-10-15T03:00:00Z', '2026-10-15T08:00:00Z'),
          _anchor,
        ),
        [DraftProblem.futureTime],
      );
      expect(draftProblems(const BreastPayload(durationMin: 15), _anchor), [
        DraftProblem.missingTime,
      ]);
    });

    test('I02 receipt: the uncertain date blocks; total includes tax', () {
      final r = ((_outputs['receipt']! as Map)['items']! as List).first as Map;
      final draft = ExpensePayload(
        merchant: r['merchant'] as String,
        totalMinor: r['amount'] as int,
        currency: r['currency'] as String,
        subtotalMinor: r['subtotal'] as int,
        taxMinor: r['tax'] as int,
      );
      expect(draftProblems(draft, _anchor), [DraftProblem.missingDate]);
      expect(
        confirmBlocker(
          _draft(
            state: DraftState.needsReview,
            revision: 1,
            uncertain: ['date'],
          ),
          1,
          _anchor,
        ),
        AssistantReason.reviewRequired,
      );
      expect(draft.totalMinor, draft.subtotalMinor! + draft.taxMinor!);
    });

    test('I04 an unknown currency is not accepted', () {
      expect(
        draftProblems(
          const ExpensePayload(
            totalMinor: 486000,
            currency: 'XYZ',
            date: '2026-10-14',
          ),
          _anchor,
        ),
        [DraftProblem.currencyUnsupported],
      );
    });

    test('I07 note reminders without a date cannot be saved', () {
      for (final r in ((_outputs['note']! as Map)['items']! as List)) {
        expect(
          draftProblems(
            ReminderPayload(title: (r as Map)['title']! as String),
            _anchor,
          ),
          [DraftProblem.missingDate],
        );
      }
    });

    test('D04 / D05: stale, expired, saved, ready', () {
      final d = _draft();
      expect(confirmBlocker(d, 1, _anchor), AssistantReason.draftStale);
      expect(
        confirmBlocker(d, 2, DateTime.parse('2026-10-16T07:20:00Z')),
        AssistantReason.draftExpired,
      );
      expect(
        confirmBlocker(_draft(state: DraftState.saved), 2, _anchor),
        AssistantReason.draftSaved,
      );
      expect(
        confirmBlocker(_draft(state: DraftState.discarded), 2, _anchor),
        AssistantReason.invalidState,
      );
      expect(confirmBlocker(d, 2, _anchor), isNull);
    });
  });

  group('pack · reads and usage (R01, U02)', () {
    test('R01 bottle ml and nursing minutes apart, with their sources', () {
      final r = careSummary(
        [
          for (final l in _logs)
            (
              id: l['id']! as String,
              kind: l['kind']! as String,
              ml: l['ml'] as num?,
              minutes: l['minutes'] as num?,
            ),
        ],
        '2026-10-15',
        _anchor,
      );
      expect(r.summary.bottle, const CountAmount(3, 390));
      expect(r.summary.breast, const CountAmount(2, 35));
      expect(r.sourceIds, hasLength(5));
      expect(r.summary.coverage, SummaryCoverage.unknown);
      // The pack's provider "summary" agrees with the engine.
      final s = _outputs['summary']! as Map;
      expect(r.summary.bottle.amount, s['bottleMl']);
      expect(r.summary.breast.amount, s['nursingMinutes']);
      expect(r.sourceIds, s['sources']);
    });

    test('credits: text 1, a photo task 3 (QA values from the pack)', () {
      final q = _context['quotaExamples']! as Map;
      final u = AssistantUsage.fromJson(usageJson())!;
      expect(creditsFor(TaskModality.text, u), q['text']);
      expect(creditsFor(TaskModality.image, u), q['image']);
      expect(u.limit, q['free']);
    });

    test(
      'U02 the same request id with a different input is a different key',
      () {
        String key(String text) => taskInputKey(
          conversationId: 'c',
          scope: const AssistantScope.child('test_teddy'),
          modality: TaskModality.text,
          text: text,
        );
        expect(key('x'), key(' x '));
        expect(key('x'), isNot(key('y')));
      },
    );
  });

  group('credit display math (Chat/Mức dùng)', () {
    UsageView view(int remaining, {String plan = 'free', int limit = 20}) =>
        UsageView.of(
          AssistantUsage.fromJson(
            usageJson(
              plan: plan,
              limit: limit,
              used: limit - remaining,
              remaining: remaining,
            ),
          )!,
        );

    test('Còn / Gần hết / Hết from the server snapshot', () {
      expect(view(18).level, UsageLevel.ok);
      expect(view(2).level, UsageLevel.near); // CH20: less than a photo
      expect(view(0).level, UsageLevel.out); // CH21
      expect(view(15, plan: 'premium', limit: 200).level, UsageLevel.near);
      expect(view(200, plan: 'premium', limit: 200).level, UsageLevel.ok);
      expect(view(0, plan: 'premium', limit: 200).level, UsageLevel.out);
    });

    test('fraction and affordability', () {
      expect(view(15).fraction, 0.75);
      expect(view(2).affords(3), isFalse);
      expect(view(2).affords(1), isTrue);
      final zero = UsageView.of(
        AssistantUsage.fromJson(usageJson(limit: 0, used: 0, remaining: 0))!,
      );
      expect(zero.fraction, 0);
      expect(zero.level, UsageLevel.out);
    });
  });

  group('reconnect: events and merges', () {
    test('duplicate and old events are ignored, new ones kept in order', () {
      final c = EventCursor();
      expect(c.accept([_event(2, 'b'), _event(1, 'a')]).map((e) => e.eventId), [
        'a',
        'b',
      ]);
      expect(c.accept([_event(1, 'a'), _event(2, 'b')]), isEmpty);
      // A replayed id with a new sequence, and an older sequence, are both dropped.
      expect(c.accept([_event(3, 'b'), _event(0, 'z')]), isEmpty);
      expect(c.accept([_event(4, 'c')]).single.eventId, 'c');
      expect(c.lastSequence, 4);
    });

    test('an older task version never replaces a newer one', () {
      final newer = AssistantTask.fromJson(taskJson(version: 5))!;
      final older = AssistantTask.fromJson(
        taskJson(version: 3, state: 'processing'),
      )!;
      expect(mergeTask(newer, older), same(newer));
      expect(mergeTask(older, newer), same(newer));
    });

    test('a draft never goes back within a revision', () {
      final saved = AssistantDraft.fromJson(
        bottleDraftJson(state: 'saved', revision: 2),
      )!;
      final lateDraft = AssistantDraft.fromJson(bottleDraftJson(revision: 2))!;
      final older = AssistantDraft.fromJson(bottleDraftJson(revision: 1))!;
      final failed = AssistantDraft.fromJson(
        bottleDraftJson(state: 'failed', revision: 2),
      )!;
      final edited = AssistantDraft.fromJson(bottleDraftJson(revision: 3))!;
      expect(mergeDraft(saved, lateDraft), same(saved));
      expect(mergeDraft(saved, older), same(saved));
      expect(mergeDraft(failed, lateDraft), same(failed));
      expect(mergeDraft(failed, saved), same(saved));
      expect(mergeDraft(failed, edited), same(edited));
    });

    test('confirm results apply per item: never a fake "all saved"', () {
      final drafts = TaskSnapshot.fromJson(batchSnapshot())!.drafts;
      final out = applyConfirm(drafts, [
        ConfirmItemResult(
          draftId: drafts[0].id,
          status: ConfirmStatus.saved,
          revision: 1,
          recordId: 'r_1',
        ),
        ConfirmItemResult(
          draftId: drafts[1].id,
          status: ConfirmStatus.conflict,
          revision: 1,
        ),
      ]);
      expect(out[0].state, DraftState.saved);
      expect(out[0].recordId, 'r_1');
      expect(out[1].state, DraftState.failed);
      expect(out[1].error, AssistantReason.domainConflict);
      // A conflict is resolved by the person, not by a retry.
      expect(retryable(out[1]), isFalse);
      expect(canSaveAnyway(out[1]), isTrue);
      expect(retryable(out[1].copyWith(errorCode: 'AI_UNAVAILABLE')), isTrue);
    });
  });

  group('record links (allowlisted in-app routes only)', () {
    AssistantDraft saved(String? link, {String kind = 'bottle'}) =>
        AssistantDraft.fromJson({
          ...bottleDraftJson(state: 'saved', recordId: 'r_9'),
          'recordLink': link,
          if (kind == 'expense')
            'payload': {'kind': 'expense', 'keepReceipt': false},
        })!;

    test("the server adapter's links map to the app's routes", () {
      expect(
        recordLocation(saved('/care/records/$teddyId/r_9')),
        '/care/record/r_9',
      );
      expect(
        recordLocation(saved('/rhythm/checkins/$teddyId/ci_1')),
        '/rhythm',
      );
      expect(recordLocation(saved('/care/record/r_9')), '/care/record/r_9');
    });

    test('anything else falls back to the module, never followed', () {
      for (final link in [
        'https://example.com/x',
        '//evil.example/care/record/r_9',
        '/me/account',
        'javascript:alert(1)',
        '/care/record/../me',
      ]) {
        expect(recordLocation(saved(link)), '/care/record/r_9', reason: link);
      }
      expect(
        recordLocation(saved(null, kind: 'expense')),
        startsWith('/utilities/spending'),
      );
    });
  });

  group('kept input on the phone', () {
    test('kept, read back and cleared per scope', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AssistantLocalStore(await SharedPreferences.getInstance());
      final kept = KeptInput(
        text: 'Hôm nay con bú thế nào?',
        requestId: 'r1',
        inputKey: 'k',
        reason: KeptReason.offline,
        at: assistantNow,
      );
      store.keep(teddyScope.key, kept);
      await Future<void>.delayed(Duration.zero);
      expect(store.kept(teddyScope.key)?.text, kept.text);
      expect(store.kept(householdScope.key), isNull);
      store.setConversation(teddyScope.key, conversation1, [taskA]);
      await Future<void>.delayed(Duration.zero);
      expect(store.conversation(teddyScope.key), conversation1);
      expect(store.taskIds(teddyScope.key), [taskA]);
      store.keep(teddyScope.key, null);
      await Future<void>.delayed(Duration.zero);
      expect(store.kept(teddyScope.key), isNull);
      await store.clearAll();
      expect(store.conversation(teddyScope.key), isNull);
    });
  });
}
