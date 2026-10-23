import {
  premium48Phase6,
  premium48FinalPhase,
  keepsakeSeedV1,
  type KeepsakeCatalog,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import { routeOf } from '../src/context';
import {
  CardPreview,
  KeepsakesBody,
  catalogIssues,
  filterTemplates,
  keepsakeTemplateUrl,
  sortTemplates,
  templateIdFor,
  templateUsageOf,
  type KeepsakeTab,
  type KeepsakeView,
} from '../src/screens/Keepsakes';
import { levelsForRoles, type StaffRole } from './fixtures';

// Mẫu kỷ niệm on the portal (D-068 #7, #8): the catalog and its artwork are managed here, the
// Sơ cứu way; Miễn phí / Cao cấp per template and for the whole set. Server-rendered, no network.
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
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ');

const live: KeepsakeView = {
  current: {
    version: 'ks_20261013_01',
    publishedAt: '2026-10-13T03:00:00Z',
    catalog: keepsakeSeedV1,
  },
  draft: null,
  history: [
    {
      versionId: 'kv_0000000000000001',
      status: 'published',
      label: 'ks_20261013_01',
      notes: 'Bộ đầu',
      authorName: 'Hà Vũ',
      approverName: 'BS. Lan',
      createdAt: '2026-10-13T02:00:00Z',
      updatedAt: '2026-10-13T03:00:00Z',
      approvedAt: '2026-10-13T03:00:00Z',
      rejection: null,
      templates: 8,
    },
  ],
  assets: [{ asset: 'frame-pink_1a2b3c4d.webp', url: 'https://img.test/frame.webp' }],
};

describe('Mẫu kỷ niệm', () => {
  it('renders all final cards in both languages, including the required occasion and theme', () => {
    for (let phase = 7; phase <= 12; phase++)
      for (const t of premium48FinalPhase(phase).filter((t) => t.kind === 'card'))
        for (const locale of ['vi', 'en'] as const) {
          const html = render(
            <CardPreview template={t} format="portrait" urls={new Map()} width={480} />,
            ['admin'],
            locale,
          );
          expect(html).not.toMatch(/\{(?:occasionName|relativeName|babyName)\}/);
          expect(text(html)).toContain('Teddy');
        }
  });
  it('shows only the explicitly selected decoration set, independent of preview locale', () => {
    const assets = {
      'p48-celebrate-neutral-corner': 'neutral_abcdef12.webp',
      'p48-celebrate-tet-corner': 'tet_abcdef12.webp',
      'p48-celebrate-christmas-corner': 'christmas_abcdef12.webp',
    };
    const t = premium48FinalPhase(10, assets).find((t) => t.id === 'card_premium48_20')!;
    for (const locale of ['vi', 'en'] as const) {
      const html = render(
        <CardPreview
          template={t}
          format="portrait"
          urls={new Map(Object.values(assets).map((v) => [v, 'https://img.test/' + v]))}
          width={480}
        />,
        ['admin'],
        locale,
      );
      expect(html).toContain('https://img.test/neutral_abcdef12.webp');
      expect(html).not.toContain('https://img.test/tet_abcdef12.webp');
      expect(html).not.toContain('https://img.test/christmas_abcdef12.webp');
    }
  });
  it('renders phase 6 milestone cards with a required parent-entered field in either locale', () => {
    const t = premium48Phase6()[0]!;
    for (const locale of ['vi', 'en'] as const) {
      const html = render(
        <CardPreview template={t} format="portrait" urls={new Map()} width={480} />,
        ['admin'],
        locale,
      );
      expect(html).not.toContain('{milestoneName}');
      expect(text(html)).toContain(locale === 'vi' ? 'những bước nhỏ' : 'little steps');
    }
  });
  it('shows newly added templates first within each group, regardless of display order or version', () => {
    const card = keepsakeSeedV1.templates.find((t) => t.kind === 'card')!;
    const video = keepsakeSeedV1.templates.find((t) => t.kind === 'video')!;
    const added = [card, video].map((t) => ({
      ...t,
      id: `${t.id}_new`,
      name: { vi: `Mới thêm ${t.kind}`, en: `Newly added ${t.kind}` },
      order: 999,
      version: 1,
    }));
    const view: KeepsakeView = {
      ...live,
      current: {
        ...live.current!,
        catalog: {
          ...keepsakeSeedV1,
          templates: [...keepsakeSeedV1.templates.map((t) => ({ ...t, version: 20 })), ...added],
        },
      },
    };
    for (const locale of ['vi', 'en'] as const) {
      const html = render(
        <KeepsakesBody view={view} canEdit canApprove onChanged={() => {}} />,
        ['admin'],
        locale,
      );
      expect(html).toContain(locale === 'vi' ? 'Sắp xếp mẫu' : 'Sort templates');
      for (const original of [card, video]) {
        const newest = added.find((t) => t.kind === original.kind)!;
        expect(html.indexOf(newest.name[locale])).toBeGreaterThan(-1);
        expect(html.indexOf(newest.name[locale])).toBeLessThan(html.indexOf(original.name[locale]));
      }
    }
  });

  it('uses the matching MP4 and poster when the portal language changes', () => {
    const video = keepsakeSeedV1.templates.find((t) => t.kind === 'video')!;
    const localized = {
      ...video,
      preview: 'legacy-vi_12345678.mp4',
      previews: { vi: 'demo-vi_12345678.mp4', en: 'demo-en_12345678.mp4' },
      thumbs: { vi: 'poster-vi_12345678.webp', en: 'poster-en_12345678.webp' },
    };
    const view: KeepsakeView = {
      ...live,
      current: { ...live.current!, catalog: { ...keepsakeSeedV1, templates: [localized] } },
      assets: [
        ...Object.values(localized.previews),
        ...Object.values(localized.thumbs),
        localized.preview,
      ].map((asset) => ({ asset, url: `https://img.test/${asset}` })),
    };
    for (const language of ['vi', 'en'] as const) {
      const html = render(
        <KeepsakesBody view={view} canEdit canApprove onChanged={() => {}} />,
        ['admin'],
        language,
      );
      expect(html).toContain(`src="https://img.test/${localized.previews[language]}#t=4"`);
      expect(html).toContain(`src="https://img.test/${localized.thumbs[language]}"`);
      expect(html).not.toContain('legacy-vi_12345678.mp4');
      expect(html).not.toContain(localized.previews[language === 'en' ? 'vi' : 'en']);
    }
  });

  it('tabs: the gallery, the Cao cấp setting, the files and history', () => {
    const tab = (initialTab: KeepsakeTab) =>
      text(
        render(
          <KeepsakesBody
            view={live}
            canEdit
            canApprove
            onChanged={() => {}}
            initialTab={initialTab}
          />,
        ),
      );
    const gallery = tab('templates');
    // The version in use is a compact badge (details in its popover), not a banner.
    expect(gallery).not.toContain('Bản đang dùng · ks_20261013_01');
    expect(gallery).toContain('Đang dùng');
    for (const label of ['Mẫu 8', 'Nhạc nền 0', 'Tệp 1', 'Cài đặt', 'Lịch sử 1']) {
      expect(gallery).toContain(label);
    }
    expect(gallery).toContain('Thiệp cột mốc 4');
    expect(gallery).toContain('Video kỷ niệm 4');
    for (const name of ['Tròn trịa', 'Toàn ảnh', 'Hồng phấn', 'Đêm sao', 'Tháng đầu tiên']) {
      expect(gallery).toContain(name);
    }
    expect(gallery).toContain('6–8 ảnh');
    expect(gallery).toContain('Mẫu mới');
    expect(gallery).toContain('Thêm thiệp');
    expect(gallery).toContain('Thêm video');
    expect(tab('settings')).toContain('Mẫu Cao cấp: mọi gia đình dùng được (beta)');
    const files = tab('files');
    expect(files).toContain('frame-pink_1a2b3c4d.webp');
    expect(files).toContain('Chưa dùng');
    expect(tab('history')).toContain('Bộ đầu');
  });

  it('nothing published: start from the seed (editors only)', () => {
    const empty: KeepsakeView = { current: null, draft: null, history: [], assets: [] };
    expect(
      text(render(<KeepsakesBody view={empty} canEdit canApprove={false} onChanged={() => {}} />)),
    ).toContain('Bắt đầu từ bộ mẫu đầu tiên');
    expect(
      text(
        render(
          <KeepsakesBody view={empty} canEdit={false} canApprove={false} onChanged={() => {}} />,
          ['support'],
        ),
      ),
    ).not.toContain('Bắt đầu từ bộ mẫu đầu tiên');
  });

  it('a pending draft offers Duyệt & xuất bản and Trả lại to approvers only', () => {
    const pending: KeepsakeView = {
      ...live,
      draft: {
        ...live.history[0]!,
        versionId: 'kv_0000000000000002',
        status: 'pending',
        label: null,
        catalog: {
          ...keepsakeSeedV1,
          premium: { access: 'hidden', badges: false },
        },
      },
    };
    const approver = text(
      render(<KeepsakesBody view={pending} canEdit={false} canApprove onChanged={() => {}} />),
    );
    expect(approver).toContain('Duyệt & xuất bản');
    expect(approver).toContain('Trả lại');
    expect(
      text(
        render(
          <KeepsakesBody
            view={pending}
            canEdit={false}
            canApprove
            onChanged={() => {}}
            initialTab="settings"
          />,
        ),
      ),
    ).toContain('Mẫu Cao cấp: ẩn');
    const editor = text(
      render(<KeepsakesBody view={pending} canEdit canApprove={false} onChanged={() => {}} />),
    );
    expect(editor).not.toContain('Duyệt & xuất bản');
    // An editor looking at the set in use while a draft is open reads only.
    expect(
      text(
        render(
          <KeepsakesBody
            view={{ ...pending, draft: { ...pending.draft!, status: 'draft' } }}
            canEdit
            canApprove={false}
            onChanged={() => {}}
          />,
        ),
      ),
    ).toContain('Gửi duyệt');
  });

  it('a draft older than the set in use: warned, update offered, approval held', () => {
    const stale: KeepsakeView = {
      ...live,
      draft: {
        ...live.history[0]!,
        versionId: 'kv_0000000000000003',
        status: 'pending',
        label: null,
        createdAt: '2026-10-12T02:00:00Z',
        basedOn: null,
        catalog: keepsakeSeedV1,
      },
    };
    const html = render(<KeepsakesBody view={stale} canEdit canApprove onChanged={() => {}} />);
    expect(text(html)).toContain('Bản nháp này được tạo trước khi xuất bản ks_20261013_01');
    expect(text(html)).toContain('Cập nhật bản nháp theo bản đang dùng');
    expect(html).toMatch(/<button[^>]*disabled[^>]*>[^<]*Duyệt &amp; xuất bản/);
  });

  it('checks the set against the shared schema before saving', () => {
    expect(catalogIssues(keepsakeSeedV1)).toEqual([]);
    const broken: KeepsakeCatalog = structuredClone(keepsakeSeedV1);
    broken.templates[0]!.layouts = {};
    broken.templates[1]!.id = broken.templates[2]!.id;
    const issues = catalogIssues(broken);
    expect(issues.length).toBeGreaterThan(0);
    expect(issues.join('\n')).toMatch(/card_round|duplicate/);
  });

  it('previews a card from its layers with uploaded pictures', () => {
    const t = structuredClone(keepsakeSeedV1.templates[0]!);
    t.layouts!.portrait!.push({
      type: 'image',
      asset: 'frame-pink_1a2b3c4d.webp',
      rect: { x: 0, y: 0, w: 1, h: 1 },
      fit: 'cover',
      opacity: 1,
    });
    const html = render(
      <CardPreview
        template={t}
        format="portrait"
        width={250}
        urls={new Map([['frame-pink_1a2b3c4d.webp', 'https://img.test/frame.webp']])}
      />,
    );
    expect(html).toContain('https://img.test/frame.webp');
    expect(text(html)).toContain('1 tháng');
    expect(text(html)).toContain('Teddy');
    expect(html).toContain('height:312.5px');
    // The Child Life logo layer of the seed (D-068 #10), tinted with the palette's ink.
    expect(html).toContain('aria-label="Child Life"');
    expect(html).toContain(`fill="${t.palette.ink}"`);
  });

  it('Thư viện nhạc: licensed tracks, a player, and a default track per video template', () => {
    const catalog: KeepsakeCatalog = structuredClone(keepsakeSeedV1);
    catalog.music = [
      {
        id: 'music_lullaby',
        title: { vi: 'Ru con', en: 'Lullaby' },
        artist: 'Studio A',
        mood: 'gentle',
        durationSec: 62,
        asset: 'lullaby_9f8e7d6c.mp3',
        licence: { kind: 'licensed', source: 'Artlist', reference: 'INV-42', expiresOn: null },
        status: 'published',
        order: 10,
      },
    ];
    const withMusic: KeepsakeView = {
      ...live,
      current: { ...live.current!, catalog },
      assets: [
        ...live.assets,
        { asset: 'lullaby_9f8e7d6c.mp3', url: 'https://img.test/lullaby.mp3' },
        { asset: 'first-month_0a0b0c0d.mp4', url: 'https://img.test/first-month.mp4' },
      ],
    };
    const music = text(
      render(
        <KeepsakesBody
          view={withMusic}
          canEdit
          canApprove
          onChanged={() => {}}
          initialTab="music"
        />,
      ),
    );
    expect(music).toContain('Thư viện nhạc (1)');
    expect(music).toContain('Ru con · Lullaby');
    expect(music).toContain('Studio A · Nhẹ nhàng · 1:02');
    expect(music).toContain('Có license');
    expect(music).toContain('Hiện trong app');
    const files = render(
      <KeepsakesBody view={withMusic} canEdit canApprove onChanged={() => {}} initialTab="files" />,
    );
    expect(files).toContain('src="https://img.test/lullaby.mp3"');
    expect(files).toContain('href="https://img.test/first-month.mp4"');
    expect(text(files)).toContain('♪ Ru con');
  });

  it('is in the sidebar under NỘI DUNG for content staff', () => {
    const sidebar = (roles: StaffRole[]) =>
      text(
        render(
          <Sidebar
            route="keepsakes"
            badges={null}
            environment="dev"
            locale="vi"
            onLocale={() => undefined}
            onSignOut={() => undefined}
            navigate={() => undefined}
          />,
          roles,
        ),
      );
    expect(sidebar(['ops'])).toContain('NỘI DUNG Sơ cứu Nhịp lớn lên Mẫu kỷ niệm');
    expect(sidebar(['analyst'])).not.toContain('Mẫu kỷ niệm');
  });
});

describe('Mẫu mới', () => {
  it('gives a readable, unique id from the Vietnamese name', () => {
    expect(templateIdFor('card', 'Sinh nhật đầu tiên', [])).toBe('card_sinh_nhat_dau_tien');
    expect(templateIdFor('video', 'Bé đi', ['video_be_di'])).toBe('video_be_di_2');
    expect(templateIdFor('card', '', [])).toBe('card_moi');
  });
});

describe('Mẫu kỷ niệm list (portal UX 2026-10-21)', () => {
  const templates = keepsakeSeedV1.templates;
  const name = (t: (typeof templates)[number]) => t.name.vi;

  it('an open template has its own address, so the browser back returns to the list', () => {
    expect(keepsakeTemplateUrl('card_tron tria')).toBe('/keepsakes/templates/card_tron%20tria');
    expect(routeOf('/keepsakes/templates/card_tron')).toBe('keepsakes');
    expect(routeOf('/keepsakes')).toBe('keepsakes');
  });

  it('filters by Miễn phí / Cao cấp, kind and a name or id search', () => {
    const premium = filterTemplates(templates, { kind: 'all', tier: 'premium', q: '' }, name);
    expect(premium.length).toBeGreaterThan(0);
    expect(premium.every((t) => t.tier === 'premium')).toBe(true);
    const free = filterTemplates(templates, { kind: 'all', tier: 'free', q: '' }, name);
    expect(free.length + premium.length).toBe(templates.length);
    const one = templates.find((t) => t.kind === 'video')!;
    expect(
      filterTemplates(templates, { kind: 'video', tier: 'all', q: name(one).toUpperCase() }, name),
    ).toEqual([one]);
    expect(filterTemplates(templates, { kind: 'card', tier: 'all', q: one.id }, name)).toEqual([]);
    const html = text(
      render(<KeepsakesBody view={live} canEdit canApprove onChanged={() => {}} />),
    );
    expect(html).toContain('Tất cả Thiệp Video Mọi gói Miễn phí Cao cấp');
  });

  it('reads per-template exports defensively and sorts most → least', () => {
    expect(templateUsageOf(live)).toBeNull();
    expect(templateUsageOf({ usage: { a: { exports: 'x' } } })).toBeNull();
    const [a, b, c] = templates.filter((t) => t.kind === 'video');
    const usage = templateUsageOf({
      usage: {
        [a!.id]: { exports: 3, exports30d: 1 },
        [b!.id]: { exports: 12, exports30d: 4 },
        [c!.id]: { exports: 12, exports30d: 9 },
      },
    })!;
    expect(usage.get(b!.id)).toEqual({ exports: 12, exports30d: 4 });
    expect(
      templateUsageOf({ templateUsage: [{ templateId: a!.id, exports: 2 }] })?.get(a!.id),
    ).toEqual({ exports: 2, exports30d: null });
    const rows = [a!, b!, c!].map((t, i) => ({ t, i }));
    expect(sortTemplates(rows, 'exports', usage).map((r) => r.t.id)).toEqual([c!.id, b!.id, a!.id]);
    // Without the server's counts the sort falls back to the display order.
    expect(sortTemplates(rows, 'exports', null).map((r) => r.t.id)).toEqual(
      sortTemplates(rows, 'display', null).map((r) => r.t.id),
    );
    // The tiles show the counts only when the server sends them.
    const withUsage = text(
      render(
        <KeepsakesBody
          view={{ ...live, usage: { [b!.id]: { exports: 12, exports30d: 4 } } }}
          canEdit
          canApprove
          onChanged={() => {}}
        />,
      ),
    );
    expect(withUsage).toContain('12 lượt xuất · 4 trong 30 ngày');
    expect(withUsage).toContain('0 lượt xuất');
    // Cards are not counted by the server: no "0 lượt xuất" on them.
    expect(withUsage.match(/lượt xuất/g)).toHaveLength(
      templates.filter((t) => t.kind === 'video').length,
    );
    expect(
      text(render(<KeepsakesBody view={live} canEdit canApprove onChanged={() => {}} />)),
    ).not.toContain('lượt xuất');
  });
});
