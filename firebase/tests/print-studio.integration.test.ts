import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { randomUUID } from 'node:crypto';
import { beforeAll, beforeEach, afterAll, describe, it, expect } from 'vitest';
import sharp from 'sharp';
import { initialPrintCatalog, printDesignSchema } from '@child-life/contracts';
import {
  createPrintOrder,
  cancelPrintOrder,
  exportPrint,
  staffPrintOrder,
  submitPrintReview,
  staffPrintReview,
  removePrintReview,
  cleanupPrintArtifacts,
  type PrintStore,
  renderPrintOrder,
  recoverPrintRenders,
  recordPrintSignal,
  staffPrintCatalog,
} from '../functions/src/print-studio.js';
import { type Staff } from '../functions/src/staff.js';

const projectId = 'demo-child-life',
  now = new Date('2026-10-24T07:00:00Z');
let app: App, db: Firestore, photo: Buffer;
const files = new Map<string, Buffer>();
let storageDown = false;
const store: PrintStore = {
  read: async (path) => {
    if (storageDown) throw new Error('unavailable');
    if (files.has(path)) return files.get(path)!;
    if (path === 'babies/b1/media/photo1/original.jpg') return photo;
    throw new Error('missing');
  },
  save: async (p, b) => {
    if (storageDown) throw new Error('unavailable');
    files.set(p, b);
  },
  url: async (p) => `https://example.invalid/${p}`,
};
const staff: Staff = { uid: 'operator', name: 'Operator', roles: ['owner'] };
const design = printDesignSchema.parse({
  product: 'single',
  size: '10x15',
  style: 'minimal',
  frame: 'white',
  occasion: 'hundred',
  name: 'Teddy',
  title: '100 ngày',
  date: '2026-11-25',
  message: '',
  birthDetails: '',
  showBirthDetails: false,
  mediaIds: ['photo1'],
  pages: 24,
  locale: 'vi',
});
const request = () => ({
  babyId: 'b1',
  requestId: randomUUID(),
  catalogVersion: 1,
  design,
  quantity: 1,
  approved: true,
  address: {
    recipient: 'Mai',
    phone: '0905123456',
    address: '12 Nguyễn Văn Linh, Đà Nẵng',
    country: 'VN',
    neededBy: '2026-11-25',
    gift: false,
    giftMessage: '',
  },
});
beforeAll(async () => {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  app = initializeApp({ projectId }, `print-${randomUUID()}`);
  db = getFirestore(app);
  photo = await sharp({ create: { width: 2000, height: 3000, channels: 3, background: '#d6e5de' } })
    .jpeg()
    .toBuffer();
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  files.clear();
  storageDown = false;
  await db.doc('babies/b1').set({ state: 'active' });
  await db.doc('babies/b1/members/mom').set({ role: 'coParent', status: 'active' });
  await db.doc('babies/b1/members/grandma').set({ role: 'relative', status: 'active' });
  await db.doc('babies/b1/media/photo1').set({
    status: 'ready',
    type: 'photo',
    paths: { original: 'babies/b1/media/photo1/original.jpg' },
    width: 2000,
    height: 3000,
    sizeBytes: photo.length,
  });
  await db.doc('publicConfig/printStudio').set({
    ...initialPrintCatalog,
    physicalEnabled: true,
  });
});
describe('manual Print Studio orders', () => {
  it('exports an information-only frame and records gift wrapping/payment preference', async () => {
    const info = { ...design, mediaIds: [], pageLayouts: ['text'], pagePhotos: [[]] };
    const exported = await exportPrint(
      db,
      store,
      'mom',
      { babyId: 'b1', design: info, format: 'pdf', cropMarks: false, acknowledgeQuality: false },
      now,
    );
    expect(exported.pages).toBe(1);
    const req = request();
    const order = await createPrintOrder(
      db,
      'mom',
      {
        ...req,
        design: info,
        paymentMethod: 'bankTransfer',
        address: { ...req.address, gift: true, giftMessage: 'For you' },
      },
      now,
    );
    const doc = await db.doc(`babies/b1/printOrders/${order.id}`).get();
    expect(doc.get('total')).toBe(159000);
    expect(doc.get('giftWrapFee')).toBe(30000);
    expect(doc.get('paymentMethod')).toBe('bankTransfer');
    expect(doc.get('status')).toBe('pendingConfirmation');
  });
  it('records one immutable order even when storage is offline; retry never duplicates demand', async () => {
    storageDown = true;
    const req = request();
    const [a, b] = await Promise.all([
      createPrintOrder(db, 'mom', req, now),
      createPrintOrder(db, 'mom', req, now),
    ]);
    expect(a.id).toBe(b.id);
    expect(files.size).toBe(0);
    const doc = await db.doc(`babies/b1/printOrders/${a.id}`).get();
    expect(doc.get('status')).toBe('pendingConfirmation');
    expect(doc.get('render.status')).toBe('queued');
    expect(doc.get('total')).toBe(129000);
    expect(doc.get('deposit')).toBeUndefined();
    expect(doc.get('bank')).toBeUndefined();
    expect((await db.doc('printDemandDaily/2026-10-24').get()).get('submitted')).toBe(1);
    await renderPrintOrder(db, store, 'b1', a.id, 1, now);
    expect((await doc.ref.get()).get('render.status')).toBe('failed');
    expect((await doc.ref.get()).get('status')).toBe('pendingConfirmation');
    const target = { babyId: 'b1', id: a.id };
    await staffPrintOrder(db, store, staff, { ...target, retryRender: true }, now);
    storageDown = false;
    await renderPrintOrder(db, store, 'b1', a.id, 2, now);
    const ready = await doc.ref.get();
    expect(ready.get('render.status')).toBe('ready');
    expect(files.get(ready.get('artifact'))!.subarray(0, 8).toString()).toBe('%PDF-1.4');
    expect((await doc.ref.get()).get('design')).toEqual(req.design);
    expect((await db.collection('babies/b1/printLeases').get()).empty).toBe(true);
  });
  it('requires customer agreement, keeps notes private, and completes a manually handled order', async () => {
    const { id } = await createPrintOrder(db, 'mom', request(), now),
      target = { babyId: 'b1', id };
    await expect(
      staffPrintOrder(db, store, staff, { ...target, status: 'printing' }, now),
    ).rejects.toMatchObject({ reason: 'invalid-transition' });
    await expect(
      staffPrintOrder(db, store, staff, { ...target, status: 'confirmed' }, now),
    ).rejects.toMatchObject({ reason: 'customer-confirmation-required' });
    await staffPrintOrder(
      db,
      store,
      staff,
      { ...target, note: 'Call after 5pm', printPartner: 'Local printer', contacted: true },
      now,
    );
    expect((await db.doc(`babies/b1/printOrders/${id}`).get()).get('internalNote')).toBeUndefined();
    expect((await db.doc(`printOrderOps/${id}`).get()).get('internalNote')).toBe('Call after 5pm');
    await staffPrintOrder(
      db,
      store,
      staff,
      {
        ...target,
        status: 'confirmed',
        customerConfirmed: true,
        quote: { subtotal: 100000, shipping: 25000 },
      },
      now,
    );
    const ref = db.doc(`babies/b1/printOrders/${id}`);
    expect((await ref.get()).get('total')).toBe(125000);
    expect((await ref.get()).get('requestedQuote.total')).toBe(129000);
    expect((await ref.get()).get('pricesEstimated')).toBe(false);
    await expect(
      cancelPrintOrder(db, 'mom', { ...target, reason: 'price' }, now),
    ).rejects.toMatchObject({ reason: 'already-processing' });
    await expect(
      staffPrintOrder(db, store, staff, { ...target, status: 'printing' }, now),
    ).rejects.toMatchObject({ reason: 'file-not-ready' });
    await Promise.all([
      renderPrintOrder(db, store, 'b1', id, 1, now),
      renderPrintOrder(db, store, 'b1', id, 1, now),
    ]);
    expect([...files.keys()].filter((p) => p.endsWith('.pdf'))).toHaveLength(1);
    await staffPrintOrder(db, store, staff, { ...target, status: 'printing' }, now);
    await staffPrintOrder(db, store, staff, { ...target, status: 'shipped' }, now); // tracking is optional for manual delivery.
    await staffPrintOrder(db, store, staff, { ...target, status: 'delivered' }, now);
    await submitPrintReview(db, 'mom', { ...target, rating: 5, message: 'Khung chắc.' }, now);
    await staffPrintReview(db, staff, { id, publish: true }, now);
    const review = (await db.doc(`printReviewsPublic/${id}`).get()).data()!;
    expect(review.uid).toBeUndefined();
    expect(review.babyId).toBeUndefined();
    await removePrintReview(db, 'mom', target, now);
    expect((await db.doc(`printReviewsPublic/${id}`).get()).exists).toBe(false);
    const removed: Array<{ path: string; prefix?: boolean }> = [];
    await cleanupPrintArtifacts(
      db,
      async (path, prefix) => {
        removed.push({ path, ...(prefix === undefined ? {} : { prefix }) });
      },
      new Date(now.getTime() + 8 * 86_400_000),
    );
    expect(removed).toContainEqual({ path: `babies/b1/printOrders/${id}/`, prefix: true });
  });
  it('collects a cancellation reason, stops queued work and does not require a refund', async () => {
    const { id } = await createPrintOrder(db, 'mom', request(), now),
      target = { babyId: 'b1', id };
    await expect(cancelPrintOrder(db, 'mom', target, now)).rejects.toMatchObject({
      reason: 'malformed',
    });
    await cancelPrintOrder(db, 'mom', { ...target, reason: 'price' }, now);
    await recoverPrintRenders(db, store, now);
    expect(files.size).toBe(0);
    expect((await db.doc(`printOrderIndex/${id}`).get()).get('renderStatus')).toBe('cancelled');
    const second = await createPrintOrder(db, 'mom', request(), now);
    await staffPrintOrder(
      db,
      store,
      staff,
      { babyId: 'b1', id: second.id, status: 'confirmed', customerConfirmed: true },
      now,
    );
    await staffPrintOrder(
      db,
      store,
      staff,
      { babyId: 'b1', id: second.id, status: 'cancelled', reason: 'customer_changed_mind' },
      now,
    );
    expect((await db.doc(`babies/b1/printOrders/${second.id}`).get()).get('status')).toBe(
      'cancelled',
    );
  });
  it('recovers a worker lease after interruption and rejects a stale attempt', async () => {
    const { id } = await createPrintOrder(db, 'mom', request(), now),
      ref = db.doc(`babies/b1/printOrders/${id}`);
    const expired = new Date(now.getTime() - 1000);
    await ref.update({ 'render.status': 'rendering', 'render.leaseUntil': expired });
    await db
      .doc(`printOrderIndex/${id}`)
      .update({ renderStatus: 'rendering', renderLeaseUntil: expired });
    await recoverPrintRenders(db, store, now);
    expect((await ref.get()).get('render.status')).toBe('ready');
    const count = files.size;
    await renderPrintOrder(db, store, 'b1', id, 0, now);
    expect(files.size).toBe(count);
  });
  it('deduplicates funnel events and stores no child identity in analytics', async () => {
    const data = { requestId: randomUUID(), event: 'viewed', product: 'trio' };
    await Promise.all([
      recordPrintSignal(db, 'mom', data, now),
      recordPrintSignal(db, 'mom', data, now),
    ]);
    const row = await db.doc('printDemandDaily/2026-10-24').get();
    expect(row.get('viewed')).toBe(1);
    const event = (await db.collection('printDemandEvents').get()).docs[0]!.data();
    expect(event.uid).toBeUndefined();
    expect(event.babyId).toBeUndefined();
  });
  it('rejects relatives, foreign media, stale prices, deadlines and unavailable products', async () => {
    await db.doc('publicConfig/printStudio').update({ orderProducts: ['single', 'trio', 'five'] });
    await expect(createPrintOrder(db, 'grandma', request(), now)).rejects.toMatchObject({
      reason: 'not-allowed',
    });
    const req = request();
    for (const [patch, reason] of [
      [{ catalogVersion: 999 }, 'price-changed'],
      [{ address: { ...req.address, country: 'US' } }, 'country-unsupported'],
      [{ address: { ...req.address, neededBy: '2026-10-25' } }, 'deadline-too-soon'],
      [{ design: { ...design, mediaIds: ['foreign'] } }, 'photo-unavailable'],
      [{ design: { ...design, product: 'book', size: '20x20' } }, 'product-unavailable'],
    ] as const)
      await expect(createPrintOrder(db, 'mom', { ...req, ...patch }, now)).rejects.toMatchObject({
        reason,
      });
    expect((await db.collection('printOrderIndex').get()).empty).toBe(true);
  });
  it('opens order collection without bank configuration; digital export works while ordering is paused', async () => {
    await staffPrintCatalog(
      db,
      staff,
      { catalog: { ...initialPrintCatalog, physicalEnabled: true } },
      now,
    );
    await createPrintOrder(db, 'mom', { ...request(), catalogVersion: 2 }, now);
    await db.doc('publicConfig/printStudio').update({ physicalEnabled: false });
    await expect(createPrintOrder(db, 'mom', request(), now)).rejects.toMatchObject({
      reason: 'ordering-unavailable',
    });
    const answer = await exportPrint(
      db,
      store,
      'mom',
      { babyId: 'b1', design, format: 'pdf', cropMarks: true, acknowledgeQuality: false },
      now,
    );
    expect(answer.pages).toBe(1);
    await db.doc('babies/b1').update({ state: 'deleting' });
    await expect(createPrintOrder(db, 'mom', request(), now)).rejects.toMatchObject({
      reason: 'deleting',
    });
  });
});
