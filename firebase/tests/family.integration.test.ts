import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { createBaby } from '../functions/src/babies.js';
import {
  FamilyError,
  acceptInvite,
  claimAnonymous,
  createInvite,
  declineInvite,
  endOfDayIn,
  expireMemberships,
  inviteForLanding,
  listMyInvites,
  previewInvite,
  regenerateInvite,
  removeMember,
  revokeInvite,
  sendInviteEmail,
  updateMember,
  type Caller,
} from '../functions/src/family.js';
import { deliverNotice, type PushSender } from '../functions/src/social.js';
import {
  deliverMail,
  renderInviteEmail,
  unsubscribe,
  type OutgoingMail,
} from '../functions/src/mail.js';

// S3 handlers against the Firestore emulator (`pnpm test:rules`). Business map §7.2, P-020, P-021,
// P-005, P-007, D-017…D-020.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T03:00:00Z');
const later = (minutes: number) => new Date(now.getTime() + minutes * 60_000);
let app: App;
let db: Firestore;

const mom: Caller = { uid: 'mom', anonymous: false, emailTrusted: true };
const dad: Caller = { uid: 'dad', anonymous: false, emailTrusted: true };
const nanny: Caller = { uid: 'nanny', anonymous: false, emailTrusted: true };
const guest: Caller = { uid: 'guest', anonymous: true, emailTrusted: false };

async function reasonOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof FamilyError) return error.reason;
    throw error;
  }
  throw new Error('expected a FamilyError');
}

let babyId: string;

async function invite(
  caller: Caller,
  role: 'coParent' | 'caregiver' | 'relative' = 'caregiver',
  at = now,
) {
  return createInvite(
    db,
    caller,
    { requestId: randomUUID(), babyId, relation: 'grandmother', role },
    at,
  );
}

async function join(caller: Caller, code: string, at = now) {
  return acceptInvite(
    db,
    caller,
    '203.0.113.7',
    { code, displayName: caller.uid, relation: 'grandmother' },
    at,
  );
}

beforeAll(() => {
  app = initializeApp({ projectId }, `family-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) throw new Error('Run with the Firestore emulator (pnpm test:rules)');
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  ({ babyId } = await createBaby(
    db,
    'mom',
    {
      requestId: randomUUID(),
      nickname: 'Teddy',
      dateOfBirth: '2026-09-17',
      gender: 'girl',
      timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
      avatarPreset: 1,
      trackers: ['bottle'],
      self: { displayName: 'Mai', relation: 'mother' },
    },
    now,
    10 * 1024 ** 3,
  ));
});

describe('creating invites (14b → 14c)', () => {
  it('returns a 6-digit code, a link token and a 7-day expiry, and lists it as pending', async () => {
    const ticket = await invite(mom);
    expect(ticket.code).toMatch(/^\d{6}$/);
    expect(ticket.token).toMatch(/^[A-Za-z0-9_-]{32}$/);
    expect(new Date(ticket.expiresAt).getTime() - now.getTime()).toBe(7 * 86_400_000);
    const pending = await db.doc(`babies/${babyId}/pendingInvites/${ticket.inviteId}`).get();
    expect(pending.data()).toMatchObject({
      role: 'caregiver',
      relation: 'grandmother',
      code: ticket.code,
    });
  });

  it('needs a verified email, an account and the Cùng nuôi role (D-015, §5)', async () => {
    expect(await reasonOf(invite({ ...mom, emailTrusted: false }))).toBe('email-unverified');
    expect(await reasonOf(invite(guest))).toBe('account-required');
    const ticket = await invite(mom);
    await join(nanny, ticket.code);
    expect(await reasonOf(invite(nanny))).toBe('not-co-parent');
    expect(await reasonOf(invite({ uid: 'stranger', anonymous: false, emailTrusted: true }))).toBe(
      'not-a-member',
    );
  });

  it('only the owner invites or manages co-parents (D-017)', async () => {
    const ticket = await invite(mom, 'coParent');
    await join(dad, ticket.code);
    expect(await reasonOf(invite(dad, 'coParent'))).toBe('owner-only');
    await expect(invite(dad, 'relative')).resolves.toBeTruthy();
  });

  it('relatives get both extra rights off unless chosen (D-019)', async () => {
    const ticket = await invite(mom, 'relative');
    const pending = await db.doc(`babies/${babyId}/pendingInvites/${ticket.inviteId}`).get();
    expect(pending.get('extraRights')).toEqual({ viewBabyInfo: false, viewDailyCare: false });
  });
});

describe('redeeming (15 → 16 → 16a)', () => {
  it('previews by code or link token, signed out', async () => {
    const ticket = await invite(mom);
    const byCode = await previewInvite(db, null, '198.51.100.1', { code: ticket.code }, now);
    expect(byCode).toMatchObject({
      status: 'valid',
      babyNickname: 'Teddy',
      inviterName: 'Mai',
      role: 'caregiver',
      alreadyMember: false,
    });
    expect(await previewInvite(db, null, null, { token: ticket.token }, now)).toMatchObject({
      status: 'valid',
    });
    expect(await inviteForLanding(db, ticket.token, now)).toMatchObject({ code: ticket.code });
  });

  it('joins with the invite role and the invitee relation; the code is then used', async () => {
    const ticket = await invite(mom, 'relative');
    const result = await acceptInvite(
      db,
      guest,
      null,
      { code: ticket.code, displayName: 'Hoa', relation: 'other', relationCustom: 'Bà ngoại' },
      now,
    );
    expect(result).toEqual({ babyId, role: 'relative' });
    const member = (await db.doc(`babies/${babyId}/members/guest`).get()).data();
    expect(member).toMatchObject({
      role: 'relative',
      relation: 'other',
      relationCustom: 'Bà ngoại',
      displayName: 'Hoa',
      status: 'active',
      invitedBy: 'mom',
    });
    expect((await db.doc(`babies/${babyId}/pendingInvites/${ticket.inviteId}`).get()).exists).toBe(
      false,
    );
    expect(await previewInvite(db, null, null, { token: ticket.token }, now)).toEqual({
      status: 'not-found',
    });
    expect(await reasonOf(join(nanny, ticket.code))).toBe('not-found');
  });

  it('reports already-member, expired and revoked (G-035, G-036)', async () => {
    const first = await invite(mom);
    await join(nanny, first.code);
    const second = await invite(mom);
    expect(await previewInvite(db, 'nanny', null, { code: second.code }, now)).toMatchObject({
      alreadyMember: true,
    });
    expect(await reasonOf(join(nanny, second.code))).toBe('already-member');

    const old = await invite(mom);
    expect(await previewInvite(db, null, null, { code: old.code }, later(8 * 24 * 60))).toEqual({
      status: 'expired',
    });
    expect(await reasonOf(join(dad, old.code, later(8 * 24 * 60)))).toBe('expired');

    const revoked = await invite(mom);
    await revokeInvite(db, mom, { inviteId: revoked.inviteId }, now);
    expect(await previewInvite(db, null, null, { token: revoked.token }, now)).toEqual({
      status: 'not-found',
    });
  });

  it('locks a caller out after 10 unknown codes (P-021)', async () => {
    for (let i = 0; i < 10; i += 1) {
      expect(
        await previewInvite(db, 'guest', '203.0.113.9', { code: String(100000 + i) }, now),
      ).toEqual({ status: 'not-found' });
    }
    const ticket = await invite(mom);
    expect(
      await previewInvite(db, 'guest', '203.0.113.9', { code: ticket.code }, now),
    ).toMatchObject({ status: 'locked' });
    expect(await reasonOf(join(guest, ticket.code))).toBe('locked');
    expect(
      await previewInvite(db, 'guest', '203.0.113.9', { code: ticket.code }, later(16)),
    ).toMatchObject({ status: 'valid' });
  });

  it('"Tạo mã mới" invalidates the old code and link and resets the expiry (P-020)', async () => {
    const ticket = await invite(mom);
    const fresh = await regenerateInvite(db, mom, { inviteId: ticket.inviteId }, later(60));
    expect(fresh.code).not.toBe(ticket.code);
    expect(await previewInvite(db, null, null, { code: ticket.code }, later(61))).toEqual({
      status: 'not-found',
    });
    expect(await previewInvite(db, null, null, { token: ticket.token }, later(61))).toEqual({
      status: 'not-found',
    });
    expect(new Date(fresh.expiresAt).getTime()).toBe(later(60).getTime() + 7 * 86_400_000);
    await expect(join(nanny, fresh.code, later(61))).resolves.toMatchObject({ role: 'caregiver' });
  });
});

describe('invites mailed to me (owner, 2026-10-11)', () => {
  const quynh: Caller = {
    uid: 'quynh',
    anonymous: false,
    emailTrusted: true,
    email: 'quynh@example.com',
  };
  const stranger: Caller = {
    uid: 'stranger',
    anonymous: false,
    emailTrusted: true,
    email: 'someone@example.com',
  };
  async function mailed(role: 'coParent' | 'caregiver' = 'coParent', at = now) {
    const ticket = await invite(mom, role, at);
    await sendInviteEmail(
      db,
      mom,
      { inviteId: ticket.inviteId, email: 'Quynh@Example.com', locale: 'vi' },
      at,
    );
    return ticket;
  }

  it('lists live invites to my verified email, newest per baby, not for babies I am in', async () => {
    await mailed('caregiver');
    const newest = await mailed('coParent', later(1));
    const mine = await listMyInvites(db, quynh, later(2));
    expect(mine.invites).toHaveLength(1);
    expect(mine.invites[0]).toMatchObject({
      inviteId: newest.inviteId,
      babyNickname: 'Teddy',
      inviterName: 'Mai',
      role: 'coParent',
    });
    expect((await listMyInvites(db, stranger, later(2))).invites).toEqual([]);
    // No trusted email, no list.
    expect((await listMyInvites(db, { ...quynh, emailTrusted: false }, later(2))).invites).toEqual(
      [],
    );
    expect((await listMyInvites(db, quynh, later(8 * 24 * 60))).invites).toEqual([]);
  });

  it('accepts by id without the code, only for the recipient', async () => {
    const ticket = await mailed();
    const asStranger = acceptInvite(
      db,
      stranger,
      null,
      { inviteId: ticket.inviteId, displayName: 'X', relation: 'other', relationCustom: 'X' },
      now,
    );
    expect(await reasonOf(asStranger)).toBe('not-found');
    const result = await acceptInvite(
      db,
      quynh,
      null,
      { inviteId: ticket.inviteId, displayName: 'Quỳnh', relation: 'mother' },
      now,
    );
    expect(result).toEqual({ babyId, role: 'coParent' });
    expect((await db.doc(`babies/${babyId}/members/quynh`).get()).get('displayName')).toBe('Quỳnh');
    // Used now: gone from my list, and the code no longer works.
    expect((await listMyInvites(db, quynh, now)).invites).toEqual([]);
    expect(await reasonOf(join(nanny, ticket.code))).toBe('not-found');
  });

  it('declines: the invite closes for everyone and leaves "Đang chờ"', async () => {
    const ticket = await mailed();
    expect(await reasonOf(declineInvite(db, stranger, { inviteId: ticket.inviteId }, now))).toBe(
      'not-found',
    );
    await declineInvite(db, quynh, { inviteId: ticket.inviteId }, now);
    expect((await db.doc(`invites/${ticket.inviteId}`).get()).get('status')).toBe('declined');
    expect((await db.doc(`babies/${babyId}/pendingInvites/${ticket.inviteId}`).get()).exists).toBe(
      false,
    );
    expect((await listMyInvites(db, quynh, now)).invites).toEqual([]);
    expect(await reasonOf(join(nanny, ticket.code))).toBe('not-found');
    expect(
      await reasonOf(
        acceptInvite(
          db,
          quynh,
          null,
          { inviteId: ticket.inviteId, displayName: 'Quỳnh', relation: 'mother' },
          now,
        ),
      ),
    ).toBe('revoked');
  });
});

describe('invite email (14c Email, 14d, 14e)', () => {
  it('queues a bilingual email, limits resends and honours "Huỷ nhận email"', async () => {
    const ticket = await invite(mom);
    await sendInviteEmail(
      db,
      mom,
      { inviteId: ticket.inviteId, email: 'Ba.Ngoai@Example.com', locale: 'vi' },
      now,
    );
    const queued = await db.collection('mail').get();
    expect(queued.size).toBe(1);
    expect(queued.docs[0]!.data()).toMatchObject({
      to: 'ba.ngoai@example.com',
      template: 'invite',
      status: 'queued',
    });
    expect(
      await reasonOf(
        sendInviteEmail(
          db,
          mom,
          { inviteId: ticket.inviteId, email: 'ba.ngoai@example.com', locale: 'vi' },
          later(0.5),
        ),
      ),
    ).toBe('too-soon');

    const sent: OutgoingMail[] = [];
    expect(
      await deliverMail(
        queued.docs[0]!,
        { send: async (m) => void sent.push(m) },
        { webOrigin: 'https://example.test', now },
      ),
    ).toBe('sent');
    expect(sent[0]!.subject).toBe('Mai mời bạn cùng chăm Teddy');
    expect(sent[0]!.html).toContain(`https://example.test/i/${ticket.token}`);
    expect(sent[0]!.html).toContain(`${ticket.code.slice(0, 3)} ${ticket.code.slice(3)}`);

    const token = queued.docs[0]!.get('unsubscribeToken') as string;
    expect(await unsubscribe(db, token, now)).toBe(true);
    expect(
      await reasonOf(
        sendInviteEmail(
          db,
          mom,
          { inviteId: ticket.inviteId, email: 'ba.ngoai@example.com', locale: 'vi' },
          later(5),
        ),
      ),
    ).toBe('suppressed');
  });

  it('a waiting invite mail is dropped once the same invite was mailed again', async () => {
    const ticket = await invite(mom);
    const send = (at: Date, locale: 'vi' | 'en') =>
      sendInviteEmail(
        db,
        mom,
        { inviteId: ticket.inviteId, email: 'ba.ngoai@example.com', locale },
        at,
      );
    await send(now, 'en');
    const first = (await db.collection('mail').get()).docs[0]!;
    expect(await deliverMail(first, null, { webOrigin: 'https://example.test', now })).toBe(
      'waiting-provider',
    );
    await send(later(5), 'vi');
    const sent: OutgoingMail[] = [];
    const sender = { send: async (m: OutgoingMail) => void sent.push(m) };
    const docs = (await db.collection('mail').orderBy('createdAt').get()).docs;
    expect(await deliverMail(docs[1]!, sender, { webOrigin: 'x', now: later(5) })).toBe('sent');
    expect(
      await deliverMail(await docs[0]!.ref.get(), sender, { webOrigin: 'x', now: later(20) }),
    ).toBe('superseded');
    expect(sent.map((m) => m.subject)).toEqual(['Mai mời bạn cùng chăm Teddy']);
  });

  it('waits for the provider when none is configured', async () => {
    const ticket = await invite(mom);
    await sendInviteEmail(
      db,
      mom,
      { inviteId: ticket.inviteId, email: 'a@example.com', locale: 'en' },
      now,
    );
    const doc = (await db.collection('mail').get()).docs[0]!;
    expect(await deliverMail(doc, null, { webOrigin: 'https://example.test', now })).toBe(
      'waiting-provider',
    );
    expect(
      renderInviteEmail('en', doc.get('data'), { webOrigin: 'x', unsubscribeUrl: 'y' }).subject,
    ).toBe('Mai invited you to care for Teddy');
  });
});

describe('managing members (14f)', () => {
  it('changes role, relation and access end date; records the end of day in the baby zone', async () => {
    const ticket = await invite(mom);
    await join(nanny, ticket.code);
    await updateMember(
      db,
      mom,
      { babyId, uid: 'nanny', role: 'relative', relation: 'nanny', accessUntil: '2026-12-31' },
      now,
    );
    const member = (await db.doc(`babies/${babyId}/members/nanny`).get()).data()!;
    expect(member).toMatchObject({
      role: 'relative',
      relation: 'nanny',
      accessUntil: '2026-12-31',
      extraRights: { viewBabyInfo: false, viewDailyCare: false },
    });
    expect((member.accessUntilAt as Timestamp).toDate().toISOString()).toBe(
      '2026-12-31T17:00:00.000Z',
    );
    expect((await db.collection('audit').where('action', '==', 'member.update').get()).size).toBe(
      1,
    );
  });

  it('protects the owner and keeps co-parents to the owner (D-017); caregivers cannot manage', async () => {
    const coParent = await invite(mom, 'coParent');
    await join(dad, coParent.code);
    const caregiver = await invite(mom);
    await join(nanny, caregiver.code);
    expect(await reasonOf(removeMember(db, dad, { babyId, uid: 'mom' }, now))).toBe(
      'owner-protected',
    );
    expect(
      await reasonOf(updateMember(db, dad, { babyId, uid: 'nanny', role: 'coParent' }, now)),
    ).toBe('owner-only');
    expect(await reasonOf(removeMember(db, nanny, { babyId, uid: 'dad' }, now))).toBe(
      'not-co-parent',
    );
    await updateMember(db, dad, { babyId, uid: 'nanny', relation: 'relative' }, now);
    await removeMember(db, mom, { babyId, uid: 'dad' }, now);
    expect((await db.doc(`babies/${babyId}/members/dad`).get()).get('status')).toBe('removed');
  });

  it('expires memberships after "Thời hạn" (P-005)', async () => {
    const ticket = await invite(mom);
    await join(nanny, ticket.code);
    await updateMember(db, mom, { babyId, uid: 'nanny', accessUntil: '2026-10-08' }, now);
    expect(await expireMemberships(db, now)).toBe(0);
    expect(await expireMemberships(db, new Date('2026-10-08T17:00:01Z'))).toBe(1);
    expect((await db.doc(`babies/${babyId}/members/nanny`).get()).get('status')).toBe('expired');
  });
});

describe('saving a temporary identity (16d, P-007)', () => {
  it('moves the anonymous memberships to the existing account and deletes the temporary user', async () => {
    const ticket = await invite(mom, 'relative');
    await join(guest, ticket.code);
    const deleted: string[] = [];
    const result = await claimAnonymous(
      db,
      {
        verify: async () => ({ uid: 'guest', provider: 'anonymous' }),
        deleteUser: async (uid) => void deleted.push(uid),
      },
      { uid: 'hoa', anonymous: false, emailTrusted: true },
      { anonymousIdToken: 'x'.repeat(40) },
      now,
    );
    expect(result).toEqual({ moved: 1 });
    expect((await db.doc(`babies/${babyId}/members/hoa`).get()).data()).toMatchObject({
      role: 'relative',
      status: 'active',
      mergedFrom: 'guest',
    });
    expect((await db.doc(`babies/${babyId}/members/guest`).get()).get('status')).toBe('merged');
    expect(deleted).toEqual(['guest']);
  });

  it('refuses tokens that are not anonymous', async () => {
    expect(
      await reasonOf(
        claimAnonymous(
          db,
          {
            verify: async () => ({ uid: 'x', provider: 'password' }),
            deleteUser: async () => undefined,
          },
          { uid: 'hoa', anonymous: false, emailTrusted: true },
          { anonymousIdToken: 'x'.repeat(40) },
          now,
        ),
      ),
    ).toBe('bad-token');
  });
});

describe('end of day in a zone', () => {
  it('handles fixed and DST zones', () => {
    expect(endOfDayIn('Asia/Ho_Chi_Minh', '2026-12-31').toISOString()).toBe(
      '2026-12-31T17:00:00.000Z',
    );
    expect(endOfDayIn('America/New_York', '2026-07-04').toISOString()).toBe(
      '2026-07-05T04:00:00.000Z',
    );
    expect(endOfDayIn('America/New_York', '2026-01-04').toISOString()).toBe(
      '2026-01-05T05:00:00.000Z',
    );
  });
});

describe('membership notifications (G-109, D-092)', () => {
  const pushed: { tokens: string[]; title: string; body: string; data: Record<string, string> }[] =
    [];
  const sender: PushSender = {
    async send(tokens, message) {
      pushed.push({ tokens, title: message.title, body: message.body, data: message.data });
      return [];
    },
  };
  const notices = async () =>
    (await db.collection(`babies/${babyId}/notifications`).get()).docs.map((d) => ({
      id: d.id,
      kind: d.get('kind') as string,
      recipients: d.get('recipients') as string[],
    }));
  const inbox = async (uid: string) =>
    (await db.collection(`users/${uid}/notifications`).get()).docs.map((d) => d.data());

  beforeEach(async () => {
    pushed.length = 0;
    for (const uid of ['mom', 'nanny', 'quynh'])
      await db.doc(`users/${uid}/devices/d_${uid}`).set({ token: `t-${uid}`, language: 'vi' });
  });

  it('a join tells the co-parents (not the newcomer) and opens the family members screen', async () => {
    const ticket = await invite(mom);
    await join(nanny, ticket.code);
    const [joined] = (await notices()).filter((n) => n.kind === 'memberJoined');
    expect(joined).toEqual({
      id: `member_joined_${ticket.inviteId}`,
      kind: 'memberJoined',
      recipients: ['mom'],
    });
    await deliverNotice(db, sender, babyId, joined!.id, now);
    expect(pushed).toHaveLength(1);
    expect(pushed[0]).toMatchObject({
      tokens: ['t-mom'],
      title: 'Thành viên mới trong gia đình',
      body: 'nanny đã tham gia gia đình. Mở để xem.',
    });
    expect(pushed[0]!.data).toMatchObject({ kind: 'memberJoined', destination: 'FAMILY_MEMBERS' });
    expect((await inbox('mom'))[0]).toMatchObject({ kind: 'memberJoined', group: 'family' });
    // No baby name anywhere in the copy (R-120).
    expect(JSON.stringify(pushed)).not.toContain('Teddy');
  });

  it('the "Thành viên gia đình" switch mutes joins and declines', async () => {
    await db.doc('users/mom/settings/notifications').set({ familyMembers: false });
    const ticket = await invite(mom);
    await join(nanny, ticket.code);
    await deliverNotice(db, sender, babyId, `member_joined_${ticket.inviteId}`, now);
    expect(pushed).toHaveLength(0);
    expect(await inbox('mom')).toHaveLength(0);
  });

  it('a decline tells the inviter', async () => {
    const quynh: Caller = {
      uid: 'quynh',
      anonymous: false,
      emailTrusted: true,
      email: 'quynh@example.com',
    };
    const ticket = await invite(mom, 'coParent');
    await sendInviteEmail(
      db,
      mom,
      { inviteId: ticket.inviteId, email: 'quynh@example.com', locale: 'vi' },
      now,
    );
    await declineInvite(db, quynh, { inviteId: ticket.inviteId }, now);
    expect((await notices()).filter((n) => n.kind === 'inviteDeclined')).toEqual([
      { id: `invite_declined_${ticket.inviteId}`, kind: 'inviteDeclined', recipients: ['mom'] },
    ]);
  });

  it('a role change tells the member, a relation-only edit does not; removal opens only the inbox', async () => {
    const ticket = await invite(mom);
    await join(nanny, ticket.code);
    await updateMember(db, mom, { babyId, uid: 'nanny', relation: 'nanny' }, later(1));
    expect((await notices()).filter((n) => n.kind === 'roleChanged')).toEqual([]);
    await updateMember(db, mom, { babyId, uid: 'nanny', role: 'relative' }, later(2));
    const role = (await notices()).filter((n) => n.kind === 'roleChanged');
    expect(role).toEqual([expect.objectContaining({ recipients: ['nanny'] })]);

    await removeMember(db, mom, { babyId, uid: 'nanny' }, later(3));
    const [removed] = (await notices()).filter((n) => n.kind === 'memberRemoved');
    expect(removed!.recipients).toEqual(['nanny']);
    await deliverNotice(db, sender, babyId, removed!.id, later(3));
    expect(pushed.at(-1)).toMatchObject({
      tokens: ['t-nanny'],
      title: 'Bạn không còn trong một gia đình',
    });
    expect(pushed.at(-1)!.data.destination).toBe('INBOX');
  });
});
