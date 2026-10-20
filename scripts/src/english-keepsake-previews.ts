/** Dev-only locale migration for every CURRENT video template. No new template IDs or price changes.
 * --prepare downloads the published catalog/assets for the renderer; --publish atomically installs
 * completed English MP4s/posters while preserving Vietnamese assets and all unrelated staff data.
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { setDefaultResultOrder } from 'node:dns';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { keepsakePublicCatalogSchema, keepsakeTemplateAssets } from '@child-life/contracts';
setDefaultResultOrder('ipv4first');
const args = process.argv.slice(2),
  p = args.indexOf('--project');
if (p < 0 || args[p + 1] !== 'child-life-dev')
  throw new Error('Only --project child-life-dev is allowed');
const project = 'child-life-dev',
  bucket = `${project}.firebasestorage.app`;
const token = execFileSync('gcloud', ['auth', 'print-access-token'], { encoding: 'utf8' }).trim();
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const headers = {
  Authorization: `Bearer ${token}`,
  'x-goog-user-project': project,
  'Content-Type': 'application/json',
};
const out = resolve(import.meta.dirname, '../../artifacts/keepsake-english');
mkdirSync(out, { recursive: true });
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
  throw new Error('unsupported value');
}
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
async function get(path: string) {
  const r = await fetch(`${base}/${path}`, { headers });
  if (!r.ok) throw new Error(`read ${path}: ${r.status}`);
  const doc = (await r.json()) as {
    name: string;
    fields: Record<string, Record<string, unknown>>;
    updateTime: string;
  };
  return { doc, data: decode({ mapValue: { fields: doc.fields } }) as Record<string, unknown> };
}
async function upload(file: string, name: string, ext: string, type: string) {
  const bytes = readFileSync(file),
    asset = `${name.slice(0, 40)}_${createHash('sha256').update(bytes).digest('hex').slice(0, 8)}.${ext}`,
    boundary = 'englishPreviewAsset';
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
  if (!r.ok && r.status !== 412) throw new Error(`upload ${r.status}`);
  return asset;
}
if (args.includes('--prepare')) {
  const live = await get('publicConfig/keepsakes'),
    catalog = keepsakePublicCatalogSchema.parse(live.data);
  writeFileSync(join(out, 'catalog.json'), JSON.stringify(catalog, null, 2));
  const videos = catalog.templates.filter((t) => t.kind === 'video');
  const needed = videos.filter((t) => !t.previews?.en);
  const assets = new Set<string>();
  for (const t of needed) {
    for (const a of keepsakeTemplateAssets(t)) if (!a.endsWith('.mp4')) assets.add(a);
    const music = catalog.music.find((m) => m.id === t.defaultMusic);
    if (music) assets.add(music.asset);
  }
  for (const a of assets) {
    if (existsSync(join(out, a))) continue;
    const r = await fetch(
      `https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encodeURIComponent(`content/keepsakes/${a}`)}?alt=media`,
      { headers },
    );
    if (!r.ok) throw new Error(`download ${a}: ${r.status}`);
    writeFileSync(join(out, a), Buffer.from(await r.arrayBuffer()));
  }
  console.log(
    `Prepared ${needed.length} missing English previews; ${videos.length} video templates total.`,
  );
}
if (args.includes('--publish')) {
  const source = keepsakePublicCatalogSchema.parse(
    JSON.parse(readFileSync(join(out, 'catalog.json'), 'utf8')),
  );
  const expected = source.templates.filter((t) => t.kind === 'video' && !t.previews?.en);
  const uploaded = new Map<string, { preview: string; thumb: string }>();
  for (const t of expected) {
    const stem = join(out, `${t.id}-en`);
    if (!existsSync(`${stem}.mp4`) || !existsSync(`${stem}.webp`))
      throw new Error(`render missing: ${t.id}`);
    const name = `en-${t.id.replace(/^video_/, '').replaceAll('_', '-')}`;
    uploaded.set(t.id, {
      preview: await upload(`${stem}.mp4`, name, 'mp4', 'video/mp4'),
      thumb: await upload(`${stem}.webp`, `${name}-poster`, 'webp', 'image/webp'),
    });
  }
  const live = await get('publicConfig/keepsakes'),
    content = await get('content/keepsakes'),
    catalog = keepsakePublicCatalogSchema.parse(live.data);
  const highest = { ...((content.data.highest ?? {}) as Record<string, number>) };
  const templates = catalog.templates.map((t) => {
    const u = uploaded.get(t.id);
    if (!u) return t;
    const before = expected.find((s) => s.id === t.id)!;
    if (before.version !== t.version) throw new Error(`Template changed during render: ${t.id}`);
    const version = Math.max(t.version, highest[t.id] ?? 0) + 1;
    highest[t.id] = version;
    return {
      ...t,
      version,
      previews: { ...(t.preview ? { vi: t.preview } : {}), ...t.previews, en: u.preview },
      thumbs: { ...(t.thumb ? { vi: t.thumb } : {}), ...t.thumbs, en: u.thumb },
    };
  });
  if (templates.filter((t) => t.kind === 'video').some((t) => !t.previews?.en))
    throw new Error('Incomplete English coverage');
  const label = `ks_video_en_${Date.now()}`,
    published = { ...live.data, version: label, publishedAt: new Date().toISOString(), templates };
  const fields = (data: unknown) =>
    (encode(data) as { mapValue: { fields: unknown } }).mapValue.fields;
  writeFileSync(
    join(out, 'catalog-before.json'),
    JSON.stringify({ public: live.data, content: content.data }, null, 2),
  );
  const r = await fetch(`${base}:commit`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      writes: [
        {
          update: { name: live.doc.name, fields: fields(published) },
          currentDocument: { updateTime: live.doc.updateTime },
        },
        {
          update: { name: content.doc.name, fields: fields({ ...content.data, highest }) },
          currentDocument: { updateTime: content.doc.updateTime },
        },
      ],
    }),
  });
  if (!r.ok) throw new Error(`Atomic publish refused: ${r.status} ${await r.text()}`);
  writeFileSync(
    join(out, 'published.json'),
    JSON.stringify(
      {
        version: label,
        changed: [...uploaded.keys()],
        videos: templates
          .filter((t) => t.kind === 'video')
          .map((t) => ({ id: t.id, version: t.version, previews: t.previews, thumbs: t.thumbs })),
      },
      null,
      2,
    ),
  );
  console.log(
    `Published English previews for ${uploaded.size} existing videos; every ${templates.filter((t) => t.kind === 'video').length} video template now has an English MP4.`,
  );
}
if (args.includes('--verify')) {
  const live = await get('publicConfig/keepsakes');
  const catalog = keepsakePublicCatalogSchema.parse(live.data);
  const videos = catalog.templates.filter((t) => t.kind === 'video');
  const checked = [];
  for (const t of videos) {
    if (!t.previews?.en || !t.previews.vi || t.previews.en === t.previews.vi)
      throw new Error(`Missing distinct VI/EN MP4s: ${t.id}`);
    if (!t.thumbs?.en || !t.thumbs.vi) throw new Error(`Missing localized posters: ${t.id}`);
    for (const asset of [...Object.values(t.previews), ...Object.values(t.thumbs)]) {
      const url = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(`content/keepsakes/${asset}`)}?alt=media`;
      const response = await fetch(url, { headers: { Range: 'bytes=0-31' } });
      if (!response.ok) throw new Error(`Public preview unavailable: ${t.id} ${response.status}`);
      await response.arrayBuffer();
    }
    checked.push({ id: t.id, previews: t.previews, thumbs: t.thumbs });
  }
  writeFileSync(
    join(out, 'public-coverage.json'),
    JSON.stringify({ version: live.data.version, checked }, null, 2),
  );
  console.log(
    `Verified public VI/EN MP4s and posters for ${videos.length}/${videos.length} video templates.`,
  );
}
