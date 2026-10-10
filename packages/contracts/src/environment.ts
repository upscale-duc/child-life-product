/** Deployment environments. Emulators are a local test target, not an environment. */
export const environments = ['dev', 'prod'] as const;
export type Environment = (typeof environments)[number];

/** Firebase project that each environment must talk to. A mismatch is a fatal configuration error. */
export const firebaseProjectIds: Record<Environment, string> = {
  dev: 'child-life-dev',
  prod: 'child-life-prod',
};

/** Public hosts per environment (implementation plan §3.7). */
export const publicHosts: Record<Environment, { site: string; admin: string }> = {
  dev: { site: 'dev.childlife.app', admin: 'admin.dev.childlife.app' },
  prod: { site: 'childlife.app', admin: 'admin.childlife.app' },
};

export const functionsRegion = 'asia-southeast1';
