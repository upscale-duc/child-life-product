/**
 * Writes `design/keepsake-templates/chapter1.json`: the Chapter 01 templates with the art
 * library's asset names, checked against the shared schema (the portal imports this file; dev
 * publishes it with `seed-keepsakes.ts --chapter1`). With `--art <dir>` it also writes each art
 * asset's WebP there (for local renders and tests).
 *   pnpm --filter child-life-scripts exec tsx src/keepsake-chapter1-build.ts [--art <dir>]
 */
import {
  keepsakeCatalogSchema,
  keepsakeChapter1Videos,
  keepsakeSeedV1,
} from '@child-life/contracts';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { artDir, buildArt } from './keepsake-art.js';
import { chapter1Cards } from './keepsakes-chapter1.js';

const art = JSON.parse(readFileSync(join(artDir, 'assets.json'), 'utf8')) as Record<string, string>;
const templates = [...chapter1Cards(art), ...keepsakeChapter1Videos];
// Checked as part of a whole catalog (ids unique, schema refinements).
const parsed = keepsakeCatalogSchema.safeParse({
  ...keepsakeSeedV1,
  templates: [...keepsakeSeedV1.templates, ...templates],
});
if (!parsed.success) {
  for (const i of parsed.error.issues.slice(0, 20)) console.error(i.path.join('.'), i.message);
  process.exit(1);
}
const out = join(artDir, '../keepsake-templates/chapter1.json');
writeFileSync(out, `${JSON.stringify({ templates }, null, 2)}\n`);
console.log(`${templates.length} templates → design/keepsake-templates/chapter1.json`);

const at = process.argv.indexOf('--art');
if (at >= 0) {
  const dir = process.argv[at + 1]!;
  mkdirSync(dir, { recursive: true });
  for (const a of await buildArt()) writeFileSync(join(dir, a.asset), a.bytes);
  console.log(`art → ${dir}`);
}
