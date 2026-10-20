// Render the two phase-1 videos in VI/EN, 4:5/9:16, plus boundary stills and normalized original music.
import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import {
  premium48Phase1,
  freezeKeepsakePresentation,
  type KeepsakePresentationRequest,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { serveFolder } from '../src/serve';
import { syncArt } from './sync-art.mjs';
import type { StoryProps } from '../src/kit/core';
const phase = process.argv.includes('--phase5')
  ? 5
  : process.argv.includes('--phase4')
    ? 4
    : process.argv.includes('--phase3')
      ? 3
      : process.argv.includes('--phase2')
        ? 2
        : 1;
const phase5 = phase === 5;
const phase4 = phase === 4;
const phase3 = phase === 3;
const phase2 = phase >= 2;
const out = resolve(process.argv[2] ?? `../../artifacts/premium48-phase${phase}`);
const photos = resolve(
  process.argv[3] ??
    (phase2 ? `/tmp/child-life-p48-phase${phase}-photos` : '/tmp/child-life-p48-photos'),
);
const stillsOnly = process.argv.includes('--stills');
const onlyAt = process.argv.indexOf('--only');
const only = onlyAt >= 0 ? process.argv[onlyAt + 1] : null;
await mkdir(out, { recursive: true });
const require = createRequire(import.meta.url);
const bin = dirname(
  require.resolve(`@remotion/compositor-${process.platform}-${process.arch}/package.json`, {
    paths: [dirname(require.resolve('@remotion/renderer'))],
  }),
);
const ffmpeg = resolve('../../firebase/functions/node_modules/@ffmpeg-installer/ffmpeg');
const ffmpegPath = (require(ffmpeg) as { path: string }).path;
execFileSync(process.execPath, [
  phase5
    ? 'scripts/premium48-phase5-music.mjs'
    : phase4
      ? 'scripts/premium48-phase4-music.mjs'
      : phase3
        ? 'scripts/premium48-phase3-music.mjs'
        : phase2
          ? 'scripts/premium48-phase2-music.mjs'
          : 'scripts/premium48-music.mjs',
  out,
]);
for (const name of phase5
  ? ['p48-wardrobe', 'p48-smile']
  : phase4
    ? ['p48-chapter', 'p48-compare']
    : phase3
      ? ['p48-observe', 'p48-letter']
      : phase2
        ? ['p48-home', 'p48-month']
        : ['p48-arrival', 'p48-embrace'])
  if (!existsSync(join(out, `${name}.m4a`))) {
    execFileSync(ffmpegPath, [
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
const licence = JSON.parse(readFileSync(join(photos, 'licence.json'), 'utf8')) as {
  file: string;
  source: string;
  licence: string;
  release?: string;
  ownerApproved?: string;
}[];
if (
  licence.some(
    (p) =>
      !p.release && !(/^(CC0|Pexels License|Unsplash License)/.test(p.licence) && p.ownerApproved),
  )
)
  throw new Error('sample rights missing');
if (phase2) {
  const old: { download: string }[] = JSON.parse(
    readFileSync(resolve('../../design/sample-photos/licence.json'), 'utf8'),
  ) as { download: string }[];
  if (phase >= 3)
    old.push(
      ...JSON.parse(
        readFileSync(resolve('../../design/sample-photos/premium48-phase2-licence.json'), 'utf8'),
      ),
    );
  if (phase >= 4)
    old.push(
      ...JSON.parse(
        readFileSync(resolve('../../design/sample-photos/premium48-phase3-licence.json'), 'utf8'),
      ),
    );
  if (phase5)
    old.push(
      ...JSON.parse(
        readFileSync(resolve('../../design/sample-photos/premium48-phase4-licence.json'), 'utf8'),
      ),
    );
  const fresh = JSON.parse(readFileSync(join(photos, 'licence.json'), 'utf8')) as {
    download: string;
  }[];
  if (
    fresh.length !== (phase5 ? 8 : phase4 ? 7 : 10) ||
    new Set(fresh.map((p) => p.download)).size !== (phase5 ? 8 : phase4 ? 7 : 10) ||
    fresh.some((p) => old.some((o) => o.download === p.download))
  )
    throw new Error('Phase 2 requires ten distinct new sample photos');
}
const ps = await serveFolder(photos),
  ms = await serveFolder(out);
try {
  await syncArt();
  const serveUrl = await bundle({
    entryPoint: resolve('src/remotion-entry.ts'),
    publicDir: resolve('public'),
  });
  const report = [];
  const templates: KeepsakeTemplate[] = phase2
    ? JSON.parse(readFileSync(join(out, 'templates.json'), 'utf8')).templates
    : premium48Phase1();
  for (const t of templates.filter((t) => t.kind === 'video'))
    for (const locale of ['vi', 'en'] as const)
      for (const format of ['story', 'portrait'] as const) {
        const stem = `V${t.id.slice(-2)}-${locale}-${format}`;
        if (only && only !== stem) continue;
        const embrace = t.id.endsWith('_02');
        const month = t.id.endsWith(phase5 ? '_10' : phase4 ? '_08' : phase3 ? '_06' : '_04');
        const presentation: KeepsakePresentationRequest = {
          values: phase5
            ? month
              ? { babyName: 'Lily', momentDate: '', reactionConfirmed: 'false' }
              : {
                  babyName: 'Noah',
                  itemName: locale === 'vi' ? 'áo cotton' : 'cotton outfit',
                  outgrownConfirmed: 'false',
                  storedDate: '',
                }
            : phase4
              ? month
                ? { babyName: 'Bảo An', thenDate: '', nowDate: '' }
                : {
                    babyName: 'Bảo An',
                    monthNumber: '01',
                    discovery: locale === 'vi' ? 'bàn tay bé xíu' : 'tiny hands',
                    memoryLine: '',
                  }
              : phase3
                ? month
                  ? { babyName: 'Bảo An', narratorName: '' }
                  : {
                      babyName: 'Bảo An',
                      favoriteThing: locale === 'vi' ? 'những cái ôm' : 'cuddles',
                      littleDetail: locale === 'vi' ? 'bàn tay bé xíu' : 'tiny fingers',
                      memoryLine: locale === 'vi' ? 'chơi cùng mẹ' : 'playing together',
                    }
                : phase2
                  ? month
                    ? { babyName: 'Bảo An', birthPhotoConfirmed: 'false' }
                    : { babyName: 'Bảo An', momentDate: '2026-09-20', journeyConfirmed: 'false' }
                  : embrace
                    ? {
                        babyName: 'Bảo An',
                        narratorName: locale === 'vi' ? 'Mẹ Linh' : 'Linh',
                        momentDate: '2026-09-18',
                        firstConfirmed: 'false',
                      }
                    : {
                        babyName: 'Bảo An',
                        birthDate: '2026-09-17',
                        birthTime: '09:35',
                        placeName: 'Đà Nẵng',
                      },
          overrides: {},
          format,
          reducedMotion: false,
          crops: Array.from({ length: 5 }, (_, beat) => ({
            x:
              phase4 && month
                ? beat === 3
                  ? 0.8
                  : -0.6
                : !phase4 && phase2 && month && beat === 0
                  ? -0.3
                  : 0,
            y: phase4 && month ? (beat === 3 ? 0 : 1) : phase3 && month && beat === 4 ? -1 : 0,
            zoom: phase4 && month && beat !== 3 ? 1.15 : 1,
            fit: phase5
              ? 'contain'
              : phase4
                ? month
                  ? 'cover'
                  : 'contain'
                : phase2 && (month || beat !== 2)
                  ? 'cover'
                  : 'contain',
          })),
        };
        const indices = phase5
          ? month
            ? [5, 6, 7]
            : [0, 1, 2, 3, 4]
          : phase4
            ? month
              ? [5, 6]
              : [0, 1, 2, 3, 4]
            : phase2
              ? month
                ? [5, 6, 7, 8, 9]
                : [0, 1, 2, 3, 4]
              : embrace
                ? [3, 5, 17, 15]
                : [3, 1, 6, 5, 0];
        const props: StoryProps = {
          photos: indices.map((i) => ps.url(licence[i]!.file)),
          title: t.name[locale],
          message: '',
          name: phase5 ? (month ? 'Lily' : 'Noah') : 'Bảo An',
          dateLine: '',
          mark: null,
          palette: t.palette,
          ...(phase2
            ? {
                artAssets: Object.fromEntries(
                  Object.entries(t.assets).map(([role, asset]) => [role, ms.url(asset)]),
                ),
              }
            : {}),
          music: ms.url(
            phase5
              ? month
                ? 'p48-smile.m4a'
                : 'p48-wardrobe.m4a'
              : phase4
                ? month
                  ? 'p48-compare.m4a'
                  : 'p48-chapter.m4a'
                : phase3
                  ? month
                    ? 'p48-letter.m4a'
                    : 'p48-observe.m4a'
                  : phase2
                    ? month
                      ? 'p48-month.m4a'
                      : 'p48-home.m4a'
                    : embrace
                      ? 'p48-embrace.m4a'
                      : 'p48-arrival.m4a',
          ),
          durationSec: 35,
          brand: t.brand,
          locale,
          presentation: freezeKeepsakePresentation(t.personalization!, presentation, locale),
        };
        const composition = await selectComposition({
          serveUrl,
          id: t.composition!,
          inputProps: props,
        });
        writeFileSync(join(out, `${stem}.json`), JSON.stringify(props, null, 2));
        console.log('Rendering', stem);
        for (const f of [0, 90, 209, 210, 300, 420, 510, 630, 720, 900, 990, 1049]) {
          await renderStill({
            serveUrl,
            composition,
            inputProps: props,
            frame: f,
            output: join(out, `${stem}-${f}.png`),
            scale: 0.4,
          });
        }
        if (
          !stillsOnly &&
          (process.argv.includes('--force') || !existsSync(join(out, `${stem}.mp4`)))
        )
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
            concurrency: 4,
          });
        if (!stillsOnly) {
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
        }
        console.log(stem, composition.width, composition.height, composition.durationInFrames);
      }
  writeFileSync(join(out, 'video-qa.json'), JSON.stringify(report, null, 2));
} finally {
  await ps.close();
  await ms.close();
}
