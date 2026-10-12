import { createHash, randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { resolveExportDownload } from '../functions/src/export-download.js';
import { deliverMail, type OutgoingMail } from '../functions/src/mail.js';

// "Tải tệp về" from the export email (R-187, P-123) against the Firestore emulator.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const now = new Date('2026-10-12T01:00:00Z');
const babyId = 'b_ex0000000000000000aa';
const jobId = 'ex_0123456789abcdef0123';
const token = 'A'.repeat(32);
const issued: [string, string][] = [];
const issuer = {
  issue: async (path: string, filename: string) => {
    issued.push([path, filename]);
    return `https://files.test/${issued.length}`;
  },
};
const hours = (h: number) => new Date(now.getTime() + h * 3_600_000);
const resolve = (t = token, at = now) => resolveExportDownload(db, issuer, jobId, t, at);

beforeAll(() => {
  app = initializeApp({ projectId }, `export-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  issued.length = 0;
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  await db
    .doc(`babies/${babyId}/members/mom`)
    .set({ role: 'coParent', status: 'active', isOwner: true });
  await db.doc(`dataJobs/${jobId}`).set({
    kind: 'export',
    exportKind: 'care',
    babyId,
    uid: 'mom',
    state: 'ready',
    path: `exports/mom/${jobId}/child-life-care.zip`,
    readyAt: Timestamp.fromDate(now),
    expiresAt: Timestamp.fromDate(hours(24)),
    downloadTokenHash: createHash('sha256').update(token).digest('hex'),
  });
});

describe('exportDownload', () => {
  it('the right token, while ready and allowed, gets a fresh file URL', async () => {
    expect(await resolve()).toEqual({ kind: 'redirect', url: 'https://files.test/1' });
    expect(issued[0]).toEqual([
      `exports/mom/${jobId}/child-life-care.zip`,
      'child-life-care-2026-10-12.zip',
    ]);
  });

  it('a wrong or malformed token looks the same as an unknown job', async () => {
    expect(await resolve('B'.repeat(32))).toEqual({ kind: 'invalid' });
    expect(await resolve('short')).toEqual({ kind: 'invalid' });
    expect(await resolveExportDownload(db, issuer, 'ex_ffffffffffffffffffff', token, now)).toEqual({
      kind: 'invalid',
    });
    expect(issued).toHaveLength(0);
  });

  it('after 24 hours, or once expired, the page says so', async () => {
    expect(await resolve(token, hours(25))).toEqual({ kind: 'expired' });
    await db.doc(`dataJobs/${jobId}`).update({ state: 'expired', path: null });
    expect(await resolve()).toEqual({ kind: 'expired' });
  });

  it('the right is re-checked at every click (removed, or no longer the owner for media)', async () => {
    await db.doc(`babies/${babyId}/members/mom`).update({ status: 'removed' });
    expect(await resolve()).toEqual({ kind: 'denied' });
    await db.doc(`babies/${babyId}/members/mom`).update({ status: 'active', isOwner: false });
    expect((await resolve()).kind).toBe('redirect');
    await db.doc(`dataJobs/${jobId}`).update({ exportKind: 'media' });
    expect(await resolve()).toEqual({ kind: 'denied' });
  });

  it('the email carries the link; the queue forgets the token once sent', async () => {
    const ref = await db.collection('mail').add({
      to: 'mom@example.com',
      template: 'exportReady',
      locale: 'vi',
      data: { jobId, token, size: '3 MB' },
      unsubscribeToken: 'x'.repeat(32),
      status: 'queued',
      attempts: 0,
      createdAt: now,
    });
    const sent: OutgoingMail[] = [];
    await deliverMail(
      await ref.get(),
      { send: async (m) => void sent.push(m) },
      {
        webOrigin: 'https://w.test',
        functionsOrigin: 'https://fn.test',
        now,
      },
    );
    expect(sent[0]!.html).toContain(`href="https://fn.test/exportDownload/${jobId}/${token}"`);
    expect(sent[0]!.html).toContain('Tải tệp về');
    expect(sent[0]!.text).toContain('Dung lượng: 3 MB');
    expect((await ref.get()).get('data.token')).toBeNull();
    await ref.delete();
  });
});
