// Product Hub · draft feature descriptions with Claude (D-155, D-158). For each feature without
// approved sections (or the --features list), Claude writes the eight description sections from
// the feature's own sources only; the output is a drafts file for scripts/product-hub-drafts.ts,
// which checks every source and saves the sections as AI drafts. Nothing is saved here.
//
//   cd firebase/functions
//   ANTHROPIC_API_KEY=… GOOGLE_CLOUD_QUOTA_PROJECT=child-life-dev pnpm exec tsx \
//     scripts/product-hub-author.ts --project child-life-dev --out ../../docs/product-hub/drafts/<file>.json \
//     [--features care.sleep,care.diaper]
//
// Uses the Claude model of the Copilot (one call per feature, ≈ $0.10–0.15 each).

import { writeFileSync } from 'node:fs';
import { COPILOT_MODEL } from '@child-life/contracts';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { recordAiCall } from '../src/ai-telemetry.js';
import { claudeCopilotModel } from '../src/product-copilot-claude.js';
import { loadIndex, loadLive } from '../src/product-copilot.js';
import { authorFeature } from '../src/product-hub-author.js';

const argv = process.argv.slice(2);
const arg = (n: string) => {
  const i = argv.indexOf(`--${n}`);
  return i >= 0 ? argv[i + 1] : undefined;
};
function fail(m: string): never {
  console.error(m);
  process.exit(1);
}

const project = arg('project') ?? 'child-life-dev';
const outPath = arg('out') ?? fail('--out <drafts.json> is required');
const key = process.env.ANTHROPIC_API_KEY ?? fail('ANTHROPIC_API_KEY is not set');
initializeApp({ projectId: project, storageBucket: `${project}.firebasestorage.app` });
const db = getFirestore();
const file = getStorage().bucket().file('productHub/index/current.json.gz');
const store = {
  save: async () => undefined,
  read: async () => ((await file.exists())[0] ? (await file.download())[0] : null),
};
const model = claudeCopilotModel(key, COPILOT_MODEL, (u) => recordAiCall(db, u));
const [index, live] = await Promise.all([loadIndex(db, store), loadLive(db)]);
const approved = new Set([...live.sections.entries()].filter(([, s]) => s.some((x) => x.approved)).map(([f]) => f));
const wanted = arg('features')?.split(',').map((x) => x.trim()) ?? live.features.map((f) => f.id).filter((id) => !approved.has(id)).sort();

const features: Record<string, unknown> = {};
let done = 0;
const queue = [...wanted];
async function worker() {
  for (let id = queue.shift(); id; id = queue.shift()) {
    const t = Date.now();
    try {
      const r = await authorFeature(index, live, id, model);
      if (r) features[id] = r.sections;
      console.log(`  ${id}: ${r ? Object.keys(r.sections).length : 0} sections from ${r?.blocks ?? 0} blocks (${((Date.now() - t) / 1000).toFixed(0)}s) [${++done}/${wanted.length}]`);
    } catch (e) {
      console.log(`  ${id}: failed ${String(e).slice(0, 160)} [${++done}/${wanted.length}]`);
    }
  }
}
await Promise.all([worker(), worker(), worker()]);
const ordered = Object.fromEntries(Object.keys(features).sort().map((k) => [k, features[k]]));
writeFileSync(outPath, `${JSON.stringify({ version: 1, revision: 'dev-index', author: 'Claude (AI draft, needs approval)', features: ordered }, null, 2)}\n`);
console.log(`Wrote ${Object.keys(ordered).length} features to ${outPath}. Check and save with scripts/product-hub-drafts.ts.`);
