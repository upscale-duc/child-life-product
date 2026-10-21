import {
  productAnalyticsRequestSchema,
  type ProductAnalyticsRequest,
  type ProductAnalyticsResult,
  type AnalyticsAgeBand,
  type AnalyticsContext,
  type AnalyticsModule,
  type EngagementKind,
  type EngagementStage,
  type EngagementReasonCode,
} from '@child-life/contracts';
import {
  FieldValue,
  type Firestore,
  type Query,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import { parse, requireStaff, staffAudit, StaffError, type Staff } from './staff.js';
import {
  ANALYTICS_DAY_MS as DAY,
  analyticsCollectionEnabled,
  analyticsDate,
  analyticsHash,
  analyticsTime,
} from './product-analytics-store.js';
import {
  reduceProductAnalytics,
  shiftProductDay,
  type ProductFactRow,
  type ProductAccountRow,
  type ProductCostRow,
  productDayStart,
} from './product-analytics-reducer.js';

const CACHE_MS = 5 * 60_000;
const PAGE_SIZE = 500;
const MAX_ROWS = 200_000;

async function* pages(query: Query) {
  let cursor: QueryDocumentSnapshot | undefined;
  let total = 0;
  for (;;) {
    const q = cursor ? query.startAfter(cursor) : query;
    const page = await q.limit(PAGE_SIZE).get();
    if (page.empty) return;
    total += page.size;
    if (total > MAX_ROWS) throw new Error('analytics-query-budget');
    yield page.docs;
    cursor = page.docs.at(-1);
    if (page.size < PAGE_SIZE) return;
  }
}

const blank = (request: ProductAnalyticsRequest, now: Date): ProductAnalyticsResult => ({
  ...reduceProductAnalytics({
    request,
    facts: [],
    accounts: [],
    costs: [],
    credits: null,
    now,
    sourceStartAt: null,
    collectionEnabled: false,
  }),
  status: 'preparing',
});

/** Staff reads are O(1) snapshot reads, never a scan of user/family operational data per render. */
export async function productAnalytics(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const viewer = requireStaff(staff, 'analytics.view');
  const req = parse(productAnalyticsRequestSchema, data);
  if (req.section === 'cost') requireStaff(staff, 'premium.view');
  const lastClosed = shiftProductDay(analyticsDate(now), -1);
  if (req.to > lastClosed || req.from < shiftProductDay(analyticsDate(now), -400))
    throw new StaffError('invalid-argument', 'malformed');
  const state = await db.doc('productAnalyticsState/current').get();
  const epoch = Number(state.get('privacyEpoch') ?? 0);
  if (Number(state.get('purgesActive') ?? 0) > 0) return blank(req, now);
  const { section: selectedSection, ...query } = req;
  const group = selectedSection === 'cost' ? 'cost' : 'product';
  const key = analyticsHash(
    JSON.stringify({ query, group, epoch, bucket: Math.floor(now.getTime() / CACHE_MS) }),
  );
  const ref = db.doc(`productAnalyticsQueries/${key}`);
  const entry = await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) return existing.data()!;
    const budgetRef = db.doc(
      `productAnalyticsQueryBudgets/${analyticsHash(`${viewer.uid}:${Math.floor(now.getTime() / CACHE_MS)}`)}`,
    );
    const budget = await tx.get(budgetRef);
    const used = Number(budget.get('count') ?? 0);
    if (used >= 20) throw new StaffError('failed-precondition', 'query-limit');
    tx.set(budgetRef, { count: used + 1, expiresAt: new Date(now.getTime() + 2 * DAY) });
    const doc = {
      request: { ...req, section: group === 'cost' ? 'cost' : 'overview' },
      privacyEpoch: epoch,
      state: 'pending',
      createdAt: now,
      expiresAt: new Date(now.getTime() + 2 * DAY),
    };
    tx.create(ref, doc);
    return doc;
  });
  // Always recheck privacy epoch, including a snapshot a worker published during a purge.
  const latest = await db.doc('productAnalyticsState/current').get();
  if (
    Number(latest.get('purgesActive') ?? 0) > 0 ||
    Number(latest.get('privacyEpoch') ?? 0) !== epoch
  )
    return blank(req, now);
  if ('results' in entry && entry.results?.[req.section])
    return entry.results[req.section] as ProductAnalyticsResult;
  return {
    ...blank(req, now),
    ...(entry.state === 'failed' ? { status: 'unavailable' as const } : {}),
  };
}

/** Trigger worker; published snapshots are aggregate-only and fenced on deletions. */
export async function buildProductAnalyticsQuery(db: Firestore, queryId: string, now: Date) {
  const ref = db.doc(`productAnalyticsQueries/${queryId}`);
  const job = await ref.get();
  if (!job.exists || job.get('state') === 'done') return;
  const parsed = productAnalyticsRequestSchema.safeParse(job.get('request'));
  if (!parsed.success) {
    await ref.update({ state: 'failed' });
    return;
  }
  const r = parsed.data;
  const state = await db.doc('productAnalyticsState/current').get();
  const epoch = Number(state.get('privacyEpoch') ?? 0);
  if (epoch !== Number(job.get('privacyEpoch'))) {
    await ref.update({ state: 'failed' });
    return;
  }
  try {
    const n = Math.round((productDayStart(r.to) - productDayStart(r.from)) / DAY) + 1;
    const earliest = shiftProductDay(r.from, -Math.max(n, 30));
    const since = new Date(Math.max(productDayStart(earliest), now.getTime() - 400 * DAY));
    const staffRows = await db.collection('staffMembers').select('status').get();
    const excludedStaff = new Set(staffRows.docs.map((d) => d.id));
    const facts: ProductFactRow[] = [];
    if (r.section !== 'cost') {
      for await (const rows of pages(
        db
          .collection('productAnalyticsFacts')
          .where('at', '>=', since)
          .where('at', '<', new Date(productDayStart(analyticsDate(now))))
          .orderBy('at'),
      )) {
        for (const d of rows) {
          const f = d.data();
          if (typeof f.uid === 'string' && excludedStaff.has(f.uid)) continue;
          facts.push({
            event: String(f.event),
            day: String(f.day),
            at: analyticsTime(f.at),
            receivedAt: analyticsTime(f.receivedAt),
            uid: typeof f.uid === 'string' ? f.uid : null,
            familyId: typeof f.familyId === 'string' ? f.familyId : null,
            module: f.module as AnalyticsModule | null,
            platform: String(f.platform ?? 'unknown'),
            locale: String(f.locale ?? 'unknown'),
            context: f.context as AnalyticsContext,
            ageBand: f.ageBand as AnalyticsAgeBand,
            kind: f.kind as EngagementKind | null,
            stage: f.stage as EngagementStage | null,
            opportunity: f.opportunity as string | null,
            template: f.template as string | null,
            meaningful: f.meaningful === true,
            windowClosesAt: analyticsTime(f.windowClosesAt) || null,
            reason: (f.reason ?? 'none') as EngagementReasonCode,
          });
        }
      }
    }
    const accounts: ProductAccountRow[] = [];
    if (r.section !== 'cost') {
      for await (const rows of pages(
        db
          .collection('productAnalyticsAccounts')
          .where('registeredAt', '>=', since)
          .orderBy('registeredAt'),
      )) {
        for (const d of rows)
          if (!excludedStaff.has(d.id))
            accounts.push({
              uid: d.id,
              registeredAt: analyticsTime(d.get('registeredAt')),
              registrationVerified: d.get('registrationVerified') === true,
              ageBand: d.get('ageBand') as AnalyticsAgeBand,
              locale: String(d.get('locale') ?? 'unknown'),
              primaryContextAt: analyticsTime(d.get('primaryContextAt')) || null,
              creator: d.get('creator') === true,
            });
      }
    }
    const costs: ProductCostRow[] = [];
    // Active accounts can predate the query window. Join only referenced private profiles,
    // otherwise an older active user's onboarding age band silently becomes unknown.
    if (r.section !== 'cost') {
      const loaded = new Set(accounts.map((p) => p.uid));
      const missing = [
        ...new Set(facts.flatMap((f) => (f.uid && !loaded.has(f.uid) ? [f.uid] : []))),
      ];
      for (let offset = 0; offset < missing.length; offset += 200) {
        const rows = await db.getAll(
          ...missing
            .slice(offset, offset + 200)
            .map((uid) => db.doc(`productAnalyticsAccounts/${uid}`)),
        );
        for (const d of rows)
          if (d.exists)
            accounts.push({
              uid: d.id,
              registeredAt: analyticsTime(d.get('registeredAt')),
              registrationVerified: d.get('registrationVerified') === true,
              ageBand: d.get('ageBand') as AnalyticsAgeBand,
              locale: String(d.get('locale') ?? 'unknown'),
              primaryContextAt: analyticsTime(d.get('primaryContextAt')) || null,
              creator: d.get('creator') === true,
            });
      }
    }
    let credits: number | null = null;
    if (r.section === 'cost') {
      const snapshots = await db
        .collection('aiUsageDaily')
        .where('day', '>=', r.from)
        .where('day', '<=', r.to)
        .get();
      for (const doc of snapshots.docs)
        costs.push(
          Object.fromEntries(
            [
              'calls',
              'knownUsage',
              'unknownUsage',
              'inputTokens',
              'outputTokens',
              'cachedInputTokens',
              'knownCachedUsage',
              'ratedCalls',
              'estimatedCostUsdMicros',
            ].map((key) => [key, Number(doc.get(key) ?? 0)]),
          ) as unknown as ProductCostRow,
        );
      // Ledger units, never guessed from calls or token usage. Filter committed timestamp.
      let committed = 0,
        any = false;
      for await (const rows of pages(
        db
          .collectionGroup('quotaOps')
          .where('committedAt', '>=', new Date(productDayStart(r.from)))
          .where('committedAt', '<', new Date(productDayStart(shiftProductDay(r.to, 1))))
          .orderBy('committedAt'),
      )) {
        for (const d of rows)
          if (d.get('feature') === 'assistant' && d.get('state') === 'committed') {
            committed += Number(d.get('units') ?? 0);
            any = true;
          }
      }
      credits = any ? committed : null;
    }
    const enabled = await analyticsCollectionEnabled(db);
    const sections: ProductAnalyticsRequest['section'][] =
      r.section === 'cost'
        ? ['cost']
        : ['overview', 'acquisition', 'memories', 'engagement', 'features'];
    const results = Object.fromEntries(
      sections.map((section) => [
        section,
        reduceProductAnalytics({
          request: { ...r, section },
          facts,
          accounts,
          costs,
          credits,
          now,
          sourceStartAt: analyticsTime(state.get('sourceStartAt'))
            ? new Date(analyticsTime(state.get('sourceStartAt')))
            : null,
          collectionEnabled: enabled,
        }),
      ]),
    );
    await db.runTransaction(async (tx) => {
      const live = await tx.get(db.doc('productAnalyticsState/current'));
      if (
        Number(live.get('purgesActive') ?? 0) > 0 ||
        Number(live.get('privacyEpoch') ?? 0) !== epoch
      ) {
        tx.update(ref, { state: 'failed' });
        return;
      }
      tx.update(ref, { state: 'done', results, computedAt: now });
    });
  } catch {
    // Only a fixed coarse failure code; never log query rows, identities or payloads.
    await ref.update({ state: 'failed', failure: 'source-or-budget-unavailable' });
  }
}

export async function exportProductAnalytics(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'analytics.export');
  const request = parse(productAnalyticsRequestSchema, data);
  const result = await productAnalytics(db, staff, data, now);
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'analytics.export',
      category: 'analytics',
      target: `v2:${request.section}:${request.from}:${request.to}`,
      reason: null,
    },
    now,
  );
  await batch.commit();
  return result;
}

/** Registration clocks and privacy fences have the same cleanup discipline as source observations. */
export async function invalidateProductAnalytics(db: Firestore) {
  await db
    .doc('productAnalyticsState/current')
    .set({ privacyEpoch: FieldValue.increment(1) }, { merge: true });
}
