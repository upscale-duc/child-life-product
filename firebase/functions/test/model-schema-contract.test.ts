import { describe, expect, it } from 'vitest';
import type { z } from 'zod';
import { assistantReadTools, draftKinds, understandingSchema } from '@child-life/contracts';
import { parseUnderstanding, understandingJsonSchema } from '../src/assistant-model.js';
import {
  imageJsonSchema,
  imageReadingSchema,
  parseImageReading,
} from '../src/assistant-image-model.js';

/**
 * The model answers in strict JSON mode, so any reply its JSON schema allows can arrive. The
 * scripted fakes always fill every field, which hid that the server's zod schemas refused
 * shapes the JSON schema permits (an expense without a time line: every one VALIDATION_FAILED).
 * This walks each JSON schema — every anyOf branch, enum value, null and array length — with
 * the values the prompt asks for in formatted strings (dates, clocks, currency), and checks the
 * server accepts what it asked for.
 */
type Json = Record<string, unknown>;

function rng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 2 ** 32;
  };
}

/** Strings the prompts ask in a fixed format; anything else is free text. */
function stringFor(key: string, max: number, r: () => number): string {
  if (/^(date|documentDate|anchorDate)$/.test(key)) return '2026-10-22';
  if (/^(time|endTime|hhmm|at)$/.test(key)) return r() < 0.5 ? '08:30' : '23:05';
  if (key === 'currency') return 'VND';
  const words = ['x', 'bỉm', 'Mua bỉm hết 150k'];
  return words[Math.floor(r() * words.length)]!.slice(0, max);
}

function sample(schema: Json, r: () => number, root: Json, key = ''): unknown {
  const pick = <T>(xs: readonly T[]): T => xs[Math.floor(r() * xs.length)]!;
  if (typeof schema.$ref === 'string') {
    const name = schema.$ref.replace('#/$defs/', '');
    return sample((root.$defs as Record<string, Json>)[name]!, r, root, key);
  }
  if (Array.isArray(schema.anyOf)) return sample(pick(schema.anyOf as Json[]), r, root, key);
  if (Array.isArray(schema.enum)) return pick(schema.enum as unknown[]);
  if ('const' in schema) return schema.const;
  const type = Array.isArray(schema.type) ? pick(schema.type as string[]) : schema.type;
  switch (type) {
    case 'null':
      return null;
    case 'boolean':
      return r() < 0.5;
    case 'integer':
    case 'number': {
      if (key === 'weekday') return Math.floor(r() * 7);
      // Unbounded in the JSON schema: the small values a real reply carries (0.9, -1, 3).
      if (schema.minimum === undefined && schema.maximum === undefined) {
        return pick(type === 'integer' ? [0, 1, 3] : [0, 0.5, 0.9, 1]);
      }
      const min = (schema.minimum as number | undefined) ?? 0;
      const max = (schema.maximum as number | undefined) ?? Math.max(min, 120);
      const n = pick([min, max, min + (max - min) / 2]);
      return type === 'integer' ? Math.round(n) : n;
    }
    case 'string':
      return stringFor(key, (schema.maxLength as number | undefined) ?? 200, r);
    case 'array': {
      const min = (schema.minItems as number | undefined) ?? 0;
      const max = Math.min((schema.maxItems as number | undefined) ?? 3, 3);
      const n = min + Math.floor(r() * (max - min + 1));
      return Array.from({ length: n }, () => sample(schema.items as Json, r, root, key));
    }
    case 'object': {
      const props = (schema.properties ?? {}) as Record<string, Json>;
      const required = new Set((schema.required ?? []) as string[]);
      const out: Json = {};
      for (const [k, v] of Object.entries(props)) {
        if (required.has(k) || r() < 0.5) out[k] = sample(v, r, root, k);
      }
      return out;
    }
    default:
      throw new Error(`unhandled JSON schema: ${JSON.stringify(schema).slice(0, 120)}`);
  }
}

/** Each field the server refuses (path with indexes folded, zod code), with one example. */
function refusals(
  schema: Json,
  parse: (raw: unknown) => { ok: boolean },
  explain: z.ZodType,
  prepare: (raw: unknown) => unknown = (raw) => raw,
  runs = 4000,
): Record<string, string> {
  const r = rng(20261022);
  const seen: Record<string, string> = {};
  for (let i = 0; i < runs; i++) {
    const raw = sample(schema, r, schema);
    if (parse(raw).ok) continue;
    const issues = explain.safeParse(prepare(raw)).error?.issues ?? [];
    if (issues.length === 0) seen['refused (no zod detail)'] ??= JSON.stringify(raw).slice(0, 300);
    for (const x of issues) {
      const key = `${x.path.map((p) => (typeof p === 'number' ? '#' : String(p))).join('.')}:${x.code}`;
      seen[key] ??= JSON.stringify(raw).slice(0, 300);
    }
  }
  return seen;
}

const kinds = [...draftKinds];
const reads = [...assistantReadTools];

describe('model JSON schemas and the server parsers agree', () => {
  it('Lumi understanding (v9): every reply the schema allows parses', () => {
    expect(
      refusals(
        understandingJsonSchema(kinds, reads, ['c_other']),
        parseUnderstanding,
        understandingSchema,
      ),
    ).toEqual({});
  });
  it('Lumi image reading: every reply the schema allows parses', () => {
    expect(refusals(imageJsonSchema(), parseImageReading, imageReadingSchema)).toEqual({});
  });
});
