import { createHash, randomBytes } from 'node:crypto';
import {
  assignKeepsakeVersions,
  defaultKeepsakePremium,
  keepsakeActSchema,
  keepsakeCatalogSchema,
  keepsakePublicCatalogSchema,
  publicKeepsakeMusic,
  keepsakeDraftSchema,
  keepsakeTemplateAssets,
  keepsakeUploadAssetSchema,
  type KeepsakeCatalog,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';
import { mayApproveOwn, readContentPolicy } from './content-policy.js';

/**
 * Mẫu kỷ niệm on the portal (D-068 #7: template artwork is controlled and distributed from the
 * portal, never built into the app). The same workflow as Sơ cứu (D-058, `content.ts`): one open
 * version of the whole catalog (Nháp or Chờ duyệt) under `content/keepsakes/versions`; a
 * different person with "Nội dung · Duyệt" approves, and approval publishes the catalog to
 * `publicConfig/keepsakes` in the same transaction, giving every changed template its next
 * version number (`assignKeepsakeVersions`; `highest` on `content/keepsakes` remembers the
 * numbers ever used, so a rollback never reuses one). Assets are stored once, named by content
 * hash, public and immutable at `content/keepsakes/{asset}`: template artwork and music, never
 * child media. Every step is in the audit log.
 */

export interface KeepsakeAssetStore {
  exists(asset: string): Promise<boolean>;
  save(asset: string, bytes: Buffer, contentType: string): Promise<void>;
  list(): Promise<string[]>;
  publicUrl(asset: string): string;
  /** PNG / JPEG / WebP in, WebP out (at most the card export width, alpha kept). */
  encodeImage(bytes: Buffer): Promise<Buffer>;
  /** A large upload under `content/keepsakes-incoming/` (staff only, Storage Rules). */
  readIncoming(path: string): Promise<Buffer | null>;
  deleteIncoming(path: string): Promise<void>;
}

export interface KeepsakeContentDeps {
  assets: KeepsakeAssetStore;
}

const root = (db: Firestore) => db.doc('content/keepsakes');
const versions = (db: Firestore) => root(db).collection('versions');
const publicDoc = (db: Firestore) => db.doc('publicConfig/keepsakes');
const iso = (v: unknown) =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;

function versionView(d: DocumentSnapshot) {
  return {
    versionId: d.id,
    status: d.get('status') as string,
    label: (d.get('label') as string | null | undefined) ?? null,
    notes: (d.get('notes') as string | undefined) ?? '',
    authorName: (d.get('authorName') as string | undefined) ?? '',
    approverName: (d.get('approverName') as string | null | undefined) ?? null,
    createdAt: iso(d.get('createdAt')),
    updatedAt: iso(d.get('updatedAt')),
    approvedAt: iso(d.get('approvedAt')),
    rejection: (d.get('rejection') as { by: string; reason: string } | null | undefined) ?? null,
    basedOn: (d.get('basedOn') as string | null | undefined) ?? null,
    templates: ((d.get('catalog') as KeepsakeCatalog | undefined)?.templates ?? []).length,
  };
}

/** The newest render jobs the usage counts read (one scan on the existing createdAt index). */
export const TEMPLATE_USAGE_SCAN = 5000;

/**
 * Videos exported per template (/keepsakes sort "most → least"): completed render jobs all time
 * and in the last 30 days, from ONE scan of the newest [TEMPLATE_USAGE_SCAN] jobs across families
 * (`keepsakeJobs` collection group, the `createdAt` index `staffRenderOps` already uses; only
 * `templateId`, `status` and `finishedAt` are read). `capped`: more jobs exist, so all-time counts
 * are a floor; the 30-day counts stay exact unless that many jobs started in 30 days.
 */
export async function templateUsage(db: Firestore, now: Date) {
  const snap = await db
    .collectionGroup('keepsakeJobs')
    .orderBy('createdAt', 'desc')
    .limit(TEMPLATE_USAGE_SCAN)
    .select('templateId', 'status', 'finishedAt')
    .get();
  const since = now.getTime() - 30 * 86_400_000;
  const usage: Record<string, { exports: number; exports30d: number }> = {};
  for (const d of snap.docs) {
    if (d.get('status') !== 'completed') continue;
    const id = d.get('templateId') as string | undefined;
    if (!id) continue;
    const row = (usage[id] ??= { exports: 0, exports30d: 0 });
    row.exports += 1;
    const finished = d.get('finishedAt') as Timestamp | Date | null | undefined;
    const at = finished instanceof Timestamp ? finished.toMillis() : (finished?.getTime?.() ?? 0);
    if (at >= since) row.exports30d += 1;
  }
  return { usage, capped: snap.size >= TEMPLATE_USAGE_SCAN };
}

async function openVersion(db: Firestore) {
  const snap = await versions(db).where('status', 'in', ['draft', 'pending']).limit(1).get();
  return snap.docs[0] ?? null;
}

/**
 * What the portal's Mẫu kỷ niệm screen shows: in use, the open version, history, assets, and per
 * video template id the videos exported (`usage[templateId]`: all time and last 30 days; a
 * template with none, and every card, is absent).
 */
export async function keepsakeView(
  db: Firestore,
  deps: KeepsakeContentDeps,
  staff: Staff | null,
  now: Date = new Date(),
) {
  requireStaff(staff, 'content.view');
  const [pub, meta, open, history, assets, usage] = await Promise.all([
    publicDoc(db).get(),
    root(db).get(),
    openVersion(db),
    versions(db).orderBy('createdAt', 'desc').limit(20).get(),
    deps.assets.list(),
    templateUsage(db, now),
  ]);
  return {
    usage: usage.usage,
    usageCapped: usage.capped,
    current: pub.exists
      ? {
          version: pub.get('version') as string,
          publishedAt: pub.get('publishedAt') as string,
          catalog: {
            templates: pub.get('templates') as KeepsakeCatalog['templates'],
            premium: (pub.get('premium') as KeepsakeCatalog['premium'] | undefined) ?? {
              ...defaultKeepsakePremium,
            },
            // With their licence (kept for staff in `content/keepsakes`, never in publicConfig).
            music: (meta.get('music') as KeepsakeCatalog['music'] | undefined) ?? [],
          },
        }
      : null,
    draft: open ? { ...versionView(open), catalog: open.get('catalog') as KeepsakeCatalog } : null,
    history: history.docs.map(versionView),
    assets: assets.map((asset) => ({ asset, url: deps.assets.publicUrl(asset) })),
  };
}

/** Save the open draft (or start one). Every asset it names must already be uploaded. */
export async function keepsakeDraft(
  db: Firestore,
  deps: KeepsakeContentDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(keepsakeDraftSchema, data);
  const used = [
    ...req.catalog.templates.flatMap(keepsakeTemplateAssets),
    ...req.catalog.music.map((m) => m.asset),
  ];
  for (const asset of new Set(used)) {
    if (!(await deps.assets.exists(asset))) {
      throw new StaffError('failed-precondition', 'asset-missing');
    }
  }
  return db.runTransaction(async (tx) => {
    const open = await tx.get(versions(db).where('status', 'in', ['draft', 'pending']).limit(1));
    const ref = open.docs[0]?.ref ?? versions(db).doc(`kv_${randomBytes(8).toString('hex')}`);
    if (open.docs[0]) {
      // Editing a version under review withdraws it: the reviewer must see what they approve.
      tx.update(ref, {
        catalog: req.catalog,
        notes: req.notes,
        status: 'draft',
        rejection: null,
        updatedAt: now,
        ...(req.basedOn !== undefined ? { basedOn: req.basedOn } : {}),
      });
    } else {
      tx.create(ref, {
        status: 'draft',
        catalog: req.catalog,
        notes: req.notes,
        authorUid: s.uid,
        authorName: s.name,
        createdAt: now,
        updatedAt: now,
        label: null,
        rejection: null,
        basedOn: req.basedOn ?? null,
      });
    }
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'content.keepsakes.draft',
        category: 'content',
        target: 'keepsakes',
        reason: null,
        detail: { templates: req.catalog.templates.length },
      },
      now,
    );
    return { versionId: ref.id };
  });
}

/** "ks_20261013_01", then _02 for a second release the same day (Vietnam time). */
function nextLabel(last: string | undefined, now: Date) {
  const day = new Date(now.getTime() + 7 * 3600_000).toISOString().slice(0, 10).replace(/-/g, '');
  const prefix = `ks_${day}_`;
  const n = last?.startsWith(prefix) ? Number(last.slice(-2)) + 1 : 1;
  return `${prefix}${String(n).padStart(2, '0')}`;
}

/** Gửi duyệt · Duyệt & xuất bản · Trả lại · Huỷ nháp · Dùng lại bản này (rollback). */
export async function keepsakeAct(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  const req = parse(keepsakeActSchema, data);
  const snap = await versions(db).doc(req.versionId).get();
  if (!snap.exists) throw new StaffError('not-found', 'not-found');
  const status = snap.get('status') as string;
  const ref = snap.ref;
  const audit = (s: Staff, action: string, tx: FirebaseFirestore.Transaction) =>
    staffAudit(
      tx,
      db,
      s,
      {
        action: `content.keepsakes.${action}`,
        category: 'content',
        target: 'keepsakes',
        reason: req.reason,
      },
      now,
    );

  switch (req.action) {
    case 'submit':
    case 'discard': {
      const s = requireStaff(staff, 'content.edit');
      if (status !== 'draft') throw new StaffError('failed-precondition', 'not-draft');
      const next = req.action === 'submit' ? 'pending' : 'discarded';
      await db.runTransaction(async (tx) => {
        tx.update(ref, {
          status: next,
          ...(req.action === 'submit' ? { submittedAt: now, submittedByName: s.name } : {}),
          updatedAt: now,
        });
        audit(s, req.action, tx);
      });
      return { status: next };
    }
    case 'reject': {
      const s = requireStaff(staff, 'content.approve');
      if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
      await db.runTransaction(async (tx) => {
        tx.update(ref, {
          status: 'draft',
          rejection: { by: s.name, reason: req.reason },
          updatedAt: now,
        });
        audit(s, 'reject', tx);
      });
      return { status: 'draft' };
    }
    case 'approve':
    case 'rollback': {
      const s = requireStaff(staff, 'content.approve');
      if (req.action === 'approve') {
        if (status !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
        // Two people: whoever wrote the version cannot approve it (P-138 pattern, D-058), unless
        // the Owner may approve their own (D-079).
        if (snap.get('authorUid') === s.uid && !mayApproveOwn(s, await readContentPolicy(db))) {
          throw new StaffError('failed-precondition', 'same-person');
        }
      } else if (status !== 'retired' && status !== 'published') {
        throw new StaffError('failed-precondition', 'not-retired');
      }
      const draft = keepsakeCatalogSchema.safeParse(snap.get('catalog'));
      if (!draft.success) throw new StaffError('failed-precondition', 'invalid-catalog');
      const previous = await versions(db).where('status', '==', 'published').get();
      const target =
        req.action === 'approve' ? ref : versions(db).doc(`kv_${randomBytes(8).toString('hex')}`);
      return db.runTransaction(async (tx) => {
        const [pub, meta] = await Promise.all([tx.get(publicDoc(db)), tx.get(root(db))]);
        // A draft made from an older release would undo the later one: bring it up to date first.
        if (req.action === 'approve' && pub.exists) {
          const basedOn = snap.get('basedOn') as string | null | undefined;
          const created = (snap.get('createdAt') as Timestamp | undefined)?.toDate();
          const publishedAt = Date.parse((pub.get('publishedAt') as string | undefined) ?? '');
          const stale = basedOn
            ? basedOn !== pub.get('version')
            : !!created && publishedAt > created.getTime();
          if (stale) throw new StaffError('failed-precondition', 'stale-draft');
        }
        const current = pub.exists
          ? keepsakePublicCatalogSchema.safeParse({
              templates: pub.get('templates'),
              premium: pub.get('premium') ?? undefined,
              music: pub.get('music') ?? undefined,
            })
          : null;
        const highest = (meta.get('highest') as Record<string, number> | undefined) ?? {};
        const catalog = assignKeepsakeVersions(
          draft.data,
          current?.success ? current.data : null,
          highest,
        );
        const label = nextLabel(pub.get('version') as string | undefined, now);
        for (const p of previous.docs) {
          if (p.id !== target.id) tx.update(p.ref, { status: 'retired', updatedAt: now });
        }
        const fields = {
          status: 'published',
          label,
          catalog: draft.data,
          published: catalog,
          approverUid: s.uid,
          approverName: s.name,
          approvedAt: now,
          updatedAt: now,
        };
        if (req.action === 'approve') {
          tx.update(ref, fields);
        } else {
          tx.create(target, {
            ...fields,
            notes: `Dùng lại ${snap.get('label') as string}`,
            authorUid: s.uid,
            authorName: s.name,
            createdAt: now,
            rejection: null,
          });
        }
        tx.set(publicDoc(db), {
          version: label,
          publishedAt: now.toISOString(),
          templates: catalog.templates,
          premium: catalog.premium,
          // The app's Thư viện nhạc: published tracks, without licence details.
          music: catalog.music.map(publicKeepsakeMusic),
        });
        const nextHighest = { ...highest };
        for (const t of catalog.templates) {
          nextHighest[t.id] = Math.max(nextHighest[t.id] ?? 0, t.version);
        }
        tx.set(
          root(db),
          {
            currentVersionId: target.id,
            highest: nextHighest,
            music: catalog.music,
            updatedAt: now,
          },
          { merge: true },
        );
        audit(s, req.action, tx);
        return { status: 'published', version: label };
      });
    }
  }
}

/** What an upload really is (never trust the name): a picture, MP3 / M4A music or an MP4 video. */
export function sniffKeepsakeAsset(head: Buffer): 'image' | 'mp3' | 'm4a' | 'mp4' | null {
  if (head.length >= 3 && head[0] === 0xff && head[1] === 0xd8 && head[2] === 0xff) return 'image';
  if (head.length >= 4 && head.readUInt32BE(0) === 0x89504e47) return 'image';
  if (head.length >= 12 && head.toString('ascii', 0, 4) === 'RIFF') {
    return head.toString('ascii', 8, 12) === 'WEBP' ? 'image' : null;
  }
  if (head.length >= 3 && head.toString('ascii', 0, 3) === 'ID3') return 'mp3';
  if (head.length >= 2 && head[0] === 0xff && (head[1]! & 0xe0) === 0xe0) return 'mp3';
  if (head.length >= 12 && head.toString('ascii', 4, 8) === 'ftyp') {
    const brand = head.toString('ascii', 8, 12);
    if (brand === 'M4A ') return 'm4a';
    return ['isom', 'iso2', 'mp41', 'mp42', 'avc1', 'M4V '].includes(brand) ? 'mp4' : null;
  }
  return null;
}

/** One asset (stored once; the same bytes give the same name). */
export async function keepsakeUploadAsset(
  db: Firestore,
  deps: KeepsakeContentDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(keepsakeUploadAssetSchema, data);
  let raw: Buffer;
  if (req.incoming) {
    // Only what this staff member put there themselves.
    if (!req.incoming.startsWith(`content/keepsakes-incoming/${s.uid}/`)) {
      throw new StaffError('permission-denied', 'not-yours');
    }
    const read = await deps.assets.readIncoming(req.incoming);
    if (!read) throw new StaffError('not-found', 'asset-missing');
    raw = read;
  } else {
    raw = Buffer.from(req.data!, 'base64');
  }
  const kind = sniffKeepsakeAsset(raw.subarray(0, 16));
  if (!kind) throw new StaffError('invalid-argument', 'asset-unreadable');
  let bytes: Buffer;
  if (kind === 'image') {
    try {
      bytes = await deps.assets.encodeImage(raw);
    } catch {
      throw new StaffError('invalid-argument', 'asset-unreadable');
    }
  } else {
    bytes = raw;
  }
  const ext = kind === 'image' ? 'webp' : kind;
  const asset = `${req.name}_${createHash('sha256').update(bytes).digest('hex').slice(0, 8)}.${ext}`;
  if (!(await deps.assets.exists(asset))) {
    await deps.assets.save(
      asset,
      bytes,
      kind === 'image'
        ? 'image/webp'
        : kind === 'mp3'
          ? 'audio/mpeg'
          : kind === 'mp4'
            ? 'video/mp4'
            : 'audio/mp4',
    );
  }
  if (req.incoming) await deps.assets.deleteIncoming(req.incoming);
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    { action: 'content.keepsakes.asset', category: 'content', target: asset, reason: null },
    now,
  );
  await batch.commit();
  return { asset, url: deps.assets.publicUrl(asset) };
}
