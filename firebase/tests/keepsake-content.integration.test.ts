import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  keepsakeSeedV1,
  publicKeepsakeMusic,
  type KeepsakeMusic,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import {
  keepsakeAct,
  keepsakeDraft,
  keepsakeUploadAsset,
  keepsakeView,
  sniffKeepsakeAsset,
  type KeepsakeContentDeps,
} from '../functions/src/keepsake-content.js';
import type { Staff } from '../functions/src/staff.js';

// Mẫu kỷ niệm on the portal (D-068 #7) against the Firestore emulator, with an in-memory asset
// store: draft → submit → a different person approves → publicConfig/keepsakes with versions.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const now = new Date('2026-10-13T03:00:00Z');
const ops: Staff = { uid: 'u_ops', name: 'Hà Vũ', roles: ['ops'] };
const expert: Staff = { uid: 'u_expert', name: 'BS. Lan', roles: ['expert'] };
const expert2: Staff = { uid: 'u_expert2', name: 'Linh', roles: ['expert'] };
const support: Staff = { uid: 'u_support', name: 'Mai', roles: ['support'] };

const stored = new Map<string, string>();
const incoming = new Map<string, Buffer>();
const deps: KeepsakeContentDeps = {
  assets: {
    exists: async (a) => stored.has(a),
    save: async (a, _bytes, type) => void stored.set(a, type),
    list: async () => [...stored.keys()],
    publicUrl: (a) => `https://img.test/${a}`,
    encodeImage: async (bytes) => Buffer.concat([Buffer.from('RIFF0000WEBP'), bytes]),
    readIncoming: async (path) => incoming.get(path) ?? null,
    deleteIncoming: async (path) => void incoming.delete(path),
  },
};
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, 4]);

async function publish(catalog = keepsakeSeedV1, by = ops) {
  const { versionId } = await keepsakeDraft(db, deps, by, { catalog, notes: '' }, now);
  await keepsakeAct(db, by, { versionId, action: 'submit', reason: null }, now);
  await keepsakeAct(db, expert, { versionId, action: 'approve', reason: null }, now);
  return versionId;
}

beforeAll(() => {
  app = initializeApp({ projectId }, `keepsakes-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => deleteApp(app));
beforeEach(async () => {
  stored.clear();
  for (const path of ['publicConfig/keepsakes', 'content/keepsakes']) await db.doc(path).delete();
  const old = await db.collection('content/keepsakes/versions').get();
  await Promise.all(old.docs.map((d) => d.ref.delete()));
});

describe('Mẫu kỷ niệm workflow', () => {
  it('publishes the seed after a second person approves, at version 1', async () => {
    const { versionId } = await keepsakeDraft(
      db,
      deps,
      expert2,
      { catalog: keepsakeSeedV1, notes: 'Bộ đầu' },
      now,
    );
    await keepsakeAct(db, expert2, { versionId, action: 'submit', reason: null }, now);
    expect(
      await reason(keepsakeAct(db, ops, { versionId, action: 'approve', reason: null }, now)),
    ).toBe('role');
    expect(
      await reason(keepsakeAct(db, expert2, { versionId, action: 'approve', reason: null }, now)),
    ).toBe('same-person');
    expect(
      await keepsakeAct(db, expert, { versionId, action: 'approve', reason: null }, now),
    ).toEqual({ status: 'published', version: 'ks_20261013_01' });
    const pub = await db.doc('publicConfig/keepsakes').get();
    const templates = pub.get('templates') as KeepsakeTemplate[];
    expect(pub.get('premium')).toEqual({ access: 'everyone', badges: true });
    expect(templates.map((t) => [t.id, t.version])).toEqual(
      keepsakeSeedV1.templates.map((t) => [t.id, 1]),
    );
  });

  it('a changed template gets the next version; archiving removes it; rollback never reuses', async () => {
    const first = await publish();
    const [round, ...rest] = keepsakeSeedV1.templates;
    await publish({ ...keepsakeSeedV1, templates: [{ ...round!, order: 12 }, ...rest] });
    let templates = (await db.doc('publicConfig/keepsakes').get()).get(
      'templates',
    ) as KeepsakeTemplate[];
    expect(templates.find((t) => t.id === 'card_round')!.version).toBe(2);
    expect(templates.find((t) => t.id === 'card_blush')!.version).toBe(1);

    // The Cao cấp setting changes no template version (D-068 #8).
    await publish({ ...keepsakeSeedV1, premium: { access: 'hidden', badges: false } });
    const hidden = await db.doc('publicConfig/keepsakes').get();
    expect(hidden.get('premium')).toEqual({ access: 'hidden', badges: false });
    expect(
      (hidden.get('templates') as KeepsakeTemplate[]).find((t) => t.id === 'card_blush')!.version,
    ).toBe(1);
    await publish({ ...keepsakeSeedV1, templates: [{ ...round!, status: 'archived' }, ...rest] });
    templates = (await db.doc('publicConfig/keepsakes').get()).get(
      'templates',
    ) as KeepsakeTemplate[];
    expect(templates.some((t) => t.id === 'card_round')).toBe(false);

    // Rolling back to the first release brings card_round back as a new number, not 1 again.
    expect((await keepsakeView(db, deps, ops)).history).toHaveLength(4);
    await keepsakeAct(db, expert, { versionId: first, action: 'rollback', reason: null }, now);
    templates = (await db.doc('publicConfig/keepsakes').get()).get(
      'templates',
    ) as KeepsakeTemplate[];
    // Versions 1 (seed), 2 (order 12), 3 (back to order 10 with the Cao cấp change), then 4.
    expect(templates.find((t) => t.id === 'card_round')!.version).toBe(4);
  });

  it('refuses a draft naming an asset that was never uploaded, and staff without the right', async () => {
    const [round, ...rest] = keepsakeSeedV1.templates;
    const framed = {
      templates: [
        {
          ...round!,
          layouts: {
            portrait: [
              ...round!.layouts!.portrait!,
              {
                type: 'image' as const,
                asset: 'frame_00000000.webp',
                rect: { x: 0, y: 0, w: 1, h: 1 },
                fit: 'cover' as const,
                opacity: 1,
              },
            ],
          },
        },
        ...rest,
      ],
    };
    expect(await reason(keepsakeDraft(db, deps, ops, { catalog: framed, notes: '' }, now))).toBe(
      'asset-missing',
    );
    expect(
      await reason(keepsakeDraft(db, deps, support, { catalog: keepsakeSeedV1, notes: '' }, now)),
    ).not.toBe('ok');
  });
});

describe('assets', () => {
  it('pictures become WebP named by content hash; music is kept; anything else is refused', async () => {
    const pic = await keepsakeUploadAsset(
      db,
      deps,
      ops,
      { name: 'frame-pink', data: png.toString('base64') },
      now,
    );
    expect(pic.asset).toMatch(/^frame-pink_[a-f0-9]{8}\.webp$/);
    expect(stored.get(pic.asset)).toBe('image/webp');
    const again = await keepsakeUploadAsset(
      db,
      deps,
      ops,
      { name: 'frame-pink', data: png.toString('base64') },
      now,
    );
    expect(again.asset).toBe(pic.asset);
    const mp3 = Buffer.concat([Buffer.from('ID3'), Buffer.alloc(20)]);
    const song = await keepsakeUploadAsset(
      db,
      deps,
      ops,
      { name: 'lullaby', data: mp3.toString('base64') },
      now,
    );
    expect(song.asset).toMatch(/\.mp3$/);
    expect(
      await reason(
        keepsakeUploadAsset(
          db,
          deps,
          ops,
          { name: 'x1', data: Buffer.from('not a file at all').toString('base64') },
          now,
        ),
      ),
    ).toBe('asset-unreadable');
    expect(sniffKeepsakeAsset(Buffer.from('RIFF0000WAVE'))).toBe(null);
  });

  it('a large file (a preview video) comes through the staff member’s own incoming folder', async () => {
    const mp4 = Buffer.concat([
      Buffer.from([0, 0, 0, 0x18]),
      Buffer.from('ftypisom'),
      Buffer.alloc(40),
    ]);
    const path = `content/keepsakes-incoming/${ops.uid}/first-month-preview.mp4`;
    incoming.set(path, mp4);
    const r = await keepsakeUploadAsset(
      db,
      deps,
      ops,
      { name: 'first-month-preview', incoming: path },
      now,
    );
    expect(r.asset).toMatch(/^first-month-preview_[a-f0-9]{8}\.mp4$/);
    expect(stored.get(r.asset)).toBe('video/mp4');
    expect(incoming.has(path)).toBe(false);
    expect(
      await reason(
        keepsakeUploadAsset(
          db,
          deps,
          ops,
          { name: 'x1', incoming: 'content/keepsakes-incoming/someoneelse/x1.mp4' },
          now,
        ),
      ),
    ).toBe('not-yours');
  });
});

describe('drafts made from an older release', () => {
  it('cannot be approved until they are brought up to date', async () => {
    await publish();
    const live = (await db.doc('publicConfig/keepsakes').get()).get('version') as string;
    // A draft made from the set in use, then another release lands (a rollback, a dev seed).
    const { versionId } = await keepsakeDraft(
      db,
      deps,
      expert2,
      { catalog: keepsakeSeedV1, notes: '', basedOn: live },
      now,
    );
    await db
      .doc('publicConfig/keepsakes')
      .update({ version: 'ks_other', publishedAt: now.toISOString() });
    await keepsakeAct(db, expert2, { versionId, action: 'submit', reason: null }, now);
    expect(
      await reason(keepsakeAct(db, expert, { versionId, action: 'approve', reason: null }, now)),
    ).toBe('stale-draft');
    // Saved again from the set in use: approved.
    await keepsakeDraft(
      db,
      deps,
      expert2,
      { catalog: keepsakeSeedV1, notes: '', basedOn: 'ks_other' },
      now,
    );
    await keepsakeAct(db, expert2, { versionId, action: 'submit', reason: null }, now);
    expect(
      await reason(keepsakeAct(db, expert, { versionId, action: 'approve', reason: null }, now)),
    ).toBe('ok');
  });
});

describe('Thư viện nhạc', () => {
  const track = (over: Record<string, unknown> = {}) => ({
    id: 'music_lullaby',
    title: { vi: 'Ru con nhẹ nhàng', en: 'Gentle lullaby' },
    artist: 'Studio',
    mood: 'gentle',
    durationSec: 60,
    asset: 'lullaby_1a2b3c4d.mp3',
    licence: { kind: 'licensed', source: 'Store', reference: 'INV-1', expiresOn: null },
    status: 'published',
    order: 10,
    ...over,
  });

  it('a template’s default music must be a published, licensed track that is uploaded', async () => {
    const [first, ...rest] = keepsakeSeedV1.templates.filter((t) => t.kind === 'video');
    const cards = keepsakeSeedV1.templates.filter((t) => t.kind === 'card');
    const withMusic = (music: unknown[]) => ({
      ...keepsakeSeedV1,
      music,
      templates: [...cards, { ...first!, defaultMusic: 'music_lullaby' }, ...rest],
    });
    // Not uploaded yet.
    expect(
      await reason(keepsakeDraft(db, deps, ops, { catalog: withMusic([track()]), notes: '' }, now)),
    ).toBe('asset-missing');
    stored.set('lullaby_1a2b3c4d.mp3', 'audio/mpeg');
    // No licence: refused by the schema.
    expect(
      await reason(
        keepsakeDraft(
          db,
          deps,
          ops,
          {
            catalog: withMusic([
              track({ licence: { kind: 'licensed', source: '', reference: '', expiresOn: null } }),
            ]),
            notes: '',
          },
          now,
        ),
      ),
    ).not.toBe('ok');
    expect(
      await reason(keepsakeDraft(db, deps, ops, { catalog: withMusic([track()]), notes: '' }, now)),
    ).toBe('ok');
  });
  it('publishing gives the app the tracks without licence; staff keep the licence', async () => {
    const videos = keepsakeSeedV1.templates.filter((t) => t.kind === 'video');
    const cards = keepsakeSeedV1.templates.filter((t) => t.kind === 'card');
    stored.set('lullaby_1a2b3c4d.mp3', 'audio/mpeg');
    const catalog = {
      ...keepsakeSeedV1,
      music: [track(), track({ id: 'music_draft', status: 'draft' })],
      templates: [...cards, { ...videos[0]!, defaultMusic: 'music_lullaby' }, ...videos.slice(1)],
    };
    await publish(catalog as typeof keepsakeSeedV1);
    const pub = await db.doc('publicConfig/keepsakes').get();
    expect(pub.get('music')).toEqual([publicKeepsakeMusic(track() as KeepsakeMusic)]);
    expect((pub.get('music') as object[])[0]).not.toHaveProperty('licence');
    const view = await keepsakeView(db, deps, ops);
    expect(view.current?.catalog.music).toEqual([track()]);
    // Publishing the same set again keeps every version.
    await publish(catalog as typeof keepsakeSeedV1);
    const again = (await db.doc('publicConfig/keepsakes').get()).get(
      'templates',
    ) as KeepsakeTemplate[];
    expect(again.every((t) => t.version === 1)).toBe(true);
  });
});
