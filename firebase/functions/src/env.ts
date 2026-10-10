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
