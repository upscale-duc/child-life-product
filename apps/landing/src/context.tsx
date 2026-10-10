import { createContext, useContext } from 'react';
import type { Content } from './content/types';
import type { Route } from './routes';

export interface Site {
  c: Content;
  route: Route;
  /** Home page of the current language ("/" or "/en/"). */
  homePath: string;
  /** Shows a short message in the page toast. */
  notify: (message: string) => void;
}

export const SiteContext = createContext<Site | null>(null);

export function useSite(): Site {
  const site = useContext(SiteContext);
  if (!site) throw new Error('useSite outside SiteContext');
  return site;
}
