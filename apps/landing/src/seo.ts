import type { Environment } from '@child-life/contracts';
import type { Content } from './content/types';
import { alternateOf, type Route } from './routes';
import { siteOrigin } from './site';

const escape = (value: string) =>
  value.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/** Builds the <head> tags for one prerendered page: title, description, canonical,
 *  hreflang alternates, Open Graph / Twitter, theme colours and JSON-LD. */
export function buildHead(route: Route, content: Content, environment: Environment): string {
  const origin = siteOrigin[environment];
  const page = route.page === 'home' ? content.meta : content.legal[route.page].meta;
  const url = `${origin}${route.path}`;
  const vi = alternateOf(route, 'vi');
  const en = alternateOf(route, 'en');
  const ogImage = `${origin}/og/${route.locale}.png`;

  const tags = [
    `<title>${escape(page.title)}</title>`,
    `<meta name="description" content="${escape(page.description)}">`,
    `<link rel="canonical" href="${url}">`,
    `<link rel="alternate" hreflang="vi" href="${origin}${vi.path}">`,
    `<link rel="alternate" hreflang="en" href="${origin}${en.path}">`,
    `<link rel="alternate" hreflang="x-default" href="${origin}${vi.path}">`,
    `<meta property="og:type" content="website">`,
    `<meta property="og:site_name" content="Child Life">`,
    `<meta property="og:locale" content="${route.locale === 'vi' ? 'vi_VN' : 'en_US'}">`,
    `<meta property="og:locale:alternate" content="${route.locale === 'vi' ? 'en_US' : 'vi_VN'}">`,
    `<meta property="og:title" content="${escape(page.title)}">`,
    `<meta property="og:description" content="${escape(page.description)}">`,
    `<meta property="og:url" content="${url}">`,
    `<meta property="og:image" content="${ogImage}">`,
    `<meta property="og:image:width" content="1200">`,
    `<meta property="og:image:height" content="630">`,
    `<meta property="og:image:alt" content="${escape(content.meta.ogAlt)}">`,
    `<meta name="twitter:card" content="summary_large_image">`,
    // The landing is designed in Light only (Website 210:759).
    `<meta name="theme-color" content="#F6FCFB">`,
  ];
  // Dev hosts must never be indexed (plan §3.7).
  if (environment !== 'prod') tags.push('<meta name="robots" content="noindex, nofollow">');

  if (route.page === 'home') {
    const graph = [
      {
        '@type': 'Organization',
        '@id': `${origin}/#org`,
        name: 'Child Life',
        url: `${origin}/`,
        logo: `${origin}/icons/icon-512.png`,
        email: content.footer.email,
      },
      {
        '@type': 'WebSite',
        '@id': `${origin}/#website`,
        url: `${origin}/`,
        name: 'Child Life',
        inLanguage: ['vi', 'en'],
        publisher: { '@id': `${origin}/#org` },
      },
      {
        '@type': 'MobileApplication',
        name: 'Child Life',
        operatingSystem: 'iOS, Android',
        applicationCategory: 'LifestyleApplication',
        description: page.description,
        inLanguage: route.locale,
        offers: { '@type': 'Offer', price: '0', priceCurrency: 'VND' },
        publisher: { '@id': `${origin}/#org` },
      },
      {
        '@type': 'FAQPage',
        inLanguage: route.locale,
        mainEntity: content.faq.items.map((item) => ({
          '@type': 'Question',
          name: item.q,
          acceptedAnswer: { '@type': 'Answer', text: item.a },
        })),
      },
    ];
    const json = JSON.stringify({ '@context': 'https://schema.org', '@graph': graph }).replace(
      /</g,
      '\\u003c',
    );
    tags.push(`<script type="application/ld+json">${json}</script>`);
  }
  return tags.join('\n    ');
}
