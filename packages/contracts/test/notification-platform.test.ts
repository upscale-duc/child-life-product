import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import {
  canTransition,
  catalogConsistent,
  destinationChain,
  destinationFor,
  destinationParams,
  inboxGroupOf,
  localizedTemplateCopySchema,
  notificationDestinationIds,
  notificationDestinations,
  notificationDeliveryStates,
  notificationKinds,
  notificationOpsConfigSchema,
  notificationTemplateIds,
  notificationTemplates,
  notificationTypes,
  recordNotificationOpenSchema,
  renderTemplate,
  retryDelayMs,
  staffNotificationTimelineSchema,
  staffTemplateActionSchema,
  validateTemplateCopy,
  deliveryIsTerminal,
} from '../src/index.js';

describe('catalog', () => {
  it('covers every notification kind and agrees with EN07 switches and quiet hours', () => {
    expect(Object.keys(notificationTypes).sort()).toEqual([...notificationKinds].sort());
    expect(catalogConsistent()).toEqual([]);
  });

  it('every template belongs to exactly the kinds that list it, and every template is used', () => {
    const used = new Set(Object.values(notificationTypes).flatMap((t) => t.templates));
    expect([...used].sort()).toEqual([...notificationTemplateIds].sort());
  });

  it('ENG scenarios ride the platform kinds (no second pipeline)', () => {
    const byScenario = Object.values(notificationTypes).flatMap((t) =>
      t.engagement.map((e) => [e, t.kind] as const),
    );
    const scenarios = new Set(byScenario.map(([e]) => e));
    expect([...scenarios].sort()).toEqual([
      'ENG-01',
      'ENG-02',
      'ENG-03',
      'ENG-04',
      'ENG-05',
      'ENG-06',
    ]);
  });

  it('groups: memories / family / care / other, unknown kinds fall to other', () => {
    expect(inboxGroupOf('reminderRule')).toBe('care');
    expect(inboxGroupOf('vaccine')).toBe('care');
    expect(inboxGroupOf('album')).toBe('memories');
    expect(inboxGroupOf('message')).toBe('family');
    expect(inboxGroupOf('storage')).toBe('family');
    expect(inboxGroupOf('test')).toBe('other');
    expect(inboxGroupOf('fromTheFuture')).toBe('other');
  });
});

describe('destinations', () => {
  it('every destination falls back to INBOX within a few steps, never in a loop', () => {
    for (const id of notificationDestinationIds) {
      const chain = destinationChain(id);
      expect(chain.at(-1)).toBe('INBOX');
      expect(chain.length).toBeLessThanOrEqual(4);
    }
  });

  it('validates params: required, pattern, no extra keys passed through', () => {
    expect(destinationParams('MEMORIES_VIDEO_JOB', { babyId: 'b1', jobId: 'ksj_x' })).toBeNull();
    expect(
      destinationParams('MEMORIES_VIDEO_JOB', {
        babyId: 'b1',
        jobId: `ksj_${'a'.repeat(32)}`,
        url: 'https://evil',
      }),
    ).toEqual({ babyId: 'b1', jobId: `ksj_${'a'.repeat(32)}` });
    expect(destinationParams('INBOX', {})).toEqual({});
    expect(destinationParams('CARE_VACCINES', { babyId: 'b1', date: 'tomorrow' })).toBeNull();
    expect(destinationParams('CARE_VACCINES', { babyId: 'b1' })).toEqual({ babyId: 'b1' });
  });

  it('engagement destinations always need the server re-authorised id', () => {
    for (const d of Object.values(notificationDestinations)) {
      if (d.permission === 'engagement_server')
        expect(d.params.some((p) => p.key === 'engagementId' && p.required)).toBe(true);
    }
  });

  it('derives the destination of legacy rows from kind and ids', () => {
    expect(destinationFor('spending', { babyId: 'b', importId: 'im_x' })).toBe('SPENDING_IMPORT');
    expect(destinationFor('spending', { babyId: 'b' })).toBe('SPENDING');
    expect(destinationFor('story', { sourceCollection: 'stories', sourceId: 's1' })).toBe(
      'MEMORIES_STORY',
    );
    expect(destinationFor('story', {})).toBe('MEMORIES_STORY');
    expect(destinationFor('keepsakeVideo', { babyId: 'b' })).toBe('MEMORIES');
    expect(destinationFor('memories', { destination: 'INBOX' })).toBe('INBOX');
    expect(destinationFor('memories', { destination: 'https://x' })).toBe('MEMORIES');
  });

  it('the app mirror lists the same destination ids', () => {
    const dart = readFileSync(
      fileURLToPath(
        new URL(
          '../../../apps/mobile/lib/features/notifications/notification_destinations.dart',
          import.meta.url,
        ),
      ),
      'utf8',
    );
    const ids = [...dart.matchAll(/'([A-Z_]{4,})'/g)].map((m) => m[1]);
    for (const id of notificationDestinationIds) expect(ids).toContain(id);
  });
});

describe('lifecycle', () => {
  it('delivery never leaves a terminal state; accepted is never retried', () => {
    for (const s of ['accepted', 'rejected', 'cancelled', 'unknown'] as const) {
      expect(deliveryIsTerminal(s)).toBe(true);
      for (const to of notificationDeliveryStates)
        expect(canTransition('delivery', s, to)).toBe(false);
    }
    expect(canTransition('delivery', 'attempted', 'retry_pending')).toBe(true);
    expect(canTransition('delivery', 'failed', 'retry_pending')).toBe(true);
    expect(canTransition('delivery', 'failed', 'accepted')).toBe(false);
    expect(canTransition('delivery', 'pending', 'accepted')).toBe(false);
  });

  it('read and action are independent, one-way dimensions', () => {
    expect(canTransition('read', 'unread', 'read')).toBe(true);
    expect(canTransition('read', 'read', 'unread')).toBe(false);
    expect(canTransition('action', 'not_started', 'completed')).toBe(true);
    expect(canTransition('action', 'completed', 'started')).toBe(false);
    expect(canTransition('action', 'none', 'completed')).toBe(false);
    expect(canTransition('lifecycle', 'persisted', 'expired')).toBe(true);
    expect(canTransition('lifecycle', 'expired', 'persisted')).toBe(false);
  });

  it('bounded backoff', () => {
    expect([1, 2, 3, 9].map(retryDelayMs)).toEqual([60_000, 300_000, 1_800_000, 1_800_000]);
  });
});

describe('templates', () => {
  it('every built-in copy is valid against its own placeholder list', () => {
    for (const id of notificationTemplateIds) {
      const def = notificationTemplates[id];
      expect(validateTemplateCopy(def, def.builtin), id).toEqual([]);
      expect(localizedTemplateCopySchema.safeParse(def.builtin).success, id).toBe(true);
    }
  });

  it('renders numbers, plurals, per-language values and the baby name (D-094)', () => {
    const def = notificationTemplates['memories.new_moments'];
    expect(
      renderTemplate(def.builtin, 'en', { count: 1, actor_name: 'Mai', baby_name: 'Bin' }),
    ).toMatchObject({
      title: '1 new moment of Bin',
      body: 'Mai just shared with the family. Come take a look!',
      missing: [],
    });
    expect(renderTemplate(def.builtin, 'en', { count: 3, actor_name: 'Mai' }).title).toBe(
      '3 new moments of your baby',
    );
    expect(
      renderTemplate(def.builtin, 'vi', { count: 3, actor_name: 'Mai', baby_name: 'Bin' }).title,
    ).toBe('3 khoảnh khắc mới của Bin');
    const rule = notificationTemplates['care.rule_due'];
    expect(
      renderTemplate(rule.builtin, 'vi', {
        activity_name: { vi: 'cữ bú', en: 'feed' },
      }),
    ).toMatchObject({ title: 'Đến giờ cữ bú của bé rồi', body: 'Chưa có lần ghi nào gần đây' });
    // Without a name the line still starts with a capital ("Bé sắp tròn…", "Your baby is…").
    const eng = notificationTemplates['eng.keepsake_suggestion'];
    const label = { milestone_label: { vi: '100 ngày', en: '100 days' } };
    expect(renderTemplate(eng.builtin, 'vi', label).title).toBe('Bé sắp tròn 100 ngày rồi 🎉');
    expect(renderTemplate(eng.builtin, 'en', label).title).toBe('Your baby is almost 100 days 🎉');
    expect(renderTemplate(eng.builtin, 'vi', { ...label, baby_name: 'Bin' }).title).toBe(
      'Bin sắp tròn 100 ngày rồi 🎉',
    );
  });

  it('a missing value with no fallback is reported, and long values are cut', () => {
    const def = notificationTemplates['family.storage_granted'];
    expect(renderTemplate(def.builtin, 'vi', {}).missing).toEqual(['gb']);
    const r = renderTemplate(notificationTemplates['family.message'].builtin, 'en', {
      actor_name: 'x'.repeat(100),
    });
    // A long name is cut inside the title.
    expect(r.title).toBe(`New message from ${'x'.repeat(39)}…`);
  });

  it('rejects unknown and disallowed placeholders, URLs, markup and dropped required ones', () => {
    const def = notificationTemplates['family.storage_granted'];
    const copy = (vi: string, en = 'More {{gb}} GB') => ({
      vi: { title: 'T', body: vi },
      en: { title: 'T', body: en },
    });
    const codes = (vi: string, en?: string) =>
      validateTemplateCopy(def, copy(vi, en)).map((i) => `${i.language}:${i.code}`);
    expect(codes('{{baby_dob}} {{gb}}')).toContain('vi:unknown_placeholder');
    expect(codes('{{baby_name}} {{gb}}')).toContain('vi:not_allowed');
    expect(codes('{{actor_name}} {{gb}}')).toContain('vi:not_allowed');
    expect(codes('Xem https://x.y {{gb}}')).toContain('vi:forbidden_content');
    expect(codes('<b>{{gb}}</b>')).toContain('vi:forbidden_content');
    expect(codes('Không có số')).toContain('vi:missing_required');
    expect(codes('{{gb}', 'x {{gb}}')).toContain('vi:unbalanced_braces');
    expect(codes('{{plural:gb|một|nhiều}} {{gb}}')).toEqual([]);
    const story = notificationTemplates['memories.new_moments'];
    expect(
      validateTemplateCopy(story, {
        vi: { title: '{{plural:actor_name|a|b}}', body: '{{count}}' },
        en: { title: 'x', body: 'y' },
      }).map((i) => i.code),
    ).toContain('plural_needs_number');
  });
});

describe('staff API shapes', () => {
  it('template actions', () => {
    expect(
      staffTemplateActionSchema.safeParse({
        templateId: 'eng.weekly_recap',
        action: 'rollback',
        version: 2,
      }).success,
    ).toBe(true);
    expect(
      staffTemplateActionSchema.safeParse({ templateId: 'nope', action: 'publish' }).success,
    ).toBe(false);
  });

  it('timeline filters are bounded (92 days, masked recipient refs only)', () => {
    const base = { code: 'F-ABCD', from: '2026-10-01', to: '2026-10-21' };
    expect(staffNotificationTimelineSchema.safeParse(base).success).toBe(true);
    expect(staffNotificationTimelineSchema.safeParse({ ...base, from: '2026-01-01' }).success).toBe(
      false,
    );
    expect(
      staffNotificationTimelineSchema.safeParse({ ...base, recipient: 'uid_abc' }).success,
    ).toBe(false);
  });

  it('open receipts and ops config', () => {
    expect(
      recordNotificationOpenSchema.safeParse({
        inboxId: 'n_rr-abc-123',
        surface: 'push',
        outcome: 'navigated',
        destination: 'CARE_RULE_REMINDER',
      }).success,
    ).toBe(true);
    expect(notificationOpsConfigSchema.parse({})).toEqual({
      templatesEnabled: true,
      retryEnabled: true,
      pushPaused: { memories: false, family: false, care: false, other: false },
    });
  });
});
