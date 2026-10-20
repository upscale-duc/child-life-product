// English demo movies for every published video that still has only a Vietnamese MP4.
import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import {
  keepsakePublicCatalogSchema,
  keepsakeAgeLabel,
  occasions,
  type OccasionId,
} from '@child-life/contracts';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { serveFolder } from '../src/serve';
import { syncArt } from './sync-art.mjs';
import { storyOf } from '../src/compositions/registry';
import type { StoryProps } from '../src/kit/core';
const out = resolve('../../artifacts/keepsake-english'),
  photoDir = resolve('/tmp/child-life-p48-photos');
const catalog = keepsakePublicCatalogSchema.parse(
  JSON.parse(readFileSync(join(out, 'catalog.json'), 'utf8')),
);
const sources = JSON.parse(readFileSync(join(photoDir, 'licence.json'), 'utf8')) as {
  file: string;
  ageDays?: number;
  licence: string;
  ownerApproved?: string;
  release?: string;
}[];
if (
  sources.some(
    (p) =>
      !p.release && !(/^(CC0|Pexels License|Unsplash License)/.test(p.licence) && p.ownerApproved),
  )
)
  throw new Error('uncleared sample');
await syncArt();
const photos = await serveFolder(photoDir),
  assets = await serveFolder(out);
try {
  const serveUrl = await bundle({
    entryPoint: resolve('src/remotion-entry.ts'),
    publicDir: resolve('public'),
  });
  const report = [];
  for (const t of catalog.templates.filter((t) => t.kind === 'video' && !t.previews?.en)) {
    const file = join(out, `${t.id}-en`);
    if (existsSync(`${file}.mp4`) && existsSync(`${file}.webp`)) {
      console.log('cached', t.id);
      continue;
    }
    const text = (key: string) =>
      (t.texts.find((x) => x.key === key)?.default.en ?? '').replaceAll('{name}', 'An');
    const window = t.ageDays ?? { min: 0, max: 400 };
    const gap = (p: (typeof sources)[number]) =>
      p.ageDays === undefined ? 0 : Math.max(0, window.min - p.ageDays, p.ageDays - window.max);
    const chosen = [...sources]
      .sort((a, b) => gap(a) - gap(b) || (a.ageDays ?? 0) - (b.ageDays ?? 0))
      .slice(0, t.photos.max);
    const shift = [...t.id].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 9973, 7) % chosen.length;
    const rotated = [...chosen.slice(shift), ...chosen.slice(0, shift)];
    const picks = Array.from({ length: t.photos.max }, (_, i) => rotated[i % rotated.length]!);
    const occasion = t.occasions[0] ? occasions[t.occasions[0] as OccasionId] : null;
    const mark =
      occasion && occasion.kind === 'age'
        ? 'days' in occasion
          ? occasion.days
            ? String(occasion.days)
            : null
          : String(occasion.months === 12 ? 1 : occasion.months)
        : null;
    const track = catalog.music.find((m) => m.id === t.defaultMusic);
    const props: StoryProps = {
      photos: picks.map((p) => photos.url(p.file)),
      title: text('title'),
      message: text('message'),
      headline: text('headline'),
      closing: text('closing'),
      lines: text('lines'),
      letter: text('letter'),
      name: 'An',
      dateLine: '',
      mark,
      palette: t.palette,
      music: track ? assets.url(track.asset) : t.assets.music ? assets.url(t.assets.music) : null,
      durationSec: t.durationSec ?? 30,
      brand: t.brand,
      locale: 'en',
      birthStats: '3.2 kg · 50 cm',
      photoInfo: picks.map((p) =>
        p.ageDays === undefined
          ? { takenAt: null, label: null }
          : {
              takenAt: new Date(Date.UTC(2026, 0, 1 + p.ageDays)).toISOString(),
              label: keepsakeAgeLabel(
                '2026-01-01',
                new Date(Date.UTC(2026, 0, 1 + p.ageDays)).toISOString().slice(0, 10),
                'en',
              ),
            },
      ),
    };
    const composition = await selectComposition({
      serveUrl,
      id: t.composition!,
      inputProps: props,
    });
    console.log('Rendering English', t.id, `${composition.durationInFrames / 30}s`);
    await renderStill({
      serveUrl,
      composition,
      inputProps: props,
      frame: storyOf(t.composition).poster(props),
      imageFormat: 'webp',
      scale: 2 / 3,
      output: `${file}.webp`,
    });
    await renderMedia({
      serveUrl,
      composition,
      inputProps: props,
      codec: 'h264',
      crf: 21,
      scale: 2 / 3,
      pixelFormat: 'yuv420p',
      audioCodec: 'aac',
      audioBitrate: '160k',
      sampleRate: 48000,
      concurrency: 4,
      outputLocation: `${file}.mp4`,
    });
    writeFileSync(`${file}.json`, JSON.stringify(props, null, 2));
    report.push({
      id: t.id,
      sourceVersion: t.version,
      locale: 'en',
      frames: composition.durationInFrames,
      fps: 30,
      width: 720,
      height: 1280,
    });
    writeFileSync(join(out, 'render-report.json'), JSON.stringify(report, null, 2));
    console.log('Done English', t.id);
  }
} finally {
  await photos.close();
  await assets.close();
}
