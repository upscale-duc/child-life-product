import { describe, expect, it } from 'vitest';
import { emptyDialogue, type DialogueState } from '@child-life/contracts';
import {
  afterAsk,
  afterSave,
  afterStop,
  afterTurn,
  applyChange,
  dialogueForModel,
  itemLabel,
  keysOf,
  questionWaitPart,
  resolveFollowUp,
  restatePart,
  setAsidePart,
} from '../src/assistant-dialogue.js';

// Lumi L7 (P-168 #1–#2, #6): the dialogue state, the resolver and the change of an item.

const zone = 'Asia/Ho_Chi_Minh';
const now = new Date('2026-10-19T06:54:00.000Z'); // 13:54 local
const at = (hhmm: string, day = '2026-10-19') => new Date(`${day}T${hhmm}:00+07:00`).toISOString();
const bottle = {
  kind: 'bottle' as const,
  amountMl: 180,
  occurredAt: at('13:00'),
  milk: 'formula' as const,
};
const question = {
  id: 'cl_1',
  field: 'time.missing',
  question: { vi: 'Việc này lúc mấy giờ?', en: 'When was this?' },
  choices: [{ id: 'ago_0', label: { vi: 'Vừa xong', en: 'Just now' } }],
  allowText: true,
};

const base = (): DialogueState => emptyDialogue('u1', 'cv1', now);
const asked = () =>
  afterTurn(base(), {
    ownerUid: 'u1',
    conversationId: 'cv1',
    taskId: 'tk_a',
    now,
    kind: 'question',
    drafts: [],
    dropped: [],
    question: {
      pc: question,
      expiresAt: new Date(now.getTime() + 30 * 60_000),
      about: { kind: 'bottle', keys: { amountMl: 180 } },
    },
    setAside: false,
  });
const waiting = () =>
  afterTurn(base(), {
    ownerUid: 'u1',
    conversationId: 'cv1',
    taskId: 'tk_a',
    now,
    kind: 'drafts',
    drafts: [{ draftId: 'dr_a_0', payload: bottle }],
    dropped: [],
    question: null,
    setAside: false,
  });
const resolve = (
  text: string,
  dialogue: DialogueState | null,
  more: Partial<Parameters<typeof resolveFollowUp>[0]> = {},
) => resolveFollowUp({ text, dialogue, ruled: false, answersQuestion: false, talk: null, ...more });

describe('dialogue state', () => {
  it('keeps the question, the drafts waiting, then the saved record, with no words', () => {
    const q = asked();
    expect(q.question).toMatchObject({ taskId: 'tk_a', field: 'time.missing', allowText: true });
    expect(q.turns.map((t) => t.kind)).toEqual(['question']);
    const w = afterTurn(q, {
      ownerUid: 'u1',
      conversationId: 'cv1',
      taskId: 'tk_a',
      now,
      kind: 'drafts',
      drafts: [{ draftId: 'dr_a_0', payload: bottle }],
      dropped: [],
      question: null,
      setAside: false,
    });
    // Answered in its own task: the question is gone, the draft waits.
    expect(w.question).toBeNull();
    expect(w.waiting).toEqual([
      expect.objectContaining({ draftId: 'dr_a_0', kind: 'bottle', keys: keysOf(bottle) }),
    ]);
    const s = afterSave(
      w,
      [{ taskId: 'tk_a', draftId: 'dr_a_0', payload: bottle, recordId: 'r_1', op: 'create' }],
      now,
    );
    expect(s.waiting).toEqual([]);
    expect(s.saved).toEqual([expect.objectContaining({ recordId: 'r_1', kind: 'bottle' })]);
    const gone = afterSave(
      s,
      [{ taskId: 'tk_b', draftId: 'dr_b_0', payload: bottle, recordId: 'r_1', op: 'delete' }],
      now,
    );
    expect(gone.saved).toEqual([]);
    // Privacy: ids, kinds, numbers, enums and instants only.
    expect(JSON.stringify(s)).not.toMatch(/Việc này|Vừa xong|note|title/u);
  });

  it('a new topic sets the question aside; "Giữ lại" (asked again) brings it back', () => {
    const q = asked();
    const next = afterTurn(q, {
      ownerUid: 'u1',
      conversationId: 'cv1',
      taskId: 'tk_b',
      now,
      kind: 'answer',
      drafts: [],
      dropped: [],
      question: null,
      setAside: true,
    });
    expect(next.question).toBeNull();
    expect(next.setAside).toMatchObject({ taskId: 'tk_a' });
    const kept = afterAsk(next, {
      ownerUid: 'u1',
      conversationId: 'cv1',
      taskId: 'tk_a',
      pc: { ...question, id: 'cl_1_1' },
      expiresAt: new Date(now.getTime() + 30 * 60_000),
      now,
    });
    expect(kept.question).toMatchObject({ taskId: 'tk_a', clarificationId: 'cl_1_1' });
    expect(kept.question?.about).toEqual({ kind: 'bottle', keys: { amountMl: 180 } });
    expect(kept.setAside).toBeNull();
    // A stopped task takes its question and drafts with it.
    expect(afterStop(kept, 'tk_a', 'canceled', now).question).toBeNull();
  });
});

describe('the resolver', () => {
  it('my open question: answers, "là sao", "ok", "huỷ"; a log of its own is a new topic', () => {
    const q = asked();
    expect(resolve('13:00', q, { answersQuestion: true }).kind).toBe('answer');
    expect(resolve('Hỏi mấy giờ xong ko ghi gì là sao', q)).toMatchObject({
      kind: 'reask',
      why: 'meta',
    });
    expect(resolve('là sao', q, { answersQuestion: true })).toMatchObject({ kind: 'reask' });
    expect(resolve('ok', q, { answersQuestion: true })).toMatchObject({
      kind: 'reask',
      why: 'short',
    });
    expect(resolve('huỷ', q).kind).toBe('cancel_question');
    expect(resolve('bé ngủ từ 9h đến 10h', q, { ruled: true, answersQuestion: false }).kind).toBe(
      'none',
    );
    expect(resolve('hôm nay bé bú mấy cữ', q).kind).toBe('none');
  });

  it('a waiting draft: corrections, additions, a delete, a short reply never a new task', () => {
    const w = waiting();
    expect(resolve('180 chứ', w)).toMatchObject({
      kind: 'correct',
      target: { saved: false, item: { draftId: 'dr_a_0' } },
      change: { field: 'amountMl', value: 180 },
    });
    expect(resolve('lúc 13h30 mới đúng', w)).toMatchObject({
      kind: 'correct',
      change: { field: 'clock' },
    });
    expect(resolve('xoá cái vừa ghi', w)).toMatchObject({
      kind: 'delete',
      target: { saved: false },
    });
    expect(resolve('ok', w, { talk: 'ack' }).kind).toBe('restate');
    expect(resolve('Ghi', w).kind).toBe('restate');
    // Thanks keeps its own reply (the waiting line is added in `startTask`).
    expect(resolve('cảm ơn', w, { talk: 'thanks' }).kind).toBe('none');
    // A feed has no minutes: "thêm 10 phút" is not about this bottle.
    expect(resolve('thêm 10 phút', w).kind).toBe('restate');
    // A new log of its own.
    expect(resolve('bé ngủ từ 9h đến 10h', w, { ruled: true }).kind).toBe('none');
    expect(resolve('rồi ngủ lúc 10h', w)).toEqual({ kind: 'continue', after: bottle.occurredAt });
  });

  it('a record saved in the last 30 min: an edit or a delete draft', () => {
    const s = afterSave(
      waiting(),
      [{ taskId: 'tk_a', draftId: 'dr_a_0', payload: bottle, recordId: 'r_1', op: 'create' }],
      now,
    );
    expect(resolve('120 chứ', s)).toMatchObject({
      kind: 'correct',
      target: { saved: true, item: { recordId: 'r_1' } },
    });
    expect(resolve('xoá cái vừa ghi', s)).toMatchObject({
      kind: 'delete',
      target: { saved: true },
    });
    expect(resolve('là sao', s).kind).toBe('restate');
    // Nothing waits: "ok" is small talk again.
    expect(resolve('ok', s, { talk: 'ack' }).kind).toBe('none');
    expect(resolve('ok', null).kind).toBe('none');
  });
});

describe('a change applied to an item', () => {
  const x = { zone, anchor: now };
  it('amounts, sides, milk, the diaper', () => {
    expect(applyChange(bottle, { field: 'amountMl', value: 120 }, x)).toMatchObject({
      amountMl: 120,
    });
    expect(applyChange(bottle, { field: 'side', value: 'left' }, x)).toBeNull();
    expect(applyChange(bottle, { field: 'milk', value: 'breast_milk' }, x)).toMatchObject({
      milk: 'breast_milk',
    });
    expect(
      applyChange(
        { kind: 'diaper', diaper: 'wet', occurredAt: at('13:00') },
        { field: 'diaper', value: 'both' },
        x,
      ),
    ).toMatchObject({ diaper: 'both' });
  });

  it('times keep the day and never move into the future', () => {
    const clock = (hhmm: string, explicit = true) => ({
      field: 'clock' as const,
      clock: { hhmm, explicit, dayOffset: null },
      end: false,
    });
    expect(applyChange(bottle, clock('13:30'), x)).toMatchObject({ occurredAt: at('13:30') });
    // "lúc 1h" for a feed at 13:00: 13:00, not 01:00.
    expect(applyChange(bottle, clock('01:00', false), x)).toMatchObject({
      occurredAt: at('13:00'),
    });
    // 15:00 today is still ahead at 13:54: yesterday's.
    expect(applyChange(bottle, clock('15:00'), x)).toMatchObject({
      occurredAt: at('15:00', '2026-10-18'),
    });
  });

  it('lengths: a feed gets minutes, a sleep moves its end and keeps its length', () => {
    const breast = {
      kind: 'breast' as const,
      occurredAt: at('13:00'),
      durationMin: 15,
      side: 'left' as const,
    };
    expect(applyChange(breast, { field: 'addMin', value: 10 }, x)).toMatchObject({
      durationMin: 25,
    });
    expect(applyChange(breast, { field: 'addMin', value: -20 }, x)).toBeNull();
    const sleep = {
      kind: 'sleep' as const,
      startedAt: at('11:00'),
      endedAt: at('12:00'),
      durationMin: 60,
    };
    expect(applyChange(sleep, { field: 'addMin', value: 10 }, x)).toMatchObject({
      endedAt: at('12:10'),
      durationMin: 70,
    });
    expect(
      applyChange(
        sleep,
        { field: 'clock', clock: { hhmm: '12:30', explicit: true, dayOffset: null }, end: true },
        x,
      ),
    ).toMatchObject({ endedAt: at('12:30'), durationMin: 90 });
    // An end past now is never written.
    expect(applyChange(sleep, { field: 'addMin', value: 180 }, x)).toBeNull();
  });
});

describe('words', () => {
  it('names the item and says what waits', () => {
    expect(itemLabel('bottle', keysOf(bottle), zone, 'vi', now)).toBe('cữ bú bình 180ml lúc 13:00');
    expect(itemLabel('bottle', keysOf(bottle), zone, 'en', now)).toBe(
      'bottle feed 180 ml at 13:00',
    );
    const q = asked().question!;
    expect(questionWaitPart(q, zone, 'vi', now, 'meta')).toMatchObject({
      code: 'FOLLOW_UP',
      text: expect.stringContaining('Mình đang chờ giờ của cữ bú bình 180ml'),
    });
    expect(setAsidePart(q, zone, 'vi', now)).toMatchObject({
      code: 'QUESTION_SET_ASIDE',
      text: 'Mình bỏ câu hỏi về cữ bú bình 180ml nhé.',
    });
    expect(restatePart(waiting(), zone, 'vi', now)).toMatchObject({
      code: 'FOLLOW_UP',
      text: expect.stringContaining('Mình đang chờ bạn lưu cữ bú bình 180ml lúc 13:00 ở trên'),
    });
    expect(restatePart(base(), zone, 'vi', now)).toBeNull();
  });

  it('the model sees kinds, values and local times — never words, ids or names', () => {
    const view = dialogueForModel(
      asked(),
      {
        taskId: 'tk_a',
        text: 'Bé Na bú bình 180ml',
        drafts: [
          {
            id: 'dr_a_0',
            taskId: 'tk_a',
            state: 'draft',
            payload: bottle,
            recordLink: null,
          },
          {
            id: 'dr_a_1',
            taskId: 'tk_a',
            state: 'saved',
            payload: {
              kind: 'expense',
              merchant: 'Con Cưng',
              totalMinor: 500000,
              currency: 'VND',
              date: '2026-10-19',
              subtotalMinor: null,
              taxMinor: null,
              categoryId: 'c_milk',
              babyId: 'b1',
              keepReceipt: false,
              note: 'sữa cho Na',
            },
            recordLink: '/x',
          },
        ],
      },
      zone,
      '2026-10-19',
      now,
    )!;
    expect(view.text).toBeNull();
    expect(view.drafts[0]).toEqual({
      kind: 'bottle',
      saved: false,
      amountMl: 180,
      occurredAt: { time: '13:00', dayOffset: 0 },
      milk: 'formula',
    });
    expect(view.question).toEqual({ field: 'time.missing', about: 'bottle feed 180 ml' });
    expect(JSON.stringify(view)).not.toMatch(/Na|Con Cưng|dr_|tk_|b1/u);
  });
});
