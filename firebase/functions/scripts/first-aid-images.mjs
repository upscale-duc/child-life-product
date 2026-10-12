// Sơ cứu (D-058): turns the Figma exports in content/first-aid/source/ (original PNG fills and
// SVG pictograms, kept out of git) into the WebP files committed in content/first-aid/images/,
// which the seed uploads to Storage `content/first-aid/{slug}_{hash}.webp`.
//   node firebase/functions/scripts/first-aid-images.mjs
import { mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(join(here, '..', 'package.json'));
const sharp = require('sharp');
const root = join(here, '..', '..', '..', 'content', 'first-aid');
const out = join(root, 'images');
mkdirSync(out, { recursive: true });

// Two pictures on the photo_demo sheet that no frame places, used for authored variants.
const extras = {
  'pastel-clay-child-cpr-demonstration.png': 'ep-tim-tre-lon',
  'ring-gauze-pad-for-a-splinter.png': 'vong-gac-di-vat',
};

let n = 0;
const ills = join(root, 'source', 'illustrations');
for (const f of readdirSync(ills).filter((f) => f.endsWith('.png'))) {
  const slug = f.replace(/\.png$/, '');
  writeFileSync(
    join(out, `${slug}.webp`),
    await sharp(join(ills, f)).resize({ width: 1200 }).webp({ quality: 78 }).toBuffer(),
  );
  n++;
}
for (const [f, slug] of Object.entries(extras)) {
  writeFileSync(
    join(out, `${slug}.webp`),
    await sharp(join(ills, 'unused', f))
      .resize({ width: 1200 })
      .webp({ quality: 78 })
      .toBuffer(),
  );
  n++;
}
const icons = join(root, 'source', 'icons');
for (const f of readdirSync(icons).filter((f) => f.endsWith('.svg'))) {
  const slug = `icon-${f.replace(/\.svg$/, '')}`;
  writeFileSync(
    join(out, `${slug}.webp`),
    await sharp(join(icons, f), { density: 600 })
      .resize(176, 176, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .webp({ quality: 90 })
      .toBuffer(),
  );
  n++;
}
console.log(`${n} images in content/first-aid/images`);
