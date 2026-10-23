/** DEV ONLY: add/update exactly the four reviewed phase-1 templates. Preserve every other template,
 * music track, premium policy and content draft. Atomic compare-and-set prevents overwriting staff work.
 * Run after backend, renderer and player support are deployed:
 * pnpm --filter child-life-scripts exec tsx src/publish-premium48.ts --project child-life-dev
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { setDefaultResultOrder } from 'node:dns';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import {
  assignKeepsakeVersions,
  keepsakeCatalogSchema,
  keepsakePublicCatalogSchema,
  premium48Phase1,
  premium48Phase2,
  premium48Phase3,
  premium48Phase4,
  premium48Phase5,
  premium48Phase6,
  premium48FinalPhase,
  premium48FinalDesigns,
  publicKeepsakeMusic,
  type KeepsakeMusic,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import { buildArt } from './keepsake-art.js';
const at = process.argv.indexOf('--project');
setDefaultResultOrder('ipv4first');
const phase = Number(process.argv.find((v) => /^--phase(?:[1-9]|1[0-2])$/.test(v))?.slice(7) ?? 1);
const finalDesigns = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase);
if (at < 0 || process.argv[at + 1] !== 'child-life-dev')
  throw new Error('Only --project child-life-dev is allowed');
const project = 'child-life-dev',
  bucket = `${project}.firebasestorage.app`;
const token = execFileSync('gcloud', ['auth', 'print-access-token'], { encoding: 'utf8' }).trim();
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const out = resolve(import.meta.dirname, `../../artifacts/premium48-phase${phase}`);
if (phase >= 2) {
  const qa = JSON.parse(readFileSync(join(out, 'video-qa.json'), 'utf8')) as {
    probe: {
      streams: { codec_type: string; nb_frames?: string; width?: number; height?: number }[];
    };
    id: string;
  }[];
  const photos = JSON.parse(readFileSync(join(out, 'photo-qa.json'), 'utf8')) as {
    count: number;
    distinctFromExistingCatalog: boolean;
  };
  if (
    qa.length !== 8 ||
    qa.some(
      (q) =>
        !q.probe.streams.some(
          (s) =>
            s.codec_type === 'video' &&
            s.nb_frames === (q.id === 'video_premium48_22' ? '1500' : '1050') &&
            s.width === 1080 &&
            (s.height === 1350 || s.height === 1920),
        ),
    ) ||
    photos.count !==
      (phase >= 7
        ? ({ 7: 10, 8: 8, 9: 8, 10: 10, 11: 17, 12: 10 } as Record<number, number>)[phase]
        : phase === 6
          ? 10
          : phase === 5
            ? 8
            : phase === 4
              ? 7
              : 10) ||
    !photos.distinctFromExistingCatalog
  )
    throw new Error(`Phase ${phase} media/photo QA incomplete`);
}
const headers = {
  Authorization: `Bearer ${token}`,
  'Content-Type': 'application/json',
  'x-goog-user-project': project,
};
function encode(v: unknown): unknown {
  if (v == null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number')
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(encode) } };
  return {
    mapValue: {
      fields: Object.fromEntries(Object.entries(v as object).map(([k, x]) => [k, encode(x)])),
    },
  };
}
function decode(v: Record<string, unknown>): unknown {
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('arrayValue' in v)
    return ((v.arrayValue as { values?: Record<string, unknown>[] }).values ?? []).map(decode);
  if ('mapValue' in v)
    return Object.fromEntries(
      Object.entries(
        (v.mapValue as { fields?: Record<string, Record<string, unknown>> }).fields ?? {},
      ).map(([k, x]) => [k, decode(x)]),
    );
  throw new Error('unsupported Firestore value');
}
async function get(path: string) {
  const r = await fetch(`${base}/${path}`, { headers });
  if (!r.ok) throw new Error(`${path}: ${r.status}`);
  const doc = (await r.json()) as {
    name: string;
    fields: Record<string, Record<string, unknown>>;
    updateTime: string;
  };
  return { doc, data: decode({ mapValue: { fields: doc.fields } }) as Record<string, unknown> };
}
async function upload(bytes: Buffer, name: string, ext: string, type: string) {
  const asset = `${name}_${createHash('sha256').update(bytes).digest('hex').slice(0, 8)}.${ext}`;
  const boundary = 'p48asset';
  const body = Buffer.concat([
    Buffer.from(
      `--${boundary}\r\nContent-Type: application/json\r\n\r\n${JSON.stringify({ name: `content/keepsakes/${asset}`, contentType: type, cacheControl: 'public, max-age=31536000, immutable' })}\r\n--${boundary}\r\nContent-Type: ${type}\r\n\r\n`,
    ),
    bytes,
    Buffer.from(`\r\n--${boundary}--`),
  ]);
  const r = await fetch(
    `https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=multipart&ifGenerationMatch=0`,
    {
      method: 'POST',
      headers: { ...headers, 'Content-Type': `multipart/related; boundary=${boundary}` },
      body,
    },
  );
  if (!r.ok && r.status !== 412) throw new Error(`asset upload: ${r.status}`);
  return asset;
}
const assets: Record<string, string> = {};
const phaseArt =
  phase >= 7
    ? (
        JSON.parse(
          readFileSync(
            resolve(
              import.meta.dirname,
              `../../design/keepsake-art/premium48-phase${phase}-manifest.json`,
            ),
            'utf8',
          ),
        ).assets as { name: string }[]
      ).map(({ name }) => {
        const t = (
          JSON.parse(readFileSync(join(out, 'templates.json'), 'utf8'))
            .templates as KeepsakeTemplate[]
        ).find((t) =>
          Object.values(t.assets).some((v) => v.startsWith(`art-${name}`.slice(0, 40) + '_')),
        )!;
        const asset = Object.values(t.assets).find((v) =>
          v.startsWith(`art-${name}`.slice(0, 40) + '_'),
        )!;
        return { name, bytes: readFileSync(join(out, asset)) };
      })
    : await buildArt();
for (const a of phaseArt.filter((a) =>
  phase >= 7
    ? finalDesigns.some((d) => a.name.startsWith(`p48-${d.part}-`))
    : phase === 6
      ? /^p48-(milestone-|discover-|grain$)/.test(a.name)
      : phase === 5
        ? /^p48-(wardrobe-|smile-|grain$)/.test(a.name)
        : phase === 4
          ? /^p48-(chapter-|compare-|grain$)/.test(a.name)
          : phase === 3
            ? /^p48-(observe-|letter-|grain$)/.test(a.name)
            : phase === 2
              ? /^p48-(home-|scrap-|grain$)/.test(a.name)
              : /^p48-(arrival-|embrace-|grain$)/.test(a.name),
))
  assets[a.name] = await upload(a.bytes, `art-${a.name}`, 'webp', 'image/webp');
const music: KeepsakeMusic[] = [];
for (const [part, vi, en, bpm] of phase >= 7
  ? finalDesigns.flatMap((d) =>
      (d.n === 20 ? ['neutral', 'tet', 'christmas'] : ['default']).map(
        (variant) =>
          [
            `${d.part}${variant === 'default' ? '' : `_${variant}`}`,
            `${d.music.vi}${variant === 'default' ? '' : ` · ${variant}`}`,
            `${d.music.en}${variant === 'default' ? '' : ` · ${variant}`}`,
            d.bpm,
          ] as const,
      ),
    )
  : phase === 6
    ? ([
        ['milestone', 'Từng bước của con', 'Your Little Steps', 96],
        ['discover', 'Qua đôi mắt con', 'Through Your Eyes', 82],
      ] as const)
    : phase === 5
      ? ([
          ['wardrobe', 'Sợi chỉ ký ức', 'Threads to Remember', 70],
          ['smile', 'Nắng trong nụ cười', 'Sunshine in Your Smile', 92],
        ] as const)
      : phase === 4
        ? ([
            ['chapter', 'Trang tháng', 'Monthly Pages', 88],
            ['compare', 'Giữa hai khoảnh khắc', 'Between Two Moments', 72],
          ] as const)
        : phase === 3
          ? ([
              ['observe', 'Những điều bé xíu', 'Tiny Little Things', 84],
              ['letter', 'Thư gửi con', 'A Letter for You', 62],
            ] as const)
          : phase === 2
            ? ([
                ['home', 'Đường về nhà', 'The Way Home', 78],
                ['month', 'Từng chút một', 'Little by Little', 76],
              ] as const)
            : ([
                ['arrival', 'Ngày con đến', 'The Day You Arrived', 68],
                ['embrace', 'Vòng tay ấm', 'Held Close', 64],
              ] as const))
  music.push({
    id: `music_p48_${part}`,
    title: { vi, en },
    artist: 'Child Life',
    mood: 'emotional',
    durationSec: part === 'months' ? 50 : 35,
    asset: await upload(
      readFileSync(join(out, `p48-${part.replaceAll('_', '-')}.m4a`)),
      `p48-${part.replaceAll('_', '-')}`,
      'm4a',
      'audio/mp4',
    ),
    licence: {
      kind: 'original',
      source: 'Child Life · original synthesized score',
      reference: `apps/renderer/scripts/premium48${phase >= 7 ? '-final' : phase >= 2 ? `-phase${phase}` : ''}-music.mjs · ${bpm} BPM · 2026-10-22`,
      expiresOn: null,
    },
    status: 'published',
    order:
      phase >= 7
        ? 18 +
          premium48FinalDesigns.findIndex((d) => part === d.part || part.startsWith(d.part + '_')) +
          (part.startsWith('celebrate_')
            ? ['neutral', 'tet', 'christmas'].indexOf(part.slice(10))
            : premium48FinalDesigns.findIndex((d) => d.part === part) > 7
              ? 2
              : 0)
        : phase === 6
          ? part === 'milestone'
            ? 16
            : 17
          : phase === 5
            ? part === 'wardrobe'
              ? 14
              : 15
            : phase === 4
              ? part === 'chapter'
                ? 12
                : 13
              : phase === 3
                ? part === 'observe'
                  ? 10
                  : 11
                : phase === 2
                  ? part === 'home'
                    ? 8
                    : 9
                  : part === 'arrival'
                    ? 6
                    : 7,
  });
const added: KeepsakeTemplate[] =
  phase >= 7
    ? premium48FinalPhase(
        phase,
        assets,
        Object.fromEntries(
          finalDesigns.map((d) => [d.part, `music_p48_${d.part}${d.n === 20 ? '_neutral' : ''}`]),
        ),
      )
    : phase === 6
      ? premium48Phase6(assets, { milestone: music[0]!.id, discover: music[1]!.id })
      : phase === 5
        ? premium48Phase5(assets, { wardrobe: music[0]!.id, smile: music[1]!.id })
        : phase === 4
          ? premium48Phase4(assets, { chapter: music[0]!.id, compare: music[1]!.id })
          : phase === 3
            ? premium48Phase3(assets, { observe: music[0]!.id, letter: music[1]!.id })
            : phase === 2
              ? premium48Phase2(assets, { home: music[0]!.id, month: music[1]!.id })
              : premium48Phase1(assets, {
                  arrival: music[0]!.id,
                  embrace: music[1]!.id,
                });
// Locale-specific demos prevent an English app from playing a Vietnamese sample.
for (const t of added) {
  const video = t.kind === 'video';
  const n = `${video ? 'V' : 'C'}${t.id.slice(-2)}`;
  const sharp = (await import('sharp')).default;
  t.thumbs = {};
  if (video) t.previews = {};
  for (const locale of ['vi', 'en'] as const) {
    if (video)
      t.previews![locale] = await upload(
        readFileSync(join(out, `${n}-${locale}-story.mp4`)),
        `p48-${n.toLowerCase()}-${locale}-preview`,
        'mp4',
        'video/mp4',
      );
    const source = join(
      out,
      video
        ? `${n}-${locale}-story-${t.composition === 'PremiumTwelveMonths' ? 1440 : 990}.png`
        : `${n}-${locale}-portrait.png`,
    );
    t.thumbs[locale] = await upload(
      await sharp(source).resize({ width: 480 }).webp({ quality: 90 }).toBuffer(),
      `p48-${n.toLowerCase()}-${locale}-thumb`,
      'webp',
      'image/webp',
    );
  }
  t.thumb = t.thumbs.vi ?? null;
  if (video) t.preview = t.previews?.vi ?? null;
}
const live = await get('publicConfig/keepsakes'),
  content = await get('content/keepsakes');
const current = keepsakePublicCatalogSchema.parse(live.data);
const ids = new Set(added.map((t) => t.id)),
  mids = new Set(music.map((t) => t.id));
const privateMusic = (content.data.music ?? []) as KeepsakeMusic[];
const mergedMusic = [...privateMusic.filter((m) => !mids.has(m.id)), ...music];
// Do not discard a public track if staff metadata and the published catalog have drifted.
if (current.music.some((m) => !mergedMusic.some((p) => p.id === m.id)))
  throw new Error('Music catalog drift; refusing to publish');
const next = assignKeepsakeVersions(
  keepsakeCatalogSchema.parse({
    templates: [...current.templates.filter((t) => !ids.has(t.id)), ...added],
    premium: current.premium,
    music: mergedMusic.filter((m) => mids.has(m.id) || current.music.some((c) => c.id === m.id)),
  }),
  current,
  (content.data.highest ?? {}) as Record<string, number>,
);
const highest = { ...((content.data.highest ?? {}) as Record<string, number>) };
for (const t of next.templates) highest[t.id] = Math.max(highest[t.id] ?? 0, t.version);
const version = `ks_p48_phase${phase}_${Date.now()}`;
const publicData = {
  ...live.data,
  version,
  publishedAt: new Date().toISOString(),
  templates: next.templates,
  premium: current.premium,
  music: next.music.map(publicKeepsakeMusic),
};
const contentData = { ...content.data, highest, music: mergedMusic };
writeFileSync(
  join(out, 'catalog-before.json'),
  JSON.stringify({ public: live.data, content: content.data }, null, 2),
);
const fields = (data: unknown) =>
  (encode(data) as { mapValue: { fields: unknown } }).mapValue.fields;
const commit = await fetch(`${base}:commit`, {
  method: 'POST',
  headers,
  body: JSON.stringify({
    writes: [
      {
        update: { name: live.doc.name, fields: fields(publicData) },
        currentDocument: { updateTime: live.doc.updateTime },
      },
      {
        update: { name: content.doc.name, fields: fields(contentData) },
        currentDocument: { updateTime: content.doc.updateTime },
      },
    ],
  }),
});
if (!commit.ok) throw new Error(`Atomic publish refused: ${commit.status} ${await commit.text()}`);
writeFileSync(
  join(out, 'published.json'),
  JSON.stringify(
    { project, version, templates: next.templates.filter((t) => ids.has(t.id)), music },
    null,
    2,
  ),
);
console.log(
  `Published ${version}: 4 templates; retained ${current.templates.filter((t) => !ids.has(t.id)).length} existing templates and existing Premium access=${current.premium.access}.`,
);
