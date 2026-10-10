/**
 * Seeds `config/flags` and `config/limits` in the DEV project with the contract defaults.
 * The `mirrorPublicConfig` function then publishes the validated projections to `publicConfig/*`.
 *
 * Refuses any project other than child-life-dev (brief §03: dev seed scripts reject prod).
 * Uses the caller's gcloud credentials (`gcloud auth login`) through the Firestore REST API.
 */
import { execFileSync } from 'node:child_process';
import {
  defaultFlags,
  defaultLimits,
  firebaseProjectIds,
  flagsSchema,
  limitsSchema,
} from '@child-life/contracts';

type FirestoreValue =
  | { nullValue: null }
  | { booleanValue: boolean }
  | { integerValue: string }
  | { doubleValue: number }
  | { stringValue: string }
  | { arrayValue: { values: FirestoreValue[] } }
  | { mapValue: { fields: Record<string, FirestoreValue> } };

function toValue(value: unknown): FirestoreValue {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(toValue) } };
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toValue(v)])),
      },
    };
  }
  throw new Error(`Unsupported value: ${String(value)}`);
}

function argValue(flag: string): string | undefined {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

const project = argValue('--project');
if (project !== firebaseProjectIds.dev) {
  console.error(
    `Refusing to seed "${project ?? '(none)'}": this script only targets ${firebaseProjectIds.dev}.`,
  );
  process.exit(1);
}

const token = execFileSync('gcloud', ['auth', 'print-access-token'], { encoding: 'utf8' }).trim();
const documents = {
  flags: flagsSchema.parse(defaultFlags),
  limits: limitsSchema.parse(defaultLimits),
};

for (const [id, data] of Object.entries(documents)) {
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/config/${id}`;
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'x-goog-user-project': project,
    },
    body: JSON.stringify({
      fields: (toValue(data) as { mapValue: { fields: object } }).mapValue.fields,
    }),
  });
  if (!response.ok) {
    console.error(`config/${id}: HTTP ${response.status} ${await response.text()}`);
    process.exit(1);
  }
  console.log(`config/${id} seeded in ${project}`);
}
