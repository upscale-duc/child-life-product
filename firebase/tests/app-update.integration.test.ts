import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  appUpdateSave,
  appUpdateUploadImage,
  appUpdateView,
  type AppUpdateDeps,
} from '../functions/src/app-update.js';
import type { Staff } from '../functions/src/staff.js';

// Cập nhật ứng dụng on the portal (D-061) against the Firestore emulator: publish to
// publicConfig/appUpdate, history, audit, and who may do it.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const now = new Date('2026-10-12T03:00:00Z');
const eng: Staff = { uid: 'u_eng', name: 'Khoa', roles: ['eng'] };
const ops: Staff = { uid: 'u_ops', name: 'Hà Vũ', roles: ['ops'] };
const support: Staff = { uid: 'u_support', name: 'Mai', roles: ['support'] };

const stored = new Set<string>();
const deps: AppUpdateDeps = {
  images: {
    exists: async (i) => stored.has(i),
    save: async (i) => void stored.add(i),
    list: async () => [...stored],
    publicUrl: (i) => `https://img.test/${i}`,
    encode: async (bytes) => Buffer.from(bytes),
  },
};
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const text = (vi: string, en: string) => ({ vi, en });
const config = (iosMinimum: string | null, image: string | null = null) => ({
  ios: {
    latest: '1.2.0',
    minimum: iosMinimum,
    storeUrl: 'https://apps.apple.com/app/id6700000000',
  },
  android: { latest: null, minimum: null, storeUrl: null },
  snoozeDays: 3,
  release: {
    version: '1.2.0',
    summary: text('Sơ cứu, chi tiêu chung, lịch tiêm', 'First aid, shared spending, vaccines'),
    highlights: [
      {
        icon: 'alert' as const,
        tone: 'danger' as const,
        title: text('Sơ cứu trẻ em', 'Child first aid'),
        body: text('25 tình huống, đọc to từng bước', '25 situations, read aloud'),
      },
    ],
    pages: [
      {
        image,
        title: text('Sơ cứu trẻ em, luôn trong túi bạn', 'First aid, always with you'),
        body: text('25 tình huống thường gặp.', '25 common situations.'),
        where: text('Tìm trong tab Tiện ích', 'In the Utilities tab'),
      },
    ],
  },
});

beforeAll(() => {
  app = initializeApp({ projectId }, `app-update-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  stored.clear();
  await db.doc('publicConfig/appUpdate').delete();
  await db.recursiveDelete(db.collection('appUpdateHistory'));
  await db.recursiveDelete(db.collection('staffAudit'));
});

describe('Cập nhật ứng dụng on the portal', () => {
  it('publishes with a reason; history and audit name a raised minimum', async () => {
    expect(
      await reason(appUpdateSave(db, deps, ops, { config: config(null), reason: 'x1x' }, now)),
    ).toBe('role');
    const first = await appUpdateSave(
      db,
      deps,
      eng,
      { config: config(null), reason: 'Bản 1.2.0' },
      now,
    );
    expect(first).toEqual({ version: 'au_20261012_01' });
    const second = await appUpdateSave(
      db,
      deps,
      eng,
      { config: config('1.1.0'), reason: 'Bản cũ lỗi đồng bộ' },
      now,
    );
    expect(second.version).toBe('au_20261012_02');
    const pub = (await db.doc('publicConfig/appUpdate').get()).data()!;
    expect(pub.config.ios.minimum).toBe('1.1.0');
    const view = await appUpdateView(db, deps, ops);
    expect(view.current?.version).toBe('au_20261012_02');
    expect(view.history.map((h) => h.reason)).toEqual(['Bản cũ lỗi đồng bộ', 'Bản 1.2.0']);
    const audit = await db.collection('staffAudit').orderBy('target').get();
    const details = audit.docs.map((d) => d.get('detail') as Record<string, unknown>);
    expect(details[0]!.raisedMinimum).toBeUndefined();
    expect(details[1]!.raisedMinimum).toEqual({ ios: '1.1.0', android: null });
    expect(await reason(appUpdateView(db, deps, support))).toBe('role');
  });

  it('rejects a minimum above latest, a missing store link or a missing picture', async () => {
    const bad = config('1.3.0');
    expect(await reason(appUpdateSave(db, deps, eng, { config: bad, reason: 'xxx' }, now))).toBe(
      'malformed',
    );
    const noStore = { ...config(null), ios: { latest: '1.2.0', minimum: null, storeUrl: null } };
    expect(
      await reason(appUpdateSave(db, deps, eng, { config: noStore, reason: 'xxx' }, now)),
    ).toBe('malformed');
    expect(
      await reason(
        appUpdateSave(
          db,
          deps,
          eng,
          { config: config(null, 'so-cuu_0000abcd'), reason: 'xxx' },
          now,
        ),
      ),
    ).toBe('image-missing');
    const img = await appUpdateUploadImage(
      db,
      deps,
      eng,
      { name: 'so-cuu', data: Buffer.from('fake').toString('base64') },
      now,
    );
    expect(
      await reason(
        appUpdateSave(db, deps, eng, { config: config(null, img.id), reason: 'xxx' }, now),
      ),
    ).toBe('ok');
  });
});
