import { randomBytes } from 'node:crypto';
import {
  diffRows,
  localDateIn,
  referenceActSchema,
  referenceDocIds,
  referenceDraftSchema,
  referenceRowsSchemas,
  referenceV1,
  referenceViewSchema,
  rowKey,
  type GrowthRow,
  type ReferenceDataset,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Dữ liệu tham chiếu (Figma C01–C04, P-138). One open version per dataset (Nháp or Chờ duyệt);
 * a different person with "Duyệt" approves, and approval publishes it to
 * `publicConfig/reference_*` for the apps (which validate it and keep their own copy as the
 * fallback). Until the first approval the version in use is v1, the copy the app shipped.
 * Rollback re-publishes an earlier version. Every step needs a reason and is logged.
 */

const ZONE = 'Asia/Ho_Chi_Minh';
const BUILTIN = 'builtin';
const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;
const isoOrNull = (v: unknown) => (ms(v) ? new Date(ms(v)).toISOString() : null);

const datasetRef = (db: Firestore, dataset: ReferenceDataset) => db.doc(`referenceData/${dataset}`);
const versions = (db: Firestore, dataset: ReferenceDataset) =>
  datasetRef(db, dataset).collection('versions');

/** Checks the schema plus what a schema cannot: unique rows, bands that join, sane changes. */
export function validateRows(
  dataset: ReferenceDataset,
  rows: unknown[],
  current: unknown[],
): unknown[] {
  const parsed = referenceRowsSchemas[dataset].safeParse(rows);
  if (!parsed.success) throw new StaffError('invalid-argument', 'rows-invalid');
  const out = parsed.data as unknown[];
  const keys = out.map((r) => rowKey(dataset, r));
  if (new Set(keys).size !== keys.length)
    throw new StaffError('invalid-argument', 'rows-duplicate');
  if (dataset === 'bottle.quickPicks') {
    const bands = [...(out as Array<{ fromDay: number; toDay: number | null }>)].sort(
      (a, b) => a.fromDay - b.fromDay,
    );
    if (bands[0]!.fromDay !== 0) throw new StaffError('invalid-argument', 'bands-gap');
    for (let i = 1; i < bands.length; i++) {
      if (bands[i - 1]!.toDay !== bands[i]!.fromDay)
        throw new StaffError('invalid-argument', 'bands-gap');
    }
    if (bands[bands.length - 1]!.toDay !== null)
      throw new StaffError('invalid-argument', 'bands-open');
  }
  if (dataset === 'growth.weight' || dataset === 'growth.length') {
    // A WHO table moves little between releases: more than ±30 % on a row is a typo.
    const before = new Map((current as GrowthRow[]).map((r) => [rowKey(dataset, r), r]));
    for (const r of out as GrowthRow[]) {
      const b = before.get(rowKey(dataset, r));
      if (b && Math.abs(r.median - b.median) / b.median > 0.3) {
        throw new StaffError('invalid-argument', 'rows-out-of-range');
      }
    }
  }
  return out;
}

function versionView(d: DocumentSnapshot) {
  return {
    versionId: d.id,
    label: (d.get('label') as string | null) ?? null,
    status: d.get('status') as string,
    notes: (d.get('notes') as string | undefined) ?? '',
    source: d.get('source') as string,
    author: d.get('authorName') as string,
    authorUid: d.get('authorUid') as string,
    approver: (d.get('approverName') as string | null) ?? null,
    createdAt: isoOrNull(d.get('createdAt')),
    updatedAt: isoOrNull(d.get('updatedAt')),
    publishedAt: isoOrNull(d.get('publishedAt')),
    rejection: (d.get('rejection') as { by: string; reason: string } | null) ?? null,
  };
}

async function current(db: Firestore, dataset: ReferenceDataset) {
  const ds = await datasetRef(db, dataset).get();
  const id = ds.get('currentVersionId') as string | undefined;
  if (!id) {
    return {
      versionId: BUILTIN,
      label: 'v1',
      rows: referenceV1(dataset) as unknown[],
      publishedAt: null,
      approver: null,
    };
  }
  const v = await versions(db, dataset).doc(id).get();
  return {
    versionId: id,
    label: v.get('label') as string,
    rows: v.get('rows') as unknown[],
    publishedAt: isoOrNull(v.get('publishedAt')),
    approver: (v.get('approverName') as string | null) ?? null,
  };
}

async function openVersion(db: Firestore, dataset: ReferenceDataset) {
  const snap = await versions(db, dataset)
    .where('status', 'in', ['draft', 'pending'])
    .limit(1)
    .get();
  return snap.docs[0] ?? null;
}

/** `staffReference`: the version in use, the open draft with its diff, and the history. */
export async function referenceView(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'reference.view');
  const { dataset } = parse(referenceViewSchema, data);
  const [cur, open, history] = await Promise.all([
    current(db, dataset),
    openVersion(db, dataset),
    versions(db, dataset).orderBy('createdAt', 'desc').limit(20).get(),
  ]);
  return {
    dataset,
    current: cur,
    draft: open
      ? {
          ...versionView(open),
          rows: open.get('rows') as unknown[],
          diff: diffRows(dataset, cur.rows, open.get('rows') as unknown[]),
        }
      : null,
    history: history.docs.map(versionView),
  };
}

/** Save the open draft (or start one): rows from the editor or from a CSV import (C03). */
export async function referenceDraft(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'reference.edit');
  const req = parse(referenceDraftSchema, data);
  const cur = await current(db, req.dataset);
  const rows = validateRows(req.dataset, req.rows, cur.rows);
  const diff = diffRows(req.dataset, cur.rows, rows);
  if (!diff.added.length && !diff.removed.length && !diff.changed.length) {
    throw new StaffError('failed-precondition', 'no-change');
  }
  return db.runTransaction(async (tx) => {
    const open = await tx.get(
      versions(db, req.dataset).where('status', 'in', ['draft', 'pending']).limit(1),
    );
    const ref =
      open.docs[0]?.ref ?? versions(db, req.dataset).doc(`rv_${randomBytes(8).toString('hex')}`);
    if (open.docs[0]) {
      // Editing a version under review withdraws it: the reviewer must see what they approve.
      tx.update(ref, {
        rows,
        notes: req.notes,
        source: req.source,
        status: 'draft',
        updatedAt: now,
        rejection: null,
      });
    } else {
      tx.create(ref, {
        dataset: req.dataset,
        status: 'draft',
        rows,
        notes: req.notes,
        source: req.source,
        baseVersionId: cur.versionId,
        authorUid: s.uid,
        authorName: s.name,
        createdAt: now,
        updatedAt: now,
        label: null,
        rejection: null,
      });
    }
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'reference.draft',
        category: 'reference',
        target: req.dataset,
        reason: null,
        detail: {
          added: diff.added.length,
          changed: diff.changed.length,
          removed: diff.removed.length,
          source: req.source,
        },
      },
      now,
    );
    return { versionId: ref.id, diff };
  });
}

/** "v2026.10", then "v2026.10.2" for a second release in the same month. */
async function nextLabel(db: Firestore, dataset: ReferenceDataset, now: Date) {
  const month = `v${localDateIn(ZONE, now).slice(0, 7).replace('-', '.')}`;
  const same = await versions(db, dataset)
    .where('label', '>=', month)
    .where('label', '<=', `${month}.99`)
    .get();
  return same.empty ? month : `${month}.${same.size + 1}`;
}

/** Gửi duyệt · Duyệt & xuất bản · Trả lại · Huỷ nháp · Dùng lại bản này (rollback). */
export async function referenceAct(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  const req = parse(referenceActSchema, data);
  // Version ids are unique across datasets; find which dataset holds it.
  let dataset: ReferenceDataset | null = null;
  let snap: DocumentSnapshot | null = null;
  for (const d of Object.keys(referenceDocIds) as ReferenceDataset[]) {
    const v = await versions(db, d).doc(req.versionId).get();
    if (v.exists) {
      dataset = d;
      snap = v;
      break;
    }
  }
  if (!dataset || !snap) throw new StaffError('not-found', 'not-found');
  const status = snap.get('status') as string;
  const author = snap.get('authorUid') as string;
  const ref = snap.ref;

  switch (req.action) {
    case 'submit': {
      const s = requireStaff(staff, 'reference.edit');
      if (status !== 'draft') throw new StaffError('failed-precondition', 'not-draft');
      await db.runTransaction(async (tx) => {
        tx.update(ref, {
          status: 'pending',
          submittedAt: now,
          submittedByName: s.name,
          updatedAt: now,
        });
        staffAudit(
          tx,
          db,
          s,
          {
            action: 'reference.submit',
            category: 'reference',
            target: dataset,
            reason: req.reason,
          },
          now,
        );
      });
      return { status: 'pending' };
    }
    case 'discard': {
      const s = requireStaff(staff, 'reference.edit');
      if (status !== 'draft') throw new StaffError('failed-precondition', 'not-draft');
      await db.runTransaction(async (tx) => {
        tx.update(ref, { status: 'discarded', updatedAt: now });
        staffAudit(
          tx,
          db,
          s,
          {
            action: 'reference.discard',
            category: 'reference',
            target: dataset,
            reason: req.reason,
          },
          now,
        );
      });
      return { status: 'discarded' };
    }
    case 'reject': {
      const s = requireStaff(staff, 'reference.approve');
      if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
      await db.runTransaction(async (tx) => {
        tx.update(ref, {
          status: 'draft',
          rejection: { by: s.name, reason: req.reason },
          updatedAt: now,
        });
        staffAudit(
          tx,
          db,
          s,
          {
            action: 'reference.reject',
            category: 'reference',
            target: dataset,
            reason: req.reason,
          },
          now,
        );
      });
      return { status: 'draft' };
    }
    case 'approve':
    case 'rollback': {
      const s = requireStaff(staff, 'reference.approve');
      if (req.action === 'approve') {
        if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
        // Two people: whoever wrote the version cannot approve it (P-138, P-139).
        if (author === s.uid) throw new StaffError('failed-precondition', 'same-person');
      } else if (status !== 'retired') {
        throw new StaffError('failed-precondition', 'not-retired');
      }
      const cur = await current(db, dataset);
      const rows = snap.get('rows') as unknown[];
      const label = await nextLabel(db, dataset, now);
      const target =
        req.action === 'approve'
          ? ref
          : versions(db, dataset).doc(`rv_${randomBytes(8).toString('hex')}`);
      await db.runTransaction(async (tx) => {
        if (req.action === 'approve') {
          tx.update(ref, {
            status: 'published',
            label,
            approverUid: s.uid,
            approverName: s.name,
            publishedAt: now,
            updatedAt: now,
          });
        } else {
          tx.create(target, {
            dataset,
            status: 'published',
            rows,
            notes: `Dùng lại ${snap.get('label') as string}`,
            source: 'rollback',
            baseVersionId: cur.versionId,
            authorUid: s.uid,
            authorName: s.name,
            approverUid: s.uid,
            approverName: s.name,
            createdAt: now,
            updatedAt: now,
            publishedAt: now,
            label,
            rejection: null,
          });
        }
        if (cur.versionId !== BUILTIN) {
          tx.update(versions(db, dataset).doc(cur.versionId), {
            status: 'retired',
            updatedAt: now,
          });
        } else {
          // The first release keeps the shipped copy in the history, so it can be used again.
          tx.create(versions(db, dataset).doc(`rv_${randomBytes(8).toString('hex')}`), {
            dataset,
            status: 'retired',
            rows: cur.rows,
            notes: 'Bản gói trong app',
            source: 'builtin',
            baseVersionId: null,
            authorUid: 'app',
            authorName: 'Child Life',
            approverUid: null,
            approverName: null,
            createdAt: new Date(now.getTime() - 1),
            updatedAt: now,
            publishedAt: null,
            label: 'v1',
            rejection: null,
          });
        }
        tx.set(datasetRef(db, dataset), {
          currentVersionId: target.id,
          currentLabel: label,
          publishedAt: now,
        });
        tx.set(db.doc(`publicConfig/${referenceDocIds[dataset]}`), {
          dataset,
          version: label,
          publishedAt: now.toISOString(),
          rows,
        });
        const diff = diffRows(dataset, cur.rows, rows);
        staffAudit(
          tx,
          db,
          s,
          {
            action: req.action === 'approve' ? 'reference.publish' : 'reference.rollback',
            category: 'reference',
            target: `${dataset} ${label}`,
            reason: req.reason,
            detail: {
              from: cur.label,
              added: diff.added.length,
              changed: diff.changed.length,
              removed: diff.removed.length,
            },
          },
          now,
        );
      });
      return { status: 'published', label };
    }
  }
}
