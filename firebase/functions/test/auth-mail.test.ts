import { describe, expect, it } from 'vitest';
import { appSignInUrl, AuthMailError, sendAuthEmail, signInLinkTarget } from '../src/auth-mail.js';
import { otherAppHost } from '../src/env.js';
import { renderSignInLinkPage } from '../src/pages.js';

// The app's "Gửi link đăng nhập" (07a / 07b, D-064): Firebase's action link rebuilt on the
// website, whose /auth/link/ opens the app; a browser gets a page pointing to the other domain.
const action =
  'https://child-life-dev.firebaseapp.com/__/auth/action?apiKey=AIzaSyA-abcdefghijklmnopqrstu&mode=signIn&oobCode=Xy_z-0123456789abc&continueUrl=https%3A%2F%2Fdev.childlife.app%2Fauth%2Flink%2F&lang=vi';
const now = new Date('2026-10-13T03:00:00.000Z');
const exp = String(now.getTime() / 1000 + 15 * 60);

function fakes() {
  const limits = new Map<string, Record<string, unknown>>();
  const sent: { to: string; subject: string; html: string }[] = [];
  const generated: { email: string; url: string; handleCodeInApp: boolean }[] = [];
  const db = {
    doc: (path: string) => ({ path }),
    runTransaction: async (fn: (tx: unknown) => Promise<void>) =>
      fn({
        get: async (ref: { path: string }) => ({
          get: (field: string) => limits.get(ref.path)?.[field],
        }),
        set: (ref: { path: string }, data: Record<string, unknown>) => limits.set(ref.path, data),
      }),
  };
  const auth = {
    generateSignInWithEmailLink: async (
      email: string,
      settings: { url: string; handleCodeInApp: boolean },
    ) => {
      generated.push({ email, ...settings });
      return action;
    },
  };
  const sender = {
    send: async (m: { to: string; subject: string; html: string }) => {
      sent.push(m);
    },
  };
  const deps = {
    db: db as never,
    auth: auth as never,
    sender: sender as never,
    adminOrigin: 'https://admin.dev.childlife.app',
    webOrigin: 'https://dev.childlife.app',
    continueUrl: 'https://child-life-dev-landing.web.app/auth/link/',
  };
  return { deps, sent, generated };
}

describe('app sign-in link', () => {
  it('rebuilds the action link on the website with a 15-minute deadline', () => {
    const url = new URL(appSignInUrl(action, 'https://dev.childlife.app', now));
    expect(url.origin + url.pathname).toBe('https://dev.childlife.app/auth/link/');
    expect(Object.fromEntries(url.searchParams)).toEqual({
      mode: 'signIn',
      oobCode: 'Xy_z-0123456789abc',
      apiKey: 'AIzaSyA-abcdefghijklmnopqrstu',
      lang: 'vi',
      exp,
    });
  });

  it('mails anyone a link, with the usual per-address limit', async () => {
    const { deps, sent, generated } = fakes();
    const req = { kind: 'appSignInLink', email: 'Mai@Example.com', locale: 'vi' };
    await expect(sendAuthEmail(deps, null, req, now)).resolves.toEqual({ ok: true });
    expect(generated).toEqual([
      {
        email: 'mai@example.com',
        url: 'https://child-life-dev-landing.web.app/auth/link/',
        handleCodeInApp: true,
      },
    ]);
    expect(sent).toHaveLength(1);
    expect(sent[0]!.to).toBe('mai@example.com');
    expect(sent[0]!.subject).toBe('Đăng nhập Child Life');
    expect(sent[0]!.html).toContain(
      'https://dev.childlife.app/auth/link/?mode=signIn&amp;oobCode=',
    );
    expect(sent[0]!.html).not.toContain('firebaseapp.com');
    // A second mail within the minute is refused before anything is generated.
    await expect(sendAuthEmail(deps, null, req, now)).rejects.toBeInstanceOf(AuthMailError);
    expect(generated).toHaveLength(1);
  });

  it('opened in a browser: the same link on the other domain, or expired', () => {
    const query = Object.fromEntries(new URL(appSignInUrl(action, 'https://x', now)).searchParams);
    const host = otherAppHost('child-life-dev', 'dev.childlife.app');
    expect(host).toBe('child-life-dev-landing.web.app');
    const open = signInLinkTarget(query, host, now);
    expect(open.expired).toBe(false);
    expect(open.openUrl).toBe(
      `https://child-life-dev-landing.web.app/auth/link/?mode=signIn&oobCode=Xy_z-0123456789abc&apiKey=AIzaSyA-abcdefghijklmnopqrstu&lang=vi&exp=${exp}`,
    );
    expect(renderSignInLinkPage('vi', open)).toContain('Mở Child Life');

    const later = new Date(now.getTime() + 16 * 60 * 1000);
    expect(signInLinkTarget(query, host, later)).toEqual({ openUrl: null, expired: true });
    expect(renderSignInLinkPage('en', { openUrl: null, expired: true })).toContain(
      'This link has expired',
    );
    // Anything else in the query is dropped; a bad code is not passed on.
    expect(signInLinkTarget({ ...query, x: '"><script>' }, host, now).openUrl).not.toContain(
      'script',
    );
    expect(signInLinkTarget({ ...query, oobCode: '"><b>' }, host, now).openUrl).toBeNull();
  });
});
