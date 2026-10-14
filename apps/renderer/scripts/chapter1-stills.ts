// Stills of the Chapter 01 videos (intro, poster, a late scene, closing) with the cleared sample
// photos, to look at the motion design without Firebase:
//   pnpm --filter child-life-renderer exec tsx scripts/chapter1-stills.ts <outDir> [Composition…]
import { bundle } from '@remotion/bundler';
import { renderStill, selectComposition } from '@remotion/renderer';
import { keepsakeChapter1Videos } from '@child-life/contracts';
import { mkdir, readdir } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { storyOf } from '../src/compositions/registry';
import type { StoryProps } from '../src/kit/core';
import { serveFolder } from '../src/serve';
import { syncArt } from './sync-art.mjs';

const [outDir, ...only] = process.argv.slice(2);
if (!outDir) throw new Error('usage: chapter1-stills <outDir> [Composition…]');
await mkdir(outDir, { recursive: true });
const dir = resolve('player/samples');
const served = await serveFolder(dir);
const files = (await readdir(dir)).filter((f) => f.endsWith('.jpg')).sort();
await syncArt();
const serveUrl = await bundle({ entryPoint: resolve('src/remotion-entry.ts'), publicDir: resolve('public') });
for (const t of keepsakeChapter1Videos) {
  const id = t.composition!;
  if (only.length && !only.includes(id)) continue;
  const text = (k: string) => (t.texts.find((x) => x.key === k)?.default.vi ?? '').replaceAll('{name}', 'Bông');
  const n = t.photos.max;
  const props: StoryProps = {
    photos: Array.from({ length: n }, (_, i) => served.url(files[i % files.length]!)),
    title: text('title'),
    message: text('message'),
    headline: text('headline'),
    closing: text('closing'),
    lines: text('lines'),
    letter: text('letter'),
    name: 'Bông',
    dateLine: '14.01 – 14.07.2026',
    mark: null,
    palette: t.palette,
    music: null,
    durationSec: t.durationSec ?? 30,
    brand: t.brand,
    locale: 'vi',
    birthStats: '3,2 kg · 50 cm',
    photoInfo: Array.from({ length: n }, (_, i) => ({
      takenAt: new Date(Date.UTC(2026, 0, 14 + i * 20)).toISOString(),
      label: i === 0 ? 'Ngày đầu' : `Tháng ${Math.min(11, Math.ceil((i * 20) / 30))}`,
    })),
  };
  const composition = await selectComposition({ serveUrl, id, inputProps: props });
  const total = composition.durationInFrames;
  const frames = { a: 50, b: storyOf(id).poster(props), c: Math.round(total * 0.62), d: total - 20 };
  for (const [k, frame] of Object.entries(frames)) {
    await renderStill({ composition, serveUrl, inputProps: props, frame, scale: 0.25, output: join(outDir, `${id}-${k}.png`) });
  }
  console.log(id, `${(total / 30).toFixed(1)} s`);
}
await served.close();
