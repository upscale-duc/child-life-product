import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

// Cloud Storage Security Rules may read at most two Firestore documents per evaluation
// ("No more than two Firestore documents may be accessed in a single Rules evaluation").
// The emulator does not enforce it, so a third firestore.get() passes every emulator test and
// fails every real upload with a Rules ERROR — this static check keeps each `allow` within two.
const source = readFileSync(join(__dirname, '../storage.rules'), 'utf8');

/** Function name → body, for the rules' `function name(args) { ... }` declarations. */
function functions(src: string): Map<string, string> {
  const out = new Map<string, string>();
  const re = /function\s+(\w+)\s*\([^)]*\)\s*\{/g;
  for (let m = re.exec(src); m; m = re.exec(src)) {
    let depth = 1;
    let i = re.lastIndex;
    while (depth > 0 && i < src.length) {
      if (src[i] === '{') depth++;
      else if (src[i] === '}') depth--;
      i++;
    }
    out.set(m[1]!, src.slice(re.lastIndex, i - 1));
  }
  return out;
}

const fns = functions(source);

/** Firestore documents an expression reads: direct calls plus the functions it calls. */
function reads(expr: string, seen: string[] = []): number {
  let n = (expr.match(/firestore\.(get|exists)\(/g) ?? []).length;
  for (const [name, body] of fns) {
    if (seen.includes(name)) continue;
    const calls = (expr.match(new RegExp(`\\b${name}\\(`, 'g')) ?? []).length;
    if (calls) n += calls * reads(body, [...seen, name]);
  }
  return n;
}

describe('Storage Rules stay within two Firestore reads', () => {
  const allows = [...source.matchAll(/allow\s+[\w, ]+:\s*if\s+([\s\S]*?);/g)].map((m) => m[1]!);

  it('finds the rules that read Firestore', () => {
    expect(allows.length).toBeGreaterThan(3);
  });

  for (const [i, expr] of allows.entries()) {
    it(`allow #${i + 1} reads at most two documents`, () => {
      expect(reads(expr)).toBeLessThanOrEqual(2);
    });
  }
});
