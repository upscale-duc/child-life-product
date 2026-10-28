import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  assignCarePlanItems,
  dateKeyIn,
  deleteCarePlanItem,
  editableDate,
  saveCarePlanItem,
  setCarePlanItemStatus,
  shiftDateKey,
  startCarePlanDay,
} from '../functions/src/care-plan.js';

// Cùng Chăm Con (D-135) against the Firestore emulator: start a day, add / edit / delete tasks
// for today or every day, assign, done / skip, permissions. Times are Hồ Chí Minh (UTC+7).
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_cp00000000000000000001';
const vn = (d: number, hh: number, mm = 0) => new Date(Date.UTC(2026, 9, d, hh - 7, mm));
const now = vn(28, 9);
const today = '2026-10-28';
const id = (n: number) => `pi_${n.toString(16).padStart(32, '0')}`;

const member = (uid: string, role: string, status = 'active') => ({
  uid,
  babyId,
  role,
  status,
  displayName: uid,
  relation: 'other',
  relationCustom: null,
});

const items = async (date = today) =>
  (await db.collection(`babies/${babyId}/carePlanDays/${date}/items`).get()).docs.map((d) =>
    d.data(),
  );
const day = async (date = today) =>
  (await db.doc(`babies/${babyId}/carePlanDays/${date}`).get()).data();
const template = async () =>
  (await db.collection(`babies/${babyId}/carePlanTemplate`).get()).docs.map((d) => d.data());
const history = async () =>
  (await db.collection(`babies/${babyId}/carePlanHistory`).orderBy('at').get()).docs.map((d) =>
    d.data(),
  );

const item = (n: number, extra: Record<string, unknown> = {}) => ({
  babyId,
  date: today,
  itemId: id(n),
  task: 'bottle',
  title: null,
  time: '07:00',
  assignees: ['mom'],
  scope: 'today',
  ...extra,
});

beforeAll(() => {
  app = initializeApp({ projectId }, `care-plan-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  await db.doc(`babies/${babyId}`).set({ timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc(`babies/${babyId}/members/mom`).set(member('mom', 'coParent'));
  await db.doc(`babies/${babyId}/members/dad`).set(member('dad', 'coParent'));
  await db.doc(`babies/${babyId}/members/nanny`).set(member('nanny', 'caregiver'));
  await db.doc(`babies/${babyId}/members/aunt`).set(member('aunt', 'relative'));
  await db.doc(`babies/${babyId}/members/gone`).set(member('gone', 'caregiver', 'removed'));
});

describe('dates', () => {
  it('the day is the baby’s; yesterday to a week ahead can change', () => {
    expect(dateKeyIn('Asia/Ho_Chi_Minh', vn(28, 6))).toBe('2026-10-28');
    // 23:30 on the 27th in UTC is already the 28th in Hồ Chí Minh.
    expect(dateKeyIn('Asia/Ho_Chi_Minh', new Date(Date.UTC(2026, 9, 27, 23, 30)))).toBe(
      '2026-10-28',
    );
    expect(shiftDateKey('2026-10-31', 1)).toBe('2026-11-01');
    expect(editableDate('Asia/Ho_Chi_Minh', '2026-10-27', now)).toBe(true);
    expect(editableDate('Asia/Ho_Chi_Minh', '2026-10-26', now)).toBe(false);
    expect(editableDate('Asia/Ho_Chi_Minh', '2026-11-03', now)).toBe(true);
    expect(editableDate('Asia/Ho_Chi_Minh', '2026-11-04', now)).toBe(false);
  });
});

describe('starting a day (04-0)', () => {
  it('Cùng nuôi start it; caregivers and relatives cannot; a second start changes nothing', async () => {
    await expect(
      startCarePlanDay(db, 'nanny', { babyId, date: today, from: 'empty' }, now),
    ).rejects.toThrow('not-allowed');
    await expect(
      startCarePlanDay(db, 'aunt', { babyId, date: today, from: 'empty' }, now),
    ).rejects.toThrow('not-allowed');
    expect(await startCarePlanDay(db, 'mom', { babyId, date: today, from: 'empty' }, now)).toEqual({
      created: true,
      items: 0,
    });
    expect(
      await startCarePlanDay(db, 'dad', { babyId, date: today, from: 'yesterday' }, now),
    ).toEqual({ created: false, items: 0 });
    expect((await day())!.revision).toBe(1);
    expect((await day())!.createdBy).toBe('mom');
  });

  it('refuses old days', async () => {
    await expect(
      startCarePlanDay(db, 'mom', { babyId, date: '2026-10-20', from: 'empty' }, now),
    ).rejects.toThrow('day-closed');
  });

  it('“Giống hôm qua” copies yesterday open, without who has left', async () => {
    const y = shiftDateKey(today, -1);
    await startCarePlanDay(db, 'mom', { babyId, date: y, from: 'empty' }, now);
    await saveCarePlanItem(db, 'mom', item(1, { date: y, assignees: ['nanny'] }), now);
    await saveCarePlanItem(db, 'mom', item(2, { date: y, time: '18:30', task: 'bath' }), now);
    await setCarePlanItemStatus(db, 'mom', { babyId, date: y, itemId: id(1), status: 'done' }, now);
    await db.doc(`babies/${babyId}/members/nanny`).update({ status: 'removed' });

    const r = await startCarePlanDay(db, 'dad', { babyId, date: today, from: 'yesterday' }, now);
    expect(r).toEqual({ created: true, items: 2 });
    const copied = (await items()).sort((a, b) => a.time.localeCompare(b.time));
    expect(copied.map((i) => [i.task, i.time, i.status, i.assignees])).toEqual([
      ['bottle', '07:00', 'open', []],
      ['bath', '18:30', 'open', ['mom']],
    ]);
  });

  it('“Mọi ngày” tasks start the next day', async () => {
    await startCarePlanDay(db, 'mom', { babyId, date: today, from: 'empty' }, now);
    await saveCarePlanItem(
      db,
      'mom',
      item(1, { task: 'vitamin', time: '09:00', scope: 'everyDay' }),
      now,
    );
    await saveCarePlanItem(db, 'mom', item(2, { task: 'read', time: '20:00' }), now);
    expect((await template()).map((t) => t.task)).toEqual(['vitamin']);

    const tomorrow = shiftDateKey(today, 1);
    await startCarePlanDay(db, 'mom', { babyId, date: tomorrow, from: 'everyday' }, now);
    const next = await items(tomorrow);
    expect(next.map((i) => [i.task, i.time])).toEqual([['vitamin', '09:00']]);
    expect(next[0]!.templateId).toBe((await template())[0]!.id);
  });
});

describe('tasks (06, 06b)', () => {
  beforeEach(async () => {
    await startCarePlanDay(db, 'mom', { babyId, date: today, from: 'empty' }, now);
  });

  it('only managers add; assignees are parents and caregivers; the day must exist', async () => {
    await expect(saveCarePlanItem(db, 'nanny', item(1), now)).rejects.toThrow('not-allowed');
    await expect(
      saveCarePlanItem(db, 'mom', item(1, { assignees: ['aunt'] }), now),
    ).rejects.toThrow('assignee-not-allowed');
    await expect(
      saveCarePlanItem(db, 'mom', item(1, { assignees: ['gone'] }), now),
    ).rejects.toThrow('assignee-not-allowed');
    await expect(
      saveCarePlanItem(db, 'mom', item(1, { date: shiftDateKey(today, 1) }), now),
    ).rejects.toThrow('no-day');
    await expect(
      saveCarePlanItem(db, 'mom', item(1, { task: 'custom', title: null }), now),
    ).rejects.toThrow('malformed');
  });

  it('“Ba và Mẹ cùng làm” is one task with two people; edits keep status', async () => {
    await saveCarePlanItem(db, 'dad', item(1, { assignees: ['mom', 'dad'] }), now);
    await setCarePlanItemStatus(
      db,
      'nanny',
      { babyId, date: today, itemId: id(1), status: 'done' },
      now,
    );
    await saveCarePlanItem(db, 'mom', item(1, { time: '07:30', assignees: ['dad'] }), now);
    const [i] = await items();
    expect(i).toMatchObject({ time: '07:30', assignees: ['dad'], status: 'done', doneBy: 'nanny' });
    expect((await day())!.revision).toBe(4);
  });

  it('a custom task keeps its title; a known task never stores one', async () => {
    await saveCarePlanItem(db, 'mom', item(1, { task: 'custom', title: 'Nhỏ mũi' }), now);
    await saveCarePlanItem(db, 'mom', item(2, { task: 'bath', title: 'ignored' }), now);
    const byId = Object.fromEntries((await items()).map((i) => [i.id, i]));
    expect(byId[id(1)]!.title).toBe('Nhỏ mũi');
    expect(byId[id(2)]!.title).toBeNull();
  });

  it('delete: today only keeps the everyday task; every day removes it', async () => {
    await saveCarePlanItem(db, 'mom', item(1, { scope: 'everyDay' }), now);
    await saveCarePlanItem(db, 'mom', item(2, { scope: 'everyDay', time: '13:00' }), now);
    await deleteCarePlanItem(
      db,
      'mom',
      { babyId, date: today, itemId: id(1), scope: 'today' },
      now,
    );
    expect(await template()).toHaveLength(2);
    await deleteCarePlanItem(
      db,
      'mom',
      { babyId, date: today, itemId: id(2), scope: 'everyDay' },
      now,
    );
    expect(await template()).toHaveLength(1);
    expect(await items()).toHaveLength(0);
    // A retry of a delete is harmless.
    expect(
      await deleteCarePlanItem(
        db,
        'mom',
        { babyId, date: today, itemId: id(2), scope: 'today' },
        now,
      ),
    ).toEqual({ deleted: false });
  });
});

describe('assigning (05) and the ring', () => {
  beforeEach(async () => {
    await startCarePlanDay(db, 'mom', { babyId, date: today, from: 'empty' }, now);
    await saveCarePlanItem(db, 'mom', item(1), now);
    await saveCarePlanItem(db, 'mom', item(2, { time: '08:30', task: 'sleep' }), now);
  });

  it('“Giao cả ca” gives the whole group to one person', async () => {
    await assignCarePlanItems(
      db,
      'dad',
      { babyId, date: today, itemIds: [id(1), id(2)], assignees: ['nanny'] },
      now,
    );
    expect((await items()).every((i) => i.assignees.join() === 'nanny')).toBe(true);
    await expect(
      assignCarePlanItems(
        db,
        'nanny',
        { babyId, date: today, itemIds: [id(1)], assignees: [] },
        now,
      ),
    ).rejects.toThrow('not-allowed');
  });

  it('anyone who cares may mark done (who did it is recorded); undo; skip needs a manager', async () => {
    const r = await setCarePlanItemStatus(
      db,
      'dad',
      { babyId, date: today, itemId: id(1), status: 'done' },
      now,
    );
    expect(r).toEqual({ status: 'done', doneBy: 'dad' });
    // Mẹ was assigned, Ba did it: the plan keeps Mẹ, the task records Ba.
    expect((await items()).find((i) => i.id === id(1))).toMatchObject({
      assignees: ['mom'],
      doneBy: 'dad',
    });
    // A retry changes nothing.
    await setCarePlanItemStatus(
      db,
      'dad',
      { babyId, date: today, itemId: id(1), status: 'done' },
      now,
    );
    await setCarePlanItemStatus(
      db,
      'mom',
      { babyId, date: today, itemId: id(1), status: 'open' },
      now,
    );
    expect((await items()).find((i) => i.id === id(1))).toMatchObject({
      status: 'open',
      doneBy: null,
    });

    await expect(
      setCarePlanItemStatus(
        db,
        'nanny',
        { babyId, date: today, itemId: id(2), status: 'skipped' },
        now,
      ),
    ).rejects.toThrow('not-allowed');
    await expect(
      setCarePlanItemStatus(
        db,
        'aunt',
        { babyId, date: today, itemId: id(2), status: 'done' },
        now,
      ),
    ).rejects.toThrow('not-allowed');
    await setCarePlanItemStatus(
      db,
      'mom',
      { babyId, date: today, itemId: id(2), status: 'skipped' },
      now,
    );

    // Same clock in this test, so compare as a set; one entry per change.
    expect((await history()).map((h) => h.action).sort()).toEqual([
      'add',
      'add',
      'done',
      'skip',
      'start',
      'undone',
    ]);
  });
});
