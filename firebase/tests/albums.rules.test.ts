import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// S10: shared albums only for relatives (11e), private favourites (R-107), loves (names for
// parents, counts on targets), one-way messages (D-034), push tokens per install.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const relations: Record<string, string> = {
  mom: 'mother',
  dad: 'father',
  nanny: 'nanny',
  grandma: 'grandmother',
};
const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: relations[uid] ?? 'other',
  relationCustom: null,
  displayName: uid,
  ...extra,
});
const author = (uid: string) => ({
  name: uid,
  relation: relations[uid] ?? 'other',
  relationCustom: null,
});

const ALB_FAMILY = `alb_${'a'.repeat(32)}`;
const ALB_PRIVATE = `alb_${'b'.repeat(32)}`;
const MED_SHARED = `med_${'1'.repeat(32)}`;
const MED_PRIVATE = `med_${'2'.repeat(32)}`;
const MEM_SHARED = `mem_${'3'.repeat(32)}`;
const MSG = `msg_${'4'.repeat(32)}`;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', familyId: 'f1' });
    for (const [uid, role] of [
      ['mom', 'coParent'],
      ['dad', 'coParent'],
      ['nanny', 'caregiver'],
      ['grandma', 'relative'],
    ] as const) {
      await setDoc(doc(db, `babies/b1/members/${uid}`), member(uid, role));
    }
    await setDoc(doc(db, `babies/b1/albums/${ALB_FAMILY}`), {
      name: 'Giờ tắm',
      audience: 'family',
    });
    await setDoc(doc(db, `babies/b1/albums/${ALB_FAMILY}/items/${MED_SHARED}`), {
      mediaId: MED_SHARED,
    });
    await setDoc(doc(db, `babies/b1/albums/${ALB_PRIVATE}`), {
      name: 'Ngủ ngoan',
      audience: 'parents',
    });
    await setDoc(doc(db, `babies/b1/albums/${ALB_PRIVATE}/items/${MED_PRIVATE}`), {
      mediaId: MED_PRIVATE,
    });
    const media = (effective: string) => ({
      effectiveAudience: effective,
      status: 'ready',
      deleted: false,
      captureAt: Timestamp.now(),
    });
    await setDoc(doc(db, `babies/b1/media/${MED_SHARED}`), media('family'));
    await setDoc(doc(db, `babies/b1/media/${MED_PRIVATE}`), media('parents'));
    await setDoc(doc(db, `babies/b1/memories/${MEM_SHARED}`), {
      audience: 'family',
      state: 'published',
      deleted: false,
    });
    await setDoc(doc(db, `babies/b1/reactions/media__${MED_SHARED}__mom`), {
      uid: 'mom',
      target: 'media',
      targetId: MED_SHARED,
      author: author('mom'),
      createdAt: Timestamp.now(),
    });
  });
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();

describe('albums (10d, 11e)', () => {
  it('parents see every album; relatives only shared ones and their items', async () => {
    await assertSucceeds(getDoc(doc(db('dad'), `babies/b1/albums/${ALB_PRIVATE}`)));
    await assertSucceeds(getDoc(doc(db('grandma'), `babies/b1/albums/${ALB_FAMILY}`)));
    await assertSucceeds(
      getDoc(doc(db('grandma'), `babies/b1/albums/${ALB_FAMILY}/items/${MED_SHARED}`)),
    );
    await assertFails(getDoc(doc(db('grandma'), `babies/b1/albums/${ALB_PRIVATE}`)));
    await assertFails(
      getDoc(doc(db('grandma'), `babies/b1/albums/${ALB_PRIVATE}/items/${MED_PRIVATE}`)),
    );
    await assertFails(getDoc(doc(db('nanny'), `babies/b1/albums/${ALB_FAMILY}`)));
  });

  it('only Functions write albums', async () => {
    await assertFails(
      setDoc(doc(db('mom'), `babies/b1/albums/alb_${'c'.repeat(32)}`), { name: 'x' }),
    );
    await assertFails(updateDoc(doc(db('mom'), `babies/b1/albums/${ALB_FAMILY}`), { name: 'x' }));
  });
});

describe('favourites (R-107)', () => {
  const fav = (uid: string, mediaId: string) => ({
    uid,
    mediaId,
    createdAt: serverTimestamp(),
  });

  it('private to their owner, only on what they can see', async () => {
    const own = `grandma__${MED_SHARED}`;
    await assertSucceeds(
      setDoc(doc(db('grandma'), `babies/b1/favorites/${own}`), fav('grandma', MED_SHARED)),
    );
    await assertSucceeds(getDoc(doc(db('grandma'), `babies/b1/favorites/${own}`)));
    await assertFails(getDoc(doc(db('mom'), `babies/b1/favorites/${own}`)));
    await assertFails(
      setDoc(
        doc(db('grandma'), `babies/b1/favorites/grandma__${MED_PRIVATE}`),
        fav('grandma', MED_PRIVATE),
      ),
    );
    await assertSucceeds(
      setDoc(doc(db('mom'), `babies/b1/favorites/mom__${MED_PRIVATE}`), fav('mom', MED_PRIVATE)),
    );
    await assertFails(
      setDoc(
        doc(db('nanny'), `babies/b1/favorites/nanny__${MED_SHARED}`),
        fav('nanny', MED_SHARED),
      ),
    );
    await assertFails(
      setDoc(doc(db('mom'), `babies/b1/favorites/dad__${MED_SHARED}`), fav('dad', MED_SHARED)),
    );
    await assertSucceeds(deleteDoc(doc(db('grandma'), `babies/b1/favorites/${own}`)));
  });
});

describe('loves (11c, 11f, 11g)', () => {
  const love = (uid: string, target: string, targetId: string) => ({
    uid,
    target,
    targetId,
    author: author(uid),
    createdAt: serverTimestamp(),
  });

  it('relatives love what is shared, as themselves', async () => {
    await assertSucceeds(
      setDoc(
        doc(db('grandma'), `babies/b1/reactions/media__${MED_SHARED}__grandma`),
        love('grandma', 'media', MED_SHARED),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(db('grandma'), `babies/b1/reactions/album__${ALB_FAMILY}__grandma`),
        love('grandma', 'album', ALB_FAMILY),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(db('grandma'), `babies/b1/reactions/memory__${MEM_SHARED}__grandma`),
        love('grandma', 'memory', MEM_SHARED),
      ),
    );
    await assertFails(
      setDoc(
        doc(db('grandma'), `babies/b1/reactions/media__${MED_PRIVATE}__grandma`),
        love('grandma', 'media', MED_PRIVATE),
      ),
    );
    await assertFails(
      setDoc(
        doc(db('grandma'), `babies/b1/reactions/media__${MED_SHARED}__mom`),
        love('mom', 'media', MED_SHARED),
      ),
    );
    await assertFails(
      setDoc(
        doc(db('nanny'), `babies/b1/reactions/media__${MED_SHARED}__nanny`),
        love('nanny', 'media', MED_SHARED),
      ),
    );
  });

  it('names for parents; a relative reads only their own', async () => {
    await assertSucceeds(getDoc(doc(db('dad'), `babies/b1/reactions/media__${MED_SHARED}__mom`)));
    await assertFails(getDoc(doc(db('grandma'), `babies/b1/reactions/media__${MED_SHARED}__mom`)));
    await assertFails(deleteDoc(doc(db('dad'), `babies/b1/reactions/media__${MED_SHARED}__mom`)));
    await assertSucceeds(
      deleteDoc(doc(db('mom'), `babies/b1/reactions/media__${MED_SHARED}__mom`)),
    );
  });
});

describe('messages (D-034)', () => {
  const message = (uid: string, context: Record<string, string>, text = 'Bà thương con.') => ({
    id: MSG,
    babyId: 'b1',
    from: uid,
    author: author(uid),
    context,
    text,
    createdAt: serverTimestamp(),
    readBy: {},
  });

  it('relatives write about shared things; caregivers "Nhắn Mẹ" from a record', async () => {
    await assertSucceeds(
      setDoc(
        doc(db('grandma'), `babies/b1/messages/${MSG}`),
        message('grandma', { kind: 'media', id: MED_SHARED }),
      ),
    );
    await assertSucceeds(getDoc(doc(db('grandma'), `babies/b1/messages/${MSG}`)));
    await assertSucceeds(getDoc(doc(db('mom'), `babies/b1/messages/${MSG}`)));
    await assertFails(getDoc(doc(db('nanny'), `babies/b1/messages/${MSG}`)));
    const other = `msg_${'5'.repeat(32)}`;
    await assertFails(
      setDoc(doc(db('grandma'), `babies/b1/messages/${other}`), {
        ...message('grandma', { kind: 'media', id: MED_PRIVATE }),
        id: other,
      }),
    );
    await assertFails(
      setDoc(doc(db('grandma'), `babies/b1/messages/${other}`), {
        ...message('grandma', { kind: 'media', id: MED_SHARED }, ''),
        id: other,
      }),
    );
    await assertSucceeds(
      setDoc(doc(db('nanny'), `babies/b1/messages/${other}`), {
        ...message('nanny', { kind: 'record', id: `r_${'6'.repeat(32)}` }),
        id: other,
      }),
    );
    await assertFails(
      setDoc(doc(db('mom'), `babies/b1/messages/msg_${'7'.repeat(32)}`), {
        ...message('mom', { kind: 'media', id: MED_SHARED }),
        id: `msg_${'7'.repeat(32)}`,
      }),
    );
  });

  it('a parent marks it read for themselves only', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `babies/b1/messages/${MSG}`), {
        ...message('grandma', { kind: 'media', id: MED_SHARED }),
        createdAt: Timestamp.now(),
      });
    });
    await assertSucceeds(
      updateDoc(doc(db('mom'), `babies/b1/messages/${MSG}`), { 'readBy.mom': true }),
    );
    await assertFails(
      updateDoc(doc(db('mom'), `babies/b1/messages/${MSG}`), { 'readBy.dad': true }),
    );
    await assertFails(updateDoc(doc(db('mom'), `babies/b1/messages/${MSG}`), { text: 'x' }));
    await assertFails(
      updateDoc(doc(db('grandma'), `babies/b1/messages/${MSG}`), { 'readBy.grandma': true }),
    );
  });
});

describe('push tokens', () => {
  const device = {
    token: 'fcm-token',
    platform: 'android',
    language: 'vi',
    updatedAt: serverTimestamp(),
  };
  const id = `d_${'8'.repeat(32)}`;

  it('each person registers only their own installs', async () => {
    await assertSucceeds(setDoc(doc(db('grandma'), `users/grandma/devices/${id}`), device));
    await assertSucceeds(getDoc(doc(db('grandma'), `users/grandma/devices/${id}`)));
    await assertFails(getDoc(doc(db('mom'), `users/grandma/devices/${id}`)));
    await assertFails(setDoc(doc(db('mom'), `users/grandma/devices/${id}`), device));
    await assertFails(
      setDoc(doc(db('grandma'), `users/grandma/devices/${id}`), { ...device, platform: 'web' }),
    );
  });
});
