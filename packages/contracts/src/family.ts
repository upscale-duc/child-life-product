import { z } from 'zod';
import {
  babyIdSchema,
  memberRoles,
  relationCustomMaxLength,
  displayNameMaxLength,
} from './baby.js';

/**
 * Family, invites and memberships (Slice S3; Figma 14a–14f, 15–17, 16a–16d; business map §7.2,
 * R-030…R-039, P-020, P-021, P-005, P-007; owner decisions D-017…D-020).
 */

/** Every relation label: 10a / 16a self chips (Mẹ … Khác…) plus "Bạn bè" from 14b. */
export const relations = [
  'mother',
  'father',
  'grandmother',
  'grandfather',
  'nanny',
  'relative',
  'friend',
  'other',
] as const;
export type Relation = (typeof relations)[number];

/** 14b "Người được mời là": Ba, Bà, Ông, Bảo mẫu, Họ hàng, Bạn bè, Khác… ("Mẹ" is absent). */
export const inviteRelations = relations.filter((r) => r !== 'mother') as Exclude<
  Relation,
  'mother'
>[];

/** Invites last 7 days ("Hết hạn sau 7 ngày", R-032). */
export const inviteTtlDays = 7;

/** P-021: wrong codes per caller / IP before a lockout, and the window and lockout length. */
export const inviteLookupMaxFailures = 10;
export const inviteLookupWindowMinutes = 15;
export const inviteLookupLockMinutes = 15;

/** "Gửi lại": at most this many emails per invite, at least a minute apart. */
export const inviteMaxEmails = 5;
export const inviteEmailMinGapSeconds = 60;

export const inviteCodeSchema = z.string().regex(/^\d{6}$/);
export const inviteTokenSchema = z.string().regex(/^[A-Za-z0-9_-]{32}$/);
export const inviteIdSchema = z.string().regex(/^i_[a-f0-9]{20}$/);

/** 14b2: relatives always see shared memories and can love; two optional view rights. */
export const extraRightsSchema = z.object({
  /** "Thông tin bé · Ngày sinh, cân nặng". */
  viewBabyInfo: z.boolean(),
  /** "Chăm sóc hằng ngày · Bú, ngủ, tã · chỉ xem" (read-only Today, D-018). */
  viewDailyCare: z.boolean(),
  /** 8l "Ghi khoản đã chi": record expenses, see only one's own (D-055). Caregivers too. */
  recordSpending: z.boolean().optional(),
  /** 8l "Xem toàn bộ chi tiêu": every expense, totals, statistics, budget (D-055). */
  viewSpending: z.boolean().optional(),
});
export type ExtraRights = z.infer<typeof extraRightsSchema>;

/** Q-021 → D-019: both off by default (least privilege). */
export const defaultExtraRights: ExtraRights = { viewBabyInfo: false, viewDailyCare: false };

const relationFields = {
  relation: z.enum(relations),
  relationCustom: z.string().trim().min(1).max(relationCustomMaxLength).optional(),
};

const customOnlyForOther = (v: { relation: Relation; relationCustom?: string | undefined }) =>
  (v.relation === 'other') === (v.relationCustom !== undefined);

export const createInviteRequestSchema = z
  .object({
    requestId: z.uuid(),
    babyId: babyIdSchema,
    relation: z.enum(inviteRelations as [Relation, ...Relation[]]),
    relationCustom: relationFields.relationCustom,
    role: z.enum(memberRoles),
    extraRights: extraRightsSchema.optional(),
  })
  .refine(customOnlyForOther, {
    message: 'relationCustom only for "other"',
    path: ['relationCustom'],
  })
  .refine((v) => v.role === 'relative' || v.extraRights === undefined, {
    message: 'extraRights only for relatives',
    path: ['extraRights'],
  });
export type CreateInviteRequest = z.infer<typeof createInviteRequestSchema>;

/** What the inviter needs to show 14c: code, link token, expiry. */
export const inviteTicketSchema = z.object({
  inviteId: inviteIdSchema,
  code: inviteCodeSchema,
  token: inviteTokenSchema,
  expiresAt: z.iso.datetime(),
});
export type InviteTicket = z.infer<typeof inviteTicketSchema>;

export const inviteRefSchema = z.object({ inviteId: inviteIdSchema });

export const sendInviteEmailRequestSchema = z.object({
  inviteId: inviteIdSchema,
  email: z.email().max(254),
  locale: z.enum(['vi', 'en']),
});

/** By 6-digit code (15) or link token (/i/{token}, QR). */
export const inviteLookupSchema = z.union([
  z.object({ code: inviteCodeSchema }),
  z.object({ token: inviteTokenSchema }),
]);
export type InviteLookup = z.infer<typeof inviteLookupSchema>;

const validInviteFields = {
  babyNickname: z.string(),
  inviterName: z.string(),
  inviterRelation: z.enum(relations),
  inviterRelationCustom: z.string().nullable(),
  role: z.enum(memberRoles),
  relation: z.enum(relations),
  relationCustom: z.string().nullable(),
  extraRights: extraRightsSchema.nullable(),
  expiresAt: z.iso.datetime(),
};

export const invitePreviewSchema = z.discriminatedUnion('status', [
  z.object({
    status: z.literal('valid'),
    ...validInviteFields,
    /** The caller already belongs to this baby (G-036). */
    alreadyMember: z.boolean(),
  }),
  z.object({ status: z.enum(['expired', 'revoked', 'used', 'not-found']) }),
  z.object({ status: z.literal('locked'), retryAfterSeconds: z.number().int().positive() }),
]);
export type InvitePreview = z.infer<typeof invitePreviewSchema>;

/**
 * Invites mailed to the caller's own verified email (owner, 2026-10-11): shown to a signed-in
 * user to accept or decline without typing the code. Only live invites for babies they are not
 * already in.
 */
export const myInviteSchema = z.object({ inviteId: inviteIdSchema, ...validInviteFields });
export type MyInvite = z.infer<typeof myInviteSchema>;
export const myInvitesResponseSchema = z.object({ invites: z.array(myInviteSchema) });
export type MyInvitesResponse = z.infer<typeof myInvitesResponseSchema>;

/** "Từ chối": only the invite's own recipient (by verified email). */
export const declineInviteRequestSchema = inviteRefSchema;

export const acceptInviteRequestSchema = z.intersection(
  // By code or link token (anyone holding it), or by id for an invite mailed to the caller.
  z.union([inviteLookupSchema, inviteRefSchema]),
  z
    .object({
      displayName: z.string().trim().min(1).max(displayNameMaxLength),
      ...relationFields,
    })
    .refine(customOnlyForOther, {
      message: 'relationCustom only for "other"',
      path: ['relationCustom'],
    }),
);
export type AcceptInviteRequest = z.infer<typeof acceptInviteRequestSchema>;

export const memberUidSchema = z.string().min(1).max(128);

/** 14f: role, access end date ("Thời hạn"), relation; changes apply immediately. */
export const updateMemberRequestSchema = z
  .object({
    babyId: babyIdSchema,
    uid: memberUidSchema,
    role: z.enum(memberRoles).optional(),
    relation: z.enum(relations).optional(),
    relationCustom: z.string().trim().min(1).max(relationCustomMaxLength).nullable().optional(),
    extraRights: extraRightsSchema.optional(),
    /** Last day of access (baby's calendar), or null to remove the limit. */
    accessUntil: z.iso.date().nullable().optional(),
  })
  .refine(
    (v) =>
      v.role !== undefined ||
      v.relation !== undefined ||
      v.extraRights !== undefined ||
      v.accessUntil !== undefined,
    'Nothing to change',
  );
export type UpdateMemberRequest = z.infer<typeof updateMemberRequestSchema>;

export const removeMemberRequestSchema = z.object({ babyId: babyIdSchema, uid: memberUidSchema });

/** P-007: an anonymous ("Vào ngay") identity saved into an account that already exists. */
export const claimAnonymousRequestSchema = z.object({
  anonymousIdToken: z.string().min(20).max(4096),
});
