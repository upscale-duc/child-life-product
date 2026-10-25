import { describe, expect, it } from 'vitest';
import sharp from 'sharp';
import { printDesignSchema } from '@child-life/contracts';
import {
  printDimensions,
  printPageCount,
  printPdf,
  printSlots,
  renderPrintPage,
} from '../src/print-render.js';

const design = printDesignSchema.parse({
  product: 'trio',
  size: '13x18',
  style: 'minimal',
  frame: 'white',
  occasion: 'hundred',
  name: 'Teddy',
  title: '100 ngày',
  date: '2026-11-25',
  message: 'Cảm ơn con',
  birthDetails: '17.08.2026',
  showBirthDetails: true,
  mediaIds: ['a', 'b', 'c', 'd', 'e'],
  pages: 24,
  locale: 'vi',
});
describe('print production renderer', () => {
  it('renders real 300-DPI trim + 3mm bleed, without depending on a mobile screenshot', async () => {
    const bytes = await sharp({
      create: { width: 2400, height: 3000, channels: 3, background: '#e9a23b' },
    })
      .jpeg()
      .toBuffer();
    const sources = Array.from({ length: 5 }, () => ({ bytes, width: 2400, height: 3000 }));
    for (const style of ['minimal', 'playful', 'timeless'] as const) {
      const png = await renderPrintPage({ ...design, style }, sources, 1, false);
      const meta = await sharp(png).metadata();
      expect(meta.width).toBe(Math.round((130 / 25.4) * 300) + 2 * Math.round((3 / 25.4) * 300));
      expect(meta.height).toBe(Math.round((180 / 25.4) * 300) + 2 * Math.round((3 / 25.4) * 300));
      expect(meta.density).toBe(300);
    }
    const png = await renderPrintPage(design, sources, 0, true),
      pdf = await printPdf([png], design, true);
    expect(pdf.subarray(0, 8).toString()).toBe('%PDF-1.4');
    expect(pdf.toString('latin1')).toContain('/TrimBox');
    expect(pdf.toString('latin1')).toContain('/Count 1');
  });
  it('renders edited square spreads, keeps page photo choices and supports text-only frames', async () => {
    const bytes = await sharp({
      create: { width: 640, height: 640, channels: 3, background: '#c49270' },
    })
      .jpeg()
      .toBuffer();
    const sources = [{ bytes, width: 640, height: 640 }];
    const book = printDesignSchema.parse({
      ...design,
      product: 'book',
      size: '15x15',
      mediaIds: ['a'],
      pageLayouts: ['portrait', 'text', 'collage'],
      pagePhotos: [[0], [], [0, 0, 0, 0]],
      pageTitles: ['100 ngày\nTeddy', 'Chào con', 'Nụ cười đầu tiên'],
      pageSubtitles: ['', 'Cả nhà thương con', '25.11.2026'],
    });
    expect(book.pagePhotos).toEqual({ '0': [0], '1': [], '2': [0, 0, 0, 0] });
    for (const page of [0, 1, 2]) {
      const png = await renderPrintPage(book, sources, page, false);
      const meta = await sharp(png).metadata();
      expect(meta.width).toBe(meta.height);
      expect(meta.density).toBe(300);
    }
    const info = printDesignSchema.parse({
      ...design,
      product: 'single',
      mediaIds: [],
      pageLayouts: ['text'],
      pagePhotos: [[]],
    });
    expect((await renderPrintPage(info, [], 0, false)).length).toBeGreaterThan(1000);
  });
  it('maps every photo slot, allows sparse books without inventing events', () => {
    expect(printSlots(design, 2)).toEqual([1, 2, 3, 4]);
    expect(printPageCount({ ...design, product: 'five' })).toBe(5);
    expect(printSlots({ ...design, product: 'five' }, 4)).toEqual([6]);
    expect(printSlots({ ...design, product: 'book', mediaIds: ['a'] }, 23)).toEqual([0]);
    expect(printDimensions['20x20']).toEqual([200, 200]);
  });
});
