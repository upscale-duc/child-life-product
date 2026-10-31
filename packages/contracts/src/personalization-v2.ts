import { z } from 'zod';
import { addDaysIso } from './rhythm.js';
import { localDateIn } from './baby.js';
import { careNightWindow, dayBoundsIn } from './care.js';
import type { Activity, Recommendation } from './personalization.js';

/** P-172: explicit, expiring inputs. Never infer a clinical fact from missing logs. */
const babyId = z
  .string()
  .min(1)
  .max(128)
  .regex(/^[^/]+$/);
const id = z.string().regex(/^[a-zA-Z0-9_:-]{1,100}$/);
/**
 * P-172 (audit 2026-10-21 P2 #7): only choices that change what is shown. "Người khác chăm"
 * (`other_carer`) and the `handover` / `routine` focuses changed nothing and were dropped; a value
 * stored before that reads as "usual" / no focus (`personalizedDay`).
 */
export const dailyContexts = ['usual', 'few_minutes', 'busy'] as const;
export const weeklyFocuses = ['play'] as const;
export const notebookKinds = [
  'sleep',
  'soothing',
  'feeding',
  'avoid',
  'routine',
  'carer',
  'other',
] as const;
export const responseKinds = [
  'save',
  // Owner, 2026-10-22: a saved idea can be taken out of "Đã lưu" again.
  'unsave',
  'hide',
  'snooze',
  'dislike',
  'known',
  'intend',
  'tried',
  'helpful',
  'unsure',
  'exclude',
  'restore',
] as const;
export const personalizationDayRequestSchema = z
  .object({ babyId, locale: z.enum(['vi', 'en']) })
  .strict();
export const personalizationDigestRequestSchema = z
  .object({ babyId, deviceId: z.string().regex(/^d_[a-f0-9]{32}$/) })
  .strict();
export const personalizationMutationSchema = z
  .object({
    babyId,
    action: z.discriminatedUnion('kind', [
      z.object({ kind: z.literal('context'), value: z.enum(dailyContexts) }).strict(),
      z.object({ kind: z.literal('focus'), value: z.enum(weeklyFocuses).nullable() }).strict(),
      z.object({ kind: z.literal('routine'), unusual: z.boolean() }).strict(),
      z
        .object({
          kind: z.literal('respond'),
          contentId: id,
          value: z.enum(responseKinds),
          scope: z.enum(['person', 'baby']).optional(),
        })
        .strict(),
      z
        .object({
          kind: z.literal('note'),
          id,
          revision: z.number().int().min(0),
          text: z.string().trim().min(1).max(200),
          category: z.enum(notebookKinds),
          source: z.enum(['app', 'lumi']).optional(),
          scope: z.enum(['person', 'baby']),
          days: z.union([z.literal(1), z.literal(7), z.literal(30)]).nullable(),
          avoidActivityId: z
            .string()
            .regex(/^act_[a-z0-9_]{2,40}$/)
            .nullable(),
        })
        .strict(),
      z.object({ kind: z.literal('delete_note'), id, revision: z.number().int().min(1) }).strict(),
      z
        .object({
          kind: z.literal('work'),
          reminderId: z.string().regex(/^rm_[a-f0-9]{32}$/),
          transition: z.enum(['accept', 'release', 'complete']),
          revision: z.number().int().min(0),
        })
        .strict(),
      z
        .object({
          kind: z.literal('acknowledge'),
          version: z
            .string()
            .regex(/^[a-f0-9]{64}$/)
            .optional(),
        })
        .strict(),
      z
        .object({
          kind: z.literal('digest'),
          enabled: z.boolean(),
          deviceId: z
            .string()
            .regex(/^d_[a-f0-9]{32}$/)
            .nullable(),
        })
        .strict(),
    ]),
  })
  .strict();
export type PersonalizationMutation = z.infer<typeof personalizationMutationSchema>;
export interface PersonalResponse {
  value: (typeof responseKinds)[number];
  at: string;
  until: string | null;
  saved?: boolean;
  intendedAt?: string;
  triedAt?: string;
  outcome?: 'helpful' | 'unsure';
  outcomeAt?: string;
}
export interface NotebookNote {
  id: string;
  authorUid: string;
  confirmedBy?: string;
  source?: 'app' | 'lumi';
  text: string;
  category: (typeof notebookKinds)[number];
  scope: 'person' | 'baby';
  revision: number;
  confirmedAt: string;
  expiresAt: string | null;
  avoidActivityId: string | null;
}
export interface PersonalizationState {
  context?: { value: (typeof dailyContexts)[number]; expiresAt: string };
  focus?: { value: (typeof weeklyFocuses)[number]; expiresAt: string } | null;
  responses?: Record<string, PersonalResponse>;
  digest?: { enabled: boolean; deviceId: string | null };
}
export function activeAt(expiry: string | null | undefined, now: Date): boolean {
  return (
    expiry === null ||
    (typeof expiry === 'string' &&
      Number.isFinite(Date.parse(expiry)) &&
      Date.parse(expiry) > now.getTime())
  );
}
export function nextLocalDay(zone: string, now: Date): string {
  return dayBoundsIn(zone, localDateIn(zone, now)).end.toISOString();
}
export function nextLocalWeek(zone: string, now: Date): string {
  const today = localDateIn(zone, now);
  const day = new Date(`${today}T12:00:00Z`).getUTCDay();
  return dayBoundsIn(zone, addDaysIso(today, (7 - day) % 7)).end.toISOString();
}
export function responseSuppresses(r: PersonalResponse | undefined, now: Date): boolean {
  return (
    !!r &&
    ['hide', 'snooze', 'dislike', 'known', 'exclude', 'tried', 'helpful'].includes(r.value) &&
    activeAt(r.until, now)
  );
}
export function recommendationCurrent(
  rec: Pick<Recommendation, 'generatedAt' | 'contentVersion' | 'state'> & { expiresAt?: string },
  activity: Activity | undefined,
  x: { now: Date; zone: string; ageDays: number | null; locale: string; country: string | null },
): boolean {
  const generated = Date.parse(rec.generatedAt);
  return (
    Number.isFinite(generated) &&
    generated <= x.now.getTime() &&
    localDateIn(x.zone, new Date(generated)) === localDateIn(x.zone, x.now) &&
    (rec.expiresAt === undefined || activeAt(rec.expiresAt, x.now)) &&
    ['suggested', 'started'].includes(rec.state) &&
    !!activity &&
    activity.status === 'published' &&
    activity.version === rec.contentVersion &&
    activity.locales.includes(x.locale as 'vi' | 'en') &&
    x.ageDays !== null &&
    x.ageDays >= activity.ageDays.from &&
    x.ageDays <= activity.ageDays.to &&
    (activity.regions.length === 0 || (x.country !== null && activity.regions.includes(x.country)))
  );
}
export interface PatternRecord {
  id: string;
  type: string;
  at: string;
  end: string | null;
}
export interface RoutinePattern {
  kind: 'feed_interval' | 'day_sleep';
  lowMinutes: number;
  highMinutes: number;
  samples: number;
  days: number;
  asOf: string;
}
/** Describe recorded intervals only. No feed/diaper daily totals or clinical interpretations. */
export function routinePatterns(
  records: readonly PatternRecord[],
  now: Date,
  zone: string,
): RoutinePattern[] {
  const since = now.getTime() - 14 * 86_400_000;
  const unique = new Map<string, PatternRecord>();
  for (const r of records) {
    const at = Date.parse(r.at);
    if (Number.isFinite(at) && at >= since && at <= now.getTime())
      unique.set(`${r.type}:${r.at}:${r.end}`, r);
  }
  const rows = [...unique.values()].sort((a, b) => a.at.localeCompare(b.at));
  const out: RoutinePattern[] = [];
  const collect = (kind: RoutinePattern['kind'], points: { minutes: number; at: string }[]) => {
    const days = new Set(points.map((p) => localDateIn(zone, new Date(p.at)))).size;
    if (points.length < 5 || days < 3) return;
    const last = points.at(-1)!.at;
    if (now.getTime() - Date.parse(last) > 3 * 86_400_000) return;
    const sorted = points.map((p) => p.minutes).sort((a, b) => a - b);
    const low = sorted[Math.floor((sorted.length - 1) * 0.25)]!;
    const high = sorted[Math.ceil((sorted.length - 1) * 0.75)]!;
    if (low <= 0 || high / low > 2) return;
    out.push({
      kind,
      lowMinutes: Math.floor(low / 5) * 5,
      highMinutes: Math.ceil(high / 5) * 5,
      samples: points.length,
      days,
      asOf: last,
    });
  };
  const feeds = rows.filter((r) => r.type === 'bottle' || r.type === 'breast');
  collect(
    'feed_interval',
    feeds.flatMap((r, i) => {
      const previous = feeds[i - 1];
      if (
        !previous ||
        localDateIn(zone, new Date(previous.at)) !== localDateIn(zone, new Date(r.at))
      )
        return [];
      const minutes = (Date.parse(r.at) - Date.parse(previous.at)) / 60_000;
      return minutes >= 30 && minutes <= 360 ? [{ minutes, at: r.at }] : [];
    }),
  );
  const sleeps = rows.filter((r) => r.type === 'sleep' && r.end !== null);
  collect(
    'day_sleep',
    sleeps.flatMap((r) => {
      const minutes = (Date.parse(r.end!) - Date.parse(r.at)) / 60_000;
      const hour = Number(
        new Intl.DateTimeFormat('en', { timeZone: zone, hour: 'numeric', hourCycle: 'h23' }).format(
          new Date(r.at),
        ),
      );
      const overlap = sleeps.some(
        (other) =>
          other.id !== r.id &&
          Date.parse(other.at) < Date.parse(r.end!) &&
          Date.parse(other.end!) > Date.parse(r.at),
      );
      return !overlap &&
        hour >= careNightWindow.toHour &&
        hour < careNightWindow.fromHour &&
        minutes >= 10 &&
        minutes <= 180 &&
        Date.parse(r.end!) <= now.getTime()
        ? [{ minutes, at: r.at }]
        : [];
    }),
  );
  return out;
}
export function nextWorkState(
  current: { state: string; actorUid: string | null; revision: number },
  transition: 'accept' | 'release' | 'complete',
  uid: string,
  parent: boolean,
) {
  if (transition === 'accept') {
    if (current.state === 'accepted' && current.actorUid === uid) return current;
    if (current.state !== 'unclaimed') throw new Error('work-conflict');
    return { state: 'accepted', actorUid: uid, revision: current.revision + 1 };
  }
  if (current.state === 'completed' && transition === 'complete' && current.actorUid === uid)
    return current;
  if (current.state !== 'accepted' || (current.actorUid !== uid && !parent))
    throw new Error('work-conflict');
  return {
    state: transition === 'release' ? 'unclaimed' : 'completed',
    actorUid: transition === 'release' ? null : uid,
    revision: current.revision + 1,
  };
}
