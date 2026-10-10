import { createContext, useContext } from 'react';
import type { StaffIdentity } from './session';

export const StaffContext = createContext<StaffIdentity | null>(null);

export function useStaff(): StaffIdentity {
  const staff = useContext(StaffContext);
  if (!staff) throw new Error('StaffContext missing');
  return staff;
}

export type Route =
  'overview' | 'support' | 'storage' | 'jobs' | 'system' | 'systemAi' | 'features' | 'audit';

export const routePaths: Record<Route, string> = {
  overview: '/',
  support: '/support',
  storage: '/storage',
  jobs: '/jobs',
  system: '/system',
  systemAi: '/system/ai',
  features: '/features',
  audit: '/audit',
};

export function routeOf(pathname: string): Route {
  const clean = pathname.replace(/\/+$/, '') || '/';
  const hit = (Object.entries(routePaths) as Array<[Route, string]>).find(([, p]) => p === clean);
  return hit ? hit[0] : 'overview';
}

export const NavigateContext = createContext<(route: Route) => void>(() => undefined);
export const useNavigate = () => useContext(NavigateContext);

/** Re-fetches the sidebar counts after a decision. */
export const BadgesContext = createContext<() => void>(() => undefined);
export const useRefreshBadges = () => useContext(BadgesContext);
