import { z } from 'zod';

/**
 * QA handbook on the staff portal ("Phát triển › Sổ tay kiểm thử", P-132). The handbook explains
 * each module and lists its smoke and core (happy path) cases; results are recorded per test run so
 * every build keeps its own history. Built-in cases ship with the server
 * (`firebase/functions/src/qa-catalog.ts`); staff can add their own and edit or archive any case.
 * It never touches family data, so it sits outside the R-183 staff audit (each result and comment
 * carries who and when instead).
 */

/** Modules in the order the handbook lists them (follows the Figma coverage checklist §B–§G). */
export const qaModules = [
  'onboarding',
  'baby',
  'family',
  'roles',
  'today',
  'care',
  'history',
  'reminders',
  'offline',
  'widgets',
  'memories',
  'albums',
  'stories',
  'me',
  'platform',
  'landing',
  'portal',
] as const;
export type QaModule = (typeof qaModules)[number];

/** Case ids read "CARE-004"; cases added on the portal read "CARE-Q01". */
export const qaModulePrefix: Record<QaModule, string> = {
  onboarding: 'ONB',
  baby: 'BABY',
  family: 'FAM',
  roles: 'ROLE',
  today: 'TODAY',
  care: 'CARE',
  history: 'HIST',
  reminders: 'REM',
  offline: 'SYNC',
  widgets: 'WID',
  memories: 'MEM',
  albums: 'ALB',
  stories: 'STORY',
  me: 'ME',
  platform: 'PLAT',
  landing: 'WEB',
  portal: 'ADM',
};

/** Smoke = the critical path, run on every deploy; core = the module's main happy paths. */
export const qaLevels = ['smoke', 'core'] as const;
export type QaLevel = (typeof qaLevels)[number];

/** iOS and Android app, the staff portal, the landing website and the public story page. */
export const qaPlatforms = ['ios', 'android', 'portal', 'landing', 'share'] as const;
export type QaPlatform = (typeof qaPlatforms)[number];

export const qaStatuses = ['notRun', 'passed', 'failed', 'blocked', 'skipped'] as const;
export type QaStatus = (typeof qaStatuses)[number];

export const qaEnvironments = ['dev', 'prod'] as const;
export type QaEnvironment = (typeof qaEnvironments)[number];

/** One test case: who to sign in as, the steps, and what must be true afterwards. */
export interface QaCaseContent {
  module: QaModule;
  title: string;
  level: QaLevel;
  platforms: QaPlatform[];
  /** The test account or starting state, e.g. "Chủ hồ sơ, 1 bé". */
  account: string;
  steps: string[];
  expected: string[];
}

export interface QaCaseSeed extends QaCaseContent {
  id: string;
  /** Business-map ids (R-xxx, D-xxx, P-xxx) and Figma frames the case checks. */
  refs?: string[];
}

export const qaCaseIdPattern = /^[A-Z]{2,5}-Q?\d{2,3}$/;
export const qaCaseIdSchema = z.string().regex(qaCaseIdPattern);
export const qaRunIdSchema = z.string().regex(/^r_[a-f0-9]{20}$/);

const line = z.string().trim().min(1).max(500);

export const qaCaseContentSchema = z.object({
  module: z.enum(qaModules),
  title: z.string().trim().min(3).max(160),
  level: z.enum(qaLevels),
  platforms: z
    .array(z.enum(qaPlatforms))
    .min(1)
    .max(qaPlatforms.length)
    .refine((p) => new Set(p).size === p.length, 'duplicate platform'),
  account: z.string().trim().max(200),
  steps: z.array(line).min(1).max(20),
  expected: z.array(line).min(1).max(20),
});

/** `staffQa`: the catalog, the runs, and the results of one run (the newest open one by default). */
export const qaHandbookSchema = z.object({ runId: qaRunIdSchema.nullable() });

/** `staffQaCase`: the comments on one case in one run. */
export const qaCaseRefSchema = z.object({ runId: qaRunIdSchema, caseId: qaCaseIdSchema });

/** `staffQaUpdate`: every handbook write. */
export const qaUpdateSchema = z.discriminatedUnion('op', [
  z.object({
    op: z.literal('createRun'),
    /** "1.0.3 (38) DEV". */
    name: z.string().trim().min(1).max(60),
    environment: z.enum(qaEnvironments),
    notes: z.string().trim().max(500),
  }),
  z.object({ op: z.literal('archiveRun'), runId: qaRunIdSchema, archived: z.boolean() }),
  z.object({
    op: z.literal('setResult'),
    runId: qaRunIdSchema,
    caseId: qaCaseIdSchema,
    status: z.enum(qaStatuses),
  }),
  z.object({
    op: z.literal('comment'),
    runId: qaRunIdSchema,
    caseId: qaCaseIdSchema,
    text: z.string().trim().min(1).max(2000),
  }),
  qaCaseContentSchema.extend({ op: z.literal('saveCase'), caseId: qaCaseIdSchema.nullable() }),
  z.object({ op: z.literal('archiveCase'), caseId: qaCaseIdSchema, archived: z.boolean() }),
]);
export type QaUpdate = z.infer<typeof qaUpdateSchema>;
