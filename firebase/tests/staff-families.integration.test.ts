import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  answerStaffTransfer,
  cancelTransfer,
  expireTransfers,
  familyDetail,
  listFamilies,
  openTransfer,
  refreshAllFamilies,
  type FamilyDeps,
} from '../functions/src/staff-families.js';
import { StaffError, familyCode, type Staff } from '../functions/src/staff.js';
import { AccountError } from '../functions/src/account.js';

// Gia đình v1.0 against the Firestore emulator (A15–A17, P-136): the directory read model, filters
// and search, a detail made of counts (no names, ages, custom labels, device names or full emails),
// the view audit, and an ownership transfer the owner must agree to in the app.
const projectId = 'demo-child-life';
const now = new Date('2026-10-11T08:00:00Z');
const GB = 1024 ** 3;
let app: App;
let db: Firestore;
const familyId = 'f_fam1';
const code = familyCode(familyId);

const ops: Staff = { uid: 's_ops', name: 'Hà Vũ', roles: ['ops'] };
const support: Staff = { uid: 's_sup', name: 'Thảo Lê', roles: ['support'] };
const qa: Staff = { uid: 's_qa', name: 'Thu Hà', roles: ['qa'] };

const emails: Record<string, string> = {
  mom: 'mai.nguyen@gmail.com',
  dad: 'minh.tran@gmail.com',
  grandma: 'ba.ngoai@gmail.com',
  aunt: 'co.lan@gmail.com',
};
const deps: FamilyDeps = {
  emailOf: async (uid) => emails[uid] ?? null,
  uidByEmail: async (email) => Object.entries(emails).find(([, e]) => e === email)?.[0] ?? null,
};

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError || e instanceof AccountError ? e.reason : String(e);
  }
};

beforeAll(() => {
  app = initializeApp({ projectId }, `families-${randomUUID()}`);
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
  await db.doc(`families/${familyId}`).set({
    ownerUid: 'mom',
    quotaBytes: 10 * GB,
    usedBytes: 8.5 * GB,
    babyIds: ['b1', 'b2'],
    createdAt: new Date('2026-03-12T00:00:00Z'),
  });
  await db.doc('users/mom').set({ ownedFamilyId: familyId, ownedBabyCount: 2, displayName: 'Mai' });
  await db.doc('users/dad').set({ displayName: 'Minh' });
  for (const b of ['b1', 'b2']) {
    await db
      .doc(`babies/${b}`)
      .set({ nickname: b === 'b1' ? 'Teddy' : 'Na', familyId, ownerUid: 'mom' });
    for (const [uid, role, relation] of [
      ['mom', 'coParent', 'mother'],
      ['dad', 'coParent', 'father'],
    ] as const) {
      await db
        .doc(`babies/${b}/members/${uid}`)
        .set({ uid, babyId: b, role, relation, status: 'active', isOwner: uid === 'mom' });
    }
  }
  await db.doc('babies/b1/members/grandma').set({
    uid: 'grandma',
    babyId: 'b1',
    role: 'caregiver',
    relation: 'grandmother',
    status: 'active',
  });
  await db.doc('babies/b2/members/aunt').set({
    uid: 'aunt',
    babyId: 'b2',
    role: 'relative',
    relation: 'other',
    relationCustom: 'Cô Lan',
    status: 'active',
  });
  await db.doc('users/mom/devices/d_1').set({
    platform: 'ios',
    appVersion: '1.0.3',
    name: 'iPhone của Mai',
    model: 'iPhone',
    language: 'vi',
    lastActiveAt: new Date(now.getTime() - 3_600_000),
  });
  await db.doc('users/dad/devices/d_2').set({
    platform: 'android',
    appVersion: '1.0.3',
    name: 'Pixel',
    language: 'vi',
    updatedAt: new Date(now.getTime() - 86_400_000),
  });
  for (let i = 0; i < 3; i++) {
    await db.doc(`babies/b1/records/r${i}`).set({
      babyId: 'b1',
      type: 'bottle',
      createdAt: new Date(now.getTime() - i * 3_600_000),
      note: 'Bé uống 90 ml',
    });
  }
  await db
    .doc('babies/b1/media/m1')
    .set({ type: 'photo', createdAt: now, caption: 'Ảnh của Teddy' });
  await db.doc('babies/b2/stories/s1').set({ title: 'Na tập bò', createdAt: now });
  await db.doc('invites/i_1').set({
    familyId,
    babyId: 'b1',
    relation: 'grandfather',
    role: 'relative',
    status: 'pending',
    createdAt: now,
    expiresAt: new Date(now.getTime() + 86_400_000),
    babyNickname: 'Teddy',
  });
  await db.doc('invites/i_2').set({
    familyId,
    babyId: 'b1',
    relation: 'other',
    relationCustom: 'Chú Tư',
    role: 'relative',
    status: 'pending',
    createdAt: now,
    expiresAt: new Date(now.getTime() - 1),
  });
  await db.doc('supportTickets/t_1').set({
    ticket: 'CL-1042',
    uid: 'mom',
    status: 'new',
    message: 'Không tải được video\nchi tiết',
    createdAt: now,
  });
  // A second, quiet family on Android only.
  await db
    .doc('families/f_fam2')
    .set({ ownerUid: 'solo', quotaBytes: 20 * GB, usedBytes: 1 * GB, babyIds: [], createdAt: now });
  await refreshAllFamilies(db, now, deps);
});

const leaks = (v: unknown) => {
  const text = JSON.stringify(v);
  return [
    'Teddy',
    '"Na"',
    'Cô Lan',
    'Chú Tư',
    'iPhone của Mai',
    'mai.nguyen',
    'minh.tran',
    'Ảnh của',
    'tập bò',
    'Bé uống',
  ].filter((w) => text.includes(w));
};

describe('the directory (A15)', () => {
  it('rows, KPIs, filters and search by code or exact email, without content', async () => {
    const all = await listFamilies(
      db,
      support,
      { activity: 'all', platform: 'all', storage: 'all' },
      deps,
    );
    expect(all.kpis).toMatchObject({ total: 2, active: 1, low: 1, nearFull: 1 });
    expect(all.kpis.multiCarerRate).toBe(0.5);
    const row = all.rows.find((r) => r.code === code)!;
    expect(row).toMatchObject({
      owner: 'm***@gmail.com',
      members: 4,
      carers: 3,
      pendingInvites: 1,
      babies: 2,
      platforms: ['android', 'ios'],
      activity: 'active',
    });
    expect(all.rows[0]!.code).toBe(code);
    expect(leaks(all)).toEqual([]);

    const both = await listFamilies(
      db,
      ops,
      { activity: 'active', platform: 'both', storage: 'over80' },
      deps,
    );
    expect(both.rows.map((r) => r.code)).toEqual([code]);
    const expanded = await listFamilies(
      db,
      ops,
      { activity: 'all', platform: 'all', storage: 'expanded' },
      deps,
    );
    expect(expanded.rows.map((r) => r.code)).toEqual([familyCode('f_fam2')]);

    expect(
      (
        await listFamilies(
          db,
          ops,
          { activity: 'all', platform: 'all', storage: 'all', q: code.toLowerCase() },
          deps,
        )
      ).rows,
    ).toHaveLength(1);
    const byEmail = await listFamilies(
      db,
      ops,
      { activity: 'all', platform: 'all', storage: 'all', q: 'Minh.Tran@gmail.com' },
      deps,
    );
    expect(byEmail.rows.map((r) => r.code)).toEqual([code]);
    expect(JSON.stringify(byEmail)).not.toContain('minh.tran');
    expect(
      await reason(
        listFamilies(db, qa, { activity: 'all', platform: 'all', storage: 'all' }, deps),
      ),
    ).toBe('role');
  });
});

describe('the detail (A16)', () => {
  it('counts, product roles, masked people, related tickets; the view is audited', async () => {
    const d = await familyDetail(db, support, { code }, now, deps);
    expect(d).toMatchObject({
      code,
      owner: 'm***@gmail.com',
      language: 'vi',
      activity: 'active',
      expanded: false,
    });
    expect(d.members.map((m) => [m.email, m.relation, m.isOwner, m.eligible])).toEqual([
      ['m***@gmail.com', 'mother', true, false],
      ['m***@gmail.com', 'father', false, true],
      ['b***@gmail.com', 'grandmother', false, false],
      ['c***@gmail.com', 'other', false, false],
    ]);
    expect(d.members[0]).toMatchObject({ platform: 'ios', model: 'iPhone', appVersion: '1.0.3' });
    expect(d.invites.map((i) => [i.relation, i.state])).toEqual([
      ['grandfather', 'pending'],
      ['other', 'expired'],
    ]);
    expect(d.babies).toEqual([
      { ordinal: 1, records7d: 3, media7d: 1, stories: 0 },
      { ordinal: 2, records7d: 0, media7d: 0, stories: 1 },
    ]);
    expect(d.tickets).toEqual([
      expect.objectContaining({ ticket: 'CL-1042', title: 'Không tải được video', status: 'new' }),
    ]);
    expect(leaks({ ...d, tickets: [] })).toEqual([]);
    const audit = await db.collection('staffAudit').where('action', '==', 'family.view').get();
    expect(audit.docs.map((a) => [a.get('target'), a.get('category'), a.get('actorName')])).toEqual(
      [[code, 'families', 'Thảo Lê']],
    );
    expect(await reason(familyDetail(db, support, { code: 'F-ZZZZ' }, now, deps))).toBe(
      'not-found',
    );
  });
});

describe('ownership transfer opened by staff (A17)', () => {
  it('needs Vận hành, an eligible Cùng nuôi and the owner’s yes in the app', async () => {
    const open = (s: Staff, toUid: string, why = 'Chủ hồ sơ yêu cầu qua Hỗ trợ') =>
      openTransfer(db, s, { code, toUid, ticket: 'CL-1042', reason: why }, now, deps);
    expect(await reason(open(support, 'dad'))).toBe('role');
    expect(await reason(open(ops, 'grandma'))).toBe('not-eligible');
    expect(await reason(open(ops, 'mom'))).toBe('not-eligible');
    const { transferId } = await open(ops, 'dad');
    expect(await reason(open(ops, 'dad'))).toBe('transfer-pending');

    const mom = (await db.doc('users/mom').get()).get('pendingStaffTransfer');
    expect(mom).toMatchObject({ transferId, toMasked: 'm***@gmail.com', ticket: 'CL-1042' });
    const mail = await db.collection('mail').where('template', '==', 'ownershipStaffRequest').get();
    expect(mail.docs.map((m) => m.get('to'))).toEqual(['mai.nguyen@gmail.com']);
    expect((await familyDetail(db, ops, { code }, now, deps)).transfer).toMatchObject({
      id: transferId,
      to: 'm***@gmail.com',
      openedBy: 'Hà Vũ',
    });

    const caller = (uid: string) => ({
      uid,
      email: emails[uid] ?? null,
      anonymous: false,
      locale: 'vi' as const,
    });
    expect(
      await reason(
        answerStaffTransfer(db, caller('dad'), { transferId, accept: true }, now, deps.emailOf),
      ),
    ).toBe('not-found');
    expect(
      await answerStaffTransfer(db, caller('mom'), { transferId, accept: true }, now, deps.emailOf),
    ).toEqual({ state: 'confirmed' });
    // The owner's yes is the usual offer: the candidate now accepts in the app (13n).
    expect((await db.doc('users/dad').get()).get('pendingOwnership')).toMatchObject({
      familyId,
      fromUid: 'mom',
    });
    expect((await db.doc('users/mom').get()).get('pendingStaffTransfer')).toBeUndefined();
    expect(
      await reason(
        answerStaffTransfer(db, caller('mom'), { transferId, accept: true }, now, deps.emailOf),
      ),
    ).toBe('not-pending');
  });

  it('staff can cancel; unanswered requests expire after 48 hours', async () => {
    const { transferId } = await openTransfer(
      db,
      ops,
      { code, toUid: 'dad', ticket: null, reason: 'theo yêu cầu' },
      now,
      deps,
    );
    await cancelTransfer(db, ops, { transferId, reason: 'chủ hồ sơ đổi ý' }, now);
    expect((await db.doc(`familyTransfers/${transferId}`).get()).get('state')).toBe('cancelled');
    expect((await db.doc('users/mom').get()).get('pendingStaffTransfer')).toBeUndefined();

    const second = await openTransfer(
      db,
      ops,
      { code, toUid: 'dad', ticket: null, reason: 'lần nữa' },
      now,
      deps,
    );
    expect(await expireTransfers(db, new Date(now.getTime() + 49 * 3_600_000))).toBe(1);
    expect((await db.doc(`familyTransfers/${second.transferId}`).get()).get('state')).toBe(
      'expired',
    );
    const log = await db.collection('staffAudit').where('category', '==', 'families').get();
    expect(log.docs.map((d) => d.get('action')).sort()).toEqual([
      'family.transferCancel',
      'family.transferOpen',
      'family.transferOpen',
    ]);
  });
});
