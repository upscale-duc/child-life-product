import { createHash } from 'node:crypto';
import {
  aiBudgetSchema,
  closeTicketSchema,
  decideStorageSchema,
  defaultFlags,
  defaultLimits,
  flagsSchema,
  limitsSchema,
  listAuditSchema,
  listJobsSchema,
  listStorageRequestsSchema,
  listTicketsSchema,
  localDateIn,
  maskEmail,
  overviewRequestSchema,
  replyTicketSchema,
  rerunJobSchema,
  routineGrantGb,
  setFlagSchema,
  staffCan,
  ticketRefSchema,
  type Flags,
  type StaffAction,
  type StaffRole,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { queueMail } from './account.js';

/**
 * The staff portal's server (S15, Figma A01–A12). Staff are Firebase accounts with the `staff`
 * claim and roles (D-043, P-121/P-125). Every read returns counts, bytes, masked emails and family
 * codes only — never photos, videos, captions, care payloads or baby names. Every mutation checks
 * the role matrix, requires a reason and writes the append-only `staffAudit` log (A12, R-183).
 * The user's own ticket / request text is shown as typed (P-124).
 */

export class StaffError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'failed-precondition' | 'permission-denied' | 'not-found',
    readonly reason: string,
  ) {
    super(reason);
  }
}

export interface Staff {
  uid: string;
  name: string;
  roles: StaffRole[];
}

/** Reads accounts for the funnel and "Tài khoản tạo" (Admin Auth in production). */
export interface AccountLister {
  list(): Promise<Array<{ uid: string; email: string | null; createdAt: Date; verified: boolean }>>;
}

const DAY_MS = 86_400_000;
const GB = 1024 ** 3;
const ZONE = 'Asia/Ho_Chi_Minh';

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new StaffError('invalid-argument', 'malformed');
  return r.data as T;
}

export function requireStaff(staff: Staff | null, action: StaffAction): Staff {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  if (!staffCan(staff.roles, action)) throw new StaffError('permission-denied', 'role');
  return staff;
}

const roleLabel: Record<StaffRole, string> = {
  ops: 'Vận hành',
  support: 'Hỗ trợ',
  eng: 'Kỹ thuật',
  lead: 'Trưởng nhóm',
};

type AuditCategory = 'support' | 'storage' | 'data' | 'features';

/** One append-only entry (A12): time, actor, role, action, category, target, reason. */
function audit(
  tx: Transaction | FirebaseFirestore.WriteBatch,
  db: Firestore,
  staff: Staff,
  entry: {
    action: string;
    category: AuditCategory;
    target: string;
    reason: string | null;
    detail?: Record<string, unknown>;
  },
  now: Date,
) {
  const ref = db.collection('staffAudit').doc();
  const data = {
    ...entry,
    detail: entry.detail ?? null,
    actorUid: staff.uid,
    actorName: staff.name,
    actorRole: staff.roles.map((r) => roleLabel[r]).join(' · '),
    at: now,
  };
  (tx as Transaction).create(ref, data);
}

/** "F-7Q2K": an anonymous, stable family code (A04, A08). */
const B32 = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';
export function familyCode(familyId: string): string {
  const digest = createHash('sha256').update(`family:${familyId}`).digest();
  return `F-${Array.from(digest.subarray(0, 4), (b) => B32[b % B32.length]).join('')}`;
}

const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;
const iso = (v: unknown) => new Date(ms(v)).toISOString();
const median = (xs: number[]) => {
  if (!xs.length) return null;
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.floor(s.length / 2)]!;
};

async function familyShape(db: Firestore, familyId: string) {
  const family = await db.doc(`families/${familyId}`).get();
  const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];
  const people = new Set<string>();
  for (const b of babyIds) {
    const members = await db
      .collection(`babies/${b}/members`)
      .where('status', '==', 'active')
      .select()
      .get();
    members.docs.forEach((m) => people.add(m.id));
  }
  return { family, babies: babyIds.length, people: people.size };
}

// ---------- Sidebar badges ----------

/**
 * The sidebar counts: open tickets ("Tất cả"), pending storage requests, and data jobs that are
 * running or failed (the A06 badge counts what is in flight or needs a re-run).
 */
export async function badges(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'view');
  const count = async (q: FirebaseFirestore.Query) => (await q.count().get()).data().count;
  const [tickets, storage, deletions, exports] = await Promise.all([
    count(db.collection('supportTickets').where('status', 'in', ['new', 'claimed', 'waiting'])),
    count(db.collection('storageRequests').where('status', '==', 'open')),
    count(db.collection('deletionJobs').where('state', 'in', ['queued', 'running', 'failed'])),
    count(db.collection('dataJobs').where('state', 'in', ['queued', 'running', 'failed'])),
  ]);
  return { tickets, storage, jobs: deletions + exports };
}

// ---------- A02 Tổng quan ----------

export async function overview(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  accounts: AccountLister,
) {
  requireStaff(staff, 'view');
  const { days } = parse(overviewRequestSchema, data);
  const since = new Date(now.getTime() - days * DAY_MS);
  const prevSince = new Date(since.getTime() - days * DAY_MS);
  const babies = await db.collection('babies').select('familyId').get();
  const familyOf = new Map(babies.docs.map((b) => [b.id, b.get('familyId') as string]));

  const activity = async (from: Date, to: Date) => {
    const out: Array<{
      babyId: string;
      at: number;
      type: string | undefined;
      by: string | undefined;
    }> = [];
    for (const group of ['records', 'memories'] as const) {
      const snap = await db
        .collectionGroup(group)
        .where('createdAt', '>=', from)
        .where('createdAt', '<', to)
        .select('babyId', 'createdAt', 'type', 'createdBy')
        .get();
      for (const d of snap.docs) {
        out.push({
          babyId: (d.get('babyId') as string) ?? d.ref.parent.parent!.id,
          at: ms(d.get('createdAt')),
          type: group === 'records' ? (d.get('type') as string) : undefined,
          by: d.get('createdBy') as string | undefined,
        });
      }
    }
    return out;
  };
  const current = await activity(since, now);
  const previous = await activity(prevSince, since);
  const families = (rows: typeof current) =>
    new Set(rows.map((r) => familyOf.get(r.babyId)).filter(Boolean));
  const activeFamilies = families(current);

  // Daily active families (last [days] days, Vietnam dates).
  const byDay = new Map<string, Set<string>>();
  for (const r of current) {
    const day = localDateIn(ZONE, new Date(r.at));
    const f = familyOf.get(r.babyId);
    if (!f) continue;
    if (!byDay.has(day)) byDay.set(day, new Set());
    byDay.get(day)!.add(f);
  }
  const daily = Array.from({ length: days }, (_, i) => {
    const day = localDateIn(ZONE, new Date(now.getTime() - (days - 1 - i) * DAY_MS));
    return { date: day, families: byDay.get(day)?.size ?? 0 };
  });

  // Accounts and the getting-started funnel.
  const users = await accounts.list();
  const inWindow = users.filter((u) => u.createdAt >= since);
  const prevAccounts = users.filter((u) => u.createdAt >= prevSince && u.createdAt < since).length;
  const members = await db
    .collectionGroup('members')
    .select('uid', 'role', 'status', 'babyId')
    .get();
  const joined = new Set(members.docs.map((m) => m.get('uid') as string));
  const owners = new Set(
    (await db.collection('users').where('ownedBabyCount', '>', 0).select().get()).docs.map(
      (d) => d.id,
    ),
  );
  const loggers = new Set(
    current
      .filter((r) => r.type)
      .map((r) => r.by)
      .filter(Boolean) as string[],
  );
  const inviters = new Set(
    (
      await db.collection('invites').where('createdAt', '>=', since).select('inviterUid').get()
    ).docs.map((d) => d.get('inviterUid') as string),
  );
  const funnel = [
    { step: 'firstOpen', count: null as number | null },
    { step: 'account', count: inWindow.length },
    { step: 'verified', count: inWindow.filter((u) => u.verified).length },
    { step: 'baby', count: inWindow.filter((u) => owners.has(u.uid) || joined.has(u.uid)).length },
    { step: 'firstLog', count: inWindow.filter((u) => loggers.has(u.uid)).length },
    { step: 'invite', count: inWindow.filter((u) => inviters.has(u.uid)).length },
  ];

  // Families with two or more people logging care (Cùng nuôi / Người chăm sóc).
  const carers = new Map<string, Set<string>>();
  for (const m of members.docs) {
    if (
      m.get('status') !== 'active' ||
      !['coParent', 'caregiver'].includes(m.get('role') as string)
    )
      continue;
    const f = familyOf.get(m.get('babyId') as string);
    if (!f) continue;
    if (!carers.has(f)) carers.set(f, new Set());
    carers.get(f)!.add(m.get('uid') as string);
  }
  const multi = [...activeFamilies].filter((f) => (carers.get(f as string)?.size ?? 0) >= 2).length;

  // Weekly care logs by type, counts only.
  const weeks = Array.from({ length: 6 }, (_, i) => {
    const end = now.getTime() - (5 - i) * 7 * DAY_MS;
    return { start: end - 7 * DAY_MS, end, feed: 0, sleep: 0, diaper: 0 };
  });
  const sixWeeks = await db
    .collectionGroup('records')
    .where('createdAt', '>=', new Date(weeks[0]!.start))
    .select('type', 'createdAt')
    .get();
  for (const d of sixWeeks.docs) {
    const at = ms(d.get('createdAt'));
    const w = weeks.find((x) => at >= x.start && at < x.end);
    const t = d.get('type') as string;
    if (!w) continue;
    if (t === 'bottle' || t === 'breast') w.feed++;
    else if (t === 'sleep') w.sleep++;
    else if (t === 'diaper') w.diaper++;
  }

  return {
    kpis: {
      activeFamilies: activeFamilies.size,
      activeFamiliesPrev: families(previous).size,
      newAccounts: inWindow.length,
      newAccountsPrev: prevAccounts,
      setupRate: inWindow.length ? funnel[3]!.count! / inWindow.length : null,
      multiCarerRate: activeFamilies.size ? multi / activeFamilies.size : null,
    },
    daily,
    funnel,
    weekly: weeks.map((w) => ({
      weekStart: new Date(w.start).toISOString(),
      feed: w.feed,
      sleep: w.sleep,
      diaper: w.diaper,
    })),
    alerts: await alerts(db, now),
  };
}

/** "Cần xử lý" (A02): failed jobs, pending storage, slow videos, unclaimed tickets. */
async function alerts(db: Firestore, now: Date) {
  const failed = (
    await db.collection('deletionJobs').where('state', '==', 'failed').count().get()
  ).data().count;
  const pending = (
    await db.collection('storageRequests').where('status', '==', 'open').count().get()
  ).data().count;
  const stale = (
    await db
      .collection('supportTickets')
      .where('status', '==', 'new')
      .where('createdAt', '<', new Date(now.getTime() - 4 * 3_600_000))
      .count()
      .get()
  ).data().count;
  const videos = await db
    .collectionGroup('media')
    .where('type', '==', 'video')
    .where('status', '==', 'uploading')
    .select('createdAt')
    .get();
  const waiting = videos.docs.filter(
    (v) => now.getTime() - ms(v.get('createdAt')) > 2 * 60_000,
  ).length;
  return [
    ...(failed
      ? [{ severity: 'error', module: 'jobs', kind: 'deletionFailed', count: failed }]
      : []),
    ...(pending
      ? [{ severity: 'high', module: 'storage', kind: 'storagePending', count: pending }]
      : []),
    ...(waiting >= 15
      ? [{ severity: 'warn', module: 'system', kind: 'videoQueue', count: waiting }]
      : []),
    ...(stale
      ? [{ severity: 'wait', module: 'support', kind: 'ticketsUnclaimed', count: stale }]
      : []),
  ];
}

// ---------- A03 Hỗ trợ ----------

function ticketRow(d: DocumentSnapshot) {
  const message = (d.get('message') as string) ?? '';
  return {
    id: d.id,
    ticket: d.get('ticket') as string,
    title: message.split('\n')[0]!.slice(0, 80),
    category: d.get('category') as string,
    email: maskEmail(d.get('email') as string | null),
    status: d.get('status') as string,
    createdAt: iso(d.get('createdAt')),
    claimedBy: (d.get('claimedByName') as string | undefined) ?? null,
  };
}

export async function listTickets(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'view');
  const req = parse(listTicketsSchema, data);
  const all = await db.collection('supportTickets').orderBy('createdAt', 'desc').limit(300).get();
  const rows = all.docs.map(ticketRow);
  const open = rows.filter((r) => r.status !== 'closed');
  const counts = {
    open: open.length,
    new: rows.filter((r) => r.status === 'new').length,
    claimed: rows.filter((r) => r.status === 'claimed').length,
    waiting: rows.filter((r) => r.status === 'waiting').length,
  };
  const q = req.q?.trim().toLowerCase();
  const filtered = (
    req.status === 'open' ? rows : rows.filter((r) => r.status === req.status)
  ).filter((r) => !q || r.ticket.toLowerCase().includes(q) || r.email.toLowerCase().includes(q));
  return { counts, rows: filtered };
}

export async function ticketDetail(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'view');
  const { ticketId } = parse(ticketRefSchema, data);
  const t = await db.doc(`supportTickets/${ticketId}`).get();
  if (!t.exists) throw new StaffError('not-found', 'not-found');
  const uid = t.get('uid') as string;
  const memberships = await db
    .collectionGroup('members')
    .where('uid', '==', uid)
    .select('role', 'isOwner', 'babyId', 'status')
    .get();
  const active = memberships.docs.filter((m) => m.get('status') === 'active');
  const role = active.some((m) => m.get('isOwner'))
    ? 'owner'
    : ((active[0]?.get('role') as string | undefined) ?? null);
  const babyId = active[0]?.get('babyId') as string | undefined;
  let family: { babies: number; people: number; usedBytes: number; quotaBytes: number } | null =
    null;
  if (babyId) {
    const familyId = (await db.doc(`babies/${babyId}`).get()).get('familyId') as string;
    const shape = await familyShape(db, familyId);
    family = {
      babies: shape.babies,
      people: shape.people,
      usedBytes: (shape.family.get('usedBytes') as number) ?? 0,
      quotaBytes: (shape.family.get('quotaBytes') as number) ?? 0,
    };
  }
  return {
    ...ticketRow(t),
    // The user's own words, shown as typed (P-124).
    message: t.get('message') as string,
    role,
    family,
    diagnostics: (t.get('diagnostics') as Record<string, unknown> | null) ?? null,
    thread: ((t.get('thread') as Array<Record<string, unknown>> | undefined) ?? []).map((m) => ({
      ...m,
      at: iso(m.at),
    })),
  };
}

export async function claimTicket(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'support.claim');
  const { ticketId } = parse(ticketRefSchema, data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`supportTickets/${ticketId}`);
    const t = await tx.get(ref);
    if (!t.exists) throw new StaffError('not-found', 'not-found');
    if (t.get('status') !== 'new') throw new StaffError('failed-precondition', 'already-claimed');
    tx.update(ref, { status: 'claimed', claimedBy: s.uid, claimedByName: s.name, claimedAt: now });
    audit(
      tx,
      db,
      s,
      {
        action: 'support.claim',
        category: 'support',
        target: t.get('ticket') as string,
        reason: null,
      },
      now,
    );
  });
}

const wifiGuide = {
  vi: 'Video lớn tải lâu khi mạng yếu. Bạn thử bật Wi-Fi, mở Child Life và để app mở cho tới khi thanh tải xong nhé. Trong Kỷ niệm → hàng chờ tải, bật "Video chỉ tải qua Wi-Fi" để video tự đợi Wi-Fi.',
  en: 'Large videos upload slowly on weak connections. Please connect to Wi-Fi, open Child Life and keep it open until the upload finishes. In Memories → upload queue, turn on "Videos over Wi-Fi only" so videos wait for Wi-Fi.',
} as const;

/** "Gửi" / "Gửi hướng dẫn tải qua Wi-Fi": an email to the user; the ticket waits on them. */
export async function replyTicket(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'support.reply');
  const req = parse(replyTicketSchema, data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`supportTickets/${req.ticketId}`);
    const t = await tx.get(ref);
    if (!t.exists) throw new StaffError('not-found', 'not-found');
    const locale = (t.get('locale') as 'vi' | 'en' | undefined) ?? 'vi';
    const text = req.macro === 'wifiGuide' ? wifiGuide[locale] : req.text;
    tx.update(ref, {
      status: 'waiting',
      thread: FieldValue.arrayUnion({ by: s.name, text, at: now }),
      updatedAt: now,
    });
    const email = t.get('email') as string | null;
    if (email)
      queueMail(
        tx,
        db,
        email,
        'supportReply',
        locale,
        { ticket: t.get('ticket') as string, body: text },
        now,
      );
    audit(
      tx,
      db,
      s,
      {
        action: req.macro === 'wifiGuide' ? 'support.macro.wifiGuide' : 'support.reply',
        category: 'support',
        target: t.get('ticket') as string,
        reason: req.reason,
      },
      now,
    );
  });
}

export async function closeTicket(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'support.close');
  const req = parse(closeTicketSchema, data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`supportTickets/${req.ticketId}`);
    const t = await tx.get(ref);
    if (!t.exists) throw new StaffError('not-found', 'not-found');
    // P-124: kept one year after closing.
    tx.update(ref, {
      status: 'closed',
      closedAt: now,
      retainUntil: new Date(now.getTime() + 365 * DAY_MS),
    });
    audit(
      tx,
      db,
      s,
      {
        action: 'support.close',
        category: 'support',
        target: t.get('ticket') as string,
        reason: req.reason,
      },
      now,
    );
  });
}

// ---------- A04 / A05 Mở rộng dung lượng ----------

export async function listStorageRequests(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  accounts: AccountLister,
) {
  requireStaff(staff, 'view');
  const { status } = parse(listStorageRequestsSchema, data);
  const snap = await db.collection('storageRequests').orderBy('createdAt', 'desc').limit(200).get();
  const created = new Map((await accounts.list()).map((u) => [u.uid, u.createdAt]));
  const rows = [];
  for (const d of snap.docs.filter((x) => x.get('status') === status)) {
    const familyId = d.get('familyId') as string;
    const { family, babies, people } = await familyShape(db, familyId);
    const usage = (family.get('usage') as Record<string, Record<string, number>> | undefined) ?? {};
    const photos = Object.values(usage).reduce((s, u) => s + (u.photoBytes ?? 0), 0);
    const videos = Object.values(usage).reduce((s, u) => s + (u.videoBytes ?? 0), 0);
    const used = (family.get('usedBytes') as number) ?? 0;
    const quota = (family.get('quotaBytes') as number) ?? defaultLimits.familyQuotaBytes;
    rows.push({
      id: d.id,
      code: `MR-${d.id.slice(3, 7).toUpperCase()}`,
      family: familyCode(familyId),
      babies,
      people,
      usedBytes: used,
      quotaBytes: quota,
      requestedGb: d.get('amountGb') as number,
      message: (d.get('message') as string | null) ?? null,
      createdAt: iso(d.get('createdAt')),
      decidedAt: d.get('decidedAt') ? iso(d.get('decidedAt')) : null,
      grantedGb: (d.get('grantedGb') as number | undefined) ?? null,
      metrics: {
        photoBytes: photos,
        videoBytes: videos,
        otherBytes: Math.max(0, used - photos - videos),
        freeBytes: Math.max(0, quota - used),
        previousGrants: (family.get('grantsCount') as number | undefined) ?? 0,
        ownerCreatedAt: created.get(family.get('ownerUid') as string)?.toISOString() ?? null,
        requesterIsOwner: family.get('ownerUid') === d.get('requesterUid'),
      },
    });
  }
  const all = snap.docs;
  const open = all.filter((d) => d.get('status') === 'open');
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const grantedThisMonth = all.filter(
    (d) => d.get('status') === 'granted' && ms(d.get('decidedAt')) >= monthStart.getTime(),
  );
  const families = await db.collection('families').select('usedBytes', 'quotaBytes').get();
  const over80 = families.docs.filter((f) => {
    const q = (f.get('quotaBytes') as number) ?? 0;
    return q > 0 && ((f.get('usedBytes') as number) ?? 0) >= q * 0.8;
  }).length;
  const decided = all.filter(
    (d) => d.get('decidedAt') && ms(d.get('decidedAt')) >= now.getTime() - 30 * DAY_MS,
  );
  return {
    kpis: {
      pending: open.length,
      oldestAt: open.length ? iso(open[open.length - 1]!.get('createdAt')) : null,
      over80,
      grantedThisMonth: grantedThisMonth.length,
      grantedGbThisMonth: grantedThisMonth.reduce(
        (s, d) => s + ((d.get('grantedGb') as number) ?? 0),
        0,
      ),
      medianHours: median(
        decided.map((d) => (ms(d.get('decidedAt')) - ms(d.get('createdAt'))) / 3_600_000),
      ),
    },
    rows,
  };
}

/**
 * A05 "Duyệt và báo gia đình" / "Từ chối": quota += grant (> 20 GB or custom needs a team lead,
 * P-120); the family's queued uploads resume on their own; the requester gets an email and the
 * parents a generic in-app notice. The decision and its reason go to A12.
 */
export async function decideStorage(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'storage.decide');
  const req = parse(decideStorageSchema, data);
  if (
    req.decision === 'grant' &&
    (req.grantGb > 20 || !(routineGrantGb as readonly number[]).includes(req.grantGb))
  ) {
    requireStaff(staff, 'storage.large');
  }
  return db.runTransaction(async (tx) => {
    const ref = db.doc(`storageRequests/${req.requestId}`);
    const r = await tx.get(ref);
    if (!r.exists) throw new StaffError('not-found', 'not-found');
    if (r.get('status') !== 'open') throw new StaffError('failed-precondition', 'already-decided');
    const familyId = r.get('familyId') as string;
    const familyRef = db.doc(`families/${familyId}`);
    const family = await tx.get(familyRef);
    const quota =
      (family.get('quotaBytes') as number | undefined) ?? defaultLimits.familyQuotaBytes;
    const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];
    const parents = new Set<string>([family.get('ownerUid') as string]);
    for (const b of babyIds) {
      const p = await tx.get(
        db
          .collection(`babies/${b}/members`)
          .where('role', '==', 'coParent')
          .where('status', '==', 'active'),
      );
      p.docs.forEach((m) => parents.add(m.id));
    }
    const code = familyCode(familyId);
    const locale = (r.get('locale') as 'vi' | 'en' | undefined) ?? 'vi';
    const email = r.get('email') as string | null;
    if (req.decision === 'grant') {
      const next = quota + req.grantGb * GB;
      tx.update(familyRef, {
        quotaBytes: next,
        grantsCount: FieldValue.increment(1),
        storageNoticeState: 'ok',
        updatedAt: now,
      });
      tx.update(ref, {
        status: 'granted',
        grantedGb: req.grantGb,
        staffMessage: req.message,
        decidedBy: s.uid,
        decidedAt: now,
      });
      if (babyIds[0]) {
        tx.create(db.doc(`babies/${babyIds[0]}/notifications/storage_granted_${req.requestId}`), {
          kind: 'storageGranted',
          babyId: babyIds[0],
          count: req.grantGb,
          actor: null,
          recipients: [...parents],
          createdAt: now,
          delivered: false,
        });
      }
      if (email) {
        queueMail(
          tx,
          db,
          email,
          'storageGranted',
          locale,
          { amountGb: req.grantGb, quotaGb: String(next / GB), body: req.message },
          now,
        );
      }
      audit(
        tx,
        db,
        s,
        {
          action: 'storage.grant',
          category: 'storage',
          target: code,
          reason: req.reason,
          detail: { grantGb: req.grantGb, before: quota, after: next },
        },
        now,
      );
      return { quotaBytes: next };
    }
    tx.update(ref, {
      status: 'declined',
      staffMessage: req.message,
      decidedBy: s.uid,
      decidedAt: now,
    });
    if (email)
      queueMail(
        tx,
        db,
        email,
        'storageDeclined',
        locale,
        { amountGb: r.get('amountGb') as number, body: req.message },
        now,
      );
    audit(
      tx,
      db,
      s,
      {
        action: 'storage.decline',
        category: 'storage',
        target: code,
        reason: req.reason,
        detail: { requestedGb: r.get('amountGb') },
      },
      now,
    );
    return { quotaBytes: quota };
  });
}

// ---------- A06 / A07 Yêu cầu dữ liệu ----------

/** "DJ-2226": a short, stable job code shown in A06 and the audit log. */
export const jobCode = (jobId: string) =>
  `DJ-${createHash('sha256').update(jobId).digest('hex').slice(0, 4).toUpperCase()}`;

export async function listJobs(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  requireStaff(staff, 'view');
  const { kind } = parse(listJobsSchema, data);
  const since = new Date(now.getTime() - 30 * DAY_MS);
  const rows: Array<Record<string, unknown>> = [];
  if (kind !== 'export') {
    const jobs = await db.collection('deletionJobs').where('createdAt', '>=', since).get();
    for (const j of jobs.docs) {
      const steps = (j.get('steps') as string[]) ?? [];
      const step = (j.get('step') as number) ?? 0;
      rows.push({
        id: j.id,
        code: jobCode(j.id),
        type: j.get('kind') === 'baby' ? 'deleteBaby' : 'deleteAccount',
        email: maskEmail((j.get('email') as string | null) ?? null),
        createdAt: iso(j.get('createdAt')),
        progress: steps.length ? step / steps.length : 0,
        steps,
        step,
        failedStep: (j.get('failedStep') as string | undefined) ?? null,
        state: j.get('state') as string,
        finishedAt: j.get('finishedAt') ? iso(j.get('finishedAt')) : null,
      });
    }
  }
  if (kind !== 'deletion') {
    const jobs = await db.collection('dataJobs').where('createdAt', '>=', since).get();
    for (const j of jobs.docs) {
      rows.push({
        id: j.id,
        code: jobCode(j.id),
        type: j.get('exportKind') === 'media' ? 'exportMedia' : 'exportCare',
        email: maskEmail((j.get('email') as string | null) ?? null),
        createdAt: iso(j.get('createdAt')),
        progress: ['ready', 'expired'].includes(j.get('state') as string) ? 1 : 0,
        state: j.get('state') as string,
        expiresAt: j.get('expiresAt') ? iso(j.get('expiresAt')) : null,
        readyAt: j.get('readyAt') ? iso(j.get('readyAt')) : null,
      });
    }
  }
  rows.sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
  const running = rows.filter((r) => ['queued', 'running'].includes(r.state as string));
  const exportTimes = rows
    .filter((r) => r.readyAt)
    .map((r) => (Date.parse(r.readyAt as string) - Date.parse(r.createdAt as string)) / 60_000);
  const deletions = rows.filter((r) => String(r.type).startsWith('delete'));
  return {
    kpis: {
      running: running.length,
      runningExports: running.filter((r) => String(r.type).startsWith('export')).length,
      failed24h: rows.filter(
        (r) => r.state === 'failed' && Date.parse(r.createdAt as string) >= now.getTime() - DAY_MS,
      ).length,
      medianExportMinutes: median(exportTimes),
      deletionsDone: deletions.filter((r) => r.state === 'done').length,
      deletionsTotal: deletions.filter((r) => r.state === 'done' || r.state === 'failed').length,
    },
    rows,
  };
}

/** A07 "Chạy lại": a failed deletion resumes at its failed step (completed steps are skipped). */
export async function rerunJob(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  run: (jobId: string) => Promise<unknown>,
) {
  const s = requireStaff(staff, 'jobs.rerun');
  const req = parse(rerunJobSchema, data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`deletionJobs/${req.jobId}`);
    const j = await tx.get(ref);
    if (!j.exists) throw new StaffError('not-found', 'not-found');
    if (j.get('state') !== 'failed') throw new StaffError('failed-precondition', 'not-failed');
    tx.update(ref, { state: 'queued', attempts: 0, updatedAt: now, rerunBy: s.uid });
    audit(
      tx,
      db,
      s,
      {
        action: 'jobs.rerun',
        category: 'data',
        target: jobCode(req.jobId),
        reason: req.reason,
        detail: { from: j.get('failedStep') ?? null },
      },
      now,
    );
  });
  await run(req.jobId);
}

// ---------- A08 / A09 Hệ thống & AI ----------

export async function systemHealth(db: Firestore, staff: Staff | null, now: Date) {
  requireStaff(staff, 'view');
  const families = await db
    .collection('families')
    .select('usedBytes', 'quotaBytes', 'grantsCount', 'storageNoticeState', 'usageReconciledAt')
    .get();
  const buckets = [0, 0, 0, 0, 0, 0];
  let stored = 0;
  const near: Array<Record<string, unknown>> = [];
  const open = await db
    .collection('storageRequests')
    .where('status', '==', 'open')
    .select('familyId')
    .get();
  const pending = new Set(open.docs.map((d) => d.get('familyId') as string));
  for (const f of families.docs) {
    const used = (f.get('usedBytes') as number) ?? 0;
    const quota = (f.get('quotaBytes') as number) ?? defaultLimits.familyQuotaBytes;
    stored += used;
    if (((f.get('grantsCount') as number) ?? 0) > 0) buckets[5]!++;
    else buckets[used < GB ? 0 : used < 3 * GB ? 1 : used < 6 * GB ? 2 : used < 8 * GB ? 3 : 4]!++;
    if (quota > 0 && used >= quota * 0.8) {
      const { babies } = await familyShape(db, f.id);
      near.push({
        family: familyCode(f.id),
        babies,
        usedBytes: used,
        quotaBytes: quota,
        requested: pending.has(f.id),
      });
    }
  }
  near.sort(
    (a, b) =>
      (b.usedBytes as number) / (b.quotaBytes as number) -
      (a.usedBytes as number) / (a.quotaBytes as number),
  );
  const day = await db
    .collectionGroup('media')
    .where('createdAt', '>=', new Date(now.getTime() - DAY_MS))
    .select('status', 'type', 'createdAt')
    .get();
  const terminal = day.docs.filter((d) =>
    ['ready', 'unreadable', 'cancelled'].includes(d.get('status') as string),
  );
  const failed = day.docs.filter((d) => d.get('status') === 'unreadable').length;
  const videos = await db
    .collectionGroup('media')
    .where('type', '==', 'video')
    .where('status', '==', 'uploading')
    .select('createdAt')
    .get();
  const hourly = Array.from({ length: 24 }, (_, h) => {
    const at = now.getTime() - (23 - h) * 3_600_000;
    return videos.docs.filter((v) => ms(v.get('createdAt')) <= at).length;
  });
  return {
    kpis: {
      storedBytes: stored,
      over80: near.length,
      videosWaiting: videos.size,
      uploadFailureRate: terminal.length ? failed / terminal.length : 0,
    },
    histogram: buckets,
    families: families.size,
    videoQueue: hourly,
    videoThreshold: 15,
    nearQuota: near.slice(0, 20),
  };
}

export async function readAiBudget(db: Firestore, now: Date) {
  const month = now.toISOString().slice(0, 7);
  const parsed = aiBudgetSchema.safeParse((await db.doc('config/ai').get()).data());
  const b = parsed.success ? parsed.data : { monthlyBudgetVnd: 15_000_000, month, spentVnd: 0 };
  return b.month === month ? b : { ...b, month, spentVnd: 0 };
}

export async function aiStats(db: Firestore, staff: Staff | null, now: Date) {
  requireStaff(staff, 'view');
  const since = new Date(now.getTime() - 14 * DAY_MS);
  const drafts = await db
    .collectionGroup('stories')
    .where('origin', '==', 'ai')
    .where('createdAt', '>=', since)
    .select('createdAt', 'status', 'blocks')
    .get();
  const week = drafts.docs.filter((d) => ms(d.get('createdAt')) >= now.getTime() - 7 * DAY_MS);
  const saved = week.filter((d) => d.get('status') === 'saved');
  const edited = saved.filter((d) =>
    ((d.get('blocks') as Array<{ type: string; ai?: boolean }>) ?? []).some(
      (b) => b.type === 'paragraph' && b.ai === false,
    ),
  );
  const daily = Array.from({ length: 14 }, (_, i) => {
    const day = localDateIn(ZONE, new Date(now.getTime() - (13 - i) * DAY_MS));
    return {
      date: day,
      drafts: drafts.docs.filter((d) => localDateIn(ZONE, new Date(ms(d.get('createdAt')))) === day)
        .length,
    };
  });
  const budget = await readAiBudget(db, now);
  const flags = flagsSchema.safeParse((await db.doc('config/flags').get()).data());
  return {
    kpis: {
      drafts7d: week.length,
      savedRate: week.length ? saved.length / week.length : null,
      costPerDraftVnd: week.length ? Math.round(budget.spentVnd / Math.max(1, week.length)) : null,
      reports: 0,
    },
    outcomes: {
      editedSaved: edited.length,
      savedAsIs: saved.length - edited.length,
      left: week.length - saved.length,
    },
    daily,
    budget,
    rollout: flags.success ? flags.data.ai_story_drafts : launchedFlags.ai_story_drafts,
  };
}

// ---------- A10 / A11 Tính năng & phát hành ----------

/**
 * What runs when no flags document exists yet: the shipped features are on, AI drafts and unbuilt
 * features (lock widgets, Night care auto) are off. The first change writes the full set.
 */
export const launchedFlags: Flags = {
  ...structuredClone(defaultFlags),
  media_upload: { enabled: true, scope: 'all', percent: 0, notice: null },
  video_upload: { enabled: true, scope: 'all', percent: 0, notice: null },
  story_share_link: { enabled: true, scope: 'all', percent: 0, notice: null },
  invites: { enabled: true, scope: 'all', percent: 0, notice: null },
};

export async function readFlags(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'view');
  const flags = flagsSchema.safeParse((await db.doc('config/flags').get()).data());
  const limits = limitsSchema.safeParse((await db.doc('config/limits').get()).data());
  const last = await db
    .collection('staffAudit')
    .where('category', '==', 'features')
    .orderBy('at', 'desc')
    .limit(20)
    .get();
  const lastEdit = new Map<string, { by: string; at: string }>();
  for (const a of last.docs) {
    const key = a.get('target') as string;
    if (!lastEdit.has(key))
      lastEdit.set(key, { by: a.get('actorName') as string, at: iso(a.get('at')) });
  }
  return {
    flags: flags.success ? flags.data : launchedFlags,
    limits: limits.success ? limits.data : defaultLimits,
    lastEdit: Object.fromEntries(lastEdit),
    recent: last.docs.slice(0, 5).map((a) => ({
      action: a.get('action') as string,
      target: a.get('target') as string,
      by: a.get('actorName') as string,
      at: iso(a.get('at')),
      reason: a.get('reason') as string,
      detail: a.get('detail') ?? null,
    })),
  };
}

/** A10 switch / rollout step and A11 "Tắt tính năng": reason required; never changes rights. */
export async function setFlag(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(setFlagSchema, data);
  const s = requireStaff(staff, 'flags.rollout');
  await db.runTransaction(async (tx) => {
    const ref = db.doc('config/flags');
    const snap = await tx.get(ref);
    const parsed = flagsSchema.safeParse(snap.data());
    const flags: Flags = parsed.success ? parsed.data : structuredClone(launchedFlags);
    const before = flags[req.key];
    // Turning a feature on or off is a kill switch (Kỹ thuật); moving a rollout step is Vận hành.
    if (before.enabled !== req.enabled) requireStaff(staff, 'flags.toggle');
    flags[req.key] = {
      enabled: req.enabled,
      scope: req.scope,
      percent: req.scope === 'percent' ? req.percent : 0,
      notice: req.enabled ? null : req.notice,
    };
    tx.set(ref, flags);
    audit(
      tx,
      db,
      s,
      {
        action:
          before.enabled !== req.enabled
            ? req.enabled
              ? 'flags.on'
              : 'flags.off'
            : 'flags.rollout',
        category: 'features',
        target: req.key,
        reason: req.reason,
        detail: { before, after: flags[req.key] },
      },
      now,
    );
  });
}

// ---------- A12 Nhật ký thao tác ----------

export async function listAudit(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  exporting = false,
) {
  const s = requireStaff(staff, exporting ? 'audit.export' : 'view');
  const req = parse(listAuditSchema, data);
  let q = db
    .collection('staffAudit')
    .where('at', '>=', new Date(now.getTime() - req.days * DAY_MS))
    .orderBy('at', 'desc')
    .limit(500);
  if (req.category !== 'all') q = q.where('category', '==', req.category);
  const snap = await q.get();
  const text = req.q?.trim().toLowerCase();
  const rows = snap.docs
    .map((a) => ({
      id: a.id,
      at: iso(a.get('at')),
      actor: a.get('actorName') as string,
      role: a.get('actorRole') as string,
      action: a.get('action') as string,
      category: a.get('category') as string,
      target: a.get('target') as string,
      reason: (a.get('reason') as string | null) ?? null,
      // Staff-entered amounts and flag states only, never family content.
      detail: (a.get('detail') as Record<string, unknown> | null) ?? null,
    }))
    .filter(
      (r) => !text || [r.actor, r.target, r.action].some((v) => v.toLowerCase().includes(text)),
    );
  if (exporting) {
    const batch = db.batch();
    audit(
      batch,
      db,
      s,
      {
        action: 'audit.export',
        category: 'data',
        target: `${req.category}:${req.days}d`,
        reason: null,
      },
      now,
    );
    await batch.commit();
  }
  return { rows };
}

/** The 30-day spend check before a weekly draft (A09: AI pauses itself at 100 %). */
export async function aiBudgetLeft(db: Firestore, now: Date): Promise<boolean> {
  const b = await readAiBudget(db, now);
  return b.monthlyBudgetVnd === 0 || b.spentVnd < b.monthlyBudgetVnd;
}

/** Adds a draft's cost to this month's spend (OpenAI only; the template is free). */
export async function chargeAi(db: Firestore, now: Date, vnd: number): Promise<void> {
  const b = await readAiBudget(db, now);
  await db.doc('config/ai').set({ ...b, spentVnd: b.spentVnd + vnd });
}
