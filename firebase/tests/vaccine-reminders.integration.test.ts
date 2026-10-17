import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { ringVaccineReminders, snoozeVaccineReminder } from '../functions/src/vaccine-reminders.js';
import type { PushSender } from '../functions/src/social.js';

// Sổ tiêm chủng reminders (P-133) against the Firestore emulator: the evening before at 19:00 to
// the chosen recipients, once; "Nhắc lại sáng mai" rings at 07:00. Times are Hồ Chí Minh (UTC+7).
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_vx000000000000000001';
const vn = (d: string, h: number, m = 0) =>
  new Date(`${d}T${String(h - 7).padStart(2, '0')}:${String(m).padStart(2, '0')}:00Z`);

const sent: { tokens: string[]; title: string; body: string; data: Record<string, string> }[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    sent.push({ tokens, title: message.title, body: message.body, data: message.data });
    return [];
  },
};

const member = (uid: string, role: string) => ({ uid, babyId, role, status: 'active' });

beforeAll(() => {
  app = initializeApp({ projectId }, `vx-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  sent.length = 0;
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  await db.doc(`babies/${babyId}`).set({ timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc(`babies/${babyId}/members/mom`).set(member('mom', 'coParent'));
  await db.doc(`babies/${babyId}/members/dad`).set(member('dad', 'coParent'));
  await db.doc(`babies/${babyId}/members/nanny`).set(member('nanny', 'caregiver'));
  await db.doc(`babies/${babyId}/members/aunt`).set(member('aunt', 'relative'));
  for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
    // Other files on this emulator leave devices and settings for the same uids.
    await db.recursiveDelete(db.doc(`users/${uid}`));
    await db
      .doc(`users/${uid}/devices/d_${uid}`)
      .set({ token: `t-${uid}`, language: uid === 'dad' ? 'en' : 'vi' });
  }
  for (const id of ['vitk', 'bcg', 'hepb']) {
    await db.doc(`babies/${babyId}/vaccines/${id}_1`).set({ status: 'given', plannedOn: null });
  }
  await db.doc(`babies/${babyId}/vaccinePlan/main`).set({
    dtp: null,
    setupDone: true,
    scheduleFrom: '2026-09-17',
    remind: true,
    recipients: ['mom', 'dad'],
    bookPhotos: [],
  });
});

describe('ringing (VX 8)', () => {
  it('the evening before at 19:00, to the chosen recipients, once', async () => {
    expect((await ringVaccineReminders(db, sender, vn('2026-11-16', 18, 55))).rang).toBe(0);
    const { rang } = await ringVaccineReminders(db, sender, vn('2026-11-16', 19, 0));
    expect(rang).toBe(1);
    expect(sent.map((s) => s.tokens[0]).sort()).toEqual(['t-dad', 't-mom']);
    const vi = sent.find((s) => s.tokens[0] === 't-mom')!;
    expect(vi.title).toBe('Ngày mai có lịch tiêm của bé');
    // EN08 (D-076 #2): what to bring.
    expect(vi.body).toBe(
      '6in1 · Rota · Phế cầu (mũi 1) · Mốc 2 tháng tuổi. Nhớ mang sổ tiêm và một chiếc khăn mỏng.',
    );
    expect(vi.data).toMatchObject({ kind: 'vaccine', babyId, date: '2026-11-17', months: '2' });
    expect((await ringVaccineReminders(db, sender, vn('2026-11-16', 19, 5))).rang).toBe(0);
  });

  it('a family abroad hears only of the doses it dated itself (D-078)', async () => {
    await db.doc('families/f_vx_abroad').set({ ownerUid: 'mom', country: 'US' });
    await db.doc(`babies/${babyId}`).set({ familyId: 'f_vx_abroad' }, { merge: true });
    try {
      expect((await ringVaccineReminders(db, sender, vn('2026-11-16', 19, 0))).rang).toBe(0);
      await db
        .doc(`babies/${babyId}/vaccines/dtp_1`)
        .set({ status: 'planned', plannedOn: '2026-11-20' });
      const { rang } = await ringVaccineReminders(db, sender, vn('2026-11-19', 19, 0));
      expect(rang).toBe(1);
      expect(sent[0]!.data).toMatchObject({ date: '2026-11-20' });
    } finally {
      await db.doc('families/f_vx_abroad').delete();
    }
  });

  it('follows the schedule approved on the portal (P-138)', async () => {
    const { vaccineSchedule } = await import('@child-life/contracts');
    const rows = vaccineSchedule.map((v) =>
      v.id === 'pcv' || v.id === 'rota' ? { ...v, months: v.months.map((m) => m + 1) } : v,
    );
    await db.doc('publicConfig/reference_vaccines').set({
      dataset: 'vaccines.schedule',
      version: 'v2026.10',
      publishedAt: '2026-10-17T00:00:00.000Z',
      rows,
    });
    try {
      await ringVaccineReminders(db, sender, vn('2026-11-16', 19, 0));
      const vi = sent.find((m) => m.tokens[0] === 't-mom')!;
      expect(vi.body).toMatch(/^6in1 \(mũi 1\) · Mốc 2 tháng tuổi/);
    } finally {
      await db.doc('publicConfig/reference_vaccines').delete();
    }
  });

  it('off, or nobody chosen → everyone eligible; relatives never', async () => {
    await db.doc(`babies/${babyId}/vaccinePlan/main`).update({ recipients: [] });
    await ringVaccineReminders(db, sender, vn('2026-11-14', 19, 0));
    expect(sent.map((s) => s.tokens[0]).sort()).toEqual(['t-dad', 't-mom', 't-nanny']);
    sent.length = 0;
    await db.doc(`babies/${babyId}/vaccinePlan/main`).update({ remind: false });
    expect((await ringVaccineReminders(db, sender, vn('2026-11-16', 19, 0))).rang).toBe(0);
  });
});

describe('"Nhắc lại sáng mai"', () => {
  it('parents and caregivers snooze to 07:00 on the day; relatives cannot', async () => {
    await expect(
      snoozeVaccineReminder(db, 'aunt', { babyId, date: '2026-11-17' }, vn('2026-11-16', 19, 1)),
    ).rejects.toThrow('not-allowed');
    await snoozeVaccineReminder(
      db,
      'nanny',
      { babyId, date: '2026-11-17' },
      vn('2026-11-16', 19, 1),
    );
    const { rang } = await ringVaccineReminders(db, sender, vn('2026-11-17', 7, 0));
    expect(rang).toBe(1);
    expect(sent.find((x) => x.tokens[0] === 't-mom')!.title).toBe('Hôm nay có lịch tiêm của bé');
  });
});
