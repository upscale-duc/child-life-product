import { randomBytes } from 'node:crypto';
import {
  qaCaseRefSchema,
  qaHandbookSchema,
  qaModulePrefix,
  qaModules,
  qaUpdateSchema,
  type QaCaseContent,
  type QaStatus,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { qaCatalog } from './qa-catalog.js';
import { StaffError, parse, requireStaff, type Staff } from './staff.js';

/**
 * The QA handbook's server (P-132): the built-in catalog merged with the cases staff added or
 * edited (`qaCases/{caseId}`), test runs (`qaRuns/{runId}`), one result per case per run
 * (`qaRuns/{runId}/results/{caseId}`) and comments under each result. Nothing here reads family
 * data; results and comments carry the staff member's name and time instead of an audit entry.
 */

const iso = (v: unknown) =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;

const builtins = new Map(qaCatalog.map((c) => [c.id, c]));

function seedContent(id: string): QaCaseContent | null {
  const seed = builtins.get(id);
  if (!seed) return null;
  const { module, title, level, platforms, account, steps, expected } = seed;
  return { module, title, level, platforms: [...platforms], account, steps: [...steps], expected };
}

/** The built-in cases (repo order, or the portal edit) and then the added ones, by module. */
function mergeCases(docs: Map<string, DocumentData>) {
  const view = (id: string, content: QaCaseContent, doc: DocumentData | undefined) => ({
    id,
    ...content,
    refs: builtins.get(id)?.refs ?? [],
    builtin: builtins.has(id),
    edited: builtins.has(id) && !!doc?.content,
    archived: doc?.archived === true,
    updatedBy: (doc?.updatedByName as string | undefined) ?? null,
    updatedAt: iso(doc?.updatedAt),
  });
  const out = qaCatalog.map((seed) => {
    const doc = docs.get(seed.id);
    return view(seed.id, (doc?.content as QaCaseContent | undefined) ?? seedContent(seed.id)!, doc);
  });
  const added = [...docs.entries()]
    .filter(([id, doc]) => !builtins.has(id) && doc.content)
    .sort(([a], [b]) => a.localeCompare(b, 'en', { numeric: true }))
    .map(([id, doc]) => view(id, doc.content as QaCaseContent, doc));
  const order = (m: string) => qaModules.indexOf(m as (typeof qaModules)[number]);
  return [...out, ...added]
    .map((c, i) => ({ c, i }))
    .sort((a, b) => order(a.c.module) - order(b.c.module) || a.i - b.i)
    .map(({ c }) => c);
}

function runView(id: string, d: DocumentData) {
  return {
    id,
    name: d.name as string,
    environment: d.environment as string,
    notes: (d.notes as string | undefined) ?? '',
    createdBy: d.createdByName as string,
    createdAt: iso(d.createdAt)!,
    archived: d.archived === true,
  };
}

/** `staffQa`: every case, the runs (newest first) and one run's results. */
export async function handbook(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'qa.view');
  const { runId } = parse(qaHandbookSchema, data);
  const [caseSnap, runSnap] = await Promise.all([
    db.collection('qaCases').get(),
    db.collection('qaRuns').orderBy('createdAt', 'desc').limit(200).get(),
  ]);
  const cases = mergeCases(new Map(caseSnap.docs.map((d) => [d.id, d.data()])));
  const runs = runSnap.docs.map((d) => runView(d.id, d.data()));
  // A remembered run that no longer exists falls back to the newest open one.
  const run = runs.find((r) => r.id === runId) ?? runs.find((r) => !r.archived) ?? null;
  const results: Record<
    string,
    { status: QaStatus; by: string | null; at: string | null; comments: number }
  > = {};
  if (run) {
    const snap = await db.collection(`qaRuns/${run.id}/results`).get();
    for (const d of snap.docs) {
      results[d.id] = {
        status: (d.get('status') as QaStatus | undefined) ?? 'notRun',
        by: (d.get('byName') as string | undefined) ?? null,
        at: iso(d.get('at')),
        comments: (d.get('comments') as number | undefined) ?? 0,
      };
    }
  }
  return { cases, runs, runId: run?.id ?? null, results };
}

/** `staffQaCase`: the comments on one case in one run, oldest first. */
export async function caseComments(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'qa.view');
  const { runId, caseId } = parse(qaCaseRefSchema, data);
  const snap = await db
    .collection(`qaRuns/${runId}/results/${caseId}/comments`)
    .orderBy('at')
    .limit(200)
    .get();
  return {
    comments: snap.docs.map((d) => ({
      id: d.id,
      by: d.get('byName') as string,
      text: d.get('text') as string,
      at: iso(d.get('at'))!,
    })),
  };
}

async function caseExists(db: Firestore, caseId: string, tx: FirebaseFirestore.Transaction) {
  if (builtins.has(caseId)) return true;
  const doc = await tx.get(db.doc(`qaCases/${caseId}`));
  return doc.exists && !!doc.get('content');
}

/** `staffQaUpdate`: runs, results, comments and cases. */
export async function update(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  const req = parse(qaUpdateSchema, data);
  const by = { byUid: staff.uid, byName: staff.name };

  switch (req.op) {
    case 'createRun': {
      requireStaff(staff, 'qa.manage');
      const runId = `r_${randomBytes(10).toString('hex')}`;
      await db.doc(`qaRuns/${runId}`).create({
        name: req.name,
        environment: req.environment,
        notes: req.notes,
        createdByUid: staff.uid,
        createdByName: staff.name,
        createdAt: now,
        archived: false,
      });
      return { runId };
    }

    case 'archiveRun': {
      requireStaff(staff, 'qa.manage');
      const ref = db.doc(`qaRuns/${req.runId}`);
      await db.runTransaction(async (tx) => {
        if (!(await tx.get(ref)).exists) throw new StaffError('not-found', 'run');
        tx.update(ref, {
          archived: req.archived,
          archivedAt: req.archived ? now : null,
          archivedByName: req.archived ? staff.name : null,
        });
      });
      return {};
    }

    case 'setResult':
    case 'comment': {
      requireStaff(staff, 'qa.test');
      const runRef = db.doc(`qaRuns/${req.runId}`);
      const resultRef = runRef.collection('results').doc(req.caseId);
      await db.runTransaction(async (tx) => {
        const run = await tx.get(runRef);
        if (!run.exists) throw new StaffError('not-found', 'run');
        // An archived run is the record of a past build: read-only.
        if (run.get('archived') === true) throw new StaffError('failed-precondition', 'archived');
        if (!(await caseExists(db, req.caseId, tx))) throw new StaffError('not-found', 'case');
        if (req.op === 'setResult') {
          tx.set(resultRef, { status: req.status, ...by, at: now }, { merge: true });
        } else {
          tx.create(resultRef.collection('comments').doc(), { text: req.text, ...by, at: now });
          tx.set(resultRef, { comments: FieldValue.increment(1) }, { merge: true });
        }
      });
      return {};
    }

    case 'saveCase': {
      requireStaff(staff, 'qa.manage');
      const { caseId, module, title, level, platforms, account, steps, expected } = req;
      const content: QaCaseContent = { module, title, level, platforms, account, steps, expected };
      return db.runTransaction(async (tx) => {
        if (caseId) {
          const ref = db.doc(`qaCases/${caseId}`);
          const doc = await tx.get(ref);
          if (!builtins.has(caseId) && !doc.get('content')) {
            throw new StaffError('not-found', 'case');
          }
          tx.set(
            ref,
            {
              builtin: builtins.has(caseId),
              content,
              archived: doc.get('archived') === true,
              updatedByName: staff.name,
              updatedAt: now,
            },
            { merge: true },
          );
          return { caseId };
        }
        // Added cases read "CARE-Q01", so they never collide with built-in ids added later.
        const prefix = `${qaModulePrefix[content.module]}-Q`;
        const added = await tx.get(db.collection('qaCases').where('builtin', '==', false));
        const taken = added.docs
          .filter((d) => d.id.startsWith(prefix))
          .map((d) => Number(d.id.slice(prefix.length)));
        const next = Math.max(0, ...taken) + 1;
        if (next > 999) throw new StaffError('failed-precondition', 'too-many');
        const id = `${prefix}${String(next).padStart(2, '0')}`;
        tx.create(db.doc(`qaCases/${id}`), {
          builtin: false,
          content,
          archived: false,
          createdByName: staff.name,
          createdAt: now,
          updatedByName: staff.name,
          updatedAt: now,
        });
        return { caseId: id };
      });
    }

    case 'archiveCase': {
      requireStaff(staff, 'qa.manage');
      const ref = db.doc(`qaCases/${req.caseId}`);
      await db.runTransaction(async (tx) => {
        if (!(await caseExists(db, req.caseId, tx))) throw new StaffError('not-found', 'case');
        tx.set(
          ref,
          {
            builtin: builtins.has(req.caseId),
            archived: req.archived,
            updatedByName: staff.name,
            updatedAt: now,
          },
          { merge: true },
        );
      });
      return {};
    }
  }
}
