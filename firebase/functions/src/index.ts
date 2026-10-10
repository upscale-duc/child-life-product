import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall, onRequest, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { getMessaging } from 'firebase-admin/messaging';
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
import { CareError, onRecordWritten, purgeDeletedRecords, resolveSleepConflict } from './care.js';
import { BabyError, createBaby, getBabyAvatar, setBabyAvatar, type AvatarStore } from './babies.js';
import { handlePing, PingError } from './ping.js';
import { bucketOpen, bucketPurgeStore, bucketStore, sharpImages } from './images.js';
import {
  AccountError,
  answerOwnership,
  createSupportTicket,
  expireExports,
  familyStorage,
  maybeStorageNotice,
  offerOwnership,
  requestAccountDeletion,
  requestBabyDeletion,
  requestExport,
  requestStorage,
  resumeDeletionJobs,
  runDeletionJob,
  runExport,
  signOutDevice,
  updateBabyProfile,
  updateMyProfile,
  type AccountCaller,
  type JobDeps,
} from './account.js';
import { addToAlbum, createAlbum, deleteAlbum, removeFromAlbum, updateAlbum } from './albums.js';
import { deliverNotice, onMessageCreated, onReactionWritten, type PushSender } from './social.js';
import { openAiProvider, templateProvider, type AiProvider } from './ai.js';
import {
  StaffError,
  aiStats,
  badges,
  claimTicket,
  closeTicket,
  decideStorage,
  listAudit,
  listJobs,
  listStorageRequests,
  listTickets,
  overview,
  readFlags,
  replyTicket,
  rerunJob,
  setFlag,
  systemHealth,
  ticketDetail,
  type AccountLister,
  type Staff,
} from './staff.js';
import {
  LinkError,
  createShareLink,
  expireLinks,
  handleShare,
  recordCard,
  revokeShareLink,
} from './links.js';
import {
  StoryError,
  deleteStory,
  requestSuggestion,
  saveStory,
  storyAssist,
  suggestForAll,
} from './stories.js';
import {
  MemoryError,
  cancelUploads,
  createMemory,
  onMediaWritten,
  processUpload,
  purgeMediaBin,
  reconcileFamilyUsage,
  releaseStaleUploads,
  reserveUploads,
  updateMedia,
} from './memories.js';
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

/** 27 "Giữ bản đã chọn" (R-075). */
export const resolveSleepOverlap = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  try {
    return await resolveSleepConflict(getFirestore(), request.auth.uid, request.data, new Date());
  } catch (error) {
    if (error instanceof CareError) {
      throw new HttpsError(error.code, error.reason, { reason: error.reason });
    }
    throw error;
  }
});

/** "Đã xoá gần đây": soft-deleted records leave after 30 days (P-009). */
export const purgeCareBin = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'Asia/Ho_Chi_Minh' },
  async () => {
    const purged = await purgeDeletedRecords(getFirestore(), new Date());
    if (purged > 0) logger.info('care records purged', { count: purged });
  },
);

// ---------- Memories (S9) ----------

function memoryCall<T>(name: string, run: (uid: string, data: unknown) => Promise<T>) {
  return onCall(async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return await run(request.auth.uid, request.data);
    } catch (error) {
      if (error instanceof MemoryError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      // Never log the payload: captions and capture dates are child data.
      logger.error(`${name} failed`, { error: String(error) });
      throw new HttpsError('internal', `${name} failed`);
    }
  });
}

/** 10h "Tải lên N mục" / "Viết ghi chú": memory, items and quota reservations (P-031). */
export const createMemorySession = memoryCall('createMemorySession', (uid, data) =>
  createMemory(getFirestore(), uid, data, new Date()),
);

/** Items kept on the device for quota (R-121) try again. */
export const reserveMemoryUploads = memoryCall('reserveMemoryUploads', (uid, data) =>
  reserveUploads(getFirestore(), uid, data, new Date()),
);

/** 10i "×" on a queued or uploading item. */
export const cancelMemoryUploads = memoryCall('cancelMemoryUploads', (uid, data) =>
  cancelUploads(getFirestore(), bucketStore(getStorage().bucket()), uid, data, new Date()),
);

/** 10b3 / 10b4 / 10o batch actions: Ai thấy, Đổi ngày, Gắn mốc, Xoá, restore. */
export const updateMemoryMedia = memoryCall('updateMemoryMedia', (uid, data) =>
  updateMedia(getFirestore(), uid, data, new Date()),
);

/** Raw upload finished: validate, strip metadata, renditions, commit quota (P-031, P-033). */
export const onMediaUploaded = onObjectFinalized(
  { memory: '1GiB', timeoutSeconds: 300, concurrency: 4 },
  async (event) => {
    const path = event.data.name;
    if (!path.startsWith('babies/') || !path.includes('/uploads/')) return;
    const result = await processUpload(
      getFirestore(),
      bucketStore(getStorage().bucket(event.data.bucket)),
      sharpImages,
      path,
      new Date(),
    );
    logger.info('media upload processed', { result });
  },
);

/** Memory counts, publish state and the batch's single notification follow the items (P-030). */
export const onMemoryMediaWrite = onDocumentWritten(
  'babies/{babyId}/media/{mediaId}',
  async (event) => {
    const change = event.data;
    if (!change) return;
    await onMediaWritten(
      getFirestore(),
      event.params.babyId,
      change.after.exists ? change.after : null,
      change.before.exists ? change.before : null,
      new Date(),
    );
    // 80 % / 100 % notices follow committed bytes (13c, 13d).
    const familyId = change.after.get('familyId') as string | undefined;
    if (
      familyId &&
      change.after.get('status') === 'ready' &&
      change.before.get('status') !== 'ready'
    ) {
      await maybeStorageNotice(getFirestore(), familyId, new Date());
    }
  },
);

/** "Đã xoá gần đây" ends after 30 days (R-111, P-034). */
export const purgeMemoryBin = onSchedule(
  { schedule: 'every day 03:45', timeZone: 'Asia/Ho_Chi_Minh' },
  async () => {
    const purged = await purgeMediaBin(
      getFirestore(),
      bucketStore(getStorage().bucket()),
      new Date(),
    );
    if (purged > 0) logger.info('media purged', { count: purged });
  },
);

/** Unused reservations go back after 24 h (P-031). */
export const releaseStaleMemoryUploads = onSchedule('every 60 minutes', async () => {
  const released = await releaseStaleUploads(
    getFirestore(),
    bucketStore(getStorage().bucket()),
    new Date(),
  );
  if (released > 0) logger.info('stale uploads released', { count: released });
});

// ---------- Albums, loves, messages, notices (S10) ----------

/** "Album mới" (10d, 10h5). */
export const createMemoryAlbum = memoryCall('createMemoryAlbum', (uid, data) =>
  createAlbum(getFirestore(), uid, data, new Date()),
);

/** 10e4 rename, 10e5 cover, 10e6 audience (D-002), 10e7 sort. */
export const updateMemoryAlbum = memoryCall('updateMemoryAlbum', (uid, data) =>
  updateAlbum(getFirestore(), uid, data, new Date()),
);

/** 10b3 "Album", 10e "Thêm ảnh". */
export const addToMemoryAlbum = memoryCall('addToMemoryAlbum', (uid, data) =>
  addToAlbum(getFirestore(), uid, data, new Date()),
);

/** 10e8 "Bỏ khỏi album". */
export const removeFromMemoryAlbum = memoryCall('removeFromMemoryAlbum', (uid, data) =>
  removeFromAlbum(getFirestore(), uid, data, new Date()),
);

/** 10e10: the album only; its items stay (R-106). */
export const deleteMemoryAlbum = memoryCall('deleteMemoryAlbum', (uid, data) =>
  deleteAlbum(getFirestore(), uid, data, new Date()),
);

/** "♥ 4": love counts follow `reactions`. */
export const onLoveWrite = onDocumentWritten(
  'babies/{babyId}/reactions/{reactionId}',
  async (event) => {
    const change = event.data;
    if (!change) return;
    await onReactionWritten(
      getFirestore(),
      event.params.babyId,
      change.before.exists ? change.before : null,
      change.after.exists ? change.after : null,
    );
  },
);

/** "Nhắn ba mẹ" → one notice for the parents (D-034). */
export const onParentMessage = onDocumentCreated(
  'babies/{babyId}/messages/{messageId}',
  async (event) => {
    if (!event.data) return;
    await onMessageCreated(getFirestore(), event.params.babyId, event.data, new Date());
  },
);

const pushSender = (): PushSender | null => {
  // The emulator suite has no messaging: notices are only marked delivered there.
  if (process.env.FUNCTIONS_EMULATOR === 'true') return null;
  return {
    async send(tokens, message) {
      const result = await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title: message.title, body: message.body },
        data: message.data,
        apns: { payload: { aps: { sound: 'default' } } },
        android: { priority: 'high' },
      });
      return result.responses
        .map((r, i) => ({ r, token: tokens[i]! }))
        .filter(
          ({ r }) =>
            !r.success &&
            ['messaging/registration-token-not-registered', 'messaging/invalid-argument'].includes(
              r.error?.code ?? '',
            ),
        )
        .map(({ token }) => token);
    },
  };
};

/** Generic lock-screen notices (11b, R-120): no photo, no caption, no baby name. */
export const deliverFamilyNotice = onDocumentCreated(
  'babies/{babyId}/notifications/{noticeId}',
  async (event) => {
    const { sent } = await deliverNotice(
      getFirestore(),
      pushSender(),
      event.params.babyId,
      event.params.noticeId,
      new Date(),
    );
    logger.info('family notice delivered', { sent });
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

// ---------- S11: Me, storage, profiles, account ----------

/** Staff inbox for storage requests and help tickets (portal is the source of truth). */
const supportInbox = defineString('SUPPORT_INBOX', { default: 'support@childlife.app' });

function accountCaller(request: CallableRequest): AccountCaller {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  const token = request.auth.token;
  const locale = (request.data as { locale?: unknown } | null)?.locale === 'en' ? 'en' : 'vi';
  return {
    uid: request.auth.uid,
    email: typeof token.email === 'string' ? token.email : null,
    anonymous: token.firebase.sign_in_provider === 'anonymous',
    locale,
  };
}

const accountCall = <T>(
  name: string,
  run: (caller: AccountCaller, data: unknown) => Promise<T>,
  options: { timeoutSeconds?: number } = {},
) =>
  onCall(options, async (request) => {
    const caller = accountCaller(request);
    try {
      return await run(caller, request.data);
    } catch (error) {
      if (error instanceof AccountError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      // Never log the payload: nicknames, messages and ticket text are personal.
      logger.error(`${name} failed`, { error: String(error) });
      throw new HttpsError('internal', `${name} failed`);
    }
  });

const jobDeps = (): JobDeps => ({
  store: bucketPurgeStore(getStorage().bucket()),
  async deleteAuthUser(uid) {
    try {
      await getAuth().deleteUser(uid);
    } catch (error) {
      if ((error as { code?: string }).code !== 'auth/user-not-found') throw error;
    }
  },
});

/** 13b "Dung lượng": totals, by baby, by type, largest videos, open request. */
export const getFamilyStorage = accountCall('getFamilyStorage', (c, d) =>
  familyStorage(getFirestore(), c, d, new Date()),
);

/** 13e "Gửi yêu cầu" (+10 / +20 GB, D-010). */
export const requestMoreStorage = accountCall('requestMoreStorage', (c, d) =>
  requestStorage(getFirestore(), c, d, new Date(), { staffInbox: supportInbox.value() }),
);

/** 13k "Lưu thay đổi". */
export const updateBabyProfileInfo = accountCall('updateBabyProfileInfo', (c, d) =>
  updateBabyProfile(getFirestore(), c, d, new Date()),
);

/** 13l "Xoá vĩnh viễn": locks writes and queues the purge job. */
export const deleteBabyProfile = accountCall('deleteBabyProfile', (c, d) =>
  requestBabyDeletion(getFirestore(), c, d, new Date()),
);

/** 13m "Lưu": display name and relation per baby. */
export const updateMyProfileInfo = accountCall('updateMyProfileInfo', (c, d) =>
  updateMyProfile(getFirestore(), c, d, new Date()),
);

/** "Chuyển chủ hồ sơ" (Q-016). */
export const offerFamilyOwnership = accountCall('offerFamilyOwnership', (c, d) =>
  offerOwnership(getFirestore(), c, d, new Date(), async (uid) => {
    try {
      return (await getAuth().getUser(uid)).email ?? null;
    } catch {
      return null;
    }
  }),
);

export const answerFamilyOwnership = accountCall('answerFamilyOwnership', (c, d) =>
  answerOwnership(getFirestore(), c, d, new Date()),
);

/** 13n "Xoá tài khoản" (after ownership transfer, R-046). */
export const deleteMyAccount = accountCall('deleteMyAccount', (c, d) =>
  requestAccountDeletion(getFirestore(), c, d, new Date()),
);

/** 13n "Đăng xuất" on another device. */
export const signOutMyDevice = accountCall('signOutMyDevice', (c, d) =>
  signOutDevice(getFirestore(), c, d, new Date()),
);

/** "Xuất dữ liệu" (R-187, G-072). */
export const requestDataExport = accountCall('requestDataExport', (c, d) =>
  requestExport(getFirestore(), c, d, new Date()),
);

/** "Trợ giúp & liên hệ" (G-057, G-073). */
export const createHelpTicket = accountCall('createHelpTicket', (c, d) =>
  createSupportTicket(getFirestore(), c, d, new Date(), { staffInbox: supportInbox.value() }),
);

/** Deletion jobs start at once and resume from their failed step (P-110). */
export const runDeletion = onDocumentCreated(
  { document: 'deletionJobs/{jobId}', timeoutSeconds: 540, memory: '512MiB' },
  async (event) => {
    const result = await runDeletionJob(
      getFirestore(),
      jobDeps(),
      event.params.jobId,
      () => new Date(),
    );
    logger.info('deletion job', { jobId: event.params.jobId, result });
  },
);

export const resumeDeletions = onSchedule(
  { schedule: 'every 15 minutes', timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    const n = await resumeDeletionJobs(getFirestore(), jobDeps(), () => new Date());
    logger.info('deletion jobs resumed', { n });
  },
);

/** Builds an export into `exports/{uid}/{jobId}/` (Storage Rules re-check access, R-187). */
export const buildDataExport = onDocumentCreated(
  { document: 'dataJobs/{jobId}', timeoutSeconds: 540, memory: '1GiB' },
  async (event) => {
    const bucket = getStorage().bucket();
    const limits = limitsSchema.safeParse((await getFirestore().doc('config/limits').get()).data());
    const ttl = limits.success ? limits.data.exportLinkTtlHours : defaultLimits.exportLinkTtlHours;
    const result = await runExport(
      getFirestore(),
      bucketPurgeStore(bucket),
      bucketOpen(bucket),
      event.params.jobId,
      new Date(),
      ttl,
    );
    logger.info('export built', { jobId: event.params.jobId, result });
  },
);

export const expireDataExports = onSchedule('every 60 minutes', async () => {
  const n = await expireExports(
    getFirestore(),
    bucketPurgeStore(getStorage().bucket()),
    new Date(),
  );
  logger.info('exports expired', { n });
});

/** Daily reconciliation of every family's breakdown with its items (13b). */
export const reconcileStorageUsage = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'Asia/Ho_Chi_Minh', timeoutSeconds: 540 },
  async () => {
    const families = await getFirestore().collection('families').select().get();
    for (const f of families.docs) await reconcileFamilyUsage(getFirestore(), f.id);
    logger.info('storage reconciled', { families: families.size });
  },
);

// ---------- S12: stories and AI (D-003) ----------

/** Set with `firebase functions:secrets:set OPENAI_API_KEY` (value "unset" = template drafts). */
const openAiKey = defineSecret('OPENAI_API_KEY');
const openAiModel = defineString('OPENAI_MODEL', { default: 'gpt-4.1-mini' });

function aiProvider(): AiProvider {
  const key = openAiKey.value();
  return !key || key === 'unset' ? templateProvider : openAiProvider(key, openAiModel.value());
}

const storyCall = <T>(
  name: string,
  run: (uid: string, data: unknown) => Promise<T>,
  options: { secrets?: ReturnType<typeof defineSecret>[]; timeoutSeconds?: number } = {},
) =>
  onCall(options, async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return await run(request.auth.uid, request.data);
    } catch (error) {
      if (error instanceof StoryError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      // Never log the payload: story text is family content.
      logger.error(`${name} failed`, { error: String(error) });
      throw new HttpsError('internal', `${name} failed`);
    }
  });

/** 14f "Lưu câu chuyện" and re-saves. */
export const saveFamilyStory = storyCall('saveFamilyStory', (uid, d) =>
  saveStory(getFirestore(), uid, d, new Date()),
);

/** Delete a story (G-050). */
export const deleteFamilyStory = storyCall('deleteFamilyStory', (uid, d) =>
  deleteStory(getFirestore(), uid, d, new Date()),
);

/** 14b / 14c paragraph help. */
export const storyParagraphAssist = storyCall(
  'storyParagraphAssist',
  (uid, d) => storyAssist(getFirestore(), aiProvider(), uid, d, new Date()),
  { secrets: [openAiKey], timeoutSeconds: 60 },
);

/** "Gợi ý tuần này" on request. */
export const requestStorySuggestion = storyCall(
  'requestStorySuggestion',
  (uid, d) => requestSuggestion(getFirestore(), aiProvider(), uid, d, new Date()),
  { secrets: [openAiKey], timeoutSeconds: 120 },
);

/** Weekly suggestions, Sunday 19:00 in Vietnam (P-090). */
export const weeklyStorySuggestions = onSchedule(
  {
    schedule: 'every sunday 19:00',
    timeZone: 'Asia/Ho_Chi_Minh',
    secrets: [openAiKey],
    timeoutSeconds: 540,
  },
  async () => {
    const made = await suggestForAll(getFirestore(), aiProvider(), new Date());
    logger.info('story suggestions', { made });
  },
);

// ---------- S13: external sharing (14h–14n) ----------

const linkCall = <T>(name: string, run: (uid: string, data: unknown) => Promise<T>) =>
  onCall(async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    if (request.auth.token.firebase.sign_in_provider === 'anonymous') {
      throw new HttpsError('permission-denied', 'account-required', { reason: 'account-required' });
    }
    try {
      return await run(request.auth.uid, request.data);
    } catch (error) {
      if (error instanceof LinkError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      logger.error(`${name} failed`, { error: String(error) });
      throw new HttpsError('internal', `${name} failed`);
    }
  });

/** 14k "Sao chép & chia sẻ". */
export const createStoryLink = linkCall('createStoryLink', (uid, d) =>
  createShareLink(getFirestore(), uid, d, new Date(), webOriginFor(currentProjectId())),
);

/** 14m "Thu hồi". */
export const revokeStoryLink = linkCall('revokeStoryLink', (uid, d) =>
  revokeShareLink(getFirestore(), uid, d, new Date()),
);

/** "Thiệp ảnh đã lưu". */
export const recordStoryCard = linkCall('recordStoryCard', (uid, d) =>
  recordCard(getFirestore(), uid, d, new Date()),
);

export const expireStoryLinks = onSchedule('every 60 minutes', async () => {
  const n = await expireLinks(getFirestore(), new Date());
  logger.info('links expired', { n });
});

/** Our share cookies, carried in Hosting's single forwarded cookie `__session`. */
function cookiesOf(header: string | undefined): Record<string, string> {
  for (const part of (header ?? '').split(';')) {
    const i = part.indexOf('=');
    if (i > 0 && part.slice(0, i).trim() === '__session') {
      try {
        const jar = JSON.parse(decodeURIComponent(part.slice(i + 1).trim())) as unknown;
        if (jar && typeof jar === 'object') {
          return Object.fromEntries(
            Object.entries(jar as Record<string, unknown>).filter(
              (e): e is [string, string] => typeof e[1] === 'string',
            ),
          );
        }
      } catch {
        return {};
      }
    }
  }
  return {};
}

/** `/s/{token}` on the landing host (14l, G-052): the recipient page and its images. */
export const shareView = onRequest({ memory: '512MiB' }, async (req, res) => {
  const origin = webOriginFor(currentProjectId());
  const form: Record<string, string> = {};
  if (req.method === 'POST' && req.body && typeof req.body === 'object') {
    for (const [k, v] of Object.entries(req.body as Record<string, unknown>)) {
      if (typeof v === 'string') form[k] = v;
    }
  }
  const out = await handleShare(
    getFirestore(),
    bucketStore(getStorage().bucket()),
    {
      method: req.method,
      path: req.path,
      ip: clientAddress(req.headers['x-forwarded-for'], req.ip),
      cookies: cookiesOf(req.get('cookie')),
      form,
      locale: localeFromHeader(req.get('accept-language')),
    },
    new Date(),
    origin,
  );
  for (const [k, v] of Object.entries(out.headers)) res.set(k, v);
  // Firebase Hosting forwards only the "__session" cookie: carry ours inside it.
  const jar = {
    ...cookiesOf(req.get('cookie')),
    ...Object.fromEntries(out.cookies.map((c) => [c.name, c.value])),
  };
  if (out.cookies.length) {
    res.cookie('__session', JSON.stringify(jar), {
      httpOnly: true,
      secure: true,
      sameSite: 'lax',
      maxAge: Math.max(...out.cookies.map((c) => c.maxAge)) * 1000,
      path: '/s',
    });
  }
  if (out.type === 'redirect') {
    res.redirect(out.status, out.headers.Location ?? '/');
    return;
  }
  res.status(out.status);
  if (out.type === 'jpeg') res.type('image/jpeg').send(Buffer.from(out.body as Uint8Array));
  else res.type('html').send(out.body as string);
});

function clientAddress(forwarded: string | string[] | undefined, ip: string | undefined): string {
  const first = (Array.isArray(forwarded) ? forwarded[0] : forwarded)?.split(',')[0]?.trim();
  return first || ip || 'unknown';
}

// ---------- S15: staff portal (A01–A12, D-043) ----------

/** The signed-in staff member from the ID token's custom claims (set by `scripts/create-staff.mjs`). */
function staffOf(request: CallableRequest): Staff | null {
  const token = request.auth?.token;
  if (!token || token.staff !== true || !Array.isArray(token.roles)) return null;
  const roles = (token.roles as unknown[]).filter((r): r is Staff['roles'][number] =>
    ['ops', 'support', 'eng', 'lead'].includes(String(r)),
  );
  return { uid: request.auth!.uid, name: String(token.name ?? token.email ?? 'staff'), roles };
}

const authAccounts: AccountLister = {
  async list() {
    const out: Awaited<ReturnType<AccountLister['list']>> = [];
    let page: string | undefined;
    do {
      const r = await getAuth().listUsers(1000, page);
      for (const u of r.users) {
        if (u.customClaims?.staff === true) continue;
        out.push({
          uid: u.uid,
          email: u.email ?? null,
          createdAt: new Date(u.metadata.creationTime),
          verified: u.emailVerified,
        });
      }
      page = r.pageToken;
    } while (page && out.length < 20_000);
    return out;
  },
};

const staffCall = <T>(name: string, run: (staff: Staff | null, data: unknown) => Promise<T>) =>
  onCall({ timeoutSeconds: 120, memory: '512MiB' }, async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return await run(staffOf(request), request.data);
    } catch (error) {
      if (error instanceof StaffError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      logger.error(`${name} failed`, { error: String(error) });
      throw new HttpsError('internal', `${name} failed`);
    }
  });

export const staffBadges = staffCall('staffBadges', (s) => badges(getFirestore(), s));
export const staffOverview = staffCall('staffOverview', (s, d) =>
  overview(getFirestore(), s, d, new Date(), authAccounts),
);
export const staffTickets = staffCall('staffTickets', (s, d) => listTickets(getFirestore(), s, d));
export const staffTicket = staffCall('staffTicket', (s, d) => ticketDetail(getFirestore(), s, d));
export const staffClaimTicket = staffCall('staffClaimTicket', (s, d) =>
  claimTicket(getFirestore(), s, d, new Date()),
);
export const staffReplyTicket = staffCall('staffReplyTicket', (s, d) =>
  replyTicket(getFirestore(), s, d, new Date()),
);
export const staffCloseTicket = staffCall('staffCloseTicket', (s, d) =>
  closeTicket(getFirestore(), s, d, new Date()),
);
export const staffStorageRequests = staffCall('staffStorageRequests', (s, d) =>
  listStorageRequests(getFirestore(), s, d, new Date(), authAccounts),
);
export const staffDecideStorage = staffCall('staffDecideStorage', (s, d) =>
  decideStorage(getFirestore(), s, d, new Date()),
);
export const staffJobs = staffCall('staffJobs', (s, d) =>
  listJobs(getFirestore(), s, d, new Date()),
);
export const staffRerunJob = onCall({ timeoutSeconds: 540, memory: '512MiB' }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  try {
    await rerunJob(getFirestore(), staffOf(request), request.data, new Date(), (jobId) =>
      runDeletionJob(getFirestore(), jobDeps(), jobId, () => new Date()),
    );
  } catch (error) {
    if (error instanceof StaffError)
      throw new HttpsError(error.code, error.reason, { reason: error.reason });
    logger.error('staffRerunJob failed', { error: String(error) });
    throw new HttpsError('internal', 'staffRerunJob failed');
  }
});
export const staffSystem = staffCall('staffSystem', (s) =>
  systemHealth(getFirestore(), s, new Date()),
);
export const staffAi = staffCall('staffAi', (s) => aiStats(getFirestore(), s, new Date()));
export const staffFlags = staffCall('staffFlags', (s) => readFlags(getFirestore(), s));
export const staffSetFlag = staffCall('staffSetFlag', (s, d) =>
  setFlag(getFirestore(), s, d, new Date()),
);
export const staffAudit = staffCall('staffAudit', (s, d) =>
  listAudit(getFirestore(), s, d, new Date()),
);
export const staffExportAudit = staffCall('staffExportAudit', (s, d) =>
  listAudit(getFirestore(), s, d, new Date(), true),
);
