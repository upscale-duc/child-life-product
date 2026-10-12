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
  type User,
  type UserCredential,
} from 'firebase/auth';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { IntlProvider } from 'react-intl';
import { ApiContext, ApiError, type Api, type StaffMe } from './api';
import { StaffContext } from './context';
import { messages } from './messages';
import { SignInScreen, type SignInActions, type SignInNotice } from './screens/SignIn';
import { linkEmail, rememberLinkEmail, staffFromClaims, type StaffIdentity } from './session';
import { Shell } from './Shell';
import { Loading } from './ui';

type Session =
  | { kind: 'checking' }
  | { kind: 'signedOut'; notice: SignInNotice }
  | { kind: 'staff'; staff: StaffIdentity };

/**
 * Who this account is on the portal: the `staff` claim, or a pending invitation accepted on this
 * first sign-in (P-135); then `staffMe` gives the stored roles and levels (P-134). `null` = refused.
 */
export async function identify(user: User, api: Api): Promise<StaffIdentity | null> {
  // A fresh token picks up role changes; offline, the stored one still says who this is (D-062).
  let token = await user.getIdTokenResult(true).catch(() => user.getIdTokenResult());
  let staff = staffFromClaims(user.uid, user.email, token.claims);
  if (!staff) {
    try {
      await api.call('staffAcceptInvite');
    } catch (e) {
      // No invitation (or not verified) is a refusal; a network error is tried again.
      if (e instanceof ApiError && ['permission-denied', 'failed-precondition'].includes(e.code)) {
        return null;
      }
      throw e;
    }
    token = await user.getIdTokenResult(true);
    staff = staffFromClaims(user.uid, user.email, token.claims);
    if (!staff) return null;
  }
  try {
    const me = await api.call<StaffMe>('staffMe');
    return { ...staff, name: me.name, roles: me.roles, roleNames: me.roleNames, levels: me.levels };
  } catch (e) {
    // Paused, removed or expired since the token was issued.
    if (e instanceof ApiError && e.code === 'permission-denied') return null;
    return staff;
  }
}

/**
 * The staff portal (S15, Figma A01–A12; v1.0 P-134). Access needs the `staff` claim or an
 * invitation; anyone else is signed out again (and an account the email link has just created is
 * removed). D-043: no TOTP.
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
      setSession({ kind: 'signedOut', notice });
      await signOut(auth);
    },
    [auth],
  );

  /** A just-created email-link account without the claim is deleted, so no stray users remain. */
  const checkCredential = useCallback(
    async (cred: UserCredential) => {
      const staff = await identify(cred.user, api);
      if (!staff) {
        if (getAdditionalUserInfo(cred)?.isNewUser) await cred.user.delete().catch(() => undefined);
        throw Object.assign(new Error('denied'), { code: 'portal/denied' });
      }
      setSession({ kind: 'staff', staff });
    },
    [api],
  );

  /** Runs one sign-in with the auth listener paused, then signs out again if it was refused. */
  const signIn = useCallback(
    async (attempt: () => Promise<UserCredential>) => {
      signingIn.current = true;
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

  // The session stays until the member signs out or loses access (D-062: no idle sign-out).
  // Offline or a slow first call keeps the session and tries again; only a refusal signs out.
  useEffect(() => {
    let retry: ReturnType<typeof setTimeout> | undefined;
    const resolve = (user: User, attempt: number) => {
      identify(user, api)
        .then((staff) => {
          if (!staff) return end('denied');
          setSession({ kind: 'staff', staff });
        })
        .catch(() => {
          retry = setTimeout(
            () => resolve(user, attempt + 1),
            Math.min(30_000, 2_000 * 2 ** attempt),
          );
        });
    };
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      clearTimeout(retry);
      if (signingIn.current) return;
      if (!user) {
        setSession((s) => (s.kind === 'signedOut' ? s : { kind: 'signedOut', notice: null }));
        return;
      }
      resolve(user, 0);
    });
    return () => {
      clearTimeout(retry);
      unsubscribe();
    };
  }, [auth, api, end]);

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

  // Branded mail through `sendAuthEmail` (D-054); Firebase's own mail while no provider is set up.
  const sendAuthMail = useCallback(
    async (kind: 'signInLink' | 'resetPassword', email: string, fallback: () => Promise<void>) => {
      try {
        await api.call('sendAuthEmail', { kind, email, locale });
      } catch (e) {
        if (!(e instanceof ApiError) || e.code !== 'unavailable') throw e;
        await fallback();
      }
    },
    [api, locale],
  );

  const actions = useMemo<SignInActions>(
    () => ({
      withPassword: (email, password) =>
        signIn(() => signInWithEmailAndPassword(auth, email, password)),
      async sendLink(email) {
        await sendAuthMail('signInLink', email, () =>
          sendSignInLinkToEmail(auth, email, {
            url: `${window.location.origin}/`,
            handleCodeInApp: true,
          }),
        );
        rememberLinkEmail(email);
      },
      async resetPassword(email) {
        await sendAuthMail('resetPassword', email, () =>
          sendPasswordResetEmail(auth, email).catch((e: { code?: string }) => {
            // Same answer whether or not the address has an account.
            if (e.code !== 'auth/user-not-found') throw e;
          }),
        );
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
    [auth, signIn, sendAuthMail],
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
