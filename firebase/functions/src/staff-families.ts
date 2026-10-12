import { randomBytes } from 'node:crypto';
import {
  FAMILY_ACTIVE_DAYS,
  STAFF_TRANSFER_HOURS,
  answerStaffTransferSchema,
  cancelTransferSchema,
  defaultLimits,
  familyRefSchema,
  listFamiliesSchema,
  maskEmail,
  openTransferSchema,
  relations,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Query,
} from 'firebase-admin/firestore';
import { AccountError, offerOwnership, queueMail, type AccountCaller } from './account.js';
import { StaffError, familyCode, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Gia đình (Figma A15–A17, P-136). Staff look families up by their anonymous code and see counts:
 * never a family or baby name, an age, a full email, a custom relationship label (it can hold a
 * name) or a device name. `familyDirectory/{familyId}` is the read model for paging and filters,
 * rebuilt from the source on writes that matter, nightly, and whenever a detail is opened.
 * Ownership transfer opened by staff reuses the owner's own offer (P-001 / P-003): the current
 * owner agrees in the app within 48 hours, then the candidate accepts as usual.
 */

export interface FamilyDeps {
  emailOf(uid: string): Promise<string | null>;
  uidByEmail(email: string): Promise<string | null>;
}

const DAY_MS = 86_400_000;
const PAGE = 25;
const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;
const isoOrNull = (v: unknown) => (ms(v) ? new Date(ms(v)).toISOString() : null);

type Role = 'coParent' | 'caregiver' | 'relative';

interface MemberFacts {
  uid: string;
  relation: string;
  isOwner: boolean;
  roles: Array<{ baby: number; role: Role }>;
  lastActiveAt: number;
  /** Owns another family, so cannot receive this one (R-046). */
  ownsFamily: boolean;
  devices: Array<{
    platform: string;
    appVersion: string;
    model: string | null;
    language: string | null;
    at: number;
  }>;
}

/** Everything the directory and the detail need, read from the source documents. */
async function gather(db: Firestore, familyId: string, now: Date) {
  const family = await db.doc(`families/${familyId}`).get();
  if (!family.exists) return null;
  const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];
  const members = new Map<string, MemberFacts>();
  const babies: Array<{
    ordinal: number;
    records7d: number;
    media7d: number;
    stories: number;
    lastWriteAt: number;
  }> = [];
  const since = new Date(now.getTime() - 7 * DAY_MS);
  for (const [i, babyId] of babyIds.entries()) {
    const snap = await db
      .collection(`babies/${babyId}/members`)
      .where('status', '==', 'active')
      .get();
    for (const m of snap.docs) {
      const uid = (m.get('uid') as string | undefined) ?? m.id;
      const rel = m.get('relation') as string;
      const facts = members.get(uid) ?? {
        uid,
        // A custom label ("Khác…") is free text and may hold a name: staff only see "Khác".
        relation: (relations as readonly string[]).includes(rel) ? rel : 'other',
        isOwner: false,
        roles: [],
        lastActiveAt: 0,
        ownsFamily: false,
        devices: [],
      };
      facts.isOwner ||= m.get('isOwner') === true || uid === family.get('ownerUid');
      facts.roles.push({ baby: i + 1, role: m.get('role') as Role });
      members.set(uid, facts);
    }
    const count = async (q: Query) => (await q.count().get()).data().count;
    const [records7d, media7d, stories, last] = await Promise.all([
      count(db.collection(`babies/${babyId}/records`).where('createdAt', '>=', since)),
      count(db.collection(`babies/${babyId}/media`).where('createdAt', '>=', since)),
      count(db.collection(`babies/${babyId}/stories`)),
      db
        .collection(`babies/${babyId}/records`)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .select('createdAt')
        .get(),
    ]);
    babies.push({
      ordinal: i + 1,
      records7d,
      media7d,
      stories,
      lastWriteAt: last.empty ? 0 : ms(last.docs[0]!.get('createdAt')),
    });
  }
  const users = members.size
    ? await db.getAll(...[...members.keys()].map((u) => db.doc(`users/${u}`)))
    : [];
  for (const u of users) {
    const m = members.get(u.id)!;
    m.ownsFamily =
      ((u.get('ownedBabyCount') as number | undefined) ?? 0) > 0 &&
      u.get('ownedFamilyId') !== familyId;
  }
  for (const m of members.values()) {
    const devices = await db.collection(`users/${m.uid}/devices`).get();
    for (const d of devices.docs) {
      if (d.get('signedOutAt')) continue;
      const at = Math.max(ms(d.get('lastActiveAt')), ms(d.get('updatedAt')));
      m.devices.push({
        platform: (d.get('platform') as string) ?? '',
        appVersion: (d.get('appVersion') as string) ?? '',
        model: (d.get('model') as string | undefined) ?? null,
        language: (d.get('language') as string | undefined) ?? null,
        at,
      });
      m.lastActiveAt = Math.max(m.lastActiveAt, at);
    }
  }
  const invites = await db.collection('invites').where('familyId', '==', familyId).get();
  return { family, babyIds, members: [...members.values()], babies, invites: invites.docs };
}

type Gathered = NonNullable<Awaited<ReturnType<typeof gather>>>;

function summarize(g: Gathered, now: Date) {
  const usedBytes = (g.family.get('usedBytes') as number) ?? 0;
  const quotaBytes = (g.family.get('quotaBytes') as number) ?? defaultLimits.familyQuotaBytes;
  const recent = now.getTime() - 30 * DAY_MS;
  const platforms = [
    ...new Set(
      g.members.flatMap((m) => m.devices.filter((d) => d.at >= recent).map((d) => d.platform)),
    ),
  ]
    .filter((p) => p === 'ios' || p === 'android')
    .sort();
  const lastActiveAt = Math.max(
    0,
    ...g.members.map((m) => m.lastActiveAt),
    ...g.babies.map((b) => b.lastWriteAt),
  );
  const pending = g.invites.filter(
    (i) => i.get('status') === 'pending' && ms(i.get('expiresAt')) > now.getTime(),
  ).length;
  const carers = g.members.filter((m) =>
    m.roles.some((r) => r.role === 'coParent' || r.role === 'caregiver'),
  ).length;
  return {
    usedBytes,
    quotaBytes,
    platforms,
    platformKey: platforms.length === 2 ? 'both' : (platforms[0] ?? 'none'),
    lastActiveAt,
    activity:
      lastActiveAt >= now.getTime() - FAMILY_ACTIVE_DAYS * DAY_MS
        ? ('active' as const)
        : ('low' as const),
    pending,
    carers,
    members: g.members.length,
    babies: g.babyIds.length,
  };
}

/** Rebuilds one `familyDirectory` row (or removes it when the family is gone). */
export async function refreshFamilyDirectory(
  db: Firestore,
  familyId: string,
  now: Date,
  deps: FamilyDeps,
) {
  const ref = db.doc(`familyDirectory/${familyId}`);
  const g = await gather(db, familyId, now);
  if (!g) {
    await ref.delete();
    return null;
  }
  const s = summarize(g, now);
  const ownerUid = g.family.get('ownerUid') as string;
  const row = {
    code: familyCode(familyId),
    ownerMasked: maskEmail(await deps.emailOf(ownerUid)),
    members: s.members,
    carers: s.carers,
    multiCarer: s.carers >= 2,
    pendingInvites: s.pending,
    babies: s.babies,
    usedBytes: s.usedBytes,
    quotaBytes: s.quotaBytes,
    over80: s.quotaBytes > 0 && s.usedBytes / s.quotaBytes >= 0.8,
    expanded: s.quotaBytes > defaultLimits.familyQuotaBytes,
    platforms: s.platforms,
    platformKey: s.platformKey,
    lastActiveAt: s.lastActiveAt ? new Date(s.lastActiveAt) : null,
    activity: s.activity,
    createdAt: g.family.get('createdAt') ?? null,
    updatedAt: now,
  };
  await ref.set(row);
  return { row, gathered: g, summary: s };
}

function directoryRow(d: DocumentSnapshot) {
  return {
    code: d.get('code') as string,
    owner: d.get('ownerMasked') as string,
    members: d.get('members') as number,
    carers: d.get('carers') as number,
    pendingInvites: d.get('pendingInvites') as number,
    babies: d.get('babies') as number,
    usedBytes: d.get('usedBytes') as number,
    quotaBytes: d.get('quotaBytes') as number,
    platforms: (d.get('platforms') as string[]) ?? [],
    lastActiveAt: isoOrNull(d.get('lastActiveAt')),
    activity: d.get('activity') as 'active' | 'low',
  };
}

/** A15: KPIs, status tabs, filters and pages of 25 (newest activity first). */
export async function listFamilies(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  deps: FamilyDeps,
) {
  requireStaff(staff, 'families.view');
  const req = parse(listFamiliesSchema, data);
  const dir = db.collection('familyDirectory');
  const count = async (q: Query) => (await q.count().get()).data().count;
  const [total, active, low, multi, nearFull] = await Promise.all([
    count(dir),
    count(dir.where('activity', '==', 'active')),
    count(dir.where('activity', '==', 'low')),
    count(dir.where('multiCarer', '==', true)),
    count(dir.where('over80', '==', true)),
  ]);
  const kpis = { total, active, low, multiCarerRate: total ? multi / total : null, nearFull };

  const q = req.q?.trim();
  if (q) {
    // A code, or an exact email: matched here, never sent back (only the masked owner shows).
    let ids: string[] = [];
    if (/^F-[A-Z2-9]{4}$/i.test(q)) {
      const hit = await dir.where('code', '==', q.toUpperCase()).limit(5).get();
      ids = hit.docs.map((d) => d.id);
    } else if (q.includes('@')) {
      const uid = await deps.uidByEmail(q.toLowerCase());
      if (uid) {
        const memberships = await db
          .collectionGroup('members')
          .where('uid', '==', uid)
          .where('status', '==', 'active')
          .select('babyId')
          .get();
        const babyIds = [...new Set(memberships.docs.map((m) => m.get('babyId') as string))];
        const babies = babyIds.length
          ? await db.getAll(...babyIds.map((b) => db.doc(`babies/${b}`)))
          : [];
        ids = [...new Set(babies.map((b) => b.get('familyId') as string).filter(Boolean))];
      }
    }
    const docs = ids.length ? await db.getAll(...ids.map((id) => dir.doc(id))) : [];
    const rows = docs.filter((d) => d.exists).map(directoryRow);
    return { kpis, rows, next: null };
  }

  let query: Query = dir;
  if (req.activity !== 'all') query = query.where('activity', '==', req.activity);
  if (req.platform !== 'all') query = query.where('platformKey', '==', req.platform);
  if (req.storage !== 'all') query = query.where(req.storage, '==', true);
  query = query.orderBy('lastActiveAt', 'desc').limit(PAGE + 1);
  if (req.after) {
    const cursor = await dir.doc(req.after).get();
    if (cursor.exists) query = query.startAfter(cursor);
  }
  const snap = await query.get();
  const page = snap.docs.slice(0, PAGE);
  return {
    kpis,
    rows: page.map(directoryRow),
    next: snap.docs.length > PAGE ? page[page.length - 1]!.id : null,
  };
}

async function familyIdOf(db: Firestore, code: string): Promise<string> {
  const hit = await db.collection('familyDirectory').where('code', '==', code).limit(1).get();
  if (hit.empty) throw new StaffError('not-found', 'not-found');
  return hit.docs[0]!.id;
}

/** Members who may become owner: Cùng nuôi of every baby, and not the owner (P-003). */
function candidates(g: Gathered): string[] {
  return g.members
    .filter((m) => !m.isOwner && !m.ownsFamily)
    .filter((m) =>
      g.babyIds.every((_, i) => m.roles.some((r) => r.baby === i + 1 && r.role === 'coParent')),
    )
    .map((m) => m.uid);
}

/** A16: counts only, logged as a view (`family.view`, A16 "Mọi lượt xem … được ghi vào nhật ký"). */
export async function familyDetail(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  deps: FamilyDeps,
) {
  const s = requireStaff(staff, 'families.view');
  const { code } = parse(familyRefSchema, data);
  const familyId = await familyIdOf(db, code);
  const built = await refreshFamilyDirectory(db, familyId, now, deps);
  if (!built) throw new StaffError('not-found', 'not-found');
  const { gathered: g, summary } = built;
  const uids = g.members.map((m) => m.uid);
  const masked = new Map(
    await Promise.all(uids.map(async (u) => [u, maskEmail(await deps.emailOf(u))] as const)),
  );
  const tickets = uids.length
    ? await db.collection('supportTickets').where('uid', 'in', uids.slice(0, 30)).get()
    : null;
  const transferSnap = await db
    .collection('familyTransfers')
    .where('familyId', '==', familyId)
    .where('state', '==', 'pending')
    .get();
  const transfer = transferSnap.docs.find((t) => ms(t.get('expiresAt')) > now.getTime());
  const languages = g.members
    .flatMap((m) => m.devices.map((d) => d.language))
    .filter(Boolean) as string[];
  const language =
    languages.sort(
      (a, b) => languages.filter((x) => x === b).length - languages.filter((x) => x === a).length,
    )[0] ?? null;
  const eligible = candidates(g);
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    { action: 'family.view', category: 'families', target: code, reason: null },
    now,
  );
  await batch.commit();
  return {
    code,
    createdAt: isoOrNull(g.family.get('createdAt')),
    owner: masked.get(g.family.get('ownerUid') as string) ?? '—',
    platforms: summary.platforms,
    usedBytes: summary.usedBytes,
    quotaBytes: summary.quotaBytes,
    expanded: summary.quotaBytes > defaultLimits.familyQuotaBytes,
    language,
    lastActiveAt: summary.lastActiveAt ? new Date(summary.lastActiveAt).toISOString() : null,
    activity: summary.activity,
    members: g.members
      .map((m) => {
        const device = [...m.devices].sort((a, b) => b.at - a.at)[0];
        return {
          uid: m.uid,
          email: masked.get(m.uid) ?? '—',
          relation: m.relation,
          isOwner: m.isOwner,
          roles: m.roles,
          lastActiveAt: m.lastActiveAt ? new Date(m.lastActiveAt).toISOString() : null,
          platform: device?.platform ?? null,
          model: device?.model ?? null,
          appVersion: device?.appVersion ?? null,
          eligible: eligible.includes(m.uid),
        };
      })
      .sort((a, b) => Number(b.isOwner) - Number(a.isOwner)),
    invites: g.invites
      .filter((i) => i.get('status') === 'pending')
      .map((i) => ({
        relation: (relations as readonly string[]).includes(i.get('relation') as string)
          ? (i.get('relation') as string)
          : 'other',
        role: i.get('role') as Role,
        state: ms(i.get('expiresAt')) > now.getTime() ? ('pending' as const) : ('expired' as const),
        createdAt: isoOrNull(i.get('createdAt')),
      })),
    babies: g.babies.map((b) => ({
      ordinal: b.ordinal,
      records7d: b.records7d,
      media7d: b.media7d,
      stories: b.stories,
    })),
    tickets: (tickets?.docs ?? [])
      .map((t) => ({
        id: t.id,
        ticket: t.get('ticket') as string,
        title: ((t.get('message') as string) ?? '').split('\n')[0]!.slice(0, 80),
        status: t.get('status') as string,
        createdAt: isoOrNull(t.get('createdAt')),
      }))
      .sort((a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? ''))
      .slice(0, 5),
    transfer: transfer
      ? {
          id: transfer.id,
          to: transfer.get('toMasked') as string,
          ticket: (transfer.get('ticket') as string | null) ?? null,
          openedBy: transfer.get('openedByName') as string,
          expiresAt: isoOrNull(transfer.get('expiresAt')),
        }
      : null,
  };
}

/**
 * A17 "Gửi yêu cầu xác nhận": staff open a request on the owner's behalf; the owner sees it in the
 * app and by email and must agree within 48 hours.
 */
export async function openTransfer(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  deps: FamilyDeps,
) {
  const s = requireStaff(staff, 'families.transfer');
  const req = parse(openTransferSchema, data);
  const familyId = await familyIdOf(db, req.code);
  const g = await gather(db, familyId, now);
  if (!g) throw new StaffError('not-found', 'not-found');
  if (!candidates(g).includes(req.toUid))
    throw new StaffError('failed-precondition', 'not-eligible');
  const ownerUid = g.family.get('ownerUid') as string;
  const [ownerEmail, toEmail] = await Promise.all([
    deps.emailOf(ownerUid),
    deps.emailOf(req.toUid),
  ]);
  const id = `ft_${randomBytes(10).toString('hex')}`;
  const expiresAt = new Date(now.getTime() + STAFF_TRANSFER_HOURS * 3_600_000);
  await db.runTransaction(async (tx) => {
    const open = await tx.get(
      db
        .collection('familyTransfers')
        .where('familyId', '==', familyId)
        .where('state', '==', 'pending'),
    );
    if (open.docs.some((t) => ms(t.get('expiresAt')) > now.getTime())) {
      throw new StaffError('failed-precondition', 'transfer-pending');
    }
    const toMasked = maskEmail(toEmail);
    tx.create(db.doc(`familyTransfers/${id}`), {
      familyId,
      code: req.code,
      fromUid: ownerUid,
      toUid: req.toUid,
      toMasked,
      ticket: req.ticket,
      reason: req.reason,
      openedByUid: s.uid,
      openedByName: s.name,
      openedAt: now,
      expiresAt,
      state: 'pending',
    });
    // What the owner's app shows (Tôi → Tài khoản & đăng nhập), readable only by them.
    tx.set(
      db.doc(`users/${ownerUid}`),
      {
        pendingStaffTransfer: { transferId: id, toMasked, ticket: req.ticket, at: now, expiresAt },
      },
      { merge: true },
    );
    if (ownerEmail) {
      queueMail(
        tx,
        db,
        ownerEmail,
        'ownershipStaffRequest',
        'vi',
        { toEmail: toMasked, ticket: req.ticket ?? '—' },
        now,
      );
    }
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'family.transferOpen',
        category: 'families',
        target: req.code,
        reason: req.reason,
        detail: { to: toMasked, ticket: req.ticket },
      },
      now,
    );
  });
  return { transferId: id, expiresAt: expiresAt.toISOString() };
}

export async function cancelTransfer(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'families.transfer');
  const req = parse(cancelTransferSchema, data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`familyTransfers/${req.transferId}`);
    const t = await tx.get(ref);
    if (!t.exists || t.get('state') !== 'pending') throw new StaffError('not-found', 'not-found');
    tx.update(ref, { state: 'cancelled', closedAt: now, closedByUid: s.uid });
    tx.set(
      db.doc(`users/${t.get('fromUid')}`),
      { pendingStaffTransfer: FieldValue.delete() },
      { merge: true },
    );
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'family.transferCancel',
        category: 'families',
        target: t.get('code') as string,
        reason: req.reason,
      },
      now,
    );
  });
  return {};
}

/**
 * The owner's answer in the app. Agreeing makes the usual owner offer to the candidate (who then
 * accepts as in 13n); declining closes the request. Either way the request is done.
 */
export async function answerStaffTransfer(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
  emailOf: (uid: string) => Promise<string | null>,
) {
  const parsed = answerStaffTransferSchema.safeParse(data);
  if (!parsed.success) throw new AccountError('invalid-argument', 'malformed');
  const req = parsed.data;
  const ref = db.doc(`familyTransfers/${req.transferId}`);
  const t = await ref.get();
  if (!t.exists || t.get('fromUid') !== caller.uid)
    throw new AccountError('not-found', 'not-found');
  if (t.get('state') !== 'pending' || ms(t.get('expiresAt')) <= now.getTime()) {
    throw new AccountError('failed-precondition', 'not-pending');
  }
  if (req.accept) {
    await offerOwnership(db, caller, { toUid: t.get('toUid') as string }, now, emailOf);
  }
  await ref.update({ state: req.accept ? 'confirmed' : 'declined', closedAt: now });
  await db
    .doc(`users/${caller.uid}`)
    .set({ pendingStaffTransfer: FieldValue.delete() }, { merge: true });
  return { state: req.accept ? 'confirmed' : 'declined' };
}

/** Hourly: requests the owner did not answer in 48 hours. */
export async function expireTransfers(db: Firestore, now: Date) {
  const due = await db
    .collection('familyTransfers')
    .where('state', '==', 'pending')
    .where('expiresAt', '<=', now)
    .get();
  for (const t of due.docs) {
    await t.ref.update({ state: 'expired', closedAt: now });
    await db
      .doc(`users/${t.get('fromUid')}`)
      .set({ pendingStaffTransfer: FieldValue.delete() }, { merge: true });
  }
  return due.size;
}

/** Nightly (and after deploy): every family's directory row, so activity and status stay true. */
export async function refreshAllFamilies(db: Firestore, now: Date, deps: FamilyDeps) {
  const families = await db.collection('families').select().get();
  for (const f of families.docs) await refreshFamilyDirectory(db, f.id, now, deps);
  const known = new Set(families.docs.map((f) => f.id));
  const stale = await db.collection('familyDirectory').select().get();
  for (const d of stale.docs) if (!known.has(d.id)) await d.ref.delete();
  return families.size;
}
