import { createHash } from 'node:crypto';
import type { Auth } from 'firebase-admin/auth';
import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';
import type { MailSender } from './mail.js';
import { renderAuthEmail, type AuthTemplate } from './mail-templates.js';

/**
 * Branded sign-in mail (D-054) instead of Firebase Auth's own templates: "Xác minh email" (08),
 * "Quên mật khẩu" (09), the portal's "Link qua email" and the app's "Gửi link đăng nhập" (07a, D-064).
 * The link comes from the Admin SDK and goes straight to the provider (never stored or logged). Each address gets at most one mail a
 * minute and five a day per kind, checked before anything about the account is looked up, so the
 * answer never tells whether an address has an account. Without a provider the caller falls back
 * to Firebase's own mail ("no-provider").
 */

export class AuthMailError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'unauthenticated' | 'resource-exhausted' | 'unavailable',
    readonly reason: string,
  ) {
    super(reason);
  }
}

export const authMailLimits = { minGapSeconds: 60, perDay: 5 } as const;

const locale = z.enum(['vi', 'en']).default('vi');
const email = z.email().max(254);
const requestSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('verifyEmail'), locale }).strict(),
  z.object({ kind: z.literal('resetPassword'), email, locale }).strict(),
  z.object({ kind: z.literal('signInLink'), email, locale }).strict(),
  z.object({ kind: z.literal('appSignInLink'), email, locale }).strict(),
]);

/** 07b "Mở link trên điện thoại này trong 15 phút" (D-064). */
export const appSignInLinkMinutes = 15;

/** The app's path for an email sign-in link, on the web domains that open the app (D-064). */
export const appSignInPath = '/auth/link/';

const hash = (s: string) => createHash('sha256').update(s).digest('hex');

export async function sendAuthEmail(
  deps: {
    db: Firestore;
    auth: Auth;
    sender: MailSender | null;
    adminOrigin: string;
    /** The public website (`webOriginFor`): the app's sign-in links open there (D-064). */
    webOrigin: string;
    /** `signInContinueUrlFor`: required by Firebase, never opened. */
    continueUrl: string;
  },
  caller: { uid: string; email: string | undefined; emailVerified: boolean | undefined } | null,
  data: unknown,
  now: Date,
): Promise<{ ok: true }> {
  const parsed = requestSchema.safeParse(data);
  if (!parsed.success) throw new AuthMailError('invalid-argument', 'malformed');
  const req = parsed.data;
  if (!deps.sender) throw new AuthMailError('unavailable', 'no-provider');

  let to: string;
  if (req.kind === 'verifyEmail') {
    if (!caller?.email) throw new AuthMailError('unauthenticated', 'sign-in-first');
    if (caller.emailVerified) return { ok: true };
    to = caller.email.toLowerCase();
  } else {
    to = req.email.trim().toLowerCase();
  }
  await claim(deps.db, req.kind, to, now);

  const link = await linkFor(deps, req.kind, to, now);
  if (!link) return { ok: true };
  await deps.sender.send({ to, ...renderAuthEmail(req.kind, req.locale, { link, email: to }) });
  return { ok: true };
}

/** One per minute, five per day, per kind and address (the hash only is kept). */
async function claim(db: Firestore, kind: AuthTemplate, to: string, now: Date) {
  const ref = db.doc(`authMailLimits/${hash(`${kind}:${to}`)}`);
  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const day = now.toISOString().slice(0, 10);
    const last = doc.get('lastAt') as Timestamp | undefined;
    const sameDay = doc.get('day') === day;
    const count = sameDay ? ((doc.get('count') as number | undefined) ?? 0) : 0;
    if (last && now.getTime() - last.toMillis() < authMailLimits.minGapSeconds * 1000) {
      throw new AuthMailError('resource-exhausted', 'too-soon');
    }
    if (count >= authMailLimits.perDay) {
      throw new AuthMailError('resource-exhausted', 'too-many');
    }
    tx.set(ref, { kind, day, count: count + 1, lastAt: Timestamp.fromDate(now) });
  });
}

/** The action link, or null when nothing should be sent (no such account, not staff). */
async function linkFor(
  deps: { db: Firestore; auth: Auth; adminOrigin: string; webOrigin: string; continueUrl: string },
  kind: AuthTemplate,
  to: string,
  now: Date,
): Promise<string | null> {
  const notFound = (e: unknown) =>
    (e as { code?: string }).code === 'auth/user-not-found' ||
    (e as { code?: string }).code === 'auth/email-not-found';
  switch (kind) {
    case 'verifyEmail':
      return deps.auth.generateEmailVerificationLink(to);
    case 'resetPassword':
      try {
        return await deps.auth.generatePasswordResetLink(to);
      } catch (e) {
        if (notFound(e)) return null;
        throw e;
      }
    case 'signInLink': {
      // The portal is for staff and invited staff only (P-135).
      const [member, invite] = await Promise.all([
        deps.db.collection('staffMembers').where('email', '==', to).limit(1).get(),
        deps.db
          .collection('staffInvites')
          .where('email', '==', to)
          .where('state', '==', 'pending')
          .limit(1)
          .get(),
      ]);
      if (member.empty && invite.empty) return null;
      return deps.auth.generateSignInWithEmailLink(to, {
        url: `${deps.adminOrigin}/`,
        handleCodeInApp: true,
      });
    }
    case 'appSignInLink': {
      // Anyone may sign in or sign up with a link (D-064); the answer is the same either way.
      const action = await deps.auth.generateSignInWithEmailLink(to, {
        url: deps.continueUrl,
        handleCodeInApp: true,
      });
      return appSignInUrl(action, deps.webOrigin, now);
    }
  }
}

/**
 * Firebase's action link (`…firebaseapp.com/__/auth/action?mode=signIn&oobCode=…`) rebuilt on the
 * website, whose `/auth/link/` is a Universal Link / App Link into the app (D-064); a browser gets a
 * page that says to open it on the phone. `exp` is the 15 minutes of 07b, checked by the app and
 * the page; Firebase's own expiry still applies after it.
 */
export function appSignInUrl(action: string, webOrigin: string, now: Date): string {
  const from = new URL(action).searchParams;
  const params = new URLSearchParams();
  for (const key of ['mode', 'oobCode', 'apiKey', 'lang']) {
    const value = from.get(key);
    if (value) params.set(key, value);
  }
  params.set('exp', String(Math.floor(now.getTime() / 1000) + appSignInLinkMinutes * 60));
  return `${webOrigin}${appSignInPath}?${params.toString()}`;
}

/**
 * The page for a sign-in link opened in a browser (D-064): the same link on [otherHost], so the
 * button opens the app, or expired. Only the link's own parameters are passed on.
 */
export function signInLinkTarget(
  query: Record<string, unknown>,
  otherHost: string,
  now: Date,
): { openUrl: string | null; expired: boolean } {
  const value = (key: string, pattern: RegExp) => {
    const v = query[key];
    return typeof v === 'string' && pattern.test(v) ? v : null;
  };
  const code = value('oobCode', /^[A-Za-z0-9_-]{10,200}$/);
  const apiKey = value('apiKey', /^[A-Za-z0-9_-]{20,60}$/);
  const exp = Number(value('exp', /^[0-9]{9,11}$/));
  if (!code || !apiKey || value('mode', /^signIn$/) === null || !exp) {
    return { openUrl: null, expired: true };
  }
  if (now.getTime() / 1000 > exp) return { openUrl: null, expired: true };
  const params = new URLSearchParams({ mode: 'signIn', oobCode: code, apiKey });
  const lang = value('lang', /^[a-z]{2}(-[A-Za-z]{2})?$/);
  if (lang) params.set('lang', lang);
  params.set('exp', String(exp));
  return { openUrl: `https://${otherHost}${appSignInPath}?${params.toString()}`, expired: false };
}
