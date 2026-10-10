import { z } from 'zod';
import { babyIdSchema } from './baby.js';
import { storyIdSchema } from './stories.js';

/**
 * External sharing (Slice S13; Figma 14h–14n; business map R-160…R-166, P-095, P-096, G-052).
 * A private link shows a live projection of a saved story (P-095) on `/s/{token}-{slug}`; cards
 * are images made on the device and only listed ("không thu hồi được", R-162).
 */

/** "Hết hạn sau": 24 giờ / 7 ngày / 30 ngày (R-163). */
export const linkExpiries = { '24h': 24, '7d': 24 * 7, '30d': 24 * 30 } as const;
export type LinkExpiry = keyof typeof linkExpiries;

/** 5 wrong passcodes per 15 minutes per link and address (P-096). */
export const passcodeLimits = { attempts: 5, windowMinutes: 15 } as const;

/** Unguessable part of the URL (≈ 95 bits). */
export const linkTokenSchema = z.string().regex(/^[A-Za-z0-9]{16}$/);

export const createShareLinkSchema = z.object({
  requestId: z.uuid(),
  babyId: babyIdSchema,
  storyId: storyIdSchema,
  expiry: z.enum(['24h', '7d', '30d']),
  /** "Ẩn tên thật & ngày sinh" (default on). */
  hideIdentity: z.boolean(),
  /** "Cho tải ảnh về" (default off; R-166: viewing can never prevent screenshots). */
  allowDownload: z.boolean(),
  /** "Hỏi mật mã 4 số" (default off). */
  passcode: z.boolean(),
});
export type CreateShareLink = z.infer<typeof createShareLinkSchema>;

export const revokeShareLinkSchema = z.object({ token: linkTokenSchema });

export const cardTemplates = ['moment', 'three', 'four', 'letter', 'night'] as const;
export type CardTemplate = (typeof cardTemplates)[number];

/** "Thiệp ảnh đã lưu": the card is already on the recipient's side (R-162). */
export const recordCardSchema = z.object({
  requestId: z.uuid(),
  babyId: babyIdSchema,
  storyId: storyIdSchema,
  template: z.enum(cardTemplates),
});

/** "teddy" from "Teddy", "be-na" from "Bé Na" (URL tail only; the token is the key). */
export function slugOf(nickname: string): string {
  return (
    nickname
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .replace(/đ/g, 'd')
      .replace(/Đ/g, 'D')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 24) || 'be'
  );
}

/** "3 tuần tuổi" / "3 weeks old" (same units as the app's age label). */
export function ageLabel(dob: string, today: string, locale: 'vi' | 'en'): string {
  const [y1, m1, d1] = dob.split('-').map(Number) as [number, number, number];
  const [y2, m2, d2] = today.split('-').map(Number) as [number, number, number];
  const days = Math.floor((Date.UTC(y2, m2 - 1, d2) - Date.UTC(y1, m1 - 1, d1)) / 86_400_000);
  const vi = locale === 'vi';
  if (days <= 0) return vi ? 'mới chào đời' : 'newborn';
  if (days < 14) return vi ? `${days} ngày tuổi` : `${days} ${days === 1 ? 'day' : 'days'} old`;
  if (days < 91) {
    const w = Math.floor(days / 7);
    return vi ? `${w} tuần tuổi` : `${w} weeks old`;
  }
  let months = (y2 - y1) * 12 + m2 - m1;
  if (d2 < d1) months -= 1;
  if (months < 24) {
    const m = Math.max(3, months);
    return vi ? `${m} tháng tuổi` : `${m} months old`;
  }
  const years = Math.floor(months / 12);
  return vi ? `${years} tuổi` : `${years} years old`;
}
