// Copies the original art library (design/keepsake-art/*.svg) into public/art, where the
// compositions load it with staticFile('art/…'). Run by the build, sample and preview scripts.
import { cp, mkdir, readdir, rm } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const from = join(root, '../../design/keepsake-art');
const to = join(root, 'public/art');

export async function syncArt() {
  await rm(to, { recursive: true, force: true });
  await mkdir(to, { recursive: true });
  for (const f of await readdir(from)) if (f.endsWith('.svg')) await cp(join(from, f), join(to, f));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) await syncArt();
