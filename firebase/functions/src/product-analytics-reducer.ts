import {
  analyticsModules,
  engagementKinds,
  engagementStages,
  type ProductAnalyticsResult,
  type ProductAnalyticsRequest,
  type ProductMetric,
  type AnalyticsAgeBand,
  type AnalyticsContext,
  type AnalyticsModule,
  type EngagementKind,
  type EngagementStage,
  type EngagementReasonCode,
} from '@child-life/contracts';
import {
  ANALYTICS_DAY_MS as DAY,
  ANALYTICS_ZONE,
  analyticsDate,
} from './product-analytics-store.js';

export interface ProductFactRow {
  event: string;
  day: string;
  at: number;
  receivedAt: number;
  uid: string | null;
  familyId: string | null;
  module: AnalyticsModule | null;
  platform: string;
  locale: string;
  context: AnalyticsContext;
  ageBand: AnalyticsAgeBand;
  kind: EngagementKind | null;
  stage: EngagementStage | null;
  opportunity: string | null;
  template: string | null;
  meaningful: boolean;
  windowClosesAt: number | null;
  reason: EngagementReasonCode;
}
export interface ProductAccountRow {
  uid: string;
  registeredAt: number;
  registrationVerified: boolean;
  ageBand: AnalyticsAgeBand;
  locale: string;
  primaryContextAt: number | null;
  creator: boolean;
}
export interface ProductCostRow {
  calls: number;
  knownUsage: number;
  unknownUsage: number;
  inputTokens: number;
  outputTokens: number;
  cachedInputTokens: number;
  knownCachedUsage?: number;
  ratedCalls: number;
  estimatedCostUsdMicros: number;
}
export const productDayStart = (day: string) => Date.parse(`${day}T00:00:00+07:00`);
export const shiftProductDay = (day: string, n: number) =>
  analyticsDate(new Date(productDayStart(day) + n * DAY));
const unique = <T>(xs: T[], select: (x: T) => string | null) =>
  new Set(xs.map(select).filter((x): x is string => !!x));

/** Exact unions only. Nothing in this result contains an operational identity or content. */
export function reduceProductAnalytics(input: {
  request: ProductAnalyticsRequest;
  facts: ProductFactRow[];
  accounts: ProductAccountRow[];
  costs: ProductCostRow[];
  credits: number | null;
  now: Date;
  sourceStartAt: Date | null;
  collectionEnabled: boolean;
  threshold?: number;
}): ProductAnalyticsResult {
  const { request: r, now } = input;
  const threshold = Math.max(20, input.threshold ?? 20);
  const from = productDayStart(r.from),
    end = productDayStart(shiftProductDay(r.to, 1));
  const days = Math.round((end - from) / DAY);
  const profiles = new Map(input.accounts.map((p) => [p.uid, p]));
  const unsupported = r.chapter === 'chapter01' ? ['chapter'] : [];
  const filtered = input.facts.filter(
    (f) =>
      (r.platform === 'all' || f.platform === r.platform) &&
      (r.locale === 'all' || f.locale === r.locale) &&
      (r.context === 'all' || f.context === r.context) &&
      (r.ageBand === 'all' || (f.uid ? profiles.get(f.uid)?.ageBand : f.ageBand) === r.ageBand),
  );
  const period = (start: number, stop: number) =>
    filtered.filter((f) => f.at >= start && f.at < stop);
  const current = period(from, end),
    previous = period(from - days * DAY, from);
  const activity = (fs: ProductFactRow[]) =>
    fs.filter((f) => f.event === 'app_foreground_observed');
  const familyActivity = (fs: ProductFactRow[]) =>
    fs.filter(
      (f) =>
        f.familyId &&
        (f.meaningful ||
          f.event === 'family_context_viewed' ||
          f.event === 'family_content_viewed' ||
          f.event === 'photo_review_opened' ||
          f.event === 'memory_story_started'),
    );
  const users = (fs: ProductFactRow[]) => unique(activity(fs), (f) => f.uid).size;
  const families = (fs: ProductFactRow[]) => unique(familyActivity(fs), (f) => f.familyId).size;
  const covered = !!input.sourceStartAt && analyticsDate(input.sourceStartAt) <= r.from;
  const previousCovered =
    !!input.sourceStartAt && input.sourceStartAt.getTime() <= from - days * DAY;
  const mature = end + 3 * DAY <= now.getTime();
  const hasSource = input.sourceStartAt !== null;
  const metrics: ProductMetric[] = [];
  function metric(
    id: string,
    value: number | null,
    unit: ProductMetric['unit'],
    population: number,
    options: Partial<ProductMetric> = {},
  ): ProductMetric {
    const status: ProductMetric['status'] = unsupported.length
      ? 'unavailable'
      : !hasSource
        ? 'no_data'
        : population === 0
          ? 'no_data'
          : value === null
            ? 'unavailable'
            : population < threshold
              ? 'insufficient'
              : mature
                ? 'ready'
                : 'provisional';
    const result: ProductMetric = {
      id,
      unit,
      value:
        status === 'insufficient' || status === 'no_data' || status === 'unavailable'
          ? null
          : value,
      numerator: null,
      denominator: null,
      status,
      reason: unsupported.length
        ? 'unsupported_filter'
        : status === 'insufficient'
          ? 'small_cohort'
          : value === null
            ? 'not_instrumented'
            : 'none',
      windowDays: days,
      previous: null,
      ...options,
    };
    if (
      population > 0 &&
      population < threshold &&
      !['unavailable', 'immature'].includes(result.status)
    ) {
      result.status = 'insufficient';
      result.reason = 'small_cohort';
    }
    if (unsupported.length) {
      result.status = 'unavailable';
      result.reason = 'unsupported_filter';
    }
    if (
      result.status === 'insufficient' ||
      result.status === 'unavailable' ||
      result.status === 'immature' ||
      result.status === 'no_data'
    ) {
      result.value = null;
      result.numerator = null;
      result.denominator = null;
      result.previous = null;
    }
    return result;
  }
  function count(
    id: string,
    value: number,
    unit: ProductMetric['unit'],
    pop: number,
    prev?: number,
    opts: Partial<ProductMetric> = {},
  ) {
    const m = metric(id, value, unit, pop, opts);
    if (
      r.comparison &&
      prev !== undefined &&
      prev >= threshold &&
      previousCovered &&
      m.value !== null
    )
      m.previous = prev;
    metrics.push(m);
    return m;
  }
  function unavailable(
    id: string,
    unit: ProductMetric['unit'],
    reason: ProductMetric['reason'] = 'not_instrumented',
  ) {
    metrics.push(metric(id, null, unit, 0, { status: 'unavailable', reason }));
  }
  const selectedAccounts = input.accounts
    .filter((p) => p.registrationVerified)
    .filter(
      (p) =>
        (r.locale === 'all' || p.locale === r.locale) &&
        (r.ageBand === 'all' || p.ageBand === r.ageBand),
    );
  const registrations = selectedAccounts.filter(
    (p) => p.registeredAt >= from && p.registeredAt < end,
  );
  const oldRegistrations = selectedAccounts.filter(
    (p) => p.registeredAt >= from - days * DAY && p.registeredAt < from,
  );
  const accountFiltersSupported =
    r.platform === 'all' && r.context === 'all' && !unsupported.length;
  if (accountFiltersSupported && hasSource)
    count(
      'A01',
      registrations.length,
      'users',
      registrations.length,
      oldRegistrations.length,
      !covered ? { status: 'provisional', reason: 'history_unavailable' } : {},
    );
  else
    unavailable(
      'A01',
      'users',
      accountFiltersSupported ? 'history_unavailable' : 'unsupported_filter',
    );
  count('A02', users(current), 'users', users(current), users(previous));
  count('A03', families(current), 'families', families(current), families(previous));
  for (const n of [1, 7, 30]) {
    const fs = period(end - n * DAY, end);
    count(`A02_${n}`, users(fs), 'users', users(fs), undefined, { windowDays: n });
  }

  const cohort = registrations.filter((p) => p.registeredAt + 10 * DAY <= now.getTime());
  const outcomesByUser = new Map<string, ProductFactRow[]>();
  const foregroundDays = new Map<string, Set<string>>();
  for (const f of filtered)
    if (f.uid) {
      if (f.meaningful || f.event === 'family_content_viewed') {
        const rows = outcomesByUser.get(f.uid) ?? [];
        rows.push(f);
        outcomesByUser.set(f.uid, rows);
      }
      if (f.event === 'app_foreground_observed') {
        const ds = foregroundDays.get(f.uid) ?? new Set<string>();
        ds.add(f.day);
        foregroundDays.set(f.uid, ds);
      }
    }
  const confirmed = (p: ProductAccountRow) =>
    (outcomesByUser.get(p.uid) ?? []).filter(
      (f) => f.at >= p.registeredAt && f.at < p.registeredAt + 7 * DAY,
    );
  const activated = cohort.filter((p) => confirmed(p).length > 0);
  const missingOutcomeActors = filtered.some(
    (f) => f.meaningful && !f.uid && f.at >= from && f.at < end + 7 * DAY,
  );
  if (accountFiltersSupported && hasSource) {
    const c = cohort.length;
    metrics.push(
      metric('A08', c ? activated.length / c : null, 'users', c, {
        numerator: activated.length,
        denominator: c,
        windowDays: 7,
        ...(missingOutcomeActors
          ? { status: 'unavailable' as const, reason: 'no_source' as const }
          : {}),
        ...(registrations.length > 0 && c === 0
          ? { status: 'immature' as const, reason: 'window_open' as const }
          : {}),
      }),
    );
    const creators = cohort.filter((p) => p.creator);
    const firstMemory = creators.filter((p) =>
      confirmed(p).some((f) => f.event === 'memory_ready'),
    );
    metrics.push(
      metric(
        'A10',
        creators.length ? firstMemory.length / creators.length : null,
        'users',
        creators.length,
        {
          numerator: firstMemory.length,
          denominator: creators.length,
          windowDays: 7,
          ...(missingOutcomeActors
            ? { status: 'unavailable' as const, reason: 'no_source' as const }
            : {}),
        },
      ),
    );
  } else {
    unavailable('A08', 'users', 'unsupported_filter');
    unavailable('A10', 'users', 'unsupported_filter');
  }
  // Last fully closed ISO week, independent of the dashboard range length.
  const dow = new Date(`${r.to}T00:00:00Z`).getUTCDay();
  const weekEnd = dow === 0 ? end : productDayStart(shiftProductDay(r.to, -((dow + 6) % 7)));
  const meaningful = period(weekEnd - 7 * DAY, weekEnd).filter((f) => f.meaningful);
  const wmf = unique(meaningful, (f) => f.familyId).size;
  count('A11', wmf, 'families', families(period(weekEnd - 7 * DAY, weekEnd)), undefined, {
    windowDays: 7,
  });

  function retentionMetric(ps: ProductAccountRow[], n: number): ProductMetric {
    const eligible = ps.filter(
      (p) =>
        productDayStart(shiftProductDay(analyticsDate(new Date(p.registeredAt)), n + 1)) +
          3 * DAY <=
        now.getTime(),
    );
    const retained = eligible.filter((p) =>
      foregroundDays.get(p.uid)?.has(shiftProductDay(analyticsDate(new Date(p.registeredAt)), n)),
    );
    if (!accountFiltersSupported || !hasSource)
      return metric(`A05_${n}`, null, 'users', 0, {
        status: 'unavailable',
        reason: !accountFiltersSupported ? 'unsupported_filter' : 'history_unavailable',
      });
    if (ps.length && !eligible.length)
      return metric(`A05_${n}`, null, 'users', 0, {
        status: 'immature',
        reason: 'window_open',
        windowDays: n,
      });
    return metric(
      `A05_${n}`,
      eligible.length ? retained.length / eligible.length : null,
      'users',
      eligible.length,
      { numerator: retained.length, denominator: eligible.length, windowDays: n },
    );
  }
  const retention: ProductAnalyticsResult['retention'] = [];
  for (let i = 0; i < days; i++) {
    const day = shiftProductDay(r.from, i);
    const ps = registrations.filter((p) => analyticsDate(new Date(p.registeredAt)) === day);
    retention.push({
      day,
      users: ps.length >= threshold ? ps.length : null,
      d1: retentionMetric(ps, 1),
      d7: retentionMetric(ps, 7),
      d30: retentionMetric(ps, 30),
    });
  }
  for (const n of [1, 7, 30]) metrics.push(retentionMetric(registrations, n));

  const sourceFamilies = unique(current, (f) => f.familyId).size;
  const outcomeIds: Array<[string, string]> = [
    ['M_ready', 'memory_ready'],
    ['M_story', 'story_saved'],
    ['M_card', 'card_filed'],
    ['M_video', 'video_filed'],
    ['M_rendered', 'video_rendered'],
    ['M_render_failed', 'video_failed'],
    ['M_upload', 'memory_upload_requested'],
    ['M_review', 'photo_review_opened'],
    ['M_video_requested', 'video_requested'],
    ['M_share', 'memory_story_share_sheet_opened'],
  ];
  for (const [id, event] of outcomeIds) {
    if (r.platform !== 'all' || r.locale !== 'all') {
      unavailable(id, 'actions', 'unsupported_filter');
      continue;
    }
    count(id, current.filter((f) => f.event === event).length, 'actions', sourceFamilies);
  }
  for (const id of ['M_discovered', 'M_approved', 'M_cloud_conversion'])
    unavailable(id, 'opportunities');
  const moduleRows = analyticsModules.map((module) => {
    const fs = current.filter(
      (f) =>
        f.module === module &&
        (f.meaningful || ['family_content_viewed', 'lumi_answer_viewed'].includes(f.event)),
    );
    const n = unique(fs, (f) => f.familyId).size;
    return {
      dimension: 'module' as const,
      key: module,
      count: n >= threshold && !unsupported.length ? n : null,
    };
  });
  const familyActors = new Map<string, Set<string>>();
  const familyModules = new Map<string, Set<string>>();
  for (const f of current)
    if (f.familyId && (f.meaningful || f.event === 'family_content_viewed')) {
      if (f.uid) {
        const actors = familyActors.get(f.familyId) ?? new Set<string>();
        actors.add(f.uid);
        familyActors.set(f.familyId, actors);
      }
      if (f.module) {
        const modules = familyModules.get(f.familyId) ?? new Set<string>();
        modules.add(f.module);
        familyModules.set(f.familyId, modules);
      }
    }
  count(
    'F02',
    [...familyModules.values()].filter((set) => set.size >= 2).length,
    'families',
    sourceFamilies,
  );
  count(
    'F04',
    [...familyActors.values()].filter((set) => set.size >= 2).length,
    'families',
    sourceFamilies,
  );
  const templateMap = new Map<string, Set<string>>();
  for (const f of current.filter(
    (f) => f.template && ['video_filed', 'card_filed'].includes(f.event),
  )) {
    const set = templateMap.get(f.template!) ?? new Set<string>();
    if (f.familyId) set.add(f.familyId);
    templateMap.set(f.template!, set);
  }
  const breakdowns: ProductAnalyticsResult['breakdowns'] = [...moduleRows];
  for (const [key, fs] of templateMap)
    if (fs.size >= threshold) breakdowns.push({ dimension: 'template', key, count: fs.size });
  for (const dimension of ['platform', 'locale', 'ageBand'] as const) {
    const map = new Map<string, Set<string>>();
    for (const f of activity(current))
      if (f.uid) {
        const key =
          dimension === 'ageBand' ? (profiles.get(f.uid)?.ageBand ?? 'unknown') : f[dimension];
        const set = map.get(key) ?? new Set<string>();
        set.add(f.uid);
        map.set(key, set);
      }
    // No totals/remaining cells published beside suppressed slices (subtraction guardrail).
    if ([...map.values()].every((set) => set.size >= threshold))
      for (const [key, set] of map) breakdowns.push({ dimension, key, count: set.size });
  }
  const engagement = engagementKinds.map((kind) => {
    const eligible = current.filter(
      (f) => f.kind === kind && f.stage === 'eligible' && f.opportunity,
    );
    const byOpportunity = new Map(eligible.map((f) => [f.opportunity!, f]));
    const fs = filtered.filter((f) => {
      const e = f.opportunity ? byOpportunity.get(f.opportunity) : null;
      return (
        e && f.kind === kind && f.at >= e.at && (!e.windowClosesAt || f.at <= e.windowClosesAt)
      );
    });
    const recipients = unique(eligible, (f) => f.uid).size;
    const stages = Object.fromEntries(
      engagementStages.map((stage) => [
        stage,
        recipients >= threshold && !unsupported.length
          ? unique(
              fs.filter((f) => f.stage === stage),
              (f) => f.opportunity,
            ).size
          : null,
      ]),
    ) as Record<EngagementStage, number | null>;
    const measurable = eligible.filter((e) => e.windowClosesAt !== null);
    const matured = measurable.filter((e) => e.windowClosesAt! + 3 * DAY <= now.getTime());
    const matureKeys = new Set(matured.map((e) => e.opportunity!));
    const completed = unique(
      fs.filter((f) => f.stage === 'completed' && f.opportunity && matureKeys.has(f.opportunity)),
      (f) => f.opportunity,
    ).size;
    let conversion: ProductMetric;
    if (!measurable.length)
      conversion = metric(`E_${kind}`, null, 'opportunities', 0, {
        status: 'unavailable',
        reason: 'not_instrumented',
      });
    else if (!matured.length)
      conversion = metric(`E_${kind}`, null, 'opportunities', 0, {
        status: 'immature',
        reason: 'window_open',
      });
    else
      conversion = metric(
        `E_${kind}`,
        completed / matured.length,
        'opportunities',
        unique(matured, (f) => f.uid).size,
        {
          numerator: completed,
          denominator: matured.length,
          windowDays: kind === 'ENG-04' ? 1 : kind === 'ENG-02' ? null : 7,
        },
      );
    if (from < productDayStart(analyticsDate(new Date(now.getTime() - 30 * DAY)))) {
      conversion = metric(`E_${kind}`, null, 'opportunities', 0, {
        status: 'unavailable',
        reason: 'history_unavailable',
      });
      for (const stage of engagementStages) stages[stage] = null;
    }
    metrics.push(conversion);
    const reasonsMap = new Map<EngagementReasonCode, Set<string>>();
    for (const f of fs)
      if (f.reason !== 'none' && f.opportunity) {
        const set = reasonsMap.get(f.reason) ?? new Set<string>();
        set.add(f.opportunity);
        reasonsMap.set(f.reason, set);
      }
    const reasons =
      recipients >= threshold &&
      !unsupported.length &&
      from >= productDayStart(analyticsDate(new Date(now.getTime() - 30 * DAY)))
        ? [...reasonsMap].map(([reason, ids]) => ({ reason, count: ids.size }))
        : [];
    return { kind, stages, conversion, reasons };
  });
  const rowsByDay = new Map<string, ProductFactRow[]>();
  for (const f of current) {
    const rows = rowsByDay.get(f.day) ?? [];
    rows.push(f);
    rowsByDay.set(f.day, rows);
  }
  const series: ProductAnalyticsResult['series'] = Array.from({ length: days }, (_, i) => {
    const day = shiftProductDay(r.from, i),
      fs = rowsByDay.get(day) ?? [];
    const u = users(fs),
      f = families(fs);
    return {
      day,
      users: u >= threshold && !unsupported.length ? u : null,
      families: f >= threshold && !unsupported.length ? f : null,
      actions: f >= threshold && !unsupported.length ? fs.filter((x) => x.meaningful).length : null,
    };
  });

  if (r.section === 'cost') {
    metrics.length = 0;
    const supported =
      r.platform === 'all' &&
      r.locale === 'all' &&
      r.ageBand === 'all' &&
      r.context === 'all' &&
      !unsupported.length;
    const sum = (key: keyof ProductCostRow) =>
      input.costs.reduce((n, row) => n + (row[key] ?? 0), 0);
    const calls = sum('calls');
    const cost = (id: string, value: number | null, unit: ProductMetric['unit']) => {
      const available =
        supported &&
        value !== null &&
        (id === 'C_credits' ? input.credits !== null : input.costs.length > 0);
      metrics.push({
        id,
        unit,
        value: available ? value : null,
        numerator: null,
        denominator: null,
        status: !supported ? 'unavailable' : available ? 'ready' : 'unavailable',
        reason: !supported ? 'unsupported_filter' : available ? 'none' : 'no_source',
        windowDays: days,
        previous: null,
      });
    };
    cost('C_calls', calls, 'calls');
    cost('C_input', sum('knownUsage') > 0 ? sum('inputTokens') : null, 'tokens');
    cost('C_output', sum('knownUsage') > 0 ? sum('outputTokens') : null, 'tokens');
    cost(
      'C_cached',
      calls > 0 && sum('knownCachedUsage') === calls ? sum('cachedInputTokens') : null,
      'tokens',
    );
    cost('C_unknown', sum('unknownUsage'), 'calls');
    cost('C_rated', sum('ratedCalls'), 'calls');
    cost(
      'C_estimate',
      sum('ratedCalls') > 0 ? sum('estimatedCostUsdMicros') / 1_000_000 : null,
      'usd',
    );
    cost('C_actual', null, 'usd');
    cost('C_render', null, 'usd');
    cost('C_storage', null, 'usd');
    cost('C_credits', input.credits, 'credits');
  }
  // Section-specific projection: the payload remains aggregate, small and useful to the view.
  const sectionIds: Record<ProductAnalyticsRequest['section'], (id: string) => boolean> = {
    overview: (id) => ['A01', 'A02', 'A03', 'A08', 'A10', 'A11'].includes(id),
    acquisition: (id) => id.startsWith('A') && id !== 'A11',
    memories: (id) => id.startsWith('M'),
    engagement: (id) => id.startsWith('E'),
    features: (id) => ['A03', 'A11', 'F02', 'F04'].includes(id),
    cost: (id) => id.startsWith('C'),
  };
  const latest = input.facts.reduce((max, f) => Math.max(max, f.receivedAt), 0);
  return {
    schemaVersion: 2,
    definitionVersion: 1,
    section: r.section,
    range: { from: r.from, to: r.to },
    reportingZone: ANALYTICS_ZONE,
    status:
      current.length ||
      registrations.length ||
      input.costs.length ||
      input.credits !== null ||
      metrics.some((m) => m.value !== null)
        ? 'ready'
        : hasSource
          ? 'no_data'
          : input.collectionEnabled
            ? 'no_data'
            : 'disabled',
    computedAt: now.toISOString(),
    observedThrough: latest ? new Date(latest).toISOString() : null,
    sourceStartAt: input.sourceStartAt?.toISOString() ?? null,
    collectionEnabled: input.collectionEnabled,
    stale: false,
    privacyThreshold: threshold,
    unsupportedFilters: unsupported,
    metrics: metrics.filter((m) => sectionIds[r.section](m.id)),
    series,
    retention: r.section === 'acquisition' ? retention : [],
    breakdowns: unsupported.length ? [] : breakdowns,
    engagement: r.section === 'engagement' ? engagement : [],
    quality: {
      unknownActor:
        sourceFamilies >= threshold ? current.filter((f) => f.meaningful && !f.uid).length : null,
      lateObservations:
        sourceFamilies >= threshold
          ? current.filter((f) => f.receivedAt - f.at > 3 * DAY).length
          : null,
      sourceCoverage: covered ? 'partial' : 'none',
    },
  };
}
