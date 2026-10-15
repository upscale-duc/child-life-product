import { randomBytes } from 'node:crypto';
import {
  milestoneSeedSchema,
  referenceMilestoneContentSchema,
  referenceMilestoneDraftSchema,
  referenceMilestoneIdSchema,
  referenceMilestoneSchema,
} from '@child-life/contracts';
import type { ContentKindAdapter } from './content-library.js';

/**
 * Reference Mốc phát triển (B07 / B08, D-076 #6) on the editorial workflow. The schema belongs to
 * the milestones slice (`packages/contracts/src/milestones.ts`); this adapter only plugs it into
 * contentDrafts → contentMilestones. Its seed is the milestones slice's
 * `content/milestones/milestones.seed.json`, sent by the portal ("Nhập bản nháp mẫu").
 */
export const milestoneAdapter: ContentKindAdapter = {
  newId: () => `m_${randomBytes(5).toString('hex')}`,
  isId: (id) => referenceMilestoneIdSchema.safeParse(id).success,
  draft: referenceMilestoneDraftSchema,
  strict: referenceMilestoneContentSchema,
  published: (id, data, meta) => referenceMilestoneSchema.parse({ id, ...data, ...meta }),
  row: (d) => ({
    group: d.group,
    order: d.order,
    ageRange: d.ageRange,
    hasIllustration: !!d.illustration,
    sources: Array.isArray(d.sources) ? d.sources.length : 0,
  }),
  seed: (payload) => {
    if (payload === undefined) return [];
    const parsed = milestoneSeedSchema.safeParse(payload);
    if (!parsed.success) return null;
    return parsed.data.milestones.map(({ id, ...data }) => ({
      id,
      reviewerLabel: 'Nhóm chuyên môn · Phát triển',
      data: data as Record<string, unknown>,
    }));
  },
};
