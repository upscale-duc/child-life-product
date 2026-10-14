// Builds the renderer image contents into build/: the server bundled with esbuild (workspace
// packages such as @child-life/contracts inlined), and the Remotion compositions bundled for the
// browser (build/bundle, with public/ fonts). The Dockerfile installs only the runtime packages.
import { bundle } from '@remotion/bundler';
import { build } from 'esbuild';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { syncArt } from './sync-art.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'build');
await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });

const runtime = [
  '@remotion/renderer',
  '@remotion/bundler',
  'remotion',
  'firebase-admin',
  'react',
  'react-dom',
];
await build({
  entryPoints: [join(root, 'src/server.ts')],
  outfile: join(out, 'server.js'),
  bundle: true,
  platform: 'node',
  target: 'node22',
  format: 'esm',
  jsx: 'automatic',
  external: runtime.flatMap((n) => [n, `${n}/*`]),
  banner: {
    js: "import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);",
  },
  logLevel: 'warning',
});

await syncArt();
await bundle({
  entryPoint: join(root, 'src/remotion-entry.ts'),
  publicDir: join(root, 'public'),
  outDir: join(out, 'bundle'),
});

const pkg = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'));
await writeFile(
  join(out, 'package.json'),
  `${JSON.stringify(
    {
      name: 'child-life-renderer-image',
      private: true,
      type: 'module',
      main: 'server.js',
      engines: { node: '22' },
      dependencies: Object.fromEntries(runtime.map((n) => [n, pkg.dependencies[n]])),
    },
    null,
    2,
  )}\n`,
);
console.log(`renderer build written to ${out}`);
