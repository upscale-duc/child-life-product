import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  AiUnavailable,
  openAiProvider,
  templateProvider,
  type AiProvider,
} from '../functions/src/ai.js';
import {
  StoryError,
  deleteStory,
  saveStory,
  storyAssist,
  suggestStory,
} from '../functions/src/stories.js';

// S12 server side against the Firestore emulator: save with one notice and D-002 photo sharing,
// re-save without a notice (P-091), delete (G-050), paragraph help with guardrails and a daily
// limit (P-092), and the weekly suggestion (P-090, R-196, Q-036) with the template fallback.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z');
let app: App;
let db: Firestore;
const babyId = 'b_5701000000000000000a';
const familyId = 'f_s12';
const story = `sto_${'1'.repeat(32)}`;
let seq = 0;
const med = () => `med_${(++seq).toString(16).padStart(32, '0')}`;

async function item(audience: 'family' | 'parents', extra: Record<string, unknown> = {}) {
  const id = med();
  await db.doc(`babies/${babyId}/media/${id}`).set({
    id,
    babyId,
    familyId,
    type: 'photo',
    audience,
    effectiveAudience: audience,
    albumIds: [],
    status: 'ready',
    deleted: false,
    captureAt: new Date(now.getTime() - seq * 3_600_000),
    createdBy: 'mom',
    ...extra,
  });
  return id;
}

const get = async (path: string) => (await db.doc(path).get()).data();
const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StoryError ? e.reason : String(e);
  }
};

async function draft(mediaIds: string[], extra: Record<string, unknown> = {}) {
  await db.doc(`babies/${babyId}/stories/${story}`).set({
    id: story,
    babyId,
    kind: 'story',
    origin: 'manual',
    suggestion: false,
    status: 'draft',
    title: 'Tuần Teddy biết cười',
    coverMediaId: mediaIds[0] ?? null,
    blocks: [
      { id: 'b0', type: 'paragraph', text: 'Sáng thứ Hai Teddy cười.', ai: false },
      ...(mediaIds.length > 1
        ? [
            {
              id: 'b1',
              type: 'photos',
              items: mediaIds.slice(1).map((m) => ({ mediaId: m, caption: null })),
            },
          ]
        : []),
    ],
    audience: 'family',
    createdBy: 'mom',
    author: { name: 'Mai', relation: 'mother', relationCustom: null },
    loveCount: 0,
    createdAt: now,
    updatedAt: now,
    ...extra,
  });
}

beforeAll(() => {
  app = initializeApp({ projectId }, `stories-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://127.0.0.1:8080/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {
      method: 'DELETE',
    },
  );
  seq = 0;
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    familyId,
    state: 'active',
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  for (const [uid, role, relation, name] of [
    ['mom', 'coParent', 'mother', 'Mai'],
    ['dad', 'coParent', 'father', 'Minh'],
    ['nanny', 'caregiver', 'nanny', 'Cô Lan'],
    ['grandma', 'relative', 'grandmother', 'Bà nội Hoa'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      relation,
      relationCustom: null,
      displayName: name,
      status: 'active',
    });
  }
});

describe('save and delete (14f, P-091, D-002, G-050)', () => {
  it('first Gia đình save shares its photos and sends one notice; re-saves do not', async () => {
    const shared = await item('family');
    const priv = await item('parents');
    await draft([shared, priv]);
    const first = await saveStory(
      db,
      'mom',
      { babyId, storyId: story, audience: 'family', notifyFamily: true },
      now,
    );
    expect(first.madeVisible).toBe(1);
    expect(first.notificationId).not.toBeNull();
    expect((await get(`babies/${babyId}/media/${priv}`))!.effectiveAudience).toBe('family');
    const notice = (await get(`babies/${babyId}/notifications/${first.notificationId}`))!;
    expect(notice.kind).toBe('story');
    expect([...notice.recipients].sort()).toEqual(['dad', 'grandma']);

    const again = await saveStory(
      db,
      'dad',
      { babyId, storyId: story, audience: 'family', notifyFamily: true },
      now,
    );
    expect(again.notificationId).toBeNull();
    expect((await get(`babies/${babyId}/stories/${story}`))!.status).toBe('saved');
  });

  it('Chỉ ba mẹ takes the photos back; deleting keeps the memories', async () => {
    const priv = await item('parents');
    await draft([priv]);
    await saveStory(
      db,
      'mom',
      { babyId, storyId: story, audience: 'family', notifyFamily: false },
      now,
    );
    expect((await get(`babies/${babyId}/media/${priv}`))!.effectiveAudience).toBe('family');
    await saveStory(
      db,
      'mom',
      { babyId, storyId: story, audience: 'parents', notifyFamily: false },
      now,
    );
    expect((await get(`babies/${babyId}/media/${priv}`))!.effectiveAudience).toBe('parents');
    await saveStory(
      db,
      'mom',
      { babyId, storyId: story, audience: 'family', notifyFamily: false },
      now,
    );
    await db
      .doc(`babies/${babyId}/reactions/story__${story}__grandma`)
      .set({ target: 'story', targetId: story, uid: 'grandma' });
    await deleteStory(db, 'dad', { babyId, storyId: story }, now);
    expect(await get(`babies/${babyId}/stories/${story}`)).toBeUndefined();
    expect(await get(`babies/${babyId}/reactions/story__${story}__grandma`)).toBeUndefined();
    const m = (await get(`babies/${babyId}/media/${priv}`))!;
    expect(m.effectiveAudience).toBe('parents');
    expect(m.deleted).toBe(false);
  });

  it('parents only; no title or a deleted photo refuses the save', async () => {
    const a = await item('family');
    await draft([a]);
    expect(
      await reason(
        saveStory(
          db,
          'grandma',
          { babyId, storyId: story, audience: 'family', notifyFamily: true },
          now,
        ),
      ),
    ).toBe('parents-only');
    await draft([a], { title: '  ' });
    expect(
      await reason(
        saveStory(
          db,
          'mom',
          { babyId, storyId: story, audience: 'family', notifyFamily: true },
          now,
        ),
      ),
    ).toBe('title-required');
    await db.doc(`babies/${babyId}/media/${a}`).update({ deleted: true });
    await draft([a]);
    expect(
      await reason(
        saveStory(
          db,
          'mom',
          { babyId, storyId: story, audience: 'family', notifyFamily: true },
          now,
        ),
      ),
    ).toBe('media-missing');
  });
});

describe('AI help (14b, 14c, P-092)', () => {
  const ask = (op: string, text = 'Sáng thứ Hai Teddy cười.') =>
    ({ babyId, storyId: story, blockId: 'b0', op, text, locale: 'vi' }) as const;

  it('guarded options; invented facts are dropped; unavailable is said plainly', async () => {
    await draft([]);
    const fake: AiProvider = {
      name: 'openai',
      draft: async () => ({ title: 't', paragraphs: ['p'], quote: null }),
      assist: async () => [
        'Sáng thứ Hai Teddy nhoẻn miệng cười.',
        'Teddy cười lúc 7 giờ ở Đà Lạt.',
      ],
    };
    expect(await storyAssist(db, fake, 'mom', ask('warmer'), now)).toEqual({
      options: ['Sáng thứ Hai Teddy nhoẻn miệng cười.'],
    });
    expect(await reason(storyAssist(db, templateProvider, 'mom', ask('warmer'), now))).toBe(
      'ai-unavailable',
    );
    const down: AiProvider = {
      ...fake,
      assist: async () => {
        throw new AiUnavailable('500');
      },
    };
    expect(await reason(storyAssist(db, down, 'mom', ask('rewrite'), now))).toBe('ai-unavailable');
    expect(await reason(storyAssist(db, fake, 'nanny', ask('rewrite'), now))).toBe('parents-only');
  });

  it('a daily limit per person', async () => {
    await draft([]);
    await db.doc(`rateLimits/storyAssist_mom_${now.toISOString().slice(0, 10)}`).set({ count: 60 });
    const fake: AiProvider = { ...templateProvider, name: 'openai', assist: async () => ['x'] };
    expect(await reason(storyAssist(db, fake, 'mom', ask('rewrite'), now))).toBe('assist-limit');
  });

  it('OpenAI is asked not to store and only gets text', async () => {
    const calls: Array<{ url: string; body: Record<string, unknown> }> = [];
    const fetchImpl = (async (url: string, init: { body: string }) => {
      calls.push({ url, body: JSON.parse(init.body) as Record<string, unknown> });
      return new Response(
        JSON.stringify({
          choices: [{ message: { content: JSON.stringify({ options: ['A.'] }) } }],
        }),
      );
    }) as unknown as typeof fetch;
    const p = openAiProvider('k', 'gpt-test', fetchImpl);
    expect(await p.assist('shorter', 'Teddy cười.', { nickname: 'Teddy', locale: 'vi' })).toEqual([
      'A.',
    ]);
    expect(calls[0]!.url).toContain('api.openai.com');
    expect(calls[0]!.body.store).toBe(false);
    expect(JSON.stringify(calls[0]!.body)).not.toMatch(/image|base64/i);
  });
});

describe('weekly suggestion (P-090, R-196, Q-036)', () => {
  async function week(n: number) {
    for (let i = 0; i < n; i++) await item(i % 2 ? 'family' : 'parents');
    await db.doc(`babies/${babyId}/memories/mem_1`).set({
      occurredAt: new Date(now.getTime() - 3_600_000),
      caption: 'Sáng thứ Hai Teddy cười khi mẹ hát ru.',
      author: { name: 'Mai', relation: 'mother', relationCustom: null },
      mediaIds: [],
      milestone: { id: 'ms_x', name: 'Lần đầu cười', date: '2026-10-05' },
      deleted: false,
    });
  }

  it('needs 5 items and the flag; attaches up to 9 photos; at most 3 a week', async () => {
    await week(3);
    expect(
      (await suggestStory(db, templateProvider, babyId, 'vi', now, { ignoreFlag: true })).reason,
    ).toBe('too-few-items');
    await week(10);
    expect((await suggestStory(db, templateProvider, babyId, 'vi', now)).reason).toBe('flag-off');
    const made = await suggestStory(db, templateProvider, babyId, 'vi', now, { ignoreFlag: true });
    expect(made.reason).toBe('created');
    const s = (await get(`babies/${babyId}/stories/${made.storyId}`))!;
    expect(s).toMatchObject({ origin: 'ai', suggestion: true, status: 'draft', createdBy: 'ai' });
    const photos = s.blocks
      .filter((b: { type: string }) => b.type === 'photos')
      .flatMap((b: { items: unknown[] }) => b.items);
    expect(photos.length + 1).toBeLessThanOrEqual(9);
    expect(s.blocks.some((b: { type: string }) => b.type === 'milestone')).toBe(true);
    for (let i = 0; i < 2; i++)
      await suggestStory(db, templateProvider, babyId, 'vi', now, { ignoreFlag: true });
    expect(
      (await suggestStory(db, templateProvider, babyId, 'vi', now, { ignoreFlag: true })).reason,
    ).toBe('weekly-limit');
  });

  it('an inventing model falls back to the template draft (no partial text, G-051)', async () => {
    await week(10);
    const inventing: AiProvider = {
      name: 'openai',
      draft: async () => ({
        title: 'Teddy đi Đà Lạt',
        paragraphs: ['Teddy nặng 7 ký.'],
        quote: null,
      }),
      assist: async () => [],
    };
    const made = await suggestStory(db, inventing, babyId, 'vi', now, { ignoreFlag: true });
    expect(made.provider).toBe('template');
    const s = (await get(`babies/${babyId}/stories/${made.storyId}`))!;
    expect(JSON.stringify(s.blocks)).not.toContain('Đà Lạt');
  });
});
