import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';
import { getStorage } from 'firebase-admin/storage';
import { defaultLimits, functionsRegion, limitsSchema } from '@child-life/contracts';
import { currentProjectId } from './env.js';
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
    throw new HttpsError('permission-denied', 'An account is required', { reason: 'account-required' });
  }
  return request.auth.uid;
}

function asHttpsError(operation: string, error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof BabyError) return new HttpsError(error.code, error.reason, { reason: error.reason });
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
    const response = await createBaby(getFirestore(), uid, request.data, new Date(), await familyQuotaBytes());
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
