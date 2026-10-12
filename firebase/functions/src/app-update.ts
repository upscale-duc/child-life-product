import { createHash } from 'node:crypto';
import {
  appUpdatePublicDocId,
  appUpdateSaveSchema,
  appUpdateUploadImageSchema,
  compareAppVersions,
  localDateIn,
  type AppUpdateConfig,
  type AppUpdatePlatform,
  type AppUpdatePublic,
} from '@child-life/contracts';
import type { Firestore } from 'firebase-admin/firestore';
import type { FirstAidImageStore } from './content.js';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Cập nhật ứng dụng on the portal (D-061): the versions each store has, the oldest one allowed to
 * run, and the release notes ("Có gì mới"). Saving publishes at once to `publicConfig/appUpdate`
 * (the app reads it, cached for offline) and keeps every published version in
 * `appUpdateHistory`, with the reason, in the audit log. Pictures are stored like Sơ cứu's.
 */

export interface AppUpdateDeps {
  images: FirstAidImageStore;
}

const ZONE = 'Asia/Ho_Chi_Minh';
const publicDoc = (db: Firestore) => db.doc(`publicConfig/${appUpdatePublicDocId}`);

/** What the portal screen shows: the published config, the last versions and the pictures. */
export async function appUpdateView(db: Firestore, deps: AppUpdateDeps, staff: Staff | null) {
  requireStaff(staff, 'release.view');
  const [pub, history, images] = await Promise.all([
    publicDoc(db).get(),
    db.collection('appUpdateHistory').orderBy('publishedAt', 'desc').limit(20).get(),
    deps.images.list(),
  ]);
  return {
    current: pub.exists ? (pub.data() as AppUpdatePublic) : null,
    history: history.docs.map((d) => ({
      version: d.id,
      publishedAt: d.get('publishedAt') as string,
      byName: d.get('byName') as string,
      reason: d.get('reason') as string,
      config: d.get('config') as AppUpdateConfig,
    })),
    images: images.map((id) => ({ id, url: deps.images.publicUrl(id) })),
  };
}

const raised = (before: AppUpdatePlatform | undefined, after: AppUpdatePlatform) =>
  !!after.minimum && (!before?.minimum || compareAppVersions(after.minimum, before.minimum) > 0);

/** Publish. Every picture must already exist. */
export async function appUpdateSave(
  db: Firestore,
  deps: AppUpdateDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'release.edit');
  const { config, reason } = parse(appUpdateSaveSchema, data);
  for (const page of config.release?.pages ?? []) {
    if (page.image && !(await deps.images.exists(page.image))) {
      throw new StaffError('failed-precondition', 'image-missing');
    }
  }
  return db.runTransaction(async (tx) => {
    const pub = await tx.get(publicDoc(db));
    const before = pub.exists ? (pub.get('config') as AppUpdateConfig) : null;
    const day = localDateIn(ZONE, now).replace(/-/g, '');
    const last = pub.get('version') as string | undefined;
    const n = last?.startsWith(`au_${day}_`) ? Number(last.slice(-2)) + 1 : 1;
    const version = `au_${day}_${String(n).padStart(2, '0')}`;
    const published: AppUpdatePublic = { version, publishedAt: now.toISOString(), config };
    tx.set(publicDoc(db), published);
    tx.set(db.collection('appUpdateHistory').doc(version), {
      publishedAt: published.publishedAt,
      byUid: s.uid,
      byName: s.name,
      reason,
      config,
    });
    const blocks = {
      ios: raised(before?.ios, config.ios) ? config.ios.minimum : null,
      android: raised(before?.android, config.android) ? config.android.minimum : null,
    };
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'release.publish',
        category: 'features',
        target: version,
        reason,
        detail: {
          iosLatest: config.ios.latest,
          iosMinimum: config.ios.minimum,
          androidLatest: config.android.latest,
          androidMinimum: config.android.minimum,
          release: config.release?.version ?? null,
          ...(blocks.ios || blocks.android ? { raisedMinimum: blocks } : {}),
        },
      },
      now,
    );
    return { version };
  });
}

/** A picture for "Có gì mới" (stored once; the same bytes give the same id). */
export async function appUpdateUploadImage(
  db: Firestore,
  deps: AppUpdateDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'release.edit');
  const req = parse(appUpdateUploadImageSchema, data);
  let webp: Buffer;
  try {
    webp = await deps.images.encode(Buffer.from(req.data, 'base64'), false);
  } catch {
    throw new StaffError('invalid-argument', 'image-unreadable');
  }
  const id = `${req.name}_${createHash('sha256').update(webp).digest('hex').slice(0, 8)}`;
  if (!(await deps.images.exists(id))) await deps.images.save(id, webp);
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    { action: 'release.image', category: 'features', target: id, reason: null },
    now,
  );
  await batch.commit();
  return { id, url: deps.images.publicUrl(id) };
}
