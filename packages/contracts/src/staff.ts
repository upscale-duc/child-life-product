import { z } from 'zod';
import { flagKeys, rolloutScopes } from './config.js';

/**
 * Staff portal "Child Life · Vận hành" (Slice S15; Figma A01–A12; business map §5.1, §7.15,
 * R-180…R-190, D-007, D-043, P-120…P-125). Staff never see photos, videos, captions or care
 * records; they see masked emails, anonymous family codes, counts and bytes. Every mutation needs
 * a reason and lands in the append-only staff audit log (A12).
 */

/**
 * Staff access v1.0 (P-134, Figma A18–A21): a role is a set of levels, one per portal function.
 * Built-in roles ship here; Owner, Admin and Kiểm thử are locked, the others can be re-tuned on the
 * portal (`staffRoles/{id}`) and staff may add their own roles. The server resolves a member's roles
 * to levels on every call; the ID token only carries `staff: true`, the role ids and a name.
 */
export const staffRoles = [
  'owner',
  'admin',
  'ops',
  'support',
  'eng',
  'analyst',
  'expert',
  'qa',
] as const;
export type BuiltinStaffRole = (typeof staffRoles)[number];
/** A built-in role id, or the id of a role made on the portal ("r_…"). */
export type StaffRole = string;

/** Roles nobody can edit on the portal (A21 lock icons; Kiểm thử is the QA handbook, P-132). */
export const lockedStaffRoles: readonly BuiltinStaffRole[] = ['owner', 'admin', 'qa'];

/** S15 claims: trưởng nhóm became Admin in v1.0 (P-134). */
export const legacyStaffRoles: Record<string, BuiltinStaffRole> = { lead: 'admin' };

/** Portal functions, in the order of the A19 matrix (rows). */
export const staffFunctions = [
  'overview',
  'analyticsExport',
  'families',
  'familyTransfer',
  'support',
  'storage',
  'dataJobs',
  'reference',
  'system',
  'features',
  'staff',
  'audit',
  'qa',
] as const;
export type StaffFunction = (typeof staffFunctions)[number];

/**
 * — · Xem · che · Xem · Sửa (the routine action) · Duyệt (the sensitive action, and approving
 * someone else's request) · Toàn quyền (Duyệt + configuring the function).
 */
export const staffLevels = ['none', 'viewMasked', 'view', 'edit', 'approve', 'full'] as const;
export type StaffLevel = (typeof staffLevels)[number];
export type StaffLevels = Record<StaffFunction, StaffLevel>;

export function levelAtLeast(have: StaffLevel | undefined, need: StaffLevel): boolean {
  return staffLevels.indexOf(have ?? 'none') >= staffLevels.indexOf(need);
}

const none = Object.fromEntries(staffFunctions.map((f) => [f, 'none'])) as StaffLevels;
const all = (level: StaffLevel) =>
  Object.fromEntries(staffFunctions.map((f) => [f, level])) as StaffLevels;

/**
 * Built-in levels (A19, with the P-134 fixes: Owner is never weaker than Admin, Kỹ sư keeps the
 * data-job re-run and has no ticket access because tickets may hold child details, P-124).
 */
export const staffRoleTemplates: Record<BuiltinStaffRole, StaffLevels> = {
  owner: all('full'),
  admin: { ...all('full'), staff: 'edit' },
  ops: {
    ...none,
    overview: 'view',
    families: 'view',
    familyTransfer: 'edit',
    support: 'edit',
    storage: 'edit',
    dataJobs: 'edit',
    reference: 'edit',
    system: 'view',
    features: 'view',
    audit: 'view',
    qa: 'edit',
  },
  support: {
    ...none,
    overview: 'view',
    families: 'viewMasked',
    support: 'edit',
    storage: 'view',
    dataJobs: 'view',
    reference: 'view',
    qa: 'edit',
  },
  eng: {
    ...none,
    overview: 'view',
    dataJobs: 'edit',
    system: 'edit',
    features: 'edit',
    audit: 'view',
    qa: 'full',
  },
  analyst: { ...none, overview: 'view', analyticsExport: 'edit', qa: 'edit' },
  expert: { ...none, reference: 'approve', qa: 'edit' },
  qa: { ...none, qa: 'full' },
};

/**
 * Hard ceilings (A21 "Quyền xem email đầy đủ, xuất hoặc xoá dữ liệu không thể cấp cho vai trò Hỗ
 * trợ"; "Gia đình · chuyển chủ · Chỉ Vận hành trở lên"). Applied to edits of that role.
 */
export const staffRoleCaps: Partial<Record<BuiltinStaffRole, Partial<StaffLevels>>> = {
  support: {
    familyTransfer: 'none',
    analyticsExport: 'none',
    dataJobs: 'view',
    staff: 'none',
  },
};

/** Applies a role's ceilings to the levels someone wants to give it. */
export function capLevels(role: string, levels: StaffLevels): StaffLevels {
  const caps = staffRoleCaps[role as BuiltinStaffRole];
  if (!caps) return levels;
  const out = { ...levels };
  for (const [f, cap] of Object.entries(caps) as Array<[StaffFunction, StaffLevel]>) {
    if (!levelAtLeast(cap, out[f])) out[f] = cap;
  }
  return out;
}

export function builtinRole(role: string): BuiltinStaffRole | null {
  const id = legacyStaffRoles[role] ?? role;
  return (staffRoles as readonly string[]).includes(id) ? (id as BuiltinStaffRole) : null;
}

/**
 * A member's levels: the highest level any of their roles gives. `custom` holds the roles stored
 * on the portal (edited built-ins and made-up roles); locked roles always use the template.
 */
export function levelsForRoles(
  roles: readonly string[],
  custom: Readonly<Record<string, StaffLevels>> = {},
): StaffLevels {
  const out = { ...none };
  for (const r of roles) {
    const builtin = builtinRole(r);
    const levels =
      builtin && lockedStaffRoles.includes(builtin)
        ? staffRoleTemplates[builtin]
        : (custom[builtin ?? r] ?? (builtin ? staffRoleTemplates[builtin] : null));
    if (!levels) continue;
    for (const f of staffFunctions) {
      if (levelAtLeast(levels[f], out[f])) out[f] = levels[f];
    }
  }
  return out;
}

export const staffActions = [
  'overview.view',
  'analytics.view',
  'analytics.export',
  'families.view',
  'families.transfer',
  'support.view',
  'support.claim',
  'support.reply',
  'support.close',
  'storage.view',
  'storage.decide',
  'storage.large',
  'jobs.view',
  'jobs.rerun',
  'jobs.approve',
  'reference.view',
  'reference.edit',
  'reference.approve',
  'system.view',
  'features.view',
  'flags.toggle',
  'flags.rollout',
  'staff.view',
  'staff.manage',
  'staff.owners',
  'audit.view',
  'audit.export',
  'qa.view',
  'qa.test',
  'qa.manage',
] as const;
export type StaffAction = (typeof staffActions)[number];

/** Each action is one function at a minimum level (§5.1 as of v1.0). */
export const staffActionLevel: Record<StaffAction, readonly [StaffFunction, StaffLevel]> = {
  'overview.view': ['overview', 'view'],
  'analytics.view': ['overview', 'view'],
  'analytics.export': ['analyticsExport', 'edit'],
  'families.view': ['families', 'viewMasked'],
  'families.transfer': ['familyTransfer', 'edit'],
  'support.view': ['support', 'viewMasked'],
  'support.claim': ['support', 'edit'],
  'support.reply': ['support', 'edit'],
  'support.close': ['support', 'edit'],
  'storage.view': ['storage', 'view'],
  'storage.decide': ['storage', 'edit'],
  // P-120: more than 20 GB, or a custom amount, needs "Duyệt" (was trưởng nhóm).
  'storage.large': ['storage', 'approve'],
  'jobs.view': ['dataJobs', 'view'],
  'jobs.rerun': ['dataJobs', 'edit'],
  // P-139: a deletion re-run needs a second person ("Xoá cần người thứ hai duyệt").
  'jobs.approve': ['dataJobs', 'approve'],
  'reference.view': ['reference', 'view'],
  'reference.edit': ['reference', 'edit'],
  'reference.approve': ['reference', 'approve'],
  'system.view': ['system', 'view'],
  'features.view': ['features', 'view'],
  'flags.toggle': ['features', 'edit'],
  'flags.rollout': ['features', 'edit'],
  'staff.view': ['staff', 'view'],
  'staff.manage': ['staff', 'edit'],
  // "Chỉ Owner đổi vai trò Owner, Admin".
  'staff.owners': ['staff', 'full'],
  'audit.view': ['audit', 'view'],
  'audit.export': ['audit', 'view'],
  'qa.view': ['qa', 'view'],
  'qa.test': ['qa', 'edit'],
  'qa.manage': ['qa', 'full'],
};

export function staffCan(levels: StaffLevels, action: StaffAction): boolean {
  const [fn, level] = staffActionLevel[action];
  return levelAtLeast(levels[fn], level);
}

/** "n***@gmail.com" (A03, A06). */
export function maskEmail(email: string | null | undefined): string {
  if (!email || !email.includes('@')) return '—';
  const [user, domain] = email.split('@') as [string, string];
  return `${user.slice(0, 1)}***@${domain}`;
}

const reason = z.string().trim().min(3).max(500);

export const overviewRequestSchema = z.object({
  days: z.union([z.literal(7), z.literal(30), z.literal(90)]),
});

export const ticketStatuses = ['new', 'claimed', 'waiting', 'closed'] as const;
export const listTicketsSchema = z.object({
  status: z.enum(['open', ...ticketStatuses]),
  q: z.string().max(80).optional(),
});
export const ticketRefSchema = z.object({ ticketId: z.string().regex(/^t_[a-f0-9]{20}$/) });
export const replyTicketSchema = ticketRefSchema.extend({
  text: z.string().trim().min(1).max(4000),
  /** "Gửi hướng dẫn tải qua Wi-Fi" and other macros (A03). */
  macro: z.enum(['wifiGuide']).nullable(),
  reason,
});
export const closeTicketSchema = ticketRefSchema.extend({ reason });

export const listStorageRequestsSchema = z.object({
  status: z.enum(['open', 'granted', 'declined']),
});
export const decideStorageSchema = z.discriminatedUnion('decision', [
  z.object({
    decision: z.literal('grant'),
    requestId: z.string().regex(/^sr_[a-f0-9]{20}$/),
    grantGb: z.number().int().min(1).max(500),
    reason,
    message: z.string().trim().max(1000),
  }),
  z.object({
    decision: z.literal('decline'),
    requestId: z.string().regex(/^sr_[a-f0-9]{20}$/),
    reason,
    message: z.string().trim().max(1000),
  }),
]);
/** "+5 GB" / "+10 GB" are routine; above 20 GB (or custom) needs a team lead (P-120). */
export const routineGrantGb = [5, 10, 20] as const;

export const listJobsSchema = z.object({ kind: z.enum(['all', 'export', 'deletion']) });
export const rerunJobSchema = z.object({ jobId: z.string().min(3).max(64), reason });

export const setFlagSchema = z.object({
  key: z.enum(flagKeys),
  enabled: z.boolean(),
  scope: z.enum(rolloutScopes),
  percent: z.union([z.literal(0), z.literal(10), z.literal(25), z.literal(50), z.literal(100)]),
  /** A11 "Báo cho gia đình trong app": shown to families while the feature is off. */
  notice: z.string().trim().max(280).nullable(),
  reason,
});

/** A12 categories; v1.0 adds families, staff, reference data and analytics exports (P-139). */
export const auditCategories = [
  'support',
  'storage',
  'data',
  'features',
  'families',
  'staff',
  'reference',
  'analytics',
] as const;
export type AuditCategory = (typeof auditCategories)[number];
export const listAuditSchema = z.object({
  category: z.enum(['all', ...auditCategories]),
  days: z.union([z.literal(1), z.literal(7), z.literal(30), z.literal(90)]),
  q: z.string().max(80).optional(),
});

/** AI budget (A09): monthly VND budget; 80 % alert; at 100 % new suggestions pause. */
export const aiBudgetSchema = z.object({
  monthlyBudgetVnd: z.number().int().nonnegative(),
  month: z.string().regex(/^\d{4}-\d{2}$/),
  spentVnd: z.number().nonnegative(),
});
export type AiBudget = z.infer<typeof aiBudgetSchema>;

// ---------- Nhân sự & phân quyền (A18–A21, P-134, P-135) ----------

/** "ops", "support", … or a role made on the portal ("r_" + 12 hex). */
export const staffRoleIdSchema = z.string().regex(/^(?:[a-z]{2,10}|r_[a-f0-9]{12})$/);
export const staffLevelsSchema = z.record(z.enum(staffFunctions), z.enum(staffLevels));
const staffUid = z.string().min(1).max(128);

/** "Thời hạn quyền": unlimited, 30 days, or until a date (Vietnam calendar date). */
export const staffAccessSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('unlimited') }),
  z.object({ kind: z.literal('days'), days: z.literal(30) }),
  z.object({ kind: z.literal('until'), until: z.string().regex(/^\d{4}-\d{2}-\d{2}$/) }),
]);
export type StaffAccess = z.infer<typeof staffAccessSchema>;

/** Any email domain (owner, 2026-10-11); no 2FA (D-043 kept). Invitations last 7 days. */
export const staffInviteSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(254),
  name: z.string().trim().min(1).max(80),
  roles: z.array(staffRoleIdSchema).min(1).max(5),
  access: staffAccessSchema,
  reason,
});
export const STAFF_INVITE_DAYS = 7;

export const staffMemberUpdateSchema = z.discriminatedUnion('op', [
  z.object({
    op: z.literal('roles'),
    uid: staffUid,
    roles: z.array(staffRoleIdSchema).min(1).max(5),
    reason,
  }),
  z.object({ op: z.literal('access'), uid: staffUid, access: staffAccessSchema, reason }),
  z.object({ op: z.literal('pause'), uid: staffUid, reason }),
  z.object({ op: z.literal('resume'), uid: staffUid, reason }),
  z.object({ op: z.literal('remove'), uid: staffUid, reason }),
  z.object({
    op: z.literal('revokeInvite'),
    inviteId: z.string().regex(/^si_[a-f0-9]{20}$/),
    reason,
  }),
]);

/** A21 "Lưu thay đổi" (and "Tạo vai trò" with `roleId: null`). */
export const staffSaveRoleSchema = z.object({
  roleId: staffRoleIdSchema.nullable(),
  name: z.string().trim().min(2).max(40),
  levels: staffLevelsSchema,
  reason,
});

export const staffMemberStatuses = ['active', 'paused', 'expired', 'removed'] as const;
export type StaffMemberStatus = (typeof staffMemberStatuses)[number];

// ---------- Gia đình (A15–A17, P-136) ----------

/** "F-7Q2K": the anonymous family code (`familyCode()`), never a sequential number. */
export const familyCodeSchema = z.string().regex(/^F-[A-Z2-9]{4}$/);

/** A family is "Hoạt động" with any activity in the last 7 days, otherwise "Ít hoạt động". */
export const FAMILY_ACTIVE_DAYS = 7;

export const listFamiliesSchema = z.object({
  activity: z.enum(['all', 'active', 'low']),
  platform: z.enum(['all', 'ios', 'android', 'both']),
  storage: z.enum(['all', 'over80', 'expanded']),
  /** A family code, or an exact email matched on the server and never echoed back. */
  q: z.string().trim().max(254).optional(),
  /** Paging cursor: the last family id of the previous page. */
  after: z.string().max(64).optional(),
});

export const familyRefSchema = z.object({ code: familyCodeSchema });

/** A17: the current owner confirms within 48 hours; the candidate must be Cùng nuôi of every baby. */
export const STAFF_TRANSFER_HOURS = 48;
const transferId = z.string().regex(/^ft_[a-f0-9]{20}$/);
export const openTransferSchema = z.object({
  code: familyCodeSchema,
  toUid: z.string().min(1).max(128),
  ticket: z
    .string()
    .trim()
    .regex(/^CL-\d{3,6}$/)
    .nullable(),
  reason,
});
export const cancelTransferSchema = z.object({ transferId, reason });
/** The owner's answer in the app (Tôi → Tài khoản & đăng nhập). */
export const answerStaffTransferSchema = z.object({ transferId, accept: z.boolean() });

// ---------- Phân tích (A13 / A14, P-137) ----------

/** How an account arrived: Android Play install referrer from the landing links, or not known. */
export const acquisitionSchema = z.object({
  channel: z.enum(['website', 'store', 'unknown']),
});
export const analyticsRequestSchema = z.object({
  tab: z.enum(['growth', 'features']),
  days: z.union([z.literal(7), z.literal(30), z.literal(90)]),
  platform: z.enum(['all', 'ios', 'android']),
});
