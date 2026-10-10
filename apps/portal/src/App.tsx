import type { Environment } from '@child-life/contracts';
import { saveLocale, type SupportedLocale } from '@child-life/web-config';
import {
  getAdditionalUserInfo,
  isSignInWithEmailLink,
  onAuthStateChanged,
  sendPasswordResetEmail,
  sendSignInLinkToEmail,
  signInWithEmailAndPassword,
  signInWithEmailLink,
  signOut,
  type Auth,
  type UserCredential,
} from 'firebase/auth';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { IntlProvider } from 'react-intl';
import { ApiContext, type Api } from './api';
import { StaffContext } from './context';
import { messages } from './messages';
import { SignInScreen, type SignInActions, type SignInNotice } from './screens/SignIn';
import {
  clearActivity,
  idleExpired,
  linkEmail,
  markActivity,
  readActivity,
  rememberLinkEmail,
  staffFromClaims,
  IDLE_MS,
  type StaffIdentity,
} from './session';
import { Shell } from './Shell';
import { Loading } from './ui';

type Session =
  | { kind: 'checking' }
  | { kind: 'signedOut'; notice: SignInNotice }
  | { kind: 'staff'; staff: StaffIdentity };

/**
 * The staff portal (S15, Figma A01–A12). Access needs the `staff` claim; anyone else is signed
 * out again (and an account the email link has just created is removed). D-043: no TOTP.
 */
export function App({
  auth,
  api,
  environment,
  initialLocale,
}: {
  auth: Auth;
  api: Api;
  environment: Environment;
  initialLocale: SupportedLocale;
}) {
  const [locale, setLocale] = useState(initialLocale);
  const [session, setSession] = useState<Session>({ kind: 'checking' });
  const [pendingLink, setPendingLink] = useState(false);
  // While a fresh sign-in is checked (and possibly removed), the auth listener stands aside.
  const signingIn = useRef(false);

  const end = useCallback(
    async (notice: SignInNotice) => {
      clearActivity();
      setSession({ kind: 'signedOut', notice });
      await signOut(auth);
    },
    [auth],
  );

  /** A just-created email-link account without the claim is deleted, so no stray users remain. */
  const checkCredential = useCallback(async (cred: UserCredential) => {
    const token = await cred.user.getIdTokenResult(true);
    const staff = staffFromClaims(cred.user.uid, cred.user.email, token.claims);
    if (!staff) {
      if (getAdditionalUserInfo(cred)?.isNewUser) await cred.user.delete().catch(() => undefined);
      throw Object.assign(new Error('denied'), { code: 'portal/denied' });
    }
    markActivity(Date.now());
    setSession({ kind: 'staff', staff });
  }, []);

  /** Runs one sign-in with the auth listener paused, then signs out again if it was refused. */
  const signIn = useCallback(
    async (attempt: () => Promise<UserCredential>) => {
      signingIn.current = true;
      markActivity(Date.now());
      try {
        await checkCredential(await attempt());
      } catch (e) {
        if ((e as { code?: string }).code === 'portal/denied') await end('denied');
        throw e;
      } finally {
        signingIn.current = false;
      }
    },
    [checkCredential, end],
  );

  useEffect(
    () =>
      onAuthStateChanged(auth, (user) => {
        if (signingIn.current) return;
        if (!user) {
          setSession((s) => (s.kind === 'signedOut' ? s : { kind: 'signedOut', notice: null }));
          return;
        }
        if (idleExpired(readActivity(), Date.now())) {
          void end('idle');
          return;
        }
        user
          .getIdTokenResult(true)
          .then((token) => {
            const staff = staffFromClaims(user.uid, user.email, token.claims);
            if (!staff) return end('denied');
            markActivity(Date.now());
            setSession({ kind: 'staff', staff });
          })
          .catch(() => end(null));
      }),
    [auth, end],
  );

  // Completing an email link opened in this browser.
  useEffect(() => {
    const href = window.location.href;
    if (!isSignInWithEmailLink(auth, href)) return;
    const email = linkEmail();
    if (!email) {
      setPendingLink(true);
      return;
    }
    signIn(() => signInWithEmailLink(auth, email, href))
      .catch(async (e: { code?: string }) => {
        if (e.code !== 'portal/denied') await end('linkInvalid');
      })
      .finally(() => {
        rememberLinkEmail(null);
        window.history.replaceState({}, '', '/');
      });
  }, [auth, signIn, end]);

  // Idle sign-out (A01 "Tự đăng xuất sau 30 phút không hoạt động"), shared across tabs.
  useEffect(() => {
    if (session.kind !== 'staff') return;
    let last = 0;
    const touch = () => {
      const now = Date.now();
      if (now - last > 15_000) {
        last = now;
        markActivity(now);
      }
    };
    const events = ['pointerdown', 'keydown', 'mousemove', 'wheel', 'touchstart'] as const;
    events.forEach((e) => window.addEventListener(e, touch, { passive: true }));
    const check = setInterval(() => {
      if (idleExpired(readActivity() ?? Date.now() - IDLE_MS, Date.now())) void end('idle');
    }, 30_000);
    return () => {
      events.forEach((e) => window.removeEventListener(e, touch));
      clearInterval(check);
    };
  }, [session.kind, end]);

  const actions = useMemo<SignInActions>(
    () => ({
      withPassword: (email, password) =>
        signIn(() => signInWithEmailAndPassword(auth, email, password)),
      async sendLink(email) {
        await sendSignInLinkToEmail(auth, email, {
          url: `${window.location.origin}/`,
          handleCodeInApp: true,
        });
        rememberLinkEmail(email);
      },
      async resetPassword(email) {
        await sendPasswordResetEmail(auth, email).catch((e: { code?: string }) => {
          // Same answer whether or not the address has an account.
          if (e.code !== 'auth/user-not-found') throw e;
        });
      },
      async finishLink(email) {
        try {
          await signIn(() => signInWithEmailLink(auth, email, window.location.href));
        } finally {
          setPendingLink(false);
          window.history.replaceState({}, '', '/');
        }
      },
    }),
    [auth, signIn],
  );

  const changeLocale = (l: SupportedLocale) => {
    saveLocale(l);
    document.documentElement.lang = l;
    setLocale(l);
  };

  return (
    <IntlProvider locale={locale} defaultLocale="vi" messages={messages[locale]}>
      <ApiContext.Provider value={api}>
        {session.kind === 'checking' ? (
          <Loading />
        ) : session.kind === 'staff' ? (
          <StaffContext.Provider value={session.staff}>
            <Shell
              environment={environment}
              locale={locale}
              onLocale={changeLocale}
              onSignOut={() => void end(null)}
            />
          </StaffContext.Provider>
        ) : (
          <SignInScreen actions={actions} notice={session.notice} pendingLink={pendingLink} />
        )}
      </ApiContext.Provider>
    </IntlProvider>
  );
}
