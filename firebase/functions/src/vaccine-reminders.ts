import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';
import { localDateIn, plannedDate, scheduleFor, type VaccineDef } from '@child-life/contracts';
import { mutedRecipients } from './account.js';
import type { PushSender } from './social.js';

/**
 * Sổ tiêm chủng reminders (Figma VX 2 / VX 8 / VX 9a, P-133). For every baby whose plan has
 * reminders on, the open doses are grouped by planned date; each date rings 3 days before and the
 * evening before at 19:00 in the baby's zone (a rescheduled dose only the evening before), plus a
 * "Nhắc lại sáng mai" snooze at 07:00. Sent reminders are kept in `vaccineReminders` so nothing
 * rings twice. The copy never names the baby (R-120); nothing about the child is logged.
 */

export class VaccineReminderError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found',
    readonly reason: string,
  ) {
    super(reason);
  }
}

const RING_HOUR = 19;
const MORNING_HOUR = 7;
/** Late runs still send within this window (a 5-minute scheduler, deploys, retries). */
const GRACE_MS = 6 * 3_600_000;

type Kind = '3d' | 'eve' | 'morning';

interface OpenDose {
  def: VaccineDef;
  dose: number;
  months: number;
  date: string;
  rescheduled: boolean;
}

/** The instant of local [date] at [hour]:00 in [zone]. */
export function atLocalHour(zone: string, date: string, hour: number): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  // Walk from the UTC guess to the local hour (zones are whole or half hours).
  let guess = Date.UTC(y, m - 1, d, hour) - 14 * 3_600_000;
  for (let i = 0; i < 28 * 4; i += 1) {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: zone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      hourCycle: 'h23',
    }).formatToParts(new Date(guess));
    const get = (t: string) => parts.find((p) => p.type === t)?.value ?? '';
    if (`${get('year')}-${get('month')}-${get('day')}` === date && Number(get('hour')) === hour) {
      return new Date(guess);
    }
    guess += 15 * 60_000;
  }
  return new Date(Date.UTC(y, m - 1, d, hour - 7));
}

function addDays(date: string, n: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}

/** Open doses of a baby's book (not given, not declined). */
export function openDoses(
  dob: string,
  dtp: '6in1' | '5in1' | null,
  records: Map<string, { status: string; plannedOn: string | null }>,
): OpenDose[] {
  const out: OpenDose[] = [];
  for (const def of scheduleFor(dtp)) {
    def.months.forEach((months, i) => {
      const r = records.get(`${def.id}_${i + 1}`);
      if (r?.status === 'given' || r?.status === 'declined') return;
      const rescheduled = r?.status === 'planned' && r.plannedOn != null;
      out.push({
        def,
        dose: i + 1,
        months,
        date: rescheduled ? r!.plannedOn! : plannedDate(dob, months),
        rescheduled,
      });
    });
  }
  return out;
}

/** The reminders due at [now] for a baby: (date, kind, fireAt). */
export function dueReminders(
  zone: string,
  doses: OpenDose[],
  snoozes: string[],
  now: Date,
): { date: string; kind: Kind; fireAt: Date; doses: OpenDose[] }[] {
  const today = localDateIn(zone, now);
  const byDate = new Map<string, OpenDose[]>();
  for (const d of doses) {
    if (d.date < today) continue;
    byDate.set(d.date, [...(byDate.get(d.date) ?? []), d]);
  }
  const out: { date: string; kind: Kind; fireAt: Date; doses: OpenDose[] }[] = [];
  const consider = (date: string, kind: Kind, fireAt: Date, group: OpenDose[]) => {
    const t = fireAt.getTime();
    if (t <= now.getTime() && now.getTime() - t < GRACE_MS)
      out.push({ date, kind, fireAt, doses: group });
  };
  for (const [date, group] of byDate) {
    if (group.every((d) => !d.rescheduled)) {
      consider(date, '3d', atLocalHour(zone, addDays(date, -3), RING_HOUR), group);
    }
    consider(date, 'eve', atLocalHour(zone, addDays(date, -1), RING_HOUR), group);
    if (snoozes.includes(date))
      consider(date, 'morning', atLocalHour(zone, date, MORNING_HOUR), group);
  }
  return out;
}

const titles: Record<Kind, { vi: string; en: string }> = {
  '3d': { vi: 'Còn 3 ngày đến lịch tiêm của bé', en: 'A vaccination is due in 3 days' },
  eve: { vi: 'Ngày mai có lịch tiêm của bé', en: 'A vaccination is due tomorrow' },
  morning: { vi: 'Hôm nay có lịch tiêm của bé', en: 'A vaccination is due today' },
};

/** VX 8: "6in1 · Rota · Phế cầu (mũi 1) · Mốc 2 tháng tuổi" — vaccine names, never the baby's. */
export function vaccineCopy(kind: Kind, doses: OpenDose[], language: string) {
  const en = language.startsWith('en');
  const name = (d: OpenDose) => (en ? d.def.short.en : d.def.short.vi);
  const sameDose = new Set(doses.map((d) => d.dose)).size === 1;
  const list = sameDose
    ? `${doses.map(name).join(' · ')} (${en ? 'dose' : 'mũi'} ${doses[0]!.dose})`
    : doses.map((d) => `${name(d)} ${en ? 'dose' : 'mũi'} ${d.dose}`).join(' · ');
  const months = Math.min(...doses.map((d) => d.months));
  const milestone = en
    ? months === 0
      ? 'newborn'
      : `${months}-month milestone`
    : months === 0
      ? 'Mốc sơ sinh'
      : `Mốc ${months} tháng tuổi`;
  return { title: titles[kind][en ? 'en' : 'vi'], body: `${list} · ${milestone}` };
}

/** Every 5 minutes: ring what is due for every baby with reminders on. */
export async function ringVaccineReminders(
  db: Firestore,
  sender: PushSender | null,
  now: Date,
): Promise<{ rang: number; sent: number }> {
  const plans = await db.collectionGroup('vaccinePlan').where('remind', '==', true).get();
  let rang = 0;
  let sent = 0;
  for (const plan of plans.docs) {
    if (plan.id !== 'main') continue;
    const babyRef = plan.ref.parent.parent!;
    const dob = plan.get('scheduleFrom') as string | null | undefined;
    if (!dob) continue;
    const baby = await babyRef.get();
    if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') continue;
    const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
    const docs = await babyRef.collection('vaccines').get();
    const records = new Map(
      docs.docs.map((d) => [
        d.id,
        {
          status: d.get('status') as string,
          plannedOn: (d.get('plannedOn') as string | null) ?? null,
        },
      ]),
    );
    const snoozeDocs = await babyRef
      .collection('vaccineReminders')
      .where('kind', '==', 'snooze')
      .get();
    const snoozes = snoozeDocs.docs.map((d) => d.get('date') as string);
    const due = dueReminders(
      zone,
      openDoses(dob, (plan.get('dtp') as '6in1' | '5in1' | null) ?? null, records),
      snoozes,
      now,
    );
    for (const r of due) {
      const mark = babyRef.collection('vaccineReminders').doc(`${r.date}_${r.kind}`);
      const claimed = await db.runTransaction(async (tx) => {
        if ((await tx.get(mark)).exists) return false;
        tx.set(mark, { kind: r.kind, date: r.date, sentAt: Timestamp.fromDate(now) });
        return true;
      });
      if (!claimed) continue;
      rang += 1;
      sent += await pushTo(db, sender, babyRef.id, plan, r, now);
    }
  }
  return { rang, sent };
}

async function pushTo(
  db: Firestore,
  sender: PushSender | null,
  babyId: string,
  plan: DocumentSnapshot,
  r: { date: string; kind: Kind; doses: OpenDose[] },
  now: Date,
): Promise<number> {
  if (!sender) return 0;
  const members = await db.collection(`babies/${babyId}/members`).get();
  const eligible = members.docs
    .filter((m) => {
      if (m.get('status') !== 'active') return false;
      const until = m.get('accessUntilAt') as Timestamp | null | undefined;
      if (until && until.toMillis() <= now.getTime()) return false;
      return ['coParent', 'caregiver'].includes(m.get('role') as string);
    })
    .map((m) => m.id);
  const chosen = (plan.get('recipients') as string[] | undefined) ?? [];
  const recipients = chosen.length ? eligible.filter((u) => chosen.includes(u)) : eligible;
  const muted = await mutedRecipients(db, 'vaccine', recipients);
  const months = Math.min(...r.doses.map((d) => d.months));
  let sent = 0;
  for (const uid of recipients) {
    if (muted.has(uid)) continue;
    const devices = await db.collection(`users/${uid}/devices`).get();
    const byLanguage = new Map<string, string[]>();
    for (const d of devices.docs) {
      const token = d.get('token') as string | undefined;
      if (!token || d.get('signedOutAt')) continue;
      const language = (d.get('language') as string | undefined) ?? 'vi';
      byLanguage.set(language, [...(byLanguage.get(language) ?? []), token]);
    }
    for (const [language, tokens] of byLanguage) {
      const rejected = await sender.send(tokens, {
        ...vaccineCopy(r.kind, r.doses, language),
        data: { kind: 'vaccine', babyId, date: r.date, months: String(months) },
        // VX 8 actions: the iOS category, drawn by the app on Android (A6).
        androidDraws: true,
        apns: {
          category: 'CL_VACCINE',
          collapseId: `vx-${babyId}-${r.date}`,
          threadId: `vx-${babyId}`,
        },
      });
      sent += tokens.length - rejected.length;
      for (const t of rejected) {
        const dead = devices.docs.find((d) => d.get('token') === t);
        if (dead) await dead.ref.delete();
      }
    }
  }
  return sent;
}

const snoozeSchema = z
  .object({
    babyId: z.string().min(1).max(64),
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  })
  .strict();

/** VX 8 "Nhắc lại sáng mai": ring again at 07:00 on the appointment day. */
export async function snoozeVaccineReminder(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ ok: true }> {
  const parsed = snoozeSchema.safeParse(data);
  if (!parsed.success) throw new VaccineReminderError('invalid-argument', 'malformed');
  const { babyId, date } = parsed.data;
  const member = await db.doc(`babies/${babyId}/members/${uid}`).get();
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  const ok =
    member.exists &&
    member.get('status') === 'active' &&
    (!until || until.toMillis() > now.getTime()) &&
    ['coParent', 'caregiver'].includes(member.get('role') as string);
  if (!ok) throw new VaccineReminderError('permission-denied', 'not-allowed');
  await db.doc(`babies/${babyId}/vaccineReminders/snooze_${date}`).set({
    kind: 'snooze',
    date,
    by: uid,
    at: Timestamp.fromDate(now),
  });
  return { ok: true };
}
