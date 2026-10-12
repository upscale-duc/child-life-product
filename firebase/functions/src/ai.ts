import {
  aiDraftSchema,
  storyLimits,
  type AiDraft,
  type AssistOp,
  type StorySources,
} from '@child-life/contracts';

/**
 * Story AI behind one adapter (D-003): OpenAI first, server-side only, swappable. Only text goes
 * out — captions, notes, milestone, dates, counts, the nickname and relation labels; never photos
 * or real names (R-196, Q-036). Requests ask the provider not to store them. Without a key the
 * template provider writes a plain draft and rewrites are reported as unavailable (SP-4 fallback).
 */
export interface AiProvider {
  readonly name: 'openai' | 'template';
  draft(sources: StorySources): Promise<AiDraft>;
  /** Alternatives for one paragraph; [] when the provider cannot help. */
  assist(
    op: AssistOp,
    text: string,
    context: { nickname: string; locale: 'vi' | 'en' },
  ): Promise<string[]>;
}

export class AiUnavailable extends Error {}

const sentences = (s: string) =>
  s
    .split(/(?<=[.!?…])\s+/u)
    .map((x) => x.trim())
    .filter(Boolean);

const fmtDate = (iso: string, locale: 'vi' | 'en') => {
  const [, m, d] = iso.split('-').map(Number);
  return locale === 'vi'
    ? `${d} tháng ${m}`
    : `${new Date(iso).toLocaleString('en-GB', { month: 'short', timeZone: 'UTC' })} ${d}`;
};

/** A plain, factual draft built only from the sources (no model). */
export const templateProvider: AiProvider = {
  name: 'template',
  async draft(s) {
    const vi = s.locale === 'vi';
    const range = `${fmtDate(s.rangeStart, s.locale)} – ${fmtDate(s.rangeEnd, s.locale)}`;
    const title = s.milestone
      ? vi
        ? `Tuần ${s.nickname} ${s.milestone.name.toLocaleLowerCase('vi')}`
        : `${s.nickname}'s week: ${s.milestone.name}`
      : vi
        ? `Một tuần của ${s.nickname}`
        : `A week with ${s.nickname}`;
    const paragraphs: string[] = [];
    paragraphs.push(
      vi
        ? `Từ ${range}, cả nhà lưu lại ${s.photos} ảnh${s.videos ? ` và ${s.videos} video` : ''} của ${s.nickname}.`
        : `From ${range}, the family kept ${s.photos} photos${s.videos ? ` and ${s.videos} videos` : ''} of ${s.nickname}.`,
    );
    const notes = s.notes.filter((n) => n.text.trim().length > 0).slice(0, 4);
    if (notes.length)
      paragraphs.push(notes.map((n) => n.text.trim().replace(/\s+/g, ' ')).join(' '));
    if (s.milestone) {
      paragraphs.push(
        vi
          ? `${fmtDate(s.milestone.date, 'vi')} là ngày ${s.milestone.name.toLocaleLowerCase('vi')}.`
          : `${fmtDate(s.milestone.date, 'en')} was the day of “${s.milestone.name}”.`,
      );
    }
    return aiDraftSchema.parse({
      title: title.slice(0, storyLimits.titleMax),
      paragraphs: paragraphs.map((p) => p.slice(0, 600)),
      quote: null,
    });
  },
  async assist(op, text) {
    if (op !== 'shorter') return [];
    const first = sentences(text);
    return first.length > 1 ? [first.slice(0, Math.ceil(first.length / 2)).join(' ')] : [];
  },
};

const rules = (locale: 'vi' | 'en') =>
  locale === 'vi'
    ? [
        'Bạn giúp ba mẹ viết nhật ký ngắn về con, bằng tiếng Việt, giọng ấm áp, giản dị.',
        'Chỉ dùng sự kiện có trong ghi chép được cung cấp. Không bịa thêm sự kiện, người, nơi chốn, con số hay ngày tháng.',
        'Chỉ gọi bé bằng biệt danh. Chỉ nhắc người bằng vai trò có trong danh sách (Mẹ, Ba, Bà…).',
        'Không nói về sức khoẻ, bệnh, thuốc hay lời khuyên y tế.',
      ]
    : [
        'You help parents write a short, warm, plain journal entry about their baby, in English.',
        'Use only facts present in the notes provided. Never invent events, people, places, numbers or dates.',
        'Refer to the baby only by the nickname, and to people only by the listed role labels.',
        'Do not discuss health, illness, medicine or medical advice.',
      ];

const opText: Record<AssistOp, { vi: string; en: string }> = {
  rewrite: {
    vi: 'Viết lại đoạn này theo cách khác, giữ nguyên sự kiện.',
    en: 'Rewrite this paragraph differently, keeping the same facts.',
  },
  shorter: { vi: 'Viết ngắn hơn, giữ ý chính.', en: 'Make it shorter, keeping the main point.' },
  warmer: {
    vi: 'Viết ấm áp hơn, giữ nguyên sự kiện.',
    en: 'Make it warmer, keeping the same facts.',
  },
  suggest: {
    vi: 'Gợi ý một câu kết ngắn cho đoạn này, không thêm sự kiện.',
    en: 'Suggest one short closing sentence for this paragraph, adding no facts.',
  },
};

/** OpenAI chat completions with a JSON schema; `store: false` (no retention, R-196). */
export function openAiProvider(
  apiKey: string,
  model: string,
  fetchImpl: typeof fetch = fetch,
): AiProvider {
  async function call(
    system: string[],
    user: string,
    schema: Record<string, unknown>,
  ): Promise<unknown> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30_000);
    try {
      const res = await fetchImpl('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        signal: controller.signal,
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model,
          store: false,
          temperature: 0.6,
          max_completion_tokens: 900,
          messages: [
            { role: 'system', content: system.join('\n') },
            { role: 'user', content: user },
          ],
          response_format: {
            type: 'json_schema',
            json_schema: { name: 'out', strict: true, schema },
          },
        }),
      });
      if (!res.ok) throw new AiUnavailable(`openai ${res.status}`);
      const body = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
      const content = body.choices?.[0]?.message?.content;
      if (!content) throw new AiUnavailable('empty');
      return JSON.parse(content);
    } finally {
      clearTimeout(timer);
    }
  }

  return {
    name: 'openai',
    async draft(s) {
      const out = await call(
        rules(s.locale),
        JSON.stringify({
          task:
            s.locale === 'vi'
              ? 'Viết một câu chuyện ngắn (tiêu đề, 2–4 đoạn, một câu trích dẫn hoặc null) về tuần này.'
              : 'Write a short story (title, 2–4 paragraphs, one pull quote or null) about this week.',
          nickname: s.nickname,
          people: s.people,
          dates: { from: s.rangeStart, to: s.rangeEnd },
          counts: { photos: s.photos, videos: s.videos },
          milestone: s.milestone,
          notes: s.notes,
        }),
        {
          type: 'object',
          additionalProperties: false,
          required: ['title', 'paragraphs', 'quote'],
          properties: {
            title: { type: 'string' },
            paragraphs: { type: 'array', items: { type: 'string' } },
            quote: { type: ['string', 'null'] },
          },
        },
      );
      return aiDraftSchema.parse(out);
    },
    async assist(op, text, ctx) {
      const out = (await call(
        rules(ctx.locale),
        JSON.stringify({ task: opText[op][ctx.locale], nickname: ctx.nickname, paragraph: text }),
        {
          type: 'object',
          additionalProperties: false,
          required: ['options'],
          properties: { options: { type: 'array', items: { type: 'string' } } },
        },
      )) as { options?: unknown };
      return Array.isArray(out.options)
        ? out.options.filter((o): o is string => typeof o === 'string').slice(0, 3)
        : [];
    },
  };
}

// ---------- Nhập chi tiêu: rows from pasted text or photos (D-060, P-144) ----------

/** One spending row read by the model; the server reads it again like a file. */
export interface AiExpenseRow {
  date: string | null;
  amount: number | null;
  note: string;
  category: string;
  payer: string;
}

export interface ExpenseExtractInput {
  /** What was pasted, or photos (JPEG) of a notebook, a receipt list, a screenshot. */
  text?: string;
  images?: Buffer[];
  /** The baby's local day: dates without a year are in this year, never after it. */
  today: string;
  locale: 'vi' | 'en';
}

/**
 * Text or photos → spending rows (D-003 adapter, OpenAI first). Only what the person pasted or
 * photographed goes out, with today's date and the language; never the baby's name or any other
 * family data. The request asks the provider not to store it (`store: false`).
 */
export interface ExpenseExtractor {
  readonly name: 'openai';
  extractExpenses(input: ExpenseExtractInput): Promise<AiExpenseRow[]>;
}

const expenseRowsSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['rows'],
  properties: {
    rows: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['date', 'amount', 'note', 'category', 'payer'],
        properties: {
          date: { type: ['string', 'null'] },
          amount: { type: ['number', 'null'] },
          note: { type: 'string' },
          category: { type: 'string' },
          payer: { type: 'string' },
        },
      },
    },
  },
} as const;

const expenseRules = (today: string, locale: 'vi' | 'en') => [
  'You read a family’s spending notes (pasted text or photos of a notebook, receipts or a screenshot) and list each expense as one row.',
  `Today is ${today}. Dates are day first (12/10 = 12 October). A date without a year is in the year of today and never after today. Write dates as YYYY-MM-DD, or null when the row has no date.`,
  'Amounts are Vietnamese đồng (VND), whole numbers, positive. "k" or "nghìn" = thousand, "tr" or "triệu" = million, "1tr2" = 1 200 000. Use null when no amount is readable.',
  'note: what was bought, copied from the source in its own language, short. category: a category written in the source (for example "Sữa", "Tã", "Y tế"), else "". payer: who paid when written (for example "Mẹ", "Ba"), else "".',
  'Do not invent rows, dates or amounts. Skip totals, balances and income. Keep the order of the source.',
  locale === 'vi'
    ? 'The family writes mostly in Vietnamese.'
    : 'The family writes mostly in English.',
];

/** Rows from the model, checked; anything else is treated as a failed reading. */
function readExpenseRows(out: unknown, max: number): AiExpenseRow[] {
  const rows = (out as { rows?: unknown } | null)?.rows;
  if (!Array.isArray(rows)) throw new AiUnavailable('shape');
  const text = (v: unknown) => (typeof v === 'string' ? v.trim().slice(0, 300) : '');
  return rows.slice(0, max).map((r: Record<string, unknown>) => ({
    date: typeof r?.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(r.date) ? r.date : null,
    amount: typeof r?.amount === 'number' && Number.isFinite(r.amount) ? r.amount : null,
    note: text(r?.note),
    category: text(r?.category),
    payer: text(r?.payer),
  }));
}

/** OpenAI chat completions with a strict JSON schema, text and images, `store: false`. */
export function openAiExpenseExtractor(
  apiKey: string,
  model: string,
  fetchImpl: typeof fetch = fetch,
  maxRows = 5000,
): ExpenseExtractor {
  return {
    name: 'openai',
    async extractExpenses(input) {
      const content: Array<Record<string, unknown>> = [];
      if (input.text) content.push({ type: 'text', text: input.text });
      for (const image of input.images ?? []) {
        content.push({
          type: 'image_url',
          image_url: { url: `data:image/jpeg;base64,${image.toString('base64')}`, detail: 'high' },
        });
      }
      if (content.length === 0) return [];
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 150_000);
      try {
        const res = await fetchImpl('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          signal: controller.signal,
          headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model,
            store: false,
            temperature: 0,
            max_completion_tokens: 16_000,
            messages: [
              { role: 'system', content: expenseRules(input.today, input.locale).join('\n') },
              { role: 'user', content },
            ],
            response_format: {
              type: 'json_schema',
              json_schema: { name: 'expenses', strict: true, schema: expenseRowsSchema },
            },
          }),
        });
        if (!res.ok) throw new AiUnavailable(`openai ${res.status}`);
        const body = (await res.json()) as {
          choices?: Array<{ message?: { content?: string } }>;
        };
        const raw = body.choices?.[0]?.message?.content;
        if (!raw) throw new AiUnavailable('empty');
        let parsed: unknown;
        try {
          parsed = JSON.parse(raw);
        } catch {
          throw new AiUnavailable('json');
        }
        return readExpenseRows(parsed, maxRows);
      } catch (error) {
        if (error instanceof AiUnavailable) throw error;
        // Network errors and timeouts: never the request or the reply in the message.
        throw new AiUnavailable('request');
      } finally {
        clearTimeout(timer);
      }
    },
  };
}
