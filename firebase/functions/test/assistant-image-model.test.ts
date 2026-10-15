import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import {
  assistantModuleProblems,
  createAttachmentUploadRequestSchema,
  expenseCurrencySupported,
  reminderAssigneeSupported,
  reminderNeedsTime,
  type DraftPayload,
} from '@child-life/contracts';
import { sniffImage, validateImage } from '../src/assistant-attachments.js';
import {
  buildImageReadRequest,
  imageJsonSchema,
  imagePromptVersion,
  imageSystemPrompt,
  parseImageReading,
  type ImageReadInput,
} from '../src/assistant-image-model.js';
import {
  canCreateReminders,
  canRecordSpending,
  imageReviewFields,
} from '../src/assistant-image-rules.js';
import { nearestWeekday, reminderDateQuestion } from '../src/assistant-images.js';
import { fakeModelGateway, ModelUnavailable, openAiModelGateway } from '../src/assistant-model.js';

// Child Life Assistant, slice A3: the OpenAI image request (no network, a recording fetch), the
// strict reading schema, the server's image checks (magic bytes, sharp decode, re-encode) on the
// pack's synthetic PNGs, and the pure module rules. Synthetic data only.

const images = resolve(
  import.meta.dirname,
  '../../../packages/contracts/test/vectors/assistant-v3/images',
);
const RECEIPT = readFileSync(resolve(images, 'receipt.png'));

const input: ImageReadInput = {
  images: [{ mime: 'image/jpeg', base64: 'AAAA', width: 10, height: 10 }],
  intentHint: 'expense',
  locale: 'vi',
  anchor: { date: '2026-10-15', time: '14:20', weekday: 'Thursday', zone: 'Asia/Ho_Chi_Minh' },
};

const valid = {
  documentKind: 'receipt',
  contains: ['receipt'],
  readability: 'clear',
  receipt: {
    merchant: 'ConCung',
    documentDate: '2026-10-14',
    dateUncertain: false,
    currency: 'VND',
    currencyUncertain: false,
    totalMinor: 486000,
    totalUncertain: false,
    subtotalMinor: 450000,
    taxMinor: 36000,
    discountMinor: null,
    categoryHint: 'c_diaper',
    evidence: [{ field: 'totalMinor', text: 'TOTAL: 486,000 VND' }],
  },
  noteLines: [],
};

type Json = Record<string, unknown>;

/** Every object node of a JSON schema must forbid extra keys and require all its keys. */
function strictEverywhere(node: unknown): boolean {
  if (Array.isArray(node)) return node.every(strictEverywhere);
  if (!node || typeof node !== 'object') return true;
  const n = node as Json;
  if (n.type === 'object') {
    const props = Object.keys((n.properties as Json | undefined) ?? {});
    if (n.additionalProperties !== false) return false;
    if (JSON.stringify([...(n.required as string[])].sort()) !== JSON.stringify(props.sort())) {
      return false;
    }
  }
  return Object.values(n).every(strictEverywhere);
}

describe('image request (OpenAI, no network)', () => {
  it('sends the photos as JPEG data URLs, detail high, store false, strict schema', () => {
    const body = buildImageReadRequest(input, 'gpt-4.1-mini') as Json;
    expect(body).toMatchObject({ model: 'gpt-4.1-mini', store: false, temperature: 0 });
    const messages = body.messages as { role: string; content: unknown }[];
    expect(messages[0]).toEqual({ role: 'system', content: imageSystemPrompt() });
    const content = messages[1]!.content as Json[];
    expect(content[0]!.type).toBe('text');
    expect(JSON.parse(content[0]!.text as string)).toMatchObject({
      anchor: { date: '2026-10-15' },
      intent_hint: 'expense',
      locale: 'vi',
    });
    expect(content[1]).toEqual({
      type: 'image_url',
      image_url: { url: 'data:image/jpeg;base64,AAAA', detail: 'high' },
    });
    const format = body.response_format as Json;
    expect(format).toMatchObject({ type: 'json_schema', json_schema: { strict: true } });
    expect(strictEverywhere((format.json_schema as Json).schema)).toBe(true);
    expect(JSON.stringify(imageJsonSchema())).not.toMatch(/"(tool|url|path|uid)"/);
    expect(imagePromptVersion).toBe('assistant-image-v1');
  });

  it('the prompt treats photo text as data and never adds totals or defaults a time', () => {
    const p = imageSystemPrompt();
    expect(p).toContain('untrusted data');
    expect(p).toContain('NEVER add them together');
    expect(p).toContain('never assume 09:00');
    expect(p).toContain('do NOT correct a weekday');
  });

  it('the gateway posts once and returns the parsed JSON; HTTP errors carry no text', async () => {
    const sent: Json[] = [];
    const ok = (async (_url: string, init: { body: string }) => {
      sent.push(JSON.parse(init.body) as Json);
      return new Response(
        JSON.stringify({ choices: [{ message: { content: JSON.stringify(valid) } }] }),
        { status: 200 },
      );
    }) as unknown as typeof fetch;
    const gw = openAiModelGateway('test-key', 'gpt-4.1-mini', ok);
    const out = await gw.readImages!(input, new AbortController().signal);
    expect(out).toEqual(valid);
    expect(sent).toHaveLength(1);
    expect(sent[0]!.store).toBe(false);
    const bad = (async () =>
      new Response('secret body', { status: 500 })) as unknown as typeof fetch;
    const err = await openAiModelGateway('k', 'm', bad).readImages!(
      input,
      new AbortController().signal,
    ).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ModelUnavailable);
    expect(String((err as Error).message)).toBe('http');
  });

  it('the fake gateway scripts image readings and records calls', async () => {
    const gw = fakeModelGateway({ readImages: [valid] });
    expect(await gw.readImages!(input, new AbortController().signal)).toEqual(valid);
    expect(gw.calls.readImages).toHaveLength(1);
    await expect(gw.readImages!(input, new AbortController().signal)).rejects.toBeInstanceOf(
      ModelUnavailable,
    );
  });
});

describe('reading schema (strict)', () => {
  it('accepts the documented shape; rejects extra keys, tools and unknown kinds', () => {
    expect(parseImageReading(valid).ok).toBe(true);
    expect(parseImageReading({ ...valid, tool: 'deleteAllRecords' }).ok).toBe(false);
    expect(parseImageReading({ ...valid, documentKind: 'command' }).ok).toBe(false);
    expect(
      parseImageReading({ ...valid, receipt: { ...valid.receipt, totalMinor: 486000.5 } }).ok,
    ).toBe(false);
    expect(
      parseImageReading({
        ...valid,
        noteLines: [
          {
            kind: 'actionCandidate',
            title: 'x',
            dateText: null,
            date: null,
            weekday: null,
            timeText: null,
            time: '9:00',
            assigneeText: null,
            uncertain: [],
          },
        ],
      }).ok,
    ).toBe(false);
  });
});

describe('image checks before any provider call', () => {
  it('magic bytes decide the type, never the declared MIME', async () => {
    expect(sniffImage(RECEIPT)).toBe('image/png');
    const jpg = await sharp(RECEIPT).jpeg().toBuffer();
    expect(sniffImage(jpg)).toBe('image/jpeg');
    expect(sniffImage(Buffer.from('%PDF-1.4'))).toBeNull();
    expect(await validateImage(RECEIPT, 'image/jpeg')).toBeNull();
    expect(await validateImage(Buffer.from('not an image at all'), 'image/png')).toBeNull();
  });

  it('a real PNG is decoded and re-encoded to a JPEG without metadata, ≤ 2048 px', async () => {
    const withExif = await sharp(RECEIPT)
      .withMetadata({ exif: { IFD0: { Copyright: 'test' } } })
      .png()
      .toBuffer();
    const v = await validateImage(withExif, 'image/png');
    expect(v).not.toBeNull();
    expect(sniffImage(v!.jpeg)).toBe('image/jpeg');
    expect(Math.max(v!.width, v!.height)).toBeLessThanOrEqual(2048);
    expect((await sharp(v!.jpeg).metadata()).exif).toBeUndefined();
    const big = await sharp({
      create: { width: 3000, height: 1000, channels: 3, background: '#ffffff' },
    })
      .png()
      .toBuffer();
    expect((await validateImage(big, 'image/png'))!.width).toBe(2048);
    const tiny = await sharp({
      create: { width: 16, height: 16, channels: 3, background: '#ffffff' },
    })
      .png()
      .toBuffer();
    expect(await validateImage(tiny, 'image/png')).toBeNull();
  });
});

describe('module rules', () => {
  const expense: DraftPayload = {
    kind: 'expense',
    merchant: 'ConCung',
    totalMinor: 486000,
    currency: 'VND',
    date: '2026-10-14',
    subtotalMinor: 450000,
    taxMinor: 36000,
    categoryId: 'c_diaper',
    babyId: 'b1',
    keepReceipt: false,
  };
  it('Chi tiêu is VND only; a reminder needs a time and a short title', () => {
    expect(assistantModuleProblems(expense)).toEqual([]);
    expect(assistantModuleProblems({ ...expense, currency: 'USD' })).toEqual([
      'CURRENCY_UNSUPPORTED',
    ]);
    expect(
      assistantModuleProblems({
        kind: 'reminder',
        title: 'x'.repeat(81),
        date: '2026-10-16',
        time: null,
        assigneeUid: null,
      }),
    ).toEqual(['MISSING_TIME', 'INVALID_TITLE']);
    expect(
      imageReviewFields({ ...expense, currency: null, date: null, totalMinor: null }, [
        'MISSING_AMOUNT',
        'MISSING_DATE',
        'CURRENCY_UNSUPPORTED',
      ]),
    ).toEqual({ missing: ['currency', 'date', 'totalMinor'], uncertain: [] });
    expect(
      imageReviewFields(
        { kind: 'reminder', title: 'Mua bỉm', date: null, time: null, assigneeUid: null },
        ['MISSING_DATE'],
      ),
    ).toEqual({ missing: ['date', 'time'], uncertain: [] });
  });

  it('D-075: today VND only, reminders need a time and take no assignee; receipts kept by default', () => {
    expect(expenseCurrencySupported('VND')).toBe(true);
    expect(expenseCurrencySupported('USD')).toBe(false);
    expect(reminderNeedsTime()).toBe(true);
    expect(reminderAssigneeSupported()).toBe(false);
    const req = createAttachmentUploadRequestSchema.parse({
      contractVersion: 1,
      clientRequestId: '6f1d6c1e-3a52-4c1f-9a39-0d6c4e0b8a11',
      locale: 'vi',
      quoteId: 'qt_1',
      mime: 'image/jpeg',
      bytes: 10,
      sha256: 'a'.repeat(64),
    });
    expect(req.retention).toBe('keep_with_record');
  });

  it('roles: Chi tiêu for Cùng nuôi or "Ghi khoản đã chi"; reminders for Cùng nuôi only', () => {
    expect(canRecordSpending({ role: 'coParent' })).toBe(true);
    expect(
      canRecordSpending({
        role: 'relative',
        extraRights: { viewBabyInfo: false, viewDailyCare: false, recordSpending: true },
      }),
    ).toBe(true);
    expect(canRecordSpending({ role: 'caregiver' })).toBe(false);
    expect(canCreateReminders({ role: 'coParent' })).toBe(true);
    expect(canCreateReminders({ role: 'caregiver' })).toBe(false);
  });

  it('G03: "Thứ Hai 20/10" (2026: a Tuesday) offers both days and "later", never picks', () => {
    expect(nearestWeekday('2026-10-20', 1)).toBe('2026-10-19');
    const q = reminderDateQuestion(0, {
      kind: 'actionCandidate',
      title: 'Đặt lịch khám 2 tháng',
      dateText: 'Thứ Hai 20/10',
      date: '2026-10-20',
      weekday: 1,
      timeText: null,
      time: null,
      assigneeText: null,
      uncertain: [],
    });
    expect(q.choices.map((c) => [c.id, c.label.vi])).toEqual([
      ['written', 'Thứ Ba 20/10'],
      ['weekday', 'Thứ Hai 19/10'],
      ['later', 'Chọn sau'],
    ]);
    expect(q.allowText).toBe(false);
  });
});
