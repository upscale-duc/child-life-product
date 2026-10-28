import type { Firestore } from 'firebase-admin/firestore';
import { carePlanMethods, carePlanMorningWindow, type CarePlanMethod } from '@child-life/contracts';
import { carePlanSettingsRef, dateKeyIn, draftCarePlanDay } from './care-plan.js';
import { isActiveMember } from './family.js';
import { notifyUsers } from './notifications.js';
import { taskLine } from './care-plan-reminders.js';
import type { PushSender } from './social.js';
import type { CarePlanTask } from '@child-life/contracts';

/**
 * Cùng Chăm Con "Tự tạo lịch mỗi sáng" + N5 (D-136 #3, ANALYSIS §6.1): for each family that
 * turned it on, once its baby's clock passes 06:30 (after the default quiet hours; until 11:00), today's plan is drafted the way
 * the family last started a day, and every plan manager gets "Lịch của Bin đã sẵn". The draft is
 * not reminded (N1) until someone taps "Dùng lịch này". A day that already exists is left alone.
 *
 * Idempotent: `draftedFor` on the settings records the day handled, the draft is made in a
 * transaction that skips an existing day, and the notice id names the baby and the date. Nothing
 * about the child is logged; the push holds a count and the first catalogue task.
 */

/** "06:45" in [zone] at [now]. */
function clockIn(zone: string, now: Date): string {
  return new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(now);
}

export async function draftCarePlanMornings(
  db: Firestore,
  sender: PushSender | null,
  now: Date,
): Promise<{ drafted: number; sent: number }> {
  const on = await db.collectionGroup('carePlanSettings').where('autoDraft', '==', true).get();
  let drafted = 0;
  let sent = 0;
  for (const settings of on.docs) {
    const babyRef = settings.ref.parent.parent;
    if (!babyRef || babyRef.parent.id !== 'babies' || settings.id !== 'family') continue;
    const babyId = babyRef.id;
    const baby = await babyRef.get();
    if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') continue;
    const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
    const clock = clockIn(zone, now);
    if (clock < carePlanMorningWindow.from || clock > carePlanMorningWindow.until) continue;
    const today = dateKeyIn(zone, now);
    if (settings.get('draftedFor') === today) continue;

    const stored = settings.get('method') as string | undefined;
    const method: CarePlanMethod =
      stored && (carePlanMethods as readonly string[]).includes(stored) && stored !== 'empty'
        ? (stored as CarePlanMethod)
        : 'everyday';
    const made = await draftCarePlanDay(db, babyId, today, zone, method, now);
    await carePlanSettingsRef(db, babyId).set({ draftedFor: today }, { merge: true });
    if (!made) continue;
    drafted += 1;

    const managers = await db
      .collection(`babies/${babyId}/members`)
      .where('role', '==', 'coParent')
      .get();
    const uids = managers.docs.filter((m) => isActiveMember(m, now)).map((m) => m.id);
    const first = [{ task: made.first.task as CarePlanTask, time: made.first.time }];
    const result = await notifyUsers(
      db,
      sender,
      uids,
      {
        kind: 'carePlanReady',
        id: `cpr-${babyId}-${today}`,
        babyId,
        data: { babyId, date: today },
        message: (language) =>
          language === 'en'
            ? {
                title: 'Your baby’s plan is ready',
                body: `${made.items} tasks · starting ${taskLine(first, 'en')}. Look it over, then tap Use this plan.`,
              }
            : {
                title: 'Lịch của bé đã sẵn',
                body: `${made.items} việc · bắt đầu ${taskLine(first, 'vi')}. Xem rồi chọn Dùng lịch này nhé.`,
              },
        template: {
          id: 'care.plan_ready',
          values: {
            count: made.items,
            task_line: { vi: taskLine(first, 'vi'), en: taskLine(first, 'en') },
          },
        },
        zone,
      },
      now,
    );
    sent += result.sent;
  }
  return { drafted, sent };
}
