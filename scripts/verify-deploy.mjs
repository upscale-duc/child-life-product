#!/usr/bin/env node
/**
 * After a Functions deploy: make sure what was deployed is what is serving (D-092, one-person
 * operations). `firebase deploy` can end with "Deploy complete!" while
 *  1. a service's new revision failed its healthcheck (Cloud Run CPU quota during big deploys):
 *     the OLD revision keeps serving — 62 services on dev on 2026-10-22;
 *  2. a callable lost its public `run.invoker` binding: every call gets an HTML 403 before our
 *     code runs (staffNotificationTemplateAction, getEngagement, Lumi callables, staffTicket …).
 * This script finds both, repairs them (redeploys the stuck functions in small batches after the
 * quota recovers; re-adds `allUsers → run.invoker` on CALLABLES only — scheduled and event
 * functions stay private) and ends with one line: OK, or what is still wrong.
 *
 * Usage: node scripts/verify-deploy.mjs dev|prod [--no-wait]
 * Called by scripts/deploy.sh after any deploy that includes functions. Prod still needs
 * CHILD_LIFE_PROD_APPROVED=yes (the same gate as the deploy itself).
 */
import { execFile, execFileSync } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const env = process.argv[2];
const noWait = process.argv.includes('--no-wait');
const projects = { dev: 'child-life-dev', prod: 'child-life-ecosystem' };
const project = projects[env];
if (!project) {
  console.error('Usage: node scripts/verify-deploy.mjs dev|prod [--no-wait]');
  process.exit(2);
}
if (env === 'prod' && process.env.CHILD_LIFE_PROD_APPROVED !== 'yes') {
  console.error('Production needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run.');
  process.exit(2);
}
const region = 'asia-southeast1';
const execFileAsync = promisify(execFile);
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[verify] ${m}`);

function run(cmd, args, { quiet = false } = {}) {
  return execFileSync(cmd, args, {
    cwd: root,
    encoding: 'utf8',
    stdio: quiet ? ['ignore', 'pipe', 'pipe'] : ['ignore', 'pipe', 'inherit'],
    maxBuffer: 64 * 1024 * 1024,
  });
}

/** Deployed functions: id → callable? */
function listFunctions() {
  const out = JSON.parse(
    run('firebase', ['functions:list', '--project', project, '--json'], { quiet: true }),
  );
  const rows = out.result ?? out;
  return rows
    .filter((f) => !f.region || f.region === region)
    .map((f) => ({
      id: f.id,
      callable: 'callableTrigger' in f,
      // 1st-gen functions have no Cloud Run service (nothing to check there).
      service: f.runServiceId ?? null,
    }));
}

/** Cloud Run services whose newest revision is not the one serving. */
function stuckServices() {
  const csv = run(
    'gcloud',
    [
      'run',
      'services',
      'list',
      '--region',
      region,
      '--project',
      project,
      '--format=csv[no-heading](metadata.name,status.latestReadyRevisionName,status.latestCreatedRevisionName)',
    ],
    { quiet: true },
  );
  return csv
    .split('\n')
    .map((l) => l.split(','))
    .filter((c) => c.length === 3 && c[1] !== c[2])
    .map((c) => c[0]);
}

function redeploy(ids) {
  try {
    run('firebase', [
      'deploy',
      '--project',
      project,
      '--only',
      ids.map((id) => `functions:${id}`).join(','),
      '--force',
    ]);
    return true;
  } catch {
    return false;
  }
}

async function fixStuck(functions) {
  const byService = new Map(functions.filter((f) => f.service).map((f) => [f.service, f.id]));
  for (let round = 1; round <= 3; round++) {
    const stuck = stuckServices()
      .map((s) => byService.get(s))
      .filter(Boolean);
    if (stuck.length === 0) return [];
    log(`round ${round}: ${stuck.length} function(s) still serve an older revision`);
    if (round === 1 && !noWait) {
      log('waiting 15 min for the Cloud Run CPU quota to recover …');
      await sleep(15 * 60_000);
    }
    for (let i = 0; i < stuck.length; i += 5) {
      const batch = stuck.slice(i, i + 5);
      log(`redeploying ${batch.join(', ')}`);
      redeploy(batch);
      if (i + 5 < stuck.length) await sleep(120_000);
    }
    await sleep(60_000);
  }
  return stuckServices()
    .map((s) => byService.get(s))
    .filter(Boolean);
}

/**
 * Whether Cloud Run lets anyone reach the callable (`allUsers → roles/run.invoker`). Read from
 * the IAM policy, not by calling the function: calling ~200 callables wakes ~200 instances and
 * exhausts the CPU quota for real users (seen on dev, 2026-10-22).
 */
async function invokerOpen(id) {
  const service = serviceOf.get(id);
  if (!service) return 'n/a';
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const { stdout } = await execFileAsync(
        'gcloud',
        [
          'run',
          'services',
          'get-iam-policy',
          service,
          '--region',
          region,
          '--project',
          project,
          '--format=json',
        ],
        { cwd: root, maxBuffer: 4 * 1024 * 1024 },
      );
      const policy = JSON.parse(stdout || '{}');
      const open = (policy.bindings ?? []).some(
        (b) => b.role === 'roles/run.invoker' && (b.members ?? []).includes('allUsers'),
      );
      return open ? 'ok' : 'forbidden';
    } catch {
      await sleep(3_000 * (attempt + 1));
    }
  }
  return 'unknown';
}

async function checkAll(ids) {
  const result = new Map();
  const queue = [...ids];
  await Promise.all(
    Array.from({ length: 6 }, async () => {
      while (queue.length) {
        const id = queue.shift();
        result.set(id, await invokerOpen(id));
      }
    }),
  );
  return result;
}

function reopen(id) {
  const service = serviceOf.get(id);
  if (!service) return false;
  try {
    run(
      'gcloud',
      [
        'run',
        'services',
        'add-iam-policy-binding',
        service,
        '--region',
        region,
        '--project',
        project,
        '--member=allUsers',
        '--role=roles/run.invoker',
        '--quiet',
      ],
      { quiet: true },
    );
    return true;
  } catch {
    return false;
  }
}

const functions = listFunctions();
const callables = functions.filter((f) => f.callable).map((f) => f.id);
const serviceOf = new Map(functions.map((f) => [f.id, f.service]));
log(`${functions.length} functions, ${callables.length} callables on ${project}`);

const stillStuck = await fixStuck(functions);

let probes = await checkAll(callables);
const forbidden = callables.filter((id) => probes.get(id) === 'forbidden');
if (forbidden.length) {
  log(
    `re-opening ${forbidden.length} callable(s) without the public invoker: ${forbidden.join(', ')}`,
  );
  for (const id of forbidden) reopen(id);
  const again = await checkAll(forbidden);
  for (const [id, r] of again) probes.set(id, r);
}
const badCallables = callables.filter((id) => !['ok', 'n/a'].includes(probes.get(id)));

if (stillStuck.length === 0 && badCallables.length === 0) {
  console.log(
    `✔ verify ${env}: all ${functions.length} functions serve their newest revision; all ${callables.length} callables are reachable (public invoker).`,
  );
  process.exit(0);
}
console.log(
  `✖ verify ${env}: ${stillStuck.length ? `still on an older revision: ${stillStuck.join(', ')}. ` : ''}${
    badCallables.length
      ? `callables not reachable: ${badCallables.map((id) => `${id} (${probes.get(id)})`).join(', ')}.`
      : ''
  } Re-run: node scripts/verify-deploy.mjs ${env}`,
);
process.exit(1);
