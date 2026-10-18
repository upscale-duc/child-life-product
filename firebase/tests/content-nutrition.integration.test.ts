import { randomUUID } from 'node:crypto';
import {
  contentNutrientSchema,
  contentNutritionRuleSchema,
  contentNutritionStageSchema,
  editorialChecks,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  contentAct,
  contentItem,
  contentList,
  contentSave,
  contentSeed,
  type ContentLibraryDeps,
} from '../functions/src/content-library.js';
import {
  seedNutrients,
  seedNutritionRules,
  seedNutritionStages,
} from '../functions/src/nutrition-seed.js';
import type { Staff } from '../functions/src/staff.js';
import {
  nutrientFixture,
  ruleFixture,
  stageFixture,
} from '../functions/test/nutrition-fixtures.js';

// Dinh dưỡng theo giai đoạn (D-083, P-163; plan §3, §5) on the editorial workflow against the
// Firestore emulator: save → submit → approve → publish for the three kinds, the `unsafe-copy`
// and `stage-overlap` gates, nutrient links, the D01–D04 lists and coverage, the review queue and
// the expert seed. Its own project.
const projectId = 'demo-child-life-content-nutrition';
let app: App;
let db: Firestore;
const now = new Date('2026-10-18T03:00:00Z');

const ops: Staff = { uid: 's_ops', name: 'Hà Vũ', roles: ['ops'] };
const expert: Staff = { uid: 's_expert', name: 'BS. Lan', roles: ['expert'] };
const support: Staff = { uid: 's_support', name: 'Mai', roles: ['support'] };

const deps = (requireReview = false): ContentLibraryDeps => ({
  requireReview,
  images: {
    exists: async () => false,
    save: async () => undefined,
    list: async () => [],
    publicUrl: (i) => `https://img.test/${i}`,
    encode: async (bytes) => Buffer.from(bytes),
  },
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const checks = [...editorialChecks];
type Kind = 'nutritionStage' | 'nutrient' | 'nutritionRule';

async function save(kind: Kind, data: unknown, id: string | null = null, by: Staff = ops) {
  const r = await contentSave(
    db,
    deps(),
    by,
    { kind, id, data, reviewerLabel: 'BS. Hà · Dinh dưỡng', notes: '' },
    now,
  );
  return r.id;
}
const act = (by: Staff, kind: Kind, id: string, action: string, extra = {}) =>
  contentAct(db, deps(), by, { kind, id, action, reason: '', ...extra }, now);
const approveIt = async (kind: Kind, id: string) => {
  await act(ops, kind, id, 'submit');
  return act(expert, kind, id, 'approve', { checks });
};
const publishIt = async (kind: Kind, id: string) => {
  await approveIt(kind, id);
  return act(expert, kind, id, 'publish');
};
/** A stage over [from, to) months, straight to the app. */
const liveStage = async (from: number, to: number) => {
  const id = await save('nutritionStage', stageFixture(from, to));
  await publishIt('nutritionStage', id);
  return id;
};

beforeAll(() => {
  app = initializeApp({ projectId }, `content-nutrition-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of [
    'contentDrafts',
    'contentNutritionStages',
    'contentNutrients',
    'contentNutritionRules',
    'staffAudit',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc('config/content').delete();
});

describe('workflow', () => {
  it('a stage goes Nháp → Gửi duyệt → Duyệt → Xuất bản to contentNutritionStages', async () => {
    const nut = await save('nutrient', nutrientFixture());
    expect(nut).toMatch(/^nut_[a-f0-9]{8}$/);
    const id = await save('nutritionStage', stageFixture(6, 9, [nut]));
    expect(id).toMatch(/^nst_[a-f0-9]{8}$/);
    // Two people (D-058) as for every kind.
    await act(ops, 'nutritionStage', id, 'submit');
    expect(
      await reason(act({ ...expert, uid: ops.uid }, 'nutritionStage', id, 'approve', { checks })),
    ).toBe('same-person');
    await act(expert, 'nutritionStage', id, 'approve', { checks });
    expect((await db.doc(`contentNutritionStages/${id}`).get()).exists).toBe(false);
    expect(await act(expert, 'nutritionStage', id, 'publish')).toEqual({
      status: 'published',
      revision: 1,
    });
    const pub = contentNutritionStageSchema.parse(
      (await db.doc(`contentNutritionStages/${id}`).get()).data(),
    );
    expect(pub).toMatchObject({
      id,
      status: 'published',
      revision: 1,
      illustrative: true,
      ageMonths: { from: 6, to: 9 },
      nutrientIds: [nut],
    });
    const item = await contentItem(db, support, { kind: 'nutritionStage', id }, now);
    expect(item.row).toMatchObject({
      kind: 'nutritionStage',
      status: 'published',
      title: { vi: 'Bắt đầu ăn dặm', en: 'Starting solids' },
      ageMonths: { from: 6, to: 9 },
      live: { revision: 1 },
    });
    // Taken off the app with a reason.
    await act(expert, 'nutritionStage', id, 'unpublish', { reason: 'Đang sửa lớn' });
    expect((await db.doc(`contentNutritionStages/${id}`).get()).exists).toBe(false);
  });

  it('micronutrients and rules publish to their own collections; prod needs the review', async () => {
    const nut = await save('nutrient', nutrientFixture(true));
    await publishIt('nutrient', nut);
    const n = contentNutrientSchema.parse((await db.doc(`contentNutrients/${nut}`).get()).data());
    expect(n.campaign?.rounds).toHaveLength(2);

    const rule = await save('nutritionRule', ruleFixture());
    await act(ops, 'nutritionRule', rule, 'submit');
    const prod = (action: string, extra = {}) =>
      contentAct(
        db,
        deps(true),
        expert,
        { kind: 'nutritionRule', id: rule, action, reason: '', ...extra },
        now,
      );
    expect(await reason(prod('approve', { checks }))).toBe('review-required');
    const review = { reviewer: 'BS. Thu Hà', credential: 'Nhi khoa', reviewedOn: '2026-10-17' };
    await prod('approve', { checks, review });
    await prod('publish');
    const r = contentNutritionRuleSchema.parse(
      (await db.doc(`contentNutritionRules/${rule}`).get()).data(),
    );
    expect(r).toMatchObject({ illustrative: false, review, metric: 'weight' });
  });

  it('incomplete drafts save but cannot be submitted; a condition outside its metric never saves', async () => {
    const half = { ...ruleFixture(), banner: { vi: 'Nhắc cân lại', en: '' } };
    const id = await save('nutritionRule', half);
    expect(await reason(act(ops, 'nutritionRule', id, 'submit'))).toBe('invalid-content');
    expect(
      await reason(save('nutritionRule', { ...ruleFixture(), condition: 'noMeasurement' })),
    ).toBe('malformed');
    // Ids belong to their kind.
    expect(await reason(save('nutrient', nutrientFixture(), 'nst_wrong_kind'))).toBe('malformed');
  });
});

describe('unsafe-copy (P-163 #16)', () => {
  it('a dose or a condition word blocks Gửi duyệt; sources may cite anything', async () => {
    const dosed = stageFixture();
    dosed.summary.vi = 'Bé cần 50 mg sắt mỗi ngày.';
    const a = await save('nutritionStage', dosed);
    expect(await reason(act(ops, 'nutritionStage', a, 'submit'))).toBe('unsafe-copy');
    expect((await db.doc(`contentDrafts/${a}`).get()).get('status')).toBe('draft');

    const worded = ruleFixture();
    worded.tips[0]!.body.vi = 'Nếu bé béo phì, giảm sữa.';
    const b = await save('nutritionRule', worded);
    expect(await reason(act(ops, 'nutritionRule', b, 'submit'))).toBe('unsafe-copy');

    const nutrient = nutrientFixture();
    nutrient.foods.push({ vi: 'Viên 10 mcg', en: '10 mcg tablet' });
    const c = await save('nutrient', nutrient);
    expect(await reason(act(ops, 'nutrient', c, 'submit'))).toBe('unsafe-copy');

    const cited = nutrientFixture();
    cited.sources = [{ label: 'AAP: vitamin D 400 IU', url: 'https://www.aap.org/' }];
    const d = await save('nutrient', cited);
    expect(await reason(act(ops, 'nutrient', d, 'submit'))).toBe('ok');
  });

  it('Duyệt and Xuất bản check again (a draft changed outside the portal)', async () => {
    const id = await save('nutrient', nutrientFixture());
    await act(ops, 'nutrient', id, 'submit');
    await db.doc(`contentDrafts/${id}`).update({ 'data.why.en': 'Prevents malnutrition.' });
    expect(await reason(act(expert, 'nutrient', id, 'approve', { checks }))).toBe('unsafe-copy');
    await db.doc(`contentDrafts/${id}`).update({ 'data.why.en': 'Helps blood.' });
    await act(expert, 'nutrient', id, 'approve', { checks });
    await db.doc(`contentDrafts/${id}`).update({ 'data.why.vi': 'Uống 2 mg mỗi ngày.' });
    expect(await reason(act(expert, 'nutrient', id, 'publish'))).toBe('unsafe-copy');
    expect((await db.doc(`contentNutrients/${id}`).get()).exists).toBe(false);
  });
});

describe('stage-overlap (P-163 #17)', () => {
  it('Duyệt refuses a range sharing a month with a live or an approved stage', async () => {
    await liveStage(6, 9);
    const b = await save('nutritionStage', stageFixture(8, 12));
    expect(await reason(approveIt('nutritionStage', b))).toBe('stage-overlap');
    expect((await db.doc(`contentDrafts/${b}`).get()).get('status')).toBe('in_review');
    // Adjacent ranges (to exclusive) are fine; an approved one blocks too.
    const c = await save('nutritionStage', stageFixture(9, 12));
    await approveIt('nutritionStage', c);
    const d = await save('nutritionStage', stageFixture(10, 12));
    expect(await reason(approveIt('nutritionStage', d))).toBe('stage-overlap');
    // In review or draft stages do not block.
    const e = await save('nutritionStage', stageFixture(12, 24));
    await act(ops, 'nutritionStage', e, 'submit');
    const f = await save('nutritionStage', stageFixture(12, 24));
    expect(await reason(approveIt('nutritionStage', f))).toBe('ok');
  });

  it('Xuất bản refuses too, and a stage never overlaps itself across revisions', async () => {
    const a = await save('nutritionStage', stageFixture(12, 24));
    await approveIt('nutritionStage', a);
    // Approved before the check (or by a race): publishing checks again, both ways.
    const b = await save('nutritionStage', stageFixture(20, 37));
    await db.doc(`contentDrafts/${b}`).update({ status: 'approved', approverUid: expert.uid });
    expect(await reason(act(expert, 'nutritionStage', b, 'publish'))).toBe('stage-overlap');
    expect(await reason(act(expert, 'nutritionStage', a, 'publish'))).toBe('stage-overlap');
    await act(expert, 'nutritionStage', b, 'reject', { reason: 'Trùng 20–23 tháng' });
    await act(expert, 'nutritionStage', a, 'publish');
    // Editing the live stage: its own live range does not count against it.
    await save('nutritionStage', stageFixture(12, 20), a);
    expect(await reason(publishIt('nutritionStage', a))).toBe('ok');
    expect((await db.doc(`contentNutritionStages/${a}`).get()).get('ageMonths')).toEqual({
      from: 12,
      to: 20,
    });
    // b now fits after the live range moved.
    expect(await reason(publishIt('nutritionStage', b))).toBe('ok');
  });

  it('unpublishing a stage frees its months', async () => {
    const a = await liveStage(0, 6);
    const b = await save('nutritionStage', stageFixture(0, 4));
    await act(ops, 'nutritionStage', b, 'submit');
    expect(await reason(act(expert, 'nutritionStage', b, 'approve', { checks }))).toBe(
      'stage-overlap',
    );
    await act(expert, 'nutritionStage', a, 'unpublish', { reason: 'Chia nhỏ giai đoạn' });
    expect(await reason(act(expert, 'nutritionStage', b, 'approve', { checks }))).toBe('ok');
  });
});

describe('nutrient links', () => {
  it('a stage cannot be submitted with a micronutrient that does not exist or was archived', async () => {
    const missing = await save('nutritionStage', stageFixture(6, 9, ['nut_missing_one']));
    expect(await reason(act(ops, 'nutritionStage', missing, 'submit'))).toBe('link-missing');
    const nut = await save('nutrient', nutrientFixture());
    await act(ops, 'nutrient', nut, 'archive');
    const archived = await save('nutritionStage', stageFixture(6, 9, [nut]));
    expect(await reason(act(ops, 'nutritionStage', archived, 'submit'))).toBe('link-missing');
    // A micronutrient on the app counts even without a draft (e.g. imported elsewhere).
    await db.doc('contentNutrients/nut_published_only').set({ status: 'published' });
    const pub = await save('nutritionStage', stageFixture(6, 9, ['nut_published_only']));
    expect(await reason(act(ops, 'nutritionStage', pub, 'submit'))).toBe('ok');
  });
});

type ListOut = {
  rows: Array<Record<string, unknown> & { id: string; kind: string; title: { vi: string } }>;
  counts: Record<string, unknown>;
  coverage?: Record<string, unknown>;
};

describe('lists, coverage and the queue', () => {
  it('D01 rows and the 0–36 month strip; D03 and D04 rows', async () => {
    const nut = await save('nutrient', nutrientFixture(true));
    const live = await liveStage(0, 6);
    await save('nutritionStage', stageFixture(6, 9, [nut]));
    const rule = await save('nutritionRule', ruleFixture());

    const stages = (await contentList(
      db,
      deps(),
      support,
      { view: 'nutritionStage' },
      now,
    )) as unknown as ListOut;
    expect(stages.counts).toMatchObject({ inApp: 1, drafts: 1, total: 2 });
    expect(stages.rows.find((r) => r.id === live)).toMatchObject({
      ageMonths: { from: 0, to: 6 },
      ageLabel: { from: 0, to: 5 },
      milk: { perDayMl: { min: 600, max: 900 } },
      solidsMeals: { vi: '2–3 bữa' },
      nutrientIds: [],
      live: { revision: 1 },
    });
    expect(stages.coverage).toMatchObject({
      total: 37,
      covered: 9,
      published: 6,
      gaps: [{ from: 9, to: 37 }],
      liveGaps: [{ from: 6, to: 37 }],
      overlaps: [],
    });
    expect((stages.coverage!.months as unknown[])[7]).toMatchObject({ state: 'draft' });

    const nutrients = (await contentList(
      db,
      deps(),
      support,
      { view: 'nutrient' },
      now,
    )) as unknown as ListOut;
    expect(nutrients.coverage).toBeUndefined();
    expect(nutrients.rows[0]).toMatchObject({
      id: nut,
      title: { vi: 'Vitamin A', en: 'Vitamin A' },
      key: 'vitaminA',
      foods: expect.arrayContaining([expect.objectContaining({ vi: expect.any(String) })]),
      hasCampaign: true,
    });

    const rules = (await contentList(
      db,
      deps(),
      support,
      { view: 'nutritionRule' },
      now,
    )) as unknown as ListOut;
    expect(rules.rows[0]).toMatchObject({
      id: rule,
      title: { vi: 'Hai lần cân gần nhất của bé thấp hơn khoảng chuẩn WHO.' },
      metric: 'weight',
      condition: 'belowRange',
      ageMonths: { from: 0, to: 37 },
      remindAfterDays: 14,
    });
  });

  it('the review queue lists nutrition items and counts them per kind', async () => {
    const nut = await save('nutrient', nutrientFixture());
    const stage = await save('nutritionStage', stageFixture(6, 9, [nut]));
    const rule = await save('nutritionRule', ruleFixture());
    await act(ops, 'nutrient', nut, 'submit');
    await act(ops, 'nutritionStage', stage, 'submit');
    await approveIt('nutritionRule', rule);
    const q = (await contentList(db, deps(), expert, { view: 'queue' }, now)) as unknown as {
      rows: Array<{ id: string; kind: string; status: string }>;
      counts: Record<string, { inReview: number; approved: number }>;
      available: string[];
    };
    expect(q.rows.map((r) => r.kind).sort()).toEqual([
      'nutrient',
      'nutritionRule',
      'nutritionStage',
    ]);
    expect(q.counts.nutrient).toMatchObject({ inReview: 1 });
    expect(q.counts.nutritionStage).toMatchObject({ inReview: 1 });
    expect(q.counts.nutritionRule).toMatchObject({ approved: 1 });
    expect(q.available).toEqual(
      expect.arrayContaining(['nutritionStage', 'nutrient', 'nutritionRule']),
    );
  });

  it('imports the expert drafts once, as Nháp, and audits without content text', async () => {
    const kinds = ['nutritionStage', 'nutrient', 'nutritionRule'] as const;
    const sizes = {
      nutritionStage: seedNutritionStages.length,
      nutrient: seedNutrients.length,
      nutritionRule: seedNutritionRules.length,
    };
    const added = Object.fromEntries(Object.entries(sizes).filter(([, n]) => n > 0));
    const total = Object.values(sizes).reduce((a, b) => a + b, 0);
    expect(await contentSeed(db, ops, { kinds: [...kinds] }, now)).toEqual({ added, skipped: 0 });
    expect(await contentSeed(db, ops, { kinds: [...kinds] }, now)).toEqual({
      added: {},
      skipped: total,
    });
    const draftsNow = await db.collection('contentDrafts').get();
    expect(draftsNow.size).toBe(total);
    expect(draftsNow.docs.every((d) => d.get('status') === 'draft')).toBe(true);

    const id = await save('nutritionRule', ruleFixture());
    await publishIt('nutritionRule', id);
    const audit = await db.collection('staffAudit').get();
    expect(audit.docs.map((d) => d.get('action') as string)).toEqual(
      expect.arrayContaining([
        'content.nutritionRule.save',
        'content.nutritionRule.submit',
        'content.nutritionRule.approve',
        'content.nutritionRule.publish',
      ]),
    );
    expect(JSON.stringify(audit.docs.map((d) => d.data()))).not.toContain('Hai lần cân');
  });
});
