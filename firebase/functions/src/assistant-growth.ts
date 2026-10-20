import { whoLms } from './assistant-growth-data.g.js';

/** Same interpolation/LMS method as mobile WhoGrowth. No extrapolation beyond 0–5 years. */
export function growthPercentile(
  measure: 'weight' | 'length' | 'head',
  sex: string,
  ageDays: number,
  value: number,
): number | null {
  if (
    !Number.isFinite(value) ||
    !Number.isFinite(ageDays) ||
    !['boy', 'girl'].includes(sex) ||
    ageDays < 0 ||
    ageDays > 1856 ||
    value <= 0
  )
    return null;
  const key = `who${measure[0]!.toUpperCase()}${measure.slice(1)}${sex === 'boy' ? 'Boys' : 'Girls'}`;
  const t = whoLms[key];
  if (!t || ageDays > t[t.length - 4]!) return null;
  let lo = 0,
    hi = t.length / 4 - 1;
  while (hi - lo > 1) {
    const mid = Math.floor((lo + hi) / 2);
    if (t[mid * 4]! <= ageDays) lo = mid;
    else hi = mid;
  }
  const f = (ageDays - t[lo * 4]!) / (t[hi * 4]! - t[lo * 4]!);
  const at = (i: number) => t[lo * 4 + i]! + (t[hi * 4 + i]! - t[lo * 4 + i]!) * f;
  const l = at(1),
    m = at(2),
    s = at(3);
  const z = l === 0 ? Math.log(value / m) / s : ((value / m) ** l - 1) / (l * s);
  // Normal CDF (Abramowitz & Stegun), max absolute error < 7.5e-8.
  const x = Math.abs(z),
    q = 1 / (1 + 0.2316419 * x);
  const tail =
    (Math.exp((-x * x) / 2) / Math.sqrt(2 * Math.PI)) *
    q *
    (0.31938153 + q * (-0.356563782 + q * (1.781477937 + q * (-1.821255978 + q * 1.330274429))));
  return Math.max(0, Math.min(100, (z >= 0 ? 1 - tail : tail) * 100));
}
