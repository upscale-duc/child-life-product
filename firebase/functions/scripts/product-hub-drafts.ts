// Product Hub · section drafts from a file (D-155). Saves AI-written feature sections as DRAFTS
// (origin "ai"); someone with Sản phẩm › Duyệt approves them in the portal. Every source is
// checked first: a repository path must exist, a "#anchor" must be one of the file's headings, a
// "path:line" must be within the file, and a D/R/P/Q/G id must be in the business map.
//
//   cd firebase/functions
//   pnpm exec tsx scripts/product-hub-drafts.ts --file ../../docs/product-hub/drafts/pilot-2026-10-31.json
//   GOOGLE_CLOUD_QUOTA_PROJECT=child-life-dev pnpm exec tsx scripts/product-hub-drafts.ts \
//     --file … --project child-life-dev --as you@childlife.app --submit
//
// Dry run by default (checks only). An existing draft is replaced; an approved section is never
// touched (the draft waits beside it). Prod needs CHILD_LIFE_PROD_APPROVED=yes.
// --approve --sign "Child Life Team" then approves the saved drafts as the --as staff member (the
// Owner may approve their own, D-155 #3), shown with that signature (D-158); only on the owner's
// explicit instruction.

import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { featureSectionKeys, productFeatureIdSchema, sectionBodySchema } from '@child-life/contracts';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { z } from 'zod';
import { actSection, saveSection } from '../src/product-hub.js';
import { anchorOf, chunkMarkdown, parseBusinessMap } from '../src/product-hub-ingest.js';
import { resolveStaff } from '../src/staff-access.js';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const argv = process.argv.slice(2);
const arg = (n: string) => {
  const i = argv.indexOf(`--${n}`);
  return i >= 0 ? argv[i + 1] : undefined;
};
const flag = (n: string) => argv.includes(`--${n}`);
function fail(m: string): never {
  console.error(m);
  process.exit(1);
}

const fileSchema = z.object({
  version: z.literal(1),
  revision: z.string(),
  author: z.string(),
  features: z.record(
    productFeatureIdSchema,
    z.partialRecord(
      z.enum(featureSectionKeys),
      z.object({ body: sectionBodySchema, sources: z.array(z.string().min(3).max(300)).max(30) }),
    ),
  ),
});

/** Problems with one source string, or [] when it checks out. */
export function sourceProblems(src: string, ids: Set<string>): string[] {
  if (/^[DRPQG]-\d{3}$/.test(src)) return ids.has(src) ? [] : [`${src}: not in the business map`];
  const m = src.match(/^([^#:]+)(?:#(.+)|:(\d+))?$/);
  if (!m) return [`${src}: not a path, path#anchor, path:line or id`];
  const [, path, anchor, line] = m as unknown as [string, string, string?, string?];
  const abs = resolve(repo, path);
  if (!existsSync(abs)) return [`${src}: no such file`];
  const text = readFileSync(abs, 'utf8');
  if (line && Number(line) > text.split('\n').length) return [`${src}: past the end of the file`];
  if (anchor) {
    const anchors = new Set(chunkMarkdown(text).map((c) => c.anchor));
    for (const h of text.matchAll(/^#{1,6}\s+(.+?)\s*#*\s*$/gm)) anchors.add(anchorOf(h[1]!.replace(/[*_`]/g, '')));
    if (!anchors.has(anchor)) return [`${src}: no heading with anchor "${anchor}"`];
  }
  return [];
}

async function main() {
  const file = arg('file') ?? fail('--file <drafts.json> is required');
  const drafts = fileSchema.parse(JSON.parse(readFileSync(resolve(process.cwd(), file), 'utf8')));
  const map = readFileSync(resolve(repo, 'docs/product/business-map.md'), 'utf8');
  const ids = new Set(parseBusinessMap(map, 'docs/product/business-map.md', 'HEAD').records.map((r) => r.id));

  let problems = 0;
  let count = 0;
  for (const [feature, sections] of Object.entries(drafts.features)) {
    for (const [key, s] of Object.entries(sections)) {
      count++;
      for (const p of s!.sources.flatMap((src) => sourceProblems(src, ids))) {
        problems++;
        console.log(`  ${feature}/${key}: ${p}`);
      }
      if (!s!.body.en) console.log(`  ${feature}/${key}: no English (shown as "EN chưa có")`);
    }
  }
  console.log(`${count} sections in ${Object.keys(drafts.features).length} features · ${problems} source problems`);
  if (problems) fail('Fix the sources before saving.');
  if (!flag('submit')) {
    console.log('Nothing stored (dry run). Add --project <id> --as <email> --submit to save the drafts.');
    return;
  }
  const project = arg('project') ?? fail('--project is required with --submit');
  if (project === 'child-life-ecosystem' && process.env.CHILD_LIFE_PROD_APPROVED !== 'yes') {
    fail('Saving to prod needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run.');
  }
  initializeApp({ projectId: project });
  const db = getFirestore();
  const now = new Date();
  const user = await getAuth()
    .getUserByEmail(arg('as') ?? fail('--as <staff email> is required'))
    .catch(() => fail(`No account ${arg('as')} in ${project}`));
  const staff = await resolveStaff(db, { uid: user.uid, token: user.customClaims ?? {} }, now);
  if (!staff) fail(`${arg('as')} is not active staff in ${project}`);
  for (const [feature, sections] of Object.entries(drafts.features)) {
    for (const [key, s] of Object.entries(sections)) {
      await saveSection(db, staff, { feature, key, body: s!.body, sources: s!.sources }, now, 'ai');
    }
    console.log(`  ${feature}: ${Object.keys(sections).length} drafts saved`);
  }
  if (flag('approve')) {
    const signAs = arg('sign');
    for (const [feature, sections] of Object.entries(drafts.features)) {
      for (const key of Object.keys(sections)) {
        await actSection(db, staff, { feature, key, action: 'approve' }, now, signAs ? { signAs } : {});
      }
      console.log(`  ${feature}: ${Object.keys(sections).length} approved${signAs ? ` as "${signAs}"` : ''}`);
    }
  }
  console.log('Saved as AI drafts: approve them in Sản phẩm › Tính năng › (feature).');
}

main().catch((e) => fail(String((e as Error).stack ?? e)));
