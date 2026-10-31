/**
 * Lumi end-to-end conversation simulator (docs/assistant/test-plan.md §3a). Drives the REAL
 * callables and worker (`quoteTask` → `startTask` → `runAssistantTask` → `submitClarification` /
 * `patchDraft` / `confirmDrafts` → `getAssistantTask`) against the Firestore emulator, per case,
 * with either the deterministic fake model (scripted replies, CI) or the real OpenAI gateway
 * (live, owner-approved, metered). Synthetic data only; message text is never logged.
 */
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  draftKinds,
  isTimedEventKind,
  milestoneSeedSchema,
  publishedFromSeed,
  type AssistantPart,
  type AssistantTaskSnapshot,
  type ConfirmItemResult,
  type DraftPayload,
} from '@child-life/contracts';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { initializeApp, type App } from 'firebase-admin/app';
import {
  cancelTask,
  confirmDrafts,
  getAssistantTask,
  patchDraft,
  quoteTask,
  setAssistantConsent,
  startTask,
  submitClarification,
  type AssistantDeps,
} from '../../functions/src/assistant.js';
import {
  createAttachmentUpload,
  memoryAttachmentStore,
} from '../../functions/src/assistant-attachments.js';
import {
  fakeModelGateway,
  intentFieldNames,
  intentKindFields,
  ModelUnavailable,
  openAiModelGateway,
  type FakeStep,
  type ModelGateway,
} from '../../functions/src/assistant-model.js';
import { localClock, localInstant } from '../../functions/src/assistant-tools.js';
import { runAssistantTask } from '../../functions/src/assistant-worker.js';
import type { Answer, Case, FakeModel, FakeUnderstanding, Turn, Who } from './types.js';

export const ROOT = resolve(import.meta.dirname, '../../..');
export const ZONE = 'Asia/Ho_Chi_Minh';
export const DAY = '2026-10-15';
export const F = 'f_e2e_household';
/** The app fixtures' baby (`teddyId`) so exported snapshots replay as they are. */
export const B = 'b_00000000000000000001';
export const SHARED = `cv_${B}`;
export const WIN = 'assistant_cal_2026-10';
/** The app fixtures' members (family_fixtures.dart) plus a relative with daily care. */
export const UID: Record<Who, string> = {
  MOM: 'u_mai',
  DAD: 'u_minh',
  NANNY: 'u_lan',
  AUNT: 'u_thu',
  GRANDMA: 'u_hoa',
  NANNY_SPEND: 'u_lan2',
};
export const WHO_OF: Record<string, Who> = Object.fromEntries(
  Object.entries(UID).map(([k, v]) => [v, k as Who]),
);
const ROLE: Record<Who, { role: string; relation: string; name: string; extra?: object }> = {
  MOM: { role: 'coParent', relation: 'mother', name: 'Mai', extra: { isOwner: true } },
  DAD: { role: 'coParent', relation: 'father', name: 'Minh' },
  NANNY: { role: 'caregiver', relation: 'nanny', name: 'Cô Lan' },
  NANNY_SPEND: {
    role: 'caregiver',
    relation: 'nanny',
    name: 'Cô Hằng',
    extra: { extraRights: { recordSpending: true } },
  },
  AUNT: {
    role: 'relative',
    relation: 'relative',
    name: 'Dì Thu',
    extra: { extraRights: { viewBabyInfo: false, viewDailyCare: true } },
  },
  GRANDMA: {
    role: 'relative',
    relation: 'grandmother',
    name: 'Bà nội Hoa',
    extra: { extraRights: { viewBabyInfo: true } },
  },
};
export const sharedRole = (w: Who) => ROLE[w].role === 'coParent' || ROLE[w].role === 'caregiver';

export const controls = JSON.parse(
  readFileSync(
    resolve(ROOT, 'apps/mobile/test/features/assistant_replay/field_controls.json'),
    'utf8',
  ),
) as {
  kinds: Record<
    string,
    { editor: boolean; fields: Record<string, { control: string; words: string[] }> }
  >;
};

// ---------- Time helpers ----------

const addDays = (date: string, n: number) =>
  new Date(Date.parse(`${date}T00:00:00Z`) + n * 86_400_000).toISOString().slice(0, 10);
/** "D-1 22:00" | "14:20" (D0) → instant. */
export const localAt = (spec: string) => {
  const m = /^(?:D(-?\d+) )?(\d\d:\d\d)$/.exec(spec);
  if (!m) throw new Error(`bad time spec ${spec}`);
  return localInstant(ZONE, addDays(DAY, Number(m[1] ?? 0)), m[2]!);
};
/** An instant → "D0 08:00". */
export const describeLocal = (iso: string | null | undefined) => {
  if (!iso) return null;
  const at = new Date(iso);
  const date = new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(at);
  const diff = Math.round(
    (Date.parse(`${date}T00:00:00Z`) - Date.parse(`${DAY}T00:00:00Z`)) / 86_400_000,
  );
  return `D${diff} ${localClock(ZONE, at)}`;
};
export const dateSpec = (spec: string) =>
  /^D-?\d+$/.test(spec) ? addDays(DAY, Number(spec.slice(1))) : spec;

// ---------- Gateways ----------

const F0 = {
  amountMl: null,
  milk: null,
  time: null,
  dayOffset: null,
  endTime: null,
  endDayOffset: null,
  durationMin: null,
  side: null,
  observation: null,
  when: null,
  note: null,
  title: null,
  amount: null,
  currency: null,
  categoryId: null,
  merchant: null,
  date: null,
  assigneeText: null,
  // v5 (Lumi fixes 2026-10-16).
  diaper: null,
  weightKg: null,
  lengthCm: null,
  headCm: null,
};

const known = new Set<string>(intentFieldNames);

/** "diaper|meal": the first kind the contracts know (future kinds fall back to today's). */
export const pickKind = (k: string) =>
  k.split('|').find((x) => (draftKinds as readonly string[]).includes(x)) ?? k.split('|').at(-1)!;

/** L9: "ago 5" / "clock 11:20" / "clock 22:00 -1" / "unknown" → a v9 time spec. */
function timeSpecOf(s: string | undefined) {
  if (s === undefined) return null;
  const [how, a, b] = s.split(/\s+/);
  if (how === 'ago') return { how, minutes: Number(a ?? 0), hhmm: null, dayOffset: null };
  if (how === 'clock') return { how, minutes: null, hhmm: a ?? null, dayOffset: Number(b ?? 0) };
  return { how: 'unknown', minutes: null, hhmm: null, dayOffset: null };
}

/** L9: a scripted understanding in the v9 output shape (the server's strict schema). */
export function understandingOf(u: FakeUnderstanding): Record<string, unknown> {
  return {
    act: u.act,
    target: u.target ?? null,
    confidence: u.conf ?? 0.9,
    events: (u.e ?? []).map((e) => {
      const kind = pickKind(e.k);
      const timed = isTimedEventKind(kind);
      return {
        kind,
        status: e.st ?? (kind === 'reminder' ? 'planned' : 'finished'),
        started: timed ? timeSpecOf(e.started) : null,
        ended: timed ? timeSpecOf(e.ended) : null,
        durationMin: timed ? (e.dur ?? null) : null,
        fields: e.f ?? {},
        evidence: Object.entries(e.ev ?? {}).map(([field, text]) => ({ field, text })),
        uncertainFields: e.unc ?? [],
      };
    }),
    reads: u.reads ?? [],
    ask: u.ask ?? null,
    care: null,
    healthSigns: [],
  };
}

export function extractionOf(m: FakeModel): FakeStep<unknown> {
  if (m.error) return new ModelUnavailable(m.error === 'timeout' ? 'timeout' : 'http', 500, null);
  if (m.raw !== undefined) return m.raw;
  if (m.u) return understandingOf(m.u);
  return {
    intents: (m.i ?? []).map((x) => {
      const kind = pickKind(x.k);
      // Only the fields the running schema knows (a reply written for a newer prompt, e.g. v4
      // `phase`, is cut down to what this code's strict schema accepts) — since v7 (2026-10-19)
      // only the kind's own fields, as the per-kind strict schema lets the model write.
      const own = new Set<string>(
        intentKindFields[kind as keyof typeof intentKindFields] ?? intentFieldNames,
      );
      const keep = (k: string) => known.has(k) && own.has(k);
      return {
        kind,
        fields: Object.fromEntries(
          Object.entries({ ...F0, ...(x.f ?? {}) }).filter(([k]) => keep(k)),
        ),
        evidence: Object.entries(x.ev ?? {})
          .filter(([field]) => keep(field))
          .map(([field, text]) => ({ field, text })),
        uncertainFields: (x.unc ?? []).filter(keep),
        missingFields: (x.miss ?? []).filter(keep),
        correctsPrevious: x.cp ?? false,
        // L7 (v8): the waiting / saved item it corrects (maybe another kind).
        ...(x.cr ? { corrects: pickKind(x.cr) } : {}),
      };
    }),
    reads: m.reads ?? [],
    clarification: m.clar ? { field: m.clar } : null,
    care: m.care
      ? { topic: m.care.topic, sleep: m.care.sleep ?? null, evidence: m.care.evidence ?? [] }
      : null,
    healthSigns: m.health ?? [],
    smallTalk: m.talk ?? false,
    outOfScope: m.oos ?? false,
  };
}

export interface LiveMeter {
  calls: number;
  refused: number;
  max: number;
  promptTokens: number;
  completionTokens: number;
  latencies: number[];
  /** `LUMI_E2E_DUMP=1`: the raw model readings, in call order (synthetic cases only). */
  raw?: unknown[];
}

/** The real gateway with a hard call budget; wording is skipped (the engine's template). */
export function liveGateway(
  apiKey: string,
  model: string,
  meter: LiveMeter,
  understandingModel?: string,
): ModelGateway {
  const metered: typeof fetch = async (input, init) => {
    if (meter.calls >= meter.max) {
      meter.refused += 1;
      throw new Error('e2e call budget reached');
    }
    meter.calls += 1;
    const t0 = Date.now();
    const res = await fetch(input, init);
    meter.latencies.push(Date.now() - t0);
    try {
      const usage = ((await res.clone().json()) as { usage?: Record<string, number> }).usage;
      meter.promptTokens += usage?.prompt_tokens ?? 0;
      meter.completionTokens += usage?.completion_tokens ?? 0;
    } catch {
      // best effort
    }
    return res;
  };
  const real = openAiModelGateway(apiKey, model, metered, understandingModel ?? model);
  return {
    name: 'openai',
    model: real.model,
    promptVersion: real.promptVersion,
    // L9: the understanding call (v9) — the worker's only path (L9c).
    understand: async (i, s) => {
      const out = await real.understand(i, s);
      // Debugging a live run: the raw readings of the synthetic cases (never real data).
      if (process.env.LUMI_E2E_DUMP) meter.raw = [...(meter.raw ?? []), out];
      return out;
    },
    word: async () => {
      throw new ModelUnavailable('script');
    },
  };
}

// ---------- World ----------

let app: App | null = null;
export let db: Firestore;
export function initDb(projectId: string) {
  app = initializeApp({ projectId }, `e2e-${randomUUID()}`);
  db = getFirestore(app);
}

const on = (key: keyof typeof defaultFlags) => ({
  ...defaultFlags[key],
  enabled: true,
  scope: 'all' as const,
});
const off = (key: keyof typeof defaultFlags) => ({ ...defaultFlags[key], enabled: false });
/**
 * The callable envelope. LUMI-05: the current app declares every kind it can show
 * (`clientDraftKinds`); `legacy` = an app from before 2026-10-16 (no declaration).
 */
export const E = (locale: string, over: Record<string, unknown>, legacy = false) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale,
  ...(legacy ? {} : { clientDraftKinds: [...draftKinds] }),
  ...over,
});
const L = (vi: string, en = vi) => ({ vi, en });

export async function seedWorld(c: Case, files: ReturnType<typeof memoryAttachmentStore>) {
  for (const col of [
    'babies',
    'families',
    'config',
    'publicConfig',
    'users',
    'assistantConversations',
    'assistantTasks',
    'assistantQuotes',
    'assistantExecutions',
    'assistantRequests',
  ]) {
    await db.recursiveDelete(db.collection(col));
  }
  files.objects.clear();
  const w = c.world ?? {};
  const flags: Record<string, unknown> = {};
  for (const k of [
    'assistant',
    'assistant_live',
    'assistant_writes',
    'assistant_care',
    'assistant_images',
    'rhythm',
  ] as const) {
    flags[k] = (w.off ?? []).includes(k) ? off(k) : on(k);
  }
  await db.doc('config/flags').set(flags);
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    quotas: {
      ...defaultEntitlementsConfig.quotas,
      assistant: { ...defaultEntitlementsConfig.quotas.assistant, free: w.quota ?? 1000 },
    },
  });
  await db.doc('publicConfig/content_rhythm').set({
    version: 'rc_e2e_01',
    publishedAt: new Date('2026-10-01T00:00:00Z').toISOString(),
    activities: [
      {
        id: 'act_e2e_wind_down',
        version: 1,
        status: 'published',
        title: L('Thư giãn trước giờ ngủ (thử nghiệm)'),
        summary: L('Nội dung thử nghiệm'),
        steps: { vi: ['Bước 1', 'Bước 2'], en: ['Step 1', 'Step 2'] },
        safety: null,
        durationMin: 10,
        ageDays: { from: 0, to: 730 },
        needs: ['sleep'],
        interests: [],
        timeOfDay: 'evening',
        locales: ['vi', 'en'],
        regions: [],
        sources: [],
        review: null,
      },
    ],
    ageCards: [],
    health: {
      signs: [{ id: 'fever_young', label: L('Sốt'), maxAgeDays: 90 }],
      whileWaiting: { vi: [], en: [] },
      disclaimer: L('TEST_ONLY'),
      regions: [],
      sources: [],
      review: null,
    },
  });
  await db
    .doc(`families/${F}`)
    .set({ ownerUid: UID.MOM, country: 'VN', timeZone: ZONE, babyIds: [B] });
  await db.doc(`babies/${B}`).set({
    familyId: F,
    timeZone: { mode: 'auto', zone: ZONE },
    state: 'active',
    nickname: 'Teddy',
  });
  if (w.dob !== null) {
    await db.doc(`babies/${B}/restricted/profile`).set({ dateOfBirth: w.dob ?? '2026-03-10' });
  }
  for (const who of Object.keys(UID) as Who[]) {
    const r = ROLE[who];
    await db.doc(`babies/${B}/members/${UID[who]}`).set({
      role: r.role,
      status: 'active',
      relation: r.relation,
      relationCustom: null,
      displayName: r.name,
      ...(r.extra ?? {}),
    });
  }
  for (const who of Object.keys(UID) as Who[]) {
    if ((w.noConsent ?? []).includes(who)) continue;
    await setAssistantConsent(
      deps(null, new Date('2026-10-01T00:00:00Z')),
      UID[who],
      E('vi', { consent: { version: assistantConsentVersion } }),
    );
  }
  for (const s of w.seed ?? []) await seedPreset(s);
}

async function seedRecord(
  id: string,
  type: string,
  at: string,
  data: Record<string, unknown>,
  end: string | null = null,
) {
  await db.doc(`babies/${B}/records/${id}`).set({
    id,
    babyId: B,
    type,
    occurredAt: Timestamp.fromDate(localAt(at)),
    endedAt: end ? Timestamp.fromDate(localAt(end)) : null,
    data,
    createdBy: UID.DAD,
    author: { name: 'Minh', relation: 'father', relationCustom: null },
    createdAt: Timestamp.fromDate(localAt('D-1 00:00')),
    clientCreatedAt: Timestamp.fromDate(localAt('D-1 00:00')),
    updatedAt: Timestamp.fromDate(localAt('D-1 00:00')),
    updatedBy: UID.DAD,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    source: 'app',
  });
}

async function seedPreset(name: string) {
  const r = (n: number) => `r_${String(n).repeat(32).slice(0, 32)}`;
  switch (name) {
    case 'bottle0800':
      return seedRecord(r(7), 'bottle', 'D0 08:00', { amountMl: 120, milk: 'formula' });
    case 'breast1400':
      return seedRecord(r(8), 'breast', 'D0 14:00', { side: 'left', durationMin: 15 });
    case 'sleepNight':
      return seedRecord(r(6), 'sleep', 'D-1 21:00', {}, 'D0 05:30');
    case 'day':
      await seedRecord(r(1), 'bottle', 'D0 07:00', { amountMl: 120, milk: 'formula' });
      await seedRecord(r(2), 'bottle', 'D0 11:00', { amountMl: 150, milk: 'formula' });
      await seedRecord(r(3), 'breast', 'D0 09:00', { side: 'left', durationMin: 15 });
      await seedRecord(r(4), 'sleep', 'D0 12:00', {}, 'D0 13:30');
      await seedRecord(r(5), 'sleep', 'D-1 13:00', {}, 'D-1 14:30');
      await seedRecord(r(6), 'sleep', 'D-1 21:00', {}, 'D0 05:30');
      await seedRecord(r(9), 'bottle', 'D-1 10:00', { amountMl: 90, milk: 'formula' });
      return;
    case 'sleepTimer1230':
    case 'breastTimerLeft': {
      const sleep = name === 'sleepTimer1230';
      const started = localAt(sleep ? 'D0 12:30' : 'D0 14:05');
      await db.doc(`babies/${B}/timers/${sleep ? 'sleep' : 'breast'}`).set({
        type: sleep ? 'sleep' : 'breast',
        babyId: B,
        sessionId: sleep ? 'a'.repeat(32) : 'b'.repeat(32),
        startedAt: Timestamp.fromDate(started),
        startedBy: UID.DAD,
        author: { name: 'Minh', relation: 'father', relationCustom: null },
        sides: sleep
          ? null
          : {
              left: { accumulatedMs: 0, runningSince: Timestamp.fromDate(started) },
              right: { accumulatedMs: 0, runningSince: null },
            },
        paused: false,
        pausedSides: [],
        updatedAt: Timestamp.fromDate(started),
        updatedBy: UID.DAD,
      });
      return;
    }
    case 'expense500k':
      await db.doc(`babies/${B}/expenses/x_${'a'.repeat(32)}`).set({
        amount: 500000,
        currency: 'VND',
        categoryId: 'c_milk',
        note: 'sữa',
        spentOn: DAY,
        payer: null,
        receiptPath: null,
        source: 'manual',
        sourceRef: null,
        createdBy: UID.MOM,
        author: { name: 'Mai', relation: 'mother', relationCustom: null },
        createdAt: Timestamp.fromDate(localAt('D0 09:00')),
        updatedAt: Timestamp.fromDate(localAt('D0 09:00')),
        updatedBy: UID.MOM,
        deleted: false,
        deletedAt: null,
        deletedBy: null,
      });
      return;
    // Lumi L5: the Ăn dặm diary is on (meals can be saved).
    case 'solidsOn':
      await db.doc(`babies/${B}/solids/settings`).set({ enabled: true, method: 'mixed' });
      return;
    // Lumi L5: 6in1 dose 1 already in Sổ tiêm chủng.
    case 'dtp1Given':
      await db.doc(`babies/${B}/vaccines/dtp_1`).set({
        babyId: B,
        vaccineId: 'dtp',
        dose: 1,
        status: 'given',
        givenOn: '2026-09-15',
        givenTime: null,
        place: 'service',
        facility: null,
        reaction: null,
        declineReason: null,
        plannedOn: null,
        photoPath: null,
        createdBy: UID.MOM,
        author: { name: 'Mai', relation: 'mother', relationCustom: null },
        createdAt: Timestamp.fromDate(localAt('D-30 09:00')),
        updatedAt: Timestamp.fromDate(localAt('D-30 09:00')),
        updatedBy: UID.MOM,
      });
      return;
    // Lumi L5 (Mốc): the reference milestones published, as the dev seed does.
    case 'milestones': {
      const seed = milestoneSeedSchema.parse(
        JSON.parse(readFileSync(resolve(ROOT, 'content/milestones/milestones.seed.json'), 'utf8')),
      );
      const at = localAt('D-30 09:00').toISOString();
      await Promise.all(
        seed.milestones.map((m) =>
          db.doc(`contentMilestones/${m.id}`).set(publishedFromSeed(m, at)),
        ),
      );
      return;
    }
    // Lumi L5 (Mốc): "Lẫy" already recorded.
    case 'rolledOver':
      await db.doc(`babies/${B}/milestones/p_rolls_over`).set({
        kind: 'reference',
        referenceId: 'rolls_over',
        status: 'observed',
        name: 'Lẫy (lật người)',
        date: '2026-09-20',
        deleted: false,
      });
      return;
    default:
      throw new Error(`unknown seed ${name}`);
  }
}

// ---------- Running a case ----------

export interface Step {
  turn: number;
  label: string;
  uid: string;
  taskId: string;
  snapshot: AssistantTaskSnapshot;
  /** Instant the step happened (the server's `now`). */
  at: string;
}

export interface ConfirmLog {
  turn: number;
  uid: string;
  taskId: string;
  requestId: string;
  items: ConfirmItemResult[];
  error: string | null;
  retried: boolean;
  /** Records counted by the app's queries right after. */
  recordsAfter: number;
}

export interface CaseRun {
  steps: Step[];
  confirms: ConfirmLog[];
  /** Refusals by a callable (reason) per turn. */
  refusals: { turn: number; op: string; reason: string }[];
  /** The task of the last message turn. */
  lastTaskId: string | null;
  lastUid: string;
  /** Server questions asked across the case (fields, in order). */
  asked: string[];
  modelCalls: number;
  /** Blocked quotes (app's view). */
  quoteBlocks: string[];
  anchor: Date;
  clock: Date;
  /** Patches (field fixes) and their results. */
  patches: {
    turn: number;
    draftId: string;
    ok: boolean;
    state: string | null;
    error: string | null;
  }[];
}

export interface RunContext {
  mode: 'fake' | 'live';
  live: ModelGateway | null;
  files: ReturnType<typeof memoryAttachmentStore>;
}

export const deps = (
  gateway: ModelGateway | null,
  now: Date,
  files?: ReturnType<typeof memoryAttachmentStore>,
): AssistantDeps => ({ db, now, environment: 'test', gateway, ...(files ? { files } : {}) });

export const reasonOf = (e: unknown) =>
  (e as { reason?: string }).reason ?? (e instanceof Error ? e.message.slice(0, 80) : 'error');

export async function snapshotOf(taskId: string, uid: string, now: Date, locale = 'vi') {
  return (await getAssistantTask(deps(null, now), uid, E(locale, { taskId, afterSequence: null })))
    .data;
}

function nextClock(run: CaseRun, at: string | undefined): Date {
  if (!at) return new Date(run.clock.getTime() + 20_000);
  if (at.startsWith('+')) return new Date(run.clock.getTime() + Number(at.slice(1)) * 60_000);
  return localAt(at);
}

const vectors = resolve(ROOT, 'packages/contracts/test/vectors/assistant-v3/images');
const image = (name: 'receipt' | 'blurry' | 'note') =>
  readFileSync(
    resolve(
      vectors,
      name === 'receipt'
        ? 'receipt.png'
        : name === 'blurry'
          ? 'receipt-blurry.png'
          : 'note-board.png',
    ),
  );

export async function runCase(c: Case, ctx: RunContext): Promise<CaseRun> {
  const anchor = localAt(c.anchor ?? '14:20');
  const run: CaseRun = {
    steps: [],
    confirms: [],
    refusals: [],
    lastTaskId: null,
    lastUid: UID[c.as ?? 'MOM'],
    asked: [],
    modelCalls: 0,
    quoteBlocks: [],
    anchor,
    clock: anchor,
    patches: [],
  };
  const locale = c.locale ?? 'vi';
  let first = true;
  for (const [ti, turn] of c.turns.entries()) {
    const label = `turn ${ti + 1}`;
    if ('say' in turn || 'photo' in turn) {
      run.clock = first ? anchor : nextClock(run, turn.at);
      if (first && turn.at) run.clock = nextClock(run, turn.at);
      first = false;
      await runMessage(c, turn, ti, label, run, ctx, locale);
    } else if ('patch' in turn) {
      await runPatch(turn.patch, ti, run, locale);
    } else if ('confirm' in turn) {
      await runConfirm(turn, ti, run, locale);
    } else if ('cancel' in turn) {
      if (!run.lastTaskId) continue;
      run.clock = new Date(run.clock.getTime() + 5_000);
      try {
        await cancelTask(deps(null, run.clock), run.lastUid, E(locale, { taskId: run.lastTaskId }));
      } catch (e) {
        run.refusals.push({ turn: ti, op: 'cancelTask', reason: reasonOf(e) });
      }
      await capture(run, ti, `${label} · after cancel`, run.lastTaskId, run.lastUid, locale);
    } else if ('withdrawConsent' in turn) {
      await setAssistantConsent(
        deps(null, run.clock),
        UID[turn.withdrawConsent],
        E(locale, { consent: null }),
      );
    }
  }
  return run;
}

async function capture(
  run: CaseRun,
  turn: number,
  label: string,
  taskId: string,
  uid: string,
  locale: string,
) {
  try {
    const snapshot = await snapshotOf(taskId, uid, run.clock, locale);
    run.steps.push({ turn, label, uid, taskId, snapshot, at: run.clock.toISOString() });
    return snapshot;
  } catch (e) {
    run.refusals.push({ turn, op: 'getAssistantTask', reason: reasonOf(e) });
    return null;
  }
}

function gatewayFor(
  ctx: RunContext,
  turn: { model?: FakeModel | FakeModel[] | null; reading?: unknown[] },
): ModelGateway & { calls?: { extract: unknown[]; readImages: unknown[] } } {
  if (ctx.mode === 'live' && ctx.live && !('reading' in turn && turn.reading)) return ctx.live;
  const models = turn.model == null ? [] : Array.isArray(turn.model) ? turn.model : [turn.model];
  return fakeModelGateway({
    extract: models.map(extractionOf),
    word: [],
    readImages: (turn.reading ?? []) as FakeStep<never>[],
  });
}

async function runMessage(
  c: Case,
  turn: Extract<Turn, { say: string }> | Extract<Turn, { photo: string }>,
  ti: number,
  label: string,
  run: CaseRun,
  ctx: RunContext,
  locale: string,
) {
  const who = turn.as ?? c.as ?? 'MOM';
  const uid = UID[who];
  run.lastUid = uid;
  const gw = gatewayFor(ctx, turn);
  // LUMI-05: a turn sent by an app from before 2026-10-16.
  const legacy = 'client' in turn && turn.client === 'legacy';
  const scope = { type: 'child' as const, babyId: B };
  const isPhoto = 'photo' in turn;
  const hint = isPhoto
    ? turn.hint === undefined
      ? 'expense'
      : turn.hint
    : (turn.intentHint ?? null);
  const conversationId =
    isPhoto ||
    !sharedRole(who) ||
    ('conversation' in turn && turn.conversation === 'none') ||
    hint === 'expense'
      ? null
      : SHARED;
  const work = async (taskId: string) => {
    await runAssistantTask(
      {
        db,
        now: run.clock,
        environment: 'test',
        gateway: gw,
        timeoutMs: ctx.mode === 'live' ? 60_000 : 2_000,
        files: ctx.files,
      },
      taskId,
    );
  };
  let taskId: string;
  // Lumi L2: the app sends text without a quote (startTask quotes inline); an older app and
  // photos still quote first.
  const quoted = isPhoto || legacy;
  const startDeps = () => ({ ...deps(gw, run.clock, ctx.files), ruleReads: c.rules !== false });
  try {
    const q = quoted
      ? await quoteTask(
          deps(gw, run.clock, ctx.files),
          uid,
          E(
            locale,
            {
              conversationId,
              scope,
              modality: isPhoto ? 'image' : 'text',
              attachmentCount: isPhoto ? 1 : 0,
              intentHint: hint,
            },
            legacy,
          ),
        )
      : null;
    if (q && !q.data.allowed) {
      run.quoteBlocks.push(q.data.reason ?? 'blocked');
      // The app still starts on USAGE_EXHAUSTED / AI_UNAVAILABLE (health is free; the rest is kept
      // as a blocked task); anything else stops in the app.
      if (q.data.reason !== 'USAGE_EXHAUSTED' && q.data.reason !== 'AI_UNAVAILABLE') {
        run.refusals.push({ turn: ti, op: 'quoteTask', reason: q.data.reason ?? 'blocked' });
        return;
      }
    }
    const attachmentIds: string[] = [];
    if (isPhoto) {
      const bytes = image(turn.photo);
      const { createHash } = await import('node:crypto');
      const up = await createAttachmentUpload(
        deps(null, run.clock, ctx.files),
        uid,
        E(locale, {
          quoteId: q!.data.quoteId,
          mime: 'image/png',
          bytes: bytes.length,
          sha256: createHash('sha256').update(bytes).digest('hex'),
          retention: turn.retention ?? 'keep_with_record',
        }),
      );
      ctx.files.put(up.data.uploadPath, bytes, 'image/png');
      attachmentIds.push(up.data.attachmentId);
    }
    const requestId = randomUUID();
    const body = E(
      locale,
      {
        clientRequestId: requestId,
        conversationId,
        scope,
        ...(q ? { quoteId: q.data.quoteId } : { intentHint: hint }),
        text: isPhoto ? null : turn.say,
        attachmentIds,
      },
      legacy,
    );
    const r = await startTask(startDeps(), uid, body);
    if (!r.taskId) {
      run.refusals.push({ turn: ti, op: 'startTask', reason: r.reasonCode ?? r.status });
      return;
    }
    taskId = r.taskId;
    if (!isPhoto && turn.replay) {
      // The same request again (a flaky network): the same task, no second charge.
      const again = await startTask(startDeps(), uid, body);
      if (again.taskId !== taskId) {
        run.refusals.push({ turn: ti, op: 'startTask.replay', reason: 'DIFFERENT_TASK' });
      }
    }
    if (r.data.task.state === 'queued') await work(taskId);
  } catch (e) {
    run.refusals.push({ turn: ti, op: 'start', reason: reasonOf(e) });
    return;
  }
  run.lastTaskId = taskId;
  let snap = await capture(run, ti, `${label} · after start`, taskId, uid, locale);
  const answers = [...(turn.answers ?? [])];
  for (let round = 0; snap && snap.task.state === 'awaiting_clarification' && round < 5; round++) {
    const cl = snap.task.clarification;
    if (!cl) break;
    run.asked.push(cl.field);
    const ai = answers.findIndex(
      (a) =>
        cl.field === a.field || cl.field.startsWith(`${a.field}.`) || cl.field.startsWith(a.field),
    );
    if (ai < 0) break;
    const a = answers.splice(ai, 1)[0]!;
    if (a.afterMin) run.clock = new Date(run.clock.getTime() + a.afterMin * 60_000);
    else run.clock = new Date(run.clock.getTime() + 15_000);
    const { choiceId, text } = answerOf(a, cl);
    try {
      await submitClarification(
        deps(gw, run.clock, ctx.files),
        uid,
        E(
          locale,
          {
            taskId,
            expectedVersion: snap.task.version,
            clarificationId: cl.id,
            choiceId,
            text,
          },
          legacy,
        ),
      );
      await work(taskId);
    } catch (e) {
      run.refusals.push({ turn: ti, op: 'submitClarification', reason: reasonOf(e) });
    }
    snap = await capture(run, ti, `${label} · after answer ${cl.field}`, taskId, uid, locale);
  }
  const calls = (gw as { calls?: { extract: unknown[]; readImages: unknown[] } }).calls;
  if (calls) run.modelCalls += calls.extract.length + calls.readImages.length;
}

function answerOf(
  a: Answer,
  cl: NonNullable<AssistantTaskSnapshot['task']['clarification']>,
): { choiceId: string | null; text: string | null } {
  if (a.member) return { choiceId: UID[a.member], text: null };
  if (typeof a.choice === 'number')
    return { choiceId: cl.choices[a.choice]?.id ?? 'missing', text: null };
  if (typeof a.choice === 'string') return { choiceId: a.choice, text: null };
  return { choiceId: null, text: a.text ?? '' };
}

/** What the app's editor sends: the edited payload and every flagged field as confirmed. */
export function fixedPayload(
  d: AssistantTaskSnapshot['drafts'][number],
  set: Record<string, unknown>,
  now: Date,
): DraftPayload {
  const p = { ...(d.payload as Record<string, unknown>) };
  const ago = (min: number) => new Date(now.getTime() - min * 60_000).toISOString();
  const flagged = new Set([...d.missingFields, ...d.uncertainFields]);
  // A person fills what is empty (sensible synthetic values), keeps what is there.
  const fill: Record<string, Record<string, unknown>> = {
    bottle: { amountMl: 100, occurredAt: ago(30), milk: 'formula' },
    breast: { occurredAt: ago(30), durationMin: 15, side: 'left' },
    sleep: { startedAt: ago(120), endedAt: ago(60), durationMin: 60 },
    expense: { totalMinor: 100000, currency: 'VND', date: DAY, categoryId: 'c_other' },
    reminder: { date: addDays(DAY, 1), title: 'việc thử' },
    observation: { date: DAY },
    timer: { at: ago(5) },
    // LUMI-01: what the app's fix rows / editors let the person fill.
    pump: { amountMl: 100, occurredAt: ago(30), side: 'both' },
    diaper: { diaper: 'wet', occurredAt: ago(10) },
    // 2026-10-16: the head circumference (optional: filled only when it is the flagged field).
    growth: { weightKg: 6.2, measuredOn: DAY, headCm: 40 },
    // Lumi L5: the meal editor's dish and time.
    meal: { title: 'cháo', occurredAt: ago(30) },
  };
  for (const [k, v] of Object.entries(fill[p.kind as string] ?? {})) {
    if (k === 'headCm' && !flagged.has(k)) continue;
    if (p[k] === null || p[k] === undefined) {
      if (flagged.has(k) || d.problems.length > 0) p[k] = v;
    } else if (
      flagged.has(k) &&
      d.problems.some((x) => x === 'INVALID_AMOUNT') &&
      (k === 'amountMl' || k === 'durationMin' || k === 'totalMinor' || k === 'headCm')
    ) {
      // An amount over the limit: the person types a sensible one.
      p[k] = v;
    }
  }
  // LUMI-11: a reminder time already gone is moved to tomorrow (the app's date row).
  if (p.kind === 'reminder' && d.problems.includes('PAST_TIME')) p.date = addDays(DAY, 1);
  if (
    p.kind === 'sleep' &&
    p.startedAt &&
    p.endedAt &&
    Date.parse(p.endedAt as string) <= Date.parse(p.startedAt as string)
  ) {
    p.endedAt = new Date(Date.parse(p.startedAt as string) + 60 * 60_000).toISOString();
  }
  for (const key of ['occurredAt', 'endedAt']) {
    if (typeof p[key] === 'string' && Date.parse(p[key] as string) > now.getTime()) p[key] = ago(5);
  }
  if (p.kind === 'sleep' && typeof p.startedAt === 'string' && typeof p.endedAt === 'string') {
    if (Date.parse(p.startedAt) >= Date.parse(p.endedAt)) p.startedAt = ago(65);
    p.durationMin = Math.round(
      (Date.parse(p.endedAt) - Date.parse(p.startedAt as string)) / 60_000,
    );
  }
  return { ...p, ...set } as DraftPayload;
}

async function runPatch(
  spec: { draft?: number; set?: Record<string, unknown>; confirm?: 'flagged' | string[] },
  ti: number,
  run: CaseRun,
  locale: string,
) {
  if (!run.lastTaskId) return;
  run.clock = new Date(run.clock.getTime() + 20_000);
  const snap = await snapshotOf(run.lastTaskId, run.lastUid, run.clock, locale);
  const d = snap.drafts[spec.draft ?? 0];
  if (!d) {
    run.refusals.push({ turn: ti, op: 'patchDraft', reason: 'NO_DRAFT' });
    return;
  }
  const confirmed =
    spec.confirm === 'flagged' || spec.confirm === undefined
      ? [...new Set([...d.missingFields, ...d.uncertainFields])]
      : spec.confirm;
  const r = await applyPatch(d, fixedPayload(d, spec.set ?? {}, run.clock), confirmed, run, locale);
  run.patches.push({ turn: ti, draftId: d.id, ...r });
  await capture(run, ti, `turn ${ti + 1} · after edit`, run.lastTaskId, run.lastUid, locale);
}

export async function applyPatch(
  d: AssistantTaskSnapshot['drafts'][number],
  payload: DraftPayload,
  confirmedFields: string[],
  run: CaseRun,
  locale: string,
): Promise<{ ok: boolean; state: string | null; error: string | null }> {
  try {
    const r = await patchDraft(
      deps(null, run.clock),
      run.lastUid,
      E(locale, { draftId: d.id, expectedRevision: d.revision, payload, confirmedFields }),
    );
    return { ok: true, state: r.data.draft.state, error: null };
  } catch (e) {
    return { ok: false, state: null, error: reasonOf(e) };
  }
}

/** Every saveable pending draft of [snap] for the confirm request. */
export function pendingOf(snap: AssistantTaskSnapshot, which: 'all' | number[]) {
  return snap.drafts
    .map((d, i) => ({ d, i }))
    .filter(
      ({ d, i }) =>
        (d.state === 'draft' || d.state === 'needs_review') &&
        (which === 'all' || which.includes(i)),
    )
    .map(({ d }) => d);
}

async function runConfirm(
  turn: Extract<Turn, { confirm: unknown }>,
  ti: number,
  run: CaseRun,
  locale: string,
) {
  if (!run.lastTaskId) return;
  const uid = turn.as ? UID[turn.as] : run.lastUid;
  run.clock = new Date(run.clock.getTime() + 20_000);
  let snap: AssistantTaskSnapshot;
  // L7: "Lưu" on the card that waits — the last message's, else (a follow-up answered without a
  // card: "ok", "là sao") the latest card still waiting above, as the person taps it.
  let taskId = run.lastTaskId;
  try {
    snap = await snapshotOf(taskId, uid, run.clock, locale);
    if (turn.confirm === 'all' && pendingOf(snap, 'all').length === 0) {
      for (const s of [...run.steps].reverse()) {
        if (s.taskId === taskId || s.uid !== uid) continue;
        const other = await snapshotOf(s.taskId, uid, run.clock, locale);
        if (pendingOf(other, 'all').length > 0) {
          taskId = s.taskId;
          snap = other;
          break;
        }
      }
    }
  } catch (e) {
    run.refusals.push({ turn: ti, op: 'confirmDrafts', reason: reasonOf(e) });
    return;
  }
  await confirmNow(
    run,
    ti,
    uid,
    taskId,
    pendingOf(snap, turn.confirm),
    turn.acknowledge ?? [],
    turn.retry ?? false,
    locale,
  );
  await capture(run, ti, `turn ${ti + 1} · after save`, taskId, uid, locale);
}

export async function confirmNow(
  run: CaseRun,
  ti: number,
  uid: string,
  taskId: string,
  drafts: AssistantTaskSnapshot['drafts'],
  acknowledge: string[],
  retry: boolean,
  locale: string,
) {
  if (drafts.length === 0) return;
  const requestId = randomUUID();
  const body = E(locale, {
    clientRequestId: requestId,
    taskId,
    selected: drafts.map((d) => ({
      draftId: d.id,
      revision: d.revision,
      acknowledge: acknowledge.length ? acknowledge : d.warnings,
    })),
  });
  const once = async (retried: boolean) => {
    try {
      const r = await confirmDrafts(deps(null, run.clock), uid, body);
      run.confirms.push({
        turn: ti,
        uid,
        taskId,
        requestId,
        items: r.data.items,
        error: null,
        retried,
        recordsAfter: await countRecords(),
      });
    } catch (e) {
      run.confirms.push({
        turn: ti,
        uid,
        taskId,
        requestId,
        items: [],
        error: reasonOf(e),
        retried,
        recordsAfter: await countRecords(),
      });
    }
  };
  await once(false);
  if (retry) await once(true);
}

/** Domain records written by the assistant (the app's collections). */
export async function countRecords() {
  let n = 0;
  // Seeded records are `source: 'app'`; everything else in these collections came from a save.
  // Lumi L5: meals in the Ăn dặm diary.
  for (const col of ['records', 'expenses', 'reminders', 'checkins', 'timers', 'meals']) {
    const s = await db.collection(`babies/${B}/${col}`).get();
    n += s.docs.filter(
      (d) =>
        !(col === 'records' && d.get('source') === 'app') &&
        !(col === 'expenses' && d.get('source') === 'manual') &&
        // L7: a record deleted through Lumi ("xoá cái vừa ghi") is no longer saved.
        d.get('deleted') !== true,
    ).length;
  }
  return n;
}

/** The `data` of the care records of [type] a case saved (seeded ones are `source: 'app'`). */
export async function savedRecordData(type: string): Promise<Record<string, unknown>[]> {
  const s = await db.collection(`babies/${B}/records`).where('type', '==', type).get();
  return s.docs
    .filter((d) => d.get('source') !== 'app' && d.get('deleted') !== true)
    .map((d) => (d.get('data') as Record<string, unknown> | undefined) ?? {});
}

// ---------- Outcome ----------

export function outcomeOf(s: AssistantTaskSnapshot): string {
  const parts: AssistantPart[] = s.messages
    .filter((m) => m.role === 'assistant')
    .flatMap((m) => m.parts);
  const codes = parts.flatMap((p) => (p.type === 'text' && p.code ? [p.code as string] : []));
  if (parts.some((p) => p.type === 'health_support')) return 'health';
  if (codes.includes('SMALL_TALK')) return 'small_talk';
  if (codes.includes('HELP')) return 'help';
  // L10: a read answered with its card (0663bb8: a question the rules read is free).
  if (s.task.state === 'ready' && parts.some((p) => p.type === 'read_card')) return 'answer';
  if (s.task.state === 'awaiting_clarification') return 'awaiting';
  if (s.task.state === 'blocked') return `blocked:${s.task.errorCode ?? '-'}`;
  if (s.drafts.length > 0) return 'drafts';
  if (s.task.state === 'failed' && s.task.errorCode === 'WRITE_DENIED') return 'denied';
  if (s.task.state === 'failed' && s.task.errorCode === 'READ_DENIED') return 'read_denied';
  if (codes.includes('CARE_NO_APPROVED_CONTENT') || codes.includes('RECIPES_NONE_APPROVED'))
    return 'fallback';
  if (parts.some((p) => p.type === 'approved_content' || p.type === 'recipe_list')) return 'care';
  if (
    codes.includes('MEDICINE_NOT_SCHEDULED') ||
    codes.includes('PREVIOUS_SAVED') ||
    codes.includes('APP_UPDATE_NEEDED')
  )
    return 'notice';
  // L7: a follow-up the server answered from the dialogue state (a restate, a delete…).
  if (codes.includes('FOLLOW_UP') && s.task.state === 'ready') return 'follow_up';
  if (
    s.task.state === 'ready' &&
    parts.some((p) => p.type === 'source_summary' || p.type === 'text')
  ) {
    return s.task.usage === 'committed' ? 'answer' : 'fallback';
  }
  return `${s.task.state}:${s.task.errorCode ?? '-'}`;
}

export const noticeCodes = (s: AssistantTaskSnapshot) =>
  s.messages
    .flatMap((m) => m.parts)
    .flatMap((p) => (p.type === 'text' && p.code ? [p.code as string] : []));

export const quota = async () =>
  ((await db.doc(`families/${F}/quota/${WIN}`).get()).data() ?? { used: 0, reserved: 0 }) as {
    used: number;
    reserved: number;
  };
