import { useState, type FormEvent } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { maskEmail } from '@child-life/contracts';
import { Button, Segmented } from '../ui';

export type SignInNotice = 'denied' | 'linkInvalid' | null;

export interface SignInActions {
  withPassword(email: string, password: string): Promise<void>;
  sendLink(email: string): Promise<void>;
  resetPassword(email: string): Promise<void>;
  /** Completes an email link opened on another browser (the address must be typed again). */
  finishLink(email: string): Promise<void>;
}

/** Firebase Auth error codes → message ids (no account enumeration: one message for both). */
export function authErrorId(code: string): string {
  switch (code) {
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
    case 'auth/invalid-login-credentials':
      return 'signIn.error.credentials';
    case 'auth/invalid-email':
    case 'auth/missing-email':
    case 'invalid-argument': // sendAuthEmail: malformed address
      return 'signIn.error.email';
    case 'auth/too-many-requests':
    case 'resource-exhausted': // sendAuthEmail: one a minute, five a day per address
      return 'signIn.error.tooMany';
    case 'auth/network-request-failed':
      return 'signIn.error.network';
    case 'auth/invalid-action-code':
    case 'auth/expired-action-code':
      return 'signIn.notice.linkInvalid';
    case 'portal/denied':
      return 'signIn.notice.denied';
    case 'auth/user-disabled':
      return 'signIn.error.disabled';
    default:
      return 'signIn.error.generic';
  }
}

/**
 * A01 Đăng nhập (D-043): email + password, or a sign-in link by email. No TOTP and no company
 * SSO in V1; the staff claim decides access, and the session stays until sign-out (D-062).
 */
export function SignInScreen({
  actions,
  notice,
  pendingLink,
}: {
  actions: SignInActions;
  notice: SignInNotice;
  /** An email link was opened here, but the address it was sent to is unknown. */
  pendingLink: boolean;
}) {
  const intl = useIntl();
  const [mode, setMode] = useState<'password' | 'link'>('password');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState<'link' | 'reset' | null>(null);

  const run = async (fn: () => Promise<void>, after?: 'link' | 'reset') => {
    setBusy(true);
    setError(null);
    try {
      await fn();
      if (after) setSent(after);
    } catch (e) {
      setError(authErrorId((e as { code?: string }).code ?? ''));
    } finally {
      setBusy(false);
    }
  };
  const submit = (e: FormEvent) => {
    e.preventDefault();
    const address = email.trim();
    if (pendingLink) void run(() => actions.finishLink(address));
    else if (mode === 'password') void run(() => actions.withPassword(address, password));
    else void run(() => actions.sendLink(address), 'link');
  };

  return (
    <main className="signin">
      <aside className="signin__brand">
        <div>
          <p className="brand">
            Child Life <span className="brand__sub">Vận hành</span>
          </p>
          <h1 className="signin__headline">
            <FormattedMessage id="signIn.headline" />
          </h1>
          <ul className="promises">
            {(['photos', 'reason', 'masked'] as const).map((k) => (
              <li key={k}>
                <span className="promises__check" aria-hidden="true">
                  ✓
                </span>
                <FormattedMessage id={`signIn.promise.${k}`} />
              </li>
            ))}
          </ul>
        </div>
        <p className="signin__foot">
          <FormattedMessage id="signIn.internal" />
        </p>
      </aside>
      <section className="signin__main">
        <form className="signin__card" onSubmit={submit} noValidate>
          <h2 className="signin__title">
            <FormattedMessage id="signIn.title" />
          </h2>
          <p className="muted">
            <FormattedMessage id={pendingLink ? 'signIn.confirmSub' : 'signIn.sub'} />
          </p>

          {notice && !error && (
            <p className="note note--warn" role="status">
              <FormattedMessage id={`signIn.notice.${notice}`} />
            </p>
          )}

          {!pendingLink && (
            <Segmented
              label={intl.formatMessage({ id: 'signIn.method' })}
              value={mode}
              onChange={(m) => {
                setMode(m);
                setSent(null);
                setError(null);
              }}
              options={[
                { value: 'password', label: <FormattedMessage id="signIn.password" /> },
                { value: 'link', label: <FormattedMessage id="signIn.link" /> },
              ]}
            />
          )}

          {sent ? (
            <div className="sent" role="status">
              <p className="sent__title">
                <FormattedMessage id={sent === 'link' ? 'signIn.linkSent' : 'signIn.resetSent'} />
              </p>
              <p className="muted">
                <FormattedMessage
                  id={sent === 'link' ? 'signIn.linkSentBody' : 'signIn.resetSentBody'}
                  values={{ email: maskEmail(email.trim()) }}
                />
              </p>
              <Button kind="ghost" onClick={() => setSent(null)}>
                <FormattedMessage id="signIn.useOther" />
              </Button>
            </div>
          ) : (
            <>
              <div className="field">
                <label className="field__label" htmlFor="email">
                  <FormattedMessage id="signIn.email" />
                </label>
                <input
                  id="email"
                  className="field__input"
                  type="email"
                  autoComplete="username"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>
              {mode === 'password' && !pendingLink && (
                <div className="field">
                  <label className="field__label" htmlFor="password">
                    <FormattedMessage id="signIn.passwordLabel" />
                  </label>
                  <input
                    id="password"
                    className="field__input"
                    type="password"
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
              )}
              {error && (
                <p className="error" role="alert">
                  <FormattedMessage id={error} />
                </p>
              )}
              <Button
                kind="primary"
                type="submit"
                disabled={
                  busy || !email.trim() || (mode === 'password' && !pendingLink && !password)
                }
              >
                <FormattedMessage
                  id={
                    pendingLink
                      ? 'signIn.continue'
                      : mode === 'password'
                        ? 'signIn.submit'
                        : 'signIn.sendLink'
                  }
                />
              </Button>
              {mode === 'password' && !pendingLink && (
                <button
                  type="button"
                  className="linkbtn"
                  disabled={busy || !email.trim()}
                  onClick={() => void run(() => actions.resetPassword(email.trim()), 'reset')}
                >
                  <FormattedMessage id="signIn.forgot" />
                </button>
              )}
            </>
          )}
        </form>
      </section>
    </main>
  );
}
