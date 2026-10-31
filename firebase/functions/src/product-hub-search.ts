import type { CopilotBlockKind, CopilotCitation } from '@child-life/contracts';
import { fold } from './product-hub-ingest.js';

/**
 * Product Hub search (D-155, doc 06 §2.10): BM25 over approved knowledge, no embeddings. Pure —
 * the server builds the document list (chunks and decisions at approval time; feature records and
 * sections live), this module ranks it. Accent-folded so "hieu con" finds "Hiểu con"; decision ids
 * and feature ids are kept whole and an exact id match ranks first.
 */

export interface SearchDoc {
  id: string;
  kind: CopilotBlockKind;
  title: string;
  text: string;
  path: string | null;
  anchor: string | null;
  authority: CopilotCitation['authority'];
  status: CopilotCitation['status'];
  date: string | null;
  revision: string | null;
  features: string[];
  ids: string[];
}

const stopwords = new Set(
  (
    'the a an and or of to in on for is are be with as by at it this that what which how does do ' +
    'la va cua cho trong khi co khong duoc nhung cac mot nay nao gi the nhu de thi da se bi voi ve tu den'
  ).split(' '),
);

const idToken = /\b(?:[DRPQG]-\d{3}|(?:care|grow|remember|platform)\.[a-z][a-z0-9_]+)\b/gi;

/** Lowercase, accent-folded words (≥ 2 letters) plus whole ids ("d-150", "care.feeding"). */
export function tokenize(text: string): string[] {
  const ids = (text.match(idToken) ?? []).map((t) => t.toLowerCase());
  const words = fold(text)
    .split(/[^a-z0-9]+/)
    .filter((w) => w.length >= 2 && !stopwords.has(w));
  return [...words, ...ids];
}

const authorityWeight: Record<SearchDoc['authority'], number> = {
  verified_implementation: 1,
  approved_decision: 1,
  approved_section: 1,
  code: 1,
  approved_spec: 0.95,
  draft_spec: 0.8,
  design_reference: 0.65,
  research: 0.65,
  ai_inference: 0.45,
};

export interface SearchIndex {
  docs: SearchDoc[];
  tf: Array<Map<string, number>>;
  len: number[];
  df: Map<string, number>;
  avgdl: number;
}

export function buildIndex(docs: SearchDoc[]): SearchIndex {
  const tf: Array<Map<string, number>> = [];
  const len: number[] = [];
  const df = new Map<string, number>();
  for (const d of docs) {
    const m = new Map<string, number>();
    // The heading counts twice: a match in the title says more than one in the body.
    const tokens = [...tokenize(d.title), ...tokenize(d.title), ...tokenize(d.text), ...d.ids.map((x) => x.toLowerCase())];
    for (const t of tokens) m.set(t, (m.get(t) ?? 0) + 1);
    for (const t of m.keys()) df.set(t, (df.get(t) ?? 0) + 1);
    tf.push(m);
    len.push(tokens.length);
  }
  const avgdl = len.reduce((a, b) => a + b, 0) / Math.max(1, len.length);
  return { docs, tf, len, df, avgdl };
}

export interface SearchHit {
  doc: SearchDoc;
  score: number;
}

/**
 * Top `k` documents for the query. `feature` boosts (does not filter) documents linked to that
 * feature, so a feature question still finds the cross-feature rule it depends on.
 */
export function search(
  index: SearchIndex,
  query: string,
  options: { k?: number; feature?: string | undefined; kinds?: CopilotBlockKind[] } = {},
): SearchHit[] {
  const k = options.k ?? 8;
  const terms = [...new Set(tokenize(query))];
  if (!terms.length) return [];
  const queryIds = new Set((query.match(idToken) ?? []).map((t) => t.toLowerCase()));
  const N = index.docs.length;
  const k1 = 1.2;
  const b = 0.75;
  const hits: SearchHit[] = [];
  index.docs.forEach((doc, i) => {
    if (options.kinds && !options.kinds.includes(doc.kind)) return;
    const tf = index.tf[i]!;
    let score = 0;
    for (const t of terms) {
      const f = tf.get(t);
      if (!f) continue;
      const n = index.df.get(t) ?? 0;
      const idf = Math.log(1 + (N - n + 0.5) / (n + 0.5));
      score += (idf * (f * (k1 + 1))) / (f + k1 * (1 - b + (b * index.len[i]!) / index.avgdl));
    }
    if (score === 0) return;
    if (doc.ids.some((x) => queryIds.has(x.toLowerCase())) || queryIds.has(doc.id.toLowerCase())) score += 5;
    if (options.feature && doc.features.includes(options.feature)) score *= 1.6;
    score *= authorityWeight[doc.authority] ?? 0.6;
    if (doc.status === 'draft') score *= 0.85;
    hits.push({ doc, score });
  });
  hits.sort((a, b2) => b2.score - a.score || a.doc.id.localeCompare(b2.doc.id));
  return hits.slice(0, k);
}

/** A short excerpt around the first query term, for search results and citations. */
export function excerpt(text: string, query: string, max = 400): string {
  const clean = text.replace(/\s+/g, ' ').trim();
  if (clean.length <= max) return clean;
  const folded = fold(clean);
  const first = tokenize(query)
    .map((t) => folded.indexOf(t))
    .filter((i) => i >= 0)
    .sort((a, b) => a - b)[0];
  const start = Math.max(0, (first ?? 0) - Math.floor(max / 3));
  return `${start > 0 ? '…' : ''}${clean.slice(start, start + max)}${start + max < clean.length ? '…' : ''}`;
}
