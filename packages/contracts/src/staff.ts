import { z } from 'zod';
import { flagKeys, rolloutScopes } from './config.js';

/**
 * Staff portal "Child Life · Vận hành" (Slice S15; Figma A01–A12; business map §5.1, §7.15,
 * R-180…R-190, D-007, D-043, P-120…P-125). Staff never see photos, videos, captions or care
 * records; they see masked emails, anonymous family codes, counts and bytes. Every mutation needs
 * a reason and lands in the append-only staff audit log (A12).
 */

/** Custom-claim roles: Vận hành, Hỗ trợ, Kỹ thuật, trưởng nhóm (P-121). */
export const staffRoles = ['ops', 'support', 'eng', 'lead'] as const;
export type StaffRole = (typeof staffRoles)[number];

export const staffActions = [
  'view',
  'support.claim',
  'support.reply',
  'support.close',
  'storage.decide',
  'storage.large',
  'jobs.rerun',
  'flags.toggle',
  'flags.rollout',
  'audit.export',
] as const;
export type StaffAction = (typeof staffActions)[number];

/** The matrix (§5.1): who may do what; team leads may do everything. */
export const staffMatrix: Record<StaffAction, readonly StaffRole[]> = {
  view: ['ops', 'support', 'eng', 'lead'],
  'support.claim': ['support', 'ops', 'lead'],
  'support.reply': ['support', 'ops', 'lead'],
  'support.close': ['support', 'ops', 'lead'],
  'storage.decide': ['ops', 'lead'],
  // P-120: more than 20 GB, or a custom amount, needs the trưởng nhóm role.
  'storage.large': ['lead'],
  'jobs.rerun': ['eng', 'ops', 'lead'],
  'flags.toggle': ['eng', 'lead'],
  'flags.rollout': ['ops', 'eng', 'lead'],
  'audit.export': ['ops', 'support', 'eng', 'lead'],
};

export function staffCan(roles: readonly string[], action: StaffAction): boolean {
  return roles.some((r) => (staffMatrix[action] as readonly string[]).includes(r));
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

export const auditCategories = ['support', 'storage', 'data', 'features'] as const;
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
