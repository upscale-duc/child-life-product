import { createHash, randomUUID } from 'node:crypto';
import { z } from 'zod';
import { FieldValue, Timestamp, type Firestore, type Transaction } from 'firebase-admin/firestore';
import {
  localDateIn,
  canAdvancePrintOrder,
  initialPrintCatalog,
  printCatalogSchema,
  printDesignSchema,
  printExportRequestSchema,
  printOrderRequestSchema,
  printOrderStatuses,
  printTotals,
  normalizePrintStatus,
  printCancellationReasons,
  printProductSchema,
  type PrintCatalog,
  type PrintDesign,
} from '@child-life/contracts';
import { AccountError } from './account.js';
import { requireStaff, staffAudit, parse, StaffError, type Staff } from './staff.js';
import {
  printArchive,
  printPageCount,
  printPdf,
  printQuality,
  printSlots,
  renderPrintPage,
  type PrintSource,
} from './print-render.js';

const safeId = z.string().regex(/^[A-Za-z0-9_-]{1,100}$/);
export interface PrintStore {
  read(path: string): Promise<Buffer>;
  save(path: string, bytes: Buffer, contentType: string): Promise<void>;
  url(path: string, expires: Date): Promise<string>;
}
function read<T>(schema: z.ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) throw new AccountError('invalid-argument', 'malformed');
  return result.data;
}
async function parent(db: Firestore, uid: string, babyId: string, now: Date, tx?: Transaction) {
  const refs = [db.doc(`babies/${babyId}/members/${uid}`), db.doc(`babies/${babyId}`)];
  const [m, b] = tx ? await tx.getAll(...refs) : await db.getAll(...refs);
  const until = m!.get('accessUntilAt') as Timestamp | undefined;
  if (
    m!.get('role') !== 'coParent' ||
    m!.get('status') !== 'active' ||
    (until && until.toMillis() <= now.getTime())
  )
    throw new AccountError('permission-denied', 'not-allowed');
  if (!b!.exists || b!.get('state') === 'deleting')
    throw new AccountError('failed-precondition', 'deleting');
}
export async function getPrintCatalog(db: Firestore): Promise<PrintCatalog> {
  const doc = await db.doc('publicConfig/printStudio').get();
  if (!doc.exists) return initialPrintCatalog;
  const c = printCatalogSchema.safeParse(doc.data());
  if (!c.success) throw new AccountError('failed-precondition', 'catalog-unavailable');
  return c.data;
}
async function sources(
  db: Firestore,
  store: PrintStore,
  babyId: string,
  d: PrintDesign,
): Promise<PrintSource[]> {
  const required = Array.from({ length: printPageCount(d) }, (_, p) => printSlots(d, p)).flat();
  if (required.some((i) => !d.mediaIds[i]))
    throw new AccountError('failed-precondition', 'photos-missing');
  // Resolve only this baby's ready originals. The request never supplies a Storage path or URL.
  const docs = d.mediaIds.length
    ? await db.getAll(...d.mediaIds.map((id) => db.doc(`babies/${babyId}/media/${id}`)))
    : [];
  let total = 0;
  const out: PrintSource[] = [];
  const cache = new Map<string, PrintSource>();
  for (const doc of docs) {
    const j = doc.data(),
      path = j?.paths?.original;
    if (
      !j ||
      j.status !== 'ready' ||
      j.type !== 'photo' ||
      j.deleted ||
      typeof path !== 'string' ||
      !path.startsWith(`babies/${babyId}/media/${doc.id}/`)
    )
      throw new AccountError('failed-precondition', 'photo-unavailable');
    const cached = cache.get(path);
    if (cached) {
      out.push(cached);
      continue;
    }
    total += Number(j.sizeBytes ?? 0);
    if (total > 150_000_000) throw new AccountError('resource-exhausted', 'too-large');
    const bytes = await store.read(path);
    if (bytes.length > 25_000_000) throw new AccountError('resource-exhausted', 'too-large');
    const sharp = (await import('sharp')).default;
    const meta = await sharp(bytes, { limitInputPixels: 80_000_000 }).metadata();
    const source = {
      bytes,
      width: meta.autoOrient.width ?? meta.width ?? 0,
      height: meta.autoOrient.height ?? meta.height ?? 0,
    };
    cache.set(path, source);
    out.push(source);
  }
  return out;
}
async function render(d: PrintDesign, s: PrintSource[], marks: boolean) {
  const pages: Buffer[] = [];
  for (let p = 0; p < printPageCount(d); p++) pages.push(await renderPrintPage(d, s, p, marks));
  return pages;
}
async function withPrintLease<T>(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  work: () => Promise<T>,
): Promise<T> {
  const req = read(z.object({ babyId: safeId }), data),
    ref = db.doc(`babies/${req.babyId}/printLeases/${randomUUID()}`);
  await db.runTransaction(async (tx) => {
    await parent(db, uid, req.babyId, now, tx);
    tx.create(ref, { expiresAt: new Date(now.getTime() + 6 * 60_000) });
  });
  try {
    return await work();
  } finally {
    await ref.delete();
  }
}
export function exportPrint(
  db: Firestore,
  store: PrintStore,
  uid: string,
  data: unknown,
  now: Date,
) {
  return withPrintLease(db, uid, data, now, () => renderExport(db, store, uid, data, now));
}
async function renderExport(
  db: Firestore,
  store: PrintStore,
  uid: string,
  data: unknown,
  now: Date,
) {
  const req = read(printExportRequestSchema, data);
  await parent(db, uid, req.babyId, now);
  const c = await getPrintCatalog(db);
  if (!c.digitalEnabled) throw new AccountError('failed-precondition', 'export-paused');
  const src = await sources(db, store, req.babyId, req.design);
  const quality = printQuality(req.design, src);
  if (quality.some((dpi) => dpi < 150) && !req.acknowledgeQuality)
    throw new AccountError('failed-precondition', 'low-resolution');
  const pages = await render(req.design, src, req.cropMarks);
  const pdf = req.format === 'pdf',
    ext = pdf ? 'pdf' : 'zip';
  const key = randomUUID(),
    path = `babies/${req.babyId}/printExports/${uid}/${key}.${ext}`;
  const bytes = pdf
    ? await printPdf(pages, req.design, req.cropMarks)
    : await printArchive(pages, req.format as 'jpg' | 'png');
  await parent(db, uid, req.babyId, now);
  await db
    .doc(`printArtifacts/${key}`)
    .set({ babyId: req.babyId, path, expiresAt: new Date(now.getTime() + 86_400_000) });
  await store.save(path, bytes, pdf ? 'application/pdf' : 'application/zip');
  const expires = new Date(now.getTime() + 3_600_000);
  return {
    url: await store.url(path, expires),
    expiresAt: expires.toISOString(),
    pages: pages.length,
    format: ext,
  };
}
export async function savePrintDraft(db: Firestore, uid: string, data: unknown, now: Date) {
  const req = read(z.object({ babyId: safeId, design: printDesignSchema }), data);
  return db.runTransaction(async (tx) => {
    await parent(db, uid, req.babyId, now, tx);
    tx.set(db.doc(`babies/${req.babyId}/printDrafts/${uid}`), {
      design: req.design,
      updatedAt: now,
    });
    return { saved: true };
  });
}
/** Accept the immutable request first. A Firestore worker builds its production files later. */
export async function createPrintOrder(db: Firestore, uid: string, data: unknown, now: Date) {
  const req = read(printOrderRequestSchema, data),
    c = await getPrintCatalog(db);
  const id = `CL${createHash('sha256').update(`${uid}:${req.requestId}`).digest('hex').slice(0, 16).toUpperCase()}`;
  const ref = db.doc(`babies/${req.babyId}/printOrders/${id}`);
  return db.runTransaction(async (tx) => {
    await parent(db, uid, req.babyId, now, tx);
    const [old, current] = await tx.getAll(ref, db.doc('publicConfig/printStudio'));
    if (old!.exists) return { id };
    const live = printCatalogSchema.safeParse(current!.data());
    if (!c.physicalEnabled) throw new AccountError('failed-precondition', 'ordering-unavailable');
    if (
      !live.success ||
      !live.data.physicalEnabled ||
      live.data.version !== req.catalogVersion ||
      live.data.version !== c.version
    )
      throw new AccountError('failed-precondition', 'price-changed');
    if (!c.orderProducts.includes(req.design.product))
      throw new AccountError('failed-precondition', 'product-unavailable');
    if (!c.supportedCountries.includes(req.address.country))
      throw new AccountError('failed-precondition', 'country-unsupported');
    const earliest = localDateIn(
      'Asia/Ho_Chi_Minh',
      new Date(now.getTime() + c.leadDays * 86_400_000),
    );
    if (req.address.neededBy && req.address.neededBy < earliest)
      throw new AccountError('failed-precondition', 'deadline-too-soon');
    let totals;
    try {
      totals = printTotals(c, req.design, req.quantity, req.address.gift);
    } catch {
      throw new AccountError('failed-precondition', 'variant-unavailable');
    }
    const d = req.design,
      required = Array.from({ length: printPageCount(d) }, (_, p) => printSlots(d, p)).flat();
    if (d.mediaIds.some((id) => !id) || required.some((i) => !d.mediaIds[i]))
      throw new AccountError('failed-precondition', 'photos-missing');
    const docs = d.mediaIds.length
      ? await tx.getAll(...d.mediaIds.map((id) => db.doc(`babies/${req.babyId}/media/${id}`)))
      : [];
    const snapshotSources = docs.map((doc) => {
      const j = doc.data(),
        path = j?.paths?.original;
      if (
        !j ||
        j.status !== 'ready' ||
        j.type !== 'photo' ||
        j.deleted ||
        typeof path !== 'string' ||
        !path.startsWith(`babies/${req.babyId}/media/${doc.id}/`)
      )
        throw new AccountError('failed-precondition', 'photo-unavailable');
      return { id: doc.id, path, width: Number(j.width ?? 0), height: Number(j.height ?? 0) };
    });
    if (
      printQuality(
        d,
        snapshotSources.map((s) => ({ ...s, bytes: Buffer.alloc(0) })),
      ).some((dpi) => dpi < 150)
    )
      throw new AccountError('failed-precondition', 'low-resolution');
    const artifactKey = `order-${id}`,
      prefix = `babies/${req.babyId}/printOrders/${id}/`;
    const order = {
      id,
      babyId: req.babyId,
      uid,
      design: d,
      snapshotSources,
      quantity: req.quantity,
      paymentMethod: req.paymentMethod,
      giftWrapFee: req.address.gift ? c.giftWrapFee : 0,
      address: req.address,
      ...totals,
      requestedQuote: { ...totals, pricesEstimated: c.pricesEstimated },
      pricesEstimated: c.pricesEstimated,
      catalogVersion: c.version,
      status: 'pendingConfirmation',
      render: { status: 'queued', attempt: 1, error: null, leaseUntil: null },
      artifact: null,
      artifactKey,
      cancellationReason: null,
      createdAt: now,
      updatedAt: now,
      events: [{ status: 'pendingConfirmation', at: now }],
      reviewed: false,
    };
    tx.create(ref, order);
    tx.create(db.doc(`printOrderOps/${id}`), {
      babyId: req.babyId,
      internalNote: '',
      printPartner: '',
      contacted: false,
      updatedAt: now,
    });
    tx.create(db.doc(`printArtifacts/${artifactKey}`), {
      babyId: req.babyId,
      path: prefix,
      prefix: true,
      expiresAt: null,
    });
    tx.create(db.doc(`printOrderIndex/${id}`), {
      babyId: req.babyId,
      id,
      status: order.status,
      renderStatus: 'queued',
      renderAttempt: 1,
      renderLeaseUntil: null,
      total: totals.total,
      createdAt: now,
      updatedAt: now,
    });
    countDemand(tx, db, now, 'submitted');
    return { id };
  });
}

/** Compare-and-set plus an expiring lease makes delivery and manual retry safe to repeat. */
export async function renderPrintOrder(
  db: Firestore,
  store: PrintStore,
  babyId: string,
  id: string,
  attempt: number,
  now: Date,
) {
  const ref = db.doc(`babies/${babyId}/printOrders/${id}`),
    token = randomUUID(),
    leaseRef = db.doc(`babies/${babyId}/printLeases/${token}`);
  const input = await db
    .runTransaction(async (tx) => {
      const doc = await tx.get(ref);
      if (!doc.exists) {
        tx.delete(db.doc(`printOrderIndex/${id}`));
        return null;
      }
      if (doc.get('status') === 'cancelled') return null;
      const r = doc.get('render');
      if (
        !r ||
        r.attempt !== attempt ||
        r.status === 'ready' ||
        r.status === 'failed' ||
        (r.status === 'rendering' && r.leaseUntil?.toMillis() > now.getTime())
      )
        return null;
      await parent(db, doc.get('uid'), babyId, now, tx);
      const until = new Date(now.getTime() + 6 * 60_000);
      tx.update(ref, {
        'render.status': 'rendering',
        'render.token': token,
        'render.leaseUntil': until,
        'render.error': null,
      });
      tx.update(db.doc(`printOrderIndex/${id}`), {
        renderStatus: 'rendering',
        renderLeaseUntil: until,
      });
      tx.create(leaseRef, { expiresAt: until });
      return doc.data()!;
    })
    .catch(async (error) => {
      if (!(error instanceof AccountError)) throw error;
      await db.runTransaction(async (tx) => {
        const doc = await tx.get(ref);
        if (!doc.exists || doc.get('status') === 'cancelled') return;
        const r = doc.get('render');
        if (r.attempt !== attempt || r.status === 'ready') return;
        tx.update(ref, {
          'render.status': 'failed',
          'render.error': error.reason,
          'render.leaseUntil': null,
        });
        tx.update(db.doc(`printOrderIndex/${id}`), {
          renderStatus: 'failed',
          renderLeaseUntil: null,
        });
      });
      return null;
    });
  if (!input) return;
  try {
    const d = printDesignSchema.parse(input.design),
      src: PrintSource[] = [],
      cache = new Map<string, PrintSource>();
    let sourceBytes = 0;
    for (const source of input.snapshotSources as Array<{ id: string; path: string }>) {
      if (cache.has(source.id)) {
        src.push(cache.get(source.id)!);
        continue;
      }
      const copy = `babies/${babyId}/printOrders/${id}/sources/${source.id}`;
      let bytes: Buffer;
      try {
        bytes = await store.read(copy);
      } catch {
        try {
          bytes = await store.read(source.path);
        } catch (error) {
          const code = (error as { code?: unknown }).code;
          if (
            code === 404 ||
            code === 'storage/object-not-found' ||
            (error as Error).message === 'missing'
          )
            throw new AccountError('failed-precondition', 'photo-unavailable');
          throw error;
        }
        if (bytes.length > 25_000_000) throw new AccountError('resource-exhausted', 'too-large');
        await store.save(copy, bytes, 'application/octet-stream');
      }
      sourceBytes += bytes.length;
      if (bytes.length > 25_000_000 || sourceBytes > 150_000_000)
        throw new AccountError('resource-exhausted', 'too-large');
      const sharp = (await import('sharp')).default,
        meta = await sharp(bytes, { limitInputPixels: 80_000_000 }).metadata();
      const decoded = {
        bytes,
        width: meta.autoOrient.width ?? meta.width ?? 0,
        height: meta.autoOrient.height ?? meta.height ?? 0,
      };
      cache.set(source.id, decoded);
      src.push(decoded);
    }
    if ([...cache.values()].reduce((sum, s) => sum + s.bytes.length, 0) > 150_000_000)
      throw new AccountError('resource-exhausted', 'too-large');
    if (printQuality(d, src).some((dpi) => dpi < 150))
      throw new AccountError('failed-precondition', 'low-resolution');
    const pdf = await printPdf(await render(d, src, false), d, false),
      path = `babies/${babyId}/printOrders/${id}/${token}.pdf`;
    await store.save(path, pdf, 'application/pdf');
    await db.runTransaction(async (tx) => {
      const doc = await tx.get(ref);
      if (!doc.exists || doc.get('status') === 'cancelled' || doc.get('render.token') !== token)
        return;
      await parent(db, input.uid, babyId, new Date(), tx);
      tx.update(ref, {
        artifact: path,
        'render.status': 'ready',
        'render.error': null,
        'render.leaseUntil': null,
      });
      tx.update(db.doc(`printOrderIndex/${id}`), { renderStatus: 'ready', renderLeaseUntil: null });
    });
  } catch (error) {
    const code = error instanceof AccountError ? error.reason : 'render-failed';
    await db.runTransaction(async (tx) => {
      const doc = await tx.get(ref);
      if (!doc.exists || doc.get('status') === 'cancelled' || doc.get('render.token') !== token)
        return;
      tx.update(ref, {
        'render.status': 'failed',
        'render.error': code,
        'render.leaseUntil': null,
      });
      tx.update(db.doc(`printOrderIndex/${id}`), {
        renderStatus: 'failed',
        renderLeaseUntil: null,
      });
    });
  } finally {
    await leaseRef.delete();
  }
}

/** A bounded sweep recovers interrupted workers and events missed during a deployment. */
export async function recoverPrintRenders(db: Firestore, store: PrintStore, now: Date) {
  const started = Date.now();
  const [queued, working] = await Promise.all([
    db.collection('printOrderIndex').where('renderStatus', '==', 'queued').limit(5).get(),
    db.collection('printOrderIndex').where('renderLeaseUntil', '<=', now).limit(20).get(),
  ]);
  for (const doc of [
    ...queued.docs,
    ...working.docs
      .filter((d) => d.get('renderLeaseUntil')?.toMillis() <= now.getTime())
      .slice(0, 5),
  ]) {
    if (Date.now() - started > 200_000) break;
    await renderPrintOrder(
      db,
      store,
      doc.get('babyId'),
      doc.id,
      doc.get('renderAttempt'),
      new Date(now.getTime() + Date.now() - started),
    );
  }
}

function countDemand(tx: Transaction, db: Firestore, now: Date, event: string) {
  const day = localDateIn('Asia/Ho_Chi_Minh', now);
  tx.set(
    db.doc(`printDemandDaily/${day}`),
    { day, [event]: FieldValue.increment(1) },
    { merge: true },
  );
}
export async function recordPrintSignal(db: Firestore, uid: string, data: unknown, now: Date) {
  const req = read(
    z.object({
      requestId: z.string().uuid(),
      event: z.enum(['viewed', 'designStarted']),
      product: printProductSchema,
    }),
    data,
  );
  const key = createHash('sha256').update(`${uid}:${req.requestId}:${req.event}`).digest('hex');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`printDemandEvents/${key}`),
      doc = await tx.get(ref);
    if (doc.exists) return;
    tx.create(ref, {
      event: req.event,
      product: req.product,
      createdAt: now,
      expiresAt: new Date(now.getTime() + 30 * 86_400_000),
    });
    countDemand(tx, db, now, req.event);
  });
  return { recorded: true };
}
export async function cancelPrintOrder(db: Firestore, uid: string, data: unknown, now: Date) {
  const req = read(
    z.object({ babyId: safeId, id: safeId, reason: z.enum(printCancellationReasons) }),
    data,
  );
  return db.runTransaction(async (tx) => {
    await parent(db, uid, req.babyId, now, tx);
    const ref = db.doc(`babies/${req.babyId}/printOrders/${req.id}`),
      doc = await tx.get(ref);
    if (!doc.exists || doc.get('uid') !== uid)
      throw new AccountError('permission-denied', 'not-allowed');
    if (doc.get('status') === 'cancelled') return { cancelled: true };
    if (normalizePrintStatus(doc.get('status')) !== 'pendingConfirmation')
      throw new AccountError('failed-precondition', 'already-processing');
    // The owner can withdraw a request until staff have confirmed it.
    tx.update(ref, {
      status: 'cancelled',
      'render.status': doc.get('render.status') === 'ready' ? 'ready' : 'cancelled',
      cancellationReason: req.reason,
      updatedAt: now,
      events: [...doc.get('events'), { status: 'cancelled', at: now, reason: req.reason }],
    });
    tx.update(db.doc(`printOrderIndex/${req.id}`), {
      status: 'cancelled',
      renderStatus: 'cancelled',
      renderLeaseUntil: null,
      updatedAt: now,
    });
    tx.update(db.doc(`printArtifacts/${doc.get('artifactKey')}`), {
      expiresAt: new Date(now.getTime() + 7 * 86_400_000),
    });
    countDemand(tx, db, now, `cancelled_${req.reason}`);
    return { cancelled: true };
  });
}
export async function staffPrintStudio(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'support.view');
  const docs = await db.collection('printOrderIndex').orderBy('createdAt', 'desc').limit(100).get();
  const reviews = await db
    .collection('printReviews')
    .where('status', '==', 'pending')
    .limit(50)
    .get();
  return {
    reviews: reviews.docs.map((d) => ({
      id: d.id,
      rating: d.get('rating'),
      message: d.get('message'),
      product: d.get('product'),
    })),
    demand: (
      await db.collection('printDemandDaily').orderBy('day', 'desc').limit(30).get()
    ).docs.map((d) => d.data()),
    catalog: await getPrintCatalog(db),
    orders: docs.docs.map((d) => ({
      ...d.data(),
      status: normalizePrintStatus(d.get('status')),
      createdAt: d.get('createdAt').toDate().toISOString(),
    })),
  };
}

export async function staffPrintReview(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'support.reply'),
    req = parse(z.object({ id: safeId, publish: z.boolean() }), data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`printReviews/${req.id}`),
      doc = await tx.get(ref);
    if (!doc.exists) throw new StaffError('not-found', 'not-found');
    tx.update(ref, { status: req.publish ? 'published' : 'rejected' });
    if (req.publish)
      tx.set(db.doc(`printReviewsPublic/${req.id}`), {
        rating: doc.get('rating'),
        message: doc.get('message'),
        product: doc.get('product'),
        createdAt: doc.get('createdAt'),
      });
    else tx.delete(db.doc(`printReviewsPublic/${req.id}`));
    staffAudit(
      tx,
      db,
      s,
      { action: 'print.review', category: 'support', target: req.id, reason: null },
      now,
    );
  });
  return { saved: true };
}
export async function removePrintReview(db: Firestore, uid: string, data: unknown, now: Date) {
  const req = read(z.object({ babyId: safeId, id: safeId }), data);
  await db.runTransaction(async (tx) => {
    await parent(db, uid, req.babyId, now, tx);
    const ref = db.doc(`printReviews/${req.id}`),
      doc = await tx.get(ref);
    if (!doc.exists) return;
    if (doc.get('uid') !== uid || doc.get('babyId') !== req.babyId)
      throw new AccountError('permission-denied', 'not-allowed');
    tx.delete(ref);
    tx.delete(db.doc(`printReviewsPublic/${req.id}`));
    tx.update(db.doc(`babies/${req.babyId}/printOrders/${req.id}`), { reviewed: false });
  });
  return { removed: true };
}
export async function staffPrintCatalog(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'system.video'),
    req = parse(z.object({ catalog: printCatalogSchema }), data);
  await db.runTransaction(async (tx) => {
    const ref = db.doc('publicConfig/printStudio'),
      old = await tx.get(ref);
    if (old.exists && old.get('version') !== req.catalog.version)
      throw new StaffError('failed-precondition', 'stale');
    tx.set(ref, { ...req.catalog, version: req.catalog.version + 1 });
    staffAudit(
      tx,
      db,
      s,
      { action: 'print.catalog', category: 'features', target: 'printStudio', reason: null },
      now,
    );
  });
  return { saved: true };
}
export async function staffPrintOrder(
  db: Firestore,
  store: PrintStore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const req = parse(
    z.object({
      babyId: safeId,
      id: safeId,
      status: z.enum(printOrderStatuses).optional(),
      tracking: z.string().trim().max(100).optional(),
      note: z.string().trim().max(2000).optional(),
      printPartner: z.string().trim().max(120).optional(),
      contacted: z.boolean().optional(),
      reason: z.enum(printCancellationReasons).optional(),
      retryRender: z.boolean().optional(),
      customerConfirmed: z.boolean().optional(),
      quote: z
        .object({
          subtotal: z.number().int().min(0).max(100_000_000),
          shipping: z.number().int().min(0).max(100_000_000),
        })
        .optional(),
    }),
    data,
  );
  const s = requireStaff(staff, 'support.reply'),
    ref = db.doc(`babies/${req.babyId}/printOrders/${req.id}`),
    opsRef = db.doc(`printOrderOps/${req.id}`);
  const mutation =
    req.status !== undefined ||
    req.note !== undefined ||
    req.printPartner !== undefined ||
    req.contacted !== undefined ||
    req.tracking !== undefined ||
    req.retryRender;
  if (mutation)
    await db.runTransaction(async (tx) => {
      const [doc, ops] = await tx.getAll(ref, opsRef);
      if (!doc!.exists) throw new StaffError('not-found', 'not-found');
      const from = normalizePrintStatus(doc!.get('status'));
      const artifact = doc!.get('artifactKey')
        ? await tx.get(db.doc(`printArtifacts/${doc!.get('artifactKey')}`))
        : null;
      if (req.status && !canAdvancePrintOrder(from, req.status))
        throw new StaffError('failed-precondition', 'invalid-transition');
      if (req.status === 'confirmed' && req.customerConfirmed !== true)
        throw new StaffError('failed-precondition', 'customer-confirmation-required');
      if (req.quote && req.status !== 'confirmed')
        throw new StaffError('invalid-argument', 'quote-only-on-confirm');
      if (req.status === 'cancelled' && !req.reason)
        throw new StaffError('invalid-argument', 'cancellation-reason-required');
      if (
        req.status === 'printing' &&
        ((doc!.get('render.status') ?? (doc!.get('artifact') ? 'ready' : 'failed')) !== 'ready' ||
          !artifact?.exists ||
          (artifact.get('expiresAt') && artifact.get('expiresAt').toMillis() <= now.getTime()))
      )
        throw new StaffError('failed-precondition', 'file-not-ready');
      const patch: Record<string, unknown> = { updatedAt: now };
      if (req.status) {
        patch.status = req.status;
        patch.events = [
          ...doc!.get('events'),
          { status: req.status, at: now, ...(req.reason ? { reason: req.reason } : {}) },
        ];
        if (req.status === 'confirmed') {
          if (req.quote) {
            patch.subtotal = req.quote.subtotal;
            patch.shipping = req.quote.shipping;
            patch.total = req.quote.subtotal + req.quote.shipping;
          }
          patch.pricesEstimated = false;
          patch.customerConfirmedAt = now;
        }
        if (req.status === 'cancelled') {
          patch.cancellationReason = req.reason;
          if (doc!.get('render.status') !== 'ready') patch['render.status'] = 'cancelled';
        }
        countDemand(
          tx,
          db,
          now,
          req.status === 'cancelled' ? `cancelled_${req.reason}` : req.status,
        );
      }
      if (req.tracking !== undefined) patch.tracking = req.tracking;
      const index: Record<string, unknown> = {
        updatedAt: now,
        ...(req.status ? { status: req.status } : {}),
      };
      if (req.status === 'cancelled')
        Object.assign(index, { renderStatus: 'cancelled', renderLeaseUntil: null });
      if (req.quote) index.total = req.quote.subtotal + req.quote.shipping;
      if (req.retryRender) {
        const state = doc!.get('render.status'),
          until = doc!.get('render.leaseUntil') as Timestamp | null;
        if (
          from === 'cancelled' ||
          from === 'delivered' ||
          (state !== 'failed' &&
            !(state === 'rendering' && until && until.toMillis() <= now.getTime()))
        )
          throw new StaffError('failed-precondition', 'render-not-retryable');
        const attempt = Number(doc!.get('render.attempt') ?? 0) + 1;
        patch.render = { status: 'queued', attempt, error: null, leaseUntil: null };
        Object.assign(index, {
          renderStatus: 'queued',
          renderAttempt: attempt,
          renderLeaseUntil: null,
        });
      }
      tx.update(ref, patch);
      tx.update(db.doc(`printOrderIndex/${req.id}`), index);
      if (
        req.note !== undefined ||
        req.printPartner !== undefined ||
        req.contacted !== undefined ||
        req.status === 'confirmed'
      )
        tx.set(
          opsRef,
          {
            babyId: req.babyId,
            internalNote: req.note ?? ops!.get('internalNote') ?? '',
            printPartner: req.printPartner ?? ops!.get('printPartner') ?? '',
            contacted:
              req.status === 'confirmed' ? true : (req.contacted ?? ops!.get('contacted') ?? false),
            updatedAt: now,
          },
          { merge: true },
        );
      if ((req.status === 'delivered' || req.status === 'cancelled') && artifact?.exists)
        tx.update(artifact.ref, { expiresAt: new Date(now.getTime() + 7 * 86_400_000) });
      staffAudit(
        tx,
        db,
        s,
        {
          action: req.status
            ? `print.${req.status}`
            : req.retryRender
              ? 'print.render.retry'
              : 'print.ops',
          category: 'support',
          target: req.id,
          reason: null,
        },
        now,
      );
    });
  const [doc, ops] = await db.getAll(ref, opsRef);
  if (!doc!.exists) throw new StaffError('not-found', 'not-found');
  const j = doc!.data()!,
    artifactRecord = j.artifactKey ? await db.doc(`printArtifacts/${j.artifactKey}`).get() : null;
  const expiry = artifactRecord?.get('expiresAt') as Timestamp | null | undefined;
  const available =
    j.artifact && artifactRecord?.exists && (!expiry || expiry.toMillis() > now.getTime());
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    { action: 'print.fulfillment.read', category: 'support', target: req.id, reason: null },
    now,
  );
  await batch.commit();
  return {
    ...j,
    status: normalizePrintStatus(j.status),
    render: j.render
      ? { ...j.render, leaseUntil: j.render.leaseUntil?.toDate().toISOString() ?? null }
      : { status: j.artifact ? 'ready' : 'failed', attempt: 0, error: null, leaseUntil: null },
    internalNote: ops!.get('internalNote') ?? '',
    printPartner: ops!.get('printPartner') ?? '',
    contacted: ops!.get('contacted') ?? false,
    createdAt: j.createdAt.toDate().toISOString(),
    updatedAt: j.updatedAt.toDate().toISOString(),
    events: j.events.map((e: { status: string; at: Timestamp }) => ({
      status: normalizePrintStatus(e.status),
      at: e.at.toDate().toISOString(),
    })),
    fileUrl: available ? await store.url(j.artifact, new Date(now.getTime() + 15 * 60_000)) : null,
  };
}
export async function submitPrintReview(db: Firestore, uid: string, data: unknown, now: Date) {
  const req = read(
    z.object({
      babyId: safeId,
      id: safeId,
      rating: z.number().int().min(1).max(5),
      message: z.string().trim().min(1).max(500),
    }),
    data,
  );
  return db.runTransaction(async (tx) => {
    await parent(db, uid, req.babyId, now, tx);
    const ref = db.doc(`babies/${req.babyId}/printOrders/${req.id}`),
      doc = await tx.get(ref);
    if (doc.get('uid') !== uid || doc.get('status') !== 'delivered')
      throw new AccountError('permission-denied', 'not-delivered');
    if (doc.get('reviewed')) throw new AccountError('failed-precondition', 'already-reviewed');
    tx.create(db.doc(`printReviews/${req.id}`), {
      babyId: req.babyId,
      rating: req.rating,
      message: req.message,
      status: 'pending',
      product: doc.get('design.product'),
      uid,
      createdAt: now,
    });
    tx.update(ref, { reviewed: true });
    return { submitted: true };
  });
}

/** Daily bounded cleanup: temporary exports in 24h; production files 7d after delivery/cancel. */
export async function cleanupPrintArtifacts(
  db: Firestore,
  remove: (path: string, prefix?: boolean) => Promise<void>,
  now: Date,
) {
  const docs = await db.collection('printArtifacts').where('expiresAt', '<=', now).limit(200).get();
  for (const doc of docs.docs) {
    await remove(doc.get('path') as string, doc.get('prefix') === true);
    await doc.ref.delete();
  }
  const events = await db
    .collection('printDemandEvents')
    .where('expiresAt', '<=', now)
    .limit(500)
    .get();
  const batch = db.batch();
  for (const event of events.docs) batch.delete(event.ref);
  if (!events.empty) await batch.commit();
  return docs.size;
}
