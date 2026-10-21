import { describe, it, expect } from 'vitest';
import {
  campaignDate,
  campaignWindow,
  decideEngagement,
  engagementRefreshSchema,
  engagementPreferencesSchema,
  defaultEngagementPolicy,
  engagementSegments,
  type EngagementDecisionInput,
} from '../src/engagement.js';
const now = Date.parse('2026-10-21T03:00:00Z');
const input: EngagementDecisionInput = {
  now,
  dueAt: now,
  expiresAt: now + 7 * 86400_000,
  scheduled: false,
  enabled: true,
  authorized: true,
  source: 'ready',
  context: 'current',
  consent: true,
  category: true,
  pushAvailable: true,
  paused: false,
  reduced: false,
  dismissed: false,
  sentAt: null,
  snoozedUntil: 0,
  completedAt: 0,
  recent: [],
  zone: 'Asia/Ho_Chi_Minh',
  quiet: { from: '22:00', to: '06:00' },
  spacingUntil: 0,
};
describe('ENG-00 decisions', () => {
  it.each([
    [{}, 'push_eligible', 'reserved'],
    [{ authorized: false }, 'suppress', 'not_authorized'],
    [{ enabled: false, scheduled: true }, 'cancel', 'disabled'],
    [{ source: 'resolved' }, 'suppress', 'source_resolved'],
    [{ dismissed: true }, 'suppress', 'user_choice'],
    [{ expiresAt: now }, 'expire', 'window_closed'],
    [{ source: 'unknown' }, 'delay', 'awaiting_verification'],
    [{ paused: true }, 'suppress', 'fatigue_paused'],
    [{ consent: false }, 'in_app_only', 'channel_unavailable'],
    [{ pushAvailable: false }, 'in_app_only', 'channel_unavailable'],
    [{ context: 'retrospective', expiresAt: now - 1 }, 'in_app_only', 'window_closed'],
    [{ sentAt: now - 1 }, 'suppress', 'duplicate'],
    [{ holdout: true }, 'in_app_only', 'holdout'],
    [{ snoozedUntil: now + 1000 }, 'delay', 'snoozed'],
    [{ digestAt: now + 1000 }, 'group_into_digest', 'digest_member'],
    [{ dueAt: now + 1000 }, 'delay', 'not_due'],
    [{ completedAt: now - 1000 }, 'delay', 'post_completion_quiet'],
    [{ recent: [now - 1000] }, 'delay', 'budget'],
    [{ reduced: true, recent: [now - 2 * 86400_000] }, 'delay', 'budget'],
    [{ spacingUntil: now + 1000 }, 'delay', 'higher_priority'],
  ] as const)('returns a deterministic decision for %j', (patch, decision, reason) => {
    expect(decideEngagement({ ...input, ...patch } as EngagementDecisionInput)).toMatchObject({
      decision,
      reason,
    });
  });
  it('delays across midnight quiet hours and expires rather than catching up', () => {
    const night = Date.parse('2026-10-21T16:00:00Z');
    const r = decideEngagement({ ...input, now: night });
    expect(r.reason).toBe('quiet_hours');
    expect(new Date(r.nextAt!).toISOString()).toBe('2026-10-21T23:00:00.000Z');
    expect(decideEngagement({ ...input, now: night, expiresAt: night + 1000 }).decision).toBe(
      'expire',
    );
  });
  it('does not infer segments from missing history or raise caps after success', () => {
    expect(
      engagementSegments({
        accountDays: 1,
        historyKnown: false,
        firstMemory: false,
        pending: true,
        saveDays: 2,
        videos: 1,
        views: 1,
        fatigue: true,
      }),
    ).toEqual([
      'unknown',
      'pending_photos',
      'active_memory_saver',
      'active_video_creator',
      'family_viewer',
      'fatigue',
    ]);
    expect(defaultEngagementPolicy).toMatchObject({ dailyCap: 1, weeklyCap: 3, approved: false });
    expect(engagementPreferencesSchema.parse({}).consent).toBe(false);
    expect(
      engagementRefreshSchema.safeParse({
        babyId: 'b',
        deviceId: 'd',
        pushAllowed: true,
        facePrint: 'private',
      }).success,
    ).toBe(false);
  });
  it('calculates calendar milestones for late joiners without birth-date onboarding assumptions', () => {
    expect(campaignDate('2026-01-31', 'm1')).toBe('2026-02-28');
    expect(campaignDate('2024-02-29', 'y1')).toBe('2025-02-28');
    expect(campaignDate('2026-01-01', 'd100')).toBe('2026-04-11');
    expect(campaignWindow('2026-01-01', 'm1', 'Asia/Ho_Chi_Minh', new Date(now)).context).toBe(
      'retrospective',
    );
  });
  it.each([
    ['2026-02-01', 'm1', 'current', true],
    ['2026-04-01', 'm1', 'retrospective', true],
    ['2026-07-01', 'm6', 'current', true],
    ['2026-10-01', 'm6', 'retrospective', true],
    ['2027-01-01', 'y1', 'current', true],
    ['2026-10-01', 'y1', 'current', false],
  ] as const)('supports join ages 1/3/6/9/12 months at %s', (date, kind, context, visible) => {
    const w = campaignWindow('2026-01-01', kind, 'Asia/Ho_Chi_Minh', new Date(`${date}T03:00:00Z`));
    expect(w).toMatchObject({ context, visible });
    if (context === 'retrospective') {
      expect(
        decideEngagement({ ...input, context, dueAt: w.dueAt, expiresAt: w.pushExpiresAt })
          .decision,
      ).toBe('in_app_only');
    }
  });
});
