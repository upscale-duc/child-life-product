import { describe, expect, it } from 'vitest';
import {
  continuationCueIn,
  correctionIn,
  deleteCueIn,
  emptyDialogue,
  followUpCueIn,
  keepCueIn,
  kindWordIn,
  liveDialogue,
  metaCueIn,
  shortReplyIn,
  yesNoIn,
  type DialogueQuestion,
} from '../src/index.js';

// Lumi L7 (P-168 #2): the words a follow-up is read by, before rules or the model.

describe('follow-up words', () => {
  it('reads deletes of the last item', () => {
    for (const t of [
      'xoá cái vừa ghi',
      'Xóa cái vừa ghi nhé',
      'huỷ cái đó',
      'bỏ cữ vừa rồi',
      'xoá đi',
      'xóa giúp mình cái vừa ghi',
      'delete that',
      'undo',
    ]) {
      expect(deleteCueIn(t), t).toBe(true);
    }
    for (const t of ['bỏ bú 2 ngày nay', 'xoá tan cơn đói', 'bé bú 120ml', 'mua bỉm']) {
      expect(deleteCueIn(t), t).toBe(false);
    }
  });

  it('reads "là sao" and friends as a question about what Lumi does', () => {
    for (const t of [
      'là sao',
      'Hỏi mấy giờ xong ko ghi gì là sao',
      'sao không ghi',
      'mình gõ rồi mà',
      'what?',
      'why didn’t you log it',
    ]) {
      expect(metaCueIn(t), t).toBe(true);
    }
    for (const t of ['bé bú 120ml', 'sao bé khó ngủ thế', '13:00']) {
      expect(metaCueIn(t), t).toBe(false);
    }
  });

  it('reads "Giữ lại" and continuations', () => {
    expect(keepCueIn('Giữ lại')).toBe(true);
    expect(keepCueIn('giữ lại nhé')).toBe(true);
    expect(keepCueIn('giữ lại 2 hộp sữa')).toBe(false);
    expect(continuationCueIn('rồi ngủ lúc 10h')).toBe(true);
    expect(continuationCueIn('xong rồi bé ngủ')).toBe(true);
    expect(continuationCueIn('xong rồi')).toBe(false);
    expect(continuationCueIn('bé ngủ rồi')).toBe(false);
  });

  it('reads corrections and additions with their value', () => {
    expect(correctionIn('180 chứ')).toMatchObject({
      change: { field: 'amountMl', value: 180 },
      cue: true,
    });
    expect(correctionIn('150ml thôi')?.change).toEqual({ field: 'amountMl', value: 150 });
    expect(correctionIn('thêm 10 phút')?.change).toEqual({ field: 'addMin', value: 10 });
    expect(correctionIn('bớt 5 phút')?.change).toEqual({ field: 'addMin', value: -5 });
    expect(correctionIn('lúc 13h mới đúng')).toMatchObject({
      change: { field: 'clock', clock: { hhmm: '13:00', explicit: true }, end: false },
      cue: true,
    });
    expect(correctionIn('dậy lúc 6h mới đúng')?.change).toMatchObject({
      field: 'clock',
      end: true,
    });
    expect(correctionIn('bên trái chứ')?.change).toEqual({ field: 'side', value: 'left' });
    expect(correctionIn('bình chứ không phải mẹ')).toMatchObject({
      change: { field: 'kind', value: 'bottle' },
      kindWord: 'bottle',
    });
    expect(correctionIn('sữa công thức chứ')?.change).toEqual({ field: 'milk', value: 'formula' });
    expect(correctionIn('tã bẩn chứ')?.change).toEqual({ field: 'diaper', value: 'dirty' });
    // "phải" alone is "must" / "right": never a side without a correcting word.
    expect(correctionIn('phải')).toBeNull();
    expect(correctionIn('cảm ơn')).toBeNull();
  });

  it('a bare value counts only as a short reply without its own log words', () => {
    expect(followUpCueIn('180')).toMatchObject({ kind: 'correction' });
    expect(followUpCueIn('13:00')).toMatchObject({ kind: 'correction' });
    expect(followUpCueIn('180 chứ')).toMatchObject({ kind: 'correction' });
    // A log of its own: "bé bú 150ml" is a new feed, "dậy lúc 6h" a wake-up.
    expect(followUpCueIn('bé bú 150ml')).toBeNull();
    expect(followUpCueIn('dậy lúc 6h')).toBeNull();
    // With a correcting word the log words name the item corrected.
    expect(followUpCueIn('bú 150ml chứ')).toMatchObject({
      kind: 'correction',
      change: { field: 'amountMl', value: 150 },
    });
    // Order: meta and delete words first.
    expect(followUpCueIn('xoá cái vừa ghi')).toEqual({ kind: 'delete' });
    expect(followUpCueIn('là sao')).toEqual({ kind: 'meta' });
    expect(followUpCueIn('Giữ lại')).toEqual({ kind: 'keep' });
    expect(followUpCueIn('rồi ngủ lúc 10h')).toEqual({ kind: 'continuation' });
  });

  it('short replies, yes / no and kind words', () => {
    for (const t of ['ok', 'ừ', '180', '13:00', 'Ghi', 'không', 'đúng rồi']) {
      expect(shortReplyIn(t), t).toBe(true);
    }
    // A state of the baby is never a short reply ("bé ngủ rồi" is a log).
    expect(shortReplyIn('bé ngủ rồi')).toBe(false);
    expect(shortReplyIn('hôm nay bé bú mấy cữ')).toBe(false);
    expect(yesNoIn('Ừ')).toBe('yes');
    expect(yesNoIn('ok nhé')).toBe('yes');
    expect(yesNoIn('không')).toBe('no');
    expect(yesNoIn('13:00')).toBeNull();
    expect(kindWordIn('bình')).toBe('bottle');
    expect(kindWordIn('bú mẹ')).toBe('breast');
    expect(kindWordIn('hút sữa')).toBe('pump');
    expect(kindWordIn('lúc 13h')).toBeNull();
  });
});

describe('dialogue state', () => {
  const now = new Date('2026-10-19T07:00:00.000Z');
  it('lapses after its TTL; an expired question and old saves drop out', () => {
    const d = emptyDialogue('u1', 'cv1', now);
    expect(liveDialogue(d, now)).not.toBeNull();
    expect(liveDialogue(d, new Date(now.getTime() + 121 * 60_000))).toBeNull();
    const withItems = {
      ...d,
      question: {
        taskId: 'tk_1',
        clarificationId: 'cl_1',
        field: 'time.missing',
        choiceIds: [],
        allowText: true,
        askedAt: now.toISOString(),
        expiresAt: new Date(now.getTime() + 10 * 60_000).toISOString(),
        about: null,
      },
      saved: [
        {
          taskId: 'tk_0',
          draftId: 'dr_0',
          kind: 'bottle' as const,
          keys: {},
          recordId: 'r_0',
          savedAt: now.toISOString(),
        },
      ],
    };
    const later = liveDialogue(withItems, new Date(now.getTime() + 31 * 60_000))!;
    expect(later.question).toBeNull();
    expect(later.saved).toEqual([]);
    expect(liveDialogue(withItems, new Date(now.getTime() + 5 * 60_000))!.saved).toHaveLength(1);
  });

  it('L10 A6: a question stored with its chip labels (before L10) keeps only their ids', () => {
    const d = emptyDialogue('u1', 'cv1', now);
    const q = {
      taskId: 'tk_1',
      clarificationId: 'cl_1',
      field: 'reminder.assignee',
      chips: [{ id: 'm_1', label: { vi: 'Mẹ Lan', en: 'Mẹ Lan' } }],
      allowText: false,
      askedAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + 10 * 60_000).toISOString(),
      about: null,
    } as unknown as DialogueQuestion;
    const live = liveDialogue(
      { ...d, question: q, setAside: { ...q, at: now.toISOString() } },
      now,
    )!;
    expect(live.question?.choiceIds).toEqual(['m_1']);
    expect(JSON.stringify(live)).not.toContain('Mẹ Lan');
  });
});
