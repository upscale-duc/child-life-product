import { firebaseProjectIds, type Environment } from '@child-life/contracts';

/** Resolves the environment from the running project. Emulator projects use the `demo-` prefix. */
export function environmentForProject(projectId: string | undefined): Environment {
  if (!projectId) throw new Error('Project id is not available in this runtime');
  if (projectId === firebaseProjectIds.prod) return 'prod';
  if (projectId === firebaseProjectIds.dev || projectId.startsWith('demo-')) return 'dev';
  throw new Error(`Project ${projectId} is not a Child Life environment`);
}

export function currentProjectId(): string | undefined {
  return process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
}

/** Public website of the environment: invite links, unsubscribe links (plan §3.7). */
export function webOriginFor(projectId: string | undefined): string {
  return environmentForProject(projectId) === 'prod'
    ? 'https://childlife.app'
    : 'https://dev.childlife.app';
}

/**
 * The hosts serving the invite page `/i/{token}`, all in the app's Associated Domains / App Links
 * (D-059). The page's "Mở app" button links to another one: iOS ignores a Universal Link to the
 * domain the page is on. Prod has one host until a second is chosen.
 */
export function inviteHostsFor(projectId: string | undefined): string[] {
  return environmentForProject(projectId) === 'prod'
    ? ['childlife.app']
    : ['dev.childlife.app', 'child-life-dev-landing.web.app'];
}

/** "Mở app và nhận lời mời" on the page served from [host]. */
export function inviteOpenUrl(projectId: string | undefined, host: string, token: string): string {
  const hosts = inviteHostsFor(projectId);
  const other = hosts.find((h) => h !== host) ?? hosts[0]!;
  return `https://${other}/i/${token}`;
}

/** Store pages for "Cài app"; none until the app is published (dev testers install by hand). */
const storeLinks: Record<Environment, { appStore: string | null; playStore: string | null }> = {
  dev: { appStore: null, playStore: null },
  prod: { appStore: null, playStore: null },
};

export function storeLinksFor(projectId: string | undefined) {
  return storeLinks[environmentForProject(projectId)];
}

/** The staff portal of the environment: staff invitations (P-135). */
export function adminOriginFor(projectId: string | undefined): string {
  return environmentForProject(projectId) === 'prod'
    ? 'https://admin.childlife.app'
    : 'https://admin.dev.childlife.app';
}
