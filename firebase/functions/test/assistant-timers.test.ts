import { careStatesIn } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import {
  understandingSystemPrompt,
  parseExtraction,
  type ModelIntent,
} from '../src/assistant-model.js';
import { sameAsPendingPart, timerRunningPart } from '../src/assistant-talk.js';
import { checkIntents, sleepStartQuestion } from '../src/assistant-text.js';
import { timerLinkFor, timerSessionIdForDraft } from '../src/assistant-timers.js';
import type { TrustedScope } from '../src/assistant-common.js';

// Lumi 2026-10-16 (docs/assistant/api.md "Timers and review fields"): the pure pieces; the
// planner and the confirm writer run against the emulator (firebase/tests/assistant-timers).
const s = { zone: 'Asia/Ho_Chi_Minh' } as TrustedScope;
const NIGHT = new Date('2026-10-15T18:05:00Z'); // 01:05 on the 16th, local

const blank = {
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
};
const intent = (
  kind: ModelIntent['kind'],
  fields: Partial<ModelIntent['fields']> = {},
): ModelIntent => ({
  kind,
  fields: { ...blank, ...fields },
  evidence: [],
  uncertainFields: [],
  missingFields: [],
  correctsPrevious: false,
});
const check = (text: string, raw: ModelIntent[], previous: string | null = null) =>
  checkIntents(
    { text, previous: previous === null ? null : { taskId: 'tk_x', text: previous, drafts: [] } },
    raw,
    careStatesIn(text),
  ).map(
    (i) =>
      `${i.kind}${i.fields.phase ? `:${i.fields.phase}` : ''}${i.fields.observation ? `:${i.fields.observation}` : ''}`,
  );

describe('checkIntents: a state or a plain log is never an observation', () => {
  it('"Con đang ngủ" read as an observation (the dev incident) → the sleep timer item', () => {
    expect(
      check('Con đang ngủ', [
        intent('observation', { observation: 'sleep', note: 'Con đang ngủ' }),
      ]),
    ).toEqual(['sleep:start']);
  });
  it('the model found nothing → the state still gives its item; "bú xong rồi" → breast stop', () => {
    expect(check('con dậy rồi', [])).toEqual(['sleep:stop']);
    expect(check('bú xong rồi', [])).toEqual(['breast:stop']);
  });
  it('"bé ngủ 2 tiếng" read as an observation → the sleep log (its start is asked)', () => {
    expect(check('bé ngủ 2 tiếng', [intent('observation', { observation: 'sleep' })])).toEqual([
      'sleep',
    ]);
  });
  it('something different noticed stays an observation', () => {
    expect(check('dạo này con khó ngủ', [intent('observation', { observation: 'sleep' })])).toEqual(
      ['observation:sleep'],
    );
    expect(
      check('bé bú ít hơn mọi khi', [intent('observation', { observation: 'feeding' })]),
    ).toEqual(['observation:feeding']);
  });
  it('the same words again are never a correction', () => {
    const corr = { ...intent('bottle', { amountMl: 120 }), correctsPrevious: true };
    const out = checkIntents(
      { text: 'bé bú 120ml', previous: { taskId: 'tk_x', text: 'Bé bú 120ml.', drafts: [] } },
      [corr],
      [],
    );
    expect(out[0]!.correctsPrevious).toBe(false);
  });
});

describe('sleepStartQuestion: "dậy rồi" with no timer', () => {
  it('asks the start with chips by length ending at the wake time, typed answers allowed', () => {
    const q = sleepStartQuestion({ s, anchor: NIGHT }, NIGHT);
    expect(q.field).toBe('time.start');
    expect(q.allowText).toBe(true);
    expect(q.question.vi).toBe('Bé dậy lúc 01:05. Bé bắt đầu ngủ lúc mấy giờ?');
    expect(q.choices).toEqual([
      {
        id: 'at_2026-10-16_00:05',
        label: { vi: 'Khoảng 1 tiếng (từ 00:05)', en: 'About 1 h (from 00:05)' },
      },
      {
        id: 'at_2026-10-15_23:05',
        label: { vi: 'Khoảng 2 tiếng (từ 23:05 hôm qua)', en: 'About 2 h (from 23:05 yesterday)' },
      },
      {
        id: 'at_2026-10-15_22:05',
        label: { vi: 'Khoảng 3 tiếng (từ 22:05 hôm qua)', en: 'About 3 h (from 22:05 yesterday)' },
      },
    ]);
  });
});

describe('timer replies and ids', () => {
  it('TIMER_RUNNING names the timer and its start, links the timer screen', () => {
    const p = timerRunningPart(
      'sleep',
      { clock: '23:10', yesterday: true },
      'vi',
      timerLinkFor('b_1', 'sleep'),
    );
    expect(p).toEqual({
      type: 'text',
      schemaVersion: 1,
      text: 'Bé đang ngủ, đồng hồ đã tính giờ từ 23:10 hôm qua. Kết thúc giấc ngủ bây giờ, hay để đồng hồ tiếp tục?',
      code: 'TIMER_RUNNING',
      link: '/care/timer/sleep?babyId=b_1',
    });
    expect(
      (
        timerRunningPart('breast', { clock: '01:00', yesterday: false }, 'en', 'x') as {
          text: string;
        }
      ).text,
    ).toContain('feed timer is already running since 01:00');
    expect(sameAsPendingPart('vi')).toMatchObject({ code: 'SAME_AS_PENDING' });
  });
  it('one timer session per draft (32 hex, stable)', () => {
    const a = timerSessionIdForDraft('dr_' + 'a'.repeat(32) + '_0');
    expect(a).toMatch(/^[a-f0-9]{32}$/);
    expect(timerSessionIdForDraft('dr_' + 'a'.repeat(32) + '_0')).toBe(a);
    expect(timerSessionIdForDraft('dr_' + 'a'.repeat(32) + '_1')).not.toBe(a);
  });
});

describe('model v4: phase', () => {
  it('the prompt explains states vs observations (L9c: the understanding prompt only)', () => {
    expect(understandingSystemPrompt()).toContain('A plain state or log is NEVER an observation');
  });
  it('a v4 item with phase parses; a v3 item without it still parses', () => {
    const base = {
      reads: [],
      clarification: null,
      care: null,
      healthSigns: [],
      smallTalk: false,
      outOfScope: false,
    };
    expect(
      parseExtraction({ ...base, intents: [{ ...intent('sleep', { phase: 'start' }) }] }).ok,
    ).toBe(true);
    expect(parseExtraction({ ...base, intents: [intent('sleep')] }).ok).toBe(true);
    expect(
      parseExtraction({
        ...base,
        intents: [{ ...intent('sleep'), fields: { ...blank, phase: 'running' } }],
      }).ok,
    ).toBe(false);
  });
});
