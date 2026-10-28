import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { AiSummaryError } from '../functions/src/ai-summary.js';
import { handoverSendId, markHandover, sendHandover } from '../functions/src/handover-send.js';
import { deliverNotice, type PushSender } from '../functions/src/social.js';
import { setCareDuty } from '../functions/src/care-duty.js';

// D-093 "Gửi cho Jun": a handover sent to one member, through the family notice pipeline.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T03:00:00Z');
const babyId = 'b_teddy';
const summaryId = `su_${'a'.repeat(32)}`;
let app: App;
let db: Firestore;

const pushed: { tokens: string[]; title: string; body: string; data: Record<string, string> }[] =
  [];
const sender: PushSender = {
  async send(tokens, message) {
    pushed.push({ tokens, title: message.title, body: message.body, data: message.data });
    return [];
  },
};

async function reasonOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof AiSummaryError) return error.reason;
    throw error;
  }
  throw new Error('expected an AiSummaryError');
}

beforeAll(() => {
  app = initializeApp({ projectId }, `handover-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) throw new Error('Run with the Firestore emulator');
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  pushed.length = 0;
  await db
    .doc(`babies/${babyId}`)
    .set({ nickname: 'Teddy', timeZone: { zone: 'Asia/Ho_Chi_Minh' } });
  const member = (uid: string, role: string, extra: Record<string, unknown> = {}) =>
    db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      status: 'active',
      displayName: uid === 'mom' ? 'Duckie' : uid,
      ...extra,
    });
  await member('mom', 'coParent', { relation: 'mother' });
  await member('jun', 'caregiver', { relation: 'father' });
  await member('grandma', 'relative');
  await db.doc(`babies/${babyId}/summaries/${summaryId}`).set({
    id: summaryId,
    kind: 'handover',
    status: 'ready',
  });
  await db.doc('users/jun/devices/d_jun').set({ token: 't-jun', language: 'vi' });
});

describe('sendHandover (D-093)', () => {
  it('records the send, pushes who sent it (no child data) and opens that handover', async () => {
    const result = await sendHandover(db, 'mom', { babyId, summaryId, recipientUid: 'jun' }, now);
    expect(result).toEqual({
      sendId: handoverSendId(summaryId, 'jun'),
      sentAt: now.toISOString(),
      pushable: true,
    });
    const send = await db.doc(`babies/${babyId}/handoverSends/${result.sendId}`).get();
    expect(send.data()).toMatchObject({ senderUid: 'mom', recipientUid: 'jun', seenAt: null });
    await deliverNotice(db, sender, babyId, `handover_${result.sendId}`, now);
    expect(pushed).toHaveLength(1);
    expect(pushed[0]).toMatchObject({
      tokens: ['t-jun'],
      title: 'Bàn giao cho bạn',
      body: 'Duckie vừa gửi bàn giao cho bạn. Mở để xem.',
    });
    expect(pushed[0]!.data).toMatchObject({
      kind: 'handoverSent',
      destination: 'CARE_HANDOVER',
      summaryId,
    });
    expect(JSON.stringify(pushed)).not.toContain('Teddy');
  });

  it('a second tap returns the first send and pushes nothing more', async () => {
    const first = await sendHandover(db, 'mom', { babyId, summaryId, recipientUid: 'jun' }, now);
    const again = await sendHandover(
      db,
      'mom',
      { babyId, summaryId, recipientUid: 'jun' },
      new Date(now.getTime() + 60_000),
    );
    expect(again.sentAt).toBe(first.sentAt);
    expect((await db.collection(`babies/${babyId}/notifications`).get()).size).toBe(1);
  });

  it('works both ways; never to oneself, nor to someone who cannot read care', async () => {
    expect(
      (await sendHandover(db, 'jun', { babyId, summaryId, recipientUid: 'mom' }, now)).pushable,
    ).toBe(false);
    expect(
      await reasonOf(sendHandover(db, 'mom', { babyId, summaryId, recipientUid: 'mom' }, now)),
    ).toBe('self');
    expect(
      await reasonOf(sendHandover(db, 'mom', { babyId, summaryId, recipientUid: 'grandma' }, now)),
    ).toBe('recipient-cannot-read');
    expect(
      await reasonOf(sendHandover(db, 'grandma', { babyId, summaryId, recipientUid: 'jun' }, now)),
    ).toBe('ROLE_DENIED');
  });

  it('says when the push cannot reach them (switch off or no device)', async () => {
    await db.doc('users/jun/settings/notifications').set({ handovers: false });
    expect(
      (await sendHandover(db, 'mom', { babyId, summaryId, recipientUid: 'jun' }, now)).pushable,
    ).toBe(false);
  });

  it('enabled handover settings alone do not make a device reachable; registration does', async () => {
    await db.doc('users/jun/settings/notifications').set({ handovers: true });
    await db.doc('users/jun/devices/d_jun').delete();
    const request = { babyId, summaryId, recipientUid: 'jun' };
    const before = await sendHandover(db, 'mom', request, now);
    expect(before.pushable).toBe(false);
    // The handover exists even while the push endpoint is missing.
    expect((await db.doc(`babies/${babyId}/handoverSends/${before.sendId}`).get()).exists).toBe(true);
    await db.doc('users/jun/devices/d_jun').set({ token: 'new-token', language: 'vi' });
    const after = await sendHandover(db, 'mom', request, now);
    expect(after.pushable).toBe(true);
    expect(after.sendId).toBe(before.sendId);
  });

  it('the recipient marks it seen, then received; nobody else can', async () => {
    const { sendId } = await sendHandover(
      db,
      'mom',
      { babyId, summaryId, recipientUid: 'jun' },
      now,
    );
    expect(await reasonOf(markHandover(db, 'mom', { babyId, sendId, action: 'seen' }, now))).toBe(
      'send-not-found',
    );
    const seen = await markHandover(db, 'jun', { babyId, sendId, action: 'seen' }, now);
    expect(seen).toEqual({ seenAt: now.toISOString(), receivedAt: null });
    const later = new Date(now.getTime() + 5 * 60_000);
    const received = await markHandover(db, 'jun', { babyId, sendId, action: 'received' }, later);
    expect(received).toEqual({ seenAt: now.toISOString(), receivedAt: later.toISOString() });
  });

  it('only a ready handover can be sent', async () => {
    await db.doc(`babies/${babyId}/summaries/${summaryId}`).update({ status: 'pending' });
    expect(
      await reasonOf(sendHandover(db, 'mom', { babyId, summaryId, recipientUid: 'jun' }, now)),
    ).toBe('summary-not-found');
  });
});

describe('P-181 "Ai đang trông bé"', () => {
  const duty = async () => (await db.doc(`babies/${babyId}/careDuty/current`).get()).data();
  const later = new Date(now.getTime() + 60 * 60_000);

  it('records the verified parent pair, with idempotent retries from either parent', async () => {
    const result = await setCareDuty(
      db,
      'mom',
      { babyId, action: 'together', coCarerUid: 'jun' },
      now,
    );
    expect(result).toEqual({ uid: 'mom', coCarerUid: 'jun', since: now.toISOString() });
    expect(
      await setCareDuty(db, 'jun', { babyId, action: 'together', coCarerUid: 'mom' }, later),
    ).toEqual(result);
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60_000);
    expect(
      await setCareDuty(db, 'mom', { babyId, action: 'together', coCarerUid: 'jun' }, tomorrow),
    ).toMatchObject({ since: tomorrow.toISOString() });
  });

  it.each(['mom', 'jun'])('ending %s’s part keeps the other parent on duty', async (ending) => {
    await setCareDuty(db, 'mom', { babyId, action: 'together', coCarerUid: 'jun' }, now);
    const remaining = ending === 'mom' ? 'jun' : 'mom';
    expect(await setCareDuty(db, ending, { babyId, action: 'end' }, later)).toEqual({
      uid: remaining,
      since: now.toISOString(),
    });
    expect(await duty()).toMatchObject({ uid: remaining, coCarerUid: null, previousUid: ending });
    await setCareDuty(db, remaining, { babyId, action: 'end' }, later);
    expect(await duty()).toMatchObject({ uid: null, coCarerUid: null });
  });

  it('refuses a fabricated parent pair or inactive parent without changing the current duty', async () => {
    await setCareDuty(db, 'mom', { babyId, action: 'take' }, now);
    for (const coCarerUid of ['mom', 'grandma', 'unknown']) {
      expect(
        await reasonOf(setCareDuty(db, 'mom', { babyId, action: 'together', coCarerUid }, later)),
      ).toBe('not-a-parent-pair');
    }
    await db.doc(`babies/${babyId}/members/jun`).update({ status: 'removed' });
    expect(
      await reasonOf(
        setCareDuty(db, 'mom', { babyId, action: 'together', coCarerUid: 'jun' }, later),
      ),
    ).toBe('not-a-parent-pair');
    expect(await duty()).toMatchObject({ uid: 'mom', coCarerUid: null });
    expect(await reasonOf(setCareDuty(db, 'mom', { babyId, action: 'together' }, later))).toBe(
      'bad-request',
    );
  });

  it('a solo take or a received handover clears the previous parent pair', async () => {
    await setCareDuty(db, 'mom', { babyId, action: 'together', coCarerUid: 'jun' }, now);
    await setCareDuty(db, 'mom', { babyId, action: 'take' }, later);
    expect(await duty()).toMatchObject({ uid: 'mom', coCarerUid: null, previousCoCarerUid: 'jun' });
    await setCareDuty(db, 'mom', { babyId, action: 'together', coCarerUid: 'jun' }, now);
    const { sendId } = await sendHandover(
      db,
      'mom',
      { babyId, summaryId, recipientUid: 'jun' },
      now,
    );
    await markHandover(db, 'jun', { babyId, sendId, action: 'received' }, later);
    expect(await duty()).toMatchObject({ uid: 'jun', coCarerUid: null, via: 'handover' });
  });

  it('a carer takes it, the next one takes over, and only the one on duty can end it', async () => {
    expect(await setCareDuty(db, 'mom', { babyId, action: 'take' }, now)).toEqual({
      uid: 'mom',
      since: now.toISOString(),
    });
    expect(await duty()).toMatchObject({ uid: 'mom', via: 'manual', previousUid: null });
    await setCareDuty(db, 'jun', { babyId, action: 'take' }, later);
    const d = await duty();
    expect(d).toMatchObject({ uid: 'jun', previousUid: 'mom' });
    expect(d?.previousUntil.toDate()).toEqual(later);
    // Mẹ ending someone else's duty changes nothing; Jun ending theirs clears it.
    await setCareDuty(db, 'mom', { babyId, action: 'end' }, later);
    expect(await duty()).toMatchObject({ uid: 'jun' });
    await setCareDuty(db, 'jun', { babyId, action: 'end' }, later);
    expect(await duty()).toMatchObject({ uid: null, previousUid: 'jun' });
  });

  it('a relative (no care logging) cannot take it; bad input is refused', async () => {
    expect(await reasonOf(setCareDuty(db, 'grandma', { babyId, action: 'take' }, now))).toBe(
      'not-a-carer',
    );
    expect(await reasonOf(setCareDuty(db, 'mom', { babyId, action: 'nap' }, now))).toBe(
      'bad-request',
    );
  });

  it('renews an expired shift for the same carer; a fresh retry keeps its start time', async () => {
    await setCareDuty(db, 'mom', { babyId, action: 'take' }, now);
    const freshRetry = await setCareDuty(db, 'mom', { babyId, action: 'take' }, later);
    expect(freshRetry.since).toBe(now.toISOString());
    expect((await duty())?.since.toDate()).toEqual(now);

    // Mobile treats a shift >=24h old as inactive and offers "Tôi trông bé" again.
    const nextDay = new Date(now.getTime() + 24 * 60 * 60_000);
    const renewed = await setCareDuty(db, 'mom', { babyId, action: 'take' }, nextDay);
    expect(renewed).toEqual({ uid: 'mom', since: nextDay.toISOString() });
    expect((await duty())?.since.toDate()).toEqual(nextDay);
  });

  it('receiving a handover puts the recipient on duty, once', async () => {
    await setCareDuty(db, 'mom', { babyId, action: 'take' }, now);
    const { sendId } = await sendHandover(
      db,
      'mom',
      { babyId, summaryId, recipientUid: 'jun' },
      now,
    );
    await markHandover(db, 'jun', { babyId, sendId, action: 'seen' }, now);
    expect(await duty()).toMatchObject({ uid: 'mom' });
    await markHandover(db, 'jun', { babyId, sendId, action: 'received' }, later);
    expect(await duty()).toMatchObject({ uid: 'jun', via: 'handover', previousUid: 'mom' });
    // Mẹ takes it back; a second "received" does not move it again.
    await setCareDuty(db, 'mom', { babyId, action: 'take' }, later);
    await markHandover(db, 'jun', { babyId, sendId, action: 'received' }, later);
    expect(await duty()).toMatchObject({ uid: 'mom' });
  });
});
