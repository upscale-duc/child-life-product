import { describe, expect, it } from 'vitest';
import {
  notificationTemplates,
  renderTemplate,
  vaccineSchedule,
  type LocalizedTemplateCopy,
  type PlaceholderValue,
} from '@child-life/contracts';
import { noticeCopy, noticeTemplate } from '../src/social.js';
import { ruleCopy, ruleName } from '../src/reminder-rules.js';
import { vaccineCopy, vaccineParts } from '../src/vaccine-reminders.js';
import { budgetCopy, recurringCopy } from '../src/spending.js';
import { importSummary } from '../src/mail-templates.js';
import { engagementCopy, engagementGenericCopy, engagementTemplate } from '../src/engagement.js';

// P-174: template version 0 must be exactly what each producer sent before the Portal existed,
// so publishing nothing changes nothing, and the Portal shows the copy users really receive.
const langs = ['vi', 'en'] as const;
const same = (
  copy: LocalizedTemplateCopy,
  values: Record<string, PlaceholderValue>,
  expected: (l: 'vi' | 'en') => { title: string; body: string },
) => {
  for (const l of langs) {
    const r = renderTemplate(copy, l, values);
    expect(r.missing).toEqual([]);
    expect({ title: r.title, body: r.body }).toEqual({
      title: expected(l).title,
      body: expected(l).body,
    });
  }
};

describe('built-in templates equal the producer copy', () => {
  it('family notices (moments, story, video, storage, message)', () => {
    for (const [kind, count] of [
      ['memories', 1],
      ['shared', 7],
      ['album', 2],
      ['story', 1],
      ['keepsakeVideo', 1],
      ['keepsakeVideoFailed', 1],
      ['storage', 80],
      ['storage', 95],
      ['storage', 100],
      ['storageGranted', 50],
      ['message', 1],
      ['memberJoined', 1],
      ['inviteDeclined', 1],
      ['roleChanged', 1],
      ['memberRemoved', 1],
    ] as const) {
      const t = noticeTemplate(kind, count, 'Mai')!;
      same(notificationTemplates[t.id].builtin, t.values, (l) => noticeCopy(kind, count, 'Mai', l));
    }
  });

  it('rule reminders, with and without a last log', () => {
    const now = new Date('2026-10-22T05:00:00Z');
    for (const type of ['feed', 'sleep', 'diaper', 'pump'] as const) {
      for (const anchor of [null, new Date('2026-10-22T02:15:00Z')]) {
        same(
          notificationTemplates['care.rule_due'].builtin,
          {
            activity_name: ruleName[type],
            last_logged_line: {
              vi: ruleCopy(type, 'vi', 'Asia/Ho_Chi_Minh', anchor, now).body,
              en: ruleCopy(type, 'en', 'Asia/Ho_Chi_Minh', anchor, now).body,
            },
          },
          (l) => ruleCopy(type, l, 'Asia/Ho_Chi_Minh', anchor, now),
        );
      }
    }
  });

  it('vaccines (3 days, eve, morning; one or several doses)', () => {
    const doses = vaccineSchedule.slice(0, 3).map((def, i) => ({
      def,
      dose: i === 2 ? 2 : 1,
      months: 2,
      date: '2026-11-01',
      rescheduled: false,
    }));
    for (const kind of ['3d', 'eve', 'morning'] as const) {
      for (const set of [doses.slice(0, 2), doses]) {
        same(
          notificationTemplates[`care.vaccine_${kind}`].builtin,
          {
            dose_list: { vi: vaccineParts(set, false).list, en: vaccineParts(set, true).list },
            age_label: {
              vi: vaccineParts(set, false).milestone,
              en: vaccineParts(set, true).milestone,
            },
          },
          (l) => vaccineCopy(kind, set, l),
        );
      }
    }
  });

  it('spending (recurring 1 / many, budget, import done / failed)', () => {
    for (const count of [1, 3])
      same(notificationTemplates['spending.recurring'].builtin, { count }, (l) =>
        recurringCopy(count, l),
      );
    same(notificationTemplates['spending.budget80'].builtin, {}, (l) => budgetCopy(l));
    same(
      notificationTemplates['spending.import_done'].builtin,
      { import_summary: { vi: importSummary('vi', 4, 1, 0), en: importSummary('en', 4, 1, 0) } },
      (l) => ({
        title: l === 'vi' ? 'Đã nhập xong chi tiêu' : 'Your spending import is done',
        body: importSummary(l, 4, 1, 0),
      }),
    );
  });

  it('Smart Engagement ENG-01/02/03/05/06: concrete copy from real values (D-092)', () => {
    const cases = {
      'ENG-01': {},
      'ENG-02': { milestone_label: { vi: '100 ngày', en: '100 days' } },
      'ENG-03': { week_count: 18 },
      'ENG-05': { update_count: 1 },
      'ENG-06': { activity_title: { vi: 'Đọc sách tranh cùng bé', en: 'Picture-book time' } },
    } as const;
    for (const [kind, values] of Object.entries(cases)) {
      const id = engagementTemplate[kind as 'ENG-01'];
      same(notificationTemplates[id].builtin, values, (l) =>
        engagementCopy(kind as 'ENG-01', values, l),
      );
    }
    expect(engagementCopy('ENG-02', cases['ENG-02'], 'vi')).toEqual({
      title: 'Bé sắp tròn 100 ngày rồi 🎉',
      body: 'Làm video kỷ niệm 100 ngày từ những bức ảnh bạn đã lưu, chỉ mất vài phút.',
    });
    expect(engagementCopy('ENG-03', { week_count: 1 }, 'en').title).toBe(
      '1 moment to remember from last week',
    );
    expect(engagementCopy('ENG-06', cases['ENG-06'], 'vi').title).toBe(
      'Gợi ý hôm nay: Đọc sách tranh cùng bé',
    );
    // A value that could not be computed: the old generic line, never a half-filled one.
    expect(engagementCopy('ENG-03', {}, 'vi')).toEqual(engagementGenericCopy['ENG-03'].vi);
    expect(engagementCopy('ENG-06', {}, 'vi').title).toBe('Gợi ý hôm nay: một hoạt động mới');
  });
});
