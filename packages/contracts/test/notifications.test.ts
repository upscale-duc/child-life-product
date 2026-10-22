import { describe, expect, it } from 'vitest';
import {
  defaultNotificationSettings,
  inQuietHours,
  inboxIdSchema,
  inboxItemSchema,
  localClockIn,
  notificationCategoryOf,
  notificationKinds,
  notificationRouteOf,
  notificationSettingKeys,
  notificationSettingOf,
  notificationSettingsDocSchema,
  notificationSettingsOf,
  ringsInQuietHours,
} from '../src/index.js';

// Notification centre (D-076 #2): EN07 settings, quiet hours, the inbox row.
const vn = (h: number, m = 0) => new Date(Date.UTC(2026, 9, 15, h - 7, m)); // Asia/Ho_Chi_Minh is UTC+7

describe('notification settings (EN07)', () => {
  it('defaults: articles and family activity off, the rest on', () => {
    expect(notificationSettingsOf(null)).toEqual(defaultNotificationSettings);
    expect(defaultNotificationSettings.articles).toBe(false);
    expect(defaultNotificationSettings.familyActivity).toBe(false);
    expect(notificationSettingKeys.filter((k) => defaultNotificationSettings[k])).toHaveLength(13); // + familyMembers (G-109, D-092)
  });

  it('vaccines and spending follow the old "Nhắc việc" switch until set (G-056)', () => {
    const old = notificationSettingsOf({ reminders: false, memories: true });
    expect(old.vaccines).toBe(false);
    expect(old.spending).toBe(false);
    const set = notificationSettingsOf({ reminders: false, vaccines: true });
    expect(set.vaccines).toBe(true);
    expect(set.spending).toBe(false);
  });

  it('ignores non-bool values and unknown keys', () => {
    const s = notificationSettingsOf({ memories: 'no', other: false });
    expect(s.memories).toBe(true);
  });

  it('doc schema: bools only, no unknown keys', () => {
    expect(notificationSettingsDocSchema.safeParse({ rhythm: false }).success).toBe(true);
    expect(notificationSettingsDocSchema.safeParse({ rhythm: 'off' }).success).toBe(false);
    expect(notificationSettingsDocSchema.safeParse({ babyName: 'x' }).success).toBe(false);
  });
});

describe('kinds', () => {
  it('every kind has a category, a route and a switch entry', () => {
    for (const k of notificationKinds) {
      expect(notificationCategoryOf[k]).toBeDefined();
      expect(notificationRouteOf(k)).toBeTruthy();
      expect(k in notificationSettingOf).toBe(true);
    }
  });

  it('answers to the person’s own request are never silenced', () => {
    expect(notificationSettingOf.keepsakeVideo).toBeNull();
    expect(notificationSettingOf.storageGranted).toBeNull();
    expect(notificationSettingOf.vaccine).toBe('vaccines');
  });

  it('only reminders the person set ring in quiet hours', () => {
    expect(ringsInQuietHours('reminderRule')).toBe(true);
    expect(ringsInQuietHours('vaccine')).toBe(true);
    expect(ringsInQuietHours('spending')).toBe(false);
    expect(ringsInQuietHours('memories')).toBe(false);
  });
});

describe('quiet hours', () => {
  const zone = 'Asia/Ho_Chi_Minh';
  it('reads the local clock', () => {
    expect(localClockIn(zone, vn(22, 5))).toBe('22:05');
    expect(localClockIn(zone, vn(6, 0))).toBe('06:00');
  });

  it('wraps midnight', () => {
    const q = { from: '22:00', to: '06:00' };
    expect(inQuietHours(q, zone, vn(21, 59))).toBe(false);
    expect(inQuietHours(q, zone, vn(22, 0))).toBe(true);
    expect(inQuietHours(q, zone, vn(3, 0))).toBe(true);
    expect(inQuietHours(q, zone, vn(6, 0))).toBe(false);
  });

  it('same-day ranges, off and malformed', () => {
    expect(inQuietHours({ from: '13:00', to: '15:00' }, zone, vn(14))).toBe(true);
    expect(inQuietHours({ from: '13:00', to: '15:00' }, zone, vn(15))).toBe(false);
    expect(inQuietHours(null, zone, vn(23))).toBe(false);
    expect(inQuietHours({ from: '22:00', to: '22:00' }, zone, vn(22))).toBe(false);
    expect(inQuietHours({ from: '25:00', to: '06:00' }, zone, vn(23))).toBe(false);
  });
});

describe('inbox item', () => {
  const now = new Date('2026-10-15T10:00:00Z');
  const item = {
    kind: 'vaccine',
    category: 'reminders',
    title: { vi: 'Ngày mai có lịch tiêm của bé', en: 'A vaccination is due tomorrow' },
    body: { vi: '6in1 (mũi 1)', en: '6in1 (dose 1)' },
    route: 'vaccine',
    babyId: 'b_1',
    data: { kind: 'vaccine', babyId: 'b_1', date: '2026-10-16', months: '2' },
    pushed: true,
    createdAt: now,
    readAt: null,
    archivedAt: null,
    expireAt: new Date(now.getTime() + 90 * 86_400_000),
  };

  it('accepts what the helper writes', () => {
    expect(inboxItemSchema.safeParse(item).success).toBe(true);
  });

  it('rejects free text in the link data and unknown fields', () => {
    expect(
      inboxItemSchema.safeParse({ ...item, data: { note: 'line one\nline two' } }).success,
    ).toBe(false);
    expect(inboxItemSchema.safeParse({ ...item, caption: 'x' }).success).toBe(false);
  });

  it('ids', () => {
    expect(inboxIdSchema.safeParse('n_vx-b_1-2026-10-16-eve').success).toBe(true);
    expect(inboxIdSchema.safeParse('../x').success).toBe(false);
  });
});
