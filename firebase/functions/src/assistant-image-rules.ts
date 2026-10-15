import {
  assistantModuleProblems,
  draftReviewFields,
  type DraftPayload,
  type DraftProblem,
  type MemberGrant,
} from '@child-life/contracts';
import { sha } from './assistant-common.js';

/**
 * Child Life Assistant, slice A3 (photos → Chi tiêu, notes → one-off reminders): the pure rules
 * shared by the prepare tools, `patchDraft` and the writers. A leaf module (contracts and ids
 * only) so the registry in `assistant-tools.ts` can use it without an import cycle.
 */

/** Rules `canRecordSpending`: Cùng nuôi, or anyone with the 8l right "Ghi khoản đã chi". */
export function canRecordSpending(m: MemberGrant): boolean {
  return (
    m.role === 'coParent' ||
    (m.extraRights as Record<string, unknown> | null | undefined)?.recordSpending === true
  );
}

/** Rules `reminders` create: Cùng nuôi only (D-030, D-031); caregivers view, relatives never. */
export function canCreateReminders(m: MemberGrant): boolean {
  return m.role === 'coParent';
}

const hex32 = (s: string) => sha(s).slice(0, 32);
/** One expense per draft (`x_` + 32 hex, Rules `^x_[a-f0-9]{32}$`). */
export const expenseIdForDraft = (draftId: string) => `x_${hex32(`expense|${draftId}`)}`;
/** One reminder per draft (`rm_` + 32 hex, Rules `^rm_[a-f0-9]{32}$`). */
export const reminderIdForDraft = (draftId: string) => `rm_${hex32(`reminder|${draftId}`)}`;
/** The receipt copy kept with an expense (Rules: `babies/{b}/expenses/<8–64>.jpg`). */
export const receiptPathFor = (babyId: string, expenseId: string) =>
  `babies/${babyId}/expenses/${expenseId}.jpg`;

/**
 * Fields the person must fill (`missing`) or look at (`uncertain`) on an expense or reminder
 * draft, from the form's problems plus the module's (`assistantModuleProblems`): a missing total,
 * date or currency, a currency Chi tiêu cannot store, a reminder without a date or a time, a
 * title too long. Used by `reviewFields` for these two kinds.
 */
export function imageReviewFields(
  p: DraftPayload,
  problems: readonly DraftProblem[],
): { missing: string[]; uncertain: string[] } {
  // Lumi 2026-10-16: one mapping for every kind (contracts `draftReviewFields`).
  return draftReviewFields(p, problems);
}

/** Every problem the app should show for a draft: the form's and the module's, once each. */
export function allDraftProblems(
  formProblems: readonly DraftProblem[],
  p: DraftPayload,
): DraftProblem[] {
  return [...new Set([...formProblems, ...assistantModuleProblems(p)])];
}
