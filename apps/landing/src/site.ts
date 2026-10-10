import type { Environment } from '@child-life/contracts';

/** Public origin of the landing per environment. Dev uses the Firebase default domain until
 *  dev.childlife.app DNS is connected (plan §3.7). */
export const siteOrigin: Record<Environment, string> = {
  dev: 'https://child-life-dev-landing.web.app',
  prod: 'https://childlife.app',
};

/** Store listings are not published yet; `null` renders the badges as "coming soon". */
export const storeLinks: { appStore: string | null; googlePlay: string | null } = {
  appStore: null,
  googlePlay: null,
};

export const contactEmail = 'hello@childlife.app';
