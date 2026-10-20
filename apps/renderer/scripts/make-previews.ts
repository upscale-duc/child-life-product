// The "Xem mẫu" videos and covers of the seed's video templates (owner, 2026-10-14: a real export
// as the preview), rendered with the same compositions the server uses, plus the M4A encodes of
// the music library's WAV masters (`compose-music.mjs`).
//
// Photos must be cleared for publishing (owner, 2026-10-14): `<photosDir>/licence.json` lists every
// file with its source and licence. A photo of a person also needs a model / guardian `release`,
// or a free licence (CC0, Pexels, Unsplash) with the owner's recorded acceptance (`ownerApproved`,
// design/sample-photos). Anything else stops the script. `ageDays` (optional) is how old the baby
// is in the photo: templates pick photos of their age and show it as the age label.
//   pnpm --filter child-life-renderer exec tsx scripts/make-previews.ts <photosDir> <musicDir> <outDir> [Composition…] [--covers]
import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import {
  keepsakeAgeLabel,
  keepsakeChapter1Videos,
  keepsakeSeedV1,
  occasions,
  type KeepsakeComposition,
} from '@child-life/contracts';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { storyOf } from '../src/compositions/registry';
import { serveFolder } from '../src/serve';
import { syncArt } from './sync-art.mjs';

const args = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const [photosDir, musicDir, outDir, ...only] = args;
const covers = process.argv.includes('--covers');
if (!photosDir || !musicDir || !outDir) {
  throw new Error('usage: make-previews <photosDir> <musicDir> <outDir> [Composition…] [--covers]');
}
await mkdir(outDir, { recursive: true });

/** One sample photo and why it may be published. */
interface PhotoLicence {
  file: string;
  source: string;
  licence: string;
  /** "person": a real person, needs `release`; "illustration": no person. */
  subject: 'person' | 'illustration';
  /** Model / guardian release reference (contract, invoice or signed form id). */
  release?: string | null;
  /** The owner's acceptance of a free licence without a release (date and words). */
  ownerApproved?: string;
  ageDays?: number;
}
const freeLicence = /^(CC0|Pexels License|Unsplash License)/;
const listPath = join(photosDir, 'licence.json');
if (!existsSync(listPath)) {
  throw new Error(`${listPath} is missing: every sample photo needs a licence`);
}
const cleared = (JSON.parse(readFileSync(listPath, 'utf8')) as PhotoLicence[]).map((p) => {
  if (!p.file || !p.source || !p.licence) {
    throw new Error(`${p.file ?? '?'}: source and licence are required`);
  }
  const accepted = freeLicence.test(p.licence) && !!p.ownerApproved;
  if (p.subject !== 'illustration' && !p.release && !accepted) {
    throw new Error(`${p.file}: a photo of a person needs a model/guardian release`);
  }
  if (!existsSync(join(photosDir, p.file))) throw new Error(`${p.file}: not in ${photosDir}`);
  return p;
});
if (cleared.length === 0) throw new Error('no cleared photos');

// Remotion's own ffmpeg (no system install needed): WAV → AAC in an "M4A " container.
const require = createRequire(import.meta.url);
const ffmpegDir = dirname(
  require.resolve(`@remotion/compositor-${process.platform}-${process.arch}/package.json`, {
    paths: [dirname(require.resolve('@remotion/renderer'))],
  }),
);
const tracks = ['ru-em', 'nang-mai', 'binh-minh', 'mo-mang', 'tiec-vui'] as const;
for (const track of tracks) {
  // Kept once made: re-encoding could change the bytes, and so the published asset name.
  if (existsSync(join(outDir, `${track}.m4a`))) continue;
  execFileSync(
    join(ffmpegDir, 'ffmpeg'),
    [
      ...['-y', '-loglevel', 'error', '-i', join(musicDir, `${track}.wav`)],
      ...['-c:a', 'aac', '-b:a', '160k', '-f', 'mp4', '-brand', 'M4A ', '-movflags', '+faststart'],
      join(outDir, `${track}.m4a`),
    ],
    { env: { ...process.env, DYLD_LIBRARY_PATH: ffmpegDir, LD_LIBRARY_PATH: ffmpegDir } },
  );
}

/** The default track per composition (as `seed-keepsakes.ts` sets `defaultMusic`). */
export const previewMusic: Record<KeepsakeComposition, (typeof tracks)[number]> = {
  PremiumArrival: 'binh-minh',
  PremiumEmbrace: 'ru-em',
  PremiumHomecoming: 'binh-minh',
  PremiumFirstMonth: 'binh-minh',
  PremiumLittleThings: 'binh-minh',
  PremiumMonthLetter: 'binh-minh',
  PremiumMonthlyChapter: 'binh-minh',
  PremiumThenNow: 'binh-minh',
  PremiumOutgrownKeepsake: 'binh-minh',
  PremiumSmileToKeep: 'binh-minh',
  FirstWeek: 'ru-em',
  FirstMonth: 'binh-minh',
  HundredDays: 'tiec-vui',
  LittleMoments: 'nang-mai',
  WelcomeWorld: 'binh-minh',
  OurFirstDays: 'ru-em',
  LittleLoveStory: 'mo-mang',
  TinyMoments: 'nang-mai',
  GrowingSoFast: 'binh-minh',
  HelloSmile: 'nang-mai',
  FirstMilestone: 'tiec-vui',
  HundredDaysLove: 'binh-minh',
  HalfYear: 'binh-minh',
  LetterToBaby: 'ru-em',
  ThenAndNow: 'mo-mang',
  FirstBirthday: 'tiec-vui',
};

const photos = await serveFolder(resolve(photosDir));
const music = await serveFolder(resolve(outDir));
await syncArt();
const serveUrl = await bundle({
  entryPoint: resolve('src/remotion-entry.ts'),
  publicDir: resolve('public'),
});
const name = 'Bông';
const dob = '2026-01-01';
const dayAfter = (days: number) => new Date(Date.UTC(2026, 0, 1 + days)).toISOString().slice(0, 10);
for (const t of [...keepsakeSeedV1.templates, ...keepsakeChapter1Videos]) {
  if (t.kind !== 'video' || !t.composition) continue;
  if (only.length && !only.includes(t.composition)) continue;
  const text = (key: string) =>
    (t.texts.find((x) => x.key === key)?.default.vi ?? '').replaceAll('{name}', name);
  // Photos of the template's age first (when the list says how old the baby is), in age order.
  const window = t.ageDays ?? { min: 0, max: 400 };
  const gap = (p: PhotoLicence) =>
    p.ageDays === undefined ? 0 : Math.max(0, window.min - p.ageDays, p.ageDays - window.max);
  const chosen = [...cleared]
    .sort((a, b) => gap(a) - gap(b) || (a.ageDays ?? 0) - (b.ageDays ?? 0))
    .slice(0, t.photos.max)
    .sort((a, b) => (a.ageDays ?? 0) - (b.ageDays ?? 0));
  // A different first photo per template (covers would otherwise repeat); ages stay in the
  // labels, and timeline videos sort by them.
  const shift = [...t.id].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 9973, 7) % chosen.length;
  const rotated = [...chosen.slice(shift), ...chosen.slice(0, shift)];
  const picks = Array.from({ length: t.photos.max }, (_, i) => rotated[i % rotated.length]!);
  const occasion = t.occasions[0] ? occasions[t.occasions[0]] : null;
  const mark =
    occasion && occasion.kind === 'age'
      ? 'days' in occasion
        ? occasion.days > 0
          ? String(occasion.days)
          : null
        : String(occasion.months === 12 ? 1 : occasion.months)
      : null;
  const inputProps = {
    photos: picks.map((p) => photos.url(p.file)),
    title: text('title'),
    message: text('message'),
    headline: text('headline'),
    closing: text('closing'),
    lines: text('lines'),
    letter: text('letter'),
    name,
    dateLine: '',
    mark,
    palette: t.palette,
    music: music.url(`${previewMusic[t.composition]}.m4a`),
    durationSec: t.durationSec ?? 30,
    brand: t.brand,
    locale: 'vi' as const,
    birthStats: '3,2 kg · 50 cm',
    photoInfo: picks.map((p) =>
      p.ageDays === undefined
        ? { takenAt: null, label: null }
        : {
            takenAt: `${dayAfter(p.ageDays)}T09:00:00Z`,
            label: keepsakeAgeLabel(dob, dayAfter(p.ageDays), 'vi'),
          },
    ),
  };
  const composition = await selectComposition({ serveUrl, id: t.composition, inputProps });
  const stem = join(outDir, t.id.replace('video_', '').replaceAll('_', '-'));
  await renderStill({
    composition,
    serveUrl,
    inputProps,
    frame: storyOf(t.composition).poster(inputProps),
    imageFormat: 'webp',
    scale: 2 / 3,
    output: `${stem}-cover.webp`,
  });
  console.log('rendered', `${stem}-cover.webp`);
  if (covers) continue;
  await renderMedia({
    composition,
    serveUrl,
    inputProps,
    codec: 'h264',
    crf: 23,
    scale: 2 / 3,
    pixelFormat: 'yuv420p',
    audioCodec: 'aac',
    outputLocation: `${stem}.mp4`,
  });
  console.log('rendered', `${stem}.mp4`);
}
await photos.close();
await music.close();
