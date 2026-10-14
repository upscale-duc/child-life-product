/**
 * The original art library (`design/keepsake-art/*.svg`) as catalog assets: each SVG rasterised to
 * a transparent WebP (twice its drawn size, at most the 2160 px card width; textures smaller and
 * softer) and named like `staffKeepsakesAsset` does, `art-{name}_{sha256[:8]}.webp`. Run alone it
 * writes `design/keepsake-art/assets.json` (name → asset), which the Chapter 01 templates use; the
 * same bytes are what `seed-keepsakes.ts --art` uploads, so the names always match.
 *   pnpm --filter child-life-scripts exec tsx src/keepsake-art.ts
 */
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

export const artDir = join(import.meta.dirname, '../../design/keepsake-art');

export interface ArtAsset {
  name: string;
  asset: string;
  bytes: Buffer;
}

export async function buildArt(): Promise<ArtAsset[]> {
  const { default: sharp } = await import('sharp');
  const out: ArtAsset[] = [];
  for (const file of readdirSync(artDir)
    .filter((f) => f.endsWith('.svg'))
    .sort()) {
    const name = file.replace(/\.svg$/, '');
    const svg = readFileSync(join(artDir, file));
    const meta = await sharp(svg).metadata();
    // Textures are noise and barely compress: smaller and softer (cards scale them up).
    const texture = name.includes('grain');
    const width = texture ? 1024 : Math.min(2160, (meta.width ?? 1000) * 2);
    const bytes = await sharp(svg, { density: texture ? 72 : 144 })
      .resize({ width })
      .webp({ quality: texture ? 55 : 90, alphaQuality: texture ? 60 : 100 })
      .toBuffer();
    const stem = `art-${name}`.slice(0, 40);
    const hash = createHash('sha256').update(bytes).digest('hex').slice(0, 8);
    out.push({ name, asset: `${stem}_${hash}.webp`, bytes });
  }
  return out;
}

if (import.meta.filename === process.argv[1]) {
  const art = await buildArt();
  writeFileSync(
    join(artDir, 'assets.json'),
    `${JSON.stringify(Object.fromEntries(art.map((a) => [a.name, a.asset])), null, 2)}\n`,
  );
  console.log(`${art.length} assets → design/keepsake-art/assets.json`);
}
