// Renders every route to static HTML (SEO), plus sitemap.xml and robots.txt for the environment.
// Usage: node scripts/prerender.mjs dev|prod   (after the client and SSR builds)
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const environment = process.argv[2];
if (!['dev', 'prod'].includes(environment)) {
  console.error('Usage: node scripts/prerender.mjs dev|prod');
  process.exit(1);
}

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(root, 'dist');
// Inline the single stylesheet (~11 KB gzip) so first paint needs no extra round trip.
const template = readFileSync(join(dist, 'index.html'), 'utf8').replace(
  /<link rel="stylesheet"[^>]*href="(\/assets\/[^"]+\.css)"[^>]*>/,
  (_, href) =>
    `<style>${readFileSync(join(dist, href), 'utf8').replace(/\/\*# sourceMappingURL=.*?\*\//g, '')}</style>`,
);
if (!template.includes('<style>'))
  throw new Error('prerender: stylesheet link not found in dist/index.html');
const { render, routes, siteOrigin, alternates } = await import(
  pathToFileURL(join(root, 'dist-ssr/entry-server.js')).href
);
const origin = siteOrigin[environment];

for (const route of routes) {
  const { html, head, lang } = render(route.path, environment);
  const page = template
    .replace('<html lang="vi"', `<html lang="${lang}"`)
    .replace('<!--app-head-->', head)
    .replace('<!--app-html-->', html);
  const file = join(dist, route.path, 'index.html');
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, page);
  console.log(`prerendered ${route.path}`);
}

// 404 page = home in Vietnamese with noindex.
const notFound = render('/', environment);
writeFileSync(
  join(dist, '404.html'),
  template
    .replace('<!--app-head-->', `${notFound.head}\n    <meta name="robots" content="noindex">`)
    .replace('<!--app-html-->', notFound.html),
);

const sitemap = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">',
  ...routes.map((route) => {
    const alts = alternates(route)
      .map(
        (alt) =>
          `    <xhtml:link rel="alternate" hreflang="${alt.locale}" href="${origin}${alt.path}"/>`,
      )
      .join('\n');
    return `  <url>\n    <loc>${origin}${route.path}</loc>\n${alts}\n    <xhtml:link rel="alternate" hreflang="x-default" href="${origin}${alternates(route).find((a) => a.locale === 'vi').path}"/>\n  </url>`;
  }),
  '</urlset>',
  '',
].join('\n');
writeFileSync(join(dist, 'sitemap.xml'), sitemap);

writeFileSync(
  join(dist, 'robots.txt'),
  environment === 'prod'
    ? `User-agent: *\nDisallow: /s/\nDisallow: /i/\nSitemap: ${origin}/sitemap.xml\n`
    : 'User-agent: *\nDisallow: /\n',
);

// Android App Links for invite links /i/{token} (plan §3.6). Dev is signed with the debug key;
// prod fingerprints are added when the release signing key exists.
const androidApps = {
  dev: [
    {
      package_name: 'app.childlife.dev',
      sha256_cert_fingerprints: [
        '57:BA:4F:2C:29:C9:30:D4:EA:C9:43:3B:93:56:81:09:F3:4B:69:02:89:8E:12:C8:78:97:6A:80:6A:0E:DF:D3',
      ],
    },
  ],
  prod: [],
};
mkdirSync(join(dist, '.well-known'), { recursive: true });
writeFileSync(
  join(dist, '.well-known', 'assetlinks.json'),
  `${JSON.stringify(
    androidApps[environment].map((app) => ({
      relation: ['delegate_permission/common.handle_all_urls'],
      target: { namespace: 'android_app', ...app },
    })),
    null,
    2,
  )}\n`,
);

// iOS Universal Links: only invite links /i/{token} open the app; story links /s/… stay on the
// web. Served instead of Firebase's generated file, which opened every path. Dev borrows the
// owner's interim team (tool/ios_flavors.rb); prod waits for the Child Life developer account.
const iosApps = { dev: ['VHFV2HNZGN.dev.hsba.app'], prod: [] };
writeFileSync(
  join(dist, '.well-known', 'apple-app-site-association'),
  `${JSON.stringify(
    {
      applinks: {
        details: iosApps[environment].map((appID) => ({
          appIDs: [appID],
          components: [{ '/': '/i/*' }],
          appID,
          paths: ['/i/*'],
        })),
      },
    },
    null,
    2,
  )}\n`,
);

rmSync(join(root, 'dist-ssr'), { recursive: true, force: true });
console.log(`sitemap.xml and robots.txt written for ${environment} (${origin})`);
