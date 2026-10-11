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
    : 'https://child-life-dev-landing.web.app';
}

/** The staff portal of the environment: staff invitations (P-135). */
export function adminOriginFor(projectId: string | undefined): string {
  return environmentForProject(projectId) === 'prod'
    ? 'https://admin.childlife.app'
    : 'https://admin.dev.childlife.app';
}
