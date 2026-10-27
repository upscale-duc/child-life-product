import { fileURLToPath, pathToFileURL } from 'node:url';
const { chromium } = await import(
  pathToFileURL(
    process.env.PORTAL_PLAYWRIGHT_MODULE ||
      '/tmp/child-life-portal-browser/node_modules/playwright/index.mjs',
  ).href
);
import fs from 'node:fs';
import path from 'node:path';
const root = fileURLToPath(new URL('../../../../', import.meta.url));
const phase = process.env.PHASE || 'after';
const routes = process.env.ROUTES
  ? JSON.parse(process.env.ROUTES)
  : [
      '/',
      '/analytics',
      '/analytics/acquisition',
      '/analytics/memories',
      '/analytics/engagement',
      '/analytics/features',
      '/analytics/cost',
      '/analytics/personalization',
      '/families',
      '/support',
      '/storage',
      '/jobs',
      '/notifications',
      '/notifications/templates',
      '/notifications/catalog',
      '/notifications/delivery',
      '/notifications/journeys',
      '/notifications/timeline',
      '/notifications/analytics',
      '/notifications/settings',
      '/first-aid',
      '/rhythm',
      '/keepsakes',
      '/print-studio',
      '/articles',
      '/stages',
      '/milestones',
      '/nutrition',
      '/solids',
      '/content-review',
      '/reference',
      '/features',
      '/features/families',
      '/features/plan',
      '/features/history',
      '/system',
      '/system/ai',
      '/system/assistant',
      '/system/tasks',
      '/app-update',
      '/staff',
      '/audit',
      '/qa',
      '/sign-in',
      '/articles/new',
      '/stages/new',
      '/milestones/new',
      '/nutrition/nutrients',
      '/nutrition/rules',
      '/nutrition/stages/new',
      '/nutrition/nutrients/new',
      '/nutrition/rules/new',
      '/solids/recipes',
      '/solids/guides',
      '/solids/foods/new',
      '/solids/recipes/new',
      '/solids/guides/new',
      '/notifications/templates/memories.new_moments',
      '/reference/weight',
      '/reference/bottle',
      '/reference/vaccines',
    ];
const output = path.join(root, 'docs/design/reviews/assets/2026-10-26-portal', phase);
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({
  executablePath:
    process.env.PORTAL_CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
});
const jobs =
  phase === 'before'
    ? routes.map((r) => ({ route: r, lang: 'vi', theme: 'light', width: 1440 }))
    : routes.flatMap((route) =>
        ['vi', 'en'].flatMap((lang) =>
          ['light', 'dark'].map((theme) => ({ route, lang, theme, width: 1440 })),
        ),
      );
if (phase !== 'before')
  for (const route of ['/features', '/notifications', '/analytics', '/app-update', '/articles'])
    jobs.push({ route, lang: 'vi', theme: 'light', width: 390 });
if (phase === 'after')
  for (const route of [
    '/features',
    '/notifications',
    '/analytics',
    '/app-update',
    '/articles/new',
    '/print-studio',
  ])
    jobs.push({ route, lang: 'vi', theme: 'light', width: 720, scale: 2 });
let index = 0;
const results = [];
await Promise.all(
  Array.from({ length: 3 }, async () => {
    while (index < jobs.length) {
      const task = jobs[index++];
      const page = await browser.newPage({
        viewport: { width: task.width, height: 1000 },
        deviceScaleFactor: task.scale || 1,
      });
      const errors = [];
      await page.route(/https:\/\/[^/]*\.test\//, (route) =>
        route.fulfill({
          contentType: 'image/svg+xml',
          body: '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400"><rect width="600" height="400" fill="#e6f7f5"/></svg>',
        }),
      );
      page.on('pageerror', (e) => errors.push(e.message));
      page.on('console', (m) => {
        if (m.type() === 'error' && !m.text().includes('404')) errors.push(m.text().slice(0, 400));
      });
      await page.addInitScript(
        (theme) => localStorage.setItem('childlife.portal.theme', theme),
        task.theme,
      );
      await page.goto(
        'http://127.0.0.1:5181/test/design-review/index.html?path=' +
          encodeURIComponent(task.route) +
          '&lang=' +
          task.lang,
      );
      await page.waitForTimeout(500);
      await page.evaluate((t) => {
        document.documentElement.dataset.theme = t;
      }, task.theme);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(100);
      const name =
        (task.route === '/' ? 'overview' : task.route.slice(1).replaceAll('/', '-')) +
        '_' +
        task.lang +
        '_' +
        task.theme +
        '_' +
        task.width +
        (task.scale ? '_zoom2' : '');
      const text = await page.locator('body').innerText();
      const overflow = await page.evaluate(() => ({
        page: document.documentElement.scrollWidth - innerWidth,
        main: document.querySelector('main')?.scrollWidth,
      }));
      await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
      results.push({ ...task, name, errors, overflow, text });
      if (task.route === '/' && task.lang === 'vi' && task.theme === 'light')
        fs.writeFileSync(
          phase === 'before' || phase === 'baseline'
            ? '/tmp/portal-catalog-before.json'
            : '/tmp/portal-catalog-after.json',
          JSON.stringify(await page.evaluate(() => window.__review.messages), null, 2),
        );
      await page.close();
    }
  }),
);
const prior =
  process.env.ROUTES && fs.existsSync(path.join(output, 'coverage.json'))
    ? JSON.parse(fs.readFileSync(path.join(output, 'coverage.json'), 'utf8'))
    : [];
const merged = [...prior.filter((x) => !results.some((r) => r.name === x.name)), ...results];
fs.writeFileSync(path.join(output, 'coverage.json'), JSON.stringify(merged, null, 2));
console.log(
  JSON.stringify(
    {
      phase,
      captures: results.length,
      errors: results
        .filter((r) => r.errors.length)
        .map((r) => ({ route: r.route, lang: r.lang, errors: r.errors })),
      overflow: results
        .filter((r) => r.overflow.page > 0)
        .map((r) => ({ route: r.route, width: r.width, overflow: r.overflow.page })),
    },
    null,
    2,
  ),
);
await browser.close();
