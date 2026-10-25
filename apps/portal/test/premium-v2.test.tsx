import { defaultEntitlementsConfig, type StaffProposal } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import {
  AdjustUsagePanel,
  PlansVersionSection,
  ProposalsList,
  RefundJobButton,
  planChanges,
} from '../src/screens/PremiumPlans';
import { levelsForRoles, type StaffRole } from './fixtures';

// Premium v2 on the portal (Figma 958:13863 PT02–PT04, D-101): the running plans version, the
// proposals a second person approves, the manual adjustment and the video refund. Server-rendered.
const api: Api = { call: () => Promise.reject(new ApiError('internal', null)) };

function render(node: ReactNode, roles: StaffRole[] = ['admin'], locale: 'vi' | 'en' = 'vi') {
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
const text = (html: string) =>
  html
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');

const plans = defaultEntitlementsConfig.plans;

describe('Gói & hạn mức (PT03)', () => {
  it('shows the running version with Free and Premium as PV00 draws them', () => {
    const t = text(
      render(<PlansVersionSection config={defaultEntitlementsConfig} onChanged={() => {}} />),
    );
    expect(t).toContain('Đang chạy: 2.0-launch');
    expect(t).toContain('Credit Lumi 30 (một lần) 200 / tháng');
    expect(t).toContain('Chỗ người ghi 3 6');
    expect(t).toContain('Soạn phiên bản mới');
    expect(t).toContain('Đọc ảnh 3');
  });

  it('a viewer sees the values but cannot draft', () => {
    const t = text(
      render(<PlansVersionSection config={defaultEntitlementsConfig} onChanged={() => {}} />, [
        'analyst',
      ]),
    );
    expect(t).toContain('Đang chạy: 2.0-launch');
    expect(t).not.toContain('Soạn phiên bản mới');
  });

  it('lists what a version changes', () => {
    const next = structuredClone(plans);
    next.free.storageGB = 2;
    next.premium.price.vn.month = 69000;
    expect(planChanges(plans, next)).toEqual([
      'free.storageGB: 1 → 2',
      'premium.price.vn.month: 59000 → 69000',
    ]);
  });
});

describe('Chờ duyệt', () => {
  const proposal = (over: Partial<StaffProposal>): StaffProposal => ({
    id: 'pp_abcdefgh',
    kind: 'plans',
    status: 'pending',
    version: '2.1',
    plans: { ...structuredClone(plans), free: { ...plans.free, storageGB: 2 } },
    adjustment: null,
    reason: '',
    by: 'Kỹ sư',
    at: '2026-10-25T03:00:00Z',
    decidedBy: null,
    decidedAt: null,
    mine: false,
    ...over,
  });

  it('a version and a large adjustment wait with Duyệt / Từ chối', () => {
    const t = text(
      render(
        <ProposalsList
          current={plans}
          onChanged={() => {}}
          list={[
            proposal({}),
            proposal({
              id: 'pa_abcdefgh',
              kind: 'adjustment',
              version: null,
              plans: null,
              adjustment: { code: 'F-7Q2K', feature: 'video', amount: 60 },
              mine: true,
            }),
          ]}
        />,
      ),
    );
    expect(t).toContain('Phiên bản 2.1');
    expect(t).toContain('free.storageGB: 1 → 2');
    expect(t).toContain('F-7Q2K · +60 lượt video');
    expect(t).toContain('Bạn gửi · cần người khác duyệt');
    expect(t.match(/Duyệt/g)?.length).toBeGreaterThanOrEqual(2);
  });

  it('nothing waiting reads as such (English too)', () => {
    expect(
      text(render(<ProposalsList current={plans} onChanged={() => {}} list={[]} />)),
    ).toContain('Không có thay đổi nào chờ duyệt.');
    expect(
      text(
        render(<ProposalsList current={plans} onChanged={() => {}} list={[]} />, ['admin'], 'en'),
      ),
    ).toContain('Nothing is waiting for approval.');
  });
});

describe('Điều chỉnh and Hoàn lượt (PT02, PT04)', () => {
  it('the adjustment says when a second approver is needed', () => {
    const t = text(render(<AdjustUsagePanel code="F-7Q2K" onDone={() => {}} />));
    expect(t).toContain('Điều chỉnh thủ công');
    expect(t).toContain('Trên 50 cần người thứ hai duyệt');
    expect(t).toContain('Gửi điều chỉnh');
  });

  it('only those who grant see them', () => {
    expect(text(render(<AdjustUsagePanel code="F-7Q2K" onDone={() => {}} />, ['analyst']))).toBe(
      '',
    );
    expect(text(render(<RefundJobButton family="F-7Q2K" job="KJ-1A2B" />))).toContain('Hoàn lượt');
    expect(text(render(<RefundJobButton family="F-7Q2K" job="KJ-1A2B" />, ['analyst']))).toBe('');
  });
});
