// Product Hub · "Sản phẩm" knowledge sync (D-155, docs/product-hub/06-knowledge-ingestion.md).
//
// Reads the repository at a revision (default HEAD) — the Markdown under docs/, the business map,
// the feature registry (docs/product-hub/registry/features.json) and the code the registry points
// at — compares it with what the project has applied, and prints the change set. Nothing changes
// until --submit, and even then only a PENDING change set is stored: someone with "Duyệt" on
// Sản phẩm approves it in the portal (not the submitter, except the Owner — D-155 #3).
//
//   pnpm --filter @child-life/contracts run build
//   cd firebase/functions
//   gcloud auth application-default login      # once
//   pnpm exec tsx scripts/product-hub-sync.ts --project child-life-dev              # dry run
//   pnpm exec tsx scripts/product-hub-sync.ts --project child-life-dev --as you@childlife.app --submit
//
// Flags: --rev <git rev> (default HEAD) · --worktree (read files on disk, dry run only) ·
// --offline (no Firestore; diff against an empty state) · --replace-pending · --out <file.json> ·
// --rebuild-index (only rebuild the Copilot's search index from what is approved; no diff).
// Prod (child-life-ecosystem) needs CHILD_LIFE_PROD_APPROVED=yes, as scripts/deploy.sh.

import { execFileSync, spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { productRegistrySchema } from '@child-life/contracts';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { rebuildSearchArtifact } from '../src/product-copilot.js';
import { appliedState, submitChangeSet } from '../src/product-hub.js';
import {
  buildChangeSet,
  defaultSyncConfig,
  emptyState,
  globToRegExp,
  selectFiles,
  sha256,
  type RepoFile,
} from '../src/product-hub-ingest.js';
import { resolveStaff } from '../src/staff-access.js';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const registryPath = 'docs/product-hub/registry/features.json';
const argv = process.argv.slice(2);
const arg = (name: string) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 ? argv[i + 1] : undefined;
};
const flag = (name: string) => argv.includes(`--${name}`);
function fail(message: string): never {
  console.error(message);
  process.exit(1);
}

const git = (...args: string[]) =>
  execFileSync('git', args, { cwd: repo, encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 });

/** Blob contents for many SHAs in one `git cat-file --batch` call. */
function catFiles(shas: string[]): Map<string, string> {
  const out = new Map<string, string>();
  if (!shas.length) return out;
  const r = spawnSync('git', ['cat-file', '--batch'], {
    cwd: repo,
    input: shas.join('\n') + '\n',
    maxBuffer: 1024 * 1024 * 1024,
  });
  const buf = r.stdout;
  let pos = 0;
  while (pos < buf.length) {
    const nl = buf.indexOf(10, pos);
    const [sha, , size] = buf.subarray(pos, nl).toString().split(' ');
    const len = Number(size);
    out.set(sha!, buf.subarray(nl + 1, nl + 1 + len).toString('utf8'));
    pos = nl + 1 + len + 1;
  }
  return out;
}

/** The files the snapshot needs text for: selected Markdown, registry code, the functions index. */
function textPaths(all: string[], registryText: string): Set<string> {
  const reg = productRegistrySchema.parse(JSON.parse(registryText));
  const want = new Set(selectFiles(all, defaultSyncConfig));
  want.add('firebase/functions/src/index.ts');
  want.add('docs/product/business-map.md');
  const globs = reg.features.flatMap((f) => [...f.modules, ...f.functions]).map(globToRegExp);
  for (const p of all) {
    if (/\.(dart|ts|tsx|swift|kt)$/.test(p) && globs.some((g) => g.test(p))) want.add(p);
  }
  return want;
}

function readRevision(rev: string) {
  const commit = git('rev-parse', rev).trim();
  const tree = git('ls-tree', '-r', commit)
    .split('\n')
    .filter(Boolean)
    .map((l) => {
      const [meta, path] = l.split('\t') as [string, string];
      const [, type, sha] = meta.split(' ');
      return { path, sha: sha!, type: type! };
    })
    .filter((x) => x.type === 'blob' && !x.path.startsWith('.claude/'));
  const registryEntry = tree.find((x) => x.path === registryPath);
  if (!registryEntry) fail(`${registryPath} is not in ${rev}; commit it or use --worktree.`);
  const registryText = catFiles([registryEntry.sha]).get(registryEntry.sha)!;
  const want = textPaths(
    tree.map((x) => x.path),
    registryText,
  );
  const texts = catFiles(tree.filter((x) => want.has(x.path)).map((x) => x.sha));
  const files: RepoFile[] = tree.map((x) => ({
    path: x.path,
    blobSha: x.sha,
    text: want.has(x.path) ? texts.get(x.sha) : undefined,
  }));
  return { revision: commit, files, registryText, dirty: false };
}

function readWorktree() {
  const commit = git('rev-parse', 'HEAD').trim();
  const paths = git('ls-files', '--cached', '--others', '--exclude-standard')
    .split('\n')
    .filter((p) => p && !p.startsWith('.claude/'));
  const registryText = readFileSync(resolve(repo, registryPath), 'utf8');
  const want = textPaths(paths, registryText);
  const files: RepoFile[] = [];
  for (const path of paths) {
    let text: string | undefined;
    try {
      text = want.has(path) ? readFileSync(resolve(repo, path), 'utf8') : undefined;
    } catch {
      continue; // listed but deleted on disk
    }
    // A content hash stands in for the blob SHA; move detection still works within the tree.
    files.push({ path, blobSha: text !== undefined ? sha256(text).slice(0, 40) : `wt:${path}`, text });
  }
  const dirty = git('status', '--porcelain').trim().length > 0;
  return { revision: `${commit}+worktree`, files, registryText, dirty };
}

async function main() {
  const project = arg('project') ?? 'child-life-dev';
  if (flag('rebuild-index')) {
    initializeApp({ projectId: project, storageBucket: `${project}.firebasestorage.app` });
    const file = getStorage().bucket().file('productHub/index/current.json.gz');
    const { docs } = await rebuildSearchArtifact(
      getFirestore(),
      {
        save: (bytes) => file.save(bytes, { contentType: 'application/gzip', resumable: false }),
        read: async () => ((await file.exists())[0] ? (await file.download())[0] : null),
      },
      new Date(),
    );
    console.log(`Search index rebuilt on ${project}: ${docs} documents.`);
    return;
  }
  const submit = flag('submit');
  const worktree = flag('worktree');
  if (submit && worktree) fail('--worktree is for dry runs; commit and sync a revision to submit.');
  if (submit && !arg('as')) fail('--submit needs --as <staff email>.');
  if (submit && project === 'child-life-ecosystem' && process.env.CHILD_LIFE_PROD_APPROVED !== 'yes') {
    fail('Submitting to prod needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run.');
  }

  const snap = worktree ? readWorktree() : readRevision(arg('rev') ?? 'HEAD');
  const registry = productRegistrySchema.parse(JSON.parse(snap.registryText));
  const now = new Date();

  let state = emptyState;
  let db: ReturnType<typeof getFirestore> | null = null;
  if (!flag('offline')) {
    initializeApp({ projectId: project });
    db = getFirestore();
    state = await appliedState(db);
  }
  const draft = buildChangeSet({ revision: snap.revision, files: snap.files, registry, now }, state);
  const s = draft.summary;
  const mode = submit ? 'SUBMIT' : 'DRY RUN';
  console.log(`${mode}: ${snap.revision} → ${flag('offline') ? 'empty state (offline)' : project}`);
  console.log(
    `  ${s.added} added · ${s.changed} changed · ${s.moved} moved · ${s.deleted} deleted · ${s.unchanged} unchanged`,
  );
  const byType = (t: string) => draft.items.filter((i) => i.type === t);
  console.log(
    `  sources ${byType('source').length} · decisions ${byType('decision').length} · features ${byType('feature').length} · conflicts ${byType('conflict').length}`,
  );
  for (const i of draft.items.slice(0, 40)) {
    if (i.type === 'source') console.log(`  ${i.change.padEnd(8)} ${i.source.path} (${i.chunks.length} chunks)`);
  }
  for (const i of byType('conflict')) {
    if (i.type === 'conflict') console.log(`  conflict ${i.conflict.topic}: ${i.conflict.summary}`);
  }
  if (s.warnings.length) {
    console.log(`  ${s.warnings.length} warnings:`);
    s.warnings.slice(0, 40).forEach((w) => console.log(`    - ${w}`));
  }
  if (arg('out')) writeFileSync(arg('out')!, JSON.stringify(draft, null, 2));

  if (!submit) {
    console.log('Nothing stored (dry run). Add --as <email> --submit to queue it for review.');
    return;
  }
  const user = await getAuth()
    .getUserByEmail(arg('as')!)
    .catch(() => fail(`No account ${arg('as')} in ${project}`));
  const staff = await resolveStaff(db!, { uid: user.uid, token: user.customClaims ?? {} }, now);
  if (!staff) fail(`${arg('as')} is not active staff in ${project}`);
  const { id } = await submitChangeSet(db!, staff, { ...draft, dirty: snap.dirty }, now, {
    replacePending: flag('replace-pending'),
  });
  console.log(`Queued change set ${id}: review it in Sản phẩm › Nguồn tri thức › Chờ duyệt.`);
}

main().catch((e) => fail(String((e as Error).stack ?? e)));
