import { createContext, useContext } from 'react';
import type { StaffIdentity } from './session';

export const StaffContext = createContext<StaffIdentity | null>(null);

export function useStaff(): StaffIdentity {
  const staff = useContext(StaffContext);
  if (!staff) throw new Error('StaffContext missing');
  return staff;
}

export type Route =
  | 'overview'
  | 'analytics'
  | 'families'
  | 'support'
  | 'storage'
  | 'jobs'
  | 'reference'
  | 'firstAid'
  | 'rhythm'
  | 'keepsakes'
  // Editorial content (D-076 #5–#7): B01/B02, B05/B06, B07/B08, B03/B04.
  | 'articles'
  | 'stages'
  | 'milestones'
  // Dinh dưỡng theo giai đoạn (D-083): D01–D04.
  | 'nutrition'
  // Ăn dặm (D-085): Thực phẩm, Công thức, Hướng dẫn.
  | 'solids'
  | 'contentReview'
  // Hệ thống & AI (owner 2026-10-21): Lưu trữ, AI, the assistant's usage and task lookup.
  | 'system'
  | 'appUpdate'
  // Tính năng & Premium (D-089): one hub for features, families, the plan and system switches.
  | 'features'
  // Thông báo & Gắn kết (P-174): catalog, templates, delivery, journeys, family timeline.
  | 'notifications'
  | 'staff'
  | 'audit'
  | 'qa';

export const routePaths: Record<Route, string> = {
  overview: '/',
  analytics: '/analytics',
  families: '/families',
  support: '/support',
  storage: '/storage',
  jobs: '/jobs',
  reference: '/reference',
  firstAid: '/first-aid',
  rhythm: '/rhythm',
  keepsakes: '/keepsakes',
  articles: '/articles',
  stages: '/stages',
  milestones: '/milestones',
  nutrition: '/nutrition',
  solids: '/solids',
  contentReview: '/content-review',
  system: '/system',
  appUpdate: '/app-update',
  features: '/features',
  notifications: '/notifications',
  staff: '/staff',
  audit: '/audit',
  qa: '/qa',
};

/** v1.0 screens with their own sub-pages: "/families/F-7Q2K", "/staff/roles/support". */
const nestedRoutes: Route[] = [
  'analytics',
  'families',
  'reference',
  'firstAid',
  'rhythm',
  // "/keepsakes/templates/<id>": a template open, so the browser's back returns to the list.
  'keepsakes',
  'staff',
  'articles',
  'stages',
  'milestones',
  'nutrition',
  'solids',
  'contentReview',
  // "/features/families", "/system/ai": a tab of the page.
  'features',
  'system',
  // "/notifications/templates/<id>", "/notifications/timeline/F-7Q2K": a tab or an item.
  'notifications',
];

/**
 * Addresses of pages that were merged (owner, 2026-10-21): old links and bookmarks open the tab
 * that holds their content now.
 */
export const legacyPaths: Readonly<Record<string, string>> = {
  '/premium': '/features/plan',
  '/assistant': '/system/assistant',
};

/** The address to show for [pathname]: a merged page's old address becomes its tab's. */
export function canonicalPath(pathname: string): string {
  const clean = pathname.replace(/\/+$/, '') || '/';
  const hit = Object.keys(legacyPaths).find((p) => clean === p || clean.startsWith(`${p}/`));
  return hit ? legacyPaths[hit]! : pathname;
}

export function routeOf(pathname: string): Route {
  const clean = canonicalPath(pathname).replace(/\/+$/, '') || '/';
  const hit = (Object.entries(routePaths) as Array<[Route, string]>).find(([, p]) => p === clean);
  if (hit) return hit[0];
  const nested = nestedRoutes.find((r) => clean.startsWith(`${routePaths[r]}/`));
  return nested ?? 'overview';
}

/** The path segments after a nested route's base ("/staff/roles/ops" → ["roles", "ops"]). */
export function subPath(route: Route, pathname: string): string[] {
  const base = routePaths[route];
  const path = canonicalPath(pathname);
  if (!path.startsWith(`${base}/`)) return [];
  return path
    .slice(base.length + 1)
    .split('/')
    .filter(Boolean)
    .map(decodeURIComponent);
}

/** Opens a page; `sub` opens one of its tabs or items ("plan" → "/features/plan"). */
export const NavigateContext = createContext<(route: Route, sub?: string) => void>(() => undefined);
export const useNavigate = () => useContext(NavigateContext);

/** Re-fetches the sidebar counts after a decision. */
export const BadgesContext = createContext<() => void>(() => undefined);
export const useRefreshBadges = () => useContext(BadgesContext);
