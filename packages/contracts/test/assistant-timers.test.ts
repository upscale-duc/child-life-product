import { describe, expect, it } from 'vitest';
import {
  careStatesIn,
  draftFieldKeys,
  draftKinds,
  draftPayloadSchema,
  draftProblemFields,
  draftProblems,
  draftReviewFields,
  assistantModuleProblems,
  observationCueIn,
  requiredDraftFields,
  sameMessage,
  timerRecordAt,
  type DraftPayload,
  type DraftProblem,
} from '../src/index.js';

// Lumi 2026-10-16 (docs/assistant/api.md "Timers and review fields"): ongoing states drive the
// app's timers, and every review flag names a real field of its draft. Synthetic values only.

const allProblems: DraftProblem[] = [
  'MISSING_AMOUNT',
  'INVALID_AMOUNT',
  'MISSING_TIME',
  'FUTURE_TIME',
  'INVALID_TIME',
  'MISSING_DATE',
  'CURRENCY_UNSUPPORTED',
  'MISSING_TITLE',
  'INVALID_TITLE',
  'PAST_TIME',
  'INVALID_ASSIGNEE',
];

const anchor = new Date('2026-10-15T18:05:00Z'); // 01:05 on the 16th in Vietnam

/** Payloads that raise every problem a kind can have (form + module checks). */
const troubled: DraftPayload[] = [
  { kind: 'bottle', amountMl: null, occurredAt: null, milk: null },
  { kind: 'bottle', amountMl: 900, occurredAt: '2026-10-15T20:00:00Z', milk: 'formula' },
  { kind: 'breast', occurredAt: null, durationMin: 300, side: null },
  { kind: 'breast', occurredAt: '2026-10-15T20:00:00Z', durationMin: 10, side: 'left' },
  { kind: 'sleep', startedAt: null, endedAt: null },
  { kind: 'sleep', startedAt: '2026-10-15T17:00:00Z', endedAt: '2026-10-15T16:00:00Z' },
  { kind: 'sleep', startedAt: '2026-10-15T17:00:00Z', endedAt: '2026-10-15T20:00:00Z' },
  {
    kind: 'expense',
    merchant: null,
    totalMinor: null,
    currency: null,
    date: null,
    subtotalMinor: null,
    taxMinor: null,
    categoryId: null,
    babyId: null,
    keepReceipt: false,
  },
  {
    kind: 'expense',
    merchant: null,
    totalMinor: -5,
    currency: 'XXX',
    date: '2026-10-15',
    subtotalMinor: null,
    taxMinor: null,
    categoryId: null,
    babyId: null,
    keepReceipt: false,
  },
  { kind: 'reminder', title: ' ', date: null, time: null, assigneeUid: null },
  { kind: 'reminder', title: 'x'.repeat(100), date: '2026-10-20', time: null, assigneeUid: null },
  { kind: 'observation', observation: 'sleep', date: '2026-10-16', when: null, note: null },
  { kind: 'meal', recipeId: null, title: 'Cháo', occurredAt: '2026-10-15T20:00:00Z' },
  {
    kind: 'timer',
    timer: 'sleep',
    action: 'start',
    at: null,
    side: null,
    sessionId: null,
    startedAt: null,
  },
  {
    kind: 'timer',
    timer: 'sleep',
    action: 'start',
    at: '2026-10-15T20:00:00Z',
    side: null,
    sessionId: null,
    startedAt: null,
  },
  {
    kind: 'timer',
    timer: 'breast',
    action: 'start',
    at: '2026-10-15T08:00:00Z',
    side: 'left',
    sessionId: null,
    startedAt: null,
  },
  {
    kind: 'timer',
    timer: 'sleep',
    action: 'stop',
    at: '2026-10-15T16:00:00Z',
    side: null,
    sessionId: 'a'.repeat(32),
    startedAt: '2026-10-15T17:00:00Z',
  },
];

describe('review fields: every problem names a real field of its kind', () => {
  it('maps every draft kind × every DraftProblem to a field of that kind (or not applicable)', () => {
    for (const kind of draftKinds) {
      const keys = draftFieldKeys[kind];
      expect(keys.length).toBeGreaterThan(1);
      for (const pr of allProblems) {
        const f = draftProblemFields[kind][pr];
        if (f !== null) expect(keys, `${kind} ${pr} → ${f}`).toContain(f);
      }
      for (const f of requiredDraftFields[kind]) expect(keys, `${kind} requires ${f}`).toContain(f);
    }
  });

  it('every problem a kind can raise is mapped, and review lists hold only its own fields', () => {
    const raised = new Map<string, Set<DraftProblem>>();
    for (const p of troubled) {
      expect(draftPayloadSchema.safeParse(p).success, JSON.stringify(p)).toBe(true);
      const problems = [...new Set([...draftProblems(p, anchor), ...assistantModuleProblems(p)])];
      for (const pr of problems) {
        const set = raised.get(p.kind) ?? new Set();
        set.add(pr);
        raised.set(p.kind, set);
        if (!(p.kind === 'expense' && pr === 'CURRENCY_UNSUPPORTED')) {
          expect(draftProblemFields[p.kind][pr], `${p.kind} ${pr}`).not.toBeNull();
        }
      }
      const r = draftReviewFields(p, problems, ['time', 'date', 'when', 'note', 'side']);
      for (const f of [...r.missing, ...r.uncertain]) {
        expect(draftFieldKeys[p.kind], `${p.kind}: ${f}`).toContain(f);
      }
      // A filled field is never "missing"; an empty one is never only "uncertain".
      for (const f of r.missing) {
        const v = (p as Record<string, unknown>)[f];
        expect(v === null || (typeof v === 'string' && v.trim() === ''), `${p.kind} ${f}`).toBe(
          true,
        );
      }
      for (const f of r.uncertain) expect(r.missing).not.toContain(f);
    }
    // The sample really exercises the kinds that have problems.
    for (const k of ['bottle', 'breast', 'sleep', 'expense', 'reminder', 'timer'] as const) {
      expect(raised.get(k)?.size ?? 0, k).toBeGreaterThan(0);
    }
  });

  it('the dev incident: an observation with no "when" is complete (nothing missing)', () => {
    const p: DraftPayload = {
      kind: 'observation',
      observation: 'sleep',
      date: '2026-10-16',
      when: null,
      note: null,
    };
    // The model said "time" was missing: it is not a field of an observation.
    expect(draftReviewFields(p, draftProblems(p, anchor), ['time'])).toEqual({
      missing: [],
      uncertain: [],
    });
  });

  it('the second incident: a breastfeed whose time was filled by "Vừa xong" and no side is complete', () => {
    const p: DraftPayload = {
      kind: 'breast',
      occurredAt: '2026-10-15T17:48:58.920Z',
      durationMin: 20,
      side: null,
    };
    expect(draftReviewFields(p, draftProblems(p, anchor))).toEqual({ missing: [], uncertain: [] });
  });

  it('names the real gap: sleep ends, bottle amount, expense amount / currency / date, reminder date', () => {
    const r = (p: DraftPayload) => draftReviewFields(p, draftProblems(p, anchor)).missing;
    expect(r({ kind: 'sleep', startedAt: '2026-10-15T14:00:00Z', endedAt: null })).toEqual([
      'endedAt',
    ]);
    expect(
      r({ kind: 'bottle', amountMl: null, occurredAt: anchor.toISOString(), milk: 'formula' }),
    ).toEqual(['amountMl']);
    expect(
      r({
        kind: 'expense',
        merchant: null,
        totalMinor: null,
        currency: null,
        date: null,
        subtotalMinor: null,
        taxMinor: null,
        categoryId: 'c_milk',
        babyId: null,
        keepReceipt: false,
      }),
    ).toEqual(['currency', 'date', 'totalMinor']);
    expect(
      r({ kind: 'reminder', title: 'Mua bỉm', date: null, time: null, assigneeUid: null }),
    ).toEqual(['date']);
  });
});

describe('timer drafts: problems', () => {
  const t = (over: Partial<Extract<DraftPayload, { kind: 'timer' }>>): DraftPayload => ({
    kind: 'timer',
    timer: 'sleep',
    action: 'start',
    at: anchor.toISOString(),
    side: null,
    sessionId: null,
    startedAt: null,
    ...over,
  });
  it('a start now is fine; in the future, missing or older than the record can hold is not', () => {
    expect(draftProblems(t({}), anchor)).toEqual([]);
    expect(draftProblems(t({ at: '2026-10-15T18:30:00Z' }), anchor)).toEqual(['FUTURE_TIME']);
    expect(draftProblems(t({ at: null }), anchor)).toEqual(['MISSING_TIME']);
    expect(draftProblems(t({ at: '2026-10-14T17:00:00Z' }), anchor)).toEqual(['INVALID_TIME']);
    expect(
      draftProblems(t({ timer: 'breast', side: 'left', at: '2026-10-15T13:00:00Z' }), anchor),
    ).toEqual(['INVALID_TIME']);
  });
  it('a stop must end after the running start', () => {
    const stop = { action: 'stop' as const, sessionId: 'b'.repeat(32) };
    expect(draftProblems(t({ ...stop, startedAt: '2026-10-15T16:10:00Z' }), anchor)).toEqual([]);
    expect(draftProblems(t({ ...stop, startedAt: '2026-10-15T18:10:00Z' }), anchor)).toEqual([
      'INVALID_TIME',
    ]);
  });
});

describe('timerRecordAt mirrors the app timer "Kết thúc" (CareTimer.toRecord)', () => {
  const start = Date.parse('2026-10-15T16:10:00Z');
  it('sleep: start … end, capped at 24 h', () => {
    const s = {
      type: 'sleep' as const,
      sessionId: 'c'.repeat(32),
      startedAt: start,
      left: null,
      right: null,
      pausedSides: [],
    };
    expect(timerRecordAt(s, start + 55 * 60_000)).toEqual({
      type: 'sleep',
      occurredAt: start,
      endedAt: start + 55 * 60_000,
      data: {},
    });
    expect(timerRecordAt(s, start + 30 * 3_600_000).endedAt).toBe(start + 24 * 3_600_000);
  });
  it('breast: sides summed, per-side minutes, the running side as the end side', () => {
    const b = {
      type: 'breast' as const,
      sessionId: 'd'.repeat(32),
      startedAt: start,
      left: { accumulatedMs: 7 * 60_000 + 40_000, runningSince: null },
      right: { accumulatedMs: 0, runningSince: start + 8 * 60_000 },
      pausedSides: [],
    };
    expect(timerRecordAt(b, start + 14 * 60_000)).toEqual({
      type: 'breast',
      occurredAt: start,
      endedAt: start + 14 * 60_000,
      data: { side: 'both', durationMin: 14, leftMin: 8, rightMin: 6, endSide: 'right' },
    });
  });
  it('breast: one side only, at least one minute', () => {
    const b = {
      type: 'breast' as const,
      sessionId: 'e'.repeat(32),
      startedAt: start,
      left: { accumulatedMs: 0, runningSince: start },
      right: { accumulatedMs: 0, runningSince: null },
      pausedSides: [],
    };
    expect(timerRecordAt(b, start + 20_000).data).toEqual({
      side: 'left',
      durationMin: 1,
      leftMin: 0,
      rightMin: 0,
      endSide: 'left',
    });
  });
});

describe('careStatesIn: ongoing states → timers', () => {
  const one = (text: string) =>
    careStatesIn(text).map((s) => `${s.timer}:${s.action}${s.side ? `:${s.side}` : ''}`);
  it.each([
    ['Con đang ngủ', ['sleep:start']],
    ['con dang ngu', ['sleep:start']],
    ['bé vừa ngủ', ['sleep:start']],
    ['bé ngủ rồi', ['sleep:start']],
    ['bắt đầu ngủ lúc 21h', ['sleep:start']],
    ['con dậy rồi', ['sleep:stop']],
    ['bé vừa dậy', ['sleep:stop']],
    ['bé vừa ngủ dậy', ['sleep:stop']],
    ['dậy lúc 6h', ['sleep:stop']],
    ['đang cho bú (trái)', ['breast:start:left']],
    ['đang cho bú bên phải', ['breast:start:right']],
    ['bé đang ti mẹ', ['breast:start']],
    ['bú xong rồi', ['breast:stop']],
    ['She fell asleep', ['sleep:start']],
    ['he just woke up', ['sleep:stop']],
  ])('%s', (text, want) => expect(one(text)).toEqual(want));
  it.each([
    'bé ngủ 2 tiếng',
    'vừa ngủ dậy, ngủ được 2 tiếng',
    'dậy lúc 6h, ngủ 9 tiếng',
    'con khó ngủ quá',
    'bé chưa ngủ',
    'bé hay thức giấc',
    'bé bú bình 120ml',
    'đang bú bình',
    'vừa bú mẹ 20 phút',
    'bé bú 15 phút xong',
    'cô giáo dạy bé hát',
    'bình đầy rồi',
    'mua sữa hết 500k',
  ])('not a state: %s', (text) => expect(one(text)).toEqual([]));
});

describe('observation cues and repeated messages', () => {
  it('a sleep / feeding note is an observation only with a "different" cue', () => {
    for (const t of [
      'bé khó ngủ',
      'dạo này hay thức giấc',
      'con quấy hơn mọi khi',
      'bé bú ít',
      'biếng ăn',
    ])
      expect(observationCueIn(t), t).toBe(true);
    for (const t of ['Con đang ngủ', 'bé ngủ 2 tiếng', 'bé vừa bú', 'bé ngủ rồi', 'con dậy rồi'])
      expect(observationCueIn(t), t).toBe(false);
  });
  it('same message: punctuation, case and spaces ignored; diacritics kept', () => {
    expect(sameMessage('Con đang ngủ', 'con đang ngủ.')).toBe(true);
    expect(sameMessage('Con đang ngủ', '  Con   đang ngủ!! ')).toBe(true);
    expect(sameMessage('Con đang ngủ', 'Con đang ngủ 2 tiếng')).toBe(false);
    expect(sameMessage('', '')).toBe(false);
    expect(sameMessage(null, 'x')).toBe(false);
  });
});
