import type { Environment } from '@child-life/contracts';

/** GA4 measurement id per environment (public, not a secret). `null` loads no analytics: dev is
 *  never measured, and prod stays off until the owner's GA4 web stream for childlife.app exists.
 *  The owner chose to measure without a consent banner (2026-10-30); the privacy page says so. */
export const analyticsIds: Record<Environment, string | null> = {
  dev: null,
  prod: 'G-CJ3X59FL2P',
};

type Gtag = (...args: unknown[]) => void;

/** Loads gtag.js after the page is interactive. Page views only (plus GA4's enhanced
 *  measurement); the landing has no account or child data to send. */
export function startAnalytics(environment: Environment): void {
  const id = analyticsIds[environment];
  if (!id) return;
  const w = window as unknown as { dataLayer: unknown[]; gtag: Gtag };
  w.dataLayer = w.dataLayer ?? [];
  w.gtag = function gtag() {
    // gtag.js reads the `arguments` object itself, not an array.
    // eslint-disable-next-line prefer-rest-params
    w.dataLayer.push(arguments);
  };
  w.gtag('js', new Date());
  w.gtag('config', id);
  const script = document.createElement('script');
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(id)}`;
  document.head.appendChild(script);
}
