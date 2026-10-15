import type { ExtraRights } from './family.js';
import type { MemberRole } from './baby.js';

/**
 * What a family member may do in Nhịp lớn lên, Premium and Kỷ niệm 2.0, by role (business map
 * §2.1 / §5, D-072 #1–#2). Paid plans never change these: "Premium không đổi vai trò" (ST02).
 * Every check is repeated server-side; the app only uses this to hide what would be refused.
 */
export const familyActions = [
  /** Save a check-in ("Hôm nay con có gì khác?", C01/C02). */
  'rhythm.checkin',
  /** Kept for old callers only: valid days are automatic since D-073 #1, nobody marks "ghi đủ". */
  'rhythm.markDay',
  /** Try / give feedback on a suggestion (AC01, AC02). */
  'rhythm.feedback',
  /** Receive need-based suggestions and the next action after a check-in (H02, PS01). */
  'rhythm.suggestions',
  /** Due date and reference reminders (NL02a–c). Episodes (NL07b) follow `rhythm.checkin`. */
  'rhythm.setup',
  /** Read saved check-ins, rhythm facts and summaries (`history.read`). */
  'history.read',
  /** Health guidance (HL01): everyone, in every plan state. */
  'health.read',
  /** Generate an AI handover / explanation (SU01). Caregivers read it, never generate (D-072 #2). */
  'ai.generate',
  /** Confirm a milestone, create a card or video (MS01, MO01–MO04). */
  'moments.create',
  /** One's own interests, digest time, quiet hours, AI consent (EN01, EN02). */
  'preferences.own',
  /** Buy, restore and manage the household plan (PR01–PR03): the family owner only (D-072 #1). */
  'billing.manage',
  /** Household country of residence and time zone (D-072 #3). */
  'family.settings',
] as const;
export type FamilyAction = (typeof familyActions)[number];

/** The parts of a `babies/{b}/members/{uid}` document the checks need. */
export interface MemberGrant {
  role: MemberRole;
  isOwner?: boolean;
  extraRights?: Partial<ExtraRights> | null;
}

export function familyCan(member: MemberGrant, action: FamilyAction): boolean {
  const { role } = member;
  switch (action) {
    case 'health.read':
    case 'preferences.own':
      return true;
    case 'rhythm.checkin':
    case 'rhythm.markDay':
    case 'rhythm.feedback':
    case 'rhythm.suggestions':
      return role === 'coParent' || role === 'caregiver';
    case 'history.read':
      // A relative reads care only with "Chăm sóc hằng ngày" (D-018).
      return (
        role === 'coParent' ||
        role === 'caregiver' ||
        (role === 'relative' && member.extraRights?.viewDailyCare === true)
      );
    case 'rhythm.setup':
    case 'ai.generate':
    case 'moments.create':
      return role === 'coParent';
    case 'billing.manage':
    case 'family.settings':
      return role === 'coParent' && member.isOwner === true;
  }
}
