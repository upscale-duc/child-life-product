import { createHash } from 'node:crypto';
import {
  catalogueFeature,
  journeyRegistrySchema,
  metricRegistrySchema,
  type ChangeItem,
  type MetricInstrumentation,
  type ProductMetricRecord,
  type ProductJourneyRecord,
  type ChangeSetSummary,
  type DecisionKind,
  type DecisionStatus,
  type FeatureFacts,
  type ProductChunk,
  type ProductConflictRecord,
  type ProductDecisionRecord,
  type ProductFeatureRecord,
  type ProductRegistry,
  type ProductSourceRecord,
  type RegistryFeature,
  type SourceAuthority,
} from '@child-life/contracts';

/**
 * Product Hub ingestion (D-155, `docs/product-hub/06-knowledge-ingestion.md`): pure functions
 * from a repository snapshot to a change set. No Firestore, no file system — the sync script
 * reads the repository and the applied state, the server stores what this returns. Everything
 * is deterministic: the same revision and state give the same change set (no duplicates).
 */

export const sha256 = (s: string | Buffer) => createHash('sha256').update(s).digest('hex');

// ---------- Text helpers ----------

/** Lowercase, Vietnamese accents folded ("Hiểu con" → "hieu con"), for matching and search. */
export function fold(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase();
}

/** Normalized text for hashing: LF line ends, no trailing spaces. */
export function normalizeText(s: string): string {
  return s
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .map((l) => l.replace(/\s+$/, ''))
    .join('\n')
    .trim();
}

const idPattern = /\b(?:[DRPQG]-\d{3}|MET-\d{2,3})\b/g;
/** Decision, rule, proposal, question, gap and metric ids mentioned in a text, sorted, unique. */
export function extractIds(text: string): string[] {
  return [...new Set(text.match(idPattern) ?? [])].sort();
}

/** "vi" when Vietnamese diacritics make up a visible share of the letters. */
export function detectLang(text: string): 'vi' | 'en' {
  const letters = text.match(/\p{L}/gu)?.length ?? 0;
  if (letters === 0) return 'en';
  const marked = text.match(/[ăâđêôơưàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ]/giu);
  return (marked?.length ?? 0) / letters > 0.03 ? 'vi' : 'en';
}

export function anchorOf(heading: string): string {
  return (
    fold(heading)
      .replace(/[^a-z0-9\s-]/g, '')
      .trim()
      .replace(/\s+/g, '-')
      .slice(0, 80) || 'top'
  );
}

// ---------- Secrets and paths ----------

const secretPatterns = [
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
  /\bsk-[A-Za-z0-9_-]{20,}\b/,
  /\bAIza[0-9A-Za-z_-]{35}\b/,
  /"private_key"\s*:/,
  /\bre_[A-Za-z0-9]{24,}\b/,
];
/** A file that looks like it holds a credential is refused, never ingested (doc 06 §2.1). */
export function looksSecret(text: string): boolean {
  return secretPatterns.some((p) => p.test(text));
}

/** Minimal glob: `**` any depth, `*` within a segment, `?` one char. */
export function globToRegExp(glob: string): RegExp {
  let re = '';
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i]!;
    if (c === '*') {
      if (glob[i + 1] === '*') {
        const slash = glob[i + 2] === '/';
        re += slash ? '(?:.*/)?' : '.*';
        i += slash ? 2 : 1;
      } else re += '[^/]*';
    } else if (c === '?') re += '[^/]';
    else re += c.replace(/[.+^${}()|[\]\\]/g, '\\$&');
  }
  return new RegExp(`^${re}$`);
}

export function matchGlobs(files: readonly string[], globs: readonly string[]) {
  const matched = new Set<string>();
  const dead: string[] = [];
  for (const g of globs) {
    const re = globToRegExp(g);
    const hit = files.filter((f) => re.test(f));
    if (hit.length === 0) dead.push(g);
    hit.forEach((f) => matched.add(f));
  }
  return { files: [...matched].sort(), dead };
}

export interface SyncConfig {
  include: string[];
  exclude: string[];
  sizeLimitKb: number;
}

export const defaultSyncConfig: SyncConfig = {
  include: ['docs/**/*.md'],
  exclude: [
    'docs/discovery/adaptive-experience-chat.md',
    'docs/**/img/**',
    'docs/design/reviews/assets/**',
    '**/node_modules/**',
    '.claude/**',
    'content/**',
    'artifacts/**',
  ],
  sizeLimitKb: 512,
};

export function selectFiles(files: readonly string[], config: SyncConfig): string[] {
  const inc = config.include.map(globToRegExp);
  const exc = config.exclude.map(globToRegExp);
  return files.filter((f) => inc.some((r) => r.test(f)) && !exc.some((r) => r.test(f))).sort();
}

/** Default authority by path (doc 03 §1); review can change a single source later. */
export function authorityFor(path: string): SourceAuthority {
  if (path === 'docs/product/business-map.md') return 'approved_decision';
  if (path.startsWith('docs/architecture/')) return 'approved_decision';
  if (path.startsWith('docs/discovery/figma-extract/')) return 'design_reference';
  if (path.startsWith('docs/design/')) return 'design_reference';
  if (path === 'docs/product/figma-coverage-checklist.md') return 'design_reference';
  if (
    path.startsWith('docs/product-audit/') ||
    path.startsWith('docs/audits/') ||
    path.startsWith('docs/discovery/') ||
    /\/(adaptive-experience-audit|content-review-[^/]+)\//.test(path) ||
    /(review|eval|report|latency)[^/]*\.md$/.test(path)
  ) {
    return 'research';
  }
  if (path.startsWith('docs/development/slice-reports/')) return 'verified_implementation';
  return 'draft_spec';
}

export function docDateOf(path: string, text: string): string | null {
  const fromName = path.match(/(20\d\d-\d\d-\d\d)/);
  if (fromName) return fromName[1]!;
  const head = text.split('\n').slice(0, 25).join('\n');
  const iso = head.match(/\b(20\d\d-\d\d-\d\d)\b/);
  if (iso) return iso[1]!;
  const vi = head.match(/\b(\d{1,2})\/(\d{1,2})\/(20\d\d)\b/);
  return vi ? `${vi[3]}-${vi[2]!.padStart(2, '0')}-${vi[1]!.padStart(2, '0')}` : null;
}

// ---------- Markdown chunking ----------

export interface RawChunk {
  headingPath: string[];
  anchor: string;
  text: string;
}

interface Block {
  text: string;
  /** For a table row: the header + separator lines, repeated when a table is split. */
  tableHeader?: string;
}

const bytes = (s: string) => Buffer.byteLength(s, 'utf8');

function blocksOf(lines: string[]): Block[] {
  const out: Block[] = [];
  let para: string[] = [];
  const flush = () => {
    if (para.join('').trim()) out.push({ text: para.join('\n') });
    para = [];
  };
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!;
    if (/^\s*(```|~~~)/.test(line)) {
      flush();
      const fence = [line];
      i++;
      while (i < lines.length && !/^\s*(```|~~~)/.test(lines[i]!)) fence.push(lines[i++]!);
      if (i < lines.length) fence.push(lines[i]!);
      out.push({ text: fence.join('\n') });
      continue;
    }
    if (/^\s*\|/.test(line) && /^\s*\|[\s:|-]+\|\s*$/.test(lines[i + 1] ?? '')) {
      flush();
      const header = `${line}\n${lines[i + 1]}`;
      i += 2;
      out.push({ text: header, tableHeader: header });
      while (i < lines.length && /^\s*\|/.test(lines[i]!)) {
        out.push({ text: lines[i]!, tableHeader: header });
        i++;
      }
      i--;
      continue;
    }
    if (!line.trim()) {
      flush();
      continue;
    }
    para.push(line);
  }
  flush();
  return out;
}

function hardSplit(text: string, max: number): string[] {
  const out: string[] = [];
  let rest = text;
  while (bytes(rest) > max) {
    let cut = Math.floor(rest.length * (max / bytes(rest)) * 0.95);
    const space = rest.lastIndexOf(' ', cut);
    if (space > cut * 0.6) cut = space;
    out.push(rest.slice(0, cut));
    rest = rest.slice(cut);
  }
  if (rest.trim()) out.push(rest);
  return out;
}

/**
 * One chunk per heading section; a section over `maxBytes` is split at paragraphs or table rows
 * (each piece of a table keeps its header), code fences are never split, and a single block
 * over the limit is cut at a space.
 */
export function chunkMarkdown(markdown: string, maxBytes = 4000): RawChunk[] {
  const lines = normalizeText(markdown).split('\n');
  const sections: Array<{ path: string[]; lines: string[] }> = [];
  const stack: Array<{ level: number; text: string }> = [];
  let current = { path: [] as string[], lines: [] as string[] };
  let fenced = false;
  for (const line of lines) {
    if (/^\s*(```|~~~)/.test(line)) fenced = !fenced;
    const h = !fenced && line.match(/^(#{1,6})\s+(.+?)\s*#*\s*$/);
    if (h) {
      sections.push(current);
      const level = h[1]!.length;
      while (stack.length && stack[stack.length - 1]!.level >= level) stack.pop();
      stack.push({ level, text: h[2]!.replace(/[*_`]/g, '') });
      current = { path: stack.map((s) => s.text), lines: [] };
      continue;
    }
    current.lines.push(line);
  }
  sections.push(current);

  const chunks: RawChunk[] = [];
  for (const s of sections) {
    const blocks = blocksOf(s.lines);
    if (blocks.length === 0) continue;
    const anchor = anchorOf(s.path[s.path.length - 1] ?? 'top');
    let buf: string[] = [];
    let size = 0;
    let header: string | undefined;
    const emit = () => {
      const text = buf.join('\n\n').trim();
      if (text) chunks.push({ headingPath: s.path, anchor, text });
      buf = [];
      size = 0;
    };
    for (const b of blocks) {
      for (const piece of hardSplit(b.text, maxBytes - (b.tableHeader ? bytes(b.tableHeader) : 0) - 8)) {
        const joiner = b.tableHeader && header === b.tableHeader && buf.length ? '\n' : '\n\n';
        if (size + bytes(piece) + joiner.length > maxBytes && buf.length) {
          emit();
          header = undefined;
        }
        if (b.tableHeader && header !== b.tableHeader && piece !== b.tableHeader) {
          buf.push(b.tableHeader);
          size += bytes(b.tableHeader) + 2;
        }
        if (b.tableHeader && buf.length && header === b.tableHeader) {
          buf[buf.length - 1] += `\n${piece}`;
        } else buf.push(piece);
        size += bytes(piece) + joiner.length;
        header = b.tableHeader;
      }
    }
    emit();
  }
  return chunks;
}

// ---------- Business map ----------

const defLine =
  /^(?:\|\s*|[-*]\s+)?(~~)?(?:\*\*)?(~~)?([DRPQG]-\d{3})(?:\*\*)?(~~)?(?:\*\*)?(?=[\s|.:,)]|$)/;

const cleanMd = (s: string) =>
  s
    .replace(/\*\*|~~|`/g, '')
    .replace(/\s+/g, ' ')
    .trim();

function titleOf(text: string): string {
  const bold = text.match(/\*\*([^*]{3,160})\*\*/);
  const base = cleanMd(bold ? bold[1]! : text);
  const sentence = base.split(/(?<=[.!?])\s/)[0] ?? base;
  return sentence.length > 140 ? `${sentence.slice(0, 137)}…` : sentence;
}

/**
 * The D/R/P/Q/G registry in `docs/product/business-map.md` as records. The first line that
 * starts with an id defines it (table row or list item); later mentions are references. Struck
 * ids (`~~Q-001~~`) and "Resolved by" are resolved; "supersedes / replaces D-0xx" in a later
 * decision marks that one superseded. Unreadable definition lines are returned in `unparsed`.
 */
export function parseBusinessMap(markdown: string, path: string, commit: string) {
  const lines = markdown.replace(/\r\n?/g, '\n').split('\n');
  const records = new Map<string, ProductDecisionRecord>();
  const unparsed: number[] = [];
  let headingDate: string | null = null;
  lines.forEach((line, index) => {
    const h = line.match(/^#{1,6}\s+(.*)$/);
    if (h) {
      headingDate = h[1]!.match(/(20\d\d-\d\d-\d\d)/)?.[1] ?? null;
      return;
    }
    // "G-001 loading states …; G-020 care note entry; G-021 …": one line defining many ids.
    if (/^[DRPQG]-\d{3}\s/.test(line) && /;\s*[DRPQG]-\d{3}\s/.test(line)) {
      for (const seg of line.split(/;\s*(?=[DRPQG]-\d{3}\s)/)) define(seg, index);
      return;
    }
    define(line, index);
  });
  function define(line: string, index: number) {
    const m = line.match(defLine);
    if (!m) return;
    const id = m[3]!;
    if (records.has(id)) return;
    const struck = !!(m[1] || m[2] || m[4]);
    let text: string;
    let resolves: string[] = [];
    if (line.trimStart().startsWith('|')) {
      const cells = line.split('|').slice(1, -1);
      text = cells[1] ?? '';
      if (id.startsWith('D-')) resolves = extractIds(cells[2] ?? '').filter((x) => x !== id);
    } else {
      text = line.slice(m[0].length);
    }
    if (!text.trim()) {
      unparsed.push(index + 1);
      return;
    }
    const kind = id[0] as DecisionKind;
    const date = text.match(/(20\d\d-\d\d-\d\d)/)?.[1] ?? (kind === 'D' ? headingDate : null);
    const full = cleanMd(text);
    let status: DecisionStatus =
      kind === 'D' ? 'approved' : kind === 'R' || kind === 'P' ? 'recorded' : 'open';
    if (struck || /resolved by/i.test(full)) status = 'resolved';
    records.set(id, {
      id,
      kind,
      title: titleOf(text),
      text: full.length > 4000 ? `${full.slice(0, 3999)}…` : full,
      date,
      status,
      resolves,
      supersedes: [...full.matchAll(/(?:supersed(?:es|ing)|replaces?)\s+((?:[DRP]-\d{3}[,\s/and]*)+)/gi)]
        .flatMap((x) => extractIds(x[1]!))
        .filter((x) => x !== id),
      features: [],
      source: { path, line: index + 1, commit },
    });
  }
  for (const r of records.values()) {
    for (const q of r.resolves) {
      const target = records.get(q);
      if (target && (target.kind === 'Q' || target.kind === 'P' || target.kind === 'G')) {
        target.status = 'resolved';
      }
    }
    for (const s of r.supersedes) {
      const target = records.get(s);
      if (target && target.kind === 'D') target.status = 'superseded';
    }
  }
  return { records: [...records.values()], unparsed };
}

// ---------- Code facts ----------

export interface RepoFile {
  path: string;
  blobSha: string;
  /** Text content; only read for Markdown, registry globs and the functions index. */
  text?: string;
}

/** Callable names per handler file, from the imports and export blocks of the functions index. */
export function callablesByFile(indexSource: string): Map<string, string[]> {
  const local = new Map<string, string>();
  for (const m of indexSource.matchAll(/import\s*\{([^}]*)\}\s*from\s*'\.\/([^']+)\.js'/g)) {
    const file = `firebase/functions/src/${m[2]}.ts`;
    for (const part of m[1]!.split(',')) {
      const name = part.trim().replace(/^type\s+/, '');
      if (!name) continue;
      const as = name.split(/\s+as\s+/);
      local.set((as[1] ?? as[0])!.trim(), file);
    }
  }
  const out = new Map<string, string[]>();
  const blocks = indexSource.split(/\n(?=export const )/);
  for (const b of blocks) {
    const name = b.match(/^export const (\w+)\s*=/)?.[1];
    if (!name) continue;
    const files = new Set<string>();
    for (const tok of b.match(/\b[A-Za-z_]\w*\b/g) ?? []) {
      const f = local.get(tok);
      if (f) files.add(f);
    }
    for (const f of files) out.set(f, [...(out.get(f) ?? []), name]);
  }
  return out;
}

/** Decision ids cited in code comments, with "path:line". */
export function codeCitations(files: Array<{ path: string; text: string }>, max = 60) {
  const out: Array<{ id: string; at: string }> = [];
  const seen = new Set<string>();
  for (const f of files) {
    f.text.split('\n').forEach((line, i) => {
      if (!/\/\/|\/\*|\*|#/.test(line)) return;
      for (const id of line.match(/\b[DRP]-\d{3}\b/g) ?? []) {
        if (seen.has(id) || out.length >= max) continue;
        seen.add(id);
        out.push({ id, at: `${f.path}:${i + 1}` });
      }
    });
  }
  return out;
}

export function featureFacts(
  feature: RegistryFeature,
  files: readonly string[],
  readText: (path: string) => string | undefined,
  callables: Map<string, string[]>,
): FeatureFacts {
  const modules = matchGlobs(files, feature.modules);
  const functions = matchGlobs(files, feature.functions);
  const tests = matchGlobs(files, feature.tests);
  const docs = matchGlobs(files, feature.docs);
  const codeFiles = [...modules.files, ...functions.files]
    .filter((p) => /\.(dart|ts|tsx|swift|kt)$/.test(p))
    .slice(0, 120)
    .map((p) => ({ path: p, text: readText(p) ?? '' }));
  const cites = codeCitations(codeFiles);
  const cap = (xs: string[], n = 80) => xs.slice(0, n);
  return {
    modules: cap(modules.files),
    functions: cap(functions.files),
    callables: [...new Set(functions.files.flatMap((f) => callables.get(f) ?? []))].sort(),
    tests: cap(tests.files),
    docs: cap(docs.files),
    figma: feature.figma,
    decisions: [...new Set([...feature.decisions, ...cites.map((c) => c.id)])].sort(),
    codeCitations: cites,
    deadGlobs: [...modules.dead, ...functions.dead, ...tests.dead, ...docs.dead],
  };
}

// ---------- Conflicts (deterministic, doc 06 §2.7) ----------

// Beta before Free: "Beta miễn phí" is a free beta, not a Free tier.
const tierWords: Array<[RegExp, 'free' | 'premium' | 'beta']> = [
  [/\bpremium\b/, 'premium'],
  [/\bbeta\b/, 'beta'],
  [/\b(free|mien phi)\b/, 'free'],
];

export function conflictId(parts: string[]): string {
  return `cf_${sha256(parts.join('|')).slice(0, 16)}`;
}

/**
 * Tier claims: a line in a feature's own documents that says "<alias> is / là / : Premium | Free
 * | Beta" while the code's default tier says otherwise. Plan model: a document naming plans the
 * code does not have ("Free / Plus / Pro") while the code's tiers are Free · Premium · Beta.
 */
export function detectConflicts(
  registry: ProductRegistry,
  sources: Array<{ source: ProductSourceRecord; chunks: ProductChunk[] }>,
): ProductConflictRecord[] {
  const out = new Map<string, ProductConflictRecord>();
  const tiersPath = 'packages/contracts/src/features-hub.ts';
  for (const { source, chunks } of sources) {
    // Product Hub's own documents describe these conflicts; they do not make them.
    if (source.authority === 'approved_decision' || source.path.startsWith('docs/product-hub/')) continue;
    for (const c of chunks) {
      // Paragraph by paragraph: one that also names Premium compares the models, and one that
      // says "not / backlog / deferred" rejects them; neither proposes other plans.
      const line = [c.headingPath.join(' › '), ...c.text.split(/\n\s*\n/)]
        .map((p) => p.replace(/\s*\n\s*/g, ' '))
        .find(
          (p) =>
            /\bfree\s*\/\s*plus\b|\bplus\s*\/\s*pro\b/i.test(p) &&
            !/premium/i.test(p) &&
            !/\b(không|chưa|backlog|tạm hoãn|deferred|not)\b/i.test(p),
        );
      if (line) {
        const id = conflictId(['plan_model', source.path]);
        if (!out.has(id)) {
          out.set(id, {
            id,
            topic: 'plan_model',
            feature: null,
            summary: `${source.path} names plans (Free / Plus / Pro) that the code does not have (Free · Premium · Beta).`,
            tiers: null,
            claims: [
              {
                path: source.path,
                anchor: c.anchor,
                authority: source.authority,
                text: line.trim().slice(0, 400),
                date: source.docDate,
              },
              {
                path: tiersPath,
                anchor: 'featureTiers',
                authority: 'code',
                text: "featureTiers = ['free', 'premium', 'beta']",
                date: null,
              },
            ],
            status: 'open',
          });
        }
      }
    }
  }
  for (const f of registry.features) {
    if (!f.hubKey) continue;
    const codeTier = catalogueFeature(f.hubKey).defaultTier;
    const names = [f.name.vi, f.name.en, ...f.aliases].filter(Boolean).map(fold);
    for (const { source, chunks } of sources) {
      if (!source.features.includes(f.id) || source.authority === 'approved_decision') continue;
      for (const c of chunks) {
        for (const raw of c.text.split('\n')) {
          const l = fold(raw);
          const name = names.find((n) => n.length >= 3 && l.includes(n));
          if (!name) continue;
          const after = l.slice(l.indexOf(name) + name.length, l.indexOf(name) + name.length + 50);
          if (!/^\W{0,3}(\s(la|is|are|stays|=)\s|\s?[:=—-]\s)/.test(after)) continue;
          const claimed = tierWords.find(([re]) => re.test(after))?.[1];
          if (!claimed || claimed === codeTier) continue;
          const id = conflictId(['tier', f.id, source.path, c.anchor]);
          out.set(id, {
            id,
            topic: 'tier',
            feature: f.id,
            summary: `${source.path} says ${f.name.en || f.name.vi} is ${claimed}; the default tier in code is ${codeTier}.`,
            tiers: { claimed, code: codeTier },
            claims: [
              {
                path: source.path,
                anchor: c.anchor,
                authority: source.authority,
                text: raw.trim().slice(0, 400),
                date: source.docDate,
              },
              {
                path: tiersPath,
                anchor: f.hubKey,
                authority: 'code',
                text: `featureCatalogue: ${f.hubKey} → defaultTier '${codeTier}' (live tier in config/features may differ)`,
                date: null,
              },
            ],
            status: 'open',
          });
        }
      }
    }
  }
  return [...out.values()].sort((a, b) => a.id.localeCompare(b.id));
}

// ---------- Snapshot → change set ----------

export const journeyRegistryPath = 'docs/product-hub/registry/journeys.json';

/** Problems with a cited source against the snapshot: missing file or missing heading. */
export function sourceProblem(src: string, files: Map<string, RepoFile>, ids: Set<string>): string | null {
  if (/^[DRPQG]-\d{3}$/.test(src)) return ids.size === 0 || ids.has(src) ? null : `${src} is not in the business map`;
  const m = src.match(/^([^#:]+)(?:#(.+)|:(\d+))?$/);
  if (!m) return `${src} is not a path, path#anchor, path:line or id`;
  const file = files.get(m[1]!);
  if (!file) return `${m[1]} does not exist`;
  if (m[2] && file.text !== undefined) {
    const anchors = new Set(chunkMarkdown(file.text).map((c) => c.anchor));
    for (const h of file.text.matchAll(/^#{1,6}\s+(.+?)\s*#*\s*$/gm)) anchors.add(anchorOf(h[1]!.replace(/[*_`]/g, '')));
    if (!anchors.has(m[2])) return `${src}: no heading with that anchor`;
  }
  return null;
}

export const metricRegistryPath = 'docs/product-hub/registry/metrics.json';
export const metricDictionaryPath = 'docs/product-analytics/02-metric-dictionary.md';

/** Rows of the metric dictionary: id, name, numerator, denominator, source and plan word. */
export function parseMetricDictionary(markdown: string) {
  const out: Array<Pick<ProductMetricRecord, 'id' | 'name' | 'section' | 'numerator' | 'denominator' | 'source' | 'planStatus'>> = [];
  let section = '';
  for (const line of markdown.replace(/\r\n?/g, '\n').split('\n')) {
    const h = line.match(/^##\s+(.+)$/);
    if (h) {
      section = h[1]!.trim();
      continue;
    }
    const m = line.match(/^\|\s*([ACEFM]\d{2})\s+([^|]+)\|/);
    if (!m) continue;
    const cells = line.split('|').slice(1, -1).map((c) => c.trim());
    const plan = cells.map((c) => c.match(/\b(existing|extend|new)\b\s*$/)?.[1]).find(Boolean);
    const source = cells.find((c) => /\b(existing|extend|new)\b\s*$/.test(c)) ?? cells[5] ?? '';
    out.push({
      id: m[1]!,
      name: m[2]!.trim(),
      section,
      numerator: (cells[1] ?? '').slice(0, 600),
      denominator: (cells[2] ?? '').slice(0, 400),
      source: source.slice(0, 400),
      planStatus: (plan as ProductMetricRecord['planStatus']) ?? 'unknown',
    });
  }
  return out;
}

/** What the reducer's answers say about one dictionary metric (see `metricInstrumentations`). */
export function instrumentationOf(reducerIds: string[], probe: Record<string, string>): MetricInstrumentation {
  const reasons = reducerIds.map((id) => probe[id]).filter((r): r is string => !!r);
  if (!reasons.length) return 'defined_only';
  const missing = reasons.filter((r) => r.endsWith('/not_instrumented') || r.endsWith('/no_source')).length;
  if (missing === reasons.length && reasons.every((r) => r.endsWith('/no_source'))) return 'no_source';
  if (missing === reasons.length) return 'not_instrumented';
  if (missing > 0 || reasons.length < reducerIds.length) return 'partial';
  return 'computed';
}

export interface AppliedState {
  sources: Array<Pick<ProductSourceRecord, 'id' | 'path' | 'contentHash' | 'blobSha' | 'status' | 'authority' | 'features'>>;
  /** id → hash of the stored record (see `recordHash`). */
  decisions: Record<string, string>;
  features: Record<string, string>;
  conflicts: string[];
  /** id → hash; absent in states recorded before journeys existed. */
  journeys?: Record<string, string>;
  metrics?: Record<string, string>;
}

export const emptyState: AppliedState = { sources: [], decisions: {}, features: {}, conflicts: [], journeys: {}, metrics: {} };

/**
 * A stable hash of what a record says, to tell "changed" from "unchanged": time stamps, the
 * revision, stored bookkeeping (`hash`, `removed`) and a decision's line number are left out, so a
 * row inserted above it in the business map does not mark every decision below as changed.
 */
export function recordHash(record: object): string {
  const rest: Record<string, unknown> = { ...(record as Record<string, unknown>) };
  for (const k of ['syncedAt', 'revision', 'hash', 'removed', 'removedAt', 'changeSet']) delete rest[k];
  const src = rest.source as Record<string, unknown> | undefined;
  const cleaned = src ? { ...rest, source: { ...src, commit: undefined, line: undefined } } : rest;
  return sha256(JSON.stringify(cleaned, Object.keys(flatKeys(cleaned)).sort()));
}
function flatKeys(o: unknown, acc: Record<string, true> = {}): Record<string, true> {
  if (o && typeof o === 'object') {
    for (const [k, v] of Object.entries(o)) {
      acc[k] = true;
      flatKeys(v, acc);
    }
  }
  return acc;
}

export const sourceIdOf = (path: string) => `src_${sha256(`repo:${path}`).slice(0, 16)}`;

export interface Snapshot {
  revision: string;
  files: RepoFile[];
  registry: ProductRegistry;
  config?: SyncConfig;
  now: Date;
  /** The analytics reducer run with no data, id → "status/reason" (from the sync script). */
  metricProbe?: Record<string, string>;
}

export interface ChangeSetDraft {
  revision: string;
  items: ChangeItem[];
  summary: ChangeSetSummary;
}

/** Everything the sync would change against the applied state; unchanged files produce nothing. */
export function buildChangeSet(snapshot: Snapshot, state: AppliedState): ChangeSetDraft {
  const config = snapshot.config ?? defaultSyncConfig;
  const warnings: string[] = [];
  const allPaths = snapshot.files.map((f) => f.path);
  const byPath = new Map(snapshot.files.map((f) => [f.path, f]));
  const readText = (p: string) => byPath.get(p)?.text;
  const syncedAt = snapshot.now.toISOString();
  const indexSource = readText('firebase/functions/src/index.ts') ?? '';
  const callables = callablesByFile(indexSource);

  // Features first: their doc globs decide which features a source documents.
  const featureRecords: ProductFeatureRecord[] = snapshot.registry.features.map((f) => {
    const facts = featureFacts(f, allPaths, readText, callables);
    if (facts.deadGlobs.length) warnings.push(`${f.id}: no file matches ${facts.deadGlobs.join(', ')}`);
    const meta: Record<string, unknown> = { ...f };
    for (const k of ['modules', 'functions', 'tests', 'docs', 'figma', 'decisions']) delete meta[k];
    return { ...(meta as Omit<ProductFeatureRecord, 'facts' | 'revision' | 'syncedAt'>), facts, revision: snapshot.revision, syncedAt };
  });
  const featuresOfDoc = new Map<string, string[]>();
  for (const f of featureRecords) {
    for (const d of f.facts.docs) featuresOfDoc.set(d, [...(featuresOfDoc.get(d) ?? []), f.id]);
  }

  const selected = selectFiles(allPaths, config);
  const fresh: Array<{ source: ProductSourceRecord; chunks: ProductChunk[] }> = [];
  for (const path of selected) {
    const file = byPath.get(path)!;
    const raw = file.text ?? '';
    if (looksSecret(raw)) {
      warnings.push(`${path}: refused, looks like it holds a credential`);
      continue;
    }
    const text = normalizeText(raw);
    const tooBig = bytes(text) > config.sizeLimitKb * 1024;
    if (tooBig) warnings.push(`${path}: over ${config.sizeLimitKb} KB, headings only`);
    const contentHash = sha256(text);
    const prior = state.sources.find((s) => s.path === path && s.status === 'active');
    const id = prior?.id ?? sourceIdOf(path);
    const raws = tooBig
      ? chunkMarkdown(
          text
            .split('\n')
            .filter((l) => /^#{1,6}\s/.test(l))
            .join('\n\n'),
        )
      : chunkMarkdown(text);
    const version = contentHash.slice(0, 12);
    const chunks: ProductChunk[] = raws.map((c, i) => ({
      id: `${id}_${sha256(`${i}|${c.headingPath.join('>')}|${c.text}`).slice(0, 12)}`,
      sourceId: id,
      version,
      headingPath: c.headingPath,
      anchor: c.anchor,
      text: c.text,
      lang: detectLang(c.text),
      ids: extractIds(c.text),
    }));
    const headings = [...new Set(raws.map((c) => c.headingPath.join(' › ')).filter(Boolean))];
    fresh.push({
      source: {
        id,
        kind: 'repo_md',
        path,
        title:
          text.match(/^#\s+(.+)$/m)?.[1]?.replace(/[*_`]/g, '').trim() ??
          path.split('/').pop()!.replace(/\.md$/, ''),
        authority: prior?.authority ?? authorityFor(path),
        contentHash,
        blobSha: file.blobSha,
        commit: snapshot.revision,
        docDate: docDateOf(path, text),
        headings: headings.slice(0, 200),
        features: (featuresOfDoc.get(path) ?? []).slice(0, 30),
        decisions: extractIds(text)
          .filter((x) => /^[DRPQG]-/.test(x))
          .slice(0, 50),
        bytes: bytes(text),
        chunkCount: chunks.length,
        status: 'active',
      },
      chunks,
    });
  }

  const items: ChangeItem[] = [];
  let unchanged = 0;
  const freshPaths = new Set(fresh.map((f) => f.source.path));
  const active = state.sources.filter((s) => s.status === 'active');
  const gone = active.filter((s) => !freshPaths.has(s.path));
  const movedFrom = new Map<string, (typeof gone)[number]>();
  for (const f of fresh) {
    const prior = active.find((s) => s.path === f.source.path);
    if (prior) {
      const featuresChanged = prior.features.join() !== f.source.features.join();
      if (prior.contentHash === f.source.contentHash && !featuresChanged) {
        unchanged++;
        continue;
      }
      items.push({
        type: 'source',
        change: 'changed',
        source: f.source,
        before: { path: prior.path, contentHash: prior.contentHash },
        chunks: f.chunks,
      });
      continue;
    }
    const was = gone.find((g) => g.blobSha === f.source.blobSha && !movedFrom.has(g.id));
    if (was) {
      movedFrom.set(was.id, was);
      const source = { ...f.source, id: was.id, authority: was.authority };
      items.push({
        type: 'source',
        change: 'moved',
        source,
        before: { path: was.path, contentHash: was.contentHash },
        chunks: f.chunks.map((c) => ({ ...c, id: c.id.replace(f.source.id, was.id), sourceId: was.id })),
      });
      continue;
    }
    items.push({ type: 'source', change: 'added', source: f.source, before: null, chunks: f.chunks });
  }
  for (const g of gone) {
    if (movedFrom.has(g.id)) continue;
    items.push({
      type: 'source',
      change: 'deleted',
      source: {
        id: g.id,
        kind: 'repo_md',
        path: g.path,
        title: g.path.split('/').pop()!,
        authority: g.authority,
        contentHash: g.contentHash,
        blobSha: g.blobSha,
        commit: snapshot.revision,
        docDate: null,
        headings: [],
        features: [],
        decisions: [],
        bytes: 0,
        chunkCount: 0,
        status: 'deleted',
      },
      before: { path: g.path, contentHash: g.contentHash },
      chunks: [],
    });
  }

  // Decisions from the business map (when it is in the snapshot).
  const mapPath = 'docs/product/business-map.md';
  const map = readText(mapPath);
  if (map !== undefined) {
    const { records, unparsed } = parseBusinessMap(map, mapPath, snapshot.revision);
    if (unparsed.length) warnings.push(`${mapPath}: ${unparsed.length} id lines unread (lines ${unparsed.slice(0, 10).join(', ')})`);
    for (const r of records) {
      r.features = featureRecords.filter((f) => f.facts.decisions.includes(r.id)).map((f) => f.id);
    }
    const seen = new Set<string>();
    for (const r of records) {
      seen.add(r.id);
      const h = recordHash(r);
      if (state.decisions[r.id] === h) {
        unchanged++;
        continue;
      }
      items.push({ type: 'decision', change: state.decisions[r.id] ? 'changed' : 'added', decision: r });
    }
    for (const id of Object.keys(state.decisions)) {
      if (seen.has(id)) continue;
      items.push({
        type: 'decision',
        change: 'deleted',
        decision: {
          id,
          kind: id[0] as DecisionKind,
          title: id,
          text: '',
          date: null,
          status: 'recorded',
          resolves: [],
          supersedes: [],
          features: [],
          source: { path: mapPath, line: 0, commit: snapshot.revision },
        },
      });
    }
  }

  const registryIds = new Set(featureRecords.map((f) => f.id));
  for (const f of featureRecords) {
    const h = recordHash(f);
    if (state.features[f.id] === h) {
      unchanged++;
      continue;
    }
    items.push({ type: 'feature', change: state.features[f.id] ? 'changed' : 'added', feature: f });
  }
  for (const id of Object.keys(state.features)) {
    if (registryIds.has(id)) continue;
    const meta = { id } as ProductFeatureRecord;
    items.push({ type: 'feature', change: 'deleted', feature: meta });
  }

  // Journeys (Phase 3): reviewed like features; every step's feature and every source is checked.
  const journeyFile = readText(journeyRegistryPath);
  if (journeyFile !== undefined) {
    const parsed = journeyRegistrySchema.safeParse(JSON.parse(journeyFile));
    if (!parsed.success) warnings.push(`${journeyRegistryPath}: not valid (${parsed.error.issues[0]?.message ?? 'schema'}); journeys skipped`);
    else {
      const decisionIds = new Set(
        items.flatMap((i) => (i.type === 'decision' ? [i.decision.id] : [])).concat(Object.keys(state.decisions)),
      );
      const seen = new Set<string>();
      for (const j of parsed.data.journeys) {
        seen.add(j.id);
        const features = [...new Set(j.steps.flatMap((st) => (st.feature ? [st.feature] : [])))].sort();
        for (const f of features) if (!registryIds.has(f)) warnings.push(`journey ${j.id}: unknown feature ${f}`);
        for (const src of j.sources) {
          const problem = sourceProblem(src, byPath, decisionIds);
          if (problem) warnings.push(`journey ${j.id}: ${problem}`);
        }
        const record: ProductJourneyRecord = { ...j, features, revision: snapshot.revision, syncedAt };
        const h = recordHash(record);
        if (state.journeys?.[j.id] === h) {
          unchanged++;
          continue;
        }
        items.push({ type: 'journey', change: state.journeys?.[j.id] ? 'changed' : 'added', journey: record });
      }
      for (const id of Object.keys(state.journeys ?? {})) {
        if (!seen.has(id)) items.push({ type: 'journey', change: 'deleted', journey: { id } as ProductJourneyRecord });
      }
    }
  }

  // Metrics (Phase 4, before launch): the dictionary, the reviewed mapping and the code probe.
  const dictionary = readText(metricDictionaryPath);
  const mappingFile = readText(metricRegistryPath);
  if (dictionary !== undefined && snapshot.metricProbe) {
    const mapping = mappingFile ? metricRegistrySchema.safeParse(JSON.parse(mappingFile)) : null;
    if (mapping && !mapping.success) warnings.push(`${metricRegistryPath}: not valid; metrics without mapping`);
    const byId = new Map((mapping?.success ? mapping.data.metrics : []).map((x) => [x.id, x]));
    const rows = parseMetricDictionary(dictionary);
    const seen = new Set<string>();
    for (const id of byId.keys()) if (!rows.some((r) => r.id === id)) warnings.push(`${metricRegistryPath}: ${id} is not in the dictionary`);
    for (const r of rows) {
      seen.add(r.id);
      const map = byId.get(r.id);
      const reducerIds = map?.reducerIds ?? [];
      for (const rid of reducerIds) if (!(rid in snapshot.metricProbe)) warnings.push(`metric ${r.id}: the reducer has no ${rid}`);
      for (const f of map?.features ?? []) if (!registryIds.has(f)) warnings.push(`metric ${r.id}: unknown feature ${f}`);
      const record: ProductMetricRecord = {
        ...r,
        instrumentation: instrumentationOf(reducerIds, snapshot.metricProbe),
        probe: Object.fromEntries(reducerIds.filter((x) => x in snapshot.metricProbe!).map((x) => [x, snapshot.metricProbe![x]!])),
        reducerIds,
        features: map?.features ?? [],
        note: map?.note ?? '',
        revision: snapshot.revision,
        syncedAt,
      };
      const h = recordHash(record);
      if (state.metrics?.[r.id] === h) {
        unchanged++;
        continue;
      }
      items.push({ type: 'metric', change: state.metrics?.[r.id] ? 'changed' : 'added', metric: record });
    }
    for (const id of Object.keys(state.metrics ?? {})) {
      if (!seen.has(id)) items.push({ type: 'metric', change: 'deleted', metric: { id } as ProductMetricRecord });
    }
  }

  const known = new Set(state.conflicts);
  for (const c of detectConflicts(snapshot.registry, fresh)) {
    if (!known.has(c.id)) items.push({ type: 'conflict', change: 'added', conflict: c });
  }

  const count = (k: string) => items.filter((i) => i.change === k).length;
  return {
    revision: snapshot.revision,
    items,
    summary: {
      added: count('added'),
      changed: count('changed'),
      moved: count('moved'),
      deleted: count('deleted'),
      unchanged,
      warnings,
    },
  };
}
