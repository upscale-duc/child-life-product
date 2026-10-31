import { describe, expect, it } from 'vitest';
import type { Live } from '../src/product-copilot.js';
import { authorFeature, authoredSections, sourceOfBlock } from '../src/product-hub-author.js';
import { buildIndex, type SearchDoc } from '../src/product-hub-search.js';

// Sản phẩm · feature descriptions drafted by Claude (D-155, D-158): only the feature's sources,
// citations turned into checkable sources, other features' text and conflicts never cited.
const doc = (over: Partial<SearchDoc>): SearchDoc => ({
  id: 'x', kind: 'chunk', title: '', text: '', path: 'docs/x.md', anchor: null, authority: 'draft_spec', status: 'n/a', date: null, revision: 'r1', features: [], ids: [], ...over,
});
const feature = {
  id: 'care.sleep', name: { vi: 'Giấc ngủ', en: 'Sleep' }, pillar: 'care', aliases: ['ngủ'], hubKey: null, capabilities: ['module.basic'], platforms: ['ios'], chapters: [], lifecycle: 'built', implementation: 'implemented', verification: 'code_read', release: 'not_released', confidence: 'high', dependsOn: [], note: '',
  facts: { modules: ['apps/a.dart'], functions: [], callables: [], tests: [], docs: [], figma: [], decisions: ['D-151'], codeCitations: [], deadGlobs: [] }, revision: 'r1', syncedAt: '',
} as unknown as Live['features'][number];
const live = { features: [feature], sections: new Map(), conflicts: [], tiers: {} } as Live;
const index = buildIndex([
  doc({ id: 'c1', title: 'Business map › 7.4 Timers and sleep', text: 'Sleep overlap: never auto-merge.', path: 'docs/product/business-map.md', anchor: '74-timers-and-sleep', features: ['care.sleep'] }),
  doc({ id: 'D-151', kind: 'decision', title: 'D-151 · Night window', text: 'One night window 18:00–06:00 for sleep.', path: 'docs/product/business-map.md', ids: ['D-151'], authority: 'approved_decision' }),
]);

describe('sourceOfBlock', () => {
  it('turns blocks into sources the drafts tool checks', () => {
    expect(sourceOfBlock({ ...doc({ kind: 'decision', id: 'D-151' }), block: 'S1' })).toBe('D-151');
    expect(sourceOfBlock({ ...doc({ path: 'docs/a.md', anchor: 'rules' }), block: 'S1' })).toBe('docs/a.md#rules');
    expect(sourceOfBlock({ ...doc({ kind: 'feature', path: 'docs/product-hub/registry/features.json', anchor: 'care.sleep' }), block: 'S1' })).toBe('docs/product-hub/registry/features.json');
    expect(sourceOfBlock({ ...doc({ kind: 'section', path: null }), block: 'S1' })).toBeNull();
    expect(sourceOfBlock({ ...doc({ kind: 'conflict', path: null }), block: 'S1' })).toBeNull();
  });
});

describe('authorFeature', () => {
  it('asks for every section and keeps only real citations', async () => {
    let seen = '';
    const model = {
      model: 'fake',
      async answer(call: { user: string; schema?: Record<string, unknown> }) {
        seen = call.user;
        const ids = [...call.user.matchAll(/<block id="(S\d+)"/g)].map((m) => m[1]!);
        return {
          refused: false,
          output: Object.fromEntries(authoredSections.map((k) => [k, { vi: `${k} vi`, en: `${k} en`, cites: [...ids, 'S99'] }])),
        };
      },
    };
    const r = await authorFeature(index, live, 'care.sleep', model);
    expect(seen).toContain('Feature: care.sleep');
    expect(Object.keys(r!.sections)).toEqual([...authoredSections]);
    expect(r!.sections.rules!.sources).toEqual(expect.arrayContaining(['D-151', 'docs/product/business-map.md#74-timers-and-sleep', 'docs/product-hub/registry/features.json']));
    expect(r!.sections.rules!.sources).not.toContain('S99');
  });
  it('a refusal or a broken answer gives nothing', async () => {
    expect(await authorFeature(index, live, 'care.sleep', { model: 'f', answer: async () => ({ refused: true, output: null }) })).toBeNull();
    expect(await authorFeature(index, live, 'care.sleep', { model: 'f', answer: async () => ({ refused: false, output: { nope: 1 } }) })).toBeNull();
    expect(await authorFeature(index, live, 'grow.unknown', { model: 'f', answer: async () => ({ refused: false, output: {} }) })).toBeNull();
  });
});
