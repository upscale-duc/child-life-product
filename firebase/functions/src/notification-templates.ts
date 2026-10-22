import {
  localizedTemplateCopySchema,
  notificationOpsConfigSchema,
  notificationTemplateIds,
  notificationTemplates,
  notificationTypes,
  staffSaveTemplateSchema,
  staffTemplateActionSchema,
  validateTemplateCopy,
  type LocalizedTemplateCopy,
  type NotificationTemplateDetail,
  type NotificationTemplateId,
  type NotificationTemplateRow,
  type NotificationTemplateStatus,
  type NotificationTemplateVersion,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';
import { STATS, STATS_ZONE } from './notification-ledger.js';
import { localDateIn } from '@child-life/contracts';
import { TEMPLATES, clearNotificationCaches } from './notification-runtime.js';

/**
 * Notification templates (P-174, docs/notifications/05-templates.md). Version 0 of every template
 * is the copy in code (`notificationTemplates[id].builtin`, equal to what the producers sent before
 * the Portal existed). Staff edit a draft, submit it for review and a person with
 * `notifications.publish` publishes it as an immutable version n (`versions/{n}`). The template doc
 * carries the live copy (`live`) that producers read, so a send costs one cached read. Pause,
 * archive or the ops switch `templatesEnabled: false` make every producer fall back to version 0 —
 * sending never stops because of a template. Rollback points `live` at an older version (0 = code).
 * Every mutation writes `staffAudit` (category `notifications`).
 */

// ---------- Staff ----------

const iso = (v: unknown): string | null =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;

function rowOf(
  id: NotificationTemplateId,
  doc: DocumentSnapshot | null,
  sent30d: number | null,
): NotificationTemplateRow {
  const def = notificationTemplates[id];
  const type = notificationTypes[def.kind];
  const status = (doc?.get('status') as NotificationTemplateStatus | undefined) ?? 'builtin';
  const draft = doc?.get('draft') as LocalizedTemplateCopy | null | undefined;
  return {
    id,
    kind: def.kind,
    group: type.group,
    status,
    draftState: draft ? (doc?.get('submittedBy') ? 'ready_for_review' : 'draft') : 'none',
    liveVersion: Number(doc?.get('live.version') ?? 0),
    latestVersion: Number(doc?.get('latestVersion') ?? 0),
    hasVi: true,
    hasEn: true,
    destination: type.destination,
    updatedAt: iso(doc?.get('updatedAt')),
    updatedBy: (doc?.get('updatedBy') as string | undefined) ?? null,
    sent30d,
  };
}

async function sentLast30Days(db: Firestore, now: Date): Promise<Map<string, number> | null> {
  try {
    const from = localDateIn(STATS_ZONE, new Date(now.getTime() - 30 * 86_400_000));
    const docs = await db.collection(STATS).where('day', '>=', from).get();
    const out = new Map<string, number>();
    for (const d of docs.docs) {
      const v = (d.get('v') as Record<string, Record<string, number>> | undefined) ?? {};
      for (const [key, counts] of Object.entries(v)) {
        const id = key.split('@')[0]!.replace(/~/g, '.');
        out.set(id, (out.get(id) ?? 0) + Number(counts.inbox ?? 0));
      }
    }
    return out;
  } catch {
    return null;
  }
}

export async function listNotificationTemplates(
  db: Firestore,
  staff: Staff | null,
  now: Date,
): Promise<{ templates: NotificationTemplateRow[] }> {
  requireTemplateReader(staff);
  const [docs, sent] = await Promise.all([
    db.getAll(...notificationTemplateIds.map((id) => db.doc(`${TEMPLATES}/${id}`))),
    sentLast30Days(db, now),
  ]);
  return {
    templates: notificationTemplateIds.map((id, i) =>
      rowOf(id, docs[i]!.exists ? docs[i]! : null, sent ? (sent.get(id) ?? 0) : null),
    ),
  };
}

async function detailOf(
  db: Firestore,
  id: NotificationTemplateId,
): Promise<NotificationTemplateDetail> {
  const doc = await db.doc(`${TEMPLATES}/${id}`).get();
  const versions = await db
    .collection(`${TEMPLATES}/${id}/versions`)
    .orderBy('version', 'desc')
    .limit(50)
    .get();
  const def = notificationTemplates[id];
  const draft = (doc.get('draft') as LocalizedTemplateCopy | null | undefined) ?? null;
  const liveCopy = (doc.get('live.copy') as LocalizedTemplateCopy | undefined) ?? def.builtin;
  const list: NotificationTemplateVersion[] = versions.docs.map((v) => ({
    version: Number(v.get('version')),
    copy: v.get('copy') as LocalizedTemplateCopy,
    publishedAt: iso(v.get('publishedAt')) ?? '',
    publishedBy: String(v.get('publishedBy') ?? ''),
    note: String(v.get('note') ?? ''),
  }));
  return {
    ...rowOf(id, doc.exists ? doc : null, null),
    live: liveCopy,
    draft,
    draftBy: (doc.get('draftBy') as string | undefined) ?? null,
    submittedBy: (doc.get('submittedBy') as string | undefined) ?? null,
    versions: list,
    issues: draft ? validateTemplateCopy(def, draft) : [],
  };
}

/** Templates are read by viewers of the module and by content editors (experts) alike. */
function requireTemplateReader(staff: Staff | null): Staff {
  try {
    return requireStaff(staff, 'notifications.view');
  } catch {
    return requireStaff(staff, 'notifications.edit');
  }
}

export async function getNotificationTemplate(db: Firestore, staff: Staff | null, data: unknown) {
  requireTemplateReader(staff);
  const id = parseTemplateId(data);
  return detailOf(db, id);
}

function parseTemplateId(data: unknown): NotificationTemplateId {
  const id = (data as { templateId?: unknown } | null)?.templateId;
  if (typeof id !== 'string' || !(notificationTemplateIds as readonly string[]).includes(id))
    throw new StaffError('invalid-argument', 'malformed');
  return id as NotificationTemplateId;
}

export async function saveNotificationTemplate(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'notifications.edit');
  const { templateId, copy } = parse(staffSaveTemplateSchema, data) as {
    templateId: NotificationTemplateId;
    copy: LocalizedTemplateCopy;
  };
  const issues = validateTemplateCopy(notificationTemplates[templateId], copy);
  if (issues.length) throw new TemplateInvalid(issues);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`${TEMPLATES}/${templateId}`);
    const doc = await tx.get(ref);
    tx.set(
      ref,
      {
        templateId,
        status: doc.get('status') ?? 'draft',
        draft: copy,
        draftBy: s.name,
        submittedBy: null,
        updatedAt: now,
        updatedBy: s.name,
        latestVersion: doc.get('latestVersion') ?? 0,
        ...(doc.exists ? {} : { live: null, createdAt: now }),
      },
      { merge: true },
    );
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'notifications.template.save',
        category: 'notifications',
        target: templateId,
        reason: null,
      },
      now,
    );
  });
  clearNotificationCaches();
  return detailOf(db, templateId);
}

/** `template-invalid` with the issues the editor shows. */
export class TemplateInvalid extends StaffError {
  constructor(readonly issues: unknown[]) {
    super('invalid-argument', 'template-invalid');
  }
}

export async function actOnNotificationTemplate(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const action = parse(
    staffTemplateActionSchema,
    data,
  ) as import('@child-life/contracts').StaffTemplateAction;
  const s = requireStaff(
    staff,
    action.action === 'submit' || action.action === 'discard'
      ? 'notifications.edit'
      : 'notifications.publish',
  );
  const id = action.templateId as NotificationTemplateId;
  const def = notificationTemplates[id];
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`${TEMPLATES}/${id}`);
    const doc = await tx.get(ref);
    const status = (doc.get('status') as NotificationTemplateStatus | undefined) ?? 'builtin';
    const draft = (doc.get('draft') as LocalizedTemplateCopy | null | undefined) ?? null;
    const latest = Number(doc.get('latestVersion') ?? 0);
    const liveVersion = Number(doc.get('live.version') ?? 0);
    let detail: Record<string, unknown> = {};
    switch (action.action) {
      case 'submit': {
        if (!draft) throw new StaffError('failed-precondition', 'stale');
        tx.update(ref, { submittedBy: s.name, updatedAt: now, updatedBy: s.name });
        break;
      }
      case 'discard': {
        if (!draft) throw new StaffError('failed-precondition', 'stale');
        tx.update(ref, {
          draft: null,
          draftBy: null,
          submittedBy: null,
          updatedAt: now,
          updatedBy: s.name,
        });
        break;
      }
      case 'publish': {
        if (!draft || !doc.get('submittedBy')) throw new StaffError('failed-precondition', 'stale');
        const issues = validateTemplateCopy(def, draft);
        if (issues.length) throw new TemplateInvalid(issues);
        const version = latest + 1;
        tx.create(db.doc(`${TEMPLATES}/${id}/versions/${version}`), {
          version,
          copy: draft,
          publishedAt: now,
          publishedBy: s.name,
          note: action.note ?? '',
          editedBy: doc.get('draftBy') ?? null,
          submittedBy: doc.get('submittedBy') ?? null,
        });
        tx.update(ref, {
          status: 'published',
          live: { version, copy: draft },
          latestVersion: version,
          draft: null,
          draftBy: null,
          submittedBy: null,
          publishedAt: now,
          updatedAt: now,
          updatedBy: s.name,
        });
        // Four-eyes is recorded, not enforced: a small team may self-approve, visibly.
        detail = {
          version,
          selfApproved: doc.get('submittedBy') === s.name || doc.get('draftBy') === s.name,
        };
        break;
      }
      case 'pause': {
        if (status !== 'published') throw new StaffError('failed-precondition', 'stale');
        tx.update(ref, { status: 'paused', updatedAt: now, updatedBy: s.name });
        detail = { version: liveVersion };
        break;
      }
      case 'resume': {
        if (status !== 'paused' && status !== 'archived')
          throw new StaffError('failed-precondition', 'stale');
        if (liveVersion === 0) throw new StaffError('failed-precondition', 'stale');
        tx.update(ref, { status: 'published', updatedAt: now, updatedBy: s.name });
        detail = { version: liveVersion };
        break;
      }
      case 'archive': {
        if (!doc.exists) throw new StaffError('failed-precondition', 'stale');
        tx.update(ref, { status: 'archived', updatedAt: now, updatedBy: s.name });
        break;
      }
      case 'rollback': {
        const target = action.version;
        if (target === liveVersion || target > latest)
          throw new StaffError('failed-precondition', 'stale');
        if (target === 0) {
          tx.set(
            ref,
            { status: 'builtin', live: null, updatedAt: now, updatedBy: s.name, templateId: id },
            { merge: true },
          );
        } else {
          const v = await tx.get(db.doc(`${TEMPLATES}/${id}/versions/${target}`));
          if (!v.exists) throw new StaffError('not-found', 'not-found');
          const copy = localizedTemplateCopySchema.safeParse(v.get('copy'));
          if (!copy.success || validateTemplateCopy(def, copy.data).length)
            throw new StaffError('failed-precondition', 'template-invalid');
          tx.update(ref, {
            status: 'published',
            live: { version: target, copy: copy.data },
            updatedAt: now,
            updatedBy: s.name,
          });
        }
        detail = { from: liveVersion, to: target };
        break;
      }
    }
    staffAudit(
      tx,
      db,
      s,
      {
        action: `notifications.template.${action.action}`,
        category: 'notifications',
        target: id,
        reason: null,
        detail,
      },
      now,
    );
  });
  clearNotificationCaches();
  return detailOf(db, id);
}

export async function setNotificationOps(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'notifications.ops');
  const raw = (data as { config?: unknown } | null)?.config;
  const parsed = notificationOpsConfigSchema.safeParse(raw);
  if (!parsed.success) throw new StaffError('invalid-argument', 'malformed');
  await db.runTransaction(async (tx) => {
    const ref = db.doc('config/notifications');
    const before = await tx.get(ref);
    tx.set(ref, { ...parsed.data, updatedAt: now, updatedBy: s.name });
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'notifications.ops.set',
        category: 'notifications',
        target: 'config/notifications',
        reason: null,
        detail: {
          before: before.exists
            ? {
                templatesEnabled: before.get('templatesEnabled') ?? null,
                retryEnabled: before.get('retryEnabled') ?? null,
                pushPaused: before.get('pushPaused') ?? null,
              }
            : null,
          after: parsed.data,
        },
      },
      now,
    );
  });
  clearNotificationCaches();
  return { ops: parsed.data };
}
