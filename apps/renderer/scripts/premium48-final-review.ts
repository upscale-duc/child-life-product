/** Render all final phases with one bundle and two bounded workers; resumable output. */
import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import {
  freezeKeepsakePresentation,
  premium48FinalDesigns,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { serveFolder } from '../src/serve';
import { syncArt } from './sync-art.mjs';
import type { StoryProps } from '../src/kit/core';
const root = resolve('../..'),
  require = createRequire(import.meta.url),
  stillsOnly = process.argv.includes('--stills'),
  only = process.argv.find((v) => v.startsWith('--phase='))?.split('=')[1];
const ffmpeg = (
  require(resolve('../../firebase/functions/node_modules/@ffmpeg-installer/ffmpeg')) as {
    path: string;
  }
).path;
const bin = dirname(
  require.resolve(`@remotion/compositor-${process.platform}-${process.arch}/package.json`, {
    paths: [dirname(require.resolve('@remotion/renderer'))],
  }),
);
await syncArt();
const serveUrl = await bundle({
  entryPoint: resolve('src/remotion-entry.ts'),
  publicDir: resolve('public'),
});
for (let phase = 7; phase <= 12; phase++) {
  if (only && phase !== Number(only)) continue;
  const out = join(root, `artifacts/premium48-phase${phase}`),
    photos = `/tmp/child-life-p48-phase${phase}-photos`,
    catalog = JSON.parse(readFileSync(join(out, 'templates.json'), 'utf8')) as {
      templates: KeepsakeTemplate[];
      demos: Record<string, Record<'vi' | 'en', Record<string, string>>>;
    },
    licence = JSON.parse(readFileSync(join(photos, 'licence.json'), 'utf8')) as {
      file: string;
      templates: string[];
    }[];
  execFileSync(process.execPath, ['scripts/premium48-final-music.mjs', out, String(phase)]);
  const ds = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase);
  for (const d of ds)
    for (const variant of d.n === 20 ? ['neutral', 'tet', 'christmas'] : ['default']) {
      const name = `p48-${d.part}${variant === 'default' ? '' : `-${variant}`}`;
      if (!existsSync(join(out, `${name}.m4a`)))
        execFileSync(ffmpeg, [
          '-y',
          '-loglevel',
          'error',
          '-i',
          join(out, `${name}.wav`),
          '-af',
          'loudnorm=I=-16:TP=-1:LRA=9',
          '-ar',
          '48000',
          '-ac',
          '2',
          '-c:a',
          'aac',
          '-b:a',
          '160k',
          '-movflags',
          '+faststart',
          join(out, `${name}.m4a`),
        ]);
    }
  const ps = await serveFolder(photos),
    ms = await serveFolder(out),
    report: { id: string; locale: string; format: string; probe: unknown }[] = [];
  try {
    const jobs = catalog.templates
      .filter((t) => t.kind === 'video')
      .flatMap((t) =>
        (['vi', 'en'] as const).flatMap((locale) =>
          (['story', 'portrait'] as const).map((format) => ({ t, locale, format })),
        ),
      );
    let at = 0;
    const worker = async () => {
      while (at < jobs.length) {
        const { t, locale, format } = jobs[at++]!,
          d = ds.find((d) => t.id.endsWith(`_${d.n}`))!,
          stem = `V${d.n}-${locale}-${format}`;
        const props: StoryProps = {
          photos: licence.filter((p) => p.templates.includes(`V${d.n}`)).map((p) => ps.url(p.file)),
          title: t.name[locale],
          message: '',
          name: d.baby,
          dateLine: '',
          mark: null,
          palette: t.palette,
          artAssets: Object.fromEntries(Object.entries(t.assets).map(([k, v]) => [k, ms.url(v)])),
          music: ms.url(`p48-${d.part}${d.n === 20 ? '-christmas' : ''}.m4a`),
          durationSec: t.durationSec!,
          brand: t.brand,
          locale,
          presentation: freezeKeepsakePresentation(
            t.personalization!,
            {
              values: catalog.demos[t.id]![locale],
              overrides: {},
              crops: t.personalization!.beats.map(() => ({ x: 0, y: 0, zoom: 1, fit: 'contain' })),
              format,
              reducedMotion: false,
            },
            locale,
          ),
        };
        const composition = await selectComposition({
          serveUrl,
          id: t.composition!,
          inputProps: props,
        });
        writeFileSync(join(out, `${stem}.json`), JSON.stringify(props, null, 2) + '\n');
        const frames =
          d.n === 22
            ? [0, 90, 329, 330, 660, 990, 1320, 1410, 1440, 1499]
            : [0, 90, 209, 210, 420, 630, 840, 990, 1049];
        for (const frame of frames) {
          const file = join(out, `${stem}-${frame}.png`);
          if (!existsSync(file) || process.argv.includes('--force'))
            await renderStill({
              serveUrl,
              composition,
              inputProps: props,
              frame,
              output: file,
              scale: 0.4,
            });
        }
        if (!stillsOnly) {
          if (!existsSync(join(out, `${stem}.mp4`)) || process.argv.includes('--force')) {
            console.log('Rendering', stem);
            await renderMedia({
              serveUrl,
              composition,
              inputProps: props,
              outputLocation: join(out, `${stem}.mp4`),
              codec: 'h264',
              pixelFormat: 'yuv420p',
              crf: 20,
              audioCodec: 'aac',
              audioBitrate: '160k',
              sampleRate: 48000,
              concurrency: 3,
            });
          }
          const probe = JSON.parse(
            execFileSync(
              join(bin, 'ffprobe'),
              [
                '-v',
                'error',
                '-show_streams',
                '-show_format',
                '-of',
                'json',
                join(out, `${stem}.mp4`),
              ],
              { encoding: 'utf8', env: { ...process.env, DYLD_LIBRARY_PATH: bin } },
            ),
          );
          report.push({ id: t.id, locale, format, probe });
          writeFileSync(join(out, 'video-qa.json'), JSON.stringify(report, null, 2) + '\n');
        }
        console.log('Completed', stem, composition.durationInFrames);
      }
    };
    await Promise.all([worker(), worker()]);
  } finally {
    await ps.close();
    await ms.close();
  }
}
