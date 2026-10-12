import { createHash, randomBytes } from 'node:crypto';
import {
  firstAidActSchema,
  firstAidDraftSchema,
  firstAidImages,
  firstAidPublicDocId,
  firstAidUploadImageSchema,
  localDateIn,
  type FirstAidPack,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Sơ cứu content on the portal (D-058, P-141), the same workflow as Dữ liệu tham chiếu (P-138):
 * one open version (Nháp or Chờ duyệt) under `content/firstAid/versions`; a different person with
 * "Nội dung · Duyệt" approves, and approval publishes the pack to `publicConfig/content_firstAid`
 * in the same transaction. On prod the approver records the medical review (who, when, sources),
 * which the app shows in its footer. Pictures are uploaded once, re-encoded to WebP, and stored at
 * the public, immutable `content/first-aid/{name}_{hash}.webp`. Every step is in the audit log.
 */

export interface FirstAidImageStore {
  exists(id: string): Promise<boolean>;
  /** Re-encodes and stores; returns nothing (ids are content hashes of the encoded file). */
  save(id: string, webp: Buffer): Promise<void>;
  list(): Promise<string[]>;
  publicUrl(id: string): string;
  /** PNG / JPEG / WebP in, WebP out: pictograms 176 px square, pictures 1200 px wide. */
  encode(bytes: Buffer, icon: boolean): Promise<Buffer>;
}

export interface ContentDeps {
  images: FirstAidImageStore;
  /** Prod: approving needs the medical review recorded. */
  requireReview: boolean;
}

const ZONE = 'Asia/Ho_Chi_Minh';
const root = (db: Firestore) => db.doc('content/firstAid');
const versions = (db: Firestore) => root(db).collection('versions');
const iso = (v: unknown) =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;

function versionView(d: DocumentSnapshot) {
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
    situations: ((d.get('pack') as FirstAidPack | undefined)?.situations ?? []).length,
  };
}

async function openVersion(db: Firestore) {
  const snap = await versions(db).where('status', 'in', ['draft', 'pending']).limit(1).get();
  return snap.docs[0] ?? null;
}

/** What the portal's Sơ cứu screen shows: in use, the open version, history, pictures. */
export async function firstAidView(db: Firestore, deps: ContentDeps, staff: Staff | null) {
  requireStaff(staff, 'content.view');
  const [pub, open, history, images] = await Promise.all([
    db.doc(`publicConfig/${firstAidPublicDocId}`).get(),
    openVersion(db),
    versions(db).orderBy('createdAt', 'desc').limit(20).get(),
    deps.images.list(),
  ]);
  return {
    current: pub.exists
      ? {
          version: pub.get('version') as string,
          publishedAt: pub.get('publishedAt') as string,
          pack: pub.get('pack') as FirstAidPack,
        }
      : null,
    draft: open ? { ...versionView(open), pack: open.get('pack') as FirstAidPack } : null,
    history: history.docs.map(versionView),
    images: images.map((id) => ({ id, url: deps.images.publicUrl(id) })),
    requireReview: deps.requireReview,
  };
}

/** Save the open draft (or start one from the editor). Every picture must already exist. */
export async function firstAidDraft(
  db: Firestore,
  deps: ContentDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(firstAidDraftSchema, data);
  const missing: string[] = [];
  for (const id of firstAidImages(req.pack)) {
    if (!(await deps.images.exists(id))) missing.push(id);
  }
  if (missing.length) {
    throw new StaffError('failed-precondition', 'image-missing');
  }
  return db.runTransaction(async (tx) => {
    const open = await tx.get(versions(db).where('status', 'in', ['draft', 'pending']).limit(1));
    const ref = open.docs[0]?.ref ?? versions(db).doc(`fv_${randomBytes(8).toString('hex')}`);
    if (open.docs[0]) {
      // Editing a version under review withdraws it: the reviewer must see what they approve.
      tx.update(ref, {
        pack: req.pack,
        notes: req.notes,
        status: 'draft',
        rejection: null,
        updatedAt: now,
      });
    } else {
      tx.create(ref, {
        status: 'draft',
        pack: req.pack,
        notes: req.notes,
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
        action: 'content.firstAid.draft',
        category: 'content',
        target: 'firstAid',
        reason: null,
        detail: { situations: req.pack.situations.length },
      },
      now,
    );
    return { versionId: ref.id };
  });
}

/** "fa_20261012_01", then _02 for a second release the same day. */
async function nextLabel(db: Firestore, now: Date) {
  const day = localDateIn(ZONE, now).replace(/-/g, '');
  const prefix = `fa_${day}_`;
  const pub = await db.doc(`publicConfig/${firstAidPublicDocId}`).get();
  const last = pub.get('version') as string | undefined;
  const n = last?.startsWith(prefix) ? Number(last.slice(-2)) + 1 : 1;
  return `${prefix}${String(n).padStart(2, '0')}`;
}

/** Gửi duyệt · Duyệt & xuất bản · Trả lại · Huỷ nháp · Dùng lại bản này (rollback). */
export async function firstAidAct(
  db: Firestore,
  deps: ContentDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  const req = parse(firstAidActSchema, data);
  const snap = await versions(db).doc(req.versionId).get();
  if (!snap.exists) throw new StaffError('not-found', 'not-found');
  const status = snap.get('status') as string;
  const ref = snap.ref;
  const audit = (s: Staff, action: string, tx: FirebaseFirestore.Transaction) =>
    staffAudit(
      tx,
      db,
      s,
      {
        action: `content.firstAid.${action}`,
        category: 'content',
        target: 'firstAid',
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
      if (req.action === 'approve') {
        if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
        // Two people: whoever wrote the version cannot approve it (P-138 pattern, D-058).
        if (snap.get('authorUid') === s.uid) {
          throw new StaffError('failed-precondition', 'same-person');
        }
      } else if (status !== 'retired' && status !== 'published') {
        throw new StaffError('failed-precondition', 'not-retired');
      }
      const review = req.review ?? (snap.get('pack') as FirstAidPack).review ?? null;
      if (deps.requireReview && !review) {
        throw new StaffError('failed-precondition', 'review-required');
      }
      const pack: FirstAidPack = { ...(snap.get('pack') as FirstAidPack), review };
      const label = await nextLabel(db, now);
      const previous = await versions(db).where('status', '==', 'published').get();
      const target =
        req.action === 'approve' ? ref : versions(db).doc(`fv_${randomBytes(8).toString('hex')}`);
      await db.runTransaction(async (tx) => {
        for (const p of previous.docs) {
          if (p.id !== target.id) tx.update(p.ref, { status: 'retired', updatedAt: now });
        }
        const fields = {
          status: 'published',
          label,
          pack,
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
            notes: `Dùng lại ${snap.get('label') as string}`,
            authorUid: s.uid,
            authorName: s.name,
            createdAt: now,
            rejection: null,
          });
        }
        tx.set(db.doc(`publicConfig/${firstAidPublicDocId}`), {
          version: label,
          publishedAt: now.toISOString(),
          pack,
        });
        tx.set(root(db), { currentVersionId: target.id, updatedAt: now }, { merge: true });
        audit(s, req.action, tx);
      });
      return { status: 'published', version: label };
    }
  }
}

/** A picture for the guide (stored once; the same bytes give the same id). */
export async function firstAidUploadImage(
  db: Firestore,
  deps: ContentDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(firstAidUploadImageSchema, data);
  let webp: Buffer;
  try {
    webp = await deps.images.encode(Buffer.from(req.data, 'base64'), req.name.startsWith('icon-'));
  } catch {
    throw new StaffError('invalid-argument', 'image-unreadable');
  }
  const id = `${req.name}_${createHash('sha256').update(webp).digest('hex').slice(0, 8)}`;
  if (!(await deps.images.exists(id))) await deps.images.save(id, webp);
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    { action: 'content.firstAid.image', category: 'content', target: id, reason: null },
    now,
  );
  await batch.commit();
  return { id, url: deps.images.publicUrl(id) };
}
