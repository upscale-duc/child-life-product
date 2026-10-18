// Content release: moves the editorial content between projects as a checked bundle.
//
//   export  reads what a project publishes (Sơ cứu, Nhịp lớn lên, Mẫu kỷ niệm, Dữ liệu tham chiếu,
//           Thư viện chăm bé, Giai đoạn, Mốc phát triển) and every picture / video / music file
//           those name, into a folder: bundle.json (validated) + assets/<storage path>.
//   seeds   builds the same bundle from the repo's seed files (content/, content-seed.ts).
//   import  puts a bundle into a project AS DRAFTS: assets are copied byte for byte (the ids are
//           content hashes, so they stay valid), each pack becomes its open draft, each article /
//           stage / milestone its Nháp under the same id. Nothing is approved or published: in the
//           portal someone other than the importer submits, approves and publishes, and on prod
//           approval still needs the qualified review (D-058, D-073 #2).
//
//   policy  sets the approval policy (D-079) as the Owner, with a reason, through the same function
//           as the portal's "Chính sách duyệt" (audited as content.policy).
//   publish takes every open draft through submit → approve → publish with the server's own
//           functions, as --as: the Owner alone when the policy allows it (D-079), and on prod
//           with no qualified review only when the policy turns that gate off (D-078 #6).
//
// Default is a dry run that prints the plan; --apply writes. Prod also needs
// CHILD_LIFE_PROD_APPROVED=yes (owner approval, as scripts/deploy.sh). Auth: gcloud ADC
// (`gcloud auth application-default login`); --as is the portal staff account the drafts are
// recorded under (it must be an active staff member with Nội dung · Sửa in the target project).
//
//   cd firebase/functions
//   pnpm exec tsx scripts/content-release.ts export --project child-life-dev --out ~/cl-bundles/2026-10-16
//   pnpm exec tsx scripts/content-release.ts seeds --out ~/cl-bundles/seeds
//   pnpm exec tsx scripts/content-release.ts policy --project child-life-dev --as you@childlife.app \
//     --self-approve on --review-on-prod off --reason "…" [--apply]
//   pnpm exec tsx scripts/content-release.ts publish --project child-life-dev --as you@childlife.app \
//     --reason "…" [--only …] [--apply]
//   pnpm exec tsx scripts/content-release.ts import --project child-life-prod \
//     --bundle ~/cl-bundles/2026-10-16 --as you@childlife.app [--only firstAid,articles] [--apply]
//
// Shared packages must be built first: pnpm --filter @child-life/contracts run build.
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  contentCollections,
  contentDraftsCollection,
  editorialChecks,
  contentImagePath,
  contentImages,
  firstAidImagePath,
  firstAidImages,
  firstAidPackSchema,
  firstAidPublicDocId,
  keepsakeAssetPath,
  keepsakeCatalogSchema,
  keepsakeTemplateAssets,
  referenceDatasets,
  referenceDocIds,
  referenceModelSchema,
  rhythmContentSchema,
  rhythmPublicDocIds,
  type ContentKind,
  type FirstAidPack,
  type KeepsakeCatalog,
  type ReferenceDataset,
} from '@child-life/contracts';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { firstAidAct, firstAidDraft } from '../src/content.js';
import { contentAct, contentImport, type ContentImportItem } from '../src/content-library.js';
import { readContentPolicy, setContentPolicy } from '../src/content-policy.js';
import { milestoneAdapter } from '../src/content-milestones.js';
import { seedArticles, seedStages } from '../src/content-seed.js';
import { keepsakeAct, keepsakeDraft } from '../src/keepsake-content.js';
import { referenceAct, referenceDraft } from '../src/reference-data.js';
import { rhythmAct, rhythmDraft } from '../src/rhythm-content.js';
import { resolveStaff } from '../src/staff-access.js';

type Data = Record<string, unknown>;
const sections = [
  'firstAid',
  'rhythm',
  'keepsakes',
  'reference',
  'articles',
  'stages',
  'milestones',
] as const;
type Section = (typeof sections)[number];
const kindOf: Record<'articles' | 'stages' | 'milestones', ContentKind> = {
  articles: 'article',
  stages: 'stage',
  milestones: 'milestone',
};

interface Asset {
  path: string;
  sha256: string;
  bytes: number;
  contentType: string;
}
interface Bundle {
  format: 'child-life-content@1';
  source: string;
  createdAt: string;
  firstAid: { version: string | null; pack: FirstAidPack } | null;
  rhythm: {
    reference: Data | null;
    content: Data | null;
    versions: Record<string, string | null>;
  } | null;
  keepsakes: { version: string | null; catalog: KeepsakeCatalog } | null;
  reference: Partial<Record<ReferenceDataset, { version: string; rows: unknown[] }>>;
  articles: ContentImportItem[];
  stages: ContentImportItem[];
  milestones: ContentImportItem[];
  assets: Asset[];
}

// ---------- arguments ----------

const [command, ...rest] = process.argv.slice(2);
const arg = (name: string) => {
  const i = rest.indexOf(`--${name}`);
  return i >= 0 ? rest[i + 1] : undefined;
};
const flag = (name: string) => rest.includes(`--${name}`);
const fail = (msg: string): never => {
  console.error(msg);
  process.exit(1);
};
const only = new Set<Section>((arg('only')?.split(',') as Section[] | undefined) ?? [...sections]);
for (const s of only) if (!sections.includes(s)) fail(`--only: unknown section "${s}"`);

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const sha256 = (b: Buffer) => createHash('sha256').update(b).digest('hex');
const typeOf = (path: string) =>
  path.endsWith('.webp')
    ? 'image/webp'
    : path.endsWith('.mp4')
      ? 'video/mp4'
      : path.endsWith('.m4a')
        ? 'audio/mp4'
        : path.endsWith('.mp3')
          ? 'audio/mpeg'
          : 'application/octet-stream';
const stable = (v: unknown): string =>
  Array.isArray(v)
    ? `[${v.map(stable).join(',')}]`
    : v && typeof v === 'object'
      ? `{${Object.keys(v)
          .sort()
          .map((k) => `${JSON.stringify(k)}:${stable((v as Data)[k])}`)
          .join(',')}}`
      : JSON.stringify(v);
const same = (a: unknown, b: unknown) => stable(a) === stable(b);
const without = (d: Data, keys: string[]) =>
  Object.fromEntries(Object.entries(d).filter(([k]) => !keys.includes(k)));
const publishedMeta = [
  'id',
  'status',
  'revision',
  'review',
  'illustrative',
  'reviewDueOn',
  'publishedAt',
  'firstPublishedAt',
];

function connect(project: string) {
  if (!/^child-life-(dev|prod)$|^demo-/.test(project)) fail(`Unknown project ${project}`);
  process.env.GOOGLE_CLOUD_QUOTA_PROJECT ??= project;
  initializeApp({ projectId: project, storageBucket: `${project}.firebasestorage.app` });
  return { db: getFirestore(), bucket: getStorage().bucket() };
}

/** Every storage object the bundle's content names. */
function assetPaths(b: Bundle): string[] {
  const out = new Set<string>();
  if (b.firstAid) for (const id of firstAidImages(b.firstAid.pack)) out.add(firstAidImagePath(id));
  if (b.keepsakes) {
    for (const t of b.keepsakes.catalog.templates)
      for (const a of keepsakeTemplateAssets(t)) out.add(keepsakeAssetPath(a));
    for (const m of b.keepsakes.catalog.music) out.add(keepsakeAssetPath(m.asset));
  }
  for (const item of [...b.articles, ...b.stages, ...b.milestones])
    for (const id of contentImages(item.kind, item.data)) out.add(contentImagePath(id));
  return [...out].sort();
}

/** Schema checks shared by export, seeds and import (the server checks them again). */
function validate(b: Bundle) {
  if (b.format !== 'child-life-content@1') fail('Not a content bundle (format)');
  if (b.firstAid) firstAidPackSchema.parse(b.firstAid.pack);
  if (b.rhythm?.reference)
    referenceModelSchema.omit({ version: true, publishedAt: true }).parse(b.rhythm.reference);
  if (b.rhythm?.content)
    rhythmContentSchema.omit({ version: true, publishedAt: true }).parse(b.rhythm.content);
  if (b.keepsakes) keepsakeCatalogSchema.parse(b.keepsakes.catalog);
  const ids = new Set<string>();
  for (const item of [...b.articles, ...b.stages, ...b.milestones]) {
    if (ids.has(item.id)) fail(`Duplicate id ${item.id}`);
    ids.add(item.id);
  }
}

function writeBundle(out: string, b: Bundle, files: Map<string, Buffer>) {
  validate(b);
  for (const [path, bytes] of files) {
    const to = join(out, 'assets', path);
    mkdirSync(dirname(to), { recursive: true });
    writeFileSync(to, bytes);
  }
  b.assets = assetPaths(b).map((path) => {
    const bytes = files.get(path);
    if (!bytes) return fail(`Missing asset ${path}`);
    return { path, sha256: sha256(bytes), bytes: bytes.length, contentType: typeOf(path) };
  });
  writeFileSync(join(out, 'bundle.json'), `${JSON.stringify(b, null, 1)}\n`);
  const mb = b.assets.reduce((n, a) => n + a.bytes, 0) / 1e6;
  console.log(
    `Bundle ${out}: first aid ${b.firstAid ? `${b.firstAid.pack.situations.length} situations` : '—'}, ` +
      `rhythm ${b.rhythm ? 'yes' : '—'}, keepsakes ${b.keepsakes?.catalog.templates.length ?? '—'} templates, ` +
      `reference ${Object.keys(b.reference).length} tables, ${b.articles.length} articles, ` +
      `${b.stages.length} stages, ${b.milestones.length} milestones, ${b.assets.length} assets (${mb.toFixed(1)} MB)`,
  );
}

const emptyBundle = (source: string): Bundle => ({
  format: 'child-life-content@1',
  source,
  createdAt: new Date().toISOString(),
  firstAid: null,
  rhythm: null,
  keepsakes: null,
  reference: {},
  articles: [],
  stages: [],
  milestones: [],
  assets: [],
});

// ---------- export (a live project → bundle) ----------

async function exportProject(project: string, out: string) {
  const { db, bucket } = connect(project);
  const b = emptyBundle(project);
  const doc = async (path: string) => (await db.doc(path).get()).data() ?? null;

  if (only.has('firstAid')) {
    const pub = await doc(`publicConfig/${firstAidPublicDocId}`);
    if (pub) b.firstAid = { version: pub.version as string, pack: pub.pack as FirstAidPack };
  }
  if (only.has('rhythm')) {
    const ref = await doc(`publicConfig/${rhythmPublicDocIds.reference}`);
    const con = await doc(`publicConfig/${rhythmPublicDocIds.content}`);
    b.rhythm = {
      reference: ref ? without(ref, ['version', 'publishedAt']) : null,
      content: con ? without(con, ['version', 'publishedAt']) : null,
      versions: {
        reference: (ref?.version as string) ?? null,
        content: (con?.version as string) ?? null,
      },
    };
  }
  if (only.has('keepsakes')) {
    const pub = await doc('publicConfig/keepsakes');
    const meta = await doc('content/keepsakes');
    if (pub) {
      b.keepsakes = {
        version: pub.version as string,
        // The licences are kept for staff in content/keepsakes, never in publicConfig.
        catalog: keepsakeCatalogSchema.parse({
          templates: pub.templates,
          premium: pub.premium,
          music: meta?.music ?? [],
        }),
      };
    }
  }
  if (only.has('reference')) {
    for (const dataset of referenceDatasets) {
      const pub = await doc(`publicConfig/${referenceDocIds[dataset]}`);
      // No published version = the built-in v1 every project ships; nothing to carry.
      if (pub)
        b.reference[dataset] = { version: pub.version as string, rows: pub.rows as unknown[] };
    }
  }
  for (const section of ['articles', 'stages', 'milestones'] as const) {
    if (!only.has(section)) continue;
    const kind = kindOf[section];
    const [pubs, drafts] = await Promise.all([
      db.collection(contentCollections[kind]).get(),
      db.collection(contentDraftsCollection).where('kind', '==', kind).get(),
    ]);
    const labels = new Map(
      drafts.docs.map((d) => [d.id, (d.get('reviewerLabel') as string | null) ?? null]),
    );
    // What the app shows: the published revision (a newer unpublished draft stays behind).
    b[section] = pubs.docs
      .filter((d) => d.get('status') === 'published')
      .map((d) => ({
        kind,
        id: d.id,
        reviewerLabel: labels.get(d.id) ?? null,
        data: without(d.data(), publishedMeta),
      }))
      .sort((x, y) => x.id.localeCompare(y.id));
  }

  const files = new Map<string, Buffer>();
  for (const path of assetPaths(b)) {
    const [bytes] = await bucket.file(path).download();
    files.set(path, bytes);
  }
  mkdirSync(out, { recursive: true });
  writeBundle(out, b, files);
}

// ---------- seeds (the repo → bundle) ----------

function seedsBundle(out: string) {
  const b = emptyBundle('repo seeds');
  const files = new Map<string, Buffer>();
  const read = (p: string) => JSON.parse(readFileSync(join(repo, p), 'utf8')) as Data;

  if (only.has('firstAid')) {
    // The seed names pictures by slug; ids are `{slug}_{sha8}` of content/first-aid/images/*.webp.
    const seed = read('content/first-aid/pack.seed.json') as unknown as FirstAidPack;
    const idOf = (slug: string | null) => {
      if (slug == null) return null;
      const bytes = readFileSync(join(repo, 'content/first-aid/images', `${slug}.webp`));
      const id = `${slug}_${sha256(bytes).slice(0, 8)}`;
      files.set(firstAidImagePath(id), bytes);
      return id;
    };
    const pack = {
      ...seed,
      situations: seed.situations.map((s) => ({
        ...s,
        icon: idOf(s.icon)!,
        hero: idOf(s.hero)!,
        variants: s.variants.map((v) => ({
          ...v,
          hero: idOf(v.hero),
          steps: v.steps.map((st) => ({ ...st, image: idOf(st.image) })),
        })),
      })),
      cpr: seed.cpr.map((c) => ({ ...c, image: idOf(c.image) })),
    };
    b.firstAid = { version: null, pack: firstAidPackSchema.parse(pack) };
  }
  if (only.has('rhythm')) {
    b.rhythm = {
      reference: without(read('content/rhythm/reference.seed.json'), ['version', 'publishedAt']),
      content: without(read('content/rhythm/content.seed.json'), ['version', 'publishedAt']),
      versions: { reference: null, content: null },
    };
  }
  if (only.has('articles'))
    b.articles = seedArticles.map((s) => ({
      kind: 'article',
      ...s,
      data: s.data as unknown as Data,
    }));
  if (only.has('stages'))
    b.stages = seedStages.map((s) => ({ kind: 'stage', ...s, data: s.data as unknown as Data }));
  if (only.has('milestones')) {
    const seed = milestoneAdapter.seed(read('content/milestones/milestones.seed.json'));
    if (!seed) fail('content/milestones/milestones.seed.json does not match milestoneSeedSchema');
    b.milestones = seed!.map((s) => ({ kind: 'milestone', ...s }));
  }
  // Keepsakes and reference tables have no repo seed in this format: export them from a project.
  only.delete('keepsakes');
  only.delete('reference');
  mkdirSync(out, { recursive: true });
  writeBundle(out, b, files);
}

// ---------- import (bundle → a project, as drafts) ----------

async function importBundle(project: string, dir: string, as: string, apply: boolean) {
  const b = JSON.parse(readFileSync(join(dir, 'bundle.json'), 'utf8')) as Bundle;
  validate(b);
  if (apply && project === 'child-life-prod' && process.env.CHILD_LIFE_PROD_APPROVED !== 'yes') {
    fail('Importing to prod needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run.');
  }
  const { db, bucket } = connect(project);
  const now = new Date();
  const user = await getAuth()
    .getUserByEmail(as)
    .catch(() => fail(`No account ${as} in ${project}`));
  const staff = await resolveStaff(db, { uid: user.uid, token: user.customClaims ?? {} }, now);
  if (!staff) fail(`${as} is not active staff in ${project}`);
  const notes = `Nhập từ gói nội dung ${b.source} (${b.createdAt.slice(0, 10)}) · chờ duyệt`;
  const mode = apply ? 'APPLY' : 'DRY RUN';
  console.log(`${mode}: ${dir} → ${project} as ${staff!.name}`);

  // 1. Assets, byte for byte (an object with the same name is the same content: names are hashes).
  const wanted = new Set(assetPaths(b));
  let uploaded = 0;
  for (const a of b.assets.filter((x) => wanted.has(x.path))) {
    const file = bucket.file(a.path);
    if ((await file.exists())[0]) continue;
    const bytes = readFileSync(join(dir, 'assets', a.path));
    if (sha256(bytes) !== a.sha256) fail(`Asset changed since export: ${a.path}`);
    uploaded++;
    if (apply) {
      await file.save(bytes, {
        contentType: a.contentType,
        metadata: { cacheControl: 'public, max-age=31536000, immutable' },
      });
    }
  }
  console.log(`assets: ${uploaded} to upload, ${wanted.size - uploaded} already there`);

  const openDraft = async (path: string, where?: [string, string]) => {
    let q = db.collection(path).where('status', 'in', ['draft', 'pending']);
    if (where) q = q.where(where[0], '==', where[1]);
    return (await q.limit(1).get()).docs[0] ?? null;
  };
  const replaceOpen = flag('replace-open-drafts');
  const blocked = (what: string) =>
    console.log(
      `${what}: SKIPPED, the project has an open draft (finish it, or pass --replace-open-drafts)`,
    );
  const doc = async (path: string) => (await db.doc(path).get()).data() ?? null;

  // 2. Packs: each becomes the open draft (the draft functions check every picture exists).
  if (only.has('firstAid') && b.firstAid) {
    const pub = await doc(`publicConfig/${firstAidPublicDocId}`);
    if (pub && same(pub.pack, b.firstAid.pack)) console.log('first aid: same as published');
    else if ((await openDraft('content/firstAid/versions')) && !replaceOpen) blocked('first aid');
    else {
      console.log(`first aid: draft of ${b.firstAid.pack.situations.length} situations`);
      if (apply)
        await firstAidDraft(
          db,
          { requireReview: true, images: imageStore(bucket, 'content/first-aid/') },
          staff,
          { pack: b.firstAid.pack, notes },
          now,
        );
    }
  }
  if (only.has('rhythm') && b.rhythm) {
    for (const d of ['reference', 'content'] as const) {
      const data = b.rhythm[d];
      if (!data) continue;
      const pub = await doc(`publicConfig/${rhythmPublicDocIds[d]}`);
      if (pub && same(without(pub, ['version', 'publishedAt']), data))
        console.log(`rhythm ${d}: same as published`);
      else if ((await openDraft(`content/rhythm/${d}`)) && !replaceOpen) blocked(`rhythm ${d}`);
      else {
        console.log(`rhythm ${d}: draft`);
        if (apply) await rhythmDraft(db, staff, { doc: d, data, notes }, now);
      }
    }
  }
  if (only.has('keepsakes') && b.keepsakes) {
    const pub = await doc('publicConfig/keepsakes');
    if (
      pub &&
      same(pub.templates, b.keepsakes.catalog.templates) &&
      same(pub.premium, b.keepsakes.catalog.premium)
    ) {
      console.log('keepsakes: same as published');
    } else if ((await openDraft('content/keepsakes/versions')) && !replaceOpen)
      blocked('keepsakes');
    else {
      console.log(`keepsakes: draft of ${b.keepsakes.catalog.templates.length} templates`);
      // Based on the target's release, so approval does not refuse it as stale.
      const draft = {
        catalog: b.keepsakes.catalog,
        notes,
        basedOn: (pub?.version as string | undefined) ?? null,
      };
      if (apply) await keepsakeDraft(db, { assets: assetStore(bucket) }, staff, draft, now);
    }
  }
  if (only.has('reference')) {
    for (const [dataset, t] of Object.entries(b.reference) as [
      ReferenceDataset,
      { rows: unknown[] },
    ][]) {
      const pub = await doc(`publicConfig/${referenceDocIds[dataset]}`);
      if (pub && same(pub.rows, t.rows)) console.log(`reference ${dataset}: same as published`);
      else if ((await openDraft(`referenceData/${dataset}/versions`)) && !replaceOpen)
        blocked(`reference ${dataset}`);
      else {
        console.log(`reference ${dataset}: draft of ${t.rows.length} rows`);
        if (apply)
          await referenceDraft(db, staff, { dataset, rows: t.rows, notes, source: 'edit' }, now);
      }
    }
  }

  // 3. Articles, stages, milestones: Nháp under the same ids.
  const items = (['articles', 'stages', 'milestones'] as const)
    .filter((s) => only.has(s))
    .flatMap((s) => b[s]);
  if (items.length) {
    const deps = { requireReview: true, images: imageStore(bucket, 'content/library/') };
    const result = await contentImport(db, deps, staff, items, now, { notes, dryRun: !apply });
    const by = (o: string) => result.filter((r) => r.outcome === o);
    console.log(
      `library: ${by('added').length} new, ${by('updated').length} changed, ${by('same').length} unchanged, ` +
        `${by('busy').length} skipped (waiting for review or approved)`,
    );
    for (const r of by('busy')) console.log(`  busy: ${r.kind} ${r.id}`);
  }
  console.log(
    apply
      ? `Done. In the ${project} portal, submit, approve and publish: someone other than ${staff!.name}, or the Owner alone when "Chính sách duyệt" allows it (D-079); prod needs the qualified review unless the policy turns it off.`
      : 'Dry run only: nothing was written. Re-run with --apply.',
  );
}

async function staffFor(db: ReturnType<typeof getFirestore>, project: string, as: string) {
  const user = await getAuth()
    .getUserByEmail(as)
    .catch(() => fail(`No account ${as} in ${project}`));
  const staff = await resolveStaff(
    db,
    { uid: user.uid, token: user.customClaims ?? {} },
    new Date(),
  );
  if (!staff) fail(`${as} is not active staff in ${project}`);
  return staff!;
}

const onOff = (name: string) => {
  const v = arg(name);
  if (v === undefined) return undefined;
  if (v !== 'on' && v !== 'off') fail(`--${name} on|off`);
  return v === 'on';
};

/** `policy`: the Owner's "Chính sách duyệt" switches (D-079), audited like the portal. */
async function setPolicy(project: string, as: string, apply: boolean) {
  const reason = arg('reason');
  if (!reason) fail('policy needs --reason "…" (written to the audit log)');
  if (apply && project === 'child-life-prod' && process.env.CHILD_LIFE_PROD_APPROVED !== 'yes') {
    fail('Changing prod needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run.');
  }
  const { db } = connect(project);
  const staff = await staffFor(db, project, as);
  const change = {
    ownerSelfApprove: onOff('self-approve'),
    reviewRequiredOnProd: onOff('review-on-prod'),
  };
  console.log(`${apply ? 'APPLY' : 'DRY RUN'}: ${project} policy now`, await readContentPolicy(db));
  console.log('change to', change, 'as', staff.name);
  if (apply)
    console.log('saved', await setContentPolicy(db, staff, { ...change, reason }, new Date()));
}

/** `publish`: every open draft through submit → approve → publish, with the server's functions. */
async function publishAll(project: string, as: string, apply: boolean) {
  const reason = arg('reason');
  if (!reason || reason.trim().length < 3)
    fail('publish needs --reason "…" (written to the audit log)');
  const prod = project === 'child-life-prod';
  if (apply && prod && process.env.CHILD_LIFE_PROD_APPROVED !== 'yes') {
    fail('Publishing to prod needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run.');
  }
  const { db, bucket } = connect(project);
  const staff = await staffFor(db, project, as);
  const policy = await readContentPolicy(db);
  console.log(`${apply ? 'APPLY' : 'DRY RUN'}: publish on ${project} as ${staff.name}`, policy);
  const now = () => new Date();
  const done: string[] = [];
  const step = async (label: string, run: () => Promise<unknown>) => {
    done.push(label);
    if (apply) await run();
  };
  const open = async (path: string) =>
    (await db.collection(path).where('status', 'in', ['draft', 'pending']).get()).docs;

  if (only.has('firstAid')) {
    const deps = { requireReview: prod, images: imageStore(bucket, 'content/first-aid/') };
    for (const v of await open('content/firstAid/versions')) {
      const act = (action: string) =>
        firstAidAct(db, deps, staff, { versionId: v.id, action, reason, review: null }, now());
      if (v.get('status') === 'draft') await step(`first aid ${v.id}: submit`, () => act('submit'));
      await step(`first aid ${v.id}: approve and publish`, () => act('approve'));
    }
  }
  if (only.has('rhythm')) {
    for (const d of ['reference', 'content'] as const) {
      for (const v of await open(`content/rhythm/${d}`)) {
        const act = (action: string) =>
          rhythmAct(
            db,
            { requireReview: prod },
            staff,
            { doc: d, versionId: v.id, action, reason, review: null },
            now(),
          );
        if (v.get('status') === 'draft')
          await step(`rhythm ${d} ${v.id}: submit`, () => act('submit'));
        await step(`rhythm ${d} ${v.id}: approve and publish`, () => act('approve'));
      }
    }
  }
  if (only.has('keepsakes')) {
    for (const v of await open('content/keepsakes/versions')) {
      const act = (action: string) =>
        keepsakeAct(db, staff, { versionId: v.id, action, reason }, now());
      if (v.get('status') === 'draft') await step(`keepsakes ${v.id}: submit`, () => act('submit'));
      await step(`keepsakes ${v.id}: approve and publish`, () => act('approve'));
    }
  }
  if (only.has('reference')) {
    for (const dataset of referenceDatasets) {
      for (const v of await open(`referenceData/${dataset}/versions`)) {
        const act = (action: string) =>
          referenceAct(db, staff, { versionId: v.id, action, reason }, now());
        if (v.get('status') === 'draft')
          await step(`reference ${dataset} ${v.id}: submit`, () => act('submit'));
        await step(`reference ${dataset} ${v.id}: approve and publish`, () => act('approve'));
      }
    }
  }
  const kinds = (['articles', 'stages', 'milestones'] as const)
    .filter((x) => only.has(x))
    .map((x) => kindOf[x]);
  if (kinds.length) {
    const deps = { requireReview: prod, images: imageStore(bucket, 'content/library/') };
    const drafts = await db
      .collection(contentDraftsCollection)
      .where('status', 'in', ['draft', 'in_review', 'approved'])
      .get();
    for (const d of drafts.docs.filter((x) => kinds.includes(x.get('kind') as ContentKind))) {
      const kind = d.get('kind') as ContentKind;
      const act = (action: string, extra: Data = {}) =>
        contentAct(db, deps, staff, { kind, id: d.id, action, reason, ...extra }, now());
      const status = d.get('status') as string;
      if (status === 'draft') await step(`${kind} ${d.id}: submit`, () => act('submit'));
      if (status !== 'approved') {
        await step(`${kind} ${d.id}: approve`, () =>
          act('approve', { checks: [...editorialChecks] }),
        );
      }
      await step(`${kind} ${d.id}: publish`, () => act('publish'));
    }
  }
  const count = (w: string) => done.filter((x) => x.endsWith(w)).length;
  console.log(
    `${done.length} steps: ${count('submit')} submit, ${count('approve')} approve, ` +
      `${count('approve and publish')} approve and publish, ${count('publish')} publish`,
  );
  if (process.env.VERBOSE) for (const x of done) console.log(`  ${x}`);
  console.log(apply ? 'Done.' : 'Dry run only: nothing was written. Re-run with --apply.');
}

function imageStore(bucket: ReturnType<ReturnType<typeof getStorage>['bucket']>, prefix: string) {
  const path = (id: string) => `${prefix}${id}.webp`;
  return {
    exists: async (id: string) => (await bucket.file(path(id)).exists())[0],
    save: () => fail('not used'),
    list: async () => [],
    publicUrl: (id: string) => path(id),
    encode: () => fail('not used'),
  } as unknown as Parameters<typeof firstAidDraft>[1]['images'];
}
function assetStore(bucket: ReturnType<ReturnType<typeof getStorage>['bucket']>) {
  return {
    exists: async (asset: string) => (await bucket.file(keepsakeAssetPath(asset)).exists())[0],
  } as unknown as Parameters<typeof keepsakeDraft>[1]['assets'];
}

// ---------- main ----------

const out = arg('out');
if (command === 'export') {
  if (!arg('project') || !out) fail('export --project <id> --out <dir> [--only …]');
  if (existsSync(join(out!, 'bundle.json'))) fail(`${out} already holds a bundle`);
  await exportProject(arg('project')!, out!);
} else if (command === 'seeds') {
  if (!out) fail('seeds --out <dir> [--only …]');
  if (existsSync(join(out!, 'bundle.json'))) fail(`${out} already holds a bundle`);
  seedsBundle(out!);
} else if (command === 'import') {
  if (!arg('project') || !arg('bundle') || !arg('as')) {
    fail(
      'import --project <id> --bundle <dir> --as <staff email> [--only …] [--apply] [--replace-open-drafts]',
    );
  }
  await importBundle(arg('project')!, arg('bundle')!, arg('as')!, flag('apply'));
} else if (command === 'policy') {
  if (!arg('project') || !arg('as')) {
    fail(
      'policy --project <id> --as <owner email> [--self-approve on|off] [--review-on-prod on|off] --reason "…" [--apply]',
    );
  }
  await setPolicy(arg('project')!, arg('as')!, flag('apply'));
} else if (command === 'publish') {
  if (!arg('project') || !arg('as')) {
    fail('publish --project <id> --as <staff email> --reason "…" [--only …] [--apply]');
  }
  await publishAll(arg('project')!, arg('as')!, flag('apply'));
} else {
  fail('Usage: content-release.ts export | seeds | import | policy | publish (see the header)');
}
