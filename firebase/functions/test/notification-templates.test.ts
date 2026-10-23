import { describe, expect, it } from 'vitest';
import {
  notificationTemplates,
  renderTemplate,
  vaccineSchedule,
  type NotificationTemplateId,
  type PlaceholderValue,
} from '@child-life/contracts';
import { noticeCopy, noticeTemplate } from '../src/social.js';
import { ruleCopy, ruleName } from '../src/reminder-rules.js';
import { vaccineParts } from '../src/vaccine-reminders.js';
import { budgetCopy, recurringCopy } from '../src/spending.js';
import { importSummary } from '../src/mail-templates.js';
import { engagementCopy, engagementGenericCopy, engagementTemplate } from '../src/engagement.js';

// The copy people receive is the template (version 0 = built-in, or the Portal's published one)
// rendered with the producer's values. D-094: lines tied to one baby carry its nickname, so a
// parent of two can tell them apart; with "Hiện tên bé" off (or no nickname) they say "bé". The
// producers' own copy functions remain the fallback when a value is missing.
const render = (
  id: NotificationTemplateId,
  values: Record<string, PlaceholderValue>,
  language: 'vi' | 'en',
) => {
  const r = renderTemplate(notificationTemplates[id].builtin, language, values);
  expect(r.missing).toEqual([]);
  return { title: r.title, body: r.body };
};

describe('family notices', () => {
  it('moments, story and video carry the baby name; storage and messages do not', () => {
    const moments = noticeTemplate('shared', 7, 'Mai')!;
    expect(render(moments.id, { ...moments.values, baby_name: 'Bin' }, 'vi')).toEqual({
      title: 'Có 7 khoảnh khắc mới của Bin',
      body: 'Mai vừa chia sẻ với gia đình. Mở để xem.',
    });
    expect(render(moments.id, { ...noticeTemplate('memories', 1, 'Mai')!.values }, 'en')).toEqual({
      title: '1 new moment of your baby',
      body: 'Mai just shared with the family. Open to see.',
    });
    const story = noticeTemplate('story', 1, 'Mai')!;
    expect(render(story.id, { baby_name: 'Bin' }, 'vi').title).toBe('Có 1 câu chuyện mới về Bin');
    const video = noticeTemplate('keepsakeVideo', 1, '')!;
    expect(render(video.id, { baby_name: 'Bin' }, 'en').title).toBe('Bin’s memory video is ready');
    expect(render(video.id, {}, 'en').title).toBe('Your baby’s memory video is ready');
    // Family-wide notices never name a baby.
    for (const [kind, count] of [
      ['storage', 80],
      ['storage', 100],
      ['storageGranted', 50],
      ['message', 1],
      ['memberJoined', 1],
    ] as const) {
      const t = noticeTemplate(kind, count, 'Mai')!;
      expect(notificationTemplates[t.id].placeholders).not.toContain('baby_name');
      for (const l of ['vi', 'en'] as const)
        expect(render(t.id, t.values, l)).toEqual(noticeCopy(kind, count, 'Mai', l));
    }
  });
});

describe('care', () => {
  it('rule reminders name the baby and keep the last-log line', () => {
    const now = new Date('2026-10-22T05:00:00Z');
    const anchor = new Date('2026-10-22T02:15:00Z');
    const values = {
      activity_name: ruleName.feed,
      last_logged_line: {
        vi: ruleCopy('feed', 'vi', 'Asia/Ho_Chi_Minh', anchor, now).body,
        en: ruleCopy('feed', 'en', 'Asia/Ho_Chi_Minh', anchor, now).body,
      },
    };
    expect(render('care.rule_due', { ...values, baby_name: 'Bin' }, 'vi')).toEqual({
      title: 'Đến giờ nhắc bú cho Bin',
      body: 'Lần bú gần nhất 09:15 · 2 giờ 45 phút trước',
    });
    expect(render('care.rule_due', values, 'en').title).toBe(
      'Time for your baby’s feeding reminder',
    );
  });

  it('vaccines name the baby; the dose list and what to bring stay', () => {
    const doses = vaccineSchedule.slice(0, 2).map((def) => ({
      def,
      dose: 1,
      months: 2,
      date: '2026-11-01',
      rescheduled: false,
    }));
    const values = {
      dose_list: { vi: vaccineParts(doses, false).list, en: vaccineParts(doses, true).list },
      age_label: {
        vi: vaccineParts(doses, false).milestone,
        en: vaccineParts(doses, true).milestone,
      },
    };
    const eve = render('care.vaccine_eve', { ...values, baby_name: 'Bin' }, 'vi');
    expect(eve.title).toBe('Ngày mai có lịch tiêm của Bin');
    expect(eve.body).toMatch(/Mốc 2 tháng tuổi\. Nhớ mang sổ tiêm và một chiếc khăn mỏng\.$/);
    expect(render('care.vaccine_3d', values, 'en').title).toBe(
      'Your baby’s vaccination is in 3 days',
    );
  });

  it('spending stays as it was (no baby name)', () => {
    for (const count of [1, 3])
      for (const l of ['vi', 'en'] as const)
        expect(render('spending.recurring', { count }, l)).toEqual(recurringCopy(count, l));
    for (const l of ['vi', 'en'] as const)
      expect(render('spending.budget80', {}, l)).toEqual(budgetCopy(l));
    expect(
      render(
        'spending.import_done',
        { import_summary: { vi: importSummary('vi', 4, 1, 0), en: importSummary('en', 4, 1, 0) } },
        'vi',
      ).body,
    ).toBe(importSummary('vi', 4, 1, 0));
  });
});

describe('Smart Engagement (D-092 concrete values, D-094 baby name)', () => {
  const cases = {
    'ENG-01': {},
    'ENG-02': { milestone_label: { vi: '100 ngày', en: '100 days' } },
    'ENG-03': { week_count: 18 },
    'ENG-05': { update_count: 1 },
    'ENG-06': { activity_title: { vi: 'Đọc sách tranh cùng bé', en: 'Picture-book time' } },
  } as const;

  it('with the name', () => {
    const named = (kind: keyof typeof cases, l: 'vi' | 'en') =>
      render(engagementTemplate[kind], { ...cases[kind], baby_name: 'Bin' }, l).title;
    expect(named('ENG-01', 'vi')).toBe('Ảnh mới của Bin đang chờ bạn 📸');
    expect(named('ENG-02', 'vi')).toBe('Bin sắp tròn 100 ngày rồi 🎉');
    expect(named('ENG-03', 'vi')).toBe('Tuần qua của Bin có 18 khoảnh khắc đáng nhớ');
    expect(named('ENG-05', 'en')).toBe('1 new family update about Bin');
    expect(named('ENG-06', 'vi')).toBe('Gợi ý hôm nay cho Bin: Đọc sách tranh cùng bé');
  });

  it('the fallback copy (no name) and the generic line when a value is missing', () => {
    expect(engagementCopy('ENG-02', cases['ENG-02'], 'vi').title).toBe(
      'Bé sắp tròn 100 ngày rồi 🎉',
    );
    expect(engagementCopy('ENG-03', { week_count: 1 }, 'en').title).toBe(
      '1 moment to remember from your baby’s week',
    );
    expect(engagementCopy('ENG-03', {}, 'vi')).toEqual(engagementGenericCopy['ENG-03'].vi);
    expect(engagementCopy('ENG-06', {}, 'vi').title).toBe(
      'Gợi ý hôm nay cho bé: một hoạt động mới',
    );
  });
});
