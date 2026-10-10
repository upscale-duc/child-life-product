import { describe, expect, it } from 'vitest';
import {
  batchReadyToNotify,
  createMemoryRequestSchema,
  effectiveAudience,
  sniffMedia,
  updateMediaRequestSchema,
} from '../src/index.js';

const hex = (c: string) => c.repeat(32);
const photo = (n: string, overrides: Record<string, unknown> = {}) => ({
  mediaId: `med_${hex(n)}`,
  type: 'photo',
  contentType: 'image/jpeg',
  sizeBytes: 2_100_000,
  captureAt: '2026-10-05T02:20:00.000Z',
  durationMs: null,
  width: 3024,
  height: 4032,
  hasPoster: false,
  ...overrides,
});
const request = (overrides: Record<string, unknown> = {}) => ({
  babyId: 'b_1',
  memoryId: `mem_${hex('a')}`,
  batchId: `bat_${hex('b')}`,
  caption: 'Teddy cười khi nghe ba hát.',
  audience: 'family',
  notifyFamily: true,
  dateMode: 'capture',
  date: null,
  milestone: { id: 'p_first_smile', name: 'Lần đầu cười', date: '2026-10-05' },
  items: [photo('1')],
  ...overrides,
});

describe('memories (S9)', () => {
  it('accepts 10h compose and a text-only note', () => {
    expect(createMemoryRequestSchema.parse(request()).items).toHaveLength(1);
    expect(createMemoryRequestSchema.safeParse(request({ items: [] })).success).toBe(true);
    expect(createMemoryRequestSchema.safeParse(request({ items: [], caption: null })).success).toBe(
      false,
    );
  });

  it('caps a batch at 30 items and refuses duplicates and mismatched types', () => {
    const many = Array.from({ length: 31 }, (_, i) =>
      photo('0', { mediaId: `med_${i.toString(16).padStart(32, '0')}` }),
    );
    expect(createMemoryRequestSchema.safeParse(request({ items: many })).success).toBe(false);
    expect(
      createMemoryRequestSchema.safeParse(request({ items: [photo('1'), photo('1')] })).success,
    ).toBe(false);
    expect(
      createMemoryRequestSchema.safeParse(
        request({ items: [photo('1', { contentType: 'video/mp4' })] }),
      ).success,
    ).toBe(false);
    expect(
      createMemoryRequestSchema.safeParse(
        request({
          items: [
            photo('1', {
              type: 'video',
              contentType: 'video/quicktime',
              sizeBytes: 48_000_000,
              durationMs: 24_000,
              hasPoster: true,
            }),
          ],
        }),
      ).success,
    ).toBe(true);
  });

  it('single date mode needs a date', () => {
    expect(createMemoryRequestSchema.safeParse(request({ dateMode: 'single' })).success).toBe(
      false,
    );
    expect(
      createMemoryRequestSchema.safeParse(request({ dateMode: 'single', date: '2026-10-08' }))
        .success,
    ).toBe(true);
  });

  it('batch actions', () => {
    expect(
      updateMediaRequestSchema.safeParse({
        babyId: 'b_1',
        mediaIds: [`med_${hex('1')}`],
        change: { kind: 'audience', audience: 'family', notifyFamily: true },
      }).success,
    ).toBe(true);
    expect(
      updateMediaRequestSchema.safeParse({
        babyId: 'b_1',
        mediaIds: [`med_${hex('1')}`],
        change: { kind: 'rename' },
      }).success,
    ).toBe(false);
  });

  it('effective audience: the most permissive wins (D-002)', () => {
    expect(effectiveAudience('parents')).toBe('parents');
    expect(effectiveAudience('parents', ['parents', 'family'])).toBe('family');
    expect(effectiveAudience('family', [])).toBe('family');
  });

  it('notifies once all items are terminal, or only Wi-Fi waits remain (P-030, Q-019)', () => {
    const r = (status: 'uploading' | 'ready' | 'unreadable' | 'cancelled', wifi = false) => ({
      status,
      waitingWifi: wifi,
    });
    expect(batchReadyToNotify([r('ready'), r('uploading')])).toBe(false);
    expect(batchReadyToNotify([r('ready'), r('unreadable')])).toBe(true);
    expect(batchReadyToNotify([r('ready'), r('uploading', true)])).toBe(true);
    expect(batchReadyToNotify([r('uploading', true)])).toBe(false);
    expect(batchReadyToNotify([r('cancelled'), r('unreadable')])).toBe(false);
    expect(batchReadyToNotify([])).toBe(true);
  });

  it('sniffs real content, not the declared type', () => {
    expect(sniffMedia(new Uint8Array([0xff, 0xd8, 0xff, 0xe0]))).toBe('jpeg');
    const mov = new TextEncoder().encode('\0\0\0\x14ftypqt  ');
    expect(sniffMedia(mov)).toBe('quicktime');
    const mp4 = new TextEncoder().encode('\0\0\0\x18ftypisom');
    expect(sniffMedia(mp4)).toBe('mp4');
    expect(sniffMedia(new TextEncoder().encode('<!doctype html>'))).toBeNull();
  });
});
