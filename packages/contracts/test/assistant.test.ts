import { describe, expect, it } from 'vitest';
import {
  careSummary,
  confirmBlocker,
  creditsFor,
  draftPayloadSchema,
  draftProblems,
  eligibleRecipes,
  noteActions,
  taskInputKey,
  taskStateForOutcome,
  usageForOutcome,
  weekdayMatches,
  type DraftPayload,
  type TaskOutcome,
} from '../src/index.js';
import context from './vectors/assistant-v3/context.json' with { type: 'json' };
import logs from './vectors/assistant-v3/logs.json' with { type: 'json' };
import outputs from './vectors/assistant-v3/provider_outputs.json' with { type: 'json' };
import recipes from './vectors/assistant-v3/recipes.json' with { type: 'json' };

/**
 * Assistant v3 simulation pack (synthetic, `TEST_ONLY_NOT_COMMERCIAL`): the stateless contracts
 * ported to the real functions. Stateful cases (tasks, drafts, ledger, roles) run against Firestore
 * in firebase/tests/assistant.*.test.ts. Clock 2026-10-15T07:20Z, Asia/Ho_Chi_Minh.
 */
const anchor = new Date(context.now);

/** The pack's provider outputs as typed drafts (field names mapped to the contract). */
const bottle = (ml: number | null, at = '2026-10-15T01:00:00Z'): DraftPayload => ({
  kind: 'bottle',
  amountMl: ml,
  occurredAt: at,
  milk: null,
});
const sleep = (start: string, end: string): DraftPayload => ({
  kind: 'sleep',
  startedAt: start,
  endedAt: end,
});

describe('pack · drafts (D06, D07, I02, I04, I07)', () => {
  it('text batch maps to valid bottle + sleep drafts', () => {
    const [b, s] = outputs.text_batch.items;
    expect(draftProblems(bottle(b!.ml!, b!.at!), anchor)).toEqual([]);
    expect(draftProblems(sleep(s!.start!, s!.end!), anchor)).toEqual([]);
  });
  it('D06 a non-positive amount is refused; D07 sleep ending before it starts is refused', () => {
    expect(draftProblems(bottle(-1), anchor)).toEqual(['INVALID_AMOUNT']);
    expect(draftProblems(sleep('2026-10-15T02:00:00Z', '2026-10-15T01:00:00Z'), anchor)).toEqual([
      'INVALID_TIME',
    ]);
  });
  it('a completed log after the send time is refused; sleep is never flipped or moved overnight', () => {
    expect(draftProblems(bottle(120, '2026-10-15T09:00:00Z'), anchor)).toEqual(['FUTURE_TIME']);
    expect(draftProblems(sleep('2026-10-15T03:00:00Z', '2026-10-15T02:00:00Z'), anchor)).toContain(
      'INVALID_TIME',
    );
  });
  it('I02 receipt: the uncertain date blocks saving until confirmed; total already includes tax', () => {
    const r = outputs.receipt.items[0]!;
    const draft: DraftPayload = {
      kind: 'expense',
      merchant: r.merchant!,
      totalMinor: r.amount!,
      currency: r.currency!,
      date: null,
      subtotalMinor: r.subtotal!,
      taxMinor: r.tax!,
      categoryId: null,
      babyId: null,
      keepReceipt: false,
    };
    expect(draftProblems(draft, anchor)).toEqual(['MISSING_DATE']);
    expect(
      confirmBlocker(
        {
          state: 'needs_review',
          revision: 1,
          expiresAt: '2026-10-16T07:20:00Z',
          uncertainFields: ['date'],
          missingFields: [],
        },
        1,
        anchor,
      ),
    ).toBe('REVIEW_REQUIRED');
    const fixed = { ...draft, date: '2026-10-14' };
    expect(draftProblems(fixed, anchor)).toEqual([]);
    expect(fixed.totalMinor).toBe(fixed.subtotalMinor! + fixed.taxMinor!);
  });
  it('I04 an unknown currency symbol is not accepted', () => {
    expect(draftPayloadSchema.safeParse({ kind: 'expense', currency: '$' }).success).toBe(false);
    const d: DraftPayload = {
      kind: 'expense',
      merchant: null,
      totalMinor: 486000,
      currency: 'XYZ',
      date: '2026-10-14',
      subtotalMinor: null,
      taxMinor: null,
      categoryId: null,
      babyId: null,
      keepReceipt: false,
    };
    expect(draftProblems(d, anchor)).toEqual(['CURRENCY_UNSUPPORTED']);
  });
  it('I07 note reminders without a date cannot be saved', () => {
    for (const r of outputs.note.items) {
      expect(
        draftProblems(
          { kind: 'reminder', title: r.title!, date: null, time: null, assigneeUid: null },
          anchor,
        ),
      ).toEqual(['MISSING_DATE']);
    }
  });
  it('D04 / D05 a stale revision or an expired draft is refused; a saved draft is never re-saved', () => {
    const d = {
      state: 'draft' as const,
      revision: 2,
      expiresAt: '2026-10-16T07:20:00Z',
      uncertainFields: [],
      missingFields: [],
    };
    expect(confirmBlocker(d, 1, anchor)).toBe('DRAFT_STALE');
    expect(confirmBlocker(d, 2, new Date('2026-10-16T07:20:00Z'))).toBe('DRAFT_EXPIRED');
    expect(confirmBlocker({ ...d, state: 'saved' }, 2, anchor)).toBe('DRAFT_SAVED');
    expect(confirmBlocker(d, 2, anchor)).toBeNull();
  });
});

describe('pack · usage per outcome (U04, U05, U10, I01, E01)', () => {
  const asOutcome = (o: { kind: string }): TaskOutcome => {
    switch (o.kind) {
      case 'drafts':
        return { kind: 'drafts', items: [bottle(120)] };
      case 'answer':
        return { kind: 'answer', parts: [] };
      case 'clarification':
        return {
          kind: 'clarification',
          clarification: {
            id: 'c1',
            field: 'sleep.period',
            question: { vi: '?', en: '?' },
            choices: [],
            allowText: false,
          },
        };
      case 'health_route':
        return { kind: 'health_route', signs: [] };
      case 'unreadable':
        return { kind: 'unreadable' };
      case 'error':
        return { kind: 'error', code: 'AI_UNAVAILABLE' };
      default:
        return { kind: 'rejected', detail: o.kind };
    }
  };
  it.each([
    ['text_batch', 'commit', 'ready'],
    ['summary', 'commit', 'ready'],
    ['clarify', 'hold', 'awaiting_clarification'],
    ['blurry', 'release', 'failed'],
    ['failure', 'release', 'failed'],
    ['health', 'release', 'ready'],
    ['injection', 'release', 'failed'],
  ] as const)('%s → %s / %s', (key, usage, state) => {
    const o = asOutcome(outputs[key as keyof typeof outputs]);
    expect(usageForOutcome(o)).toBe(usage);
    expect(taskStateForOutcome(o)).toBe(state);
  });
  it('credits: text 1, a photo task 3 (QA values from the pack)', () => {
    expect(creditsFor('text')).toBe(context.quotaExamples.text);
    expect(creditsFor('image')).toBe(context.quotaExamples.image);
  });
});

describe('pack · reads, recipes, notes (R01, R02, I06, G03)', () => {
  it('R01 bottle ml and nursing minutes stay apart, with their sources', () => {
    const { summary, sourceIds } = careSummary(logs, '2026-10-15', '2026-10-15T07:20:00Z');
    expect(summary.bottle).toEqual({ count: 3, ml: 390 });
    expect(summary.breast).toEqual({ count: 2, minutes: 35 });
    expect(sourceIds).toHaveLength(5);
    expect(summary.coverage).toBe('unknown');
  });
  it('R02 recipes: approved, right age and region, no recorded-reaction ingredient', () => {
    expect(
      eligibleRecipes(
        recipes,
        context.secondChild.ageMonths,
        context.secondChild.recordedReactionIngredientIds,
        'VN',
      ),
    ).toEqual(['test_recipe_1']);
  });
  it('I06 note lines become reminders only with the explicit fallback and only where reminders exist', () => {
    const lines = [
      { kind: 'actionCandidate' },
      { kind: 'informational' },
      { kind: 'medicalText' },
      { kind: 'actionCandidate' },
    ];
    expect(noteActions(lines, { tasks: false, reminders: true }, false)).toEqual([]);
    expect(noteActions(lines, { tasks: false, reminders: true }, true)).toHaveLength(2);
    expect(noteActions(lines, { tasks: false, reminders: false }, true)).toEqual([]);
  });
  it('G03 "Thứ Hai 20/10" in 2026 is a Tuesday: the mismatch is detected', () => {
    expect(weekdayMatches('2026-10-20', 1)).toBe(false);
    expect(weekdayMatches('2026-10-20', 2)).toBe(true);
  });
  it('U02 the same request id with a different input is a different key', () => {
    const base = {
      conversationId: 'c',
      scope: { type: 'child' as const, babyId: 'test_teddy' },
      modality: 'text' as const,
      text: 'x',
      attachmentIds: [],
    };
    expect(taskInputKey(base)).toBe(taskInputKey({ ...base, text: ' x ' }));
    expect(taskInputKey(base)).not.toBe(taskInputKey({ ...base, text: 'y' }));
  });
});
