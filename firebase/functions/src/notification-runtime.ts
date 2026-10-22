import {
  defaultNotificationOpsConfig,
  localizedTemplateCopySchema,
  notificationOpsConfigSchema,
  notificationTemplates,
  validateTemplateCopy,
  type LocalizedTemplateCopy,
  type NotificationOpsConfig,
  type NotificationTemplateId,
  type NotificationTemplateStatus,
} from '@child-life/contracts';
import type { Firestore } from 'firebase-admin/firestore';

/**
 * What a send reads (P-174): the ops switches `config/notifications` and the live copy of a
 * template, each cached per instance for a minute. Kept apart from the staff module so producers
 * do not load Portal code. See notification-templates.ts for the workflow.
 */

export const TEMPLATES = 'notificationTemplates';
const CACHE_MS = 60_000;

interface LiveTemplate {
  version: number;
  copy: LocalizedTemplateCopy;
}
const cache = new Map<string, { at: number; value: LiveTemplate | null }>();
let opsCache: { at: number; value: NotificationOpsConfig } | null = null;

/** Tests and staff writes drop the per-instance caches. */
export function clearNotificationCaches() {
  cache.clear();
  opsCache = null;
}

export async function notificationOps(
  db: Firestore,
  now = Date.now(),
): Promise<NotificationOpsConfig> {
  if (opsCache && now - opsCache.at < CACHE_MS) return opsCache.value;
  const doc = await db.doc('config/notifications').get();
  // The doc also carries who changed it and when; only the switches are parsed.
  const { templatesEnabled, retryEnabled, pushPaused } = (doc.data() ?? {}) as Record<
    string,
    unknown
  >;
  const parsed = notificationOpsConfigSchema.safeParse(
    Object.fromEntries(
      Object.entries({ templatesEnabled, retryEnabled, pushPaused }).filter(
        ([, v]) => v !== undefined,
      ),
    ),
  );
  // A malformed doc must not stop notifications: the safe defaults apply.
  const value = parsed.success ? parsed.data : defaultNotificationOpsConfig;
  opsCache = { at: now, value };
  return value;
}

/** The published copy producers use, or null for version 0 (code). */
export async function liveTemplate(
  db: Firestore,
  id: NotificationTemplateId,
  now = Date.now(),
): Promise<LiveTemplate | null> {
  const hit = cache.get(id);
  if (hit && now - hit.at < CACHE_MS) return hit.value;
  const doc = await db.doc(`${TEMPLATES}/${id}`).get();
  let value: LiveTemplate | null = null;
  const status = doc.get('status') as NotificationTemplateStatus | undefined;
  const live = doc.get('live') as { version?: unknown; copy?: unknown } | undefined;
  if (status === 'published' && live && typeof live.version === 'number' && live.version > 0) {
    const copy = localizedTemplateCopySchema.safeParse(live.copy);
    // A copy that no longer validates (registry changed) is never sent: version 0 instead.
    if (copy.success && validateTemplateCopy(notificationTemplates[id], copy.data).length === 0)
      value = { version: live.version, copy: copy.data };
  }
  cache.set(id, { at: now, value });
  return value;
}
