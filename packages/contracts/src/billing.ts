import { z } from 'zod';
import type { GrantEnvironment, GrantStatus } from './entitlements.js';

/**
 * Billing (brief p.9, plan §5.2, D-072 #1 / #6): `in_app_purchase` on the phone, verification
 * and lifecycle on the server. A client's "success" is never proof of payment; the provider's
 * current status is (Apple App Store Server API / Notifications V2, Google Play Developer API +
 * RTDN). One verified subscription grants one household; only the family owner buys.
 */

export const billingProviders = ['apple', 'google'] as const;
export type BillingProvider = (typeof billingProviders)[number];

/**
 * `config/billing` (server; public projection for the paywall): store product ids per period.
 * Prices, currency and renewal copy always come from the storefront, never from here (brief p.4).
 */
export const billingConfigSchema = z.object({
  products: z
    .array(
      z.object({
        key: z.enum(['monthly', 'yearly']),
        apple: z.string().min(1).max(120).nullable(),
        google: z.string().min(1).max(120).nullable(),
      }),
    )
    .max(4),
  /** Apple bundle / Google package the verifier accepts for this project. */
  appleBundleId: z.string().min(1).max(200).nullable(),
  googlePackage: z.string().min(1).max(200).nullable(),
});
export type BillingConfig = z.infer<typeof billingConfigSchema>;

export const defaultBillingConfig: BillingConfig = {
  products: [],
  appleBundleId: null,
  googlePackage: null,
};

export const purchaseEntryPoints = ['rhythm', 'templates', 'plan'] as const;

/** Where to come back after a purchase (MO03 "tiếp tục đúng mẫu & ảnh"). */
export const purchaseResumeSchema = z
  .object({
    kind: z.enum(['card', 'video', 'rhythm']),
    templateId: z.string().max(80).nullable(),
    /** Opaque draft key kept on the phone (selected photos never leave it). */
    draftRef: z.string().max(80).nullable(),
  })
  .strict();

/** `startPurchase`: the owner asks to buy; the intent id becomes the store account token. */
export const startPurchaseRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  productKey: z.enum(['monthly', 'yearly']),
  provider: z.enum(billingProviders),
  entryPoint: z.enum(purchaseEntryPoints),
  resume: purchaseResumeSchema.nullable(),
});

export interface StartPurchaseAnswer {
  intentId: string;
  /** Apple `appAccountToken` (a UUID) / Google `obfuscatedAccountId`: binds the purchase to the
   * intent, so the server can tell which household the store transaction is for. */
  accountToken: string;
  productId: string;
}

/** `verifyPurchase`: what the phone got from the store; the server re-checks with the provider. */
export const verifyPurchaseRequestSchema = z.discriminatedUnion('provider', [
  z.object({
    provider: z.literal('apple'),
    intentId: z.uuid(),
    /** StoreKit 2 transaction id; the server fetches the signed transaction itself. */
    transactionId: z.string().min(1).max(64),
  }),
  z.object({
    provider: z.literal('google'),
    intentId: z.uuid(),
    productId: z.string().min(1).max(120),
    purchaseToken: z.string().min(1).max(4000),
  }),
]);

/** `restorePurchase` (PR01 / PR03 "Khôi phục"): never moves a subscription to another household. */
export const restorePurchaseRequestSchema = z.discriminatedUnion('provider', [
  z.object({
    provider: z.literal('apple'),
    babyId: z.string().min(1).max(128),
    transactionIds: z.array(z.string().min(1).max(64)).min(1).max(20),
  }),
  z.object({
    provider: z.literal('google'),
    babyId: z.string().min(1).max(128),
    purchases: z
      .array(
        z.object({
          productId: z.string().min(1).max(120),
          purchaseToken: z.string().min(1).max(4000),
        }),
      )
      .min(1)
      .max(20),
  }),
]);

export interface PurchaseAnswer {
  /** `pending`: not granted, keep the selection and allow refresh (PR02 Pending). */
  outcome: 'active' | 'pending' | 'expired' | 'already_bound' | 'not_owner' | 'not_found';
  validUntil: string | null;
  resume: z.infer<typeof purchaseResumeSchema> | null;
}

/** Provider-neutral subscription state the grant is built from. */
export interface NormalizedSubscription {
  provider: BillingProvider;
  /** Apple originalTransactionId / Google first purchase token (linked chain root). */
  originalId: string;
  productId: string;
  status: GrantStatus;
  /** Exclusive end of access (grace end while in grace). */
  validUntil: Date | null;
  autoRenew: boolean | null;
  environment: GrantEnvironment;
  /** The token the purchase was bound with (intent id), when the store returns it. */
  accountToken: string | null;
  /** Google: must be acknowledged within 3 days or it is refunded. */
  needsAcknowledge: boolean;
}

/** Apple: decoded JWSTransaction + JWSRenewalInfo + the status from Get All Subscription Statuses. */
export interface AppleStatusInput {
  /** 1 active · 2 expired · 3 billing retry · 4 billing grace period · 5 revoked. */
  status: 1 | 2 | 3 | 4 | 5;
  transaction: {
    originalTransactionId: string;
    productId: string;
    expiresDate?: number;
    revocationDate?: number;
    appAccountToken?: string;
    environment: 'Sandbox' | 'Production' | 'Xcode' | 'LocalTesting';
  };
  renewal?: { autoRenewStatus?: 0 | 1; gracePeriodExpiresDate?: number };
}

export function normalizeApple(x: AppleStatusInput): NormalizedSubscription {
  const t = x.transaction;
  const expires = t.expiresDate ? new Date(t.expiresDate) : null;
  const grace = x.renewal?.gracePeriodExpiresDate
    ? new Date(x.renewal.gracePeriodExpiresDate)
    : null;
  const status: GrantStatus =
    t.revocationDate || x.status === 5
      ? 'revoked'
      : x.status === 1
        ? 'active'
        : x.status === 4
          ? 'grace'
          : x.status === 3
            ? 'on_hold'
            : 'expired';
  return {
    provider: 'apple',
    originalId: t.originalTransactionId,
    productId: t.productId,
    status,
    validUntil: status === 'grace' ? (grace ?? expires) : expires,
    autoRenew: x.renewal?.autoRenewStatus === undefined ? null : x.renewal.autoRenewStatus === 1,
    environment: t.environment === 'Production' ? 'production' : 'test',
    accountToken: t.appAccountToken ?? null,
    needsAcknowledge: false,
  };
}

/** Google: `purchases.subscriptionsv2.get` (the fields used). */
export interface GoogleStatusInput {
  subscriptionState:
    | 'SUBSCRIPTION_STATE_PENDING'
    | 'SUBSCRIPTION_STATE_ACTIVE'
    | 'SUBSCRIPTION_STATE_PAUSED'
    | 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD'
    | 'SUBSCRIPTION_STATE_ON_HOLD'
    | 'SUBSCRIPTION_STATE_CANCELED'
    | 'SUBSCRIPTION_STATE_EXPIRED'
    | 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED'
    | 'SUBSCRIPTION_STATE_UNSPECIFIED';
  lineItems: {
    productId: string;
    expiryTime?: string;
    autoRenewingPlan?: { autoRenewEnabled?: boolean };
  }[];
  testPurchase?: object;
  acknowledgementState?: 'ACKNOWLEDGEMENT_STATE_PENDING' | 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  linkedPurchaseToken?: string;
}

/** [token] is the purchase token the status was fetched with (the chain root when not linked). */
export function normalizeGoogle(
  x: GoogleStatusInput,
  token: string,
  now: Date,
): NormalizedSubscription {
  const item = x.lineItems[0];
  const expires = item?.expiryTime ? new Date(item.expiryTime) : null;
  const before = (d: Date | null) => d !== null && d.getTime() > now.getTime();
  const status: GrantStatus = (() => {
    switch (x.subscriptionState) {
      case 'SUBSCRIPTION_STATE_ACTIVE':
        return 'active';
      case 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD':
        return 'grace';
      // Cancelled auto-renew keeps access until expiry (brief p.9, M05).
      case 'SUBSCRIPTION_STATE_CANCELED':
        return before(expires) ? 'active' : 'expired';
      case 'SUBSCRIPTION_STATE_PENDING':
        return 'pending';
      case 'SUBSCRIPTION_STATE_ON_HOLD':
      case 'SUBSCRIPTION_STATE_PAUSED':
        return 'on_hold';
      default:
        return 'expired';
    }
  })();
  return {
    provider: 'google',
    originalId: x.linkedPurchaseToken ?? token,
    productId: item?.productId ?? '',
    status,
    validUntil: expires,
    autoRenew:
      x.subscriptionState === 'SUBSCRIPTION_STATE_CANCELED'
        ? false
        : (item?.autoRenewingPlan?.autoRenewEnabled ?? null),
    environment: x.testPurchase ? 'test' : 'production',
    accountToken: x.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null,
    needsAcknowledge:
      x.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING' &&
      (status === 'active' || status === 'grace'),
  };
}

/** `billingAccounts/{provider}_{hash(originalId)}`: one store subscription → one household. */
export function billingAccountId(provider: BillingProvider, originalIdHash: string): string {
  return `${provider}_${originalIdHash}`;
}
