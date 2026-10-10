import type { IntlShape } from 'react-intl';

/**
 * Number, size and time formatting. Vietnamese reads "1.284", "9,6 GB", "62%"; English reads
 * "1,284", "9.6 GB", "62%". Everything is shown in Vietnam time, the team's time zone.
 */
export const ZONE = 'Asia/Ho_Chi_Minh';
const GB = 1024 ** 3;
const TB = 1024 ** 4;

export function gb(intl: IntlShape, bytes: number, digits = 1): string {
  return `${intl.formatNumber(bytes / GB, { maximumFractionDigits: digits, minimumFractionDigits: 0 })} GB`;
}

export function bytes(intl: IntlShape, value: number): string {
  if (value >= TB) return `${intl.formatNumber(value / TB, { maximumFractionDigits: 2 })} TB`;
  if (value >= GB) return gb(intl, value);
  return `${intl.formatNumber(value / 1024 ** 2, { maximumFractionDigits: 0 })} MB`;
}

export function pct(intl: IntlShape, ratio: number | null, digits = 0): string {
  if (ratio === null || !Number.isFinite(ratio)) return '—';
  return intl.formatNumber(ratio, { style: 'percent', maximumFractionDigits: digits });
}

export function num(intl: IntlShape, value: number | null): string {
  return value === null ? '—' : intl.formatNumber(value);
}

export function vnd(intl: IntlShape, value: number): string {
  if (value >= 1_000_000) {
    return intl.formatMessage(
      { id: 'fmt.millionVnd' },
      { n: intl.formatNumber(value / 1_000_000, { maximumFractionDigits: 1 }) },
    );
  }
  return intl.formatMessage({ id: 'fmt.vnd' }, { n: intl.formatNumber(value) });
}

/** Change against the previous window: ratio for counts, percentage points for rates. */
export function delta(current: number, previous: number): number | null {
  if (previous === 0) return null;
  return (current - previous) / previous;
}

function dayKey(d: Date): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(d);
}

/** "12 phút trước", "3 giờ trước", "hôm qua", "2 ngày trước", then a date. */
export function ago(intl: IntlShape, iso: string, now: Date): string {
  const at = new Date(iso);
  const minutes = Math.max(0, Math.round((now.getTime() - at.getTime()) / 60_000));
  if (minutes < 1) return intl.formatMessage({ id: 'fmt.justNow' });
  if (minutes < 60) return intl.formatMessage({ id: 'fmt.minutesAgo' }, { n: minutes });
  const yesterday = dayKey(new Date(now.getTime() - 86_400_000));
  if (minutes < 24 * 60 && dayKey(at) === dayKey(now)) {
    return intl.formatMessage({ id: 'fmt.hoursAgo' }, { n: Math.floor(minutes / 60) });
  }
  if (dayKey(at) === yesterday) return intl.formatMessage({ id: 'fmt.yesterday' });
  const days = Math.round(minutes / (24 * 60));
  if (days < 7) return intl.formatMessage({ id: 'fmt.daysAgo' }, { n: days });
  return shortDate(intl, iso);
}

/** "2/10" (vi) or "Oct 2" (en). */
export function shortDate(intl: IntlShape, iso: string): string {
  return intl.formatDate(iso, { day: 'numeric', month: 'numeric', timeZone: ZONE });
}

/** "10:42 hôm nay", "Hôm qua 21:03", "2/10 14:05". */
export function when(intl: IntlShape, iso: string, now: Date): string {
  const at = new Date(iso);
  const time = intl.formatTime(at, { hour: '2-digit', minute: '2-digit', timeZone: ZONE });
  if (dayKey(at) === dayKey(now)) return intl.formatMessage({ id: 'fmt.today' }, { time });
  if (dayKey(at) === dayKey(new Date(now.getTime() - 86_400_000))) {
    return intl.formatMessage({ id: 'fmt.yesterdayAt' }, { time });
  }
  return `${shortDate(intl, iso)} ${time}`;
}

/** "5 giờ", "40 phút". */
export function duration(intl: IntlShape, minutes: number | null): string {
  if (minutes === null) return '—';
  if (minutes < 60) return intl.formatMessage({ id: 'fmt.minutes' }, { n: Math.round(minutes) });
  return intl.formatMessage({ id: 'fmt.hours' }, { n: Math.round(minutes / 60) });
}

/** Families at 90 % or more are drawn in orange, below in teal (A04). */
export function usageTone(used: number, quota: number): 'warn' | 'ok' {
  return quota > 0 && used / quota >= 0.9 ? 'warn' : 'ok';
}

/** A CSV cell: quoted, inner quotes doubled, formula prefixes neutralised. */
export function csvCell(value: unknown): string {
  let s = value === null || value === undefined ? '' : String(value);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return `"${s.replace(/"/g, '""')}"`;
}

export function toCsv(header: string[], rows: unknown[][]): string {
  return [header, ...rows].map((r) => r.map(csvCell).join(',')).join('\r\n');
}

export function downloadCsv(filename: string, csv: string): void {
  const blob = new Blob([String.fromCharCode(0xfeff), csv], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
