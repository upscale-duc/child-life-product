import { describe, expect, it } from 'vitest';
import {
  canAdvancePrintOrder,
  initialPrintCatalog,
  printDesignSchema,
  printOrderRequestSchema,
  printPrice,
  printTotals,
} from '../src/print-studio.js';

export const design = printDesignSchema.parse({
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
describe('Print Studio commercial rules', () => {
  it('calculates the complete quote without any deposit or payment fields', () => {
    expect(printTotals(initialPrintCatalog, design, 1)).toEqual({
      subtotal: 349000,
      shipping: 30000,
      total: 379000,
    });
    expect(printTotals(initialPrintCatalog, design, 2)).toEqual({
      subtotal: 698000,
      shipping: 0,
      total: 698000,
    });
  });
  it('rejects nonexistent variants rather than charging a zero price', () => {
    expect(() => printPrice(initialPrintCatalog, { ...design, size: '20x20' })).toThrow(
      'variant-unavailable',
    );
    expect(() =>
      printPrice(initialPrintCatalog, { ...design, product: 'book', size: '15x15', pages: 40 }),
    ).toThrow();
  });
  it('requires staff confirmation and prevents cancelling production in progress', () => {
    expect(canAdvancePrintOrder('pendingConfirmation', 'printing')).toBe(false);
    expect(canAdvancePrintOrder('pendingConfirmation', 'confirmed')).toBe(true);
    expect(canAdvancePrintOrder('printing', 'cancelled')).toBe(false);
    expect(canAdvancePrintOrder('delivered', 'printing')).toBe(false);
  });
  it('requires an explicit approved snapshot and constrains quantity / shipping', () => {
    const req = {
      babyId: 'b1',
      requestId: 'bee22c12-5afd-4ebe-899d-a60671a6b025',
      catalogVersion: 1,
      design,
      quantity: 1,
      approved: true,
      address: {
        recipient: 'Mai',
        phone: '0905123456',
        address: '12 Nguyễn Văn Linh, Đà Nẵng',
        country: 'VN',
        neededBy: null,
        gift: false,
        giftMessage: '',
      },
    };
    expect(printOrderRequestSchema.safeParse(req).success).toBe(true);
    for (const patch of [
      { approved: false },
      { quantity: 0 },
      { quantity: 11 },
      { address: { ...req.address, phone: '123' } },
    ])
      expect(printOrderRequestSchema.safeParse({ ...req, ...patch }).success).toBe(false);
  });
});
