import type { FlagKey, Flags, Limits } from '@child-life/contracts';
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
  | 'staffExportAudit';

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
export interface TicketRow {
  id: string;
  ticket: string;
  title: string;
  category: string;
  email: string;
  status: TicketStatus;
  createdAt: string;
  claimedBy: string | null;
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
  category: 'support' | 'storage' | 'data' | 'features';
  target: string;
  reason: string | null;
  detail: Record<string, unknown> | null;
}
