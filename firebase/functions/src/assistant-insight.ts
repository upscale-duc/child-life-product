import { careNightWindow, insightSchema, type Insight } from '@child-life/contracts';

/**
 * Hiểu con (D-151 #7): Lumi explains the current "Điều đáng chú ý" from the server's own document
 * (`babies/{b}/insights/current`, functions `insights.ts`): the same numbers as Hôm nay and Hiểu
 * con, worked out by the rules, never by the model. Read on the rule path, so 0 credits.
 */

const pad = (n: number) => String(n).padStart(2, '0');
const day = (iso: string) => {
  const [, m, d] = iso.split('-');
  return `${d}/${m}`;
};

function amount(i: Pick<Insight, 'kind'>, value: number, vi: boolean): string {
  if (i.kind === 'night_feeds') {
    const v = Math.abs(value);
    const n = Number.isInteger(v) ? String(v) : v.toFixed(1).replace('.', vi ? ',' : '.');
    return vi ? `${n} cữ` : `${n} ${v === 1 ? 'feed' : 'feeds'}`;
  }
  const m = Math.round(Math.abs(value));
  const h = Math.floor(m / 60);
  const r = m % 60;
  if (h === 0) return vi ? `${r} phút` : `${r} min`;
  if (r === 0) return vi ? `${h} giờ` : `${h} h`;
  return vi ? `${h} giờ ${r} phút` : `${h} h ${r} min`;
}

/** The titles the app shows (ARB `hcLongestUp` …), in the chat's language. */
export function insightTitle(i: Pick<Insight, 'kind' | 'direction'>, vi: boolean): string {
  const up = i.direction === 'up';
  switch (i.kind) {
    case 'night_longest':
      return vi
        ? `Khoảng ngủ đêm dài nhất đang ${up ? 'dài' : 'ngắn'} hơn`
        : `Longest night stretch is getting ${up ? 'longer' : 'shorter'}`;
    case 'night_total':
      return vi
        ? `Đêm gần đây ngủ ${up ? 'nhiều' : 'ít'} hơn`
        : `${up ? 'More' : 'Less'} night sleep lately`;
    case 'night_feeds':
      return vi
        ? `Đêm gần đây bú ${up ? 'nhiều' : 'ít'} cữ hơn`
        : `${up ? 'More' : 'Fewer'} night feeds lately`;
  }
}

function measure(i: Pick<Insight, 'kind'>, vi: boolean): string {
  switch (i.kind) {
    case 'night_longest':
      return vi ? 'khoảng ngủ liền dài nhất mỗi đêm' : 'the longest single sleep each night';
    case 'night_total':
      return vi ? 'tổng giờ ngủ trong đêm' : 'total sleep during the night';
    case 'night_feeds':
      return vi ? 'số cữ bú bình và bú mẹ trong đêm' : 'bottle and breast feeds during the night';
  }
}

/** One insight in a few plain sentences: the figures, the nights counted, the basis, who logged. */
export function insightExplanation(i: Insight, vi: boolean): string {
  const night = `${pad(careNightWindow.fromHour)}:00`;
  const morning = `${pad(careNightWindow.toHour)}:00`;
  const left = i.points
    .slice(i.points.length - i.coverage.total)
    .filter((p) => p.value === null)
    .map((p) => day(p.date));
  const parts = [
    vi
      ? `Mình lấy ${measure(i, vi)}, từ ${night} đến ${morning}.`
      : `I took ${measure(i, vi)}, from ${night} to ${morning}.`,
    vi
      ? `${i.coverage.valid} đêm gần đây (${day(i.recent.from)}–${day(i.recent.to)}) trung bình ${amount(i, i.value, vi)}; ${i.baselineCoverage.valid} đêm trước đó (${day(i.baseline.from)}–${day(i.baseline.to)}) trung bình ${amount(i, i.baselineValue, vi)}.`
      : `The last ${i.coverage.valid} nights (${day(i.recent.from)}–${day(i.recent.to)}) averaged ${amount(i, i.value, vi)}; the ${i.baselineCoverage.valid} nights before (${day(i.baseline.from)}–${day(i.baseline.to)}) averaged ${amount(i, i.baselineValue, vi)}.`,
  ];
  if (i.peak && i.kind === 'night_longest')
    parts.push(
      vi
        ? `Dài nhất là đêm ${day(i.peak.date)}: ${amount(i, i.peak.value, vi)}.`
        : `The longest was the night of ${day(i.peak.date)}: ${amount(i, i.peak.value, vi)}.`,
    );
  if (left.length)
    parts.push(
      vi
        ? `Đêm ${left.join(', ')} chưa ghi đủ nên không tính.`
        : `Not counted: ${left.join(', ')} (not fully logged).`,
    );
  if (i.authors.length)
    parts.push(
      vi
        ? `Ghi bởi ${i.authors.map((a) => a.name).join(', ')}.`
        : `Logged by ${i.authors.map((a) => a.name).join(', ')}.`,
    );
  // One sentence per line: the read card shows each as its own paragraph.
  return parts.join('\n');
}

export type InsightBasis =
  | { kind: 'items'; rows: { label: string; value: string }[]; link: string; computedAt: string }
  | { kind: 'sparse'; text: string }
  | { kind: 'none'; text: string };

/** What the read card says for [doc] (the stored document's data, possibly absent). */
export function insightBasis(doc: Record<string, unknown> | undefined, vi: boolean): InsightBasis {
  const items = (Array.isArray(doc?.items) ? doc.items : [])
    .map((raw) => insightSchema.safeParse(raw))
    .flatMap((r) => (r.success ? [r.data] : []))
    .slice(0, 3);
  const progress = (doc?.progress ?? {}) as { validNights?: number; neededNights?: number };
  const valid = progress.validNights ?? 0;
  const needed = progress.neededNights ?? 5;
  if (items.length === 0) {
    if (!doc || valid < needed)
      return {
        kind: 'sparse',
        text: vi
          ? `Mới có ${valid}/${needed} đêm có ghi đủ, chưa đủ để so sánh với tuần trước.`
          : `Only ${valid} of ${needed} fully logged nights so far, not enough to compare with the week before.`,
      };
    return {
      kind: 'none',
      text: vi
        ? 'Tuần này giấc ngủ đêm và cữ bú đêm không có thay đổi đáng chú ý.'
        : 'No notable change in night sleep or night feeds this week.',
    };
  }
  const computed = doc?.computedAt as { toDate?: () => Date } | Date | undefined;
  const at = computed instanceof Date ? computed : (computed?.toDate?.() ?? new Date(0));
  return {
    kind: 'items',
    rows: items.map((i) => ({ label: insightTitle(i, vi), value: insightExplanation(i, vi) })),
    link: `/care/insights/${items[0]!.kind}`,
    computedAt: at.toISOString(),
  };
}

export const insightCaveat = (vi: boolean) =>
  vi
    ? 'Số liệu tính từ ghi nhận của gia đình. Dữ liệu chưa cho biết nguyên nhân; nếu lo lắng, hãy hỏi bác sĩ.'
    : "Figures come from your family's logs. They can't tell the cause; if you're worried, ask your doctor.";
