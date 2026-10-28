import type { CarePlanTask, CarePlanTemplateMethod } from './care-plan.js';
import { carePlanRhythmDays } from './care-plan.js';

/**
 * Drafted plans (D-136): what "Theo nhịp của bé" and the reference templates put in a draft day.
 * Pure, so the server (`startCarePlanDay`, the morning draft) and tests share one source.
 *
 * Only feeds, sleep and gentle routines (tummy time, bath, reading, teeth). Never medicine,
 * vitamins or doses (FLOW §4), never a diaper task (changes follow the baby, not a clock).
 */

export interface DraftTask {
  task: CarePlanTask;
  time: string;
}

/** A logged care event: its kind and the baby-local day and minute it started. */
export interface RhythmEvent {
  kind: 'feed' | 'sleep';
  date: string;
  minute: number;
}

const hhmm = (minute: number) => {
  const m = (((Math.round(minute / 5) * 5) % 1440) + 1440) % 1440;
  return `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`;
};

/** D-136 #2: every one of [dates] (the last 7 days) has a feed and a sleep. */
export function rhythmReady(events: RhythmEvent[], dates: string[]): boolean {
  if (dates.length < carePlanRhythmDays) return false;
  return dates.every(
    (d) =>
      events.some((e) => e.date === d && e.kind === 'feed') &&
      events.some((e) => e.date === d && e.kind === 'sleep'),
  );
}

/**
 * The usual times of one kind: repeatedly take the half-hour with the most days that had an
 * event within ±30 minutes of it (at least half the days), place the task at the median of those
 * events (to 5 minutes), and drop events within [gap] minutes of it. Earliest first.
 */
export function usualTimes(
  minutes: { date: string; minute: number }[],
  days: number,
  gap: number,
  max: number,
): number[] {
  let left = [...minutes];
  const out: number[] = [];
  const need = Math.ceil(days / 2);
  while (out.length < max) {
    let best: { slot: number; days: number; near: number[] } | null = null;
    for (let slot = 0; slot < 1440; slot += 30) {
      const near = left.filter((e) => Math.abs(e.minute - slot) <= 30);
      const n = new Set(near.map((e) => e.date)).size;
      if (n >= need && (!best || n > best.days)) {
        best = { slot, days: n, near: near.map((e) => e.minute) };
      }
    }
    if (!best) break;
    const sorted = [...best.near].sort((a, b) => a - b);
    const median = sorted[Math.floor(sorted.length / 2)]!;
    out.push(median);
    left = left.filter((e) => Math.abs(e.minute - median) > gap);
  }
  return out.sort((a, b) => a - b);
}

/**
 * "Theo nhịp của bé": the usual feed and sleep start times of the last days ([feed] is the
 * family's usual feed: breast or bottle). Two feeds at least 90 minutes apart, two sleeps at
 * least 60 minutes apart; at most 10 feeds and 6 sleeps.
 */
export function rhythmDraft(
  events: RhythmEvent[],
  days: number,
  feed: 'bottle' | 'breast',
): DraftTask[] {
  const of = (k: RhythmEvent['kind']) =>
    events.filter((e) => e.kind === k).map((e) => ({ date: e.date, minute: e.minute }));
  const tasks: DraftTask[] = [
    ...usualTimes(of('feed'), days, 90, 10).map((m) => ({ task: feed, time: hhmm(m) })),
    ...usualTimes(of('sleep'), days, 60, 6).map((m) => ({ task: 'sleep' as const, time: hhmm(m) })),
  ];
  return dedupe(tasks);
}

function dedupe(tasks: DraftTask[]): DraftTask[] {
  const seen = new Set<string>();
  return tasks
    .filter((t) => {
      const k = `${t.task}@${t.time}`;
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    })
    .sort((a, b) => a.time.localeCompare(b.time) || a.task.localeCompare(b.task));
}

/** D-136 #4: EASY 3.5 / EASY 4 fit babies under this many months; older babies get only `basic`. */
export const carePlanEasyMaxMonths = 6;

/**
 * Whether [method] is offered to a baby [ageMonths] old (null: date of birth unknown, every
 * template is offered).
 */
export function templateOffered(method: CarePlanTemplateMethod, ageMonths: number | null): boolean {
  if (method === 'basic' || ageMonths === null) return true;
  return ageMonths < carePlanEasyMaxMonths;
}

const at = (feed: 'bottle' | 'breast', feeds: string[], rest: [CarePlanTask, string][]) =>
  dedupe([
    ...feeds.map((time) => ({ task: feed, time })),
    ...rest.map(([task, time]) => ({ task, time })),
  ]);

/**
 * The reference templates, **chờ duyệt** (D-136 #1): drafted by engineering from the sources in
 * `docs/design/explorations/cung-cham-con/templates-draft.md`, offered only on dev until the owner
 * reviews them. Times are a starting point the family edits; none is a medical schedule.
 */
export function templateDraft(
  method: CarePlanTemplateMethod,
  ageMonths: number,
  feed: 'bottle' | 'breast',
): DraftTask[] {
  switch (method) {
    case 'easy35':
      // EASY 3.5 (≈ 6 weeks – 4 months): a feed every ~3.5 h, sleep after a short awake time.
      return at(
        feed,
        ['07:00', '10:30', '14:00', '17:30', '22:00'],
        [
          ['sleep', '08:30'],
          ['sleep', '12:00'],
          ['sleep', '15:30'],
          ['bath', '18:30'],
          ['sleep', '19:00'],
        ],
      );
    case 'easy4':
      // EASY 4 (≈ 4 – 6 months): a feed every ~4 h, three naps, bedtime around 19:00–19:30.
      return at(
        feed,
        ['07:00', '11:00', '15:00', '18:45'],
        [
          ['sleep', '09:00'],
          ['sleep', '13:00'],
          ['sleep', '17:00'],
          ['bath', '18:15'],
          ['sleep', '19:30'],
        ],
      );
    case 'basic':
      if (ageMonths < 3) {
        // Newborns feed on demand, about every 2–3 h: a few reminders, not every feed.
        return at(
          feed,
          ['07:00', '10:00', '13:00', '16:00', '19:00', '22:00'],
          [
            ['tummy', '09:00'],
            ['bath', '18:30'],
          ],
        );
      }
      if (ageMonths < 6) {
        return at(
          feed,
          ['07:00', '10:30', '14:00', '17:30', '21:30'],
          [
            ['sleep', '09:00'],
            ['tummy', '10:00'],
            ['sleep', '12:30'],
            ['sleep', '16:00'],
            ['bath', '18:30'],
            ['sleep', '19:30'],
          ],
        );
      }
      if (ageMonths < 12) {
        return at(
          feed,
          ['07:00', '11:00', '15:00', '19:00'],
          [
            ['solids', '08:30'],
            ['sleep', '09:30'],
            ['sleep', '14:00'],
            ['solids', '17:00'],
            ['bath', '18:30'],
            ['read', '19:15'],
            ['sleep', '19:30'],
          ],
        );
      }
      return dedupe([
        { task: 'solids', time: '07:30' },
        { task: 'solids', time: '12:00' },
        { task: 'sleep', time: '12:30' },
        { task: 'walk', time: '16:30' },
        { task: 'solids', time: '18:00' },
        { task: 'bath', time: '19:00' },
        { task: 'teeth', time: '19:30' },
        { task: 'read', time: '19:40' },
        { task: 'sleep', time: '20:00' },
      ]);
  }
}
