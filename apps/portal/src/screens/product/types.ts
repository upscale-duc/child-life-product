import type {
  ChangeSetSummary,
  CoverageResult,
  FeatureLifecycle,
  FeatureSection,
  FeatureTier,
  ProductChunk,
  ProductConflictRecord,
  ProductFeatureRecord,
  ProductPillar,
  ProductSourceRecord,
  SourceAuthority,
} from '@child-life/contracts';

/** Response shapes of the `productHub*` callables (firebase/functions/src/product-hub.ts). */

export interface FeatureRow {
  id: string;
  name: { vi: string; en: string };
  pillar: ProductPillar;
  chapters: string[];
  platforms: string[];
  lifecycle: FeatureLifecycle;
  implementation: ProductFeatureRecord['implementation'];
  verification: ProductFeatureRecord['verification'];
  release: ProductFeatureRecord['release'];
  confidence: 'high' | 'medium' | 'low';
  hubKey: string | null;
  tier: FeatureTier | null;
  coverage: number;
  band: 'low' | 'mid' | 'high';
  missing: string[];
  stale: number;
  conflicts: number;
  syncedAt: string | null;
  revision: string;
}
export interface FeaturesView {
  features: FeatureRow[];
  conflictsWithoutFeature: number;
}

export interface FeatureView {
  feature: ProductFeatureRecord & { syncedAt: string | null };
  sections: FeatureSection[];
  supersededCitations: Array<{ section: string; id: string }>;
  coverage: CoverageResult;
  access: {
    hubKey: string | null;
    defaultTier: FeatureTier | null;
    liveTier: FeatureTier | null;
    credits: boolean;
    flags: string[];
    capabilities: string[];
  };
  sources: Array<{
    id: string;
    path: string;
    title: string;
    authority: SourceAuthority;
    docDate: string | null;
    commit: string;
  }>;
  decisions: Array<{ id: string; kind: string; title: string; date: string | null; status: string }>;
  conflicts: ProductConflictRecord[];
  dependents: string[];
  canEdit: boolean;
  canApprove: boolean;
}

export interface OverviewView {
  total: number;
  byLifecycle: Record<string, number>;
  byPillar: Record<string, number>;
  byPillarLifecycle: Record<string, number>;
  byTier: Record<string, number>;
  byBand: Record<string, number>;
  needVerification: number;
  released: number;
  staleFeatures: number;
  openConflicts: number;
  sources: number;
  pending: number;
  lastSync: { revision: string; at: string | null; by: string } | null;
  recentDecisions: Array<{ id: string; title: string; date: string | null }>;
  recentChanges: Array<{
    id: string;
    status: string;
    revision: string;
    at: string | null;
    summary: ChangeSetSummary;
  }>;
}

export interface PlansView {
  catalogue: Array<{
    key: string;
    group: string;
    defaultTier: FeatureTier;
    liveTier: FeatureTier | null;
    credits: boolean;
    flags: string[];
    capabilities: string[];
    features: string[];
  }>;
  capabilities: Array<{ key: string; free: boolean; premium: boolean; credits: boolean }>;
  conflicts: ProductConflictRecord[];
  decisions: Array<{ id: string; title: string; date: string | null }>;
}

export interface SourceRow {
  id: string;
  path: string;
  title: string;
  authority: SourceAuthority;
  features: string[];
  decisions: number;
  chunkCount: number;
  docDate: string | null;
  commit: string;
  syncedAt: string | null;
}
export interface SourcesView {
  sources: SourceRow[];
}
export interface SourceView {
  source: ProductSourceRecord & { syncedAt: string | null };
  chunks: ProductChunk[];
  versions: Array<{ contentHash: string; commit: string; path: string; syncedAt: string | null }>;
}

export interface ChangeSetRow {
  id: string;
  status: string;
  revision: string;
  summary: ChangeSetSummary;
  itemCount: number;
  createdBy: string;
  createdByUid: string;
  createdAt: string | null;
  reviewedBy: string | null;
  reviewedAt: string | null;
  reason: string;
}
export interface ChangeSetsView {
  changeSets: ChangeSetRow[];
}
export interface ChangeSetView {
  id: string;
  status: string;
  revision: string;
  summary: ChangeSetSummary;
  createdBy: string;
  createdByUid: string;
  createdAt: string | null;
  sources: Array<{
    change: string;
    id: string;
    path: string;
    beforePath: string | null;
    title: string;
    authority: SourceAuthority;
    features: string[];
    chunkCount: number;
    diff: Array<{ heading: string; change: 'added' | 'removed' | 'changed'; before: string; after: string }>;
  }>;
  decisions: Array<{ change: string; id: string; title: string; status: string }>;
  features: Array<{ change: string; id: string; name: { vi: string; en: string } | null; deadGlobs: string[] }>;
  conflicts: ProductConflictRecord[];
}

// ---------- Copilot (Phase 2) ----------

export type { CopilotAnswer, CopilotCitation, CopilotMessage } from '@child-life/contracts';

export interface ConversationsView {
  conversations: Array<{ id: string; scope: string; title: string; lastAt: string | null; messages: number }>;
}
export interface ConversationView {
  id: string;
  scope: string;
  title: string;
  messages: import('@child-life/contracts').CopilotMessage[];
}
export interface AskResult {
  conversationId: string;
  questionId: string;
  message: import('@child-life/contracts').CopilotMessage;
}
export interface SearchView {
  built: boolean;
  hits: Array<{
    id: string;
    kind: string;
    title: string;
    path: string | null;
    anchor: string | null;
    authority: string;
    date: string | null;
    features: string[];
    excerpt: string;
  }>;
}
export interface DraftsView {
  drafts: Array<{
    id: string;
    type: string;
    feature: string | null;
    title: string;
    body: string;
    evidence: string[];
    status: string;
    createdBy: string;
    createdAt: string | null;
  }>;
}

// ---------- Phase 3 ----------

export type {
  ProductJourneyRecord,
  ProductOpportunity,
  ProductConflictRecord as ConflictRecord,
} from '@child-life/contracts';

export interface DecisionRow {
  id: string;
  kind: string;
  title: string;
  excerpt: string;
  date: string | null;
  status: string;
  features: string[];
  resolves: string[];
  supersedes: string[];
  supersededBy: string[];
  resolvedBy: string[];
  line: number;
}
export interface DecisionsView {
  decisions: DecisionRow[];
  openByFeature: Record<string, string[]>;
  total: number;
}
export interface DecisionDetailView {
  decision: import('@child-life/contracts').ProductDecisionRecord;
  supersededBy: string[];
  resolvedBy: string[];
  opportunities: Array<{ id: string; title: string; status: string }>;
}
export interface JourneysView {
  journeys: Array<{
    id: string;
    name: { vi: string; en: string };
    goal: { vi: string; en: string };
    steps: number;
    features: string[];
    verification: string;
    metrics: string[];
    revision: string;
  }>;
}
export interface JourneyView {
  journey: import('@child-life/contracts').ProductJourneyRecord;
  features: Array<{ id: string; name: { vi: string; en: string }; lifecycle: string; verification: string }>;
}
export interface OpportunitiesView {
  opportunities: import('@child-life/contracts').ProductOpportunity[];
  canEdit: boolean;
  canApprove: boolean;
}
export interface ConflictsView {
  conflicts: Array<
    import('@child-life/contracts').ProductConflictRecord & {
      createdAt: string | null;
      resolution: { note: string; decision: string | null; by: string; at: string } | null;
      history: Array<{ from: string; to: string; by: string; at: string; note: string }>;
    }
  >;
  canApprove: boolean;
  canEdit: boolean;
}
export interface SectionVersionsView {
  current: import('@child-life/contracts').FeatureSection['approved'];
  versions: Array<NonNullable<import('@child-life/contracts').FeatureSection['approved']>>;
}
