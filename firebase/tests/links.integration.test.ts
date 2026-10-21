import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { ageLabel, slugOf } from '@child-life/contracts';
import {
  LinkError,
  createShareLink,
  expireLinks,
  handleShare,
  recordCard,
  revokeShareLink,
  type ShareRequest,
} from '../functions/src/links.js';
import type { MediaStore } from '../functions/src/memories.js';

// S13 server side against the Firestore emulator: link creation (saved stories only, parents only,
// passcode once), the recipient page as a live projection (P-095: family-visible photos only,
// nothing deleted, no birth date unless chosen), images through the same checks, passcode lock
// (P-096), view counting, revoke, expiry, and the card list (R-162).
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z');
const later = (h: number) => new Date(now.getTime() + h * 3_600_000);
let app: App;
let db: Firestore;
const babyId = 'b_5713000000000000000a';
const storyId = `sto_${'2'.repeat(32)}`;
const SHARED = `med_${'a'.repeat(32)}`;
const PRIVATE = `med_${'b'.repeat(32)}`;
const GONE = `med_${'c'.repeat(32)}`;

const store: MediaStore = {
  head: async () => null,
  read: async (path) =>
    path.includes('missing') ? null : new TextEncoder().encode(`jpeg:${path}`),
  save: async () => {},
  move: async () => {},
  size: async () => null,
  delete: async () => {},
};

const req = (path: string, extra: Partial<ShareRequest> = {}): ShareRequest => ({
  method: 'GET',
  path,
  ip: '1.2.3.4',
  cookies: {},
  form: {},
  locale: 'vi',
  ...extra,
});

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof LinkError ? e.reason : String(e);
  }
};

const make = (extra: Record<string, unknown> = {}) =>
  createShareLink(
    db,
    'mom',
    {
      requestId: randomUUID(),
      babyId,
      storyId,
      expiry: '7d',
      hideIdentity: true,
      allowDownload: false,
      passcode: false,
      ...extra,
    },
    now,
    'https://dev.childlife.app',
  );

beforeAll(() => {
  app = initializeApp({ projectId }, `links-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {
      method: 'DELETE',
    },
  );
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Bé Na',
    familyId: 'f1',
    state: 'active',
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  await db
    .doc(`babies/${babyId}/restricted/profile`)
    .set({ dateOfBirth: '2026-09-17', gender: 'girl' });
  for (const [uid, role, name] of [
    ['mom', 'coParent', 'Nguyễn Mai'],
    ['grandma', 'relative', 'Bà nội Hoa'],
  ] as const) {
    await db
      .doc(`babies/${babyId}/members/${uid}`)
      .set({ uid, babyId, role, status: 'active', displayName: name });
  }
  for (const [id, audience, deleted] of [
    [SHARED, 'family', false],
    [PRIVATE, 'parents', false],
    [GONE, 'family', true],
  ] as const) {
    await db.doc(`babies/${babyId}/media/${id}`).set({
      type: 'photo',
      status: 'ready',
      deleted,
      effectiveAudience: audience,
      paths: {
        display: `babies/${babyId}/media/${id}/display.jpg`,
        original: `babies/${babyId}/media/${id}/original.jpg`,
      },
    });
  }
  await db.doc(`babies/${babyId}/stories/${storyId}`).set({
    status: 'saved',
    audience: 'family',
    title: 'Tuần Na biết cười',
    coverMediaId: SHARED,
    blocks: [
      { id: 'b0', type: 'paragraph', text: 'Na cười <b>lần đầu</b>.', ai: false },
      {
        id: 'b1',
        type: 'photos',
        items: [SHARED, PRIVATE, GONE].map((m) => ({ mediaId: m, caption: null })),
      },
    ],
  });
});

describe('helpers', () => {
  it('slug and age', () => {
    expect(slugOf('Bé Na')).toBe('be-na');
    expect(slugOf('Đậu')).toBe('dau');
    expect(ageLabel('2026-09-17', '2026-10-08', 'vi')).toBe('3 tuần tuổi');
    expect(ageLabel('2026-09-17', '2026-10-08', 'en')).toBe('3 weeks old');
  });
});

describe('creating links (14k)', () => {
  it('saved stories only, parents only; the passcode is returned once', async () => {
    expect(
      await reason(
        createShareLink(
          db,
          'grandma',
          {
            requestId: randomUUID(),
            babyId,
            storyId,
            expiry: '7d',
            hideIdentity: true,
            allowDownload: false,
            passcode: false,
          },
          now,
          'x',
        ),
      ),
    ).toBe('parents-only');
    await db.doc(`babies/${babyId}/stories/${storyId}`).update({ status: 'draft' });
    expect(await reason(make())).toBe('not-saved');
    await db.doc(`babies/${babyId}/stories/${storyId}`).update({ status: 'saved' });
    const link = await make({ passcode: true, expiry: '24h' });
    expect(link.url).toBe(`https://dev.childlife.app/s/${link.token}-be-na`);
    expect(link.passcode).toMatch(/^\d{4}$/);
    expect(link.expiresAt).toBe(later(24).toISOString());
    const stored = (await db.doc(`shareLinks/${link.token}`).get()).data()!;
    expect(JSON.stringify(stored)).not.toContain(link.passcode!);
    const mine = await db.collection('users/mom/sharedOut').get();
    expect(mine.docs[0]!.get('views')).toBe(0);
  });
});

describe('the recipient page (14l, P-095)', () => {
  it('shows family-visible photos, escapes text, hides the birth date, counts one view', async () => {
    const { token } = await make();
    const page = await handleShare(db, store, req(`/s/${token}-be-na`), now, 'https://x');
    expect(page.status).toBe(200);
    const html = page.body as string;
    expect(html).toContain('Tuần Na biết cười');
    expect(html).toContain('Na cười &lt;b&gt;lần đầu&lt;/b&gt;.');
    expect(html).toContain('Bé Na · 3 tuần tuổi · Mai chia sẻ');
    expect(html).toContain(SHARED);
    expect(html).not.toContain(PRIVATE);
    expect(html).not.toContain(GONE);
    expect(html).not.toContain('sinh ngày');
    expect(html).toContain('Người gửi không cho tải ảnh về.');
    // Owner request: no expiry date on the page; every photo opens full screen (no script).
    expect(html).not.toContain('hết hạn');
    expect(html).not.toContain('<script');
    expect(html).toMatch(/<a [^>]*href="#v-med_[a-z]+"><img/);
    expect(html).toMatch(/<div class="lb" id="v-med_[a-z]+">/);
    expect(page.headers['X-Robots-Tag']).toContain('noindex');
    const seen = Object.fromEntries(page.cookies.map((c) => [c.name, c.value]));
    await handleShare(db, store, req(`/s/${token}-be-na`, { cookies: seen }), now, 'https://x');
    expect((await db.doc(`shareLinks/${token}`).get()).get('views')).toBe(1);
    expect((await db.collection('users/mom/sharedOut').get()).docs[0]!.get('views')).toBe(1);
  });

  it('images pass the same checks; originals only when downloads are allowed', async () => {
    const { token } = await make();
    const img = await handleShare(db, store, req(`/s/${token}/m/${SHARED}`), now, 'x');
    expect(img.type).toBe('jpeg');
    expect(new TextDecoder().decode(img.body as Uint8Array)).toContain('display.jpg');
    expect((await handleShare(db, store, req(`/s/${token}/m/${PRIVATE}`), now, 'x')).status).toBe(
      404,
    );
    expect(
      (await handleShare(db, store, req(`/s/${token}/m/${SHARED}/dl`), now, 'x')).headers[
        'Content-Disposition'
      ],
    ).toBeUndefined();
    const open = await make({ allowDownload: true, hideIdentity: false });
    const dl = await handleShare(db, store, req(`/s/${open.token}/m/${SHARED}/dl`), now, 'x');
    expect(new TextDecoder().decode(dl.body as Uint8Array)).toContain('original.jpg');
    expect(dl.headers['Content-Disposition']).toContain('attachment');
    const page = await handleShare(db, store, req(`/s/${open.token}`), now, 'x');
    expect(page.body as string).toContain('sinh ngày');
  });

  it('a story made private or deleted later: photos follow at view time', async () => {
    const { token } = await make();
    await db.doc(`babies/${babyId}/media/${SHARED}`).update({ effectiveAudience: 'parents' });
    const page = await handleShare(db, store, req(`/s/${token}`), now, 'x');
    expect(page.body as string).not.toContain(SHARED);
    await db.doc(`babies/${babyId}/stories/${storyId}`).delete();
    expect((await handleShare(db, store, req(`/s/${token}`), now, 'x')).status).toBe(404);
  });
});

describe('passcode, revoke and expiry (P-096, G-052)', () => {
  it('asks for the code; 5 wrong tries lock the address for 15 minutes', async () => {
    const { token, passcode } = await make({ passcode: true });
    const form = await handleShare(db, store, req(`/s/${token}`), now, 'x');
    expect(form.status).toBe(401);
    expect(form.body as string).not.toContain('Tuần Na');
    const wrong = passcode === '0000' ? '1111' : '0000';
    for (let i = 0; i < 4; i++) {
      const r = await handleShare(
        db,
        store,
        req(`/s/${token}`, { method: 'POST', form: { passcode: wrong } }),
        now,
        'x',
      );
      expect(r.body as string).toContain('Mật mã chưa đúng');
    }
    const fifth = await handleShare(
      db,
      store,
      req(`/s/${token}`, { method: 'POST', form: { passcode: wrong } }),
      now,
      'x',
    );
    expect(fifth.status).toBe(429);
    const blocked = await handleShare(
      db,
      store,
      req(`/s/${token}`, { method: 'POST', form: { passcode: passcode! } }),
      now,
      'x',
    );
    expect(blocked.status).toBe(429);
    // Another address, or the same one after the window, may try again.
    const ok = await handleShare(
      db,
      store,
      req(`/s/${token}`, { method: 'POST', form: { passcode: passcode! }, ip: '5.6.7.8' }),
      now,
      'x',
    );
    expect(ok.type).toBe('redirect');
    const jar = Object.fromEntries(ok.cookies.map((c) => [c.name, c.value]));
    const page = await handleShare(db, store, req(`/s/${token}`, { cookies: jar }), now, 'x');
    expect(page.status).toBe(200);
    const after = await handleShare(
      db,
      store,
      req(`/s/${token}`, { method: 'POST', form: { passcode: passcode! } }),
      new Date(now.getTime() + 16 * 60_000),
      'x',
    );
    expect(after.type).toBe('redirect');
  });

  it('revoked and unknown links look the same; expired ones say so', async () => {
    const { token } = await make({ expiry: '24h' });
    expect(await reason(revokeShareLink(db, 'grandma', { token }, now))).toBe('not-found');
    await revokeShareLink(db, 'mom', { token }, now);
    const revoked = await handleShare(db, store, req(`/s/${token}`), now, 'x');
    const unknown = await handleShare(db, store, req('/s/AAAAAAAAAAAAAAAA'), now, 'x');
    expect(revoked.status).toBe(404);
    expect(revoked.body).toBe(unknown.body);
    expect((await db.collection('users/mom/sharedOut').get()).docs[0]!.get('status')).toBe(
      'revoked',
    );

    const other = await make({ expiry: '24h' });
    expect((await handleShare(db, store, req(`/s/${other.token}`), later(25), 'x')).status).toBe(
      410,
    );
    expect(await expireLinks(db, later(25))).toBe(1);
    expect((await db.doc(`shareLinks/${other.token}`).get()).get('status')).toBe('expired');
  });

  it('cards are listed and never revocable (R-162)', async () => {
    await recordCard(
      db,
      'mom',
      { requestId: randomUUID(), babyId, storyId, template: 'moment' },
      now,
    );
    const rows = await db.collection('users/mom/sharedOut').get();
    expect(rows.docs[0]!.data()).toMatchObject({
      kind: 'card',
      template: 'moment',
      title: 'Tuần Na biết cười',
    });
  });
});
