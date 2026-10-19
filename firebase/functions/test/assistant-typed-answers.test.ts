import { careStatesIn } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import type { ModelIntent } from '../src/assistant-model.js';
import { reaskPart } from '../src/assistant-talk.js';
import { ampmQuestion, checkIntents, readTypedAnswer } from '../src/assistant-text.js';
import { clarificationFor } from '../src/assistant-tools.js';

// L1 (D-088, P-167 #3): any words answer the open question; unreadable ones ask it again. The
// planner's readings (timer from 11:21, no morning / evening question) run in the e2e harness
// (`firebase/tests/assistant-e2e/cases/16-care-ongoing-l1.json`).

describe('readTypedAnswer', () => {
  const ampm = ampmQuestion(['11:21']);

  it('the morning / evening question takes typed words', () => {
    expect(ampm.allowText).toBe(true);
    expect(clarificationFor('time.ampm', 'cl_1').allowText).toBe(true);
    expect(readTypedAnswer(ampm, 'Sáng. Hiện tại thì biết sáng hay tối chứ')).toEqual({
      choiceId: 'am',
    });
    expect(readTypedAnswer(ampm, 'tối')).toEqual({ choiceId: 'pm' });
    expect(readTypedAnswer(ampm, '23:21')).toEqual({ choiceId: 'pm' });
    // Trưa / đêm depend on the hour: kept as text, read per time by the planner.
    expect(readTypedAnswer(ampm, 'trưa')).toEqual({ choiceId: null });
    expect(readTypedAnswer(ampm, 'đêm')).toEqual({ choiceId: null });
  });

  it('words that say no half of the day are unreadable (asked again)', () => {
    expect(readTypedAnswer(ampm, 'hả?')).toBe('unreadable');
    expect(readTypedAnswer(ampm, '11:21')).toBe('unreadable');
  });

  it('a chip question reads the one chip the words name', () => {
    const when = clarificationFor('sleep.when', 'cl_1');
    expect(readTypedAnswer(when, 'giấc đêm')).toEqual({ choiceId: 'night' });
    expect(readTypedAnswer(when, 'Giấc ngày ạ')).toEqual({ choiceId: 'day' });
    expect(readTypedAnswer(when, 'chua ro')).toEqual({ choiceId: 'unsure' });
    // "giấc" alone names two chips.
    expect(readTypedAnswer(when, 'giấc')).toBe('unreadable');
    expect(readTypedAnswer(when, 'x')).toBe('unreadable');
    const period = clarificationFor('sleep.period', 'cl_1');
    expect(readTypedAnswer(period, 'bé khó vào giấc lắm')).toEqual({ choiceId: 'falling_asleep' });
    expect(readTypedAnswer(period, 'cả hai')).toEqual({ choiceId: 'both' });
    const intent = clarificationFor('intent', 'cl_1');
    expect(readTypedAnswer(intent, 'ghi thêm')).toEqual({ choiceId: 'write' });
  });

  it('a question with a free answer keeps the text as it is', () => {
    const missing = clarificationFor('time.missing', 'cl_1');
    expect(readTypedAnswer(missing, '8h sáng')).toEqual({ choiceId: null });
  });
});

describe('reaskPart: the question again instead of the help text', () => {
  it('names the open question in the task locale', () => {
    const q = ampmQuestion(['11:21']);
    expect(reaskPart(q, 'vi')).toMatchObject({
      type: 'text',
      text: 'Bạn trả lời giúp mình câu hỏi ở trên trước nhé: 11:21 là buổi sáng hay chiều tối?',
    });
    expect(reaskPart(q, 'en')).toMatchObject({
      text: 'Could you answer the question above first: Was 11:21 in the morning or the evening?',
    });
  });
});

describe('checkIntents: a state still going on (L1)', () => {
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
  it('"Bé đang ngủ. Vừa ngủ được 5p rồi" with nothing from the model → a sleep start item', () => {
    const text = 'Bé đang ngủ. Vừa ngủ được 5p rồi';
    const out = checkIntents({ text, previous: null }, [], careStatesIn(text));
    expect(out.map((i) => `${i.kind}:${i.fields.phase}`)).toEqual(['sleep:start']);
  });
  it('the model read it as a 5-minute observation → the sleep start item', () => {
    const text = 'Đang ngủ và ngủ cách đây 5p';
    const obs: ModelIntent = {
      kind: 'observation',
      fields: { ...blank, observation: 'sleep' },
      evidence: [],
      uncertainFields: [],
      missingFields: [],
      correctsPrevious: false,
    };
    const out = checkIntents({ text, previous: null }, [obs], careStatesIn(text));
    expect(out.map((i) => `${i.kind}:${i.fields.phase ?? ''}`)).toEqual(['sleep:start']);
  });
});
