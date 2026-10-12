import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { staffRoleTemplates } from '@child-life/contracts';
import {
  acceptStaffInvite,
  expireStaffAccess,
  inviteStaff,
  listStaff,
  resolveStaff,
  saveStaffRole,
  staffMe,
  updateStaffMember,
  type StaffAuthPort,
} from '../functions/src/staff-access.js';
import { StaffError, listTickets, type Staff } from '../functions/src/staff.js';

// Staff access v1.0 against the Firestore emulator (P-134, P-135, P-139): members and roles decide
// on every call, invitations from the portal, pause / remove / the last Owner, role ceilings and
// roles made on the portal, access windows. No 2FA (D-043); any email domain.
const projectId = 'demo-child-life';
const now = new Date('2026-10-11T08:00:00Z');
let app: App;
let db: Firestore;

const owner: Staff = { uid: 'u_owner', name: 'Chủ', roles: ['owner'] };
const admin: Staff = { uid: 'u_admin', name: 'Linh Trần', roles: ['admin'] };
const ops: Staff = { uid: 'u_ops', name: 'Hà Vũ', roles: ['ops'] };

function fakeAuth() {
  const calls: Array<[string, unknown]> = [];
  const port: StaffAuthPort = {
    setClaims: async (uid, claims) => void calls.push(['claims:' + uid, claims]),
    revoke: async (uid) => void calls.push(['revoke:' + uid, null]),
  };
  return { port, calls };
}

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError ? e.reason : String(e);
  }
};

async function member(uid: string, roles: string[], extra: Record<string, unknown> = {}) {
  await db.doc(`staffMembers/${uid}`).set({
    email: `${uid}@example.com`,
    name: uid,
    roles,
    status: 'active',
    accessUntil: null,
    createdAt: now,
    lastSeenAt: null,
    ...extra,
  });
}

const token = (extra: Record<string, unknown> = {}) => ({ staff: true, roles: ['ops'], ...extra });

beforeAll(() => {
  app = initializeApp({ projectId }, `staff-access-${randomUUID()}`);
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
  await member('u_owner', ['owner']);
  await member('u_admin', ['admin']);
  await member('u_ops', ['ops']);
});

describe('resolving the caller', () => {
  it('members decide; claims-only accounts keep their claim roles; trưởng nhóm is Admin', async () => {
    expect(await resolveStaff(db, undefined, now)).toBeNull();
    expect(await resolveStaff(db, { uid: 'x', token: { roles: ['ops'] } }, now)).toBeNull();
    const legacy = await resolveStaff(
      db,
      { uid: 'u_old', token: token({ roles: ['lead'], name: 'Cũ' }) },
      now,
    );
    expect(legacy).toMatchObject({ name: 'Cũ', roleNames: ['Admin'] });
    expect(legacy!.levels!.storage).toBe('full');

    const o = await resolveStaff(db, { uid: 'u_ops', token: token() }, now);
    expect(o!.levels).toEqual(staffRoleTemplates.ops);
    expect(staffMe(o)).toMatchObject({ roleNames: ['Vận hành'] });
    expect((await db.doc('staffMembers/u_ops').get()).get('lastSeenAt')).toBeTruthy();

    await db.doc('staffMembers/u_ops').update({ status: 'paused' });
    expect(await resolveStaff(db, { uid: 'u_ops', token: token() }, now)).toBeNull();
    await db
      .doc('staffMembers/u_ops')
      .update({ status: 'active', accessUntil: new Date(now.getTime() - 1) });
    expect(await resolveStaff(db, { uid: 'u_ops', token: token() }, now)).toBeNull();
    await member('u_ghost', ['nope']);
    expect(await resolveStaff(db, { uid: 'u_ghost', token: token() }, now)).toBeNull();
  });
});

describe('invitations (A20, P-135)', () => {
  it('Admin invites any domain; the invitee joins on first email-link sign-in', async () => {
    expect(
      await reason(
        inviteStaff(
          db,
          ops,
          {
            email: 'a@x.vn',
            name: 'A',
            roles: ['support'],
            access: { kind: 'unlimited' },
            reason: 'thêm người',
          },
          now,
          { adminOrigin: 'https://admin' },
        ),
      ),
    ).toBe('role');
    // Only "Nhân sự: Toàn quyền" (Owner) hands out Owner / Admin.
    const bad = {
      email: 'b@x.vn',
      name: 'B',
      roles: ['admin'],
      access: { kind: 'unlimited' },
      reason: 'thêm admin',
    };
    expect(await reason(inviteStaff(db, admin, bad, now, { adminOrigin: 'https://admin' }))).toBe(
      'role',
    );
    expect(await reason(inviteStaff(db, owner, bad, now, { adminOrigin: 'https://admin' }))).toBe(
      'ok',
    );

    const { inviteId } = await inviteStaff(
      db,
      admin,
      {
        email: 'Thao@Gmail.com',
        name: 'Thảo Lê',
        roles: ['support'],
        access: { kind: 'days', days: 30 },
        reason: 'Hỗ trợ ca tối',
      },
      now,
      { adminOrigin: 'https://admin' },
    );
    const inv = (await db.doc(`staffInvites/${inviteId}`).get()).data()!;
    expect(inv).toMatchObject({ email: 'thao@gmail.com', state: 'pending', roles: ['support'] });
    const mail = await db.collection('mail').where('to', '==', 'thao@gmail.com').get();
    expect(mail.docs[0]!.get('template')).toBe('staffInvite');
    expect(mail.docs[0]!.get('data')).toMatchObject({
      role: 'Hỗ trợ',
      url: 'https://admin',
      fromName: 'Linh Trần',
    });

    const { port, calls } = fakeAuth();
    const signIn = (verified: boolean, email = 'thao@gmail.com') => ({
      uid: 'u_thao',
      token: { email, email_verified: verified },
    });
    expect(await reason(acceptStaffInvite(db, signIn(false), now, port))).toBe('unverified');
    expect(await reason(acceptStaffInvite(db, signIn(true, 'z@x.vn'), now, port))).toBe(
      'no-invite',
    );
    expect(await acceptStaffInvite(db, signIn(true), now, port)).toEqual({
      roles: ['support'],
      name: 'Thảo Lê',
    });
    expect(calls).toEqual([
      ['claims:u_thao', { staff: true, roles: ['support'], name: 'Thảo Lê' }],
    ]);
    const m = (await db.doc('staffMembers/u_thao').get()).data()!;
    expect(m).toMatchObject({ status: 'active', roles: ['support'] });
    expect(m.accessUntil.toDate().getTime()).toBe(now.getTime() + 30 * 86_400_000);
    expect((await db.doc(`staffInvites/${inviteId}`).get()).get('state')).toBe('accepted');

    const team = await listStaff(db, admin, now);
    expect(team.kpis).toMatchObject({ members: 4, invites: 1 });
    expect(team.roles.find((r) => r.id === 'support')).toMatchObject({ members: 1, locked: false });
    expect(team.roles.find((r) => r.id === 'owner')).toMatchObject({ members: 1, locked: true });
    expect(await reason(listStaff(db, ops, now))).toBe('role');
  });
});

describe('member actions (A18)', () => {
  it('pause signs out at once; the last Owner and yourself are protected', async () => {
    const { port, calls } = fakeAuth();
    const act = (s: Staff, d: Record<string, unknown>) =>
      updateStaffMember(db, s, { reason: 'theo yêu cầu', ...d }, now, port);
    expect(await reason(act(admin, { op: 'pause', uid: 'u_owner' }))).toBe('role');
    expect(await reason(act(owner, { op: 'pause', uid: 'u_owner' }))).toBe('self');
    expect(await reason(act(owner, { op: 'roles', uid: 'u_owner', roles: ['admin'] }))).toBe(
      'last-owner',
    );
    await act(admin, { op: 'pause', uid: 'u_ops' });
    expect(calls).toEqual([
      ['claims:u_ops', null],
      ['revoke:u_ops', null],
    ]);
    expect(await resolveStaff(db, { uid: 'u_ops', token: token() }, now)).toBeNull();
    await act(admin, { op: 'resume', uid: 'u_ops' });
    expect((await resolveStaff(db, { uid: 'u_ops', token: token() }, now))!.name).toBe('u_ops');
    await act(admin, { op: 'roles', uid: 'u_ops', roles: ['ops', 'analyst'] });
    const both = await resolveStaff(db, { uid: 'u_ops', token: token() }, now);
    expect(both!.levels).toMatchObject({ analyticsExport: 'edit', familyTransfer: 'edit' });
    // A second Owner makes the first one removable.
    await member('u_owner2', ['owner']);
    expect(await reason(act(owner, { op: 'roles', uid: 'u_owner', roles: ['admin'] }))).toBe('ok');
    const log = await db.collection('staffAudit').where('category', '==', 'staff').get();
    expect(log.docs.map((d) => d.get('action')).sort()).toEqual([
      'staff.pause',
      'staff.resume',
      'staff.roles',
      'staff.roles',
    ]);
    expect(log.docs.every((d) => d.get('reason') === 'theo yêu cầu')).toBe(true);
  });

  it('access windows end on the hour; old invitations expire', async () => {
    const { port, calls } = fakeAuth();
    await member('u_temp', ['support'], { accessUntil: new Date(now.getTime() - 60_000) });
    await db.doc('staffInvites/si_00000000000000000001').set({
      email: 'old@x.vn',
      state: 'pending',
      roles: ['support'],
      expiresAt: new Date(now.getTime() - 1),
      createdAt: now,
    });
    expect(await expireStaffAccess(db, now, port)).toEqual({ members: 1, invites: 1 });
    expect((await db.doc('staffMembers/u_temp').get()).get('status')).toBe('expired');
    expect(calls).toEqual([
      ['claims:u_temp', null],
      ['revoke:u_temp', null],
    ]);
  });
});

describe('roles (A19 / A21)', () => {
  it('locked roles stay; ceilings and the editor’s own levels cap an edit; new roles apply at once', async () => {
    const levels = {
      ...staffRoleTemplates.support,
      familyTransfer: 'full',
      staff: 'full',
      dataJobs: 'full',
      system: 'view',
    } as const;
    expect(
      await reason(
        saveStaffRole(db, admin, { roleId: 'admin', name: 'Admin', levels, reason: 'thử' }, now),
      ),
    ).toBe('locked');
    expect(
      await reason(
        saveStaffRole(db, ops, { roleId: 'support', name: 'Hỗ trợ', levels, reason: 'thử' }, now),
      ),
    ).toBe('role');
    const saved = await saveStaffRole(
      db,
      admin,
      { roleId: 'support', name: 'Hỗ trợ', levels, reason: 'Hỗ trợ xem hệ thống' },
      now,
    );
    expect(saved.levels).toMatchObject({
      familyTransfer: 'none',
      staff: 'none',
      dataJobs: 'view',
      system: 'view',
    });

    await member('u_ha', ['support']);
    const ha = await resolveStaff(db, { uid: 'u_ha', token: token() }, now);
    expect(ha!.levels!.system).toBe('view');

    const made = await saveStaffRole(
      db,
      admin,
      {
        roleId: null,
        name: 'Trực đêm',
        levels: { ...staffRoleTemplates.support, staff: 'edit' },
        reason: 'ca đêm',
      },
      now,
    );
    expect(made.roleId).toMatch(/^r_[a-f0-9]{12}$/);
    expect(made.levels.staff).toBe('view');
    await member('u_night', [made.roleId]);
    const night = await resolveStaff(db, { uid: 'u_night', token: token() }, now);
    expect(night).toMatchObject({ roleNames: ['Trực đêm'] });
    expect(await reason(listTickets(db, night, { status: 'open' }))).toBe('ok');
    expect(
      await reason(
        saveStaffRole(db, admin, { roleId: null, name: 'trực đêm', levels, reason: 'trùng' }, now),
      ),
    ).toBe('name-taken');
  });
});
