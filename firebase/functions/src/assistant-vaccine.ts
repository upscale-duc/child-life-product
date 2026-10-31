import type { Firestore } from 'firebase-admin/firestore';
import {
  familyCan,
  foldVi,
  localDateIn,
  type AssistantPart,
  type VaccinePlace,
} from '@child-life/contracts';
import type { TrustedScope } from './assistant-common.js';
import { vaccineDefsFor, type ScheduleRow } from './assistant-reads.js';

type Locale = 'vi' | 'en';

/**
 * Lumi L5 (vaccines): "bé vừa tiêm 6in1 mũi 2 ở VNVC", "hôm qua cho bé uống rota", "she got her
 * MMR today" — read by rules, no model, 0 credits. Lumi never saves the dose: the family's Sổ
 * tiêm chủng opens its own "Ghi mũi tiêm" form with what was said (dose, date, place), where the
 * reaction and photo are added and the dose is saved (the book's permissions, P-133). Questions
 * ("khi nào tiêm mũi tiếp?") and plans ("mai đi tiêm") are left to the reads and the model.
 */

/** Each NFC character folded on its own, so indices in the result are indices in [s]. */
const foldKeep = (s: string) =>
  [...s.normalize('NFC')].map((c) => foldVi(c).charAt(0) || c).join('');

const w = (alts: string) =>
  new RegExp(String.raw`(?<![\p{L}\p{N}])(?:${alts})(?![\p{L}\p{N}])`, 'gu');

/**
 * What people call each vaccine, folded, longest first where one contains another. Ids cover the
 * Vietnam book and the country schedules (contracts `vaccine-countries.ts`); the first id the
 * family's schedule has wins.
 */
const aliases: [string, string[]][] = [
  ['soi quai bi rubella|soi quai bi|mmr ?ii|mmr|priorix|measles mumps rubella', ['mmr', 'mmrv']],
  ['mmrv|proquad|priorix tetra', ['mmrv', 'mmr']],
  ['soi rubella|mr', ['mr', 'measles', 'mmr']],
  ['soi|mvvac|measles', ['measles', 'mr', 'mmr']],
  ['quai bi|mumps', ['mumps', 'mmr']],
  ['thuy dau|varivax|varilrix|chickenpox|varicella', ['varicella', 'var', 'mmrv']],
  ['viem gan a|avaxim|havax|hep a|hepatitis a', ['hepa']],
  ['viem gan b|engerix|heberbiovac|hep b|hepatitis b', ['hepb']],
  [
    '6 ?in ?1|6 trong 1|sau trong mot|hexaxim|infanrix hexa|infanrix|hexyon|vaxelis|6-in-1',
    ['dtp', 'sixin1', 'hexa', 'sixfive', 'fivein1', 'dtap'],
  ],
  [
    '5 ?in ?1|5 trong 1|nam trong mot|pentaxim|quinvaxem|combe five|sii|5-in-1',
    ['dtp', 'fivein1', 'sixfive', 'sixin1', 'hexa', 'dtap'],
  ],
  ['bach hau ho ga uon van|dtap|dtp|whooping cough', ['dtap', 'dtp', 'sixin1', 'hexa', 'fivein1']],
  ['bai liet|polio|opv|ipv|bopv', ['polio', 'ipv']],
  ['rota|rotarix|rotateq|rotavin|rotavirus', ['rota']],
  ['phe cau|synflorix|prevenar|vaxneuvance|pcv|pneumococcal', ['pcv']],
  ['nao mo cau bc|va-? ?mengoc|mengoc', ['menbc', 'menb']],
  ['nao mo cau b|bexsero|men ?b', ['menb', 'menbc']],
  [
    'nao mo cau acyw|nao mo cau|menactra|menquadfi|nimenrix|menveo|menacwy|menacyw',
    ['menacyw', 'menacwy'],
  ],
  ['viem nao nhat ban|imojev|jevax|jeev|viem nao|japanese encephalitis', ['je']],
  ['cum mua|cum|vaxigrip|influvac|ivacflu|gc flu|flu|influenza', ['flu']],
  ['hib|quimi-hib', ['hib', 'hibb']],
  ['rsv|beyfortus|nirsevimab', ['rsv']],
  ['lao|bcg|tuberculosis', ['bcg']],
  ['vitamin k|vit k', ['vitk']],
];

/** Words for a shot; "uống" only counts with a vaccine named ("uống rota", not "uống vitamin D"). */
const shotWords = w(
  'tiem|chich|tiem phong|vac ?xin|vaccinated|vaccines?|vaccinations?|immuni[sz]ed|shots?|jabs?',
);
const actWords = new RegExp(`${shotWords.source}|(?<![\\p{L}])uong(?![\\p{L}])`, 'u');
/** Asking about the book or planning a visit: not a dose given. */
const notGiven = w(
  'khi nao|bao gio|luc nao|may gio|chua|sap|se|dinh|hen|lich tiem|ke tiep|tiep theo|mui sau|nen|co nen|co can|duoc khong|bao nhieu|ngay mai|sang mai|chieu mai|toi mai|mai di|mai tiem|tuan sau|thang sau|when|should|next|due|tomorrow|will|going to|scheduled|appointment|how|what|which',
);
/** Other logs in the same message: the model reads those (and the dose waits for its own turn). */
const otherLogs = w(
  'bu|bu binh|ml|oz|ngu|thay ta|ta|bim|hut sua|can nang|kg|cm|an dam|bua an|cho an|an chao|an bot|mua|nghin|trieu|nhac|feed|feeds|bottle|nap|diaper|pump|weigh|bought|remind',
);

const numberWords: Record<string, number> = {
  mot: 1,
  hai: 2,
  ba: 3,
  bon: 4,
  tu: 4,
  nam: 5,
  sau: 6,
  first: 1,
  second: 2,
  third: 3,
  fourth: 4,
  fifth: 5,
  '1st': 1,
  '2nd': 2,
  '3rd': 3,
  '4th': 4,
  '5th': 5,
};

export interface VaccineMention {
  /** Candidate ids, preferred first. */
  ids: string[];
  /** The words matched, folded ("6in1", "rota"). */
  said: string;
  /** 1-based, `'booster'` for "mũi nhắc", null when not said. */
  dose: number | 'booster' | null;
}

export interface VaccineGiven {
  mentions: VaccineMention[];
  /** YYYY-MM-DD in the baby's zone. */
  givenOn: string;
  place: VaccinePlace | null;
  facility: string | null;
}

function doseIn(f: string): number | 'booster' | null {
  if (w('mui nhac|nhac lai|booster').test(f)) return 'booster';
  const m =
    /(?<![\p{L}])(?:mui|lan|dose|shot)\s*(?:so\s*|thu\s*)?(\d|mot|hai|ba|bon|tu|nam|sau)(?![\p{L}\p{N}])/u.exec(
      f,
    ) ??
    /(?<![\p{L}\p{N}])(first|second|third|fourth|fifth|1st|2nd|3rd|4th|5th)\s*(?:dose|shot|jab)/u.exec(
      f,
    );
  if (!m) return null;
  const n = /^\d$/.test(m[1]!) ? Number(m[1]) : numberWords[m[1]!];
  return n && n >= 1 && n <= 9 ? n : null;
}

/** dd/mm or dd/mm/yyyy (a year past this one never), else the day words, else today. */
function dateIn(f: string, today: string): string | null {
  const [y, mo, d] = today.split('-').map(Number) as [number, number, number];
  const shift = (days: number) => {
    const t = new Date(Date.UTC(y, mo - 1, d + days));
    return t.toISOString().slice(0, 10);
  };
  const m = /(?<![\p{N}])(\d{1,2})[/.-](\d{1,2})(?:[/.-](\d{2,4}))?(?![\p{N}])/u.exec(f);
  if (m) {
    const day = Number(m[1]),
      month = Number(m[2]);
    let year = m[3] ? Number(m[3]) : y;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    const date = new Date(Date.UTC(year, month - 1, day));
    if (date.getUTCDate() !== day) return null;
    // "5/11" said on 31/10 with no year is last November.
    if (!m[3] && date.toISOString().slice(0, 10) > today) date.setUTCFullYear(year - 1);
    const iso = date.toISOString().slice(0, 10);
    return iso > today ? null : iso;
  }
  if (w('hom kia|day before yesterday').test(f)) return shift(-2);
  if (w('hom qua|toi qua|sang qua|chieu qua|trua qua|yesterday|last night').test(f))
    return shift(-1);
  return today;
}

function placeIn(text: string, f: string): { place: VaccinePlace | null; facility: string | null } {
  const at = /(?<![\p{L}])(?:o|tai|at)\s+(?=\S)/gu;
  let facility: string | null = null;
  for (const m of f.matchAll(at)) {
    const start = m.index + m[0].length;
    const rest = f.slice(start);
    const stop =
      /[,.;!?\n]|\s(?:luc|hom|ngay|mui|lan|va|vao|sang|trua|chieu|toi|roi|xong|nhe|nha|today|yesterday|this|and|on)(?![\p{L}])/u.exec(
        rest,
      );
    const words = text
      .normalize('NFC')
      .slice(start, start + (stop ? stop.index : rest.length))
      .trim();
    if (words && words.length <= 80 && !/^(?:nha|nhà|home)$/iu.test(words)) {
      facility = words;
      break;
    }
  }
  const p = facility ? foldVi(facility) : f;
  const place: VaccinePlace | null = w('benh vien|bv|hospital').test(p)
    ? 'hospital'
    : w('tram y te|tram|phuong|xa|health station').test(p)
      ? 'station'
      : w('vnvc|long chau|safpo|potec|dich vu|phong kham|clinic|pharmacy').test(p)
        ? 'service'
        : null;
  return { place, facility };
}

/**
 * The doses a message says were given, or null when it does not say one was (a question, a plan,
 * other logs with it, no act word). `mentions` is empty for "bé vừa tiêm xong" with no name.
 */
export function vaccineGivenIn(text: string, today: string): VaccineGiven | null {
  const f = foldKeep(text.toLocaleLowerCase('vi'));
  if (!actWords.test(f)) return null;
  if (new RegExp(notGiven.source, 'u').test(f) || f.includes('?')) return null;
  const found: { at: number; end: number; ids: string[]; said: string }[] = [];
  let masked = f;
  for (const [alts, ids] of aliases) {
    for (const m of masked.matchAll(w(alts))) {
      found.push({ at: m.index, end: m.index + m[0].length, ids, said: m[0] });
      masked =
        masked.slice(0, m.index) + ' '.repeat(m[0].length) + masked.slice(m.index + m[0].length);
    }
  }
  found.sort((a, b) => a.at - b.at);
  // Whatever is left once the vaccine names are out must not be another log ("bú 120ml");
  // "mũi nhắc" is a booster, not a reminder.
  masked = masked.replace(w('mui nhac|nhac lai'), ' ');
  if (new RegExp(otherLogs.source, 'u').test(masked) || /\d\s*(?:k|d|tr)(?![\p{L}])/u.test(masked))
    return null;
  if (
    found.length === 0 &&
    !(
      new RegExp(shotWords.source, 'u').test(f) &&
      w('vua|da|xong|roi|moi|hom nay|today|got|had').test(f)
    )
  )
    return null;
  const mentions: VaccineMention[] = [];
  for (const [i, m] of found.entries()) {
    if (mentions.some((x) => x.ids[0] === m.ids[0])) continue;
    const next = found[i + 1]?.at ?? f.length;
    const own = doseIn(f.slice(m.end, next)) ?? doseIn(f.slice(found[i - 1]?.end ?? 0, m.at));
    mentions.push({
      ids: m.ids,
      said: m.said,
      dose: own ?? (found.length === 1 ? doseIn(f) : null),
    });
  }
  const givenOn = dateIn(f, today);
  if (!givenOn) return null;
  return { mentions, givenOn, ...placeIn(text, f) };
}

/** `/care/vaccines?log=dtp_2&on=…&place=…&facility=…`: the book opening its form on that dose. */
export function vaccineLogLink(
  key: string | null,
  g: Pick<VaccineGiven, 'givenOn' | 'place' | 'facility'>,
): string {
  const q = new URLSearchParams();
  if (key) {
    q.set('log', key);
    q.set('on', g.givenOn);
    if (g.place) q.set('place', g.place);
    if (g.facility) q.set('facility', g.facility);
  }
  const s = q.toString();
  return s ? `/care/vaccines?${s}` : '/care/vaccines';
}

const L = (vi: string, en: string) => ({ vi, en });
const ddmm = (date: string) => {
  const [, m, d] = date.split('-');
  return `${Number(d)}/${Number(m)}`;
};

function part(text: { vi: string; en: string }, locale: Locale, link?: string): AssistantPart {
  return link
    ? { type: 'text', schemaVersion: 1, text: text[locale], code: 'VACCINE_DOSE', link }
    : { type: 'text', schemaVersion: 1, text: text[locale] };
}

/** The family's schedule row for a mention (the book's rows: polio only on the 5in1 path). */
function defOf(defs: readonly ScheduleRow[], m: VaccineMention, dtp: unknown) {
  const rows = defs.filter((d) => !d.only5in1 || dtp === '5in1');
  for (const id of m.ids) {
    const def = rows.find((d) => d.id === id);
    if (def) return def;
  }
  return null;
}

/** What Lumi answers for [g]: one part per vaccine named, each opening its dose in the book. */
export async function vaccineParts(
  db: Firestore,
  s: TrustedScope,
  g: VaccineGiven,
  locale: Locale,
  anchor: Date,
): Promise<AssistantPart[]> {
  if (!familyCan(s.member, 'rhythm.checkin')) {
    return [
      part(
        L(
          'Bạn xem được Sổ tiêm chủng nhưng không ghi được mũi tiêm, nên mình chưa ghi mũi này.',
          'You can view the vaccination book but not log shots, so this one was not logged.',
        ),
        locale,
      ),
    ];
  }
  const ask = part(
    L(
      'Bé vừa tiêm mũi nào? Bạn nói tên mũi (ví dụ “6in1 mũi 2”), hoặc mở Sổ tiêm chủng để đánh dấu.',
      'Which shot was it? Say its name (for example “6-in-1 dose 2”), or open the vaccination book to tick it.',
    ),
    locale,
    vaccineLogLink(null, g),
  );
  if (g.mentions.length === 0) return [ask];
  const [plan, records, defs] = await Promise.all([
    db.doc(`babies/${s.babyId}/vaccinePlan/main`).get(),
    db.collection(`babies/${s.babyId}/vaccines`).get(),
    vaccineDefsFor(db, s.ctx.family.country),
  ]);
  const dtp = plan.get('dtp');
  const byKey = new Map(records.docs.map((d) => [d.id, d]));
  const done = (key: string) => ['given', 'declined'].includes(byKey.get(key)?.get('status'));
  const today = localDateIn(s.zone, anchor);
  const when =
    g.givenOn === today
      ? L(`hôm nay (${ddmm(g.givenOn)})`, `today (${ddmm(g.givenOn)})`)
      : L(`ngày ${ddmm(g.givenOn)}`, `on ${ddmm(g.givenOn)}`);
  const at = g.facility ? L(` tại ${g.facility}`, ` at ${g.facility}`) : L('', '');
  const parts: AssistantPart[] = [];
  for (const m of g.mentions) {
    const def = defOf(defs, m, dtp);
    if (!def) continue;
    const label = def.dtpSeries
      ? typeof dtp === 'string' && ['6in1', '5in1'].includes(dtp)
        ? dtp
        : m.said.startsWith('5') || m.said.includes('5 trong') || m.said.startsWith('penta')
          ? '5in1'
          : def.short[locale]
      : def.short[locale];
    const total = def.months.length;
    const keyOf = (n: number) => `${def.id}_${n}`;
    let n: number | null;
    if (m.dose === 'booster') n = total;
    else if (typeof m.dose === 'number') n = m.dose;
    else {
      const open = def.months.findIndex((_, i) => !done(keyOf(i + 1)));
      n = open < 0 ? null : open + 1;
    }
    if (n === null) {
      parts.push(
        part(
          L(
            `Sổ tiêm chủng đã ghi đủ ${total} mũi ${label}.`,
            `The vaccination book already has all ${total} ${label} doses.`,
          ),
          locale,
          '/care/vaccines',
        ),
      );
      continue;
    }
    if (n > total) {
      parts.push(
        part(
          L(
            `Lịch trong Sổ tiêm chủng có ${total} mũi ${label}, chưa có mũi ${n}.`,
            `The book's schedule has ${total} ${label} doses, not a dose ${n}.`,
          ),
          locale,
          '/care/vaccines',
        ),
      );
      continue;
    }
    const key = keyOf(n);
    const record = byKey.get(key);
    if (record?.get('status') === 'given') {
      const on = record.get('givenOn');
      parts.push(
        part(
          typeof on === 'string'
            ? L(
                `${label} · mũi ${n} đã có trong Sổ tiêm chủng (tiêm ngày ${ddmm(on)}).`,
                `${label} · dose ${n} is already in the vaccination book (given on ${ddmm(on)}).`,
              )
            : L(
                `${label} · mũi ${n} đã có trong Sổ tiêm chủng.`,
                `${label} · dose ${n} is already in the vaccination book.`,
              ),
          locale,
          `/care/vaccines/dose/${key}`,
        ),
      );
      continue;
    }
    parts.push(
      part(
        L(
          `Mình chuẩn bị sẵn ${label} · mũi ${n}, tiêm ${when.vi}${at.vi}. Chạm Ghi mũi tiêm để xem lại và lưu vào Sổ tiêm chủng.`,
          `Here is ${label} · dose ${n}, given ${when.en}${at.en}. Tap Log a shot to check it and save it to the vaccination book.`,
        ),
        locale,
        vaccineLogLink(key, g),
      ),
    );
  }
  return parts.length ? parts : [ask];
}
