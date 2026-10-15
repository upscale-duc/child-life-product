import { randomUUID } from 'node:crypto';
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
import { defaultLimits, functionsRegion, limitsSchema } from '@child-life/contracts';
import {
  adminOriginFor,
  currentProjectId,
  environmentForProject,
  inviteOpenUrl,
  otherAppHost,
  signInContinueUrlFor,
  storeLinksFor,
  webOriginFor,
} from './env.js';
import {
  FamilyError,
  acceptInvite,
  declineInvite,
  listMyInvites,
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
import { FeatureError, featureAccess } from './features.js';
import {
  EntitlementError,
  getCapabilities as capabilitiesOf,
  serverGrantEnvironment,
  setFamilySettings as saveFamilySettings,
} from './entitlements.js';
import {
  bumpDataVersion,
  composeHome as composeRhythmHome,
  nextAction as rhythmNextAction,
  onCheckInWritten,
  RhythmError,
  setDueDate as saveDueDate,
} from './rhythm.js';
import {
  rhythmAct,
  rhythmDraft,
  rhythmRulesView,
  rhythmView,
  setRhythmRules,
  type RhythmContentDeps,
} from './rhythm-content.js';
import {
  familyPremium,
  grantPromo,
  readPremium,
  revokeGrant,
  setEntitlementsConfig,
} from './premium-staff.js';
import { aiPolicy, familyQuota, renderOps } from './premium-ops.js';
import { deliverMail, unsubscribe, type MailSender } from './mail.js';
import { resendSender } from './mail-resend.js';
import {
  myTickets,
  recordAppEvent as recordEvent,
  sendFeedback as sendFeedbackTicket,
} from './feedback.js';
import { AuthMailError, sendAuthEmail as sendAuthMail, signInLinkTarget } from './auth-mail.js';
import {
  caseComments as qaCaseComments,
  handbook as qaHandbook,
  update as qaUpdate,
} from './qa.js';
import {
  localeFromHeader,
  renderExportPage,
  renderInvitePage,
  renderSignInLinkPage,
  renderUnsubscribePage,
} from './pages.js';
import { resolveExportDownload } from './export-download.js';
import { CareError, onRecordWritten, purgeDeletedRecords, resolveSleepConflict } from './care.js';
import { BabyError, createBaby, getBabyAvatar, setBabyAvatar, type AvatarStore } from './babies.js';
import { handlePing, PingError } from './ping.js';
import { bucketOpen, bucketPurgeStore, bucketStore, sharpImages } from './images.js';
import sharp from 'sharp';
import {
  firstAidAct,
  firstAidDraft,
  firstAidUploadImage,
  firstAidView,
  type ContentDeps,
  type FirstAidImageStore,
} from './content.js';
import { appUpdateSave, appUpdateUploadImage, appUpdateView } from './app-update.js';
import {
  KeepsakeJobError,
  attachKeepsakeLive,
  cloudTasksDispatcher,
  deleteMemoryStory as deleteMemoryStoryJob,
  completeKeepsakeJob,
  getVideoQuota as getVideoQuotaJob,
  keepsakeJobChanged,
  requestMemoryStory as requestMemoryStoryJob,
  retryMemoryStory as retryMemoryStoryJob,
  sweepKeepsakeJobs,
  type LiveSender,
  type RenderDispatcher,
} from './keepsake-jobs.js';
import {
  BillingError,
  noBillingAdapters,
  reconcileSubscriptions as reconcileBillingSubscriptions,
  restorePurchase as restorePurchaseCore,
  startPurchase as startPurchaseCore,
  verifyPurchase as verifyPurchaseCore,
  type BillingAdapters,
} from './billing.js';
import {
  keepsakeAct,
  keepsakeDraft,
  keepsakeUploadAsset,
  keepsakeView,
  type KeepsakeContentDeps,
} from './keepsake-content.js';
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
import {
  deliverNotice,
  onMessageCreated,
  onReactionWritten,
  pushPayload,
  type PushSender,
} from './social.js';
import {
  ReminderRuleError,
  answerReminderRule,
  deleteReminderRule,
  fireDueRules,
  onRecordForRules,
  saveReminderRule,
  setReminderRuleEnabled,
} from './reminder-rules.js';
import {
  VaccineReminderError,
  ringVaccineReminders,
  snoozeVaccineReminder,
} from './vaccine-reminders.js';
import {
  SpendingError,
  addRecurringExpenses as addDueRecurring,
  deleteSpendingCategory as deleteCategory,
  spendingBudgetAlert as checkBudgetAlert,
} from './spending.js';
import {
  openAiExpenseExtractor,
  openAiProvider,
  templateProvider,
  type AiProvider,
  type ExpenseExtractor,
} from './ai.js';
import {
  analyzeSpendingImport as analyzeImport,
  cleanupSpendingImports as cleanupImports,
  confirmSpendingImport as confirmImport,
  runSpendingImport as runImport,
  importPage,
  undoSpendingImport as undoImport,
  type ImportStore,
} from './spending-import.js';
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
  approveRerun,
  replyTicket,
  requestRerun,
  setFlag,
  systemHealth,
  ticketDetail,
  ticketScreenshot,
  type AccountLister,
  type Staff,
} from './staff.js';
import { referenceAct, referenceDraft, referenceView } from './reference-data.js';
import {
  analytics,
  backfillDays,
  exportAnalytics,
  markDeviceActivity,
  recordAcquisition,
} from './analytics.js';
import {
  answerStaffTransfer,
  cancelTransfer,
  expireTransfers,
  familyDetail,
  listFamilies,
  openTransfer,
  refreshAllFamilies,
  refreshFamilyDirectory,
  type FamilyDeps,
} from './staff-families.js';
import {
  acceptStaffInvite,
  expireStaffAccess,
  inviteStaff,
  listStaff,
  resolveStaff,
  saveStaffRole,
  staffMe as describeStaff,
  updateStaffMember,
  type StaffAuthPort,
} from './staff-access.js';
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
  closeWaitingBatches,
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
// Premium Slice 3 · grounded AI (plan §5.5, P-151).
import {
  AiSummaryError,
  generateSummary as runGenerateSummary,
  listSummaries as runListSummaries,
  reportSummary as runReportSummary,
  setAiConsent as runSetAiConsent,
} from './ai-summary.js';
import { sweepAiReservations } from './quota-sweeper.js';

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
  if (
    error instanceof BabyError ||
    error instanceof FamilyError ||
    error instanceof SpendingError ||
    error instanceof FeatureError ||
    error instanceof EntitlementError ||
    error instanceof RhythmError ||
    error instanceof AiSummaryError
  ) {
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
  const emailTrusted =
    token.email_verified === true || provider === 'google.com' || provider === 'apple.com';
  return {
    uid: request.auth.uid,
    anonymous: provider === 'anonymous',
    emailTrusted,
    email: emailTrusted && typeof token.email === 'string' ? token.email.toLowerCase() : null,
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

/** P-148: per-family features (Tự lưu kỷ niệm's `auto_save` rollout) for one of my babies. */
export const getFeatureAccess = familyCall('getFeatureAccess', (r) =>
  featureAccess(getFirestore(), requireAccount(r), r.data, new Date()),
);

/** Premium & Cá nhân hoá (plan §5.1): plan, capabilities and gate reasons for one of my babies. */
export const getCapabilities = familyCall('getCapabilities', (r) =>
  capabilitiesOf(getFirestore(), requireAccount(r), r.data, new Date(), serverGrantEnvironment()),
);

/** The family owner sets the household country / time zone (D-072 #1, #3). */
export const setFamilySettings = familyCall('setFamilySettings', (r) =>
  saveFamilySettings(getFirestore(), requireAccount(r), r.data, new Date()),
);

// Nhịp lớn lên (plan §7.1, D-073): due date, the next action after a check-in, the Home card.
/** NL02b: Cùng nuôi set or clear the due date (stored with the date of birth). */
export const setDueDate = familyCall('setDueDate', (r) =>
  saveDueDate(getFirestore(), requireAccount(r), r.data, new Date(), serverGrantEnvironment()),
);
/** PS01 / PS01F / HL01 after a saved check-in; idempotent per check-in. */
export const nextAction = familyCall('nextAction', (r) =>
  rhythmNextAction(getFirestore(), requireAccount(r), r.data, new Date(), serverGrantEnvironment()),
);
/** H01 / H02 / PS02: the current suggestion and the feedback behind it; never fails free Home. */
export const composeHome = familyCall('composeHome', (r) =>
  composeRhythmHome(
    getFirestore(),
    requireAccount(r),
    r.data,
    new Date(),
    serverGrantEnvironment(),
  ),
);

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
/** Invites mailed to the caller's own email (owner, 2026-10-11). */
export const listMyFamilyInvites = familyCall('listMyFamilyInvites', (r) =>
  listMyInvites(getFirestore(), callerOf(r), new Date()),
);
export const declineFamilyInvite = familyCall('declineFamilyInvite', (r) =>
  declineInvite(getFirestore(), callerOf(r), r.data, new Date()),
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
    // The rhythm facts read care records too (plan §7.1: dataVersion on every care write).
    await bumpDataVersion(getFirestore(), event.params.babyId, new Date());
    logger.debug('care summaries recomputed', { days: days.length });
  },
);

/** Nhịp lớn lên facts: a check-in was saved, edited or deleted (M14). */
export const onCheckInWrite = onDocumentWritten(
  'babies/{babyId}/checkins/{checkInId}',
  async (event) => {
    const change = event.data;
    if (!change) return;
    const { dates } = await onCheckInWritten(
      getFirestore(),
      event.params.babyId,
      change.before.exists ? change.before : null,
      change.after.exists ? change.after : null,
      new Date(),
    );
    logger.debug('rhythm facts bumped', { days: dates.length });
  },
);

/** Feedback changes what the ranking uses: bump the facts version (AC02, M18). */
export const onRecFeedbackWrite = onDocumentWritten(
  'babies/{babyId}/recFeedback/{feedbackId}',
  async (event) => {
    await bumpDataVersion(getFirestore(), event.params.babyId, new Date());
  },
);

/** NL07b: confirming or closing an observation episode changes the facts (summaries go stale). */
export const onEpisodeWrite = onDocumentWritten(
  'babies/{babyId}/episodes/{episodeId}',
  async (event) => {
    await bumpDataVersion(getFirestore(), event.params.babyId, new Date());
  },
);

// ---------- Rule reminders (v1.0 improvement, D-051) ----------

/** The first log of the activity answers a due rule reminder for everyone (1d). */
export const onCareRecordForRules = onDocumentWritten(
  'babies/{babyId}/records/{recordId}',
  async (event) => {
    const change = event.data;
    if (!change) return;
    const { updated } = await onRecordForRules(
      getFirestore(),
      event.params.babyId,
      change.before.exists ? change.before : null,
      change.after.exists ? change.after : null,
      new Date(),
    );
    if (updated > 0) logger.debug('reminder rules moved', { updated });
  },
);

function ruleCall<T>(run: (uid: string, data: unknown, now: Date) => Promise<T>) {
  return onCall(async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return await run(request.auth.uid, request.data, new Date());
    } catch (error) {
      if (error instanceof ReminderRuleError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      throw error;
    }
  });
}

export const saveRuleReminder = ruleCall((uid, data, now) =>
  saveReminderRule(getFirestore(), uid, data, now),
);
export const setRuleReminderEnabled = ruleCall((uid, data, now) =>
  setReminderRuleEnabled(getFirestore(), uid, data, now),
);
export const deleteRuleReminder = ruleCall((uid, data, now) =>
  deleteReminderRule(getFirestore(), uid, data, now),
);
export const answerRuleReminder = ruleCall((uid, data, now) =>
  answerReminderRule(getFirestore(), uid, data, now),
);

/** Sổ tiêm chủng reminders: 3 days before and the evening before at 19:00 (P-133). */
export const ringVaccineReminderPush = onSchedule('every 5 minutes', async () => {
  const { rang, sent } = await ringVaccineReminders(getFirestore(), pushSender(), new Date());
  if (rang > 0) logger.info('vaccine reminders rang', { rang, sent });
});

/** VX 8 "Nhắc lại sáng mai". */
export const snoozeVaccine = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  try {
    return await snoozeVaccineReminder(getFirestore(), request.auth.uid, request.data, new Date());
  } catch (error) {
    if (error instanceof VaccineReminderError) {
      throw new HttpsError(error.code, error.reason, { reason: error.reason });
    }
    throw error;
  }
});

// ---------- Chi tiêu (Figma v1.1 8a–8o, D-055 … D-057, P-140) ----------

/** 8o: delete a category; its expenses, recurring items and caps move in every family baby. */
export const deleteSpendingCategory = familyCall('deleteSpendingCategory', (r) =>
  deleteCategory(getFirestore(), callerOf(r).uid, r.data, new Date()),
);

/** 8i / D-057: recurring items are added on their due day in the baby's zone. */
export const addRecurringExpenses = onSchedule(
  { schedule: 'every day 00:30', timeZone: 'Asia/Ho_Chi_Minh', timeoutSeconds: 540 },
  async () => {
    const { added, babies, sent } = await addDueRecurring(getFirestore(), pushSender(), new Date());
    if (added > 0) logger.info('recurring expenses added', { added, babies, sent });
  },
);

/** 8h: the 80 % budget push, once a month (no amounts in logs, P-140). */
export const spendingBudgetAlert = onDocumentWritten(
  'babies/{babyId}/expenses/{expenseId}',
  async (event) => {
    const change = event.data;
    if (!change) return;
    const { alerted, sent } = await checkBudgetAlert(
      getFirestore(),
      pushSender(),
      event.params.babyId,
      change.before.exists ? change.before : null,
      change.after.exists ? change.after : null,
      new Date(),
    );
    if (alerted) logger.info('spending budget alert', { sent });
  },
);

/** Rings rule reminders whose time has come (1f). */
export const ringRuleReminders = onSchedule('every 1 minutes', async () => {
  const { fired, sent } = await fireDueRules(getFirestore(), pushSender(), new Date());
  if (fired > 0) logger.info('rule reminders rang', { fired, sent });
});

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

/**
 * Unused reservations go back after 24 h (P-031); a batch whose last part never came is closed
 * (D-070).
 */
export const releaseStaleMemoryUploads = onSchedule('every 60 minutes', async () => {
  const released = await releaseStaleUploads(
    getFirestore(),
    bucketStore(getStorage().bucket()),
    new Date(),
  );
  if (released > 0) logger.info('stale uploads released', { count: released });
  const closed = await closeWaitingBatches(getFirestore(), new Date());
  if (closed > 0) logger.info('waiting batches closed', { count: closed });
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
        ...pushPayload(message),
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

// ---------- Email (D-054: Resend; replaces SES, D-020) ----------

/** Set with `firebase functions:secrets:set RESEND_API_KEY` (value "unset" = not configured). */
const resendApiKey = defineSecret('RESEND_API_KEY');
const mailFrom = defineString('MAIL_FROM', { default: 'Child Life <hello@childlife.app>' });
/** Replies land in the GoDaddy mailbox. */
const mailReplyTo = defineString('MAIL_REPLY_TO', { default: 'hello@childlife.app' });

function mailSender(): MailSender | null {
  const apiKey = resendApiKey.value();
  if (!apiKey || apiKey === 'unset') return null;
  return resendSender({ apiKey, from: mailFrom.value(), replyTo: mailReplyTo.value() });
}

const mailOrigins = () => ({
  webOrigin: webOriginFor(currentProjectId()),
  adminOrigin: adminOriginFor(currentProjectId()),
  /** Where `exportDownload` answers (direct, not through Hosting: no 60 s proxy limit). */
  functionsOrigin: `https://${functionsRegion}-${currentProjectId()}.cloudfunctions.net`,
});

export const deliverQueuedMail = onDocumentCreated(
  { document: 'mail/{mailId}', secrets: [resendApiKey] },
  async (event) => {
    if (!event.data) return;
    const status = await deliverMail(event.data, mailSender(), {
      ...mailOrigins(),
      now: new Date(),
    });
    logger.info('mail processed', { mailId: event.params.mailId, status });
  },
);

/** Retries mail waiting for the provider or after a transient failure. */
export const retryQueuedMail = onSchedule(
  { schedule: 'every 15 minutes', secrets: [resendApiKey] },
  async () => {
    const sender = mailSender();
    if (!sender) return;
    const due = await getFirestore()
      .collection('mail')
      .where('status', 'in', ['waiting-provider', 'retry'])
      .limit(50)
      .get();
    for (const doc of due.docs) {
      await deliverMail(doc, sender, { ...mailOrigins(), now: new Date() });
    }
  },
);

/** Branded "Xác minh email", "Quên mật khẩu" and the portal's email link (D-054). */
export const sendAuthEmail = onCall({ secrets: [resendApiKey] }, async (request) => {
  try {
    return await sendAuthMail(
      {
        db: getFirestore(),
        auth: getAuth(),
        sender: mailSender(),
        adminOrigin: adminOriginFor(currentProjectId()),
        webOrigin: webOriginFor(currentProjectId()),
        continueUrl: signInContinueUrlFor(currentProjectId()),
      },
      request.auth
        ? {
            uid: request.auth.uid,
            email: request.auth.token.email,
            emailVerified: request.auth.token.email_verified,
          }
        : null,
      request.data,
      new Date(),
    );
  } catch (error) {
    if (error instanceof AuthMailError) {
      throw new HttpsError(error.code, error.reason, { reason: error.reason });
    }
    throw error;
  }
});

// ---------- Pages on the landing host ----------

export const inviteLanding = onRequest(async (req, res) => {
  const token = req.path.split('/').filter(Boolean).pop() ?? '';
  const { preview, code } = await inviteForLanding(getFirestore(), token, new Date());
  const project = currentProjectId();
  res.set('Cache-Control', 'private, no-store');
  res.set('X-Robots-Tag', 'noindex');
  res.status(preview.status === 'valid' ? 200 : 404).send(
    renderInvitePage(localeFromHeader(req.get('accept-language')), preview, code, {
      // Hosting forwards the domain the person opened (D-059: the button opens the other one).
      openUrl: inviteOpenUrl(project, req.get('x-forwarded-host') ?? req.hostname, token),
      ...storeLinksFor(project),
    }),
  );
});

/** The app's email sign-in link opened in a browser instead of the app (D-064). */
export const signInLinkLanding = onRequest((req, res) => {
  const link = signInLinkTarget(
    req.query,
    otherAppHost(currentProjectId(), req.get('x-forwarded-host') ?? req.hostname),
    new Date(),
  );
  res.set('Cache-Control', 'private, no-store');
  res.set('X-Robots-Tag', 'noindex');
  res
    .status(link.expired ? 410 : 200)
    .send(renderSignInLinkPage(localeFromHeader(req.get('accept-language')), link));
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

/**
 * "Tải tệp về" in the export email (R-187, P-123): re-checks the right, then redirects to a fresh
 * Firebase Storage download URL for the zip (rotated on every click, gone when the export expires).
 */
export const exportDownload = onRequest(async (req, res) => {
  const [jobId = '', token = ''] = req.path.split('/').filter(Boolean).slice(-2);
  const bucket = getStorage().bucket();
  const result = await resolveExportDownload(
    getFirestore(),
    {
      async issue(path, filename) {
        const downloadToken = randomUUID();
        await bucket.file(path).setMetadata({
          contentDisposition: `attachment; filename="${filename}"`,
          metadata: { firebaseStorageDownloadTokens: downloadToken },
        });
        return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${downloadToken}`;
      },
    },
    jobId,
    token,
    new Date(),
  );
  res.set('Cache-Control', 'private, no-store');
  res.set('Referrer-Policy', 'no-referrer');
  res.set('X-Robots-Tag', 'noindex');
  logger.info('export download', { result: result.kind });
  if (result.kind === 'redirect') {
    res.redirect(302, result.url);
    return;
  }
  res
    .status(result.kind === 'invalid' ? 404 : 410)
    .send(renderExportPage(localeFromHeader(req.get('accept-language')), result.kind));
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

/** Android install source, once per account (A13 "Nguồn gia đình mới", P-137). */
export const recordInstallSource = accountCall('recordInstallSource', (c, d) =>
  recordAcquisition(getFirestore(), c, d, new Date()),
);

/** The owner's answer to an ownership transfer opened by Child Life Hỗ trợ (A17, P-136). */
export const answerStaffOwnershipRequest = accountCall('answerStaffOwnershipRequest', (c, d) =>
  answerStaffTransfer(getFirestore(), c, d, new Date(), familyDeps.emailOf),
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

/** FB2 "Gửi góp ý" (D-065): a support ticket of category `feedback`. */
export const sendFeedback = accountCall('sendFeedback', (c, d) =>
  sendFeedbackTicket(getFirestore(), c, d, new Date(), {
    staffInbox: supportInbox.value(),
    async screenshotExists(path) {
      const [exists] = await getStorage().bucket().file(path).exists();
      return exists;
    },
  }),
);

/** FB3 "Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ". */
export const myHelpTickets = accountCall('myHelpTickets', (c) => myTickets(getFirestore(), c));

/** FB5 counters (P-137): aggregate only. */
export const recordAppEvent = accountCall('recordAppEvent', (_c, d) =>
  recordEvent(getFirestore(), d, new Date()),
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

// ---------- Premium Slice 3 · grounded AI (plan §5.5, P-151, D-072 #2) ----------

const aiCall = <T>(
  name: string,
  run: (request: CallableRequest) => Promise<T>,
  options: { secrets?: ReturnType<typeof defineSecret>[]; timeoutSeconds?: number } = {},
) =>
  onCall(options, async (request) => {
    try {
      return await run(request);
    } catch (error) {
      // asHttpsError logs only the operation and the error string, never the payload.
      throw asHttpsError(name, error);
    }
  });

/** NL10 privacy: my AI consent (versioned); withdrawing clears AI text, keeps the template. */
export const setAiConsent = aiCall('setAiConsent', (r) =>
  runSetAiConsent(getFirestore(), requireAccount(r), r.data, new Date()),
);

/** SU01 / NL10 / NL10b: handover, explanation or milestone nudge; template on any failure. */
/** Releases AI quota reservations left behind by a function that died mid-call (hourly). */
export const sweepAiQuota = onSchedule('every 60 minutes', async () => {
  const n = await sweepAiReservations(getFirestore(), new Date());
  if (n > 0) logger.info('ai quota reservations released', { count: n });
});

export const generateSummary = aiCall(
  'generateSummary',
  (r) =>
    runGenerateSummary(
      {
        db: getFirestore(),
        provider: aiProvider(),
        now: new Date(),
        environment: serverGrantEnvironment(),
      },
      requireAccount(r),
      r.data,
    ),
  { secrets: [openAiKey], timeoutSeconds: 60 },
);

/** SU01 history for `history.read` roles; summaries older than the facts come back `stale`. */
export const listSummaries = aiCall('listSummaries', (r) =>
  runListSummaries(getFirestore(), requireAccount(r), r.data, new Date(), serverGrantEnvironment()),
);

/** "Chưa đúng? Báo lại": a closed problem code for staff, no child text. */
export const reportSummary = aiCall('reportSummary', (r) =>
  runReportSummary(getFirestore(), requireAccount(r), r.data, new Date(), serverGrantEnvironment()),
);

// ---------- Nhập chi tiêu (D-060, P-144) ----------

function expenseExtractor(): ExpenseExtractor | null {
  const key = openAiKey.value();
  return !key || key === 'unset' ? null : openAiExpenseExtractor(key, openAiModel.value());
}

/** Grids and photos under `imports/` (written by the app, read and deleted here). */
const importStore = (): ImportStore => {
  const bucket = getStorage().bucket();
  return {
    size: async (path) => {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) return null;
      const [meta] = await file.getMetadata();
      return Number(meta.size ?? 0);
    },
    read: async (path) => (await bucket.file(path).download())[0],
    write: async (path, bytes, contentType) => {
      await bucket.file(path).save(bytes, { contentType, resumable: false });
    },
    listOlderThan: async (prefix, before, max) => {
      const out: string[] = [];
      let pageToken: string | undefined;
      // At most 10 pages per run; the next run continues.
      for (let page = 0; page < 10 && out.length < max; page++) {
        const [files, next] = await bucket.getFiles({
          prefix,
          maxResults: 1000,
          autoPaginate: false,
          ...(pageToken ? { pageToken } : {}),
        });
        for (const f of files) {
          const created = Date.parse(String(f.metadata.timeCreated ?? ''));
          if (Number.isFinite(created) && created < before.getTime()) out.push(f.name);
          if (out.length >= max) break;
        }
        pageToken = (next as { pageToken?: string } | null)?.pageToken;
        if (!pageToken) break;
      }
      return out;
    },
    delete: async (path) => {
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
  };
};

const importCall = <T>(
  name: string,
  options: {
    secrets?: ReturnType<typeof defineSecret>[];
    timeoutSeconds?: number;
    memory?: '512MiB' | '1GiB';
  },
  run: (uid: string, data: unknown) => Promise<T>,
) =>
  onCall(options, async (request) => {
    const uid = callerOf(request).uid;
    try {
      return await run(uid, request.data);
    } catch (error) {
      // Never the payload: it holds the family's spending.
      throw asHttpsError(name, error);
    }
  });

/** Reads the uploaded grid (or the pasted text / photos through AI) and writes the preview. */
export const analyzeSpendingImport = importCall(
  'analyzeSpendingImport',
  { secrets: [openAiKey], timeoutSeconds: 300, memory: '1GiB' },
  (uid, d) =>
    analyzeImport(
      { db: getFirestore(), store: importStore(), extractor: expenseExtractor() },
      uid,
      d,
      new Date(),
    ),
);

/** "Nhập N khoản": keeps the choices; the trigger below imports. */
export const confirmSpendingImport = importCall('confirmSpendingImport', {}, (uid, d) =>
  confirmImport(getFirestore(), uid, d, new Date()),
);

/** "Xem tất cả": one page of 50 rows to import. */
export const spendingImportPage = importCall(
  'spendingImportPage',
  { timeoutSeconds: 120, memory: '1GiB' },
  (uid, d) => importPage({ db: getFirestore(), store: importStore() }, uid, d, new Date()),
);

/** "Hoàn tác lần nhập" (7 days). */
export const undoSpendingImport = importCall(
  'undoSpendingImport',
  { timeoutSeconds: 300 },
  async (uid, d) => {
    const result = await undoImport(getFirestore(), uid, d, new Date());
    logger.info('spending import undone', { removed: result.removed });
    return result;
  },
);

/** Imports a confirmed import in batches, then mails and pushes the importer. */
export const runSpendingImport = onDocumentWritten(
  {
    document: 'babies/{babyId}/spendingImports/{importId}',
    timeoutSeconds: 540,
    memory: '1GiB',
  },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!after?.exists || after.get('status') !== 'queued') return;
    if (before?.exists && before.get('status') === 'queued') return;
    const { babyId, importId } = event.params;
    const result = await runImport(
      {
        db: getFirestore(),
        store: importStore(),
        extractor: null,
        sender: pushSender(),
        emailOf: async (uid) => {
          try {
            return (await getAuth().getUser(uid)).email ?? null;
          } catch {
            return null;
          }
        },
      },
      babyId,
      importId,
      new Date(),
    );
    if (result.ran) {
      logger.info('spending import finished', {
        babyId,
        importId,
        imported: result.imported,
        failure: result.failure,
      });
    }
  },
);

/** Deletes old grids and photos; expires imports left waiting (no mail). */
export const cleanupSpendingImports = onSchedule(
  { schedule: 'every day 03:15', timeZone: 'Asia/Ho_Chi_Minh', timeoutSeconds: 540 },
  async () => {
    const { files, expired } = await cleanupImports(getFirestore(), importStore(), new Date());
    if (files > 0 || expired > 0) logger.info('spending imports cleaned', { files, expired });
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

/**
 * The signed-in staff member: the `staff` claim gates, then `staffMembers` / `staffRoles` decide
 * (P-134), so a pause or a role edit applies on the next call.
 */
function staffOf(request: CallableRequest): Promise<Staff | null> {
  return resolveStaff(
    getFirestore(),
    request.auth ? { uid: request.auth.uid, token: request.auth.token } : undefined,
    new Date(),
  );
}

const familyDeps: FamilyDeps = {
  async emailOf(uid) {
    try {
      return (await getAuth().getUser(uid)).email ?? null;
    } catch {
      return null;
    }
  },
  async uidByEmail(email) {
    try {
      return (await getAuth().getUserByEmail(email)).uid;
    } catch {
      return null;
    }
  },
};

const staffAuthPort: StaffAuthPort = {
  async setClaims(uid, claims) {
    await getAuth().setCustomUserClaims(uid, claims);
  },
  async revoke(uid) {
    await getAuth().revokeRefreshTokens(uid);
  },
};

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

const staffCall = <T>(
  name: string,
  run: (staff: Staff | null, data: unknown) => Promise<T>,
  options: { secrets?: ReturnType<typeof defineSecret>[] } = {},
) =>
  onCall({ timeoutSeconds: 120, memory: '512MiB', ...options }, async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return await run(await staffOf(request), request.data);
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
export const staffTicketScreenshot = staffCall('staffTicketScreenshot', (s, d) =>
  ticketScreenshot(getFirestore(), s, d, new Date(), async (path) => {
    const file = getStorage().bucket().file(path);
    const [exists] = await file.exists();
    if (!exists) return null;
    const [bytes] = await file.download();
    return bytes;
  }),
);
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
// P-139: a re-run is asked for by one person and approved by another.
export const staffRerunJob = staffCall('staffRerunJob', (s, d) =>
  requestRerun(getFirestore(), s, d, new Date()),
);
export const staffApproveRerun = onCall(
  { timeoutSeconds: 540, memory: '512MiB' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      await approveRerun(
        getFirestore(),
        await staffOf(request),
        request.data,
        new Date(),
        (jobId) => runDeletionJob(getFirestore(), jobDeps(), jobId, () => new Date()),
      );
    } catch (error) {
      if (error instanceof StaffError)
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      logger.error('staffApproveRerun failed', { error: String(error) });
      throw new HttpsError('internal', 'staffApproveRerun failed');
    }
  },
);
export const staffSystem = staffCall('staffSystem', (s) =>
  systemHealth(getFirestore(), s, new Date()),
);
export const staffAi = staffCall('staffAi', (s) => aiStats(getFirestore(), s, new Date()));
export const staffFlags = staffCall('staffFlags', (s) => readFlags(getFirestore(), s));
export const staffSetFlag = staffCall('staffSetFlag', (s, d) =>
  setFlag(getFirestore(), s, d, new Date()),
);

// Premium & Cá nhân hoá (plan §5.6): regions, quotas, Beta A campaigns, promo grants.
export const staffPremium = staffCall('staffPremium', (s) => readPremium(getFirestore(), s));
export const staffSetPremiumConfig = staffCall('staffSetPremiumConfig', (s, d) =>
  setEntitlementsConfig(getFirestore(), s, d, new Date()),
);
export const staffFamilyPremium = staffCall('staffFamilyPremium', (s, d) =>
  familyPremium(getFirestore(), s, d, new Date()),
);
export const staffGrantPromo = staffCall('staffGrantPromo', (s, d) =>
  grantPromo(getFirestore(), s, d, new Date()),
);
export const staffRevokeGrant = staffCall('staffRevokeGrant', (s, d) =>
  revokeGrant(getFirestore(), s, d, new Date()),
);

// Premium operations (plan §5.6, brief "Portal cần thêm"): read-only views; no retry, no charge.
export const staffAiPolicy = staffCall(
  'staffAiPolicy',
  (s) => {
    // The key decides openai vs template; only the provider name and model leave this function.
    const live = aiProvider();
    return aiPolicy(getFirestore(), s, { name: live.name, model: live.model ?? null }, new Date());
  },
  { secrets: [openAiKey] },
);
export const staffRenderOps = staffCall('staffRenderOps', (s) =>
  renderOps(getFirestore(), s, new Date()),
);
export const staffFamilyQuota = staffCall('staffFamilyQuota', (s, d) =>
  familyQuota(getFirestore(), s, d, new Date()),
);
export const staffAudit = staffCall('staffAudit', (s, d) =>
  listAudit(getFirestore(), s, d, new Date()),
);
export const staffExportAudit = staffCall('staffExportAudit', (s, d) =>
  listAudit(getFirestore(), s, d, new Date(), true),
);

// Nhân sự & phân quyền (A18–A21, P-134, P-135).
export const staffMe = staffCall('staffMe', async (s) => describeStaff(s));
export const staffTeam = staffCall('staffTeam', (s) => listStaff(getFirestore(), s, new Date()));
export const staffInvite = staffCall('staffInvite', (s, d) =>
  inviteStaff(getFirestore(), s, d, new Date(), {
    adminOrigin: adminOriginFor(currentProjectId()),
  }),
);
export const staffUpdateMember = staffCall('staffUpdateMember', (s, d) =>
  updateStaffMember(getFirestore(), s, d, new Date(), staffAuthPort),
);
export const staffSaveRole = staffCall('staffSaveRole', (s, d) =>
  saveStaffRole(getFirestore(), s, d, new Date()),
);
/** An invitee's first sign-in: no staff claim yet, so this one is not a `staffCall`. */
export const staffAcceptInvite = onCall({ timeoutSeconds: 60 }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  try {
    return await acceptStaffInvite(
      getFirestore(),
      { uid: request.auth.uid, token: request.auth.token },
      new Date(),
      staffAuthPort,
    );
  } catch (error) {
    if (error instanceof StaffError)
      throw new HttpsError(error.code, error.reason, { reason: error.reason });
    logger.error('staffAcceptInvite failed', { error: String(error) });
    throw new HttpsError('internal', 'staffAcceptInvite failed');
  }
});
export const expireStaffAccessJob = onSchedule('every 60 minutes', async () => {
  const done = await expireStaffAccess(getFirestore(), new Date(), staffAuthPort);
  if (done.members || done.invites) logger.info('staff access expired', done);
});

// Gia đình (A15–A17, P-136): counts only, codes not names; ownership needs the owner's yes.
export const staffFamilies = staffCall('staffFamilies', (s, d) =>
  listFamilies(getFirestore(), s, d, familyDeps),
);
export const staffFamily = staffCall('staffFamily', (s, d) =>
  familyDetail(getFirestore(), s, d, new Date(), familyDeps),
);
export const staffOpenTransfer = staffCall('staffOpenTransfer', (s, d) =>
  openTransfer(getFirestore(), s, d, new Date(), familyDeps),
);
export const staffCancelTransfer = staffCall('staffCancelTransfer', (s, d) =>
  cancelTransfer(getFirestore(), s, d, new Date()),
);
export const expireFamilyTransfersJob = onSchedule('every 60 minutes', async () => {
  const n = await expireTransfers(getFirestore(), new Date());
  if (n) logger.info('family transfers expired', { n });
});
/** Keeps `familyDirectory` in step with the family, its members and its invites. */
export const familyDirectoryOnFamily = onDocumentWritten('families/{familyId}', async (event) => {
  await refreshFamilyDirectory(getFirestore(), event.params.familyId, new Date(), familyDeps);
});
export const familyDirectoryOnMember = onDocumentWritten(
  'babies/{babyId}/members/{uid}',
  async (event) => {
    const baby = await getFirestore().doc(`babies/${event.params.babyId}`).get();
    const familyId = baby.get('familyId') as string | undefined;
    if (familyId) await refreshFamilyDirectory(getFirestore(), familyId, new Date(), familyDeps);
  },
);
export const familyDirectoryOnInvite = onDocumentWritten('invites/{inviteId}', async (event) => {
  const familyId = (event.data?.after.get('familyId') ?? event.data?.before.get('familyId')) as
    string | undefined;
  if (familyId) await refreshFamilyDirectory(getFirestore(), familyId, new Date(), familyDeps);
});

// Phân tích (A13 / A14, P-137): aggregates from `statsDaily` only.
export const staffAnalytics = staffCall('staffAnalytics', (s, d) =>
  analytics(getFirestore(), s, d, new Date()),
);
export const staffExportAnalytics = staffCall('staffExportAnalytics', (s, d) =>
  exportAnalytics(getFirestore(), s, d, new Date()),
);
/** A new heartbeat day marks the person's families active (P-137). */
export const activityOnDevice = onDocumentWritten(
  'users/{uid}/devices/{deviceId}',
  async (event) => {
    await markDeviceActivity(
      getFirestore(),
      event.params.uid,
      event.data?.before.data(),
      event.data?.after.data(),
    );
  },
);
/**
 * 00:30 Vietnam: the days not yet rolled up (the day that ended, or up to 30 after a deploy), then
 * every family's directory row so "Hoạt động / Ít hoạt động" stays true without writes.
 */
export const rollupDaily = onSchedule(
  { schedule: '30 0 * * *', timeZone: 'Asia/Ho_Chi_Minh', timeoutSeconds: 540, memory: '1GiB' },
  async () => {
    const now = new Date();
    const days = await backfillDays(getFirestore(), now, 30);
    const families = await refreshAllFamilies(getFirestore(), now, familyDeps);
    logger.info('daily rollup', { days: days.length, families });
  },
);

// Dữ liệu tham chiếu (C01–C04, P-138): drafts, a second person approves, then the apps get it.
export const staffReference = staffCall('staffReference', (s, d) =>
  referenceView(getFirestore(), s, d),
);
export const staffReferenceDraft = staffCall('staffReferenceDraft', (s, d) =>
  referenceDraft(getFirestore(), s, d, new Date()),
);
export const staffReferenceAct = staffCall('staffReferenceAct', (s, d) =>
  referenceAct(getFirestore(), s, d, new Date()),
);

// Sơ cứu (D-058, P-141): the guide's draft, a second person approves (an expert on prod), the
// app reads publicConfig/content_firstAid; pictures are public WebP under content/first-aid/.
/** Public, immutable WebP pictures under `content/{folder}/` (Sơ cứu, Có gì mới). */
function publicImageStore(folder: string): FirstAidImageStore {
  const bucket = getStorage().bucket();
  const prefix = `content/${folder}/`;
  const path = (id: string) => `${prefix}${id}.webp`;
  return {
    exists: async (id) => (await bucket.file(path(id)).exists())[0],
    save: (id, webp) =>
      bucket.file(path(id)).save(webp, {
        contentType: 'image/webp',
        metadata: { cacheControl: 'public, max-age=31536000, immutable' },
      }),
    list: async () =>
      (await bucket.getFiles({ prefix }))[0]
        .map((f) => f.name.slice(prefix.length).replace(/\.webp$/, ''))
        .filter((id) => /^[a-z0-9-]{2,48}_[a-f0-9]{8}$/.test(id)),
    publicUrl: (id) =>
      `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path(id))}?alt=media`,
    encode: (bytes, icon) =>
      (icon
        ? sharp(bytes).resize(176, 176, {
            fit: 'contain',
            background: { r: 0, g: 0, b: 0, alpha: 0 },
          })
        : sharp(bytes).resize({ width: 1200, withoutEnlargement: true })
      )
        .webp({ quality: icon ? 90 : 78 })
        .toBuffer(),
  };
}
function contentDeps(): ContentDeps {
  return {
    requireReview: environmentForProject(currentProjectId()) === 'prod',
    images: publicImageStore('first-aid'),
  };
}
export const staffFirstAid = staffCall('staffFirstAid', (s) =>
  firstAidView(getFirestore(), contentDeps(), s),
);
export const staffFirstAidDraft = staffCall('staffFirstAidDraft', (s, d) =>
  firstAidDraft(getFirestore(), contentDeps(), s, d, new Date()),
);
export const staffFirstAidAct = staffCall('staffFirstAidAct', (s, d) =>
  firstAidAct(getFirestore(), contentDeps(), s, d, new Date()),
);
export const staffFirstAidImage = staffCall('staffFirstAidImage', (s, d) =>
  firstAidUploadImage(getFirestore(), contentDeps(), s, d, new Date()),
);

// Nhịp lớn lên (PN01–PN04, D-073 #2): reference model and content pack on the Sơ cứu workflow
// (a second person approves, a qualified reviewer on prod); rules in config/rhythm.
function rhythmContentDeps(): RhythmContentDeps {
  return { requireReview: environmentForProject(currentProjectId()) === 'prod' };
}
export const staffRhythm = staffCall('staffRhythm', (s) =>
  rhythmView(getFirestore(), rhythmContentDeps(), s),
);
export const staffRhythmDraft = staffCall('staffRhythmDraft', (s, d) =>
  rhythmDraft(getFirestore(), s, d, new Date()),
);
export const staffRhythmAct = staffCall('staffRhythmAct', (s, d) =>
  rhythmAct(getFirestore(), rhythmContentDeps(), s, d, new Date()),
);
export const staffRhythmRules = staffCall('staffRhythmRules', (s) =>
  rhythmRulesView(getFirestore(), s),
);
export const staffSetRhythmRules = staffCall('staffSetRhythmRules', (s, d) =>
  setRhythmRules(getFirestore(), s, d, new Date()),
);

// Mẫu kỷ niệm (D-068 #7): the template catalog and its artwork are managed in the portal and
// published to publicConfig/keepsakes; assets are public and immutable under content/keepsakes/.
function keepsakeDeps(): KeepsakeContentDeps {
  const bucket = getStorage().bucket();
  const prefix = 'content/keepsakes/';
  return {
    assets: {
      exists: async (asset) => (await bucket.file(prefix + asset).exists())[0],
      save: (asset, bytes, contentType) =>
        bucket.file(prefix + asset).save(bytes, {
          contentType,
          metadata: { cacheControl: 'public, max-age=31536000, immutable' },
        }),
      list: async () =>
        (await bucket.getFiles({ prefix }))[0]
          .map((f) => f.name.slice(prefix.length))
          .filter((a) => /^[a-z0-9-]{2,40}_[a-f0-9]{8}\.(webp|mp3|m4a|mp4)$/.test(a)),
      readIncoming: async (path) => {
        const file = bucket.file(path);
        if (!(await file.exists())[0]) return null;
        return (await file.download())[0];
      },
      deleteIncoming: async (path) => {
        await bucket.file(path).delete({ ignoreNotFound: true });
      },
      publicUrl: (asset) =>
        `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(prefix + asset)}?alt=media`,
      encodeImage: (bytes) =>
        sharp(bytes)
          .resize({ width: 2160, withoutEnlargement: true })
          .webp({ quality: 85 })
          .toBuffer(),
    },
  };
}
export const staffKeepsakes = staffCall('staffKeepsakes', (s) =>
  keepsakeView(getFirestore(), keepsakeDeps(), s),
);
export const staffKeepsakesDraft = staffCall('staffKeepsakesDraft', (s, d) =>
  keepsakeDraft(getFirestore(), keepsakeDeps(), s, d, new Date()),
);
export const staffKeepsakesAct = staffCall('staffKeepsakesAct', (s, d) =>
  keepsakeAct(getFirestore(), s, d, new Date()),
);
export const staffKeepsakesAsset = staffCall('staffKeepsakesAsset', (s, d) =>
  keepsakeUploadAsset(getFirestore(), keepsakeDeps(), s, d, new Date()),
);

// Video kỷ niệm (D-068): render jobs handed to the private Cloud Run renderer (Remotion) via Cloud
// Tasks; nothing is dispatched until KEEPSAKE_RENDERER_URL is set for the project (plan §5).
const keepsakeRendererUrl = defineString('KEEPSAKE_RENDERER_URL', { default: '' });
function keepsakeDispatcher(): RenderDispatcher | null {
  const url = keepsakeRendererUrl.value();
  if (!url || process.env.FUNCTIONS_EMULATOR === 'true') return null;
  const project = currentProjectId();
  if (!project) return null;
  return cloudTasksDispatcher({
    project,
    region: 'asia-southeast1',
    queue: 'keepsake-render',
    rendererUrl: url,
    serviceAccount: `keepsake-tasks@${project}.iam.gserviceaccount.com`,
  });
}
function keepsakeCall<T>(name: string, run: (uid: string, data: unknown) => Promise<T>) {
  return onCall(async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return await run(request.auth.uid, request.data);
    } catch (error) {
      if (error instanceof KeepsakeJobError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      // Never the payload: names, texts and photo paths are child data.
      logger.error(`${name} failed`, { error: String(error) });
      throw new HttpsError('internal', `${name} failed`);
    }
  });
}
/** MM07 "Tạo video". */
export const requestMemoryStory = keepsakeCall('requestMemoryStory', (uid, data) =>
  requestMemoryStoryJob(getFirestore(), keepsakeDispatcher(), uid, data, new Date()),
);
/** MM14 "Thử lại". */
export const retryMemoryStory = keepsakeCall('retryMemoryStory', (uid, data) =>
  retryMemoryStoryJob(getFirestore(), keepsakeDispatcher(), uid, data, new Date()),
);
/** MO04: the household's video quota (Q2) for the window a new video would count in. */
export const getVideoQuota = keepsakeCall('getVideoQuota', (uid, data) =>
  getVideoQuotaJob(getFirestore(), uid, data, new Date()),
);
/** MM14 "Xoá bản nháp". */
export const deleteMemoryStory = keepsakeCall('deleteMemoryStory', (uid, data) =>
  deleteMemoryStoryJob(getFirestore(), bucketStore(getStorage().bucket()), uid, data),
);
/** MM08: the job's Live Activity token (iPhone) or the phone's FCM token (Android, A6). */
export const attachMemoryStoryLive = keepsakeCall('attachMemoryStoryLive', (uid, data) =>
  attachKeepsakeLive(getFirestore(), uid, data, new Date()),
);
/** Live Activity pushes through FCM (the activity's ActivityKit token, the device's FCM token). */
const liveSender = (): LiveSender | null => {
  if (process.env.FUNCTIONS_EMULATOR === 'true') return null;
  return {
    async send(live, event, state, now) {
      const ts = Math.floor(now.getTime() / 1000);
      try {
        await getMessaging().send({
          token: live.fcm,
          apns: {
            liveActivityToken: live.token,
            headers: { 'apns-priority': event === 'end' ? '10' : '5' },
            payload: {
              aps: {
                timestamp: ts,
                event,
                'content-state': state,
                // Finished: the result stays on the lock screen for a while, then goes.
                ...(event === 'end' ? { 'dismissal-date': ts + 30 * 60 } : {}),
              },
            },
          },
        });
        return true;
      } catch (error) {
        const code = (error as { code?: string }).code ?? '';
        logger.warn('keepsake live push failed', { code });
        return ![
          'messaging/registration-token-not-registered',
          'messaging/invalid-argument',
        ].includes(code);
      }
    },
    async android(fcm, job, event, state) {
      try {
        await getMessaging().send({
          token: fcm,
          // Ids, status and percent only (R-116); PushService.kt draws the progress notice.
          data: {
            kind: 'keepsakeProgress',
            babyId: job.babyId,
            jobId: job.jobId,
            event,
            status: state.status,
            step: state.step ?? '',
            progress: String(state.progress),
          },
          android: { priority: event === 'end' ? 'high' : 'normal' },
        });
        return true;
      } catch (error) {
        const code = (error as { code?: string }).code ?? '';
        logger.warn('keepsake android push failed', { code });
        return ![
          'messaging/registration-token-not-registered',
          'messaging/invalid-argument',
        ].includes(code);
      }
    },
  };
};
/**
 * A job changed: its Live Activity follows, a failure tells the person who asked, and a job the
 * renderer marked completed is filed in Kỷ niệm (and tells them it is ready).
 */
export const onKeepsakeJobWritten = onDocumentWritten(
  'babies/{babyId}/keepsakeJobs/{jobId}',
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    await keepsakeJobChanged(
      getFirestore(),
      liveSender(),
      event.params.babyId,
      event.params.jobId,
      before,
      after,
      new Date(),
    );
    if (!after?.exists || after.get('status') !== 'completed' || after.get('memoryId')) return;
    await completeKeepsakeJob(
      getFirestore(),
      bucketStore(getStorage().bucket()),
      sharpImages,
      event.params.babyId,
      event.params.jobId,
      new Date(),
    );
  },
);
/** Jobs stuck rendering or never picked up fail, so "Thử lại" is offered (MM14). */
export const sweepKeepsakeJobsEvery15 = onSchedule('every 15 minutes', async () => {
  await sweepKeepsakeJobs(getFirestore(), bucketStore(getStorage().bucket()), new Date());
});

// ---- Premium billing (Slice 4 B1, plan §5.2, D-072 #1 / #6) ---------------------------------
// Provider-neutral core in billing.ts. Real Apple / Google adapters are postponed by the owner
// (D-074): the registry is empty, so every purchase call answers failed-precondition
// 'billing-not-configured' and nothing is granted. A future slice plugs real adapters in here and
// adds the appStoreNotifications (HTTP) and playRtdn (Pub/Sub) triggers over billing.ts.
const billingAdapters = (): BillingAdapters => noBillingAdapters;
function billingCall<T>(name: string, run: (uid: string, data: unknown) => Promise<T>) {
  return onCall(async (request) => {
    const uid = requireAccount(request);
    try {
      return await run(uid, request.data);
    } catch (error) {
      if (error instanceof BillingError || error instanceof EntitlementError) {
        throw new HttpsError(error.code, error.reason, { reason: error.reason });
      }
      // Never the payload: transaction ids and purchase tokens stay out of logs.
      logger.error(`${name} failed`, { error: error instanceof Error ? error.name : 'unknown' });
      throw new HttpsError('internal', `${name} failed`);
    }
  });
}
/** PR01 "Tiếp tục với Premium": the owner's purchase intent (account token for the store). */
export const startPurchase = billingCall('startPurchase', (uid, data) =>
  startPurchaseCore(
    getFirestore(),
    billingAdapters(),
    uid,
    data,
    new Date(),
    serverGrantEnvironment(),
  ),
);
/** PR02: the store's answer re-checked with the provider, then the household grant. */
export const verifyPurchase = billingCall('verifyPurchase', (uid, data) =>
  verifyPurchaseCore(
    getFirestore(),
    billingAdapters(),
    uid,
    data,
    new Date(),
    serverGrantEnvironment(),
  ),
);
/** PR01 / PR03 "Khôi phục": never moves a subscription to another household. */
export const restorePurchase = billingCall('restorePurchase', (uid, data) =>
  restorePurchaseCore(
    getFirestore(),
    billingAdapters(),
    uid,
    data,
    new Date(),
    serverGrantEnvironment(),
  ),
);
/** Subscriptions ending soon, in grace, on hold or pending are refetched (no-op without adapters). */
export const reconcileSubscriptions = onSchedule('every 6 hours', async () => {
  await reconcileBillingSubscriptions(getFirestore(), billingAdapters(), new Date());
});
// ---- end Premium billing ---------------------------------------------------------------------

// Cập nhật ứng dụng (D-061): store versions, the oldest allowed, "Có gì mới"; the app reads
// publicConfig/appUpdate.
const appUpdateDeps = () => ({ images: publicImageStore('app-update') });
export const staffAppUpdate = staffCall('staffAppUpdate', (s) =>
  appUpdateView(getFirestore(), appUpdateDeps(), s),
);
export const staffAppUpdateSave = staffCall('staffAppUpdateSave', (s, d) =>
  appUpdateSave(getFirestore(), appUpdateDeps(), s, d, new Date()),
);
export const staffAppUpdateImage = staffCall('staffAppUpdateImage', (s, d) =>
  appUpdateUploadImage(getFirestore(), appUpdateDeps(), s, d, new Date()),
);

// QA handbook (P-132): test runs, results and comments; never family data.
export const staffQa = staffCall('staffQa', (s, d) => qaHandbook(getFirestore(), s, d));
export const staffQaCase = staffCall('staffQaCase', (s, d) => qaCaseComments(getFirestore(), s, d));
export const staffQaUpdate = staffCall('staffQaUpdate', (s, d) =>
  qaUpdate(getFirestore(), s, d, new Date()),
);
