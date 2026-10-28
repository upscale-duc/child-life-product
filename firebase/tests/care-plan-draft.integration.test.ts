import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { rhythmDraft, rhythmReady, templateDraft, usualTimes } from '@child-life/contracts';
import {
  publishCarePlanDay,
  saveCarePlanItem,
  setCarePlanAutoDraft,
  startCarePlanDay,
} from '../functions/src/care-plan.js';
import { draftCarePlanMornings } from '../functions/src/care-plan-morning.js';
import { ringCareTaskReminders } from '../functions/src/care-plan-reminders.js';
import type { PushSender } from '../functions/src/social.js';

// Cùng Chăm Con step 4 (D-136) against the Firestore emulator: drafted days ("Theo nhịp của bé",
// the reference templates), "Dùng lịch này", "Đổi cách khác", and the morning draft + N5. Times
// are Hồ Chí Minh (UTC+7); 12 Nov 2026 keeps clear of other suites' plans.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_cpd0000000000000000001';
const date = '2026-11-12';
const vn = (d: number, hh: number, mm = 0) => new Date(Date.UTC(2026, 10, d, hh - 7, mm));
const now = vn(12, 6);
const mom = 'cpd_mom';
const dad = 'cpd_dad';
const nanny = 'cpd_nanny';
let run = 0;

const member = (uid: string, role: string) => ({
  uid,
  babyId,
  role,
  status: 'active',
  displayName: uid,
  relation: 'other',
  relationCustom: null,
});

const sent: { token: string; title: string; body: string; data: Record<string, string> }[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    for (const token of tokens) sent.push({ token, ...message });
    return [];
  },
};
const to = (uid: string) => sent.filter((s) => s.token === `t-${uid}`);

const day = async (d = date) => (await db.doc(`babies/${babyId}/carePlanDays/${d}`).get()).data();
const items = async (d = date) =>
  (await db.collection(`babies/${babyId}/carePlanDays/${d}/items`).get()).docs
    .map((x) => x.data())
    .sort((a, b) => String(a.time).localeCompare(String(b.time)));

/** A care record at [hh:mm] on 2026-11-[d] (baby time). */
async function log(type: string, d: number, hh: number, mm = 0) {
  await db.collection(`babies/${babyId}/records`).add({
    type,
    occurredAt: Timestamp.fromDate(vn(d, hh, mm)),
    deleted: false,
  });
}

/** Bottles at 07:00, 10:30, 14:00 and naps at 09:00, 13:00 on the 7 days before the 12th. */
async function sevenDays(skip: number | null = null) {
  for (let d = 5; d <= 11; d += 1) {
    if (d === skip) continue;
    await log('bottle', d, 7, d % 2 === 0 ? 5 : 0);
    await log('bottle', d, 10, 30);
    await log('bottle', d, 14);
    await log('sleep', d, 9);
    await log('sleep', d, 13, d % 3 === 0 ? 10 : 0);
  }
}

beforeAll(() => {
  app = initializeApp({ projectId }, `care-plan-draft-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  sent.length = 0;
  run += 1;
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  await db.doc(`babies/${babyId}/restricted/profile`).set({ dateOfBirth: '2026-07-01' });
  for (const [uid, role] of [
    [mom, 'coParent'],
    [dad, 'coParent'],
    [nanny, 'caregiver'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set(member(uid, role));
    await db.doc(`users/${uid}/devices/d1`).set({ token: `t-${uid}`, language: 'vi' });
    await db.recursiveDelete(db.collection(`users/${uid}/notifications`)).catch(() => undefined);
  }
});

describe('drafting (pure)', () => {
  it('usual times: half the days at least, at the median, apart by the gap', () => {
    const at = (date: string, minute: number) => ({ date, minute });
    const times = usualTimes(
      [at('a', 420), at('b', 425), at('c', 415), at('a', 600), at('d', 900)],
      4,
      90,
      10,
    );
    expect(times).toEqual([420]);
  });

  it('needs every one of the 7 days with a feed and a sleep (D-136 #2)', () => {
    const dates = ['1', '2', '3', '4', '5', '6', '7'];
    const full = dates.flatMap((d) => [
      { kind: 'feed' as const, date: d, minute: 420 },
      { kind: 'sleep' as const, date: d, minute: 540 },
    ]);
    expect(rhythmReady(full, dates)).toBe(true);
    expect(
      rhythmReady(
        full.filter((e) => !(e.date === '4' && e.kind === 'sleep')),
        dates,
      ),
    ).toBe(false);
    expect(rhythmDraft(full, 7, 'breast')).toEqual([
      { task: 'breast', time: '07:00' },
      { task: 'sleep', time: '09:00' },
    ]);
  });

  it('templates never hold medicine or vitamins', () => {
    for (const m of ['basic', 'easy35', 'easy4'] as const) {
      for (const age of [1, 4, 8, 18]) {
        const tasks = templateDraft(m, age, 'bottle').map((t) => t.task);
        expect(tasks).not.toContain('medicine');
        expect(tasks).not.toContain('vitamin');
        expect(tasks.length).toBeGreaterThan(3);
      }
    }
  });
});

describe('Theo nhịp của bé', () => {
  it('drafts the usual times; the draft is not reminded until “Dùng lịch này”', async () => {
    await sevenDays();
    expect(await startCarePlanDay(db, mom, { babyId, date, from: 'rhythm' }, now)).toEqual({
      created: true,
      items: 5,
      draft: true,
    });
    expect(await day()).toMatchObject({ status: 'draft', source: 'rhythm' });
    expect((await items()).map((i) => `${i.time} ${i.task}`)).toEqual([
      '07:00 bottle',
      '09:00 sleep',
      '10:30 bottle',
      '13:00 sleep',
      '14:00 bottle',
    ]);
    expect((await items()).every((i) => i.draft === true)).toBe(true);
    // A task given to Ba inside the draft still waits.
    const first = (await items())[0]!;
    await saveCarePlanItem(
      db,
      mom,
      {
        babyId,
        date,
        itemId: first.id,
        task: 'bottle',
        title: null,
        time: '07:00',
        assignees: [dad],
        scope: 'today',
      },
      now,
    );
    await ringCareTaskReminders(db, sender, vn(12, 6, 55));
    expect(to(dad)).toHaveLength(0);

    expect(await publishCarePlanDay(db, mom, { babyId, date }, now)).toEqual({ published: true });
    expect(await publishCarePlanDay(db, dad, { babyId, date }, now)).toEqual({ published: false });
    expect(await day()).toMatchObject({ status: 'published', publishedBy: mom });
    expect((await items()).some((i) => 'draft' in i)).toBe(false);
    await ringCareTaskReminders(db, sender, vn(12, 6, 55));
    expect(to(dad)).toHaveLength(1);
  });

  it('refuses when a day of the 7 is missing; the method is kept for the mornings', async () => {
    await sevenDays(8);
    await expect(startCarePlanDay(db, mom, { babyId, date, from: 'rhythm' }, now)).rejects.toThrow(
      'not-enough-data',
    );
    expect(await day()).toBeUndefined();
    await startCarePlanDay(db, mom, { babyId, date, from: 'easy4' }, now);
    expect((await db.doc(`babies/${babyId}/carePlanSettings/family`).get()).get('method')).toBe(
      'easy4',
    );
  });

  it('“Đổi cách khác” replaces a draft; a published day is never replaced', async () => {
    await startCarePlanDay(db, mom, { babyId, date, from: 'easy35' }, now);
    const easy = await items();
    await startCarePlanDay(db, dad, { babyId, date, from: 'basic' }, now);
    const basic = await items();
    expect(basic.map((i) => i.id)).not.toEqual(easy.map((i) => i.id));
    expect(await day()).toMatchObject({ status: 'draft', source: 'basic', revision: 2 });
    // Choosing the family's own way starts the day at once.
    await startCarePlanDay(db, dad, { babyId, date, from: 'empty' }, now);
    expect(await day()).toMatchObject({ status: 'published', source: 'empty' });
    expect(await items()).toHaveLength(0);
    expect(await startCarePlanDay(db, mom, { babyId, date, from: 'easy4' }, now)).toMatchObject({
      created: false,
      draft: false,
    });
  });

  it('EASY only under 6 months (D-136 #4): a 3-year-old gets the basic plan', async () => {
    await db.doc(`babies/${babyId}/restricted/profile`).set({ dateOfBirth: '2023-09-01' });
    for (const from of ['easy35', 'easy4'] as const) {
      await expect(startCarePlanDay(db, mom, { babyId, date, from }, now)).rejects.toThrow(
        'template-unavailable',
      );
    }
    await startCarePlanDay(db, mom, { babyId, date, from: 'basic' }, now);
    expect((await items()).map((i) => i.task)).toContain('teeth');
  });

  it('caregivers neither draft nor use a plan', async () => {
    await expect(startCarePlanDay(db, nanny, { babyId, date, from: 'basic' }, now)).rejects.toThrow(
      'not-allowed',
    );
    await startCarePlanDay(db, mom, { babyId, date, from: 'basic' }, now);
    await expect(publishCarePlanDay(db, nanny, { babyId, date }, now)).rejects.toThrow(
      'not-allowed',
    );
  });
});

describe('Tự tạo lịch mỗi sáng + N5', () => {
  async function everyday() {
    await startCarePlanDay(db, mom, { babyId, date: '2026-11-11', from: 'empty' }, vn(11, 6));
    for (const [n, time] of [
      [1, '07:00'],
      [2, '10:00'],
    ] as const) {
      await saveCarePlanItem(
        db,
        mom,
        {
          babyId,
          date: '2026-11-11',
          itemId: `pi_${(run * 16 + n).toString(16).padStart(32, 'd')}`,
          task: 'bottle',
          title: null,
          time,
          assignees: [dad],
          scope: 'everyDay',
        },
        vn(11, 6),
      );
    }
    await startCarePlanDay(db, mom, { babyId, date: '2026-11-11', from: 'everyday' }, vn(11, 6));
  }

  it('off by default; managers turn it on; caregivers cannot', async () => {
    await everyday();
    await draftCarePlanMornings(db, sender, vn(12, 7));
    expect(await day()).toBeUndefined();
    await expect(setCarePlanAutoDraft(db, nanny, { babyId, on: true }, now)).rejects.toThrow(
      'not-allowed',
    );
    expect(await setCarePlanAutoDraft(db, dad, { babyId, on: true }, now)).toEqual({ on: true });
  });

  it('after 06:30 drafts today the family’s way and pushes each manager once', async () => {
    await everyday();
    await setCarePlanAutoDraft(db, mom, { babyId, on: true }, vn(11, 20));
    await draftCarePlanMornings(db, sender, vn(12, 6, 15));
    expect(await day()).toBeUndefined();

    await draftCarePlanMornings(db, sender, vn(12, 6, 30));
    expect(await day()).toMatchObject({ status: 'draft', source: 'everyday', createdBy: 'system' });
    const drafted = await items();
    expect(drafted.map((i) => i.time)).toEqual(['07:00', '10:00']);
    expect(drafted.every((i) => i.draft === true && i.assignees[0] === dad)).toBe(true);
    expect(to(mom)).toHaveLength(1);
    expect(to(dad)).toHaveLength(1);
    expect(to(nanny)).toHaveLength(0);
    expect(to(mom)[0]).toMatchObject({
      title: 'Lịch của Teddy đã sẵn',
      body: '2 việc · bắt đầu 07:00 Bú bình. Xem rồi chọn Dùng lịch này nhé.',
    });
    expect(to(mom)[0]!.data).toMatchObject({ destination: 'CARE_PLAN_READY', babyId, date });

    // Later runs that morning change nothing; nor is Ba reminded of the draft.
    await draftCarePlanMornings(db, sender, vn(12, 6, 45));
    await ringCareTaskReminders(db, sender, vn(12, 6, 55));
    expect(sent).toHaveLength(2);
  });

  it('a day the family already started is left alone, and nobody is pushed', async () => {
    await everyday();
    await setCarePlanAutoDraft(db, mom, { babyId, on: true }, vn(11, 20));
    await startCarePlanDay(db, dad, { babyId, date, from: 'empty' }, vn(12, 5));
    await draftCarePlanMornings(db, sender, vn(12, 7));
    expect(await day()).toMatchObject({ status: 'published', createdBy: dad });
    expect(sent).toHaveLength(0);
  });
});
