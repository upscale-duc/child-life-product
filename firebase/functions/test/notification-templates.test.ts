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
import { engagementCopy } from '../src/engagement.js';

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

  it('Smart Engagement ENG-01/02/03/05/06', () => {
    const ids = {
      'ENG-01': 'eng.pending_photos',
      'ENG-02': 'eng.keepsake_suggestion',
      'ENG-03': 'eng.weekly_recap',
      'ENG-05': 'eng.family_recap',
      'ENG-06': 'eng.lumi_insight',
    } as const;
    for (const [kind, id] of Object.entries(ids))
      same(notificationTemplates[id].builtin, {}, (l) => engagementCopy[kind as 'ENG-01'][l]);
  });
});
