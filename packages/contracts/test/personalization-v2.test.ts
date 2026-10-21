import { describe, expect, it } from 'vitest';
import {
  activeAt,
  nextLocalDay,
  nextLocalWeek,
  nextWorkState,
  personalizationMutationSchema,
  recommendationCurrent,
  responseSuppresses,
  routinePatterns,
} from '../src/personalization-v2.js';
import {
  activitySchema,
  recommend,
  feedbackMemory,
  type Activity,
} from '../src/personalization.js';
import toddlerDrafts from '../../../content/rhythm/toddler-v2.draft.json' with { type: 'json' };

const now = new Date('2026-10-20T12:00:00Z');
const zone = 'Asia/Ho_Chi_Minh';
describe('P-172 expiring explicit inputs', () => {
  it('expires at the baby-local midnight and Monday, including DST', () => {
    expect(nextLocalDay(zone, now)).toBe('2026-10-20T17:00:00.000Z');
    expect(nextLocalWeek(zone, now)).toBe('2026-10-25T17:00:00.000Z');
    expect(nextLocalDay('America/New_York', new Date('2026-11-01T04:30:00Z'))).toBe(
      '2026-11-02T05:00:00.000Z',
    );
  });
  it('saves and silence do not imply usefulness or suppression; snooze expires exactly', () => {
    expect(responseSuppresses({ value: 'save', at: now.toISOString(), until: null }, now)).toBe(
      false,
    );
    expect(responseSuppresses(undefined, now)).toBe(false);
    expect(activeAt(now.toISOString(), now)).toBe(false);
    expect(
      responseSuppresses({ value: 'snooze', at: now.toISOString(), until: now.toISOString() }, now),
    ).toBe(false);
  });
  it('rejects injected paths and unknown fields rather than stripping authority hints', () => {
    expect(
      personalizationMutationSchema.safeParse({
        babyId: '../b',
        action: { kind: 'context', value: 'busy' },
      }).success,
    ).toBe(false);
    expect(
      personalizationMutationSchema.safeParse({
        babyId: 'b',
        action: { kind: 'context', value: 'busy', authorUid: 'other' },
      }).success,
    ).toBe(false);
    expect(
      personalizationMutationSchema.safeParse({ babyId: 'b', action: { kind: 'note', id: 'a/b' } })
        .success,
    ).toBe(false);
  });
  it('offers only choices that change what is shown (audit 2026-10-21 P2 #7)', () => {
    const ok = (action: unknown) =>
      personalizationMutationSchema.safeParse({ babyId: 'b', action }).success;
    expect(ok({ kind: 'focus', value: 'play' })).toBe(true);
    expect(ok({ kind: 'focus', value: null })).toBe(true);
    expect(ok({ kind: 'focus', value: 'handover' })).toBe(false);
    expect(ok({ kind: 'focus', value: 'routine' })).toBe(false);
    expect(ok({ kind: 'context', value: 'few_minutes' })).toBe(true);
    expect(ok({ kind: 'context', value: 'other_carer' })).toBe(false);
  });
});
describe('P-172 stored invitation eligibility', () => {
  const activity = {
    version: 1,
    status: 'published',
    locales: ['vi'],
    ageDays: { from: 0, to: 90 },
    regions: ['VN'],
  } as Activity;
  const rec = { generatedAt: now.toISOString(), contentVersion: 1, state: 'suggested' as const };
  const input = { now, zone, ageDays: 60, locale: 'vi', country: 'VN' };
  it('revalidates time, version, country, age, publication, locale and state', () => {
    expect(recommendationCurrent(rec, activity, input)).toBe(true);
    expect(
      recommendationCurrent({ ...rec, generatedAt: '2026-10-19T12:00:00Z' }, activity, input),
    ).toBe(false);
    expect(
      recommendationCurrent({ ...rec, generatedAt: '2026-10-20T12:01:00Z' }, activity, input),
    ).toBe(false);
    expect(recommendationCurrent(rec, { ...activity, version: 2 }, input)).toBe(false);
    expect(recommendationCurrent(rec, { ...activity, status: 'retired' }, input)).toBe(false);
    expect(recommendationCurrent(rec, activity, { ...input, ageDays: null })).toBe(false);
    expect(recommendationCurrent(rec, activity, { ...input, ageDays: 91 })).toBe(false);
    expect(recommendationCurrent(rec, activity, { ...input, country: 'US' })).toBe(false);
    expect(recommendationCurrent(rec, activity, { ...input, locale: 'en' })).toBe(false);
    expect(recommendationCurrent({ ...rec, state: 'done' }, activity, input)).toBe(false);
    expect(recommendationCurrent({ ...rec, expiresAt: now.toISOString() }, activity, input)).toBe(
      false,
    );
  });
});
describe('P-172 care work state', () => {
  it('prevents another caregiver claiming/completing and permits co-parent release', () => {
    const first = nextWorkState(
      { state: 'unclaimed', actorUid: null, revision: 0 },
      'accept',
      'a',
      false,
    );
    expect(() => nextWorkState(first, 'accept', 'b', false)).toThrow('work-conflict');
    expect(() => nextWorkState(first, 'complete', 'b', false)).toThrow('work-conflict');
    expect(nextWorkState(first, 'release', 'parent', true)).toEqual({
      state: 'unclaimed',
      actorUid: null,
      revision: 2,
    });
  });
  it('replaying the same acceptance or completion is idempotent', () => {
    const first = nextWorkState(
      { state: 'unclaimed', actorUid: null, revision: 0 },
      'accept',
      'a',
      false,
    );
    expect(nextWorkState(first, 'accept', 'a', false)).toBe(first);
    const done = nextWorkState(first, 'complete', 'a', false);
    expect(nextWorkState(done, 'complete', 'a', false)).toBe(done);
  });
});
describe('P-172 diary ranges are observations, not daily totals', () => {
  const records = Array.from({ length: 3 }, (_, day) =>
    [8, 10, 12].map((hour) => ({
      id: `${day}-${hour}`,
      type: 'bottle',
      at: `2026-10-${18 + day}T${String(hour - 7).padStart(2, '0')}:00:00Z`,
      end: null,
    })),
  ).flat();
  it('needs enough distinct days and recent, consistent samples', () => {
    expect(routinePatterns(records, now, zone)).toEqual([
      {
        kind: 'feed_interval',
        lowMinutes: 120,
        highMinutes: 120,
        samples: 6,
        days: 3,
        asOf: '2026-10-20T05:00:00Z',
      },
    ]);
    expect(routinePatterns(records.slice(0, 3), now, zone)).toEqual([]);
    expect(routinePatterns(records, new Date('2026-10-25T12:00:00Z'), zone)).toEqual([]);
    expect(
      routinePatterns(
        [...records, ...records.map((r) => ({ ...r, id: `copy-${r.id}` }))],
        now,
        zone,
      )[0]?.samples,
    ).toBe(6);
  });
  it('does not treat an open, overlapping or future sleep as a qualifying duration', () => {
    const sleeps = records.map((r) => ({
      ...r,
      type: 'sleep',
      end: new Date(Date.parse(r.at) + 60 * 60_000).toISOString(),
    }));
    expect(routinePatterns(sleeps, now, zone)[0]?.kind).toBe('day_sleep');
    expect(
      routinePatterns(
        sleeps.map((r) => ({ ...r, end: null })),
        now,
        zone,
      ),
    ).toEqual([]);
    const overlapping = sleeps.map((r) => ({
      ...r,
      id: `over-${r.id}`,
      at: new Date(Date.parse(r.at) + 5 * 60_000).toISOString(),
    }));
    expect(routinePatterns([...sleeps, ...overlapping], now, zone)).toEqual([]);
  });
});

describe('P-172 toddler editorial pack', () => {
  it('contains 24 bilingual source-linked short drafts and cannot be recommended before publication', () => {
    const activities = toddlerDrafts.map((a) => activitySchema.parse(a));
    expect(new Set(activities.map((a) => a.id)).size).toBe(24);
    for (const a of activities) {
      expect(a.status).toBe('draft');
      expect(a.review).toBeNull();
      expect(a.ageDays).toEqual({ from: 365, to: 1095 });
      expect(a.durationMin).toBeLessThanOrEqual(5);
      expect(a.sources.length).toBeGreaterThan(0);
    }
    expect(
      recommend({
        locale: 'vi',
        today: '2026-10-20',
        ageDays: 500,
        need: null,
        interests: [],
        fewer: [],
        country: 'VN',
        healthFlag: false,
        memory: feedbackMemory([], 3),
        activities,
      }),
    ).toEqual({ kind: 'none' });
  });
});
