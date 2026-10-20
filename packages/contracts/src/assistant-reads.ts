import { z } from 'zod';
import { foldVi } from './assistant-text.js';

/** Lumi Phase 2 (D-088 §5): scope and links always belong to the server, never the model. */
export const assistantReadTools = [
  'care_summary',
  'sleep_facts',
  'usage_snapshot',
  'day_overview',
  'diaper_summary',
  'pump_summary',
  'growth_snapshot',
  'running_timer',
  'vaccine_next',
  'reminders_today',
  'spending_month',
  'solids_history',
  'milestones',
  'stage',
  'library_search',
  'first_aid',
] as const;
export type AssistantReadTool = (typeof assistantReadTools)[number];
export interface AssistantReadRequest {
  tool: AssistantReadTool;
  dayOffset: number;
}

export const readCardSchema = z
  .object({
    type: z.literal('read_card'),
    schemaVersion: z.literal(1),
    tool: z.enum(assistantReadTools),
    title: z.string().min(1).max(160),
    asOf: z.iso.datetime(),
    rows: z
      .array(
        z
          .object({
            label: z.string().max(200),
            value: z.string().max(1600),
            link: z.string().max(300).optional(),
          })
          .strict(),
      )
      .max(24),
    caveat: z.string().max(1200).nullable(),
    action: z.object({ label: z.string().max(100), link: z.string().max(300) }).strict(),
    sourceIds: z.array(z.string().max(200)).max(200),
  })
  .strict();
export type AssistantReadCard = z.infer<typeof readCardSchema>;

/** Personal milestones have narrower access than the shared co-parent/caregiver chat. */
export const privateReadTool = (tool: AssistantReadTool) =>
  tool === 'spending_month' || tool === 'milestones';

/** Conservative whole-message read shortcut. Mixed writes fall through to understanding. */
export function assistantReadsIn(text: string): AssistantReadRequest[] {
  const t = foldVi(text)
    .replace(/[?!.,]+$/g, '')
    .trim();
  if (!t || t.length > 240) return [];
  const question =
    /\b(bao nhieu|bao lau|may|the nao|gi|chua|khong|nao|xem|tong|thong ke|what|how|which|show|any|next|bai|articles?)\b/u.test(
      t,
    ) || /[?？]/u.test(text);
  if (!question) return [];
  // A question beside a new log must not drop that log. Unit amounts and save instructions
  // belong to the model; age qualifiers ("bé 7 tháng") are allowed.
  if (
    /\b(ghi|luu|them|nhac toi|nhac minh|nhac mai|record|log|save|remind me)\b/u.test(t) ||
    /\d\s*(ml|kg|cm|oz|k|tr|vnd|usd)\b/u.test(t)
  )
    return [];
  if (/[;\n]/u.test(t) || /\b(vua|roi)\b.*\b(va|and)\b/u.test(t)) return [];
  const tool = (name: AssistantReadTool): AssistantReadRequest[] => [
    {
      tool: name,
      dayOffset: /\b(hom qua|yesterday)\b/u.test(t)
        ? -1
        : /\b(ngay mai|tomorrow)\b/u.test(t)
          ? 1
          : 0,
    },
  ];
  if (/\b(bai|bai viet|thu vien|article|articles|library|read about)\b/u.test(t))
    return tool('library_search');
  if (/\b(so cuu|first aid|sac|hoc|choking|nga|fell|fever|sot|burn|bong)\b/u.test(t))
    return tool('first_aid');
  const found: AssistantReadRequest[] = [];
  if (
    /\b(chi tieu|tieu bao nhieu|da chi|het bao nhieu|spend|spent|spending|expenses|budget|ngan sach)\b/u.test(
      t,
    )
  )
    found.push(...tool('spending_month'));
  if (/\b(tiem|vac xin|vaccine|vaccines|vaccination|immunisation|immunization)\b/u.test(t))
    found.push(...tool('vaccine_next'));
  if (/\b(nhac|nhac viec|reminder|reminders)\b/u.test(t)) found.push(...tool('reminders_today'));
  if (
    /\b(an thu|da an|tung an|thu nhung|phan ung|foods tried|tried foods|solids history|food reactions|allergens)\b/u.test(
      t,
    )
  )
    found.push(...tool('solids_history'));
  if (/\b(biet lam|moc|milestone|milestones|skills)\b/u.test(t)) found.push(...tool('milestones'));
  if (/\b(giai doan|nen lam|nen choi|thang nay be nen|stage|development stage)\b/u.test(t))
    found.push(...tool('stage'));
  if (
    /\b(nang|can nang|chieu dai|chieu cao|vong dau|tang truong|weight|weigh|height|growth|head circumference|percentile)\b/u.test(
      t,
    )
  )
    found.push(...tool('growth_snapshot'));
  if (/\b(bao lau roi|duoc bao lau|timer|running|how long.*sleep|how long.*nurs)\b/u.test(t))
    found.push(...tool('running_timer'));
  if (/\b(ta|bim|diaper|diapers|nappy|nappies)\b/u.test(t)) found.push(...tool('diaper_summary'));
  if (/\b(hut|vat sua|pump|pumped|pumping)\b/u.test(t)) found.push(...tool('pump_summary'));
  if (/\b(ngu|sleep)\b/u.test(t) && /\b(tuan|gan day|trend|week|less|it hon)\b/u.test(t))
    found.push(...tool('sleep_facts'));
  if (/\b(bu|cu|feeds|feed|fed|bottle|nursing|ngu|sleep)\b/u.test(t))
    found.push(...tool('care_summary'));
  if (
    /\b(hom nay be the nao|hom nay con the nao|tong ket hom nay|how is.*today|how.*baby.*today|day summary|daily summary)\b/u.test(
      t,
    )
  )
    return tool('day_overview');
  if (/\b(con bao nhieu luot|credits|credit balance)\b/u.test(t))
    found.push(...tool('usage_snapshot'));
  const filtered = found.filter(
    (r) =>
      r.tool !== 'care_summary' ||
      !found.some((other) => other.tool === 'running_timer' || other.tool === 'sleep_facts'),
  );
  return filtered.length <= 3 ? filtered : [];
}
