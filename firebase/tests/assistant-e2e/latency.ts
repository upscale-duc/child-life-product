/**
 * Lumi L2 (D-088 §4.4) — time to card, before and after, on the Firestore emulator with the real
 * callables and worker. Synthetic household and phrases only; nothing leaves the machine.
 *
 *   pnpm --filter @child-life/contracts run build
 *   firebase emulators:exec --only firestore --project demo-child-life-e2e \
 *     --config firebase/tests/assistant-e2e/firebase.e2e.json \
 *     "pnpm --dir firebase/tests exec tsx assistant-e2e/latency.ts --model-ms 2400 --rtt-ms 220"
 *
 * "before" = today's app: quoteTask → startTask (quote) → the trigger's worker (model) →
 * getAssistantTask. "after" = L2: startTask without a quote, rules before the model, the worker
 * inside startTask, the snapshot in the answer. The model is a fake that answers what a correct
 * model answers after [--model-ms]; [--rtt-ms] is one callable round trip on the network (measured
 * on dev: warm ≈ 220 ms from Vietnam) and [--trigger-ms] the Firestore trigger's dispatch.
 */
import { randomUUID } from 'node:crypto';
import { fakeModelGateway, type ModelGateway } from '../../functions/src/assistant-model.js';
import { ruleReadText } from '../../functions/src/assistant-rules.js';
import { runAssistantTask } from '../../functions/src/assistant-worker.js';
import { getAssistantTask, quoteTask, startTask } from '../../functions/src/assistant.js';
import { memoryAttachmentStore } from '../../functions/src/assistant-attachments.js';
import { B, E, db, deps, initDb, localAt, seedWorld, SHARED, UID, ZONE } from './harness.js';
import type { Case } from './types.js';

const args = process.argv.slice(2);
const num = (name: string, d: number) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? Number(args[i + 1]) : d;
};
const modelMs = num('model-ms', 2400);
const rttMs = num('rtt-ms', 220);
const triggerMs = num('trigger-ms', 600);
const rounds = num('rounds', 3);

/** The plan's routine logs (rules) and logs only the model reads. */
const routine = [
  'bé bú 120ml lúc 8h',
  'thay tã ướt',
  'bé ngủ lúc 9h',
  'hút 100ml',
  'bé nặng 5,2kg',
  'bú mẹ 15 phút bên trái lúc 13h',
  'bé ngủ từ 13h đến 14h',
  'con đang ngủ',
];
const modelOnly = ['8h bú 120ml, 11h bú 150ml', 'thay tã rồi cho bú 90ml lúc 13h'];

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** A fake model: after [modelMs], what a correct model returns (the rules' reading, or none). */
function slowModel(text: string, anchor: Date): ModelGateway {
  const reading = ruleReadText({ text, zone: ZONE, anchor }) ?? {
    intents: [],
    reads: [],
    clarification: null,
    care: null,
    smallTalk: false,
    outOfScope: false,
  };
  return fakeModelGateway({
    extract: [
      async () => {
        await sleep(modelMs);
        return reading;
      },
    ],
  });
}

const pct = (xs: number[], p: number) => {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))] ?? 0;
};

async function before(text: string, now: Date) {
  const gw = slowModel(text, now);
  const uid = UID.MOM;
  const scope = { type: 'child' as const, babyId: B };
  const t0 = performance.now();
  const q = await quoteTask(
    deps(gw, now),
    uid,
    E('vi', {
      conversationId: SHARED,
      scope,
      modality: 'text',
      attachmentCount: 0,
      intentHint: null,
    }),
  );
  const t1 = performance.now();
  const r = await startTask(
    { ...deps(gw, now), inline: false, ruleReads: false },
    uid,
    E('vi', {
      clientRequestId: randomUUID(),
      conversationId: SHARED,
      scope,
      quoteId: q.data.quoteId,
      text,
      attachmentIds: [],
    }),
  );
  const t2 = performance.now();
  await runAssistantTask({ db, now, environment: 'test', gateway: gw }, r.taskId!);
  const t3 = performance.now();
  await getAssistantTask(deps(null, now), uid, E('vi', { taskId: r.taskId, afterSequence: null }));
  const t4 = performance.now();
  const server = t4 - t0;
  return {
    server,
    hops: { quote: t1 - t0, start: t2 - t1, worker: t3 - t2, get: t4 - t3 },
    card: server + 3 * rttMs + triggerMs,
  };
}

async function after(text: string, now: Date) {
  const gw = slowModel(text, now);
  const t0 = performance.now();
  const r = await startTask(
    deps(gw, now),
    UID.MOM,
    E('vi', {
      clientRequestId: randomUUID(),
      conversationId: SHARED,
      scope: { type: 'child' as const, babyId: B },
      text,
      attachmentIds: [],
    }),
  );
  const server = performance.now() - t0;
  const state = (r.data as { task: { state: string } }).task.state;
  return { server, card: server + rttMs, state };
}

initDb('demo-child-life-e2e');
const files = memoryAttachmentStore();
const world = { id: 'latency', turns: [], expect: {} } as unknown as Case;
const out: Record<string, { before: number[]; after: number[]; path: string }> = {};
for (let round = 0; round < rounds; round++) {
  for (const text of [...routine, ...modelOnly]) {
    await seedWorld(world, files);
    const now = localAt('14:20');
    const b = await before(text, now);
    await seedWorld(world, files);
    const a = await after(text, now);
    const key = routine.includes(text)
      ? `rules · ${routine.indexOf(text) + 1}`
      : `model · ${modelOnly.indexOf(text) + 1}`;
    out[key] ??= { before: [], after: [], path: a.state };
    out[key].before.push(b.card);
    out[key].after.push(a.card);
  }
}
const rows = Object.entries(out).map(([k, v]) => ({
  phrase: k,
  beforeP50: Math.round(pct(v.before, 50)),
  afterP50: Math.round(pct(v.after, 50)),
  state: v.path,
}));
const all = (k: 'before' | 'after', path: string) =>
  Object.entries(out)
    .filter(([key]) => key.startsWith(path))
    .flatMap(([, v]) => v[k]);
console.log(JSON.stringify({ modelMs, rttMs, triggerMs, rounds, rows }, null, 1));
for (const path of ['rules', 'model']) {
  const b = all('before', path);
  const a = all('after', path);
  console.log(
    `${path}: before p50 ${Math.round(pct(b, 50))} ms p95 ${Math.round(pct(b, 95))} ms · after p50 ${Math.round(pct(a, 50))} ms p95 ${Math.round(pct(a, 95))} ms`,
  );
}
process.exit(0);
