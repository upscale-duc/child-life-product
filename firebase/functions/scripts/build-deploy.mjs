// Bundles the Functions source (including workspace packages such as @child-life/contracts)
// into functions/deploy, with a package.json that lists only runtime dependencies that
// Cloud Build can install from npm. Workspace protocol dependencies never reach Cloud Build.
import { build } from 'esbuild';
import { execFileSync } from 'node:child_process';
import { mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'deploy');
const pkg = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'));
// sharp ships native binaries per platform: Cloud Build installs the Linux build (S9 photos).
const external = ['firebase-functions', 'firebase-admin', 'sharp'];

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
  // Bundled CommonJS dependencies (e.g. the AWS SDK) call require() for Node built-ins.
  banner: {
    js: "import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);",
  },
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
// Non-secret Functions params (D-054). Credentials are Secret Manager secrets, never here.
await writeFile(
  join(out, '.env'),
  // MAIL_FROM / MAIL_REPLY_TO: Resend sends as hello@childlife.app; replies reach the GoDaddy mailbox.
  // SUPPORT_INBOX: where storage requests and help tickets are announced to staff (S11).
  // OPENAI_MODEL: the story model behind the adapter (D-003, S12); the key is a secret.
  'MAIL_FROM=Child Life <hello@childlife.app>\nMAIL_REPLY_TO=hello@childlife.app\nSUPPORT_INBOX=support@childlife.app\nOPENAI_MODEL=gpt-4.1-mini\n',
);
// Per-project params written by other deploy steps (e.g. KEEPSAKE_RENDERER_URL from
// scripts/deploy-renderer.sh, D-068): `.env.<projectId>` beside package.json, never committed.
for (const name of await readdir(root)) {
  if (/^\.env\.child-life-(dev|prod)$/.test(name)) {
    await writeFile(join(out, name), await readFile(join(root, name)));
  }
}
// The Firebase CLI loads firebase-functions from the source dir to discover triggers, and Cloud Build
// installs from the generated lockfile, so both see exactly the pinned runtime versions.
execFileSync('npm', ['install', '--omit=dev', '--no-audit', '--no-fund', '--loglevel=error'], {
  cwd: out,
  stdio: 'inherit',
});
console.log(`Functions bundle written to ${out}`);
