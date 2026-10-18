import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type AiStats, type Api, type SystemHealth } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { AiView, SystemScreen, SystemView } from '../src/screens/System';
import { levelsForRoles, type StaffRole } from './fixtures';

// Hệ thống & AI (A08 / A09): aggregates only, warnings first, healthy state quiet.
const now = new Date('2026-10-15T05:00:00Z');
const GB = 1024 ** 3;

const health: SystemHealth = {
  kpis: { storedBytes: 120 * GB, over80: 0, videosWaiting: 3, uploadFailureRate: 0.004 },
  histogram: [50, 30, 12, 5, 2, 1],
  families: 100,
  videoQueue: Array.from({ length: 24 }, (_, i) => (i === 23 ? 3 : 1)),
  videoThreshold: 20,
  nearQuota: [],
};

const ai: AiStats = {
  kpis: { drafts7d: 42, savedRate: 0.6, costPerDraftVnd: 1_200, reports: 0 },
  outcomes: { editedSaved: 20, savedAsIs: 5, left: 17 },
  daily: Array.from({ length: 14 }, (_, i) => ({
    date: new Date(Date.UTC(2026, 9, 2 + i)).toISOString().slice(0, 10),
    drafts: 3,
  })),
  budget: { monthlyBudgetVnd: 2_000_000, month: '2026-10', spentVnd: 500_000 },
  rollout: { enabled: true, scope: 'percent', percent: 25, notice: null },
};

// Loaders stay loading: the views are rendered with their data directly.
const api: Api = { call: () => new Promise(() => undefined) };

function html(node: ReactNode, roles: StaffRole[] = ['ops'], locale: 'vi' | 'en' = 'vi') {
  return renderToStaticMarkup(
    <IntlProvider
      locale={locale}
      defaultLocale="vi"
      messages={messages[locale]}
      onError={(e) => {
        throw e;
      }}
    >
      <ApiContext.Provider value={api}>
        <StaffContext.Provider
          value={{
            uid: 's1',
            email: 'linh@example.com',
            name: 'Linh Trần',
            roles,
            levels: levelsForRoles(roles),
          }}
        >
          {node}
        </StaffContext.Provider>
      </ApiContext.Provider>
    </IntlProvider>,
  );
}
const text = (raw: string) =>
  raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ');

describe('Hệ thống & AI › screen', () => {
  it('Lưu trữ and AI are tabs; the open one follows the route', () => {
    const raw = html(<SystemScreen tab="ai" />);
    const tabs = [...raw.matchAll(/<button[^>]*role="tab"[^>]*>(.*?)<\/button>/g)].map((m) =>
      text(m[1]!).trim(),
    );
    expect(tabs).toEqual(['Dung lượng & media', 'AI gợi ý câu chuyện']);
    expect(raw).toMatch(/aria-selected="true"[^>]*>AI gợi ý câu chuyện/);
  });
});

describe('Hệ thống & AI › Lưu trữ', () => {
  it('healthy: no warning, the figures and an empty near-quota list', () => {
    const raw = html(<SystemView data={health} now={now} />);
    const t = text(raw);
    expect(raw).not.toContain('role="alert"');
    expect(t).toContain('Ảnh, video đã lưu 120 GB');
    expect(t).toContain('Video chờ xử lý 3 Ngưỡng 20 video');
    expect(t).toContain('Tải lên lỗi 0,4%');
    expect(t).toContain('Hạn mức 10 GB · 100 gia đình');
    expect(t).toContain('Dưới ngưỡng');
    expect(t).toContain('Chưa gia đình nào dùng trên 80%.');
  });

  it('a long queue and families near quota come first; the table shows codes and usage', () => {
    const busy: SystemHealth = {
      ...health,
      kpis: { ...health.kpis, over80: 2, videosWaiting: 31 },
      nearQuota: [
        { family: 'F-7Q2K', babies: 2, usedBytes: 9.2 * GB, quotaBytes: 10 * GB, requested: true },
        { family: 'F-A1B2', babies: 1, usedBytes: 8.3 * GB, quotaBytes: 10 * GB, requested: false },
      ],
    };
    const raw = html(<SystemView data={busy} now={now} />);
    const t = text(raw);
    expect(t).toContain('31 video đang chờ xử lý, vượt ngưỡng 20');
    expect(t).toContain('2 gia đình đã dùng trên 80% dung lượng');
    // Vận hành may open the storage requests.
    expect(t).toContain('Xem yêu cầu mở rộng');
    expect(t.indexOf('vượt ngưỡng 20')).toBeLessThan(t.indexOf('Ảnh, video đã lưu'));
    expect(t).toContain('Trên ngưỡng');
    expect(t).toContain('F-7Q2K 2 bé 9,2 GB · 92% Đang chờ duyệt');
    expect(t).toContain('F-A1B2 1 bé 8,3 GB · 83% Chưa gửi');
    // No per-row note: the privacy line is one hint on the section.
    expect(t).not.toContain('Không xem được ảnh');
    // Without the storage level there is no link to the requests.
    expect(text(html(<SystemView data={busy} now={now} />, ['eng']))).not.toContain(
      'Xem yêu cầu mở rộng',
    );
    const en = text(html(<SystemView data={busy} now={now} />, ['ops'], 'en'));
    expect(en).toContain('2 families have used more than 80% of their storage');
  });
});

describe('Hệ thống & AI › AI', () => {
  it('budget first with the 80% mark and what 100% does; safety folds away', () => {
    const raw = html(<AiView data={ai} now={now} />);
    const t = text(raw);
    expect(raw).not.toContain('role="alert"');
    expect(t).toContain('Ngân sách AI · Tháng 10');
    expect(t).toContain('500.000 đ / 2 triệu đ 25%');
    expect(t).toContain('Ngày 15/31 trong tháng');
    expect(t).toContain('Cảnh báo ở 80% · tới 100%, AI tạm dừng gợi ý mới');
    expect(raw).toContain('aria-valuenow="25"');
    expect(t).toContain('Đang bật cho 25% gia đình');
    expect(t.indexOf('Ngân sách AI')).toBeLessThan(t.indexOf('Chi phí mỗi bản nháp'));
    expect(t).toContain('Chi phí mỗi bản nháp 1.200 đ');
    expect(t).toContain('Bản nháp tạo · 7 ngày 42');
    expect(t).toContain('Sửa rồi lưu');
    expect(t).toContain('Giữ an toàn cho dữ liệu của bé 4 quy tắc');
    expect(t).not.toContain('pháp lý');
  });

  it('warns at 80% and when the budget is used up', () => {
    const near = text(
      html(<AiView data={{ ...ai, budget: { ...ai.budget, spentVnd: 1_700_000 } }} now={now} />),
    );
    expect(near).toContain('Đã dùng 85% ngân sách AI tháng này');
    expect(near).toContain('Nếu chạm 100%, AI tự tạm dừng gợi ý mới');
    const over = html(
      <AiView data={{ ...ai, budget: { ...ai.budget, spentVnd: 2_100_000 } }} now={now} />,
    );
    expect(text(over)).toContain('Đã dùng hết ngân sách AI tháng này');
    expect(text(over)).toContain('AI đã tự tạm dừng gợi ý mới');
    // The bar stops at full.
    expect(over).toContain('aria-valuenow="100"');
    const en = text(
      html(
        <AiView data={{ ...ai, budget: { ...ai.budget, spentVnd: 2_100_000 } }} now={now} />,
        ['ops'],
        'en',
      ),
    );
    expect(en).toContain("This month's AI budget is used up");
  });
});
