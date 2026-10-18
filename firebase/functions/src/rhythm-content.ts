import { randomBytes } from 'node:crypto';
import {
  defaultRhythmRules,
  localDateIn,
  referenceModelSchema,
  rhythmActSchema,
  rhythmConfigSchema,
  rhythmContentSchema,
  rhythmDocs,
  rhythmDraftSchema,
  rhythmPublicDocIds,
  setRhythmRulesSchema,
  type RhythmDoc,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';
import { mayApproveOwn, readContentPolicy, reviewRequired } from './content-policy.js';

/**
 * Nhịp lớn lên content on the portal (PN01–PN04, D-073 #2), the Sơ cứu workflow (`content.ts`):
 * one open version (Nháp or Chờ duyệt) per document under `content/rhythm/{doc}`; a different
 * person with "Nội dung · Duyệt" approves, and approval publishes `publicConfig/rhythm_reference`
 * (`ref_YYYYMMDD_NN`) or `publicConfig/content_rhythm` (`rc_YYYYMMDD_NN`) in the same transaction.
 * On prod the approver records the qualified review; on dev items may still be `review: null`
 * ("Nội dung minh hoạ · chờ chuyên môn duyệt"). Rules (`config/rhythm`, PN04) are versioned
 * thresholds edited by Tính năng · Sửa. Every step is in the audit log.
 */

export interface RhythmContentDeps {
  /** Prod: approving needs the qualified review recorded. */
  requireReview: boolean;
}

const ZONE = 'Asia/Ho_Chi_Minh';
const root = (db: Firestore) => db.doc('content/rhythm');
const versions = (db: Firestore, doc: RhythmDoc) => root(db).collection(doc);
const publicDoc = (db: Firestore, doc: RhythmDoc) =>
  db.doc(`publicConfig/${rhythmPublicDocIds[doc]}`);
const labelPrefix: Record<RhythmDoc, string> = { reference: 'ref', content: 'rc' };
const iso = (v: unknown) =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;
const newVersionId = () => `rv_${randomBytes(8).toString('hex')}`;

type Review = { reviewer: string; credential: string; reviewedOn: string } | null;
type Data = Record<string, unknown>;

/** A short count for lists and the audit (never content text). */
function sizeOf(doc: RhythmDoc, data: Data | undefined) {
  if (!data) return {};
  return doc === 'reference'
    ? { stages: (data.stages as unknown[] | undefined)?.length ?? 0 }
    : {
        activities: (data.activities as unknown[] | undefined)?.length ?? 0,
        ageCards: (data.ageCards as unknown[] | undefined)?.length ?? 0,
      };
}

function versionView(doc: RhythmDoc, d: DocumentSnapshot) {
  return {
    versionId: d.id,
    status: d.get('status') as string,
    label: (d.get('label') as string | null | undefined) ?? null,
    notes: (d.get('notes') as string | undefined) ?? '',
    authorName: (d.get('authorName') as string | undefined) ?? '',
    approverName: (d.get('approverName') as string | null | undefined) ?? null,
    createdAt: iso(d.get('createdAt')),
    updatedAt: iso(d.get('updatedAt')),
    approvedAt: iso(d.get('approvedAt')),
    rejection: (d.get('rejection') as { by: string; reason: string } | null | undefined) ?? null,
    review: (d.get('review') as Review | undefined) ?? null,
    ...sizeOf(doc, d.get('data') as Data | undefined),
  };
}

async function openVersion(db: Firestore, doc: RhythmDoc) {
  const snap = await versions(db, doc).where('status', 'in', ['draft', 'pending']).limit(1).get();
  return snap.docs[0] ?? null;
}

/** What the portal's Nhịp lớn lên screens show: per document, in use, the open version, history. */
export async function rhythmView(db: Firestore, deps: RhythmContentDeps, staff: Staff | null) {
  requireStaff(staff, 'content.view');
  const out: Record<string, unknown> = {};
  for (const doc of rhythmDocs) {
    const [pub, open, history] = await Promise.all([
      publicDoc(db, doc).get(),
      openVersion(db, doc),
      versions(db, doc).orderBy('createdAt', 'desc').limit(20).get(),
    ]);
    out[doc] = {
      current: pub.exists ? pub.data() : null,
      draft: open ? { ...versionView(doc, open), data: open.get('data') as Data } : null,
      history: history.docs.map((d) => versionView(doc, d)),
    };
  }
  return { ...out, requireReview: reviewRequired(deps.requireReview, await readContentPolicy(db)) };
}

/** Save the open draft of one document (editing a version under review withdraws it). */
export async function rhythmDraft(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(rhythmDraftSchema, data);
  return db.runTransaction(async (tx) => {
    const open = await tx.get(
      versions(db, req.doc).where('status', 'in', ['draft', 'pending']).limit(1),
    );
    const ref = open.docs[0]?.ref ?? versions(db, req.doc).doc(newVersionId());
    if (open.docs[0]) {
      // The reviewer must see what they approve.
      tx.update(ref, {
        data: req.data,
        notes: req.notes,
        status: 'draft',
        rejection: null,
        updatedAt: now,
      });
    } else {
      tx.create(ref, {
        doc: req.doc,
        status: 'draft',
        data: req.data,
        notes: req.notes,
        authorUid: s.uid,
        authorName: s.name,
        createdAt: now,
        updatedAt: now,
        label: null,
        review: null,
        rejection: null,
      });
    }
    staffAudit(
      tx,
      db,
      s,
      {
        action: `content.rhythm.${req.doc}.draft`,
        category: 'content',
        target: `rhythm.${req.doc}`,
        reason: null,
        detail: sizeOf(req.doc, req.data as Data),
      },
      now,
    );
    return { versionId: ref.id };
  });
}

/** "ref_20261015_01", then _02 for a second release the same day. */
async function nextLabel(db: Firestore, doc: RhythmDoc, now: Date) {
  const day = localDateIn(ZONE, now).replace(/-/g, '');
  const prefix = `${labelPrefix[doc]}_${day}_`;
  const last = (await publicDoc(db, doc).get()).get('version') as string | undefined;
  const n = last?.startsWith(prefix) ? Number(last.slice(-2)) + 1 : 1;
  return `${prefix}${String(n).padStart(2, '0')}`;
}

/**
 * The published document: the approver's review is recorded on the reference model, and on
 * content items that have none yet (the reviewer signed off the whole pack). Validated against
 * the app's schema before it is written.
 */
function published(doc: RhythmDoc, data: Data, review: Review, version: string, at: string) {
  const withReview = <T extends { review?: Review }>(item: T): T =>
    review && !item.review ? { ...item, review } : item;
  if (doc === 'reference') {
    return referenceModelSchema.parse({
      ...data,
      review: review ?? data.review ?? null,
      version,
      publishedAt: at,
    });
  }
  return rhythmContentSchema.parse({
    ...data,
    activities: ((data.activities as Data[] | undefined) ?? []).map(withReview),
    ageCards: ((data.ageCards as Data[] | undefined) ?? []).map(withReview),
    health: data.health ? withReview(data.health as Data) : data.health,
    // Recipes (assistant slice A5) follow the same sign-off when the pack carries them.
    ...(Array.isArray(data.recipes) ? { recipes: (data.recipes as Data[]).map(withReview) } : {}),
    version,
    publishedAt: at,
  });
}

/** Gửi duyệt · Duyệt & xuất bản · Trả lại · Huỷ nháp · Dùng lại bản này (rollback). */
export async function rhythmAct(
  db: Firestore,
  deps: RhythmContentDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  const req = parse(rhythmActSchema, data);
  const snap = await versions(db, req.doc).doc(req.versionId).get();
  if (!snap.exists) throw new StaffError('not-found', 'not-found');
  const status = snap.get('status') as string;
  const ref = snap.ref;
  const audit = (s: Staff, action: string, tx: FirebaseFirestore.Transaction) =>
    staffAudit(
      tx,
      db,
      s,
      {
        action: `content.rhythm.${req.doc}.${action}`,
        category: 'content',
        target: `rhythm.${req.doc}`,
        reason: req.reason,
      },
      now,
    );

  switch (req.action) {
    case 'submit': {
      const s = requireStaff(staff, 'content.edit');
      if (status !== 'draft') throw new StaffError('failed-precondition', 'not-draft');
      await db.runTransaction(async (tx) => {
        tx.update(ref, {
          status: 'pending',
          submittedAt: now,
          submittedByName: s.name,
          updatedAt: now,
        });
        audit(s, 'submit', tx);
      });
      return { status: 'pending' };
    }
    case 'discard': {
      const s = requireStaff(staff, 'content.edit');
      if (status !== 'draft') throw new StaffError('failed-precondition', 'not-draft');
      await db.runTransaction(async (tx) => {
        tx.update(ref, { status: 'discarded', updatedAt: now });
        audit(s, 'discard', tx);
      });
      return { status: 'discarded' };
    }
    case 'reject': {
      const s = requireStaff(staff, 'content.approve');
      if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
      await db.runTransaction(async (tx) => {
        tx.update(ref, {
          status: 'draft',
          rejection: { by: s.name, reason: req.reason },
          updatedAt: now,
        });
        audit(s, 'reject', tx);
      });
      return { status: 'draft' };
    }
    case 'approve':
    case 'rollback': {
      const s = requireStaff(staff, 'content.approve');
      const policy = await readContentPolicy(db);
      if (req.action === 'approve') {
        if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
        // Two people: whoever wrote the version cannot approve it (D-058, D-073 #2), unless the
        // Owner may approve their own (D-079).
        if (snap.get('authorUid') === s.uid && !mayApproveOwn(s, policy)) {
          throw new StaffError('failed-precondition', 'same-person');
        }
      } else if (status !== 'retired' && status !== 'published') {
        throw new StaffError('failed-precondition', 'not-retired');
      }
      const review: Review = req.review ?? (snap.get('review') as Review | undefined) ?? null;
      if (reviewRequired(deps.requireReview, policy) && !review) {
        throw new StaffError('failed-precondition', 'review-required');
      }
      const label = await nextLabel(db, req.doc, now);
      let doc: Data;
      try {
        doc = published(req.doc, snap.get('data') as Data, review, label, now.toISOString());
      } catch {
        throw new StaffError('failed-precondition', 'invalid-content');
      }
      const previous = await versions(db, req.doc).where('status', '==', 'published').get();
      const target = req.action === 'approve' ? ref : versions(db, req.doc).doc(newVersionId());
      await db.runTransaction(async (tx) => {
        for (const p of previous.docs) {
          if (p.id !== target.id) tx.update(p.ref, { status: 'retired', updatedAt: now });
        }
        const fields = {
          status: 'published',
          label,
          review,
          approverUid: s.uid,
          approverName: s.name,
          approvedAt: now,
          updatedAt: now,
        };
        if (req.action === 'approve') {
          tx.update(ref, fields);
        } else {
          tx.create(target, {
            ...fields,
            doc: req.doc,
            data: snap.get('data') as Data,
            notes: `Dùng lại ${snap.get('label') as string}`,
            authorUid: s.uid,
            authorName: s.name,
            createdAt: now,
            rejection: null,
          });
        }
        tx.set(publicDoc(db, req.doc), doc);
        tx.set(root(db), { current: { [req.doc]: target.id }, updatedAt: now }, { merge: true });
        audit(s, req.action, tx);
      });
      return { status: 'published', version: label };
    }
  }
}

/** PN04: the thresholds in use (stored or the contract default). */
export async function rhythmRulesView(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'features.view');
  const snap = await db.doc('config/rhythm').get();
  const parsed = rhythmConfigSchema.safeParse(snap.data());
  return {
    rules: parsed.success ? parsed.data.rules : defaultRhythmRules,
    stored: parsed.success,
    updatedAt: iso(snap.get('updatedAt')),
    updatedByName: (snap.get('updatedByName') as string | undefined) ?? null,
  };
}

/** PN04 "Lưu quy tắc": versioned thresholds with a reason (Tính năng · Sửa). */
export async function setRhythmRules(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(setRhythmRulesSchema, data);
  const s = requireStaff(staff, 'flags.rollout');
  await db.runTransaction(async (tx) => {
    const ref = db.doc('config/rhythm');
    const before = rhythmConfigSchema.safeParse((await tx.get(ref)).data());
    tx.set(ref, { rules: req.rules, updatedAt: now, updatedBy: s.uid, updatedByName: s.name });
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'features.rhythm.rules',
        category: 'features',
        target: 'rhythm.rules',
        reason: req.reason,
        detail: {
          from: before.success ? before.data.rules.version : null,
          to: req.rules.version,
        },
      },
      now,
    );
  });
  return { rules: req.rules };
}
