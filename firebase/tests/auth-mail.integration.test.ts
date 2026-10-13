import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import type { Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { sendAuthEmail } from '../functions/src/auth-mail.js';
import type { OutgoingMail } from '../functions/src/mail.js';

// Branded sign-in mail (D-054) against the Firestore emulator, with a stand-in for Firebase Auth.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const now = new Date('2026-10-11T03:00:00Z');
const later = (s: number) => new Date(now.getTime() + s * 1000);
const sent: OutgoingMail[] = [];
const sender = { send: async (m: OutgoingMail) => void sent.push(m) };
const users = new Set(['mai@example.com']);
const auth = {
  generatePasswordResetLink: async (email: string) => {
    if (!users.has(email))
      throw Object.assign(new Error('no user'), { code: 'auth/email-not-found' });
    return 'https://x.test/reset?oobCode=r1';
  },
  generateEmailVerificationLink: async () => 'https://x.test/verify?oobCode=v1',
  generateSignInWithEmailLink: async (_: string, s: { url: string }) =>
    `https://x.test/signin?mode=signIn&oobCode=s1&apiKey=k1&continueUrl=${encodeURIComponent(s.url)}`,
} as unknown as Auth;
const deps = () => ({
  db,
  auth,
  sender,
  adminOrigin: 'https://admin.test',
  webOrigin: 'https://web.test',
  continueUrl: 'https://landing.test/auth/link/',
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );

beforeAll(() => {
  app = initializeApp({ projectId }, `auth-mail-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  sent.length = 0;
  for (const c of ['authMailLimits', 'staffMembers', 'staffInvites']) {
    await db.recursiveDelete(db.collection(c));
  }
});

describe('"Quên mật khẩu" (09)', () => {
  it('sends the branded mail; an unknown address gets the same answer and no mail', async () => {
    const ok = await sendAuthEmail(
      deps(),
      null,
      { kind: 'resetPassword', email: 'Mai@Example.com', locale: 'vi' },
      now,
    );
    expect(ok).toEqual({ ok: true });
    expect(sent[0]!.to).toBe('mai@example.com');
    expect(sent[0]!.subject).toBe('Đặt lại mật khẩu Child Life');
    expect(sent[0]!.html).toContain('https://x.test/reset?oobCode=r1');
    expect(
      await sendAuthEmail(
        deps(),
        null,
        { kind: 'resetPassword', email: 'nobody@example.com', locale: 'en' },
        now,
      ),
    ).toEqual({ ok: true });
    expect(sent).toHaveLength(1);
  });

  it('one a minute and five a day per address, before looking the account up', async () => {
    const ask = (at: Date, email = 'nobody@example.com') =>
      reason(sendAuthEmail(deps(), null, { kind: 'resetPassword', email, locale: 'vi' }, at));
    expect(await ask(now)).toBe('ok');
    expect(await ask(later(30))).toBe('too-soon');
    for (let i = 1; i <= 4; i++) expect(await ask(later(i * 61))).toBe('ok');
    expect(await ask(later(10 * 61))).toBe('too-many');
  });
});

describe('"Xác minh email" (08)', () => {
  it('only for the signed-in account, once verified nothing is sent', async () => {
    expect(await reason(sendAuthEmail(deps(), null, { kind: 'verifyEmail' }, now))).toBe(
      'sign-in-first',
    );
    await sendAuthEmail(
      deps(),
      { uid: 'u1', email: 'mai@example.com', emailVerified: false },
      { kind: 'verifyEmail', locale: 'en' },
      now,
    );
    expect(sent[0]!.subject).toBe('Verify your email');
    await sendAuthEmail(
      deps(),
      { uid: 'u1', email: 'mai@example.com', emailVerified: true },
      { kind: 'verifyEmail' },
      later(120),
    );
    expect(sent).toHaveLength(1);
  });
});

describe('portal "Link qua email"', () => {
  it('staff and invited staff only, continuing to the portal', async () => {
    await sendAuthEmail(deps(), null, { kind: 'signInLink', email: 'stranger@example.com' }, now);
    expect(sent).toHaveLength(0);
    await db.doc('staffInvites/i1').set({ email: 'new@example.com', state: 'pending' });
    await sendAuthEmail(deps(), null, { kind: 'signInLink', email: 'new@example.com' }, now);
    expect(sent[0]!.html).toContain(`continueUrl=${encodeURIComponent('https://admin.test/')}`);
    expect(sent[0]!.subject).toBe('Đăng nhập Child Life · Vận hành');
  });

  it('without a provider the client falls back to Firebase', async () => {
    expect(
      await reason(
        sendAuthEmail(
          { ...deps(), sender: null },
          null,
          { kind: 'signInLink', email: 'a@example.com' },
          now,
        ),
      ),
    ).toBe('no-provider');
    expect(
      await reason(sendAuthEmail(deps(), null, { kind: 'resetPassword', email: 'x' }, now)),
    ).toBe('malformed');
  });
});

describe('app "Gửi link đăng nhập" (07a, D-064)', () => {
  it('anyone gets a link on the website that opens the app, once a minute', async () => {
    await sendAuthEmail(
      deps(),
      null,
      { kind: 'appSignInLink', email: 'new@example.com', locale: 'vi' },
      now,
    );
    expect(sent).toHaveLength(1);
    expect(sent[0]!.subject).toBe('Đăng nhập Child Life');
    expect(sent[0]!.html).toContain('https://web.test/auth/link/?mode=signIn&amp;oobCode=s1');
    expect(sent[0]!.html).not.toContain('x.test');
    expect(
      await reason(
        sendAuthEmail(deps(), null, { kind: 'appSignInLink', email: 'new@example.com' }, later(30)),
      ),
    ).toBe('too-soon');
  });
});
