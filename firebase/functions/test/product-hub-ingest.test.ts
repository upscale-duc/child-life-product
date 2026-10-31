import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { productRegistrySchema, type ProductRegistry } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import {
  buildChangeSet,
  callablesByFile,
  chunkMarkdown,
  detectLang,
  emptyState,
  extractIds,
  fold,
  globToRegExp,
  looksSecret,
  parseBusinessMap,
  recordHash,
  selectFiles,
  defaultSyncConfig,
  type AppliedState,
  type RepoFile,
} from '../src/product-hub-ingest.js';

// Product Hub ingestion (D-155, docs/product-hub/06): pure snapshot → change set.
const repo = resolve(import.meta.dirname, '../../..');
const now = new Date('2026-10-31T09:00:00Z');

const registry: ProductRegistry = productRegistrySchema.parse({
  version: 1,
  features: [
    {
      id: 'remember.auto_save',
      name: { vi: 'Tự lưu kỷ niệm', en: 'Auto-save memories' },
      pillar: 'remember',
      hubKey: 'auto_save',
      platforms: ['ios'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      modules: ['apps/mobile/lib/features/auto_save/**'],
      functions: ['firebase/functions/src/features.ts'],
      tests: ['apps/mobile/test/features/auto_save_test.dart'],
      docs: ['docs/product/auto-save-plan.md'],
      decisions: ['D-066'],
    },
    {
      id: 'care.feeding',
      name: { vi: 'Cho ăn', en: 'Feeding' },
      pillar: 'care',
      platforms: ['ios', 'android'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      modules: ['apps/mobile/lib/features/care/**', 'apps/mobile/lib/features/missing/**'],
    },
  ],
});

const md = (path: string, text: string, blobSha = `b_${path}`): RepoFile => ({ path, blobSha, text });
const baseFiles = (): RepoFile[] => [
  md('apps/mobile/lib/features/auto_save/engine.dart', '// D-066: beta on iOS\nclass X {}'),
  md('apps/mobile/lib/features/care/care_sheets.dart', '// R-086 night window\n'),
  md('apps/mobile/test/features/auto_save_test.dart', ''),
  md(
    'firebase/functions/src/index.ts',
    "import { featureAccess } from './features.js';\nexport const getFeatureAccess = onCall((r) => featureAccess(r));\nexport const ping = onCall(() => 1);\n",
  ),
  md('firebase/functions/src/features.ts', 'export function featureAccess() {}'),
  md('docs/product/auto-save-plan.md', '# Tự lưu kỷ niệm\n\n## Tier\n\nTự lưu kỷ niệm: Premium for everyone.\n'),
  md('docs/product/plans.md', '# Free / Plus / Pro: credit proposal\n\nUsage levels.\n'),
  md('docs/notes.md', '# Notes\n\nPlain text.\n'),
];
const snapshot = (files = baseFiles(), revision = 'r1') => ({ revision, files, registry, now });

/** The state the server would hold after approving a change set. */
function applied(items: ReturnType<typeof buildChangeSet>['items']): AppliedState {
  const s: AppliedState = { sources: [], decisions: {}, features: {}, conflicts: [] };
  for (const i of items) {
    if (i.type === 'source' && i.change !== 'deleted') s.sources.push(i.source);
    if (i.type === 'decision') s.decisions[i.decision.id] = recordHash(i.decision);
    if (i.type === 'feature') s.features[i.feature.id] = recordHash(i.feature);
    if (i.type === 'conflict') s.conflicts.push(i.conflict.id);
  }
  return s;
}

describe('text helpers', () => {
  it('folds Vietnamese accents', () => {
    expect(fold('Hiểu con · Đêm')).toBe('hieu con · dem');
  });
  it('extracts decision and metric ids once, sorted', () => {
    expect(extractIds('D-150 and R-086, again D-150, MET-01')).toEqual(['D-150', 'MET-01', 'R-086']);
  });
  it('tells Vietnamese from English', () => {
    expect(detectLang('Bé bú hết, ợ hơi tốt và ngủ ngon')).toBe('vi');
    expect(detectLang('The baby fed well')).toBe('en');
  });
  it('refuses text that looks like a credential', () => {
    expect(looksSecret('-----BEGIN PRIVATE KEY-----\nabc')).toBe(true);
    expect(looksSecret('key: sk-abcdefghijklmnopqrstuvwx123')).toBe(true);
    expect(looksSecret('Lumi uses OPENAI_API_KEY from Secret Manager')).toBe(false);
  });
  it('matches globs like the registry uses them', () => {
    expect(globToRegExp('apps/**/care/*.dart').test('apps/mobile/lib/features/care/a.dart')).toBe(true);
    expect(globToRegExp('docs/**/*.md').test('docs/a.md')).toBe(true);
    expect(globToRegExp('docs/*.md').test('docs/x/a.md')).toBe(false);
  });
  it('excludes the chat log, skills and worktrees by default', () => {
    expect(
      selectFiles(
        ['docs/a.md', 'docs/discovery/adaptive-experience-chat.md', '.claude/skills/x.md', 'content/x.md', 'docs/a.png'],
        defaultSyncConfig,
      ),
    ).toEqual(['docs/a.md']);
  });
});

describe('chunkMarkdown', () => {
  it('makes one chunk per heading section with its heading path', () => {
    const c = chunkMarkdown('# A\n\nintro\n\n## B\n\nbody b\n\n### C\n\nbody c\n\n## D\n\nbody d');
    expect(c.map((x) => x.headingPath.join('>'))).toEqual(['A', 'A>B', 'A>B>C', 'A>D']);
    expect(c[2]!.anchor).toBe('c');
  });
  it('splits a large table at rows and repeats the header in every piece', () => {
    const rows = Array.from({ length: 80 }, (_, i) => `| R-${String(i).padStart(3, '0')} | ${'x'.repeat(80)} |`);
    const c = chunkMarkdown(`## Rules\n\n| Id | Text |\n| --- | --- |\n${rows.join('\n')}`, 2000);
    expect(c.length).toBeGreaterThan(2);
    for (const piece of c) expect(piece.text.startsWith('| Id | Text |\n| --- | --- |')).toBe(true);
    expect(c.flatMap((x) => x.text.split('\n')).filter((l) => l.startsWith('| R-'))).toHaveLength(80);
  });
  it('never splits a code fence or reads headings inside it', () => {
    const c = chunkMarkdown('## Code\n\n```\n# not a heading\nline\n```\n\nafter');
    expect(c).toHaveLength(1);
    expect(c[0]!.text).toContain('# not a heading');
  });
});

describe('parseBusinessMap', () => {
  const sample = [
    '## Owner decisions (2026-10-10)',
    '| ID | Decision | Resolves | Consequence |',
    '| --- | --- | --- | --- |',
    '| **D-001** | New photos are **shareable by default**. | Q-002 | x |',
    '| **D-090** | **No reasons** (owner, 2026-10-21): supersedes D-001. | — | y |',
    '- **R-040** 10 GB per family.',
    '| ~~Q-001~~ | Portal purpose |',
    '| Q-002 | Default audience |',
    '| Q-003 | Provider? (**Resolved by D-003**) |',
    'G-001 loading states; G-020 care note entry; G-021 future-time validation',
    'Later mention of D-001 is a reference.',
  ].join('\n');
  const { records, unparsed } = parseBusinessMap(sample, 'docs/product/business-map.md', 'c1');
  const byId = new Map(records.map((r) => [r.id, r]));

  it('reads table rows, list items and multi-id lines', () => {
    expect([...byId.keys()].sort()).toEqual(['D-001', 'D-090', 'G-001', 'G-020', 'G-021', 'Q-001', 'Q-002', 'Q-003', 'R-040']);
    expect(unparsed).toEqual([]);
    expect(byId.get('D-001')!.title).toBe('shareable by default');
    expect(byId.get('D-001')!.date).toBe('2026-10-10');
    expect(byId.get('D-090')!.date).toBe('2026-10-21');
    expect(byId.get('G-020')!.text).toBe('care note entry');
  });
  it('derives statuses: resolved, superseded, recorded, open', () => {
    expect(byId.get('Q-001')!.status).toBe('resolved');
    expect(byId.get('Q-002')!.status).toBe('resolved'); // in D-001's Resolves column
    expect(byId.get('Q-003')!.status).toBe('resolved');
    expect(byId.get('D-001')!.status).toBe('superseded');
    expect(byId.get('D-090')!.status).toBe('approved');
    expect(byId.get('R-040')!.status).toBe('recorded');
    expect(byId.get('G-021')!.status).toBe('open');
  });
  it('keeps the first definition, not later mentions', () => {
    expect(byId.get('D-001')!.source.line).toBe(4);
  });
  it('reads the real business map with no unreadable definition line', () => {
    const real = readFileSync(resolve(repo, 'docs/product/business-map.md'), 'utf8');
    const parsed = parseBusinessMap(real, 'docs/product/business-map.md', 'HEAD');
    expect(parsed.unparsed).toEqual([]);
    expect(parsed.records.filter((r) => r.kind === 'D').length).toBeGreaterThanOrEqual(150);
    expect(parsed.records.length).toBeGreaterThanOrEqual(480);
  });
});

describe('callablesByFile', () => {
  it('maps exported callables to the handler files they use', () => {
    const m = callablesByFile(
      "import { a, b as bee } from './x.js';\nimport { c } from './y.js';\nexport const one = onCall(() => a());\nexport const two = onCall(() => bee() + c());\n",
    );
    expect(m.get('firebase/functions/src/x.ts')).toEqual(['one', 'two']);
    expect(m.get('firebase/functions/src/y.ts')).toEqual(['two']);
  });
});

describe('buildChangeSet', () => {
  it('adds everything against an empty state, with facts, dead globs and conflicts', () => {
    const cs = buildChangeSet(snapshot(), emptyState);
    const sources = cs.items.filter((i) => i.type === 'source');
    expect(sources.map((i) => i.type === 'source' && i.source.path)).toEqual([
      'docs/notes.md',
      'docs/product/auto-save-plan.md',
      'docs/product/plans.md',
    ]);
    const feature = cs.items.find((i) => i.type === 'feature' && i.feature.id === 'remember.auto_save');
    expect(feature?.type === 'feature' && feature.feature.facts).toMatchObject({
      callables: ['getFeatureAccess'],
      decisions: ['D-066'],
      codeCitations: [{ id: 'D-066', at: 'apps/mobile/lib/features/auto_save/engine.dart:1' }],
      docs: ['docs/product/auto-save-plan.md'],
    });
    expect(cs.summary.warnings).toContain('care.feeding: no file matches apps/mobile/lib/features/missing/**');
    const plan = sources.find((i) => i.type === 'source' && i.source.path === 'docs/product/auto-save-plan.md');
    expect(plan?.type === 'source' && plan.source.features).toEqual(['remember.auto_save']);
  });

  it('raises a tier conflict and a plan-model conflict, never picking a winner (Scenario C)', () => {
    const conflicts = buildChangeSet(snapshot(), emptyState).items.flatMap((i) =>
      i.type === 'conflict' ? [i.conflict] : [],
    );
    expect(conflicts.map((c) => c.topic).sort()).toEqual(['plan_model', 'tier']);
    const tier = conflicts.find((c) => c.topic === 'tier')!;
    expect(tier.feature).toBe('remember.auto_save');
    expect(tier.status).toBe('open');
    expect(tier.claims.map((c) => c.authority)).toEqual(['draft_spec', 'code']);
  });

  it('is idempotent: the same revision against its own applied state changes nothing', () => {
    const first = buildChangeSet(snapshot(), emptyState);
    const again = buildChangeSet(snapshot(undefined, 'r2'), applied(first.items));
    expect(again.items).toEqual([]);
    expect(again.summary.unchanged).toBeGreaterThan(0);
  });

  it('detects changed, moved and deleted files (Scenario D)', () => {
    const state = applied(buildChangeSet(snapshot(), emptyState).items);
    const files = baseFiles()
      .filter((f) => f.path !== 'docs/notes.md' && f.path !== 'docs/product/plans.md')
      .map((f) =>
        f.path === 'docs/product/auto-save-plan.md' ? { ...f, text: `${f.text}\n## New\n\nMore.\n`, blobSha: 'b2' } : f,
      );
    files.push(md('docs/archive/notes.md', '# Notes\n\nPlain text.\n', 'b_docs/notes.md'));
    const cs = buildChangeSet(snapshot(files, 'r2'), state);
    const changes = cs.items.flatMap((i) => (i.type === 'source' ? [`${i.change}:${i.source.path}`] : []));
    expect(changes.sort()).toEqual([
      'changed:docs/product/auto-save-plan.md',
      'deleted:docs/product/plans.md',
      'moved:docs/archive/notes.md',
    ]);
    const moved = cs.items.find((i) => i.type === 'source' && i.change === 'moved');
    const oldId = state.sources.find((s) => s.path === 'docs/notes.md')!.id;
    expect(moved?.type === 'source' && moved.source.id).toBe(oldId);
    expect(moved?.type === 'source' && moved.before?.path).toBe('docs/notes.md');
  });

  it('a row inserted above does not mark the decisions below as changed', () => {
    const map = (extra: string) =>
      md('docs/product/business-map.md', `## Owner decisions (2026-10-10)\n| ID | Decision | R | C |\n| --- | --- | --- | --- |\n${extra}| **D-001** | **First**. | — | — |\n| **D-002** | **Second**. | — | — |\n`, `b_${extra.length}`);
    const state = applied(buildChangeSet(snapshot([...baseFiles(), map('')]), emptyState).items);
    const next = buildChangeSet(snapshot([...baseFiles(), map('| **D-000** | **Zero**. | — | — |\n')], 'r2'), state);
    const decisions = next.items.flatMap((i) => (i.type === 'decision' ? [`${i.change}:${i.decision.id}`] : []));
    expect(decisions).toEqual(['added:D-000']);
  });

  it('refuses a credential-looking file and reports it', () => {
    const files = [...baseFiles(), md('docs/leak.md', '# Keys\n\n-----BEGIN PRIVATE KEY-----\n')];
    const cs = buildChangeSet(snapshot(files), emptyState);
    expect(cs.items.some((i) => i.type === 'source' && i.source.path === 'docs/leak.md')).toBe(false);
    expect(cs.summary.warnings).toContain('docs/leak.md: refused, looks like it holds a credential');
  });
});

describe('the repository registry', () => {
  const real = productRegistrySchema.parse(
    JSON.parse(readFileSync(resolve(repo, 'docs/product-hub/registry/features.json'), 'utf8')),
  );
  it('has the 49 Phase 0 features and every hub catalogue key', async () => {
    const { featureKeys } = await import('@child-life/contracts');
    expect(real.features).toHaveLength(49);
    const hubKeys = real.features.flatMap((f) => (f.hubKey ? [f.hubKey] : []));
    expect([...new Set(hubKeys)].sort()).toEqual([...featureKeys].sort());
  });
});
