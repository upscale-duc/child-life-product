import { describe, expect, it } from 'vitest';
import {
  interestsForGoals,
  ageBandFor,
  analyticsObservationSchema,
  ageInMonths,
  applyBand,
  bandDefaults,
  defaultExperience,
  experienceSchema,
  goalOrder,
  rankToday,
  stagePromptDue,
  widgetIds,
  widgetRegistry,
  type Experience,
  type WidgetId,
} from '../src/index.js';

const all = widgetIds;
const visibleIds = (exp: Experience, available: readonly WidgetId[] = all) =>
  rankToday(exp, available)
    .filter((w) => w.visible)
    .map((w) => w.id);

describe('age (AX00 rule 7)', () => {
  it('counts whole calendar months, end-of-month birthdays included', () => {
    expect(ageInMonths('2026-08-17', '2026-10-23')).toBe(2); // AX01 "2 tháng 6 ngày"
    expect(ageInMonths('2022-03-12', '2026-10-24')).toBe(55); // AX02 "4 tuổi 7 tháng"
    expect(ageInMonths('2026-01-31', '2026-02-28')).toBe(1);
    expect(ageInMonths('2026-01-31', '2026-02-27')).toBe(0);
    expect(ageInMonths('2026-10-24', '2026-10-24')).toBe(0);
  });

  it('bands are 0–1, 1–3, 3–6 and 6+ (open-ended, Q-094)', () => {
    expect([0, 11, 12, 35, 36, 71, 72, 200].map(ageBandFor)).toEqual([
      'b0_1',
      'b0_1',
      'b1_3',
      'b1_3',
      'b3_6',
      'b3_6',
      'b6_12',
      'b6_12',
    ]);
  });
});

describe('goals (AX03 / AX04)', () => {
  it('lists the band presets first', () => {
    expect(goalOrder('b0_1').slice(0, 2)).toEqual(['track_care', 'memories']);
    expect(goalOrder('b3_6')).toEqual([
      'memories',
      'spending',
      'family',
      'track_care',
      'growth_vaccines',
      'reminders',
    ]);
  });
});

describe('rankToday', () => {
  it('every widget is registered and every band default is a widget', () => {
    expect(widgetRegistry.map((w) => w.id).sort()).toEqual([...widgetIds].sort());
    for (const list of Object.values(bandDefaults)) {
      expect(list.every((id) => widgetIds.includes(id))).toBe(true);
    }
  });

  it('with the preset goals, Hôm nay is the AX00 default for each band (AX10–AX13)', () => {
    const core = (band: Parameters<typeof defaultExperience>[0]) =>
      visibleIds(defaultExperience(band), [
        'tiles',
        'reminders',
        'recent_memories',
        'growth',
        'moment_today',
        'create_from_memories',
        'spending',
        'family_view',
        'vaccine',
        'quickActions',
      ]);
    expect(core('b0_1')).toEqual(['tiles', 'reminders', 'recent_memories', 'growth']);
    expect(core('b1_3')).toEqual(['recent_memories', 'tiles', 'reminders', 'growth']);
    expect(core('b3_6')).toEqual([
      'moment_today',
      'create_from_memories',
      'spending',
      'reminders',
      'family_view',
    ]);
    expect(core('b6_12')).toEqual(['recent_memories', 'reminders', 'spending', 'growth']);
  });

  it('AX14: for Na the quick log and growth are hidden by default, listed under "Đã ẩn"', () => {
    const ranked = rankToday(defaultExperience('b3_6'), ['tiles', 'growth', 'reminders']);
    expect(ranked.find((w) => w.id === 'tiles')).toMatchObject({ visible: false });
    expect(ranked.find((w) => w.id === 'growth')).toMatchObject({ visible: false });
    expect(ranked.find((w) => w.id === 'reminders')).toMatchObject({
      visible: true,
      reason: { kind: 'age' },
    });
  });

  it('a goal the person adds goes up and shows; a preset goal they remove goes down', () => {
    const na: Experience = {
      ...defaultExperience('b3_6'),
      goals: [...defaultExperience('b3_6').goals, 'growth_vaccines'],
    };
    expect(visibleIds(na, ['moment_today', 'growth', 'reminders'])).toEqual([
      'growth',
      'moment_today',
      'reminders',
    ]);
    const teddy: Experience = { ...defaultExperience('b0_1'), goals: ['memories'] };
    const order = visibleIds(teddy, ['tiles', 'reminders', 'recent_memories']);
    expect(order[order.length - 1]).toBe('tiles'); // still shown: removing a goal never hides
  });

  it('ticked goals all count: Cam, 17 months, keeps Kỷ niệm first and Tăng trưởng up (owner 2026-10-24)', () => {
    const cam: Experience = {
      ...defaultExperience('b1_3'),
      goalsSource: 'chosen',
      goals: ['memories', 'growth_vaccines', 'family', 'spending', 'reminders'],
    };
    const ids = visibleIds(cam, [
      'recent_memories',
      'tiles',
      'reminders',
      'growth',
      'spending',
      'family_view',
    ]);
    expect(ids[0]).toBe('recent_memories');
    expect(ids.indexOf('growth')).toBeLessThan(ids.indexOf('tiles'));
  });

  it('AX06: Na with the presets ticked → Cả nhà before Nhắc nhở', () => {
    const na: Experience = { ...defaultExperience('b3_6'), goalsSource: 'chosen' };
    expect(
      visibleIds(na, [
        'moment_today',
        'create_from_memories',
        'spending',
        'reminders',
        'family_view',
      ]),
    ).toEqual(['moment_today', 'create_from_memories', 'spending', 'family_view', 'reminders']);
  });

  it('only available widgets are listed (AX00 rule 4: released features only)', () => {
    expect(rankToday(defaultExperience('b0_1'), ['reminders']).map((w) => w.id)).toEqual([
      'reminders',
    ]);
  });

  it('pinned stays first and never moves; hidden never comes back by itself', () => {
    const exp: Experience = {
      ...defaultExperience('b3_6'),
      pinned: ['reminders'],
      hidden: ['spending'],
    };
    const ranked = rankToday(exp, all, { usage: { spending: 1, moment_today: 1 } });
    expect(ranked[0]).toMatchObject({ id: 'reminders', pinned: true, reason: { kind: 'pinned' } });
    expect(ranked.find((w) => w.id === 'spending')!.visible).toBe(false);
  });

  it('usage and recent activity reorder a ranked Today', () => {
    const ranked = visibleIds(defaultExperience('b6_12'), ['recent_memories', 'growth']);
    expect(ranked).toEqual(['recent_memories', 'growth']);
    const used = rankToday(defaultExperience('b6_12'), ['recent_memories', 'growth'], {
      usage: { growth: 1 },
      recent: new Set<WidgetId>(['growth']),
    }).map((w) => w.id);
    expect(used).toEqual(['growth', 'recent_memories']);
  });

  it('a manual order is kept against usage; new widgets follow it (P-176)', () => {
    const exp: Experience = { ...defaultExperience('b3_6'), order: ['reminders', 'moment_today'] };
    const ids = rankToday(exp, ['reminders', 'moment_today', 'spending'], {
      usage: { moment_today: 1 },
    }).map((w) => w.id);
    expect(ids).toEqual(['reminders', 'moment_today', 'spending']);
  });
});

describe('stage transition (AX33)', () => {
  it('is offered once per milestone and only when the band is newer than the applied one', () => {
    const teddy = defaultExperience('b0_1');
    expect(stagePromptDue(teddy, 11)).toBeNull();
    expect(stagePromptDue(teddy, 12)).toBe(12);
    expect(stagePromptDue({ ...teddy, stagePrompts: { m12: 'kept' } }, 13)).toBeNull();
    expect(stagePromptDue({ ...teddy, stagePrompts: { m12: 'kept' } }, 36)).toBe(36);
    // Added at 4 years: already on the 3–6 defaults, nothing to suggest.
    expect(stagePromptDue(defaultExperience('b3_6'), 55)).toBeNull();
  });

  it('"Áp dụng" keeps pins and hides; "Khôi phục" clears hides; a birthday alone changes nothing', () => {
    const exp: Experience = {
      ...defaultExperience('b0_1'),
      pinned: ['growth'],
      hidden: ['tiles'],
      order: ['reminders'],
    };
    expect(applyBand(exp, 'b1_3')).toMatchObject({
      bandApplied: 'b1_3',
      pinned: ['growth'],
      hidden: ['tiles'],
      order: [],
    });
    expect(applyBand(exp, 'b1_3', true).hidden).toEqual([]);
    // rankToday only reads bandApplied, never the current age.
    expect(rankToday(exp, ['tiles']).find((w) => w.id === 'tiles')!.visible).toBe(false);
  });
});

describe('experience document (users/{uid}/experience/{babyId})', () => {
  it('accepts the defaults and rejects duplicates or unknown ids', () => {
    expect(experienceSchema.parse(defaultExperience('b1_3'))).toBeTruthy();
    const bad = { ...defaultExperience('b1_3'), pinned: ['tiles', 'tiles'] };
    expect(experienceSchema.safeParse(bad).success).toBe(false);
    const unknown = { ...defaultExperience('b1_3'), hidden: ['learning'] };
    expect(experienceSchema.safeParse(unknown).success).toBe(false);
    const extra = { ...defaultExperience('b1_3'), stagePrompts: { m144: 'kept' } };
    expect(experienceSchema.safeParse(extra).success).toBe(false);
  });
});

describe('adaptive analytics events (MET-01, P-175)', () => {
  const base = {
    schemaVersion: 1,
    receiptId: '00000000-0000-4000-8000-000000000001',
    ownerUid: 'u1',
    occurredAt: '2026-10-24T08:00:00.000Z',
    babyId: 'b1',
    platform: 'ios',
    locale: 'vi',
  } as const;

  it('needs one closed detail; older events refuse it', () => {
    expect(
      analyticsObservationSchema.safeParse({
        ...base,
        event: 'adaptive_widget_opened',
        detail: 'moment_today',
      }).success,
    ).toBe(true);
    expect(
      analyticsObservationSchema.safeParse({ ...base, event: 'adaptive_widget_opened' }).success,
    ).toBe(false);
    expect(
      analyticsObservationSchema.safeParse({
        ...base,
        event: 'adaptive_interest',
        detail: 'học tập',
      }).success,
    ).toBe(false);
    expect(
      analyticsObservationSchema.safeParse({
        ...base,
        event: 'family_context_viewed',
        detail: 'chosen',
      }).success,
    ).toBe(false);
  });
});

describe('D-143: goals replace EN01 interests', () => {
  it('maps each goal to its content topics, in interests order, without duplicates', () => {
    expect(interestsForGoals(['track_care', 'memories'])).toEqual([
      'sleep',
      'feeding',
      'nutrition',
      'moments',
    ]);
    expect(interestsForGoals(['memories', 'growth_vaccines', 'growth_vaccines'])).toEqual([
      'milestones',
      'vaccines',
      'moments',
    ]);
    expect(interestsForGoals(['spending', 'family', 'reminders'])).toEqual([]);
    expect(interestsForGoals([])).toEqual([]);
  });
});
