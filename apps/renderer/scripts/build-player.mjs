// Builds the preview page (player/) into dist-player/ for Firebase Hosting (target "player"):
// the renderer's compositions bundled with @remotion/player, the fonts, and sample pictures
// (illustrations, never a child's photo) for template demos.
import { build } from 'esbuild';
import { cp, mkdir, rm } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { syncArt } from './sync-art.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'dist-player');
await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });
await build({
  entryPoints: [join(root, 'player/player.tsx')],
  outfile: join(out, 'app.js'),
  bundle: true,
  minify: true,
  format: 'esm',
  platform: 'browser',
  target: ['es2020', 'safari15'],
  jsx: 'automatic',
  define: { 'process.env.NODE_ENV': '"production"' },
  logLevel: 'warning',
});
await cp(join(root, 'player/index.html'), join(out, 'index.html'));
await cp(join(root, 'public/fonts'), join(out, 'fonts'), { recursive: true });
await cp(join(root, 'player/samples'), join(out, 'samples'), { recursive: true });
await syncArt();
await cp(join(root, 'public/art'), join(out, 'art'), { recursive: true });
console.log(`preview page written to ${out}`);
