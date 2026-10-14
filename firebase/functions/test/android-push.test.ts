import { describe, expect, it } from 'vitest';
import { androidNotification, pushPayload } from '../src/social.js';

// Android plan A1: every push names a channel the app creates, the status-bar icon and a tag
// that replaces an earlier notice for the same rule or day.
describe('androidNotification', () => {
  it('rule and vaccine reminders go to "reminders" and replace each other by tag', () => {
    expect(
      androidNotification({
        title: 't',
        body: 'b',
        data: { kind: 'reminderRule' },
        apns: { category: 'CL_RULE_FEED', collapseId: 'rr-1', threadId: '1' },
      }),
    ).toEqual({ channelId: 'reminders', icon: 'ic_stat_notify', color: '#087F7B', tag: 'rr-1' });
    expect(
      androidNotification({ title: 't', body: 'b', data: { kind: 'vaccine' } }).channelId,
    ).toBe('reminders');
  });

  it('spending has its own channel; family notices go to "family" without a tag', () => {
    expect(
      androidNotification({
        title: 't',
        body: 'b',
        data: { kind: 'spending' },
        apns: { collapseId: 'sp-budget-b-2026-10' },
      }),
    ).toMatchObject({ channelId: 'spending', tag: 'sp-budget-b-2026-10' });
    const notice = androidNotification({ title: 't', body: 'b', data: { kind: 'memories' } });
    expect(notice.channelId).toBe('family');
    expect(notice).not.toHaveProperty('tag');
  });
});

describe('pushPayload', () => {
  const rule = {
    title: 'Đến giờ bú',
    body: 'Teddy · cữ 14:00',
    data: { kind: 'reminderRule', babyId: 'b1', ruleId: 'r1' },
    apns: { category: 'CL_RULE_FEED', collapseId: 'rr-r1', threadId: 'r1' },
  };

  it('a push with actions is data on Android and an alert with its category on iOS (A6)', () => {
    const p = pushPayload({ ...rule, androidDraws: true });
    expect(p).not.toHaveProperty('notification');
    expect(p.data).toEqual({
      ...rule.data,
      title: 'Đến giờ bú',
      body: 'Teddy · cữ 14:00',
      draw: '1',
      tag: 'rr-r1',
    });
    expect(p.android).toEqual({ priority: 'high' });
    expect(p.apns).toEqual({
      headers: { 'apns-collapse-id': 'rr-r1' },
      payload: {
        aps: {
          sound: 'default',
          alert: { title: 'Đến giờ bú', body: 'Teddy · cữ 14:00' },
          category: 'CL_RULE_FEED',
          threadId: 'r1',
        },
      },
    });
  });

  it('other pushes keep the notification block on both, as before', () => {
    const p = pushPayload({ title: 't', body: 'b', data: { kind: 'memories' } });
    expect(p).toMatchObject({
      notification: { title: 't', body: 'b' },
      data: { kind: 'memories' },
      apns: { payload: { aps: { sound: 'default' } } },
      android: { priority: 'high', notification: { channelId: 'family' } },
    });
    expect(p.apns.payload.aps).not.toHaveProperty('alert');
  });
});
