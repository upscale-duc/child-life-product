import type { SupportedLocale } from '@child-life/web-config';

export type PageId = 'home' | 'privacy' | 'terms';

export interface Route {
  path: string;
  locale: SupportedLocale;
  page: PageId;
}

/** Every prerendered page. Vietnamese lives at the root, English under /en/ (D-012). */
export const routes: Route[] = [
  { path: '/', locale: 'vi', page: 'home' },
  { path: '/en/', locale: 'en', page: 'home' },
  { path: '/quyen-rieng-tu/', locale: 'vi', page: 'privacy' },
  { path: '/en/privacy/', locale: 'en', page: 'privacy' },
  { path: '/dieu-khoan/', locale: 'vi', page: 'terms' },
  { path: '/en/terms/', locale: 'en', page: 'terms' },
];

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
