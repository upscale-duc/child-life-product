// Sơ cứu (D-058, P-141): publishes the seed guide on DEV — the Figma copy (vi) with an engineering
// English draft, content/first-aid/pack.seed.json, and the pictures in content/first-aid/images/.
// Prod is refused: there a pack goes live only after an expert approves it in the portal.
//
//   GOOGLE_CLOUD_QUOTA_PROJECT=child-life-dev node firebase/functions/scripts/seed-first-aid.mjs \
//     --project child-life-dev [--dry-run]
//
// Pictures are uploaded as `content/first-aid/{slug}_{sha8}.webp` (public, immutable); the pack's
// slugs become those ids. The draft (`content/firstAid`), a published version and
// `publicConfig/content_firstAid` are written together, as an approval would.
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import {
  firstAidImagePath,
  firstAidImages,
  firstAidPackSchema,
  firstAidPublicDocId,
} from '../../../packages/contracts/dist/first-aid.js';

const arg = (name) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const project = arg('project');
const dryRun = process.argv.includes('--dry-run');
if (project !== 'child-life-dev') {
  console.error('Seeding is for child-life-dev only; prod content is approved in the portal.');
  process.exit(1);
}

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..', 'content', 'first-aid');
const seed = JSON.parse(readFileSync(join(root, 'pack.seed.json'), 'utf8'));

// slug → id (content hash keeps ids stable while a picture is unchanged).
const ids = new Map();
const idOf = (slug) => {
  if (slug == null) return null;
  if (!ids.has(slug)) {
    const bytes = readFileSync(join(root, 'images', `${slug}.webp`));
    ids.set(slug, {
      id: `${slug}_${createHash('sha256').update(bytes).digest('hex').slice(0, 8)}`,
      bytes,
    });
  }
  return ids.get(slug).id;
};
const pack = {
  ...seed,
  situations: seed.situations.map((s) => ({
    ...s,
    icon: idOf(s.icon),
    hero: idOf(s.hero),
    variants: s.variants.map((v) => ({
      ...v,
      hero: idOf(v.hero),
      steps: v.steps.map((st) => ({ ...st, image: idOf(st.image) })),
    })),
  })),
  cpr: seed.cpr.map((c) => ({ ...c, image: idOf(c.image) })),
};
const parsed = firstAidPackSchema.parse(pack);
const images = firstAidImages(parsed);
console.log(
  `${parsed.situations.length} situations, ${images.length} pictures${dryRun ? ' (dry run)' : ''}`,
);
if (dryRun) process.exit(0);

initializeApp({ projectId: project, storageBucket: 'child-life-dev.firebasestorage.app' });
const bucket = getStorage().bucket();
let uploaded = 0;
for (const { id, bytes } of ids.values()) {
  const file = bucket.file(firstAidImagePath(id));
  const [exists] = await file.exists();
  if (exists) continue;
  await file.save(bytes, {
    contentType: 'image/webp',
    metadata: { cacheControl: 'public, max-age=31536000, immutable' },
  });
  uploaded++;
}

const db = getFirestore();
const now = new Date();
const day = now.toISOString().slice(0, 10).replace(/-/g, '');
const prev = await db.doc(`publicConfig/${firstAidPublicDocId}`).get();
const prevVersion = prev.get('version');
const n = prevVersion?.startsWith(`fa_${day}_`) ? Number(prevVersion.slice(-2)) + 1 : 1;
const version = `fa_${day}_${String(n).padStart(2, '0')}`;
const versionId = `fv_${createHash('sha256').update(version).digest('hex').slice(0, 16)}`;
const batch = db.batch();
// Same shape as an approval on the portal (content.ts): the seed stands in for both people.
const published = await db
  .collection('content/firstAid/versions')
  .where('status', '==', 'published')
  .get();
for (const p of published.docs) batch.update(p.ref, { status: 'retired', updatedAt: now });
batch.set(db.doc(`content/firstAid/versions/${versionId}`), {
  status: 'published',
  label: version,
  pack: parsed,
  notes: 'Seed from Figma v1.1 (dev only, not medically reviewed)',
  authorUid: 'seed',
  authorName: 'Seed (Figma v1.1)',
  approverUid: 'seed',
  approverName: 'Seed (dev)',
  createdAt: now,
  updatedAt: now,
  approvedAt: now,
  rejection: null,
});
batch.set(
  db.doc('content/firstAid'),
  { currentVersionId: versionId, updatedAt: now },
  { merge: true },
);
batch.set(db.doc(`publicConfig/${firstAidPublicDocId}`), {
  version,
  publishedAt: now.toISOString(),
  pack: parsed,
});
await batch.commit();
console.log(`published ${version}; uploaded ${uploaded} new pictures`);
