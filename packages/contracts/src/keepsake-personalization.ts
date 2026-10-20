import { z } from 'zod';

const key = z.string().regex(/^[a-z][a-zA-Z0-9]{0,31}$/);
const copy = z.object({ vi: z.string().max(600), en: z.string().max(600) });

/** Premium collection. Declarative content only; never executable portal JSON. */
export const keepsakePersonalizationSchema = z
  .object({
    group: copy,
    dateRange: z.object({ start: key, end: key }).optional(),
    fields: z
      .array(
        z.object({
          key,
          label: copy,
          suggestion: copy.optional(),
          type: z.enum(['text', 'date', 'time', 'confirmation', 'month']),
          source: z.enum(['babyName', 'birthDate', 'momentDate']).optional(),
          max: z.number().int().min(1).max(160),
          required: z.boolean().default(false),
        }),
      )
      .min(1)
      .max(12),
    copy: z
      .array(
        z.object({
          key,
          label: copy,
          text: copy,
          requires: z.array(key).max(6).default([]),
          fallback: copy.default({ vi: '', en: '' }),
          editable: z.boolean().default(false),
          max: z.number().int().min(1).max(160).default(160),
        }),
      )
      .min(1)
      .max(24),
    /** Story beats reference explicitly selected input slots; reprise is intentional. */
    beats: z
      .array(
        z.object({
          slots: z.array(z.number().int().min(0).max(29)).min(1).max(5),
          textKey: key,
        }),
      )
      .max(12)
      .default([]),
  })
  .superRefine((p, ctx) => {
    const fields = new Set(p.fields.map((f) => f.key));
    const known = (k: string) =>
      fields.has(k) || (['elapsedDays', 'elapsedUnit'].includes(k) && !!p.dateRange);
    if (fields.has('elapsedDays') || fields.has('elapsedUnit'))
      ctx.addIssue({ code: 'custom', message: 'reserved derived date key' });
    if (
      p.dateRange &&
      [p.dateRange.start, p.dateRange.end].some(
        (k) => !p.fields.some((f) => f.key === k && f.type === 'date'),
      )
    )
      ctx.addIssue({ code: 'custom', message: 'date range requires two date fields' });
    const copies = new Set(p.copy.map((c) => c.key));
    if (fields.size !== p.fields.length || copies.size !== p.copy.length)
      ctx.addIssue({ code: 'custom', message: 'duplicate personalization key' });
    for (const c of p.copy) {
      for (const required of c.requires)
        if (!known(required)) ctx.addIssue({ code: 'custom', message: 'unknown required field' });
      for (const text of [c.text.vi, c.text.en, c.fallback.vi, c.fallback.en])
        for (const [, token] of text.matchAll(/\{([^}]+)\}/g))
          if (!known(token!)) ctx.addIssue({ code: 'custom', message: 'unknown copy token' });
    }
    for (const b of p.beats)
      if (!copies.has(b.textKey)) ctx.addIssue({ code: 'custom', message: 'unknown beat text' });
  });
export type KeepsakePersonalization = z.infer<typeof keepsakePersonalizationSchema>;

export const keepsakeCropSchema = z
  .object({
    x: z.number().min(-1).max(1),
    y: z.number().min(-1).max(1),
    zoom: z.number().min(1).max(2),
    fit: z.enum(['cover', 'contain']).optional(),
  })
  .strict();
export type KeepsakeCrop = z.infer<typeof keepsakeCropSchema>;

export const keepsakePresentationRequestSchema = z
  .object({
    values: z.record(key, z.string().max(160)),
    overrides: z.record(key, z.string().max(160)),
    crops: z.array(keepsakeCropSchema).max(12),
    format: z.enum(['portrait', 'story']),
    reducedMotion: z.boolean(),
  })
  .strict();
export type KeepsakePresentationRequest = z.infer<typeof keepsakePresentationRequestSchema>;
export interface KeepsakePresentation {
  copy: Record<string, string>;
  beats: KeepsakePersonalization['beats'];
  crops: KeepsakeCrop[];
  format: 'portrait' | 'story';
  reducedMotion: boolean;
}

/** Both locale copies are authored in the catalog. ISO dates are never guessed from uploads. */
export function resolveKeepsakeCopy(
  spec: KeepsakePersonalization,
  values: Record<string, string>,
  locale: 'vi' | 'en',
  overrides: Record<string, string> = {},
): Record<string, string> {
  const fields = new Map(spec.fields.map((f) => [f.key, f]));
  for (const [k, v] of Object.entries(values)) {
    const f = fields.get(k);
    if (!f || v.length > f.max) throw new Error('personalization-field');
    if (!v) continue;
    if (f.type === 'date' && !z.iso.date().safeParse(v).success)
      throw new Error('personalization-date');
    if (f.type === 'time' && !/^([01]\d|2[0-3]):[0-5]\d$/.test(v))
      throw new Error('personalization-time');
    if (f.type === 'month' && !/^(0?[1-9]|1[0-2])$/.test(v))
      throw new Error('personalization-month');
    if (f.type === 'confirmation' && v !== 'true' && v !== 'false')
      throw new Error('personalization-confirmation');
    if (/[{}]/.test(v)) throw new Error('personalization-token');
  }
  for (const f of spec.fields)
    if (f.required && !values[f.key]?.trim()) throw new Error('personalization-required');
  let elapsedDays = '';
  if (spec.dateRange) {
    const start = values[spec.dateRange.start],
      end = values[spec.dateRange.end];
    if (start && end) {
      const days = (Date.parse(`${end}T00:00:00Z`) - Date.parse(`${start}T00:00:00Z`)) / 86400000;
      if (days < 0) throw new Error('personalization-date-order');
      elapsedDays = String(days);
    }
  }
  const format = (k: string) => {
    if (k === 'elapsedDays') return elapsedDays;
    if (k === 'elapsedUnit')
      return elapsedDays ? (locale === 'vi' ? 'ngày' : elapsedDays === '1' ? 'day' : 'days') : '';
    const v = values[k]?.trim() ?? '';
    if (v && fields.get(k)?.type === 'month') return v.padStart(2, '0');
    if (!v || fields.get(k)?.type !== 'date') return v;
    return new Intl.DateTimeFormat(locale === 'vi' ? 'vi-VN' : 'en-GB', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(`${v}T12:00:00Z`));
  };
  for (const [k, v] of Object.entries(overrides)) {
    const c = spec.copy.find((c) => c.key === k);
    if (!c?.editable || v.length > c.max || /[{}]/.test(v)) throw new Error('personalization-copy');
  }
  return Object.fromEntries(
    spec.copy.map((c) => {
      const ready = c.requires.every((k) => {
        const v =
          k === 'elapsedDays' ? elapsedDays : k === 'elapsedUnit' ? format(k) : values[k]?.trim();
        return !!v && (fields.get(k)?.type !== 'confirmation' || v === 'true');
      });
      const text = overrides[c.key] ?? (ready ? c.text[locale] : c.fallback[locale]);
      const filled = text.replace(/\{([^}]+)\}/g, (_, k: string) => format(k));
      if (filled.length > c.max || /[{}]/.test(filled))
        throw new Error('personalization-copy-too-long');
      return [c.key, filled];
    }),
  );
}

export function freezeKeepsakePresentation(
  spec: KeepsakePersonalization,
  request: KeepsakePresentationRequest,
  locale: 'vi' | 'en',
): KeepsakePresentation {
  if (request.crops.length !== spec.beats.length) throw new Error('personalization-crops');
  return {
    copy: resolveKeepsakeCopy(spec, request.values, locale, request.overrides),
    beats: spec.beats,
    crops: request.crops,
    format: request.format,
    reducedMotion: request.reducedMotion,
  };
}
