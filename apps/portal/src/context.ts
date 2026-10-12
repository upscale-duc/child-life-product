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
  | 'system'
  | 'systemAi'
  | 'features'
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
  system: '/system',
  systemAi: '/system/ai',
  features: '/features',
  staff: '/staff',
  audit: '/audit',
  qa: '/qa',
};

/** v1.0 screens with their own sub-pages: "/families/F-7Q2K", "/staff/roles/support". */
const nestedRoutes: Route[] = ['analytics', 'families', 'reference', 'staff'];

export function routeOf(pathname: string): Route {
  const clean = pathname.replace(/\/+$/, '') || '/';
  const hit = (Object.entries(routePaths) as Array<[Route, string]>).find(([, p]) => p === clean);
  if (hit) return hit[0];
  const nested = nestedRoutes.find((r) => clean.startsWith(`${routePaths[r]}/`));
  return nested ?? 'overview';
}

/** The path segments after a nested route's base ("/staff/roles/ops" → ["roles", "ops"]). */
export function subPath(route: Route, pathname: string): string[] {
  const base = routePaths[route];
  if (!pathname.startsWith(`${base}/`)) return [];
  return pathname
    .slice(base.length + 1)
    .split('/')
    .filter(Boolean)
    .map(decodeURIComponent);
}

export const NavigateContext = createContext<(route: Route) => void>(() => undefined);
export const useNavigate = () => useContext(NavigateContext);

/** Re-fetches the sidebar counts after a decision. */
export const BadgesContext = createContext<() => void>(() => undefined);
export const useRefreshBadges = () => useContext(BadgesContext);
