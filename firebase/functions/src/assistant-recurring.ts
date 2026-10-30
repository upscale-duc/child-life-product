import { foldVi, reminderRuleLimits, type ReminderRuleType } from '@child-life/contracts';

/**
 * Lumi L5 (recurring reminders): "nhắc cữ bú mỗi 3 tiếng", "nhắc thay tã lúc 8h, 12h và 16h hằng
 * ngày", "remind me to pump every 3 hours" — read by rules, no model, 0 credits. A rule is the app's
 * own (`reminder-rules.ts`: feed / sleep / diaper / pump, after the last log or at fixed times);
 * Lumi never saves it: the app's editor opens with what was said and the person picks who is
 * reminded. Anything else ("nhắc uống vitamin D mỗi sáng") is left to the one-time reminder path.
 */
export interface RecurringRule {
  type: ReminderRuleType;
  mode: 'afterLast' | 'fixed';
  intervalMinutes: number | null;
  /** "HH:mm", sorted, at most `reminderRuleLimits.timesMax`. */
  times: string[];
  /** ISO weekdays (1 = Monday); all seven unless the words narrow them. */
  days: number[];
}

const w = (alts: string) =>
  new RegExp(String.raw`(?<![\p{L}\p{N}])(?:${alts})(?![\p{L}\p{N}])`, 'u');

const remindWords = w('nhac|nhac nho|dat nhac|hen gio|bao thuc|remind|reminder');
/**
 * Words that make it repeat, read WITH the diacritics: folded, "mỗi" would be "mới" and "cứ" would
 * be "cũ" ("mua sữa mới" is not a repeat).
 */
export function saysRecurring(text: string): boolean {
  const t = text.normalize('NFC').toLocaleLowerCase('vi');
  return (
    /(?<![\p{L}\p{N}])(?:mỗi|cứ|hằng ngày|hàng ngày|hằng sáng|hằng tối|đều đặn)(?![\p{L}\p{N}])/u.test(
      t,
    ) || w('every|each day|daily|everyday').test(foldVi(t))
  );
}
const typeWords: [ReminderRuleType, RegExp][] = [
  ['pump', w('hut sua|vat sua|hut|pump|pumping|express')],
  ['diaper', w('thay ta|thay bim|ta|bim|diaper|nappy')],
  ['sleep', w('ngu|giac ngu|giac|nap|sleep|bedtime')],
  ['feed', w('bu|cu bu|bu binh|bu me|cho bu|an|cu an|feed|feeding|bottle|nurse|nursing')],
];

const step = reminderRuleLimits.intervalStep;

/** "mỗi 3 tiếng", "cứ 2 tiếng rưỡi", "3 tiếng một lần", "every 2.5 hours", "mỗi 90 phút". */
function intervalIn(f: string): number | null {
  const hours = String.raw`(\d+(?:[.,]\d+)?)\s*(?:tieng|gio|h|hours?|hrs?)(?:\s*(ruoi|(\d+)\s*(?:phut|p|minutes?|mins?)))?`;
  const m =
    new RegExp(String.raw`(?:moi|cu|every)\s*${hours}`, 'u').exec(f) ??
    new RegExp(String.raw`${hours}\s*(?:mot lan|1 lan|once)`, 'u').exec(f);
  let min: number | null = null;
  if (m) {
    min = Number(m[1]!.replace(',', '.')) * 60;
    if (m[2] === 'ruoi') min += 30;
    else if (m[3]) min += Number(m[3]);
  } else {
    const p = /(?:moi|cu|every)\s*(\d+)\s*(?:phut|p|minutes?|mins?)(?![\p{L}])/u.exec(f);
    if (p) min = Number(p[1]);
  }
  if (min === null) return null;
  const rounded = Math.round(min / step) * step;
  return rounded >= reminderRuleLimits.intervalMin && rounded <= reminderRuleLimits.intervalMax
    ? rounded
    : null;
}

/** "8h", "12h30", "16:00", "9 giờ tối", "7am": each clock with its own period word. */
function timesIn(f: string): string[] {
  const out = new Set<string>();
  const re =
    /(?<![\p{L}\p{N}])(\d{1,2})(?:\s*(?:h|gio|:)\s*(\d{2})?|\s*(am|pm))(?:\s*(sang|trua|chieu|toi|dem|am|pm))?(?![\p{L}\p{N}])/gu;
  for (const m of f.matchAll(re)) {
    let h = Number(m[1]);
    const min = m[2] ? Number(m[2]) : 0;
    const period = m[4] ?? m[3];
    if (h > 23 || min > 59) continue;
    if ((period === 'chieu' || period === 'toi' || period === 'pm') && h < 12) h += 12;
    if ((period === 'am' || period === 'sang') && h === 12) h = 0;
    out.add(`${String(h).padStart(2, '0')}:${String(min).padStart(2, '0')}`);
  }
  return [...out].sort().slice(0, reminderRuleLimits.timesMax);
}

/** "thứ 2 đến thứ 6", "ngày thường", "cuối tuần", "weekdays", "weekends"; else every day. */
function daysIn(f: string): number[] {
  if (w('ngay thuong|thu 2 den thu 6|thu hai den thu sau|weekdays?').test(f))
    return [1, 2, 3, 4, 5];
  if (w('cuoi tuan|thu 7 va chu nhat|weekends?').test(f)) return [6, 7];
  return [1, 2, 3, 4, 5, 6, 7];
}

/** The rule [text] asks for, or null when it is not a recurring care reminder. */
export function recurringRuleIn(text: string): RecurringRule | null {
  const f = foldVi(text);
  if (!remindWords.test(f) || !saysRecurring(text)) return null;
  const type = typeWords.find(([, re]) => re.test(f))?.[0];
  if (!type) return null;
  const days = daysIn(f);
  const interval = intervalIn(f);
  if (interval !== null)
    return { type, mode: 'afterLast', intervalMinutes: interval, times: [], days };
  const times = timesIn(f);
  if (times.length > 0) return { type, mode: 'fixed', intervalMinutes: null, times, days };
  return null;
}

/** The app's editor, opened with the rule (`/care/reminders/rules/new?…`). */
export function ruleEditorLink(r: RecurringRule): string {
  const q = new URLSearchParams({ type: r.type });
  if (r.intervalMinutes !== null) q.set('interval', String(r.intervalMinutes));
  if (r.times.length) q.set('times', r.times.join(','));
  if (r.days.length < 7) q.set('days', r.days.join(','));
  return `/care/reminders/rules/new?${q.toString()}`;
}
