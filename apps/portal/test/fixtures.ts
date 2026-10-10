import { defaultFlags, type Flags } from '@child-life/contracts';

export {
  accountDeletionSteps,
  auditCategories,
  babyDeletionSteps,
  flagKeys,
  memberRoles,
  staffRoles,
  supportCategories,
  type StaffRole,
} from '@child-life/contracts';

/** The shipped set (mirrors `launchedFlags` in functions/src/staff.ts). */
export const launchedFlagDefaults: Flags = {
  ...defaultFlags,
  media_upload: { enabled: true, scope: 'all', percent: 0, notice: null },
  video_upload: { enabled: true, scope: 'all', percent: 0, notice: null },
  story_share_link: { enabled: true, scope: 'all', percent: 0, notice: null },
  invites: { enabled: true, scope: 'all', percent: 0, notice: null },
};
