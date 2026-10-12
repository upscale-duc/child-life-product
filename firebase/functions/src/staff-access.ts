import { randomBytes } from 'node:crypto';
import {
  STAFF_INVITE_DAYS,
  builtinRole,
  capLevels,
  levelAtLeast,
  levelsForRoles,
  localDateIn,
  lockedStaffRoles,
  staffFunctions,
  staffInviteSchema,
  staffMemberUpdateSchema,
  staffRoleTemplates,
  staffRoles,
  staffSaveRoleSchema,
  type StaffAccess,
  type StaffLevels,
  type StaffMemberStatus,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { queueMail } from './account.js';
import {
  StaffError,
  builtinRoleLabel,
  parse,
  requireStaff,
  staffAudit,
  staffLevelsOf,
  type Staff,
} from './staff.js';

/**
 * Staff access v1.0 (P-134, P-135; Figma A18–A21). A member is `staffMembers/{uid}` with role ids
 * and a status; a role is a set of levels (`staffRoles/{id}` for edited built-ins and roles made on
 * the portal, the contracts templates otherwise). Every callable resolves the caller here, so a
 * pause, a removal or a role edit applies on the next call. Claims (`staff`, `roles`, `name`) are
 * kept in step for the portal's sign-in gate. No 2FA (D-043 kept); any email domain (owner,
 * 2026-10-11).
 */

/** Sets or clears portal claims and ends sessions (Firebase Admin Auth in production). */
export interface StaffAuthPort {
  setClaims(
    uid: string,
    claims: { staff: true; roles: string[]; name: string } | null,
  ): Promise<void>;
  revoke(uid: string): Promise<void>;
}

const DAY_MS = 86_400_000;
const ZONE = 'Asia/Ho_Chi_Minh';
const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;
const isoOrNull = (v: unknown) => (ms(v) ? new Date(ms(v)).toISOString() : null);

interface RoleDef {
  id: string;
  name: string;
  levels: StaffLevels;
  builtin: boolean;
  locked: boolean;
  updatedBy: string | null;
  updatedAt: string | null;
}

let roleCache: { at: number; defs: Map<string, RoleDef> } | null = null;
// Tests run against a fresh emulator each case; production keeps roles for 30 s per instance.
const ROLE_TTL_MS = process.env.VITEST ? 0 : 30_000;

/** A function added to the matrix later reads as "—" on roles saved before it existed. */
const noLevels = Object.fromEntries(staffFunctions.map((f) => [f, 'none'])) as StaffLevels;

/** Every role: the built-ins (edited ones from Firestore) and the ones made on the portal. */
export async function roleDefs(db: Firestore, now = Date.now()): Promise<Map<string, RoleDef>> {
  if (roleCache && now - roleCache.at < ROLE_TTL_MS) return roleCache.defs;
  const snap = await db.collection('staffRoles').get();
  const stored = new Map(snap.docs.map((d) => [d.id, d]));
  const defs = new Map<string, RoleDef>();
  for (const id of staffRoles) {
    const doc = stored.get(id);
    const locked = lockedStaffRoles.includes(id);
    defs.set(id, {
      id,
      name: builtinRoleLabel[id] ?? id,
      levels:
        !locked && doc?.get('levels')
          ? { ...staffRoleTemplates[id], ...(doc.get('levels') as StaffLevels) }
          : staffRoleTemplates[id],
      builtin: true,
      locked,
      updatedBy: (doc?.get('updatedByName') as string | undefined) ?? null,
      updatedAt: isoOrNull(doc?.get('updatedAt')),
    });
  }
  for (const [id, doc] of stored) {
    if (defs.has(id)) continue;
    defs.set(id, {
      id,
      name: doc.get('name') as string,
      levels: { ...noLevels, ...(doc.get('levels') as Partial<StaffLevels> | undefined) },
      builtin: false,
      locked: false,
      updatedBy: (doc.get('updatedByName') as string | undefined) ?? null,
      updatedAt: isoOrNull(doc.get('updatedAt')),
    });
  }
  roleCache = { at: now, defs };
  return defs;
}

function forgetRoles() {
  roleCache = null;
}

/**
 * The signed-in staff member, or `null`. Members with a `staffMembers` document must be active and
 * within their access window; accounts from before v1.0 (claims only) keep their claim roles.
 */
export async function resolveStaff(
  db: Firestore,
  auth: { uid: string; token: Record<string, unknown> } | undefined,
  now: Date,
): Promise<Staff | null> {
  if (!auth || auth.token.staff !== true) return null;
  const member = await db.doc(`staffMembers/${auth.uid}`).get();
  let roles: string[];
  let name: string;
  if (member.exists) {
    if (member.get('status') !== 'active') return null;
    const until = ms(member.get('accessUntil'));
    if (until && until <= now.getTime()) return null;
    roles = (member.get('roles') as string[]) ?? [];
    name = member.get('name') as string;
    // "Gần nhất" on A18, at most once a minute.
    if (now.getTime() - ms(member.get('lastSeenAt')) > 60_000) {
      await member.ref.update({ lastSeenAt: now });
    }
  } else {
    roles = Array.isArray(auth.token.roles)
      ? (auth.token.roles as unknown[]).filter((r): r is string => typeof r === 'string')
      : [];
    name = String(auth.token.name ?? auth.token.email ?? 'staff');
  }
  if (!roles.length) return null;
  const defs = await roleDefs(db, now.getTime());
  const known = roles.filter((r) => defs.has(builtinRole(r) ?? r));
  if (!known.length) return null;
  const custom = Object.fromEntries([...defs].map(([id, d]) => [id, d.levels]));
  return {
    uid: auth.uid,
    name,
    roles: known,
    levels: levelsForRoles(known, custom),
    roleNames: known.map((r) => defs.get(builtinRole(r) ?? r)!.name),
  };
}

/** `staffMe`: who the portal is talking to and what they may open (sidebar visibility). */
export function staffMe(staff: Staff | null) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  return {
    uid: staff.uid,
    name: staff.name,
    roles: staff.roles,
    roleNames: staff.roleNames ?? staff.roles,
    levels: staffLevelsOf(staff),
  };
}

function accessUntil(access: StaffAccess, now: Date): Date | null {
  if (access.kind === 'unlimited') return null;
  if (access.kind === 'days') return new Date(now.getTime() + access.days * DAY_MS);
  // "Đến ngày…": through the end of that day in Vietnam.
  const end = new Date(`${access.until}T23:59:59+07:00`);
  if (Number.isNaN(end.getTime()) || end <= now) throw new StaffError('invalid-argument', 'past');
  return end;
}

function memberRow(d: DocumentSnapshot) {
  return {
    uid: d.id,
    name: d.get('name') as string,
    email: d.get('email') as string,
    roles: (d.get('roles') as string[]) ?? [],
    status: d.get('status') as StaffMemberStatus,
    accessUntil: isoOrNull(d.get('accessUntil')),
    lastSeenAt: isoOrNull(d.get('lastSeenAt')),
    createdAt: isoOrNull(d.get('createdAt')),
  };
}

/** "Quyền nhạy cảm": Duyệt or Toàn quyền on a function that touches families or the system. */
const sensitive = (levels: StaffLevels) =>
  staffFunctions.some((f) => f !== 'qa' && levelAtLeast(levels[f], 'approve'));

/** A18 / A19: members, pending invitations and roles with their head counts. */
export async function listStaff(db: Firestore, staff: Staff | null, now: Date) {
  requireStaff(staff, 'staff.view');
  const [members, invites, defs] = await Promise.all([
    db.collection('staffMembers').get(),
    db.collection('staffInvites').where('state', '==', 'pending').get(),
    roleDefs(db, now.getTime()),
  ]);
  const rows = members.docs.map(memberRow).filter((m) => m.status !== 'removed');
  const custom = Object.fromEntries([...defs].map(([id, d]) => [id, d.levels]));
  const live = rows.filter((m) => m.status === 'active');
  const pending = invites.docs
    .filter((d) => ms(d.get('expiresAt')) > now.getTime())
    .map((d) => ({
      id: d.id,
      email: d.get('email') as string,
      name: d.get('name') as string,
      roles: d.get('roles') as string[],
      invitedBy: d.get('invitedByName') as string,
      expiresAt: isoOrNull(d.get('expiresAt')),
    }));
  return {
    members: rows,
    invites: pending,
    roles: [...defs.values()].map((r) => ({
      ...r,
      members: live.filter((m) => m.roles.some((x) => (builtinRole(x) ?? x) === r.id)).length,
    })),
    kpis: {
      members: live.length,
      sensitive: live.filter((m) => sensitive(levelsForRoles(m.roles, custom))).length,
      invites: pending.length,
    },
  };
}

/** Owner and Admin can only be given or taken away by someone with "Nhân sự: Toàn quyền". */
const touchesOwners = (roles: readonly string[]) =>
  roles.some((r) => ['owner', 'admin'].includes(builtinRole(r) ?? r));

async function checkRoles(db: Firestore, s: Staff, roles: string[], now: Date) {
  const defs = await roleDefs(db, now.getTime());
  if (roles.some((r) => !defs.has(r))) throw new StaffError('invalid-argument', 'unknown-role');
  if (touchesOwners(roles)) requireStaff(s, 'staff.owners');
  return defs;
}

/** A20 "Gửi lời mời": any email domain, 7 days, the invitee signs in with an email link. */
export async function inviteStaff(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  deps: { adminOrigin: string },
) {
  const s = requireStaff(staff, 'staff.manage');
  const req = parse(staffInviteSchema, data);
  const defs = await checkRoles(db, s, req.roles, now);
  const until = accessUntil(req.access, now);
  const id = `si_${randomBytes(10).toString('hex')}`;
  await db.runTransaction(async (tx) => {
    const already = await tx.get(
      db.collection('staffMembers').where('email', '==', req.email).limit(1),
    );
    if (!already.empty && already.docs[0]!.get('status') !== 'removed') {
      throw new StaffError('failed-precondition', 'already-member');
    }
    const older = await tx.get(
      db.collection('staffInvites').where('email', '==', req.email).where('state', '==', 'pending'),
    );
    for (const d of older.docs) tx.update(d.ref, { state: 'replaced', updatedAt: now });
    tx.create(db.doc(`staffInvites/${id}`), {
      email: req.email,
      name: req.name,
      roles: req.roles,
      accessUntil: until,
      expiresAt: new Date(now.getTime() + STAFF_INVITE_DAYS * DAY_MS),
      state: 'pending',
      invitedByUid: s.uid,
      invitedByName: s.name,
      createdAt: now,
    });
    queueMail(
      tx,
      db,
      req.email,
      'staffInvite',
      'vi',
      {
        fromName: s.name,
        role: req.roles.map((r) => defs.get(r)!.name).join(' · '),
        url: deps.adminOrigin,
      },
      now,
    );
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'staff.invite',
        category: 'staff',
        target: req.email,
        reason: req.reason,
        detail: { roles: req.roles, until: until ? localDateIn(ZONE, until) : null },
      },
      now,
    );
  });
  return { inviteId: id };
}

/**
 * First sign-in of an invitee (email link, so the address is verified): the newest pending
 * invitation for that email becomes a member and the portal claims are set.
 */
export async function acceptStaffInvite(
  db: Firestore,
  auth: { uid: string; token: Record<string, unknown> } | undefined,
  now: Date,
  port: StaffAuthPort,
) {
  const email = typeof auth?.token.email === 'string' ? auth.token.email.toLowerCase() : null;
  if (!auth || !email) throw new StaffError('permission-denied', 'not-staff');
  if (auth.token.email_verified !== true) throw new StaffError('permission-denied', 'unverified');
  const joined = await db.runTransaction(async (tx) => {
    const invites = await tx.get(
      db.collection('staffInvites').where('email', '==', email).where('state', '==', 'pending'),
    );
    const live = invites.docs
      .filter((d) => ms(d.get('expiresAt')) > now.getTime())
      .sort((a, b) => ms(b.get('createdAt')) - ms(a.get('createdAt')));
    const invite = live[0];
    if (!invite) throw new StaffError('permission-denied', 'no-invite');
    const ref = db.doc(`staffMembers/${auth.uid}`);
    const existing = await tx.get(ref);
    if (existing.exists && existing.get('status') === 'active') {
      throw new StaffError('failed-precondition', 'already-member');
    }
    const roles = invite.get('roles') as string[];
    const name = invite.get('name') as string;
    tx.set(ref, {
      email,
      name,
      roles,
      status: 'active',
      accessUntil: invite.get('accessUntil') ?? null,
      invitedByUid: invite.get('invitedByUid'),
      createdAt: now,
      lastSeenAt: now,
    });
    tx.update(invite.ref, { state: 'accepted', acceptedUid: auth.uid, updatedAt: now });
    staffAudit(
      tx,
      db,
      { uid: auth.uid, name, roles },
      { action: 'staff.join', category: 'staff', target: email, reason: null },
      now,
    );
    return { roles, name };
  });
  await port.setClaims(auth.uid, { staff: true, roles: joined.roles, name: joined.name });
  return joined;
}

async function activeOwners(db: Firestore): Promise<string[]> {
  const snap = await db.collection('staffMembers').where('status', '==', 'active').get();
  return snap.docs
    .filter((d) => ((d.get('roles') as string[]) ?? []).includes('owner'))
    .map((d) => d.id);
}

/** A18 row actions: roles, access window, pause / resume, remove, revoke an invitation. */
export async function updateStaffMember(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  port: StaffAuthPort,
) {
  const s = requireStaff(staff, 'staff.manage');
  const req = parse(staffMemberUpdateSchema, data);

  if (req.op === 'revokeInvite') {
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`staffInvites/${req.inviteId}`);
      const inv = await tx.get(ref);
      if (!inv.exists || inv.get('state') !== 'pending')
        throw new StaffError('not-found', 'not-found');
      if (touchesOwners(inv.get('roles') as string[])) requireStaff(s, 'staff.owners');
      tx.update(ref, { state: 'revoked', updatedAt: now });
      staffAudit(
        tx,
        db,
        s,
        {
          action: 'staff.revokeInvite',
          category: 'staff',
          target: inv.get('email') as string,
          reason: req.reason,
        },
        now,
      );
    });
    return {};
  }

  const ref = db.doc(`staffMembers/${req.uid}`);
  const member = await ref.get();
  if (!member.exists || member.get('status') === 'removed')
    throw new StaffError('not-found', 'not-found');
  const before = (member.get('roles') as string[]) ?? [];
  if (touchesOwners(before)) requireStaff(s, 'staff.owners');
  const owners = await activeOwners(db);
  const lastOwner = owners.length === 1 && owners[0] === req.uid;
  const email = member.get('email') as string;
  let claims: Parameters<StaffAuthPort['setClaims']>[1] | undefined;
  let revoke = false;
  let update: Record<string, unknown> = { updatedAt: now };
  let detail: Record<string, unknown> | undefined;

  switch (req.op) {
    case 'roles': {
      await checkRoles(db, s, req.roles, now);
      if (lastOwner && !req.roles.includes('owner'))
        throw new StaffError('failed-precondition', 'last-owner');
      update = { ...update, roles: req.roles };
      detail = { before, after: req.roles };
      if (member.get('status') === 'active')
        claims = { staff: true, roles: req.roles, name: member.get('name') as string };
      break;
    }
    case 'access': {
      const until = accessUntil(req.access, now);
      if (lastOwner && until) throw new StaffError('failed-precondition', 'last-owner');
      update = { ...update, accessUntil: until };
      detail = { until: until ? localDateIn(ZONE, until) : null };
      break;
    }
    case 'pause':
    case 'remove': {
      if (req.uid === s.uid) throw new StaffError('failed-precondition', 'self');
      if (lastOwner) throw new StaffError('failed-precondition', 'last-owner');
      update = { ...update, status: req.op === 'pause' ? 'paused' : 'removed' };
      claims = null;
      revoke = true;
      break;
    }
    case 'resume': {
      if (member.get('status') === 'active')
        throw new StaffError('failed-precondition', 'already-active');
      update = { ...update, status: 'active' };
      if (ms(member.get('accessUntil')) && ms(member.get('accessUntil')) <= now.getTime()) {
        update.accessUntil = null;
      }
      claims = { staff: true, roles: before, name: member.get('name') as string };
      break;
    }
  }
  await db.runTransaction(async (tx) => {
    tx.update(ref, update);
    staffAudit(
      tx,
      db,
      s,
      {
        action: `staff.${req.op}`,
        category: 'staff',
        target: email,
        reason: req.reason,
        ...(detail ? { detail } : {}),
      },
      now,
    );
  });
  if (claims !== undefined) await port.setClaims(req.uid, claims);
  if (revoke) await port.revoke(req.uid);
  return {};
}

/**
 * A21 "Lưu thay đổi" / "Tạo vai trò". Locked roles (Owner, Admin, Kiểm thử) cannot change; no role
 * can be given more than the editor has; "Nhân sự & phân quyền" stays at most "Xem" on editable roles
 * (only Owner and Admin manage people); built-in ceilings apply (Hỗ trợ: no transfer, export, delete).
 */
export async function saveStaffRole(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'staff.manage');
  const req = parse(staffSaveRoleSchema, data);
  const defs = await roleDefs(db, now.getTime());
  const id = req.roleId ?? `r_${randomBytes(6).toString('hex')}`;
  const current = defs.get(id);
  if (req.roleId && !current) throw new StaffError('not-found', 'not-found');
  if (current?.locked) throw new StaffError('failed-precondition', 'locked');
  if (!current && [...defs.values()].some((r) => r.name.toLowerCase() === req.name.toLowerCase())) {
    throw new StaffError('failed-precondition', 'name-taken');
  }
  const mine = staffLevelsOf(s);
  const levels = capLevels(id, { ...(req.levels as StaffLevels) });
  for (const f of staffFunctions) {
    if (!levelAtLeast(mine[f], levels[f])) levels[f] = mine[f];
  }
  if (levelAtLeast(levels.staff, 'edit')) levels.staff = 'view';
  await db.runTransaction(async (tx) => {
    tx.set(db.doc(`staffRoles/${id}`), {
      name: current?.builtin ? current.name : req.name,
      levels,
      updatedByName: s.name,
      updatedByUid: s.uid,
      updatedAt: now,
      ...(current ? {} : { createdAt: now }),
    });
    staffAudit(
      tx,
      db,
      s,
      {
        action: current ? 'staff.saveRole' : 'staff.createRole',
        category: 'staff',
        target: current?.name ?? req.name,
        reason: req.reason,
        detail: current ? { before: current.levels, after: levels } : { after: levels },
      },
      now,
    );
  });
  forgetRoles();
  return { roleId: id, levels };
}

/** Hourly: access windows that ended ("Thời hạn quyền") and invitations past 7 days. */
export async function expireStaffAccess(db: Firestore, now: Date, port: StaffAuthPort) {
  const members = await db
    .collection('staffMembers')
    .where('status', '==', 'active')
    .where('accessUntil', '<=', now)
    .get();
  for (const m of members.docs) {
    if (!ms(m.get('accessUntil'))) continue;
    await m.ref.update({ status: 'expired', updatedAt: now });
    await port.setClaims(m.id, null);
    await port.revoke(m.id);
  }
  const invites = await db
    .collection('staffInvites')
    .where('state', '==', 'pending')
    .where('expiresAt', '<=', now)
    .get();
  for (const i of invites.docs) await i.ref.update({ state: 'expired', updatedAt: now });
  return { members: members.size, invites: invites.size };
}
