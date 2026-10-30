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

/** Every prerendered page. English lives at the root and Vietnamese under /vi/ (owner,
 *  2026-10-30; until then Vietnamese was at the root and English under /en/, D-012). The old
 *  paths redirect in firebase.json. Stage slugs are an engineering proposal
 *  (15-landing-v3-stages §10). */
export const routes: Route[] = [
  { path: '/', locale: 'en', page: 'home' },
  { path: '/vi/', locale: 'vi', page: 'home' },
  { path: '/journey/first-days/', locale: 'en', page: 'stage1' },
  { path: '/vi/hanh-trinh/nhung-ngay-dau-doi/', locale: 'vi', page: 'stage1' },
  { path: '/journey/exploring/', locale: 'en', page: 'stage2' },
  { path: '/vi/hanh-trinh/con-tap-kham-pha/', locale: 'vi', page: 'stage2' },
  { path: '/journey/curious/', locale: 'en', page: 'stage3' },
  { path: '/vi/hanh-trinh/to-mo-va-lon-khon/', locale: 'vi', page: 'stage3' },
  { path: '/journey/own-world/', locale: 'en', page: 'stage4' },
  { path: '/vi/hanh-trinh/the-gioi-rieng-cua-con/', locale: 'vi', page: 'stage4' },
  { path: '/lumi/', locale: 'en', page: 'lumi' },
  { path: '/vi/lumi/', locale: 'vi', page: 'lumi' },
  { path: '/privacy/', locale: 'en', page: 'privacy' },
  { path: '/vi/quyen-rieng-tu/', locale: 'vi', page: 'privacy' },
  { path: '/terms/', locale: 'en', page: 'terms' },
  { path: '/vi/dieu-khoan/', locale: 'vi', page: 'terms' },
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
