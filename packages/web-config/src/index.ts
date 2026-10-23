export * from './locale.js';
import {
  environments,
  firebaseProjectIds,
  publicHosts,
  type Environment,
} from '@child-life/contracts';

/** Public Firebase web configuration (identifiers, not secrets). Browser keys are restricted by referrer in GCP. */
export interface WebFirebaseConfig {
  apiKey: string;
  authDomain: string;
  projectId: string;
  storageBucket: string;
  messagingSenderId: string;
  appId: string;
  measurementId: string;
}

export type WebSurface = 'landing' | 'admin';

const devBase = {
  apiKey: 'AIzaSyDoAqOt57wZcaun72-sVdNJP5egVICn1gI',
  authDomain: 'child-life-dev.firebaseapp.com',
  projectId: 'child-life-dev',
  storageBucket: 'child-life-dev.firebasestorage.app',
  messagingSenderId: '759703503909',
} as const;

/** `null` = not provisioned yet. Prod is created later by the owner (D-005). */
export const webFirebaseConfigs: Record<Environment, Record<WebSurface, WebFirebaseConfig> | null> =
  {
    dev: {
      landing: {
        ...devBase,
        appId: '1:759703503909:web:7a79eb37c64ed0d7ca6bcc',
        measurementId: 'G-QESQ7YMN5Z',
      },
      admin: {
        ...devBase,
        appId: '1:759703503909:web:901e6118eec736d4ca6bcc',
        measurementId: 'G-X05X65NDEV',
      },
    },
    prod: null,
  };

export class EnvironmentConfigError extends Error {
  override name = 'EnvironmentConfigError';
}

function allowedHosts(environment: Environment, surface: WebSurface): (host: string) => boolean {
  const hosts = publicHosts[environment];
  const project = firebaseProjectIds[environment];
  const exact = new Set(
    surface === 'admin'
      ? [hosts.admin]
      : [hosts.site, ...(environment === 'prod' ? ['www.childlife.app'] : [])],
  );
  return (host) => {
    if (exact.has(host)) return true;
    // Firebase default domains and preview channels for this project's sites.
    if (host.endsWith('.web.app') || host.endsWith('.firebaseapp.com'))
      return host.startsWith(project);
    // Local development is always dev.
    return environment === 'dev' && (host === 'localhost' || host === '127.0.0.1');
  };
}

/**
 * Resolves the environment of a web build and refuses mixed or missing configuration:
 * unknown build mode, missing Firebase config, config pointing at another project,
 * or a page served from a host that belongs to the other environment.
 */
export function resolveWebEnvironment(
  mode: string,
  surface: WebSurface,
  host: string,
): { environment: Environment; firebase: WebFirebaseConfig } {
  const environment = environmentOf(mode);
  const configs = webFirebaseConfigs[environment];
  if (!configs) throw new EnvironmentConfigError(`Firebase is not configured for ${environment}`);
  const firebase = configs[surface];
  if (firebase.projectId !== firebaseProjectIds[environment]) {
    throw new EnvironmentConfigError(
      `${environment} build points at project ${firebase.projectId}`,
    );
  }
  if (!allowedHosts(environment, surface)(host)) {
    throw new EnvironmentConfigError(`${environment} ${surface} build must not run on ${host}`);
  }
  return { environment, firebase };
}

/**
 * The landing site's check: it loads no Firebase SDK, so it needs no Firebase web config, only a
 * known build mode served from one of that environment's site hosts.
 */
export function resolveSiteEnvironment(mode: string, host: string): Environment {
  const environment = environmentOf(mode);
  if (!allowedHosts(environment, 'landing')(host)) {
    throw new EnvironmentConfigError(`${environment} landing build must not run on ${host}`);
  }
  return environment;
}

function environmentOf(mode: string): Environment {
  if (!(environments as readonly string[]).includes(mode)) {
    throw new EnvironmentConfigError(`Unknown build mode "${mode}" (expected dev or prod)`);
  }
  return mode as Environment;
}
