import { describe, expect, it } from 'vitest';
import {
  asksWhatLumiDoes,
  bareMAmountIn,
  clientDraftKindsOf,
  clockTokensIn,
  diaperIn,
  draftPayloadSchema,
  draftProblems,
  draftReviewFields,
  feedingConcernIn,
  growthIn,
  legacyClientDraftKinds,
  looksLikeSpending,
  pumpCueIn,
  purchasesIn,
  quoteTaskRequestSchema,
  sleepConcernIn,
  type DraftPayload,
} from '../src/index.js';

// Lumi fixes 2026-10-16 (docs/assistant/test-report-lumi-2026-10-16.md LUMI-01…17). Synthetic
// phrases only.
const anchor = new Date('2026-10-15T07:20:00Z');
const ago = (min: number) => new Date(anchor.getTime() - min * 60_000).toISOString();

describe('LUMI-01: pump, diaper and growth drafts mirror the care forms', () => {
  const pump: DraftPayload = {
    kind: 'pump',
    amountMl: 120,
    occurredAt: ago(30),
    side: 'both',
    durationMin: null,
  };
  const diaper: DraftPayload = { kind: 'diaper', diaper: 'wet', occurredAt: ago(5) };
  const growth: DraftPayload = {
    kind: 'growth',
    weightKg: 5.2,
    lengthCm: 60,
    measuredOn: '2026-10-15',
  };
  it('parse and are clean when complete', () => {
    for (const p of [pump, diaper, growth]) {
      expect(draftPayloadSchema.safeParse(p).success, p.kind).toBe(true);
      expect(draftProblems(p, anchor), p.kind).toEqual([]);
      expect(draftReviewFields(p, draftProblems(p, anchor)), p.kind).toEqual({
        missing: [],
        uncertain: [],
      });
    }
  });
  it('pump: amount 1…1000 whole ml, length ≤ 240, a time not in the future', () => {
    expect(draftProblems({ ...pump, amountMl: null }, anchor)).toEqual(['MISSING_AMOUNT']);
    expect(draftProblems({ ...pump, amountMl: 1200 }, anchor)).toEqual(['INVALID_AMOUNT']);
    const long = { ...pump, durationMin: 300 } as DraftPayload;
    expect(draftReviewFields(long, draftProblems(long, anchor)).uncertain).toEqual(['durationMin']);
    expect(draftProblems({ ...pump, occurredAt: null }, anchor)).toEqual(['MISSING_TIME']);
    expect(draftProblems({ ...pump, occurredAt: ago(-30) }, anchor)).toEqual(['FUTURE_TIME']);
  });
  it('diaper: wet / dirty / both is required (never a guess)', () => {
    const d = { ...diaper, diaper: null } as DraftPayload;
    expect(draftReviewFields(d, draftProblems(d, anchor)).missing).toEqual(['diaper']);
  });
  it('growth: weight required 0.3…40 kg, length 20…150 cm names itself, no future day', () => {
    const noWeight = { ...growth, weightKg: null } as DraftPayload;
    expect(draftReviewFields(noWeight, draftProblems(noWeight, anchor)).missing).toEqual([
      'weightKg',
    ]);
    const badLength = { ...growth, lengthCm: 6.2 } as DraftPayload;
    expect(draftReviewFields(badLength, draftProblems(badLength, anchor)).uncertain).toEqual([
      'lengthCm',
    ]);
    expect(draftProblems({ ...growth, measuredOn: '2026-10-20' }, anchor)).toEqual(['FUTURE_TIME']);
  });
  it('growth: head circumference is optional, 20…60 cm, names itself (owner 2026-10-16)', () => {
    const withHead = { ...growth, headCm: 39 } as DraftPayload;
    expect(draftPayloadSchema.safeParse(withHead).success).toBe(true);
    expect(draftProblems(withHead, anchor)).toEqual([]);
    // A draft prepared before the field (no key) is still a growth draft.
    expect(draftPayloadSchema.safeParse(growth).success).toBe(true);
    const badHead = { ...growth, headCm: 3.9 } as DraftPayload;
    expect(draftProblems(badHead, anchor)).toEqual(['INVALID_AMOUNT']);
    expect(draftReviewFields(badHead, draftProblems(badHead, anchor)).uncertain).toEqual([
      'headCm',
    ]);
  });
  it('a reminder already past names its time (LUMI-11)', () => {
    const r: DraftPayload = {
      kind: 'reminder',
      title: 'gọi bác sĩ',
      date: '2026-10-15',
      time: '10:00',
      assigneeUid: null,
    };
    expect(draftReviewFields(r, ['PAST_TIME']).uncertain).toEqual(['time']);
  });
});

describe('LUMI-05: the kinds a client can show', () => {
  it('an app without the field gets the kinds of before 2026-10-16 only', () => {
    expect(clientDraftKindsOf(undefined)).toEqual([...legacyClientDraftKinds]);
    expect(clientDraftKindsOf(undefined)).not.toContain('timer');
    expect(clientDraftKindsOf(['bottle', 'pump', 'teleport'])).toEqual(['bottle', 'pump']);
  });
  it('the envelope accepts the declaration (and older apps without it)', () => {
    const base = {
      contractVersion: 1,
      clientRequestId: '6f1c3a1e-2b3c-4d5e-8f90-1234567890ab',
      locale: 'vi',
      conversationId: null,
      scope: { type: 'child', babyId: 'b1' },
      modality: 'text',
      attachmentCount: 0,
      intentHint: null,
    };
    expect(quoteTaskRequestSchema.safeParse(base).success).toBe(true);
    expect(
      quoteTaskRequestSchema.safeParse({ ...base, clientDraftKinds: ['bottle', 'growth'] }).data
        ?.clientDraftKinds,
    ).toEqual(['bottle', 'growth']);
  });
});

describe('LUMI-03: each clock time reads its own period', () => {
  const read = (t: string) => clockTokensIn(t).map((x) => [x.h, x.m, x.hours]);
  it.each([
    [
      'bé bú 3 lần: 6h 90ml, 9h 120ml, 12h 100ml',
      [
        [6, 0, [6, 18]],
        [9, 0, [9, 21]],
        [12, 0, [12]],
      ],
    ],
    [
      'be ngu tu 1h trua den 2h chieu',
      [
        [1, 0, [13]],
        [2, 0, [14]],
      ],
    ],
    [
      'hôm nay bé bú 6h 90ml, 9h tối 120ml',
      [
        [6, 0, [6, 18]],
        [9, 0, [21]],
      ],
    ],
    [
      'đêm qua bé ngủ từ 9h tối đến 6h sáng',
      [
        [9, 0, [21]],
        [6, 0, [6]],
      ],
    ],
    ['à không, ngủ từ 12h30', [[12, 30, [12]]]],
    ['12h đêm bé bú', [[12, 0, [0]]]],
    ['tám giờ rưỡi tối qua bú 100ml', [[8, 30, [20]]]],
    [
      'slept from 9pm to 6am',
      [
        [9, 0, [21]],
        [6, 0, [6]],
      ],
    ],
    ['9 giờ kém 15', [[8, 45, [8, 20]]]],
    ['bé bú lúc 8', [[8, 0, [8, 20]]]],
  ])('%s', (text, want) => expect(read(text)).toEqual(want));
});

describe('LUMI-01 / LUMI-15 backstop readers', () => {
  it('pumping words (never "sữa vắt" given to the baby)', () => {
    for (const t of ['hút sữa 120ml', 'vừa hút được 80ml cả 2 bên', 'hut sua 100ml', 'pumped 4oz'])
      expect(pumpCueIn(t), t).toBe(true);
    for (const t of ['bé bú 90ml sữa vắt', 'bé bú 120ml']) expect(pumpCueIn(t), t).toBe(false);
  });
  it('diaper changes and what was in them; buying diapers is money', () => {
    expect(diaperIn('thay tã ướt')).toEqual({ kind: 'wet' });
    expect(diaperIn('bé vừa ị, thay bỉm rồi')).toEqual({ kind: 'dirty' });
    expect(diaperIn('thay ta uot')).toEqual({ kind: 'wet' });
    expect(diaperIn('changed a dirty diaper at 1pm')).toEqual({ kind: 'dirty' });
    expect(diaperIn('thay tã rồi cho bú 90ml')).toEqual({ kind: null });
    expect(diaperIn('mua bỉm hết 200k')).toBeNull();
    expect(diaperIn('bé bú 120ml')).toBeNull();
  });
  it('measurements: kg forms, grams, cm, head', () => {
    expect(growthIn('bé nặng 5,2kg')).toEqual({ weightKg: 5.2, lengthCm: null, headCm: null });
    expect(growthIn('bé nặng 6kg2, dài 62cm')).toEqual({
      weightKg: 6.2,
      lengthCm: 62,
      headCm: null,
    });
    expect(growthIn('hôm qua đi khám bé nặng 5kg8')?.weightKg).toBe(5.8);
    expect(growthIn('baby weighs 5.4 kg today')?.weightKg).toBe(5.4);
    expect(growthIn('bé nặng 5200g')?.weightKg).toBe(5.2);
    expect(growthIn('vòng đầu 40cm, nặng 6 ký')).toEqual({
      weightKg: 6,
      lengthCm: null,
      headCm: 40,
    });
    expect(growthIn('bé bú 120ml lúc 8h')).toBeNull();
    expect(growthIn('bé nặng 5,2kg dài 58cm vòng đầu 39cm')).toEqual({
      weightKg: 5.2,
      lengthCm: 58,
      headCm: 39,
    });
    expect(growthIn('head circumference 40.5 cm, weight 6 kg')?.headCm).toBe(40.5);
  });
  it('"bé bu 120m" is millilitres; "bú mẹ 20m" is not', () => {
    expect(bareMAmountIn('bé bu 120m lúc 8h sang')).toBe(120);
    expect(bareMAmountIn('bú mẹ 20m')).toBeNull();
    expect(bareMAmountIn('bú mẹ 120m')).toBeNull();
  });
});

describe('LUMI-10 / -12 / -16 words', () => {
  it('a sleep concern vs a note about one night', () => {
    expect(sleepConcernIn('dạo này bé khó ngủ về đêm')).toEqual({
      kind: 'falling_asleep',
      when: 'night',
    });
    expect(sleepConcernIn('bé hay thức đêm 3 hôm nay')?.kind).toBe('night_waking');
    expect(sleepConcernIn('đêm qua bé thức giấc 2 lần')).toBeNull();
    expect(sleepConcernIn('bé ngủ 2 tiếng')).toBeNull();
    expect(feedingConcernIn('mấy hôm nay bé biếng ăn')).toBe(true);
  });
  it('"what can Lumi do" and goods bought by the box', () => {
    expect(asksWhatLumiDoes('Lumi làm được gì?')).toBe(true);
    expect(asksWhatLumiDoes('what can you do')).toBe(true);
    expect(asksWhatLumiDoes('bé bú được bao nhiêu')).toBe(false);
    expect(looksLikeSpending('Con Cưng hôm nay hai hộp sữa, bé bú 90ml lúc 13h')).toBe(true);
    expect(looksLikeSpending('bé bú 90ml lúc 13h')).toBe(false);
  });
});

describe('LUMI-16: a purchase without an amount (owner 2026-10-16)', () => {
  const moods = (t: string) => purchasesIn(t).map((p) => p.mood);
  it('done: an expense even without an amount', () => {
    expect(purchasesIn('mua hai hộp sữa')).toEqual([
      {
        mood: 'done',
        phrase: 'mua hai hộp sữa',
        title: 'mua hai hộp sữa',
        what: 'hai hộp sữa',
        merchant: null,
      },
    ]);
    expect(purchasesIn('vừa mua bỉm ở Con Cưng')[0]).toMatchObject({
      mood: 'done',
      what: 'bỉm',
      merchant: 'Con Cưng',
    });
    expect(purchasesIn('đặt tã online')[0]).toMatchObject({ mood: 'done', what: 'tã online' });
    expect(purchasesIn('hôm qua mua bỉm 350.000đ ở Con Cưng')[0]).toMatchObject({
      mood: 'done',
      what: 'bỉm',
      merchant: 'Con Cưng',
    });
    expect(moods('mua sữa cho bé Mai')).toEqual(['done']);
    expect(moods('bought diapers at Target')).toEqual(['done']);
    expect(moods('mua gì đó cho bé hết 200k')).toEqual(['done']);
    expect(moods('mua bim o con cung')).toEqual(['done']);
  });
  it('plans and to-dos: never an expense', () => {
    expect(purchasesIn('mai đi mua sữa')[0]).toMatchObject({ mood: 'plan', title: 'mua sữa' });
    expect(purchasesIn('nhớ mua bỉm')[0]).toMatchObject({ mood: 'plan', title: 'mua bỉm' });
    expect(moods('cần mua thêm tã cho bé')).toEqual(['plan']);
    expect(moods('hôm nay nhớ mua sữa')).toEqual(['plan']);
    expect(moods('chưa mua sữa')).toEqual(['plan']);
    expect(moods('hết sữa rồi, mai đi mua')).toEqual(['plan']);
    expect(purchasesIn('need to buy diapers tomorrow')[0]).toMatchObject({
      mood: 'plan',
      title: 'buy diapers',
    });
  });
  it('questions: help, never an expense', () => {
    expect(moods('mua sữa nào tốt?')).toEqual(['question']);
    expect(moods('mua sữa nào tốt')).toEqual(['question']);
    expect(moods('nên mua bỉm gì')).toEqual(['question']);
    expect(moods('which formula should I buy?')).toEqual(['question']);
  });
  it('mixed clauses keep their own mood; no buying word → nothing', () => {
    expect(moods('vừa mua bỉm ở Con Cưng, mai nhớ mua sữa')).toEqual(['done', 'plan']);
    expect(purchasesIn('trời mưa quá')).toEqual([]);
    expect(purchasesIn('bé múa đẹp')).toEqual([]);
    expect(purchasesIn('đặt lịch khám')).toEqual([]);
  });
  it('"đặt tã online" keeps the message private (D-075 #2)', () => {
    expect(looksLikeSpending('đặt tã online')).toBe(true);
    expect(looksLikeSpending('đặt lịch khám')).toBe(false);
  });
});
