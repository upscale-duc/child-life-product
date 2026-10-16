import type { SupportedLocale } from '@child-life/web-config';

/** The four "Chặng" pages of the v3 journey (Figma 370:50752, 361:3457, 361:3575, 361:3693). */
export const stageIds = ['stage1', 'stage2', 'stage3', 'stage4'] as const;
export type StageId = (typeof stageIds)[number];

export type PageId = 'home' | StageId | 'lumi' | 'privacy' | 'terms';

export interface Route {
  path: string;
  locale: SupportedLocale;
  page: PageId;
}

/** Every prerendered page. Vietnamese lives at the root, English under /en/ (D-012).
 *  Stage slugs are an engineering proposal (15-landing-v3-stages §10). */
export const routes: Route[] = [
  { path: '/', locale: 'vi', page: 'home' },
  { path: '/en/', locale: 'en', page: 'home' },
  { path: '/hanh-trinh/nhung-ngay-dau-doi/', locale: 'vi', page: 'stage1' },
  { path: '/en/journey/first-days/', locale: 'en', page: 'stage1' },
  { path: '/hanh-trinh/con-tap-kham-pha/', locale: 'vi', page: 'stage2' },
  { path: '/en/journey/exploring/', locale: 'en', page: 'stage2' },
  { path: '/hanh-trinh/to-mo-va-lon-khon/', locale: 'vi', page: 'stage3' },
  { path: '/en/journey/curious/', locale: 'en', page: 'stage3' },
  { path: '/hanh-trinh/the-gioi-rieng-cua-con/', locale: 'vi', page: 'stage4' },
  { path: '/en/journey/own-world/', locale: 'en', page: 'stage4' },
  { path: '/lumi/', locale: 'vi', page: 'lumi' },
  { path: '/en/lumi/', locale: 'en', page: 'lumi' },
  { path: '/quyen-rieng-tu/', locale: 'vi', page: 'privacy' },
  { path: '/en/privacy/', locale: 'en', page: 'privacy' },
  { path: '/dieu-khoan/', locale: 'vi', page: 'terms' },
  { path: '/en/terms/', locale: 'en', page: 'terms' },
];

export function isStage(page: PageId): page is StageId {
  return (stageIds as readonly string[]).includes(page);
}

export function routeFor(pathname: string): Route {
  const normalized = pathname.endsWith('/') ? pathname : `${pathname}/`;
  return routes.find((r) => r.path === normalized) ?? routes[0]!;
}

/** The same page in the other language (for hreflang and the language switch). */
export function alternateOf(route: Route, locale: SupportedLocale): Route {
  return routes.find((r) => r.page === route.page && r.locale === locale) ?? route;
}

export function pathOf(page: PageId, locale: SupportedLocale): string {
  return routes.find((r) => r.page === page && r.locale === locale)!.path;
}
