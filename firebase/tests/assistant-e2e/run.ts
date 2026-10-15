/**
 * Lumi end-to-end harness — CLI (docs/assistant/test-plan.md). Runs every scenario of `cases/*.json`
 * through the real callables and worker on the Firestore emulator, checks the invariants on every
 * snapshot, probes "fix and save" like the app, exports the snapshots for the app replay test, and
 * compares the violations with the known-failure baseline.
 *
 * Fake model (CI, every run; no network, no key):
 *   pnpm --filter @child-life/contracts run build
 *   firebase emulators:exec --only firestore --project demo-child-life-e2e \
 *     --config firebase/tests/assistant-e2e/firebase.e2e.json \
 *     "pnpm --dir firebase/tests exec tsx assistant-e2e/run.ts --mode fake"
 *
 * Live model (owner-approved spend; key from Secret Manager into the env only, never printed):
 *   OPENAI_API_KEY="$(gcloud secrets versions access latest --secret=OPENAI_API_KEY --project child-life-dev)" \
 *   firebase emulators:exec … "pnpm --dir firebase/tests exec tsx assistant-e2e/run.ts --mode live --max-calls 250"
 *
 * Flags: --only id,id  --group care.  --out <dir> (default $TMPDIR/lumi-e2e-<mode>)
 *        --export-fixtures (writes apps/mobile/test/features/assistant_replay/fixtures/)
 *        --strict (ignore the baseline: every violation fails)
 * Output: <out>/results.json, <out>/summary.md. Message text never leaves the synthetic cases.
 */
import { mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import {
  applyPatch,
  B,
  confirmNow,
  countRecords,
  savedRecordData,
  dateSpec,
  db,
  describeLocal,
  fixedPayload,
  initDb,
  liveGateway,
  pendingOf,
  quota,
  ROOT,
  runCase,
  seedWorld,
  snapshotOf,
  controls,
  WHO_OF,
  type CaseRun,
  type LiveMeter,
  type RunContext,
} from './harness.js';
import {
  checkExpect,
  checkSaves,
  checkSharedThread,
  checkSnapshot,
  closeRules,
  rulesEnvironment,
} from './invariants.js';
import { memoryAttachmentStore } from '../../functions/src/assistant-attachments.js';
import { legacyClientDraftKinds, type AssistantTaskSnapshot } from '@child-life/contracts';
import type { Case, CaseFile, Violation } from './types.js';

const args = process.argv.slice(2);
const arg = (name: string) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};
const has = (name: string) => args.includes(`--${name}`);
const mode = (arg('mode') ?? 'fake') as 'fake' | 'live';
const only = arg('only')?.split(',').filter(Boolean) ?? null;
const group = arg('group') ?? null;
const outDir = resolve(arg('out') ?? join(tmpdir(), `lumi-e2e-${mode}`));
const exportFixtures = has('export-fixtures');
const strict = has('strict');
const HERE = import.meta.dirname;
const FIXTURES = resolve(ROOT, 'apps/mobile/test/features/assistant_replay/fixtures');
/** The app tests' clock (`assistantNow`): exported snapshots are moved so their send time is it. */
const APP_NOW = Date.parse('2026-10-15T07:20:00.000Z');
const isoRe = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?Z$/;

const files = readdirSync(resolve(HERE, 'cases'))
  .filter((f) => f.endsWith('.json'))
  .sort();
const all: Case[] = [];
for (const f of files) {
  const cf = JSON.parse(readFileSync(resolve(HERE, 'cases', f), 'utf8')) as CaseFile;
  for (const c of cf.cases) all.push({ ...c, group: c.group ?? cf.group });
}
const ids = new Set<string>();
for (const c of all) {
  if (ids.has(c.id)) throw new Error(`duplicate case id ${c.id}`);
  ids.add(c.id);
}
const isPhoto = (c: Case) => c.turns.some((t) => 'photo' in t);
const cases = all.filter(
  (c) =>
    (!only || only.includes(c.id)) &&
    (!group || c.group.startsWith(group)) &&
    (mode === 'fake' || (c.live !== false && !isPhoto(c))),
);

const baseline = JSON.parse(readFileSync(resolve(HERE, 'known-failures.json'), 'utf8')) as {
  cases: Record<string, { bug: string; codes: string[] }>;
};

const meter: LiveMeter = {
  calls: 0,
  refused: 0,
  max: Number(arg('max-calls') ?? 250),
  promptTokens: 0,
  completionTokens: 0,
  latencies: [],
};
let live = null;
if (mode === 'live') {
  const key = process.env.OPENAI_API_KEY ?? '';
  if (!key) throw new Error('OPENAI_API_KEY is not set (read it from Secret Manager into the env)');
  live = liveGateway(key, process.env.OPENAI_MODEL ?? 'gpt-4.1-mini', meter);
}

initDb(process.env.GCLOUD_PROJECT ?? 'demo-child-life-e2e');
const store = memoryAttachmentStore();
const ctx: RunContext = { mode, live, files: store };
const host = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8287').split(':');
const env = await rulesEnvironment(host[0]!, Number(host[1]));

interface Result {
  id: string;
  group: string;
  device: string | null;
  as: string;
  ok: boolean;
  violations: Violation[];
  outcome: string | null;
  asked: string[];
  calls: number;
  credits: number;
  saved: number;
  steps: number;
  ms: number;
  error: string | null;
}
const results: Result[] = [];
mkdirSync(outDir, { recursive: true });
if (exportFixtures) {
  mkdirSync(FIXTURES, { recursive: true });
  for (const f of readdirSync(FIXTURES)) if (f.endsWith('.json')) rmSync(resolve(FIXTURES, f));
}

for (const c of cases) {
  if (mode === 'live' && meter.calls >= meter.max) break;
  const t0 = Date.now();
  let run: CaseRun | null = null;
  const violations: Violation[] = [];
  let error: string | null = null;
  let credits = 0;
  let saved = 0;
  try {
    await seedWorld(c, store);
    const q0 = await quota();
    const r0 = await countRecords();
    run = await runCase(c, ctx);
    // ---- Invariants on every snapshot ----
    for (const s of run.steps) {
      violations.push(
        ...checkSnapshot(c, s.snapshot, s.label, new Date(s.at), userTextOf(c, s.turn)),
      );
      // LUMI-05: an app build from before 2026-10-16 never gets a draft it cannot show.
      const turn = c.turns[s.turn];
      if (turn && 'say' in turn && turn.client === 'legacy') {
        for (const d of s.snapshot.drafts) {
          if (!(legacyClientDraftKinds as readonly string[]).includes(d.payload.kind)) {
            violations.push({
              code: 'CLIENT_KIND_UNSUPPORTED',
              severity: 'P0',
              at: s.label,
              detail: `a ${d.payload.kind} draft sent to an app that cannot show it (dead end)`,
            });
          }
        }
      }
    }
    // ---- Probe: fix every flagged draft like the app's editor, then save (with a retry) ----
    if (!c.noProbe) await probe(c, run, violations);
    violations.push(...(await checkSharedThread(run, 'end')));
    violations.push(...(await checkSaves(run, env)));
    // 2026-10-16: what the saved records hold (e.g. the head circumference of a measurement).
    for (const [key, want] of Object.entries(c.expect.recordData ?? {})) {
      const [type, field] = key.split('.') as [string, string];
      const rows = await savedRecordData(type);
      if (!rows.some((d) => JSON.stringify(d[field] ?? null) === JSON.stringify(want))) {
        violations.push({
          code: 'EXPECT_RECORD',
          severity: 'P1',
          at: 'expect',
          detail: `no saved ${type} record has ${field} = ${JSON.stringify(want)} (got ${JSON.stringify(rows.map((d) => d[field] ?? null))})`,
        });
      }
    }
    const q1 = await quota();
    credits = q1.used - q0.used;
    saved = (await countRecords()) - r0;
    if (
      q1.reserved >
      run.steps.filter(
        (s) => s.snapshot.task.state === 'awaiting_clarification' && s === lastOf(run!, s.taskId),
      ).length
    ) {
      violations.push({
        code: 'CREDITS_LEAK',
        severity: 'P1',
        at: 'end',
        detail: `${q1.reserved} credit(s) still reserved`,
      });
    }
    violations.push(
      ...checkExpect(c, run, credits, saved - savedByProbe(run), mode, describeLocal, dateSpec),
    );
  } catch (e) {
    error = e instanceof Error ? `${e.message.slice(0, 200)}` : String(e);
    violations.push({ code: 'HARNESS_ERROR', severity: 'P1', at: 'run', detail: error });
  }
  const allowed = new Set(c.expect.allow ?? []);
  const kept = dedupe(violations.filter((x) => !allowed.has(x.code)));
  const last = run?.lastTaskId ? (lastOf(run, run.lastTaskId)?.snapshot ?? null) : null;
  results.push({
    id: c.id,
    group: c.group,
    device: c.device ?? null,
    as: c.as ?? 'MOM',
    ok: kept.length === 0,
    violations: kept,
    outcome: last ? outcomeLabel(run!, last) : (run?.refusals[0]?.reason ?? null),
    asked: run?.asked ?? [],
    calls: run?.modelCalls ?? 0,
    credits,
    saved,
    steps: run?.steps.length ?? 0,
    ms: Date.now() - t0,
    error,
  });
  if (exportFixtures && run && mode === 'fake') exportCase(c, run, kept);
  if (run) {
    mkdirSync(resolve(outDir, 'snapshots'), { recursive: true });
    writeFileSync(
      resolve(outDir, 'snapshots', `${c.id}.json`),
      `${JSON.stringify({ steps: run.steps.map((s) => ({ label: s.label, uid: s.uid, at: s.at, snapshot: { ...s.snapshot, events: [] } })), confirms: run.confirms, refusals: run.refusals, asked: run.asked, patches: run.patches }, null, 1)}\n`,
    );
  }
  process.stdout.write(kept.length === 0 ? '.' : 'F');
}
process.stdout.write('\n');
await closeRules();

function lastOf(run: CaseRun, taskId: string) {
  return run.steps.filter((s) => s.taskId === taskId).at(-1);
}
function outcomeLabel(run: CaseRun, s: AssistantTaskSnapshot) {
  const pre =
    run.steps
      .filter(
        (x) =>
          x.taskId === s.task.id &&
          !x.label.includes('save') &&
          !x.label.includes('probe') &&
          !x.label.includes('edit'),
      )
      .at(-1)?.snapshot ?? s;
  return `${pre.task.state}${pre.task.errorCode ? `:${pre.task.errorCode}` : ''}/${pre.drafts.map((d) => `${d.payload.kind}:${d.state}`).join('+') || '-'}`;
}
function userTextOf(c: Case, turn: number): string | null {
  const t = c.turns[turn];
  return t && 'say' in t ? t.say : null;
}
function savedByProbe(run: CaseRun) {
  return run.confirms
    .filter((cf) => cf.turn === -1 && !cf.retried)
    .flatMap((cf) => cf.items)
    .filter((i) => i.status === 'saved').length;
}
function dedupe(vs: Violation[]) {
  const seen = new Set<string>();
  return vs.filter((x) => {
    const k = `${x.code}|${x.detail}`;
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });
}

async function probe(c: Case, run: CaseRun, out: Violation[]) {
  if (!run.lastTaskId) return;
  const lastTurn = c.turns.at(-1)!;
  if ('confirm' in lastTurn) return;
  const uid = run.lastUid;
  let snap: AssistantTaskSnapshot;
  try {
    snap = await snapshotOf(run.lastTaskId, uid, run.clock);
  } catch {
    return;
  }
  const pending = pendingOf(snap, 'all');
  if (pending.length === 0) return;
  let patched = false;
  for (const d of pending) {
    const flagged = [...new Set([...d.missingFields, ...d.uncertainFields])];
    const blocked = d.state === 'needs_review' || flagged.length > 0 || d.problems.length > 0;
    if (!blocked) continue;
    const map = controls.kinds[d.payload.kind];
    // Not fixable in the app (no control for a flagged field, no editor): a dead end, reported
    // by the invariants; the probe does what the app can do, nothing more.
    if (!map || !(flagged.every((f) => map.fields[f]) || map.editor)) continue;
    run.clock = new Date(run.clock.getTime() + 20_000);
    const r = await applyPatch(d, fixedPayload(d, {}, run.clock), flagged, run, 'vi');
    run.patches.push({ turn: -1, draftId: d.id, ...r });
    patched = true;
    if (!r.ok || r.state !== 'draft') {
      out.push({
        code: 'FIX_DOES_NOT_CLEAR',
        severity: 'P0',
        at: 'probe · after fix',
        detail: `${d.payload.kind}: the app's edit (fill + confirm [${flagged.join(',')}]) leaves it ${r.state ?? r.error}`,
      });
    }
  }
  if (patched) {
    const s = await snapshotOf(run.lastTaskId, uid, run.clock);
    run.steps.push({
      turn: -1,
      label: 'probe · after fix',
      uid,
      taskId: run.lastTaskId,
      snapshot: s,
      at: run.clock.toISOString(),
    });
    snap = s;
  }
  const ready = pendingOf(snap, 'all').filter((d) => d.state === 'draft');
  if (ready.length === 0) return;
  run.clock = new Date(run.clock.getTime() + 20_000);
  await confirmNow(run, -1, uid, run.lastTaskId, ready, [], true, 'vi');
  const s = await snapshotOf(run.lastTaskId, uid, run.clock);
  run.steps.push({
    turn: -1,
    label: 'probe · after save',
    uid,
    taskId: run.lastTaskId,
    snapshot: s,
    at: run.clock.toISOString(),
  });
}

// ---------- Fixtures for the app replay (assistant_replay_test.dart) ----------

function shift(x: unknown, by: number): unknown {
  if (typeof x === 'string' && isoRe.test(x)) return new Date(Date.parse(x) + by).toISOString();
  if (Array.isArray(x)) return x.map((y) => shift(y, by));
  if (x && typeof x === 'object') {
    return Object.fromEntries(
      Object.entries(x as Record<string, unknown>).map(([k, y]) => [k, shift(y, by)]),
    );
  }
  return x;
}
function exportCase(c: Case, run: CaseRun, kept: Violation[]) {
  const steps = run.steps
    .filter((s) => s.snapshot.task.scope.babyId === B)
    .map((s) => {
      const by = APP_NOW - Date.parse(s.snapshot.task.anchorInstant);
      const { events: _e, ...snap } = s.snapshot;
      void _e;
      return {
        label: s.label,
        as: WHO_OF[s.uid] ?? 'MOM',
        snapshot: shift({ ...snap, events: [] }, by),
      };
    });
  if (steps.length === 0) return;
  writeFileSync(
    resolve(FIXTURES, `${c.id}.json`),
    `${JSON.stringify({ id: c.id, group: c.group, device: c.device ?? null, serverViolations: [...new Set(kept.map((x) => x.code))], steps }, null, 1)}\n`,
  );
}

// ---------- Report ----------

const failedNew: string[] = [];
const fixedNow: string[] = [];
for (const r of results) {
  const known = baseline.cases[r.id];
  const codes = [...new Set(r.violations.map((x) => x.code))].sort();
  if (strict || !known) {
    if (!r.ok) failedNew.push(r.id);
    continue;
  }
  const extra = codes.filter((x) => !known.codes.includes(x));
  const gone = known.codes.filter((x) => !codes.includes(x));
  if (extra.length) failedNew.push(`${r.id} (+${extra.join(',')})`);
  if (gone.length) fixedNow.push(`${r.id} (${known.bug}: ${gone.join(',')} no longer seen)`);
}
const groups = new Map<string, Result[]>();
for (const r of results) {
  const g = r.group;
  groups.set(g, [...(groups.get(g) ?? []), r]);
}
const sev = (rs: Result[], s: string) =>
  rs.flatMap((r) => r.violations).filter((x) => x.severity === s).length;
const lines = [
  `# Lumi e2e — ${mode} — ${new Date().toISOString()}`,
  '',
  `Cases: ${results.length}, passing ${results.filter((r) => r.ok).length}, failing ${results.filter((r) => !r.ok).length}. Snapshots checked: ${results.reduce((a, r) => a + r.steps, 0)}.`,
  mode === 'live'
    ? `Model calls: ${meter.calls} (refused over budget: ${meter.refused}); tokens in ${meter.promptTokens}, out ${meter.completionTokens}; latency p50 ${pct(meter.latencies, 0.5)} ms, p95 ${pct(meter.latencies, 0.95)} ms.`
    : `Fake model calls: ${results.reduce((a, r) => a + r.calls, 0)}.`,
  '',
  '| Group | Cases | Pass | Fail | P0 | P1 | P2 |',
  '|---|---|---|---|---|---|---|',
  ...[...groups.entries()].map(
    ([g, rs]) =>
      `| ${g} | ${rs.length} | ${rs.filter((r) => r.ok).length} | ${rs.filter((r) => !r.ok).length} | ${sev(rs, 'P0')} | ${sev(rs, 'P1')} | ${sev(rs, 'P2')} |`,
  ),
  '',
  '## Failures',
  '',
  ...results
    .filter((r) => !r.ok)
    .flatMap((r) => [
      `### ${r.id}${r.device ? ` (device ${r.device})` : ''} — ${r.outcome ?? '-'}`,
      ...r.violations.map((x) => `- **${x.severity} ${x.code}** @ ${x.at}: ${x.detail}`),
      '',
    ]),
  '## Baseline',
  '',
  `New / unexpected failures: ${failedNew.length ? failedNew.join('; ') : 'none'}`,
  `Known failures no longer seen (update known-failures.json): ${fixedNow.length ? fixedNow.join('; ') : 'none'}`,
];
writeFileSync(resolve(outDir, 'summary.md'), `${lines.join('\n')}\n`);
writeFileSync(
  resolve(outDir, 'results.json'),
  `${JSON.stringify({ mode, at: new Date().toISOString(), meter: mode === 'live' ? { ...meter, latencies: undefined, raw: undefined } : null, results }, null, 1)}\n`,
);
if (meter.raw)
  writeFileSync(resolve(outDir, 'raw.json'), `${JSON.stringify(meter.raw, null, 1)}\n`);
console.log(lines.slice(0, 6 + groups.size + 2).join('\n'));
console.log(
  `\nNew / unexpected failures: ${failedNew.length}${failedNew.length ? ` → ${failedNew.join('; ')}` : ''}`,
);
console.log(
  `Known failures no longer seen: ${fixedNow.length}${fixedNow.length ? ` → ${fixedNow.join('; ')}` : ''}`,
);
console.log(`Results: ${outDir}`);
void db;
process.exit(failedNew.length > 0 ? 1 : 0);

function pct(xs: number[], p: number) {
  if (xs.length === 0) return 0;
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor(p * s.length))]!;
}
