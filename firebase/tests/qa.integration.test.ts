import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { qaCatalog } from '../functions/src/qa-catalog.js';
import { caseComments, handbook, update } from '../functions/src/qa.js';
import { StaffError, badges, type Staff } from '../functions/src/staff.js';

// P-132 server side against the Firestore emulator: who may read, test and manage the QA handbook,
// runs and their results, comments, cases added or edited on the portal, and that an archived run
// is read-only.
const projectId = 'demo-child-life';
const now = new Date('2026-10-11T03:00:00Z');
let app: App;
let db: Firestore;

const an: Staff = { uid: 's_an', name: 'An QA', roles: ['qa'] };
const ha: Staff = { uid: 's_ha', name: 'Hà Nguyễn', roles: ['support'] };
const minh: Staff = { uid: 's_minh', name: 'Minh Phạm', roles: ['eng'] };
const linh: Staff = { uid: 's_linh', name: 'Linh Trần', roles: ['ops'] };

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError ? e.reason : String(e);
  }
};

type Book = Awaited<ReturnType<typeof handbook>>;
const smoke = qaCatalog.find((c) => c.level === 'smoke')!;
const core = qaCatalog.find((c) => c.level === 'core')!;
const newCase = {
  module: 'care',
  title: 'Ghi tã ướt từ widget',
  level: 'core',
  platforms: ['ios'],
  account: 'Chủ hồ sơ, 1 bé',
  steps: ['Chạm "Tã" trên widget', 'Chọn "Ướt"'],
  expected: ['Hôm nay hiện lần thay tã mới, "Bạn ghi"'],
} as const;

async function newRun(by: Staff = an, name = '1.0.3 (38) DEV') {
  const out = (await update(
    db,
    by,
    { op: 'createRun', name, environment: 'dev', notes: 'iPhone 15, Pixel 8' },
    now,
  )) as { runId: string };
  return out.runId;
}

beforeAll(() => {
  app = initializeApp({ projectId }, `qa-${randomUUID()}`);
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

describe('the matrix (P-132)', () => {
  it('every staff role reads and tests; Kiểm thử, Kỹ thuật and trưởng nhóm manage', async () => {
    expect(await reason(handbook(db, null, { runId: null }))).toBe('not-staff');
    expect(
      await reason(update(db, null, { op: 'archiveRun', runId: 'r_x', archived: true }, now)),
    ).toBe('not-staff');
    for (const s of [an, ha, minh, linh]) {
      expect(await reason(handbook(db, s, { runId: null }))).toBe('ok');
    }
    expect(await reason(newRun(ha))).toBe('role');
    expect(await reason(newRun(linh))).toBe('role');
    expect(await reason(newRun(minh))).toBe('ok');
    const runId = await newRun(an);
    const set = { op: 'setResult', runId, caseId: smoke.id, status: 'passed' };
    expect(await reason(update(db, ha, set, now))).toBe('ok');
    expect(await reason(update(db, linh, { ...set, status: 'failed' }, now))).toBe('ok');
    expect(await reason(update(db, ha, { op: 'saveCase', caseId: null, ...newCase }, now))).toBe(
      'role',
    );
    expect(await reason(update(db, ha, { op: 'archiveRun', runId, archived: true }, now))).toBe(
      'role',
    );
  });

  it('Kiểm thử does not reach family dashboards', async () => {
    expect(await reason(badges(db, an))).toBe('role');
  });

  it('malformed requests are refused', async () => {
    expect(await reason(handbook(db, an, { runId: 'nope' }))).toBe('malformed');
    expect(
      await reason(
        update(db, an, { op: 'createRun', name: '', environment: 'dev', notes: '' }, now),
      ),
    ).toBe('malformed');
    expect(
      await reason(
        update(
          db,
          an,
          { op: 'saveCase', caseId: null, ...newCase, platforms: ['ios', 'ios'] },
          now,
        ),
      ),
    ).toBe('malformed');
    expect(await reason(update(db, an, { op: 'drop' }, now))).toBe('malformed');
  });
});

describe('runs, results and comments', () => {
  it('a new run is the default; results and comments carry who and when', async () => {
    const empty = await handbook(db, an, { runId: null });
    expect(empty.runId).toBeNull();
    expect(empty.cases.map((c) => c.id)).toEqual(qaCatalog.map((c) => c.id));
    expect(empty.cases.every((c) => c.builtin && !c.edited && !c.archived)).toBe(true);

    const runId = await newRun();
    await update(db, ha, { op: 'setResult', runId, caseId: smoke.id, status: 'failed' }, now);
    await update(
      db,
      ha,
      { op: 'comment', runId, caseId: smoke.id, text: 'iPhone 15, iOS 26.1 — CL-88' },
      now,
    );
    await update(
      db,
      an,
      { op: 'comment', runId, caseId: core.id, text: 'Chưa chạy được: thiếu bé thứ 2' },
      now,
    );

    const book: Book = await handbook(db, an, { runId: null });
    expect(book.runId).toBe(runId);
    expect(book.runs).toEqual([
      {
        id: runId,
        name: '1.0.3 (38) DEV',
        environment: 'dev',
        notes: 'iPhone 15, Pixel 8',
        createdBy: 'An QA',
        createdAt: now.toISOString(),
        archived: false,
      },
    ]);
    expect(book.results[smoke.id]).toEqual({
      status: 'failed',
      by: 'Hà Nguyễn',
      at: now.toISOString(),
      comments: 1,
    });
    // A comment alone leaves the case "not run".
    expect(book.results[core.id]).toMatchObject({ status: 'notRun', comments: 1 });

    const { comments } = await caseComments(db, minh, { runId, caseId: smoke.id });
    expect(comments).toEqual([
      expect.objectContaining({
        by: 'Hà Nguyễn',
        text: 'iPhone 15, iOS 26.1 — CL-88',
        at: now.toISOString(),
      }),
    ]);
    // The handbook writes no staff audit entries: it never touches family data.
    expect((await db.collection('staffAudit').count().get()).data().count).toBe(0);
  });

  it('an archived run is read-only and stops being the default', async () => {
    const old = await newRun(an, '1.0.2 (31) DEV');
    await update(db, an, { op: 'setResult', runId: old, caseId: smoke.id, status: 'passed' }, now);
    await update(db, an, { op: 'archiveRun', runId: old, archived: true }, now);
    const set = { op: 'setResult', runId: old, caseId: smoke.id, status: 'failed' };
    expect(await reason(update(db, an, set, now))).toBe('archived');
    expect(
      await reason(update(db, an, { op: 'comment', runId: old, caseId: smoke.id, text: 'x' }, now)),
    ).toBe('archived');
    expect((await handbook(db, an, { runId: null })).runId).toBeNull();
    const history = await handbook(db, an, { runId: old });
    expect(history.runId).toBe(old);
    expect(history.results[smoke.id]?.status).toBe('passed');

    const current = await newRun(an, '1.0.3 (38) DEV');
    expect((await handbook(db, an, { runId: null })).runId).toBe(current);
    // A remembered run that is gone falls back to the newest open one.
    expect((await handbook(db, an, { runId: 'r_ffffffffffffffffffff' })).runId).toBe(current);

    await update(db, an, { op: 'archiveRun', runId: old, archived: false }, now);
    expect(await reason(update(db, an, set, now))).toBe('ok');
  });

  it('unknown runs and cases are refused', async () => {
    const runId = await newRun();
    expect(
      await reason(
        update(db, an, { op: 'setResult', runId, caseId: 'ZZZ-999', status: 'passed' }, now),
      ),
    ).toBe('case');
    expect(
      await reason(
        update(
          db,
          an,
          { op: 'setResult', runId: 'r_ffffffffffffffffffff', caseId: smoke.id, status: 'passed' },
          now,
        ),
      ),
    ).toBe('run');
    expect(
      await reason(
        update(db, an, { op: 'archiveRun', runId: 'r_ffffffffffffffffffff', archived: true }, now),
      ),
    ).toBe('run');
  });
});

describe('cases written on the portal', () => {
  it('added cases get their own ids; built-in ones can be edited and archived', async () => {
    const a = (await update(db, an, { op: 'saveCase', caseId: null, ...newCase }, now)) as {
      caseId: string;
    };
    const b = (await update(
      db,
      minh,
      { op: 'saveCase', caseId: null, ...newCase, title: 'Ghi tã bẩn' },
      now,
    )) as {
      caseId: string;
    };
    expect([a.caseId, b.caseId]).toEqual(['CARE-Q01', 'CARE-Q02']);

    await update(
      db,
      an,
      { op: 'saveCase', caseId: smoke.id, ...newCase, module: smoke.module, title: 'Tên đã sửa' },
      now,
    );
    await update(db, an, { op: 'archiveCase', caseId: core.id, archived: true }, now);
    await update(
      db,
      an,
      { op: 'saveCase', caseId: 'CARE-Q01', ...newCase, title: 'Ghi tã ướt' },
      now,
    );

    const book = await handbook(db, an, { runId: null });
    const byId = new Map(book.cases.map((c) => [c.id, c]));
    expect(byId.get(smoke.id)).toMatchObject({
      title: 'Tên đã sửa',
      builtin: true,
      edited: true,
      archived: false,
      updatedBy: 'An QA',
      refs: smoke.refs ?? [],
    });
    expect(byId.get(core.id)).toMatchObject({ title: core.title, edited: false, archived: true });
    expect(byId.get('CARE-Q01')).toMatchObject({
      title: 'Ghi tã ướt',
      builtin: false,
      module: 'care',
    });
    expect(book.cases).toHaveLength(qaCatalog.length + 2);
    // Added care cases sit with the other care cases, after the built-in ones.
    const care = book.cases.filter((c) => c.module === 'care').map((c) => c.id);
    expect(care.slice(-2)).toEqual(['CARE-Q01', 'CARE-Q02']);

    // Results can be recorded on added cases too.
    const runId = await newRun();
    expect(
      await reason(
        update(db, ha, { op: 'setResult', runId, caseId: 'CARE-Q02', status: 'blocked' }, now),
      ),
    ).toBe('ok');
    expect(
      await reason(update(db, an, { op: 'saveCase', caseId: 'CARE-Q09', ...newCase }, now)),
    ).toBe('case');
    expect(
      await reason(update(db, an, { op: 'archiveCase', caseId: 'CARE-Q09', archived: true }, now)),
    ).toBe('case');
  });
});
