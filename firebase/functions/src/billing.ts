import { createHash, randomUUID } from 'node:crypto';
import {
  billingAccountId,
  billingConfigSchema,
  defaultBillingConfig,
  familyCan,
  isFlagOnForFamily,
  normalizeApple,
  normalizeGoogle,
  premiumCapabilities,
  restorePurchaseRequestSchema,
  startPurchaseRequestSchema,
  verifyPurchaseRequestSchema,
  type AppleStatusInput,
  type BillingConfig,
  type BillingProvider,
  type GoogleStatusInput,
  type GrantEnvironment,
  type NormalizedSubscription,
  type PurchaseAnswer,
  type StartPurchaseAnswer,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { gateError, loadEntitlementContext, type EntitlementContext } from './entitlements.js';
import { familyBucket } from './features.js';

/**
 * Child Life Premium billing core (brief p.9, plan §5.2, D-072 #1 / #6, D-074). Provider-neutral:
 * the store is reached only through a {@link BillingAdapters} registry, and a client's "success"
 * is never proof of payment — every grant comes from the provider's current status, fetched by
 * the server. Real Apple / Google adapters are postponed by the owner (D-074): with no adapter
 * configured every purchase call answers `failed-precondition 'billing-not-configured'` and
 * nothing is granted.
 *
 * Documents (all closed to clients by the Rules):
 * - `purchaseIntents/{intentId}`: who asked to buy, for which household, and where to come back.
 *   The id is the store account token (Apple `appAccountToken`, Google `obfuscatedAccountId`).
 * - `billingAccounts/{provider}_{sha256(originalId)}`: one store subscription → one household
 *   (never moved to another one, M06). Keeps the store reference needed to refetch the status.
 * - `families/{f}/grants/paid_<accountId>`: the grant the resolver reads; updated, never deleted.
 * - `billingEvents/{provider}_{sha256(eventId)}`: notification dedupe ledger.
 *
 * Logs carry hashes only (account ids), never a transaction id, purchase token or receipt.
 */

export class BillingError extends Error {
  constructor(
    readonly code:
      | 'invalid-argument'
      | 'permission-denied'
      | 'not-found'
      | 'failed-precondition'
      | 'resource-exhausted',
    readonly reason: string,
  ) {
    super(reason);
  }
}

// ---------------------------------------------------------------------------------------------
// Provider adapters: the contract a future real adapter implements (postponed, D-074).
// ---------------------------------------------------------------------------------------------

/** Apple status plus the start of the current period (the latest transaction's `purchaseDate`). */
export type AppleStatus = AppleStatusInput & { purchaseDate?: number };

/** A verified, decoded App Store Server Notification V2 (the fields the server uses). */
export interface AppleNotification {
  notificationUUID: string;
  notificationType: string;
  subtype: string | null;
  /** From the notification's signed transaction; null for notifications without one (TEST). */
  originalTransactionId: string | null;
  environment: 'Sandbox' | 'Production' | 'Xcode' | 'LocalTesting';
}

/** Thrown by {@link AppleAdapter.verifyNotification} when the JWS does not verify. */
export class BillingSignatureError extends Error {}

/**
 * App Store adapter. A real one uses `@apple/app-store-server-library`:
 * `AppStoreServerAPIClient` (key id, issuer id, private key; Sandbox on dev, Production on prod
 * with a Sandbox retry when Production answers "transaction not found") and `SignedDataVerifier`
 * with Apple's root certificates, bundle id and (prod) app Apple id.
 */
export interface AppleAdapter {
  /**
   * Get Transaction Info + Get All Subscription Statuses for any transaction id of the chain
   * (StoreKit 2 transaction id or original transaction id); signed transaction and renewal info
   * verified and decoded. Null when the App Store does not know the transaction.
   */
  getStatus(transactionId: string): Promise<AppleStatus | null>;
  /** Verifies and decodes an App Store Server Notifications V2 `signedPayload`. Throws
   * {@link BillingSignatureError} when the signature, chain, bundle or environment is wrong. */
  verifyNotification(signedPayload: string): Promise<AppleNotification>;
}

/**
 * Google Play adapter. A real one uses `@googleapis/androidpublisher` with the functions' service
 * account (granted in Play Console): `purchases.subscriptionsv2.get` and
 * `purchases.subscriptions.acknowledge`.
 */
export interface GoogleAdapter {
  /** `purchases.subscriptionsv2.get`; null when Play does not know the token. */
  getStatus(packageName: string, purchaseToken: string): Promise<GoogleStatusInput | null>;
  /** `purchases.subscriptions.acknowledge` (within 3 days, or Play refunds the purchase). */
  acknowledge(packageName: string, productId: string, purchaseToken: string): Promise<void>;
}

/** The registry the callables use; a null provider is "not configured". */
export interface BillingAdapters {
  apple: AppleAdapter | null;
  google: GoogleAdapter | null;
}

/** Until real payments ship (D-074): nothing is configured, nothing can be granted. */
export const noBillingAdapters: BillingAdapters = { apple: null, google: null };

// ---------------------------------------------------------------------------------------------

/** What the server binds and grants from: the normalized status plus what it needs to refetch. */
export interface StoreSubscription extends NormalizedSubscription {
  /** Start of the current billing period (the paid video window, Q2). */
  periodStart: Date | null;
  /** Apple: a transaction id of the chain; Google: the latest purchase token. Server-only. */
  storeRef: string;
  packageName: string | null;
}

export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');
const accountIdOf = (provider: BillingProvider, originalId: string) =>
  billingAccountId(provider, sha256(originalId).slice(0, 40));
export const paidGrantId = (accountId: string) => `paid_${accountId}`;

/** Purchase intents stay usable this long for a first verify (Ask to Buy / pending payments). */
const intentDays = 7;

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const toDate = (v: unknown): Date | null =>
  v instanceof Date
    ? v
    : v && typeof (v as Timestamp).toDate === 'function'
      ? (v as Timestamp).toDate()
      : null;

/** `config/billing`; missing or invalid reads as "nothing on sale". */
export async function readBillingConfig(db: Firestore): Promise<BillingConfig> {
  const parsed = billingConfigSchema.safeParse((await db.doc('config/billing').get()).data());
  return parsed.success ? parsed.data : defaultBillingConfig;
}

function productKeyOf(config: BillingConfig, provider: BillingProvider, productId: string) {
  return config.products.find((p) => p[provider] === productId)?.key ?? null;
}

/** Google gives no period start: one period back from the expiry, by the product's period. */
function googlePeriodStart(expiry: Date | null, key: 'monthly' | 'yearly' | null): Date | null {
  if (!expiry || !key) return null;
  const d = new Date(expiry);
  if (key === 'monthly') d.setUTCMonth(d.getUTCMonth() - 1);
  else d.setUTCFullYear(d.getUTCFullYear() - 1);
  return d;
}

function requireAdapter<P extends BillingProvider>(
  adapters: BillingAdapters,
  provider: P,
): NonNullable<BillingAdapters[P]> {
  const a = adapters[provider];
  if (!a) throw new BillingError('failed-precondition', 'billing-not-configured');
  return a as NonNullable<BillingAdapters[P]>;
}

/**
 * The provider's current status for [ref], normalized; null when the store does not know it or
 * the product is not one of ours (never trusted from the client).
 */
export async function fetchSubscription(
  adapters: BillingAdapters,
  config: BillingConfig,
  ref: { provider: 'apple'; transactionId: string } | { provider: 'google'; purchaseToken: string },
  now: Date,
): Promise<StoreSubscription | null> {
  let sub: StoreSubscription;
  if (ref.provider === 'apple') {
    const apple = requireAdapter(adapters, 'apple');
    if (!config.appleBundleId)
      throw new BillingError('failed-precondition', 'billing-not-configured');
    const status = await apple.getStatus(ref.transactionId);
    if (!status) return null;
    sub = {
      ...normalizeApple(status),
      periodStart: status.purchaseDate ? new Date(status.purchaseDate) : null,
      storeRef: status.transaction.originalTransactionId,
      packageName: null,
    };
  } else {
    const google = requireAdapter(adapters, 'google');
    const pkg = config.googlePackage;
    if (!pkg) throw new BillingError('failed-precondition', 'billing-not-configured');
    const status = await google.getStatus(pkg, ref.purchaseToken);
    if (!status) return null;
    const n = normalizeGoogle(status, ref.purchaseToken, now);
    sub = {
      ...n,
      periodStart: googlePeriodStart(n.validUntil, productKeyOf(config, 'google', n.productId)),
      storeRef: ref.purchaseToken,
      packageName: pkg,
    };
  }
  return productKeyOf(config, sub.provider, sub.productId) ? sub : null;
}

export interface ApplyResult {
  outcome: PurchaseAnswer['outcome'];
  familyId: string | null;
  accountId: string;
  validUntil: Date | null;
  /** The grant was created or changed (entitlementVersion bumped). */
  changed: boolean;
}

const outcomeOf = (status: string): PurchaseAnswer['outcome'] =>
  status === 'active' || status === 'grace'
    ? 'active'
    : status === 'pending'
      ? 'pending'
      : 'expired';

/**
 * Binds [sub] to its household and writes the grant from it, in one transaction. [claim] is the
 * household asking (verify / restore); null for notifications and the reconciler, which bind only
 * through the account token's intent. Never moves a subscription to another household (M06), never
 * applies a fetch older than the last one applied (M07), never deletes a grant.
 */
export async function applyStoreStatus(
  db: Firestore,
  sub: StoreSubscription,
  claim: { familyId: string } | null,
  now: Date,
): Promise<ApplyResult> {
  const accountId = accountIdOf(sub.provider, sub.originalId);
  const accountRef = db.doc(`billingAccounts/${accountId}`);
  const result = await db.runTransaction(async (tx): Promise<ApplyResult> => {
    const refused = (outcome: PurchaseAnswer['outcome']): ApplyResult => ({
      outcome,
      familyId: null,
      accountId,
      validUntil: null,
      changed: false,
    });
    const account = await tx.get(accountRef);
    let familyId: string;
    let ownerUid: string | null;
    if (account.exists) {
      familyId = account.get('familyId') as string;
      ownerUid = (account.get('billingOwnerUid') as string | null | undefined) ?? null;
      if (claim && claim.familyId !== familyId) return refused('already_bound');
    } else {
      // First sight: the store account token must name an intent; its household gets it.
      const token = sub.accountToken;
      const intent =
        token && uuid.test(token) ? await tx.get(db.doc(`purchaseIntents/${token}`)) : null;
      if (!intent?.exists || intent.get('provider') !== sub.provider) return refused('not_found');
      familyId = intent.get('familyId') as string;
      ownerUid = intent.get('uid') as string;
      if (claim && claim.familyId !== familyId) return refused('already_bound');
    }
    // Out of order: a fetch older than the one already applied changes nothing.
    const fetchedAt = toDate(account.get('fetchedAt'));
    if (fetchedAt && fetchedAt.getTime() > now.getTime()) {
      return {
        outcome: outcomeOf(account.get('status') as string),
        familyId,
        accountId,
        validUntil: toDate(account.get('expiresAt')),
        changed: false,
      };
    }
    const grantRef = db.doc(`families/${familyId}/grants/${paidGrantId(accountId)}`);
    const grant = await tx.get(grantRef);

    tx.set(
      accountRef,
      {
        provider: sub.provider,
        familyId,
        billingOwnerUid: ownerUid,
        environment: sub.environment,
        productId: sub.productId,
        status: sub.status,
        expiresAt: sub.validUntil,
        autoRenew: sub.autoRenew,
        storeRef: sub.storeRef,
        packageName: sub.packageName,
        fetchedAt: now,
        updatedAt: now,
        ...(account.exists ? {} : { boundAt: now }),
      },
      { merge: true },
    );

    const grants = (sub.status === 'active' || sub.status === 'grace') && sub.validUntil !== null;
    const live = grants && sub.validUntil!.getTime() > now.getTime();
    let changed = false;
    if (live) {
      const prev = grant.exists ? grant.data()! : null;
      const next = {
        familyId,
        source: 'paid',
        status: sub.status,
        environment: sub.environment,
        capabilities: [...premiumCapabilities],
        validFrom: toDate(prev?.validFrom) ?? now,
        validUntil: sub.validUntil!,
        billingOwnerUid: ownerUid,
        provider: sub.provider,
        sourceRef: accountId,
        campaignId: null,
        autoRenew: sub.autoRenew,
        productId: sub.productId,
        periodStart: sub.periodStart ?? toDate(prev?.periodStart) ?? now,
        updatedAt: now,
      };
      changed =
        !prev ||
        prev.status !== next.status ||
        prev.autoRenew !== next.autoRenew ||
        prev.environment !== next.environment ||
        toDate(prev.validUntil)?.getTime() !== next.validUntil.getTime() ||
        toDate(prev.periodStart)?.getTime() !== next.periodStart.getTime();
      tx.set(grantRef, next);
    } else if (grant.exists && sub.status !== 'pending') {
      // Ended (expired, on hold, revoked, refunded): the grant follows, kept for history.
      const until = sub.validUntil ?? toDate(grant.get('validUntil'))!;
      const status = grants ? 'expired' : sub.status;
      changed =
        grant.get('status') !== status ||
        grant.get('autoRenew') !== sub.autoRenew ||
        toDate(grant.get('validUntil'))?.getTime() !== until.getTime();
      if (changed) {
        tx.update(grantRef, {
          status,
          validUntil: until,
          autoRenew: sub.autoRenew,
          updatedAt: now,
        });
      }
    }
    if (changed) {
      tx.set(
        db.doc(`families/${familyId}`),
        { entitlementVersion: FieldValue.increment(1) },
        { merge: true },
      );
    }
    return {
      outcome: live ? 'active' : sub.status === 'pending' ? 'pending' : 'expired',
      familyId,
      accountId,
      validUntil: sub.validUntil,
      changed,
    };
  });
  console.info('billing applied', {
    account: accountId,
    outcome: result.outcome,
    status: sub.status,
    environment: sub.environment,
    changed: result.changed,
  });
  return result;
}

/** Google purchases are refunded unless acknowledged within 3 days; failures retry next time. */
async function acknowledgeIfNeeded(
  adapters: BillingAdapters,
  sub: StoreSubscription,
  result: ApplyResult,
): Promise<void> {
  if (sub.provider !== 'google' || !sub.needsAcknowledge || result.outcome !== 'active') return;
  try {
    await adapters.google!.acknowledge(sub.packageName!, sub.productId, sub.storeRef);
  } catch (error) {
    console.warn('billing acknowledge failed', {
      account: result.accountId,
      error: error instanceof Error ? error.name : 'unknown',
    });
  }
}

function premiumBillingOn(ctx: EntitlementContext): boolean {
  return isFlagOnForFamily(
    ctx.flags.premium_billing,
    ctx.familyId,
    familyBucket(ctx.familyId),
    ctx.family.internal,
  );
}

const isOwner = (ctx: EntitlementContext) =>
  ctx.member !== null && familyCan(ctx.member, 'billing.manage');

/**
 * `startPurchase` (PR01): the family owner (D-072 #1) asks to buy a configured product; the intent
 * id becomes the store account token so the server knows which household a transaction is for.
 */
export async function startPurchase(
  db: Firestore,
  adapters: BillingAdapters,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<StartPurchaseAnswer> {
  const parsed = startPurchaseRequestSchema.safeParse(data);
  if (!parsed.success) throw new BillingError('invalid-argument', 'bad-request');
  const req = parsed.data;
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, environment);
  if (!ctx.member) throw gateError('NOT_MEMBER');
  if (!isOwner(ctx)) throw gateError('ROLE_DENIED');
  if (!premiumBillingOn(ctx)) throw gateError('FEATURE_DISABLED');
  if (!ctx.family.country || !ctx.config.regions.advanced.includes(ctx.family.country)) {
    throw gateError('REGION_UNAVAILABLE');
  }
  requireAdapter(adapters, req.provider);
  const config = await readBillingConfig(db);
  const productId = config.products.find((p) => p.key === req.productKey)?.[req.provider];
  if (!productId) throw new BillingError('failed-precondition', 'billing-not-configured');
  const intentId = randomUUID();
  await db.doc(`purchaseIntents/${intentId}`).create({
    familyId: ctx.familyId,
    babyId: req.babyId,
    uid,
    entryPoint: req.entryPoint,
    resume: req.resume,
    provider: req.provider,
    productKey: req.productKey,
    productId,
    createdAt: now,
    expiresAt: new Date(now.getTime() + intentDays * 86_400_000),
  });
  return { intentId, accountToken: intentId, productId };
}

const answer = (
  outcome: PurchaseAnswer['outcome'],
  validUntil: Date | null,
  resume: PurchaseAnswer['resume'],
): PurchaseAnswer => ({ outcome, validUntil: validUntil?.toISOString() ?? null, resume });

/**
 * `verifyPurchase` (PR02): the store said the purchase went through; the server asks the store
 * itself, binds the subscription to the intent's household and grants while it is active or in
 * grace. Answers the intent's resume (MO03 "tiếp tục đúng mẫu & ảnh", M17).
 */
export async function verifyPurchase(
  db: Firestore,
  adapters: BillingAdapters,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<PurchaseAnswer> {
  const parsed = verifyPurchaseRequestSchema.safeParse(data);
  if (!parsed.success) throw new BillingError('invalid-argument', 'bad-request');
  const req = parsed.data;
  requireAdapter(adapters, req.provider);
  const intent = await db.doc(`purchaseIntents/${req.intentId}`).get();
  if (!intent.exists || intent.get('provider') !== req.provider) {
    return answer('not_found', null, null);
  }
  const resume = (intent.get('resume') as PurchaseAnswer['resume'] | undefined) ?? null;
  const ctx = await loadEntitlementContext(
    db,
    uid,
    intent.get('babyId') as string,
    now,
    environment,
  );
  if (!isOwner(ctx) || ctx.familyId !== intent.get('familyId')) {
    return answer('not_owner', null, null);
  }
  const config = await readBillingConfig(db);
  const sub = await fetchSubscription(
    adapters,
    config,
    req.provider === 'apple'
      ? { provider: 'apple', transactionId: req.transactionId }
      : { provider: 'google', purchaseToken: req.purchaseToken },
    now,
  );
  if (!sub) return answer('not_found', null, resume);
  const result = await applyStoreStatus(db, sub, { familyId: ctx.familyId }, now);
  await acknowledgeIfNeeded(adapters, sub, result);
  return answer(result.outcome, result.outcome === 'active' ? result.validUntil : null, resume);
}

/**
 * `restorePurchase` (PR01 / PR03 "Khôi phục"): the owner's store purchases are re-verified and
 * refreshed for this household; one bound to another household stays there (`already_bound`).
 */
export async function restorePurchase(
  db: Firestore,
  adapters: BillingAdapters,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<PurchaseAnswer> {
  const parsed = restorePurchaseRequestSchema.safeParse(data);
  if (!parsed.success) throw new BillingError('invalid-argument', 'bad-request');
  const req = parsed.data;
  requireAdapter(adapters, req.provider);
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, environment);
  if (!isOwner(ctx)) return answer('not_owner', null, null);
  const config = await readBillingConfig(db);
  const refs =
    req.provider === 'apple'
      ? req.transactionIds.map((transactionId) => ({ provider: 'apple' as const, transactionId }))
      : req.purchases.map((p) => ({ provider: 'google' as const, purchaseToken: p.purchaseToken }));
  const results: ApplyResult[] = [];
  const seen = new Set<string>();
  for (const ref of refs) {
    const sub = await fetchSubscription(adapters, config, ref, now);
    if (!sub || seen.has(sub.originalId)) continue;
    seen.add(sub.originalId);
    const result = await applyStoreStatus(db, sub, { familyId: ctx.familyId }, now);
    await acknowledgeIfNeeded(adapters, sub, result);
    results.push(result);
  }
  const best = (o: PurchaseAnswer['outcome']) => results.filter((r) => r.outcome === o);
  const active = best('active').sort(
    (a, b) => (b.validUntil?.getTime() ?? 0) - (a.validUntil?.getTime() ?? 0),
  )[0];
  if (active) return answer('active', active.validUntil, null);
  for (const o of ['already_bound', 'pending', 'expired'] as const) {
    if (best(o).length) return answer(o, null, null);
  }
  return answer('not_found', null, null);
}

// ---------------------------------------------------------------------------------------------
// Store notifications and the reconciler: a notification only triggers a refetch (M07).
// ---------------------------------------------------------------------------------------------

export interface StoreEvent {
  provider: BillingProvider;
  /** Apple notificationUUID / Pub/Sub messageId. */
  eventId: string;
  /** Notification type, for the ledger only. */
  kind: string;
  ref: { provider: 'apple'; transactionId: string } | { provider: 'google'; purchaseToken: string };
}

/**
 * One store event: deduped by id in `billingEvents`, then the current status is refetched and
 * reconciled (an event's own payload is never applied, so old or repeated events cannot move a
 * subscription backwards).
 */
export async function handleStoreEvent(
  db: Firestore,
  adapters: BillingAdapters,
  event: StoreEvent,
  now: Date,
): Promise<'processed' | 'duplicate' | 'ignored' | 'not-configured'> {
  if (!adapters[event.provider]) return 'not-configured';
  const eventRef = db.doc(`billingEvents/${event.provider}_${sha256(event.eventId).slice(0, 40)}`);
  const fresh = await db.runTransaction(async (tx) => {
    const seen = await tx.get(eventRef);
    if (seen.exists && seen.get('processedAt')) return false;
    if (!seen.exists) {
      tx.create(eventRef, {
        provider: event.provider,
        kind: event.kind.slice(0, 60),
        refHash: sha256(
          event.ref.provider === 'apple' ? event.ref.transactionId : event.ref.purchaseToken,
        ).slice(0, 40),
        receivedAt: now,
        processedAt: null,
        outcome: null,
      });
    }
    return true;
  });
  if (!fresh) return 'duplicate';
  const config = await readBillingConfig(db);
  const sub = await fetchSubscription(adapters, config, event.ref, now);
  const result = sub ? await applyStoreStatus(db, sub, null, now) : null;
  if (sub && result) await acknowledgeIfNeeded(adapters, sub, result);
  await eventRef.update({
    processedAt: now,
    outcome: result?.outcome ?? 'not_found',
    account: result?.accountId ?? null,
  });
  return result && result.familyId ? 'processed' : 'ignored';
}

/**
 * App Store Server Notifications V2 body (the future `appStoreNotifications` HTTP endpoint):
 * answers the HTTP status. A payload that does not verify is refused with 401 and nothing is
 * written.
 */
export async function appleNotification(
  db: Firestore,
  adapters: BillingAdapters,
  body: unknown,
  now: Date,
): Promise<number> {
  if (!adapters.apple) return 503;
  const signedPayload = (body as { signedPayload?: unknown } | null)?.signedPayload;
  if (typeof signedPayload !== 'string' || signedPayload.length > 100_000) return 400;
  let n: AppleNotification;
  try {
    n = await adapters.apple.verifyNotification(signedPayload);
  } catch {
    console.warn('billing apple notification refused');
    return 401;
  }
  if (n.notificationType === 'TEST' || !n.originalTransactionId) return 200;
  await handleStoreEvent(
    db,
    adapters,
    {
      provider: 'apple',
      eventId: n.notificationUUID,
      kind: n.subtype ? `${n.notificationType}.${n.subtype}` : n.notificationType,
      ref: { provider: 'apple', transactionId: n.originalTransactionId },
    },
    now,
  );
  return 200;
}

/**
 * Play real-time developer notification (the future `playRtdn` Pub/Sub trigger): [data] is the
 * decoded message JSON. Only subscription notifications for our package are handled.
 */
export async function playNotification(
  db: Firestore,
  adapters: BillingAdapters,
  messageId: string,
  data: unknown,
  now: Date,
): Promise<'processed' | 'duplicate' | 'ignored' | 'not-configured'> {
  if (!adapters.google) return 'not-configured';
  const m = data as {
    packageName?: string;
    subscriptionNotification?: { notificationType?: number; purchaseToken?: string };
  } | null;
  const token = m?.subscriptionNotification?.purchaseToken;
  if (!m || typeof token !== 'string' || token.length > 4000) return 'ignored';
  const config = await readBillingConfig(db);
  if (!config.googlePackage || m.packageName !== config.googlePackage) return 'ignored';
  return handleStoreEvent(
    db,
    adapters,
    {
      provider: 'google',
      eventId: messageId,
      kind: `subscription.${m.subscriptionNotification?.notificationType ?? 0}`,
      ref: { provider: 'google', purchaseToken: token },
    },
    now,
  );
}

/**
 * Every 6 h: subscriptions ending within 48 h (or ended without a notice yet) and those in grace,
 * on hold or pending are refetched and reconciled. A no-op without adapters.
 */
export async function reconcileSubscriptions(
  db: Firestore,
  adapters: BillingAdapters,
  now: Date,
): Promise<number> {
  if (!adapters.apple && !adapters.google) return 0;
  const [ending, unsettled] = await Promise.all([
    db
      .collection('billingAccounts')
      .where('expiresAt', '<=', new Date(now.getTime() + 48 * 3600_000))
      .where('expiresAt', '>=', new Date(now.getTime() - 30 * 86_400_000))
      .get(),
    db.collection('billingAccounts').where('status', 'in', ['grace', 'on_hold', 'pending']).get(),
  ]);
  const docs = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
  for (const d of ending.docs) if (d.get('status') === 'active') docs.set(d.id, d);
  for (const d of unsettled.docs) docs.set(d.id, d);
  const config = await readBillingConfig(db);
  let n = 0;
  for (const d of docs.values()) {
    const provider = d.get('provider') as BillingProvider;
    const storeRef = d.get('storeRef') as string | undefined;
    if (!adapters[provider] || !storeRef) continue;
    try {
      const sub = await fetchSubscription(
        adapters,
        config,
        provider === 'apple'
          ? { provider, transactionId: storeRef }
          : { provider, purchaseToken: storeRef },
        now,
      );
      if (!sub) continue;
      const result = await applyStoreStatus(db, sub, null, now);
      await acknowledgeIfNeeded(adapters, sub, result);
      n++;
    } catch (error) {
      console.warn('billing reconcile failed', {
        account: d.id,
        error: error instanceof Error ? error.name : 'unknown',
      });
    }
  }
  if (n) console.info('billing reconciled', { n });
  return n;
}
