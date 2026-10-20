import { createHash, randomBytes } from 'node:crypto';
import {
  answerOwnershipSchema,
  babyDeletionSteps,
  accountDeletionSteps,
  contentCollections,
  createSupportTicketSchema,
  deleteAccountSchema,
  deleteBabySchema,
  familyStorageRequestSchema,
  foodIdSchema,
  localDateIn,
  maxBabyAgeYears,
  noteBytesEstimate,
  offerOwnershipSchema,
  requestExportSchema,
  requestStorageSchema,
  signOutDeviceSchema,
  storageRequestBytes,
  storageState,
  updateBabyProfileSchema,
  updateMyProfileSchema,
  type FamilyStorage,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import type { Readable } from 'node:stream';
import type { AccountMailData, AccountTemplate, Locale } from './mail.js';
import { reconcileFamilyUsage } from './memories.js';

// Child Life Assistant, slice A3: assistant data goes with the account / the baby.
import { purgeAssistantForBaby, purgeAssistantForUser } from './assistant-lifecycle.js';
/**
 * Me, storage, baby profiles and the account (S11, Figma 13a–13n). Sensitive changes are callables
 * with zod validation; deletions run as resumable jobs (P-110) that only report "done" after a
 * verification step (plan flow F). Nicknames, messages and ticket text are never logged.
 */

export type AccountErrorCode =
  | 'invalid-argument'
  | 'failed-precondition'
  | 'permission-denied'
  | 'not-found'
  | 'resource-exhausted';

export class AccountError extends Error {
  constructor(
    readonly code: AccountErrorCode,
    readonly reason: string,
  ) {
    super(reason);
  }
}

export interface AccountCaller {
  uid: string;
  email: string | null;
  anonymous: boolean;
  locale: Locale;
}

const GB = 1024 ** 3;
const HOUR_MS = 3_600_000;
const sha = (s: string) => createHash('sha256').update(s).digest('hex');
const gb = (bytes: number) => (bytes / GB).toFixed(1).replace(/\.0$/, '');

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new AccountError('invalid-argument', 'malformed');
  return r.data as T;
}

function isActive(member: DocumentSnapshot, now: Date): boolean {
  if (!member.exists || member.get('status') !== 'active') return false;
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  return !until || until.toMillis() > now.getTime();
}

async function activeMember(
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
  tx?: Transaction,
): Promise<DocumentSnapshot> {
  const ref = db.doc(`babies/${babyId}/members/${uid}`);
  const m = tx ? await tx.get(ref) : await ref.get();
  if (!isActive(m, now)) throw new AccountError('permission-denied', 'not-a-member');
  return m;
}

async function activeParent(
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
  tx?: Transaction,
) {
  const m = await activeMember(db, babyId, uid, now, tx);
  if (m.get('role') !== 'coParent') throw new AccountError('permission-denied', 'parents-only');
  return m;
}

function audit(tx: Transaction, db: Firestore, entry: Record<string, unknown>, now: Date) {
  tx.create(db.collection('audit').doc(), { ...entry, at: now });
}

/** Queues one service mail (delivered by `deliverQueuedMail`). */
export function queueMail(
  tx: Transaction,
  db: Firestore,
  to: string,
  template: AccountTemplate,
  locale: Locale,
  data: AccountMailData,
  now: Date,
) {
  tx.create(db.collection('mail').doc(), {
    to,
    template,
    locale,
    data,
    unsubscribeToken: randomBytes(24).toString('base64url'),
    status: 'queued',
    attempts: 0,
    createdAt: now,
  });
}

// ---------- Storage (13b–13e) ----------

export interface StorageDeps {
  staffInbox: string;
}

/** 13b for any Cùng nuôi of a baby in the family (P-003): totals, by baby, by type, largest videos. */
export async function familyStorage(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
): Promise<FamilyStorage> {
  const { babyId } = parse(familyStorageRequestSchema, data);
  await activeParent(db, babyId, caller.uid, now);
  const baby = await db.doc(`babies/${babyId}`).get();
  const familyId = baby.get('familyId') as string;
  let family = await db.doc(`families/${familyId}`).get();
  if (!family.exists) throw new AccountError('not-found', 'family');
  // Families from before S11 have no breakdown yet: build it once from their items.
  if (family.get('usage') === undefined) {
    await reconcileFamilyUsage(db, familyId);
    family = await family.ref.get();
  }
  const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];
  const babySnaps = babyIds.length
    ? await db.getAll(...babyIds.map((b) => db.doc(`babies/${b}`)))
    : [];
  const usage = (family.get('usage') as Record<string, Record<string, number>> | undefined) ?? {};

  // Captions, notes and stories are text: a small estimate per entry ("Câu chuyện & ghi chú").
  let texts = 0;
  for (const b of babyIds) {
    const notes = await db.collection(`babies/${b}/memories`).count().get();
    texts += notes.data().count;
  }

  // "Xem video lớn nhất" (G-058): only babies the caller co-parents.
  const mine = new Set<string>();
  for (const b of babyIds) {
    const m = await db.doc(`babies/${b}/members/${caller.uid}`).get();
    if (isActive(m, now) && m.get('role') === 'coParent') mine.add(b);
  }
  const videos = await db
    .collectionGroup('media')
    .where('familyId', '==', familyId)
    .where('type', '==', 'video')
    .where('status', '==', 'ready')
    .where('deleted', '==', false)
    .orderBy('storedBytes', 'desc')
    .limit(40)
    .get();

  const open = await db
    .collection('storageRequests')
    .where('familyId', '==', familyId)
    .where('status', '==', 'open')
    .limit(1)
    .get();

  return {
    familyId,
    isOwner: family.get('ownerUid') === caller.uid,
    quotaBytes: (family.get('quotaBytes') as number | undefined) ?? 0,
    usedBytes: Math.max(0, (family.get('usedBytes') as number | undefined) ?? 0),
    binBytes: Math.max(0, (family.get('binBytes') as number | undefined) ?? 0),
    notesBytes: texts * noteBytesEstimate,
    babies: babySnaps
      .filter((s) => s.exists)
      .map((s) => {
        const u = usage[s.id] ?? {};
        return {
          babyId: s.id,
          nickname: s.get('nickname') as string,
          photos: Math.max(0, u.photos ?? 0),
          videos: Math.max(0, u.videos ?? 0),
          photoBytes: Math.max(0, u.photoBytes ?? 0),
          videoBytes: Math.max(0, u.videoBytes ?? 0),
        };
      }),
    largestVideos: videos.docs
      .filter((d) => mine.has(d.get('babyId') as string))
      .slice(0, 20)
      .map((d) => ({
        babyId: d.get('babyId') as string,
        mediaId: d.id,
        bytes: (d.get('storedBytes') as number | undefined) ?? 0,
        durationMs: (d.get('durationMs') as number | null | undefined) ?? null,
        captureAt: (d.get('captureAt') as Timestamp).toDate().toISOString(),
      })),
    openRequest: open.empty
      ? null
      : {
          id: open.docs[0]!.id,
          amountGb: open.docs[0]!.get('amountGb') as number,
          createdAt: (open.docs[0]!.get('createdAt') as Timestamp).toDate().toISOString(),
        },
  };
}

/** 13e "Gửi yêu cầu": one open request per family; email + usage attached (R-122, D-010). */
export async function requestStorage(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
  deps: StorageDeps,
): Promise<{ id: string; created: boolean }> {
  const req = parse(requestStorageSchema, data);
  if (caller.anonymous || !caller.email)
    throw new AccountError('failed-precondition', 'email-required');
  const id = `sr_${sha(`${caller.uid}:${req.requestId}`).slice(0, 20)}`;
  return db.runTransaction(async (tx) => {
    const mine = await tx.get(db.doc(`storageRequests/${id}`));
    if (mine.exists) return { id, created: false };
    await activeParent(db, req.babyId, caller.uid, now, tx);
    const baby = await tx.get(db.doc(`babies/${req.babyId}`));
    const familyId = baby.get('familyId') as string;
    const family = await tx.get(db.doc(`families/${familyId}`));
    const open = await tx.get(
      db
        .collection('storageRequests')
        .where('familyId', '==', familyId)
        .where('status', '==', 'open')
        .limit(1),
    );
    if (!open.empty) return { id: open.docs[0]!.id, created: false };
    const used = (family.get('usedBytes') as number | undefined) ?? 0;
    const quota = (family.get('quotaBytes') as number | undefined) ?? 0;
    tx.create(db.doc(`storageRequests/${id}`), {
      familyId,
      requesterUid: caller.uid,
      email: caller.email,
      amountGb: req.amountGb,
      requestedBytes: storageRequestBytes(req.amountGb),
      // Free text may mention the child: shown to staff as typed, kept 1 year (P-124).
      message: req.message ?? null,
      usage: { usedBytes: used, quotaBytes: quota },
      status: 'open',
      locale: caller.locale,
      createdAt: now,
    });
    const mail = { amountGb: req.amountGb, usedGb: gb(used), quotaGb: gb(quota), requestId: id };
    queueMail(tx, db, caller.email!, 'storageRequestAck', caller.locale, mail, now);
    queueMail(tx, db, deps.staffInbox, 'storageRequestStaff', 'vi', mail, now);
    audit(
      tx,
      db,
      { action: 'storage.request', actor: caller.uid, target: familyId, category: 'storage' },
      now,
    );
    return { id, created: true };
  });
}

/**
 * 80 % / 100 % (13c, 13d): one generic notice to the family's parents per state change. Called
 * after an item becomes ready; states are remembered on the family so a notice is sent once.
 */
export async function maybeStorageNotice(
  db: Firestore,
  familyId: string,
  now: Date,
): Promise<string | null> {
  const ref = db.doc(`families/${familyId}`);
  return db.runTransaction(async (tx) => {
    const family = await tx.get(ref);
    if (!family.exists) return null;
    const state = storageState(
      (family.get('usedBytes') as number | undefined) ?? 0,
      (family.get('quotaBytes') as number | undefined) ?? 0,
    );
    const last = (family.get('storageNoticeState') as string | undefined) ?? 'ok';
    if (state === last) return null;
    const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];
    const recipients = new Set<string>([family.get('ownerUid') as string]);
    if (state !== 'ok') {
      // Reads first (transactions), then the writes.
      for (const b of babyIds) {
        const parents = await tx.get(
          db
            .collection(`babies/${b}/members`)
            .where('role', '==', 'coParent')
            .where('status', '==', 'active'),
        );
        parents.docs.forEach((p) => recipients.add(p.id));
      }
    }
    tx.update(ref, { storageNoticeState: state });
    if (state === 'ok') return null;
    const babyId = babyIds[0];
    if (!babyId) return null;
    const id = `storage_${familyId}_${state}_${now.getTime()}`;
    tx.create(db.doc(`babies/${babyId}/notifications/${id}`), {
      kind: 'storage',
      babyId,
      count: state === 'full' ? 100 : 80,
      actor: null,
      recipients: [...recipients],
      createdAt: now,
      delivered: false,
    });
    return id;
  });
}

// ---------- Baby profile (13k, 13l) ----------

/** 13k "Lưu thay đổi" (Cùng nuôi, §5). DOB stays between 18 years ago and today in the zone. */
export async function updateBabyProfile(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
): Promise<void> {
  const req = parse(updateBabyProfileSchema, data);
  await db.runTransaction(async (tx) => {
    await activeParent(db, req.babyId, caller.uid, now, tx);
    const babyRef = db.doc(`babies/${req.babyId}`);
    const baby = await tx.get(babyRef);
    if (baby.get('state') === 'deleting') throw new AccountError('failed-precondition', 'deleting');
    const zone = req.timeZone?.zone ?? (baby.get('timeZone.zone') as string);
    if (req.dateOfBirth) {
      const today = localDateIn(zone, now);
      if (req.dateOfBirth > today) throw new AccountError('invalid-argument', 'dob-in-future');
      const oldest = `${Number(today.slice(0, 4)) - maxBabyAgeYears}${today.slice(4)}`;
      if (req.dateOfBirth < oldest) throw new AccountError('invalid-argument', 'dob-too-old');
    }
    const babyPatch: Record<string, unknown> = { updatedAt: now };
    if (req.nickname) babyPatch.nickname = req.nickname;
    if (req.timeZone) babyPatch.timeZone = req.timeZone;
    tx.update(babyRef, babyPatch);
    if (req.dateOfBirth || req.gender) {
      tx.set(
        babyRef.collection('restricted').doc('profile'),
        {
          ...(req.dateOfBirth ? { dateOfBirth: req.dateOfBirth } : {}),
          ...(req.gender ? { gender: req.gender } : {}),
          updatedAt: now,
        },
        { merge: true },
      );
    }
    audit(
      tx,
      db,
      {
        action: 'baby.update',
        actor: caller.uid,
        babyId: req.babyId,
        fields: Object.keys(req).filter((k) => k !== 'babyId'),
        category: 'family',
      },
      now,
    );
  });
}

const sameName = (a: string, b: string) =>
  a.normalize('NFC').trim().toLocaleLowerCase('vi') ===
  b.normalize('NFC').trim().toLocaleLowerCase('vi');

/** 13l "Xoá vĩnh viễn": owner only, nickname typed; writes lock at once, the job purges (P-110). */
export async function requestBabyDeletion(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
): Promise<{ jobId: string }> {
  const req = parse(deleteBabySchema, data);
  const jobId = `del_${req.babyId}`;
  return db.runTransaction(async (tx) => {
    const babyRef = db.doc(`babies/${req.babyId}`);
    const baby = await tx.get(babyRef);
    if (!baby.exists) throw new AccountError('not-found', 'not-found');
    if (baby.get('ownerUid') !== caller.uid)
      throw new AccountError('permission-denied', 'owner-only');
    const job = await tx.get(db.doc(`deletionJobs/${jobId}`));
    if (job.exists) return { jobId };
    await activeMember(db, req.babyId, caller.uid, now, tx);
    if (!sameName(req.confirmNickname, baby.get('nickname') as string)) {
      throw new AccountError('invalid-argument', 'nickname-mismatch');
    }
    tx.update(babyRef, { state: 'deleting', deletionRequestedAt: now, updatedAt: now });
    tx.create(db.doc(`deletionJobs/${jobId}`), {
      kind: 'baby',
      babyId: req.babyId,
      familyId: baby.get('familyId'),
      ownerUid: caller.uid,
      requestedBy: caller.uid,
      email: caller.email,
      locale: caller.locale,
      steps: [...babyDeletionSteps],
      step: 0,
      state: 'queued',
      attempts: 0,
      createdAt: now,
      updatedAt: now,
    });
    audit(
      tx,
      db,
      { action: 'baby.delete.request', actor: caller.uid, babyId: req.babyId, category: 'data' },
      now,
    );
    return { jobId };
  });
}

// ---------- Deletion jobs (P-110) ----------

/** Storage surface for purges and exports (bucket in production, a fake in tests). */
export interface PurgeStore {
  deletePrefix(prefix: string): Promise<void>;
  countPrefix(prefix: string): Promise<number>;
  /** Streams [entries] into one ZIP object; returns its size. */
  zip(
    path: string,
    entries: AsyncIterable<{ name: string; open: () => Promise<Readable> }>,
  ): Promise<number>;
}

export interface JobDeps {
  store: PurgeStore;
  deleteAuthUser(uid: string): Promise<void>;
}

/** Top-level collections that point at a baby and go with it. */
const babyLinked = ['invites', 'dataJobs'] as const;

async function deleteQuery(db: Firestore, q: FirebaseFirestore.Query): Promise<number> {
  let total = 0;
  for (;;) {
    const snap = await q.limit(300).get();
    if (snap.empty) return total;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
  }
}

async function babyStep(
  db: Firestore,
  deps: JobDeps,
  job: DocumentSnapshot,
  step: string,
  now: Date,
) {
  const babyId = job.get('babyId') as string;
  const familyId = job.get('familyId') as string;
  const babyRef = db.doc(`babies/${babyId}`);
  switch (step) {
    case 'lock':
      if ((await babyRef.get()).exists) await babyRef.update({ state: 'deleting' });
      return;
    case 'storage':
      await deps.store.deletePrefix(`babies/${babyId}/`);
      return;
    case 'documents': {
      for (const c of await babyRef.listCollections()) await db.recursiveDelete(c);
      for (const name of babyLinked) {
        await deleteQuery(db, db.collection(name).where('babyId', '==', babyId));
      }
      await deleteQuery(
        db,
        db.collection(`families/${familyId}/reservations`).where('babyId', '==', babyId),
      );
      // P-172: private per-viewer state and delivery/lease docs linked to this baby.
      await deleteQuery(db, db.collectionGroup('personalization').where('babyId', '==', babyId));
      await deleteQuery(db, db.collectionGroup('settings').where('babyId', '==', babyId));
      // Assistant chats, tasks, drafts and photos about this baby (every member's).
      await purgeAssistantForBaby(db, deps.store, babyId, now);
      return;
    }
    case 'family': {
      await db.runTransaction(async (tx) => {
        const familyRef = db.doc(`families/${familyId}`);
        const family = await tx.get(familyRef);
        const ownerUid = job.get('ownerUid') as string;
        const owner = await tx.get(db.doc(`users/${ownerUid}`));
        if (family.exists && ((family.get('babyIds') as string[]) ?? []).includes(babyId)) {
          tx.update(familyRef, {
            babyIds: FieldValue.arrayRemove(babyId),
            [`usage.${babyId}`]: FieldValue.delete(),
            updatedAt: now,
          });
          if (owner.exists) {
            tx.update(owner.ref, {
              ownedBabyCount: Math.max(0, ((owner.get('ownedBabyCount') as number) ?? 1) - 1),
              updatedAt: now,
            });
          }
        }
      });
      // Quota comes back: used and reserved bytes are rebuilt from the remaining items.
      await reconcileFamilyUsage(db, familyId);
      return;
    }
    case 'verify': {
      const left = await babyRef.listCollections();
      const objects = await deps.store.countPrefix(`babies/${babyId}/`);
      let linked = 0;
      for (const name of babyLinked) {
        linked += (await db.collection(name).where('babyId', '==', babyId).count().get()).data()
          .count;
      }
      if (left.length > 0 || objects > 0 || linked > 0) {
        throw new Error(
          `verify: ${left.length} collections, ${objects} objects, ${linked} links left`,
        );
      }
      return;
    }
    case 'finish':
      await db.runTransaction(async (tx) => {
        tx.delete(babyRef);
        const email = job.get('email') as string | null;
        if (email) queueMail(tx, db, email, 'babyDeleted', job.get('locale') as Locale, {}, now);
        audit(
          tx,
          db,
          { action: 'baby.delete.done', actor: job.get('requestedBy'), babyId, category: 'data' },
          now,
        );
      });
      return;
  }
}

/** Authored content stays with the family as "Người dùng đã xoá" (Q-016). */
const deletedAuthor = { name: '', relation: 'deleted', relationCustom: null };
const authoredCollections: Array<[string, string] | [string, string, string]> = [
  ['records', 'createdBy'],
  ['memories', 'createdBy'],
  ['media', 'createdBy'],
  ['milestones', 'createdBy'],
  ['reminders', 'createdBy'],
  ['messages', 'from'],
  // Nhịp lớn lên check-ins and suggestion feedback stay with the family too (plan §7.1).
  ['checkins', 'authorUid'],
  ['recFeedback', 'authorUid'],
  // NL07b episodes keep both people: who confirmed it (author) and who closed it, each marked.
  ['episodes', 'confirmedBy'],
  ['episodes', 'closedBy', 'closedByDeleted'],
  // Stored AI summaries (plan §5.5) stay with the family; who asked becomes "đã xoá".
  ['summaries', 'requestedBy'],
  // Ăn dặm meals (D-085) stay with the family like care records.
  ['meals', 'createdBy'],
  // So do the family's own recipes ("Công thức nhà mình", D-086, plan §12 #2).
  ['recipes', 'createdBy'],
];

async function accountStep(
  db: Firestore,
  deps: JobDeps,
  job: DocumentSnapshot,
  step: string,
  now: Date,
) {
  const uid = job.get('uid') as string;
  switch (step) {
    case 'memberships': {
      const members = await db.collectionGroup('members').where('uid', '==', uid).get();
      for (const m of members.docs) {
        if (m.get('status') === 'active' || m.get('status') === 'expired') {
          await m.ref.update({
            status: 'removed',
            removedAt: now,
            removedBy: uid,
            accountDeleted: true,
          });
        }
      }
      return;
    }
    case 'authored': {
      for (const [collection, field, marker = 'authorDeleted'] of authoredCollections) {
        let last: DocumentSnapshot | undefined;
        for (;;) {
          let q = db.collectionGroup(collection).where(field, '==', uid).limit(300);
          if (last) q = q.startAfter(last);
          const snap = await q.get();
          if (snap.empty) break;
          const batch = db.batch();
          let n = 0;
          for (const d of snap.docs) {
            if (d.get(marker) === true) continue;
            batch.update(
              d.ref,
              marker === 'authorDeleted'
                ? { author: deletedAuthor, authorDeleted: true }
                : { [marker]: true },
            );
            n++;
          }
          if (n > 0) await batch.commit();
          last = snap.docs[snap.docs.length - 1];
        }
      }
      // P-172 notebook notes are removed on author account deletion, including private text.
      await deleteQuery(db, db.collectionGroup('notebook').where('authorUid', '==', uid));
      // Personal marks go: loves and private favourites.
      await deleteQuery(db, db.collectionGroup('reactions').where('uid', '==', uid));
      await deleteQuery(db, db.collectionGroup('favorites').where('uid', '==', uid));
      return;
    }
    case 'personal': {
      const user = db.doc(`users/${uid}`);
      const snap = await user.get();
      const familyId = snap.get('ownedFamilyId') as string | undefined;
      if (familyId) {
        const family = await db.doc(`families/${familyId}`).get();
        if (family.exists && ((family.get('babyIds') as string[]) ?? []).length === 0) {
          await db.recursiveDelete(family.ref);
        }
      }
      // Their assistant conversations, tasks, drafts, photos and ledgers (records stay).
      await purgeAssistantForUser(db, deps.store, uid, now);
      await db.recursiveDelete(user);
      return;
    }
    case 'auth':
      await deps.deleteAuthUser(uid);
      return;
    case 'finish':
      await db.runTransaction(async (tx) => {
        const email = job.get('email') as string | null;
        if (email) queueMail(tx, db, email, 'accountDeleted', job.get('locale') as Locale, {}, now);
        tx.update(job.ref, { email: null });
        audit(tx, db, { action: 'account.delete.done', actor: uid, category: 'data' }, now);
      });
      return;
  }
}

/**
 * Runs a deletion job from its current step. Every step is idempotent; a failure records the step
 * and the job resumes there later (A07 "Chạy lại"). Only the last step marks it done.
 */
export async function runDeletionJob(
  db: Firestore,
  deps: JobDeps,
  jobId: string,
  now: () => Date,
): Promise<'done' | 'failed' | 'skipped'> {
  const ref = db.doc(`deletionJobs/${jobId}`);
  const claimed = await db.runTransaction(async (tx) => {
    const job = await tx.get(ref);
    if (!job.exists || job.get('state') === 'done') return false;
    const updated = job.get('updatedAt') as Timestamp | undefined;
    const running = job.get('state') === 'running';
    if (running && updated && now().getTime() - updated.toMillis() < 15 * 60_000) return false;
    tx.update(ref, { state: 'running', updatedAt: now(), attempts: FieldValue.increment(1) });
    return true;
  });
  if (!claimed) return 'skipped';
  let job = await ref.get();
  const steps = job.get('steps') as string[];
  for (let i = job.get('step') as number; i < steps.length; i++) {
    try {
      if (job.get('kind') === 'baby') await babyStep(db, deps, job, steps[i]!, now());
      else await accountStep(db, deps, job, steps[i]!, now());
      await ref.update({ step: i + 1, updatedAt: now(), error: null });
      job = await ref.get();
    } catch (error) {
      await ref.update({
        state: 'failed',
        failedStep: steps[i],
        error: String(error).slice(0, 300),
        updatedAt: now(),
      });
      return 'failed';
    }
  }
  await ref.update({ state: 'done', finishedAt: now(), updatedAt: now() });
  return 'done';
}

/** Picks up queued, stalled or failed jobs (at most 10 attempts, then staff re-run them). */
export async function resumeDeletionJobs(
  db: Firestore,
  deps: JobDeps,
  now: () => Date,
): Promise<number> {
  const snap = await db
    .collection('deletionJobs')
    .where('state', 'in', ['queued', 'running', 'failed'])
    .limit(20)
    .get();
  let n = 0;
  for (const d of snap.docs) {
    if (((d.get('attempts') as number) ?? 0) >= 10) continue;
    if ((await runDeletionJob(db, deps, d.id, now)) !== 'skipped') n++;
  }
  return n;
}

// ---------- Your profile (13m) ----------

export async function updateMyProfile(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
) {
  const req = parse(updateMyProfileSchema, data);
  const memberships = await db.collectionGroup('members').where('uid', '==', caller.uid).get();
  const active = memberships.docs.filter((m) => isActive(m, now));
  for (const r of req.relations ?? []) {
    if (!active.some((m) => m.get('babyId') === r.babyId)) {
      throw new AccountError('permission-denied', 'not-a-member');
    }
  }
  const batch = db.batch();
  if (req.displayName) {
    batch.set(
      db.doc(`users/${caller.uid}`),
      { displayName: req.displayName, updatedAt: now },
      { merge: true },
    );
  }
  for (const m of active) {
    const patch: Record<string, unknown> = {};
    if (req.displayName) patch.displayName = req.displayName;
    const r = req.relations?.find((x) => x.babyId === m.get('babyId'));
    if (r) {
      patch.relation = r.relation;
      patch.relationCustom = r.relationCustom;
    }
    if (Object.keys(patch).length) batch.update(m.ref, { ...patch, updatedAt: now });
  }
  await batch.commit();
}

// ---------- Ownership transfer and account deletion (13n, Q-016) ----------

async function familyBabies(tx: Transaction, db: Firestore, familyId: string) {
  const family = await tx.get(db.doc(`families/${familyId}`));
  if (!family.exists) throw new AccountError('not-found', 'family');
  return { family, babyIds: (family.get('babyIds') as string[] | undefined) ?? [] };
}

async function requireReceiver(
  tx: Transaction,
  db: Firestore,
  babyIds: string[],
  toUid: string,
  now: Date,
) {
  for (const b of babyIds) {
    const m = await tx.get(db.doc(`babies/${b}/members/${toUid}`));
    if (!isActive(m, now) || m.get('role') !== 'coParent') {
      throw new AccountError('failed-precondition', 'receiver-not-parent');
    }
  }
  const receiver = await tx.get(db.doc(`users/${toUid}`));
  if (((receiver.get('ownedBabyCount') as number | undefined) ?? 0) > 0) {
    throw new AccountError('failed-precondition', 'receiver-owns-family');
  }
  return receiver;
}

/** "Chuyển chủ hồ sơ": offered to a Cùng nuôi of every baby, who accepts in the app (Q-016). */
export async function offerOwnership(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
  emailOf: (uid: string) => Promise<string | null>,
): Promise<{ familyId: string }> {
  const { toUid } = parse(offerOwnershipSchema, data);
  if (toUid === caller.uid) throw new AccountError('invalid-argument', 'self');
  const to = await emailOf(toUid);
  return db.runTransaction(async (tx) => {
    const user = await tx.get(db.doc(`users/${caller.uid}`));
    const familyId = user.get('ownedFamilyId') as string | undefined;
    if (!familyId) throw new AccountError('failed-precondition', 'not-owner');
    const { family, babyIds } = await familyBabies(tx, db, familyId);
    if (family.get('ownerUid') !== caller.uid)
      throw new AccountError('permission-denied', 'not-owner');
    if (babyIds.length === 0) throw new AccountError('failed-precondition', 'no-babies');
    await requireReceiver(tx, db, babyIds, toUid, now);
    const fromName = (user.get('displayName') as string | undefined) ?? '';
    const previous = family.get('transfer.toUid') as string | undefined;
    if (previous && previous !== toUid) {
      tx.set(
        db.doc(`users/${previous}`),
        { pendingOwnership: FieldValue.delete() },
        { merge: true },
      );
    }
    tx.update(family.ref, { transfer: { toUid, fromUid: caller.uid, at: now } });
    tx.set(
      db.doc(`users/${toUid}`),
      { pendingOwnership: { familyId, fromUid: caller.uid, fromName, babyIds, at: now } },
      { merge: true },
    );
    if (to) queueMail(tx, db, to, 'ownershipOffer', caller.locale, { fromName }, now);
    audit(
      tx,
      db,
      { action: 'ownership.offer', actor: caller.uid, target: toUid, familyId, category: 'family' },
      now,
    );
    return { familyId };
  });
}

export async function answerOwnership(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
): Promise<{ state: 'accepted' | 'declined' | 'cancelled' }> {
  const { familyId, answer } = parse(answerOwnershipSchema, data);
  return db.runTransaction(async (tx) => {
    const { family, babyIds } = await familyBabies(tx, db, familyId);
    const transfer = family.get('transfer') as { toUid: string; fromUid: string } | undefined;
    if (!transfer) throw new AccountError('failed-precondition', 'no-offer');
    const allowed = answer === 'cancel' ? transfer.fromUid : transfer.toUid;
    if (caller.uid !== allowed) throw new AccountError('permission-denied', 'not-allowed');
    const clear = () => {
      tx.update(family.ref, { transfer: FieldValue.delete() });
      tx.set(
        db.doc(`users/${transfer.toUid}`),
        { pendingOwnership: FieldValue.delete() },
        { merge: true },
      );
    };
    if (answer !== 'accept') {
      clear();
      audit(
        tx,
        db,
        { action: `ownership.${answer}`, actor: caller.uid, familyId, category: 'family' },
        now,
      );
      return { state: answer === 'decline' ? ('declined' as const) : ('cancelled' as const) };
    }
    const receiver = await requireReceiver(tx, db, babyIds, transfer.toUid, now);
    const fromMembers = await Promise.all(
      babyIds.map((b) => tx.get(db.doc(`babies/${b}/members/${transfer.fromUid}`))),
    );
    // An empty family the receiver once made is replaced by this one.
    const oldFamily = receiver.get('ownedFamilyId') as string | undefined;
    if (oldFamily && oldFamily !== familyId) tx.delete(db.doc(`families/${oldFamily}`));
    tx.update(family.ref, {
      ownerUid: transfer.toUid,
      transfer: FieldValue.delete(),
      updatedAt: now,
    });
    for (const [i, b] of babyIds.entries()) {
      tx.update(db.doc(`babies/${b}`), { ownerUid: transfer.toUid, updatedAt: now });
      tx.update(db.doc(`babies/${b}/members/${transfer.toUid}`), { isOwner: true });
      if (fromMembers[i]!.exists) tx.update(fromMembers[i]!.ref, { isOwner: false });
    }
    tx.set(
      db.doc(`users/${transfer.fromUid}`),
      { ownedFamilyId: FieldValue.delete(), ownedBabyCount: 0, updatedAt: now },
      { merge: true },
    );
    tx.set(
      receiver.ref,
      {
        ownedFamilyId: familyId,
        ownedBabyCount: babyIds.length,
        pendingOwnership: FieldValue.delete(),
        updatedAt: now,
      },
      { merge: true },
    );
    audit(
      tx,
      db,
      {
        action: 'ownership.transfer',
        actor: caller.uid,
        before: { ownerUid: transfer.fromUid },
        after: { ownerUid: transfer.toUid },
        familyId,
        category: 'family',
      },
      now,
    );
    return { state: 'accepted' as const };
  });
}

/** "Xoá tài khoản": only without owned babies (R-046); the rest runs as a job. */
export async function requestAccountDeletion(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
): Promise<{ jobId: string }> {
  parse(deleteAccountSchema, data);
  const jobId = `acct_${sha(caller.uid).slice(0, 24)}`;
  return db.runTransaction(async (tx) => {
    const job = await tx.get(db.doc(`deletionJobs/${jobId}`));
    if (job.exists && job.get('state') !== 'done') return { jobId };
    const user = await tx.get(db.doc(`users/${caller.uid}`));
    if (((user.get('ownedBabyCount') as number | undefined) ?? 0) > 0) {
      throw new AccountError('failed-precondition', 'owns-babies');
    }
    const offered = user.get('pendingOwnership.familyId') as string | undefined;
    if (offered) {
      tx.update(db.doc(`families/${offered}`), { transfer: FieldValue.delete() });
    }
    tx.set(db.doc(`deletionJobs/${jobId}`), {
      kind: 'account',
      uid: caller.uid,
      requestedBy: caller.uid,
      email: caller.email,
      locale: caller.locale,
      steps: [...accountDeletionSteps],
      step: 0,
      state: 'queued',
      attempts: 0,
      createdAt: now,
      updatedAt: now,
    });
    audit(tx, db, { action: 'account.delete.request', actor: caller.uid, category: 'data' }, now);
    return { jobId };
  });
}

// ---------- Devices (13n) ----------

/** "Đăng xuất" another device: it signs itself out when it sees the flag (no push token kept). */
export async function signOutDevice(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
) {
  const { deviceId } = parse(signOutDeviceSchema, data);
  const ref = db.doc(`users/${caller.uid}/devices/${deviceId}`);
  const device = await ref.get();
  if (!device.exists) throw new AccountError('not-found', 'device');
  await ref.update({ signedOutAt: now, token: FieldValue.delete() });
}

// ---------- Data export (R-187, P-123) ----------

/** "Xuất dữ liệu": care for Cùng nuôi, all media for the owner only. Built by `runExport`. */
export async function requestExport(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
): Promise<{ jobId: string }> {
  const req = parse(requestExportSchema, data);
  if (caller.anonymous) throw new AccountError('failed-precondition', 'account-required');
  const jobId = `ex_${sha(`${caller.uid}:${req.requestId}`).slice(0, 20)}`;
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(db.doc(`dataJobs/${jobId}`));
    if (existing.exists) return { jobId };
    await activeParent(db, req.babyId, caller.uid, now, tx);
    const baby = await tx.get(db.doc(`babies/${req.babyId}`));
    if (baby.get('state') === 'deleting') throw new AccountError('failed-precondition', 'deleting');
    if (req.kind === 'media' && baby.get('ownerUid') !== caller.uid) {
      throw new AccountError('permission-denied', 'owner-only');
    }
    const running = await tx.get(
      db
        .collection('dataJobs')
        .where('uid', '==', caller.uid)
        .where('state', 'in', ['queued', 'running'])
        .limit(1),
    );
    if (!running.empty) throw new AccountError('resource-exhausted', 'export-running');
    tx.create(db.doc(`dataJobs/${jobId}`), {
      kind: 'export',
      exportKind: req.kind,
      babyId: req.babyId,
      uid: caller.uid,
      email: caller.email,
      locale: caller.locale,
      state: 'queued',
      createdAt: now,
      updatedAt: now,
    });
    audit(
      tx,
      db,
      { action: `export.${req.kind}`, actor: caller.uid, babyId: req.babyId, category: 'data' },
      now,
    );
    return { jobId };
  });
}

const csvCell = (v: unknown) => {
  const s = v == null ? '' : typeof v === 'object' ? JSON.stringify(v) : String(v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
/** Excel opens UTF-8 CSV correctly only with a byte-order mark. */
const BOM = String.fromCharCode(0xfeff);
const iso = (v: unknown) => (v instanceof Timestamp ? v.toDate().toISOString() : v);

/** One CSV with the BOM, from rows and the header naming their fields in order. */
const csvOf = (header: string[], rows: Record<string, unknown>[]) =>
  BOM +
  [header.join(','), ...rows.map((r) => header.map((h) => csvCell(r[h])).join(','))].join('\n');

/**
 * The "Bữa ăn dặm" sheet (D-085 #3): live meals, oldest first, with the catalogue names in the
 * export's language (the id when a food is not on the app). No photos.
 */
async function mealsCsv(db: Firestore, babyId: string, locale: Locale): Promise<string> {
  const snap = await db.collection(`babies/${babyId}/meals`).where('deleted', '==', false).get();
  const meals = snap.docs.map((d) => d.data());
  const list = (v: unknown) =>
    Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [];
  const ids = [...new Set(meals.flatMap((m) => list(m.foodIds)))].filter(
    (id) => foodIdSchema.safeParse(id).success,
  );
  const names = new Map<string, string>();
  const foods = ids.length
    ? await db.getAll(...ids.map((id) => db.collection(contentCollections.food).doc(id)))
    : [];
  for (const f of foods) {
    if (!f.exists || f.get('status') !== 'published') continue;
    const name = f.get('name') as { vi?: string; en?: string } | undefined;
    const text = (locale === 'en' ? name?.en : name?.vi) || name?.vi || '';
    if (text) names.set(f.id, text);
  }
  const amount = (a: unknown) => {
    const x = a as { preset?: string; value?: number; unit?: string } | null | undefined;
    return x?.preset ?? (x?.value != null ? `${x.value} ${x.unit ?? ''}`.trim() : null);
  };
  const rows = meals
    .map((m) => ({
      id: m.id,
      occurredAt: iso(m.occurredAt),
      slot: m.slot ?? null,
      dish: m.dish ?? '',
      foods: [...list(m.foodIds).map((id) => names.get(id) ?? id), ...list(m.freeFoods)].join('; '),
      foodIds: list(m.foodIds).join(' '),
      amount: amount(m.amount),
      reaction: m.reaction ?? null,
      symptoms: list(m.symptoms).join(' '),
      note: m.note ?? '',
      recipeId: m.recipeId ?? null,
      author: m.author?.name || null,
      createdAt: iso(m.createdAt),
    }))
    .sort((a, b) => String(a.occurredAt).localeCompare(String(b.occurredAt)));
  return csvOf(
    [
      'id',
      'occurredAt',
      'slot',
      'dish',
      'foods',
      'foodIds',
      'amount',
      'reaction',
      'symptoms',
      'note',
      'recipeId',
      'author',
      'createdAt',
    ],
    rows,
  );
}

/** Ingredient units as the app shows them ("thìa canh", D-086), else the stored code. */
const unitLabels: Record<Locale, Record<string, string>> = {
  vi: { g: 'g', ml: 'ml', tbsp: 'thìa canh', tsp: 'thìa cà phê', bowl: 'chén', piece: 'miếng' },
  en: { g: 'g', ml: 'ml', tbsp: 'tbsp', tsp: 'tsp', bowl: 'bowl', piece: 'piece' },
};

/**
 * The "Công thức nhà mình" sheet (D-086, plan §12 #2): live family recipes, oldest first, the
 * family's own words (ingredient names as written, "Cà rốt 30 g; Gạo 2 thìa canh"), numbered
 * steps, who wrote it and when. No photos.
 */
async function familyRecipesCsv(db: Firestore, babyId: string, locale: Locale): Promise<string> {
  const snap = await db.collection(`babies/${babyId}/recipes`).where('deleted', '==', false).get();
  const units = locale === 'en' ? unitLabels.en : unitLabels.vi;
  const ingredient = (x: unknown) => {
    const i = (x ?? {}) as { name?: unknown; qty?: unknown; unit?: unknown };
    const name = typeof i.name === 'string' ? i.name : '';
    const unit = typeof i.unit === 'string' ? (units[i.unit] ?? i.unit) : '';
    const qty = typeof i.qty === 'number' ? `${i.qty} ${unit}`.trim() : '';
    return [name, qty].filter(Boolean).join(' ');
  };
  const items = (v: unknown) => (Array.isArray(v) ? v : []);
  const rows = snap.docs
    .map((d) => d.data())
    .map((r) => ({
      id: r.id,
      title: r.title ?? '',
      ingredients: items(r.ingredients).map(ingredient).filter(Boolean).join('; '),
      steps: items(r.steps)
        .filter((s): s is string => typeof s === 'string')
        .map((s, i) => `${i + 1}. ${s}`)
        .join('\n'),
      note: r.note ?? '',
      author: r.author?.name || null,
      createdAt: iso(r.createdAt),
      updatedAt: iso(r.updatedAt),
    }))
    .sort((a, b) => String(a.createdAt).localeCompare(String(b.createdAt)));
  return csvOf(
    ['id', 'title', 'ingredients', 'steps', 'note', 'author', 'createdAt', 'updatedAt'],
    rows,
  );
}

async function* careEntries(
  db: Firestore,
  babyId: string,
  locale: Locale = 'vi',
  viewerUid?: string,
) {
  const records = await db
    .collection(`babies/${babyId}/records`)
    .where('deleted', '==', false)
    .get();
  const rows = records.docs
    .map((d) => d.data())
    .map((r) => ({
      id: r.id,
      type: r.type,
      occurredAt: iso(r.occurredAt),
      endedAt: iso(r.endedAt),
      data: r.data,
      note: r.note ?? null,
      author: r.author?.name || null,
      createdAt: iso(r.createdAt),
    }))
    .sort((a, b) => String(a.occurredAt).localeCompare(String(b.occurredAt)));
  const { Readable } = await import('node:stream');
  const json = JSON.stringify(
    { babyId, exportedAt: new Date().toISOString(), records: rows },
    null,
    2,
  );
  const header = ['id', 'type', 'occurredAt', 'endedAt', 'data', 'note', 'author', 'createdAt'];
  const csv = [
    header.join(','),
    ...rows.map((r) => header.map((h) => csvCell((r as Record<string, unknown>)[h])).join(',')),
  ].join('\n');
  yield { name: 'care.json', open: async () => Readable.from([Buffer.from(json)]) };
  const [notebook, work, exclusions, personal] = await Promise.all([
    db.collection(`babies/${babyId}/notebook`).get(),
    db.collection(`babies/${babyId}/careWork`).get(),
    db.collection(`babies/${babyId}/personalizationExclusions`).get(),
    viewerUid
      ? db.doc(`users/${viewerUid}/personalization/${babyId}`).get()
      : Promise.resolve(null),
  ]);
  const personalization = JSON.stringify(
    {
      notes: notebook.docs
        .map((d) => d.data())
        .filter((n) => n.scope === 'baby' || n.authorUid === viewerUid),
      careWork: work.docs.map((d) => d.data()),
      exclusions: exclusions.docs.map((d) => ({ id: d.id, ...d.data() })),
      personal: personal?.data() ?? null,
    },
    null,
    2,
  );
  yield {
    name: 'personalization.json',
    open: async () => Readable.from([Buffer.from(personalization)]),
  };
  yield { name: 'care.csv', open: async () => Readable.from([Buffer.from(`${BOM}${csv}`)]) };
  // Ăn dặm meals (D-085 #3) read their own collection; the care record types stay as they are.
  const meals = await mealsCsv(db, babyId, locale);
  yield { name: 'meals.csv', open: async () => Readable.from([Buffer.from(meals)]) };
  // The family's own recipes (D-086), likewise from their collection.
  const recipes = await familyRecipesCsv(db, babyId, locale);
  yield { name: 'family-recipes.csv', open: async () => Readable.from([Buffer.from(recipes)]) };
}

async function* mediaEntries(
  db: Firestore,
  babyId: string,
  open: (path: string) => Promise<Readable>,
) {
  const media = await db
    .collection(`babies/${babyId}/media`)
    .where('status', '==', 'ready')
    .where('deleted', '==', false)
    .get();
  for (const d of media.docs) {
    const path = (d.get('paths.original') as string | null | undefined) ?? null;
    if (!path) continue;
    const at = (d.get('captureAt') as Timestamp).toDate().toISOString().replace(/[:.]/g, '-');
    const ext = d.get('type') === 'video' ? path.split('.').pop() || 'mp4' : 'jpg';
    yield { name: `${at}_${d.id.slice(-8)}.${ext}`, open: () => open(path) };
  }
}

export const exportPath = (uid: string, jobId: string, kind: string) =>
  `exports/${uid}/${jobId}/child-life-${kind}.zip`;

/** Builds one export into the private exports area; the link lives 24 h (R-187). */
export async function runExport(
  db: Firestore,
  store: PurgeStore,
  openObject: (path: string) => Promise<Readable>,
  jobId: string,
  now: Date,
  ttlHours: number,
): Promise<'ready' | 'failed' | 'skipped'> {
  const ref = db.doc(`dataJobs/${jobId}`);
  const job = await ref.get();
  if (!job.exists || job.get('state') !== 'queued') return 'skipped';
  await ref.update({ state: 'running', updatedAt: now });
  const uid = job.get('uid') as string;
  const kind = job.get('exportKind') as string;
  const babyId = job.get('babyId') as string;
  try {
    const path = exportPath(uid, jobId, kind);
    const entries =
      kind === 'care'
        ? careEntries(db, babyId, (job.get('locale') as Locale | undefined) ?? 'vi', uid)
        : mediaEntries(db, babyId, openObject);
    const bytes = await store.zip(path, entries);
    // "Tải về" straight from the email: a 24 h token whose hash stays on the job; the page re-checks
    // the right at every click (exportDownload, P-123).
    const token = randomBytes(24).toString('base64url');
    await db.runTransaction(async (tx) => {
      tx.update(ref, {
        state: 'ready',
        path,
        bytes,
        readyAt: now,
        expiresAt: new Date(now.getTime() + ttlHours * HOUR_MS),
        downloadTokenHash: sha(token),
        updatedAt: now,
      });
      const email = job.get('email') as string | null;
      const size =
        bytes >= 1024 ** 3
          ? `${(bytes / 1024 ** 3).toFixed(1)} GB`
          : `${Math.max(1, Math.round(bytes / 1024 ** 2))} MB`;
      if (email) {
        queueMail(
          tx,
          db,
          email,
          'exportReady',
          job.get('locale') as Locale,
          { jobId, token, size },
          now,
        );
      }
    });
    return 'ready';
  } catch (error) {
    await ref.update({ state: 'failed', error: String(error).slice(0, 300), updatedAt: now });
    return 'failed';
  }
}

/** Expired exports are deleted; staff only ever see the status (P-123). */
export async function expireExports(db: Firestore, store: PurgeStore, now: Date): Promise<number> {
  const snap = await db
    .collection('dataJobs')
    .where('state', '==', 'ready')
    .where('expiresAt', '<=', now)
    .limit(100)
    .get();
  for (const d of snap.docs) {
    await store.deletePrefix(`exports/${d.get('uid')}/${d.id}/`);
    await d.ref.update({ state: 'expired', path: null, updatedAt: now });
  }
  return snap.size;
}

// ---------- Help & contact (G-057, G-073) ----------

/** "Trợ giúp & liên hệ": a numbered ticket (CL-####); diagnostics only with consent. */
export async function createSupportTicket(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
  deps: StorageDeps,
): Promise<{ ticket: string }> {
  const req = parse(createSupportTicketSchema, data);
  if (caller.anonymous || !caller.email)
    throw new AccountError('failed-precondition', 'email-required');
  const id = `t_${sha(`${caller.uid}:${req.requestId}`).slice(0, 20)}`;
  return db.runTransaction(async (tx) => {
    const ref = db.doc(`supportTickets/${id}`);
    const existing = await tx.get(ref);
    if (existing.exists) return { ticket: existing.get('ticket') as string };
    const counterRef = db.doc('counters/supportTickets');
    const counter = await tx.get(counterRef);
    const n = ((counter.get('next') as number | undefined) ?? 1001) as number;
    const ticket = `CL-${n}`;
    tx.set(counterRef, { next: n + 1 }, { merge: true });
    tx.create(ref, {
      ticket,
      category: req.category,
      message: req.message,
      diagnostics: req.diagnostics,
      uid: caller.uid,
      email: caller.email,
      locale: req.locale,
      status: 'new',
      createdAt: now,
      // P-124: kept one year after closing; excluded from analytics.
    });
    queueMail(tx, db, caller.email!, 'supportAck', req.locale, { ticket }, now);
    queueMail(
      tx,
      db,
      deps.staffInbox,
      'supportStaff',
      'vi',
      { ticket, category: req.category },
      now,
    );
    return { ticket };
  });
}

export const _test = { sameName, isActive, csvCell, mealsCsv, familyRecipesCsv };
