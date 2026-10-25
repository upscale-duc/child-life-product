import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
const root = fileURLToPath(new URL('../', import.meta.url));
const cliRequire = createRequire(require.resolve('@remotion/cli/package.json'));
const rendererRequire = createRequire(cliRequire.resolve('@remotion/renderer/package.json'));
const compositor = dirname(rendererRequire.resolve('@remotion/compositor-darwin-arm64'));
const result = spawnSync(
  join(compositor, 'ffmpeg'),
  [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-i',
    join(root, 'design/music/dream-culture-original.mp3'),
    '-af',
    'atempo=1.0857142857,loudnorm=I=-20:TP=-2:LRA=9',
    '-f',
    'mp4',
    '-ar',
    '48000',
    '-c:a',
    'aac',
    '-b:a',
    '192k',
    '-metadata',
    'title=Dream Culture — Child Life editorial source',
    '-metadata',
    'artist=Kevin MacLeod',
    '-metadata',
    'comment=CC BY 4.0; tempo adjusted 70 to 76 BPM; excerpt. See MUSIC-CREDITS.md.',
    join(root, 'public/audio/dream-culture-76bpm.m4a'),
  ],
  { stdio: 'inherit', env: { ...process.env, DYLD_LIBRARY_PATH: compositor } },
);
if (result.status !== 0) process.exit(result.status ?? 1);
