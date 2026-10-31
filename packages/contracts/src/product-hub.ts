import { z } from 'zod';
import { featureKeys } from './features-hub.js';

/**
 * Product Hub · "Sản phẩm" (D-155, `docs/product-hub/`): the staff portal's product knowledge
 * workspace. Two layers per feature (doc 05 §1): **facts** extracted by the trusted sync from a
 * pinned revision, and **narrative** sections written by staff, which count only once approved.
 * Tiers and capabilities are never stored here — they are read from `features-hub.ts`,
 * `entitlements.ts` and `config/*`. Decisions stay in `docs/product/business-map.md`; the Hub
 * mirrors them by id.
 */

// ---------- Enums ----------

export const productPillars = ['care', 'grow', 'remember', 'platform'] as const;
export type ProductPillar = (typeof productPillars)[number];

/** Product chapters describe the product's evolution; they never gate a feature (brief §1.2). */
export const productChapters = ['ch01', 'ch02', 'ch03', 'ch04'] as const;
export type ProductChapter = (typeof productChapters)[number];

export const productPlatforms = ['ios', 'android', 'watch', 'web'] as const;
export type ProductPlatform = (typeof productPlatforms)[number];

/** Four fields, never collapsed into one status (doc 05 §3). */
export const featureLifecycles = [
  'planned',
  'designed',
  'in_development',
  'built',
  'deprecated',
] as const;
export const featureImplementations = ['not_found', 'partial', 'implemented'] as const;
export const featureVerifications = [
  'unverified',
  'code_read',
  'tests_pass',
  'device_verified',
] as const;
export const featureReleases = ['not_released', 'beta', 'released', 'withdrawn'] as const;
export type FeatureLifecycle = (typeof featureLifecycles)[number];
export type FeatureImplementation = (typeof featureImplementations)[number];
export type FeatureVerification = (typeof featureVerifications)[number];
export type FeatureRelease = (typeof featureReleases)[number];

/** Authority of a knowledge source (brief §9.5), strongest first. */
export const sourceAuthorities = [
  'verified_implementation',
  'approved_decision',
  'approved_spec',
  'draft_spec',
  'design_reference',
  'research',
  'ai_inference',
] as const;
export type SourceAuthority = (typeof sourceAuthorities)[number];

export const sourceKinds = [
  'repo_md',
  'upload_md',
  'upload_txt',
  'upload_pdf',
  'upload_docx',
  'decision_registry',
] as const;
export type SourceKind = (typeof sourceKinds)[number];

export const decisionKinds = ['D', 'R', 'P', 'Q', 'G'] as const;
export type DecisionKind = (typeof decisionKinds)[number];
export const decisionStatuses = ['approved', 'superseded', 'open', 'resolved', 'recorded'] as const;
export type DecisionStatus = (typeof decisionStatuses)[number];

/** Narrative sections of a feature page (doc 04 §2.3); facts are not sections. */
export const featureSectionKeys = [
  'summary',
  'problem',
  'value',
  'ux',
  'rules',
  'edgeCases',
  'access',
  'metrics',
  'issues',
  'decisions',
] as const;
export type FeatureSectionKey = (typeof featureSectionKeys)[number];

// ---------- Ids ----------

/** "care.feeding", "platform.lumi": pillar + slug. */
export const productFeatureIdSchema = z
  .string()
  .regex(/^(care|grow|remember|platform)\.[a-z][a-z0-9_]{1,40}$/);
export const decisionIdSchema = z.string().regex(/^[DRPQG]-\d{3}$/);
const localized = z.object({ vi: z.string().trim().min(1).max(200), en: z.string().max(200) });
/** Repository-relative path: no leading slash, no "..". */
export const repoPathSchema = z
  .string()
  .min(1)
  .max(400)
  .refine((p) => !p.startsWith('/') && !p.split('/').includes('..'), 'repo-relative');

// ---------- Registry seed (docs/product-hub/registry/features.json) ----------

/**
 * One feature as engineers maintain it in the repository. Globs resolve to concrete files at the
 * sync revision; a glob that matches nothing is reported as a dead reference.
 */
export const registryFeatureSchema = z.object({
  id: productFeatureIdSchema,
  name: localized,
  pillar: z.enum(productPillars),
  aliases: z.array(z.string().min(2).max(60)).max(20).default([]),
  /** The "Tính năng & Premium" catalogue key when the feature is tierable. */
  hubKey: z.enum(featureKeys).nullable().default(null),
  /** Free capabilities the feature runs on when it has no hub key (`module.basic`, …). */
  capabilities: z.array(z.string().max(60)).max(10).default([]),
  platforms: z.array(z.enum(productPlatforms)).min(1),
  chapters: z.array(z.enum(productChapters)).default([]),
  lifecycle: z.enum(featureLifecycles),
  implementation: z.enum(featureImplementations),
  verification: z.enum(featureVerifications),
  release: z.enum(featureReleases),
  confidence: z.enum(['high', 'medium', 'low']),
  modules: z.array(z.string().max(200)).max(30).default([]),
  functions: z.array(z.string().max(200)).max(30).default([]),
  tests: z.array(z.string().max(200)).max(30).default([]),
  docs: z.array(z.string().max(200)).max(30).default([]),
  figma: z.array(z.string().regex(/^\d+:\d+$/)).max(20).default([]),
  decisions: z.array(decisionIdSchema).max(40).default([]),
  dependsOn: z.array(productFeatureIdSchema).max(20).default([]),
  note: z.string().max(400).default(''),
});
export type RegistryFeature = z.infer<typeof registryFeatureSchema>;

export const productRegistrySchema = z
  .object({ version: z.literal(1), features: z.array(registryFeatureSchema).min(1).max(200) })
  .superRefine((r, ctx) => {
    const ids = new Set<string>();
    for (const f of r.features) {
      if (ids.has(f.id)) ctx.addIssue({ code: 'custom', message: `duplicate id ${f.id}` });
      ids.add(f.id);
    }
    for (const f of r.features) {
      for (const d of f.dependsOn) {
        if (!ids.has(d)) ctx.addIssue({ code: 'custom', message: `${f.id} depends on ${d}` });
      }
    }
  });
export type ProductRegistry = z.infer<typeof productRegistrySchema>;

// ---------- Records written by the sync ----------

/** Facts the sync resolved for one feature at a revision. */
export interface FeatureFacts {
  modules: string[];
  functions: string[];
  /** Callables exported from `firebase/functions/src/index.ts` whose handler file is listed. */
  callables: string[];
  tests: string[];
  docs: string[];
  figma: string[];
  /** Explicit registry decisions plus D/R/P ids cited in the feature's code. */
  decisions: string[];
  /** "path:line" of each decision id found in code (evidence of `implements`). */
  codeCitations: Array<{ id: string; at: string }>;
  /** Registry globs that matched no file at this revision. */
  deadGlobs: string[];
}

export interface ProductFeatureRecord extends Omit<
  RegistryFeature,
  'modules' | 'functions' | 'tests' | 'docs' | 'figma' | 'decisions'
> {
  facts: FeatureFacts;
  revision: string;
  syncedAt: string;
}

export interface ProductChunk {
  id: string;
  sourceId: string;
  version: string;
  headingPath: string[];
  anchor: string;
  text: string;
  lang: 'vi' | 'en';
  ids: string[];
}

export interface ProductSourceRecord {
  id: string;
  kind: SourceKind;
  path: string;
  title: string;
  authority: SourceAuthority;
  contentHash: string;
  blobSha: string;
  commit: string;
  docDate: string | null;
  headings: string[];
  features: string[];
  decisions: string[];
  bytes: number;
  chunkCount: number;
  status: 'active' | 'deleted' | 'archived';
}

export interface ProductDecisionRecord {
  id: string;
  kind: DecisionKind;
  title: string;
  text: string;
  date: string | null;
  status: DecisionStatus;
  resolves: string[];
  supersedes: string[];
  features: string[];
  source: { path: string; line: number; commit: string };
}

export const changeKinds = ['added', 'changed', 'moved', 'deleted'] as const;
export type ChangeKind = (typeof changeKinds)[number];

export type ChangeItem =
  | {
      type: 'source';
      change: ChangeKind;
      source: ProductSourceRecord;
      before: { path: string; contentHash: string } | null;
      chunks: ProductChunk[];
    }
  | {
      type: 'decision';
      change: Exclude<ChangeKind, 'moved'>;
      decision: ProductDecisionRecord;
    }
  | {
      type: 'feature';
      change: Exclude<ChangeKind, 'moved'>;
      feature: ProductFeatureRecord;
    }
  | { type: 'conflict'; change: 'added'; conflict: ProductConflictRecord }
  | { type: 'journey'; change: Exclude<ChangeKind, 'moved'>; journey: ProductJourneyRecord };

export interface ProductConflictRecord {
  id: string;
  topic: 'tier' | 'plan_model' | 'superseded_citation' | 'dead_reference' | 'ai_suggested';
  feature: string | null;
  /** English, for logs and the sync output; the portal words it from `topic` and `tiers`. */
  summary: string;
  /** Tier conflicts: what the document claims and the default in code. */
  tiers: { claimed: 'free' | 'premium' | 'beta'; code: 'free' | 'premium' | 'beta' } | null;
  claims: Array<{
    path: string;
    anchor: string | null;
    authority: SourceAuthority | 'code';
    text: string;
    date: string | null;
  }>;
  /**
   * `suggested` (Phase 3): found by Claude, not yet confirmed by a person; it counts nowhere until
   * accepted (→ open) or dismissed. `resolved` / `accepted_difference` close an open conflict.
   */
  status: 'suggested' | 'open' | 'resolved' | 'accepted_difference' | 'dismissed';
}

export interface ChangeSetSummary {
  added: number;
  changed: number;
  moved: number;
  deleted: number;
  unchanged: number;
  warnings: string[];
}

// ---------- Narrative sections ----------

export const sectionBodySchema = z.object({
  vi: z.string().trim().min(1).max(12_000),
  en: z.string().trim().max(12_000).default(''),
});
/** "D-150", "docs/product/x.md#heading", "firebase/functions/src/insights.ts:72". */
export const sectionSourceSchema = z.string().trim().min(3).max(300);

export interface SectionVersion {
  body: { vi: string; en: string };
  sources: string[];
  by: string;
  at: string;
}
export interface FeatureSection {
  key: FeatureSectionKey;
  draft: (SectionVersion & { origin: 'staff' | 'ai' }) | null;
  approved: (SectionVersion & { approvedBy: string; approvedAt: string; version: number }) | null;
  /** Set when a cited source changed after approval; never rewrites the text (doc 06 §2.8). */
  stale: { since: string; paths: string[] } | null;
}

// ---------- Knowledge coverage (doc 05 §4) ----------

export const coverageDimensions = [
  'problem',
  'value',
  'ux',
  'rules',
  'edgeCases',
  'entitlements',
  'technical',
  'metrics',
  'decisions',
] as const;
export type CoverageDimension = (typeof coverageDimensions)[number];

export const coverageWeights: Record<CoverageDimension, number> = {
  problem: 12,
  value: 8,
  ux: 14,
  rules: 16,
  edgeCases: 10,
  entitlements: 10,
  technical: 10,
  metrics: 10,
  decisions: 10,
};

export type SectionState = 'approved' | 'draft' | 'missing';

export interface CoverageInput {
  sections: Partial<Record<FeatureSectionKey, { state: SectionState; stale: boolean; sources: number }>>;
  /** A hub key or at least one capability. */
  hasTier: boolean;
  openTierConflict: boolean;
  moduleCount: number;
  testCount: number;
  decisionCount: number;
  /** The approved metrics section cites a `docs/product-analytics/` source. */
  metricsInstrumented: boolean;
  openConflicts: number;
}

export interface CoverageResult {
  score: number;
  dimensions: Array<{ key: CoverageDimension; weight: number; earned: number; state: string }>;
  missing: CoverageDimension[];
  unverified: CoverageDimension[];
  stale: CoverageDimension[];
  capped: boolean;
}

const stateFactor: Record<SectionState, number> = { approved: 1, draft: 0.4, missing: 0 };

/**
 * Deterministic 0–100 score; document count is not an input. Approved = full weight, draft = 40 %,
 * a stale approval loses half, and an open conflict caps the score at 69.
 */
export function productCoverage(input: CoverageInput): CoverageResult {
  const dims: CoverageResult['dimensions'] = [];
  const missing: CoverageDimension[] = [];
  const unverified: CoverageDimension[] = [];
  const stale: CoverageDimension[] = [];
  const section = (key: FeatureSectionKey) =>
    input.sections[key] ?? { state: 'missing' as const, stale: false, sources: 0 };

  for (const key of coverageDimensions) {
    const weight = coverageWeights[key];
    let factor: number;
    let state: string;
    if (key === 'entitlements') {
      factor = input.hasTier && !input.openTierConflict ? 1 : input.hasTier ? 0.5 : 0;
      state = factor === 1 ? 'present' : input.hasTier ? 'conflict' : 'missing';
    } else if (key === 'technical') {
      factor = (input.moduleCount > 0 ? 0.5 : 0) + (input.testCount > 0 ? 0.5 : 0);
      state = factor === 1 ? 'present' : factor > 0 ? 'partial' : 'missing';
    } else if (key === 'decisions') {
      const s = section('decisions');
      factor = input.decisionCount > 0 ? 1 : s.state === 'approved' ? 1 : 0;
      state = factor === 1 ? 'present' : 'missing';
    } else {
      const s = section(key);
      factor = stateFactor[s.state];
      // Rules and edge cases count fully only when they cite a source.
      if ((key === 'rules' || key === 'edgeCases') && s.state === 'approved' && s.sources === 0) {
        factor = 0.6;
        unverified.push(key);
      }
      if (key === 'metrics' && s.state === 'approved' && !input.metricsInstrumented) factor = 0.7;
      if (s.stale && s.state === 'approved') {
        factor *= 0.5;
        stale.push(key);
      }
      state = s.stale && s.state === 'approved' ? 'stale' : s.state;
      if (s.state === 'draft') unverified.push(key);
    }
    if (factor === 0) missing.push(key);
    dims.push({ key, weight, earned: Math.round(weight * factor * 10) / 10, state });
  }
  let score = Math.round(dims.reduce((sum, d) => sum + d.earned, 0));
  const capped = input.openConflicts > 0 && score > 69;
  if (capped) score = 69;
  return { score, dimensions: dims, missing, unverified, stale, capped };
}

/** Coverage bands for filters and the Overview distribution. */
export function coverageBand(score: number): 'low' | 'mid' | 'high' {
  return score >= 70 ? 'high' : score >= 40 ? 'mid' : 'low';
}

// ---------- Callables ----------

export const productFeaturesQuerySchema = z.object({}).strict();
export const productFeatureRefSchema = z.object({ id: productFeatureIdSchema });
export const productSaveSectionSchema = z.object({
  feature: productFeatureIdSchema,
  key: z.enum(featureSectionKeys),
  body: sectionBodySchema,
  sources: z.array(sectionSourceSchema).max(30).default([]),
});
export const productSectionActSchema = z.object({
  feature: productFeatureIdSchema,
  key: z.enum(featureSectionKeys),
  action: z.enum(['approve', 'discard']),
});
export const productSourcesQuerySchema = z.object({
  authority: z.enum(sourceAuthorities).optional(),
  feature: productFeatureIdSchema.optional(),
  q: z.string().trim().max(80).optional(),
});
export const productSourceRefSchema = z.object({ id: z.string().min(3).max(80) });
export const productChangeSetRefSchema = z.object({ id: z.string().min(3).max(80) });
export const productReviewChangeSetSchema = z.object({
  id: z.string().min(3).max(80),
  decision: z.enum(['approve', 'reject']),
  reason: z.string().trim().max(500).default(''),
});
export const productDecisionsQuerySchema = z.object({
  kind: z.enum(decisionKinds).optional(),
  feature: productFeatureIdSchema.optional(),
  status: z.enum(decisionStatuses).optional(),
  q: z.string().trim().max(80).optional(),
});

// ---------- Copilot (Phase 2, doc 07) ----------

/**
 * Sản phẩm · Copilot on Claude (owner, 2026-10-31: "tôi muốn dùng claude API key"). Staff-only,
 * server-side, reads product knowledge only — never family data. One model call per question;
 * the server checks every citation, and a "fact" without strong evidence becomes an assumption.
 */
export const COPILOT_MODEL = 'claude-opus-5-5';
export const COPILOT_PROMPT_VERSION = 'product-copilot-v1';
/** D-155 #5: per staff member per hour and per day; a global daily cap protects the budget. */
export const COPILOT_LIMITS = {
  perHour: 20,
  perDay: 200,
  globalPerDay: 1000,
  retentionDays: 180,
  historyTurns: 3,
} as const;

export const copilotClaimTypes = ['fact', 'assumption', 'recommendation'] as const;
export type CopilotClaimType = (typeof copilotClaimTypes)[number];
export const copilotConfidences = ['verified', 'mixed', 'insufficient'] as const;
export type CopilotConfidence = (typeof copilotConfidences)[number];

export const copilotScopeSchema = z.union([z.literal('global'), productFeatureIdSchema]);
const conversationIdSchema = z.string().regex(/^[A-Za-z0-9]{10,40}$/);
export const productCopilotAskSchema = z.object({
  conversationId: conversationIdSchema.optional(),
  scope: copilotScopeSchema,
  question: z.string().trim().min(2).max(1000),
  locale: z.enum(['vi', 'en']),
});
export const productConversationRefSchema = z.object({ id: conversationIdSchema });

/** What the model must return (validated again on the server). */
export const copilotModelAnswerSchema = z.object({
  answer: z.string().max(8000),
  features: z.array(z.string().max(60)).max(20),
  claims: z
    .array(
      z.object({
        text: z.string().max(1500),
        type: z.enum(copilotClaimTypes),
        cites: z.array(z.string().max(10)).max(12),
      }),
    )
    .max(24),
  missingEvidence: z.array(z.string().max(500)).max(10),
  implications: z.string().max(2000),
  suggestions: z.array(z.string().max(600)).max(8),
});
export type CopilotModelAnswer = z.infer<typeof copilotModelAnswerSchema>;

export type CopilotBlockKind = 'chunk' | 'decision' | 'section' | 'feature' | 'registry' | 'conflict' | 'journey';
export interface CopilotCitation {
  id: string;
  kind: CopilotBlockKind;
  label: string;
  path: string | null;
  anchor: string | null;
  authority: SourceAuthority | 'code' | 'approved_section';
  status: 'approved' | 'draft' | 'stale' | 'n/a';
  date: string | null;
  revision: string | null;
  feature: string | null;
  excerpt: string;
}

export interface CopilotAnswer {
  /** `model`: Claude answered; `sources`: no model answer (not configured, error, refusal). */
  mode: 'model' | 'sources';
  reason: 'unconfigured' | 'error' | 'refused' | null;
  answer: string;
  features: string[];
  claims: Array<{ text: string; type: CopilotClaimType; cites: string[]; downgraded: boolean }>;
  confidence: CopilotConfidence;
  missingEvidence: string[];
  implications: string;
  suggestions: string[];
  citations: CopilotCitation[];
  freshness: { oldestCited: string | null; staleCited: string[] };
  model: string | null;
}

export interface CopilotMessage {
  id: string;
  role: 'user' | 'assistant';
  text: string;
  at: string;
  answer: CopilotAnswer | null;
}

export const productDraftTypes = [
  'opportunity',
  'ux_improvement',
  'rule_clarification',
  'investigation',
  'hypothesis',
] as const;
export type ProductDraftType = (typeof productDraftTypes)[number];
export const productCreateDraftSchema = z.object({
  type: z.enum(productDraftTypes),
  feature: productFeatureIdSchema.nullable().default(null),
  title: z.string().trim().min(3).max(160),
  body: z.string().trim().min(1).max(8000),
  evidence: z.array(sectionSourceSchema).max(24).default([]),
  conversationId: conversationIdSchema.optional(),
  messageId: z.string().max(40).optional(),
});
export const productHubSearchSchema = z.object({
  q: z.string().trim().min(2).max(200),
  feature: productFeatureIdSchema.optional(),
});

// ---------- Phase 3: journeys, opportunities, conflicts, section history ----------

const localizedText = z.object({ vi: z.string().trim().min(1).max(1500), en: z.string().max(1500) });

/** A user journey as kept in `docs/product-hub/registry/journeys.json` (reviewed like features). */
export const registryJourneySchema = z.object({
  id: z.string().regex(/^[a-z][a-z0-9_]{2,40}$/),
  name: localized,
  goal: localizedText,
  trigger: localizedText,
  preconditions: z.array(localizedText).max(10).default([]),
  steps: z
    .array(z.object({ text: localizedText, feature: productFeatureIdSchema.nullable().default(null) }))
    .min(1)
    .max(20),
  alternatives: z.array(localizedText).max(10).default([]),
  errors: z.array(localizedText).max(12).default([]),
  completion: localizedText,
  metrics: z.array(z.string().max(120)).max(10).default([]),
  verification: z.enum(featureVerifications),
  sources: z.array(z.string().min(3).max(300)).min(1).max(20),
});
export type RegistryJourney = z.infer<typeof registryJourneySchema>;
export const journeyRegistrySchema = z.object({
  version: z.literal(1),
  journeys: z.array(registryJourneySchema).max(100),
});
export interface ProductJourneyRecord extends RegistryJourney {
  features: string[];
  revision: string;
  syncedAt: string;
}

export const opportunityStatuses = ['proposed', 'triaged', 'accepted', 'declined', 'done'] as const;
export type OpportunityStatus = (typeof opportunityStatuses)[number];
export const opportunityLevels = ['low', 'medium', 'high'] as const;
export const opportunityEfforts = ['s', 'm', 'l'] as const;
export const opportunityPriorities = ['p1', 'p2', 'p3'] as const;

export const productSaveOpportunitySchema = z.object({
  id: z.string().min(10).max(40).optional(),
  title: z.string().trim().min(3).max(160),
  feature: productFeatureIdSchema.nullable().default(null),
  problem: z.string().trim().min(1).max(4000),
  evidence: z.array(sectionSourceSchema).max(24).default([]),
  hypothesis: z.string().trim().max(2000).default(''),
  proposal: z.string().trim().max(4000).default(''),
  impact: z.enum(opportunityLevels).default('medium'),
  effort: z.enum(opportunityEfforts).default('m'),
  priority: z.enum(opportunityPriorities).default('p2'),
  successCriteria: z.string().trim().max(2000).default(''),
  decisions: z.array(decisionIdSchema).max(20).default([]),
});
export type ProductOpportunityInput = z.infer<typeof productSaveOpportunitySchema>;
export const productOpportunityStatusSchema = z.object({
  id: z.string().min(10).max(40),
  status: z.enum(opportunityStatuses),
  note: z.string().trim().max(1000).default(''),
});
export interface ProductOpportunity extends ProductOpportunityInput {
  id: string;
  status: OpportunityStatus;
  fromDraft: string | null;
  createdBy: string;
  createdByUid: string;
  createdAt: string | null;
  updatedAt: string | null;
  history: Array<{ from: OpportunityStatus | null; to: OpportunityStatus; by: string; at: string; note: string }>;
}

export const productDraftActSchema = z.object({
  id: z.string().min(10).max(40),
  action: z.enum(['promote', 'dismiss']),
});
export const productConflictActSchema = z.object({
  id: z.string().min(3).max(60),
  action: z.enum(['accept', 'dismiss', 'resolve', 'accept_difference', 'reopen']),
  note: z.string().trim().max(1000).default(''),
  decision: decisionIdSchema.nullable().default(null),
});
export const productConflictsQuerySchema = z.object({
  status: z.enum(['all', 'suggested', 'open', 'resolved', 'accepted_difference', 'dismissed']).default('all'),
});
export const productFindConflictsSchema = z.object({ feature: productFeatureIdSchema, locale: z.enum(['vi', 'en']) });
export const productSectionRefSchema = z.object({
  feature: productFeatureIdSchema,
  key: z.enum(featureSectionKeys),
});
export const productJourneyRefSchema = z.object({ id: z.string().regex(/^[a-z][a-z0-9_]{2,40}$/) });
export const productDecisionRefSchema = z.object({ id: decisionIdSchema });

/** What Claude returns when asked for contradictions (each claim must cite a block). */
export const copilotConflictsSchema = z.object({
  conflicts: z
    .array(
      z.object({
        summary: z.string().max(600),
        claims: z.array(z.object({ block: z.string().max(10), text: z.string().max(600) })).min(2).max(4),
      }),
    )
    .max(6),
});
