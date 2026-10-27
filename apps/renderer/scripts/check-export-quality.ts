// Synthetic one-second render smoke test. No family photos, no Firebase.
// pnpm --filter child-life-renderer exec tsx scripts/check-export-quality.ts /tmp/cl-quality
import { bundle } from '@remotion/bundler';
import { renderMedia, selectComposition } from '@remotion/renderer';
import { mkdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { videoRenderScale } from '@child-life/contracts';
import { sampleProps } from '../src/compositions/Root';

const dir = resolve(process.argv[2] ?? '/tmp/cl-export-quality');
await mkdir(dir, { recursive: true });
const serveUrl = await bundle({
  entryPoint: resolve('src/remotion-entry.ts'),
  publicDir: resolve('public'),
});
const props = { ...sampleProps, brand: null, music: null };
const composition = await selectComposition({ serveUrl, id: 'LittleMoments', inputProps: props });
for (const quality of ['hd720', 'fullHd1080'] as const) {
  await renderMedia({
    serveUrl,
    composition,
    inputProps: props,
    codec: 'h264',
    scale: videoRenderScale(quality),
    frameRange: [0, 29],
    concurrency: 2,
    outputLocation: join(dir, `${quality}.mp4`),
  });
}
await writeFile(
  join(dir, 'source.json'),
  JSON.stringify({ width: composition.width, height: composition.height }),
);
console.log('Rendered synthetic quality samples:', dir);
