import { createHash, randomUUID } from 'node:crypto';
import {
  defaultEntitlementsConfig,
  defaultFlags,
  premiumCapabilities,
  type GoogleStatusInput,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  BillingSignatureError,
  appleNotification,
  applyStoreStatus,
  fetchSubscription,
  handleStoreEvent,
  noBillingAdapters,
  paidGrantId,
  playNotification,
  reconcileSubscriptions,
  restorePurchase,
  startPurchase,
  verifyPurchase,
  type AppleAdapter,
  type AppleNotification,
  type AppleStatus,
  type BillingAdapters,
  type GoogleAdapter,
} from '../functions/src/billing.js';
import { getCapabilities, requireCapability } from '../functions/src/entitlements.js';

// Premium billing core (plan §5.2, D-072 #1 / #6) against the Firestore emulator with FAKE store
// adapters — real Apple / Google adapters are postponed (D-074) and never called. Integration
// matrix M05, M06, M07, M08, M17 (server part). Its own project; synthetic `test_` ids only.
const projectId = 'demo-child-life-billing';
let app: App;
let db: Firestore;
const t0 = new Date('2026-10-14T12:00:00Z');
const day = 86_400_000;
const at = (ms: number) => new Date(t0.getTime() + ms);

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason ?? String(e),
  );
const on = () => ({ ...defaultFlags.premium_billing, enabled: true, scope: 'all' as const });

/** App Store fake: status by any transaction id of the chain; notifications "signed" by prefix. */
class FakeApple implements AppleAdapter {
  byId = new Map<string, AppleStatus>();
  fetches = 0;
  put(ids: string[], s: AppleStatus) {
    for (const id of ids) this.byId.set(id, s);
  }
  async getStatus(id: string) {
    this.fetches++;
    return this.byId.get(id) ?? null;
  }
  async verifyNotification(signedPayload: string): Promise<AppleNotification> {
    if (!signedPayload.startsWith('signed.')) throw new BillingSignatureError('bad signature');
    return JSON.parse(signedPayload.slice('signed.'.length)) as AppleNotification;
  }
}
class FakeGoogle implements GoogleAdapter {
  byToken = new Map<string, GoogleStatusInput>();
  acks: string[] = [];
  async getStatus(_pkg: string, token: string) {
    return this.byToken.get(token) ?? null;
  }
  async acknowledge(_pkg: string, _productId: string, token: string) {
    this.acks.push(token);
    const s = this.byToken.get(token);
    if (s) s.acknowledgementState = 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
  }
}

let apple: FakeApple;
let google: FakeGoogle;
let adapters: BillingAdapters;

const appleStatus = (
  intentId: string,
  over: {
    status?: AppleStatus['status'];
    expires?: Date;
    autoRenew?: 0 | 1;
    grace?: Date;
    revoked?: Date;
    env?: 'Sandbox' | 'Production';
    original?: string;
  } = {},
): AppleStatus => ({
  status: over.status ?? 1,
  transaction: {
    originalTransactionId: over.original ?? 'test_orig_1',
    productId: 'cl.premium.monthly',
    expiresDate: (over.expires ?? at(30 * day)).getTime(),
    ...(over.revoked ? { revocationDate: over.revoked.getTime() } : {}),
    appAccountToken: intentId,
    environment: over.env ?? 'Sandbox',
  },
  renewal: {
    autoRenewStatus: over.autoRenew ?? 1,
    ...(over.grace ? { gracePeriodExpiresDate: over.grace.getTime() } : {}),
  },
  purchaseDate: t0.getTime(),
});

const start = (uid = 'test_mom', babyId = 'test_b1', provider: 'apple' | 'google' = 'apple') =>
  startPurchase(
    db,
    adapters,
    uid,
    {
      babyId,
      productKey: 'monthly',
      provider,
      entryPoint: 'templates',
      resume: { kind: 'video', templateId: 'video_first_month', draftRef: 'draft_1' },
    },
    t0,
    'test',
  );
const verifyApple = (uid: string, intentId: string, transactionId: string, now = t0) =>
  verifyPurchase(db, adapters, uid, { provider: 'apple', intentId, transactionId }, now, 'test');
const grantsOf = async (familyId = 'test_f1') =>
  (await db.collection(`families/${familyId}/grants`).get()).docs;
const versionOf = async (familyId = 'test_f1') =>
  ((await db.doc(`families/${familyId}`).get()).get('entitlementVersion') as number | undefined) ??
  0;
const notify = (uuid: string, original: string, type = 'DID_RENEW', now = t0) =>
  appleNotification(
    db,
    adapters,
    {
      signedPayload: `signed.${JSON.stringify({
        notificationUUID: uuid,
        notificationType: type,
        subtype: null,
        originalTransactionId: original,
        environment: 'Sandbox',
      })}`,
    },
    now,
  );

beforeAll(() => {
  app = initializeApp({ projectId }, `billing-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => deleteApp(app));
beforeEach(async () => {
  for (const c of [
    'babies',
    'families',
    'config',
    'purchaseIntents',
    'billingAccounts',
    'billingEvents',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  apple = new FakeApple();
  google = new FakeGoogle();
  adapters = { apple, google };
  await db.doc('config/flags').set({ premium_billing: on(), memory_story: on() });
  await db
    .doc('config/entitlements')
    .set({ ...defaultEntitlementsConfig, regions: { advanced: ['VN'] } });
  await db.doc('config/billing').set({
    products: [
      { key: 'monthly', apple: 'cl.premium.monthly', google: 'premium_monthly' },
      { key: 'yearly', apple: 'cl.premium.yearly', google: 'premium_yearly' },
    ],
    appleBundleId: 'app.childlife.dev',
    googlePackage: 'app.childlife.dev',
  });
  for (const [f, b, owner] of [
    ['test_f1', 'test_b1', 'test_mom'],
    ['test_f2', 'test_b2', 'test_other'],
  ] as const) {
    await db.doc(`babies/${b}`).set({ familyId: f });
    await db.doc(`families/${f}`).set({ ownerUid: owner, country: 'VN' });
    await db
      .doc(`babies/${b}/members/${owner}`)
      .set({ role: 'coParent', isOwner: true, status: 'active' });
  }
  await db.doc('babies/test_b1/members/test_dad').set({ role: 'coParent', status: 'active' });
});

describe('not configured (D-074: real payments later)', () => {
  it('every purchase call answers billing-not-configured and nothing is written', async () => {
    adapters = noBillingAdapters;
    expect(await reason(start())).toBe('billing-not-configured');
    expect(await reason(verifyApple('test_mom', randomUUID(), 'test_tx_1'))).toBe(
      'billing-not-configured',
    );
    expect(
      await reason(
        restorePurchase(
          db,
          adapters,
          'test_mom',
          {
            provider: 'google',
            babyId: 'test_b1',
            purchases: [{ productId: 'p', purchaseToken: 't' }],
          },
          t0,
          'test',
        ),
      ),
    ).toBe('billing-not-configured');
    expect(await notify('n1', 'test_orig_1')).toBe(503);
    expect(await reconcileSubscriptions(db, adapters, t0)).toBe(0);
    for (const c of ['purchaseIntents', 'billingAccounts', 'billingEvents']) {
      expect((await db.collection(c).get()).size).toBe(0);
    }
    expect(await grantsOf()).toHaveLength(0);
  });
});

describe('startPurchase (D-072 #1)', () => {
  it('the owner gets an intent; others, a flag off or an unknown product are refused', async () => {
    const a = await start();
    expect(a).toEqual({
      intentId: a.intentId,
      accountToken: a.intentId,
      productId: 'cl.premium.monthly',
    });
    const intent = await db.doc(`purchaseIntents/${a.intentId}`).get();
    expect(intent.data()).toMatchObject({
      familyId: 'test_f1',
      uid: 'test_mom',
      entryPoint: 'templates',
      provider: 'apple',
      productId: 'cl.premium.monthly',
      resume: { kind: 'video', templateId: 'video_first_month', draftRef: 'draft_1' },
    });
    expect(intent.get('expiresAt').toDate().getTime()).toBe(at(7 * day).getTime());
    expect(await reason(start('test_dad'))).toBe('ROLE_DENIED');
    expect(await reason(start('test_other'))).toBe('NOT_MEMBER');
    await db.doc('config/flags').set({ premium_billing: { ...on(), enabled: false } });
    expect(await reason(start())).toBe('FEATURE_DISABLED');
    await db.doc('config/flags').set({ premium_billing: on() });
    await db.doc('config/billing').set({ products: [], appleBundleId: 'x', googlePackage: 'y' });
    expect(await reason(start())).toBe('billing-not-configured');
  });
});

describe('M17 · verify answers the resume; one grant for the household', () => {
  it('grants premium capabilities from the provider status and bumps the version', async () => {
    const { intentId } = await start();
    apple.put(['test_tx_1', 'test_orig_1'], appleStatus(intentId));
    const a = await verifyApple('test_mom', intentId, 'test_tx_1');
    expect(a).toEqual({
      outcome: 'active',
      validUntil: at(30 * day).toISOString(),
      resume: { kind: 'video', templateId: 'video_first_month', draftRef: 'draft_1' },
    });
    const grants = await grantsOf();
    expect(grants).toHaveLength(1);
    const accountId = `apple_${createHash('sha256').update('test_orig_1').digest('hex').slice(0, 40)}`;
    expect(grants[0]!.id).toBe(paidGrantId(accountId));
    expect(grants[0]!.data()).toMatchObject({
      familyId: 'test_f1',
      source: 'paid',
      status: 'active',
      environment: 'test',
      capabilities: [...premiumCapabilities],
      billingOwnerUid: 'test_mom',
      provider: 'apple',
      sourceRef: accountId,
      autoRenew: true,
    });
    // The binding keeps a hash as id; nothing in it names the raw original id.
    const account = await db.doc(`billingAccounts/${accountId}`).get();
    expect(account.get('familyId')).toBe('test_f1');
    expect(account.id).not.toContain('test_orig_1');
    expect(await versionOf()).toBe(1);
    expect(
      await reason(requireCapability(db, 'test_dad', 'test_b1', 'templates.premium', t0, 'test')),
    ).toBe('ok');
    const caps = await getCapabilities(db, 'test_mom', { babyId: 'test_b1' }, t0, 'test');
    expect(caps).toMatchObject({ plan: 'premium', isBillingOwner: true, autoRenew: true });

    // The same verify again: same grant, no new version.
    await verifyApple('test_mom', intentId, 'test_tx_1');
    expect(await grantsOf()).toHaveLength(1);
    expect(await versionOf()).toBe(1);
  });
});

describe('M05 · auto-renew off keeps access to validUntil', () => {
  it('cancelled renewal: premium until the period ends, then expired (kept, not deleted)', async () => {
    const { intentId } = await start();
    const end = at(10 * day);
    apple.put(['test_tx_1'], appleStatus(intentId, { autoRenew: 0, expires: end }));
    expect((await verifyApple('test_mom', intentId, 'test_tx_1')).outcome).toBe('active');
    expect((await grantsOf())[0]!.get('autoRenew')).toBe(false);
    const caps = await getCapabilities(db, 'test_mom', { babyId: 'test_b1' }, at(9 * day), 'test');
    expect(caps).toMatchObject({ plan: 'premium', autoRenew: false });
    // At validUntil the resolver stops on its own, before any notification.
    expect(
      await reason(requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', end, 'test')),
    ).toBe('PREMIUM_REQUIRED');
    // EXPIRED arrives: the refetched status ends the grant; it stays for history.
    apple.put(
      ['test_tx_1', 'test_orig_1'],
      appleStatus(intentId, { status: 2, autoRenew: 0, expires: end }),
    );
    expect(await notify('n-exp', 'test_orig_1', 'EXPIRED', at(10 * day + 60_000))).toBe(200);
    const grants = await grantsOf();
    expect(grants).toHaveLength(1);
    expect(grants[0]!.get('status')).toBe('expired');
    const after = await getCapabilities(
      db,
      'test_mom',
      { babyId: 'test_b1' },
      at(11 * day),
      'test',
    );
    expect(after.plan).toBe('expired');
  });
});

describe('M06 · pending, other households, non-owners', () => {
  it('a pending purchase grants nothing; the RTDN when it clears binds and grants', async () => {
    const { intentId } = await start('test_mom', 'test_b1', 'google');
    const status: GoogleStatusInput = {
      subscriptionState: 'SUBSCRIPTION_STATE_PENDING',
      lineItems: [{ productId: 'premium_monthly', expiryTime: at(30 * day).toISOString() }],
      testPurchase: {},
      acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
      externalAccountIdentifiers: { obfuscatedExternalAccountId: intentId },
    };
    google.byToken.set('test_token_1', status);
    const a = await verifyPurchase(
      db,
      adapters,
      'test_mom',
      { provider: 'google', intentId, productId: 'premium_monthly', purchaseToken: 'test_token_1' },
      t0,
      'test',
    );
    expect(a.outcome).toBe('pending');
    expect(await grantsOf()).toHaveLength(0);
    expect(google.acks).toHaveLength(0);
    expect((await getCapabilities(db, 'test_mom', { babyId: 'test_b1' }, t0, 'test')).plan).toBe(
      'free',
    );

    status.subscriptionState = 'SUBSCRIPTION_STATE_ACTIVE';
    status.lineItems[0]!.autoRenewingPlan = { autoRenewEnabled: true };
    const rtdn = {
      packageName: 'app.childlife.dev',
      subscriptionNotification: { notificationType: 4, purchaseToken: 'test_token_1' },
    };
    expect(await playNotification(db, adapters, 'msg-1', rtdn, at(60_000))).toBe('processed');
    expect(await playNotification(db, adapters, 'msg-1', rtdn, at(120_000))).toBe('duplicate');
    const grants = await grantsOf();
    expect(grants).toHaveLength(1);
    expect(grants[0]!.get('status')).toBe('active');
    expect(google.acks).toEqual(['test_token_1']);
    // Another app's package is ignored.
    expect(
      await playNotification(db, adapters, 'msg-2', { ...rtdn, packageName: 'other.app' }, t0),
    ).toBe('ignored');
  });

  it('restore of a transaction bound to another household is already_bound; never rebound', async () => {
    const { intentId } = await start();
    apple.put(['test_tx_1', 'test_orig_1'], appleStatus(intentId));
    await verifyApple('test_mom', intentId, 'test_tx_1');
    const r = await restorePurchase(
      db,
      adapters,
      'test_other',
      { provider: 'apple', babyId: 'test_b2', transactionIds: ['test_tx_1'] },
      at(day),
      'test',
    );
    expect(r.outcome).toBe('already_bound');
    expect(await grantsOf('test_f2')).toHaveLength(0);
    // The other owner's own intent does not take it either.
    const other = await start('test_other', 'test_b2');
    expect((await verifyApple('test_other', other.intentId, 'test_tx_1', at(day))).outcome).toBe(
      'already_bound',
    );
    // A purchase made for household 1 (its token) cannot be claimed first by household 2.
    const fresh = await start();
    apple.put(
      ['test_tx_9', 'test_orig_9'],
      appleStatus(fresh.intentId, { original: 'test_orig_9' }),
    );
    expect((await verifyApple('test_other', other.intentId, 'test_tx_9')).outcome).toBe(
      'already_bound',
    );
    expect(await grantsOf('test_f2')).toHaveLength(0);
    expect((await db.collection('billingAccounts').get()).size).toBe(1);
    // Same household: restore refreshes.
    const mine = await restorePurchase(
      db,
      adapters,
      'test_mom',
      { provider: 'apple', babyId: 'test_b1', transactionIds: ['test_tx_1', 'test_tx_1'] },
      at(day),
      'test',
    );
    expect(mine.outcome).toBe('active');
  });

  it('a non-owner cannot verify or restore (not_owner)', async () => {
    const { intentId } = await start();
    apple.put(['test_tx_1'], appleStatus(intentId));
    expect((await verifyApple('test_dad', intentId, 'test_tx_1')).outcome).toBe('not_owner');
    const r = await restorePurchase(
      db,
      adapters,
      'test_dad',
      { provider: 'apple', babyId: 'test_b1', transactionIds: ['test_tx_1'] },
      t0,
      'test',
    );
    expect(r.outcome).toBe('not_owner');
    expect(await grantsOf()).toHaveLength(0);
    expect(apple.fetches).toBe(0);
  });
});

describe('M07 · lifecycle from refetched status', () => {
  it('renew, grace, revoke, duplicates and out-of-order events reconcile to one grant', async () => {
    const { intentId } = await start();
    const ids = ['test_tx_1', 'test_orig_1'];
    apple.put(ids, appleStatus(intentId));
    await verifyApple('test_mom', intentId, 'test_tx_1');
    const v0 = await versionOf();

    // Renew: the period moves on.
    apple.put(ids, appleStatus(intentId, { expires: at(60 * day) }));
    expect(await notify('n-renew', 'test_orig_1', 'DID_RENEW', at(30 * day))).toBe(200);
    let g = (await grantsOf())[0]!;
    expect(g.get('validUntil').toDate().getTime()).toBe(at(60 * day).getTime());
    expect(await versionOf()).toBe(v0 + 1);

    // The same notification again: deduped, no refetch.
    const fetches = apple.fetches;
    expect(await notify('n-renew', 'test_orig_1', 'DID_RENEW', at(30 * day + 1))).toBe(200);
    expect(apple.fetches).toBe(fetches);
    expect(await versionOf()).toBe(v0 + 1);

    // Billing problem with grace: access until the grace end.
    apple.put(
      ids,
      appleStatus(intentId, { status: 4, expires: at(60 * day), grace: at(66 * day) }),
    );
    await notify('n-grace', 'test_orig_1', 'DID_FAIL_TO_RENEW', at(60 * day));
    g = (await grantsOf())[0]!;
    expect(g.get('status')).toBe('grace');
    expect(g.get('validUntil').toDate().getTime()).toBe(at(66 * day).getTime());
    expect(
      await reason(
        requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', at(63 * day), 'test'),
      ),
    ).toBe('ok');

    // Refund / revoke.
    apple.put(
      ids,
      appleStatus(intentId, { status: 5, expires: at(60 * day), revoked: at(61 * day) }),
    );
    await notify('n-revoke', 'test_orig_1', 'REVOKE', at(61 * day));
    expect((await grantsOf())[0]!.get('status')).toBe('revoked');

    // An older DID_RENEW delivered late: the refetch still says revoked.
    await notify('n-old-renew', 'test_orig_1', 'DID_RENEW', at(61 * day + 1000));
    const all = await grantsOf();
    expect(all).toHaveLength(1);
    expect(all[0]!.get('status')).toBe('revoked');
    expect((await db.collection('billingEvents').get()).size).toBe(4);

    // A stale fetch (taken before the last one applied) changes nothing.
    const stale = await fetchSubscription(
      adapters,
      {
        products: [{ key: 'monthly', apple: 'cl.premium.monthly', google: null }],
        appleBundleId: 'x',
        googlePackage: null,
      },
      { provider: 'apple', transactionId: 'test_tx_1' },
      at(day),
    );
    apple.put(ids, appleStatus(intentId, { expires: at(90 * day) }));
    const old = { ...stale!, status: 'active' as const, validUntil: at(90 * day) };
    expect((await applyStoreStatus(db, old, null, at(day))).changed).toBe(false);
    expect((await grantsOf())[0]!.get('status')).toBe('revoked');
  });

  it('the reconciler refetches subscriptions ending soon', async () => {
    const { intentId } = await start();
    const ids = ['test_tx_1', 'test_orig_1'];
    apple.put(ids, appleStatus(intentId, { expires: at(30 * day) }));
    await verifyApple('test_mom', intentId, 'test_tx_1');
    expect(await reconcileSubscriptions(db, adapters, at(10 * day))).toBe(0);
    apple.put(ids, appleStatus(intentId, { status: 2, expires: at(30 * day) }));
    expect(await reconcileSubscriptions(db, adapters, at(29 * day))).toBe(1);
    expect((await grantsOf())[0]!.get('status')).toBe('expired');
  });

  it('a notification whose signature fails is refused with 401 and nothing is written', async () => {
    expect(await appleNotification(db, adapters, { signedPayload: 'forged.payload' }, t0)).toBe(
      401,
    );
    expect(await appleNotification(db, adapters, { nope: 1 }, t0)).toBe(400);
    expect((await db.collection('billingEvents').get()).size).toBe(0);
    expect((await db.collection('billingAccounts').get()).size).toBe(0);
    expect(apple.fetches).toBe(0);
  });

  it('an event for a subscription nobody bound is recorded and ignored', async () => {
    apple.put(['test_orig_x'], appleStatus(randomUUID(), { original: 'test_orig_x' }));
    expect(
      await handleStoreEvent(
        db,
        adapters,
        {
          provider: 'apple',
          eventId: 'n-x',
          kind: 'SUBSCRIBED',
          ref: { provider: 'apple', transactionId: 'test_orig_x' },
        },
        t0,
      ),
    ).toBe('ignored');
    expect((await db.collection('billingAccounts').get()).size).toBe(0);
  });
});

describe('M08 · sandbox purchases', () => {
  it('produce test grants that production ignores', async () => {
    const { intentId } = await start();
    apple.put(['test_tx_1'], appleStatus(intentId, { env: 'Sandbox' }));
    await verifyApple('test_mom', intentId, 'test_tx_1');
    expect((await grantsOf())[0]!.get('environment')).toBe('test');
    expect(
      await reason(requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', t0, 'test')),
    ).toBe('ok');
    expect(
      await reason(
        requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', t0, 'production'),
      ),
    ).toBe('PREMIUM_REQUIRED');
  });
});
