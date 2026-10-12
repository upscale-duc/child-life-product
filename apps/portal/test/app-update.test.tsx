import { appUpdateConfigSchema, staffCan, type AppUpdateConfig } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api, type AppUpdateView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { AppUpdateBody, raisedMinimum } from '../src/screens/AppUpdate';
import { levelsForRoles, type StaffRole } from './fixtures';

// Cập nhật ứng dụng on the portal (D-061): what is in use, who may publish, the raised-minimum
// warning, and a published config passing the shared schema. Server-rendered, no network.
const noApi: Api = { call: () => Promise.reject(new Error('no network in tests')) };

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
      <ApiContext.Provider value={noApi}>
        <StaffContext.Provider
          value={{
            uid: 's1',
            email: 'a@example.com',
            name: 'Khoa',
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
const text = (html: string) => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');

const config: AppUpdateConfig = {
  ios: { latest: '1.2.0', minimum: '1.0.5', storeUrl: 'https://apps.apple.com/app/id6700000000' },
  android: { latest: null, minimum: null, storeUrl: null },
  snoozeDays: 3,
  release: {
    version: '1.2.0',
    summary: { vi: 'Sơ cứu, chi tiêu chung, lịch tiêm', en: 'First aid, spending, vaccines' },
    highlights: [
      {
        icon: 'alert',
        tone: 'danger',
        title: { vi: 'Sơ cứu trẻ em', en: 'Child first aid' },
        body: { vi: '25 tình huống, đọc to từng bước', en: '25 situations, read aloud' },
      },
    ],
    pages: [
      {
        image: 'so-cuu_0000abcd',
        title: { vi: 'Sơ cứu trẻ em, luôn trong túi bạn', en: 'First aid, always with you' },
        body: { vi: '25 tình huống thường gặp.', en: '25 common situations.' },
        where: { vi: 'Tìm trong tab Tiện ích', en: 'In the Utilities tab' },
      },
    ],
  },
};
const view: AppUpdateView = {
  current: { version: 'au_20261012_01', publishedAt: '2026-10-12T03:00:00Z', config },
  history: [
    {
      version: 'au_20261012_01',
      publishedAt: '2026-10-12T03:00:00Z',
      byName: 'Khoa',
      reason: 'Bản 1.2.0',
      config,
    },
  ],
  images: [{ id: 'so-cuu_0000abcd', url: 'https://img.test/so-cuu_0000abcd' }],
};

describe('Cập nhật ứng dụng', () => {
  it('shows what is in use, the release and the history', () => {
    const raw = render(<AppUpdateBody view={view} canEdit />);
    const html = text(raw);
    expect(html).toContain('Bản au_20261012_01');
    expect(html).toContain('iOS · App Store');
    expect(raw).toContain('value="Sơ cứu trẻ em, luôn trong túi bạn"');
    expect(html).toContain('1.0.5 → 1.2.0');
    expect(html).toContain('Xuất bản…');
    expect(appUpdateConfigSchema.safeParse(config).success).toBe(true);
  });

  it('only Kỹ sư, Admin and Owner publish; others read', () => {
    expect(staffCan(levelsForRoles(['eng']), 'release.edit')).toBe(true);
    expect(staffCan(levelsForRoles(['ops']), 'release.edit')).toBe(false);
    expect(staffCan(levelsForRoles(['ops']), 'release.view')).toBe(true);
    expect(staffCan(levelsForRoles(['support']), 'release.view')).toBe(false);
    const html = text(render(<AppUpdateBody view={view} canEdit={false} />, ['ops']));
    expect(html).not.toContain('Xuất bản…');
    expect(html).not.toContain('Thêm trang');
  });

  it('a raised minimum is flagged; a new one with no previous minimum too', () => {
    expect(raisedMinimum(config.ios, { ...config.ios, minimum: '1.1.0' })).toBe(true);
    expect(raisedMinimum(config.ios, config.ios)).toBe(false);
    expect(raisedMinimum(config.android, { ...config.ios })).toBe(true);
    expect(raisedMinimum(config.ios, { ...config.ios, minimum: null })).toBe(false);
  });

  it('English labels exist', () => {
    expect(text(render(<AppUpdateBody view={view} canEdit />, ['admin'], 'en'))).toContain(
      'Oldest allowed',
    );
  });
});
