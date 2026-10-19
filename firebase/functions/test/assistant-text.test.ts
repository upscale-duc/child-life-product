import { describe, expect, it } from 'vitest';
import { parseExtraction, type ModelIntent } from '../src/assistant-model.js';
import {
  helpPart,
  noticePart,
  privateConversationId,
  smallTalkPart,
  spendingPrivatePart,
} from '../src/assistant-talk.js';
import {
  calendarAround,
  checkPurchases,
  previousForModel,
  timeMissingQuestion,
  timeStartQuestion,
} from '../src/assistant-text.js';
import type { TrustedScope } from '../src/assistant-common.js';

// Lumi rework 2026-10-15: the server's own questions, replies and request context (pure parts;
// the planner itself runs against the emulator in firebase/tests/assistant-text.integration).
const s = { zone: 'Asia/Ho_Chi_Minh' } as TrustedScope;
const MORNING = new Date('2026-10-15T00:10:00Z'); // 07:10 local
const NOW = new Date('2026-10-15T07:20:00Z'); // 14:20 local

describe('server questions', () => {
  it('time.start: two half-hour chips no later than send time − length, labelled by day; typed time allowed', () => {
    const q = timeStartQuestion({ s, anchor: MORNING }, new Date(MORNING.getTime() - 540 * 60_000));
    expect(q).toMatchObject({ field: 'time.start', allowText: true });
    expect(q.choices).toEqual([
      { id: 'at_2026-10-14_21:00', label: { vi: '21:00 tối qua', en: '21:00 last night' } },
      { id: 'at_2026-10-14_22:00', label: { vi: '22:00 tối qua', en: '22:00 last night' } },
    ]);
    const nap = timeStartQuestion({ s, anchor: NOW }, new Date(NOW.getTime() - 90 * 60_000));
    expect(nap.choices.map((c) => c.label.vi)).toEqual(['11:30 hôm nay', '12:30 hôm nay']);
    for (const c of [...q.choices, ...nap.choices]) expect(c.id.length).toBeLessThanOrEqual(40);
  });

  it('time.missing: Vừa xong / 30 phút trước / 1 tiếng trước with their clock times', () => {
    const q = timeMissingQuestion({ s, anchor: NOW }, null);
    expect(q.choices).toEqual([
      { id: 'ago_0', label: { vi: 'Vừa xong (14:20)', en: 'Just now (14:20)' } },
      { id: 'ago_30', label: { vi: '30 phút trước (13:50)', en: '30 min ago (13:50)' } },
      { id: 'ago_60', label: { vi: '1 tiếng trước (13:20)', en: '1 hour ago (13:20)' } },
    ]);
    expect(q.allowText).toBe(true);
  });
});

describe('request context', () => {
  it('the calendar names today, tomorrow and weekdays (vi and en)', () => {
    const c = calendarAround('2026-10-15', 'vi');
    expect(c.find((d) => d.label === 'mai')).toEqual({
      date: '2026-10-16',
      weekday: 'Thứ Sáu (Friday)',
      label: 'mai',
    });
    expect(c.find((d) => d.date === '2026-10-19')!.weekday).toBe('Thứ Hai (Monday)');
    expect(calendarAround('2026-10-15', 'en').find((d) => d.label === 'today')!.weekday).toBe(
      'Thursday',
    );
  });

  it('the previous turn shows kinds and local times, never ids, babies or links', () => {
    const p = previousForModel(
      {
        taskId: 'tk_x',
        text: 'bé bú 120ml lúc 8h sáng',
        drafts: [
          {
            id: 'dr_x_0',
            state: 'draft',
            recordLink: null,
            payload: {
              kind: 'bottle',
              amountMl: 120,
              occurredAt: '2026-10-15T01:00:00.000Z',
              milk: 'formula',
            },
          },
          {
            id: 'dr_x_1',
            state: 'discarded',
            recordLink: null,
            payload: { kind: 'sleep', startedAt: null, endedAt: null },
          },
        ],
      },
      'Asia/Ho_Chi_Minh',
      '2026-10-15',
    );
    expect(p).toEqual({
      text: 'bé bú 120ml lúc 8h sáng',
      drafts: [
        {
          // L9: the opaque id the model names in `target`.
          id: 'i1',
          kind: 'bottle',
          saved: false,
          amountMl: 120,
          occurredAt: { time: '08:00', dayOffset: 0 },
          milk: 'formula',
        },
      ],
    });
    expect(JSON.stringify(p)).not.toContain('dr_x');
  });

  it('a v3 extraction parses (expense, reminder, correction, small talk); v2-shaped outputs still parse', () => {
    const fields = {
      amountMl: null,
      milk: null,
      time: null,
      dayOffset: null,
      endTime: null,
      endDayOffset: null,
      durationMin: null,
      side: null,
      observation: null,
      when: null,
      note: null,
      title: 'sữa',
    };
    const v3 = {
      intents: [
        {
          kind: 'expense',
          fields: {
            ...fields,
            amount: 500000,
            currency: 'VND',
            categoryId: 'c_milk',
            merchant: null,
            date: null,
            assigneeText: null,
          },
          evidence: [{ field: 'amount', text: '500k' }],
          uncertainFields: [],
          missingFields: [],
          correctsPrevious: false,
        },
      ],
      reads: [],
      clarification: null,
      care: null,
      healthSigns: [],
      smallTalk: false,
      outOfScope: false,
    };
    expect(parseExtraction(v3).ok).toBe(true);
    const { smallTalk: _a, outOfScope: _b, ...v2 } = v3;
    void _a;
    void _b;
    const i = v2.intents[0]!;
    const {
      amount: _1,
      currency: _2,
      categoryId: _3,
      merchant: _4,
      date: _5,
      assigneeText: _6,
      ...v2fields
    } = i.fields;
    void [_1, _2, _3, _4, _5, _6];
    const { correctsPrevious: _c, ...v2intent } = i;
    void _c;
    expect(parseExtraction({ ...v2, intents: [{ ...v2intent, fields: v2fields }] }).ok).toBe(true);
    // Still strict: an unknown field or a tool request is rejected.
    expect(
      parseExtraction({ ...v3, intents: [{ ...i, fields: { ...i.fields, uid: 'x' } }] }).ok,
    ).toBe(false);
    expect(parseExtraction({ ...v3, deleteAll: true }).ok).toBe(false);
  });
});

describe('server replies', () => {
  it('small talk, help and the spending notice carry codes the app can act on', () => {
    expect(smallTalkPart('thanks', 'vi')).toMatchObject({ type: 'text', code: 'SMALL_TALK' });
    expect(helpPart('en')).toMatchObject({ code: 'HELP' });
    const help = helpPart('vi');
    expect(help.type === 'text' ? help.text : '').not.toContain('lượt');
    expect(spendingPrivatePart('vi')).toMatchObject({ code: 'SPENDING_PRIVATE' });
    expect(noticePart({ code: 'PREVIOUS_SAVED', link: '/care/records/b/r' }, 'vi')).toMatchObject({
      code: 'PREVIOUS_SAVED',
      link: '/care/records/b/r',
    });
    // A2 notices keep their words and no code.
    const denied = noticePart({ code: 'WRITE_DENIED', kind: 'expense' }, 'vi');
    expect(denied).not.toHaveProperty('code');
    expect(denied.type === 'text' && denied.text).toContain('Chi tiêu');
  });

  it('the author’s private thread id is stable per person and baby', () => {
    expect(privateConversationId('u1', 'b1')).toBe(privateConversationId('u1', 'b1'));
    expect(privateConversationId('u1', 'b1')).not.toBe(privateConversationId('u2', 'b1'));
    expect(privateConversationId('u1', 'b1')).toMatch(/^cv_p_[a-f0-9]{32}$/);
  });
});

describe('LUMI-16: purchases checked against the words (owner 2026-10-16)', () => {
  const intent = (kind: ModelIntent['kind'], fields: Partial<ModelIntent['fields']>) =>
    ({
      kind,
      fields: {
        amountMl: null,
        milk: null,
        time: null,
        dayOffset: null,
        endTime: null,
        endDayOffset: null,
        durationMin: null,
        side: null,
        observation: null,
        when: null,
        note: null,
        title: null,
        ...fields,
      },
      evidence: [],
      uncertainFields: [],
      missingFields: [],
      correctsPrevious: false,
    }) as ModelIntent;

  it('a purchase made stays an expense; one the model missed is added without an amount', () => {
    const model = [intent('expense', { title: 'hai hộp sữa', amount: null })];
    expect(checkPurchases('mua hai hộp sữa', model)).toEqual({ intents: model, shopping: false });
    const added = checkPurchases('bé bú 90ml, vừa mua bỉm ở Con Cưng', [
      intent('bottle', { amountMl: 90 }),
    ]);
    expect(added.intents.map((i) => i.kind)).toEqual(['bottle', 'expense']);
    expect(added.intents[1]!.fields).toMatchObject({
      title: 'bỉm',
      merchant: 'Con Cưng',
    });
    expect(added.intents[1]!.fields.amount ?? null).toBeNull();
  });

  it('a purchase made that the model read as a to-do is the expense (live 2026-10-16)', () => {
    const r = checkPurchases('đặt tã online', [intent('reminder', { title: 'đặt tã online' })]);
    expect(r.intents.map((i) => [i.kind, i.fields.title])).toEqual([['expense', 'tã online']]);
    // A reminder with a day said is left alone; so is any reminder of a plan.
    const dated = [intent('reminder', { title: 'mua bỉm', date: '2026-10-16' })];
    expect(checkPurchases('mua bỉm', dated).intents).toEqual(dated);
    const plan = [intent('reminder', { title: 'mua bỉm' })];
    expect(checkPurchases('nhắc mua bỉm', plan).intents).toEqual(plan);
  });

  it('a plan the model read as an expense becomes a reminder in the person’s words', () => {
    const r = checkPurchases('mai đi mua sữa', [intent('expense', { title: 'sữa' })]);
    expect(r.intents.map((i) => [i.kind, i.fields.title])).toEqual([['reminder', 'mua sữa']]);
    // The model's own reminder is kept, the expense dropped.
    const both = checkPurchases('nhớ mua bỉm', [
      intent('expense', { title: 'bỉm' }),
      intent('reminder', { title: 'mua bỉm' }),
    ]);
    expect(both.intents.map((i) => i.kind)).toEqual(['reminder']);
    // Nothing from the model: nothing added (no reminder nobody asked for).
    expect(checkPurchases('cần mua thêm tã', []).intents).toEqual([]);
  });

  it('a question about buying is never an expense (help instead)', () => {
    expect(checkPurchases('mua sữa nào tốt?', [intent('expense', { title: 'sữa' })])).toEqual({
      intents: [],
      shopping: true,
    });
    expect(checkPurchases('mua sữa nào tốt?', []).shopping).toBe(true);
    const help = helpPart('vi', 'shopping');
    expect(help).toMatchObject({ code: 'HELP' });
    expect(help.type === 'text' ? help.text : '').not.toContain('lượt');
  });
});
