import { describe, expect, it } from 'vitest';
import { en } from '../src/content/en';
import { analyticsIds } from '../src/analytics';
import { vi as viContent } from '../src/content/vi';
import { render } from '../src/entry-server';
import { alternateOf, pathOf, routeFor, routes, stageIds } from '../src/routes';
import { buildHead } from '../src/seo';

/** Structure of a catalog: keys and array lengths, with leaf types. */
function shape(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(shape);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([k, v]) => [k, shape(v)]),
    );
  }
  return typeof value;
}

function strings(value: unknown, path = ''): [string, string][] {
  if (typeof value === 'string') return [[path, value]];
  if (value && typeof value === 'object')
    return Object.entries(value).flatMap(([k, v]) => strings(v, `${path}.${k}`));
  return [];
}

describe('content catalogs (D-012)', () => {
  it('Vietnamese and English have the same structure', () => {
    expect(shape(en)).toEqual(shape(viContent));
  });

  it('has no empty strings', () => {
    for (const catalog of [viContent, en]) {
      for (const [path, text] of strings(catalog))
        expect(text.trim(), `${catalog.locale}${path}`).not.toBe('');
    }
  });

  it('English is not left in Vietnamese', () => {
    const viStrings = new Set(strings(viContent).map(([, s]) => s));
    // Brand names, numbers and times may be shared; whole sentences may not.
    const shared = strings(en).filter(
      ([, s]) => viStrings.has(s) && s.split(/\s+/).filter((w) => /\p{L}{3,}/u.test(w)).length >= 3,
    );
    expect(shared).toEqual([]);
  });

  it('keeps the D-001 / Q-008 replacements (Figma copy that contradicts the app)', () => {
    const all = strings(viContent)
      .map(([, s]) => s)
      .join('\n');
    expect(all).not.toContain('mặc định chỉ ba mẹ thấy');
    expect(all).not.toContain('Gửi ảnh bé cho ba mẹ');
    expect(all).not.toContain('đã xem 12 ảnh mới');
  });
});

describe('routes', () => {
  it('every page exists in both languages, Vietnamese at the root', () => {
    for (const page of ['home', ...stageIds, 'privacy', 'terms'] as const) {
      expect(pathOf(page, 'vi').startsWith('/en/')).toBe(false);
      expect(pathOf(page, 'en').startsWith('/en/')).toBe(true);
    }
    for (const route of routes) {
      const other = alternateOf(route, route.locale === 'vi' ? 'en' : 'vi');
      expect(alternateOf(other, route.locale)).toBe(route);
    }
  });

  it('resolves paths with or without the trailing slash; unknown paths fall back to home', () => {
    expect(routeFor('/en').path).toBe('/en/');
    expect(routeFor('/en/privacy').page).toBe('privacy');
    expect(routeFor('/nope/').path).toBe('/');
  });
});

describe('SEO head', () => {
  const home = routeFor('/');

  it('dev pages are never indexable; prod pages are', () => {
    expect(buildHead(home, viContent, 'dev')).toContain('noindex');
    expect(buildHead(home, viContent, 'prod')).not.toContain('noindex');
  });

  it('declares canonical, hreflang alternates and Open Graph per language', () => {
    const head = buildHead(routeFor('/en/'), en, 'prod');
    expect(head).toContain('<link rel="canonical" href="https://childlife.app/en/">');
    expect(head).toContain('hreflang="vi" href="https://childlife.app/"');
    expect(head).toContain('hreflang="en" href="https://childlife.app/en/"');
    expect(head).toContain('hreflang="x-default" href="https://childlife.app/"');
    expect(head).toContain('og:image" content="https://childlife.app/og/en.png?v=4"');
    const stage = buildHead(routeFor('/hanh-trinh/con-tap-kham-pha/'), viContent, 'prod');
    expect(stage).toContain('og:image" content="https://childlife.app/og/vi-stage2.png?v=4"');
    expect(stage).toContain('<title>Con tập khám phá (1–3 tuổi) — Child Life</title>');
    expect(head).toContain('og:locale" content="en_US"');
  });

  it('home pages carry FAQPage JSON-LD with every question', () => {
    const head = buildHead(home, viContent, 'prod');
    const json = JSON.parse(/<script type="application\/ld\+json">(.*)<\/script>/.exec(head)![1]!);
    const faq = json['@graph'].find((node: { '@type': string }) => node['@type'] === 'FAQPage');
    expect(faq.mainEntity).toHaveLength(viContent.homePage.trust.faq.length);
  });
});

describe('prerender', () => {
  it.each(routes)('renders $path in its language with one h1', (route) => {
    const page = render(route.path, 'dev');
    expect(page.lang).toBe(route.locale);
    expect(page.html.match(/<h1[\s>]/g)).toHaveLength(1);
    expect(page.head).toContain('<title>');
  });

  it('nav links point at sections that exist on the page they lead to', () => {
    const htmlOf = (path: string) => render(path, 'dev').html;
    for (const route of routes) {
      const page = render(route.path, 'dev');
      const hrefs = [...page.html.matchAll(/<nav class="nav__links"[^>]*>(.*?)<\/nav>/g)].flatMap(
        (m) => [...m[1]!.matchAll(/href="([^"]+)"/g)].map((h) => h[1]!),
      );
      expect(hrefs, route.path).toHaveLength(5);
      for (const href of hrefs) {
        const [path, id] = href.split('#');
        const target = path ? htmlOf(path) : page.html;
        if (id) expect(target, `${route.path} → ${href}`).toContain(`id="${id}"`);
      }
    }
  });

  it('every stage page links to its neighbours and has one h1', () => {
    for (const stage of stageIds) {
      const html = render(pathOf(stage, 'vi'), 'dev').html;
      expect(html.match(/<h1[\s>]/g)).toHaveLength(1);
      expect(html).toContain('id="tai-app"');
      // Chặng 1 is the Năm đầu đời page (nav "Năm đầu đời" is current); 2–4 link their neighbours.
      if (stage === 'stage1') expect(html).toContain('aria-current="page"');
      else expect(html).toContain('rel="next"');
    }
  });

  it('no page repeats an element id', () => {
    for (const route of routes) {
      const ids = [...render(route.path, 'dev').html.matchAll(/\sid="([^"]+)"/g)].map((m) => m[1]);
      expect(
        ids.filter((id, i) => ids.indexOf(id) !== i),
        route.path,
      ).toEqual([]);
    }
  });

  it('the Lumi page has its sections and FAQ, and the home links to it', () => {
    const lumi = pathOf('lumi', 'vi');
    const page = render(lumi, 'prod');
    for (const id of [
      'gioi-thieu',
      'loi-ich',
      'hieu-ca-app',
      'cach-lam-viec',
      'hoi-dap',
      'tai-app',
    ])
      expect(page.html, id).toContain(`id="${id}"`);
    expect(page.html).not.toContain('<table');
    expect(page.head).toContain('og:image" content="https://childlife.app/og/vi-lumi.png?v=4"');
    expect(page.head).toContain(`<title>${viContent.lumiPage.meta.title}</title>`);
    const json = JSON.parse(
      /<script type="application\/ld\+json">(.*)<\/script>/.exec(page.head)![1]!,
    );
    const faq = json['@graph'].find((node: { '@type': string }) => node['@type'] === 'FAQPage');
    expect(faq.mainEntity).toHaveLength(viContent.lumiPage.faq.items.length);
    expect(
      render('/', 'dev').html.match(new RegExp(`href="${lumi}"`, 'g'))!.length,
    ).toBeGreaterThanOrEqual(2);
  });

  it('puts the FAQ answers in the HTML for search engines', () => {
    const page = render('/en/', 'prod');
    for (const item of en.homePage.trust.faq)
      expect(page.html).toContain(item.q.replace(/'/g, '&#x27;'));
  });
});

describe('analytics', () => {
  it('never measures dev; prod takes a GA4 measurement id or nothing', () => {
    expect(analyticsIds.dev).toBeNull();
    if (analyticsIds.prod !== null) expect(analyticsIds.prod).toMatch(/^G-[A-Z0-9]+$/);
  });

  it('prerendered pages load no analytics (gtag starts in the browser)', () => {
    expect(render('/', 'prod').html).not.toContain('googletagmanager');
  });
});
