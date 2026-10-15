import { describe, expect, it } from 'vitest';
import {
  babyMilestoneSchema,
  milestoneIdSchema,
  milestonePublishProblems,
  milestoneSeedSchema,
  milestoneState,
  milestoneWindow,
  parseBabyMilestone,
  publishedFromSeed,
  referenceIdOfRecord,
  referenceMilestoneDraftSchema,
  referenceMilestoneSchema,
  referenceRecordId,
} from '../src/index.js';
import seed from '../../../content/milestones/milestones.seed.json' with { type: 'json' };

/**
 * Mốc phát triển (D-076 #6): the reference milestone contract the portal publishes, the baby's
 * records (one collection with Kỷ niệm's family milestones, R-105) and the age windows.
 */
const author = { name: 'Mai', relation: 'mother', relationCustom: null };
const legacy = {
  id: `ms_${'a'.repeat(32)}`,
  babyId: 'b1',
  name: 'Lần đầu về quê',
  date: '2026-10-04',
  createdBy: 'u_mai',
  author,
};

describe('baby milestone records', () => {
  it('reads a Kỷ niệm / MS01 milestone (legacy shape) as a custom, observed one', () => {
    const m = parseBabyMilestone(legacy);
    expect(m).toMatchObject({
      kind: 'custom',
      status: 'observed',
      referenceId: null,
      note: null,
      memoryIds: [],
      source: 'memories',
      updatedBy: 'u_mai',
    });
  });

  it('keys a reference observation by p_<referenceId>, which Kỷ niệm tags accept', () => {
    expect(referenceRecordId('social_smile')).toBe('p_social_smile');
    expect(referenceIdOfRecord('p_social_smile')).toBe('social_smile');
    expect(referenceIdOfRecord(legacy.id)).toBeNull();
    expect(milestoneIdSchema.safeParse(referenceRecordId('lifts_head')).success).toBe(true);
    const ok = babyMilestoneSchema.safeParse({
      ...legacy,
      id: 'p_lifts_head',
      kind: 'reference',
      referenceId: 'lifts_head',
      status: 'observed',
      note: 'Sau cữ bú sáng',
      memoryIds: [`mem_${'b'.repeat(32)}`],
      source: 'milestones',
      updatedBy: 'u_mai',
    });
    expect(ok.success).toBe(true);
    const wrongId = babyMilestoneSchema.safeParse({ ...ok.data, id: 'p_rolls_over' });
    expect(wrongId.success).toBe(false);
  });

  it('dates observed records only; only reference milestones are followed', () => {
    const base = {
      ...legacy,
      id: 'p_lifts_head',
      kind: 'reference',
      referenceId: 'lifts_head',
      note: null,
      memoryIds: [],
      source: 'milestones',
      updatedBy: 'u_mai',
    };
    expect(
      babyMilestoneSchema.safeParse({ ...base, status: 'following', date: null }).success,
    ).toBe(true);
    expect(babyMilestoneSchema.safeParse({ ...base, status: 'following' }).success).toBe(false);
    expect(babyMilestoneSchema.safeParse({ ...base, status: 'observed', date: null }).success).toBe(
      false,
    );
    expect(
      babyMilestoneSchema.safeParse({
        ...legacy,
        kind: 'custom',
        referenceId: null,
        status: 'following',
        date: null,
        note: null,
        memoryIds: [],
        source: 'milestones',
        updatedBy: 'u_mai',
      }).success,
    ).toBe(false);
  });

  it('caps the name at Kỷ niệm’s 60 characters and the note at 500', () => {
    expect(parseBabyMilestone({ ...legacy, name: 'x'.repeat(61) })).toBeNull();
    expect(parseBabyMilestone({ ...legacy, note: 'x'.repeat(501) })).toBeNull();
    expect(parseBabyMilestone({ ...legacy, note: 'x'.repeat(500) })).not.toBeNull();
    expect(parseBabyMilestone({ id: 'nope' })).toBeNull();
  });
});

describe('windows and states (never "late")', () => {
  it('counts months by monthly birthdays and weeks by whole weeks', () => {
    expect(milestoneWindow('2026-09-17', { unit: 'months', from: 1, to: 3 })).toEqual({
      start: '2026-10-17',
      end: '2027-01-16',
    });
    expect(milestoneWindow('2026-01-31', { unit: 'months', from: 1, to: 1 })).toEqual({
      start: '2026-02-28',
      end: '2026-03-30',
    });
    expect(milestoneWindow('2026-09-17', { unit: 'weeks', from: 4, to: 6 })).toEqual({
      start: '2026-10-15',
      end: '2026-11-04',
    });
  });

  it('is seen, following, around now, upcoming or simply not recorded', () => {
    const w = { start: '2026-10-17', end: '2027-01-16' };
    expect(milestoneState({ status: 'observed' }, w, '2026-10-08')).toBe('seen');
    expect(milestoneState({ status: 'following' }, w, '2026-10-08')).toBe('following');
    expect(milestoneState(null, w, '2026-10-08')).toBe('upcoming');
    expect(milestoneState(null, w, '2026-11-01')).toBe('now');
    expect(milestoneState(null, w, '2026-08-01')).toBe('notRecorded');
    // After the window: still only "chưa ghi".
    expect(milestoneState(null, w, '2027-06-01')).toBe('notRecorded');
  });
});

describe('reference milestones (portal B07 / B08)', () => {
  const item = seed.milestones[0]!;

  it('publishes a seed item as an illustrative engineering draft', () => {
    const doc = publishedFromSeed(item as never, '2026-10-15T08:00:00.000Z');
    expect(doc.status).toBe('published');
    expect(doc.review).toBeNull();
    expect(doc.illustrative).toBe(true);
    expect(doc.reviewDueOn).toBe('2027-10-15');
    expect(milestonePublishProblems(doc, { requireReview: false })).toEqual([]);
    expect(milestonePublishProblems(doc, { requireReview: true })).toEqual(['REVIEW_REQUIRED']);
  });

  it('lifts the label only with a review, and refuses markup', () => {
    const doc = publishedFromSeed(item as never, '2026-10-15T08:00:00.000Z');
    expect(referenceMilestoneSchema.safeParse({ ...doc, illustrative: false }).success).toBe(false);
    expect(
      referenceMilestoneSchema.safeParse({
        ...doc,
        illustrative: false,
        review: { reviewer: 'Thu Hà', credential: 'Nhóm chuyên môn', reviewedOn: '2026-10-20' },
      }).success,
    ).toBe(true);
    expect(
      referenceMilestoneSchema.safeParse({
        ...doc,
        title: { vi: '<b>x</b>', en: 'x' },
      }).success,
    ).toBe(false);
  });

  it('accepts drafts with empty texts but not unknown fields', () => {
    const content: Record<string, unknown> = { ...item };
    delete content.id;
    const empty = { ...content, title: { vi: '', en: '' }, sources: [] };
    expect(referenceMilestoneDraftSchema.safeParse(empty).success).toBe(true);
    expect(referenceMilestoneDraftSchema.safeParse({ ...empty, extra: 1 }).success).toBe(false);
  });
});

describe('milestone seed (content/milestones, D-073 #2 engineering draft)', () => {
  const parsed = milestoneSeedSchema.parse(seed);
  const ms = parsed.milestones;
  const lower = (s: string) => s.toLowerCase();

  it('covers 0–24 months in all four groups, in both languages', () => {
    expect(ms.length).toBeGreaterThanOrEqual(40);
    for (const g of ['motor', 'communication', 'cognitive', 'socialEmotional'] as const) {
      expect(ms.filter((m) => m.group === g).length, g).toBeGreaterThanOrEqual(8);
    }
    const months = (m: (typeof ms)[number]) =>
      m.ageRange.unit === 'months' ? m.ageRange.from : m.ageRange.from / 4.35;
    expect(Math.min(...ms.map(months))).toBe(0);
    expect(Math.max(...ms.map((m) => (m.ageRange.unit === 'months' ? m.ageRange.to : 0)))).toBe(24);
  });

  it('keeps the design’s items and the Kỷ niệm preset ids that mean the same thing', () => {
    const ids = new Set(ms.map((m) => m.id));
    for (const id of [
      'first_smile',
      'lifts_head',
      'coos',
      'recognises_voices',
      'follows_faces',
      'laughs',
      'rolls_over',
      'sits_up',
      'crawls',
      'stands',
      'first_steps',
      'first_word',
    ]) {
      expect(ids.has(id), id).toBe(true);
    }
    const smile = ms.find((m) => m.id === 'first_smile')!;
    expect(smile.title.vi).toBe('Mỉm cười đáp lại');
    expect(smile.group).toBe('communication');
    expect(smile.ageRange).toEqual({ unit: 'months', from: 1, to: 3 });
  });

  it('cites sources and never diagnoses or judges', () => {
    const banned = [
      'chậm phát triển',
      'bất thường',
      'tự kỷ',
      'rối loạn',
      'chẩn đoán',
      'phải đạt',
      'bình thường',
    ];
    const bannedEn = ['delay', 'abnormal', 'autism', 'disorder', 'diagnos', 'must ', 'normal'];
    for (const m of ms) {
      expect(m.sources.length, m.id).toBeGreaterThan(0);
      const vi = [m.title.vi, m.howToRecognise.vi, m.talkToDoctor?.vi ?? ''].map(lower).join(' ');
      const en = [m.title.en, m.howToRecognise.en, m.talkToDoctor?.en ?? ''].map(lower).join(' ');
      for (const w of banned) expect(vi, `${m.id}: ${w}`).not.toContain(w);
      for (const w of bannedEn) expect(en, `${m.id}: ${w}`).not.toContain(w);
    }
  });

  it('has unique orders and stays sorted by age within each group', () => {
    const orders = ms.map((m) => m.order);
    expect(new Set(orders).size).toBe(orders.length);
  });
});
