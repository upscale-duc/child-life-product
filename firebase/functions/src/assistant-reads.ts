import { emergencyFor } from './assistant-care.js';
import { readRhythmContent } from './rhythm.js';
import type { Firestore } from 'firebase-admin/firestore';
import {
  addDaysIso,
  addMonthsIso,
  articleFitsAge,
  contentArticleSchema,
  contentFitsCountry,
  contentStageSchema,
  countryScheduleOf,
  currencyOfDoc,
  dayBoundsIn,
  daysBetweenIso,
  familyCan,
  firstAidPublicSchema,
  foldVi,
  localDateIn,
  minorToPlain,
  milestoneWindow,
  plannedDate,
  readCardSchema,
  referenceMilestoneSchema,
  referencePublicSchema,
  referenceRowsSchemas,
  stageFor,
  vaccineSchedule,
  type AssistantPart,
  type AssistantReadCard,
  type AssistantReadRequest,
  type AssistantReadTool,
  type MemberGrant,
} from '@child-life/contracts';
import { toDate, type TrustedScope } from './assistant-common.js';
import {
  careSummaryTool,
  localClock,
  sleepFactsTool,
  usageSnapshotTool,
} from './assistant-tools.js';
import { noticePart } from './assistant-talk.js';
import { solidsContext } from './assistant-solids.js';
import { growthPercentile } from './assistant-growth.js';
import { insightBasis, insightCaveat } from './assistant-insight.js';
import { checkCapability } from './entitlements.js';

/** Admin SDK reads are authorised BEFORE touching a module's data; mirror Firestore Rules. */
export function allowsAssistantRead(tool: AssistantReadTool, member: MemberGrant): boolean {
  switch (tool) {
    case 'usage_snapshot':
    case 'first_aid':
    case 'library_search':
    case 'stage':
      return true;
    case 'milestones':
      return member.role === 'coParent';
    case 'reminders_today':
      return member.role === 'coParent' || member.role === 'caregiver';
    case 'spending_month':
      return member.role === 'coParent' || member.extraRights?.viewSpending === true;
    // Hiểu con (D-151 #6): parents and caregivers who read care; relatives not in V1.
    case 'insight_basis':
      return member.role !== 'relative' && familyCan(member, 'history.read');
    default:
      return familyCan(member, 'history.read');
  }
}

type Row = AssistantReadCard['rows'][number];
type Input = {
  emergencyNumber?: string | null;
  db: Firestore;
  s: TrustedScope;
  anchor: Date;
  locale: 'vi' | 'en';
  text: string;
};
const strings = (v: unknown): string[] =>
  Array.isArray(v) ? v.filter((s): s is string => typeof s === 'string') : [];
const num = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
const safeId = (v: string) => /^[A-Za-z0-9_-]{1,128}$/.test(v);
const dateText = (date: string) => date.split('-').reverse().join('/');
/*
 * Read-card values are scannable label/value rows (owner 2026-10-31): the app shows a short first
 * line beside its label and any further `\n` lines as a quiet second line, so a row's figure comes
 * first and its detail (latest time, date, who) after. Zero counts are left out, minutes read as
 * hours, numbers are grouped and dates drop the current year.
 */
/** "6 giờ 2 phút" / "6 h 2 min". */
export function durationText(minutes: number, vi: boolean): string {
  const m = Math.round(minutes);
  const h = Math.floor(m / 60),
    r = m % 60;
  if (h === 0) return vi ? `${r} phút` : `${r} min`;
  if (r === 0) return vi ? `${h} giờ` : `${h} h`;
  return vi ? `${h} giờ ${r} phút` : `${h} h ${r} min`;
}
/** "1.050" / "1,050"; a plain decimal ("25.00", `minorToPlain`) keeps its fraction ("25,00"). */
export function groupedNumber(value: number | string, vi: boolean): string {
  const [whole = '0', fraction] = String(value).split('.');
  const sign = whole.startsWith('-') ? '-' : '';
  const digits = whole.replace('-', '').replace(/\B(?=(\d{3})+(?!\d))/g, vi ? '.' : ',');
  return `${sign}${digits}${fraction === undefined ? '' : `${vi ? ',' : '.'}${fraction}`}`;
}
/** "2 cữ" / "1 feed" · "2 feeds". */
const countOf = (n: number, isVi: boolean, vi: string, en: [string, string]) =>
  `${n} ${isVi ? vi : n === 1 ? en[0] : en[1]}`;
/** "10/10" this year, "10/10/2025" otherwise. */
const shortDate = (date: string, today: string) =>
  date.slice(0, 4) === today.slice(0, 4)
    ? date.slice(5).split('-').reverse().join('/')
    : dateText(date);
/** A list value, one "• " line per item. */
const bullets = (items: readonly string[]) => items.map((i) => `• ${i}`).join('\n');
const loggedNote = (vi: boolean) =>
  vi
    ? 'Chỉ tính dữ liệu gia đình đã ghi; thiếu ghi nhận không có nghĩa là không diễn ra.'
    : 'Only family logs are counted; missing logs do not mean an activity did not happen.';
function card(
  x: Input,
  tool: AssistantReadTool,
  title: string,
  rows: Row[],
  link: string,
  sourceIds: string[],
  caveat: string | null = null,
): AssistantReadCard {
  const actions: Partial<Record<AssistantReadTool, [string, string]>> = {
    day_overview: ['Mở Hôm nay', 'Open Today'],
    care_summary: ['Mở Lịch sử', 'Open History'],
    diaper_summary: ['Xem lịch sử thay tã', 'Open diaper history'],
    pump_summary: ['Xem lịch sử hút sữa', 'Open pumping history'],
    growth_snapshot: ['Mở biểu đồ tăng trưởng', 'Open growth chart'],
    running_timer: ['Mở tính giờ', 'Open timer'],
    vaccine_next: ['Mở Sổ tiêm chủng', 'Open vaccination book'],
    reminders_today: ['Mở Nhắc việc', 'Open Reminders'],
    spending_month: ['Mở Chi tiêu', 'Open Spending'],
    solids_history: ['Mở nhật ký ăn dặm', 'Open solids diary'],
    milestones: ['Mở Mốc phát triển', 'Open Milestones'],
    stage: ['Mở Giai đoạn của bé', 'Open Stages'],
    library_search: ['Mở Thư viện', 'Open Library'],
    first_aid: ['Mở Sơ cứu', 'Open First aid'],
    sleep_facts: ['Mở thống kê giấc ngủ', 'Open sleep statistics'],
    insight_basis: ['Mở Hiểu con', 'Open Know your baby'],
  };
  return readCardSchema.parse({
    type: 'read_card',
    schemaVersion: 1,
    tool,
    title,
    asOf: x.anchor.toISOString(),
    rows: rows.slice(0, 24).map((r) => ({
      ...r,
      label: r.label.replaceAll(
        '{emergency}',
        x.emergencyNumber ??
          (x.locale === 'vi' ? 'số cấp cứu địa phương' : 'your local emergency number'),
      ),
      value: r.value.replaceAll(
        '{emergency}',
        x.emergencyNumber ??
          (x.locale === 'vi' ? 'số cấp cứu địa phương' : 'your local emergency number'),
      ),
    })),
    caveat,
    action: {
      label: actions[tool]?.[x.locale === 'vi' ? 0 : 1] ?? (x.locale === 'vi' ? 'Mở xem' : 'Open'),
      link,
    },
    sourceIds: sourceIds.slice(0, 200),
  });
}
/** "11:00" on [day] (default: the anchor's day), else "22:00 · 14/10". */
const whenText = (x: Input, at: Date, day = localDateIn(x.s.zone, x.anchor)) => {
  const date = localDateIn(x.s.zone, at);
  return date === day
    ? localClock(x.s.zone, at)
    : `${localClock(x.s.zone, at)} · ${shortDate(date, localDateIn(x.s.zone, x.anchor))}`;
};
async function profile(x: Input) {
  const p = await x.db.doc(`babies/${x.s.babyId}/restricted/profile`).get();
  const dob = p.get('dateOfBirth');
  const today = localDateIn(x.s.zone, x.anchor);
  return {
    dob: typeof dob === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(dob) && dob <= today ? dob : null,
    sex: p.get('gender') as string | undefined,
    today,
  };
}
async function periodRecords(x: Input, offset: number, days: number) {
  const date = addDaysIso(localDateIn(x.s.zone, x.anchor), offset);
  const first = addDaysIso(date, 1 - days);
  const start = dayBoundsIn(x.s.zone, first).start;
  const end = new Date(Math.min(dayBoundsIn(x.s.zone, date).end.getTime(), x.anchor.getTime() + 1));
  const snap = await x.db
    .collection(`babies/${x.s.babyId}/records`)
    .where('occurredAt', '>=', start)
    .where('occurredAt', '<', end)
    .get();
  return { docs: snap.docs.filter((d) => d.get('deleted') !== true), first, date, start, end };
}

async function timerRows(
  x: Input,
  only?: 'sleep' | 'breast' | 'pump',
): Promise<{ rows: Row[]; ids: string[] }> {
  const types = ['sleep', 'breast', 'pump'] as const;
  const docs = await x.db.getAll(...types.map((k) => x.db.doc(`babies/${x.s.babyId}/timers/${k}`)));
  const rows: Row[] = [],
    ids: string[] = [];
  docs.forEach((d, i) => {
    const started = toDate(d.get('startedAt'));
    if (!d.exists || !started || started > x.anchor) return;
    const k = types[i]!;
    if (only && only !== k) return;
    rows.push({
      label:
        x.locale === 'vi'
          ? { sleep: 'Đang ngủ', breast: 'Đang bú mẹ', pump: 'Đang hút sữa' }[k]
          : { sleep: 'Sleeping', breast: 'Nursing', pump: 'Pumping' }[k],
      value: `${durationText(Math.floor((x.anchor.getTime() - started.getTime()) / 60000), x.locale === 'vi')}\n${x.locale === 'vi' ? 'Từ' : 'Since'} ${whenText(x, started)}`,
      link: `/care/timer/${k}`,
    });
    ids.push(`timer:${k}`);
  });
  return { rows, ids };
}

async function daily(x: Input, request: AssistantReadRequest): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi',
    tool = request.tool;
  const days = /\b(7 ngay|bay ngay|tuan nay|tuan qua|week|7 days|last seven)\b/u.test(
    foldVi(x.text),
  )
    ? 7
    : 1;
  const p = await periodRecords(x, request.dayOffset, tool === 'day_overview' ? 1 : days);
  const today = localDateIn(x.s.zone, x.anchor);
  const date = shortDate(p.date, today),
    period = days === 7 ? `${shortDate(p.first, today)} – ${date}` : date;
  if (tool === 'day_overview') {
    const [summary, timers] = await Promise.all([
      careSummaryTool(x.db, x.s, x.anchor, request.dayOffset, x.locale),
      request.dayOffset === 0 ? timerRows(x) : Promise.resolve({ rows: [], ids: [] }),
    ]);
    const a = summary.summary;
    const diapers = p.docs.filter((d) => d.get('type') === 'diaper');
    const pumps = p.docs.filter((d) => d.get('type') === 'pump');
    const kinds = ['bottle', 'breast', 'sleep', 'diaper', 'pump'] as const;
    const latest = await Promise.all(
      kinds.map((kind) =>
        x.db
          .collection(`babies/${x.s.babyId}/records`)
          .where('type', '==', kind)
          .where('deleted', '==', false)
          .where('occurredAt', '<', p.end)
          .orderBy('occurredAt', 'desc')
          .limit(1)
          .get(),
      ),
    );
    const lastIds: string[] = [];
    const rows: Row[] = [];
    // One row per module: today's figure, then when it last happened. A module with nothing
    // today and nothing ever logged is left out; nothing today but an earlier log says so.
    const totals: Record<(typeof kinds)[number], [number, string]> = {
      bottle: [
        a.bottle.count,
        `${countOf(a.bottle.count, vi, 'cữ', ['feed', 'feeds'])} · ${groupedNumber(a.bottle.ml, vi)} ml`,
      ],
      breast: [
        a.breast.count,
        `${countOf(a.breast.count, vi, 'lần', ['feed', 'feeds'])} · ${durationText(a.breast.minutes, vi)}`,
      ],
      sleep: [
        a.sleep.count,
        `${countOf(a.sleep.count, vi, 'giấc', ['sleep', 'sleeps'])} · ${durationText(a.sleep.minutes, vi)}`,
      ],
      diaper: [diapers.length, countOf(diapers.length, vi, 'lần', ['change', 'changes'])],
      pump: [
        pumps.length,
        `${countOf(pumps.length, vi, 'lần', ['session', 'sessions'])} · ${groupedNumber(
          pumps.reduce((n, d) => n + num(d.get('data.amountMl')), 0),
          vi,
        )} ml`,
      ],
    };
    const labels: Record<(typeof kinds)[number], [string, string, string]> = {
      bottle: ['Bú bình', 'Bottle', '/care/stats/feed'],
      breast: ['Bú mẹ', 'Nursing', '/care/stats/feed'],
      sleep: ['Giấc ngủ', 'Sleep', '/care/stats/sleep'],
      diaper: ['Thay tã', 'Diapers', '/care/history?filter=diaper'],
      pump: ['Hút sữa', 'Pumping', '/care/history?filter=pump'],
    };
    for (const [i, kind] of kinds.entries()) {
      const d = latest[i]!.docs[0];
      if (d) lastIds.push(d.id);
      const at = d && safeId(d.id) ? toDate(d.get('occurredAt')) : null;
      const [count, figure] = totals[kind];
      if (count === 0 && !at) continue;
      const last = at ? `${vi ? 'Gần nhất' : 'Latest'} ${whenText(x, at, p.date)}` : null;
      rows.push({
        label: labels[kind][vi ? 0 : 1],
        value: [count === 0 ? (vi ? 'Chưa ghi' : 'None logged') : figure, last]
          .filter(Boolean)
          .join('\n'),
        link: labels[kind][2],
      });
    }
    rows.push(...timers.rows);
    if (!rows.length)
      rows.push({
        label: '',
        value: vi ? 'Chưa có ghi nhận nào trong ngày.' : 'Nothing logged for this day yet.',
      });
    return [
      card(
        x,
        tool,
        vi ? `Ngày của bé · ${date}` : `Baby's day · ${date}`,
        rows,
        '/today',
        [
          ...summary.parts.flatMap((p) => (p.type === 'source_summary' ? p.sourceIds : [])),
          ...p.docs.map((d) => d.id),
          ...timers.ids,
          ...lastIds,
        ],
        loggedNote(vi),
      ),
    ];
  }
  const kind = tool === 'diaper_summary' ? 'diaper' : 'pump';
  const docs = p.docs.filter((d) => d.get('type') === kind);
  const total = countOf(
    docs.length,
    vi,
    'lần',
    kind === 'pump' ? ['session', 'sessions'] : ['change', 'changes'],
  );
  const rows: Row[] = [{ label: vi ? 'Số lần đã ghi' : 'Logged', value: total }];
  if (kind === 'pump')
    rows.push({
      label: vi ? 'Tổng lượng đã hút' : 'Total expressed',
      value: `${groupedNumber(
        docs.reduce((n, d) => n + num(d.get('data.amountMl')), 0),
        vi,
      )} ml`,
    });
  else
    for (const [k, label] of [
      ['wet', vi ? 'Tã ướt' : 'Wet'],
      ['dirty', vi ? 'Tã bẩn' : 'Dirty'],
      ['both', vi ? 'Cả ướt và bẩn' : 'Wet and dirty'],
    ] as const) {
      const n = docs.filter((d) => d.get('data.kind') === k).length;
      if (n > 0) rows.push({ label, value: countOf(n, vi, 'lần', ['change', 'changes']) });
    }
  if (!docs.length)
    rows.splice(0, rows.length, {
      label: '',
      value: vi ? 'Chưa ghi lần nào trong khoảng này.' : 'Nothing logged in this period yet.',
    });
  return [
    card(
      x,
      tool,
      `${vi ? (kind === 'pump' ? 'Hút sữa' : 'Thay tã') : kind === 'pump' ? 'Pumping' : 'Diapers'} · ${period}`,
      rows,
      `/care/history?filter=${kind}`,
      docs.map((d) => d.id),
      loggedNote(vi),
    ),
  ];
}

async function growth(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const [p, all] = await Promise.all([
    profile(x),
    x.db.collection(`babies/${x.s.babyId}/records`).where('type', '==', 'growth').get(),
  ]);
  const docs = all.docs
    .filter(
      (d) =>
        d.get('deleted') !== true &&
        (toDate(d.get('occurredAt'))?.getTime() ?? Infinity) <= x.anchor.getTime(),
    )
    .sort(
      (a, b) => toDate(b.get('occurredAt'))!.getTime() - toDate(a.get('occurredAt'))!.getTime(),
    );
  const rows: Row[] = [],
    ids = new Set<string>();
  const decimal = (n: number) => groupedNumber(Number(n.toFixed(2)), vi);
  for (const [field, measure, unit, label] of [
    ['weightKg', 'weight', 'kg', vi ? 'Cân nặng' : 'Weight'],
    ['lengthCm', 'length', 'cm', vi ? 'Chiều dài' : 'Length'],
    ['headCm', 'head', 'cm', vi ? 'Vòng đầu' : 'Head circumference'],
  ] as const) {
    const matches = docs.filter((d) => num(d.get(`data.${field}`)) > 0);
    const latest = matches[0];
    if (!latest) continue;
    const at = toDate(latest.get('occurredAt'))!,
      value = num(latest.get(`data.${field}`));
    ids.add(latest.id);
    const pct = p.dob
      ? growthPercentile(
          measure,
          p.sex ?? '',
          daysBetweenIso(p.dob, localDateIn(x.s.zone, at)),
          value,
        )
      : null;
    const percentile =
      pct === null
        ? ''
        : ` · WHO ${pct < 0.1 ? `< P${decimal(0.1)}` : pct > 99.9 ? `> P${decimal(99.9)}` : `P${groupedNumber(Number(pct.toFixed(1)), vi)}`}`;
    const today = localDateIn(x.s.zone, x.anchor);
    const measured = shortDate(localDateIn(x.s.zone, at), today);
    const previous = matches.find(
      (d) => localDateIn(x.s.zone, toDate(d.get('occurredAt'))!) < localDateIn(x.s.zone, at),
    );
    // "7,2 kg · WHO P50" then "Đo 10/10 · +0,35 kg so với 12/09".
    let detail = `${vi ? 'Đo' : 'Measured'} ${measured}`;
    if (previous) {
      ids.add(previous.id);
      const delta = value - num(previous.get(`data.${field}`));
      const before = shortDate(localDateIn(x.s.zone, toDate(previous.get('occurredAt'))!), today);
      detail += ` · ${delta >= 0 ? '+' : '−'}${decimal(Math.abs(delta))} ${unit} ${vi ? 'so với' : 'since'} ${before}`;
    }
    rows.push({
      label,
      value: `${decimal(value)} ${unit}${percentile}\n${detail}`,
      link: '/care/growth',
    });
  }
  if (!rows.length)
    rows.push({
      label: vi ? 'Số đo' : 'Measurements',
      value: vi ? 'Chưa có số đo đã ghi.' : 'No measurements logged yet.',
    });
  return [
    card(
      x,
      'growth_snapshot',
      vi ? 'Tăng trưởng đã ghi' : 'Logged growth',
      rows,
      '/care/growth',
      [...ids],
      vi
        ? 'Percentile WHO tham khảo theo tuổi và giới tính, không phải chẩn đoán. Chưa đủ ngày sinh hoặc giới tính thì chưa tính percentile; xem biểu đồ để theo dõi nhiều lần đo.'
        : 'WHO age-and-sex percentiles are a reference, not a diagnosis. A date of birth and sex are needed to calculate a percentile; open the chart to follow repeated measurements.',
    ),
  ];
}

/** A schedule row as the reads and Lumi L5 use it (built in, a country's, or published). */
export interface ScheduleRow {
  id: string;
  name: { vi: string; en: string };
  short: { vi: string; en: string };
  months: number[];
  only5in1?: boolean | undefined;
  dtpSeries?: boolean | undefined;
}

/**
 * The schedule the family's book shows: its country's own (D-084), else the published Vietnam
 * table (P-138), else the one built in.
 */
export async function vaccineDefsFor(
  db: Firestore,
  country: string | null | undefined,
): Promise<readonly ScheduleRow[]> {
  const countryPlan = countryScheduleOf(country);
  if (countryPlan) return countryPlan.defs;
  const reference = await db.doc('publicConfig/reference_vaccines').get();
  const published = referencePublicSchema.safeParse(reference.data());
  const parsed =
    published.success && published.data.dataset === 'vaccines.schedule'
      ? referenceRowsSchemas['vaccines.schedule'].safeParse(published.data.rows)
      : null;
  return parsed?.success ? parsed.data : vaccineSchedule;
}

async function vaccines(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const country = x.s.ctx.family.country;
  const countryPlan = countryScheduleOf(country);
  const [plan, records, defs] = await Promise.all([
    x.db.doc(`babies/${x.s.babyId}/vaccinePlan/main`).get(),
    x.db.collection(`babies/${x.s.babyId}/vaccines`).get(),
    vaccineDefsFor(x.db, country),
  ]);
  const from = plan.get('scheduleFrom') as string | undefined;
  const today = localDateIn(x.s.zone, x.anchor);
  const rows: Row[] = [],
    sourceIds = ['vaccinePlan:main'];
  if (!from || !/^\d{4}-\d{2}-\d{2}$/.test(from))
    rows.push({
      label: vi ? 'Lịch của bé' : "Baby's schedule",
      value: vi
        ? 'Hãy thiết lập ngày bắt đầu trong Sổ tiêm chủng.'
        : 'Set the schedule start date in the vaccination book.',
    });
  else {
    const byId = new Map(records.docs.map((d) => [d.id, d]));
    const due: { key: string; name: string; date: string; dose: number }[] = [];
    for (const def of defs) {
      if (def.only5in1 && plan.get('dtp') !== '5in1') continue;
      def.months.forEach((months, i) => {
        const key = `${def.id}_${i + 1}`,
          record = byId.get(key);
        if (record && ['given', 'declined'].includes(record.get('status'))) return;
        const override = record?.get('plannedOn');
        const date =
          typeof override === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(override)
            ? override
            : plannedDate(from, months);
        due.push({
          key,
          name:
            def.dtpSeries && ['6in1', '5in1'].includes(plan.get('dtp'))
              ? String(plan.get('dtp'))
              : def.name[x.locale],
          date,
          dose: i + 1,
        });
      });
    }
    due.sort((a, b) => a.date.localeCompare(b.date) || a.key.localeCompare(b.key));
    for (const d of due.slice(0, 8)) {
      rows.push({
        label: `${d.name} · ${vi ? 'mũi' : 'dose'} ${d.dose}`,
        value: `${shortDate(d.date, today)}${d.date < today ? (vi ? '\nLịch đã qua, chưa ghi đã tiêm' : '\nPast planned date, no given record') : ''}`,
        link: `/care/vaccines/dose/${d.key}`,
      });
      sourceIds.push(`vaccine:${d.key}`);
    }
    if (!rows.length)
      rows.push({
        label: vi ? 'Mũi tiếp theo' : 'Next doses',
        value: vi
          ? 'Không còn mũi chưa ghi trong lịch hiện có.'
          : 'No unrecorded doses remain in the available schedule.',
      });
  }
  const source =
    countryPlan?.programmeName[x.locale] ??
    (vi ? 'Lịch Việt Nam trong ứng dụng' : 'Vietnam schedule in the app');
  return [
    card(
      x,
      'vaccine_next',
      vi ? 'Lịch tiêm sắp tới' : 'Upcoming vaccinations',
      rows,
      '/care/vaccines',
      sourceIds,
      `${source}. ${vi ? 'Theo ngày đã dời lịch và lựa chọn của gia đình; xác nhận lịch thực tế với nơi tiêm.' : 'Includes family choices and rescheduled dates; confirm actual appointments with your clinic.'}${country && country !== 'VN' && !countryPlan ? (vi ? ' Ứng dụng chưa có lịch cho quốc gia của gia đình; đang hiển thị lịch Việt Nam tham khảo.' : " Your country's schedule is unavailable; the Vietnam schedule is shown for reference.") : ''}`,
    ),
  ];
}

async function reminders(x: Input, offset: number): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi',
    date = addDaysIso(localDateIn(x.s.zone, x.anchor), offset);
  const { start, end } = dayBoundsIn(x.s.zone, date);
  const [snap, rules] = await Promise.all([
    x.db
      .collection(`babies/${x.s.babyId}/reminders`)
      .where('dueAt', '>=', start)
      .where('dueAt', '<', end)
      .get(),
    x.db.collection(`babies/${x.s.babyId}/reminderRules`).where('enabled', '==', true).get(),
  ]);
  const activeRules = rules.docs.filter((d) => {
    const due = toDate(d.get('nextDueAt'));
    return due && due >= start && due < end;
  });
  const docs = snap.docs
    .filter((d) => d.get('deleted') !== true)
    .sort(
      (a, b) => num(toDate(a.get('dueAt'))?.getTime()) - num(toDate(b.get('dueAt'))?.getTime()),
    );
  const assignees = [
    ...new Set(
      [
        ...docs.map((d) => d.get('assigneeUid')),
        ...activeRules.flatMap((d) => strings(d.get('recipients'))),
      ].filter((id): id is string => typeof id === 'string' && safeId(id)),
    ),
  ];
  const members = assignees.length
    ? await x.db.getAll(...assignees.map((id) => x.db.doc(`babies/${x.s.babyId}/members/${id}`)))
    : [];
  const names = new Map(
    members.map((d) => [
      d.id,
      d.get('status') === 'active' ? (d.get('displayName') as string) : null,
    ]),
  );
  const rows: Row[] = docs
    .filter((d) => safeId(d.id))
    .slice(0, 20)
    .map((d) => ({
      label: String(d.get('title') ?? ''),
      value: `${[
        d.get('allDay') === true
          ? vi
            ? 'Cả ngày'
            : 'All day'
          : localClock(x.s.zone, toDate(d.get('dueAt'))!),
        d.get('done') === true ? (vi ? 'Đã xong' : 'Done') : vi ? 'Chưa xong' : 'Pending',
      ].join(' · ')}\n${names.get(d.get('assigneeUid')) ?? (vi ? 'Chưa phân công' : 'Unassigned')}`,
      link: `/care/reminders/${d.id}`,
    }));
  const ruleLabels: Record<string, [string, string]> = {
    feed: ['Nhắc bú', 'Feed reminder'],
    sleep: ['Nhắc ngủ', 'Sleep reminder'],
    diaper: ['Nhắc thay tã', 'Diaper reminder'],
    pump: ['Nhắc hút sữa', 'Pump reminder'],
  };
  for (const d of activeRules.filter((d) => safeId(d.id)).slice(0, Math.max(0, 20 - rows.length))) {
    rows.push({
      label:
        ruleLabels[String(d.get('type'))]?.[vi ? 0 : 1] ??
        (vi ? 'Nhắc theo quy tắc' : 'Rule reminder'),
      value: [
        `${localClock(x.s.zone, toDate(d.get('nextDueAt'))!)} · ${vi ? 'lần tiếp theo' : 'next'}`,
        strings(d.get('recipients'))
          .map((id) => names.get(id))
          .filter(Boolean)
          .join(', '),
      ]
        .filter(Boolean)
        .join('\n'),
      link: `/care/reminders/rules/${d.id}`,
    });
  }
  if (!rows.length)
    rows.push({
      label: vi ? 'Nhắc việc' : 'Reminders',
      value: vi ? 'Chưa có nhắc việc trong ngày.' : 'No reminders for this day.',
    });
  return [
    card(
      x,
      'reminders_today',
      `${vi ? 'Nhắc việc' : 'Reminders'} · ${dateText(date)}`,
      rows,
      '/care/reminders',
      [...docs.map((d) => d.id), ...activeRules.map((d) => d.id)],
      docs.length + activeRules.length > 20
        ? vi
          ? `Hiển thị 20 / ${docs.length + activeRules.length} nhắc việc. Mở danh sách để xem hết.`
          : `Showing 20 of ${docs.length + activeRules.length} reminders. Open the list for all.`
        : null,
    ),
  ];
}

async function spending(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const today = localDateIn(x.s.zone, x.anchor),
    text = foldVi(x.text);
  const explicit = /\bthang\s+(1[0-2]|0?[1-9])(?:\s+(?:nam\s+)?(20\d{2}))?\b/u.exec(text);
  const month = explicit
    ? `${explicit[2] ?? today.slice(0, 4)}-${explicit[1]!.padStart(2, '0')}`
    : /\b(thang truoc|last month)\b/u.test(text)
      ? addMonthsIso(`${today.slice(0, 7)}-01`, -1).slice(0, 7)
      : today.slice(0, 7);
  const [snap, cats, budget] = await Promise.all([
    x.db
      .collection(`babies/${x.s.babyId}/expenses`)
      .where('spentOn', '>=', `${month}-01`)
      .where('spentOn', '<=', `${month}-31`)
      .get(),
    x.db.collection(`families/${x.s.familyId}/spendingCategories`).get(),
    x.db.doc(`babies/${x.s.babyId}/spending/budget`).get(),
  ]);
  const names = new Map(cats.docs.map((d) => [d.id, d.get('name') as string | null]));
  const defaults: Record<string, [string, string]> = {
    c_childcare: ['Giữ trẻ & học', 'Childcare & learning'],
    c_milk: ['Sữa & ăn dặm', 'Milk & solids'],
    c_diaper: ['Tã & vệ sinh', 'Diapers & hygiene'],
    c_health: ['Y tế & tiêm chủng', 'Health & vaccines'],
    c_clothes: ['Quần áo', 'Clothes'],
    c_other: ['Khác', 'Other'],
  };
  const categoryName = (id: string) =>
    names.get(id) ?? defaults[id]?.[vi ? 0 : 1] ?? (vi ? 'Khác' : 'Other');
  const groups = new Map<string, { total: number; categories: Map<string, number> }>();
  const docs = snap.docs.filter((d) => d.get('deleted') !== true);
  for (const d of docs) {
    const currency = currencyOfDoc(d.get('currency'));
    const g = groups.get(currency) ?? { total: 0, categories: new Map<string, number>() };
    const amount = num(d.get('amount')),
      category = String(d.get('categoryId'));
    g.total += amount;
    g.categories.set(category, (g.categories.get(category) ?? 0) + amount);
    groups.set(currency, g);
  }
  const money = (amount: number, currency: string) =>
    `${groupedNumber(minorToPlain(amount, currencyOfDoc(currency)), vi)} ${currency}`;
  const rows: Row[] = [...groups].map(([currency, g]) => ({
    label: `${vi ? 'Tổng đã chi' : 'Total spent'}${groups.size > 1 ? ` · ${currency}` : ''}`,
    value: money(g.total, currency),
  }));
  const monthlyBudget = budget.get('monthlyTotal');
  if (
    month === today.slice(0, 7) &&
    typeof monthlyBudget === 'number' &&
    Number.isFinite(monthlyBudget) &&
    monthlyBudget >= 0
  ) {
    const currency = currencyOfDoc(budget.get('currency'));
    const remaining = monthlyBudget - (groups.get(currency)?.total ?? 0);
    rows.push({
      label: vi ? 'Ngân sách tháng' : 'Monthly budget',
      value: money(monthlyBudget, currency),
      link: '/utilities/spending/budget',
    });
    rows.push({
      label: vi
        ? remaining < 0
          ? 'Vượt ngân sách'
          : 'Ngân sách còn lại'
        : remaining < 0
          ? 'Over budget'
          : 'Budget remaining',
      value: money(Math.abs(remaining), currency),
    });
  }
  for (const [currency, g] of groups) {
    for (const [id, amount] of [...g.categories].sort((a, b) => b[1] - a[1]))
      rows.push({ label: categoryName(id), value: money(amount, currency) });
  }
  if (!rows.length)
    rows.push({
      label: vi ? 'Chi tiêu' : 'Spending',
      value: vi ? 'Chưa có khoản chi đã ghi trong tháng.' : 'No expenses logged this month.',
    });
  return [
    card(
      x,
      'spending_month',
      `${vi ? 'Chi tiêu tháng' : 'Spending for'} ${month.split('-').reverse().join('/')}`,
      rows,
      '/utilities/spending',
      docs.map((d) => d.id),
      `${vi ? 'Chi tiêu của bé đang chọn, chỉ trong hội thoại riêng. Các loại tiền được cộng riêng, không quy đổi.' : 'Expenses for the selected baby, in your private conversation. Currencies are totalled separately without conversion.'}${rows.length > 24 ? (vi ? ' Một số danh mục chưa hiển thị; mở Chi tiêu để xem hết.' : 'Some categories are not displayed; open Spending for all.') : ''}`,
    ),
  ];
}

async function solids(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi',
    c = await solidsContext(x.db, x.s.babyId, x.anchor);
  const symptoms: Record<string, [string, string]> = {
    rash: ['Nổi mẩn, mề đay', 'Rash or hives'],
    vomit: ['Nôn', 'Vomiting'],
    diarrhea: ['Tiêu chảy', 'Diarrhoea'],
    fussy: ['Quấy khóc bất thường', 'Unusual fussiness'],
    swelling: ['Sưng môi, mặt', 'Lip or face swelling'],
    breathing: ['Khó thở, ho, khò khè', 'Breathing symptoms'],
    other: ['Dấu hiệu khác', 'Other symptoms'],
  };
  const reactions: Record<string, [string, string]> = {
    liked: ['Thích', 'Liked'],
    neutral: ['Bình thường', 'Neutral'],
    notYet: ['Chưa hợp', 'Not yet'],
  };
  const rows: Row[] = [...c.tried]
    .sort((a, b) => b[1].lastAt.getTime() - a[1].lastAt.getTime())
    .slice(0, 20)
    .map(([id, f]) => ({
      label: f.name[x.locale],
      value: `${countOf(f.count, vi, 'lần', ['try', 'tries'])}${f.reaction ? ` · ${reactions[f.reaction]?.[vi ? 0 : 1] ?? ''}` : ''}\n${vi ? 'Gần nhất' : 'Latest'} ${shortDate(localDateIn(x.s.zone, f.lastAt), localDateIn(x.s.zone, x.anchor))}${f.symptoms.size ? ` · ${[...f.symptoms].map((s) => symptoms[s]?.[vi ? 0 : 1] ?? s).join(', ')}` : ''}`,
      ...(id.startsWith('fd_') ? { link: `/care/solids/food/${id}` } : {}),
    }));
  if (!rows.length)
    rows.push({
      label: vi ? 'Thực phẩm đã thử' : 'Foods tried',
      value: vi
        ? 'Chưa có nguyên liệu trong nhật ký ăn dặm.'
        : 'No ingredients logged in the solids diary yet.',
    });
  return [
    card(
      x,
      'solids_history',
      vi ? 'Thực phẩm bé đã thử' : 'Foods your baby has tried',
      rows,
      '/care/solids/history?tab=foods',
      c.sourceIds,
      `${vi ? 'Dấu hiệu gia đình ghi sau ăn không xác định nguyên liệu gây dị ứng; chưa ghi phản ứng không có nghĩa đã dung nạp tốt.' : 'Family symptoms after a meal do not identify an allergen; no recorded reaction does not establish tolerance.'}${c.tried.size > 20 ? (vi ? ` Đang hiển thị 20 / ${c.tried.size} thực phẩm.` : ` Showing 20 of ${c.tried.size} foods.`) : ''}`,
    ),
  ];
}

async function milestones(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const [p, ref, records] = await Promise.all([
    profile(x),
    x.db.collection('contentMilestones').where('status', '==', 'published').get(),
    x.db.collection(`babies/${x.s.babyId}/milestones`).get(),
  ]);
  const reached = records.docs.filter(
    (d) =>
      d.get('deleted') !== true &&
      d.get('status') !== 'following' &&
      typeof d.get('date') === 'string' &&
      d.get('date') <= p.today,
  );
  const rows: Row[] = reached
    .sort((a, b) => String(b.get('date')).localeCompare(String(a.get('date'))))
    .slice(0, 10)
    .map((d) => ({
      label: String(d.get('name') ?? ''),
      value: `${vi ? 'Đã ghi' : 'Seen'} ${shortDate(d.get('date') as string, p.today)}`,
      link: `/utilities/milestones/${d.id.startsWith('p_') ? d.id.slice(2) : d.id}`,
    }));
  if (!rows.length)
    rows.push({
      label: vi ? 'Đã ghi nhận' : 'Observed',
      value: vi ? 'Chưa có mốc đã ghi nhận.' : 'No milestones recorded yet.',
    });
  const ids = new Set(reached.map((d) => d.id));
  const refs = ref.docs.flatMap((d) => {
    const r = referenceMilestoneSchema.safeParse(d.data());
    return r.success ? [r.data] : [];
  });
  if (p.dob) {
    const dob = p.dob;
    const around = refs
      .filter((r) => {
        const window = milestoneWindow(dob, r.ageRange);
        return (
          !ids.has(`p_${r.id}`) && window.start <= addDaysIso(p.today, 42) && window.end >= p.today
        );
      })
      .sort((a, b) => a.order - b.order)
      .slice(0, 6);
    for (const r of around)
      rows.push({
        label: r.title[x.locale],
        value: `${vi ? 'Quanh tuổi bé' : 'Around this age'}${r.illustrative ? (vi ? '\nMinh hoạ, chờ duyệt' : '\nIllustrative, awaiting review') : ''}`,
        link: `/utilities/milestones/${r.id}`,
      });
  }
  return [
    card(
      x,
      'milestones',
      vi ? 'Mốc của bé' : 'Baby milestones',
      rows,
      '/utilities/milestones',
      reached.map((d) => d.id),
      vi
        ? 'Mỗi bé có nhịp riêng. Mốc tham khảo không phải đánh giá sớm, muộn hay chẩn đoán.'
        : 'Every baby develops at their own pace. Reference milestones are not an early/late assessment or diagnosis.',
    ),
  ];
}

async function stage(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const [p, snap] = await Promise.all([
    profile(x),
    x.db.collection('contentStages').where('status', '==', 'published').get(),
  ]);
  const stages = snap.docs.flatMap((d) => {
    const r = contentStageSchema.safeParse(d.data());
    return r.success && r.data.audience.includes(x.s.member.role) ? [r.data] : [];
  });
  const current = p.dob ? stageFor(stages, p.dob, p.today) : null;
  const rows: Row[] = current
    ? [
        { label: current.title[x.locale], value: bullets(current.doing[x.locale]) },
        {
          label: vi ? 'Ba mẹ có thể thử' : 'Things to try',
          value: bullets(current.tryThis[x.locale]),
        },
      ]
    : [
        {
          label: vi ? 'Giai đoạn' : 'Stage',
          value: !p.dob
            ? vi
              ? 'Chưa đủ ngày sinh để chọn giai đoạn.'
              : 'A date of birth is needed to choose a stage.'
            : vi
              ? 'Chưa có nội dung phù hợp với tuổi bé.'
              : 'No stage content fits this age yet.',
        },
      ];
  return [
    card(
      x,
      'stage',
      vi ? 'Giai đoạn của bé' : 'Your baby’s stage',
      rows,
      current ? `/stages/${current.id}` : '/stages',
      current ? [current.id] : [],
      current?.illustrative
        ? vi
          ? 'Nội dung minh hoạ, chờ chuyên môn duyệt.'
          : 'Illustrative content, awaiting professional review.'
        : null,
    ),
  ];
}

/** Search terms after the request boilerplate; accents/case do not affect matching. */
export function articleQuery(text: string): string[] {
  const t = foldVi(text).replace(
    /\b(tim|cho|minh|toi|xin|xem|bai|viet|ve|thu|vien|lumi|be|con|hom|nay|phu|hop|voi|tuoi|article|articles|about|find|show|me|library|for|baby|my|please|read)\b/gu,
    ' ',
  );
  return [...new Set(t.match(/[\p{L}]{2,}/gu) ?? [])];
}
async function library(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const [p, snap] = await Promise.all([
    profile(x),
    x.db.collection('contentArticles').where('status', '==', 'published').get(),
  ]);
  const query = articleQuery(x.text);
  const articles = snap.docs.flatMap((d) => {
    const r = contentArticleSchema.safeParse(d.data());
    return r.success ? [r.data] : [];
  });
  const hits = articles
    .filter(
      (a) =>
        p.dob && articleFitsAge(a, p.dob, p.today) && contentFitsCountry(a, x.s.ctx.family.country),
    )
    .map((a) => {
      const hay = foldVi(
        `${a.title[x.locale]} ${a.summary[x.locale]} ${a.keywords[x.locale].join(' ')}`,
      );
      return { a, score: query.filter((q) => hay.includes(q)).length };
    })
    .filter((h) => query.length === 0 || h.score > 0)
    .sort((a, b) => b.score - a.score || a.a.id.localeCompare(b.a.id))
    .slice(0, 3);
  const rows: Row[] = hits.map(({ a }) => ({
    label: a.title[x.locale],
    value: `${a.summary[x.locale]}${a.illustrative ? (vi ? ' · nội dung minh hoạ, chờ duyệt' : ' · illustrative, awaiting review') : ''}`,
    link: `/library/a/${a.id}`,
  }));
  if (!rows.length)
    rows.push({
      label: vi ? 'Bài phù hợp' : 'Matching articles',
      value: !p.dob
        ? vi
          ? 'Chưa đủ ngày sinh để lọc bài theo tuổi.'
          : 'A date of birth is needed to filter articles by age.'
        : vi
          ? 'Chưa tìm thấy bài phù hợp chủ đề và tuổi bé.'
          : 'No articles match the topic and age yet.',
    });
  return [
    card(
      x,
      'library_search',
      vi ? 'Thư viện chăm bé' : 'Baby care library',
      rows,
      '/library',
      hits.map(({ a }) => a.id),
      vi
        ? 'Bài viết dùng nội dung đã xuất bản; hướng dẫn và số khẩn cấp khi mở bài theo quốc gia gia đình đã chọn.'
        : 'Published articles; local guidance and emergency numbers use your selected family country when opened.',
    ),
  ];
}

export async function firstAidRead(x: Input): Promise<AssistantPart[]> {
  x = {
    ...x,
    emergencyNumber:
      emergencyFor(await readRhythmContent(x.db), x.s.ctx.family.country)?.number ?? null,
  };
  const vi = x.locale === 'vi';
  const snap = await x.db.doc('publicConfig/content_firstAid').get();
  const pack = firstAidPublicSchema.safeParse(snap.data());
  const words = articleQuery(x.text).filter(
    (q) =>
      ![
        'lam',
        'the',
        'nao',
        'thi',
        'gi',
        'khi',
        'aid',
        'first',
        'can',
        'what',
        'how',
        'do',
        'to',
      ].includes(q),
  );
  const hits = pack.success
    ? pack.data.pack.situations
        .map((s) => ({
          s,
          score: words.filter((w) =>
            foldVi(
              `${s.title[x.locale]} ${s.lead[x.locale]} ${s.keywords.map((k) => k[x.locale]).join(' ')}`,
            ).includes(w),
          ).length,
        }))
        .filter((h) => h.score > 0)
        .sort((a, b) => b.score - a.score || a.s.id.localeCompare(b.s.id))
        .slice(0, 3)
    : [];
  const rows: Row[] = hits.map(({ s }) => ({
    label: s.title[x.locale],
    value: s.lead[x.locale].replace(
      new RegExp(`\\b${pack.success ? pack.data.pack.emergencyNumber : '115'}\\b`, 'g'),
      x.emergencyNumber ?? (vi ? 'số cấp cứu địa phương' : 'your local emergency number'),
    ),
    link: `/utilities/first-aid/s/${s.id}`,
  }));
  if (!rows.length)
    rows.push({
      label: vi ? 'Hướng dẫn Sơ cứu' : 'First aid guide',
      value: vi
        ? 'Mở Sơ cứu để chọn tình huống và độ tuổi phù hợp.'
        : 'Open First aid to choose the situation and age group.',
    });
  return [
    card(
      x,
      'first_aid',
      vi ? 'Sơ cứu trẻ em' : 'Child first aid',
      rows,
      '/utilities/first-aid',
      hits.map(({ s }) => s.id),
      pack.success && pack.data.pack.review === null
        ? vi
          ? 'Nội dung minh hoạ, chờ chuyên môn duyệt.'
          : 'Illustrative content, awaiting professional review.'
        : null,
    ),
  ];
}

/** Hiểu con (D-150 Premium, D-151 #7): the current insights and how each was worked out. */
async function insightRead(x: Input): Promise<AssistantPart[]> {
  const vi = x.locale === 'vi';
  const title = vi ? 'Điều đáng chú ý' : 'Worth noticing';
  if (!checkCapability(x.s.ctx, 'rhythm.advanced', x.anchor, 'history.read').allowed)
    return [
      card(
        x,
        'insight_basis',
        title,
        [
          {
            label: '',
            value: vi ? 'Hiểu con có trong Premium.' : 'Know your baby is part of Premium.',
          },
        ],
        '/care/insights',
        [],
      ),
    ];
  const doc = await x.db.doc(`babies/${x.s.babyId}/insights/current`).get();
  const basis = insightBasis(doc.data(), vi);
  if (basis.kind !== 'items')
    return [
      card(x, 'insight_basis', title, [{ label: '', value: basis.text }], '/care/insights', []),
    ];
  return [
    card(
      x,
      'insight_basis',
      title,
      basis.rows,
      basis.link,
      [`insights:${basis.computedAt}`],
      insightCaveat(vi),
    ),
  ];
}

export async function assistantRead(
  x: Input,
  request: AssistantReadRequest,
): Promise<AssistantPart[]> {
  if (!allowsAssistantRead(request.tool, x.s.member))
    return [noticePart({ code: 'READ_DENIED' }, x.locale)];
  if (request.tool === 'stage' || request.tool === 'library_search')
    x = {
      ...x,
      emergencyNumber:
        emergencyFor(await readRhythmContent(x.db), x.s.ctx.family.country)?.number ?? null,
    };
  switch (request.tool) {
    case 'care_summary': {
      const vi = x.locale === 'vi';
      const r = await careSummaryTool(x.db, x.s, x.anchor, request.dayOffset, x.locale);
      const a = r.summary;
      const today = localDateIn(x.s.zone, x.anchor);
      // Owner 2026-10-31: label/value rows, zero modules left out, minutes as hours. The model
      // still reads the sentences in `r.facts`.
      const rows = [
        a.bottle.count > 0 && {
          label: vi ? 'Bú bình' : 'Bottle',
          value: `${countOf(a.bottle.count, vi, 'cữ', ['feed', 'feeds'])} · ${groupedNumber(a.bottle.ml, vi)} ml`,
          link: '/care/stats/feed',
        },
        a.breast.count > 0 && {
          label: vi ? 'Bú mẹ' : 'Nursing',
          value: `${countOf(a.breast.count, vi, 'lần', ['feed', 'feeds'])} · ${durationText(a.breast.minutes, vi)}`,
          link: '/care/stats/feed',
        },
        a.sleep.count > 0 && {
          label: vi ? 'Giấc ngủ' : 'Sleep',
          value: `${countOf(a.sleep.count, vi, 'giấc', ['sleep', 'sleeps'])} · ${durationText(a.sleep.minutes, vi)}`,
          link: '/care/stats/sleep',
        },
      ].filter((row) => row !== false);
      return [
        card(
          x,
          request.tool,
          `${vi ? 'Bú và ngủ đã ghi' : 'Logged feeds and sleep'} · ${shortDate(a.date, today)}`,
          rows.length
            ? rows
            : [
                {
                  label: '',
                  value: vi ? 'Chưa ghi cữ bú hay giấc ngủ nào.' : 'No feeds or sleep logged yet.',
                },
              ],
          '/care/history',
          r.parts.flatMap((p) => (p.type === 'source_summary' ? p.sourceIds : [])),
          loggedNote(vi),
        ),
      ];
    }
    case 'sleep_facts': {
      const vi = x.locale === 'vi';
      const r = await sleepFactsTool(x.db, x.s, x.anchor, x.locale);
      const perDay = (m: number) => `${vi ? 'khoảng' : 'about'} ${durationText(m, vi)}`;
      return [
        card(
          x,
          request.tool,
          vi ? 'Xu hướng giấc ngủ' : 'Sleep trend',
          r.trend
            ? [
                {
                  label: vi ? 'Gần đây (mỗi ngày)' : 'Recently (per day)',
                  value: perDay(r.trend.recent),
                },
                {
                  label: vi ? 'Trước đó (mỗi ngày)' : 'Before (per day)',
                  value: perDay(r.trend.baseline),
                },
              ]
            : r.facts.map((f) => ({ label: '', value: f.text })),
          '/care/stats/sleep',
          r.facts.map((f) => f.id),
          loggedNote(vi),
        ),
      ];
    }
    case 'usage_snapshot': {
      const r = await usageSnapshotTool(x.db, x.s, x.anchor, x.locale);
      return [{ type: 'text', schemaVersion: 1, text: r.facts.map((f) => f.text).join(' ') }];
    }
    case 'day_overview':
    case 'diaper_summary':
    case 'pump_summary':
      return daily(x, request);
    case 'growth_snapshot':
      return growth(x);
    case 'running_timer': {
      const t = foldVi(x.text);
      const only = /\b(ngu|sleep|sleeping)\b/u.test(t)
        ? 'sleep'
        : /\b(hut|pump|pumping)\b/u.test(t)
          ? 'pump'
          : /\b(bu|nursing|nurs)\b/u.test(t)
            ? 'breast'
            : undefined;
      const r = await timerRows(x, only);
      return [
        card(
          x,
          request.tool,
          x.locale === 'vi' ? 'Đang tính giờ' : 'Running timers',
          r.rows.length
            ? r.rows
            : [
                {
                  label: '',
                  value:
                    x.locale === 'vi'
                      ? 'Hiện chưa có timer đang chạy.'
                      : 'No timer is running now.',
                },
              ],
          r.rows[0]?.link ?? '/today',
          r.ids,
        ),
      ];
    }
    case 'insight_basis':
      return insightRead(x);
    case 'vaccine_next':
      return vaccines(x);
    case 'reminders_today':
      return reminders(x, request.dayOffset);
    case 'spending_month':
      return spending(x);
    case 'solids_history':
      return solids(x);
    case 'milestones':
      return milestones(x);
    case 'stage':
      return stage(x);
    case 'library_search':
      return library(x);
    case 'first_aid':
      return firstAidRead(x);
  }
}
