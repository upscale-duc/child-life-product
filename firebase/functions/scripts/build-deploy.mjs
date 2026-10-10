// Bundles the Functions source (including workspace packages such as @child-life/contracts)
// into functions/deploy, with a package.json that lists only runtime dependencies that
// Cloud Build can install from npm. Workspace protocol dependencies never reach Cloud Build.
import { build } from 'esbuild';
import { execFileSync } from 'node:child_process';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'deploy');
const pkg = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'));
const external = ['firebase-functions', 'firebase-admin'];

await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });

await build({
  entryPoints: [join(root, 'src/index.ts')],
  outfile: join(out, 'index.js'),
  bundle: true,
  platform: 'node',
  target: 'node22',
  format: 'esm',
  sourcemap: true,
  external: external.flatMap((name) => [name, `${name}/*`]),
  logLevel: 'warning',
});

const deployPkg = {
  name: 'child-life-functions-deploy',
  private: true,
  type: 'module',
  main: 'index.js',
  engines: { node: '22' },
  dependencies: Object.fromEntries(external.map((name) => [name, pkg.dependencies[name]])),
};
await writeFile(join(out, 'package.json'), `${JSON.stringify(deployPkg, null, 2)}\n`);
// The Firebase CLI loads firebase-functions from the source dir to discover triggers, and Cloud Build
// installs from the generated lockfile, so both see exactly the pinned runtime versions.
execFileSync('npm', ['install', '--omit=dev', '--no-audit', '--no-fund', '--loglevel=error'], {
  cwd: out,
  stdio: 'inherit',
});
console.log(`Functions bundle written to ${out}`);
