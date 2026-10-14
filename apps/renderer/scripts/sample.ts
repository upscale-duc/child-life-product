// Renders stills (intro, a photo scene, the outro) and optionally the full MP4 of one composition
// from placeholder photos, to look at the motion design without Firebase:
//   pnpm --filter child-life-renderer sample <photosDir> <outDir> [FirstMonth|FirstWeek|…] [--video]
import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import { mkdir, readdir } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { sampleProps } from '../src/compositions/Root';
import { INTRO, OUTRO, posterFrame } from '../src/compositions/MemoryStory';
import { serveFolder } from '../src/serve';
import { syncArt } from './sync-art.mjs';

const [photosDir, outDir, id = 'FirstMonth'] = process.argv.slice(2);
if (!photosDir || !outDir)
  throw new Error('usage: sample <photosDir> <outDir> [composition] [--video]');
await mkdir(outDir, { recursive: true });
const served = await serveFolder(resolve(photosDir));
const files = (await readdir(photosDir)).filter((f) => /\.(jpe?g|png|webp)$/.test(f)).sort();
await syncArt();
const serveUrl = await bundle({
  entryPoint: resolve('src/remotion-entry.ts'),
  publicDir: resolve('public'),
});
const inputProps = { ...sampleProps, photos: files.map(served.url), durationSec: 30 };
const composition = await selectComposition({ serveUrl, id, inputProps });
const frames = {
  intro: Math.round(INTRO / 2),
  scene: posterFrame(inputProps.durationSec, files.length),
  outro: composition.durationInFrames - Math.round(OUTRO / 3),
};
for (const [name, frame] of Object.entries(frames)) {
  await renderStill({
    composition,
    serveUrl,
    inputProps,
    frame,
    output: join(outDir, `${id}-${name}.png`),
  });
}
if (process.argv.includes('--video')) {
  await renderMedia({
    composition,
    serveUrl,
    inputProps,
    codec: 'h264',
    outputLocation: join(outDir, `${id}.mp4`),
  });
}
await served.close();
console.log('done', outDir);
