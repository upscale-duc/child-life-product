import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { bottleQuickPicksV1, referenceV1, type GrowthRow } from '@child-life/contracts';
import { referenceAct, referenceDraft, referenceView } from '../functions/src/reference-data.js';
import { StaffError, type Staff } from '../functions/src/staff.js';

// Dữ liệu tham chiếu v1.0 against the Firestore emulator (C01–C04, P-138): v1 is the shipped copy,
// drafts are validated, a different person with "Duyệt" publishes to publicConfig for the apps,
// rejection and rollback, every step logged.
const projectId = 'demo-child-life';
const now = new Date('2026-10-11T03:00:00Z');
let app: App;
let db: Firestore;

const ops: Staff = { uid: 's_ops', name: 'Hà Vũ', roles: ['ops'] };
const support: Staff = { uid: 's_sup', name: 'Thảo Lê', roles: ['support'] };
const expert: Staff = { uid: 's_exp', name: 'Mai Hồ', roles: ['expert'] };

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError ? e.reason : String(e);
  }
};

const bottleV2 = bottleQuickPicksV1.map((r, i) =>
  i === 0 ? { ...r, toDay: 14, picks: [30, 45, 60, 90] } : i === 1 ? { ...r, fromDay: 14 } : r,
);

beforeAll(() => {
  app = initializeApp({ projectId }, `reference-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
});

describe('drafts, two-person approval and publishing (C02 / C03)', () => {
  it('v1 is the shipped table; a draft is validated; someone else approves; the apps get it', async () => {
    const v1 = await referenceView(db, support, { dataset: 'bottle.quickPicks' });
    expect(v1.current).toMatchObject({
      versionId: 'builtin',
      label: 'v1',
      rows: bottleQuickPicksV1,
    });
    expect(v1.draft).toBeNull();

    const draft = (s: Staff, rows: unknown[]) =>
      referenceDraft(
        db,
        s,
        { dataset: 'bottle.quickPicks', rows, notes: 'Theo nhóm chuyên môn', source: 'edit' },
        now,
      );
    expect(await reason(draft(support, bottleV2))).toBe('role');
    expect(await reason(draft(ops, bottleQuickPicksV1))).toBe('no-change');
    expect(
      await reason(
        draft(
          ops,
          bottleV2.filter((_, i) => i !== 1),
        ),
      ),
    ).toBe('bands-gap');
    expect(
      await reason(draft(ops, [{ ...bottleV2[0], picks: [60, 45, 30, 90] }, ...bottleV2.slice(1)])),
    ).toBe('rows-invalid');
    const { versionId, diff } = await draft(ops, bottleV2);
    expect(diff).toEqual({ added: ['14'], removed: ['7'], changed: ['0'] });

    const act = (s: Staff, action: string, id = versionId) =>
      referenceAct(db, s, { versionId: id, action, reason: 'Đã rà soát với nhóm chuyên môn' }, now);
    expect(await reason(act(expert, 'approve'))).toBe('not-pending');
    await act(ops, 'submit');
    expect(await reason(act(ops, 'approve'))).toBe('role');
    expect(await act(expert, 'approve')).toEqual({ status: 'published', label: 'v2026.10' });

    const pub = (await db.doc('publicConfig/reference_bottle').get()).data()!;
    expect(pub).toMatchObject({
      dataset: 'bottle.quickPicks',
      version: 'v2026.10',
      rows: bottleV2,
    });
    const after = await referenceView(db, ops, { dataset: 'bottle.quickPicks' });
    expect(after.current).toMatchObject({ label: 'v2026.10', approver: 'Mai Hồ', rows: bottleV2 });
    expect(after.history.map((h) => [h.label, h.status])).toEqual([
      ['v2026.10', 'published'],
      ['v1', 'retired'],
    ]);

    // Rollback to the shipped copy: a new release with v1's rows.
    const v1Doc = after.history.find((h) => h.label === 'v1')!;
    expect(await act(expert, 'rollback', v1Doc.versionId)).toEqual({
      status: 'published',
      label: 'v2026.10.2',
    });
    expect((await db.doc('publicConfig/reference_bottle').get()).get('rows')).toEqual(
      bottleQuickPicksV1,
    );
    const log = await db.collection('staffAudit').where('category', '==', 'reference').get();
    expect(log.docs.map((d) => d.get('action')).sort()).toEqual([
      'reference.draft',
      'reference.publish',
      'reference.rollback',
      'reference.submit',
    ]);
  });

  it('the author never approves their own version; a rejection sends it back to draft', async () => {
    const { versionId } = await referenceDraft(
      db,
      expert,
      { dataset: 'bottle.quickPicks', rows: bottleV2, notes: '', source: 'csv' },
      now,
    );
    const act = (s: Staff, action: string) =>
      referenceAct(db, s, { versionId, action, reason: 'kiểm tra lại số liệu' }, now);
    await act(expert, 'submit');
    expect(await reason(act(expert, 'approve'))).toBe('same-person');
    await referenceAct(
      db,
      { uid: 's_adm', name: 'Linh Trần', roles: ['admin'] },
      { versionId, action: 'reject', reason: 'Thiếu nguồn' },
      now,
    );
    const v = await referenceView(db, ops, { dataset: 'bottle.quickPicks' });
    expect(v.draft).toMatchObject({
      status: 'draft',
      rejection: { by: 'Linh Trần', reason: 'Thiếu nguồn' },
    });
    await act(expert, 'discard');
    expect((await referenceView(db, ops, { dataset: 'bottle.quickPicks' })).draft).toBeNull();
  });

  it('WHO tables refuse typos beyond ±30 % of the version in use', async () => {
    const rows = referenceV1('growth.length').map((r: GrowthRow, i: number) =>
      i === 0 ? { ...r, median: r.median * 2, high: r.high * 2 } : r,
    );
    expect(
      await reason(
        referenceDraft(db, ops, { dataset: 'growth.length', rows, notes: '', source: 'csv' }, now),
      ),
    ).toBe('rows-out-of-range');
  });
});
