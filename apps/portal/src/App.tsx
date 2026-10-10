import {
  functionsRegion,
  pingResponseSchema,
  type Environment,
  type PingResponse,
} from '@child-life/contracts';
import type { SupportedLocale } from '@child-life/web-config';
import type { FirebaseApp } from 'firebase/app';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { useEffect, useState } from 'react';
import { FormattedDate, FormattedMessage, FormattedTime, IntlProvider } from 'react-intl';
import { messages } from './messages';

type PingState =
  | { status: 'pending' }
  | { status: 'ok'; result: PingResponse }
  | { status: 'error'; message: string };

/**
 * S0 shell: proves the admin site reaches its own environment's backend.
 * Staff sign-in (A01, Firebase Auth + TOTP — D-008) and the screens A02–A12 arrive in Slice S15.
 */
export function App({
  app,
  environment,
  locale,
}: {
  app: FirebaseApp;
  environment: Environment;
  locale: SupportedLocale;
}) {
  const [ping, setPing] = useState<PingState>({ status: 'pending' });

  useEffect(() => {
    const call = httpsCallable(getFunctions(app, functionsRegion), 'ping');
    call({ clientEnvironment: environment, opId: crypto.randomUUID() })
      .then((res) => setPing({ status: 'ok', result: pingResponseSchema.parse(res.data) }))
      .catch((error: unknown) => setPing({ status: 'error', message: String(error) }));
  }, [app, environment]);

  return (
    <IntlProvider locale={locale} defaultLocale="vi" messages={messages[locale]}>
      <main style={{ fontFamily: 'system-ui, sans-serif', padding: 24, color: '#173D44' }}>
        <h1 style={{ fontSize: 24, fontWeight: 600 }}>
          <FormattedMessage id="portal.title" />
        </h1>
        <p>
          <FormattedMessage id="portal.environment" values={{ environment }} />
        </p>
        {ping.status === 'pending' && (
          <p>
            <FormattedMessage id="portal.ping.pending" />
          </p>
        )}
        {ping.status === 'ok' && (
          <p>
            <FormattedMessage
              id="portal.ping.ok"
              values={{
                projectId: ping.result.projectId,
                region: ping.result.region,
                time: (
                  <>
                    <FormattedDate value={ping.result.serverTime} />{' '}
                    <FormattedTime value={ping.result.serverTime} />
                  </>
                ),
              }}
            />
          </p>
        )}
        {ping.status === 'error' && (
          <p role="alert">
            <FormattedMessage id="portal.ping.error" values={{ message: ping.message }} />
          </p>
        )}
      </main>
    </IntlProvider>
  );
}
