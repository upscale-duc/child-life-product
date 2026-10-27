import { z } from 'zod';

/** Print Studio (Figma 948:12443). Money is integer VND; public prices are never trusted. */
export const printProductSchema = z.enum(['single', 'trio', 'five', 'book']);
export const printSizeSchema = z.enum(['10x15', '13x18', '15x21', '15x15', '20x20']);
export const printStyleSchema = z.enum(['minimal', 'playful', 'timeless']);
const id = z.string().regex(/^[A-Za-z0-9_-]{1,100}$/);
const copy = z.string().trim().max(120);
export const printDesignSchema = z.object({
  product: printProductSchema,
  size: printSizeSchema,
  style: printStyleSchema,
  frame: z.enum(['white', 'wood', 'gift']),
  occasion: z.enum(['month', 'hundred', 'birthday', 'custom']),
  name: z.string().trim().min(1).max(40),
  title: copy,
  date: z.iso.date(),
  message: copy,
  birthDetails: z.string().max(100),
  showBirthDetails: z.boolean(),
  mediaIds: z.array(z.union([id, z.literal('')])).max(40),
  pageLayouts: z
    .array(z.enum(['portrait', 'collage', 'text']))
    .max(40)
    .default([]),
  // Firestore does not support arrays nested directly in arrays. Keep page keys stable.
  pagePhotos: z.preprocess(
    (value) =>
      Array.isArray(value)
        ? Object.fromEntries(value.map((slots, page) => [String(page), slots]))
        : value,
    z
      .record(
        z.string().regex(/^(?:[0-9]|[1-3][0-9])$/),
        z.array(z.number().int().min(0).max(39)).max(4),
      )
      .default({}),
  ),
  pageSubtitles: z.array(z.string().trim().max(100)).max(40).default([]),
  pageTitles: z.array(z.string().trim().max(80)).max(40).default([]),
  pages: z.union([z.literal(24), z.literal(40)]),
  locale: z.enum(['vi', 'en']),
});
export type PrintDesign = z.infer<typeof printDesignSchema>;
export const printCatalogSchema = z.object({
  version: z.number().int().positive(),
  digitalEnabled: z.boolean(),
  physicalEnabled: z.boolean(),
  supportedCountries: z.array(z.string().regex(/^[A-Z]{2}$/)),
  prices: z.record(z.string(), z.number().int().min(0).max(100_000_000)),
  giftWrapFee: z.number().int().nonnegative().default(30000),
  giftSurcharge: z.number().int().nonnegative(),
  shippingFee: z.number().int().nonnegative(),
  freeShippingFrom: z.number().int().nonnegative(),
  leadDays: z.number().int().min(1).max(60),
  pricesEstimated: z.boolean().default(true),
  orderProducts: z.array(printProductSchema).default(['single', 'trio', 'five', 'book']),
  policy: z.object({ vi: z.string().max(4000), en: z.string().max(4000) }),
});
export type PrintCatalog = z.infer<typeof printCatalogSchema>;
/** Preview-only seed. Fulfilment stays off until a real partner and prices are configured. */
export const initialPrintCatalog: PrintCatalog = {
  version: 1,
  digitalEnabled: true,
  physicalEnabled: false,
  supportedCountries: ['VN'],
  prices: {
    'single:10x15': 99000,
    'single:13x18': 129000,
    'single:15x21': 159000,
    'trio:10x15': 279000,
    'trio:13x18': 349000,
    'trio:15x21': 429000,
    'five:10x15': 449000,
    'five:13x18': 549000,
    'five:15x21': 649000,
    'book:15x15:24': 299000,
    'book:20x20:24': 499000,
    'book:20x20:40': 649000,
  },
  giftSurcharge: 60000,
  giftWrapFee: 30000,
  shippingFee: 30000,
  freeShippingFrom: 500000,
  leadDays: 7,
  pricesEstimated: true,
  orderProducts: ['single', 'trio', 'five', 'book'],
  policy: {
    vi: 'Giá dự kiến. Child Life sẽ liên hệ để xác nhận giá, ngày nhận và cách thanh toán trước khi in. Chưa cần thanh toán khi gửi đơn.',
    en: 'Estimated prices. Child Life will contact you to confirm the price, delivery date and payment arrangements before printing. No payment is required to submit an order.',
  },
};
export function printPrice(catalog: PrintCatalog, design: PrintDesign): number {
  const key = `${design.product}:${design.size}${design.product === 'book' ? `:${design.pages}` : ''}`;
  const price = catalog.prices[key];
  if (price === undefined) throw new Error('variant-unavailable');
  return price + (design.frame === 'gift' ? catalog.giftSurcharge : 0);
}
export function printTotals(
  catalog: PrintCatalog,
  design: PrintDesign,
  quantity: number,
  giftWrap = false,
) {
  const subtotal = printPrice(catalog, design) * quantity + (giftWrap ? catalog.giftWrapFee : 0);
  const shipping = subtotal >= catalog.freeShippingFrom ? 0 : catalog.shippingFee;
  const total = subtotal + shipping;
  return { subtotal, shipping, total };
}
export const printOrderStatuses = [
  'pendingConfirmation',
  'confirmed',
  'printing',
  'shipped',
  'delivered',
  'cancelled',
] as const;
export type PrintOrderStatus = (typeof printOrderStatuses)[number];
export function canAdvancePrintOrder(from: PrintOrderStatus, to: PrintOrderStatus): boolean {
  return (
    (
      {
        pendingConfirmation: ['confirmed', 'cancelled'],
        confirmed: ['printing', 'cancelled'],
        printing: ['shipped'],
        shipped: ['delivered'],
        delivered: [],
        cancelled: [],
      } as Record<string, string[]>
    )[from]?.includes(to) ?? false
  );
}
export const printAddressSchema = z.object({
  recipient: z.string().trim().min(2).max(80),
  phone: z.string().regex(/^(0|\+84)[35789]\d{8}$/),
  address: z.string().trim().min(10).max(400),
  country: z.string().regex(/^[A-Z]{2}$/),
  neededBy: z.iso.date().nullable(),
  gift: z.boolean(),
  giftMessage: z.string().trim().max(200),
});
export const printOrderRequestSchema = z.object({
  babyId: id,
  requestId: z.string().uuid(),
  catalogVersion: z.number().int(),
  design: printDesignSchema,
  quantity: z.number().int().min(1).max(10),
  address: printAddressSchema,
  approved: z.literal(true),
  paymentMethod: z.enum(['cod', 'bankTransfer']).default('cod'),
});
export const printExportRequestSchema = z.object({
  babyId: id,
  design: printDesignSchema,
  format: z.enum(['pdf', 'jpg', 'png']),
  cropMarks: z.boolean(),
  acknowledgeQuality: z.boolean(),
});

/**
 * PR-1 (D-127 Q8): the print file is built by a background job the parent can leave. The request
 * id makes a retried start return the same job.
 */
export const printExportJobRequestSchema = printExportRequestSchema.extend({
  requestId: z.string().uuid(),
});
export const printExportJobStatuses = ['queued', 'rendering', 'ready', 'failed'] as const;
export type PrintExportJobStatus = (typeof printExportJobStatuses)[number];

/** Older preview builds used a deposit state. It now means an unconfirmed order. */
export const normalizePrintStatus = (status: string): PrintOrderStatus =>
  status === 'awaitingDeposit' ? 'pendingConfirmation' : (status as PrintOrderStatus);
export const printCancellationReasons = [
  'customer_changed_mind',
  'price',
  'shipping_fee',
  'delivery_time',
  'design',
  'unreachable',
  'other',
] as const;
export const printRenderStatuses = ['queued', 'rendering', 'ready', 'failed', 'cancelled'] as const;
