/**
 * DEV only. `--catalog` publishes the first Mẫu kỷ niệm catalog (`keepsakeSeedV1`, D-068) straight
 * to `publicConfig/keepsakes`, skipping the portal's two-person approval (it replaces whatever was
 * published); `--flag` turns the `milestone_cards` beta on for every family, `--video` the
 * `memory_story` one. `--media <dir>` uploads the Xem mẫu videos and the two original tracks made by
 * `apps/renderer/scripts/make-previews.ts` and publishes the seed with them (Thư viện nhạc, default
 * music, preview, cover); templates that did not change keep their version. `--art` uploads the
 * original art library (`design/keepsake-art/*.svg`, rasterised to transparent WebP) as catalog
 * assets `art-{name}_{hash}.webp` for staff to use in templates. On prod the catalog only ever
 * comes from the portal.
 *
 * Refuses any project other than child-life-dev. Uses the caller's gcloud credentials through the
 * Firestore REST API, like `seed-config.ts`.
 *   pnpm --filter child-life-scripts exec tsx src/seed-keepsakes.ts --project child-life-dev
 *     [--catalog] [--flag] [--video] [--media <dir> [--chapter1]] [--art]
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { buildArt } from './keepsake-art.js';
import { chapter1Cards } from './keepsakes-chapter1.js';
import { join } from 'node:path';
import {
  assignKeepsakeVersions,
  firebaseProjectIds,
  flagSchema,
  keepsakeCatalogSchema,
  keepsakeChapter1Videos,
  keepsakeSeedV1,
  keepsakeTemplateSchema,
  type KeepsakeComposition,
  publicKeepsakeMusic,
  type KeepsakeCatalog,
  type KeepsakeMusic,
  type KeepsakeTemplate,
} from '@child-life/contracts';

function toValue(value: unknown): unknown {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(toValue) } };
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toValue(v)])),
      },
    };
  }
  throw new Error(`Unsupported value: ${String(value)}`);
}

function fromValue(v: Record<string, unknown>): unknown {
  if ('nullValue' in v) return null;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('stringValue' in v) return v.stringValue;
  if ('arrayValue' in v) {
    const values = (v.arrayValue as { values?: Record<string, unknown>[] }).values ?? [];
    return values.map(fromValue);
  }
  if ('mapValue' in v) {
    const fields =
      (v.mapValue as { fields?: Record<string, Record<string, unknown>> }).fields ?? {};
    return Object.fromEntries(Object.entries(fields).map(([k, x]) => [k, fromValue(x)]));
  }
  throw new Error(`Unsupported value: ${JSON.stringify(v)}`);
}

const argAt = process.argv.indexOf('--project');
const project = argAt >= 0 ? process.argv[argAt + 1] : undefined;
if (project !== firebaseProjectIds.dev) {
  console.error(
    `Refusing "${project ?? '(none)'}": this script only targets ${firebaseProjectIds.dev}.`,
  );
  process.exit(1);
}
const token = execFileSync('gcloud', ['auth', 'print-access-token'], { encoding: 'utf8' }).trim();
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;

async function get(path: string): Promise<Record<string, unknown> | null> {
  const response = await fetch(`${base}/${path}`, {
    headers: { Authorization: `Bearer ${token}`, 'x-goog-user-project': project! },
  });
  if (response.status === 404) return null;
  if (!response.ok) {
    console.error(`${path}: HTTP ${response.status} ${await response.text()}`);
    process.exit(1);
  }
  const doc = (await response.json()) as { fields?: Record<string, Record<string, unknown>> };
  return fromValue({ mapValue: { fields: doc.fields ?? {} } }) as Record<string, unknown>;
}

/** Like `staffKeepsakesAsset`: `{name}_{sha256[:8]}.{ext}` at `content/keepsakes/`, immutable. */
async function upload(
  file: string,
  name: string,
  contentType: string,
  data?: Buffer,
): Promise<string> {
  const bytes = data ?? readFileSync(file);
  // From the bytes' type when they were made here (an SVG rasterised to WebP), else the file's.
  const ext =
    { 'image/webp': 'webp', 'video/mp4': 'mp4', 'audio/mpeg': 'mp3' }[data ? contentType : ''] ??
    file.split('.').pop()!;
  const asset = `${name}_${createHash('sha256').update(bytes).digest('hex').slice(0, 8)}.${ext}`;
  const boundary = `b${createHash('sha256').update(asset).digest('hex').slice(0, 16)}`;
  const meta = {
    name: `content/keepsakes/${asset}`,
    contentType,
    cacheControl: 'public, max-age=31536000, immutable',
  };
  const body = Buffer.concat([
    Buffer.from(
      `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(meta)}\r\n` +
        `--${boundary}\r\nContent-Type: ${contentType}\r\n\r\n`,
    ),
    bytes,
    Buffer.from(`\r\n--${boundary}--`),
  ]);
  const bucket = `${project}.firebasestorage.app`;
  const response = await fetch(
    `https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=multipart`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': `multipart/related; boundary=${boundary}`,
        'x-goog-user-project': project!,
      },
      body,
    },
  );
  if (!response.ok) {
    console.error(`${asset}: HTTP ${response.status} ${await response.text()}`);
    process.exit(1);
  }
  console.log(`uploaded content/keepsakes/${asset} (${bytes.length} bytes)`);
  return asset;
}

async function patch(path: string, data: Record<string, unknown>, fields?: string[]) {
  const mask = fields ? `?${fields.map((f) => `updateMask.fieldPaths=${f}`).join('&')}` : '';
  const response = await fetch(`${base}/${path}${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'x-goog-user-project': project!,
    },
    body: JSON.stringify({
      fields: (toValue(data) as { mapValue: { fields: object } }).mapValue.fields,
    }),
  });
  if (!response.ok) {
    console.error(`${path}: HTTP ${response.status} ${await response.text()}`);
    process.exit(1);
  }
}

if (process.argv.includes('--catalog')) {
  const catalog = assignKeepsakeVersions(keepsakeCatalogSchema.parse(keepsakeSeedV1), null, {});
  await patch('publicConfig/keepsakes', {
    version: 'ks_dev_seed',
    publishedAt: new Date().toISOString(),
    templates: catalog.templates,
    premium: catalog.premium,
    music: catalog.music.map(publicKeepsakeMusic),
  });
  await patch('content/keepsakes', {
    highest: Object.fromEntries(catalog.templates.map((t) => [t.id, t.version])),
    music: catalog.music,
  });
  console.log(
    `publicConfig/keepsakes: ${catalog.templates.length} templates published in ${project}`,
  );
}

if (process.argv.includes('--flag')) {
  const flag = flagSchema.parse({ enabled: true, scope: 'all', percent: 100, notice: null });
  await patch('config/flags', { milestone_cards: flag }, ['milestone_cards']);
  console.log(`config/flags.milestone_cards: on for every family in ${project}`);
}

if (process.argv.includes('--video')) {
  const flag = flagSchema.parse({ enabled: true, scope: 'all', percent: 100, notice: null });
  await patch('config/flags', { memory_story: flag }, ['memory_story']);
  console.log(`config/flags.memory_story: on for every family in ${project}`);
}

const mediaAt = process.argv.indexOf('--media');
if (mediaAt >= 0) {
  const dir = process.argv[mediaAt + 1]!;
  const licence = {
    kind: 'original' as const,
    source: 'Child Life (apps/renderer/scripts/compose-music.mjs)',
    reference: 'apps/renderer/preview-credits.md',
    expiresOn: null,
  };
  // Placeholder originals (licence "original"), until commercially licensed tracks are bought.
  const tracks: [string, string, { vi: string; en: string }, KeepsakeMusic['mood'], number][] = [
    ['music_ru_em', 'ru-em', { vi: 'Ru êm', en: 'Hush' }, 'gentle', 75],
    ['music_nang_mai', 'nang-mai', { vi: 'Nắng mai', en: 'Morning sun' }, 'happy', 75],
    ['music_binh_minh', 'binh-minh', { vi: 'Bình minh', en: 'First light' }, 'emotional', 80],
    ['music_mo_mang', 'mo-mang', { vi: 'Mơ màng', en: 'Daydream' }, 'dreamy', 80],
    ['music_tiec_vui', 'tiec-vui', { vi: 'Tiệc vui', en: 'Party time' }, 'festive', 80],
  ];
  const music: KeepsakeMusic[] = [];
  for (const [i, [id, file, title, mood, durationSec]] of tracks.entries()) {
    music.push({
      id,
      title,
      artist: 'Child Life',
      mood,
      durationSec,
      asset: await upload(join(dir, `${file}.m4a`), file, 'audio/mp4'),
      licence,
      status: 'published',
      order: (i + 1) * 10,
    });
  }
  // The default track per composition (make-previews.ts renders the previews with the same).
  const musicOf: Record<KeepsakeComposition, string> = {
    PremiumArrival: 'music_binh_minh',
    PremiumEmbrace: 'music_ru_em',
    PremiumHomecoming: 'music_binh_minh',
    PremiumFirstMonth: 'music_binh_minh',
    PremiumLittleThings: 'music_binh_minh',
    PremiumMonthLetter: 'music_binh_minh',
    PremiumMonthlyChapter: 'music_binh_minh',
    PremiumThenNow: 'music_binh_minh',
    PremiumOutgrownKeepsake: 'music_binh-minh',
    PremiumSmileToKeep: 'music_binh-minh',
    FirstWeek: 'music_ru_em',
    FirstMonth: 'music_binh_minh',
    HundredDays: 'music_tiec_vui',
    LittleMoments: 'music_nang_mai',
    WelcomeWorld: 'music_binh_minh',
    OurFirstDays: 'music_ru_em',
    LittleLoveStory: 'music_mo_mang',
    TinyMoments: 'music_nang_mai',
    GrowingSoFast: 'music_binh_minh',
    HelloSmile: 'music_nang_mai',
    FirstMilestone: 'music_tiec_vui',
    HundredDaysLove: 'music_binh_minh',
    HalfYear: 'music_binh_minh',
    LetterToBaby: 'music_ru_em',
    ThenAndNow: 'music_mo_mang',
    FirstBirthday: 'music_tiec_vui',
  };
  // `--chapter1`: the Chapter 01 cards (art from `--art`) and videos as well.
  const chapter1 = process.argv.includes('--chapter1');
  const art = JSON.parse(
    readFileSync(join(import.meta.dirname, '../../design/keepsake-art/assets.json'), 'utf8'),
  ) as Record<string, string>;
  const all = [
    ...keepsakeSeedV1.templates,
    ...(chapter1 ? [...chapter1Cards(art), ...keepsakeChapter1Videos] : []),
  ];
  const templates: KeepsakeTemplate[] = [];
  for (const t of all) {
    if (t.kind !== 'video' || !t.composition) {
      templates.push(t);
      continue;
    }
    const stem = t.id.replace('video_', '').replaceAll('_', '-');
    templates.push({
      ...t,
      defaultMusic: musicOf[t.composition],
      preview: await upload(join(dir, `${stem}.mp4`), stem, 'video/mp4'),
      // The cover lists show (portal and app): the frame the server's poster uses.
      thumb: await upload(join(dir, `${stem}-cover.webp`), `${stem}-cover`, 'image/webp'),
    });
  }
  const draft: KeepsakeCatalog = keepsakeCatalogSchema.parse({
    ...keepsakeSeedV1,
    music,
    templates,
  });
  const live = await get('publicConfig/keepsakes');
  const meta = await get('content/keepsakes');
  const highest = (meta?.highest as Record<string, number> | undefined) ?? {};
  const catalog = assignKeepsakeVersions(
    draft,
    // Parsed like the server does, so key order from REST does not count as a change.
    live ? { templates: keepsakeTemplateSchema.array().parse(live.templates ?? []) } : null,
    highest,
  );
  await patch('publicConfig/keepsakes', {
    version: 'ks_dev_media',
    publishedAt: new Date().toISOString(),
    templates: catalog.templates,
    premium: catalog.premium,
    music: catalog.music.map(publicKeepsakeMusic),
  });
  const nextHighest = { ...highest };
  for (const t of catalog.templates)
    nextHighest[t.id] = Math.max(nextHighest[t.id] ?? 0, t.version);
  await patch('content/keepsakes', { highest: nextHighest, music: catalog.music }, [
    'highest',
    'music',
  ]);
  console.log(
    `publicConfig/keepsakes: ${catalog.music.length} tracks, versions ${catalog.templates
      .map((t) => `${t.id}@${t.version}`)
      .join(' ')}`,
  );
}

if (process.argv.includes('--art')) {
  for (const a of await buildArt()) {
    await upload(
      `${a.name}.webp`,
      a.asset.replace(/_[a-f0-9]{8}\.webp$/, ''),
      'image/webp',
      a.bytes,
    );
  }
}
