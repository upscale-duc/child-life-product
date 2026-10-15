import { createHash } from 'node:crypto';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  addDaysIso,
  aiCacheKey,
  aiConsentVersion,
  aiGate,
  aiOutputSchema,
  aiSummaryLimits,
  aiSummaryPromptVersion,
  checkInSchema,
  claimProblems,
  daysBetweenIso,
  familyCan,
  generateSummaryRequestSchema,
  listSummariesRequestSchema,
  localDateIn,
  needOf,
  needsHealthSupport,
  recFeedbackSchema,
  reportSummaryRequestSchema,
  setAiConsentRequestSchema,
  type Activity,
  type AiConsent,
  type AiOutput,
  type AiSummaryKind,
  type CheckIn,
  type GrantEnvironment,
  type Need,
  type QuotaSnapshot,
  type RecFeedback,
  type RhythmContent,
  type SummaryAnswer,
  type SummaryFact,
  type SummaryFallbackReason,
  type SummaryView,
} from '@child-life/contracts';
import { type AiProvider, type SummarizeInput } from './ai.js';
import {
  checkCapability,
  gateError,
  loadEntitlementContext,
  type EntitlementContext,
} from './entitlements.js';
import { countAppEvent } from './feedback.js';
import {
  commitQuota,
  quotaSnapshot,
  readQuotaSnapshot,
  releaseQuota,
  reserveQuota,
  type QuotaWindowRequest,
  type StoredQuotaWindow,
} from './quota.js';
import { readRhythmContent, readRhythmRules, sleepFacts } from './rhythm.js';
import { aiBudgetLeft, chargeAi } from './staff.js';

/**
 * Grounded AI, Slice 3 (plan §5.5, brief p.14, P-151 while Q-070 is open): a handover for the
 * next carer (SU01 / NL10), the explanation of one suggestion, a nudge to keep a milestone.
 *
 * Pipeline of `generateSummary`, in this order: auth → membership + `ai.generate` (Cùng nuôi;
 * caregivers and relatives read stored summaries with `history.read`, never generate, D-072 #2)
 * → health rule (health signs in the range: no model, a pointer to health support) → facts
 * snapshot → approved suggestion candidates → `ai.assistance` (entitlement + `ai_assist` kill
 * switch) and the caller's consent → cache → quota (per baby per day AND per family per month, in
 * one transaction) → provider with a timeout → `aiOutputSchema` + `aiGate` + `claimProblems` →
 * snapshot + commit; any failure releases the quota and answers with the free template built
 * from the same facts. Idempotent per `requestId`. No child data, notes or text in logs.
 */

export class AiSummaryError extends Error {
  constructor(
    readonly code:
      'invalid-argument' | 'permission-denied' | 'not-found' | 'failed-precondition' | 'aborted',
    readonly reason: string,
  ) {
    super(reason);
  }
}

export interface SummaryDeps {
  db: Firestore;
  provider: AiProvider;
  now: Date;
  environment: GrantEnvironment;
  /** Model call budget (A05); defaults to `aiSummaryLimits.timeoutMs`. */
  timeoutMs?: number;
}

const DEFAULT_ZONE = 'Asia/Ho_Chi_Minh';
/** A pending claim older than this is taken over (the earlier run died). */
const CLAIM_STALE_MS = 120_000;

function parseOr<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new AiSummaryError('invalid-argument', 'bad-request');
  return r.data as T;
}

const iso = (v: unknown): string | null =>
  v instanceof Timestamp ? v.toDate().toISOString() : typeof v === 'string' ? v : null;

export function summaryIdFor(uid: string, babyId: string, requestId: string): string {
  return `su_${createHash('sha256').update(`${uid}|${babyId}|${requestId}`).digest('hex').slice(0, 32)}`;
}

// ---------- Consent (users/{uid}/settings/ai) ----------

interface ConsentState {
  granted: boolean;
  shareMyNotes: boolean;
}

/** Only the current consent version counts (brief p.14); anything else is no consent. */
function consentOf(snap: DocumentSnapshot | undefined): ConsentState {
  const c = snap?.get('consent') as { version?: string; shareMyNotes?: boolean } | null | undefined;
  const granted = !!c && c.version === aiConsentVersion;
  return { granted, shareMyNotes: granted && c?.shareMyNotes === true };
}

const consentRef = (db: Firestore, uid: string) => db.doc(`users/${uid}/settings/ai`);

function consentView(snap: DocumentSnapshot): AiConsent {
  const c = snap.get('consent') as
    { version: string; grantedAt: unknown; shareMyNotes: boolean } | null | undefined;
  return {
    consent: c
      ? { version: c.version, grantedAt: iso(c.grantedAt) ?? '', shareMyNotes: c.shareMyNotes }
      : null,
    updatedAt: iso(snap.get('updatedAt')),
  };
}

// ---------- Fact lines (engine-written, both languages) ----------

type Locale = 'vi' | 'en';
const L = <T extends string>(m: Record<T, [string, string]>) => m;
const observationLabel = L({
  sleep: ['Giấc ngủ khác mọi ngày', 'Sleep was different'],
  feeding: ['Ăn bú khác mọi ngày', 'Feeding was different'],
  soothing: ['Khó dỗ hơn', 'Harder to soothe'],
  new_skill: ['Có kỹ năng mới', 'A new skill'],
  usual: ['Như mọi ngày', 'A usual day'],
  health: ['Lo về sức khoẻ', 'A health concern'],
});
const whenLabel = L({
  night: ['ban đêm', 'at night'],
  day: ['ban ngày', 'during the day'],
  both: ['cả ngày lẫn đêm', 'day and night'],
});
const sinceLabel = L({
  today: ['từ hôm nay', 'since today'],
  days_2_3: ['2–3 ngày', '2–3 days'],
  longer: ['lâu hơn', 'longer'],
});
const triedLabel = L({
  rocking: ['ru', 'rocking'],
  white_noise: ['tiếng ồn trắng', 'white noise'],
  feeding: ['cho bú', 'feeding'],
  skin_to_skin: ['da kề da', 'skin to skin'],
  swaddle: ['quấn', 'swaddling'],
  none: ['chưa thử gì', 'nothing yet'],
});
const feedbackLabel = L({
  started: ['Đã thử', 'Tried'],
  helpful: ['Có ích', 'Helped'],
  unsure: ['Chưa rõ', 'Not sure'],
  not_suitable: ['Không phù hợp', 'Not suitable'],
  not_today: ['Để sau', 'Not today'],
});
const pick = (pair: [string, string], locale: Locale) => (locale === 'vi' ? pair[0] : pair[1]);

function checkInLine(c: CheckIn, locale: Locale): string {
  const parts = [pick(observationLabel[c.observation], locale)];
  if (c.when) parts.push(pick(whenLabel[c.when], locale));
  if (c.since) parts.push(pick(sinceLabel[c.since], locale));
  if (c.tried.length) {
    const tried = c.tried.map((t) => pick(triedLabel[t], locale)).join(', ');
    parts.push(locale === 'vi' ? `đã thử: ${tried}` : `tried: ${tried}`);
  }
  if (c.healthSigns.length) parts.push(locale === 'vi' ? 'có dấu hiệu sức khoẻ' : 'health signs');
  return parts.join(' · ');
}

const hm = (minutes: number, locale: Locale) => {
  const h = Math.floor(minutes / 60);
  const m = Math.round(minutes % 60);
  return locale === 'vi' ? `${h} giờ ${m} phút` : `${h} h ${m} min`;
};

const activityTitle = (content: RhythmContent | null, id: string, locale: Locale) =>
  content?.activities.find((a) => a.id === id)?.title[locale] ?? id;

// ---------- Facts snapshot ----------

interface Snapshot {
  range: { from: string; to: string };
  facts: SummaryFact[];
  /** Free-text notes by fact, with their author (sent only with the author's consent). */
  notes: { factId: string; authorUid: string; text: string }[];
  /** Check-ins in the range with health signs (the health rule). */
  healthIds: string[];
  candidates: Activity[];
  /** `explain`: the content explained; template `next` suggestion otherwise. */
  suggestion: { contentId: string; factIds: string[] } | null;
  focus: SummarizeInput['focus'];
  /** `explain` / `moment` target, part of the cache key. */
  target: string | null;
  content: RhythmContent | null;
}

async function loadCheckIns(db: Firestore, babyId: string, from: string, to: string) {
  const snap = await db
    .collection(`babies/${babyId}/checkins`)
    .where('date', '>=', from)
    .where('date', '<=', to)
    .get();
  return snap.docs
    .map((d) => checkInSchema.safeParse(d.data()))
    .filter((p) => p.success && p.data.babyId === babyId)
    .map((p) => p.data as CheckIn);
}

async function loadFeedback(db: Firestore, babyId: string, from: string, to: string) {
  const snap = await db
    .collection(`babies/${babyId}/recFeedback`)
    .where('date', '>=', from)
    .where('date', '<=', to)
    .get();
  return snap.docs
    .map((d) => recFeedbackSchema.safeParse(d.data()))
    .filter((p) => p.success && p.data.babyId === babyId)
    .map((p) => p.data as RecFeedback);
}

const byDateThenId = (a: { date: string; id: string }, b: { date: string; id: string }) =>
  a.date.localeCompare(b.date) || a.id.localeCompare(b.id);

function checkInFact(c: CheckIn, locale: Locale): SummaryFact {
  return {
    id: c.id,
    kind: 'checkin',
    date: c.date,
    authorUid: c.authorUid,
    text: checkInLine(c, locale),
  };
}

function feedbackFact(f: RecFeedback, content: RhythmContent | null, locale: Locale): SummaryFact {
  return {
    id: f.id,
    kind: 'feedback',
    date: f.date,
    authorUid: f.authorUid,
    text: `${activityTitle(content, f.contentId, locale)} · ${pick(feedbackLabel[f.kind], locale)}`,
  };
}

function milestoneFact(
  m: { id: string; name: string; date: string; createdBy: string | null },
  locale: Locale,
): SummaryFact {
  return {
    id: m.id,
    kind: 'milestone',
    date: m.date,
    authorUid: m.createdBy,
    text: locale === 'vi' ? `Mốc mới: ${m.name}` : `New milestone: ${m.name}`,
  };
}

async function findMilestone(db: Firestore, babyId: string, id: string) {
  if (/^ms_[a-f0-9]{32}$/.test(id)) {
    const d = await db.doc(`babies/${babyId}/milestones/${id}`).get();
    if (!d.exists) return null;
    return {
      id,
      name: String(d.get('name') ?? ''),
      date: String(d.get('date') ?? ''),
      createdBy: (d.get('createdBy') as string | undefined) ?? null,
    };
  }
  if (!/^p_[a-z0-9_]{2,40}$/.test(id)) return null;
  // An age preset has no document: the first item tagged with it carries its name and date.
  const tagged = await db
    .collection(`babies/${babyId}/media`)
    .where('milestone.id', '==', id)
    .limit(1)
    .get();
  const d = tagged.docs[0];
  if (!d || d.get('deleted') === true) return null;
  return {
    id,
    name: String(d.get('milestone.name') ?? ''),
    date: String(d.get('milestone.date') ?? ''),
    createdBy: (d.get('createdBy') as string | undefined) ?? null,
  };
}

function eligibleCandidates(
  content: RhythmContent | null,
  locale: Locale,
  ageDays: number | null,
  country: string | null,
  needs: ReadonlySet<Need>,
): Activity[] {
  if (!content || ageDays === null) return [];
  return content.activities
    .filter(
      (a) =>
        a.status === 'published' &&
        a.locales.includes(locale) &&
        ageDays >= a.ageDays.from &&
        ageDays <= a.ageDays.to &&
        (a.regions.length === 0 || (country !== null && a.regions.includes(country))),
    )
    .map((a) => ({ a, match: a.needs.some((n) => needs.has(n)) ? 0 : 1 }))
    .sort((x, y) => x.match - y.match || x.a.id.localeCompare(y.a.id))
    .slice(0, aiSummaryLimits.maxCandidates)
    .map((x) => x.a);
}

async function buildSnapshot(
  db: Firestore,
  ctx: EntitlementContext,
  req: {
    babyId: string;
    kind: AiSummaryKind;
    locale: Locale;
    recommendationId?: string | undefined;
    milestoneId?: string | undefined;
  },
  now: Date,
): Promise<Snapshot> {
  const { babyId, locale } = req;
  const [baby, profile, content] = await Promise.all([
    db.doc(`babies/${babyId}`).get(),
    db.doc(`babies/${babyId}/restricted/profile`).get(),
    readRhythmContent(db),
  ]);
  if ((baby.get('state') ?? 'active') !== 'active') {
    throw new AiSummaryError('failed-precondition', 'deleting');
  }
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;
  const to = localDateIn(zone, now);
  const from = addDaysIso(to, -(aiSummaryLimits.rangeDays - 1));
  // The date of birth only gives the age for eligible activities; it never leaves the server.
  const dob = (profile.get('dateOfBirth') as string | undefined)?.slice(0, 10) ?? null;
  const ageDays = dob && dob <= to ? daysBetweenIso(dob, to) : null;

  const rangeCheckIns = (await loadCheckIns(db, babyId, from, to)).sort(byDateThenId);
  const healthIds = rangeCheckIns.filter((c) => needsHealthSupport(c)).map((c) => c.id);
  const notes: Snapshot['notes'] = [];
  const noteOf = (id: string, authorUid: string, note: string | null) => {
    const text = note?.trim();
    if (text) notes.push({ factId: id, authorUid, text: text.slice(0, 500) });
  };

  if (req.kind === 'explain') {
    if (!req.recommendationId) throw new AiSummaryError('invalid-argument', 'bad-request');
    const rec = await db.doc(`babies/${babyId}/recommendations/${req.recommendationId}`).get();
    if (!rec.exists) throw new AiSummaryError('not-found', 'recommendation-not-found');
    const contentId = rec.get('contentId') as string;
    const ids = ((rec.get('supportingIds') as string[] | undefined) ?? []).slice(0, 12);
    const facts: SummaryFact[] = [];
    for (const id of ids) {
      const col = id.startsWith('ci_') ? 'checkins' : id.startsWith('fb_') ? 'recFeedback' : null;
      if (!col) continue;
      const d = await db.doc(`babies/${babyId}/${col}/${id}`).get();
      if (!d.exists) continue;
      if (col === 'checkins') {
        const p = checkInSchema.safeParse(d.data());
        if (!p.success || p.data.babyId !== babyId) continue;
        facts.push(checkInFact(p.data, locale));
        noteOf(p.data.id, p.data.authorUid, p.data.note);
      } else {
        const p = recFeedbackSchema.safeParse(d.data());
        if (!p.success || p.data.babyId !== babyId) continue;
        facts.push(feedbackFact(p.data, content, locale));
        noteOf(p.data.id, p.data.authorUid, p.data.note);
      }
    }
    const activity = content?.activities.find((a) => a.id === contentId);
    return {
      range: { from, to },
      facts,
      notes,
      healthIds,
      candidates: activity ? [activity] : [],
      suggestion: activity ? { contentId, factIds: facts.map((f) => f.id) } : null,
      focus: { contentId },
      target: req.recommendationId,
      content,
    };
  }

  if (req.kind === 'moment') {
    if (!req.milestoneId) throw new AiSummaryError('invalid-argument', 'bad-request');
    const m = await findMilestone(db, babyId, req.milestoneId);
    if (!m || !m.name || !/^\d{4}-\d{2}-\d{2}$/.test(m.date)) {
      throw new AiSummaryError('not-found', 'milestone-not-found');
    }
    const fact = milestoneFact(m, locale);
    return {
      range: { from, to },
      facts: [fact],
      notes,
      healthIds,
      candidates: [],
      suggestion: null,
      focus: { factId: fact.id },
      target: req.milestoneId,
      content,
    };
  }

  // handover (SU01): check-ins, feedback, milestones in the range, sleep when the data is valid.
  const [feedback, milestones] = await Promise.all([
    loadFeedback(db, babyId, from, to),
    db
      .collection(`babies/${babyId}/milestones`)
      .where('date', '>=', from)
      .where('date', '<=', to)
      .get(),
  ]);
  const facts: SummaryFact[] = [];
  for (const c of rangeCheckIns) {
    facts.push(checkInFact(c, locale));
    noteOf(c.id, c.authorUid, c.note);
  }
  for (const f of feedback.sort(byDateThenId)) {
    facts.push(feedbackFact(f, content, locale));
    noteOf(f.id, f.authorUid, f.note);
  }
  for (const d of milestones.docs) {
    const name = d.get('name');
    const date = d.get('date');
    if (typeof name !== 'string' || typeof date !== 'string' || !d.id.startsWith('ms_')) continue;
    facts.push(
      milestoneFact(
        { id: d.id, name, date, createdBy: (d.get('createdBy') as string) ?? null },
        locale,
      ),
    );
  }
  if (checkCapability(ctx, 'rhythm.advanced', now, 'history.read').allowed) {
    const rules = await readRhythmRules(db);
    const sleep = await sleepFacts(db, babyId, zone, to, now, rules);
    if (sleep.status !== 'insufficient_data' && sleep.baseline !== null && sleep.recent !== null) {
      facts.push({
        id: 'sleep',
        kind: 'sleep',
        date: to,
        authorUid: null,
        text:
          locale === 'vi'
            ? `Giấc ngủ những ngày gần đây: khoảng ${hm(sleep.recent, 'vi')} mỗi ngày; trước đó khoảng ${hm(sleep.baseline, 'vi')} (${sleep.status === 'change_detected' ? 'có thay đổi' : 'không đổi nhiều'})`
            : `Recent sleep: about ${hm(sleep.recent, 'en')} a day; before that about ${hm(sleep.baseline, 'en')} (${sleep.status === 'change_detected' ? 'a change' : 'little change'})`,
      });
    }
  }
  // Newest facts win when there are too many.
  const kept = facts.slice(-aiSummaryLimits.maxFacts);
  const keptIds = new Set(kept.map((f) => f.id));
  const needs = new Set(
    rangeCheckIns.map((c) => needOf(c.observation)).filter((n): n is Need => n !== null),
  );
  const candidates = eligibleCandidates(content, locale, ageDays, ctx.family.country, needs);
  // The template's "next": the household's current suggestion, when it is still a candidate.
  const current = await db
    .collection(`babies/${babyId}/recommendations`)
    .orderBy('generatedAt', 'desc')
    .limit(5)
    .get();
  const rec = current.docs.find((d) =>
    ['suggested', 'started', 'done'].includes(d.get('state') as string),
  );
  const recContent = rec?.get('contentId') as string | undefined;
  return {
    range: { from, to },
    facts: kept,
    notes: notes.filter((n) => keptIds.has(n.factId)),
    healthIds,
    candidates,
    suggestion:
      recContent && candidates.some((a) => a.id === recContent)
        ? {
            contentId: recContent,
            factIds: ((rec!.get('supportingIds') as string[]) ?? []).filter((i) => keptIds.has(i)),
          }
        : null,
    focus: {},
    target: null,
    content,
  };
}

// ---------- Template (free, deterministic, NL10b) ----------

type Section = SummaryAnswer['sections'][number];
const cut = (s: string) => (s.length > 600 ? `${s.slice(0, 599)}…` : s);

/** Newest first, "YYYY-MM-DD: line" (the app renders dates; the template stays plain). */
function lines(facts: readonly SummaryFact[], max = 4): string {
  return facts
    .slice(-max)
    .reverse()
    .map((f) => `${f.date}: ${f.text}`)
    .join('; ');
}

export function templateSummary(
  kind: AiSummaryKind | 'health',
  locale: Locale,
  snap: Pick<Snapshot, 'facts' | 'healthIds' | 'suggestion' | 'content'>,
): { sections: Section[]; suggestionContentId: string | null } {
  const vi = locale === 'vi';
  const facts = snap.facts;
  const of = (k: SummaryFact['kind']) => facts.filter((f) => f.kind === k);
  if (kind === 'health') {
    return {
      sections: [
        {
          kind: 'note',
          text: vi
            ? 'Những ngày này có ghi nhận dấu hiệu sức khoẻ cần chú ý. Hãy mở phần Hỗ trợ sức khoẻ và hỏi bác sĩ của bé; tóm tắt sẽ không thay cho lời khuyên y tế.'
            : 'Health signs were noted in these days. Open Health support and check with the baby’s doctor; a summary never replaces medical advice.',
          factIds: snap.healthIds.slice(0, 12),
        },
      ],
      suggestionContentId: null,
    };
  }
  const suggestionTitle = snap.suggestion
    ? activityTitle(snap.content, snap.suggestion.contentId, locale)
    : null;
  if (kind === 'moment') {
    const m = of('milestone');
    return {
      sections: [
        { kind: 'noticed', text: cut(lines(m, 1)), factIds: m.map((f) => f.id) },
        {
          kind: 'next',
          text: vi
            ? 'Bạn có thể lưu khoảnh khắc này vào Kỷ niệm.'
            : 'You may want to keep this moment in Moments.',
          factIds: m.map((f) => f.id),
        },
      ],
      suggestionContentId: null,
    };
  }
  if (kind === 'explain') {
    const sections: Section[] = [
      {
        kind: 'noticed',
        text: facts.length
          ? cut(lines(facts))
          : vi
            ? 'Gợi ý này dựa trên lần ghi nhận gần đây của gia đình.'
            : 'This suggestion comes from the family’s recent check-in.',
        factIds: facts.map((f) => f.id).slice(0, 12),
      },
    ];
    if (snap.suggestion && suggestionTitle) {
      const a = snap.content?.activities.find((x) => x.id === snap.suggestion!.contentId);
      sections.push({
        kind: 'next',
        text: cut(`${suggestionTitle}${a ? ` — ${a.summary[locale]}` : ''}`),
        factIds: snap.suggestion.factIds.slice(0, 12),
      });
    }
    return { sections, suggestionContentId: snap.suggestion?.contentId ?? null };
  }
  const checkins = of('checkin');
  const helped = of('feedback');
  const sections: Section[] = [
    {
      kind: 'noticed',
      text: checkins.length
        ? cut(lines(checkins))
        : vi
          ? 'Chưa có ghi nhận nào trong những ngày qua.'
          : 'Nothing was noted in the last few days.',
      factIds: checkins.slice(-4).map((f) => f.id),
    },
    {
      kind: 'helped',
      text: helped.length
        ? cut(lines(helped))
        : vi
          ? 'Chưa có phản hồi về gợi ý nào.'
          : 'No feedback on suggestions yet.',
      factIds: helped.slice(-4).map((f) => f.id),
    },
    {
      kind: 'next',
      text: suggestionTitle
        ? vi
          ? `Gợi ý đang dùng: ${suggestionTitle}.`
          : `Current suggestion: ${suggestionTitle}.`
        : vi
          ? 'Ghi lại thêm vài ngày để có gợi ý phù hợp hơn.'
          : 'Keep noting a few more days for a better suggestion.',
      factIds: snap.suggestion?.factIds.slice(0, 12) ?? [],
    },
  ];
  const sleep = of('sleep');
  if (sleep.length) sections.push({ kind: 'note', text: cut(sleep[0]!.text), factIds: ['sleep'] });
  return { sections, suggestionContentId: snap.suggestion?.contentId ?? null };
}

// ---------- Stored snapshots ----------

const summaryRef = (db: Firestore, babyId: string, id: string) =>
  db.doc(`babies/${babyId}/summaries/${id}`);

async function currentDataVersion(db: Firestore, babyId: string): Promise<number> {
  return ((await db.doc(`babies/${babyId}/facts/state`).get()).get('dataVersion') as number) ?? 0;
}

function viewOf(d: DocumentSnapshot, dataVersion: number): SummaryView {
  const x = d.data()!;
  return {
    id: x.id,
    kind: x.kind,
    method: x.method,
    fallbackReason: x.fallbackReason ?? null,
    sections: x.sections ?? [],
    facts: x.facts ?? [],
    suggestionContentId: x.suggestionContentId ?? null,
    range: x.range,
    authorUids: x.authorUids ?? [],
    language: x.language,
    generatedAt: x.generatedAt,
    dataVersion: x.dataVersion ?? 0,
    quota: x.quota ?? null,
    requestedBy: x.requestedBy,
    stale: (x.dataVersion ?? 0) < dataVersion,
  };
}

interface Draft {
  id: string;
  babyId: string;
  familyId: string;
  uid: string;
  requestId: string;
  kind: AiSummaryKind;
  locale: Locale;
  target: string | null;
  snap: Snapshot;
  dataVersion: number;
  template: { sections: Section[]; suggestionContentId: string | null };
}

function storedDoc(
  d: Draft,
  now: Date,
  out: {
    method: SummaryAnswer['method'];
    fallbackReason: SummaryFallbackReason | null;
    sections: Section[];
    suggestionContentId: string | null;
    facts?: SummaryFact[];
    quota: SummaryAnswer['quota'];
    cacheKey?: string | null;
    cachedFrom?: string | null;
    modelVersion?: string | null;
    noteAuthorUids?: string[];
    aiTextOwners?: string[];
  },
) {
  const facts = out.facts ?? d.snap.facts;
  const authorUids = [...new Set(facts.map((f) => f.authorUid).filter((u): u is string => !!u))];
  return {
    id: d.id,
    babyId: d.babyId,
    familyId: d.familyId,
    kind: d.kind,
    method: out.method,
    fallbackReason: out.fallbackReason,
    sections: out.sections,
    facts,
    suggestionContentId: out.suggestionContentId,
    range: d.snap.range,
    authorUids,
    language: d.locale,
    generatedAt: now.toISOString(),
    dataVersion: d.dataVersion,
    quota: out.quota,
    requestId: d.requestId,
    requestedBy: d.uid,
    target: d.target,
    cacheKey: out.cacheKey ?? null,
    cachedFrom: out.cachedFrom ?? null,
    modelVersion: out.modelVersion ?? null,
    promptVersion: aiSummaryPromptVersion,
    consentVersion: aiConsentVersion,
    contentVersion: d.snap.content?.version ?? null,
    /** Template kept so withdrawing consent can drop the AI text (brief p.14). */
    fallbackSections: d.template.sections,
    fallbackSuggestionContentId: d.template.suggestionContentId,
    /** People whose consent the AI text rests on: the requester and whose notes were sent. */
    aiTextOwners: out.aiTextOwners ?? [],
    noteAuthorUids: out.noteAuthorUids ?? [],
    aiTextDeleted: false,
    status: 'ready',
    createdAt: Timestamp.fromDate(now),
    updatedAt: Timestamp.fromDate(now),
  };
}

const answerFromDoc = (doc: ReturnType<typeof storedDoc>): SummaryView => ({
  id: doc.id,
  kind: doc.kind,
  method: doc.method,
  fallbackReason: doc.fallbackReason,
  sections: doc.sections,
  facts: doc.facts,
  suggestionContentId: doc.suggestionContentId,
  range: doc.range,
  authorUids: doc.authorUids,
  language: doc.language,
  generatedAt: doc.generatedAt,
  dataVersion: doc.dataVersion,
  quota: doc.quota,
  requestedBy: doc.requestedBy,
  stale: false,
});

async function count(db: Firestore, now: Date, answer: SummaryView) {
  try {
    await countAppEvent(db, now, 'summaryGenerated', answer.method);
    if (answer.fallbackReason)
      await countAppEvent(db, now, 'summaryFallback', answer.fallbackReason);
  } catch {
    // Counters never fail the answer.
  }
}

/** Writes a template answer unless the request already has a stored one (idempotent). */
async function storeFallback(
  db: Firestore,
  d: Draft,
  now: Date,
  reason: SummaryFallbackReason,
  quota: SummaryAnswer['quota'] = null,
  template = d.template,
): Promise<SummaryView> {
  const ref = summaryRef(db, d.babyId, d.id);
  const doc = storedDoc(d, now, {
    method: 'fallback',
    fallbackReason: reason,
    sections: template.sections,
    suggestionContentId: template.suggestionContentId,
    quota,
  });
  const out = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (s.exists && s.get('status') !== 'pending') return viewOf(s, d.dataVersion);
    tx.set(ref, doc);
    return answerFromDoc(doc);
  });
  return out;
}

type ProviderResult = { kind: 'ok'; raw: unknown } | { kind: 'timeout' } | { kind: 'unavailable' };

async function callProvider(
  provider: AiProvider,
  input: SummarizeInput,
  timeoutMs: number,
): Promise<ProviderResult> {
  if (!provider.summarize) return { kind: 'unavailable' };
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<ProviderResult>((resolve) => {
    timer = setTimeout(() => resolve({ kind: 'timeout' }), timeoutMs);
  });
  try {
    return await Promise.race([
      provider.summarize(input).then(
        (raw): ProviderResult => (raw == null ? { kind: 'unavailable' } : { kind: 'ok', raw }),
        (): ProviderResult => ({ kind: 'unavailable' }),
      ),
      timeout,
    ]);
  } finally {
    clearTimeout(timer);
  }
}

/** Output checks (A04–A08 + claims): `null` when the model's answer may be shown. */
export function outputProblem(
  raw: unknown,
  x: { locale: Locale; factIds: readonly string[]; candidateIds: readonly string[] },
): { output: AiOutput } | { problem: 'invalid' } {
  const parsed = aiOutputSchema.safeParse(raw);
  const gate = aiGate({
    entitled: true,
    consent: true,
    healthFlag: false,
    cached: false,
    schemaValid: parsed.success,
    timeout: false,
    locale: x.locale,
    outputLocale: parsed.success ? parsed.data.language : '',
    allowedFacts: x.factIds,
    outputFactIds: parsed.success ? parsed.data.sections.flatMap((s) => s.factIds) : [],
    allowedContent: x.candidateIds,
    suggestionId: parsed.success ? parsed.data.suggestionContentId : null,
  });
  if (gate !== 'AI_VALID' || !parsed.success) return { problem: 'invalid' };
  if (claimProblems(parsed.data).length > 0) return { problem: 'invalid' };
  // Grounded: every section rests on at least one fact of the snapshot.
  if (parsed.data.sections.some((s) => s.factIds.length === 0)) return { problem: 'invalid' };
  return { output: parsed.data };
}

function aiQuotaWindows(
  ctx: EntitlementContext,
  babyId: string,
  zone: string,
): QuotaWindowRequest[] {
  return [
    {
      window: { kind: 'day', feature: 'ai_day', babyId, zone },
      limit: ctx.config.quotas.ai.perBabyPerDay,
    },
    {
      window: { kind: 'calendar_month', feature: 'ai_month', zone },
      limit: ctx.config.quotas.ai.perFamilyPerMonth,
    },
  ];
}

const quotaPair = (w: StoredQuotaWindow[]): SummaryAnswer['quota'] =>
  w.length === 2 ? { day: quotaSnapshot(w[0]!), month: quotaSnapshot(w[1]!) } : null;

// ---------- generateSummary ----------

export async function generateSummary(
  deps: SummaryDeps,
  uid: string,
  data: unknown,
): Promise<SummaryView> {
  const { db, provider, now } = deps;
  const req = parseOr(generateSummaryRequestSchema, data);
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, deps.environment);
  // Generation is Cùng nuôi only (D-072 #2); everyone with history.read reads stored summaries.
  if (!ctx.member) throw gateError('NOT_MEMBER');
  if (!familyCan(ctx.member, 'ai.generate')) throw gateError('ROLE_DENIED');

  const id = summaryIdFor(uid, req.babyId, req.requestId);
  const ref = summaryRef(db, req.babyId, id);
  const dataVersion = await currentDataVersion(db, req.babyId);
  const existing = await ref.get();
  if (existing.exists && existing.get('status') !== 'pending') {
    return viewOf(existing, dataVersion);
  }

  const snap = await buildSnapshot(db, ctx, req, now);
  const draft: Draft = {
    id,
    babyId: req.babyId,
    familyId: ctx.familyId,
    uid,
    requestId: req.requestId,
    kind: req.kind,
    locale: req.locale,
    target: snap.target,
    snap,
    dataVersion,
    template: templateSummary(req.kind, req.locale, snap),
  };
  const finish = async (view: SummaryView) => {
    await count(db, now, view);
    return view;
  };

  // A01: health signs in the range → no model at all; point to health support (free).
  if (snap.healthIds.length > 0) {
    const health = templateSummary('health', req.locale, snap);
    return finish(await storeFallback(db, draft, now, 'HEALTH_FLOW', null, health));
  }

  // A02/A03: entitlement (incl. the ai_assist kill switch and region) then the caller's consent.
  const entitled = checkCapability(ctx, 'ai.assistance', now, 'ai.generate');
  if (!entitled.allowed) {
    return finish(await storeFallback(db, draft, now, entitled.reason));
  }
  const callerConsent = consentOf(await consentRef(db, uid).get());
  if (!callerConsent.granted) {
    return finish(await storeFallback(db, draft, now, 'CONSENT_REQUIRED'));
  }

  // Notes go out only when their own author allows it (P-151), as data.
  const noteAuthors = [...new Set(snap.notes.map((n) => n.authorUid))];
  const shares = new Map<string, boolean>();
  await Promise.all(
    noteAuthors.map(async (a) =>
      shares.set(a, consentOf(await consentRef(db, a).get()).shareMyNotes),
    ),
  );
  const notes = snap.notes.filter((n) => shares.get(n.authorUid) === true);
  const noteAuthorUids = [...new Set(notes.map((n) => n.authorUid))];

  const model = `${provider.name}:${provider.model ?? 'none'}`;
  const cacheKey =
    aiCacheKey({
      babyId: req.babyId,
      kind: req.kind,
      dataVersion,
      contentVersion: snap.content?.version ?? 'none',
      locale: req.locale,
      promptVersion: aiSummaryPromptVersion,
      model,
      consentVersion: aiConsentVersion,
    }) + (snap.target ? `|${snap.target}` : '');

  // Claim the request id (one provider call per request id at a time).
  const claimed = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (s.exists && s.get('status') !== 'pending') return viewOf(s, dataVersion);
    const claimedAt = s.exists ? (s.get('claimedAt') as Timestamp).toMillis() : 0;
    if (s.exists && now.getTime() - claimedAt < CLAIM_STALE_MS) {
      throw new AiSummaryError('aborted', 'in-progress');
    }
    tx.set(ref, {
      id,
      babyId: req.babyId,
      familyId: ctx.familyId,
      kind: req.kind,
      requestId: req.requestId,
      requestedBy: uid,
      status: 'pending',
      claimedAt: Timestamp.fromDate(now),
    });
    return null;
  });
  if (claimed) return claimed;

  // A04: the same facts, language, prompt, model and consent policy → the cached text, no quota.
  const cached = (
    await db
      .collection(`babies/${req.babyId}/summaries`)
      .where('cacheKey', '==', cacheKey)
      .where('method', '==', 'ai')
      .limit(1)
      .get()
  ).docs[0];
  if (cached) {
    const c = cached.data();
    const doc = storedDoc(draft, now, {
      method: 'cache',
      fallbackReason: null,
      sections: c.sections,
      suggestionContentId: c.suggestionContentId ?? null,
      facts: c.facts,
      quota: null,
      cachedFrom: cached.id,
      modelVersion: c.modelVersion ?? null,
      noteAuthorUids: c.noteAuthorUids ?? [],
      aiTextOwners: [...new Set([...(c.aiTextOwners ?? []), uid])],
    });
    await ref.set(doc);
    return finish(answerFromDoc(doc));
  }

  // A09: the monthly AI budget pauses model calls; the template still answers.
  if (!provider.summarize || provider.name === 'template' || !(await aiBudgetLeft(db, now))) {
    return finish(await storeFallback(db, draft, now, 'unavailable'));
  }

  const zone = ctx.family.timeZone ?? DEFAULT_ZONE;
  const windows = aiQuotaWindows(ctx, req.babyId, zone);
  const reserved = await db.runTransaction(async (tx) => {
    const r = await reserveQuota(tx, db, {
      familyId: ctx.familyId,
      reservationId: id,
      windows,
      requestId: req.requestId,
      now,
    });
    if (r.outcome === 'denied') {
      const doc = storedDoc(draft, now, {
        method: 'fallback',
        fallbackReason: 'QUOTA_EXCEEDED',
        sections: draft.template.sections,
        suggestionContentId: draft.template.suggestionContentId,
        quota: quotaPair(r.windows),
      });
      tx.set(ref, doc);
      return { done: answerFromDoc(doc) };
    }
    return { done: null, state: r.state };
  });
  if (reserved.done) return finish(reserved.done);
  if (reserved.state !== 'reserved') {
    // Settled by an earlier run of this request: its snapshot is the answer.
    const again = await ref.get();
    if (again.exists && again.get('status') !== 'pending') return viewOf(again, dataVersion);
    throw new AiSummaryError('aborted', 'in-progress');
  }

  const factIds = snap.facts.map((f) => f.id);
  const candidateIds = snap.candidates.map((a) => a.id);
  const result = await callProvider(
    provider,
    {
      kind: req.kind,
      locale: req.locale,
      facts: snap.facts.map(({ id: fid, kind, date, text }) => ({ id: fid, kind, date, text })),
      notes: notes.map((n) => ({ factId: n.factId, text: n.text })),
      candidates: snap.candidates.map((a) => ({
        id: a.id,
        title: a.title[req.locale],
        summary: a.summary[req.locale],
      })),
      focus: snap.focus,
    },
    deps.timeoutMs ?? aiSummaryLimits.timeoutMs,
  );
  if (result.kind !== 'unavailable') {
    // The call was made (even when it timed out): it is paid for.
    try {
      await chargeAi(db, now, aiSummaryLimits.costVnd);
    } catch {
      // The budget counter never fails the answer.
    }
  }
  const checked =
    result.kind === 'ok'
      ? outputProblem(result.raw, { locale: req.locale, factIds, candidateIds })
      : null;
  const failure: SummaryFallbackReason | null =
    result.kind === 'timeout'
      ? 'timeout'
      : result.kind === 'unavailable'
        ? 'unavailable'
        : checked && 'problem' in checked
          ? 'invalid'
          : null;

  const view = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (s.exists && s.get('status') !== 'pending') return viewOf(s, dataVersion);
    // Consent may have been withdrawn while the model ran (brief p.14: queued work stops).
    const consents = await Promise.all(
      [uid, ...noteAuthorUids].map((u) => tx.get(consentRef(db, u))),
    );
    const stillAllowed =
      consentOf(consents[0]).granted && consents.slice(1).every((c) => consentOf(c).shareMyNotes);
    const reason: SummaryFallbackReason | null =
      failure ?? (stillAllowed ? null : 'CONSENT_REQUIRED');
    if (reason === null && checked && 'output' in checked) {
      const r = await commitQuota(tx, db, { familyId: ctx.familyId, reservationId: id, now });
      const doc = storedDoc(draft, now, {
        method: 'ai',
        fallbackReason: null,
        sections: checked.output.sections,
        suggestionContentId: checked.output.suggestionContentId,
        quota: quotaPair(r.windows),
        cacheKey,
        modelVersion: model,
        noteAuthorUids,
        aiTextOwners: [...new Set([uid, ...noteAuthorUids])],
      });
      tx.set(ref, doc);
      return answerFromDoc(doc);
    }
    const r = await releaseQuota(tx, db, {
      familyId: ctx.familyId,
      reservationId: id,
      reason: reason ?? 'invalid',
      now,
    });
    const doc = storedDoc(draft, now, {
      method: 'fallback',
      fallbackReason: reason ?? 'invalid',
      sections: draft.template.sections,
      suggestionContentId: draft.template.suggestionContentId,
      quota: quotaPair(r.windows),
    });
    tx.set(ref, doc);
    return answerFromDoc(doc);
  });
  return finish(view);
}

// ---------- Reading, reporting ----------

/**
 * SU01 history: the newest stored summaries for `history.read` roles (Cùng nuôi, Người chăm sóc,
 * relatives with Chăm sóc hằng ngày). A summary older than the facts is marked `stale` here and
 * never regenerated by itself. `moment` summaries stay with Cùng nuôi (milestones are theirs).
 */
export async function listSummaries(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<{ summaries: SummaryView[]; quota: SummaryAnswer['quota'] }> {
  const req = parseOr(listSummariesRequestSchema, data);
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, environment);
  if (!ctx.member) throw gateError('NOT_MEMBER');
  if (!familyCan(ctx.member, 'history.read')) throw gateError('ROLE_DENIED');
  const parent = ctx.member.role === 'coParent';
  const dataVersion = await currentDataVersion(db, req.babyId);
  const snap = await db
    .collection(`babies/${req.babyId}/summaries`)
    .orderBy('generatedAt', 'desc')
    .limit(50)
    .get();
  const docs = snap.docs
    .filter((d) => d.get('status') !== 'pending')
    .filter((d) => (req.kind ? d.get('kind') === req.kind : true))
    .filter((d) => parent || d.get('kind') !== 'moment')
    .slice(0, req.limit);
  const batch = db.batch();
  let marks = 0;
  for (const d of docs) {
    if (d.get('status') === 'ready' && ((d.get('dataVersion') as number) ?? 0) < dataVersion) {
      batch.update(d.ref, { status: 'stale', updatedAt: Timestamp.fromDate(now) });
      marks++;
    }
  }
  if (marks) await batch.commit();
  // The caller's own AI quota (MO04-like line under "Tạo tóm tắt"), for those who may generate.
  let quota: SummaryAnswer['quota'] = null;
  if (familyCan(ctx.member, 'ai.generate')) {
    const zone = ctx.family.timeZone ?? DEFAULT_ZONE;
    const [day, month] = aiQuotaWindows(ctx, req.babyId, zone);
    const [d, m]: QuotaSnapshot[] = await Promise.all([
      readQuotaSnapshot(db, ctx.familyId, day!, now),
      readQuotaSnapshot(db, ctx.familyId, month!, now),
    ]);
    quota = { day: d!, month: m! };
  }
  return { summaries: docs.map((d) => viewOf(d, dataVersion)), quota };
}

/**
 * "Chưa đúng? Báo lại" (SU01): a closed problem code for staff review, one per person per
 * summary; never the summary text or any child data.
 */
export async function reportSummary(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<{ reportId: string }> {
  const req = parseOr(reportSummaryRequestSchema, data);
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, environment);
  if (!ctx.member) throw gateError('NOT_MEMBER');
  if (!familyCan(ctx.member, 'history.read')) throw gateError('ROLE_DENIED');
  const s = await summaryRef(db, req.babyId, req.summaryId).get();
  if (!s.exists || s.get('status') === 'pending') {
    throw new AiSummaryError('not-found', 'summary-not-found');
  }
  if (s.get('kind') === 'moment' && ctx.member.role !== 'coParent') {
    throw gateError('ROLE_DENIED');
  }
  const reportId = `air_${createHash('sha256').update(`${req.summaryId}|${uid}`).digest('hex').slice(0, 32)}`;
  await db.doc(`aiReports/${reportId}`).set({
    id: reportId,
    babyId: req.babyId,
    familyId: ctx.familyId,
    summaryId: req.summaryId,
    reporterUid: uid,
    problem: req.problem,
    kind: s.get('kind'),
    method: s.get('method'),
    fallbackReason: s.get('fallbackReason') ?? null,
    modelVersion: s.get('modelVersion') ?? null,
    promptVersion: s.get('promptVersion') ?? null,
    language: s.get('language') ?? null,
    status: 'open',
    createdAt: Timestamp.fromDate(now),
  });
  return { reportId };
}

// ---------- Consent ----------

/** Drops the AI text of summaries resting on [uid]'s consent; the template stays (brief p.14). */
async function clearAiText(
  db: Firestore,
  uid: string,
  field: 'aiTextOwners' | 'noteAuthorUids',
  now: Date,
): Promise<number> {
  let cleared = 0;
  for (;;) {
    const snap = await db
      .collectionGroup('summaries')
      .where(field, 'array-contains', uid)
      .limit(200)
      .get();
    if (snap.empty) return cleared;
    const batch = db.batch();
    for (const d of snap.docs) {
      batch.update(d.ref, {
        method: 'fallback',
        fallbackReason: 'CONSENT_REQUIRED',
        sections: d.get('fallbackSections') ?? [],
        suggestionContentId: d.get('fallbackSuggestionContentId') ?? null,
        cacheKey: null,
        aiTextOwners: [],
        noteAuthorUids: [],
        aiTextDeleted: true,
        updatedAt: Timestamp.fromDate(now),
      });
      cleared++;
    }
    await batch.commit();
    if (snap.size < 200) return cleared;
  }
}

/**
 * `setAiConsent` (NL10 privacy, A1): per person, versioned. Withdrawing (null) clears the AI text
 * of every summary resting on this person's consent and stops work in flight (re-checked before
 * any AI text is stored); turning `shareMyNotes` off clears the summaries their notes went into.
 */
export async function setAiConsent(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<AiConsent & { cleared: number }> {
  const req = parseOr(setAiConsentRequestSchema, data);
  if (req.consent && req.consent.version !== aiConsentVersion) {
    throw new AiSummaryError('invalid-argument', 'consent-version');
  }
  const ref = consentRef(db, uid);
  await db.runTransaction(async (tx) => {
    const before = await tx.get(ref);
    const prev = before.get('consent') as { version?: string; grantedAt?: unknown } | null;
    const at = Timestamp.fromDate(now);
    tx.set(ref, {
      consent: req.consent
        ? {
            version: req.consent.version,
            // Changing "share my notes" keeps when consent was first given for this version.
            grantedAt:
              prev?.version === req.consent.version && prev.grantedAt ? prev.grantedAt : at,
            shareMyNotes: req.consent.shareMyNotes,
          }
        : null,
      updatedAt: at,
    });
  });
  let cleared = 0;
  if (!req.consent) cleared = await clearAiText(db, uid, 'aiTextOwners', now);
  else if (!req.consent.shareMyNotes) cleared = await clearAiText(db, uid, 'noteAuthorUids', now);
  return { ...consentView(await ref.get()), cleared };
}

/** Exposed for tests: the summary id a request id maps to. */
export const _summaryIdForTest = summaryIdFor;
