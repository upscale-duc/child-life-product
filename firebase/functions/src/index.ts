import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall, onRequest, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2';
import { defaultLimits, functionsRegion, limitsSchema } from '@child-life/contracts';
import { currentProjectId, webOriginFor } from './env.js';
import {
  FamilyError,
  acceptInvite,
  claimAnonymous,
  createInvite,
  expireMemberships,
  inviteForLanding,
  previewInvite,
  regenerateInvite,
  removeMember,
  revokeInvite,
  sendInviteEmail,
  updateMember,
  type Caller,
} from './family.js';
import { deliverMail, unsubscribe, type MailSender } from './mail.js';
import { localeFromHeader, renderInvitePage, renderUnsubscribePage } from './pages.js';
import { onRecordWritten, purgeDeletedRecords } from './care.js';
import { BabyError, createBaby, getBabyAvatar, setBabyAvatar, type AvatarStore } from './babies.js';
import { handlePing, PingError } from './ping.js';
import { isMirroredConfigId, publicProjection } from './config-mirror.js';

initializeApp();
setGlobalOptions({ region: functionsRegion, maxInstances: 10 });

/** S0 round trip: proves the app reaches the backend of its own environment. */
export const ping = onCall((request) => {
  try {
    const response = handlePing(request.data, currentProjectId(), new Date());
    logger.info('ping', { opId: response.opId, authenticated: request.auth != null });
    return response;
  } catch (error) {
    if (error instanceof PingError) throw new HttpsError(error.code, error.message);
    logger.error('ping failed', { error: String(error) });
    throw new HttpsError('internal', 'Ping failed');
  }
});

/** Copies validated `config/{flags|limits}` to `publicConfig/*` for clients (P-122, D-011). */
export const mirrorPublicConfig = onDocumentWritten('config/{docId}', async (event) => {
  const docId = event.params.docId;
  if (!isMirroredConfigId(docId)) return;

  const target = getFirestore().doc(`publicConfig/${docId}`);
  const after = event.data?.after;
  if (!after?.exists) {
    await target.delete();
    logger.warn('config removed; public projection deleted', { docId });
    return;
  }

  const projection = publicProjection(docId, after.data());
  if (projection == null) {
    logger.error('invalid config document; public projection left unchanged', { docId });
    return;
  }
  await target.set({ ...projection, updatedAt: FieldValue.serverTimestamp() });
  logger.info('public config mirrored', { docId });
});

/** Signed-in account (not a temporary "Vào ngay" identity) or an HttpsError. */
function requireAccount(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  if (request.auth.token.firebase.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'An account is required', {
      reason: 'account-required',
    });
  }
  return request.auth.uid;
}

function asHttpsError(operation: string, error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof BabyError || error instanceof FamilyError) {
    return new HttpsError(error.code, error.reason, { reason: error.reason });
  }
  // Never log request payloads: they carry the child's name and date of birth.
  logger.error(`${operation} failed`, { error: String(error) });
  return new HttpsError('internal', `${operation} failed`);
}

const avatarStore = (): AvatarStore => {
  const bucket = getStorage().bucket();
  return {
    save: (path, bytes) =>
      bucket.file(path).save(bytes, {
        contentType: 'image/jpeg',
        resumable: false,
        metadata: { cacheControl: 'private, max-age=0' },
      }),
    read: async (path) => {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      return exists ? (await file.download())[0] : null;
    },
    delete: async (path) => {
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
  };
};

async function familyQuotaBytes(): Promise<number> {
  const snapshot = await getFirestore().doc('config/limits').get();
  const parsed = limitsSchema.safeParse(snapshot.data());
  return parsed.success ? parsed.data.familyQuotaBytes : defaultLimits.familyQuotaBytes;
}

/** Creates a baby profile + owner membership (Figma 11 → 12 "Xong", R-043, P-001). */
export const createBabyProfile = onCall(async (request) => {
  const uid = requireAccount(request);
  try {
    const response = await createBaby(
      getFirestore(),
      uid,
      request.data,
      new Date(),
      await familyQuotaBytes(),
    );
    logger.info('baby created', { babyId: response.babyId, created: response.created });
    return response;
  } catch (error) {
    throw asHttpsError('createBabyProfile', error);
  }
});

/** Sets the baby's avatar: preset or a family-private photo (11c). */
export const setBabyAvatarImage = onCall(async (request) => {
  const uid = requireAccount(request);
  try {
    return await setBabyAvatar(getFirestore(), avatarStore(), uid, request.data, new Date());
  } catch (error) {
    throw asHttpsError('setBabyAvatarImage', error);
  }
});

/** Returns the profile photo to active members only; Storage itself stays closed to clients. */
export const getBabyAvatarImage = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  try {
    return await getBabyAvatar(getFirestore(), avatarStore(), request.auth.uid, request.data);
  } catch (error) {
    throw asHttpsError('getBabyAvatarImage', error);
  }
});

// ---------- S3: family, invites, memberships ----------

function callerOf(request: CallableRequest): Caller {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  const token = request.auth.token;
  const provider = token.firebase.sign_in_provider;
  return {
    uid: request.auth.uid,
    anonymous: provider === 'anonymous',
    emailTrusted:
      token.email_verified === true || provider === 'google.com' || provider === 'apple.com',
  };
}

/** Client address for P-021 rate limits (first hop of X-Forwarded-For behind Google's front end). */
function clientIp(request: CallableRequest): string | null {
  const forwarded = request.rawRequest.headers['x-forwarded-for'];
  const first = typeof forwarded === 'string' ? forwarded.split(',')[0]?.trim() : undefined;
  return first || request.rawRequest.ip || null;
}

const familyCall = <T>(name: string, run: (request: CallableRequest) => Promise<T>) =>
  onCall(async (request) => {
    try {
      return await run(request);
    } catch (error) {
      throw asHttpsError(name, error);
    }
  });

export const createFamilyInvite = familyCall('createFamilyInvite', (r) =>
  createInvite(getFirestore(), callerOf(r), r.data, new Date()),
);
export const regenerateFamilyInvite = familyCall('regenerateFamilyInvite', (r) =>
  regenerateInvite(getFirestore(), callerOf(r), r.data, new Date()),
);
export const revokeFamilyInvite = familyCall('revokeFamilyInvite', (r) =>
  revokeInvite(getFirestore(), callerOf(r), r.data, new Date()),
);
export const emailFamilyInvite = familyCall('emailFamilyInvite', (r) =>
  sendInviteEmail(getFirestore(), callerOf(r), r.data, new Date()),
);
/** Works signed out (screen 16 comes before choosing how to join). */
export const previewFamilyInvite = familyCall('previewFamilyInvite', (r) =>
  previewInvite(getFirestore(), r.auth?.uid ?? null, clientIp(r), r.data, new Date()),
);
export const acceptFamilyInvite = familyCall('acceptFamilyInvite', (r) =>
  acceptInvite(getFirestore(), callerOf(r), clientIp(r), r.data, new Date()),
);
export const updateFamilyMember = familyCall('updateFamilyMember', (r) =>
  updateMember(getFirestore(), callerOf(r), r.data, new Date()),
);
export const removeFamilyMember = familyCall('removeFamilyMember', (r) =>
  removeMember(getFirestore(), callerOf(r), r.data, new Date()),
);
export const claimAnonymousIdentity = familyCall('claimAnonymousIdentity', (r) =>
  claimAnonymous(
    getFirestore(),
    {
      verify: async (idToken) => {
        const decoded = await getAuth().verifyIdToken(idToken);
        return { uid: decoded.uid, provider: decoded.firebase.sign_in_provider };
      },
      deleteUser: (uid) => getAuth().deleteUser(uid),
    },
    callerOf(r),
    r.data,
    new Date(),
  ),
);

/** P-005: hourly expiry of memberships whose access end date has passed. */
export const expireFamilyMemberships = onSchedule('every 60 minutes', async () => {
  const expired = await expireMemberships(getFirestore(), new Date());
  if (expired > 0) logger.info('memberships expired', { count: expired });
});

// ---------- Care (S4) ----------

/** Keeps "Đã ghi hôm nay" per day and "đã ghi N lần" per member in step with the records. */
export const onCareRecordWrite = onDocumentWritten(
  'babies/{babyId}/records/{recordId}',
  async (event) => {
    const change = event.data;
    if (!change) return;
    const { days } = await onRecordWritten(
      getFirestore(),
      event.params.babyId,
      change.before.exists ? change.before : null,
      change.after.exists ? change.after : null,
      new Date(),
    );
    logger.debug('care summaries recomputed', { days: days.length });
  },
);

/** "Đã xoá gần đây": soft-deleted records leave after 30 days (P-009). */
export const purgeCareBin = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'Asia/Ho_Chi_Minh' },
  async () => {
    const purged = await purgeDeletedRecords(getFirestore(), new Date());
    if (purged > 0) logger.info('care records purged', { count: purged });
  },
);

// ---------- Email (D-020: AWS SES) ----------

/** Set with `firebase functions:secrets:set SES_ACCESS_KEY_ID` (value "unset" = not configured). */
const sesAccessKeyId = defineSecret('SES_ACCESS_KEY_ID');
const sesSecretAccessKey = defineSecret('SES_SECRET_ACCESS_KEY');
const sesRegion = defineString('SES_REGION', { default: 'ap-southeast-1' });
const mailFrom = defineString('MAIL_FROM', { default: 'Child Life <hello@childlife.app>' });

function sesSender(): MailSender | null {
  const keyId = sesAccessKeyId.value();
  const secret = sesSecretAccessKey.value();
  if (!keyId || keyId === 'unset' || !secret || secret === 'unset') return null;
  const client = new SESv2Client({
    region: sesRegion.value(),
    credentials: { accessKeyId: keyId, secretAccessKey: secret },
  });
  return {
    send: async (mail) => {
      await client.send(
        new SendEmailCommand({
          FromEmailAddress: mailFrom.value(),
          Destination: { ToAddresses: [mail.to] },
          Content: {
            Simple: {
              Subject: { Data: mail.subject, Charset: 'UTF-8' },
              Body: {
                Html: { Data: mail.html, Charset: 'UTF-8' },
                Text: { Data: mail.text, Charset: 'UTF-8' },
              },
              Headers: [
                { Name: 'List-Unsubscribe', Value: `<${mail.unsubscribeUrl}>` },
                { Name: 'List-Unsubscribe-Post', Value: 'List-Unsubscribe=One-Click' },
              ],
            },
          },
        }),
      );
    },
  };
}

export const deliverQueuedMail = onDocumentCreated(
  { document: 'mail/{mailId}', secrets: [sesAccessKeyId, sesSecretAccessKey] },
  async (event) => {
    if (!event.data) return;
    const status = await deliverMail(event.data, sesSender(), {
      webOrigin: webOriginFor(currentProjectId()),
      now: new Date(),
    });
    logger.info('mail processed', { mailId: event.params.mailId, status });
  },
);

/** Retries mail waiting for the provider or after a transient failure. */
export const retryQueuedMail = onSchedule(
  { schedule: 'every 15 minutes', secrets: [sesAccessKeyId, sesSecretAccessKey] },
  async () => {
    const sender = sesSender();
    if (!sender) return;
    const due = await getFirestore()
      .collection('mail')
      .where('status', 'in', ['waiting-provider', 'retry'])
      .limit(50)
      .get();
    for (const doc of due.docs) {
      await deliverMail(doc, sender, {
        webOrigin: webOriginFor(currentProjectId()),
        now: new Date(),
      });
    }
  },
);

// ---------- Pages on the landing host ----------

export const inviteLanding = onRequest(async (req, res) => {
  const token = req.path.split('/').filter(Boolean).pop() ?? '';
  const { preview, code } = await inviteForLanding(getFirestore(), token, new Date());
  res.set('Cache-Control', 'private, no-store');
  res.set('X-Robots-Tag', 'noindex');
  res
    .status(preview.status === 'valid' ? 200 : 404)
    .send(renderInvitePage(localeFromHeader(req.get('accept-language')), preview, code));
});

export const emailUnsubscribe = onRequest(async (req, res) => {
  const token = req.path.split('/').filter(Boolean).pop() ?? '';
  const ok = await unsubscribe(getFirestore(), token, new Date());
  res.set('Cache-Control', 'private, no-store');
  res.set('X-Robots-Tag', 'noindex');
  res
    .status(ok ? 200 : 404)
    .send(renderUnsubscribePage(localeFromHeader(req.get('accept-language')), ok));
});
