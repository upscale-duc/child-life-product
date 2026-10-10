import { describe, expect, it } from 'vitest';
import { en } from '../src/content/en';
import { vi as viContent } from '../src/content/vi';
import { render } from '../src/entry-server';
import { alternateOf, pathOf, routeFor, routes } from '../src/routes';
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
    for (const page of ['home', 'privacy', 'terms'] as const) {
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
    expect(head).toContain('og:image" content="https://childlife.app/og/en.png"');
    expect(head).toContain('og:locale" content="en_US"');
  });

  it('home pages carry FAQPage JSON-LD with every question', () => {
    const head = buildHead(home, viContent, 'prod');
    const json = JSON.parse(/<script type="application\/ld\+json">(.*)<\/script>/.exec(head)![1]!);
    const faq = json['@graph'].find((node: { '@type': string }) => node['@type'] === 'FAQPage');
    expect(faq.mainEntity).toHaveLength(viContent.faq.items.length);
  });
});

describe('prerender', () => {
  it.each(routes)('renders $path in its language with one h1', (route) => {
    const page = render(route.path, 'dev');
    expect(page.lang).toBe(route.locale);
    expect(page.html.match(/<h1[\s>]/g)).toHaveLength(1);
    expect(page.head).toContain('<title>');
  });

  it('every nav link points at a section on the home page', () => {
    const page = render('/', 'dev');
    const targets = [...page.html.matchAll(/data-spy="([^"]+)"/g)].map((m) => m[1]);
    expect(targets).toEqual(['cham-con', 'hieu-con', 'ky-niem', 'gia-dinh', 'hoi-dap']);
    for (const id of targets) expect(page.html).toContain(`id="${id}"`);
  });

  it('puts the FAQ answers in the HTML for search engines', () => {
    const page = render('/en/', 'prod');
    for (const item of en.faq.items) expect(page.html).toContain(item.q.replace(/'/g, '&#x27;'));
  });
});
