import type {
  AppUpdateConfig,
  AppUpdatePublic,
  AuditCategory,
  EntitlementsConfig,
  FeedbackType,
  FirstAidPack,
  FlagKey,
  Flags,
  GrantEnvironment,
  Limits,
  ReferenceModel,
  RhythmContent,
  RhythmRules,
  QaCaseContent,
  QaEnvironment,
  QaStatus,
  StaffLevels,
  StaffMemberStatus,
} from '@child-life/contracts';
import { FirebaseError } from 'firebase/app';
import { httpsCallable, type Functions } from 'firebase/functions';
import { createContext, useCallback, useContext, useEffect, useState } from 'react';

/**
 * The staff callables (S15, `firebase/functions/src/staff.ts`). Every read and write goes through
 * them: the portal never reads Firestore directly, and the server re-checks the staff claim and
 * role on every call (P-121).
 */
export type Callable =
  | 'staffBadges'
  | 'staffOverview'
  | 'staffTickets'
  | 'staffTicket'
  | 'staffTicketScreenshot'
  | 'staffClaimTicket'
  | 'staffReplyTicket'
  | 'staffCloseTicket'
  | 'staffStorageRequests'
  | 'staffDecideStorage'
  | 'staffJobs'
  | 'staffRerunJob'
  | 'staffSystem'
  | 'staffAi'
  | 'staffFlags'
  | 'staffSetFlag'
  | 'staffAudit'
  | 'staffExportAudit'
  | 'staffQa'
  | 'staffQaCase'
  | 'staffQaUpdate'
  | 'staffMe'
  | 'staffAcceptInvite'
  | 'staffTeam'
  | 'staffInvite'
  | 'staffUpdateMember'
  | 'staffSaveRole'
  | 'staffApproveRerun'
  | 'staffFamilies'
  | 'staffFamily'
  | 'staffOpenTransfer'
  | 'staffCancelTransfer'
  | 'staffAnalytics'
  | 'staffExportAnalytics'
  | 'staffReference'
  | 'staffReferenceDraft'
  | 'staffReferenceAct'
  | 'staffFirstAid'
  | 'staffFirstAidDraft'
  | 'staffFirstAidAct'
  | 'staffFirstAidImage'
  | 'staffKeepsakes'
  | 'staffKeepsakesDraft'
  | 'staffKeepsakesAct'
  | 'staffKeepsakesAsset'
  | 'staffAppUpdate'
  | 'staffAppUpdateSave'
  | 'staffAppUpdateImage'
  | 'staffPremium'
  | 'staffSetPremiumConfig'
  | 'staffFamilyPremium'
  | 'staffGrantPromo'
  | 'staffRevokeGrant'
  | 'staffAiPolicy'
  | 'staffRenderOps'
  | 'staffFamilyQuota'
  | 'staffRhythm'
  | 'staffRhythmDraft'
  | 'staffRhythmAct'
  | 'staffRhythmRules'
  | 'staffSetRhythmRules'
  | 'sendAuthEmail';

export interface Api {
  call<T>(name: Callable, data?: unknown): Promise<T>;
}

/** `role` = the matrix refused; `not-staff`, `already-claimed`, `already-decided`, … */
export class ApiError extends Error {
  constructor(
    readonly code: string,
    readonly reason: string | null,
  ) {
    super(reason ?? code);
  }
}

export function createApi(functions: Functions): Api {
  return {
    async call<T>(name: Callable, data?: unknown) {
      try {
        const res = await httpsCallable(functions, name)(data ?? {});
        return res.data as T;
      } catch (error) {
        if (error instanceof FirebaseError) {
          const details = (error as FirebaseError & { details?: { reason?: string } }).details;
          throw new ApiError(error.code.replace(/^functions\//, ''), details?.reason ?? null);
        }
        throw new ApiError('unknown', null);
      }
    },
  };
}

export const ApiContext = createContext<Api | null>(null);

export function useApi(): Api {
  const api = useContext(ApiContext);
  if (!api) throw new Error('ApiContext missing');
  return api;
}

export type Load<T> =
  { status: 'loading' } | { status: 'ok'; data: T } | { status: 'error'; error: ApiError };

/** Calls once per `key` and again on `reload()`; keeps the last data while reloading. */
export function useLoad<T>(name: Callable, data: unknown, key: string) {
  const api = useApi();
  const [state, setState] = useState<Load<T>>({ status: 'loading' });
  const [tick, setTick] = useState(0);
  useEffect(() => {
    let live = true;
    api
      .call<T>(name, data)
      .then((d) => live && setState({ status: 'ok', data: d }))
      .catch(
        (e: unknown) =>
          live &&
          setState({
            status: 'error',
            error: e instanceof ApiError ? e : new ApiError('unknown', null),
          }),
      );
    return () => {
      live = false;
    };
    // `data` is described by `key`, so it is not a dependency itself.
  }, [api, name, key, tick]);
  const reload = useCallback(() => setTick((t) => t + 1), []);
  return [state, reload] as const;
}

// ---------- Response shapes (mirrors staff.ts) ----------

export interface Badges {
  tickets: number;
  storage: number;
  jobs: number;
}

export type AlertKind = 'deletionFailed' | 'storagePending' | 'videoQueue' | 'ticketsUnclaimed';
export interface OpsAlert {
  severity: 'error' | 'high' | 'warn' | 'wait';
  module: 'jobs' | 'storage' | 'system' | 'support';
  kind: AlertKind;
  count: number;
}

export interface Overview {
  kpis: {
    activeFamilies: number;
    activeFamiliesPrev: number;
    newAccounts: number;
    newAccountsPrev: number;
    setupRate: number | null;
    multiCarerRate: number | null;
  };
  daily: Array<{ date: string; families: number }>;
  funnel: Array<{ step: string; count: number | null }>;
  weekly: Array<{ weekStart: string; feed: number; sleep: number; diaper: number }>;
  alerts: OpsAlert[];
}

export type TicketStatus = 'new' | 'claimed' | 'waiting' | 'closed';
/** Góp ý (D-065): FB2's "Ý tưởng · Báo lỗi · Khác". */
export type { FeedbackType };

export interface TicketRow {
  id: string;
  ticket: string;
  title: string;
  /** A help topic, or `feedback` (P-145). */
  category: string;
  email: string;
  status: TicketStatus;
  createdAt: string;
  claimedBy: string | null;
  feedbackType: FeedbackType | null;
  /** False for a Góp ý sent without "Cho phép liên hệ lại": nobody may write back. */
  contactable: boolean;
}
export interface TicketList {
  counts: { open: number; new: number; claimed: number; waiting: number };
  rows: TicketRow[];
}
export interface TicketDetail extends TicketRow {
  message: string;
  role: string | null;
  family: { babies: number; people: number; usedBytes: number; quotaBytes: number } | null;
  diagnostics: {
    platform?: string;
    appVersion?: string;
    osVersion?: string;
    deviceModel?: string;
    pendingUploads?: number;
    lastSyncAt?: string | null;
  } | null;
  thread: Array<{ by: string; text: string; at: string }>;
  /** The image comes from `staffTicketScreenshot`; each view is logged. */
  hasScreenshot: boolean;
}

export interface StorageRow {
  id: string;
  code: string;
  family: string;
  babies: number;
  people: number;
  usedBytes: number;
  quotaBytes: number;
  requestedGb: number;
  message: string | null;
  createdAt: string;
  decidedAt: string | null;
  grantedGb: number | null;
  metrics: {
    photoBytes: number;
    videoBytes: number;
    otherBytes: number;
    freeBytes: number;
    previousGrants: number;
    ownerCreatedAt: string | null;
    requesterIsOwner: boolean;
  };
}
export interface StorageList {
  kpis: {
    pending: number;
    oldestAt: string | null;
    over80: number;
    grantedThisMonth: number;
    grantedGbThisMonth: number;
    medianHours: number | null;
  };
  rows: StorageRow[];
}

export type JobType = 'exportCare' | 'exportMedia' | 'deleteBaby' | 'deleteAccount';
export interface JobRow {
  id: string;
  code: string;
  type: JobType;
  email: string;
  createdAt: string;
  progress: number;
  state: string;
  steps?: string[];
  step?: number;
  failedStep?: string | null;
  finishedAt?: string | null;
  expiresAt?: string | null;
  readyAt?: string | null;
  /** P-139: a deletion re-run waiting for a second person. */
  rerunRequest?: { byUid: string; by: string; reason: string; at: string } | null;
}
export interface JobList {
  kpis: {
    running: number;
    runningExports: number;
    failed24h: number;
    medianExportMinutes: number | null;
    deletionsDone: number;
    deletionsTotal: number;
  };
  rows: JobRow[];
}

export interface SystemHealth {
  kpis: { storedBytes: number; over80: number; videosWaiting: number; uploadFailureRate: number };
  histogram: number[];
  families: number;
  videoQueue: number[];
  videoThreshold: number;
  nearQuota: Array<{
    family: string;
    babies: number;
    usedBytes: number;
    quotaBytes: number;
    requested: boolean;
  }>;
}

export interface AiStats {
  kpis: {
    drafts7d: number;
    savedRate: number | null;
    costPerDraftVnd: number | null;
    reports: number;
  };
  outcomes: { editedSaved: number; savedAsIs: number; left: number };
  daily: Array<{ date: string; drafts: number }>;
  budget: { monthlyBudgetVnd: number; month: string; spentVnd: number };
  rollout: Flags[FlagKey];
}

export interface FlagsView {
  flags: Flags;
  limits: Limits;
  lastEdit: Partial<Record<FlagKey, { by: string; at: string }>>;
  recent: Array<{
    action: string;
    target: string;
    by: string;
    at: string;
    reason: string;
    detail: { before?: Flags[FlagKey]; after?: Flags[FlagKey] } | null;
  }>;
}

export interface AuditRow {
  id: string;
  at: string;
  actor: string;
  role: string;
  action: string;
  category: AuditCategory;
  target: string;
  reason: string | null;
  detail: Record<string, unknown> | null;
}

// ---------- QA handbook (P-132, mirrors qa.ts) ----------

export interface QaCase extends QaCaseContent {
  id: string;
  refs: string[];
  /** Ships with the server catalog; `edited` once someone changed it on the portal. */
  builtin: boolean;
  edited: boolean;
  archived: boolean;
  updatedBy: string | null;
  updatedAt: string | null;
}

export interface QaRun {
  id: string;
  name: string;
  environment: QaEnvironment;
  notes: string;
  createdBy: string;
  createdAt: string;
  archived: boolean;
}

export interface QaResult {
  status: QaStatus;
  by: string | null;
  at: string | null;
  comments: number;
}

export interface QaHandbook {
  cases: QaCase[];
  runs: QaRun[];
  runId: string | null;
  results: Record<string, QaResult>;
}

export interface QaComment {
  id: string;
  by: string;
  text: string;
  at: string;
}

// ---------- Nhân sự & phân quyền (P-134, mirrors staff-access.ts) ----------

export interface StaffMe {
  uid: string;
  name: string;
  roles: string[];
  roleNames: string[];
  levels: StaffLevels;
}

export interface StaffMemberRow {
  uid: string;
  name: string;
  email: string;
  roles: string[];
  status: StaffMemberStatus;
  accessUntil: string | null;
  lastSeenAt: string | null;
  createdAt: string | null;
}

export interface StaffRoleRow {
  id: string;
  name: string;
  levels: StaffLevels;
  builtin: boolean;
  locked: boolean;
  members: number;
  updatedBy: string | null;
  updatedAt: string | null;
}

export interface StaffInviteRow {
  id: string;
  email: string;
  name: string;
  roles: string[];
  invitedBy: string;
  expiresAt: string | null;
}

export interface StaffTeam {
  members: StaffMemberRow[];
  invites: StaffInviteRow[];
  roles: StaffRoleRow[];
  kpis: { members: number; sensitive: number; invites: number };
}

// ---------- Gia đình (P-136, mirrors staff-families.ts) ----------

export type FamilyRole = 'coParent' | 'caregiver' | 'relative';

export interface FamilyRow {
  code: string;
  owner: string;
  members: number;
  carers: number;
  pendingInvites: number;
  babies: number;
  usedBytes: number;
  quotaBytes: number;
  platforms: string[];
  lastActiveAt: string | null;
  activity: 'active' | 'low';
}

export interface FamilyList {
  kpis: {
    total: number;
    active: number;
    low: number;
    multiCarerRate: number | null;
    nearFull: number;
  };
  rows: FamilyRow[];
  next: string | null;
}

export interface FamilyDetail {
  code: string;
  createdAt: string | null;
  owner: string;
  platforms: string[];
  usedBytes: number;
  quotaBytes: number;
  expanded: boolean;
  language: string | null;
  lastActiveAt: string | null;
  activity: 'active' | 'low';
  members: Array<{
    uid: string;
    email: string;
    relation: string;
    isOwner: boolean;
    roles: Array<{ baby: number; role: FamilyRole }>;
    lastActiveAt: string | null;
    platform: string | null;
    model: string | null;
    appVersion: string | null;
    eligible: boolean;
  }>;
  invites: Array<{
    relation: string;
    role: FamilyRole;
    state: 'pending' | 'expired';
    createdAt: string | null;
  }>;
  babies: Array<{ ordinal: number; records7d: number; media7d: number; stories: number }>;
  tickets: Array<{
    id: string;
    ticket: string;
    title: string;
    status: string;
    createdAt: string | null;
  }>;
  transfer: {
    id: string;
    to: string;
    ticket: string | null;
    openedBy: string;
    expiresAt: string | null;
  } | null;
}

// ---------- Phân tích (P-137, mirrors analytics.ts) ----------

export type Delta = { value: number | null; change?: number | null; points?: number | null };

export interface AnalyticsGrowth {
  empty: false;
  range: { from: string; to: string };
  days: number;
  kpis: { dau: Delta; wau: Delta; mau: Delta; stickiness: Delta; d30: Delta };
  series: Array<{ date: string; dau: number; wau: number; mau: number }>;
  channels: { invite: number; website: number; store: number };
  platforms: { ios: number; android: number };
  newFamilies: number;
  cohorts: Array<{ week: string; families: number; retention: Array<number | null> }>;
  totalFamilies: number;
}

export interface AnalyticsFeatures {
  empty: false;
  range: { from: string; to: string };
  days: number;
  kpis: { carePerDay: Delta; memoriesPerWeek: Delta; storiesPerWeek: Delta; relativesShare: Delta };
  features: Array<{ feature: string; share: number | null; perDay: number; change: number | null }>;
  storage: {
    usedBytes: number;
    photoBytes: number;
    videoBytes: number;
    otherBytes: number;
    baseFamilies: number;
    expandedFamilies: number;
    over80Families: number;
  };
  versions: Array<{ platform: string; version: string; devices: number }>;
  /** D-065 counters (all platforms); absent from servers older than P-145. */
  feedback?: Record<FeedbackType, number>;
  reviewPrompt?: { eligible: number; requested: number };
  /** Tự lưu kỷ niệm beta counters (D-066, P-148); absent from older servers. */
  autoSave?: AutoSaveCounts;
}

export interface AutoSaveCounts {
  setupStarted: number;
  setupDone: number;
  accessFull: number;
  accessLimited: number;
  accessDenied: number;
  suggested: number;
  approved: number;
  unticked: number;
  rejected: number;
  skipped: number;
  missed: number;
  backgroundChecks: number;
  notified: number;
  turnedOff: number;
  wiped: number;
}

export type AnalyticsResult =
  | { empty: true; range: { from: string; to: string }; days: number }
  | AnalyticsGrowth
  | AnalyticsFeatures;

// ---------- Dữ liệu tham chiếu (P-138, mirrors reference-data.ts) ----------

export interface ReferenceVersion {
  versionId: string;
  label: string | null;
  status: 'draft' | 'pending' | 'published' | 'retired' | 'discarded';
  notes: string;
  source: string;
  author: string;
  authorUid: string;
  approver: string | null;
  createdAt: string | null;
  updatedAt: string | null;
  publishedAt: string | null;
  rejection: { by: string; reason: string } | null;
}

export interface ReferenceView {
  dataset: string;
  current: {
    versionId: string;
    label: string;
    rows: unknown[];
    publishedAt: string | null;
    approver: string | null;
  };
  draft:
    | (ReferenceVersion & {
        rows: unknown[];
        diff: { added: string[]; removed: string[]; changed: string[] };
      })
    | null;
  history: ReferenceVersion[];
}

// ---------- Sơ cứu (D-058, P-141, mirrors content.ts) ----------

export type FirstAidStatus = 'draft' | 'pending' | 'published' | 'retired' | 'discarded';

export interface FirstAidVersion {
  versionId: string;
  status: FirstAidStatus;
  label: string | null;
  notes: string;
  authorName: string;
  approverName: string | null;
  createdAt: string | null;
  updatedAt: string | null;
  approvedAt: string | null;
  rejection: { by: string; reason: string } | null;
  /** Number of situations in the version's pack. */
  situations: number;
}

export interface FirstAidImage {
  id: string;
  url: string;
}

export interface FirstAidView {
  current: { version: string; publishedAt: string; pack: FirstAidPack } | null;
  draft: (FirstAidVersion & { status: 'draft' | 'pending'; pack: FirstAidPack }) | null;
  history: FirstAidVersion[];
  images: FirstAidImage[];
  /** Prod: approving records the medical review (who, when, sources). */
  requireReview: boolean;
}

/** Cập nhật ứng dụng (D-061). */
export interface AppUpdateView {
  current: AppUpdatePublic | null;
  history: Array<{
    version: string;
    publishedAt: string;
    byName: string;
    reason: string;
    config: AppUpdateConfig;
  }>;
  images: FirstAidImage[];
}

// ---------- Premium & Cá nhân hoá (plan §5.6, mirrors premium-staff.ts) ----------

/** `config/entitlements` as the portal sees it: campaign families are family codes (F-XXXX). */
export type StaffPremiumConfig = EntitlementsConfig;

export interface StaffPremiumView {
  config: StaffPremiumConfig;
  /** False while nothing valid is stored: `config` is then the shipped default. */
  stored: boolean;
  /** Which grants count on this server (store sandbox and dev = `test`). */
  environment: GrantEnvironment;
  recent: Array<{ action: string; target: string; by: string; at: string; reason: string }>;
}

// ---------- Nhịp lớn lên (PN01–PN04, mirrors rhythm-content.ts) ----------

export type RhythmStatus = 'draft' | 'pending' | 'published' | 'retired' | 'discarded';
export type RhythmReview = { reviewer: string; credential: string; reviewedOn: string } | null;

/** What the draft of each document holds: the published shape without `version`/`publishedAt`. */
export type ReferenceDraftData = Omit<ReferenceModel, 'version' | 'publishedAt'>;
export type ContentDraftData = Omit<RhythmContent, 'version' | 'publishedAt'>;

export interface RhythmVersion {
  versionId: string;
  status: RhythmStatus;
  /** `ref_YYYYMMDD_NN` / `rc_YYYYMMDD_NN` once published. */
  label: string | null;
  notes: string;
  authorName: string;
  approverName: string | null;
  createdAt: string | null;
  updatedAt: string | null;
  approvedAt: string | null;
  rejection: { by: string; reason: string } | null;
  /** The review recorded at approval (null = not reviewed by a qualified person). */
  review: RhythmReview;
  /** Reference: number of stages. */
  stages?: number;
  /** Content: number of activities and age cards. */
  activities?: number;
  ageCards?: number;
}

export interface RhythmDocView<Current, Data> {
  current: Current | null;
  draft: (RhythmVersion & { status: 'draft' | 'pending'; data: Data }) | null;
  history: RhythmVersion[];
}

export interface RhythmView {
  reference: RhythmDocView<ReferenceModel, ReferenceDraftData>;
  content: RhythmDocView<RhythmContent, ContentDraftData>;
  /** Prod: approving records the qualified review (reviewer, credential, date). */
  requireReview: boolean;
}

/** `staffRhythmRules` (PN04): the thresholds in use, or the shipped default while none is stored. */
export interface RhythmRulesView {
  rules: RhythmRules;
  stored: boolean;
  updatedAt: string | null;
  updatedByName: string | null;
}
