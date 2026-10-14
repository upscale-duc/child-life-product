import { describe, expect, it } from 'vitest';
import {
  assignKeepsakeVersions,
  createMemoryRequestSchema,
  generatedSchema,
  keepsakeCatalogSchema,
  keepsakeBrandSvg,
  keepsakeSeedV1,
  keepsakeTemplateSchema,
  listTemplates,
  keepsakeNeedsPremiumCheck,
  keepsakeTemplateAccess,
} from '../src/index.js';

const round = keepsakeSeedV1.templates.find((t) => t.id === 'card_round')!;

describe('keepsake catalog (D-068)', () => {
  it('the seed catalog is valid and ids are unique', () => {
    const r = keepsakeCatalogSchema.safeParse(keepsakeSeedV1);
    expect(r.success ? null : r.error.issues).toBe(null);
    const keys = keepsakeSeedV1.templates.map((t) => `${t.id}@${t.version}`);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('lists MM10 cards in order with their tiers', () => {
    const cards = listTemplates(keepsakeSeedV1, 'card');
    expect(cards.map((t) => t.name.vi)).toEqual(['Tròn trịa', 'Toàn ảnh', 'Hồng phấn', 'Đêm sao']);
    expect(cards.map((t) => t.tier)).toEqual(['free', 'free', 'premium', 'premium']);
    expect(listTemplates({ templates: [{ ...round, status: 'draft' }] }, 'card')).toEqual([]);
  });

  it('a card is layers, a video a composition; cards use uploaded pictures only', () => {
    const v = keepsakeSeedV1.templates.find((t) => t.kind === 'video')!;
    expect(keepsakeTemplateSchema.safeParse({ ...v, layouts: round.layouts }).success).toBe(false);
    expect(keepsakeTemplateSchema.safeParse({ ...round, layouts: {} }).success).toBe(false);
    expect(keepsakeTemplateSchema.safeParse({ ...v, scenes: v.scenes.slice(1) }).success).toBe(
      false,
    );
    const withFrame = (asset: string) => ({
      ...round,
      layouts: {
        portrait: [
          ...round.layouts!.portrait!,
          { type: 'image', asset, rect: { x: 0, y: 0, w: 1, h: 1 }, fit: 'cover', opacity: 1 },
        ],
      },
    });
    expect(keepsakeTemplateSchema.safeParse(withFrame('frame-pink_1a2b3c4d.webp')).success).toBe(
      true,
    );
    expect(keepsakeTemplateSchema.safeParse(withFrame('lullaby_1a2b3c4d.mp3')).success).toBe(false);
    expect(
      keepsakeTemplateSchema.safeParse(withFrame('babies/b1/media/m/original.jpg')).success,
    ).toBe(false);
    expect(
      keepsakeTemplateSchema.safeParse({ ...v, assets: { music: 'lullaby_1a2b3c4d.m4a' } }).success,
    ).toBe(true);
  });

  it('publishing bumps the version of changed templates only, never reusing a number', () => {
    const published = assignKeepsakeVersions(keepsakeSeedV1, null, {});
    expect(published.templates.every((t) => t.version === 1)).toBe(true);
    const edited = {
      templates: [
        { ...round, order: 11 },
        ...keepsakeSeedV1.templates.filter((t) => t.id !== 'card_round'),
      ],
    };
    const next = assignKeepsakeVersions(edited, published, { card_round: 3 });
    expect(next.templates.find((t) => t.id === 'card_round')!.version).toBe(4);
    expect(next.templates.find((t) => t.id === 'card_blush')!.version).toBe(1);
    // Firestore returns map keys in its own order: still the same template.
    const reordered = published.templates.map((t) =>
      t.layouts ? { ...t, layouts: Object.fromEntries(Object.entries(t.layouts).reverse()) } : t,
    );
    const again = assignKeepsakeVersions(keepsakeSeedV1, { templates: reordered }, {});
    expect(again.templates.every((t) => t.version === 1)).toBe(true);
    const archived = assignKeepsakeVersions(
      { templates: [{ ...round, status: 'archived' }] },
      published,
      {},
    );
    expect(archived.templates).toEqual([]);
  });

  it('a generated memory is one photo; older apps send no `generated`', () => {
    const generated = {
      kind: 'card',
      templateId: 'card_round',
      templateVersion: 1,
      occasion: 'm1',
      format: 'portrait',
    };
    expect(generatedSchema.safeParse(generated).success).toBe(true);
    const base = {
      babyId: 'b1',
      memoryId: `mem_${'a'.repeat(32)}`,
      batchId: `bat_${'a'.repeat(32)}`,
      caption: null,
      audience: 'parents',
      notifyFamily: false,
      dateMode: 'single',
      date: '2026-11-14',
      milestone: null,
      generated,
    };
    const item = {
      mediaId: `med_${'a'.repeat(32)}`,
      type: 'photo',
      contentType: 'image/jpeg',
      sizeBytes: 1000,
      captureAt: '2026-11-14T09:00:00+07:00',
      durationMs: null,
      width: 2160,
      height: 2700,
      hasPoster: false,
    };
    expect(createMemoryRequestSchema.safeParse({ ...base, items: [item] }).success).toBe(true);
    expect(
      createMemoryRequestSchema.safeParse({
        ...base,
        items: [item, { ...item, mediaId: `med_${'b'.repeat(32)}` }],
      }).success,
    ).toBe(false);
    const old: Record<string, unknown> = { ...base };
    delete old.generated;
    const parsed = createMemoryRequestSchema.safeParse({ ...old, items: [item] });
    expect(parsed.success && parsed.data.generated).toBe(null);
  });
});

describe('Flutter test fixture', () => {
  it('apps/mobile/test/helpers/keepsake_seed.json matches the seed', async () => {
    const { readFileSync } = await import('node:fs');
    const url = new URL('../../../apps/mobile/test/helpers/keepsake_seed.json', import.meta.url);
    // Regenerate with: node packages/contracts/scripts/keepsake-fixture.mjs
    expect(JSON.parse(readFileSync(url, 'utf8'))).toEqual(keepsakeSeedV1);
  });

  it('apps/mobile/assets/logo/lockup-h-tint.svg is the brand lockup (D-068 #10)', async () => {
    const { readFileSync } = await import('node:fs');
    const url = new URL('../../../apps/mobile/assets/logo/lockup-h-tint.svg', import.meta.url);
    expect(readFileSync(url, 'utf8')).toBe(`${keepsakeBrandSvg('#000000')}\n`);
  });
});

describe('Chapter 01 set (docs/product/remember-2-templates.md)', () => {
  it('every video scene says what it shows; required scenes fit in the minimum (MM06)', async () => {
    const { keepsakeChapter1Videos } = await import('../src/index.js');
    for (const t of [...keepsakeSeedV1.templates, ...keepsakeChapter1Videos]) {
      if (t.kind !== 'video') continue;
      expect(t.scenes.filter((s) => !s.optional).length, t.id).toBeLessThanOrEqual(t.photos.min);
      expect(new Set(t.scenes.map((s) => s.hint.vi)).size, t.id).toBeGreaterThan(
        t.scenes.length / 2,
      );
      for (const s of t.scenes)
        if (s.ageDays) expect(s.ageDays.min, t.id).toBeLessThanOrEqual(s.ageDays.max);
    }
  });

  it('the twelve video templates are valid and name a composition each', async () => {
    const { keepsakeChapter1Videos, keepsakeCompositions } = await import('../src/index.js');
    const parsed = keepsakeCatalogSchema.safeParse({
      ...keepsakeSeedV1,
      templates: [...keepsakeSeedV1.templates, ...keepsakeChapter1Videos],
    });
    expect(parsed.success).toBe(true);
    expect(keepsakeChapter1Videos).toHaveLength(12);
    for (const t of keepsakeChapter1Videos) {
      expect(keepsakeCompositions).toContain(t.composition);
      expect(t.brand).not.toBeNull();
      expect(t.scenes).toHaveLength(t.photos.max);
    }
  });

  it('photo age labels and birth stats read the same in vi and en', async () => {
    const { keepsakeAgeLabel, keepsakeBirthStats } = await import('../src/index.js');
    expect(keepsakeAgeLabel('2026-01-14', '2026-01-14', 'vi')).toBe('Ngày đầu');
    expect(keepsakeAgeLabel('2026-01-14', '2026-01-18', 'en')).toBe('Day 5');
    expect(keepsakeAgeLabel('2026-01-14', '2026-02-10', 'vi')).toBe('Tuần 4');
    expect(keepsakeAgeLabel('2026-01-14', '2026-07-20', 'vi')).toBe('Tháng 6');
    expect(keepsakeAgeLabel('2026-01-14', '2027-01-14', 'en')).toBe('Year 1');
    expect(keepsakeAgeLabel('2026-01-14', '2026-01-01', 'vi')).toBe(null);
    expect(keepsakeAgeLabel(null, '2026-01-01', 'vi')).toBe(null);
    expect(keepsakeBirthStats(3.2, 50, 'vi')).toBe('3,2 kg · 50 cm');
    expect(keepsakeBirthStats(3.2, null, 'en')).toBe('3.2 kg');
    expect(keepsakeBirthStats(null, null, 'en')).toBe(null);
  });
});

describe('keepsakeTemplateAccess (Q1, D-068 #8)', () => {
  const free = { tier: 'free' as const };
  const premium = { tier: 'premium' as const };
  const mode = (access: 'everyone' | 'hidden' | 'subscribers') => ({ access, badges: true });

  it('free templates are always ok; everyone mode keeps the beta open', () => {
    for (const m of ['everyone', 'hidden', 'subscribers'] as const) {
      expect(keepsakeTemplateAccess(free, mode(m), false)).toBe('ok');
    }
    expect(keepsakeTemplateAccess(premium, mode('everyone'), false)).toBe('ok');
  });

  it('hidden is unavailable; subscribers needs templates.premium', () => {
    expect(keepsakeTemplateAccess(premium, mode('hidden'), true)).toBe('unavailable');
    expect(keepsakeTemplateAccess(premium, mode('subscribers'), false)).toBe('premium-required');
    expect(keepsakeTemplateAccess(premium, mode('subscribers'), true)).toBe('ok');
    expect(keepsakeNeedsPremiumCheck(premium, mode('subscribers'))).toBe(true);
    expect(keepsakeNeedsPremiumCheck(free, mode('subscribers'))).toBe(false);
  });
});
