/**
 * DEV only. Publishes the Nhịp lớn lên seeds (`content/rhythm/reference.seed.json`,
 * `content/rhythm/content.seed.json`, engineering drafts with `review: null`, D-073 #2) straight
 * to `publicConfig/rhythm_reference` and `publicConfig/content_rhythm`, skipping the portal's
 * two-person approval (it replaces whatever was published), with a new `ref_YYYYMMDD_NN` /
 * `rc_YYYYMMDD_NN` version. Writes `config/rhythm` with the contract default rules when it is
 * missing (`--rules` overwrites it). On prod both only ever come from the portal (PN01–PN04).
 *
 * Refuses any project other than child-life-dev. Uses the caller's gcloud credentials through the
 * Firestore REST API, like `seed-config.ts`. `--dry-run` validates and prints without writing;
 * `--dir <path>` reads the seeds from another folder.
 *   pnpm --filter child-life-scripts run seed:rhythm [-- --rules] [-- --dry-run]
 */
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import {
  defaultRhythmRules,
  firebaseProjectIds,
  localDateIn,
  referenceModelSchema,
  rhythmConfigSchema,
  rhythmContentSchema,
  rhythmPublicDocIds,
  type RhythmDoc,
} from '@child-life/contracts';

function toValue(value: unknown): unknown {
  if (value === null || value === undefined) return { nullValue: null };
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

const arg = (flag: string) => {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : undefined;
};
const has = (flag: string) => process.argv.includes(flag);

const project = arg('--project');
if (project !== firebaseProjectIds.dev) {
  console.error(
    `Refusing "${project ?? '(none)'}": this script only targets ${firebaseProjectIds.dev}.`,
  );
  process.exit(1);
}
const dryRun = has('--dry-run');
const dir = resolve(arg('--dir') ?? join(import.meta.dirname, '../../content/rhythm'));
const now = new Date();
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const token = dryRun
  ? ''
  : execFileSync('gcloud', ['auth', 'print-access-token'], { encoding: 'utf8' }).trim();
const headers = {
  Authorization: `Bearer ${token}`,
  'Content-Type': 'application/json',
  'x-goog-user-project': project,
};

async function read(path: string): Promise<Record<string, { stringValue?: string }> | null> {
  const response = await fetch(`${base}/${path}`, { headers });
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`${path}: HTTP ${response.status} ${await response.text()}`);
  return (
    ((await response.json()) as { fields?: Record<string, { stringValue?: string }> }).fields ?? {}
  );
}

async function write(path: string, data: unknown) {
  const response = await fetch(`${base}/${path}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({
      fields: (toValue(data) as { mapValue: { fields: object } }).mapValue.fields,
    }),
  });
  if (!response.ok) throw new Error(`${path}: HTTP ${response.status} ${await response.text()}`);
}

/** "rc_20261015_01", then _02 for a second release the same day (as the portal does). */
async function nextVersion(doc: RhythmDoc): Promise<string> {
  const prefix = `${doc === 'reference' ? 'ref' : 'rc'}_${localDateIn('Asia/Ho_Chi_Minh', now).replace(/-/g, '')}_`;
  if (dryRun) return `${prefix}01`;
  const last = (await read(`publicConfig/${rhythmPublicDocIds[doc]}`))?.version?.stringValue;
  const n = last?.startsWith(prefix) ? Number(last.slice(-2)) + 1 : 1;
  return `${prefix}${String(n).padStart(2, '0')}`;
}

const seeds: Record<RhythmDoc, string> = {
  reference: 'reference.seed.json',
  content: 'content.seed.json',
};
let published = 0;
for (const doc of Object.keys(seeds) as RhythmDoc[]) {
  const file = join(dir, seeds[doc]);
  if (!existsSync(file)) {
    console.warn(`${file}: not found, skipped`);
    continue;
  }
  const raw = JSON.parse(readFileSync(file, 'utf8')) as Record<string, unknown>;
  const version = await nextVersion(doc);
  const data = { ...raw, version, publishedAt: now.toISOString() };
  const parsed =
    doc === 'reference'
      ? referenceModelSchema.safeParse(data)
      : rhythmContentSchema.safeParse(data);
  if (!parsed.success) {
    console.error(`${file}: does not match the contract`);
    console.error(JSON.stringify(parsed.error.issues.slice(0, 10), null, 2));
    process.exit(1);
  }
  const path = `publicConfig/${rhythmPublicDocIds[doc]}`;
  if (!dryRun) await write(path, parsed.data);
  published += 1;
  console.log(`${path} ${dryRun ? 'valid (dry run)' : 'published'}: ${version}`);
}
if (published === 0) {
  console.error(`No seed found in ${dir}`);
  process.exit(1);
}

const config = rhythmConfigSchema.parse({ rules: defaultRhythmRules });
if (dryRun) {
  console.log(`config/rhythm valid (dry run): ${config.rules.version}`);
} else if (has('--rules') || (await read('config/rhythm')) === null) {
  await write('config/rhythm', config);
  console.log(`config/rhythm seeded: ${config.rules.version}`);
} else {
  console.log('config/rhythm kept (pass --rules to reset it to the defaults)');
}
