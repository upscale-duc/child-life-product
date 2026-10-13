import { appUpdateConfigSchema, staffCan, type AppUpdateConfig } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api, type AppUpdateView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import { AppUpdateBody, raisedMinimum } from '../src/screens/AppUpdate';
import { AppUpdatePreview, type PreviewScreen } from '../src/screens/AppUpdatePreview';
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
  it('shows what is in use on one line; history one click away; three tabs', () => {
    const raw = render(<AppUpdateBody view={view} canEdit />);
    const html = text(raw);
    expect(html).toContain('Bản au_20261012_01');
    expect(html).toContain('iOS 1.0.5 → 1.2.0');
    expect(html).toContain('Lịch sử (1)');
    expect(html).toContain('Phiên bản Có gì mới');
    expect(html).toContain('Trang giới thiệu');
    // Phiên bản: both stores in one table, the publish bar at the bottom.
    expect(html).toContain('iOS · App Store');
    expect(html).toContain('Android · Google Play');
    expect(html).toContain('Chưa có thay đổi');
    expect(html).toContain('Xuất bản…');
    expect(appUpdateConfigSchema.safeParse(config).success).toBe(true);
  });

  it('Có gì mới and Trang giới thiệu: lists that open one item at a time', () => {
    const release = text(render(<AppUpdateBody view={view} canEdit initialTab="release" />));
    expect(release).toContain('Hiện trong app');
    expect(release).toMatch(/Điểm nổi bật · \d\/4/);
    const pagesRaw = render(<AppUpdateBody view={view} canEdit initialTab="pages" />);
    expect(text(pagesRaw)).toMatch(/Trang giới thiệu · \d\/5/);
    // The first page is open with its fields; the others show their title only.
    expect(pagesRaw).toContain('value="Sơ cứu trẻ em, luôn trong túi bạn"');
    expect(pagesRaw).toContain('aria-expanded="true"');
  });

  it('only Kỹ sư, Admin and Owner publish; others read', () => {
    expect(staffCan(levelsForRoles(['eng']), 'release.edit')).toBe(true);
    expect(staffCan(levelsForRoles(['ops']), 'release.edit')).toBe(false);
    expect(staffCan(levelsForRoles(['ops']), 'release.view')).toBe(true);
    expect(staffCan(levelsForRoles(['support']), 'release.view')).toBe(false);
    const html = text(render(<AppUpdateBody view={view} canEdit={false} />, ['ops']));
    expect(html).not.toContain('Xuất bản…');
    const pages = text(
      render(<AppUpdateBody view={view} canEdit={false} initialTab="pages" />, ['ops']),
    );
    expect(pages).not.toContain('Thêm trang');
    expect(pages).not.toContain('Chọn tệp');
  });

  it('a raised minimum is flagged; a new one with no previous minimum too', () => {
    expect(raisedMinimum(config.ios, { ...config.ios, minimum: '1.1.0' })).toBe(true);
    expect(raisedMinimum(config.ios, config.ios)).toBe(false);
    expect(raisedMinimum(config.android, { ...config.ios })).toBe(true);
    expect(raisedMinimum(config.ios, { ...config.ios, minimum: null })).toBe(false);
  });

  it('uses the shadcn controls: selects, file button, icon buttons (D-063)', () => {
    const html = render(<AppUpdateBody view={view} canEdit initialTab="pages" />);
    expect(html).not.toMatch(
      /<select[^>]*class="field__input|<input[^>]*type="file"[^>]*class="field__input/,
    );
    expect(html).toContain('data-slot="select-trigger"');
    expect(text(html)).toContain('Chọn tệp');
    expect(html).toContain('aria-label="Chuyển lên"');
  });

  it('English labels exist', () => {
    expect(text(render(<AppUpdateBody view={view} canEdit />, ['admin'], 'en'))).toContain(
      'Oldest allowed',
    );
  });
});

describe('Cập nhật ứng dụng: preview (portal review 2026-10-12)', () => {
  const show = (initial: PreviewScreen, c: AppUpdateConfig = config) =>
    text(render(<AppUpdatePreview config={c} images={view.images} initial={initial} />));

  it("draws each app screen from the form, in the app's copy", () => {
    expect(show('required')).toContain('Cần cập nhật để tiếp tục');
    expect(show('required')).toMatch(/1\.0\.4\s+1\.2\.0/);
    expect(show('required')).toContain('Cập nhật trên App Store');
    expect(show('required')).toContain('Có gì mới trong 1.2.0');
    expect(show('available')).toContain('Mới · 1.2.0');
    expect(show('available')).toContain('Sơ cứu trẻ em');
    expect(show('banner')).toContain('Đã cập nhật 1.2.0');
    expect(show('banner')).toContain('Sơ cứu, chi tiêu chung, lịch tiêm');
    expect(show('pages')).toContain('Sơ cứu trẻ em, luôn trong túi bạn');
    expect(show('pages')).toContain('Tìm trong tab Tiện ích');
    expect(show('version')).toContain('Có bản mới 1.2.0');
  });

  it('says why a screen would not show', () => {
    const none = { ...config, release: null, ios: { latest: null, minimum: null, storeUrl: null } };
    expect(show('required', none)).toContain('không máy nào bị chặn');
    expect(show('available', none)).toContain('app không nhắc cập nhật');
    expect(show('banner', none)).toContain('Chưa có trang giới thiệu');
  });

  it('the page has the preview next to the form', () => {
    expect(text(render(<AppUpdateBody view={view} canEdit />))).toContain('Xem trước');
  });
});

describe('Sidebar: icons and the icon-only menu (shadcn/ui, D-063)', () => {
  const bar = (collapsed: boolean) =>
    render(
      <Sidebar
        route="appUpdate"
        badges={null}
        environment="dev"
        locale="vi"
        onLocale={() => undefined}
        onSignOut={() => undefined}
        navigate={() => undefined}
        collapsed={collapsed}
      />,
    );

  it('every item has an icon; the toggle says what it does', () => {
    const html = bar(false);
    const items = html.match(/<a [^>]*data-sidebar="menu-button"[^>]*>/g)!;
    expect(items.length).toBeGreaterThan(5);
    expect(
      html.match(/<a [^>]*data-sidebar="menu-button"[^>]*>\s*<svg [^>]*class="lucide/g)!.length,
    ).toBe(items.length);
    expect(html).toContain('aria-label="Thu gọn menu"');
    expect(html).toContain('data-state="expanded"');
    expect(html).toContain('aria-current="page"');
  });

  it('collapsed: icons only, names kept for screen readers', () => {
    const html = bar(true);
    expect(html).toContain('data-state="collapsed"');
    expect(html).toContain('data-collapsible="icon"');
    expect(html).toContain('aria-label="Mở rộng menu"');
    expect(text(html)).toContain('Cập nhật ứng dụng');
  });
});
