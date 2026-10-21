/* global fetch */
// Downloads the sample photos listed in licence.json into <dir> (with a copy of licence.json).
//   node design/sample-photos/fetch.mjs <dir>
import { Buffer } from 'node:buffer';
import { setDefaultResultOrder } from 'node:dns';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = process.argv[2];
if (!dir) throw new Error('usage: fetch.mjs <dir>');
const here = dirname(fileURLToPath(import.meta.url));
setDefaultResultOrder('ipv4first');
const list = JSON.parse(
  await readFile(
    join(
      here,
      process.argv.includes('--phase6') ? 'premium48-phase6-licence.json' : process.argv.includes('--phase5')
        ? 'premium48-phase5-licence.json'
        : process.argv.includes('--phase4')
          ? 'premium48-phase4-licence.json'
          : process.argv.includes('--phase3')
            ? 'premium48-phase3-licence.json'
            : process.argv.includes('--phase2')
              ? 'premium48-phase2-licence.json'
              : 'licence.json',
    ),
    'utf8',
  ),
);
await mkdir(dir, { recursive: true });
for (const p of list) {
  const res = await fetch(p.download, { headers: { 'User-Agent': 'child-life-previews' } });
  if (!res.ok) throw new Error(`${p.file}: HTTP ${res.status}`);
  await writeFile(join(dir, p.file), Buffer.from(await res.arrayBuffer()));
}
await writeFile(join(dir, 'licence.json'), JSON.stringify(list, null, 2));
console.log(`${list.length} photos → ${dir}`);
